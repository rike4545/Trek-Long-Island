// Copyright Bryan Carroll. All rights reserved.
//
//  SquareCustomersClient.swift
//  Trek Long Island
//
//  Lightweight Square Customers API integration for CRM contact sync.
//

import Foundation

actor SquareCustomersClient {
    static let shared = SquareCustomersClient()
    static var isDirectAccessEnabledForDebug: Bool {
        let config = Configuration.fromInfoPlist()
        return config.enabled && config.directAccessEnabled
    }

    enum Environment: String {
        case sandbox
        case production

        var baseURL: URL {
            switch self {
            case .sandbox:
                return URL(string: "https://connect.squareupsandbox.com")!
            case .production:
                return URL(string: "https://connect.squareup.com")!
            }
        }
    }

    struct Configuration {
        let enabled: Bool
        let environment: Environment
        let accessToken: String
        let apiVersion: String
        let backendBaseURL: String
        let directAccessEnabled: Bool

        static func fromInfoPlist() -> Configuration {
            let enabled = (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_ENABLED") as? Bool) ?? false

            let envRaw = (
                (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_ENVIRONMENT") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            ) ?? "sandbox"
            let environment = Environment(rawValue: envRaw) ?? .sandbox

            let accessToken = (
                (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_ACCESS_TOKEN") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            ) ?? ""

            let apiVersion = (
                (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_API_VERSION") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            ) ?? "2026-01-21"

            let backendBaseURL = (
                (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_BACKEND_BASE_URL") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            ) ?? ""

            let directAccessEnabled = (Bundle.main.object(forInfoDictionaryKey: "TLI_SQUARE_DIRECT_ACCESS_ENABLED") as? Bool) ?? false

            return Configuration(
                enabled: enabled,
                environment: environment,
                accessToken: accessToken,
                apiVersion: apiVersion,
                backendBaseURL: backendBaseURL,
                directAccessEnabled: directAccessEnabled
            )
        }
    }

    enum SyncAction: String {
        case created
        case updated
    }

    struct SyncResult {
        let customerID: String
        let action: SyncAction
    }

    enum SquareCustomersError: LocalizedError {
        case disabled
        case missingAccessToken
        case missingBackendBaseURL
        case backendUnavailable
        case invalidResponse
        case apiStatus(Int, String)

        var errorDescription: String? {
            switch self {
            case .disabled:
                return "Square sync is disabled. Enable the Square integration only after the backend proxy is configured."
            case .missingAccessToken:
                return "Square direct-access token is missing. This mode should be used only for local development."
            case .missingBackendBaseURL:
                return "Square backend base URL is missing. Configure TLI_SQUARE_BACKEND_BASE_URL for Marketplace-safe sync."
            case .backendUnavailable:
                return "Square is not connected through the backend yet. Complete seller OAuth and backend setup first."
            case .invalidResponse:
                return "Square returned an unexpected response."
            case .apiStatus(let status, let message):
                return "Square API error (\(status)): \(message)"
            }
        }
    }

    private let config: Configuration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: Configuration = .fromInfoPlist(), session: URLSession = .shared) {
        self.config = config
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func sync(contact: CRMContact) async throws -> SyncResult {
        guard config.enabled else {
            throw SquareCustomersError.disabled
        }

        if !config.backendBaseURL.isEmpty {
            return try await syncViaBackend(contact: contact)
        }

        guard config.directAccessEnabled else {
            throw SquareCustomersError.backendUnavailable
        }

        guard !config.accessToken.isEmpty else {
            throw SquareCustomersError.missingAccessToken
        }

        // Keep a stable reference between app CRM contact records and Square customers.
        let referenceID = "tli.crm.\(contact.id.uuidString.lowercased())"

        if let squareCustomerID = contact.squareCustomerID,
           !squareCustomerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let updated = try await updateCustomer(
                customerID: squareCustomerID,
                from: contact,
                referenceID: referenceID
            )
            return SyncResult(customerID: updated.id, action: .updated)
        }

        if let existing = try await searchCustomer(byReferenceID: referenceID) {
            let updated = try await updateCustomer(
                customerID: existing.id,
                from: contact,
                referenceID: referenceID
            )
            return SyncResult(customerID: updated.id, action: .updated)
        }

        if let emailCustomer = try await searchCustomer(byEmail: contact.email) {
            let updated = try await updateCustomer(
                customerID: emailCustomer.id,
                from: contact,
                referenceID: referenceID
            )
            return SyncResult(customerID: updated.id, action: .updated)
        }

        if let phoneCustomer = try await searchCustomer(byPhone: contact.phone) {
            let updated = try await updateCustomer(
                customerID: phoneCustomer.id,
                from: contact,
                referenceID: referenceID
            )
            return SyncResult(customerID: updated.id, action: .updated)
        }

        let created = try await createCustomer(from: contact, referenceID: referenceID)
        return SyncResult(customerID: created.id, action: .created)
    }

    private func syncViaBackend(contact: CRMContact) async throws -> SyncResult {
        guard let baseURL = URL(string: config.backendBaseURL), !config.backendBaseURL.isEmpty else {
            throw SquareCustomersError.missingBackendBaseURL
        }

        let url: URL
        if config.backendBaseURL.contains("squareCRMCustomerSync") {
            url = baseURL
        } else {
            url = baseURL.appendingPathComponent("squareCRMCustomerSync")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(
            SquareCRMContactSyncRequest(
                conventionID: TLIEventInfo.current.conventionID,
                contact: SquareCRMContactPayload(contact: contact)
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SquareCustomersError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = parseAPIErrorMessage(from: data)
            throw SquareCustomersError.apiStatus(http.statusCode, message)
        }

        let decoded = try decoder.decode(SquareCRMContactSyncResponse.self, from: data)
        let action = SyncAction(rawValue: decoded.action.lowercased()) ?? .updated
        return SyncResult(customerID: decoded.customerID, action: action)
    }

    // MARK: - API

    private func searchCustomer(byReferenceID referenceID: String) async throws -> SquareCustomer? {
        let filter = CustomerSearchFilter(referenceID: ExactMatch(exact: referenceID))
        return try await searchCustomer(with: filter)
    }

    private func searchCustomer(byEmail email: String) async throws -> SquareCustomer? {
        let clean = cleaned(email)
        guard !clean.isEmpty else { return nil }
        let filter = CustomerSearchFilter(emailAddress: ExactMatch(exact: clean))
        return try await searchCustomer(with: filter)
    }

    private func searchCustomer(byPhone phone: String) async throws -> SquareCustomer? {
        let clean = cleaned(phone)
        guard !clean.isEmpty else { return nil }
        let filter = CustomerSearchFilter(phoneNumber: ExactMatch(exact: clean))
        return try await searchCustomer(with: filter)
    }

    private func searchCustomer(with filter: CustomerSearchFilter) async throws -> SquareCustomer? {
        let requestBody = SearchCustomersRequest(
            limit: 1,
            query: CustomerSearchQuery(filter: filter)
        )

        let response: SearchCustomersResponse = try await send(
            path: "/v2/customers/search",
            method: "POST",
            body: requestBody
        )

        return response.customers?.first
    }

    private func createCustomer(from contact: CRMContact, referenceID: String) async throws -> SquareCustomer {
        let names = splitName(contact.fullName)

        let requestBody = UpsertCustomerRequest(
            givenName: names.given,
            familyName: names.family,
            companyName: emptyToNil(contact.organization),
            emailAddress: emptyToNil(contact.email),
            phoneNumber: emptyToNil(contact.phone),
            note: emptyToNil(contact.notes),
            referenceID: referenceID,
            idempotencyKey: UUID().uuidString
        )

        let response: UpsertCustomerResponse = try await send(
            path: "/v2/customers",
            method: "POST",
            body: requestBody
        )

        guard let customer = response.customer else {
            throw SquareCustomersError.invalidResponse
        }

        return customer
    }

    private func updateCustomer(customerID: String, from contact: CRMContact, referenceID: String) async throws -> SquareCustomer {
        let names = splitName(contact.fullName)

        let requestBody = UpsertCustomerRequest(
            givenName: names.given,
            familyName: names.family,
            companyName: emptyToNil(contact.organization),
            emailAddress: emptyToNil(contact.email),
            phoneNumber: emptyToNil(contact.phone),
            note: emptyToNil(contact.notes),
            referenceID: referenceID,
            idempotencyKey: nil
        )

        let encodedID = customerID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? customerID

        let response: UpsertCustomerResponse = try await send(
            path: "/v2/customers/\(encodedID)",
            method: "PUT",
            body: requestBody
        )

        guard let customer = response.customer else {
            throw SquareCustomersError.invalidResponse
        }

        return customer
    }

    // MARK: - Networking

    private func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        body: RequestBody
    ) async throws -> ResponseBody {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = config.environment.baseURL.appendingPathComponent(normalizedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(config.apiVersion, forHTTPHeaderField: "Square-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SquareCustomersError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = parseAPIErrorMessage(from: data)
            throw SquareCustomersError.apiStatus(http.statusCode, message)
        }

        return try decoder.decode(ResponseBody.self, from: data)
    }

    private func parseAPIErrorMessage(from data: Data) -> String {
        guard let decoded = try? decoder.decode(SquareAPIErrorResponse.self, from: data),
              let first = decoded.errors.first else {
            return "Unknown error"
        }

        if let detail = first.detail, !detail.isEmpty {
            return detail
        }
        return first.code
    }

    // MARK: - Helpers

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func emptyToNil(_ value: String) -> String? {
        let clean = cleaned(value)
        return clean.isEmpty ? nil : clean
    }

    private func splitName(_ fullName: String) -> (given: String?, family: String?) {
        let parts = cleaned(fullName)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        switch parts.count {
        case 0:
            return (nil, nil)
        case 1:
            return (parts[0], nil)
        default:
            return (parts.first, parts.dropFirst().joined(separator: " "))
        }
    }
}

// MARK: - DTOs

private struct ExactMatch: Codable {
    let exact: String
}

private struct CustomerSearchFilter: Codable {
    let referenceID: ExactMatch?
    let emailAddress: ExactMatch?
    let phoneNumber: ExactMatch?

    init(referenceID: ExactMatch? = nil, emailAddress: ExactMatch? = nil, phoneNumber: ExactMatch? = nil) {
        self.referenceID = referenceID
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
    }

    enum CodingKeys: String, CodingKey {
        case referenceID = "reference_id"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
    }
}

private struct CustomerSearchQuery: Codable {
    let filter: CustomerSearchFilter
}

private struct SearchCustomersRequest: Codable {
    let limit: Int
    let query: CustomerSearchQuery
}

private struct SearchCustomersResponse: Codable {
    let customers: [SquareCustomer]?
}

private struct UpsertCustomerRequest: Codable {
    let givenName: String?
    let familyName: String?
    let companyName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let note: String?
    let referenceID: String?
    let idempotencyKey: String?

    enum CodingKeys: String, CodingKey {
        case givenName = "given_name"
        case familyName = "family_name"
        case companyName = "company_name"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
        case note
        case referenceID = "reference_id"
        case idempotencyKey = "idempotency_key"
    }
}

private struct UpsertCustomerResponse: Codable {
    let customer: SquareCustomer?
}

private struct SquareCustomer: Codable {
    let id: String
    let referenceID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case referenceID = "reference_id"
    }
}

private struct SquareAPIErrorResponse: Codable {
    let errors: [SquareAPIError]
}

private struct SquareAPIError: Codable {
    let category: String
    let code: String
    let detail: String?
}
