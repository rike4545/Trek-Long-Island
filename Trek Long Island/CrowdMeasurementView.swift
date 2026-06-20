// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct CrowdMeasurementView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var opsStore = ConventionOpsStore.shared
    @EnvironmentObject private var nearbyRoomCountStore: NearbyRoomCountStore
    @StateObject private var bluetoothScanner = BluetoothTricorderStore()
    @State private var selectedManualRoomName: String = ""
    @State private var manualTickerCount: Int = 0
    @State private var manualReporterName: String = "Door Counter"
    @State private var manualReportMessage: String?
    @State private var bluetoothReportMessage: String?
    @State private var isBluetoothAutoPublishing = false
    @State private var lastBluetoothAutoPublish: CrowdBluetoothRoomEstimatePublish?
    private let bluetoothStaleTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let bluetoothAutoPublishInterval: TimeInterval = 30

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
                    bluetoothSignalSweepCard
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
        .navigationTitle("Crowd Management")
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
            bluetoothReportMessage = nil
            lastBluetoothAutoPublish = nil
        }
        .onReceive(bluetoothStaleTimer) { _ in
            bluetoothScanner.pruneStaleDevices()
            autoPublishBluetoothSweepCountIfNeeded()
        }
        .onDisappear {
            isBluetoothAutoPublishing = false
            bluetoothScanner.stopScanning()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Crowd Snapshot")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("People counters, line waits, nearby app sharing, and Bluetooth signal sweeps live together here for floor operations.")
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
                    .foregroundStyle(Color.primary.opacity(0.72))
            } else {
                Text("Enable sharing and select a room to estimate how many nearby devices have the app active there.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
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

    private var bluetoothSignalSweepCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Bluetooth Signal Sweep")
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text("Use a local BLE sweep as a secondary crowd signal when app-based nearby counting is unavailable or incomplete.")
                        .font(.caption)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            BluetoothSignalSweepScope(
                devices: bluetoothScanner.devices,
                isScanning: bluetoothScanner.isScanning,
                estimatedPeople: bluetoothScanner.estimatedPeopleInRoom,
                signalCount: bluetoothScanner.roomEstimateSignalCount
            )

            HStack(spacing: 10) {
                bluetoothStatusBadge
                Spacer(minLength: 8)

                Button {
                    bluetoothScanner.isScanning ? bluetoothScanner.stopScanning() : bluetoothScanner.startScanning()
                    bluetoothReportMessage = nil
                } label: {
                    Label(
                        bluetoothScanner.isScanning ? "Stop Sweep" : "Start Sweep",
                        systemImage: bluetoothScanner.isScanning ? "stop.fill" : "play.fill"
                    )
                    .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(bluetoothScanner.isScanning ? .red : TLITheme.accent(scheme))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                metricCard(title: "BLE Signals", value: "\(bluetoothScanner.devices.count)", icon: "sensor.tag.radiowaves.forward.fill")
                metricCard(title: "Room Est.", value: "\(bluetoothScanner.estimatedPeopleInRoom)", icon: "person.3.fill")
                metricCard(
                    title: "Strongest",
                    value: bluetoothScanner.strongestDevice.map { "\($0.rssi) dBm" } ?? "n/a",
                    icon: "chart.bar.fill"
                )
                metricCard(
                    title: "Connectable",
                    value: "\(bluetoothScanner.devices.filter(\.isConnectable).count)",
                    icon: "link"
                )
            }

            Picker("Publish sweep to room", selection: $selectedManualRoomName) {
                Text("Select a room").tag("")
                ForEach(roomNames, id: \.self) { room in
                    Text(room).tag(room)
                }
            }

            Toggle(
                "Automatically update this room every 30 seconds",
                isOn: Binding(
                    get: { isBluetoothAutoPublishing },
                    set: { setBluetoothAutoPublishing($0) }
                )
            )
            .disabled(selectedManualRoomName.isEmpty)

            HStack(spacing: 10) {
                Button {
                    publishBluetoothSweepCount(source: .manual)
                } label: {
                    Label("Publish Sweep", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.bordered)
                .disabled(selectedManualRoomName.isEmpty || bluetoothScanner.estimatedPeopleInRoom == 0)

                if isBluetoothAutoPublishing {
                    Label("Auto armed", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            Text(bluetoothScanner.statusMessage)
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if !selectedManualRoomName.isEmpty {
                Text("Publishes to \(selectedManualRoomName), matching the manual ticker room below.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            if let bluetoothReportMessage {
                Label(bluetoothReportMessage, systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(
                "Bluetooth estimates are approximate. They detect nearby BLE signals, not people; some guests carry multiple devices, and some carry none.",
                systemImage: "lock.shield.fill"
            )
            .font(.caption)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .fixedSize(horizontal: false, vertical: true)

            bluetoothSignalList
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

    private var bluetoothStatusBadge: some View {
        Label(bluetoothScanner.bluetoothStateLabel, systemImage: bluetoothScanner.isScanning ? "dot.radiowaves.left.and.right" : "power")
            .font(.caption.weight(.bold))
            .foregroundStyle(bluetoothScanner.isScanning ? TLITheme.accent(scheme) : TLITheme.textPrimary(scheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(TLITheme.chipBackground(scheme), in: Capsule())
            .accessibilityLabel("Bluetooth status: \(bluetoothScanner.bluetoothStateLabel)")
    }

    @ViewBuilder
    private var bluetoothSignalList: some View {
        if bluetoothScanner.devices.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(bluetoothScanner.isScanning ? "Listening for nearby signals..." : "No Bluetooth sweep running.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(bluetoothScanner.isScanning ? "Move through the room for a few seconds while the sweep listens." : "Start a sweep to use nearby BLE signals as another crowd-management input.")
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TLITheme.controlShape(cornerRadius: 14).fill(TLITheme.cardBackground(scheme).opacity(0.72)))
            .overlay(
                TLITheme.controlShape(cornerRadius: 14)
                    .stroke(TLITheme.border(scheme).opacity(0.7), lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Detected Bluetooth Signals")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                ForEach(bluetoothScanner.devices.prefix(8)) { device in
                    bluetoothSignalRow(device)
                }
            }
        }
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
                .foregroundStyle(Color.primary.opacity(0.72))
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
                    .foregroundStyle(Color.primary.opacity(0.72))
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))
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
                    .foregroundStyle(Color.primary.opacity(0.72))
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
                .foregroundStyle(Color.primary.opacity(0.72))
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

    private func bluetoothSignalRow(_ device: BluetoothTricorderDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: device.signalLevel.symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(bluetoothSignalColor(for: device.signalLevel))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(device.signalLevel.rawValue)
                    Text("\(device.rssi) dBm")
                    if device.serviceCount > 0 {
                        Text("\(device.serviceCount) service\(device.serviceCount == 1 ? "" : "s")")
                    }
                }
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            Spacer(minLength: 8)

            Text(device.lastSeen, style: .relative)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(12)
        .background(TLITheme.controlShape(cornerRadius: 14).fill(TLITheme.cardBackground(scheme).opacity(0.72)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 14)
                .stroke(bluetoothSignalColor(for: device.signalLevel).opacity(0.34), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func bluetoothSignalColor(for level: BluetoothSignalLevel) -> Color {
        switch level {
        case .strong: return .green
        case .moderate: return TLITheme.accent(scheme)
        case .faint: return .orange
        case .trace: return TLITheme.textTertiary(scheme)
        }
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

    private func setBluetoothAutoPublishing(_ isEnabled: Bool) {
        isBluetoothAutoPublishing = isEnabled
        lastBluetoothAutoPublish = nil

        if isEnabled {
            if !bluetoothScanner.isScanning {
                bluetoothScanner.startScanning()
            }
            bluetoothReportMessage = "Auto update armed for \(selectedManualRoomName.isEmpty ? "selected room" : selectedManualRoomName)."
        } else {
            bluetoothReportMessage = "Auto update paused."
        }
    }

    private func autoPublishBluetoothSweepCountIfNeeded() {
        guard isBluetoothAutoPublishing, bluetoothScanner.isScanning, !selectedManualRoomName.isEmpty else { return }
        let estimate = bluetoothScanner.estimatedPeopleInRoom
        guard estimate > 0 else { return }

        if let lastBluetoothAutoPublish {
            let isSameRoom = lastBluetoothAutoPublish.roomName == selectedManualRoomName
            let isSameEstimate = lastBluetoothAutoPublish.estimate == estimate
            let isFresh = Date().timeIntervalSince(lastBluetoothAutoPublish.date) < bluetoothAutoPublishInterval
            if isSameRoom, isSameEstimate, isFresh {
                return
            }
        }

        publishBluetoothSweepCount(source: .automatic)
    }

    private func publishBluetoothSweepCount(source: CrowdBluetoothRoomEstimateSource) {
        guard !selectedManualRoomName.isEmpty else { return }
        let estimate = bluetoothScanner.estimatedPeopleInRoom
        guard estimate > 0 else { return }

        var state = opsStore.state(for: selectedManualRoomName)
        state.occupancyCount = estimate
        state.updatedBy = "Bluetooth Signal Sweep"
        state.lastUpdated = .now
        state.note = "\(source.notePrefix) crowd-management Bluetooth sweep estimate from \(bluetoothScanner.roomEstimateSignalCount) nearby BLE signal\(bluetoothScanner.roomEstimateSignalCount == 1 ? "" : "s")."
        opsStore.upsertRoomState(state)

        manualTickerCount = estimate
        manualReportMessage = nil
        bluetoothReportMessage = "\(source.messagePrefix) \(estimate) estimated people for \(selectedManualRoomName)."

        if source == .automatic {
            lastBluetoothAutoPublish = CrowdBluetoothRoomEstimatePublish(
                roomName: selectedManualRoomName,
                estimate: estimate,
                date: .now
            )
        }
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

private struct CrowdBluetoothRoomEstimatePublish: Equatable {
    let roomName: String
    let estimate: Int
    let date: Date
}

private enum CrowdBluetoothRoomEstimateSource {
    case manual
    case automatic

    var notePrefix: String {
        switch self {
        case .manual: return "Manual"
        case .automatic: return "Automatic"
        }
    }

    var messagePrefix: String {
        switch self {
        case .manual: return "Published"
        case .automatic: return "Auto-updated"
        }
    }
}

#Preview {
    NavigationStack {
        CrowdMeasurementView()
    }
    .environmentObject(NearbyRoomCountStore.shared)
}
