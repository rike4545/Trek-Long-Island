// Copyright Bryan Carroll. All rights reserved.
//
//  TLTurboLiftGameView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct TLTurboLiftGameView: View {
    private enum Phase {
        case queue
        case routing
        case summary
    }

    private struct DeckStop: Identifiable, Hashable {
        let deck: Int
        let label: String

        var id: Int { deck }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var phase: Phase = .queue
    @State private var currentDeck = 8
    @State private var pendingStops = TLTurboLiftGameView.generateStops()
    @State private var completedStops: [DeckStop] = []
    @State private var movesUsed = 0
    @State private var queueStatus = "TurboLift idle at Deck 8."
    @State private var doorMessage = "Awaiting route authorization."
    @State private var routeScore = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                liftHeader

                switch phase {
                case .queue:
                    queueDeck
                case .routing:
                    routingDeck
                case .summary:
                    summaryDeck
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(liftBackground.ignoresSafeArea())
        .navigationTitle("TurboLift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(phase == .queue ? "Dispatch" : "Reset") {
                    resetGame(startImmediately: phase == .queue)
                }
            }
        }
    }

    private var currentTarget: DeckStop? {
        pendingStops.first
    }

    private var liftHeader: some View {
        LiftPanel(fill: LiftPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TURBOLIFT TRAFFIC CONTROL")
                            .font(.headline.bold())
                            .foregroundStyle(LiftPalette.textBright)

                        Text("Route passengers efficiently, stop on the correct deck, and keep the shaft clear.")
                            .font(.subheadline)
                            .foregroundStyle(LiftPalette.textMuted)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        liftBadge("DECK", value: "\(currentDeck)")
                        liftBadge("SCORE", value: "\(routeScore)")
                    }
                }

                HStack(spacing: 10) {
                    liftPill("Pending", value: "\(pendingStops.count)")
                    liftPill("Moves", value: "\(movesUsed)")
                    liftPill("Mode", value: phase == .routing ? "En Route" : "Standby")
                }
            }
        }
    }

    private var queueDeck: some View {
        VStack(spacing: 16) {
            LiftPanel(fill: LiftPalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Passenger Queue")
                        .font(.title2.bold())
                        .foregroundStyle(LiftPalette.textBright)

                    Text("You have a stack of priority stops from around the ship. Reach each destination, then open the doors on the correct deck to clear the request.")
                        .foregroundStyle(LiftPalette.textMuted)

                    ForEach(pendingStops) { stop in
                        stopRow(stop, isActive: stop == currentTarget)
                    }
                }
            }

            beginButton(title: "Authorize Route") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var routingDeck: some View {
        VStack(spacing: 16) {
            shaftPanel
            routeQueuePanel
            controlsPanel
        }
    }

    private var shaftPanel: some View {
        LiftPanel(fill: LiftPalette.panel) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Lift Shaft")
                        .font(.headline)
                        .foregroundStyle(LiftPalette.textBright)
                    Spacer(minLength: 0)
                    if let target = currentTarget {
                        Text("Target: \(target.label)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LiftPalette.gold)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(visibleDecks, id: \.self) { deck in
                        HStack(spacing: 10) {
                            Text("Deck \(deck)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(deck == currentDeck ? LiftPalette.textBright : LiftPalette.textMuted)
                                .frame(width: 74, alignment: .leading)

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LiftPalette.console)
                                    .frame(height: 34)

                                if deck == currentDeck {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LiftPalette.cyan)
                                        .frame(width: 120, height: 34)
                                        .overlay(alignment: .leading) {
                                            Label("CAR", systemImage: "capsule.bottomhalf.filled")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.black.opacity(0.82))
                                                .padding(.horizontal, 10)
                                        }
                                } else if currentTarget?.deck == deck {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(LiftPalette.gold, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                        .frame(height: 34)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }

                Text(queueStatus)
                    .font(.subheadline)
                    .foregroundStyle(LiftPalette.textMuted)
            }
        }
    }

    private var routeQueuePanel: some View {
        LiftPanel(fill: LiftPalette.panel) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Route Queue")
                    .font(.headline)
                    .foregroundStyle(LiftPalette.textBright)

                if pendingStops.isEmpty {
                    Text("All passengers delivered.")
                        .foregroundStyle(LiftPalette.textMuted)
                } else {
                    ForEach(pendingStops) { stop in
                        stopRow(stop, isActive: stop == currentTarget)
                    }
                }

                if !completedStops.isEmpty {
                    Divider().overlay(LiftPalette.stroke)
                    Text("Completed: \(completedStops.map(\.label).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(LiftPalette.textDim)
                }
            }
        }
    }

    private var controlsPanel: some View {
        LiftPanel(fill: LiftPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Cab Controls")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(LiftPalette.textDim)

                Text(doorMessage)
                    .foregroundStyle(LiftPalette.textBright)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        controlKey("Down", systemImage: "arrow.down.circle.fill") { move(by: -1) }
                        controlKey("Express -3", systemImage: "backward.end.circle.fill") { move(by: -3) }
                        controlKey("Open Doors", systemImage: "door.left.hand.open") { openDoors() }
                        controlKey("Express +3", systemImage: "forward.end.circle.fill") { move(by: 3) }
                        controlKey("Up", systemImage: "arrow.up.circle.fill") { move(by: 1) }
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            controlKey("Down", systemImage: "arrow.down.circle.fill") { move(by: -1) }
                            controlKey("Up", systemImage: "arrow.up.circle.fill") { move(by: 1) }
                        }

                        HStack(spacing: 12) {
                            controlKey("Express -3", systemImage: "backward.end.circle.fill") { move(by: -3) }
                            controlKey("Express +3", systemImage: "forward.end.circle.fill") { move(by: 3) }
                        }

                        controlKey("Open Doors", systemImage: "door.left.hand.open", prominent: true) { openDoors() }
                    }
                }
            }
        }
    }

    private var summaryDeck: some View {
        VStack(spacing: 16) {
            LiftPanel(fill: LiftPalette.panel) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Route Complete")
                        .font(.title2.bold())
                        .foregroundStyle(LiftPalette.textBright)

                    Text(summaryText)
                        .foregroundStyle(LiftPalette.textMuted)

                    HStack(spacing: 10) {
                        liftPill("Score", value: "\(routeScore)")
                        liftPill("Moves", value: "\(movesUsed)")
                        liftPill("Rating", value: routeScore >= 180 ? "Priority" : "Standard")
                    }
                }
            }

            routeQueuePanel

            beginButton(title: "Queue New Route") {
                resetGame(startImmediately: true)
            }
        }
    }

    private var liftBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 8 / 255, green: 9 / 255, blue: 19 / 255),
                    Color(red: 18 / 255, green: 13 / 255, blue: 28 / 255),
                    Color(red: 14 / 255, green: 24 / 255, blue: 39 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [LiftPalette.gold.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 12,
                endRadius: 240
            )

            RadialGradient(
                colors: [LiftPalette.cyan.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 12,
                endRadius: 300
            )
        }
    }

    private var visibleDecks: [Int] {
        let minimum = max(currentDeck - 3, 1)
        let maximum = min(currentDeck + 3, 22)
        return Array((minimum...maximum).reversed())
    }

    private var summaryText: String {
        if routeScore >= 180 {
            return "You ran the shaft like a senior operations officer. Nobody got stuck between decks and the passengers remain surprisingly calm."
        } else if routeScore >= 120 {
            return "The route cleared successfully. A few officers sighed dramatically, but the lift kept moving."
        } else {
            return "The passengers reached their destinations eventually. Starfleet suggests fewer scenic detours next time."
        }
    }

    private func liftBadge(_ title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(LiftPalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LiftPalette.gold, in: Capsule())
        }
    }

    private func liftPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(LiftPalette.textDim)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(LiftPalette.textBright)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(LiftPalette.console, in: Capsule())
    }

    private func stopRow(_ stop: DeckStop, isActive: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.label)
                    .font(.headline)
                    .foregroundStyle(LiftPalette.textBright)
                Text("Deck \(stop.deck)")
                    .font(.caption)
                    .foregroundStyle(LiftPalette.textMuted)
            }

            Spacer(minLength: 8)

            Text(isActive ? "ACTIVE" : "QUEUED")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? LiftPalette.cyan : LiftPalette.gold.opacity(0.7), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    private func controlKey(_ title: String, systemImage: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? .black.opacity(0.84) : LiftPalette.textBright)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(prominent ? LiftPalette.gold : LiftPalette.console)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(prominent ? LiftPalette.gold.opacity(0.4) : LiftPalette.stroke, lineWidth: 1)
        )
    }

    private func beginButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "play.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black.opacity(0.84))
        .background(LiftPalette.gold, in: RoundedRectangle(cornerRadius: 20))
    }

    private func move(by amount: Int) {
        guard phase == .routing else { return }
        currentDeck = min(max(currentDeck + amount, 1), 22)
        movesUsed += 1
        queueStatus = "TurboLift now holding at Deck \(currentDeck)."
        doorMessage = currentTarget?.deck == currentDeck
            ? "Target reached. Open doors to clear the stop."
            : "Still routing to \(currentTarget?.label ?? "next stop")."
    }

    private func openDoors() {
        guard phase == .routing, let target = currentTarget else { return }

        if currentDeck == target.deck {
            pendingStops.removeFirst()
            completedStops.append(target)
            let bonus = max(50 - movesUsed, 10)
            routeScore += bonus
            queueStatus = "Stop cleared at \(target.label)."
            doorMessage = pendingStops.isEmpty
                ? "All stops complete. Preparing route summary."
                : "Passengers transferred. Continue to \(pendingStops[0].label)."

            if pendingStops.isEmpty {
                phase = .summary
            }
        } else {
            routeScore = max(routeScore - 8, 0)
            doorMessage = "Doors opened on the wrong deck. Passenger grumbling increased."
            queueStatus = "Route mismatch detected."
            if differentiateWithoutColor {
                queueStatus += " Confirm the deck number before opening again."
            }
        }
    }

    private func resetGame(startImmediately: Bool) {
        currentDeck = 8
        pendingStops = Self.generateStops()
        completedStops = []
        movesUsed = 0
        queueStatus = "TurboLift idle at Deck 8."
        doorMessage = "Awaiting route authorization."
        routeScore = 0
        phase = startImmediately ? .routing : .queue
    }

    private static func generateStops() -> [DeckStop] {
        let stops: [DeckStop] = [
            .init(deck: 2, label: "Bridge"),
            .init(deck: 5, label: "Science Labs"),
            .init(deck: 7, label: "Crew Quarters"),
            .init(deck: 9, label: "Ten Forward"),
            .init(deck: 11, label: "Transporter Room"),
            .init(deck: 14, label: "Shuttle Bay"),
            .init(deck: 16, label: "Engineering"),
            .init(deck: 19, label: "Cargo Control")
        ]

        return Array(stops.shuffled().prefix(4))
    }
}

private struct LiftPanel<Content: View>: View {
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
                .stroke(LiftPalette.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

private enum LiftPalette {
    static let shell = LinearGradient(
        colors: [Color(red: 28 / 255, green: 18 / 255, blue: 30 / 255), Color(red: 15 / 255, green: 18 / 255, blue: 34 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panel = LinearGradient(
        colors: [Color(red: 19 / 255, green: 22 / 255, blue: 38 / 255), Color(red: 11 / 255, green: 14 / 255, blue: 28 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let console = Color(red: 14 / 255, green: 18 / 255, blue: 30 / 255)
    static let stroke = Color.white.opacity(0.08)
    static let textBright = Color(red: 244 / 255, green: 247 / 255, blue: 251 / 255)
    static let textMuted = Color(red: 180 / 255, green: 194 / 255, blue: 216 / 255)
    static let textDim = Color(red: 124 / 255, green: 144 / 255, blue: 166 / 255)
    static let gold = Color(red: 1, green: 194 / 255, blue: 106 / 255)
    static let cyan = Color(red: 86 / 255, green: 227 / 255, blue: 224 / 255)
    static let red = Color(red: 1, green: 110 / 255, blue: 116 / 255)
}
