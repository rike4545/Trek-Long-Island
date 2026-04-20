// Copyright Bryan Carroll. All rights reserved.
//
//  SquareIntegrationStore.swift
//  Trek Long Island
//
//  App-side view of the Square seller connection that lives in Firestore.
//  This keeps Square auth state, scopes, and sync readiness out of ad-hoc UI code.
//

import Foundation
import FirebaseFirestore

enum SquareConnectionStatus: String, Codable, CaseIterable, Identifiable {
    case disconnected
    case pending
    case connected
    case error

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .pending: return "Pending"
        case .connected: return "Connected"
        case .error: return "Needs Attention"
        }
    }
}

enum SquareCapability: String, Codable, CaseIterable, Identifiable {
    case customers
    case catalog
    case orders
    case payments
    case locations
    case loyalty
    case team

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

struct SquareMerchantConnection: Codable, Equatable {
    var status: SquareConnectionStatus
    var merchantID: String
    var merchantName: String
    var locationIDs: [String]
    var scopes: [String]
    var capabilities: [SquareCapability]
    var backendModeEnabled: Bool
    var cmsSyncEnabled: Bool
    var backendBaseURL: String
    var lastOAuthAt: Date?
    var lastWebhookAt: Date?
    var lastErrorMessage: String

    static let empty = SquareMerchantConnection(
        status: .disconnected,
        merchantID: "",
        merchantName: "",
        locationIDs: [],
        scopes: [],
        capabilities: [],
        backendModeEnabled: true,
        cmsSyncEnabled: false,
        backendBaseURL: "",
        lastOAuthAt: nil,
        lastWebhookAt: nil,
        lastErrorMessage: ""
    )

    var merchantDisplayName: String {
        merchantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Square merchant" : merchantName
    }

    var hasBackendBaseURL: Bool {
        !backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSyncCustomers: Bool {
        status == .connected &&
        cmsSyncEnabled &&
        hasCapability(.customers) &&
        backendModeEnabled &&
        hasBackendBaseURL
    }

    var canSyncOrders: Bool {
        status == .connected &&
        cmsSyncEnabled &&
        hasCapability(.orders) &&
        backendModeEnabled &&
        hasBackendBaseURL
    }

    func hasCapability(_ capability: SquareCapability) -> Bool {
        capabilities.contains(capability)
    }

    var statusSummary: String {
        switch status {
        case .connected:
            if canSyncCustomers {
                return "\(merchantDisplayName) is connected and ready for CRM sync."
            }
            if !cmsSyncEnabled {
                return "\(merchantDisplayName) is connected, but CMS sync is disabled."
            }
            if !backendModeEnabled || !hasBackendBaseURL {
                return "\(merchantDisplayName) is connected, but the backend proxy is not configured."
            }
            if !hasCapability(.customers) {
                return "\(merchantDisplayName) is connected, but customer permissions are missing."
            }
            return "\(merchantDisplayName) is connected, but not all sync requirements are satisfied."
        case .pending:
            return "Square authorization is in progress."
        case .error:
            return lastErrorMessage.isEmpty ? "Square needs attention before syncing." : lastErrorMessage
        case .disconnected:
            return "Connect a Square seller account before syncing CRM, catalog, orders, or location data."
        }
    }
}

@MainActor
final class SquareIntegrationStore: ObservableObject {
    static let shared = SquareIntegrationStore()

    @Published private(set) var connection: SquareMerchantConnection = .empty

    private let db = Firestore.firestore()
    private let conventionID = "trekli-2026"
    private var listener: ListenerRegistration?

    private init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    var integrationDocument: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("integrations")
            .document("square")
    }

    func refreshFromRemote() async {
        do {
            let snapshot = try await integrationDocument.getDocument()
            connection = Self.makeConnection(from: snapshot)
        } catch {
            connection = .init(
                status: .error,
                merchantID: "",
                merchantName: "",
                locationIDs: [],
                scopes: [],
                capabilities: [],
                backendModeEnabled: true,
                cmsSyncEnabled: false,
                backendBaseURL: "",
                lastOAuthAt: nil,
                lastWebhookAt: nil,
                lastErrorMessage: error.localizedDescription
            )
        }
    }

    func setCMSSyncEnabled(_ isEnabled: Bool) {
        let updatedConnection = SquareMerchantConnection(
            status: connection.status,
            merchantID: connection.merchantID,
            merchantName: connection.merchantName,
            locationIDs: connection.locationIDs,
            scopes: connection.scopes,
            capabilities: connection.capabilities,
            backendModeEnabled: connection.backendModeEnabled,
            cmsSyncEnabled: isEnabled,
            backendBaseURL: connection.backendBaseURL,
            lastOAuthAt: connection.lastOAuthAt,
            lastWebhookAt: connection.lastWebhookAt,
            lastErrorMessage: connection.lastErrorMessage
        )
        connection = updatedConnection

        integrationDocument.setData(
            [
                "cmsSyncEnabled": isEnabled,
                "updatedAt": Timestamp(date: .now)
            ],
            merge: true
        ) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.connection = SquareMerchantConnection(
                        status: .error,
                        merchantID: updatedConnection.merchantID,
                        merchantName: updatedConnection.merchantName,
                        locationIDs: updatedConnection.locationIDs,
                        scopes: updatedConnection.scopes,
                        capabilities: updatedConnection.capabilities,
                        backendModeEnabled: updatedConnection.backendModeEnabled,
                        cmsSyncEnabled: updatedConnection.cmsSyncEnabled,
                        backendBaseURL: updatedConnection.backendBaseURL,
                        lastOAuthAt: updatedConnection.lastOAuthAt,
                        lastWebhookAt: updatedConnection.lastWebhookAt,
                        lastErrorMessage: "Failed to update Square integration: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func startListening() {
        listener?.remove()
        listener = integrationDocument.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.connection = .init(
                        status: .error,
                        merchantID: "",
                        merchantName: "",
                        locationIDs: [],
                        scopes: [],
                        capabilities: [],
                        backendModeEnabled: true,
                        cmsSyncEnabled: false,
                        backendBaseURL: "",
                        lastOAuthAt: nil,
                        lastWebhookAt: nil,
                        lastErrorMessage: "Firestore Square integration error: \(error.localizedDescription)"
                    )
                    return
                }

                self.connection = Self.makeConnection(from: snapshot)
            }
        }
    }

    private static func makeConnection(from snapshot: DocumentSnapshot?) -> SquareMerchantConnection {
        guard let data = snapshot?.data() else {
            return .empty
        }

        let status = SquareConnectionStatus(rawValue: (data["status"] as? String ?? "").lowercased()) ?? .disconnected
        let merchantID = data["merchantID"] as? String ?? data["merchantId"] as? String ?? ""
        let merchantName = data["merchantName"] as? String ?? ""
        let locationIDs = data["locationIDs"] as? [String] ?? data["locationIds"] as? [String] ?? []
        let scopes = data["scopes"] as? [String] ?? []
        let capabilities = (data["capabilities"] as? [String] ?? [])
            .compactMap { SquareCapability(rawValue: $0.lowercased()) }
        let backendModeEnabled = data["backendModeEnabled"] as? Bool ?? true
        let cmsSyncEnabled = data["cmsSyncEnabled"] as? Bool ?? false
        let backendBaseURL = data["backendBaseURL"] as? String ?? ""
        let lastOAuthAt = (data["lastOAuthAt"] as? Timestamp)?.dateValue()
        let lastWebhookAt = (data["lastWebhookAt"] as? Timestamp)?.dateValue()
        let lastErrorMessage = data["lastErrorMessage"] as? String ?? ""

        return SquareMerchantConnection(
            status: status,
            merchantID: merchantID,
            merchantName: merchantName,
            locationIDs: locationIDs,
            scopes: scopes,
            capabilities: capabilities,
            backendModeEnabled: backendModeEnabled,
            cmsSyncEnabled: cmsSyncEnabled,
            backendBaseURL: backendBaseURL,
            lastOAuthAt: lastOAuthAt,
            lastWebhookAt: lastWebhookAt,
            lastErrorMessage: lastErrorMessage
        )
    }
}
