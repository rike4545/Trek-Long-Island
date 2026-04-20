// Copyright Bryan Carroll. All rights reserved.
//
//  RisaSkyBackdrop.swift
//  Trek Long Island
//
//  Animated Risa-inspired backdrop (sunset / breeze / night)
//  Swift 6 • iOS 17+
//

import SwiftUI

struct RisaSkyBackdrop: View {
    let mode: RisaZenMode
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = reduceMotion ? 0.0 : (time.truncatingRemainder(dividingBy: 60) / 60.0)

            GeometryReader { proxy in
                let size = proxy.size

                ZStack {
                    baseGradient(phase: phase)
                        .ignoresSafeArea()

                    horizonGlow(phase: phase, size: size)
                        .blendMode(.screen)
                        .opacity(mode == .nightLanterns ? 0.45 : 0.75)
                        .ignoresSafeArea()

                    cloudLayer(phase: phase, size: size, depth: 1)
                        .opacity(mode == .nightLanterns ? 0.10 : 0.22)

                    cloudLayer(phase: phase, size: size, depth: 2)
                        .opacity(mode == .nightLanterns ? 0.06 : 0.16)

                    if mode == .nightLanterns {
                        starfield(phase: phase, size: size)
                            .opacity(0.35)
                            .ignoresSafeArea()

                        lanterns(phase: phase, size: size)
                            .opacity(0.55)
                            .ignoresSafeArea()
                    }

                    vignette
                        .ignoresSafeArea()
                }
                .drawingGroup()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false) // ✅ CRITICAL: never steal taps from overlay controls
    }

    // MARK: - Layers

    private func baseGradient(phase: Double) -> some View {
        let (top, mid, bottom): (Color, Color, Color) = {
            switch mode {
            case .sunsetCruise:
                return (Color(red: 0.05, green: 0.10, blue: 0.22),
                        Color(red: 0.30, green: 0.12, blue: 0.38),
                        Color(red: 0.95, green: 0.46, blue: 0.24))
            case .oceanBreeze:
                return (Color(red: 0.02, green: 0.18, blue: 0.24),
                        Color(red: 0.08, green: 0.34, blue: 0.32),
                        Color(red: 0.80, green: 0.62, blue: 0.40))
            case .nightLanterns:
                return (Color(red: 0.02, green: 0.03, blue: 0.08),
                        Color(red: 0.06, green: 0.05, blue: 0.16),
                        Color(red: 0.10, green: 0.06, blue: 0.18))
            }
        }()

        let drift = reduceMotion ? 0.0 : (sin(phase * .pi * 2) * 0.03)

        return LinearGradient(
            stops: [
                .init(color: top, location: 0.0),
                .init(color: mid.opacity(0.98), location: 0.55 + drift),
                .init(color: bottom.opacity(mode == .nightLanterns ? 0.65 : 0.95), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func horizonGlow(phase: Double, size: CGSize) -> some View {
        let y = size.height * 0.70
        let x = size.width * (0.50 + (reduceMotion ? 0.0 : sin(phase * .pi * 2) * 0.02))

        let glowColor: Color = {
            switch mode {
            case .sunsetCruise: return Color(red: 1.00, green: 0.56, blue: 0.26)
            case .oceanBreeze: return Color(red: 0.95, green: 0.80, blue: 0.50)
            case .nightLanterns: return Color(red: 0.85, green: 0.55, blue: 0.35)
            }
        }()

        return RadialGradient(
            colors: [
                glowColor.opacity(0.75),
                glowColor.opacity(0.20),
                .clear
            ],
            center: .center,
            startRadius: 10,
            endRadius: max(size.width, size.height) * 0.55
        )
        .frame(width: max(size.width, size.height), height: max(size.width, size.height))
        .position(x: x, y: y)
        .blur(radius: 8)
    }

    private func cloudLayer(phase: Double, size: CGSize, depth: Int) -> some View {
        let speed = reduceMotion ? 0.0 : (depth == 1 ? 0.012 : 0.007)
        let offsetX = size.width * CGFloat(sin((phase * .pi * 2) + Double(depth)) * speed * 20)
        let offsetY = size.height * CGFloat(cos((phase * .pi * 2) + Double(depth)) * speed * 10)

        let hazeColor: Color = (mode == .nightLanterns)
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.12)

        return ZStack {
            SoftBlob()
                .fill(hazeColor)
                .frame(width: size.width * 1.3, height: size.height * 0.55)
                .position(x: size.width * 0.40, y: size.height * 0.22)

            SoftBlob()
                .fill(hazeColor.opacity(0.85))
                .frame(width: size.width * 1.1, height: size.height * 0.48)
                .position(x: size.width * 0.70, y: size.height * 0.32)

            SoftBlob()
                .fill(hazeColor.opacity(0.70))
                .frame(width: size.width * 1.4, height: size.height * 0.60)
                .position(x: size.width * 0.55, y: size.height * 0.44)
        }
        .blur(radius: depth == 1 ? 38 : 52)
        .offset(x: offsetX, y: offsetY)
    }

    private func starfield(phase: Double, size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let count = 120
            let w = canvasSize.width
            let h = canvasSize.height

            for i in 0..<count {
                let fx = fract(sin(Double(i) * 12.9898) * 43758.5453)
                let fy = fract(sin(Double(i) * 78.233) * 12345.6789)

                let x = w * fx
                let y = h * fy * 0.75
                let twinkle = reduceMotion ? 0.0 : (0.35 + 0.65 * abs(sin((phase * .pi * 2) + Double(i) * 0.03)))

                let r = CGFloat(1.0 + (fract(sin(Double(i) * 4.1) * 9999.0) * 1.3))
                let alpha = CGFloat(0.20 + 0.40 * twinkle)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .blur(radius: 0.6)
    }

    private func lanterns(phase: Double, size: CGSize) -> some View {
        let drift = reduceMotion ? 0.0 : sin(phase * .pi * 2) * 10.0

        return ZStack {
            LanternBlob()
                .fill(Color(red: 0.98, green: 0.68, blue: 0.42).opacity(0.45))
                .frame(width: size.width * 0.32, height: size.width * 0.32)
                .position(x: size.width * 0.18, y: size.height * 0.34 + drift)
                .blur(radius: 18)

            LanternBlob()
                .fill(Color(red: 0.90, green: 0.56, blue: 0.40).opacity(0.38))
                .frame(width: size.width * 0.26, height: size.width * 0.26)
                .position(x: size.width * 0.80, y: size.height * 0.28 - drift)
                .blur(radius: 20)

            LanternBlob()
                .fill(Color(red: 0.92, green: 0.60, blue: 0.55).opacity(0.32))
                .frame(width: size.width * 0.22, height: size.width * 0.22)
                .position(x: size.width * 0.54, y: size.height * 0.18 + drift * 0.6)
                .blur(radius: 22)
        }
        .blendMode(.screen)
    }

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.35)],
            center: .center,
            startRadius: 140,
            endRadius: 900
        )
    }

    private func fract(_ x: Double) -> Double { x - floor(x) }
}

private struct SoftBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: rect.minX + 0.05*w, y: rect.minY + 0.60*h))
        p.addCurve(to: CGPoint(x: rect.minX + 0.35*w, y: rect.minY + 0.20*h),
                   control1: CGPoint(x: rect.minX + 0.10*w, y: rect.minY + 0.20*h),
                   control2: CGPoint(x: rect.minX + 0.20*w, y: rect.minY + 0.05*h))
        p.addCurve(to: CGPoint(x: rect.minX + 0.78*w, y: rect.minY + 0.28*h),
                   control1: CGPoint(x: rect.minX + 0.52*w, y: rect.minY + 0.35*h),
                   control2: CGPoint(x: rect.minX + 0.65*w, y: rect.minY + 0.10*h))
        p.addCurve(to: CGPoint(x: rect.minX + 0.98*w, y: rect.minY + 0.72*h),
                   control1: CGPoint(x: rect.minX + 0.92*w, y: rect.minY + 0.45*h),
                   control2: CGPoint(x: rect.minX + 1.05*w, y: rect.minY + 0.60*h))
        p.addCurve(to: CGPoint(x: rect.minX + 0.62*w, y: rect.minY + 0.92*h),
                   control1: CGPoint(x: rect.minX + 0.92*w, y: rect.minY + 1.02*h),
                   control2: CGPoint(x: rect.minX + 0.75*w, y: rect.minY + 0.98*h))
        p.addCurve(to: CGPoint(x: rect.minX + 0.05*w, y: rect.minY + 0.60*h),
                   control1: CGPoint(x: rect.minX + 0.40*w, y: rect.minY + 0.86*h),
                   control2: CGPoint(x: rect.minX + 0.18*w, y: rect.minY + 0.95*h))
        p.closeSubpath()
        return p
    }
}

private struct LanternBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect.insetBy(dx: rect.width * 0.10, dy: rect.height * 0.18))
        return p
    }
}
