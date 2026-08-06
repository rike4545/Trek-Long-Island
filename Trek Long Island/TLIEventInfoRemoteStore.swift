// Copyright Bryan Carroll. All rights reserved.
//
//  TLIEventInfoRemoteStore.swift
//  Trek Long Island
//
//  Firestore-backed override for `TLIEventInfo`, so dates, venue, and hours can be
//  corrected without an App Store submission.
//
//  Design notes (mirrors GuestStatusSyncService deliberately):
//  • READ is a live snapshot listener, so a venue change reaches attendees mid-cycle.
//  • There is no write path here. This document is edited from the Firebase console
//    by the operator; the app is a pure consumer. Nothing in the client should be
//    able to rewrite what convention it belongs to.
//  • FAIL-SAFE: on permission denied, sample mode, malformed payload, or no network,
//    this store stays silent and `TLIEventInfo.current` keeps returning the compiled-in
//    `.bundled` values. A broken remote document can never blank out the venue.
//  • The last good payload is cached to UserDefaults so it applies at next cold launch
//    before Firestore connects.
//
//  Firestore path (deliberately NOT nested under conventions/{id} — this document is
//  what tells the app which convention it belongs to in the first place):
//      app_config/event_info
//
//  Document shape — every field optional, missing fields fall back to bundled:
//      conventionID:            String   // "trekli-2027"
//      pushTopicStem:           String   // "trekli_2027"
//      year:                    Int
//      displayRange:            String   // "June 11–13, 2027"
//      startMonth:              Int
//      startDay:                Int
//      endDay:                  Int
//      venue:                   Map      { name, street, city, state, postalCode,
//                                          phone, latitude, longitude }
//      conventionHours:         [Map]    { day, hours, note? }
//      vendorHallHours:         [Map]    { day, hours, note? }
//      hotelBookingURL:         String
//      hotelGroupRateDeadline:  String
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class TLIEventInfoRemoteStore: ObservableObject {

    static let shared = TLIEventInfoRemoteStore()

    /// The effective event info: remote override when valid, otherwise bundled.
    @Published private(set) var info: TLIEventInfo = .current

    /// True once a remote document has been successfully applied this session.
    @Published private(set) var isUsingRemoteOverride = false

    /// Last non-fatal error string, for the diagnostics surface.
    @Published private(set) var lastError: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasStarted = false

    private init() {}

    private var document: DocumentReference {
        db.collection("app_config").document("event_info")
    }

    // MARK: - Lifecycle

    /// Idempotent. Safe to call from `.task`/`onAppear` repeatedly.
    func start() {
        guard !hasStarted else { return }
        guard !NotificationManager.shared.isUsingSampleData else { return }
        hasStarted = true
        attachListener()
    }

    private func attachListener() {
        listener?.remove()

        listener = document.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.handle(error: error)
                    return
                }

                guard let data = snapshot?.data(), !data.isEmpty else {
                    // Document absent: bundled values are the intended source of truth.
                    self.lastError = nil
                    return
                }

                guard let parsed = Self.eventInfo(from: data) else {
                    // Malformed payload: keep whatever we are already showing.
                    self.lastError = "Event info document could not be parsed; using bundled values."
                    return
                }

                self.lastError = nil
                self.isUsingRemoteOverride = true
                TLIEventInfo.cacheRemoteOverride(parsed)
                self.info = parsed
            }
        }
    }

    private func handle(error: Error) {
        let nsError = error as NSError
        let permissionDenied = nsError.domain == FirestoreErrorDomain &&
            nsError.code == FirestoreErrorCode.permissionDenied.rawValue

        if permissionDenied {
            // Rule not deployed / no read access: fall back to bundled, silently.
            listener?.remove()
            listener = nil
            lastError = nil
        } else {
            lastError = "Event info sync error: \(error.localizedDescription)"
        }
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Parsing

    /// Field-by-field merge over `.bundled`, so a partial document (say, only a
    /// corrected venue phone number) is valid and everything else stays put.
    private static func eventInfo(from data: [String: Any]) -> TLIEventInfo? {
        var info = TLIEventInfo.bundled

        if let value = data["conventionID"] as? String, !value.isEmpty { info.conventionID = value }
        if let value = data["pushTopicStem"] as? String, !value.isEmpty { info.pushTopicStem = value }
        if let value = data["year"] as? Int { info.year = value }
        if let value = data["displayRange"] as? String, !value.isEmpty { info.displayRange = value }
        if let value = data["startMonth"] as? Int, (1...12).contains(value) { info.startMonth = value }
        if let value = data["startDay"] as? Int, (1...31).contains(value) { info.startDay = value }
        if let value = data["endDay"] as? Int, (1...31).contains(value) { info.endDay = value }

        if let venueData = data["venue"] as? [String: Any] {
            var venue = info.venue
            if let value = venueData["name"] as? String, !value.isEmpty { venue.name = value }
            if let value = venueData["street"] as? String, !value.isEmpty { venue.street = value }
            if let value = venueData["city"] as? String, !value.isEmpty { venue.city = value }
            if let value = venueData["state"] as? String, !value.isEmpty { venue.state = value }
            if let value = venueData["postalCode"] as? String, !value.isEmpty { venue.postalCode = value }
            if let value = venueData["phone"] as? String, !value.isEmpty { venue.phone = value }
            if let value = venueData["latitude"] as? Double, (-90...90).contains(value) { venue.latitude = value }
            if let value = venueData["longitude"] as? Double, (-180...180).contains(value) { venue.longitude = value }
            info.venue = venue
        }

        if let hours = hoursList(from: data["conventionHours"]), !hours.isEmpty {
            info.conventionHours = hours
        }
        if let hours = hoursList(from: data["vendorHallHours"]), !hours.isEmpty {
            info.vendorHallHours = hours
        }

        if let value = data["hotelBookingURL"] as? String, !value.isEmpty {
            info.hotelBookingURLString = value
        }
        if let value = data["hotelGroupRateDeadline"] as? String, !value.isEmpty {
            info.hotelGroupRateDeadline = value
        }
        if let value = data["isGuestRosterAnnounced"] as? Bool {
            info.isGuestRosterAnnounced = value
        }
        if let value = data["archivedRosterYear"] as? Int {
            info.archivedRosterYear = value
        }
        if let value = data["mailingListURL"] as? String, !value.isEmpty {
            info.mailingListURLString = value
        }

        // Sanity: a range that ends before it starts would break every date derivation.
        guard info.endDay >= info.startDay else { return nil }

        return info
    }

    private static func hoursList(from raw: Any?) -> [TLIEventInfo.DayHours]? {
        guard let array = raw as? [[String: Any]] else { return nil }
        return array.compactMap { entry in
            guard let day = entry["day"] as? String, !day.isEmpty,
                  let hours = entry["hours"] as? String, !hours.isEmpty else {
                return nil
            }
            let note = (entry["note"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return TLIEventInfo.DayHours(day: day, hours: hours, note: note)
        }
    }
}
