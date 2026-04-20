// Copyright Bryan Carroll. All rights reserved.
//
//  TLEngineeringMiniGameView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct TLEngineeringMiniGameView: View {
    private enum Phase {
        case briefing
        case tuning
        case results
    }

    private struct EngineeringProfile {
        var matter: Int
        var antimatter: Int
        var coolant: Int

        static func random() -> EngineeringProfile {
            EngineeringProfile(
                matter: Int.random(in: 42...78),
                antimatter: Int.random(in: 44...82),
                coolant: Int.random(in: 30...68)
            )
        }
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var phase: Phase = .briefing
    @State private var round = 1
    @State private var score = 0
    @State private var statusText = "Warp core idle. Awaiting calibration order."
    @State private var currentProfile = EngineeringProfile(matter: 52, antimatter: 55, coolant: 48)
    @State private var targetProfile = EngineeringProfile.random()
    @State private var auditLog: [String] = []
    @State private var assistsRemaining = 2

    private let totalRounds = 4

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerPanel

                switch phase {
                case .briefing:
                    briefingPanel
                case .tuning:
                    tuningPanels
                case .results:
                    resultsPanels
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(engineeringBackground.ignoresSafeArea())
        .navigationTitle("Engineering")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(phase == .briefing ? "Start Drill" : "Reset") {
                    resetGame(startImmediately: phase == .briefing)
                }
                .accessibilityInputLabels(["Engineering reset", "Engineering drill"])
            }
        }
    }

    private var headerPanel: some View {
        EngineeringPanel(fill: EngineeringPalette.shell) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WARP CORE CALIBRATION")
                            .font(.headline.bold())
                            .foregroundStyle(EngineeringPalette.textBright)

                        Text("Balance matter, antimatter, and coolant flow before the core drifts out of spec.")
                            .font(.subheadline)
                            .foregroundStyle(EngineeringPalette.textMuted)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        statusBadge("ROUND", value: "\(round)/\(totalRounds)", color: EngineeringPalette.gold)
                        statusBadge("SCORE", value: "\(score)", color: EngineeringPalette.cyan)
                    }
                }

                HStack(spacing: 10) {
                    metricPill("Instability", value: "\(instability)%")
                    metricPill("Efficiency", value: "\(efficiency)%")
                    metricPill("Assists", value: "\(assistsRemaining)")
                }
            }
        }
    }

    private var briefingPanel: some View {
        VStack(spacing: 16) {
            EngineeringPanel(fill: EngineeringPalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Chief Engineer Drill")
                        .font(.title2.bold())
                        .foregroundStyle(EngineeringPalette.textBright)

                    Text("Each round gives you a new warp-core profile. Match the target values as closely as you can, then lock the core before the plasma harmonics wander.")
                        .foregroundStyle(EngineeringPalette.textMuted)

                    VStack(alignment: .leading, spacing: 10) {
                        briefingLine("Matter injector", value: "Sets deuterium flow")
                        briefingLine("Antimatter intermix", value: "Controls reaction intensity")
                        briefingLine("Coolant lattice", value: "Keeps the core from screaming")
                    }
                }
            }

            startButton(title: "Begin Calibration") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var tuningPanels: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                warpCorePanel
                targetPanel
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            parameterPanel
            commandPanel
            logPanel
        }
    }

    private var warpCorePanel: some View {
        EngineeringPanel(fill: EngineeringPalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Core Status")

                HStack(spacing: 16) {
                    WarpCoreColumn(
                        label: "Matter",
                        value: currentProfile.matter,
                        target: targetProfile.matter,
                        color: EngineeringPalette.blue
                    )

                    WarpCoreColumn(
                        label: "Intermix",
                        value: currentProfile.antimatter,
                        target: targetProfile.antimatter,
                        color: EngineeringPalette.red
                    )

                    WarpCoreColumn(
                        label: "Coolant",
                        value: currentProfile.coolant,
                        target: targetProfile.coolant,
                        color: EngineeringPalette.cyan
                    )
                }

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngineeringPalette.textBright)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(EngineeringPalette.console, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var targetPanel: some View {
        EngineeringPanel(fill: EngineeringPalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Target Profile")

                targetRow("Matter flow", value: targetProfile.matter, color: EngineeringPalette.blue)
                targetRow("Antimatter mix", value: targetProfile.antimatter, color: EngineeringPalette.red)
                targetRow("Coolant lattice", value: targetProfile.coolant, color: EngineeringPalette.cyan)

                Divider().overlay(EngineeringPalette.stroke)

                Label("Tolerance window: +/- 8 points", systemImage: "dot.scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EngineeringPalette.textMuted)
            }
        }
        .frame(maxWidth: 240)
    }

    private var parameterPanel: some View {
        EngineeringPanel(fill: EngineeringPalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Injector Controls")

                ParameterAdjuster(
                    title: "Matter injector",
                    subtitle: "Deuterium throughput",
                    value: currentProfile.matter,
                    color: EngineeringPalette.blue,
                    onDecrease: { adjust(\EngineeringProfile.matter, by: -4) },
                    onIncrease: { adjust(\EngineeringProfile.matter, by: 4) }
                )

                ParameterAdjuster(
                    title: "Antimatter intermix",
                    subtitle: "Reaction density",
                    value: currentProfile.antimatter,
                    color: EngineeringPalette.red,
                    onDecrease: { adjust(\EngineeringProfile.antimatter, by: -4) },
                    onIncrease: { adjust(\EngineeringProfile.antimatter, by: 4) }
                )

                ParameterAdjuster(
                    title: "Coolant lattice",
                    subtitle: "Thermal suppression",
                    value: currentProfile.coolant,
                    color: EngineeringPalette.cyan,
                    onDecrease: { adjust(\EngineeringProfile.coolant, by: -4) },
                    onIncrease: { adjust(\EngineeringProfile.coolant, by: 4) }
                )
            }
        }
    }

    private var commandPanel: some View {
        EngineeringPanel(fill: EngineeringPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Command Interface")

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        commandButton("Auto-tune", systemImage: "dial.high") {
                            useAssist()
                        }
                        .disabled(assistsRemaining == 0)

                        commandButton("Lock Parameters", systemImage: "lock.circle.fill", prominent: true) {
                            lockInCurrentProfile()
                        }
                    }

                    VStack(spacing: 12) {
                        commandButton("Auto-tune", systemImage: "dial.high") {
                            useAssist()
                        }
                        .disabled(assistsRemaining == 0)

                        commandButton("Lock Parameters", systemImage: "lock.circle.fill", prominent: true) {
                            lockInCurrentProfile()
                        }
                    }
                }
            }
        }
    }

    private var logPanel: some View {
        EngineeringPanel(fill: EngineeringPalette.panel) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    panelTitle("Chief Engineer Log")
                    Spacer(minLength: 0)
                    Text("\(auditLog.count) entries")
                        .font(.caption)
                        .foregroundStyle(EngineeringPalette.textDim)
                }

                if auditLog.isEmpty {
                    Text("No interventions recorded yet.")
                        .foregroundStyle(EngineeringPalette.textMuted)
                } else {
                    ForEach(Array(auditLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(EngineeringPalette.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private var resultsPanels: some View {
        VStack(spacing: 16) {
            EngineeringPanel(fill: EngineeringPalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Warp Core Stable")
                        .font(.title2.bold())
                        .foregroundStyle(EngineeringPalette.textBright)

                    Text(resultsSummary)
                        .foregroundStyle(EngineeringPalette.textMuted)

                    HStack(spacing: 10) {
                        metricPill("Final Score", value: "\(score)")
                        metricPill("Efficiency", value: "\(efficiency)%")
                        metricPill("Best Role", value: score >= 320 ? "La Forge" : "Cadet")
                    }
                }
            }

            logPanel

            startButton(title: "Run Another Drill") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var engineeringBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 7 / 255, green: 11 / 255, blue: 22 / 255),
                    Color(red: 18 / 255, green: 19 / 255, blue: 32 / 255),
                    Color(red: 26 / 255, green: 15 / 255, blue: 24 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [EngineeringPalette.cyan.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 260
            )

            RadialGradient(
                colors: [EngineeringPalette.red.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 16,
                endRadius: 320
            )
        }
    }

    private var instability: Int {
        totalVariance
    }

    private var efficiency: Int {
        max(100 - (totalVariance / 2), 8)
    }

    private var totalVariance: Int {
        abs(currentProfile.matter - targetProfile.matter)
        + abs(currentProfile.antimatter - targetProfile.antimatter)
        + abs(currentProfile.coolant - targetProfile.coolant)
    }

    private var resultsSummary: String {
        if score >= 320 {
            return "You kept the intermix clean, the coolant steady, and the chief engineer mildly impressed."
        } else if score >= 220 {
            return "The warp core stayed online. Starfleet will call this a successful drill and avoid follow-up questions."
        } else {
            return "The ship remained mostly intact. Next time, try leaning on coolant and use assists earlier."
        }
    }

    private func statusBadge(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(EngineeringPalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color, in: Capsule())
        }
    }

    private func metricPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(EngineeringPalette.textDim)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(EngineeringPalette.textBright)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(EngineeringPalette.console, in: Capsule())
    }

    private func briefingLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(EngineeringPalette.textBright)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(EngineeringPalette.textMuted)
        }
        .font(.subheadline)
    }

    private func targetRow(_ title: String, value: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay {
                    if differentiateWithoutColor {
                        Circle().stroke(.white, lineWidth: 1)
                    }
                }
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(EngineeringPalette.textBright)
            Spacer(minLength: 10)
            Text("\(value)%")
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(EngineeringPalette.textMuted)
        }
    }

    private func panelTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(EngineeringPalette.textDim)
    }

    private func commandButton(_ title: String, systemImage: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? .black.opacity(0.82) : EngineeringPalette.textBright)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(prominent ? EngineeringPalette.gold : EngineeringPalette.console)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(prominent ? EngineeringPalette.gold.opacity(0.4) : EngineeringPalette.stroke, lineWidth: 1)
        )
    }

    private func startButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "play.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black.opacity(0.84))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EngineeringPalette.gold)
        )
    }

    private func adjust(_ keyPath: WritableKeyPath<EngineeringProfile, Int>, by delta: Int) {
        currentProfile[keyPath: keyPath] = min(max(currentProfile[keyPath: keyPath] + delta, 0), 100)
        statusText = "Injector values updated. Core variance now \(instability)%."
    }

    private func useAssist() {
        guard assistsRemaining > 0 else { return }
        assistsRemaining -= 1
        currentProfile.matter = blend(currentProfile.matter, toward: targetProfile.matter)
        currentProfile.antimatter = blend(currentProfile.antimatter, toward: targetProfile.antimatter)
        currentProfile.coolant = blend(currentProfile.coolant, toward: targetProfile.coolant)
        statusText = "Auto-tune aligned the plasma relays."
        auditLog.insert("Assist used during round \(round). Variance reduced to \(instability)%.", at: 0)
    }

    private func blend(_ current: Int, toward target: Int) -> Int {
        let adjusted = current + ((target - current) / 2)
        return min(max(adjusted, 0), 100)
    }

    private func lockInCurrentProfile() {
        let variance = totalVariance
        let roundScore = max(120 - variance - (assistsRemaining == 2 ? 0 : 10), 24)
        score += roundScore

        if variance <= 18 {
            statusText = "Round \(round) locked. Warp core harmonics stable."
        } else if variance <= 34 {
            statusText = "Round \(round) locked with manageable drift."
        } else {
            statusText = "Round \(round) barely held. Chief Engineer is making a face."
        }

        auditLog.insert("Round \(round): variance \(variance), score +\(roundScore).", at: 0)

        if round == totalRounds {
            phase = .results
        } else {
            round += 1
            targetProfile = .random()
            currentProfile = EngineeringProfile(
                matter: Int.random(in: 30...70),
                antimatter: Int.random(in: 30...70),
                coolant: Int.random(in: 30...70)
            )
        }
    }

    private func resetGame(startImmediately: Bool) {
        round = 1
        score = 0
        assistsRemaining = 2
        auditLog = []
        statusText = "Warp core idle. Awaiting calibration order."
        targetProfile = .random()
        currentProfile = EngineeringProfile(
            matter: Int.random(in: 40...64),
            antimatter: Int.random(in: 42...66),
            coolant: Int.random(in: 34...58)
        )
        phase = startImmediately ? .tuning : .briefing
    }
}

private struct EngineeringPanel<Content: View>: View {
    let fill: LinearGradient
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(EngineeringPalette.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

private struct ParameterAdjuster: View {
    let title: String
    let subtitle: String
    let value: Int
    let color: Color
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(EngineeringPalette.textBright)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(EngineeringPalette.textMuted)
                }

                Spacer(minLength: 8)

                Text("\(value)%")
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundStyle(EngineeringPalette.textBright)
            }

            HStack(spacing: 10) {
                Button(action: onDecrease) {
                    Image(systemName: "minus")
                        .font(.headline.bold())
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(EngineeringPalette.textBright)
                .background(EngineeringPalette.console, in: RoundedRectangle(cornerRadius: 14))

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(EngineeringPalette.console)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                            .frame(width: max(geometry.size.width * (CGFloat(value) / 100), 10))
                    }
                }
                .frame(height: 18)

                Button(action: onIncrease) {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black.opacity(0.85))
                .background(color, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(14)
        .background(EngineeringPalette.console.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct WarpCoreColumn: View {
    let label: String
    let value: Int
    let target: Int
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(EngineeringPalette.console)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(colors: [color.opacity(0.28), color], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(height: max(CGFloat(value) * 1.5, 18))

                Rectangle()
                    .fill(Color.white.opacity(0.28))
                    .frame(height: 2)
                    .offset(y: (150 - (CGFloat(target) * 1.5)) - 75)
            }
            .frame(height: 150)

            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(EngineeringPalette.textMuted)

            Text("\(value)%")
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(EngineeringPalette.textBright)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum EngineeringPalette {
    static let shell = LinearGradient(
        colors: [Color(red: 30 / 255, green: 20 / 255, blue: 28 / 255), Color(red: 18 / 255, green: 20 / 255, blue: 32 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panel = LinearGradient(
        colors: [Color(red: 22 / 255, green: 24 / 255, blue: 39 / 255), Color(red: 15 / 255, green: 17 / 255, blue: 28 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let console = Color(red: 13 / 255, green: 17 / 255, blue: 28 / 255)
    static let stroke = Color.white.opacity(0.08)
    static let textBright = Color(red: 242 / 255, green: 245 / 255, blue: 250 / 255)
    static let textMuted = Color(red: 181 / 255, green: 193 / 255, blue: 211 / 255)
    static let textDim = Color(red: 125 / 255, green: 143 / 255, blue: 164 / 255)
    static let blue = Color(red: 87 / 255, green: 168 / 255, blue: 1)
    static let red = Color(red: 1, green: 112 / 255, blue: 110 / 255)
    static let cyan = Color(red: 95 / 255, green: 226 / 255, blue: 227 / 255)
    static let gold = Color(red: 1, green: 196 / 255, blue: 86 / 255)
}
