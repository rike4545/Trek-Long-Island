// Copyright Bryan Carroll. All rights reserved.
//
//  NotificationManager.swift
//  Trek Long Island
//
//  Unified notifications manager
//  • Live Firestore backend (published + pending queues)
//  • Sample/preview mode (no Firestore, local data only)
//  • Role-based visibility (guest/qvip/public/all vs staff/ops/vendor)
//  • Per-device read/unread tracking + unread badge
//  • FOUR-LEVEL coordinator roles (Firebase-authenticated):
//      - watcher: room status updates only
//      - notifier: can submit notifications
//      - reviewer: can review pending + ops changes
//      - superAdmin: full control
//  • Pending workflow: add → update → approve → discard
//  • Banner + lastIncomingPriority helpers for app-wide alerts
//  • Convention ID switching (trekli-2026, etc.)
//  • 3-minute auto-lock for coordinator levels (accurate remaining-time on restore)
//

import Foundation
import Combine
import CryptoKit
import FirebaseFirestore

@MainActor
final class NotificationManager: ObservableObject {

    // MARK: - Backend Mode

    enum BackendMode {
        /// Live Firestore: listeners + reads/writes.
        case live
        /// Local-only sample data for previews / offline testing.
        case sample
    }

    // MARK: - Admin Levels (four passwords → four levels)

    enum AdminLevel: String {
        case none
        case watcher
        case notifier
        case reviewer
        case superAdmin
    }

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Published state

    /// Notifications visible to the current app user after role gating.
    @Published private(set) var notifications: [RisaNotification] = []

    /// Notifications that are still pending super-admin review.
    @Published private(set) var pendingNotifications: [RisaNotification] = []

    /// Unread count for *visible* notifications (for tab badges, etc.).
    @Published private(set) var unreadCount: Int = 0

    /// Backwards-compatible: any admin level unlocked?
    @Published private(set) var isAdminUnlocked: Bool = false

    /// Current admin level (none / staff / super admin).
    @Published private(set) var adminLevel: AdminLevel = .none

    /// Last backend error message, for surfacing in Settings/Diagnostics.
    @Published private(set) var lastError: String? = nil

    /// The most recent *new* priority notification that arrived while the
    /// app was running (after initial load). MainTabView can observe this
    /// to auto-jump to Alerts.
    @Published private(set) var lastIncomingPriority: RisaNotification? = nil

    // MARK: - Convenience admin flags

    /// Any unlocked staff role can see staff/ops/vendor notifications.
    var isStaffUnlocked: Bool {
        adminLevel != .none
    }

    /// Can submit new notifications.
    var canSubmitNotifications: Bool {
        adminLevel == .notifier || adminLevel == .superAdmin
    }

    /// Can review and moderate pending changes.
    var canReviewChanges: Bool {
        adminLevel == .reviewer || adminLevel == .superAdmin
    }

    /// Watcher/reviewer/super can modify room status operations.
    var canModifyRoomStatus: Bool {
        adminLevel == .watcher || adminLevel == .reviewer || adminLevel == .superAdmin
    }

    /// Master user only.
    var isSuperAdminUnlocked: Bool {
        adminLevel == .superAdmin
    }

    /// Published-delete is restricted to master.
    var canDeletePublishedNotifications: Bool {
        adminLevel == .superAdmin
    }

    /// Convenience alias for anything still using `filtered`.
    var filtered: [RisaNotification] { notifications }

    /// Convenience alias for pending queue.
    var pending: [RisaNotification] { pendingNotifications }

    /// Whether we are using local sample data instead of Firestore.
    var isUsingSampleData: Bool { backendMode == .sample }

    /// High-signal items that should show as a banner somewhere in the app.
    /// Example filter: priority + within last 6 hours.
    var bannerCandidates: [RisaNotification] {
        let cutoff = Date().addingTimeInterval(-6 * 60 * 60) // last 6 hours
        return notifications.filter { note in
            note.isPriority && note.timestamp >= cutoff
        }
    }

    /// Convenience: the single "top" banner to show (if any).
    var topBanner: RisaNotification? {
        bannerCandidates.first
    }

    // MARK: - Firestore + backend config

    private let db = Firestore.firestore()
    private let analytics = TLIAnalyticsStore.shared

    private var listener: ListenerRegistration?
    private var pendingListener: ListenerRegistration?

    /// Underlying full list from Firestore (before role gating).
    private var allNotifications: [RisaNotification] = []

    /// Which convention's notifications we are reading.
    private(set) var conventionID: String = "trekli-2026"

    /// Live Firestore vs sample/local mode.
    private(set) var backendMode: BackendMode = .live

    /// Used to avoid flagging an existing priority item as “incoming” on first load.
    private var didReceiveFirstPublishedSnapshot: Bool = false

    // MARK: - Local read tracking

    private let readDefaultsKey = "TrekLI.readNotificationIDs"
    private let welcomeNotificationDocumentID = "local-welcome-2026"
    private let welcomeNotificationFirstShownAtKey = "TrekLI.localWelcomeNotificationFirstShownAt"
    private var readIDs: Set<String> = []
    private var readIDsObserver: NSObjectProtocol?

    // MARK: - Admin unlock tracking

    private let adminUnlockTimeKey  = "TrekLI.adminUnlockedAt"
    private let adminLevelDefaultsKey = "TrekLI.adminLevel"
    private let adminTimeout: TimeInterval = 3 * 60 // 3 minutes
    private var autoLockTimer: Timer?

    /// Convention-only rotating password seed and window.
    /// Kept for operational display/history; no longer used for authentication.
    private let rotatingPasswordSeed = "TrekLI-Convention-Rotate-v3:6ae2d53e070fed7c1ec94347e7869417"
    private let rotatingCalendar = Calendar(identifier: .gregorian)

    // MARK: - Firestore collection helpers

    private var notificationsCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("notifications")
    }

    private var pendingCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("pending_notifications")
    }

    // MARK: - Init / deinit

    private init() {
        loadReadIDs()
        observeReadIDsDefaults()
        restoreAdminState()
        startBackend()
    }

    deinit {
        listener?.remove()
        pendingListener?.remove()
        autoLockTimer?.invalidate()
        if let readIDsObserver {
            NotificationCenter.default.removeObserver(readIDsObserver)
        }
    }

    private var analyticsActor: String {
        switch adminLevel {
        case .none: return "guest"
        case .watcher: return "watcher"
        case .notifier: return "notifier"
        case .reviewer: return "reviewer"
        case .superAdmin: return "master"
        }
    }

    // MARK: - Backend lifecycle

    /// Starts the appropriate backend given the current backendMode.
    private func startBackend() {
        didReceiveFirstPublishedSnapshot = false

        switch backendMode {
        case .live:
            startListeningPublished()
            configurePendingAccess()
        case .sample:
            listener?.remove()
            pendingListener?.remove()
            pendingNotifications = []
            loadSampleNotifications()
        }

        scheduleAutoLockTimerIfNeeded()
    }

    /// Switch between live Firestore and local sample backend.
    func setBackendMode(_ mode: BackendMode) {
        guard backendMode != mode else { return }
        backendMode = mode
        analytics.track(
            name: "backend_mode_changed",
            domain: "notifications",
            actor: analyticsActor,
            metadata: ["mode": mode == .live ? "live" : "sample"]
        )

        // Clean up state + listeners before switching.
        listener?.remove()
        pendingListener?.remove()

        didReceiveFirstPublishedSnapshot = false
        allNotifications = []
        notifications = []
        pendingNotifications = []
        unreadCount = 0
        lastError = nil
        lastIncomingPriority = nil

        startBackend()
    }

    /// Switch which convention document we are reading from.
    /// e.g. "trekli-2025" vs "trekli-2026".
    func setConventionID(_ id: String) {
        guard conventionID != id else { return }
        conventionID = id
        analytics.track(
            name: "convention_changed",
            domain: "notifications",
            actor: analyticsActor,
            metadata: ["convention_id": id]
        )

        guard backendMode == .live else {
            // Sample mode just uses local data.
            return
        }

        // Restart listeners for new convention.
        listener?.remove()
        pendingListener?.remove()

        didReceiveFirstPublishedSnapshot = false
        allNotifications = []
        notifications = []
        pendingNotifications = []
        unreadCount = 0
        lastError = nil
        lastIncomingPriority = nil

        startListeningPublished()
        configurePendingAccess()
    }

    /// Force a one-time fetch (useful for pull-to-refresh).
    /// Snapshot listeners remain the primary mechanism; this just gives the UI
    /// a “refresh” affordance and can recover after transient listener errors.
    func refreshNow() async {
        guard backendMode == .live else { return }
        await withCheckedContinuation { cont in
            fetchPublishedOnce { [weak self] items, errorString in
                Task { @MainActor in
                    if let errorString { self?.lastError = errorString }
                    if let items {
                        self?.allNotifications = items
                        self?.applyRoleFilterAndUpdateUnread()
                    }
                    cont.resume()
                }
            }
        }

        if canReviewChanges {
            await withCheckedContinuation { cont in
                fetchPendingOnce { [weak self] items, errorString in
                    Task { @MainActor in
                        if let errorString { self?.lastError = errorString }
                        if let items { self?.pendingNotifications = items }
                        cont.resume()
                    }
                }
            }
        } else {
            pendingNotifications = []
        }
        analytics.track(
            name: "notifications_refreshed",
            domain: "notifications",
            actor: analyticsActor,
            metadata: [
                "published_count": "\(allNotifications.count)",
                "pending_count": "\(pendingNotifications.count)"
            ]
        )
    }

    /// Best-effort recovery path when APNs/FCM delivers an announcement before
    /// Firestore listeners catch up. We refresh immediately, and if the payload
    /// contains a concrete document identifier we stage a temporary local copy so
    /// the announcement is still visible while the backend settles.
    func handleRemoteNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        if let pushed = makePushNotification(from: userInfo) {
            upsertIncomingNotification(pushed)

            if pushed.isPriority, shouldShow(pushed) {
                lastIncomingPriority = pushed
            }
        }

        Task {
            await refreshNow()
        }
    }

    /// Public helper: validate whether the stored unlock time has expired.
    /// Call from views (e.g. on scenePhase changes) to keep admin state accurate.
    func ensureAdminTimeout() {
        guard isAdminUnlocked else { return }
        guard let unlockDate = UserDefaults.standard.object(forKey: adminUnlockTimeKey) as? Date else {
            lockAdmin()
            return
        }
        let elapsed = Date().timeIntervalSince(unlockDate)
        if elapsed >= adminTimeout {
            lockAdmin()
        }
    }

    // MARK: - Firestore listeners

    /// Live listener for PUBLISHED notifications.
    private func startListeningPublished() {
        listener?.remove()

        listener = notificationsCollection
            .order(by: "timestamp", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error = error {
                        let message = "Firestore published notifications error: \(error.localizedDescription)"
                        print("❌ \(message)")
                        if Self.isPermissionDeniedError(error) {
                            self.handlePublishedPermissionDenied(message: message)
                            return
                        }
                        self.lastError = message

                        // Fallback to samples if we literally have nothing.
                        if self.allNotifications.isEmpty {
                            self.loadSampleNotifications()
                        }
                        return
                    }

                    self.lastError = nil

                    guard let docs = snapshot?.documents else {
                        self.allNotifications = []
                        self.applyRoleFilterAndUpdateUnread()
                        self.didReceiveFirstPublishedSnapshot = true
                        return
                    }

                    let oldIDs = Set(self.allNotifications.compactMap { $0.documentID })

                    var items: [RisaNotification] = []
                    items.reserveCapacity(docs.count)

                    for doc in docs {
                        items.append(self.makePublishedNotification(from: doc))
                    }

                    // New priority only after initial snapshot (avoids firing on first load).
                    var newPriority: RisaNotification? = nil
                    if self.didReceiveFirstPublishedSnapshot && !oldIDs.isEmpty {
                        newPriority = items.first(where: { note in
                            guard note.isPriority else { return false }
                            if let id = note.documentID { return !oldIDs.contains(id) }
                            return false
                        })
                    }

                    self.allNotifications = items
                    self.applyRoleFilterAndUpdateUnread()
                    self.didReceiveFirstPublishedSnapshot = true

                    if let priority = newPriority, self.shouldShow(priority) {
                        self.lastIncomingPriority = priority
                    }
                }
            }
    }

    /// Live listener for PENDING notifications (super-admin queue).
    private func startListeningPending() {
        pendingListener?.remove()

        pendingListener = pendingCollection
            .order(by: "timestamp", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error = error {
                        let message = "Firestore pending notifications error: \(error.localizedDescription)"
                        print("❌ \(message)")
                        self.lastError = message
                        if Self.isPermissionDeniedError(error) {
                            self.pendingListener?.remove()
                            self.pendingListener = nil
                        }
                        self.pendingNotifications = []
                        return
                    }

                    self.lastError = nil

                    guard let docs = snapshot?.documents else {
                        self.pendingNotifications = []
                        return
                    }

                    var items: [RisaNotification] = []
                    items.reserveCapacity(docs.count)

                    for doc in docs {
                        items.append(self.makePendingNotification(from: doc))
                    }

                    self.pendingNotifications = items
                }
            }
    }

    // MARK: - One-time fetch helpers (refreshable)

    private func fetchPublishedOnce(completion: @escaping ([RisaNotification]?, String?) -> Void) {
        notificationsCollection
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self else {
                    completion(nil, "NotificationManager deallocated during fetch.")
                    return
                }

                if let error = error {
                    if Self.isPermissionDeniedError(error) {
                        Task { @MainActor in
                            self.handlePublishedPermissionDenied(
                                message: "Firestore refresh published error: \(error.localizedDescription)"
                            )
                        }
                    }
                    completion(nil, "Firestore refresh published error: \(error.localizedDescription)")
                    return
                }

                let docs = snapshot?.documents ?? []
                Task { @MainActor in
                    let items = docs.map { self.makePublishedNotification(from: $0) }
                    completion(items, nil)
                }
            }
    }

    private func fetchPendingOnce(completion: @escaping ([RisaNotification]?, String?) -> Void) {
        pendingCollection
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self else {
                    completion(nil, "NotificationManager deallocated during fetch.")
                    return
                }

                if let error = error {
                    completion(nil, "Firestore refresh pending error: \(error.localizedDescription)")
                    return
                }

                let docs = snapshot?.documents ?? []
                Task { @MainActor in
                    let items = docs.map { self.makePendingNotification(from: $0) }
                    completion(items, nil)
                }
            }
    }

    private func makePublishedNotification(from doc: QueryDocumentSnapshot) -> RisaNotification {
        let data = doc.data()

        let title      = data["title"] as? String ?? "Untitled"
        let message    = (data["message"] as? String) ?? (data["body"] as? String) ?? ""
        let role       = data["role"] as? String ?? "guest"
        let category   = (data["category"] as? String) ?? (data["track"] as? String) ?? "General"
        let isPriority = parsePriority(from: data)

        let timestamp: Date
        if let ts = data["timestamp"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let ts = data["createdAt"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let ts = data["startsAt"] as? Timestamp {
            timestamp = ts.dateValue()
        } else {
            timestamp = Date()
        }

        let docID = doc.documentID
        let isRead = readIDs.contains(docID)

        return RisaNotification(
            documentID: docID,
            title: title,
            message: message,
            role: role,
            category: category,
            timestamp: timestamp,
            isRead: isRead,
            isPriority: isPriority
        )
    }

    private func makePendingNotification(from doc: QueryDocumentSnapshot) -> RisaNotification {
        let data = doc.data()

        let title      = data["title"] as? String ?? "Untitled"
        let message    = (data["message"] as? String) ?? (data["body"] as? String) ?? ""
        let role       = data["role"] as? String ?? "guest"
        let category   = (data["category"] as? String) ?? (data["track"] as? String) ?? "General"
        let isPriority = parsePriority(from: data)

        let timestamp: Date
        if let ts = data["timestamp"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let ts = data["createdAt"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let ts = data["startsAt"] as? Timestamp {
            timestamp = ts.dateValue()
        } else {
            timestamp = Date()
        }

        let docID = doc.documentID

        // Pending items are treated as unread; they never hit the user's badge.
        return RisaNotification(
            documentID: docID,
            title: title,
            message: message,
            role: role,
            category: category,
            timestamp: timestamp,
            isRead: false,
            isPriority: isPriority
        )
    }

    // MARK: - Public API: read / unread

    /// Mark a single PUBLISHED notification as read.
    func markAsRead(_ notification: RisaNotification) {
        if backendMode == .sample {
            if let idx = indexInAllNotifications(notification) {
                allNotifications[idx].isRead = true
            }
            applyRoleFilterAndUpdateUnread()
            return
        }

        guard let docID = notification.documentID else { return }

        readIDs.insert(docID)
        saveReadIDs()

        if let idx = allNotifications.firstIndex(where: { $0.documentID == docID }) {
            allNotifications[idx].isRead = true
        }

        applyRoleFilterAndUpdateUnread()
    }

    /// Mark a single PUBLISHED notification as unread.
    func markAsUnread(_ notification: RisaNotification) {
        if backendMode == .sample {
            if let idx = indexInAllNotifications(notification) {
                allNotifications[idx].isRead = false
            }
            applyRoleFilterAndUpdateUnread()
            return
        }

        guard let docID = notification.documentID else { return }

        readIDs.remove(docID)
        saveReadIDs()

        if let idx = allNotifications.firstIndex(where: { $0.documentID == docID }) {
            allNotifications[idx].isRead = false
        }

        applyRoleFilterAndUpdateUnread()
    }

    /// Toggle read/unread for a PUBLISHED notification.
    func toggleRead(_ notification: RisaNotification) {
        if notification.isRead {
            markAsUnread(notification)
        } else {
            markAsRead(notification)
        }
    }

    /// Mark all *known* PUBLISHED notifications as read (visible + hidden).
    func markAllAsRead() {
        for idx in allNotifications.indices {
            if let docID = allNotifications[idx].documentID {
                readIDs.insert(docID)
            }
            allNotifications[idx].isRead = true
        }

        saveReadIDs()
        applyRoleFilterAndUpdateUnread()
    }

    // MARK: - Create / approve / discard (pending workflow)

    /// ADMIN: Create a new notification in the *pending* queue
    /// (used by your admin-create sheet).
    func addNotification(_ notification: RisaNotification) {
        guard canSubmitNotifications else {
            print("⚠️ addNotification called without submit permissions; ignoring.")
            analytics.track(
                name: "notification_create_denied",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["status": "denied"]
            )
            return
        }

        switch backendMode {
        case .live:
            let data: [String: Any] = [
                "title":       notification.title,
                "message":     notification.message,
                "role":        notification.role,
                "category":    notification.category,
                "isPriority":  notification.isPriority,
                "timestamp":   notification.timestamp
            ]

            pendingCollection.addDocument(data: data) { [weak self] error in
                guard let self else { return }
                if let error = error {
                    let message = "Failed to add pending notification: \(error.localizedDescription)"
                    print("❌ \(message)")
                    Task { @MainActor in self.lastError = message }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "notification_created_pending_failed",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: ["status": "failed"]
                        )
                    }
                } else {
                    Task { @MainActor in self.lastError = nil }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "notification_created_pending",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: [
                                "role": notification.role.lowercased(),
                                "category": notification.category.lowercased()
                            ]
                        )
                    }
                }
            }

        case .sample:
            // Local-only pending in sample mode.
            let note = RisaNotification(
                documentID: nil,
                title: notification.title,
                message: notification.message,
                role: notification.role,
                category: notification.category,
                timestamp: notification.timestamp,
                isRead: false,
                isPriority: notification.isPriority
            )
            pendingNotifications.insert(note, at: 0)
            analytics.track(
                name: "notification_created_pending",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["backend": "sample"]
            )
        }
    }

    /// SUPER ADMIN (Level 2): Approve a pending notification and publish it.
    /// - Writes a new document into `notifications`
    /// - Deletes/moves the original from `pending_notifications`
    func approvePending(_ notification: RisaNotification) {
        guard canReviewChanges else {
            print("⚠️ approvePending called without review permissions; ignoring.")
            analytics.track(
                name: "pending_approve_denied",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["status": "denied"]
            )
            return
        }

        switch backendMode {
        case .live:
            guard let docID = notification.documentID else { return }

            let data: [String: Any] = [
                "title":       notification.title,
                "message":     notification.message,
                "role":        notification.role,
                "category":    notification.category,
                "isPriority":  notification.isPriority,
                "timestamp":   notification.timestamp
            ]

            notificationsCollection.addDocument(data: data) { [weak self] error in
                guard let self else { return }
                if let error = error {
                    let message = "Failed to publish notification: \(error.localizedDescription)"
                    print("❌ \(message)")
                    Task { @MainActor in self.lastError = message }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "pending_approved_failed",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: ["status": "failed"]
                        )
                    }
                    return
                }
                Task { @MainActor in
                    self.analytics.track(
                        name: "pending_approved",
                        domain: "notifications",
                        actor: self.analyticsActor,
                        metadata: [
                            "role": notification.role.lowercased(),
                            "category": notification.category.lowercased()
                        ]
                    )
                }

                self.pendingCollection.document(docID).delete { error in
                    if let error = error {
                        let message = "Published but failed to delete pending: \(error.localizedDescription)"
                        print("⚠️ \(message)")
                        Task { @MainActor in self.lastError = message }
                    }
                }
            }

        case .sample:
            // Move from pending → published in-memory.
            pendingNotifications.removeAll { $0.id == notification.id }
            allNotifications.insert(notification, at: 0)
            applyRoleFilterAndUpdateUnread()
            analytics.track(
                name: "pending_approved",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["backend": "sample"]
            )
        }
    }

    /// SUPER ADMIN (Level 2): Update an existing pending notification (e.g., edit text).
    func updatePending(_ notification: RisaNotification) {
        guard canReviewChanges else {
            print("⚠️ updatePending called without review permissions; ignoring.")
            analytics.track(
                name: "pending_update_denied",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["status": "denied"]
            )
            return
        }

        switch backendMode {
        case .live:
            guard let docID = notification.documentID else { return }

            let data: [String: Any] = [
                "title":       notification.title,
                "message":     notification.message,
                "role":        notification.role,
                "category":    notification.category,
                "isPriority":  notification.isPriority,
                "timestamp":   notification.timestamp
            ]

            pendingCollection.document(docID).setData(data, merge: true) { [weak self] error in
                guard let self else { return }
                if let error = error {
                    let message = "Failed to update pending notification: \(error.localizedDescription)"
                    print("❌ \(message)")
                    Task { @MainActor in self.lastError = message }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "pending_updated_failed",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: ["status": "failed"]
                        )
                    }
                } else {
                    Task { @MainActor in self.lastError = nil }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "pending_updated",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: [
                                "role": notification.role.lowercased(),
                                "category": notification.category.lowercased()
                            ]
                        )
                    }
                }
            }

        case .sample:
            if let idx = pendingNotifications.firstIndex(where: { $0.id == notification.id }) {
                pendingNotifications[idx] = notification
            }
            analytics.track(
                name: "pending_updated",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["backend": "sample"]
            )
        }
    }

    /// SUPER ADMIN (Level 2): Discard (delete) a pending notification without publishing.
    func discardPending(_ notification: RisaNotification) {
        guard canReviewChanges else {
            print("⚠️ discardPending called without review permissions; ignoring.")
            analytics.track(
                name: "pending_discard_denied",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["status": "denied"]
            )
            return
        }

        switch backendMode {
        case .live:
            guard let docID = notification.documentID else { return }

            pendingCollection.document(docID).delete { [weak self] error in
                guard let self else { return }
                if let error = error {
                    let message = "Failed to delete pending notification: \(error.localizedDescription)"
                    print("❌ \(message)")
                    Task { @MainActor in self.lastError = message }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "pending_discarded_failed",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: ["status": "failed"]
                        )
                    }
                } else {
                    Task { @MainActor in self.lastError = nil }
                    Task { @MainActor in
                        self.analytics.track(
                            name: "pending_discarded",
                            domain: "notifications",
                            actor: self.analyticsActor
                        )
                    }
                }
            }

        case .sample:
            pendingNotifications.removeAll { $0.id == notification.id }
            analytics.track(
                name: "pending_discarded",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["backend": "sample"]
            )
        }
    }

    /// SUPER ADMIN (Level 2): Deletes a PUBLISHED notification from Firestore (and local list).
    func delete(_ notification: RisaNotification) {
        guard canDeletePublishedNotifications else {
            print("⚠️ delete called without master permissions; ignoring.")
            analytics.track(
                name: "notification_delete_denied",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["status": "denied"]
            )
            return
        }

        switch backendMode {
        case .live:
            guard let docID = notification.documentID else {
                allNotifications.removeAll { $0.id == notification.id }
                applyRoleFilterAndUpdateUnread()
                return
            }

            notificationsCollection.document(docID).delete { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error = error {
                        let message = "Failed to delete notification: \(error.localizedDescription)"
                        print("❌ \(message)")
                        self.lastError = message
                        self.analytics.track(
                            name: "notification_deleted_failed",
                            domain: "notifications",
                            actor: self.analyticsActor,
                            metadata: ["status": "failed"]
                        )
                    } else {
                        self.allNotifications.removeAll { $0.documentID == docID }
                        self.applyRoleFilterAndUpdateUnread()
                        self.analytics.track(
                            name: "notification_deleted",
                            domain: "notifications",
                            actor: self.analyticsActor
                        )
                    }
                }
            }

        case .sample:
            allNotifications.removeAll { $0.id == notification.id }
            applyRoleFilterAndUpdateUnread()
            analytics.track(
                name: "notification_deleted",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["backend": "sample"]
            )
        }
    }

    // MARK: - Admin / staff-ops-vendor visibility (TWO LEVELS)

    /// Starts a trusted admin session after Firebase identity + allowlist verification.
    func activateApprovedAdminSession(level: AdminLevel) {
        guard level != .none else {
            lockAdmin()
            return
        }

        adminLevel = level
        isAdminUnlocked = true
        lastError = nil

        let now = Date()
        UserDefaults.standard.set(now, forKey: adminUnlockTimeKey)
        UserDefaults.standard.set(level.rawValue, forKey: adminLevelDefaultsKey)

        applyRoleFilterAndUpdateUnread()
        configurePendingAccess()
        restartAutoLockTimer(remaining: adminTimeout)
        TLIPushTopicManager.syncTopics(isAdminUnlocked: isStaffUnlocked)
        analytics.track(
            name: "admin_unlock_success",
            domain: "auth",
            actor: analyticsActor,
            metadata: ["role": level.rawValue.lowercased(), "method": "firebase_allowlist"]
        )
    }

    /// Lock both levels (back to guest/qvip-only view).
    func lockAdmin() {
        let actor = analyticsActor
        adminLevel = .none
        isAdminUnlocked = false

        UserDefaults.standard.removeObject(forKey: adminUnlockTimeKey)
        UserDefaults.standard.removeObject(forKey: adminLevelDefaultsKey)

        applyRoleFilterAndUpdateUnread()
        configurePendingAccess()
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        TLIPushTopicManager.syncTopics(isAdminUnlocked: isStaffUnlocked)
        analytics.track(
            name: "admin_locked",
            domain: "auth",
            actor: actor
        )
    }

    private func isConventionDay(_ date: Date) -> Bool {
        let comps = rotatingCalendar.dateComponents([.year, .month, .day], from: date)
        guard comps.year == 2026, comps.month == 6, let day = comps.day else { return false }
        return (12...14).contains(day)
    }

    /// Format: tli-<role>-<8char>, where suffix rotates daily.
    private func rotatingPassword(for role: AdminLevel, on date: Date) -> String {
        let roleKey: String
        switch role {
        case .watcher: roleKey = "watcher"
        case .notifier: roleKey = "notifier"
        case .reviewer: roleKey = "reviewer"
        case .superAdmin: roleKey = "master"
        case .none: roleKey = "none"
        }

        let formatter = DateFormatter()
        formatter.calendar = rotatingCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        let dayToken = formatter.string(from: date)

        let material = "\(rotatingPasswordSeed)|\(roleKey)|\(dayToken)"
        let digest = SHA256.hash(data: Data(material.utf8))
        let suffix = digest.map { String(format: "%02x", $0) }.joined().prefix(8).uppercased()
        return "tli-\(roleKey)-\(suffix)"
    }

    /// Master-only helper to display today's rotating passwords to staff.
    func rotatingPasswordsForTodayForDisplay(reference: Date = Date()) -> [String: String] {
        guard isSuperAdminUnlocked else { return [:] }
        guard isConventionDay(reference) else { return [:] }

        return [
            "Watcher": rotatingPassword(for: .watcher, on: reference),
            "Notifier": rotatingPassword(for: .notifier, on: reference),
            "Reviewer": rotatingPassword(for: .reviewer, on: reference),
            "Master": rotatingPassword(for: .superAdmin, on: reference)
        ]
    }

    func isConventionPasswordWindow(reference: Date = Date()) -> Bool {
        isConventionDay(reference)
    }

    // MARK: - Role gating + unread computation

    private func applyRoleFilterAndUpdateUnread() {
        notifications = notificationsIncludingWelcome()
            .sorted(by: { $0.timestamp > $1.timestamp })
            .filter { shouldShow($0) }

        recomputeUnreadCount()
    }

    /// Visibility rules:
    /// - Show broadcast/public roles to everyone
    /// - Show "guest" and "qvip" by default
    /// - Show "staff", "ops", "vendor" only when staff is unlocked
    private func shouldShow(_ note: RisaNotification) -> Bool {
        let roleLower = note.role
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if roleLower.isEmpty || roleLower == "all" || roleLower == "public" {
            return true
        }

        // Staff/Ops/Vendor only visible when at least level 1 is unlocked.
        if ["staff", "ops", "vendor"].contains(roleLower) {
            return isStaffUnlocked
        }

        // Default public roles.
        if roleLower == "guest" || roleLower == "qvip" {
            return true
        }

        // Unknown roles are treated as public instead of disappearing.
        return true
    }

    /// Recompute unreadCount from current *visible* notifications.
    /// Prefers readIDs when a documentID is present, falls back to note.isRead.
    private func recomputeUnreadCount() {
        unreadCount = notifications.reduce(0) { count, note in
            let isUnread: Bool

            if let docID = note.documentID, backendMode == .live {
                isUnread = !readIDs.contains(docID)
            } else {
                isUnread = !note.isRead
            }

            return isUnread ? count + 1 : count
        }
    }

    // MARK: - Local read IDs persistence

    private func loadReadIDs() {
        if let stored = UserDefaults.standard.stringArray(forKey: readDefaultsKey) {
            readIDs = Set(stored)
        } else if let stored = UserDefaults.standard.array(forKey: readDefaultsKey) as? [String] {
            // back-compat
            readIDs = Set(stored)
        } else {
            readIDs = []
        }
    }

    private func saveReadIDs() {
        UserDefaults.standard.set(Array(readIDs), forKey: readDefaultsKey)
    }

    private func observeReadIDsDefaults() {
        readIDsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let previous = self.readIDs
                self.loadReadIDs()
                guard previous != self.readIDs else { return }

                for idx in self.allNotifications.indices {
                    if let docID = self.allNotifications[idx].documentID {
                        self.allNotifications[idx].isRead = self.readIDs.contains(docID)
                    }
                }
                self.applyRoleFilterAndUpdateUnread()
            }
        }
    }

    // MARK: - Admin auto-lock

    private func restoreAdminState() {
        guard let date = UserDefaults.standard.object(forKey: adminUnlockTimeKey) as? Date else {
            adminLevel = .none
            isAdminUnlocked = false
            return
        }

        let elapsed = Date().timeIntervalSince(date)
        let remaining = adminTimeout - elapsed

        if remaining > 0 {
            if let levelRaw = UserDefaults.standard.string(forKey: adminLevelDefaultsKey) {
                if let level = AdminLevel(rawValue: levelRaw) {
                    adminLevel = level
                } else if levelRaw == "staff" {
                    // Back-compat mapping from older builds.
                    adminLevel = .watcher
                } else {
                    adminLevel = .superAdmin
                }
            } else {
                adminLevel = .superAdmin
            }
            isAdminUnlocked = (adminLevel != .none)
        } else {
            adminLevel = .none
            isAdminUnlocked = false
            UserDefaults.standard.removeObject(forKey: adminUnlockTimeKey)
            UserDefaults.standard.removeObject(forKey: adminLevelDefaultsKey)
        }
    }

    private func scheduleAutoLockTimerIfNeeded() {
        guard isAdminUnlocked else { return }
        guard let unlockDate = UserDefaults.standard.object(forKey: adminUnlockTimeKey) as? Date else { return }

        let elapsed = Date().timeIntervalSince(unlockDate)
        let remaining = max(0, adminTimeout - elapsed)
        if remaining <= 0 {
            lockAdmin()
            return
        }

        restartAutoLockTimer(remaining: remaining)
    }

    private func restartAutoLockTimer(remaining: TimeInterval) {
        autoLockTimer?.invalidate()
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lockAdmin()
            }
        }
    }

    private func configurePendingAccess() {
        guard backendMode == .live else {
            pendingListener?.remove()
            pendingListener = nil
            pendingNotifications = []
            return
        }

        guard canReviewChanges else {
            pendingListener?.remove()
            pendingListener = nil
            pendingNotifications = []
            return
        }

        startListeningPending()
    }

    private nonisolated static func isPermissionDeniedError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain &&
            nsError.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    private func handlePublishedPermissionDenied(message: String) {
        lastError = message

        // Avoid repeated stream failures when the current user/rules do not allow reads.
        listener?.remove()
        listener = nil
        pendingListener?.remove()
        pendingListener = nil

        if backendMode == .live {
            backendMode = .sample
            pendingNotifications = []
            loadSampleNotifications()
            analytics.track(
                name: "backend_auto_fallback",
                domain: "notifications",
                actor: analyticsActor,
                metadata: ["reason": "permission_denied"]
            )
        }
    }

    // MARK: - Helpers

    private func notificationsIncludingWelcome() -> [RisaNotification] {
        var items = allNotifications

        guard shouldInjectWelcomeNotification else {
            return items
        }

        items.append(makeWelcomeNotification())
        return items
    }

    private var shouldInjectWelcomeNotification: Bool {
        guard !readIDs.contains(welcomeNotificationDocumentID) else { return false }

        return !allNotifications.contains { note in
            note.documentID == welcomeNotificationDocumentID ||
            (
                (note.title == "Welcome to \(TLIAppBranding.appDisplayName)" ||
                 note.title == "Welcome to Trek Long Island") &&
                note.role.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "guest"
            )
        }
    }

    private func makeWelcomeNotification() -> RisaNotification {
        let defaults = UserDefaults.standard
        let firstShownAt: Date

        if let stored = defaults.object(forKey: welcomeNotificationFirstShownAtKey) as? Date {
            firstShownAt = stored
        } else {
            let now = Date()
            defaults.set(now, forKey: welcomeNotificationFirstShownAtKey)
            firstShownAt = now
        }

        return RisaNotification(
            documentID: welcomeNotificationDocumentID,
            title: "Welcome to \(TLIAppBranding.appDisplayName)",
            message: "Your mission begins now. Check the Schedule tab for today’s panels and events.",
            role: "guest",
            category: "General",
            timestamp: firstShownAt,
            isRead: readIDs.contains(welcomeNotificationDocumentID),
            isPriority: false
        )
    }

    private func makePushNotification(from userInfo: [AnyHashable: Any]) -> RisaNotification? {
        let normalized = Dictionary(uniqueKeysWithValues: userInfo.map { (String(describing: $0.key), $0.value) })

        let aps = normalized["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]

        let title =
            stringValue(in: normalized, keys: ["title"]) ??
            stringValue(in: normalized, keys: ["notificationTitle"]) ??
            stringValue(in: normalized, keys: ["gcm.notification.title"]) ??
            (alert?["title"] as? String)

        let message =
            stringValue(in: normalized, keys: ["message", "body"]) ??
            stringValue(in: normalized, keys: ["notificationBody"]) ??
            stringValue(in: normalized, keys: ["gcm.notification.body"]) ??
            (alert?["body"] as? String)

        guard let title, let message, !title.isEmpty, !message.isEmpty else {
            return nil
        }

        let role = stringValue(in: normalized, keys: ["role", "audience"]) ?? "guest"
        let category = stringValue(in: normalized, keys: ["category", "track"]) ?? "General"
        let documentID = stringValue(in: normalized, keys: ["documentID", "docID", "notificationID", "notification_id", "id"])
        let timestamp = dateValue(in: normalized, keys: ["timestamp", "createdAt", "startsAt"]) ?? Date()
        let isPriority = parsePriority(from: normalized) || ((aps?["content-available"] as? Int) == 1)
        let isRead = documentID.map(readIDs.contains) ?? false

        return RisaNotification(
            documentID: documentID,
            title: title,
            message: message,
            role: role,
            category: category,
            timestamp: timestamp,
            isRead: isRead,
            isPriority: isPriority
        )
    }

    private func upsertIncomingNotification(_ incoming: RisaNotification) {
        if let docID = incoming.documentID,
           let idx = allNotifications.firstIndex(where: { $0.documentID == docID }) {
            allNotifications[idx] = incoming
            applyRoleFilterAndUpdateUnread()
            return
        }

        let duplicate = allNotifications.contains {
            $0.documentID == nil &&
            $0.title == incoming.title &&
            $0.message == incoming.message &&
            abs($0.timestamp.timeIntervalSince(incoming.timestamp)) < 120
        }

        guard !duplicate else { return }

        allNotifications.insert(incoming, at: 0)
        applyRoleFilterAndUpdateUnread()
    }

    private func indexInAllNotifications(_ notification: RisaNotification) -> Int? {
        if let docID = notification.documentID {
            return allNotifications.firstIndex(where: { $0.documentID == docID })
        }
        return allNotifications.firstIndex(where: { $0.id == notification.id })
    }

    private func parsePriority(from data: [String: Any]) -> Bool {
        if let isPriority = data["isPriority"] as? Bool {
            return isPriority
        }
        if let showAsBanner = data["showAsBanner"] as? Bool, showAsBanner {
            return true
        }
        if let priorityRaw = data["priority"] as? String {
            let priority = priorityRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return priority == "high" || priority == "critical" || priority == "priority"
        }
        return false
    }

    private func stringValue(in data: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = data[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    private func dateValue(in data: [String: Any], keys: [String]) -> Date? {
        for key in keys {
            if let ts = data[key] as? Timestamp {
                return ts.dateValue()
            }
            if let seconds = data[key] as? TimeInterval {
                if seconds > 1_000_000_000 {
                    return Date(timeIntervalSince1970: seconds)
                }
            }
            if let raw = data[key] as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if let iso = ISO8601DateFormatter().date(from: trimmed) {
                    return iso
                }
                if let seconds = TimeInterval(trimmed), seconds > 1_000_000_000 {
                    return Date(timeIntervalSince1970: seconds)
                }
            }
        }
        return nil
    }

    // MARK: - Sample data (fallback / previews)

    func loadSampleNotifications() {
        // Keep only the welcome fallback; remove seeded sample traffic.
        allNotifications = [
            .sample(
                title: "Welcome to \(TLIAppBranding.appDisplayName)",
                message: "Your mission begins now. Check the Schedule tab for today’s panels and events.",
                role: "guest",
                category: "General"
            )
        ]

        // No seeded pending samples.
        pendingNotifications = []

        applyRoleFilterAndUpdateUnread()
    }
}

// MARK: - Preview helper (DEBUG only)

#if DEBUG
extension NotificationManager {
    /// Convenience for SwiftUI previews:
    ///   .environmentObject(NotificationManager.preview())
    static func preview() -> NotificationManager {
        let manager = NotificationManager.shared
        manager.setBackendMode(.sample)
        return manager
    }
}
#endif
