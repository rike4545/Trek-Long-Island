// Copyright Bryan Carroll. All rights reserved.
//
//  TricorderMiniGameView.swift
//  Trek Long Island
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct TricorderMiniGameView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @AppStorage("TLI.EasterEggs.tricorderRecoveredSignal") private var recoveredSignalUnlocked = false

    @State private var round: Int = 1
    @State private var anomaly = TricorderCell.random()
    @State private var scannedReadings: [TricorderCell: TricorderReading] = [:]
    @State private var scansRemaining: Int = 7
    @State private var totalScansUsed: Int = 0
    @State private var roundResolved = false
    @State private var missionComplete = false
    @State private var statusText = "Tricorder calibrated. Begin a sector sweep."
    @State private var showingRecoveredSignal = false
    @State private var presentedSignal: TricorderRecoveredSignal?

    private let totalRounds = 3
    private let gridSize = 5
    private let recoveredSignalURL = URL(string: "https://www.youtube.com/watch?v=QwPmgT-xlOo")!
    private let sfx = ZenSFX.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                commandHeader
                telemetryDeck
                controlsDeck

                if recoveredSignalUnlocked {
                    recoveredSignalPanel
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(tricorderBackground.ignoresSafeArea())
        .navigationTitle("Tricorder Scan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedSignal, content: TricorderRecoveredSignalView.init)
        .alert("Recovered signal detected", isPresented: $showingRecoveredSignal) {
            Button("Open Signal") {
                presentedSignal = TricorderRecoveredSignal(recoveredSignalURL)
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("A classified playback buffer was unlocked by your scan performance.")
        }
    }

    private var commandHeader: some View {
        TricorderPanel(fill: TricorderPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MARK VII SCIENCE TRICORDER")
                            .font(.headline.bold())
                            .foregroundStyle(TricorderPalette.textBright)

                        Text("Anomaly localization exercise. Precision sweeps recover hidden archive fragments.")
                            .font(.subheadline)
                            .foregroundStyle(TricorderPalette.textMuted)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        headerBadge("ROUND", value: "\(round)/\(totalRounds)", color: TricorderPalette.accentOrange)
                        headerBadge("MODE", value: sensorModeLabel, color: strongestReading?.color ?? TricorderPalette.accentMint)
                    }
                }

                telemetryBars
            }
        }
    }

    private var telemetryDeck: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                instrumentPanel
                    .frame(maxWidth: 300, alignment: .topLeading)
                sensorScopePanel
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(spacing: 16) {
                sensorScopePanel
                instrumentPanel
            }
        }
    }

    private var instrumentPanel: some View {
        TricorderPanel(fill: TricorderPalette.panel) {
            VStack(alignment: .leading, spacing: 16) {
                panelTitle("Telemetry")

                telemetryStatusGrid

                diagnosticReadout
                spectrumPanel
                waveformPanel
            }
        }
    }

    private var diagnosticReadout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(statusText, systemImage: missionComplete ? "checkmark.seal.fill" : "waveform.path.ecg")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TricorderPalette.textBright)

            VStack(alignment: .leading, spacing: 8) {
                readoutLine("Target drift", value: targetDriftLabel)
                readoutLine("Spectral lock", value: strongestReading?.label ?? "No contact")
                readoutLine("Sweep profile", value: controlHintText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(TricorderPalette.screen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(TricorderPalette.stroke, lineWidth: 1)
        )
    }

    private var spectrumPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelSubtitle("Subspace Spectrum")

            VStack(spacing: 8) {
                ForEach(TricorderReading.legend, id: \.self) { reading in
                    HStack(spacing: 10) {
                        Capsule()
                            .fill(reading.color)
                            .frame(width: max(CGFloat(reading.rank) * 26, 12), height: 10)
                            .overlay(alignment: .leading) {
                                if differentiateWithoutColor {
                                    Text(reading.shortCode)
                                        .font(.caption.bold())
                                        .foregroundStyle(.black.opacity(0.72))
                                        .padding(.leading, 6)
                                }
                            }

                        Text(reading.label)
                            .font(.caption)
                            .foregroundStyle(TricorderPalette.textMuted)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var waveformPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                panelSubtitle("Signal Trace")
                Spacer(minLength: 0)
                Text("\(scannedReadings.count) samples")
                    .font(.caption)
                    .foregroundStyle(TricorderPalette.textDim)
            }

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TricorderPalette.screen)

                    TricorderWaveform(readings: waveformReadings, color: strongestReading?.color ?? TricorderPalette.accentMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
            }
            .frame(height: 92)
        }
    }

    private var sensorScopePanel: some View {
        TricorderPanel(fill: TricorderPalette.panel) {
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        panelTitle("Sensor Scope")
                        Spacer(minLength: 0)
                        Text("5 x 5 GRID")
                            .font(.caption.bold())
                            .foregroundStyle(TricorderPalette.textDim)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        panelTitle("Sensor Scope")
                        Text("5 x 5 GRID")
                            .font(.caption.bold())
                            .foregroundStyle(TricorderPalette.textDim)
                    }
                }

                scopeFrame
                scanLegend
            }
        }
    }

    private var scopeFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(TricorderPalette.screen)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(TricorderPalette.stroke, lineWidth: 1)
                )

            scopeSweep

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize),
                spacing: 8
            ) {
                ForEach(0..<gridSize * gridSize, id: \.self) { index in
                    let row = index / gridSize
                    let column = index % gridSize
                    let cell = TricorderCell(row: row, column: column)

                    Button {
                        scan(cell)
                    } label: {
                        TricorderSectorCell(
                            reading: scannedReadings[cell],
                            isAvailable: scannedReadings[cell] == nil && !roundResolved && scansRemaining > 0 && !missionComplete,
                            differentiateWithoutColor: differentiateWithoutColor
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(roundResolved || scansRemaining == 0 || scannedReadings[cell] != nil || missionComplete)
                    .accessibilityLabel(accessibilityLabel(for: cell))
                    .accessibilityHint("Runs a focused scan on this sector")
                    .accessibilityInputLabels([
                        "Sector \(row + 1) \(column + 1)",
                        "Scan sector \(row + 1) \(column + 1)"
                    ])
                }
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var scopeSweep: some View {
        if reduceMotion {
            LinearGradient(
                colors: [
                    TricorderPalette.accentMint.opacity(0.04),
                    TricorderPalette.accentMint.opacity(0.16),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        } else {
            TimelineView(.animation) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate
                let phase = seconds.truncatingRemainder(dividingBy: 2.8) / 2.8

                GeometryReader { geometry in
                    let width = geometry.size.width
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    TricorderPalette.accentMint.opacity(0.08),
                                    TricorderPalette.accentMint.opacity(0.24),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * 0.26)
                        .offset(x: (width * 1.16 * phase) - (width * 0.58))
                        .blur(radius: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
        }
    }

    private var scanLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
            ForEach(TricorderReading.legend.prefix(4), id: \.self) { reading in
                Label(reading.shortCode, systemImage: reading.icon)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(reading.background, in: Capsule())
                    .foregroundStyle(reading.foreground)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Legend. Exact lock, strong signal, moderate signal, faint signal")
    }

    private var controlsDeck: some View {
        TricorderPanel(fill: TricorderPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Command Keys")

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        primaryControlButton
                        restartControlButton
                    }

                    VStack(spacing: 12) {
                        primaryControlButton
                        restartControlButton
                    }
                }
            }
        }
    }

    private var recoveredSignalPanel: some View {
        TricorderPanel(fill: TricorderPalette.recovered) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    panelTitle("Recovered Signal")
                    Spacer(minLength: 0)
                    Text("ARCHIVE OPEN")
                        .font(.caption.bold())
                        .foregroundStyle(TricorderPalette.textDim)
                }

                Text("Your tricorder has already recovered a classified playback buffer. Open it any time from the archive latch below.")
                    .font(.subheadline)
                    .foregroundStyle(TricorderPalette.textBright)

                Button {
                    presentedSignal = TricorderRecoveredSignal(recoveredSignalURL)
                } label: {
                    Label("Open Recovered Signal", systemImage: "sparkles.tv")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(TricorderPalette.accentMint)
                .accessibilityInputLabels(["Open recovered signal", "Open archive signal"])
            }
        }
    }

    private var strongestReading: TricorderReading? {
        scannedReadings.values.sorted { $0.rank > $1.rank }.first
    }

    private var telemetryBars: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                TricorderLadderBar(level: signalStrengthRatio, color: strongestReading?.color ?? TricorderPalette.accentMint)
                TricorderLadderBar(level: scanUsageRatio, color: TricorderPalette.accentBlue)
                TricorderLadderBar(level: missionProgressRatio, color: TricorderPalette.accentOrange)
            }

            VStack(alignment: .leading, spacing: 8) {
                TricorderLadderBar(level: signalStrengthRatio, color: strongestReading?.color ?? TricorderPalette.accentMint)
                TricorderLadderBar(level: scanUsageRatio, color: TricorderPalette.accentBlue)
                TricorderLadderBar(level: missionProgressRatio, color: TricorderPalette.accentOrange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Signal strength \(Int(signalStrengthRatio * 100)) percent, scan usage \(Int(scanUsageRatio * 100)) percent, mission progress \(Int(missionProgressRatio * 100)) percent")
    }

    private var telemetryStatusGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 10) {
            statusCell(title: "Scans", value: "\(scansRemaining)", color: TricorderPalette.accentOrange)
            statusCell(title: "Used", value: "\(totalScansUsed)", color: TricorderPalette.accentBlue)
            statusCell(title: "Lock", value: strongestReading?.shortCode ?? "--", color: strongestReading?.color ?? TricorderPalette.accentMint)
        }
    }

    private var waveformReadings: [TricorderReading] {
        let readings = scannedReadings.values.sorted { $0.rank > $1.rank }
        return readings.isEmpty ? [.none, .faint, .medium, .strong, .medium, .faint, .none] : readings
    }

    private var signalStrengthRatio: Double {
        Double(strongestReading?.rank ?? 0) / Double(TricorderReading.exact.rank)
    }

    private var scanUsageRatio: Double {
        min(Double(totalScansUsed) / 11.0, 1)
    }

    private var missionProgressRatio: Double {
        let completedRounds = round - (roundResolved ? 0 : 1)
        return Double(completedRounds) / Double(totalRounds)
    }

    private var sensorModeLabel: String {
        if missionComplete { return "ARCHIVE" }
        if roundResolved { return "LOCK" }
        if strongestReading == nil { return "WIDE" }
        return "TRACK"
    }

    private var targetDriftLabel: String {
        if missionComplete { return "Stabilized" }
        if roundResolved { return "Contained" }
        if scansRemaining == 0 { return "Lost" }
        return "\(max(scansRemaining - 1, 0)) sectors"
    }

    private var controlHintText: String {
        if missionComplete {
            return "Mission complete. Every anomaly has been localized."
        }
        if roundResolved {
            return "Lock acquired. Advance to the next anomaly."
        }
        if scansRemaining == 0 {
            return "No scans remaining. Reset the sweep or restart the mission."
        }
        return "Use stronger returns to narrow the search vector."
    }

    private func scan(_ cell: TricorderCell) {
        guard scannedReadings[cell] == nil, !roundResolved, scansRemaining > 0 else { return }

        let reading = TricorderReading(distance: cell.distance(to: anomaly))
        scannedReadings[cell] = reading
        scansRemaining -= 1
        totalScansUsed += 1
        sfx.play("lcars_tap_soft", ext: "wav", volume: 0.12)

        #if canImport(UIKit)
        if reading == .exact {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        #endif

        if reading == .exact {
            roundResolved = true
            if round == totalRounds {
                missionComplete = true
                statusText = "All anomalies localized. Archive-ready signal recovered."
                maybeUnlockRecoveredSignal()
            } else {
                statusText = "Anomaly localized. Ready the tricorder for the next sweep."
            }
            return
        }

        statusText = reading.statusLine

        if scansRemaining == 0 {
            statusText = "Signal lost. The anomaly slipped out of range."
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
        }
    }

    private func primaryAction() {
        if roundResolved {
            if missionComplete {
                restartMission()
            } else {
                beginNextRound()
            }
        } else {
            resetCurrentRound()
        }
    }

    private func beginNextRound() {
        round += 1
        resetRoundState()
        statusText = "New anomaly seeded. Begin scanning."
    }

    private func resetCurrentRound() {
        resetRoundState()
        statusText = "Sweep reset. Tricorder recalibrated."
    }

    private func restartMission() {
        round = 1
        missionComplete = false
        totalScansUsed = 0
        resetRoundState()
        statusText = "Fresh scan mission initialized."
    }

    private func resetRoundState() {
        anomaly = TricorderCell.random()
        scannedReadings = [:]
        scansRemaining = 7
        roundResolved = false
    }

    private func maybeUnlockRecoveredSignal() {
        guard totalScansUsed <= 11 else { return }
        guard !recoveredSignalUnlocked else { return }

        recoveredSignalUnlocked = true
        showingRecoveredSignal = true
    }

    private func accessibilityLabel(for cell: TricorderCell) -> String {
        if let reading = scannedReadings[cell] {
            return "Sector \(cell.row + 1), \(cell.column + 1), \(reading.label)"
        }
        return "Sector \(cell.row + 1), \(cell.column + 1), ready to scan"
    }

    private func panelTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline.bold())
            .foregroundStyle(TricorderPalette.textBright)
            .textCase(.uppercase)
    }

    private func panelSubtitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(TricorderPalette.textDim)
            .textCase(.uppercase)
    }

    private func headerBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(TricorderPalette.textDim)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color, in: Capsule())
        }
    }

    private func statusCell(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(TricorderPalette.textDim)
            Text(value)
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TricorderPalette.screen, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(TricorderPalette.stroke, lineWidth: 1)
        )
    }

    private func readoutLine(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(TricorderPalette.textDim)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(TricorderPalette.textBright)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tricorderActionButton(title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.72))
            }
            .foregroundStyle(.black.opacity(0.84))
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityInputLabels([title])
    }

    private var primaryControlButton: some View {
        tricorderActionButton(
            title: roundResolved ? (missionComplete ? "Run Again" : "Next Sweep") : "Reset Sweep",
            subtitle: roundResolved ? (missionComplete ? "Reinitialize exercise" : "Seed next anomaly") : "Clear current grid",
            color: TricorderPalette.accentOrange,
            action: primaryAction
        )
    }

    private var restartControlButton: some View {
        tricorderActionButton(
            title: "Restart Mission",
            subtitle: "Start from round one",
            color: TricorderPalette.accentBlue,
            action: restartMission
        )
    }

    private var tricorderBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.07),
                    Color(red: 0.02, green: 0.12, blue: 0.10),
                    Color(red: 0.01, green: 0.03, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    TricorderPalette.accentMint.opacity(scheme == .dark ? 0.20 : 0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            TricorderBackgroundGrid()
                .stroke(TricorderPalette.grid.opacity(0.25), lineWidth: 0.7)
        }
    }
}

private struct TricorderPanel<Content: View>: View {
    let fill: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(TricorderPalette.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

private struct TricorderSectorCell: View {
    let reading: TricorderReading?
    let isAvailable: Bool
    let differentiateWithoutColor: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(cellFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cellStroke, lineWidth: reading == nil ? 1 : 1.4)
                )

            if let reading {
                VStack(spacing: 4) {
                    Image(systemName: reading.icon)
                        .font(.body.bold())
                    if differentiateWithoutColor {
                        Text(reading.shortCode)
                            .font(.caption2.bold())
                    }
                }
                .foregroundStyle(reading.foreground)
            } else {
                Image(systemName: isAvailable ? "viewfinder" : "minus")
                    .font(.body.bold())
                    .foregroundStyle(TricorderPalette.textDim)
            }
        }
        .frame(minWidth: 44, minHeight: 44)
        .aspectRatio(1, contentMode: .fit)
    }

    private var cellFill: Color {
        if let reading {
            return reading.background
        }
        return isAvailable ? TricorderPalette.scopeCell : TricorderPalette.scopeCellDisabled
    }

    private var cellStroke: Color {
        if let reading {
            return reading.color.opacity(0.82)
        }
        return isAvailable ? TricorderPalette.grid : TricorderPalette.stroke
    }
}

private struct TricorderWaveform: View {
    let readings: [TricorderReading]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let maxRank = CGFloat(TricorderReading.exact.rank)

            Path { path in
                for (index, reading) in readings.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(max(readings.count - 1, 1))
                    let normalized = CGFloat(reading.rank) / maxRank
                    let y = height - ((height * 0.18) + normalized * height * 0.64)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            Path { path in
                let columns = 6
                let rows = 4

                for column in 0...columns {
                    let x = width * CGFloat(column) / CGFloat(columns)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }

                for row in 0...rows {
                    let y = height * CGFloat(row) / CGFloat(rows)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(TricorderPalette.grid.opacity(0.35), lineWidth: 0.8)
        }
        .accessibilityHidden(true)
    }
}

private struct TricorderLadderBar: View {
    let level: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(level > Double(index) / 6.0 ? color : TricorderPalette.scopeCell)
                    .frame(width: 18, height: 12)
            }
        }
    }
}

private struct TricorderBackgroundGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 28

        stride(from: rect.minX, through: rect.maxX, by: spacing).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: spacing).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private enum TricorderPalette {
    static let shell = Color(red: 0.08, green: 0.12, blue: 0.12)
    static let panel = Color(red: 0.10, green: 0.16, blue: 0.15)
    static let screen = Color(red: 0.02, green: 0.10, blue: 0.10)
    static let recovered = Color(red: 0.13, green: 0.18, blue: 0.16)
    static let scopeCell = Color(red: 0.07, green: 0.16, blue: 0.16)
    static let scopeCellDisabled = Color(red: 0.05, green: 0.09, blue: 0.09)
    static let stroke = Color.white.opacity(0.10)
    static let grid = Color(red: 0.25, green: 0.64, blue: 0.60)
    static let textBright = Color(red: 0.87, green: 0.98, blue: 0.95)
    static let textMuted = Color(red: 0.62, green: 0.80, blue: 0.76)
    static let textDim = Color(red: 0.46, green: 0.62, blue: 0.58)
    static let accentMint = Color(red: 0.36, green: 0.86, blue: 0.78)
    static let accentBlue = Color(red: 0.40, green: 0.66, blue: 0.95)
    static let accentOrange = Color(red: 0.95, green: 0.62, blue: 0.24)
}

private struct TricorderCell: Hashable {
    let row: Int
    let column: Int

    static func random() -> TricorderCell {
        TricorderCell(row: Int.random(in: 0..<5), column: Int.random(in: 0..<5))
    }

    func distance(to other: TricorderCell) -> Int {
        abs(row - other.row) + abs(column - other.column)
    }
}

private enum TricorderReading: Hashable, CaseIterable {
    case exact
    case strong
    case medium
    case faint
    case none

    static let legend: [TricorderReading] = [.exact, .strong, .medium, .faint, .none]

    init(distance: Int) {
        switch distance {
        case 0: self = .exact
        case 1: self = .strong
        case 2: self = .medium
        case 3: self = .faint
        default: self = .none
        }
    }

    var label: String {
        switch self {
        case .exact: return "Exact lock"
        case .strong: return "Strong signal"
        case .medium: return "Moderate signal"
        case .faint: return "Faint signal"
        case .none: return "No signal"
        }
    }

    var shortCode: String {
        switch self {
        case .exact: return "XL"
        case .strong: return "SG"
        case .medium: return "MD"
        case .faint: return "FT"
        case .none: return "NS"
        }
    }

    var statusLine: String {
        switch self {
        case .exact: return "Anomaly locked."
        case .strong: return "Strong return. Tighten your search pattern."
        case .medium: return "Moderate return. You are in the right quadrant."
        case .faint: return "Faint return. Sweep nearby sectors."
        case .none: return "No signal. Broaden the search."
        }
    }

    var icon: String {
        switch self {
        case .exact: return "sparkles"
        case .strong: return "dot.radiowaves.left.and.right"
        case .medium: return "antenna.radiowaves.left.and.right"
        case .faint: return "waveform.path.ecg"
        case .none: return "xmark"
        }
    }

    var color: Color {
        switch self {
        case .exact: return TricorderPalette.accentOrange
        case .strong: return Color(red: 0.96, green: 0.82, blue: 0.30)
        case .medium: return TricorderPalette.accentMint
        case .faint: return TricorderPalette.accentBlue
        case .none: return TricorderPalette.textDim
        }
    }

    var background: Color {
        switch self {
        case .exact: return TricorderPalette.accentOrange.opacity(0.25)
        case .strong: return Color(red: 0.96, green: 0.82, blue: 0.30).opacity(0.22)
        case .medium: return TricorderPalette.accentMint.opacity(0.18)
        case .faint: return TricorderPalette.accentBlue.opacity(0.18)
        case .none: return TricorderPalette.textDim.opacity(0.14)
        }
    }

    var foreground: Color {
        switch self {
        case .none: return TricorderPalette.textMuted
        default: return color
        }
    }

    var rank: Int {
        switch self {
        case .exact: return 4
        case .strong: return 3
        case .medium: return 2
        case .faint: return 1
        case .none: return 0
        }
    }
}

private struct TricorderRecoveredSignal: Identifiable {
    let url: URL
    var id: URL { url }

    init(_ url: URL) {
        self.url = url
    }
}

#if canImport(SafariServices)
private struct TricorderRecoveredSignalView: UIViewControllerRepresentable {
    let item: TricorderRecoveredSignal

    init(_ item: TricorderRecoveredSignal) {
        self.item = item
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: item.url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#else
private struct TricorderRecoveredSignalView: View {
    let item: TricorderRecoveredSignal

    init(_ item: TricorderRecoveredSignal) {
        self.item = item
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Recovered signal URL")
                .font(.headline)
            Text(item.url.absoluteString)
                .font(.footnote)
                .textSelection(.enabled)
        }
        .padding()
    }
}
#endif
