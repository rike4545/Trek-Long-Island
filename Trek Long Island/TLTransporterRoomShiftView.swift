// Copyright Bryan Carroll. All rights reserved.
//
//  TLTransporterRoomShiftView.swift
//  Trek Long Island
//
//  Transporter Room “Shift” — Star Trek console aesthetic (READABLE in Light/Dark)
//  Swift 6 • iOS 17+
//
//  Drop-in file. Present: TLTransporterRoomShiftView()
//  Key fixes vs prior:
//  - No global forced color scheme (so your TabBar won’t wash out)
//  - Text uses explicit high-contrast Trek colors (so it’s readable even in Light mode)
//  - Panels are more opaque + material blur to stop stars fighting the UI
//  - Destination uses a custom Menu button so the label is always readable
//

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Public View

@MainActor
public struct TLTransporterRoomShiftView: View {
    @StateObject private var vm = TLTRTransporterVM()

    public init() {}

    public var body: some View {
        ZStack {
            TLTRStarfieldBackground()
                .opacity(0.22)
                .ignoresSafeArea()

            TLTRNebulaWash()
                .opacity(0.40)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 14) {
                    headerPanel
                    controlPanel
                    transporterBay

                    if vm.isRunning || vm.lastResult != nil {
                        statusPanel
                    }

                    logPanel

                    Color.clear.frame(height: 16)
                }
                .padding()
                .padding(.bottom, 118) // space for fixed bottom console bar
            }
        }
        .navigationTitle("Transporter Room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        vm.resetAll()
                    } label: {
                        Label("Reset Console", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        vm.clearLog()
                    } label: {
                        Label("Clear Log", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                TLIBottomAdContainer()
                bottomConsoleBar
            }
        }
        .animation(.snappy(duration: 0.25), value: vm.isRunning)
        .animation(.snappy(duration: 0.25), value: vm.lastResult)
    }

    // MARK: - Panels

    private var headerPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            TLTRLcarsPips()
                .frame(width: 46)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("TRANSPORT CONSOLE")
                        .font(.caption.weight(.semibold))
                        .tracking(1.25)
                        .foregroundStyle(TLTRColors.muted)

                    Spacer()

                    TLTRStatusLight(isOn: vm.isRunning)
                }

                Text("Chief O’Brien is busy.\nYou’re up.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TLTRColors.primary)

                Text("Pick a destination, set your totally-scientific knobs, and press **ENERGIZE**. Results may vary by timeline.")
                    .font(.subheadline)
                    .foregroundStyle(TLTRColors.secondary)
            }
        }
        .tlConsolePanel()
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            TLTRPanelHeader(title: "CONTROL PANEL", subtitle: "Do not spill raktajino on the buttons.")

            HStack(spacing: 12) {
                TLTRFieldCard(title: "Destination", icon: "location.fill") {
                    TLTRDestinationMenu(selection: $vm.destination)
                }

                TLTRFieldCard(title: "Mode", icon: "slider.horizontal.3") {
                    Picker("Mode", selection: $vm.mode) {
                        ForEach(TLTRMode.allCases, id: \.self) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(TLTRPalette.orange)
                    // keep segmented readable regardless of the host scheme
                    .environment(\.colorScheme, .dark)
                }
            }

            VStack(spacing: 10) {
                TLTRToggleRow(
                    title: "Safety Interlocks",
                    subtitleOn: "OSHA-approved. Boring, but alive.",
                    subtitleOff: "Bold choice. Statistically exciting.",
                    iconOn: "lock.fill",
                    iconOff: "lock.open.fill",
                    isOn: $vm.safetyInterlocks
                )

                TLTRToggleRow(
                    title: "Pattern Stabilizer",
                    subtitleOn: "Keeps your atoms on speaking terms.",
                    subtitleOff: "Enables “creative” outcomes.",
                    iconOn: "waveform.path.ecg",
                    iconOff: "waveform.path.ecg",
                    isOn: $vm.patternStabilizer
                )
            }

            VStack(spacing: 12) {
                TLTRSliderRow(
                    title: "Sass Level",
                    icon: "theatermasks.fill",
                    valueText: "\(vm.sassLevel)%",
                    range: 0...100,
                    step: 5,
                    value: $vm.sassLevelDouble
                )

                TLTRSliderRow(
                    title: "Buffer Time",
                    icon: "clock.fill",
                    valueText: vm.bufferTimeLabel,
                    range: 0...8,
                    step: 1,
                    value: $vm.bufferSecondsDouble
                )
            }
        }
        .tlConsolePanel()
    }

    private var transporterBay: some View {
        VStack(alignment: .leading, spacing: 12) {
            TLTRPanelHeader(
                title: "TRANSPORT PAD",
                subtitle: vm.isRunning ? "Confinement beam active. Try not to blink." : "Pattern ready. Stand by to be iconic."
            )

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TLTRColors.padFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(TLTRColors.stroke, lineWidth: 1)
                    )

                VStack(spacing: 10) {
                    ZStack {
                        TLTRPadRings(isActive: vm.isRunning)
                            .frame(width: 168, height: 168)

                        TLTRBeamEffect(isActive: vm.isRunning)
                            .frame(width: 168, height: 168)
                            .clipShape(Circle())

                        Image(systemName: vm.isRunning ? "sparkles" : "person.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.95), .white.opacity(0.55))
                            .opacity(vm.isRunning ? 0.82 : 1.0)
                    }

                    Text(vm.isRunning ? "Pattern in transit…" : "Pattern ready.")
                        .font(.headline)
                        .foregroundStyle(TLTRColors.primary)

                    Text(vm.isRunning ? "Keep hands inside the timeline at all times." : "Proceed when ready, Ensign.")
                        .font(.subheadline)
                        .foregroundStyle(TLTRColors.secondary)
                }
                .padding()
            }
            .frame(height: 260)
        }
        .tlConsolePanel()
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("TRANSPORT STATUS", systemImage: "terminal.fill")
                    .font(.headline)
                    .foregroundStyle(TLTRColors.primary)
                Spacer()
                if vm.isRunning { ProgressView().tint(.white) }
            }

            Text(vm.statusLine)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(TLTRColors.consoleFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(TLTRColors.stroke, lineWidth: 1)
                )

            if let result = vm.lastResult, !vm.isRunning {
                Divider().opacity(0.25)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: result.outcome.icon)
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(result.outcome.tint)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.title)
                            .font(.headline)
                            .foregroundStyle(TLTRColors.primary)

                        Text(result.message)
                            .font(.subheadline)
                            .foregroundStyle(TLTRColors.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        let cols = [GridItem(.adaptive(minimum: 112), spacing: 10, alignment: .leading)]
                        LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                            TLTRBadge(label: "Integrity", value: "\(result.integrity)%")
                            TLTRBadge(label: "Timeline", value: result.timeline)
                            TLTRBadge(label: "Snack", value: result.snack)
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .tlConsolePanel()
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CAPTAIN’S LOG", systemImage: "list.bullet.rectangle.fill")
                    .font(.headline)
                    .foregroundStyle(TLTRColors.primary)

                Spacer()

                Text("\(vm.log.count)")
                    .monospacedDigit()
                    .foregroundStyle(TLTRColors.muted)
            }

            if vm.log.isEmpty {
                Text("No transports yet. This is the calm before the narrative convenience.")
                    .font(.subheadline)
                    .foregroundStyle(TLTRColors.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.log.prefix(8)) { entry in
                        TLTRLogRow(entry: entry)
                    }
                }
            }
        }
        .tlConsolePanel()
    }

    // MARK: - Bottom Console Bar

    private var bottomConsoleBar: some View {
        VStack(spacing: 10) {
            Divider().opacity(0.25)

            HStack(spacing: 12) {
                TLTRLcarsPips()
                    .frame(width: 58, height: 56)

                Button {
                    vm.energize()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: vm.isRunning ? "hourglass" : "bolt.fill")
                        Text(vm.isRunning ? "Energizing…" : "ENERGIZE")
                            .font(.headline)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(TLTRPrimaryButtonStyle())
                .disabled(vm.isRunning)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - View Model

@MainActor
fileprivate final class TLTRTransporterVM: ObservableObject {
    @Published var destination: TLTRDestination = .vendorHall
    @Published var mode: TLTRMode = .personnel
    @Published var safetyInterlocks: Bool = true
    @Published var patternStabilizer: Bool = true
    @Published var sassLevel: Int = 35
    @Published var bufferSeconds: Int = 2

    @Published var isRunning: Bool = false
    @Published var statusLine: String = "Standing by."
    @Published var lastResult: TLTRResult? = nil
    @Published var log: [TLTRLogEntry] = []

    var sassLevelDouble: Double {
        get { Double(sassLevel) }
        set { sassLevel = Int(newValue.rounded()) }
    }

    var bufferSecondsDouble: Double {
        get { Double(bufferSeconds) }
        set { bufferSeconds = Int(newValue.rounded()) }
    }

    var bufferTimeLabel: String {
        bufferSeconds == 0 ? "Off" : "\(bufferSeconds)s"
    }

    func resetAll() {
        destination = .vendorHall
        mode = .personnel
        safetyInterlocks = true
        patternStabilizer = true
        sassLevel = 35
        bufferSeconds = 2
        statusLine = "Standing by."
        lastResult = nil
        isRunning = false
    }

    func clearLog() { log.removeAll() }

    func energize() {
        guard !isRunning else { return }
        isRunning = true
        lastResult = nil

        let config = TLTRConfig(
            destination: destination,
            mode: mode,
            safetyInterlocks: safetyInterlocks,
            patternStabilizer: patternStabilizer,
            sassLevel: sassLevel,
            bufferSeconds: bufferSeconds
        )

        haptic(.warning)
        Task { await runSequence(config: config) }
    }

    private func runSequence(config: TLTRConfig) async {
        let steps = TLTRScript.steps(for: config)
        for s in steps {
            await MainActor.run { self.statusLine = s }
            try? await Task.sleep(for: .milliseconds(520))
        }

        if config.bufferSeconds > 0 {
            await MainActor.run {
                self.statusLine = "Buffering pattern (\(config.bufferSeconds)s)… please do not blink at the console."
            }
            try? await Task.sleep(for: .seconds(config.bufferSeconds))
        }

        let result = TLTRScript.resolveOutcome(for: config)

        await MainActor.run {
            self.lastResult = result
            self.statusLine = result.consoleLine
            self.isRunning = false

            let entry = TLTRLogEntry(
                date: Date(),
                destination: config.destination.title,
                mode: config.mode.title,
                outcome: result.outcome.title,
                headline: result.title
            )
            self.log.insert(entry, at: 0)
            if self.log.count > 40 { self.log = Array(self.log.prefix(40)) }

            switch result.outcome {
            case .success: self.haptic(.success)
            case .warning: self.haptic(.warning)
            case .chaos: self.haptic(.error)
            }
        }
    }

    private enum TLTRHaptic { case success, warning, error }

    private func haptic(_ kind: TLTRHaptic) {
        #if canImport(UIKit)
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        switch kind {
        case .success: g.notificationOccurred(.success)
        case .warning: g.notificationOccurred(.warning)
        case .error: g.notificationOccurred(.error)
        }
        #endif
    }
}

// MARK: - Models

fileprivate enum TLTRMode: String, CaseIterable, Hashable {
    case personnel
    case cargo

    var title: String {
        switch self {
        case .personnel: return "Personnel"
        case .cargo: return "Cargo"
        }
    }
}

fileprivate enum TLTRDestination: String, CaseIterable, Hashable {
    case vendorHall
    case panelRoom
    case photoOps
    case foodCourt
    case parkingLot
    case bridgeSimulator
    case earth1986
    case risa
    case mirrorUniverse
    case holodeck

    var title: String {
        switch self {
        case .vendorHall: return "Vendor Hall"
        case .panelRoom: return "Panel Room"
        case .photoOps: return "Photo Ops"
        case .foodCourt: return "Food Court"
        case .parkingLot: return "Parking Lot"
        case .bridgeSimulator: return "Bridge Simulator"
        case .earth1986: return "Earth (1986)"
        case .risa: return "Risa (…probably)"
        case .mirrorUniverse: return "Mirror Universe"
        case .holodeck: return "Holodeck"
        }
    }
}

fileprivate struct TLTRConfig: Hashable {
    let destination: TLTRDestination
    let mode: TLTRMode
    let safetyInterlocks: Bool
    let patternStabilizer: Bool
    let sassLevel: Int
    let bufferSeconds: Int
}

fileprivate struct TLTRLogEntry: Identifiable, Hashable {
    let id: UUID = UUID()
    let date: Date
    let destination: String
    let mode: String
    let outcome: String
    let headline: String
}

fileprivate enum TLTROutcome: String, Hashable {
    case success
    case warning
    case chaos

    var title: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Minor Glitch"
        case .chaos: return "Spectacular Chaos"
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .chaos: return "tornado"
        }
    }

    var tint: Color {
        switch self {
        case .success: return .green
        case .warning: return .yellow
        case .chaos: return .red
        }
    }
}

fileprivate struct TLTRResult: Hashable {
    let outcome: TLTROutcome
    let title: String
    let message: String
    let integrity: Int
    let timeline: String
    let snack: String

    var consoleLine: String {
        switch outcome {
        case .success:
            return "Transport complete. Please exit the pad in a dignified manner."
        case .warning:
            return "Transport complete. Ignore the humming. It’s… *character*."
        case .chaos:
            return "Transport complete(?) Look, nobody’s on fire. Call it a win."
        }
    }
}

// MARK: - Script / Humor Engine

fileprivate enum TLTRScript {
    static func steps(for config: TLTRConfig) -> [String] {
        var lines: [String] = []
        lines.append("Initializing confinement beam…")
        lines.append("Acquiring pattern lock on \(config.mode.title.lowercased())…")

        lines.append(config.patternStabilizer
                     ? "Pattern stabilizer engaged. The universe exhales."
                     : "Pattern stabilizer offline. Bold choice.")

        lines.append(config.safetyInterlocks
                     ? "Safety interlocks enabled. OSHA approves."
                     : "Safety interlocks disabled. This is why we can’t have nice things.")

        if config.sassLevel >= 70 { lines.append("Computer voice set to *extra smug*.") }
        else if config.sassLevel >= 35 { lines.append("Computer voice set to *mildly judgmental*.") }
        else { lines.append("Computer voice set to *professional-ish*.") }

        lines.append("Compensating for plasma… vibes…")
        lines.append("Destination: \(config.destination.title). Stand by…")
        return lines
    }

    static func resolveOutcome(for config: TLTRConfig) -> TLTRResult {
        let seed = UInt64(Date().timeIntervalSince1970 * 1000)
        var rng = TLTRSeededRNG(seed: seed)

        var risk = 18
        risk += (config.sassLevel / 10)
        if !config.safetyInterlocks { risk += 25 }
        if !config.patternStabilizer { risk += 18 }
        if config.destination == .mirrorUniverse { risk += 18 }
        if config.destination == .earth1986 { risk += 10 }
        if config.mode == .cargo { risk += 6 }
        risk += max(0, 3 - config.bufferSeconds) * 6

        let roll = Int(rng.next() % 100)
        let chaosThreshold = min(70, 40 + risk / 2)
        let warningThreshold = min(85, chaosThreshold + 20)

        let outcome: TLTROutcome
        if roll < chaosThreshold { outcome = .chaos }
        else if roll < warningThreshold { outcome = .warning }
        else { outcome = .success }

        let integrityBase: Int = (outcome == .success) ? 96 : (outcome == .warning ? 88 : 72)
        let integrity = max(42, min(100, integrityBase + Int(rng.next() % 9) - 4))

        let timeline = timelineLabel(destination: config.destination, rng: &rng)
        let snack = snackLabel(rng: &rng)
        let (title, message) = punchline(outcome: outcome, config: config, rng: &rng)

        return .init(outcome: outcome, title: title, message: message, integrity: integrity, timeline: timeline, snack: snack)
    }

    private static func timelineLabel(destination: TLTRDestination, rng: inout TLTRSeededRNG) -> String {
        switch destination {
        case .mirrorUniverse: return "Beards: Mandatory"
        case .earth1986: return "Casual 80s"
        case .risa: return "Vacation-ish"
        case .holodeck: return "Simulated"
        default:
            let options = ["Prime", "Prime (Mostly)", "Prime Adjacent", "Definitely Prime?", "Ask Again Later"]
            return options[Int(rng.next() % UInt64(options.count))]
        }
    }

    private static func snackLabel(rng: inout TLTRSeededRNG) -> String {
        let options = ["Gagh (replicated)", "Raktajino", "Root Beer", "Plomeek Soup", "Tactical Mints", "Mystery Snack"]
        return options[Int(rng.next() % UInt64(options.count))]
    }

    private static func punchline(outcome: TLTROutcome, config: TLTRConfig, rng: inout TLTRSeededRNG) -> (String, String) {
        let dest = config.destination.title

        switch outcome {
        case .success:
            let titles = ["Clean Beam!", "Textbook Energize", "Pattern Perfection", "Zero Drama (Suspicious)"]
            let msgs = [
                "Arrived at \(dest) with all atoms accounted for. Classic overachiever behavior.",
                "Materialization successful. Your hair is only *slightly* more heroic.",
                "No anomalies detected. The transporter is disappointed it didn’t get to be the main character."
            ]
            return (titles[Int(rng.next() % UInt64(titles.count))], msgs[Int(rng.next() % UInt64(msgs.count))])

        case .warning:
            let titles = ["Minor Glitch, Major Vibes", "Acceptable Weirdness", "The Transporter Did A Little Bit"]
            let msgs = [
                "Arrived at \(dest) successfully, but your combadge now insists it’s a “limited edition.”",
                "Pattern held, mostly. Your footsteps may make a tiny ‘beep’ sound for the next hour.",
                "Transport complete with a modest quantum squeak. Try not to think about it."
            ]
            return (titles[Int(rng.next() % UInt64(titles.count))], msgs[Int(rng.next() % UInt64(msgs.count))])

        case .chaos:
            let titles = ["Spectacularly Energized", "This Is Fine 🔥", "We’re Calling It A Success", "Temporal Oopsie-Daisy"]
            let msgs = [
                "Arrived at \(dest)… and also emotionally at a new place. Please hydrate.",
                "A transporter duplicate has been created. They already claimed the aisle seat.",
                "You materialized facing the wrong direction with the confidence of a captain. Own it.",
                "The system attempted to enhance your charisma. Results may be louder than expected."
            ]
            return (titles[Int(rng.next() % UInt64(titles.count))], msgs[Int(rng.next() % UInt64(msgs.count))])
        }
    }
}

// MARK: - Trek UI / Styling

fileprivate enum TLTRPalette {
    static let orange = Color(red: 1.00, green: 0.58, blue: 0.15)
    static let purple = Color(red: 0.74, green: 0.54, blue: 1.00)
    static let cyan   = Color(red: 0.35, green: 0.78, blue: 1.00)
    static let sand   = Color(red: 0.95, green: 0.83, blue: 0.58)
}

fileprivate enum TLTRColors {
    // Text (explicit so it’s readable even if host is Light mode)
    static let primary   = Color.white.opacity(0.95)
    static let secondary = Color.white.opacity(0.74)
    static let muted     = Color.white.opacity(0.52)

    // Surfaces
    static let panelFill  = Color.black.opacity(0.78)
    static let panelGlass = Color.black.opacity(0.18)
    static let consoleFill = Color.black.opacity(0.86)
    static let padFill    = Color.black.opacity(0.72)

    static let stroke     = Color.white.opacity(0.18)
}

fileprivate extension View {
    func tlConsolePanel() -> some View {
        self
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(TLTRColors.panelFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(TLTRColors.stroke, lineWidth: 1)
                    )
            }
            .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: 10)
    }
}

fileprivate struct TLTRPanelHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(TLTRColors.muted)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(TLTRColors.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

fileprivate struct TLTRDestinationMenu: View {
    @Binding var selection: TLTRDestination

    var body: some View {
        Menu {
            ForEach(TLTRDestination.allCases, id: \.self) { d in
                Button {
                    selection = d
                } label: {
                    Label(d.title, systemImage: d == selection ? "checkmark" : "circle")
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(selection.title)
                    .font(.headline)
                    .foregroundStyle(TLTRPalette.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTRColors.muted)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .contentShape(Rectangle())
    }
}

fileprivate struct TLTRFieldCard<Content: View>: View {
    let title: String
    let icon: String
    private let content: () -> Content

    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(TLTRPalette.orange)

                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.0)
                    .foregroundStyle(TLTRColors.muted)
            }

            content()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

fileprivate struct TLTRToggleRow: View {
    let title: String
    let subtitleOn: String
    let subtitleOff: String
    let iconOn: String
    let iconOff: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.62))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )

                Image(systemName: isOn ? iconOn : iconOff)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isOn ? TLTRPalette.cyan : TLTRColors.muted)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TLTRColors.primary)

                Text(isOn ? subtitleOn : subtitleOff)
                    .font(.subheadline)
                    .foregroundStyle(TLTRColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(TLTRPalette.orange)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

fileprivate struct TLTRSliderRow: View {
    let title: String
    let icon: String
    let valueText: String
    let range: ClosedRange<Double>
    let step: Double
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(TLTRPalette.purple)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(TLTRColors.primary)

                Spacer()

                Text(valueText)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(TLTRColors.muted)
            }

            Slider(value: $value, in: range, step: step)
                .tint(TLTRPalette.orange)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

fileprivate struct TLTRBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.0)
                .foregroundStyle(TLTRColors.muted)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTRColors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

fileprivate struct TLTRLogRow: View {
    let entry: TLTRLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [TLTRPalette.orange, TLTRPalette.purple], startPoint: .top, endPoint: .bottom))
                .frame(width: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTRColors.primary)
                    .lineLimit(2)

                Text("\(entry.destination) • \(entry.mode) • \(entry.outcome)")
                    .font(.caption)
                    .foregroundStyle(TLTRColors.secondary)
            }

            Spacer()

            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(TLTRColors.muted)
                .monospacedDigit()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

fileprivate struct TLTRStatusLight: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? Color.green.opacity(0.85) : Color.white.opacity(0.25))
            .frame(width: 10, height: 10)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: isOn ? Color.green.opacity(0.35) : .clear, radius: 8)
    }
}

fileprivate struct TLTRLcarsPips: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(TLTRPalette.orange)
                .frame(height: 22)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(TLTRPalette.purple)
                .frame(height: 18)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(TLTRPalette.cyan)
                .frame(height: 14)
        }
        .opacity(0.95)
    }
}

fileprivate struct TLTRPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.black.opacity(0.92))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [TLTRPalette.orange, TLTRPalette.sand],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.10 : 0.18), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.18 : 0.33), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Background

fileprivate struct TLTRNebulaWash: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.16),
                Color.blue.opacity(0.10),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.screen)
    }
}

fileprivate struct TLTRStarfieldBackground: View {
    fileprivate struct Star {
        let x: CGFloat
        let y: CGFloat
        let r: CGFloat
        let a: CGFloat
        let v: CGFloat
    }

    private let stars: [Star] = {
        var rng = TLTRSeededRNG(seed: 0xBADC0FFEE)
        func fr(_ m: UInt64) -> CGFloat { CGFloat(rng.next() % m) / CGFloat(m) }

        var arr: [Star] = []
        for _ in 0..<140 {
            let x = fr(10_000)
            let y = fr(10_000)
            let r = 0.6 + fr(1_000) * 1.4
            let a = 0.08 + fr(10_000) * 0.34
            let v = 0.006 + fr(10_000) * 0.018
            arr.append(.init(x: x, y: y, r: r, a: a, v: v))
        }
        return arr
    }()

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                for s in stars {
                    let yy = CGFloat((Double(s.y) + t * Double(s.v)).truncatingRemainder(dividingBy: 1.0))
                    let pt = CGPoint(x: s.x * size.width, y: yy * size.height)

                    var p = Path()
                    p.addEllipse(in: CGRect(x: pt.x - s.r, y: pt.y - s.r, width: s.r * 2, height: s.r * 2))
                    context.fill(p, with: .color(.white.opacity(s.a)))
                }
            }
        }
    }
}

// MARK: - Transporter Visuals

fileprivate struct TLTRPadRings: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            Circle().inset(by: 10).strokeBorder(Color.white.opacity(0.16), lineWidth: 1)

            Circle()
                .inset(by: 22)
                .strokeBorder(Color.white.opacity(isActive ? 0.28 : 0.16), lineWidth: isActive ? 2 : 1)
                .shadow(color: isActive ? TLTRPalette.orange.opacity(0.28) : .clear, radius: 10)

            Circle().inset(by: 36).fill(Color.black.opacity(0.42))
        }
        .background(
            Circle()
                .fill(Color.black.opacity(0.62))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        )
    }
}

fileprivate struct TLTRBeamEffect: View {
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat(t.truncatingRemainder(dividingBy: 1.0))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.00),
                                    .white.opacity(0.14),
                                    .white.opacity(0.06),
                                    .white.opacity(0.18),
                                    .white.opacity(0.00)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            LinearGradient(
                                colors: [.clear, TLTRPalette.orange.opacity(0.22), .clear],
                                startPoint: UnitPoint(x: 0.5, y: max(0, phase - 0.25)),
                                endPoint: UnitPoint(x: 0.5, y: min(1, phase + 0.25))
                            )
                            .blendMode(.screen)
                        )
                        .overlay(
                            TLTRBeamParticles(phase: phase, time: t)
                                .blendMode(.plusLighter)
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

fileprivate struct TLTRBeamParticles: View {
    let phase: CGFloat
    let time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            Canvas { context, _ in
                for i in 0..<12 {
                    let fx = CGFloat((sin(time * 2.0 + Double(i) * 1.7) + 1) * 0.5)
                    let fy = CGFloat((Double(phase) + Double(i) * 0.085).truncatingRemainder(dividingBy: 1.0))
                    let pt = CGPoint(x: fx * w, y: fy * h)
                    let r: CGFloat = 1.1 + CGFloat(i % 3)

                    var p = Path()
                    p.addEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
                    context.fill(p, with: .color(.white.opacity(0.14)))
                }
            }
        }
    }
}

// MARK: - Seeded RNG

fileprivate struct TLTRSeededRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x1234_5678_9ABC_DEF0 : seed }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TLTransporterRoomShiftView()
    }
}
