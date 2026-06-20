// Copyright Bryan Carroll. All rights reserved.

import SwiftUI

struct BluetoothSignalSweepScope: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    let devices: [BluetoothTricorderDevice]
    let isScanning: Bool
    let estimatedPeople: Int
    let signalCount: Int

    private var strongestLevel: BluetoothSignalLevel? {
        devices.first?.signalLevel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Signal Sweep")
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text(isScanning ? "Active BLE scan" : "Sweep standing by")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isScanning ? TLITheme.accent(scheme) : TLITheme.textSecondary(scheme))
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(estimatedPeople)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text("room est.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            sweepFace
                .frame(height: 218)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                sweepMetric("Signals", "\(devices.count)", "sensor.tag.radiowaves.forward.fill")
                sweepMetric("Used", "\(signalCount)", "person.wave.2.fill")
                sweepMetric("Strongest", strongestLevel?.rawValue ?? "n/a", strongestLevel?.symbolName ?? "wave.3.right")
            }
        }
        .padding(14)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var sweepFace: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 24)) { timeline in
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                let radius = max(0, size / 2 - 12)
                let sweepAngle = reduceMotion
                    ? Angle.degrees(-45)
                    : Angle.degrees(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.2) / 3.2 * 360 - 90)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(scheme == .dark ? 0.50 : 0.20),
                                    TLITheme.accent(scheme).opacity(scheme == .dark ? 0.10 : 0.07)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    ForEach(1...4, id: \.self) { ring in
                        Circle()
                            .stroke(TLITheme.border(scheme).opacity(0.65), lineWidth: 1)
                            .frame(width: radius * 2 * CGFloat(ring) / 4, height: radius * 2 * CGFloat(ring) / 4)
                            .position(center)
                    }

                    Path { path in
                        path.move(to: CGPoint(x: center.x - radius, y: center.y))
                        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                        path.move(to: CGPoint(x: center.x, y: center.y - radius))
                        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    }
                    .stroke(TLITheme.border(scheme).opacity(0.45), lineWidth: 1)

                    if isScanning {
                        SweepWedge(startAngle: sweepAngle - .degrees(34), endAngle: sweepAngle + .degrees(2))
                            .fill(
                                AngularGradient(
                                    colors: [
                                        TLITheme.accent(scheme).opacity(0.02),
                                        TLITheme.accent(scheme).opacity(0.30),
                                        TLITheme.accent(scheme).opacity(0.04)
                                    ],
                                    center: .center
                                )
                            )
                            .frame(width: radius * 2, height: radius * 2)
                            .position(center)

                        sweepLine(center: center, radius: radius, angle: sweepAngle)
                            .stroke(TLITheme.accent(scheme).opacity(0.80), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }

                    ForEach(Array(devices.prefix(18).enumerated()), id: \.element.id) { index, device in
                        signalDot(device, index: index, radius: radius, center: center)
                    }

                    VStack(spacing: 3) {
                        Image(systemName: isScanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(TLITheme.accent(scheme))
                        Text(isScanning ? "SCANNING" : "READY")
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }

    private func sweepLine(center: CGPoint, radius: CGFloat, angle: Angle) -> Path {
        var path = Path()
        let radians = angle.radians
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + cos(radians) * radius, y: center.y + sin(radians) * radius))
        return path
    }

    private func signalDot(_ device: BluetoothTricorderDevice, index: Int, radius: CGFloat, center: CGPoint) -> some View {
        let angle = Double(index) * 137.5
        let strengthRadius = radius * radiusRatio(for: device.signalLevel)
        let jitter = CGFloat((abs(device.id.hashValue) % 100)) / 100
        let adjustedRadius = max(18, strengthRadius - (jitter * 18))
        let radians = Angle.degrees(angle).radians
        let point = CGPoint(
            x: center.x + cos(radians) * adjustedRadius,
            y: center.y + sin(radians) * adjustedRadius
        )

        return Circle()
            .fill(color(for: device.signalLevel))
            .frame(width: dotSize(for: device.signalLevel), height: dotSize(for: device.signalLevel))
            .overlay(Circle().stroke(Color.white.opacity(0.42), lineWidth: 1))
            .shadow(color: color(for: device.signalLevel).opacity(0.55), radius: 6)
            .position(point)
    }

    private func sweepMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.chipBackground(scheme), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var accessibilitySummary: String {
        if isScanning {
            return "Bluetooth signal sweep scanning. \(devices.count) signals detected. Estimated room count \(estimatedPeople)."
        }
        return "Bluetooth signal sweep ready. \(devices.count) signals detected from the last scan. Estimated room count \(estimatedPeople)."
    }

    private func radiusRatio(for level: BluetoothSignalLevel) -> CGFloat {
        switch level {
        case .strong: return 0.28
        case .moderate: return 0.48
        case .faint: return 0.68
        case .trace: return 0.86
        }
    }

    private func dotSize(for level: BluetoothSignalLevel) -> CGFloat {
        switch level {
        case .strong: return 13
        case .moderate: return 11
        case .faint: return 9
        case .trace: return 7
        }
    }

    private func color(for level: BluetoothSignalLevel) -> Color {
        switch level {
        case .strong: return .green
        case .moderate: return TLITheme.accent(scheme)
        case .faint: return .orange
        case .trace: return TLITheme.textTertiary(scheme)
        }
    }
}

private struct SweepWedge: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
