// Copyright Bryan Carroll. All rights reserved.

import SwiftUI

struct BluetoothTricorderView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var opsStore = ConventionOpsStore.shared
    @StateObject private var scanner = BluetoothTricorderStore()
    @State private var selectedRoomName = ""
    @State private var publishMessage: String?
    @State private var isAutoPublishing = false
    @State private var lastAutoPublish: BluetoothRoomEstimatePublish?
    private let staleTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let autoPublishInterval: TimeInterval = 30

    private var roomNames: [String] {
        opsStore.roomStates
            .map(\.roomName)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    scanControls
                    BluetoothSignalSweepScope(
                        devices: scanner.devices,
                        isScanning: scanner.isScanning,
                        estimatedPeople: scanner.estimatedPeopleInRoom,
                        signalCount: scanner.roomEstimateSignalCount
                    )
                    metricsGrid
                    roomEstimateCard
                    privacyNotice
                    signalList
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
        .navigationTitle("Bluetooth Tricorder")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
        .onReceive(staleTimer) { _ in
            scanner.pruneStaleDevices()
            autoPublishBluetoothEstimateIfNeeded()
        }
        .onAppear {
            seedRoomSelectionIfNeeded()
        }
        .onChange(of: roomNames) { _, _ in
            seedRoomSelectionIfNeeded()
        }
        .onChange(of: selectedRoomName) { _, _ in
            lastAutoPublish = nil
            publishMessage = nil
        }
        .onDisappear {
            isAutoPublishing = false
            scanner.stopScanning()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                Text("Bluetooth Signal Sweep")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
            }

            Text("Scan the room for nearby Bluetooth Low Energy signals and compare rough proximity by signal strength.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scanControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                statusBadge
                Spacer(minLength: 8)
                Button {
                    scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
                } label: {
                    Label(scanner.isScanning ? "Stop Scan" : "Start Scan", systemImage: scanner.isScanning ? "stop.fill" : "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(scanner.isScanning ? .red : TLITheme.accent(scheme))
            }

            Text(scanner.statusMessage)
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Label(scanner.bluetoothStateLabel, systemImage: scanner.isScanning ? "dot.radiowaves.left.and.right" : "power")
            .font(.caption.weight(.bold))
            .foregroundStyle(scanner.isScanning ? TLITheme.accent(scheme) : TLITheme.textPrimary(scheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(TLITheme.chipBackground(scheme), in: Capsule())
            .accessibilityLabel("Bluetooth status: \(scanner.bluetoothStateLabel)")
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            metricCard(title: "Signals", value: "\(scanner.devices.count)", icon: "sensor.tag.radiowaves.forward.fill")
            metricCard(title: "Room Est.", value: "\(scanner.estimatedPeopleInRoom)", icon: "person.3.fill")
            metricCard(
                title: "Strongest",
                value: scanner.strongestDevice.map { "\($0.rssi) dBm" } ?? "n/a",
                icon: "chart.bar.fill"
            )
            metricCard(
                title: "Connectable",
                value: "\(scanner.devices.filter(\.isConnectable).count)",
                icon: "link"
            )
        }
    }

    private var roomEstimateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Room People Estimate")
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text("\(scanner.estimatedPeopleInRoom) estimated from \(scanner.roomEstimateSignalCount) nearby room signal\(scanner.roomEstimateSignalCount == 1 ? "" : "s").")
                        .font(.caption)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            Picker("Publish to room", selection: $selectedRoomName) {
                Text("Select a room").tag("")
                ForEach(roomNames, id: \.self) { room in
                    Text(room).tag(room)
                }
            }
            .disabled(roomNames.isEmpty)

            Toggle(
                "Automatically update this room",
                isOn: Binding(
                    get: { isAutoPublishing },
                    set: { setAutoPublishing($0) }
                )
            )
            .disabled(selectedRoomName.isEmpty)

            HStack(spacing: 10) {
                Button {
                    publishBluetoothEstimate(source: .manual)
                } label: {
                    Label("Publish Estimate", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(TLITheme.accent(scheme))
                .disabled(selectedRoomName.isEmpty || scanner.estimatedPeopleInRoom == 0)

                if isAutoPublishing {
                    Label("Auto every 30s", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            if let publishMessage {
                Label(publishMessage, systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var privacyNotice: some View {
        Label(
            "This is a rough device-based estimate, not a true headcount. Some people carry multiple Bluetooth devices, some carry none, and iOS may hide or rotate identifiers.",
            systemImage: "lock.shield.fill"
        )
        .font(.caption)
        .foregroundStyle(TLITheme.textSecondary(scheme))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 16).fill(TLITheme.cardBackground(scheme).opacity(0.78)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 16)
                .stroke(TLITheme.border(scheme).opacity(0.7), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var signalList: some View {
        if scanner.devices.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Detected Signals")
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                ForEach(scanner.devices) { device in
                    signalRow(device)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scanner.isScanning ? "Listening for signals..." : "No scan running.")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Text(scanner.isScanning ? "Move around the room for a few seconds while the tricorder listens." : "Start a scan to look for nearby BLE devices.")
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 12).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 12)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func signalRow(_ device: BluetoothTricorderDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: device.signalLevel.symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(signalColor(for: device.signalLevel))
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
        .padding(14)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(signalColor(for: device.signalLevel).opacity(0.34), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func signalColor(for level: BluetoothSignalLevel) -> Color {
        switch level {
        case .strong: return .green
        case .moderate: return TLITheme.accent(scheme)
        case .faint: return .orange
        case .trace: return TLITheme.textTertiary(scheme)
        }
    }

    private func seedRoomSelectionIfNeeded() {
        if selectedRoomName.isEmpty {
            selectedRoomName = roomNames.first ?? ""
        } else if !roomNames.contains(selectedRoomName) {
            selectedRoomName = roomNames.first ?? ""
        }
    }

    private func setAutoPublishing(_ isEnabled: Bool) {
        isAutoPublishing = isEnabled
        lastAutoPublish = nil

        if isEnabled {
            if !scanner.isScanning {
                scanner.startScanning()
            }
            publishMessage = "Auto update armed for \(selectedRoomName.isEmpty ? "selected room" : selectedRoomName)."
        } else {
            publishMessage = "Auto update paused."
        }
    }

    private func autoPublishBluetoothEstimateIfNeeded() {
        guard isAutoPublishing, scanner.isScanning, !selectedRoomName.isEmpty else { return }
        let estimate = scanner.estimatedPeopleInRoom
        guard estimate > 0 else { return }

        if let lastAutoPublish {
            let isSameRoom = lastAutoPublish.roomName == selectedRoomName
            let isSameEstimate = lastAutoPublish.estimate == estimate
            let isFresh = Date().timeIntervalSince(lastAutoPublish.date) < autoPublishInterval
            if isSameRoom, isSameEstimate, isFresh {
                return
            }
        }

        publishBluetoothEstimate(source: .automatic)
    }

    private func publishBluetoothEstimate(source: BluetoothRoomEstimateSource) {
        guard !selectedRoomName.isEmpty else { return }
        let estimate = scanner.estimatedPeopleInRoom
        guard estimate > 0 else { return }

        var state = opsStore.state(for: selectedRoomName)
        state.occupancyCount = estimate
        state.updatedBy = "Bluetooth Tricorder"
        state.lastUpdated = .now
        state.note = "\(source.notePrefix) Bluetooth room estimate from \(scanner.roomEstimateSignalCount) nearby BLE signal\(scanner.roomEstimateSignalCount == 1 ? "" : "s")."
        opsStore.upsertRoomState(state)
        publishMessage = "\(source.messagePrefix) \(estimate) estimated people for \(selectedRoomName)."

        if source == .automatic {
            lastAutoPublish = BluetoothRoomEstimatePublish(
                roomName: selectedRoomName,
                estimate: estimate,
                date: .now
            )
        }
    }
}

private struct BluetoothRoomEstimatePublish: Equatable {
    let roomName: String
    let estimate: Int
    let date: Date
}

private enum BluetoothRoomEstimateSource {
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
        BluetoothTricorderView()
    }
}
