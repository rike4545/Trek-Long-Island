// Copyright Bryan Carroll. All rights reserved.
//
//  OpsCenterView.swift
//  Trek Long Island
//
//  Unified operator/master portal.
//

import SwiftUI

private enum OpsCenterWorkspace: String, CaseIterable, Identifiable {
    case overview
    case comms
    case liveOps
    case tickets
    case crm
    case master

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .comms: return "Comms"
        case .liveOps: return "Live Ops"
        case .tickets: return "Tickets"
        case .crm: return "CRM"
        case .master: return "Master"
        }
    }

    var symbolName: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.50percent"
        case .comms: return "bubble.left.and.bubble.right.fill"
        case .liveOps: return "dot.radiowaves.left.and.right"
        case .tickets: return "qrcode.viewfinder"
        case .crm: return "person.crop.rectangle.stack.fill"
        case .master: return "lock.shield.fill"
        }
    }
}

@MainActor
struct OpsCenterView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var opsStore = ConventionOpsStore.shared
    @ObservedObject private var feedbackStore = PanelFeedbackStore.shared
    @ObservedObject private var ticketStore = TicketOpsStore.shared
    @ObservedObject private var crmStore = CRMStore.shared
    @ObservedObject private var squareIntegrationStore = SquareIntegrationStore.shared
    @ObservedObject private var auditStore = OpsAuditStore.shared
    @ObservedObject private var analyticsStore = TLIAnalyticsStore.shared
    @ObservedObject private var usageInsightsStore = TLIUsageInsightsStore.shared
    @ObservedObject private var adminAuth = AdminAuthService.shared

    @AppStorage(TLIAdSettings.adsEnabledKey) private var adsEnabled: Bool = true
    @AppStorage(TLIAdSettings.hideForStaffKey) private var hideAdsWhenStaffUnlocked: Bool = true
    @AppStorage(TLIAdSettings.interstitialEnabledKey) private var interstitialEnabled: Bool = true
    @AppStorage(TLIAdSettings.interstitialCooldownSecondsKey) private var interstitialCooldownSeconds: Double = 180
    @AppStorage(TLIAdSettings.appOpenEnabledKey) private var appOpenEnabled: Bool = true
    @AppStorage(TLIAdSettings.appOpenCooldownSecondsKey) private var appOpenCooldownSeconds: Double = 900

    @AppStorage("TLI.OpsCenter.handoffNote") private var handoffNote: String = ""
    @AppStorage("TLI.OpsCenter.handoff.roomsChecked") private var handoffRoomsChecked: Bool = false
    @AppStorage("TLI.OpsCenter.handoff.pendingChecked") private var handoffPendingChecked: Bool = false
    @AppStorage("TLI.OpsCenter.handoff.incidentsChecked") private var handoffIncidentsChecked: Bool = false

    @State private var workspace: OpsCenterWorkspace = .overview

    @State private var showCoordinatorAccessSheet = false

    @State private var openLiveOps = false
    @State private var openNotificationsPublished = false
    @State private var openNotificationsPending = false
    @State private var openQR = false
    @State private var openCRM = false
    @State private var openSupport = false
    @State private var openSquareWizard = false

    @State private var showComposer = false
    @State private var composerSeed: AdminCreateNotificationSeed?

    private var criticalRooms: [RoomOpsState] {
        opsStore.roomStates.filter {
            $0.status == .atCapacity || $0.occupancyState == .overLimit
        }
    }

    private var unresolvedTicketCount: Int {
        opsStore.activeTickets(limit: 200).filter { $0.status != .resolved }.count
    }

    private var criticalTicketCount: Int {
        opsStore.activeTickets(limit: 200).filter {
            $0.status != .resolved && ($0.severity == .high || $0.severity == .emergency)
        }.count
    }

    private var handoffIncompleteCount: Int {
        [handoffRoomsChecked, handoffPendingChecked, handoffIncidentsChecked]
            .filter { !$0 }
            .count
    }

    private var handoffCompletionRatio: Double {
        Double(3 - handoffIncompleteCount) / 3.0
    }

    private var actorLabel: String {
        notifications.adminLevel.auditActorLabel
    }

    private var analyticsSnapshot: TLIAnalyticsSnapshot {
        analyticsStore.snapshot()
    }

    private var usageSnapshot: TLIUsageSnapshot {
        usageInsightsStore.snapshot()
    }

    var body: some View {
        List {
            dashboardHeaderSection

            if notifications.adminLevel != .none {
                priorityDeckSection
                dashboardSignalsSection
            }

            analyticsPulseSection
            deviceUsageSection

            if notifications.adminLevel == .none {
                unlockSection
            } else {
                quickLaunchSection
                workspaceSection
                workspaceBodySection
                handoffSection
            }

            auditSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Ops Center")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .navigationDestination(isPresented: $openLiveOps) {
            LiveOpsView()
        }
        .navigationDestination(isPresented: $openNotificationsPublished) {
            NotificationsView(initialMode: .published)
        }
        .navigationDestination(isPresented: $openNotificationsPending) {
            NotificationsView(initialMode: .pending)
        }
        .navigationDestination(isPresented: $openQR) {
            QRCodeView()
        }
        .navigationDestination(isPresented: $openCRM) {
            CRMView()
        }
        .navigationDestination(isPresented: $openSquareWizard) {
            SquareSetupWizardView()
        }
        .navigationDestination(isPresented: $openSupport) {
            SupportCenterView()
        }
        .sheet(isPresented: $showComposer) {
            AdminCreateNotificationView(seed: composerSeed)
        }
        .sheet(isPresented: $showCoordinatorAccessSheet) {
            CoordinatorAccessView()
        }
        .onAppear {
            analyticsStore.track(
                name: "ops_center_viewed",
                domain: "ops_center",
                actor: actorLabel.lowercased(),
                metadata: ["role": notifications.adminLevel.portalTitle.lowercased()]
            )
        }
        .onChange(of: workspace) { _, newValue in
            analyticsStore.track(
                name: "ops_workspace_opened",
                domain: "ops_center",
                actor: actorLabel.lowercased(),
                metadata: ["workspace": newValue.rawValue]
            )
        }
    }

    private var dashboardHeaderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TLITheme.accent(scheme).opacity(0.16))
                            .frame(width: 46, height: 46)

                        Image(systemName: notifications.adminLevel.statusSymbol)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(
                                notifications.adminLevel == .none
                                    ? AnyShapeStyle(.secondary)
                                    : AnyShapeStyle(TLITheme.accent(scheme))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notifications.adminLevel == .none ? "Operators Dashboard Locked" : "Operators Dashboard")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text(headerSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    if notifications.adminLevel != .none {
                        Button("Lock", role: .destructive) {
                            notifications.lockAdmin()
                            auditStore.log(actor: actorLabel, action: "Locked admin session")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                HStack(spacing: 10) {
                    dashboardBadge(title: "Role", value: notifications.adminLevel.portalTitle)
                    dashboardBadge(title: "Convention", value: notifications.conventionID)
                    dashboardBadge(
                        title: "Handoff",
                        value: notifications.adminLevel == .none
                            ? "Locked"
                            : handoffIncompleteCount == 0 ? "Ready" : "\(handoffIncompleteCount) open"
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var dashboardSignalsSection: some View {
        Section("Operator Signals") {
            LazyVGrid(columns: dashboardColumns, spacing: 12) {
                dashboardSignalCard(
                    title: "Unread Alerts",
                    value: "\(notifications.unreadCount)",
                    subtitle: notifications.unreadCount == 0 ? "Feed is quiet" : "Published updates waiting",
                    symbol: "bell.badge.fill",
                    tint: notifications.unreadCount == 0 ? .secondary : .orange
                )

                dashboardSignalCard(
                    title: "Pending Review",
                    value: "\(notifications.pendingNotifications.count)",
                    subtitle: notifications.canReviewChanges ? "Queue ready for triage" : "Reviewer access required",
                    symbol: "tray.full.fill",
                    tint: notifications.pendingNotifications.isEmpty ? .secondary : .yellow
                )

                dashboardSignalCard(
                    title: "Room Risk",
                    value: "\(criticalRooms.count)",
                    subtitle: criticalRooms.isEmpty ? "No critical rooms" : "Capacity attention needed",
                    symbol: "exclamationmark.octagon.fill",
                    tint: criticalRooms.isEmpty ? .secondary : .red
                )

                dashboardSignalCard(
                    title: "Open Tickets",
                    value: "\(unresolvedTicketCount)",
                    subtitle: criticalTicketCount == 0 ? "No critical escalations" : "\(criticalTicketCount) critical",
                    symbol: "cross.case.fill",
                    tint: criticalTicketCount == 0 ? .blue : .red
                )

                dashboardSignalCard(
                    title: "Flagged Feedback",
                    value: "\(feedbackStore.flaggedEntries.count)",
                    subtitle: feedbackStore.flaggedEntries.isEmpty ? "No panel issues surfaced" : "Audience follow-up needed",
                    symbol: "bubble.left.and.exclamationmark.bubble.right.fill",
                    tint: feedbackStore.flaggedEntries.isEmpty ? .secondary : .pink
                )

                dashboardSignalCard(
                    title: "CRM Follow-ups",
                    value: "\(crmStore.openTasks.count)",
                    subtitle: crmStore.overdueTasksCount == 0 ? "No overdue tasks" : "\(crmStore.overdueTasksCount) overdue",
                    symbol: "person.crop.rectangle.stack.fill",
                    tint: crmStore.overdueTasksCount == 0 ? .teal : .orange
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var priorityDeckSection: some View {
        Section("Priority Deck") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(priorityGradient)
                        .frame(width: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(overviewPrioritySummary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            priorityTag("Workspace", value: workspace.title)
                            priorityTag("Role", value: notifications.adminLevel.portalTitle)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shift handoff")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(handoffIncompleteCount == 0 ? "Complete" : "\(handoffIncompleteCount) remaining")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                    }

                    ProgressView(value: handoffCompletionRatio, total: 1)
                        .tint(TLITheme.accent(scheme))
                }

                if !criticalRooms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Critical rooms")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(criticalRooms.prefix(3)) { room in
                            HStack {
                                Text(room.roomName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TLITheme.textPrimary(scheme))
                                Spacer(minLength: 8)
                                Text(room.status.title)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(TLITheme.cardBackground(scheme), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(TLITheme.border(scheme).opacity(0.65), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var analyticsPulseSection: some View {
        let maxDaily = max(1, analyticsSnapshot.dailyPoints7d.map(\.count).max() ?? 1)

        return Section("Analytics Pulse") {
            HStack(spacing: 12) {
                metricChip(title: "1h", value: "\(analyticsSnapshot.events1h)", systemImage: "clock")
                metricChip(title: "24h", value: "\(analyticsSnapshot.events24h)", systemImage: "calendar")
                metricChip(title: "7d", value: "\(analyticsSnapshot.events7d)", systemImage: "calendar.badge.clock")
            }

            HStack(spacing: 12) {
                metricChip(title: "Actors", value: "\(analyticsSnapshot.uniqueActors24h)", systemImage: "person.3")
                metricChip(
                    title: "Failures",
                    value: "\(analyticsSnapshot.failures24h) (\(Int((analyticsSnapshot.failureRate24h * 100).rounded()))%)",
                    systemImage: "exclamationmark.triangle.fill"
                )
            }

            if !analyticsSnapshot.topActions24h.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Top actions (24h)")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(analyticsSnapshot.topActions24h.prefix(5)), id: \.name) { item in
                        HStack {
                            Text(item.name.replacingOccurrences(of: "_", with: " "))
                                .font(.caption)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(item.count)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("7-day trend")
                    .font(.subheadline.weight(.semibold))

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(analyticsSnapshot.dailyPoints7d) { point in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(TLITheme.accent(scheme).opacity(0.78))
                                .frame(
                                    width: 18,
                                    height: CGFloat(max(6, Int((Double(point.count) / Double(maxDaily)) * 56.0)))
                                )
                            Text(point.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var deviceUsageSection: some View {
        Section("Device Usage") {
            HStack(spacing: 12) {
                metricChip(title: "Launches", value: "\(usageSnapshot.totalLaunches)", systemImage: "app.badge")
                metricChip(title: "Sessions", value: "\(usageSnapshot.sessionCount)", systemImage: "play.circle")
                metricChip(title: "Avg Time", value: usageSnapshot.averageSessionLabel, systemImage: "timer")
            }

            HStack(spacing: 12) {
                metricChip(title: "Longest", value: usageSnapshot.longestSessionLabel, systemImage: "hourglass")
                metricChip(title: "Foreground", value: usageSnapshot.totalForegroundLabel, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                metricChip(title: "Top Tab", value: usageSnapshot.mostUsedTab, systemImage: "square.grid.2x2")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Device")
                    .font(.subheadline.weight(.semibold))
                Text(usageSnapshot.deviceModel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("OS: \(usageSnapshot.systemVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("App: \(usageSnapshot.appVersion) (\(usageSnapshot.buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let lastActiveAt = usageSnapshot.lastActiveAt {
                    Text("Last active \(lastActiveAt, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !usageSnapshot.tabCounts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Most used tabs")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(usageSnapshot.tabCounts.prefix(5)), id: \.tab) { item in
                        HStack {
                            Text(item.tab)
                                .font(.caption)
                            Spacer(minLength: 8)
                            Text("\(item.count)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func metricChip(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: systemImage)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSection: some View {
        Section("Session") {
            HStack(spacing: 10) {
                Image(systemName: notifications.adminLevel.statusSymbol)
                    .foregroundStyle(notifications.adminLevel == .none ? .secondary : TLITheme.accent(scheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(notifications.adminLevel.portalTitle)
                        .font(.subheadline.weight(.semibold))
                    Text("Convention: \(notifications.conventionID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if notifications.adminLevel != .none {
                    Button("Lock", role: .destructive) {
                        notifications.lockAdmin()
                        auditStore.log(actor: actorLabel, action: "Locked admin session")
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 14) {
                Label("Unread \(notifications.unreadCount)", systemImage: "bell.badge")
                Label("Pending \(notifications.pendingNotifications.count)", systemImage: "tray.full")
                Label("Tickets \(opsStore.activeTickets(limit: 200).count)", systemImage: "cross.case")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var quickLaunchSection: some View {
        Section("Quick Launch") {
            LazyVGrid(columns: dashboardColumns, spacing: 12) {
                opsLaunchCard(
                    title: "Live Ops",
                    subtitle: "Room risk, wait times, ticket escalation",
                    symbol: "dot.radiowaves.left.and.right",
                    tint: .orange,
                    isEnabled: notifications.isStaffUnlocked
                ) {
                    openLiveOps = true
                    auditStore.log(actor: actorLabel, action: "Opened Live Ops")
                }

                opsLaunchCard(
                    title: "Comms Feed",
                    subtitle: "Published alerts and pending review",
                    symbol: "bell.badge.fill",
                    tint: .blue,
                    isEnabled: true
                ) {
                    openNotificationsPublished = true
                    auditStore.log(actor: actorLabel, action: "Opened Notifications")
                }

                opsLaunchCard(
                    title: "Ticket QR Ops",
                    subtitle: "Generate, scan, and validate tickets",
                    symbol: "qrcode.viewfinder",
                    tint: .green,
                    isEnabled: notifications.isStaffUnlocked
                ) {
                    openQR = true
                    auditStore.log(actor: actorLabel, action: "Opened QR Tools")
                }

                opsLaunchCard(
                    title: "CRM Workspace",
                    subtitle: "Contacts, follow-ups, and outreach",
                    symbol: "person.crop.rectangle.stack.fill",
                    tint: .purple,
                    isEnabled: notifications.isStaffUnlocked
                ) {
                    openCRM = true
                    auditStore.log(actor: actorLabel, action: "Opened CRM")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var unlockSection: some View {
        Section("Unlock") {
            Text("Coordinator tools require Firebase sign-in with an approved allowlisted account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let email = adminAuth.signedInEmail, !email.isEmpty {
                Label(email, systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if adminAuth.isApproved {
                if notifications.adminLevel == .none {
                    Button("Resume Secure Session") {
                        Task {
                            let unlocked = await adminAuth.resumeProtectedSession()
                            if unlocked, let role = adminAuth.approvedRole {
                                auditStore.log(actor: role.auditActorLabel, action: "Unlocked Ops Center", details: "Role \(role.portalTitle)")
                            } else {
                                auditStore.log(actor: "Unknown", action: "Failed secure session resume")
                            }
                        }
                    }
                } else {
                    Label("\(notifications.adminLevel.portalTitle) session active", systemImage: notifications.adminLevel.statusSymbol)
                        .font(.caption)
                }
            } else {
                Button("Sign In for Coordinator Access") {
                    showCoordinatorAccessSheet = true
                }
            }
        }
    }

    private var workspaceSection: some View {
        Section("Workspace") {
            VStack(alignment: .leading, spacing: 10) {
                Text(workspaceSummary(for: workspace))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(OpsCenterWorkspace.allCases) { item in
                            Button {
                                workspace = item
                            } label: {
                                Label(item.title, systemImage: item.symbolName)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        workspace == item
                                        ? TLITheme.accent(scheme).opacity(0.24)
                                        : TLITheme.cardBackground(scheme),
                                        in: Capsule()
                                    )
                            }
                            .foregroundStyle(
                                workspace == item
                                    ? AnyShapeStyle(TLITheme.accent(scheme))
                                    : AnyShapeStyle(TLITheme.textPrimary(scheme))
                            )
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var workspaceBodySection: some View {
        switch workspace {
        case .overview:
            overviewWorkspace
        case .comms:
            commsWorkspace
        case .liveOps:
            liveOpsWorkspace
        case .tickets:
            ticketsWorkspace
        case .crm:
            crmWorkspace
        case .master:
            masterWorkspace
        }
    }

    @ViewBuilder
    private var overviewWorkspace: some View {
        Section("Command Overview") {
            if criticalRooms.isEmpty && notifications.pendingNotifications.isEmpty && criticalTicketCount == 0 {
                Text("All key command signals are stable. Use Quick Launch to jump into the area you want to monitor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority focus")
                        .font(.subheadline.weight(.semibold))
                    Text(overviewPrioritySummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            overviewSessionPanel
        }

        Section("Launch") {
            Button {
                openLiveOps = true
                auditStore.log(actor: actorLabel, action: "Opened Live Ops")
            } label: {
                Label("Live Ops Dashboard", systemImage: "dot.radiowaves.left.and.right")
            }
            .disabled(!notifications.isStaffUnlocked)

            Button {
                openNotificationsPublished = true
                auditStore.log(actor: actorLabel, action: "Opened Notifications")
            } label: {
                Label("Notifications Console", systemImage: "bell.badge")
            }

            Button {
                openQR = true
                auditStore.log(actor: actorLabel, action: "Opened QR Tools")
            } label: {
                Label("Ticket QR Ops", systemImage: "qrcode.viewfinder")
            }
            .disabled(!notifications.isStaffUnlocked)

            Button {
                openCRM = true
                auditStore.log(actor: actorLabel, action: "Opened CRM")
            } label: {
                Label("Convention CRM", systemImage: "person.crop.rectangle.stack.fill")
            }
            .disabled(!notifications.isStaffUnlocked)

            Button {
                openSupport = true
                auditStore.log(actor: actorLabel, action: "Opened Support Center")
            } label: {
                Label("Support Center", systemImage: "cross.case.fill")
            }

            if notifications.isSuperAdminUnlocked {
                Button {
                    workspace = .master
                    auditStore.log(actor: actorLabel, action: "Opened Master monetization controls")
                } label: {
                    Label("Open Master Monetization Controls", systemImage: "lock.shield")
                }
            }
        }

        Section("Role Capabilities") {
            ForEach(notifications.adminLevel.portalCapabilities, id: \.self) { capability in
                Text("• \(capability)")
                    .font(.subheadline)
            }
        }
    }

    private var dashboardColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: hSizeClass == .regular ? 220 : 150), spacing: 12, alignment: .top)
        ]
    }

    private var overviewSessionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: notifications.adminLevel.statusSymbol)
                    .foregroundStyle(TLITheme.accent(scheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(notifications.adminLevel.portalTitle) session active")
                        .font(.subheadline.weight(.semibold))
                    Text("Convention: \(notifications.conventionID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 14) {
                Label("Unread \(notifications.unreadCount)", systemImage: "bell.badge")
                Label("Pending \(notifications.pendingNotifications.count)", systemImage: "tray.full")
                Label("Tickets \(opsStore.activeTickets(limit: 200).count)", systemImage: "cross.case")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
        )
    }

    private var headerSummaryText: String {
        if notifications.adminLevel == .none {
            return "Unlock a staff role to access comms, live operations, tickets, CRM, and master controls."
        }

        return "\(notifications.adminLevel.portalTitle) access is active. Track room pressure, comms, tickets, and handoff readiness from one place."
    }

    private var priorityGradient: LinearGradient {
        LinearGradient(
            colors: [
                TLITheme.accent(scheme),
                TLITheme.accent(scheme).opacity(0.55),
                RisaTheme.accentSecondary(scheme)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var overviewPrioritySummary: String {
        if !criticalRooms.isEmpty {
            return "\(criticalRooms.count) room\(criticalRooms.count == 1 ? "" : "s") need immediate capacity attention."
        }
        if notifications.pendingNotifications.count > 0 {
            return "\(notifications.pendingNotifications.count) pending notification\(notifications.pendingNotifications.count == 1 ? "" : "s") waiting in the review queue."
        }
        if criticalTicketCount > 0 {
            return "\(criticalTicketCount) critical ticket\(criticalTicketCount == 1 ? "" : "s") should be triaged now."
        }
        if handoffIncompleteCount > 0 {
            return "Shift handoff is not complete yet. \(handoffIncompleteCount) checklist item\(handoffIncompleteCount == 1 ? "" : "s") remain open."
        }
        return "No critical issues detected."
    }

    private func workspaceSummary(for workspace: OpsCenterWorkspace) -> String {
        switch workspace {
        case .overview:
            return "High-level command view with launches, role scope, and current priorities."
        case .comms:
            return "Published alerts, pending review, and drafting tools for operator communications."
        case .liveOps:
            return "Room capacity, incident pressure, and live floor controls."
        case .tickets:
            return "QR generation, scanning, and ticket flow controls."
        case .crm:
            return "Contacts, tasks, and relationship follow-up signals."
        case .master:
            return "Monetization settings, thresholds, and sensitive operator controls."
        }
    }

    private func dashboardBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
        )
    }

    private func priorityTag(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
        )
    }

    private func dashboardSignalCard(
        title: String,
        value: String,
        subtitle: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Circle()
                    .fill(tint.opacity(0.9))
                    .frame(width: 10, height: 10)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
        )
    }

    private func opsLaunchCard(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(0.16))
                            .frame(width: 38, height: 38)

                        Image(systemName: symbol)
                            .font(.headline)
                            .foregroundStyle(tint)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(isEnabled ? tint : .secondary)
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isEnabled ? TLITheme.textPrimary(scheme) : .secondary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TLITheme.border(scheme).opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }

    private var commsWorkspace: some View {
        Section("Alerts & Queue") {
            Label("Published unread: \(notifications.unreadCount)", systemImage: "envelope.badge")
            Label("Pending drafts: \(notifications.pendingNotifications.count)", systemImage: "tray.full")

            Button {
                openNotificationsPublished = true
                auditStore.log(actor: actorLabel, action: "Opened published notifications")
            } label: {
                Label("Open Published Feed", systemImage: "newspaper")
            }

            if notifications.canReviewChanges {
                Button {
                    openNotificationsPending = true
                    auditStore.log(actor: actorLabel, action: "Opened pending queue")
                } label: {
                    Label("Open Pending Queue", systemImage: "tray.full")
                }
            }

            if notifications.canSubmitNotifications {
                Button {
                    composerSeed = nil
                    showComposer = true
                    auditStore.log(actor: actorLabel, action: "Opened alert composer")
                } label: {
                    Label("Draft New Alert", systemImage: "square.and.pencil")
                }

                if let room = criticalRooms.first?.roomName {
                    Button {
                        composerSeed = .roomEscalation(roomName: room)
                        showComposer = true
                        auditStore.log(actor: actorLabel, action: "Started at-capacity alert", details: room)
                    } label: {
                        Label("Create At-Capacity Alert for \(room)", systemImage: "exclamationmark.triangle.fill")
                    }
                }
            } else {
                Text("Notifier or Master access is required to draft alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var liveOpsWorkspace: some View {
        Section("Live Operations") {
            if notifications.isSuperAdminUnlocked {
                Toggle("Show wait times", isOn: Binding(
                    get: { opsStore.waitTimesEnabled },
                    set: {
                        opsStore.setWaitTimesEnabled($0)
                        auditStore.log(actor: actorLabel, action: "Set wait times", details: $0 ? "ON" : "OFF")
                    }
                ))
            }

            if criticalRooms.isEmpty {
                Text("No rooms currently marked at capacity or over compliance limits.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(criticalRooms.prefix(6)) { room in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(room.roomName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(room.status.title) • CO \(room.occupancyLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            Label("Flagged feedback: \(feedbackStore.flaggedEntries.count)", systemImage: "bubble.left.and.exclamationmark.bubble.right")

            Button {
                openLiveOps = true
                auditStore.log(actor: actorLabel, action: "Opened Live Ops from workspace")
            } label: {
                Label("Open Full Live Ops", systemImage: "arrow.right.circle")
            }
            .disabled(!notifications.canModifyRoomStatus && !notifications.canReviewChanges && !notifications.isSuperAdminUnlocked)
        }
    }

    private var ticketsWorkspace: some View {
        Section("Ticket Operations") {
            Toggle("Enable ticket QR generation", isOn: Binding(
                get: { ticketStore.isTicketGenerationEnabled },
                set: {
                    ticketStore.setTicketGenerationEnabled($0)
                    auditStore.log(actor: actorLabel, action: "Set ticket generation", details: $0 ? "ON" : "OFF")
                }
            ))

            Toggle("Enable ticket scanning", isOn: Binding(
                get: { ticketStore.isTicketScanningEnabled },
                set: {
                    ticketStore.setTicketScanningEnabled($0)
                    auditStore.log(actor: actorLabel, action: "Set ticket scanning", details: $0 ? "ON" : "OFF")
                }
            ))

            Label("Orders: \(ticketStore.tally.orderCount)", systemImage: "ticket.fill")
            Label("Scanned: \(ticketStore.tally.totalScanned)/\(ticketStore.tally.totalPurchased)", systemImage: "qrcode")

            Button {
                Task {
                    await ticketStore.importSquareOrders()
                    auditStore.log(actor: actorLabel, action: "Imported Square ticket orders", details: ticketStore.lastSquareImportMessage ?? "Completed")
                }
            } label: {
                Label("Import Square Orders", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(!squareIntegrationStore.connection.canSyncOrders)

            if let lastSquareImportMessage = ticketStore.lastSquareImportMessage {
                Text(lastSquareImportMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                openSquareWizard = true
                auditStore.log(actor: actorLabel, action: "Opened Square setup wizard from tickets workspace")
            } label: {
                Label("Open Square Wizard", systemImage: "list.clipboard")
            }

            Button {
                openQR = true
                auditStore.log(actor: actorLabel, action: "Opened QR tools from tickets workspace")
            } label: {
                Label("Open QR Tools", systemImage: "arrow.right.circle")
            }
        }
    }

    private var crmWorkspace: some View {
        Section("CRM") {
            Label("Contacts: \(crmStore.contacts.count)", systemImage: "person.2.fill")
            Label("Open follow-ups: \(crmStore.openTasks.count)", systemImage: "checklist")
            Label("Overdue: \(crmStore.overdueTasksCount)", systemImage: "exclamationmark.triangle.fill")
            Label("Touches (24h): \(crmStore.recentTouchCount)", systemImage: "waveform.path.ecg")

            Toggle("Enable Square integration", isOn: Binding(
                get: { squareIntegrationStore.connection.cmsSyncEnabled },
                set: {
                    squareIntegrationStore.setCMSSyncEnabled($0)
                    auditStore.log(actor: actorLabel, action: "Set Square integration", details: $0 ? "ON" : "OFF")
                }
            ))
            .disabled(!notifications.isSuperAdminUnlocked)

            Label(squareIntegrationStore.connection.status.title, systemImage: squareStatusSymbol)
            Text(squareIntegrationStore.connection.statusSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !notifications.isSuperAdminUnlocked {
                Text("Master role required to change Square integration state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                openSquareWizard = true
                auditStore.log(actor: actorLabel, action: "Opened Square setup wizard from CRM workspace")
            } label: {
                Label("Open Square Wizard", systemImage: "list.clipboard")
            }

            Button {
                openCRM = true
                auditStore.log(actor: actorLabel, action: "Opened CRM workspace")
            } label: {
                Label("Open Full CRM", systemImage: "arrow.right.circle")
            }
        }
    }

    private var squareStatusSymbol: String {
        switch squareIntegrationStore.connection.status {
        case .connected:
            return "link.circle.fill"
        case .pending:
            return "hourglass.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .disconnected:
            return "link.badge.minus"
        }
    }

    @ViewBuilder
    private var masterWorkspace: some View {
        if !notifications.isSuperAdminUnlocked {
            Section("Master Controls") {
                Text("Master role required for monetization and sensitive operator controls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            if !TLIAdAvailability.areAdsDisabledForCurrentTarget {
                Section("Monetization") {
                    Toggle("Show sponsored ads", isOn: $adsEnabled)
                    Toggle("Hide ads while staff mode is unlocked", isOn: $hideAdsWhenStaffUnlocked)
                        .disabled(!adsEnabled)

                    Toggle("Enable interstitial ads", isOn: $interstitialEnabled)
                        .disabled(!adsEnabled)

                    HStack {
                        Text("Interstitial cooldown")
                        Spacer(minLength: 8)
                        Text("\(Int(interstitialCooldownSeconds)) sec")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $interstitialCooldownSeconds, in: 120...900, step: 60)
                        .disabled(!adsEnabled || !interstitialEnabled)

                    Toggle("Enable app-open ads", isOn: $appOpenEnabled)
                        .disabled(!adsEnabled)

                    HStack {
                        Text("App-open cooldown")
                        Spacer(minLength: 8)
                        Text("\(Int(appOpenCooldownSeconds)) sec")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $appOpenCooldownSeconds, in: 300...21600, step: 300)
                        .disabled(!adsEnabled || !appOpenEnabled)
                }
            }

            Section("Operational Guardrails") {
                Stepper(
                    "Low score threshold: \(feedbackStore.lowScoreThreshold, specifier: "%.1f")",
                    value: Binding(
                        get: { feedbackStore.lowScoreThreshold },
                        set: {
                            feedbackStore.setLowScoreThreshold($0)
                            auditStore.log(actor: actorLabel, action: "Updated low score threshold", details: String(format: "%.1f", $0))
                        }
                    ),
                    in: 1.0...5.0,
                    step: 0.5
                )

                Stepper(
                    "Min responses for alert: \(feedbackStore.minResponsesForAlert)",
                    value: Binding(
                        get: { feedbackStore.minResponsesForAlert },
                        set: {
                            feedbackStore.setMinResponsesForAlert($0)
                            auditStore.log(actor: actorLabel, action: "Updated min responses", details: "\($0)")
                        }
                    ),
                    in: 1...50
                )
            }

            Section("Convention Security Tokens") {
                if notifications.isConventionPasswordWindow() {
                    let rotating = notifications.rotatingPasswordsForTodayForDisplay()
                    ForEach(rotating.keys.sorted(), id: \.self) { role in
                        if let value = rotating[role] {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(role)
                                    .font(.subheadline.weight(.semibold))
                                Text(value)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                } else {
                    Text("Convention security tokens are only visible during the convention window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var handoffSection: some View {
        Section("Shift Handoff") {
            Toggle("Room status pass completed", isOn: $handoffRoomsChecked)
            Toggle("Pending queue reviewed", isOn: $handoffPendingChecked)
            Toggle("Incidents reviewed", isOn: $handoffIncidentsChecked)

            TextField("Handoff notes", text: $handoffNote, axis: .vertical)
                .lineLimit(2...6)

            Text("Use this note for operator-to-operator handoff at shift change.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var auditSection: some View {
        Section("Audit Trail") {
            if auditStore.entries.isEmpty {
                Text("No audit entries yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(auditStore.entries.prefix(20)) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.action)
                            .font(.subheadline.weight(.semibold))
                        Text("\(entry.actor) • \(entry.timestamp, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !entry.details.isEmpty {
                            Text(entry.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if notifications.isSuperAdminUnlocked {
                Button("Clear Audit Trail", role: .destructive) {
                    auditStore.clear()
                    auditStore.log(actor: actorLabel, action: "Cleared audit trail")
                }
            }
        }
    }
}

private extension NotificationManager.AdminLevel {
    var portalTitle: String {
        switch self {
        case .none: return "Locked"
        case .watcher: return "Watcher"
        case .notifier: return "Notifier"
        case .reviewer: return "Reviewer"
        case .superAdmin: return "Master"
        }
    }

    var statusSymbol: String {
        switch self {
        case .none: return "lock.fill"
        case .watcher: return "eye.fill"
        case .notifier: return "plus.bubble.fill"
        case .reviewer: return "checkmark.seal.fill"
        case .superAdmin: return "lock.open.trianglebadge.exclamationmark"
        }
    }

    var auditActorLabel: String {
        switch self {
        case .none: return "Guest"
        case .watcher: return "Watcher"
        case .notifier: return "Notifier"
        case .reviewer: return "Reviewer"
        case .superAdmin: return "Master"
        }
    }

    var portalCapabilities: [String] {
        switch self {
        case .none:
            return ["Unlock required"]
        case .watcher:
            return [
                "Update room status and occupancy in Live Ops",
                "Use ticket QR operations",
                "View operator dashboards"
            ]
        case .notifier:
            return [
                "Draft and submit notifications",
                "Use ticket QR operations",
                "View operator dashboards"
            ]
        case .reviewer:
            return [
                "Moderate pending notification drafts",
                "Review incidents and flagged feedback",
                "Update room status and occupancy"
            ]
        case .superAdmin:
            return [
                "All watcher/notifier/reviewer permissions",
                "Delete published notifications",
                "Manage wait-times and monetization controls",
                "View convention security tokens and audit tools"
            ]
        }
    }
}

#Preview {
    NavigationStack {
        OpsCenterView()
    }
}
