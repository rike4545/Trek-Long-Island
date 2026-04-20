// Copyright Bryan Carroll. All rights reserved.
//
//  TLILayout.swift
//  Trek Long Island
//
//  Created by Bryan on 11/27/25.
//


//
//  TLILayout.swift
//  Trek Long Island
//
//  Shared layout helpers for Trek Long Island.
//  • Quick link grid columns (iPhone vs iPad)
//  • Adaptive content width for regular-width (iPad) while staying full-bleed on iPhone
//  • Simple utilities you can reuse in other views
//

import SwiftUI

// MARK: - TLILayout namespace

enum TLILayout {
    /// Default max width for primary content columns on regular-width devices.
    /// Use a finite width to avoid oversized layout expansion on regular width.
    static let defaultContentMaxWidth: CGFloat = 980

    /// Slightly tighter width for sheets / detail panels, if needed.
    static let tightContentMaxWidth: CGFloat = 720

    // MARK: - Quick Links Grid

    /// Columns for the Home "Quick Links" grid.
    /// - Compact width (iPhone): 2 columns
    /// - Regular width (iPad): 3 columns
    static func quickLinkColumns(
        for sizeClass: UserInterfaceSizeClass?
    ) -> [GridItem] {
        if sizeClass == .regular {
            return [
                GridItem(.adaptive(minimum: 170, maximum: 280), spacing: 16)
            ]
        } else {
            return [
                GridItem(.adaptive(minimum: 136, maximum: .infinity), spacing: 12)
            ]
        }
    }

    /// Narrow-phone variant for grids that need to survive older iPhones such as SE-sized widths.
    static func quickLinkColumns(
        for sizeClass: UserInterfaceSizeClass?,
        availableWidth: CGFloat
    ) -> [GridItem] {
        if sizeClass == .regular {
            return quickLinkColumns(for: sizeClass)
        }

        let minimum: CGFloat = availableWidth <= 340 ? 124 : 136
        let spacing = availableWidth <= 340 ? 10.0 : 12.0

        return [
            GridItem(.adaptive(minimum: minimum, maximum: .infinity), spacing: spacing)
        ]
    }

    /// Generic helper if you want a grid tuned by minimum tile width.
    static func columns(
        for sizeClass: UserInterfaceSizeClass?,
        minTileWidth: CGFloat = 260,
        spacing: CGFloat = 16
    ) -> [GridItem] {
        adaptiveColumns(
            for: sizeClass,
            compactMinimum: min(minTileWidth, 180),
            regularMinimum: minTileWidth,
            spacing: spacing
        )
    }

    /// Adaptive grid columns that survive split view, fold-like width changes,
    /// and iPad multitasking better than fixed 2-up / 3-up counts.
    static func adaptiveColumns(
        for sizeClass: UserInterfaceSizeClass?,
        compactMinimum: CGFloat = 150,
        regularMinimum: CGFloat = 240,
        regularMaximum: CGFloat = .infinity,
        spacing: CGFloat = 16
    ) -> [GridItem] {
        [
            GridItem(
                .adaptive(
                    minimum: sizeClass == .regular ? regularMinimum : compactMinimum,
                    maximum: sizeClass == .regular ? regularMaximum : .infinity
                ),
                spacing: spacing,
                alignment: .top
            )
        ]
    }

    static func isSmallPhone(width: CGFloat, height: CGFloat) -> Bool {
        width <= 340 || height <= 667
    }

    static func compactHorizontalPadding(for width: CGFloat) -> CGFloat {
        width <= 340 ? 12 : 16
    }

    static func sectionSpacing(for width: CGFloat) -> CGFloat {
        width <= 340 ? 18 : 24
    }
}

// MARK: - Adaptive content width modifier

/// Centers content in a column on regular-width devices while leaving it full-bleed on iPhone.
/// Use this around your main VStack content (e.g. in HomeView, AboutView, SettingsView).
private struct AdaptiveContentWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let maxWidth: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(
                maxWidth: (hSizeClass == .regular && maxWidth.isFinite) ? maxWidth : .infinity,
                alignment: .topLeading
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
    }
}

// MARK: - View extension

extension View {
    /// Centers the view in a column on iPad/regular width while keeping it full-bleed on iPhone.
    ///
    /// Usage:
    /// ```swift
    /// ScrollView {
    ///     contentLayout
    ///         .adaptiveContentWidth() // uses TLILayout.defaultContentMaxWidth
    /// }
    /// ```
    func adaptiveContentWidth(
        maxWidth: CGFloat = TLILayout.defaultContentMaxWidth,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 0
    ) -> some View {
        modifier(
            AdaptiveContentWidthModifier(
                maxWidth: maxWidth,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding
            )
        )
    }
}
