import SwiftUI

struct LCARSReactiveSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    let accent: Color
    let cornerRadius: CGFloat
    let emphasis: Bool
    let idleSweepDuration: Double

    func body(content: Content) -> some View {
        if RisaTheme.isLCARSThemeEnabled {
            content
                .overlay {
                    LCARSReactiveOverlay(
                        accent: accent,
                        cornerRadius: cornerRadius,
                        emphasis: emphasis,
                        idleSweepDuration: idleSweepDuration
                    )
                }
                .shadow(
                    color: accent.opacity(emphasis ? (scheme == .dark ? 0.22 : 0.12) : (scheme == .dark ? 0.12 : 0.06)),
                    radius: emphasis ? 10 : 4,
                    x: 0,
                    y: emphasis ? 2 : 1
                )
        } else {
            content
        }
    }
}

private struct LCARSReactiveOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("TLI.Accessibility.reduceAnimations") private var reduceAnimations = false

    let accent: Color
    let cornerRadius: CGFloat
    let emphasis: Bool
    let idleSweepDuration: Double

    var body: some View {
        if reduceMotion || reduceAnimations || !emphasis {
            overlay(phase: 0.42, showsSweep: false)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate
                let duration = max(idleSweepDuration, 0.8)
                overlay(phase: seconds.truncatingRemainder(dividingBy: duration) / duration, showsSweep: true)
            }
        }
    }

    private func overlay(phase: Double, showsSweep: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return GeometryReader { proxy in
            let size = proxy.size
            let width = max(size.width, 1)
            let bandWidth = max(44, width * 0.28)
            let travel = width + (bandWidth * 2)
            let xOffset = (travel * phase) - bandWidth

            ZStack {
                shape
                    .stroke(
                        accent.opacity(emphasis ? 0.42 : 0.18),
                        lineWidth: emphasis ? 1.15 : 0.7
                    )

                if showsSweep {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    accent.opacity(0.08),
                                    .white.opacity(0.18),
                                    accent.opacity(0.10),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: bandWidth)
                        .offset(x: xOffset - (width / 2))
                        .blur(radius: 6)
                }

                VStack(spacing: 7) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(accent.opacity(emphasis ? 0.020 : 0.010))
                            .frame(height: 1)
                    }
                }
                .padding(.vertical, 10)
                .blendMode(.screen)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
        }
        .allowsHitTesting(false)
    }
}

struct LCARSInteractiveButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @AppStorage("TLI.Accessibility.reduceAnimations") private var reduceAnimations = false

    let accent: Color
    let cornerRadius: CGFloat
    let idleEmphasis: Bool
    let pressedScale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let isActive = configuration.isPressed || idleEmphasis

        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .modifier(
                LCARSReactiveSurfaceModifier(
                    accent: accent,
                    cornerRadius: cornerRadius,
                    emphasis: isActive,
                    idleSweepDuration: configuration.isPressed ? 1.2 : 2.8
                )
            )
            .brightness(configuration.isPressed ? 0.06 : 0.0)
            .saturation(configuration.isPressed ? 1.04 : 1.0)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(
                showButtonShapes || reduceMotion || reduceAnimations ? nil : .spring(response: 0.24, dampingFraction: 0.78),
                value: configuration.isPressed
            )
    }
}

extension View {
    func lcarsReactiveSurface(
        accent: Color,
        cornerRadius: CGFloat,
        emphasis: Bool = false,
        idleSweepDuration: Double = 3.4
    ) -> some View {
        modifier(
            LCARSReactiveSurfaceModifier(
                accent: accent,
                cornerRadius: cornerRadius,
                emphasis: emphasis,
                idleSweepDuration: idleSweepDuration
            )
        )
    }
}
