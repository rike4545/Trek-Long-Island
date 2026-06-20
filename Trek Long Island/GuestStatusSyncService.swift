// Copyright Bryan Carroll. All rights reserved.
//
//  GuestStatusSyncService.swift
//  Trek Long Island
//
//  Firestore-backed propagation of guest status overrides (cancelled / replaced).
//
//  Design notes:
//  • Mirrors the local `GuestStatusStore` shape (keyed by guest.slug) so the two
//    can be merged with a simple precedence rule: remote wins when present,
//    otherwise fall back to the device-local store.
//  • READ is a live snapshot listener so attendees see cancellations without a
//    rebuild. WRITE is gated to master (superAdmin) and only attempted in live
//    backend mode.
//  • FAIL-SAFE: if the Firestore security rule for `guest_status` is not deployed
//    (permission denied) or the backend is in sample mode, this service stays
//    empty and silent, and the app behaves exactly as it did with local-only
//    overrides. Nothing here can break the existing roster flow.
//
//  Firestore path:
//      conventions/{conventionID}/guest_status/{guestSlug}
//
//  Document shape:
//      status:               String   // GuestStatus.rawValue ("cancelled" | "replaced" | "active")
//      note:                 String?  // optional operator note
//      replacementGuestName: String?  // optional replacement name
//      updatedAt:            Timestamp (server time)
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class GuestStatusSyncService: ObservableObject {

    static let shared = GuestStatusSyncService()

    /// Remote overrides keyed by `guest.slug`. Empty when sync is unavailable.
    @Published private(set) var remoteOverrides: [String: GuestStatusOverride] = [:]

    /// Last non-fatal error string, for diagnostics surfaces.
    @Published private(set) var lastError: String?

    /// Whether the live listener is currently attached.
    @Published private(set) var isListening = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasStarted = false

    private init() {}

    // MARK: - Collection

    /// Reads the convention ID from NotificationManager so both stay in sync
    /// when the operator switches conventions (e.g. trekli-2026).
    private var conventionID: String {
        NotificationManager.shared.conventionID
    }

    private var collection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("guest_status")
    }

    // MARK: - Lifecycle

    /// Idempotent. Safe to call from `.task`/`onAppear` repeatedly.
    func start() {
        guard !hasStarted else { return }
        // In sample/offline mode the local GuestStatusStore is the source of truth.
        guard !NotificationManager.shared.isUsingSampleData else { return }
        hasStarted = true
        attachListener()
    }

    /// Re-attach the listener for a new convention document.
    func restartForConventionChange() {
        listener?.remove()
        listener = nil
        isListening = false
        hasStarted = false
        remoteOverrides = [:]
        start()
    }

    private func attachListener() {
        listener?.remove()
        isListening = true

        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.handle(error: error)
                    return
                }

                self.lastError = nil

                guard let docs = snapshot?.documents else {
                    self.remoteOverrides = [:]
                    return
                }

                var parsed: [String: GuestStatusOverride] = [:]
                parsed.reserveCapacity(docs.count)
                for doc in docs {
                    if let override = Self.override(from: doc.data()) {
                        parsed[doc.documentID] = override
                    }
                }
                self.remoteOverrides = parsed
            }
        }
    }

    private func handle(error: Error) {
        let nsError = error as NSError
        let permissionDenied = nsError.domain == FirestoreErrorDomain &&
            nsError.code == FirestoreErrorCode.permissionDenied.rawValue

        if permissionDenied {
            // Rule not deployed / no read access: silently fall back to local-only.
            listener?.remove()
            listener = nil
            isListening = false
            remoteOverrides = [:]
            lastError = nil
        } else {
            lastError = "Guest status sync error: \(error.localizedDescription)"
        }
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Read

    func override(for guest: Guest) -> GuestStatusOverride? {
        remoteOverrides[guest.slug]
    }

    // MARK: - Master writes

    /// Publish a cancellation/replacement to all devices. Master-only, live-only.
    /// Returns false (no-op) when not permitted; callers should still write the
    /// local store so the operator's own device updates instantly.
    @discardableResult
    func setStatus(
        for guest: Guest,
        status: GuestStatus,
        note: String?,
        replacementGuestName: String?
    ) -> Bool {
        guard NotificationManager.shared.isSuperAdminUnlocked,
              !NotificationManager.shared.isUsingSampleData else {
            return false
        }

        let data: [String: Any] = [
            "status": status.rawValue,
            "note": note ?? NSNull(),
            "replacementGuestName": replacementGuestName ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        collection.document(guest.slug).setData(data, merge: true) { [weak self] error in
            guard let self, let error else { return }
            Task { @MainActor in
                self.lastError = "Failed to sync guest status: \(error.localizedDescription)"
            }
        }
        return true
    }

    /// Remove a published override (restore to active). Master-only, live-only.
    @discardableResult
    func clearStatus(for guest: Guest) -> Bool {
        guard NotificationManager.shared.isSuperAdminUnlocked,
              !NotificationManager.shared.isUsingSampleData else {
            return false
        }

        collection.document(guest.slug).delete { [weak self] error in
            guard let self, let error else { return }
            Task { @MainActor in
                self.lastError = "Failed to clear synced guest status: \(error.localizedDescription)"
            }
        }
        return true
    }

    // MARK: - Parsing

    private static func override(from data: [String: Any]) -> GuestStatusOverride? {
        guard let statusRaw = data["status"] as? String,
              let status = GuestStatus(rawValue: statusRaw) else {
            return nil
        }

        let note = (data["note"] as? String)
        let replacement = (data["replacementGuestName"] as? String)

        let updatedAt: Date
        if let ts = data["updatedAt"] as? Timestamp {
            updatedAt = ts.dateValue()
        } else {
            updatedAt = Date()
        }

        return GuestStatusOverride(
            status: status,
            note: note,
            replacementGuestName: replacement,
            updatedAt: updatedAt
        )
    }
}
