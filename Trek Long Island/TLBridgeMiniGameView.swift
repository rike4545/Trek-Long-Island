// Copyright Bryan Carroll. All rights reserved.
//
//  TLBridgeMiniGameView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct TLBridgeMiniGameView: View {
    private enum Phase {
        case briefing
        case inProgress
        case debrief
    }

    private struct BridgeScenario: Identifiable {
        struct Option: Identifiable {
            let id = UUID()
            let title: String
            let detail: String
        }

        let id = UUID()
        let title: String
        let location: String
        let briefing: String
        let station: String
        let options: [Option]
        let correctIndex: Int
        let successLine: String
        let failureLine: String
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var phase: Phase = .briefing
    @State private var scenarios: [BridgeScenario] = TLBridgeMiniGameView.makeScenarioDeck()
    @State private var index = 0
    @State private var selectedOptionID: UUID?
    @State private var revealed = false
    @State private var commandScore = 0
    @State private var shipIntegrity = 100
    @State private var bridgeStatus = "Bridge on standby. Awaiting mission orders."
    @State private var commendations: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                bridgeHeader

                switch phase {
                case .briefing:
                    briefingCard
                case .inProgress:
                    missionDeck
                case .debrief:
                    debriefDeck
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(bridgeBackground.ignoresSafeArea())
        .navigationTitle("Bridge Command")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(phase == .briefing ? "Launch" : "Reset") {
                    resetGame(startImmediately: phase == .briefing)
                }
            }
        }
    }

    private var currentScenario: BridgeScenario? {
        guard scenarios.indices.contains(index) else { return nil }
        return scenarios[index]
    }

    private var bridgeHeader: some View {
        BridgePanel(fill: BridgePalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TACTICAL COMMAND SIM")
                            .font(.headline.bold())
                            .foregroundStyle(BridgePalette.textBright)

                        Text("Issue the right order, keep the ship together, and try to sound like you meant it.")
                            .font(.subheadline)
                            .foregroundStyle(BridgePalette.textMuted)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        bridgeCapsule("MISSION", value: "\(min(index + 1, scenarios.count))/\(scenarios.count)")
                        bridgeCapsule("INTEGRITY", value: "\(shipIntegrity)%")
                    }
                }

                HStack(spacing: 10) {
                    statusNode(title: "Command", value: "\(commandScore)")
                    statusNode(title: "Readiness", value: readinessLabel)
                    statusNode(title: "Station", value: currentScenario?.station ?? "Standby")
                }
            }
        }
    }

    private var briefingCard: some View {
        VStack(spacing: 16) {
            BridgePanel(fill: BridgePalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bridge Duty Rotation")
                        .font(.title2.bold())
                        .foregroundStyle(BridgePalette.textBright)

                    Text("You’ll face a sequence of bridge incidents. Pick the order that best matches the moment. Good calls raise command score; shaky calls scrape the hull.")
                        .foregroundStyle(BridgePalette.textMuted)

                    missionLine(title: "Station reports", detail: "Each scenario highlights the lead console.")
                    missionLine(title: "Ship integrity", detail: "Bad calls reduce hull and shield confidence.")
                    missionLine(title: "Debrief log", detail: "Strong calls earn bridge commendations.")
                }
            }

            launchButton(title: "Take the Center Seat") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var missionDeck: some View {
        VStack(spacing: 16) {
            if let scenario = currentScenario {
                bridgeViewport(for: scenario)
                optionsPanel(for: scenario)
                commandConsole
            }
        }
    }

    private func bridgeViewport(for scenario: BridgeScenario) -> some View {
        BridgePanel(fill: BridgePalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scenario.title)
                            .font(.title3.bold())
                            .foregroundStyle(BridgePalette.textBright)
                        Text(scenario.location)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BridgePalette.gold)
                    }

                    Spacer(minLength: 0)

                    Label(scenario.station, systemImage: "dot.scope")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BridgePalette.textMuted)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(BridgePalette.viewport)

                    bridgeSweep

                    VStack(spacing: 12) {
                        Image(systemName: scenarioSymbol(for: scenario))
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(BridgePalette.cyan)
                            .modifier(BridgePulseModifier(isEnabled: !reduceMotion, trigger: index))

                        Text(scenario.briefing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BridgePalette.textBright)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                }
                .frame(height: 220)

                Text(bridgeStatus)
                    .font(.subheadline)
                    .foregroundStyle(BridgePalette.textMuted)
            }
        }
    }

    private func optionsPanel(for scenario: BridgeScenario) -> some View {
        BridgePanel(fill: BridgePalette.panel) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Command Options")
                    .font(.headline)
                    .foregroundStyle(BridgePalette.textBright)

                ForEach(Array(scenario.options.enumerated()), id: \.element.id) { offset, option in
                    let state = optionState(option, correctID: scenario.options[scenario.correctIndex].id)
                    Button {
                        guard !revealed else { return }
                        selectedOptionID = option.id
                        revealChoice(for: scenario, selectedIndex: offset)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(state.badgeColor)
                                    .frame(width: 34, height: 34)
                                Text(letter(for: offset))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.black.opacity(0.82))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.headline)
                                    .foregroundStyle(BridgePalette.textBright)
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(BridgePalette.textMuted)
                            }

                            Spacer(minLength: 0)

                            if let icon = state.icon {
                                Image(systemName: icon)
                                    .foregroundStyle(state.badgeColor)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(state.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(state.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(revealed)
                }
            }
        }
    }

    private var commandConsole: some View {
        BridgePanel(fill: BridgePalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Console Feed")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(BridgePalette.textDim)

                Text(revealed ? "Decision logged. Advance when ready." : "Awaiting command input from the center seat.")
                    .foregroundStyle(BridgePalette.textBright)

                Button {
                    advanceScenario()
                } label: {
                    Label(index == scenarios.count - 1 ? "Open Debrief" : "Next Incident", systemImage: "arrow.right.circle.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black.opacity(0.84))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(revealed ? BridgePalette.gold : BridgePalette.gold.opacity(0.32))
                )
                .disabled(!revealed)
            }
        }
    }

    private var debriefDeck: some View {
        VStack(spacing: 16) {
            BridgePanel(fill: BridgePalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Mission Debrief")
                        .font(.title2.bold())
                        .foregroundStyle(BridgePalette.textBright)
                    Text(debriefSummary)
                        .foregroundStyle(BridgePalette.textMuted)

                    HStack(spacing: 10) {
                        statusNode(title: "Command", value: "\(commandScore)")
                        statusNode(title: "Integrity", value: "\(shipIntegrity)%")
                        statusNode(title: "Rank", value: commandScore >= 18 ? "Captain" : "XO")
                    }
                }
            }

            BridgePanel(fill: BridgePalette.panel) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Commendations")
                        .font(.headline)
                        .foregroundStyle(BridgePalette.textBright)

                    ForEach(commendations, id: \.self) { line in
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(BridgePalette.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }
            }

            launchButton(title: "Run Another Simulation") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var bridgeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 7 / 255, green: 10 / 255, blue: 18 / 255),
                    Color(red: 10 / 255, green: 18 / 255, blue: 34 / 255),
                    Color(red: 20 / 255, green: 16 / 255, blue: 28 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [BridgePalette.red.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 18,
                endRadius: 220
            )

            RadialGradient(
                colors: [BridgePalette.cyan.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 12,
                endRadius: 280
            )
        }
    }

    private var bridgeSweep: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.clear

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, BridgePalette.cyan.opacity(0.34), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 90)
                    .blur(radius: 4)
                    .offset(x: reduceMotion ? geometry.size.width * 0.55 : geometry.size.width * 0.62)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityHidden(true)
    }

    private var readinessLabel: String {
        switch shipIntegrity {
        case 85...: return "Green"
        case 65..<85: return "Yellow"
        default: return "Red"
        }
    }

    private var debriefSummary: String {
        if commandScore >= 18 {
            return "You ran the bridge with calm precision. The crew is ready to follow you into the Neutral Zone or at least into a staff meeting."
        } else if commandScore >= 12 {
            return "The ship made it home, and your officers only had to improvise a little."
        } else {
            return "The bridge survived the simulation. Starfleet recommends more time with the tactical handbook."
        }
    }

    private func missionLine(title: String, detail: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(BridgePalette.textBright)
            Spacer(minLength: 12)
            Text(detail)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(BridgePalette.textMuted)
        }
        .font(.subheadline)
    }

    private func bridgeCapsule(_ title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(BridgePalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BridgePalette.gold, in: Capsule())
        }
    }

    private func statusNode(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(BridgePalette.textDim)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(BridgePalette.textBright)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(BridgePalette.console, in: Capsule())
    }

    private func launchButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "play.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black.opacity(0.84))
        .background(BridgePalette.gold, in: RoundedRectangle(cornerRadius: 20))
    }

    private func optionState(_ option: BridgeScenario.Option, correctID: UUID) -> (background: Color, border: Color, badgeColor: Color, icon: String?) {
        guard revealed else {
            let isSelected = option.id == selectedOptionID
            return (
                isSelected ? BridgePalette.consoleSelected : BridgePalette.console,
                isSelected ? BridgePalette.cyan.opacity(0.8) : BridgePalette.stroke,
                isSelected ? BridgePalette.cyan : BridgePalette.gold,
                nil
            )
        }

        if option.id == correctID {
            return (BridgePalette.success.opacity(0.22), BridgePalette.success, BridgePalette.success, "checkmark.circle.fill")
        }

        if option.id == selectedOptionID {
            let accent = differentiateWithoutColor ? BridgePalette.gold : BridgePalette.red
            return (accent.opacity(0.18), accent, accent, "xmark.circle.fill")
        }

        return (BridgePalette.console, BridgePalette.stroke, BridgePalette.gold, nil)
    }

    private func revealChoice(for scenario: BridgeScenario, selectedIndex: Int) {
        revealed = true
        let isCorrect = selectedIndex == scenario.correctIndex

        if isCorrect {
            commandScore += 4
            bridgeStatus = scenario.successLine
            commendations.append("Strong \(scenario.station.lowercased()) decision during “\(scenario.title)”")
        } else {
            commandScore += 1
            shipIntegrity = max(shipIntegrity - 12, 12)
            bridgeStatus = scenario.failureLine
        }
    }

    private func advanceScenario() {
        if index == scenarios.count - 1 {
            phase = .debrief
            if commendations.isEmpty {
                commendations = ["The bridge remained operational under pressure.", "Crew morale stayed above the minimum acceptable threshold."]
            }
        } else {
            index += 1
            selectedOptionID = nil
            revealed = false
            bridgeStatus = "New incident incoming. Awaiting command."
        }
    }

    private func scenarioSymbol(for scenario: BridgeScenario) -> String {
        if scenario.title.localizedCaseInsensitiveContains("Klingon") { return "shield.lefthalf.filled" }
        if scenario.title.localizedCaseInsensitiveContains("Nebula") { return "smoke.fill" }
        if scenario.title.localizedCaseInsensitiveContains("Distress") { return "dot.radiowaves.left.and.right" }
        if scenario.title.localizedCaseInsensitiveContains("Temporal") { return "clock.arrow.trianglehead.counterclockwise.rotate.90" }
        return "sparkles"
    }

    private func letter(for index: Int) -> String {
        let scalar = UnicodeScalar(65 + index) ?? UnicodeScalar(65)!
        return String(Character(scalar))
    }

    private func resetGame(startImmediately: Bool) {
        scenarios = Self.makeScenarioDeck()
        index = 0
        selectedOptionID = nil
        revealed = false
        commandScore = 0
        shipIntegrity = 100
        commendations = []
        bridgeStatus = "Bridge on standby. Awaiting mission orders."
        phase = startImmediately ? .inProgress : .briefing
    }

    private static func makeScenarioDeck() -> [BridgeScenario] {
        [
            BridgeScenario(
                title: "Klingon Intercept",
                location: "Argelius Expanse",
                briefing: "A Bird-of-Prey decloaks off the bow and starts matching your turn rate.",
                station: "Tactical",
                options: [
                    .init(title: "Raise shields and hold phasers", detail: "Project readiness without escalating first."),
                    .init(title: "Fire warning shots immediately", detail: "Show initiative, skip diplomacy."),
                    .init(title: "Drop shields to appear peaceful", detail: "Trust the vibes.")
                ],
                correctIndex: 0,
                successLine: "Tactical reports a balanced posture. The Klingon captain opens a channel instead of a hull breach.",
                failureLine: "The bridge lurches as the Klingons seize the initiative. Next time, maybe don’t lead with chaos."
            ),
            BridgeScenario(
                title: "Nebula Sensor Ghost",
                location: "Mutara-class nebula",
                briefing: "Long-range sensors are throwing duplicate starship signatures and helm wants clean vectors.",
                station: "Science",
                options: [
                    .init(title: "Recalibrate sensors for baryon scatter", detail: "Filter the nebula and rebuild the tactical map."),
                    .init(title: "Go to warp to clear the interference", detail: "Leave before learning anything."),
                    .init(title: "Use visual contact only", detail: "Fly blind and hope for the best.")
                ],
                correctIndex: 0,
                successLine: "Science cuts through the nebular distortion and helm gets a clean lane.",
                failureLine: "The duplicate contacts keep dancing across the screen, and helm is now muttering about your leadership."
            ),
            BridgeScenario(
                title: "Colony Distress Call",
                location: "Theta Cygni IV",
                briefing: "A colony requests immediate power support while an ion storm builds overhead.",
                station: "Operations",
                options: [
                    .init(title: "Beam emergency cells and coordinate evacuation", detail: "Support the colony while controlling risk."),
                    .init(title: "Wait for Starfleet Command approval", detail: "Technically correct, dramatically late."),
                    .init(title: "Send one shuttle with no escort", detail: "Minimal paperwork, maximal danger.")
                ],
                correctIndex: 0,
                successLine: "Operations synchronizes the rescue and the colony’s grid holds long enough to evacuate civilians.",
                failureLine: "The storm intensifies while your delay chews up the rescue window."
            ),
            BridgeScenario(
                title: "Temporal Feedback",
                location: "Chroniton wake",
                briefing: "The ship starts receiving its own damaged log entries from seventeen minutes in the future.",
                station: "Engineering",
                options: [
                    .init(title: "Reduce warp output and isolate the deflector", detail: "Stabilize the ship before the feedback loops."),
                    .init(title: "Increase warp to outrun the anomaly", detail: "A bold misunderstanding of time."),
                    .init(title: "Ignore the logs until they repeat", detail: "Let the paradox marinate.")
                ],
                correctIndex: 0,
                successLine: "Engineering dampens the chroniton surge and the future logs stop accusing you of bad command.",
                failureLine: "The deck plating groans as the feedback cascade deepens through the EPS grid."
            )
        ]
        .shuffled()
    }
}

private struct BridgePanel<Content: View>: View {
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
                .stroke(BridgePalette.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.30), radius: 18, y: 10)
    }
}

private struct BridgePulseModifier: ViewModifier {
    let isEnabled: Bool
    let trigger: Int

    func body(content: Content) -> some View {
        if isEnabled {
            content.symbolEffect(.pulse, value: trigger)
        } else {
            content
        }
    }
}

private enum BridgePalette {
    static let shell = LinearGradient(
        colors: [Color(red: 28 / 255, green: 20 / 255, blue: 24 / 255), Color(red: 18 / 255, green: 23 / 255, blue: 37 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panel = LinearGradient(
        colors: [Color(red: 20 / 255, green: 25 / 255, blue: 38 / 255), Color(red: 11 / 255, green: 17 / 255, blue: 30 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let viewport = Color(red: 9 / 255, green: 15 / 255, blue: 28 / 255)
    static let console = Color(red: 14 / 255, green: 20 / 255, blue: 32 / 255)
    static let consoleSelected = Color(red: 18 / 255, green: 28 / 255, blue: 46 / 255)
    static let stroke = Color.white.opacity(0.08)
    static let textBright = Color(red: 244 / 255, green: 246 / 255, blue: 251 / 255)
    static let textMuted = Color(red: 183 / 255, green: 195 / 255, blue: 215 / 255)
    static let textDim = Color(red: 124 / 255, green: 142 / 255, blue: 165 / 255)
    static let gold = Color(red: 1, green: 194 / 255, blue: 103 / 255)
    static let cyan = Color(red: 92 / 255, green: 215 / 255, blue: 1)
    static let red = Color(red: 1, green: 104 / 255, blue: 104 / 255)
    static let success = Color(red: 111 / 255, green: 234 / 255, blue: 171 / 255)
}
