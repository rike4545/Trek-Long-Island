// Copyright Bryan Carroll. All rights reserved.
//
//  SquareTicketOrdersClient.swift
//  Trek Long Island
//
//  Backend proxy for importing Square ticket orders into Firestore-backed QR ops.
//

import Foundation

actor SquareTicketOrdersClient {
    static let shared = SquareTicketOrdersClient()

    private struct SyncRequest: Encodable {
        let conventionID: String
        let daysBack: Int
    }

    enum TicketSyncError: LocalizedError {
        case disabled
        case missingBackendBaseURL
        case invalidResponse
        case apiStatus(Int, String)

        var errorDescription: String? {
            switch self {
            case .disabled:
                return "Square ticket sync is disabled."
            case .missingBackendBaseURL:
                return "Square backend base URL is missing."
            case .invalidResponse:
                return "Square ticket sync returned an unexpected response."
            case .apiStatus(let status, let message):
                return "Square ticket sync error (\(status)): \(message)"
            }
        }
    }

    struct SyncResult: Decodable {
        let syncedCount: Int
        let syncedDocIDs: [String]
        let daysBack: Int
    }

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let config: SquareCustomersClient.Configuration

    init(
        session: URLSession = .shared,
        config: SquareCustomersClient.Configuration = .fromInfoPlist()
    ) {
        self.session = session
        self.config = config
    }

    func importOrders(daysBack: Int = 30) async throws -> SyncResult {
        guard config.enabled else {
            throw TicketSyncError.disabled
        }

        guard let baseURL = URL(string: config.backendBaseURL), !config.backendBaseURL.isEmpty else {
            throw TicketSyncError.missingBackendBaseURL
        }

        let url: URL
        if config.backendBaseURL.contains("squareTicketOrderSync") {
            url = baseURL
        } else {
            url = baseURL.appendingPathComponent("squareTicketOrderSync")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(
            SyncRequest(
                conventionID: TLIEventInfo.current.conventionID,
                daysBack: max(1, min(daysBack, 90))
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TicketSyncError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let decoded = try? decoder.decode([String: String].self, from: data) {
                message = decoded["error"] ?? "Unknown error"
            } else {
                message = "Unknown error"
            }
            throw TicketSyncError.apiStatus(http.statusCode, message)
        }

        return try decoder.decode(SyncResult.self, from: data)
    }
}
