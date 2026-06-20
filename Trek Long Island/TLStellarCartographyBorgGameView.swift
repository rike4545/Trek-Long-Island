// Copyright Bryan Carroll. All rights reserved.

import SwiftUI

@MainActor
struct TLStellarCartographyBorgGameView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gridSize = 6
    private let totalRounds = 4
    private let scansPerRound = 7

    @State private var cubeSector = StellarSector.random(in: 6)
    @State private var scanned: [StellarSector: BorgReading] = [:]
    @State private var round = 1
    @State private var score = 0
    @State private var scansRemaining = 7
    @State private var assimilation = 18
    @State private var phase: StellarPhase = .briefing
    @State private var statusText = "Stellar Cartography standing by. Borg transwarp wake detected near the outer sectors."

    var body: some View {
        ZStack {
            StellarPalette.background(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerPanel
                    cartographyMap
                    readoutPanel
                    controlsPanel
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .navigationTitle("Stellar Cartography")
        .navigationBarTitleDisplayMode(.inline)
        .tint(StellarPalette.cyan)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetGame(startImmediately: phase == .scanning)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Reset Stellar Cartography")
            }
        }
    }

    private var headerPanel: some View {
        StellarPanel(fill: StellarPalette.shell) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(StellarPalette.cyan.opacity(0.16))
                            .frame(width: 52, height: 52)

                        Image(systemName: "sparkles")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(StellarPalette.cyan)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("STELLAR CARTOGRAPHY")
                            .font(.caption.weight(.bold))
                            .tracking(1.6)
                            .foregroundStyle(StellarPalette.textDim)

                        Text("Borg Signal Intercept")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(StellarPalette.textBright)

                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(StellarPalette.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        statusBadge("ROUND", value: "\(round)/\(totalRounds)", color: StellarPalette.gold)
                        statusBadge("SCANS", value: "\(scansRemaining)", color: StellarPalette.cyan)
                        statusBadge("SCORE", value: "\(score)", color: StellarPalette.mint)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            statusBadge("ROUND", value: "\(round)/\(totalRounds)", color: StellarPalette.gold)
                            statusBadge("SCANS", value: "\(scansRemaining)", color: StellarPalette.cyan)
                        }
                        statusBadge("SCORE", value: "\(score)", color: StellarPalette.mint)
                    }
                }

                assimilationMeter
            }
        }
    }

    private var cartographyMap: some View {
        StellarPanel(fill: StellarPalette.panel) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sector Grid")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(StellarPalette.textBright)

                        Text("Scan sectors to isolate the Borg cube before assimilation reaches critical mass.")
                            .font(.footnote)
                            .foregroundStyle(StellarPalette.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: phase == .complete ? "checkmark.seal.fill" : "scope")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(phase == .complete ? StellarPalette.mint : StellarPalette.gold)
                        .accessibilityHidden(true)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(StellarPalette.screen)
                    StellarGridShape(gridSize: gridSize)
                        .stroke(StellarPalette.grid.opacity(0.55), lineWidth: 0.8)
                    starfield
                        .opacity(scheme == .dark ? 0.85 : 0.55)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize),
                        spacing: 8
                    ) {
                        ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                            let sector = StellarSector(index: index, gridSize: gridSize)
                            sectorButton(sector)
                        }
                    }
                    .padding(12)
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(StellarPalette.stroke, lineWidth: 1)
                )
            }
        }
    }

    private var readoutPanel: some View {
        StellarPanel(fill: StellarPalette.panelSecondary) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sensor Readout")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StellarPalette.textBright)

                HStack(spacing: 10) {
                    readoutCell("Nearest", value: bestReading?.label ?? "--", color: bestReading?.color ?? StellarPalette.textDim)
                    readoutCell("Assimilation", value: "\(assimilation)%", color: assimilationColor)
                    readoutCell("Status", value: phase.shortLabel, color: phase.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(BorgReading.legend, id: \.self) { reading in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(reading.color)
                                .frame(width: 18, height: 10)
                            Text(reading.legendLabel)
                                .font(.caption)
                                .foregroundStyle(StellarPalette.textMuted)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Reading legend")
            }
        }
    }

    private var controlsPanel: some View {
        StellarPanel(fill: StellarPalette.shell) {
            VStack(spacing: 12) {
                if phase == .briefing {
                    Button {
                        beginScan()
                    } label: {
                        commandButtonLabel("Begin Tachyon Sweep", systemImage: "antenna.radiowaves.left.and.right", prominent: true)
                    }
                    .buttonStyle(.plain)
                } else if phase == .scanning {
                    Text("Select a sector on the map.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StellarPalette.textBright)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if phase == .roundComplete {
                    Button {
                        nextRound()
                    } label: {
                        commandButtonLabel(round >= totalRounds ? "Finish Simulation" : "Next Stellar Sweep", systemImage: "arrow.right.circle.fill", prominent: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        resetGame(startImmediately: true)
                    } label: {
                        commandButtonLabel("Run Another Simulation", systemImage: "play.circle.fill", prominent: true)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    resetGame(startImmediately: false)
                } label: {
                    commandButtonLabel("Reset Console", systemImage: "arrow.counterclockwise", prominent: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var starfield: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<36, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 7) ? StellarPalette.mint : StellarPalette.cyan)
                        .frame(width: CGFloat((index % 3) + 2), height: CGFloat((index % 3) + 2))
                        .position(
                            x: CGFloat((index * 37) % 100) / 100 * size,
                            y: CGFloat((index * 61 + 13) % 100) / 100 * size
                        )
                }

                if phase == .scanning && !reduceMotion {
                    Circle()
                        .stroke(StellarPalette.cyan.opacity(0.26), lineWidth: 2)
                        .frame(width: size * 0.72, height: size * 0.72)
                        .position(x: size * 0.5, y: size * 0.5)
                        .transition(.opacity)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var assimilationMeter: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Assimilation Risk")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(StellarPalette.textDim)
                Spacer()
                Text("\(assimilation)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(assimilationColor)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(StellarPalette.console)
                    Capsule()
                        .fill(assimilationColor)
                        .frame(width: proxy.size.width * CGFloat(assimilation) / 100)
                }
            }
            .frame(height: 10)
            .accessibilityLabel("Assimilation risk \(assimilation) percent")
        }
    }

    private var bestReading: BorgReading? {
        scanned.values.sorted { $0.rank > $1.rank }.first
    }

    private var assimilationColor: Color {
        if assimilation >= 80 {
            return differentiateWithoutColor ? StellarPalette.gold : StellarPalette.red
        }
        if assimilation >= 55 {
            return StellarPalette.gold
        }
        return StellarPalette.mint
    }

    private func sectorButton(_ sector: StellarSector) -> some View {
        let reading = scanned[sector]
        let isDisabled = phase != .scanning || reading != nil
        let isExact = reading == .cube

        return Button {
            scan(sector)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((reading?.background ?? StellarPalette.sector).opacity(isDisabled && reading == nil ? 0.5 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(reading?.color ?? StellarPalette.grid, lineWidth: isExact ? 2 : 1)
                    )

                VStack(spacing: 4) {
                    Image(systemName: reading?.icon ?? "circle.grid.cross")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(reading?.color ?? StellarPalette.textDim)

                    Text(sector.code)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(StellarPalette.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel(for: sector, reading: reading))
    }

    private func statusBadge(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(StellarPalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 82, alignment: .leading)
        .background(StellarPalette.console, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(StellarPalette.stroke, lineWidth: 1)
        )
    }

    private func readoutCell(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(StellarPalette.textDim)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StellarPalette.console, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(StellarPalette.stroke, lineWidth: 1)
        )
    }

    private func commandButtonLabel(_ title: String, systemImage: String, prominent: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
            Text(title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
        }
        .foregroundStyle(prominent ? .black.opacity(0.84) : StellarPalette.textBright)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(
            prominent ? StellarPalette.gold : StellarPalette.console,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(prominent ? StellarPalette.gold.opacity(0.5) : StellarPalette.stroke, lineWidth: 1)
        )
    }

    private func beginScan() {
        phase = .scanning
        statusText = "Tachyon sweep active. Locate the Borg cube before the grid is assimilated."
    }

    private func scan(_ sector: StellarSector) {
        guard phase == .scanning, scanned[sector] == nil else { return }

        let reading = BorgReading(distance: sector.distance(to: cubeSector))
        scanned[sector] = reading
        scansRemaining -= 1
        assimilation = min(100, assimilation + reading.assimilationGain)

        if reading == .cube {
            let roundBonus = max(10, scansRemaining * 8)
            score += 75 + roundBonus
            phase = .roundComplete
            statusText = "Borg cube isolated in sector \(sector.code). Transwarp conduit collapsed."
            return
        }

        if scansRemaining <= 0 || assimilation >= 100 {
            phase = .roundComplete
            statusText = "Borg cube evaded the sweep. Stellar map recovered partial telemetry from sector \(cubeSector.code)."
            scanned[cubeSector] = .cube
            assimilation = min(100, assimilation + 12)
            return
        }

        statusText = reading.statusLine(for: sector)
    }

    private func nextRound() {
        if round >= totalRounds {
            phase = .complete
            statusText = score >= 260
                ? "Simulation complete. Stellar Cartography recommends you for anti-assimilation duty."
                : "Simulation complete. Borg signatures logged for remedial tactical review."
            return
        }

        round += 1
        startRound()
    }

    private func resetGame(startImmediately: Bool) {
        round = 1
        score = 0
        assimilation = 18
        startRound()
        if startImmediately {
            beginScan()
        } else {
            phase = .briefing
            statusText = "Stellar Cartography standing by. Borg transwarp wake detected near the outer sectors."
        }
    }

    private func startRound() {
        cubeSector = StellarSector.random(in: gridSize)
        scanned = [:]
        scansRemaining = scansPerRound
        phase = .scanning
        assimilation = min(82, max(12, assimilation - 16))
        statusText = "New transwarp echo detected. Recalibrate the stellar grid and begin sector isolation."
    }

    private func accessibilityLabel(for sector: StellarSector, reading: BorgReading?) -> String {
        if let reading {
            return "Sector \(sector.code), \(reading.legendLabel)"
        }
        return "Unscanned sector \(sector.code)"
    }
}

private struct StellarPanel<Content: View>: View {
    let fill: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(StellarPalette.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 10, y: 6)
    }
}

private struct StellarGridShape: Shape {
    let gridSize: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard gridSize > 1 else { return path }

        for index in 1..<gridSize {
            let ratio = CGFloat(index) / CGFloat(gridSize)
            let x = rect.minX + rect.width * ratio
            let y = rect.minY + rect.height * ratio
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private struct StellarSector: Hashable {
    let row: Int
    let column: Int

    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    init(index: Int, gridSize: Int) {
        self.row = index / gridSize
        self.column = index % gridSize
    }

    static func random(in gridSize: Int) -> StellarSector {
        StellarSector(
            row: Int.random(in: 0..<gridSize),
            column: Int.random(in: 0..<gridSize)
        )
    }

    var code: String {
        "\(Character(UnicodeScalar(65 + column)!))\(row + 1)"
    }

    func distance(to other: StellarSector) -> Int {
        abs(row - other.row) + abs(column - other.column)
    }
}

private enum StellarPhase {
    case briefing
    case scanning
    case roundComplete
    case complete

    var shortLabel: String {
        switch self {
        case .briefing: return "Standby"
        case .scanning: return "Scanning"
        case .roundComplete: return "Locked"
        case .complete: return "Complete"
        }
    }

    var accent: Color {
        switch self {
        case .briefing: return StellarPalette.gold
        case .scanning: return StellarPalette.cyan
        case .roundComplete: return StellarPalette.mint
        case .complete: return StellarPalette.gold
        }
    }
}

private enum BorgReading: Hashable {
    case cube
    case strong
    case moderate
    case trace
    case clear

    init(distance: Int) {
        switch distance {
        case 0: self = .cube
        case 1: self = .strong
        case 2: self = .moderate
        case 3: self = .trace
        default: self = .clear
        }
    }

    static let legend: [BorgReading] = [.cube, .strong, .moderate, .trace, .clear]

    var rank: Int {
        switch self {
        case .cube: return 5
        case .strong: return 4
        case .moderate: return 3
        case .trace: return 2
        case .clear: return 1
        }
    }

    var label: String {
        switch self {
        case .cube: return "Cube"
        case .strong: return "Strong"
        case .moderate: return "Moderate"
        case .trace: return "Trace"
        case .clear: return "Clear"
        }
    }

    var legendLabel: String {
        switch self {
        case .cube: return "Borg cube located"
        case .strong: return "Strong transwarp wake"
        case .moderate: return "Moderate subspace distortion"
        case .trace: return "Trace chroniton residue"
        case .clear: return "No collective signal"
        }
    }

    var icon: String {
        switch self {
        case .cube: return "cube.fill"
        case .strong: return "wave.3.right"
        case .moderate: return "wave.2.right"
        case .trace: return "wave.1.right"
        case .clear: return "checkmark"
        }
    }

    var color: Color {
        switch self {
        case .cube: return StellarPalette.red
        case .strong: return StellarPalette.gold
        case .moderate: return StellarPalette.cyan
        case .trace: return StellarPalette.mint
        case .clear: return StellarPalette.textDim
        }
    }

    var background: Color {
        switch self {
        case .cube: return StellarPalette.red.opacity(0.22)
        case .strong: return StellarPalette.gold.opacity(0.18)
        case .moderate: return StellarPalette.cyan.opacity(0.16)
        case .trace: return StellarPalette.mint.opacity(0.15)
        case .clear: return StellarPalette.console
        }
    }

    var assimilationGain: Int {
        switch self {
        case .cube: return 0
        case .strong: return 14
        case .moderate: return 10
        case .trace: return 7
        case .clear: return 5
        }
    }

    func statusLine(for sector: StellarSector) -> String {
        switch self {
        case .cube:
            return "Borg cube isolated in sector \(sector.code)."
        case .strong:
            return "Sector \(sector.code): strong transwarp wake. The cube is adjacent."
        case .moderate:
            return "Sector \(sector.code): moderate distortion. Narrow the search nearby."
        case .trace:
            return "Sector \(sector.code): trace residue. The cube is still at range."
        case .clear:
            return "Sector \(sector.code): no collective signal. Replot the sweep."
        }
    }
}

private enum StellarPalette {
    static let shell = Color(red: 0.08, green: 0.12, blue: 0.20)
    static let panel = Color(red: 0.10, green: 0.17, blue: 0.25)
    static let panelSecondary = Color(red: 0.08, green: 0.15, blue: 0.18)
    static let console = Color(red: 0.04, green: 0.08, blue: 0.12)
    static let screen = Color(red: 0.02, green: 0.05, blue: 0.08)
    static let sector = Color(red: 0.07, green: 0.13, blue: 0.18)
    static let stroke = Color.white.opacity(0.18)
    static let grid = Color(red: 0.28, green: 0.84, blue: 0.92)
    static let cyan = Color(red: 0.36, green: 0.88, blue: 0.96)
    static let mint = Color(red: 0.56, green: 0.94, blue: 0.64)
    static let gold = Color(red: 1.00, green: 0.75, blue: 0.28)
    static let red = Color(red: 1.00, green: 0.32, blue: 0.30)
    static let textBright = Color.white.opacity(0.94)
    static let textMuted = Color.white.opacity(0.72)
    static let textDim = Color.white.opacity(0.50)

    static func background(_ scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: scheme == .dark
                ? [Color.black, Color(red: 0.03, green: 0.07, blue: 0.12), Color(red: 0.02, green: 0.09, blue: 0.08)]
                : [Color(red: 0.83, green: 0.92, blue: 0.96), Color(red: 0.68, green: 0.80, blue: 0.88), Color(red: 0.50, green: 0.70, blue: 0.76)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    NavigationStack {
        TLStellarCartographyBorgGameView()
    }
}
