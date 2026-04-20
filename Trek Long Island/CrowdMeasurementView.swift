// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct CrowdMeasurementView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var opsStore = ConventionOpsStore.shared
    @EnvironmentObject private var nearbyRoomCountStore: NearbyRoomCountStore
    @State private var selectedManualRoomName: String = ""
    @State private var manualTickerCount: Int = 0
    @State private var manualReporterName: String = "Door Counter"
    @State private var manualReportMessage: String?

    private var sortedRooms: [RoomOpsState] {
        opsStore.roomStates.sorted { lhs, rhs in
            let lWait = lhs.waitMinutes ?? 0
            let rWait = rhs.waitMinutes ?? 0
            if lWait != rWait { return lWait > rWait }
            if lhs.status != rhs.status {
                return statusRank(lhs.status) > statusRank(rhs.status)
            }
            return lhs.roomName.localizedCaseInsensitiveCompare(rhs.roomName) == .orderedAscending
        }
    }

    private var totalPeopleCount: Int {
        opsStore.roomStates.reduce(0) { $0 + max(0, $1.occupancyCount) }
    }

    private var roomsWithWaitPosted: Int {
        sortedRooms.filter { $0.waitMinutes != nil }.count
    }

    private var longestWaitMinutes: Int {
        sortedRooms.compactMap(\.waitMinutes).max() ?? 0
    }

    private var averageWaitMinutes: Int {
        let waits = sortedRooms.compactMap(\.waitMinutes).filter { $0 >= 0 }
        guard !waits.isEmpty else { return 0 }
        let total = waits.reduce(0, +)
        return Int(Double(total) / Double(waits.count))
    }

    private var roomNames: [String] {
        sortedRooms.map(\.roomName)
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    summaryStrip
                    nearbyAutoCountCard
                    manualTickerCard
                    waitTimesNotice
                    roomsSection
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.tightContentMaxWidth + 160,
                    horizontalPadding: 20,
                    verticalPadding: 0
                )
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Crowd Measurement")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
        .onAppear {
            seedManualTickerSelectionIfNeeded()
        }
        .onChange(of: roomNames) { _, _ in
            seedManualTickerSelectionIfNeeded()
        }
        .onChange(of: selectedManualRoomName) { _, newValue in
            syncManualTicker(to: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Crowd Snapshot")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("People counters and line waits are estimates from room operations updates.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var summaryStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            metricCard(title: "People Count", value: "\(totalPeopleCount)", icon: "person.3.fill")
            metricCard(
                title: "Nearby Apps",
                value: nearbyRoomCountStore.isEnabled && !nearbyRoomCountStore.selectedRoomName.isEmpty
                    ? "\(nearbyRoomCountStore.totalActiveCountForSelectedRoom)"
                    : "off",
                icon: "dot.radiowaves.left.and.right"
            )
            metricCard(title: "Avg Wait", value: averageWaitMinutes > 0 ? "\(averageWaitMinutes)m" : "n/a", icon: "clock.fill")
            metricCard(title: "Longest", value: longestWaitMinutes > 0 ? "\(longestWaitMinutes)m" : "n/a", icon: "timer")
            metricCard(title: "Lines Posted", value: "\(roomsWithWaitPosted)", icon: "line.3.horizontal.decrease.circle")
        }
    }

    private var nearbyAutoCountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automatic Room Count")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Toggle(
                "Share this device for nearby room counting",
                isOn: Binding(
                    get: { nearbyRoomCountStore.isEnabled },
                    set: { nearbyRoomCountStore.setEnabled($0) }
                )
            )

            Picker(
                "My room",
                selection: Binding(
                    get: { nearbyRoomCountStore.selectedRoomName },
                    set: { nearbyRoomCountStore.setSelectedRoomName($0) }
                )
            ) {
                Text("Select a room").tag("")
                ForEach(roomNames, id: \.self) { room in
                    Text(room).tag(room)
                }
            }
            .disabled(!nearbyRoomCountStore.isEnabled)

            if nearbyRoomCountStore.isEnabled && !nearbyRoomCountStore.selectedRoomName.isEmpty {
                Label(
                    "\(nearbyRoomCountStore.totalActiveCountForSelectedRoom) active app\(nearbyRoomCountStore.totalActiveCountForSelectedRoom == 1 ? "" : "s") detected for \(nearbyRoomCountStore.selectedRoomName).",
                    systemImage: "person.2.wave.2.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("This is a nearby-device estimate based on users who currently have the app open and joined to the same room.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enable sharing and select a room to estimate how many nearby devices have the app active there.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let authorizationMessage = nearbyRoomCountStore.authorizationMessage {
                Text("Nearby counting unavailable: \(authorizationMessage)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var manualTickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manual Door Ticker")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Use this when the automatic system is off or you need a manual room count at the door. Tap plus for entries, minus for exits, then report the total for the room.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Picker("Room", selection: $selectedManualRoomName) {
                Text("Select a room").tag("")
                ForEach(roomNames, id: \.self) { room in
                    Text(room).tag(room)
                }
            }

            TextField("Reported by", text: $manualReporterName)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TLITheme.cardBackground(scheme).opacity(0.28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                )

            HStack(spacing: 12) {
                tickerActionButton(title: "Exit", systemImage: "minus", fill: .red.opacity(0.88)) {
                    manualTickerCount = max(0, manualTickerCount - 1)
                    manualReportMessage = nil
                }

                VStack(spacing: 4) {
                    Text("\(manualTickerCount)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text("Current manual count")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .frame(maxWidth: .infinity)

                tickerActionButton(title: "Entry", systemImage: "plus", fill: TLITheme.accent(scheme)) {
                    manualTickerCount += 1
                    manualReportMessage = nil
                }
            }

            HStack(spacing: 10) {
                Button("Reset") {
                    syncManualTicker(to: selectedManualRoomName)
                    manualReportMessage = nil
                }
                .buttonStyle(.bordered)

                Button("Report Count") {
                    reportManualCount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedManualRoomName.isEmpty)
            }

            if let manualReportMessage, !manualReportMessage.isEmpty {
                Label(manualReportMessage, systemImage: "checkmark.seal")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !selectedManualRoomName.isEmpty {
                let state = opsStore.state(for: selectedManualRoomName)
                Text("Last published room count for \(selectedManualRoomName): \(state.occupancyCount)")
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var waitTimesNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: opsStore.waitTimesEnabled ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(opsStore.waitTimesEnabled ? .green : .orange)
            Text(opsStore.waitTimesEnabled
                 ? "Line wait estimates are currently enabled."
                 : "Line wait estimates are temporarily disabled.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var roomsSection: some View {
        if sortedRooms.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No crowd measurements posted yet.")
                    .font(.headline)
                Text("Room counters and wait times will appear once operators publish updates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TLITheme.cardBackground(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
        } else {
            VStack(spacing: 10) {
                ForEach(sortedRooms) { room in
                    roomCard(room)
                }
            }
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func roomCard(_ room: RoomOpsState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: room.status.symbolName)
                    .foregroundStyle(TLITheme.accent(scheme))
                Text(room.roomName)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(room.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            HStack(spacing: 14) {
                Label(peopleLabel(for: room), systemImage: "person.3.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Label(waitLabel(for: room), systemImage: "clock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(waitColor(for: room))
            }

            if let automaticCount = nearbyRoomCountStore.automaticCount(for: room.roomName) {
                Label("Nearby apps: \(automaticCount)", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if room.occupancyLimit > 0 {
                GeometryReader { proxy in
                    let width = max(0, proxy.size.width)
                    let ratio = min(1.0, Double(max(0, room.occupancyCount)) / Double(max(1, room.occupancyLimit)))
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.secondary.opacity(0.18))
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(waitColor(for: room).opacity(0.75))
                            .frame(width: width * ratio)
                    }
                }
                .frame(height: 8)
            }

            Text("Updated \(room.lastUpdated, style: .relative)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TLITheme.cardBackground(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func tickerActionButton(title: String, systemImage: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color.black)
            .frame(width: 88, height: 88)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
            )
        }
        .buttonStyle(.plain)
    }

    private func seedManualTickerSelectionIfNeeded() {
        if selectedManualRoomName.isEmpty, let firstRoom = roomNames.first {
            selectedManualRoomName = firstRoom
            syncManualTicker(to: firstRoom)
        } else if !selectedManualRoomName.isEmpty, !roomNames.contains(selectedManualRoomName) {
            selectedManualRoomName = roomNames.first ?? ""
            syncManualTicker(to: selectedManualRoomName)
        }
    }

    private func syncManualTicker(to roomName: String) {
        guard !roomName.isEmpty else {
            manualTickerCount = 0
            return
        }
        manualTickerCount = max(0, opsStore.state(for: roomName).occupancyCount)
    }

    private func reportManualCount() {
        let trimmedReporter = manualReporterName.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedBy = trimmedReporter.isEmpty ? "Door Counter" : trimmedReporter
        guard !selectedManualRoomName.isEmpty else { return }

        var state = opsStore.state(for: selectedManualRoomName)
        state.occupancyCount = max(0, manualTickerCount)
        state.updatedBy = updatedBy
        state.lastUpdated = .now
        if state.note.isEmpty {
            state.note = "Manual door ticker update"
        }
        opsStore.upsertRoomState(state)
        manualReportMessage = "Reported \(manualTickerCount) people for \(selectedManualRoomName)."
    }

    private func statusRank(_ status: RoomLiveStatus) -> Int {
        switch status {
        case .open: return 1
        case .cleared: return 1
        case .filling: return 2
        case .atCapacity: return 3
        }
    }

    private func peopleLabel(for room: RoomOpsState) -> String {
        if room.occupancyLimit > 0 {
            return "\(room.occupancyCount)/\(room.occupancyLimit) in room"
        }
        return "\(room.occupancyCount) in room"
    }

    private func waitLabel(for room: RoomOpsState) -> String {
        guard opsStore.waitTimesEnabled else { return "Wait not posted" }
        guard let wait = room.waitMinutes else { return "No wait posted" }
        return wait == 0 ? "Walk-in" : "~\(wait)m line"
    }

    private func waitColor(for room: RoomOpsState) -> Color {
        if room.status == .atCapacity { return .red }
        guard let wait = room.waitMinutes else { return .secondary }
        if wait >= 45 { return .red }
        if wait >= 20 { return .orange }
        return .green
    }
}

#Preview {
    NavigationStack {
        CrowdMeasurementView()
    }
    .environmentObject(NearbyRoomCountStore.shared)
}
