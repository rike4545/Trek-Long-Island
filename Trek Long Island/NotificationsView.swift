// Copyright Bryan Carroll. All rights reserved.
//
//  NotificationsView.swift
//  Trek Long Island
//
//  - Role filters, unread/priority filters, search
//  - Swipe to delete (super admin only), swipe to mark read/unread
//  - Coordinator unlock via Firebase sign-in + allowlist check
//  - Toast/snackbar on admin unlock / lock / auth changes
//  - Pull-to-refresh (one-time fetch) for live Firestore mode
//  - Super-admin Pending Queue with approve/edit/discard
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TLINotificationsListMode: String, CaseIterable, Identifiable {
    case published = "Published"
    case pending = "Pending"
    var id: String { rawValue }
}

@MainActor
struct NotificationsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var manager = NotificationManager.shared
    @StateObject private var scheduleLoader = ICSLoader()

    @State private var mode: TLINotificationsListMode = .published

    @State private var selectedPublished: RisaNotification?
    @State private var selectedPending: RisaNotification?
    @State private var selectedLiveEvent: ICSParsedEvent?

    @State private var showCreateSheet = false
    @State private var showCoordinatorAccessSheet = false
    @State private var showLockConfirm: Bool = false

    private enum PostUnlockAction { case create }
    @State private var postUnlockAction: PostUnlockAction? = nil

    // Local UI state
    @State private var searchText = ""
    @State private var selectedRole: String = "All"
    @State private var showOnlyUnread: Bool = false
    @State private var showOnlyPriority: Bool = false
    @State private var showOnlySpecialEvent: Bool = false

    @AppStorage("TLI.NotificationPrefs.digestMode") private var digestMode: Bool = false
    @AppStorage("TLI.NotificationPrefs.quietStartHour") private var quietStartHour: Int = 22
    @AppStorage("TLI.NotificationPrefs.quietEndHour") private var quietEndHour: Int = 7
    @AppStorage("TLI.NotificationPrefs.priorityOverridesQuiet") private var priorityOverridesQuiet: Bool = true

    // Toast / snackbar state
    private enum AdminToastKind { case status, error }
    @State private var showAdminToast: Bool = false
    @State private var adminToastMessage: String = ""
    @State private var adminToastKind: AdminToastKind = .status

    init(initialMode: TLINotificationsListMode = .published) {
        _mode = State(initialValue: initialMode)
    }

    // MARK: - Data

    private var sourceNotes: [RisaNotification] {
        switch mode {
        case .published:
            return manager.notifications
        case .pending:
            // Pending is only meaningful for super admin; otherwise keep empty.
            return manager.canReviewChanges ? manager.pendingNotifications : []
        }
    }

    private var roleOptions: [String] {
        let roles = Set(sourceNotes.map { $0.role.trimmingCharacters(in: .whitespacesAndNewlines).capitalized })
            .filter { !$0.isEmpty }
        return ["All"] + roles.sorted()
    }

    private var normalizedSelectedRole: String {
        roleOptions.contains(selectedRole) ? selectedRole : "All"
    }

    private var quietHoursActive: Bool {
        guard mode == .published else { return false }
        if quietStartHour == quietEndHour { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        if quietStartHour < quietEndHour {
            return hour >= quietStartHour && hour < quietEndHour
        }
        return hour >= quietStartHour || hour < quietEndHour
    }

    private var displayed: [RisaNotification] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = sourceNotes
            // Role filter
            .filter {
                normalizedSelectedRole == "All" ||
                $0.role.trimmingCharacters(in: .whitespacesAndNewlines).capitalized == normalizedSelectedRole
            }
            // Quiet hours filter (optional priority bypass)
            .filter { note in
                guard quietHoursActive else { return true }
                if priorityOverridesQuiet {
                    return note.isPriority
                }
                return false
            }
            // Priority filter
            .filter { !showOnlyPriority || $0.isPriority }
            // Special event filter
            .filter { !showOnlySpecialEvent || isSpecialEventCategory($0.category) }
            // Unread filter (only applies to published; pending is always “unread-like”)
            .filter { mode == .pending ? true : (!showOnlyUnread || !$0.isRead) }
            // Search filter
            .filter {
                guard !q.isEmpty else { return true }
                return $0.title.localizedCaseInsensitiveContains(q)
                    || $0.message.localizedCaseInsensitiveContains(q)
                    || $0.category.localizedCaseInsensitiveContains(q)
            }
            .sorted { lhs, rhs in
                // Keep priority announcements on top, then newest first.
                if lhs.isPriority != rhs.isPriority { return lhs.isPriority && !rhs.isPriority }
                return lhs.timestamp > rhs.timestamp
            }

        if digestMode && mode == .published {
            return Array(filtered.prefix(25))
        }
        return filtered
    }

    private var publishedPriorityCount: Int {
        manager.notifications.filter(\.isPriority).count
    }

    private var publishedTodayCount: Int {
        let cal = Calendar.current
        return manager.notifications.filter { cal.isDateInToday($0.timestamp) }.count
    }

    private func isSpecialEventCategory(_ category: String) -> Bool {
        let normalized = category
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalized == "special event" || normalized == "special events"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.28)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                headerControls

                NotificationList(
                    mode: mode,
                    notes: displayed,
                    showOnlyUnread: showOnlyUnread,
                    canDelete: manager.canDeletePublishedNotifications && mode == .published,
                    onSelectPublished: { selectedPublished = $0 },
                    onSelectPending: { selectedPending = $0 },
                    onDelete: { manager.delete($0) },
                    onToggleRead: { manager.toggleRead($0) },
                    onApprove: { manager.approvePending($0) },
                    onDiscard: { manager.discardPending($0) }
                )
                .refreshable {
                    await manager.refreshNow()
                    scheduleLoader.load()
                }
            }

            // Admin toast / snackbar
            if showAdminToast {
                adminToast
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tint(TLITheme.accent(scheme))
        .toolbar { toolbar }

        // Admin create sheet (super admin)
        .sheet(isPresented: $showCreateSheet) {
            AdminCreateNotificationView()
                .environmentObject(manager)
        }

        // Published detail
        .sheet(item: $selectedPublished) { note in
            NotificationDetailView(notification: note)
        }

        // Pending editor (super-admin only)
        .sheet(item: $selectedPending) { note in
            PendingEditorView(notification: note)
        }

        // Happening Now event detail
        .sheet(item: $selectedLiveEvent) { event in
            NavigationStack {
                EventDetailView(event: event)
                    .tliNavBarStyle()
            }
        }

        // Coordinator access (Firebase sign-in + secure session resume)
        .sheet(isPresented: $showCoordinatorAccessSheet) {
            CoordinatorAccessView {
                adminToastKind = .status
                if postUnlockAction == .create, manager.canSubmitNotifications {
                    showCreateSheet = true
                }
                postUnlockAction = nil
            }
        }

        // Lock confirm
        .alert("Lock Admin Mode?", isPresented: $showLockConfirm) {
            Button("Lock", role: .destructive) {
                manager.lockAdmin()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Staff and operations notifications will be hidden again until you unlock admin.")
        }

        // Toast on admin unlock / lock (based on TWO levels)
        .onChange(of: manager.adminLevel) { _, level in
            adminToastKind = .status
            switch level {
            case .none:
                adminToastMessage = "Admin mode locked — staff, ops, and vendor messages hidden."
                if mode == .pending { mode = .published }
            case .watcher:
                adminToastMessage = "Watcher unlocked — room status operations enabled."
                if mode == .pending { mode = .published }
            case .notifier:
                adminToastMessage = "Notifier unlocked — notification submit tools enabled."
                if mode == .pending { mode = .published }
            case .reviewer:
                adminToastMessage = "Reviewer unlocked — pending review and ops moderation enabled."
            case .superAdmin:
                adminToastMessage = "Master unlocked — full controls available."
            }
            showToast()
        }

        // If auto-lock happens while backgrounded, re-check when active.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                manager.ensureAdminTimeout()
            }
        }

        // Triple-tap anywhere on the screen to trigger coordinator access sheet.
        .simultaneousGesture(
            TapGesture(count: 3).onEnded {
                postUnlockAction = nil
                showCoordinatorAccessSheet = true
            }
        )
        .onAppear {
            // If super admin is not unlocked, never stay on pending mode.
            if mode == .pending && !manager.canReviewChanges {
                mode = .published
            }

            if scheduleLoader.events.isEmpty {
                scheduleLoader.load()
            }

            Task {
                await manager.refreshNow()
            }
        }
    }

    private var happeningNowEvents: [ICSParsedEvent] {
        let now = Date()
        return scheduleLoader.events
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
    }

    private var startingSoonEvents: [ICSParsedEvent] {
        let now = Date()
        let soon = now.addingTimeInterval(60 * 60)
        return Array(
            scheduleLoader.events
                .filter { $0.startDate > now && $0.startDate <= soon }
                .sorted { $0.startDate < $1.startDate }
                .prefix(3)
        )
    }

    // MARK: - Header controls

    private var headerControls: some View {
        VStack(spacing: 10) {
            if manager.canReviewChanges {
                Picker("Mode", selection: $mode) {
                    ForEach(TLINotificationsListMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            if mode == .published, (quietHoursActive || digestMode) {
                notificationPreferencesBanner
                    .padding(.horizontal)
            }

            if mode == .published {
                announcementsSummaryStrip
                    .padding(.horizontal)
            }

            FilterBar(
                mode: mode,
                searchText: $searchText,
                selectedRole: Binding(get: { normalizedSelectedRole }, set: { selectedRole = $0 }),
                roleOptions: roleOptions,
                showOnlyUnread: $showOnlyUnread,
                showOnlyPriority: $showOnlyPriority,
                showOnlySpecialEvent: $showOnlySpecialEvent,
                adminLevel: manager.adminLevel
            )
            .padding(.top, manager.canReviewChanges ? 0 : 4)

            if mode == .published {
                HappeningNowPanel(events: happeningNowEvents, upcoming: startingSoonEvents, onSelect: { selectedLiveEvent = $0 })
                    .padding(.horizontal)
            }
        }
    }

    private var notificationPreferencesBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            if quietHoursActive {
                Text(priorityOverridesQuiet
                     ? "Quiet hours active: only priority notices are shown."
                     : "Quiet hours active: notifications are muted.")
                    .font(.caption)
            }
            if digestMode {
                Text("Digest mode active: showing latest 25 items.")
                    .font(.caption)
            }
        }
        .foregroundStyle(Color.primary.opacity(0.72))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var announcementsSummaryStrip: some View {
        HStack(spacing: 10) {
            summaryPill(title: "Priority", value: "\(publishedPriorityCount)", icon: "exclamationmark.circle")
            summaryPill(title: "Today", value: "\(publishedTodayCount)", icon: "calendar")
            if manager.unreadCount > 0 {
                Text("\(manager.unreadCount) unread")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
            Spacer(minLength: 0)
        }
    }

    private func summaryPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(title)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            TLITheme.cardBackground(scheme),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .foregroundStyle(TLITheme.textPrimary(scheme))
    }

    private var navigationTitle: String {
        switch mode {
        case .published:
            return "Announcements"
        case .pending:
            return "Pending (\(manager.pendingNotifications.count))"
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if mode == .published {
                    Toggle("Show Only Unread", isOn: $showOnlyUnread)
                    Toggle("Show Only Priority", isOn: $showOnlyPriority)
                    Toggle("Show Only Special Event", isOn: $showOnlySpecialEvent)

                    Divider()

                    Button("Mark All Read") {
                        manager.markAllAsRead()
                    }
                    .disabled(manager.unreadCount == 0)

                    Divider()
                }

                if manager.adminLevel != .none {
                    Button("Lock Admin Mode", role: .destructive) {
                        showLockConfirm = true
                    }
                    Divider()
                }

                Button {
                    if manager.canSubmitNotifications {
                        showCreateSheet = true
                    } else {
                        postUnlockAction = .create
                        showCoordinatorAccessSheet = true
                    }
                } label: {
                    Label("Create Notification", systemImage: "plus.bubble")
                }

                if manager.canReviewChanges {
                    Button {
                        mode = .pending
                    } label: {
                        Label("Open Pending Queue (\(manager.pendingNotifications.count))", systemImage: "tray.full")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Toast Helpers

    private func showToast() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(adminToastKind == .error ? .error : .success)
        #endif

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showAdminToast = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(2200))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    showAdminToast = false
                }
            }
        }
    }

    private var adminToast: some View {
        let iconName: String
        let tintColor: Color

        switch adminToastKind {
        case .status:
            switch manager.adminLevel {
            case .none:
                iconName = "lock.fill"
                tintColor = TLITheme.textPrimary(scheme)
            case .watcher:
                iconName = "eye.fill"
                tintColor = TLITheme.accent(scheme)
            case .notifier:
                iconName = "plus.bubble.fill"
                tintColor = TLITheme.accent(scheme)
            case .reviewer:
                iconName = "checkmark.seal.fill"
                tintColor = TLITheme.accent(scheme)
            case .superAdmin:
                iconName = "lock.open.trianglebadge.exclamationmark"
                tintColor = .red
            }
        case .error:
            iconName = "exclamationmark.triangle.fill"
            tintColor = .yellow
        }

        return HStack(spacing: 10) {
            Image(systemName: iconName)
                .imageScale(.medium)
                .foregroundColor(tintColor)

            Text(adminToastMessage)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .foregroundStyle(TLITheme.textPrimary(scheme))
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.8 : 0.25),
            radius: 8,
            y: 4
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Filter Bar (search + role chips + unread/priority pills)

private struct FilterBar: View {
    @Environment(\.colorScheme) private var scheme

    let mode: TLINotificationsListMode

    @Binding var searchText: String
    @Binding var selectedRole: String
    let roleOptions: [String]

    @Binding var showOnlyUnread: Bool
    @Binding var showOnlyPriority: Bool
    @Binding var showOnlySpecialEvent: Bool

    let adminLevel: NotificationManager.AdminLevel

    var body: some View {
        VStack(spacing: 10) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.primary.opacity(0.72))

                TextField("Search notifications…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                TLITheme.cardBackground(scheme),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
            .padding(.horizontal)

            // Roles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(roleOptions, id: \.self) { role in
                        let isSel = (role == selectedRole)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                selectedRole = role
                            }
                        } label: {
                            Text(role)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    isSel
                                        ? TLITheme.accent(scheme).opacity(0.92)
                                        : TLITheme.cardBackground(scheme),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                                )
                                .foregroundColor(isSel ? .black : TLITheme.textPrimary(scheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 2)
            }

            HStack(spacing: 10) {
                if mode == .published {
                    FilterPill(
                        title: "Unread",
                        systemImage: "circlebadge",
                        isOn: $showOnlyUnread
                    )
                    FilterPill(
                        title: "Priority",
                        systemImage: "exclamationmark.circle",
                        isOn: $showOnlyPriority
                    )
                    FilterPill(
                        title: "Special Event",
                        systemImage: "sparkles",
                        isOn: $showOnlySpecialEvent
                    )
                } else {
                    Text("Pending items don’t affect your unread badge.")
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 8)

                AdminStatusPill(level: adminLevel)
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterPill: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .imageScale(.small)
                Text(title)
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isOn ? TLITheme.accent(scheme).opacity(0.18) : TLITheme.cardBackground(scheme),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(TLITheme.border(scheme), lineWidth: 1)
            )
            .foregroundStyle(isOn ? TLITheme.accent(scheme) : TLITheme.textPrimary(scheme))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "\(title) filter on" : "\(title) filter off")
    }
}

private struct AdminStatusPill: View {
    @Environment(\.colorScheme) private var scheme
    let level: NotificationManager.AdminLevel

    private var label: String {
        switch level {
        case .none: return "Guest"
        case .watcher: return "Watcher"
        case .notifier: return "Notifier"
        case .reviewer: return "Reviewer"
        case .superAdmin: return "Master"
        }
    }

    private var icon: String {
        switch level {
        case .none: return "person"
        case .watcher: return "eye"
        case .notifier: return "plus.bubble"
        case .reviewer: return "checkmark.seal"
        case .superAdmin: return "lock.open"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(label)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            TLITheme.cardBackground(scheme),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .foregroundStyle(TLITheme.textPrimary(scheme))
        .accessibilityLabel("Admin level \(label)")
    }
}

// MARK: - List

private struct NotificationList: View {
    @Environment(\.colorScheme) private var scheme

    let mode: TLINotificationsListMode
    let notes: [RisaNotification]
    let showOnlyUnread: Bool
    let canDelete: Bool

    let onSelectPublished: (RisaNotification) -> Void
    let onSelectPending: (RisaNotification) -> Void

    let onDelete: (RisaNotification) -> Void
    let onToggleRead: (RisaNotification) -> Void

    let onApprove: (RisaNotification) -> Void
    let onDiscard: (RisaNotification) -> Void

    var body: some View {
        List {
            if notes.isEmpty {
                EmptyRow(mode: mode, showOnlyUnread: showOnlyUnread)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(notes) { note in
                    Button {
                        switch mode {
                        case .published: onSelectPublished(note)
                        case .pending: onSelectPending(note)
                        }
                    } label: {
                        NotificationCardView(
                            notification: note,
                            showRoleChip: true,
                            showCategoryChip: true,
                            showTimestamp: true
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        switch mode {
                        case .published:
                            if canDelete {
                                Button(role: .destructive) { onDelete(note) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        case .pending:
                            Button(role: .destructive) { onDiscard(note) } label: {
                                Label("Discard", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        switch mode {
                        case .published:
                            Button { onToggleRead(note) } label: {
                                Label(
                                    note.isRead ? "Unread" : "Read",
                                    systemImage: note.isRead ? "envelope.badge" : "envelope.open"
                                )
                            }
                            .tint(.blue)
                        case .pending:
                            Button { onApprove(note) } label: {
                                Label("Approve", systemImage: "checkmark.seal")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

private struct EmptyRow: View {
    let mode: TLINotificationsListMode
    let showOnlyUnread: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: mode == .pending ? "tray" : "bell.slash")
                .font(.largeTitle)
                .foregroundStyle(Color.primary.opacity(0.72))

            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(Color.primary.opacity(0.72))

            Text(emptySubtitle)
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }

    private var emptyTitle: String {
        switch mode {
        case .pending:
            return "No pending notifications"
        case .published:
            return showOnlyUnread ? "No unread notifications" : "No notifications yet"
        }
    }

    private var emptySubtitle: String {
        switch mode {
        case .pending:
            return "Drafts waiting for approval will appear here."
        case .published:
            return "Pull to refresh or check back later."
        }
    }
}


private struct HappeningNowPanel: View {
    @Environment(\.colorScheme) private var scheme
    let events: [ICSParsedEvent]
    let upcoming: [ICSParsedEvent]
    let onSelect: (ICSParsedEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(TLITheme.accent(scheme))
                Text("Happening Now")
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer()
                Text("\(events.count) live")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            if events.isEmpty {
                Text("No sessions are live right now.")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                ForEach(events.prefix(3), id: \.id) { event in
                    Button {
                        onSelect(event)
                    } label: {
                        HStack(spacing: 8) {
                            Text(event.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            Text(event.room)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.primary.opacity(0.72))
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !upcoming.isEmpty {
                Divider().overlay(TLITheme.border(scheme))
                Text("Starting within 1 hour")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))

                ForEach(upcoming, id: \.id) { event in
                    Button {
                        onSelect(event)
                    } label: {
                        HStack(spacing: 8) {
                            Text(event.title)
                                .font(.footnote)
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(event.startDate, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.primary.opacity(0.72))
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }
}

// MARK: - Pending Editor

private struct PendingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var manager = NotificationManager.shared

    let notification: RisaNotification

    private struct Draft: Equatable {
        var title: String
        var message: String
        var role: String
        var category: String
        var isPriority: Bool
    }

    @State private var draft: Draft
    @State private var showDiscardConfirm = false
    @State private var showApproveConfirm = false

    init(notification: RisaNotification) {
        self.notification = notification
        self._draft = State(initialValue: Draft(
            title: notification.title,
            message: notification.message,
            role: notification.role,
            category: notification.category,
            isPriority: notification.isPriority
        ))
    }

    private var updatedNotification: RisaNotification {
        // Preserve Firestore docID + timestamp; pending items are treated as unread.
        return RisaNotification(
            documentID: notification.documentID,
            title: draft.title,
            message: draft.message,
            role: draft.role,
            category: draft.category,
            timestamp: notification.timestamp,
            isRead: false,
            isPriority: draft.isPriority
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TLITheme.backgroundGradient(scheme).ignoresSafeArea()

                Form {
                    Section("Content") {
                        TextField("Title", text: $draft.title)
                        TextField("Category", text: $draft.category)
                        TextField("Role", text: $draft.role)
                        Toggle("Priority", isOn: $draft.isPriority)

                        TextEditor(text: $draft.message)
                            .frame(minHeight: 160)
                    }

                    Section {
                        Button {
                            manager.updatePending(updatedNotification)
                            dismiss()
                        } label: {
                            Label("Save Changes", systemImage: "checkmark.circle")
                        }
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(role: .destructive) {
                            showDiscardConfirm = true
                        } label: {
                            Label("Discard Draft", systemImage: "trash")
                        }

                        Button {
                            showApproveConfirm = true
                        } label: {
                            Label("Approve + Publish", systemImage: "paperplane")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Pending Draft")
            .navigationBarTitleDisplayMode(.inline)
            .tliNavBarStyle()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Discard Draft?", isPresented: $showDiscardConfirm) {
                Button("Discard", role: .destructive) {
                    manager.discardPending(notification)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the pending notification.")
            }
            .alert("Approve + Publish?", isPresented: $showApproveConfirm) {
                Button("Publish", role: .destructive) {
                    manager.updatePending(updatedNotification) // ensure latest changes are saved
                    manager.approvePending(updatedNotification)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will publish the notification to attendees.")
            }
        }
    }
}
