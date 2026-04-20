// Copyright Bryan Carroll. All rights reserved.
//
//  TLICardModifier.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct TLIPanelSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var accessibilityContrast

    let cornerRadius: CGFloat
    let fillOpacity: Double
    let borderOpacity: Double
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    func body(content: Content) -> some View {
        let shape = TLITheme.panelShape(cornerRadius: cornerRadius)
        let decorationOpacity = RisaTheme.isLCARSThemeEnabled ? 0.34 : 0.55
        let effectiveBorderOpacity = accessibilityContrast == .increased ? max(borderOpacity, 0.98) : borderOpacity
        let panelFill = (RisaTheme.isLCARSThemeEnabled ? TLITheme.cardBackground(scheme) : Color.clear)
            .opacity(reduceTransparency ? 1.0 : 1.0)
        let lcarsFill = AnyShapeStyle(
            TLITheme.lcarsPanelFill(scheme).opacity(reduceTransparency ? min(1.0, fillOpacity + 0.1) : fillOpacity)
        )

        content
            .background(
                shape
                    .fill(panelFill)
                    .overlay(
                        shape
                            .fill(lcarsFill)
                    )
                    .overlay(shape.fill(TLITheme.cardGloss(scheme)))
                    .overlay(
                        TLITheme.panelDecoration(scheme)
                            .opacity(reduceTransparency ? decorationOpacity * 0.35 : decorationOpacity)
                            .clipShape(shape)
                    )
            )
            .overlay(
                shape
                    .stroke(TLITheme.border(scheme).opacity(effectiveBorderOpacity), lineWidth: accessibilityContrast == .increased ? 1.4 : 0.95)
            )
            .shadow(
                color: TLITheme.cardShadowColor(scheme),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

@MainActor
struct TLICardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .modifier(
                TLIPanelSurfaceModifier(
                    cornerRadius: 20,
                    fillOpacity: 1,
                    borderOpacity: 0.92,
                    shadowRadius: 14,
                    shadowY: 8
                )
            )
    }
}

extension View {
    /// Risa/TLI glass card wrapper used across the app.
    func tliCard() -> some View {
        self.modifier(TLICardModifier())
    }

    func tliPanelSurface(
        cornerRadius: CGFloat = 20,
        fillOpacity: Double = 1,
        borderOpacity: Double = 0.8,
        shadowRadius: CGFloat = 8,
        shadowY: CGFloat = 4
    ) -> some View {
        self.modifier(
            TLIPanelSurfaceModifier(
                cornerRadius: cornerRadius,
                fillOpacity: fillOpacity,
                borderOpacity: borderOpacity,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }

    @ViewBuilder
    func tliLCARSPanelChrome(
        accent: Color,
        metadata: String? = nil,
        contentTopInset: CGFloat = 0
    ) -> some View {
        if RisaTheme.isLCARSThemeEnabled {
            self
            .padding(.top, contentTopInset)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Capsule(style: .continuous)
                            .fill(accent)
                            .frame(width: 42, height: 8)
                        Capsule(style: .continuous)
                            .fill(RisaTheme.accentSecondary(.dark))
                            .frame(width: 18, height: 8)
                        Capsule(style: .continuous)
                            .fill(RisaTheme.accentGold(.dark))
                            .frame(width: 28, height: 8)
                    }

                    if let metadata {
                        Text(metadata.uppercased())
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundStyle(RisaTheme.textSecondary(.dark))
                    }
                }
                .padding(.top, 10)
                .padding(.leading, 12)
            }
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent, RisaTheme.textTertiary(.dark), RisaTheme.accentSecondary(.dark)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8)
                    .padding(.vertical, 12)
                    .padding(.leading, 6)
                    .opacity(0.92)
            }
        } else {
            self
        }
    }
}
