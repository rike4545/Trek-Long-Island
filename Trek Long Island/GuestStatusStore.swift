// Copyright Bryan Carroll. All rights reserved.
//
//  GuestStatusStore.swift
//  Trek Long Island
//
//  Local operator overrides for guest roster status updates.
//

import Foundation

struct GuestStatusOverride: Codable, Equatable {
    let status: GuestStatus
    let note: String?
    let replacementGuestName: String?
    let updatedAt: Date
}

@MainActor
final class GuestStatusStore: ObservableObject {
    static let shared = GuestStatusStore()

    @Published private(set) var overrides: [String: GuestStatusOverride] = [:]

    private let defaultsKey = "TLI.Guests.statusOverrides"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        load()
    }

    func override(for guest: Guest) -> GuestStatusOverride? {
        overrides[guest.slug]
    }

    func resolvedGuest(_ guest: Guest) -> Guest {
        guard let override = overrides[guest.slug] else { return guest }
        return guest.applying(statusOverride: override)
    }

    func setStatus(
        for guest: Guest,
        status: GuestStatus,
        note: String? = nil,
        replacementGuestName: String? = nil
    ) {
        overrides[guest.slug] = GuestStatusOverride(
            status: status,
            note: sanitized(note),
            replacementGuestName: sanitized(replacementGuestName),
            updatedAt: .now
        )
        save()
    }

    func clearStatus(for guest: Guest) {
        overrides.removeValue(forKey: guest.slug)
        save()
    }

    private func sanitized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        guard let decoded = try? decoder.decode([String: GuestStatusOverride].self, from: data) else { return }
        overrides = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(overrides) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
