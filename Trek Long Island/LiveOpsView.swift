// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

private enum LiveOpsMetricFocus: String, CaseIterable, Identifiable {
    case risk
    case occupancy
    case wait

    var id: String { rawValue }

    var title: String {
        switch self {
        case .risk: return "Risk"
        case .occupancy: return "Occupancy"
        case .wait: return "Wait"
        }
    }
}

private struct LiveOpsRoomSnapshot: Identifiable {
    let state: RoomOpsState
    let occupancyRatio: Double
    let waitMinutes: Int
    let riskScore: Double

    var id: String { state.id }
}

@MainActor
struct LiveOpsView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var nearbyRoomCountStore: NearbyRoomCountStore
    @StateObject private var loader = ICSLoader()
    @ObservedObject private var opsStore = ConventionOpsStore.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var feedbackStore = PanelFeedbackStore.shared
    @ObservedObject private var ticketOpsStore = TicketOpsStore.shared

    @State private var selectedRoomName: String = ""
    @State private var selectedStatus: RoomLiveStatus = .open
    @State private var selectedWaitMinutes: Int = 0
    @State private var includeWait: Bool = false
    @State private var selectedOccupancyCount: Int = 0
    @State private var selectedOccupancyLimit: Int = 0
    @State private var staffNote: String = ""
    @State private var visualMetricFocus: LiveOpsMetricFocus = .risk
    @State private var showCriticalOnly: Bool = false
    @State private var selectedVisualizerRoomID: String?
    @State private var feedbackExportURL: URL?
    @State private var feedbackExportError: String?

    private var happeningNow: [ICSParsedEvent] {
        let now = Date()
        return loader.events
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
    }

    private var startingSoon: [ICSParsedEvent] {
        let now = Date()
        let soon = now.addingTimeInterval(60 * 60)
        return loader.events
            .filter { $0.startDate > now && $0.startDate <= soon }
            .sorted { $0.startDate < $1.startDate }
    }

    private var canEditOps: Bool {
        notifications.canModifyRoomStatus || notifications.canReviewChanges || notifications.isSuperAdminUnlocked
    }

    private var canModifyRoomStatus: Bool {
        notifications.canModifyRoomStatus || notifications.isSuperAdminUnlocked
    }

    private var canReviewChanges: Bool {
        notifications.canReviewChanges
    }

    private var isSuperAdmin: Bool {
        notifications.adminLevel == .superAdmin
    }

    private var canViewPanelInsights: Bool {
        notifications.isStaffUnlocked
    }

    private var waitTimesOffMessage: String {
        "Badges will be checked at the entrance to each room and will adhere to capacity limits."
    }

    private var roomOptions: [String] {
        let names = Set(loader.events.map(\.room)).union(opsStore.roomStates.map(\.roomName))
        return names.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.sorted()
    }

    private var overLimitRooms: [RoomOpsState] {
        opsStore.roomStates.filter { $0.occupancyState == .overLimit }
    }

    private var atCapacityRooms: [RoomOpsState] {
        opsStore.roomStates.filter { $0.status == .atCapacity }
    }

    private var unresolvedTicketCount: Int {
        opsStore.activeTickets(limit: 200).filter { $0.status != .resolved }.count
    }

    private var criticalTicketCount: Int {
        opsStore.activeTickets(limit: 200).filter {
            $0.status != .resolved && ($0.severity == .high || $0.severity == .emergency)
        }.count
    }

    private var roomSnapshots: [LiveOpsRoomSnapshot] {
        opsStore.roomStates.map { state in
            let occupancyRatio: Double = {
                guard state.occupancyLimit > 0 else { return 0 }
                return max(0, Double(state.occupancyCount) / Double(max(1, state.occupancyLimit)))
            }()
            let waitMinutes = max(0, state.waitMinutes ?? 0)
            let waitScore = min(Double(waitMinutes) / 60.0, 1.0)
            let occupancyScore = min(occupancyRatio, 1.0)
            let statusScore: Double = {
                switch state.status {
                case .open: return 0.06
                case .cleared: return 0.04
                case .filling: return 0.32
                case .atCapacity: return 0.68
                }
            }()
            let overLimitBoost = state.occupancyState == .overLimit ? 0.30 : 0.0
            let riskScore = min(1.0, statusScore + (occupancyScore * 0.45) + (waitScore * 0.30) + overLimitBoost)

            return LiveOpsRoomSnapshot(
                state: state,
                occupancyRatio: occupancyRatio,
                waitMinutes: waitMinutes,
                riskScore: riskScore
            )
        }
    }

    private var filteredSnapshots: [LiveOpsRoomSnapshot] {
        let source: [LiveOpsRoomSnapshot]
        if showCriticalOnly {
            source = roomSnapshots.filter {
                $0.riskScore >= 0.55
                    || $0.state.status == .atCapacity
                    || $0.state.occupancyState == .overLimit
            }
        } else {
            source = roomSnapshots
        }

        return source.sorted { lhs, rhs in
            switch visualMetricFocus {
            case .risk:
                if lhs.riskScore == rhs.riskScore {
                    return lhs.state.roomName.localizedCaseInsensitiveCompare(rhs.state.roomName) == .orderedAscending
                }
                return lhs.riskScore > rhs.riskScore
            case .occupancy:
                if lhs.occupancyRatio == rhs.occupancyRatio {
                    return lhs.state.roomName.localizedCaseInsensitiveCompare(rhs.state.roomName) == .orderedAscending
                }
                return lhs.occupancyRatio > rhs.occupancyRatio
            case .wait:
                if lhs.waitMinutes == rhs.waitMinutes {
                    return lhs.state.roomName.localizedCaseInsensitiveCompare(rhs.state.roomName) == .orderedAscending
                }
                return lhs.waitMinutes > rhs.waitMinutes
            }
        }
    }

    private var activeSnapshotSelection: LiveOpsRoomSnapshot? {
        if let id = selectedVisualizerRoomID,
           let matched = filteredSnapshots.first(where: { $0.id == id }) {
            return matched
        }
        return filteredSnapshots.first
    }

    private var detectedCountForSelectedRoom: Int? {
        nearbyRoomCountStore.automaticCount(for: selectedRoomName)
    }

    var body: some View {
        Group {
            if notifications.isStaffUnlocked {
                List {
                    Section("Operator Dashboard") {
                        HStack {
                            metricPill(title: "Over CO", value: "\(overLimitRooms.count)", systemImage: "exclamationmark.octagon.fill")
                            Spacer(minLength: 8)
                            metricPill(title: "At Capacity", value: "\(atCapacityRooms.count)", systemImage: "person.3.fill")
                            Spacer(minLength: 8)
                            metricPill(title: "Open Tickets", value: "\(unresolvedTicketCount)", systemImage: "cross.case.fill")
                        }

                        HStack {
                            metricPill(
                                title: "Scanned",
                                value: "\(ticketOpsStore.tally.totalScanned)/\(ticketOpsStore.tally.totalPurchased)",
                                systemImage: "qrcode.viewfinder"
                            )
                            Spacer(minLength: 8)
                            metricPill(
                                title: "Flagged Feedback",
                                value: "\(feedbackStore.flaggedEntries.count)",
                                systemImage: "bubble.left.and.exclamationmark.bubble.right"
                            )
                            Spacer(minLength: 8)
                            metricPill(
                                title: "Critical",
                                value: "\(criticalTicketCount)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                        }

                        if overLimitRooms.isEmpty && atCapacityRooms.isEmpty && criticalTicketCount == 0 {
                            Text("All key operator signals look stable right now.")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        } else {
                            if !overLimitRooms.isEmpty {
                                Text("CO over limit: \(overLimitRooms.map(\.roomName).joined(separator: ", "))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                            if !atCapacityRooms.isEmpty {
                                Text("At capacity: \(atCapacityRooms.map(\.roomName).joined(separator: ", "))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                            if criticalTicketCount > 0 {
                                Text("Critical unresolved tickets: \(criticalTicketCount)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

            Section("Interactive Ops Visualizer") {
                interactiveOpsVisualizerSection
            }

            Section("Live Sessions") {
                if happeningNow.isEmpty {
                    Text("No sessions are live right now.")
                        .foregroundStyle(Color.primary.opacity(0.72))
                } else {
                    ForEach(happeningNow.prefix(8), id: \.id) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(event.room)
                                Text("ends \(event.endDate, style: .time)")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                        }
                        .padding(.vertical, 2)
                    }
                }

                if !startingSoon.isEmpty {
                    Divider()
                    Text("Starting within 1 hour")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.72))
                    ForEach(startingSoon.prefix(6), id: \.id) { event in
                        HStack {
                            Text(event.title)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(event.startDate, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }
                }
            }

            Section("Room Status") {
                ForEach(opsStore.roomStates) { state in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: state.status.symbolName)
                                .foregroundStyle(RisaTheme.accent(scheme))
                            Text(state.roomName)
                                .font(.headline)
                            Spacer(minLength: 8)
                            Text(state.status.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }

                        HStack(spacing: 12) {
                            Text(opsStore.waitTimesEnabled ? state.waitLabel : waitTimesOffMessage)
                                .font(.subheadline)
                                .lineLimit(2)
                            Text("Updated \(state.lastUpdated, style: .relative) by \(state.updatedBy)")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: state.occupancyState.symbolName)
                                .foregroundStyle(state.occupancyState == .overLimit ? .red : (state.occupancyState == .compliant ? .green : .secondary))
                            Text("CO: \(state.occupancyLabel)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.primary.opacity(0.72))
                            Text("•")
                                .foregroundStyle(Color.primary.opacity(0.72))
                            Text(state.occupancyState.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(state.occupancyState == .overLimit ? .red : .secondary)
                        }

                        if !state.note.isEmpty {
                            Text(state.note)
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Crowd Guide") {
                crowdGuideRow(status: .open, meaning: "Normal traffic. Walk-ins should move quickly.")
                crowdGuideRow(status: .filling, meaning: "Demand is rising. Join lines early and follow queue markers.")
                crowdGuideRow(status: .atCapacity, meaning: "Room is full. Use overflow or pick an alternate nearby session.")
                crowdGuideRow(status: .cleared, meaning: "Previous crowd has dispersed. Entry lanes are reopening.")

                Text(opsStore.waitTimesEnabled
                     ? "Wait times are estimates from staff spot checks and can change quickly."
                     : waitTimesOffMessage)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            if canViewPanelInsights { panelInsightsSection }

            if canReviewChanges { flaggedFeedbackQueueSection }

            if canEditOps {
                if isSuperAdmin {
                    Section("Super Admin Controls") {
                        Toggle("Show wait times", isOn: Binding(
                            get: { opsStore.waitTimesEnabled },
                            set: { opsStore.setWaitTimesEnabled($0) }
                        ))

                        if !opsStore.waitTimesEnabled {
                            Text(waitTimesOffMessage)
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }

                        Stepper(
                            "Low score threshold: \(feedbackStore.lowScoreThreshold, specifier: "%.1f")",
                            value: Binding(
                                get: { feedbackStore.lowScoreThreshold },
                                set: { feedbackStore.setLowScoreThreshold($0) }
                            ),
                            in: 1.0...5.0,
                            step: 0.5
                        )

                        Stepper(
                            "Min responses for alert: \(feedbackStore.minResponsesForAlert)",
                            value: Binding(
                                get: { feedbackStore.minResponsesForAlert },
                                set: { feedbackStore.setMinResponsesForAlert($0) }
                            ),
                            in: 1...50
                        )
                    }
                }

                if canModifyRoomStatus {
                    Section("Room Status Update") {
                        Picker("Room", selection: $selectedRoomName) {
                            ForEach(roomOptions, id: \.self) { room in
                                Text(room).tag(room)
                            }
                        }

                        Picker("Status", selection: $selectedStatus) {
                            ForEach(RoomLiveStatus.allCases) { status in
                                Text(status.title).tag(status)
                            }
                        }

                        Toggle("Include wait time", isOn: $includeWait)
                            .disabled(!opsStore.waitTimesEnabled)

                        if !opsStore.waitTimesEnabled {
                            Text("Wait times are currently disabled by super admin.")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }

                        if includeWait && opsStore.waitTimesEnabled {
                            Stepper("Wait: \(selectedWaitMinutes) minutes", value: $selectedWaitMinutes, in: 0...240, step: 5)
                        }

                        Stepper("Current room count: \(selectedOccupancyCount)", value: $selectedOccupancyCount, in: 0...20000, step: 1)
                        if let detectedCountForSelectedRoom {
                            HStack {
                                Label("Nearby detected apps: \(detectedCountForSelectedRoom)", systemImage: "dot.radiowaves.left.and.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.primary.opacity(0.72))
                                Spacer(minLength: 8)
                                Button("Use Detected Count") {
                                    selectedOccupancyCount = detectedCountForSelectedRoom
                                }
                                .buttonStyle(.bordered)
                            }
                        } else if nearbyRoomCountStore.isEnabled {
                            Text("No nearby app count detected for this room yet.")
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                        Stepper("CO room limit: \(selectedOccupancyLimit)", value: $selectedOccupancyLimit, in: 0...20000, step: 1)

                        TextField("Ops note (optional)", text: $staffNote)

                        Button("Save Room Update") {
                            let updatedBy: String
                            switch notifications.adminLevel {
                            case .superAdmin: updatedBy = "Master"
                            case .reviewer: updatedBy = "Reviewer"
                            case .watcher: updatedBy = "Watcher"
                            case .notifier: updatedBy = "Notifier"
                            case .none: updatedBy = "Staff"
                            }

                            opsStore.upsertRoomState(
                                roomName: selectedRoomName,
                                status: selectedStatus,
                                waitMinutes: (includeWait && opsStore.waitTimesEnabled) ? selectedWaitMinutes : nil,
                                note: staffNote,
                                updatedBy: updatedBy
                            )
                            var occupancyState = opsStore.state(for: selectedRoomName)
                            occupancyState.occupancyCount = selectedOccupancyCount
                            occupancyState.occupancyLimit = selectedOccupancyLimit
                            occupancyState.updatedBy = updatedBy
                            occupancyState.lastUpdated = .now
                            opsStore.upsertRoomState(occupancyState)
                            staffNote = ""
                        }
                        .disabled(selectedRoomName.isEmpty)
                    }
                }

                if canReviewChanges {
                    Section("Incident Review Board") {
                        let tickets = opsStore.activeTickets(limit: 8)
                        if tickets.isEmpty {
                            Text("No active support tickets.")
                                .foregroundStyle(Color.primary.opacity(0.72))
                        } else {
                            ForEach(tickets) { ticket in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(ticket.category.title)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.ultraThinMaterial, in: Capsule())
                                        Label(ticket.privacy.title, systemImage: ticket.privacy.symbolName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                        Spacer(minLength: 8)
                                        Menu(ticket.status.title) {
                                            ForEach(SupportTicketStatus.allCases) { status in
                                                Button(status.title) {
                                                    opsStore.updateTicketStatus(id: ticket.id, status: status)
                                                }
                                            }
                                        }
                                    }
                                    Text(ticket.title)
                                        .font(.headline)
                                    Text("\(ticket.location) • \(ticket.severity.title) • \(ticket.updatedAt, style: .relative)")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
                }
                .scrollContentBackground(.hidden)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundStyle(TLITheme.accent(scheme))
                    Text("Live Ops Locked")
                        .font(.headline)
                    Text("Unlock a staff role in Ops Center to continue.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.72))
                    NavigationLink {
                        OpsCenterView()
                    } label: {
                        Label("Open Ops Center", systemImage: "person.crop.rectangle.stack.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Live Ops")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if notifications.isStaffUnlocked {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lock") {
                        notifications.lockAdmin()
                    }
                }
            }
        }
        .task {
            if notifications.isStaffUnlocked {
                if loader.events.isEmpty {
                    loader.load()
                }
                if selectedRoomName.isEmpty {
                    selectedRoomName = roomOptions.first ?? ""
                }
            }
        }
        .onChange(of: roomOptions) { _, newValue in
            if selectedRoomName.isEmpty {
                selectedRoomName = newValue.first ?? ""
            }
        }
        .onChange(of: selectedRoomName) { _, newValue in
            guard !newValue.isEmpty else { return }
            let state = opsStore.state(for: newValue)
            selectedStatus = state.status
            selectedWaitMinutes = state.waitMinutes ?? 0
            includeWait = state.waitMinutes != nil
            selectedOccupancyCount = state.occupancyCount
            selectedOccupancyLimit = state.occupancyLimit
            staffNote = state.note
        }
        .onChange(of: filteredSnapshots.map(\.id)) { _, ids in
            if let selectedVisualizerRoomID, ids.contains(selectedVisualizerRoomID) {
                return
            }
            selectedVisualizerRoomID = ids.first
        }
    }

    private func metricPill(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var interactiveOpsVisualizerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Focus", selection: $visualMetricFocus) {
                ForEach(LiveOpsMetricFocus.allCases) { focus in
                    Text(focus.title).tag(focus)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Show critical rooms only", isOn: $showCriticalOnly)
                .font(.caption.weight(.semibold))

            if filteredSnapshots.isEmpty {
                Text("No rooms match this filter.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                ForEach(filteredSnapshots) { snapshot in
                    Button {
                        selectedVisualizerRoomID = snapshot.id
                    } label: {
                        visualizerRoomRow(snapshot, isSelected: snapshot.id == activeSnapshotSelection?.id)
                    }
                    .buttonStyle(.plain)
                }

                if let selected = activeSnapshotSelection {
                    Divider()
                    selectedRoomInsightCard(selected)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func visualizerRoomRow(_ snapshot: LiveOpsRoomSnapshot, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(snapshot.state.roomName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(metricLabel(for: snapshot))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            GeometryReader { proxy in
                let width = max(0, proxy.size.width)
                let ratio = metricRatio(for: snapshot)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.18))
                    Capsule(style: .continuous)
                        .fill(metricColor(for: snapshot).opacity(0.85))
                        .frame(width: width * CGFloat(ratio))
                }
            }
            .frame(height: 10)

            HStack(spacing: 10) {
                Label(snapshot.state.status.title, systemImage: snapshot.state.status.symbolName)
                Text("CO \(snapshot.state.occupancyLabel)")
                if opsStore.waitTimesEnabled {
                    Text(snapshot.state.waitLabel)
                }
            }
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.72))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? TLITheme.accent(scheme).opacity(0.12) : TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isSelected ? TLITheme.accent(scheme).opacity(0.65) : TLITheme.border(scheme),
                    lineWidth: 1
                )
        )
    }

    private func selectedRoomInsightCard(_ snapshot: LiveOpsRoomSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Focused Room: \(snapshot.state.roomName)")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text("Risk \(Int((snapshot.riskScore * 100).rounded()))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(metricColor(for: snapshot))
            }

            GeometryReader { proxy in
                let width = max(0, proxy.size.width)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.18))
                    Capsule()
                        .fill(metricColor(for: snapshot).opacity(0.85))
                        .frame(width: width * CGFloat(min(max(snapshot.riskScore, 0), 1)))
                }
            }
            .frame(height: 10)

            Text(operatorRecommendation(for: snapshot))
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))

            HStack(spacing: 10) {
                Label("Updated \(snapshot.state.lastUpdated, style: .relative)", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                Spacer(minLength: 8)
                Button("Load into Update Form") {
                    selectedRoomName = snapshot.state.roomName
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func metricRatio(for snapshot: LiveOpsRoomSnapshot) -> Double {
        switch visualMetricFocus {
        case .risk:
            return min(max(snapshot.riskScore, 0), 1)
        case .occupancy:
            return min(max(snapshot.occupancyRatio / 1.20, 0), 1)
        case .wait:
            return min(max(Double(snapshot.waitMinutes) / 60.0, 0), 1)
        }
    }

    private func metricLabel(for snapshot: LiveOpsRoomSnapshot) -> String {
        switch visualMetricFocus {
        case .risk:
            return "Risk \(Int((snapshot.riskScore * 100).rounded()))%"
        case .occupancy:
            if snapshot.state.occupancyLimit > 0 {
                return "\(Int((snapshot.occupancyRatio * 100).rounded()))%"
            }
            return "Unset"
        case .wait:
            guard opsStore.waitTimesEnabled else { return "Hidden" }
            return snapshot.waitMinutes == 0 ? "Walk-in" : "\(snapshot.waitMinutes)m"
        }
    }

    private func metricColor(for snapshot: LiveOpsRoomSnapshot) -> Color {
        if snapshot.state.status == .atCapacity || snapshot.state.occupancyState == .overLimit {
            return .red
        }
        if snapshot.riskScore >= 0.65 {
            return .orange
        }
        if snapshot.riskScore >= 0.45 {
            return .yellow
        }
        return .green
    }

    private func operatorRecommendation(for snapshot: LiveOpsRoomSnapshot) -> String {
        if snapshot.state.status == .atCapacity || snapshot.state.occupancyState == .overLimit {
            return "Hold additional entry and direct attendees to overflow or alternate sessions now."
        }
        if snapshot.waitMinutes >= 45 {
            return "Queue pressure is high. Reassign staff to this room and publish alternate nearby options."
        }
        if snapshot.riskScore >= 0.55 {
            return "Monitor every 10 minutes and be ready to switch status to At Capacity if inflow continues."
        }
        return "Room is within normal operating range. Keep standard monitoring cadence."
    }

    @ViewBuilder
    private var panelInsightsSection: some View {
        Section("Panel Insights") {
            HStack {
                metricPill(
                    title: "Responses",
                    value: "\(feedbackStore.totalResponses)",
                    systemImage: "text.bubble"
                )
                Spacer(minLength: 8)
                metricPill(
                    title: "Avg",
                    value: feedbackStore.globalAverageRating > 0
                        ? String(format: "%.1f ★", feedbackStore.globalAverageRating)
                        : "n/a",
                    systemImage: "star.fill"
                )
                Spacer(minLength: 8)
                metricPill(
                    title: "Issues",
                    value: "\(feedbackStore.issueReportCount)",
                    systemImage: "exclamationmark.bubble"
                )
            }

            if feedbackStore.totalResponses > 0 {
                Button {
                    prepareFeedbackExport()
                } label: {
                    Label("Prepare Feedback Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }

                if let feedbackExportURL {
                    ShareLink(item: feedbackExportURL) {
                        Label("Export CSV for Records", systemImage: "doc.text")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            if let feedbackExportError {
                Text(feedbackExportError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            let insights = feedbackStore.insights(limit: 10)
            if insights.isEmpty {
                Text("No panel feedback submissions yet.")
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                ForEach(insights) { insight in
                    panelInsightRow(insight)
                }
            }
        }
    }

    @ViewBuilder
    private var flaggedFeedbackQueueSection: some View {
        Section("Flagged Feedback Queue") {
            let flagged = feedbackStore.flaggedEntries.prefix(10)
            if flagged.isEmpty {
                Text("No flagged feedback entries.")
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                ForEach(Array(flagged)) { entry in
                    flaggedFeedbackRow(entry)
                }
            }
        }
    }

    @ViewBuilder
    private func panelInsightRow(_ insight: PanelFeedbackInsight) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(insight.eventTitle)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(String(format: "%.1f ★", insight.averageRating))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
            }

            HStack(spacing: 10) {
                Text("\(insight.responseCount) response\(insight.responseCount == 1 ? "" : "s")")
                Text("•")
                Text("Issues: \(insight.issueCount)")
                if !insight.room.isEmpty {
                    Text("•")
                    Text(insight.room)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.72))

            if !insight.topTags.isEmpty {
                Text("Top tags: \(insight.topTags.map(\.title).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            if feedbackStore.shouldAlert(for: insight) {
                Text("Needs review: score is below alert threshold.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func prepareFeedbackExport() {
        do {
            feedbackExportURL = try feedbackStore.makeExportFile()
            feedbackExportError = nil
        } catch {
            feedbackExportURL = nil
            feedbackExportError = "Could not prepare feedback export. Please try again."
        }
    }

    @ViewBuilder
    private func flaggedFeedbackRow(_ entry: PanelFeedbackEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(entry.eventTitle)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text("\(entry.rating)★")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if !entry.comment.isEmpty {
                Text(entry.comment)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            HStack(spacing: 10) {
                if entry.isIssueReported {
                    Label(entry.isIssueResolved ? "Issue resolved" : "Issue reported", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(entry.isIssueResolved ? .secondary : .orange)
                }

                Spacer(minLength: 8)

                if !entry.isIssueResolved {
                    Button("Resolve") {
                        feedbackStore.resolveIssue(entryID: entry.id)
                    }
                    .font(.caption.weight(.semibold))
                }

                Button("Hide Comment", role: .destructive) {
                    feedbackStore.hideComment(entryID: entry.id)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func crowdGuideRow(status: RoomLiveStatus, meaning: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.symbolName)
                .foregroundStyle(RisaTheme.accent(scheme))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(.subheadline.weight(.semibold))
                Text(meaning)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
        }
    }
}

#Preview {
    NavigationStack {
        LiveOpsView()
    }
    .environmentObject(NearbyRoomCountStore.shared)
}
