// Copyright Bryan Carroll. All rights reserved.
//
//  TicketOpsStore.swift
//  Trek Long Island
//
//  Operator controls for QR ticket generation, scanning validation,
//  and attendance tallies by order.
//

import Foundation
import FirebaseFirestore

struct TicketOrderRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var ticketCount: Int
    var orderNumber: String
    var scannedCount: Int
    var issuer: String
    var createdAt: Date
    var updatedAt: Date
    var lastScannedAt: Date?
    var source: String
    var externalOrderID: String?
    var externalPaymentID: String?
    var orderState: String?
    var lastSquareSyncAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        ticketCount: Int,
        orderNumber: String,
        scannedCount: Int = 0,
        issuer: String = TicketQRPayload.issuerName,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastScannedAt: Date? = nil,
        source: String = "manual",
        externalOrderID: String? = nil,
        externalPaymentID: String? = nil,
        orderState: String? = nil,
        lastSquareSyncAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.ticketCount = max(1, ticketCount)
        self.orderNumber = orderNumber
        self.scannedCount = max(0, scannedCount)
        self.issuer = issuer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastScannedAt = lastScannedAt
        self.source = source
        self.externalOrderID = externalOrderID
        self.externalPaymentID = externalPaymentID
        self.orderState = orderState
        self.lastSquareSyncAt = lastSquareSyncAt
    }
}

struct TicketQRPayload: Codable, Hashable {
    static let issuerName = "Trek Long Island Corp."
    static let version = 1

    let issuer: String
    let orderNumber: String
    let name: String
    let ticketCount: Int
    let issuedAt: Date
    let version: Int
}

struct TicketTallySummary {
    let orderCount: Int
    let totalPurchased: Int
    let totalScanned: Int

    var totalRemaining: Int {
        max(0, totalPurchased - totalScanned)
    }
}

enum TicketScanOutcome: Equatable {
    case accepted(record: TicketOrderRecord)
    case noRemaining(record: TicketOrderRecord)
    case orderNotFound(orderNumber: String)
    case invalidPayload
    case operatorDisabled
}

@MainActor
final class TicketOpsStore: ObservableObject {
    static let shared = TicketOpsStore()

    @Published private(set) var orders: [TicketOrderRecord] = []
    @Published private(set) var isTicketGenerationEnabled: Bool = false
    @Published private(set) var isTicketScanningEnabled: Bool = false
    @Published private(set) var lastSquareImportMessage: String?

    private let ordersKey = "TLI.TicketOps.orders.v1"
    private let generationEnabledKey = "TLI.TicketOps.generationEnabled.v1"
    private let scanningEnabledKey = "TLI.TicketOps.scanningEnabled.v1"
    private let conventionID = TLIEventInfo.current.conventionID
    private let analytics = TLIAnalyticsStore.shared
    private let db = Firestore.firestore()
    private var ordersListener: ListenerRegistration?
    private var configListener: ListenerRegistration?

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        load()
        startListening()
    }

    deinit {
        ordersListener?.remove()
        configListener?.remove()
    }

    var tally: TicketTallySummary {
        let purchased = orders.reduce(0) { $0 + $1.ticketCount }
        let scanned = orders.reduce(0) { $0 + $1.scannedCount }
        return TicketTallySummary(orderCount: orders.count, totalPurchased: purchased, totalScanned: scanned)
    }

    func setTicketGenerationEnabled(_ enabled: Bool) {
        isTicketGenerationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: generationEnabledKey)
        syncConfig()
        analytics.track(
            name: "ticket_generation_toggled",
            domain: "tickets",
            actor: "staff",
            metadata: ["enabled": enabled ? "true" : "false"]
        )
    }

    func setTicketScanningEnabled(_ enabled: Bool) {
        isTicketScanningEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: scanningEnabledKey)
        syncConfig()
        analytics.track(
            name: "ticket_scanning_toggled",
            domain: "tickets",
            actor: "staff",
            metadata: ["enabled": enabled ? "true" : "false"]
        )
    }

    func upsertOrder(name: String, ticketCount: Int, orderNumber: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOrder = canonicalOrder(orderNumber)
        guard !cleanName.isEmpty, !cleanOrder.isEmpty else { return }

        let isUpdate = orders.contains(where: { canonicalOrder($0.orderNumber) == cleanOrder })
        if let index = orders.firstIndex(where: { canonicalOrder($0.orderNumber) == cleanOrder }) {
            let existing = orders[index]
            orders[index] = TicketOrderRecord(
                id: existing.id,
                name: cleanName,
                ticketCount: max(1, ticketCount),
                orderNumber: cleanOrder,
                scannedCount: min(existing.scannedCount, max(1, ticketCount)),
                issuer: TicketQRPayload.issuerName,
                createdAt: existing.createdAt,
                updatedAt: .now,
                lastScannedAt: existing.lastScannedAt,
                source: existing.source,
                externalOrderID: existing.externalOrderID,
                externalPaymentID: existing.externalPaymentID,
                orderState: existing.orderState,
                lastSquareSyncAt: existing.lastSquareSyncAt
            )
        } else {
            orders.insert(
                TicketOrderRecord(
                    name: cleanName,
                    ticketCount: max(1, ticketCount),
                    orderNumber: cleanOrder
                ),
                at: 0
            )
        }
        save()
        syncOrder(orders.first(where: { canonicalOrder($0.orderNumber) == cleanOrder }))
        analytics.track(
            name: isUpdate ? "ticket_order_updated" : "ticket_order_created",
            domain: "tickets",
            actor: "staff",
            value: Double(max(1, ticketCount)),
            metadata: ["order_number": cleanOrder.lowercased()]
        )
    }

    func importSquareOrders(daysBack: Int = 30) async {
        do {
            let result = try await SquareTicketOrdersClient.shared.importOrders(daysBack: daysBack)
            lastSquareImportMessage = result.syncedCount == 0
                ? "No Square ticket orders matched the current sync filters."
                : "Imported \(result.syncedCount) Square ticket order\(result.syncedCount == 1 ? "" : "s")."
            analytics.track(
                name: "ticket_square_import_completed",
                domain: "tickets",
                actor: "staff",
                value: Double(result.syncedCount),
                metadata: ["days_back": "\(result.daysBack)"]
            )
        } catch {
            lastSquareImportMessage = error.localizedDescription
            analytics.track(
                name: "ticket_square_import_failed",
                domain: "tickets",
                actor: "staff",
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    func removeOrder(id: UUID) {
        guard let existing = orders.first(where: { $0.id == id }) else { return }
        orders.removeAll(where: { $0.id == id })
        save()
        deleteOrder(existing)
        analytics.track(
            name: "ticket_order_removed",
            domain: "tickets",
            actor: "staff",
            metadata: ["order_id": id.uuidString.lowercased()]
        )
    }

    func payloadString(forOrderNumber orderNumber: String) -> String? {
        let key = canonicalOrder(orderNumber)
        guard let record = orders.first(where: { canonicalOrder($0.orderNumber) == key }) else { return nil }
        let payload = TicketQRPayload(
            issuer: TicketQRPayload.issuerName,
            orderNumber: record.orderNumber,
            name: record.name,
            ticketCount: record.ticketCount,
            issuedAt: .now,
            version: TicketQRPayload.version
        )
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }

    func scan(payloadString: String) -> TicketScanOutcome {
        guard isTicketScanningEnabled else {
            analytics.track(
                name: "ticket_scan_denied",
                domain: "tickets",
                actor: "staff",
                metadata: ["status": "disabled"]
            )
            return .operatorDisabled
        }
        guard let payload = decodePayload(payloadString),
              payload.issuer == TicketQRPayload.issuerName else {
            analytics.track(
                name: "ticket_scan_failed",
                domain: "tickets",
                actor: "staff",
                metadata: ["status": "invalid_payload"]
            )
            return .invalidPayload
        }

        let orderKey = canonicalOrder(payload.orderNumber)
        guard let index = orders.firstIndex(where: { canonicalOrder($0.orderNumber) == orderKey }) else {
            analytics.track(
                name: "ticket_scan_failed",
                domain: "tickets",
                actor: "staff",
                metadata: ["status": "order_not_found"]
            )
            return .orderNotFound(orderNumber: payload.orderNumber)
        }

        if orders[index].scannedCount >= orders[index].ticketCount {
            analytics.track(
                name: "ticket_scan_rejected",
                domain: "tickets",
                actor: "staff",
                metadata: ["status": "no_remaining"]
            )
            return .noRemaining(record: orders[index])
        }

        orders[index].scannedCount += 1
        orders[index].updatedAt = .now
        orders[index].lastScannedAt = .now
        save()
        syncOrder(orders[index])
        analytics.track(
            name: "ticket_scan_accepted",
            domain: "tickets",
            actor: "staff",
            metadata: ["order_number": orderKey.lowercased()]
        )
        return .accepted(record: orders[index])
    }

    func decodePayload(_ text: String) -> TicketQRPayload? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? decoder.decode(TicketQRPayload.self, from: data)
    }

    private func canonicalOrder(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func load() {
        let defaults = UserDefaults.standard
        isTicketGenerationEnabled = defaults.bool(forKey: generationEnabledKey)
        isTicketScanningEnabled = defaults.bool(forKey: scanningEnabledKey)
        if let data = defaults.data(forKey: ordersKey),
           let decoded = try? decoder.decode([TicketOrderRecord].self, from: data) {
            orders = decoded.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            orders = []
        }
    }

    private func save() {
        if let data = try? encoder.encode(orders.sorted { $0.updatedAt > $1.updatedAt }) {
            UserDefaults.standard.set(data, forKey: ordersKey)
        }
    }

    private var ordersCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("ticket_orders")
    }

    private var configDocument: DocumentReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("tickets")
            .document("config")
    }

    private func startListening() {
        startListeningOrders()
        startListeningConfig()
    }

    private func startListeningOrders() {
        ordersListener?.remove()
        ordersListener = ordersCollection
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        print("❌ Firestore ticket orders error: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else {
                        self.orders = []
                        self.save()
                        return
                    }

                    self.orders = docs.compactMap(Self.makeOrder(from:))
                    self.save()
                }
            }
    }

    private func startListeningConfig() {
        configListener?.remove()
        configListener = configDocument.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("❌ Firestore ticket config error: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else { return }
                if let enabled = data["generationEnabled"] as? Bool {
                    self.isTicketGenerationEnabled = enabled
                    UserDefaults.standard.set(enabled, forKey: self.generationEnabledKey)
                }
                if let enabled = data["scanningEnabled"] as? Bool {
                    self.isTicketScanningEnabled = enabled
                    UserDefaults.standard.set(enabled, forKey: self.scanningEnabledKey)
                }
            }
        }
    }

    private func syncOrder(_ order: TicketOrderRecord?) {
        guard let order else { return }
        ordersCollection.document(order.id.uuidString.lowercased()).setData(Self.makeFirestoreData(from: order), merge: true) { error in
            if let error {
                print("❌ Firestore ticket order sync error: \(error.localizedDescription)")
            }
        }
    }

    private func deleteOrder(_ order: TicketOrderRecord) {
        ordersCollection.document(order.id.uuidString.lowercased()).delete { error in
            if let error {
                print("❌ Firestore ticket order delete error: \(error.localizedDescription)")
            }
        }
    }

    private func syncConfig() {
        configDocument.setData(
            [
                "generationEnabled": isTicketGenerationEnabled,
                "scanningEnabled": isTicketScanningEnabled
            ],
            merge: true
        ) { error in
            if let error {
                print("❌ Firestore ticket config sync error: \(error.localizedDescription)")
            }
        }
    }

    private static func makeFirestoreData(from order: TicketOrderRecord) -> [String: Any] {
        [
            "id": order.id.uuidString.lowercased(),
            "name": order.name,
            "ticketCount": order.ticketCount,
            "orderNumber": order.orderNumber,
            "scannedCount": order.scannedCount,
            "issuer": order.issuer,
            "createdAt": Timestamp(date: order.createdAt),
            "updatedAt": Timestamp(date: order.updatedAt),
            "lastScannedAt": order.lastScannedAt.map(Timestamp.init(date:)) as Any,
            "source": order.source,
            "externalOrderID": order.externalOrderID as Any,
            "externalPaymentID": order.externalPaymentID as Any,
            "orderState": order.orderState as Any,
            "lastSquareSyncAt": order.lastSquareSyncAt.map(Timestamp.init(date:)) as Any
        ]
    }

    private static func makeOrder(from doc: QueryDocumentSnapshot) -> TicketOrderRecord? {
        let data = doc.data()
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let ticketCount = data["ticketCount"] as? Int,
            let orderNumber = data["orderNumber"] as? String
        else {
            return nil
        }

        let scannedCount = max(0, data["scannedCount"] as? Int ?? 0)
        let issuer = data["issuer"] as? String ?? TicketQRPayload.issuerName
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
        let lastScannedAt = (data["lastScannedAt"] as? Timestamp)?.dateValue()
        let source = data["source"] as? String ?? "manual"
        let externalOrderID = data["externalOrderID"] as? String
        let externalPaymentID = data["externalPaymentID"] as? String
        let orderState = data["orderState"] as? String
        let lastSquareSyncAt = (data["lastSquareSyncAt"] as? Timestamp)?.dateValue()

        return TicketOrderRecord(
            id: id,
            name: name,
            ticketCount: max(1, ticketCount),
            orderNumber: orderNumber,
            scannedCount: scannedCount,
            issuer: issuer,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastScannedAt: lastScannedAt,
            source: source,
            externalOrderID: externalOrderID,
            externalPaymentID: externalPaymentID,
            orderState: orderState,
            lastSquareSyncAt: lastSquareSyncAt
        )
    }
}
