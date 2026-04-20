import SwiftUI

struct TLIAccessibleSurfaceModifier<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var accessibilityContrast

    let shape: S
    let baseFill: Color
    let accentWash: Color
    let strokeColor: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    func body(content: Content) -> some View {
        let effectiveFill = reduceTransparency
            ? baseFill.opacity(accessibilityContrast == .increased ? 1.0 : 0.96)
            : baseFill
        let effectiveAccentWash = reduceTransparency
            ? accentWash.opacity(accessibilityContrast == .increased ? 0.22 : 0.12)
            : accentWash
        let lineWidth: CGFloat = accessibilityContrast == .increased ? 1.5 : 0.9

        return content
            .background(
                shape
                    .fill(effectiveFill)
                    .overlay(shape.fill(effectiveAccentWash))
            )
            .overlay(
                shape.stroke(strokeColor.opacity(accessibilityContrast == .increased ? 0.65 : 1.0), lineWidth: lineWidth)
            )
            .shadow(
                color: shadowColor.opacity(accessibilityContrast == .increased ? 0.9 : 0.75),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

struct TLIButtonShapeModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @Environment(\.colorSchemeContrast) private var accessibilityContrast

    let shape: S
    let strokeColor: Color

    func body(content: Content) -> some View {
        if showButtonShapes {
            content.overlay(
                shape.stroke(
                    strokeColor.opacity(accessibilityContrast == .increased ? 0.95 : 0.7),
                    lineWidth: accessibilityContrast == .increased ? 2 : 1.2
                )
            )
        } else {
            content
        }
    }
}

extension View {
    func tliAccessibleSurface<S: Shape>(
        shape: S,
        baseFill: Color,
        accentWash: Color = .clear,
        strokeColor: Color,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowY: CGFloat
    ) -> some View {
        modifier(
            TLIAccessibleSurfaceModifier(
                shape: shape,
                baseFill: baseFill,
                accentWash: accentWash,
                strokeColor: strokeColor,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }

    func tliButtonShapeOutline<S: Shape>(
        shape: S,
        strokeColor: Color
    ) -> some View {
        modifier(TLIButtonShapeModifier(shape: shape, strokeColor: strokeColor))
    }
}
