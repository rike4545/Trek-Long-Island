// Copyright Bryan Carroll. All rights reserved.
//
//  RisaTheme.swift
//  Trek Long Island
//
//  Modern Trek LI theme + global UI appearance
//  • Dark “space bridge” gradient
//  • Soft, airy light mode with Trek-tinted whites
//  • Asset-aware overrides (TextPrimary, AccentPrimary, etc.)
//  • Nav/Tab bar glass via AppUIAppearance.configure()
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TLIColorTheme: String, CaseIterable, Identifiable {
    case tos
    case tng
    case ds9
    case voyager
    case enterprise
    case starfleet
    case lcars
    case risa

    var id: String { rawValue }

    static var defaultTheme: TLIColorTheme { .starfleet }

    static func fromStoredRawValue(_ rawValue: String?) -> TLIColorTheme {
        switch rawValue?.lowercased() {
        case "classic":
            .starfleet
        case "desi":
            .risa
        case "lcars":
            .lcars
        case "risa":
            .risa
        case "tos", "tng", "ds9", "voyager", "enterprise", "starfleet":
            .starfleet
        case let value?:
            TLIColorTheme(rawValue: value) ?? .defaultTheme
        default:
            .defaultTheme
        }
    }

    var title: String {
        switch self {
        case .tos: return "TOS"
        case .tng: return "TNG"
        case .ds9: return "DS9"
        case .voyager: return "Voyager"
        case .enterprise: return "Enterprise"
        case .starfleet: return "Federation Command"
        case .lcars: return "LCARS"
        case .risa: return "Risa"
        }
    }

    var description: String {
        switch self {
        case .tos:
            "Bold bridge primaries, black consoles, and classic-series command drama."
        case .tng:
            "Enterprise-D warmth, soft greys, and polished late-24th-century comfort."
        case .ds9:
            "Promenade bronze, gunmetal framing, and station-side amber light."
        case .voyager:
            "Cool shipboard greys, blue instrumentation, and long-range mission focus."
        case .enterprise:
            "NX-era steel, blue instrumentation, and practical early-Starfleet restraint."
        case .starfleet:
            "A cinematic bridge look with command reds, instrumentation blues, and deep console shadows."
        case .lcars:
            "Black-backed LCARS panels with yellow, blue, red, and warm console color."
        case .risa:
            "Vacation-world brightness with tropical color and relaxed resort energy."
        }
    }

    var symbol: String {
        switch self {
        case .tos: return "sparkles.tv"
        case .tng: return "rectangle.3.group.bubble.left.fill"
        case .ds9: return "building.2.crop.circle.fill"
        case .voyager: return "location.north.line.fill"
        case .enterprise: return "dot.radiowaves.left.and.right"
        case .starfleet: return "star.circle.fill"
        case .lcars: return "cpu.fill"
        case .risa: return "sun.max.fill"
        }
    }

    fileprivate var palette: TLIThemePalette {
        switch self {
        case .tos:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.98, green: 0.95, blue: 0.88),
                textPrimaryLight: Color(red: 26/255, green: 21/255, blue: 20/255),
                textSecondaryDark: Color(red: 0.95, green: 0.84, blue: 0.60),
                textSecondaryLight: Color(red: 98/255, green: 72/255, blue: 40/255),
                textMutedDark: Color(red: 0.78, green: 0.71, blue: 0.56),
                textMutedLight: Color(red: 120/255, green: 94/255, blue: 74/255),
                textTertiaryDark: Color(red: 0.00, green: 0.60, blue: 0.96),
                textTertiaryLight: Color(red: 0.00, green: 0.48, blue: 0.78),
                accentDark: Color(red: 242/255, green: 195/255, blue: 0/255),
                accentLight: Color(red: 223/255, green: 0/255, blue: 0/255),
                accentSecondaryDark: Color(red: 0/255, green: 153/255, blue: 246/255),
                accentSecondaryLight: Color(red: 0/255, green: 153/255, blue: 246/255),
                accentGoldDark: Color(red: 242/255, green: 195/255, blue: 0/255),
                accentGoldLight: Color(red: 242/255, green: 195/255, blue: 0/255),
                backgroundTopDark: Color(red: 0/255, green: 0/255, blue: 0/255),
                backgroundMidDark: Color(red: 38/255, green: 8/255, blue: 8/255),
                backgroundBottomDark: Color(red: 92/255, green: 44/255, blue: 0/255),
                backgroundTopLight: Color(red: 0.98, green: 0.95, blue: 0.88),
                backgroundMidLight: Color(red: 0.96, green: 0.88, blue: 0.66),
                backgroundBottomLight: Color(red: 0.90, green: 0.83, blue: 0.74),
                cardBackgroundDark: Color(red: 7/255, green: 7/255, blue: 10/255).opacity(0.95),
                cardBackgroundLight: Color(red: 0.98, green: 0.94, blue: 0.87).opacity(0.98),
                cardStrokeDark: Color(red: 242/255, green: 195/255, blue: 0/255).opacity(0.52),
                cardStrokeLight: Color(red: 223/255, green: 0/255, blue: 0/255).opacity(0.28),
                chipBackgroundDark: Color(red: 30/255, green: 7/255, blue: 7/255).opacity(0.94),
                chipBackgroundLight: Color(red: 0.95, green: 0.87, blue: 0.72),
                navBarDark: Color(red: 0/255, green: 0/255, blue: 0/255),
                navBarLight: Color(red: 0.98, green: 0.93, blue: 0.86),
                tabBarDark: Color(red: 5/255, green: 5/255, blue: 8/255),
                tabBarLight: Color(red: 0.98, green: 0.93, blue: 0.86),
                tabInactiveDark: Color(red: 242/255, green: 195/255, blue: 0/255).opacity(0.74),
                tabInactiveLight: Color.black.opacity(0.58)
            )
        case .tng:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.96, green: 0.93, blue: 0.84),
                textPrimaryLight: Color(red: 34/255, green: 26/255, blue: 26/255),
                textSecondaryDark: Color(red: 0.84, green: 0.77, blue: 0.58),
                textSecondaryLight: Color(red: 96/255, green: 74/255, blue: 54/255),
                textMutedDark: Color(red: 0.73, green: 0.67, blue: 0.58),
                textMutedLight: Color(red: 122/255, green: 98/255, blue: 82/255),
                textTertiaryDark: Color(red: 0.17, green: 0.33, blue: 0.65),
                textTertiaryLight: Color(red: 0.17, green: 0.33, blue: 0.65),
                accentDark: Color(red: 214/255, green: 164/255, blue: 68/255),
                accentLight: Color(red: 167/255, green: 19/255, blue: 19/255),
                accentSecondaryDark: Color(red: 43/255, green: 83/255, blue: 167/255),
                accentSecondaryLight: Color(red: 43/255, green: 83/255, blue: 167/255),
                accentGoldDark: Color(red: 193/255, green: 199/255, blue: 48/255),
                accentGoldLight: Color(red: 193/255, green: 199/255, blue: 48/255),
                backgroundTopDark: Color(red: 0/255, green: 0/255, blue: 0/255),
                backgroundMidDark: Color(red: 44/255, green: 18/255, blue: 18/255),
                backgroundBottomDark: Color(red: 97/255, green: 78/255, blue: 38/255),
                backgroundTopLight: Color(red: 0.93, green: 0.89, blue: 0.80),
                backgroundMidLight: Color(red: 0.88, green: 0.82, blue: 0.69),
                backgroundBottomLight: Color(red: 0.84, green: 0.76, blue: 0.70),
                cardBackgroundDark: Color(red: 18/255, green: 10/255, blue: 10/255).opacity(0.96),
                cardBackgroundLight: Color(red: 0.91, green: 0.85, blue: 0.77).opacity(0.97),
                cardStrokeDark: Color(red: 214/255, green: 164/255, blue: 68/255).opacity(0.52),
                cardStrokeLight: Color(red: 167/255, green: 19/255, blue: 19/255).opacity(0.26),
                chipBackgroundDark: Color(red: 38/255, green: 20/255, blue: 20/255).opacity(0.95),
                chipBackgroundLight: Color(red: 0.85, green: 0.80, blue: 0.70).opacity(0.82),
                navBarDark: Color(red: 9/255, green: 9/255, blue: 11/255),
                navBarLight: Color(red: 0.91, green: 0.85, blue: 0.78),
                tabBarDark: Color(red: 6/255, green: 6/255, blue: 8/255),
                tabBarLight: Color(red: 0.93, green: 0.88, blue: 0.82),
                tabInactiveDark: Color(red: 214/255, green: 164/255, blue: 68/255).opacity(0.72),
                tabInactiveLight: Color.black.opacity(0.62)
            )
        case .ds9:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.95, green: 0.91, blue: 0.84),
                textPrimaryLight: Color(red: 42/255, green: 34/255, blue: 34/255),
                textSecondaryDark: Color(red: 0.85, green: 0.77, blue: 0.68),
                textSecondaryLight: Color(red: 92/255, green: 74/255, blue: 68/255),
                textMutedDark: Color(red: 0.74, green: 0.66, blue: 0.58),
                textMutedLight: Color(red: 114/255, green: 92/255, blue: 82/255),
                textTertiaryDark: Color(red: 0.58, green: 0.58, blue: 0.62),
                textTertiaryLight: Color(red: 122/255, green: 102/255, blue: 92/255),
                accentDark: Color(red: 0.74, green: 0.49, blue: 0.26),
                accentLight: Color(red: 0.52, green: 0.31, blue: 0.20),
                accentSecondaryDark: Color(red: 0.54, green: 0.58, blue: 0.60),
                accentSecondaryLight: Color(red: 0.42, green: 0.45, blue: 0.48),
                accentGoldDark: Color(red: 0.84, green: 0.67, blue: 0.33),
                accentGoldLight: Color(red: 0.66, green: 0.48, blue: 0.20),
                backgroundTopDark: Color(red: 11/255, green: 12/255, blue: 15/255),
                backgroundMidDark: Color(red: 28/255, green: 30/255, blue: 34/255),
                backgroundBottomDark: Color(red: 74/255, green: 49/255, blue: 31/255),
                backgroundTopLight: Color(red: 0.95, green: 0.93, blue: 0.90),
                backgroundMidLight: Color(red: 0.86, green: 0.83, blue: 0.81),
                backgroundBottomLight: Color(red: 0.78, green: 0.73, blue: 0.68),
                cardBackgroundDark: Color(red: 20/255, green: 20/255, blue: 24/255).opacity(0.95),
                cardBackgroundLight: Color(red: 0.94, green: 0.90, blue: 0.86).opacity(0.96),
                cardStrokeDark: Color(red: 0.69, green: 0.52, blue: 0.30).opacity(0.36),
                cardStrokeLight: Color(red: 0.46, green: 0.36, blue: 0.30).opacity(0.24),
                chipBackgroundDark: Color(red: 49/255, green: 37/255, blue: 30/255).opacity(0.92),
                chipBackgroundLight: Color(red: 0.87, green: 0.83, blue: 0.78),
                navBarDark: Color(red: 18/255, green: 18/255, blue: 22/255),
                navBarLight: Color(red: 0.93, green: 0.90, blue: 0.86),
                tabBarDark: Color(red: 14/255, green: 14/255, blue: 18/255),
                tabBarLight: Color(red: 0.94, green: 0.91, blue: 0.88),
                tabInactiveDark: Color(red: 0.76, green: 0.65, blue: 0.52).opacity(0.70),
                tabInactiveLight: Color.black.opacity(0.56)
            )
        case .voyager:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.94, green: 0.96, blue: 0.98),
                textPrimaryLight: Color(red: 28/255, green: 38/255, blue: 48/255),
                textSecondaryDark: Color(red: 0.76, green: 0.82, blue: 0.86),
                textSecondaryLight: Color(red: 80/255, green: 94/255, blue: 106/255),
                textMutedDark: Color(red: 0.62, green: 0.68, blue: 0.72),
                textMutedLight: Color(red: 104/255, green: 116/255, blue: 126/255),
                textTertiaryDark: Color(red: 0.70, green: 0.74, blue: 0.77),
                textTertiaryLight: Color(red: 126/255, green: 128/255, blue: 132/255),
                accentDark: Color(red: 0.62, green: 0.72, blue: 0.78),
                accentLight: Color(red: 0.42, green: 0.50, blue: 0.56),
                accentSecondaryDark: Color(red: 0.46, green: 0.58, blue: 0.68),
                accentSecondaryLight: Color(red: 0.38, green: 0.46, blue: 0.54),
                accentGoldDark: Color(red: 0.78, green: 0.70, blue: 0.58),
                accentGoldLight: Color(red: 0.66, green: 0.58, blue: 0.46),
                backgroundTopDark: Color(red: 10/255, green: 14/255, blue: 18/255),
                backgroundMidDark: Color(red: 36/255, green: 42/255, blue: 48/255),
                backgroundBottomDark: Color(red: 74/255, green: 80/255, blue: 86/255),
                backgroundTopLight: Color(red: 0.93, green: 0.95, blue: 0.96),
                backgroundMidLight: Color(red: 0.85, green: 0.88, blue: 0.90),
                backgroundBottomLight: Color(red: 0.78, green: 0.81, blue: 0.83),
                cardBackgroundDark: Color(red: 20/255, green: 26/255, blue: 31/255).opacity(0.94),
                cardBackgroundLight: Color(red: 0.93, green: 0.95, blue: 0.96).opacity(0.97),
                cardStrokeDark: Color(red: 0.58, green: 0.66, blue: 0.72).opacity(0.34),
                cardStrokeLight: Color(red: 0.50, green: 0.55, blue: 0.60).opacity(0.22),
                chipBackgroundDark: Color(red: 34/255, green: 40/255, blue: 46/255).opacity(0.92),
                chipBackgroundLight: Color(red: 0.86, green: 0.89, blue: 0.91),
                navBarDark: Color(red: 18/255, green: 22/255, blue: 27/255),
                navBarLight: Color(red: 0.93, green: 0.95, blue: 0.96),
                tabBarDark: Color(red: 14/255, green: 18/255, blue: 22/255),
                tabBarLight: Color(red: 0.93, green: 0.95, blue: 0.96),
                tabInactiveDark: Color(red: 0.72, green: 0.77, blue: 0.80).opacity(0.72),
                tabInactiveLight: Color.black.opacity(0.56)
            )
        case .enterprise:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.94, green: 0.97, blue: 0.98),
                textPrimaryLight: Color(red: 28/255, green: 36/255, blue: 44/255),
                textSecondaryDark: Color(red: 0.79, green: 0.87, blue: 0.91),
                textSecondaryLight: Color(red: 78/255, green: 92/255, blue: 102/255),
                textMutedDark: Color(red: 0.69, green: 0.77, blue: 0.80),
                textMutedLight: Color(red: 100/255, green: 112/255, blue: 120/255),
                textTertiaryDark: Color(red: 0.58, green: 0.65, blue: 0.71),
                textTertiaryLight: Color(red: 118/255, green: 126/255, blue: 132/255),
                accentDark: Color(red: 0.34, green: 0.73, blue: 0.88),
                accentLight: Color(red: 0.26, green: 0.48, blue: 0.62),
                accentSecondaryDark: Color(red: 0.55, green: 0.61, blue: 0.66),
                accentSecondaryLight: Color(red: 0.49, green: 0.54, blue: 0.58),
                accentGoldDark: Color(red: 0.93, green: 0.78, blue: 0.47),
                accentGoldLight: Color(red: 0.82, green: 0.64, blue: 0.24),
                backgroundTopDark: Color(red: 14/255, green: 18/255, blue: 21/255),
                backgroundMidDark: Color(red: 27/255, green: 36/255, blue: 42/255),
                backgroundBottomDark: Color(red: 68/255, green: 78/255, blue: 82/255),
                backgroundTopLight: Color(red: 0.95, green: 0.97, blue: 0.97),
                backgroundMidLight: Color(red: 0.88, green: 0.91, blue: 0.92),
                backgroundBottomLight: Color(red: 0.80, green: 0.83, blue: 0.84),
                cardBackgroundDark: Color(red: 21/255, green: 28/255, blue: 33/255).opacity(0.94),
                cardBackgroundLight: Color(red: 0.94, green: 0.96, blue: 0.96).opacity(0.96),
                cardStrokeDark: Color(red: 0.50, green: 0.67, blue: 0.74).opacity(0.34),
                cardStrokeLight: Color(red: 0.45, green: 0.51, blue: 0.54).opacity(0.24),
                chipBackgroundDark: Color(red: 35/255, green: 45/255, blue: 48/255).opacity(0.92),
                chipBackgroundLight: Color(red: 0.86, green: 0.89, blue: 0.90),
                navBarDark: Color(red: 18/255, green: 24/255, blue: 28/255),
                navBarLight: Color(red: 0.94, green: 0.96, blue: 0.96),
                tabBarDark: Color(red: 15/255, green: 20/255, blue: 24/255),
                tabBarLight: Color(red: 0.95, green: 0.96, blue: 0.96),
                tabInactiveDark: Color(red: 0.69, green: 0.77, blue: 0.80).opacity(0.72),
                tabInactiveLight: Color.black.opacity(0.56)
            )
        case .starfleet:
            TLIThemePalette(
                textPrimaryDark: Color(red: 0.96, green: 0.94, blue: 0.90),
                textPrimaryLight: Color(red: 16/255, green: 16/255, blue: 22/255),
                textSecondaryDark: Color(red: 0.86, green: 0.83, blue: 0.77),
                textSecondaryLight: Color.black.opacity(0.70),
                textMutedDark: Color(red: 0.66, green: 0.70, blue: 0.75),
                textMutedLight: Color.black.opacity(0.54),
                textTertiaryDark: Color(red: 0.39, green: 0.62, blue: 0.92),
                textTertiaryLight: Color(red: 167/255, green: 19/255, blue: 19/255).opacity(0.72),
                accentDark: Color(red: 0.86, green: 0.20, blue: 0.16),
                accentLight: Color(red: 167/255, green: 19/255, blue: 19/255),
                accentSecondaryDark: Color(red: 0.36, green: 0.66, blue: 0.98),
                accentSecondaryLight: Color(red: 43/255, green: 83/255, blue: 167/255),
                accentGoldDark: Color(red: 0.90, green: 0.71, blue: 0.34),
                accentGoldLight: Color(red: 214/255, green: 164/255, blue: 68/255),
                backgroundTopDark: Color(red: 4/255, green: 8/255, blue: 18/255),
                backgroundMidDark: Color(red: 17/255, green: 24/255, blue: 42/255),
                backgroundBottomDark: Color(red: 58/255, green: 18/255, blue: 14/255),
                backgroundTopLight: Color(red: 0.95, green: 0.96, blue: 0.97),
                backgroundMidLight: Color(red: 0.92, green: 0.92, blue: 0.93),
                backgroundBottomLight: Color(red: 0.87, green: 0.88, blue: 0.90),
                cardBackgroundDark: Color(red: 9/255, green: 14/255, blue: 26/255).opacity(0.96),
                cardBackgroundLight: Color(red: 0.95, green: 0.96, blue: 0.97).opacity(0.98),
                cardStrokeDark: Color(red: 0.60, green: 0.72, blue: 0.92).opacity(0.26),
                cardStrokeLight: Color(red: 43/255, green: 83/255, blue: 167/255).opacity(0.20),
                chipBackgroundDark: Color(red: 17/255, green: 24/255, blue: 40/255).opacity(0.96),
                chipBackgroundLight: Color(red: 0.90, green: 0.92, blue: 0.95),
                navBarDark: Color(red: 7/255, green: 11/255, blue: 20/255),
                navBarLight: Color(red: 0.96, green: 0.97, blue: 0.98),
                tabBarDark: Color(red: 6/255, green: 10/255, blue: 18/255),
                tabBarLight: Color(red: 0.96, green: 0.97, blue: 0.98),
                tabInactiveDark: Color(red: 0.60, green: 0.72, blue: 0.92).opacity(0.74),
                tabInactiveLight: Color.black.opacity(0.52)
            )
        case .lcars:
            TLIThemePalette(
                textPrimaryDark: RisaPalette.lcarsSpaceWhite,
                textPrimaryLight: RisaPalette.lcarsPanelBlack,
                textSecondaryDark: RisaPalette.lcarsAlmond.opacity(0.92),
                textSecondaryLight: RisaPalette.lcarsGray.opacity(0.90),
                textMutedDark: RisaPalette.lcarsGray.opacity(0.86),
                textMutedLight: RisaPalette.lcarsC52.opacity(0.78),
                textTertiaryDark: RisaPalette.lcarsIce.opacity(0.90),
                textTertiaryLight: RisaPalette.lcarsBluey.opacity(0.82),
                accentDark: RisaPalette.lcarsOrange,
                accentLight: RisaPalette.lcarsOrange,
                accentSecondaryDark: RisaPalette.lcarsBluey,
                accentSecondaryLight: RisaPalette.lcarsSky,
                accentGoldDark: RisaPalette.lcarsGold,
                accentGoldLight: RisaPalette.lcarsSunflower,
                backgroundTopDark: RisaPalette.lcarsVoid,
                backgroundMidDark: RisaPalette.lcarsPanelBlack,
                backgroundBottomDark: RisaPalette.lcarsC51,
                backgroundTopLight: RisaPalette.lcarsSpaceWhite,
                backgroundMidLight: RisaPalette.lcarsVioletCreme,
                backgroundBottomLight: RisaPalette.lcarsAlmondCreme,
                cardBackgroundDark: RisaPalette.lcarsVoid.opacity(0.98),
                cardBackgroundLight: RisaPalette.lcarsAlmondCreme.opacity(0.96),
                cardStrokeDark: RisaPalette.lcarsBluey.opacity(0.44),
                cardStrokeLight: RisaPalette.lcarsAfricanViolet.opacity(0.34),
                chipBackgroundDark: RisaPalette.lcarsC52.opacity(0.90),
                chipBackgroundLight: RisaPalette.lcarsVioletCreme.opacity(0.78),
                navBarDark: RisaPalette.lcarsPanelBlack,
                navBarLight: RisaPalette.lcarsSpaceWhite,
                tabBarDark: RisaPalette.lcarsVoid,
                tabBarLight: RisaPalette.lcarsVioletCreme,
                tabInactiveDark: RisaPalette.lcarsBluey.opacity(0.76),
                tabInactiveLight: Color.black.opacity(0.62)
            )
        case .risa:
            TLIThemePalette(
                textPrimaryDark: .white,
                textPrimaryLight: Color(red: 10/255, green: 16/255, blue: 30/255),
                textSecondaryDark: Color.white.opacity(0.82),
                textSecondaryLight: Color(red: 20/255, green: 32/255, blue: 56/255).opacity(0.86),
                textMutedDark: Color.white.opacity(0.66),
                textMutedLight: Color.black.opacity(0.55),
                textTertiaryDark: Color.white.opacity(0.50),
                textTertiaryLight: Color.black.opacity(0.44),
                accentDark: Color(red: 1.00, green: 0.41, blue: 0.75),
                accentLight: Color(red: 1.00, green: 0.41, blue: 0.75),
                accentSecondaryDark: Color(red: 0.26, green: 0.78, blue: 1.00),
                accentSecondaryLight: Color(red: 0.26, green: 0.78, blue: 1.00),
                accentGoldDark: Color(red: 0.81, green: 1.00, blue: 0.00),
                accentGoldLight: Color(red: 0.81, green: 1.00, blue: 0.00),
                backgroundTopDark: RisaPalette.desiNightTop,
                backgroundMidDark: RisaPalette.desiNightMid,
                backgroundBottomDark: RisaPalette.desiNightBottom,
                backgroundTopLight: Color(red: 0.03, green: 0.67, blue: 0.65),
                backgroundMidLight: Color(red: 0.06, green: 0.78, blue: 0.74),
                backgroundBottomLight: Color(red: 0.74, green: 1.00, blue: 0.03),
                cardBackgroundDark: RisaPalette.desiCardDark,
                cardBackgroundLight: Color.white.opacity(0.90),
                cardStrokeDark: RisaPalette.desiBorderDark,
                cardStrokeLight: Color(red: 0.01, green: 0.30, blue: 0.56).opacity(0.30),
                chipBackgroundDark: RisaPalette.desiChipDark,
                chipBackgroundLight: Color(red: 0.85, green: 1.00, blue: 0.15).opacity(0.55),
                navBarDark: RisaPalette.desiNavDark,
                navBarLight: Color(red: 0.53, green: 0.90, blue: 0.89),
                tabBarDark: RisaPalette.desiTabDark,
                tabBarLight: Color(red: 0.75, green: 0.96, blue: 0.52),
                tabInactiveDark: Color(red: 0.54, green: 1.00, blue: 0.78).opacity(0.74),
                tabInactiveLight: Color.black.opacity(0.70)
            )
        }
    }
}

enum TLILCARSLabel {
    static var bridge: String { RisaTheme.isLCARSThemeEnabled ? "Main Viewer" : "Bridge" }
    static var schedule: String { RisaTheme.isLCARSThemeEnabled ? "Mission Timeline" : "Schedule" }
    static var explore: String { RisaTheme.isLCARSThemeEnabled ? "Personnel Database" : "Explore" }
    static var map: String { RisaTheme.isLCARSThemeEnabled ? "Ship Deck Layout" : "Map" }
    static var more: String { RisaTheme.isLCARSThemeEnabled ? "Subsystems" : "More" }
    static var bridgeTab: String { RisaTheme.isLCARSThemeEnabled ? "Viewer" : "Bridge" }
    static var scheduleTab: String { RisaTheme.isLCARSThemeEnabled ? "Timeline" : "Schedule" }
    static var exploreTab: String { RisaTheme.isLCARSThemeEnabled ? "Database" : "Explore" }
    static var mapTab: String { RisaTheme.isLCARSThemeEnabled ? "Decks" : "Map" }
    static var moreTab: String { RisaTheme.isLCARSThemeEnabled ? "Systems" : "More" }
    static var guests: String { RisaTheme.isLCARSThemeEnabled ? "Personnel Database" : "Guests" }
    static var exhibitors: String { RisaTheme.isLCARSThemeEnabled ? "Commerce Registry" : "Exhibitors" }
    static var sponsors: String { RisaTheme.isLCARSThemeEnabled ? "Federation Sponsors" : "Sponsors" }
    static var maps: String { RisaTheme.isLCARSThemeEnabled ? "Ship Deck Layout" : "Maps" }
}

private struct TLIThemePalette {
    let textPrimaryDark: Color
    let textPrimaryLight: Color
    let textSecondaryDark: Color
    let textSecondaryLight: Color
    let textMutedDark: Color
    let textMutedLight: Color
    let textTertiaryDark: Color
    let textTertiaryLight: Color
    let accentDark: Color
    let accentLight: Color
    let accentSecondaryDark: Color
    let accentSecondaryLight: Color
    let accentGoldDark: Color
    let accentGoldLight: Color
    let backgroundTopDark: Color
    let backgroundMidDark: Color
    let backgroundBottomDark: Color
    let backgroundTopLight: Color
    let backgroundMidLight: Color
    let backgroundBottomLight: Color
    let cardBackgroundDark: Color
    let cardBackgroundLight: Color
    let cardStrokeDark: Color
    let cardStrokeLight: Color
    let chipBackgroundDark: Color
    let chipBackgroundLight: Color
    let navBarDark: Color
    let navBarLight: Color
    let tabBarDark: Color
    let tabBarLight: Color
    let tabInactiveDark: Color
    let tabInactiveLight: Color

    func textPrimary(for scheme: ColorScheme) -> Color { scheme == .dark ? textPrimaryDark : textPrimaryLight }
    func textSecondary(for scheme: ColorScheme) -> Color { scheme == .dark ? textSecondaryDark : textSecondaryLight }
    func textMuted(for scheme: ColorScheme) -> Color { scheme == .dark ? textMutedDark : textMutedLight }
    func textTertiary(for scheme: ColorScheme) -> Color { scheme == .dark ? textTertiaryDark : textTertiaryLight }
    func accent(for scheme: ColorScheme) -> Color { scheme == .dark ? accentDark : accentLight }
    func accentSecondary(for scheme: ColorScheme) -> Color { scheme == .dark ? accentSecondaryDark : accentSecondaryLight }
    func accentGold(for scheme: ColorScheme) -> Color { scheme == .dark ? accentGoldDark : accentGoldLight }
    func backgroundTop(for scheme: ColorScheme) -> Color { scheme == .dark ? backgroundTopDark : backgroundTopLight }
    func backgroundMid(for scheme: ColorScheme) -> Color { scheme == .dark ? backgroundMidDark : backgroundMidLight }
    func backgroundBottom(for scheme: ColorScheme) -> Color { scheme == .dark ? backgroundBottomDark : backgroundBottomLight }
    func cardBackground(for scheme: ColorScheme) -> Color { scheme == .dark ? cardBackgroundDark : cardBackgroundLight }
    func cardStroke(for scheme: ColorScheme) -> Color { scheme == .dark ? cardStrokeDark : cardStrokeLight }
    func chipBackground(for scheme: ColorScheme) -> Color { scheme == .dark ? chipBackgroundDark : chipBackgroundLight }
    func navBarBackground(for scheme: ColorScheme) -> Color { scheme == .dark ? navBarDark : navBarLight }
    func tabBarBackground(for scheme: ColorScheme) -> Color { scheme == .dark ? tabBarDark : tabBarLight }
    func tabInactive(for scheme: ColorScheme) -> Color { scheme == .dark ? tabInactiveDark : tabInactiveLight }
}

// MARK: - Asset Helper

private extension Color {
    /// Try to load a Color from Assets by name, returning nil if missing.
    static func tliAsset(named name: String) -> Color? {
        #if os(iOS)
        if let ui = UIColor(named: name) {
            return Color(ui)
        }
        #endif
        return nil
    }
}

// MARK: - Core Palette (fallbacks if you don't have assets)

private enum RisaPalette {
    // Deep dark-mode “space” tones
    static let spaceNavy   = Color(red:  3/255, green: 10/255, blue: 30/255) // top
    static let deepIndigo  = Color(red: 18/255, green: 20/255, blue: 62/255) // mid
    static let nightViolet = Color(red: 45/255, green: 18/255, blue: 88/255) // bottom
    static let classicNightTop = Color(red: 4/255, green: 10/255, blue: 28/255)
    static let classicNightMid = Color(red: 12/255, green: 28/255, blue: 64/255)
    static let classicNightBottom = Color(red: 24/255, green: 32/255, blue: 78/255)
    static let classicCardDark = Color(red: 9/255, green: 18/255, blue: 42/255).opacity(0.88)
    static let classicBorderDark = Color(red: 0.42, green: 0.78, blue: 1.00).opacity(0.30)
    static let classicChipDark = Color(red: 0.11, green: 0.18, blue: 0.36).opacity(0.92)

    // Light-mode “Trek paper” tones (slightly cool, not pure white)
    static let lightIrisTop    = Color(red: 0.965, green: 0.975, blue: 1.000)
    static let lightIrisBottom = Color(red: 0.910, green: 0.930, blue: 1.000)

    // Brand-ish accents
    static let accentMagenta = Color(red: 0.93, green: 0.38, blue: 0.63)
    static let accentCyan    = Color(red: 0.29, green: 0.83, blue: 0.93)
    static let accentGold    = Color(red: 0.98, green: 0.82, blue: 0.45)

    // Desi dark-mode tones
    static let desiNightTop      = Color(red: 2/255, green: 20/255, blue: 26/255)
    static let desiNightMid      = Color(red: 4/255, green: 53/255, blue: 63/255)
    static let desiNightBottom   = Color(red: 12/255, green: 27/255, blue: 20/255)
    static let desiCardDark      = Color(red: 6/255, green: 28/255, blue: 34/255).opacity(0.92)
    static let desiChipDark      = Color(red: 0.06, green: 0.27, blue: 0.24).opacity(0.96)
    static let desiBorderDark    = Color(red: 0.34, green: 0.95, blue: 0.78).opacity(0.34)
    static let desiNavDark       = Color(red: 1/255, green: 24/255, blue: 31/255)
    static let desiTabDark       = Color(red: 1/255, green: 18/255, blue: 24/255)

    // LCARS reference tones aligned to the public LCARS color guide.
    static let lcarsVoid        = Color(red: 1/255, green: 1/255, blue: 5/255)
    static let lcarsPanelBlack  = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let lcarsMidnight    = Color(red: 17/255, green: 17/255, blue: 238/255)
    static let lcarsSpaceWhite  = Color(red: 245/255, green: 246/255, blue: 250/255)
    static let lcarsVioletCreme = Color(red: 221/255, green: 187/255, blue: 255/255)
    static let lcarsGreen       = Color(red: 51/255, green: 204/255, blue: 153/255)
    static let lcarsMagenta     = Color(red: 204/255, green: 68/255, blue: 153/255)
    static let lcarsBlue        = Color(red: 68/255, green: 85/255, blue: 255/255)
    static let lcarsYellow      = Color(red: 255/255, green: 204/255, blue: 51/255)
    static let lcarsViolet      = Color(red: 153/255, green: 68/255, blue: 255/255)
    static let lcarsOrange      = Color(red: 255/255, green: 119/255, blue: 0/255)
    static let lcarsAfricanViolet = Color(red: 204/255, green: 136/255, blue: 255/255)
    static let lcarsLavender    = Color(red: 221/255, green: 187/255, blue: 255/255)
    static let lcarsRose        = Color(red: 204/255, green: 68/255, blue: 153/255)
    static let lcarsRed         = Color(red: 221/255, green: 68/255, blue: 68/255)
    static let lcarsAlmond      = Color(red: 255/255, green: 170/255, blue: 144/255)
    static let lcarsAlmondCreme = Color(red: 255/255, green: 187/255, blue: 170/255)
    static let lcarsSunflower   = Color(red: 255/255, green: 204/255, blue: 102/255)
    static let lcarsBluey       = Color(red: 119/255, green: 136/255, blue: 255/255)
    static let lcarsGray        = Color(red: 102/255, green: 102/255, blue: 136/255)
    static let lcarsSky         = Color(red: 170/255, green: 170/255, blue: 255/255)
    static let lcarsIce         = Color(red: 136/255, green: 204/255, blue: 255/255)
    static let lcarsGold        = Color(red: 255/255, green: 170/255, blue: 0/255)
    static let lcarsMars        = Color(red: 255/255, green: 34/255, blue: 0/255)
    static let lcarsPeach       = Color(red: 255/255, green: 136/255, blue: 102/255)
    static let lcarsButterscotch = Color(red: 255/255, green: 153/255, blue: 102/255)
    static let lcarsTomato      = Color(red: 255/255, green: 85/255, blue: 85/255)
    static let lcarsLilac       = Color(red: 204/255, green: 51/255, blue: 255/255)
    static let lcarsRoseblush   = Color(red: 204/255, green: 102/255, blue: 102/255)
    static let lcarsHoney       = Color(red: 255/255, green: 204/255, blue: 153/255)
    static let lcarsC51         = Color(red: 85/255, green: 34/255, blue: 85/255)
    static let lcarsC52         = Color(red: 102/255, green: 51/255, blue: 102/255)
    static let lcarsC53         = Color(red: 119/255, green: 68/255, blue: 119/255)
    static let lcarsC54         = Color(red: 136/255, green: 85/255, blue: 136/255)
    static let lcarsC55         = Color(red: 153/255, green: 102/255, blue: 153/255)
    static let lcarsC56         = Color(red: 255/255, green: 136/255, blue: 0/255)
    static let lcarsC57         = Color(red: 208/255, green: 176/255, blue: 160/255)
    static let lcarsC58         = Color(red: 187/255, green: 187/255, blue: 255/255)
    static let lcarsC59         = Color(red: 153/255, green: 170/255, blue: 102/255)
    static let lcarsSignalGreen = Color(red: 0.58, green: 0.86, blue: 0.41)
    static let lcarsSlate       = Color(red: 68/255, green: 74/255, blue: 119/255)
    static let lcarsCream       = Color(red: 246/255, green: 238/255, blue: 246/255)
    static let lcarsLightPanel  = Color(red: 255/255, green: 235/255, blue: 222/255)

    // Card / chip helpers
    static let cardDark   = Color.white.opacity(0.11)
    static let cardLight  = Color.white.opacity(0.90)
    static let borderDark = Color.white.opacity(0.24)
    static let borderLite = Color.black.opacity(0.10)
}

// MARK: - Risa Theme

enum RisaTheme {
    private static var activePreset: TLIVisualPreset {
        if let raw = UserDefaults.standard.string(forKey: "appVisualPreset") {
            return TLIVisualPreset.fromStoredRawValue(raw)
        }
        return TLIVisualPreset.resolve(theme: activeColorTheme, appearance: activeAppearance)
    }

    private static var activeAppearance: AppAppearance {
        let raw = UserDefaults.standard.string(forKey: "appAppearance") ?? AppAppearance.system.rawValue
        return AppAppearance(rawValue: raw) ?? .system
    }

    private static var activeColorTheme: TLIColorTheme {
        TLIColorTheme.fromStoredRawValue(UserDefaults.standard.string(forKey: "appColorTheme"))
    }

    static var isDesiThemeEnabled: Bool {
        activeColorTheme == .risa
    }

    static var isLCARSThemeEnabled: Bool {
        activeColorTheme == .lcars
    }

    static var currentTheme: TLIColorTheme {
        activePreset.theme
    }

    static var currentPreset: TLIVisualPreset {
        activePreset
    }

    private static var isHighContrastEnabled: Bool {
        UserDefaults.standard.bool(forKey: "TLI.Accessibility.highContrast")
    }

    private static func blend(_ color: Color, toward target: Color, amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let source = UIColor(color)
        let destination = UIColor(target)

        var sr: CGFloat = 0
        var sg: CGFloat = 0
        var sb: CGFloat = 0
        var sa: CGFloat = 0
        var tr: CGFloat = 0
        var tg: CGFloat = 0
        var tb: CGFloat = 0
        var ta: CGFloat = 0

        guard source.getRed(&sr, green: &sg, blue: &sb, alpha: &sa),
              destination.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else {
            return color
        }

        let clamped = min(max(amount, 0), 1)
        return Color(
            red: sr + (tr - sr) * clamped,
            green: sg + (tg - sg) * clamped,
            blue: sb + (tb - sb) * clamped,
            opacity: sa + (ta - sa) * clamped
        )
        #else
        return color
        #endif
    }

    // MARK: Text

    /// Primary text (titles, body).
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "TextPrimary") { return asset }
        if isHighContrastEnabled {
            return scheme == .dark ? .white : .black
        }
        return activeColorTheme.palette.textPrimary(for: scheme)
    }

    /// Secondary / supporting text.
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "TextSecondary") { return asset }
        if isHighContrastEnabled {
            return scheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
        }
        let base = activeColorTheme.palette.textSecondary(for: scheme)
        let target = textPrimary(scheme)
        let amount: CGFloat = scheme == .dark ? 0.18 : 0.24
        return blend(base, toward: target, amount: amount)
    }

    /// Muted / caption text.
    static func textMuted(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "TextMuted") { return asset }
        let base = activeColorTheme.palette.textMuted(for: scheme)
        let target = textPrimary(scheme)
        let amount: CGFloat = scheme == .dark ? 0.14 : 0.20
        return blend(base, toward: target, amount: amount)
    }

    /// Tertiary / de-emphasized text (labels, meta).
    static func textTertiary(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "TextTertiary") { return asset }
        let base = activeColorTheme.palette.textTertiary(for: scheme)
        let target = textPrimary(scheme)
        let amount: CGFloat = scheme == .dark ? 0.10 : 0.16
        return blend(base, toward: target, amount: amount)
    }

    // MARK: Accents

    /// Primary accent (buttons, links, selection).
    static func accent(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "AccentPrimary") { return asset }
        if isHighContrastEnabled {
            return scheme == .dark ? RisaPalette.lcarsPeach : Color(red: 0.82, green: 0.24, blue: 0.46)
        }
        return activeColorTheme.palette.accent(for: scheme)
    }

    /// Secondary accent (chips, highlights).
    static func accentSecondary(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "AccentSecondary") { return asset }
        return activeColorTheme.palette.accentSecondary(for: scheme)
    }

    /// Softer accent used for backgrounds, pills, etc.
    static func accentSoft(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "AccentSoft") { return asset }
        let base = accent(scheme)
        let opacity: Double
        switch activeColorTheme {
        case .lcars, .tng:
            opacity = scheme == .dark ? 0.42 : 0.24
        case .risa:
            opacity = scheme == .dark ? 0.52 : 0.30
        case .tos, .ds9:
            opacity = scheme == .dark ? 0.40 : 0.22
        case .voyager:
            opacity = scheme == .dark ? 0.36 : 0.24
        case .enterprise:
            opacity = scheme == .dark ? 0.34 : 0.20
        case .starfleet:
            opacity = scheme == .dark ? 0.45 : 0.30
        }
        return base.opacity(opacity)
    }

    /// Gold accent, useful for “Q Pass” or sponsor highlights.
    static func accentGold(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "AccentGold") { return asset }
        return activeColorTheme.palette.accentGold(for: scheme)
    }

    // MARK: Backgrounds

    static func backgroundTop(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "BackgroundTop") { return asset }
        return activeColorTheme.palette.backgroundTop(for: scheme)
    }

    static func backgroundBottom(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "BackgroundBottom") { return asset }
        return activeColorTheme.palette.backgroundBottom(for: scheme)
    }

    /// The main “space / paper” gradient used behind most screens.
    static func backgroundGradientColors(for scheme: ColorScheme) -> [Color] {
        let palette = activeColorTheme.palette
        switch activeColorTheme {
        case .lcars, .tng:
            return [
                palette.backgroundTop(for: scheme),
                palette.backgroundMid(for: scheme),
                palette.backgroundBottom(for: scheme)
            ]
        default:
            return [
                palette.backgroundTop(for: scheme),
                palette.backgroundMid(for: scheme),
                palette.backgroundBottom(for: scheme)
            ]
        }
    }

    // MARK: Surfaces

    /// Glassy card background color (used with .ultraThinMaterial overlays).
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "CardBackground") { return asset }
        if isHighContrastEnabled {
            return scheme == .dark ? Color.black.opacity(0.72) : Color.white
        }
        return activeColorTheme.palette.cardBackground(for: scheme)
    }

    /// Card outline color.
    static func cardStroke(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "CardStroke") { return asset }
        if isHighContrastEnabled {
            return scheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.22)
        }
        return activeColorTheme.palette.cardStroke(for: scheme)
    }

    /// Alias expected by older views.
    static func cardBorder(_ scheme: ColorScheme) -> Color {
        cardStroke(scheme)
    }

    /// Chip/tag pill backgrounds.
    static func chipBackground(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "ChipBackground") { return asset }
        return activeColorTheme.palette.chipBackground(for: scheme)
    }

    /// Chip/tag pill foreground text color.
    static func chipForeground(_ scheme: ColorScheme) -> Color {
        if let asset = Color.tliAsset(named: "ChipForeground") { return asset }
        return textPrimary(scheme)
    }

    static func selectedChipBackground(_ scheme: ColorScheme) -> Color {
        switch activeColorTheme {
        case .tos:
            return accentGold(scheme)
        case .tng, .lcars:
            return accent(scheme).opacity(0.94)
        case .ds9:
            return accent(scheme).opacity(0.92)
        case .voyager:
            return accentSecondary(scheme).opacity(0.94)
        case .enterprise:
            return accent(scheme).opacity(0.88)
        case .starfleet:
            return accent(scheme).opacity(0.92)
        case .risa:
            return accentSecondary(scheme).opacity(0.92)
        }
    }

    static func selectedChipForeground(_ scheme: ColorScheme) -> Color {
        switch activeColorTheme {
        case .tos, .voyager, .risa:
            return Color.black.opacity(0.92)
        default:
            return scheme == .dark ? Color.black.opacity(0.90) : textPrimary(scheme)
        }
    }

    // MARK: - UIKit Bridge (Nav/Tab colors)

    #if os(iOS)
    private static func normalizedScheme(_ scheme: ColorScheme?) -> ColorScheme {
        scheme ?? .dark
    }

    static func accentUIColor(for scheme: ColorScheme?) -> UIColor {
        UIColor(accent(normalizedScheme(scheme)))
    }

    static func navBarBackgroundUIColor(for scheme: ColorScheme?) -> UIColor {
        let normalized = normalizedScheme(scheme)
        let alpha = activeColorTheme == .lcars ? 0.98 : 0.95
        return UIColor(activeColorTheme.palette.navBarBackground(for: normalized)).withAlphaComponent(alpha)
    }

    static func navTitleUIColor(for scheme: ColorScheme?) -> UIColor {
        UIColor(textPrimary(normalizedScheme(scheme)))
    }

    static func tabBarBackgroundUIColor(for scheme: ColorScheme?) -> UIColor {
        let normalized = normalizedScheme(scheme)
        let alpha = activeColorTheme == .lcars ? 0.98 : 0.97
        return UIColor(activeColorTheme.palette.tabBarBackground(for: normalized)).withAlphaComponent(alpha)
    }

    static func tabIconActiveUIColor(for scheme: ColorScheme?) -> UIColor {
        accentUIColor(for: scheme)
    }

    static func tabIconInactiveUIColor(for scheme: ColorScheme?) -> UIColor {
        let normalized = normalizedScheme(scheme)
        return UIColor(activeColorTheme.palette.tabInactive(for: normalized))
    }

    static func tabLabelActiveUIColor(for scheme: ColorScheme?) -> UIColor {
        accentUIColor(for: scheme)
    }

    static func tabLabelInactiveUIColor(for scheme: ColorScheme?) -> UIColor {
        UIColor(textSecondary(normalizedScheme(scheme)).opacity(0.92))
    }

    /// Canonical accent color for UIKit tinting.
    static var accentUIColor: UIColor {
        accentUIColor(for: .dark)
    }

    static var navBarBackgroundUIColor: UIColor {
        navBarBackgroundUIColor(for: .dark)
    }

    static var navTitleUIColor: UIColor {
        navTitleUIColor(for: .dark)
    }

    static var tabBarBackgroundUIColor: UIColor {
        tabBarBackgroundUIColor(for: .dark)
    }

    static var tabIconActiveUIColor: UIColor {
        tabIconActiveUIColor(for: .dark)
    }

    static var tabIconInactiveUIColor: UIColor {
        tabIconInactiveUIColor(for: .dark)
    }

    static var tabLabelActiveUIColor: UIColor {
        tabLabelActiveUIColor(for: .dark)
    }

    static var tabLabelInactiveUIColor: UIColor {
        tabLabelInactiveUIColor(for: .dark)
    }
    #endif

    static func navBarBackground(_ scheme: ColorScheme) -> Color {
        activeColorTheme.palette.navBarBackground(for: scheme)
    }

    static func tabBarBackground(_ scheme: ColorScheme) -> Color {
        activeColorTheme.palette.tabBarBackground(for: scheme)
    }
}

// MARK: - Trek LI Theme Helpers (SwiftUI side)

/// Convenience API used throughout the Trek Long Island SwiftUI views.
enum TLITheme {
    /// Full-screen background gradient. No starfield.
    static func backgroundGradient(_ scheme: ColorScheme) -> some View {
        let theme = RisaTheme.currentTheme
        let primaryGlow = RisaTheme.accent(scheme).opacity(scheme == .dark ? 0.25 : 0.10)
        let secondaryGlow = RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.18 : 0.08)
        let tertiaryGlow = RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.12 : 0.06)
        let vignette = Color.black.opacity(scheme == .dark ? 0.26 : 0.08)
        let lcarsHorizon = RisaTheme.isLCARSThemeEnabled && scheme == .dark
            ? Color(red: 6/255, green: 25/255, blue: 82/255).opacity(0.34)
            : .clear
        let starfieldOpacity: Double
        let gridOpacity: Double
        switch (theme, scheme) {
        case (.tos, .dark):
            starfieldOpacity = 0.16
            gridOpacity = 0.12
        case (.tng, .dark):
            starfieldOpacity = 0.22
            gridOpacity = 0.34
        case (.ds9, .dark):
            starfieldOpacity = 0.10
            gridOpacity = 0.14
        case (.voyager, .dark):
            starfieldOpacity = 0.34
            gridOpacity = 0.18
        case (.enterprise, .dark):
            starfieldOpacity = 0.12
            gridOpacity = 0.10
        case (.starfleet, .dark):
            starfieldOpacity = 0.24
            gridOpacity = 0.22
        case (.lcars, .dark):
            starfieldOpacity = 0.18
            gridOpacity = 0.22
        case (.risa, .dark):
            starfieldOpacity = 0.08
            gridOpacity = 0.10
        case (.tos, .light):
            starfieldOpacity = 0.04
            gridOpacity = 0.05
        case (.tng, .light):
            starfieldOpacity = 0.08
            gridOpacity = 0.18
        case (.ds9, .light):
            starfieldOpacity = 0.03
            gridOpacity = 0.08
        case (.voyager, .light):
            starfieldOpacity = 0.10
            gridOpacity = 0.12
        case (.enterprise, .light):
            starfieldOpacity = 0.03
            gridOpacity = 0.06
        case (.starfleet, .light):
            starfieldOpacity = 0.06
            gridOpacity = 0.12
        case (.lcars, .light):
            starfieldOpacity = 0.16
            gridOpacity = 0.24
        case (.risa, .light):
            starfieldOpacity = 0.01
            gridOpacity = 0.03
        @unknown default:
            starfieldOpacity = scheme == .dark ? 0.24 : 0.12
            gridOpacity = scheme == .dark ? 0.20 : 0.10
        }

        return ZStack {
            LinearGradient(
                colors: RisaTheme.backgroundGradientColors(for: scheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [primaryGlow, .clear],
                center: .topLeading,
                startRadius: 24,
                endRadius: 430
            )

            RadialGradient(
                colors: [secondaryGlow, .clear],
                center: .bottomTrailing,
                startRadius: 12,
                endRadius: 390
            )

            RadialGradient(
                colors: [tertiaryGlow, .clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )

            LinearGradient(
                colors: [.clear, lcarsHorizon],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.screen)

            if theme == .lcars {
                LCARSWallpaperOverlay(scheme: scheme)

                LinearGradient(
                    colors: [
                        Color.black.opacity(scheme == .dark ? 0.26 : 0.10),
                        Color.black.opacity(scheme == .dark ? 0.18 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.multiply)
            }

            StarfieldOverlay(scheme: scheme)
                .opacity(starfieldOpacity)

            LCARSGridOverlay(scheme: scheme)
                .opacity(gridOpacity)

            LinearGradient(
                colors: [.clear, vignette],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
    }

    /// Standard card background color.
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        RisaTheme.cardBackground(scheme)
    }

    /// Standard card border color.
    static func cardStroke(_ scheme: ColorScheme) -> Color {
        RisaTheme.cardStroke(scheme)
    }

    /// Alias for older code expecting `TLITheme.border`.
    static func border(_ scheme: ColorScheme) -> Color {
        RisaTheme.cardStroke(scheme)
    }

    /// Hairline / divider thickness (used where a CGFloat is expected).
    static var hairline: CGFloat {
        #if os(iOS)
        let scale = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.scale ?? 2.0
        return 1.0 / scale
        #else
        return 0.5
        #endif
    }

    /// Shadow color for cards.
    static func cardShadowColor(_ scheme: ColorScheme) -> Color {
        switch RisaTheme.currentTheme {
        case .lcars, .tng:
            return scheme == .dark
                ? Color.black.opacity(0.82)
                : Color.black.opacity(0.16)
        case .tos, .ds9:
            return scheme == .dark
                ? Color.black.opacity(0.72)
                : Color.black.opacity(0.14)
        case .voyager:
            return scheme == .dark
                ? Color(red: 0, green: 0, blue: 0).opacity(0.68)
                : Color.black.opacity(0.15)
        case .enterprise:
            return scheme == .dark
                ? Color.black.opacity(0.58)
                : Color.black.opacity(0.12)
        case .starfleet, .risa:
            return scheme == .dark
                ? Color(red: 0.01, green: 0.03, blue: 0.08).opacity(0.76)
                : Color.black.opacity(0.16)
        }
    }

    /// Gloss gradient used for card highlights.
    static func cardGloss(_ scheme: ColorScheme) -> LinearGradient {
        switch RisaTheme.currentTheme {
        case .lcars, .tng:
            let top = Color.white.opacity(scheme == .dark ? 0.08 : 0.18)
            let middle = RisaPalette.lcarsPeach.opacity(scheme == .dark ? 0.10 : 0.08)
            return LinearGradient(colors: [top, middle, .clear], startPoint: .top, endPoint: .bottom)
        case .tos:
            return LinearGradient(
                colors: [
                    Color.white.opacity(scheme == .dark ? 0.10 : 0.20),
                    RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.12 : 0.08),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ds9:
            return LinearGradient(
                colors: [
                    Color.white.opacity(scheme == .dark ? 0.05 : 0.14),
                    RisaTheme.accent(scheme).opacity(scheme == .dark ? 0.08 : 0.05),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .voyager:
            return LinearGradient(
                colors: [
                    Color.white.opacity(scheme == .dark ? 0.10 : 0.20),
                    RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.10 : 0.06),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .enterprise:
            return LinearGradient(
                colors: [
                    Color.white.opacity(scheme == .dark ? 0.07 : 0.16),
                    Color.white.opacity(scheme == .dark ? 0.03 : 0.06),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .starfleet:
            let top = Color.white.opacity(scheme == .dark ? 0.08 : 0.22)
            let middle = RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.12 : 0.08)
            let lower = RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.06 : 0.04)
            return LinearGradient(colors: [top, middle, lower, .clear], startPoint: .top, endPoint: .bottom)
        case .risa:
            let top = Color.white.opacity(scheme == .dark ? 0.14 : 0.22)
            let middle = Color.white.opacity(scheme == .dark ? 0.04 : 0.08)
            let bottom = Color.clear
            return LinearGradient(colors: [top, middle, bottom], startPoint: .top, endPoint: .bottom)
        }
    }

    /// Primary accent color (for SF Symbols, highlights, etc.).
    static func accent(_ scheme: ColorScheme) -> Color {
        RisaTheme.accent(scheme)
    }

    /// Softer accent used for backgrounds/pills.
    static func accentSoft(_ scheme: ColorScheme) -> Color {
        RisaTheme.accentSoft(scheme)
    }

    /// Primary text.
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        RisaTheme.textPrimary(scheme)
    }

    /// Secondary text.
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        RisaTheme.textSecondary(scheme)
    }

    /// Tertiary / de-emphasized text.
    static func textTertiary(_ scheme: ColorScheme) -> Color {
        RisaTheme.textTertiary(scheme)
    }

    /// Chip backgrounds.
    static func chipBackground(_ scheme: ColorScheme) -> Color {
        RisaTheme.chipBackground(scheme)
    }

    /// Chip foreground.
    static func chipForeground(_ scheme: ColorScheme) -> Color {
        RisaTheme.chipForeground(scheme)
    }

    static func selectedChipBackground(_ scheme: ColorScheme) -> Color {
        RisaTheme.selectedChipBackground(scheme)
    }

    static func selectedChipForeground(_ scheme: ColorScheme) -> Color {
        RisaTheme.selectedChipForeground(scheme)
    }

    // MARK: - LCARS Panel Helpers

    static func lcarsPanelShape(cornerRadius: CGFloat) -> UnevenRoundedRectangle {
        let main = max(16, cornerRadius)
        let small = max(10, cornerRadius * 0.45)
        return UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: main,
                bottomLeading: main,
                bottomTrailing: small,
                topTrailing: small
            )
        )
    }

    static func panelShape(cornerRadius: CGFloat) -> AnyShape {
        switch RisaTheme.currentTheme {
        case .tos:
            AnyShape(RoundedRectangle(cornerRadius: max(10, cornerRadius * 0.5), style: .continuous))
        case .tng:
            AnyShape(lcarsPanelShape(cornerRadius: cornerRadius))
        case .ds9:
            AnyShape(RoundedRectangle(cornerRadius: max(16, cornerRadius * 0.85), style: .continuous))
        case .voyager:
            AnyShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: max(22, cornerRadius),
                    bottomLeading: max(14, cornerRadius * 0.7),
                    bottomTrailing: max(22, cornerRadius),
                    topTrailing: max(14, cornerRadius * 0.7)
                )
            ))
        case .enterprise:
            AnyShape(RoundedRectangle(cornerRadius: max(12, cornerRadius * 0.65), style: .continuous))
        case .starfleet:
            AnyShape(RoundedRectangle(cornerRadius: max(20, cornerRadius), style: .continuous))
        case .lcars:
            AnyShape(lcarsPanelShape(cornerRadius: cornerRadius))
        case .risa:
            AnyShape(RoundedRectangle(cornerRadius: max(24, cornerRadius * 1.15), style: .continuous))
        }
    }

    static func controlShape(cornerRadius: CGFloat) -> AnyShape {
        switch RisaTheme.currentTheme {
        case .tos:
            AnyShape(RoundedRectangle(cornerRadius: max(10, cornerRadius - 6), style: .continuous))
        case .tng:
            AnyShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: cornerRadius * 0.55,
                    bottomLeading: cornerRadius * 0.55,
                    bottomTrailing: cornerRadius,
                    topTrailing: cornerRadius
                )
            ))
        case .ds9:
            AnyShape(RoundedRectangle(cornerRadius: max(12, cornerRadius - 4), style: .continuous))
        case .voyager:
            AnyShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: cornerRadius,
                    bottomLeading: cornerRadius * 0.55,
                    bottomTrailing: cornerRadius,
                    topTrailing: cornerRadius * 0.55
                )
            ))
        case .enterprise:
            AnyShape(RoundedRectangle(cornerRadius: max(8, cornerRadius - 8), style: .continuous))
        case .starfleet:
            AnyShape(Capsule(style: .continuous))
        case .lcars:
            AnyShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: cornerRadius * 0.45,
                    bottomLeading: cornerRadius * 0.45,
                    bottomTrailing: cornerRadius * 1.25,
                    topTrailing: cornerRadius * 1.25
                )
            ))
        case .risa:
            AnyShape(Capsule(style: .continuous))
        }
    }

    static func sectionAccentGradient(_ scheme: ColorScheme) -> LinearGradient {
        switch RisaTheme.currentTheme {
        case .tos:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentGold(scheme), RisaTheme.accentSecondary(scheme)], startPoint: .leading, endPoint: .trailing)
        case .tng, .lcars:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentSecondary(scheme)], startPoint: .leading, endPoint: .trailing)
        case .ds9:
            return LinearGradient(colors: [RisaTheme.accentGold(scheme), RisaTheme.accent(scheme)], startPoint: .leading, endPoint: .trailing)
        case .voyager:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentSecondary(scheme), RisaTheme.accentGold(scheme)], startPoint: .leading, endPoint: .trailing)
        case .enterprise:
            return LinearGradient(colors: [RisaTheme.accentSecondary(scheme), RisaTheme.accent(scheme)], startPoint: .leading, endPoint: .trailing)
        case .starfleet:
            return LinearGradient(
                colors: [
                    RisaTheme.accentGold(scheme),
                    RisaTheme.accent(scheme),
                    RisaTheme.accentSecondary(scheme)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .risa:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentSecondary(scheme), RisaTheme.accentGold(scheme)], startPoint: .leading, endPoint: .trailing)
        }
    }

    @ViewBuilder
    static func panelDecoration(_ scheme: ColorScheme) -> some View {
        switch RisaTheme.currentTheme {
        case .tos:
            TOSPanelDecoration(scheme: scheme)
        case .tng:
            LCARSPanelDecoration(scheme: scheme)
                .opacity(0.74)
        case .ds9:
            DS9PanelDecoration(scheme: scheme)
        case .voyager:
            VoyagerPanelDecoration(scheme: scheme)
        case .enterprise:
            EnterprisePanelDecoration(scheme: scheme)
        case .starfleet:
            StarfleetPanelDecoration(scheme: scheme)
        case .lcars:
            LCARSPanelDecoration(scheme: scheme)
        case .risa:
            RisaPanelDecoration(scheme: scheme)
        }
    }

    static func lcarsRailGradient(_ scheme: ColorScheme) -> LinearGradient {
        switch RisaTheme.currentTheme {
        case .risa:
            return LinearGradient(
                colors: [
                    RisaTheme.accent(scheme),
                    RisaTheme.accentSecondary(scheme),
                    RisaTheme.accentGold(scheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .lcars:
            return LinearGradient(
                colors: [
                    RisaPalette.lcarsBluey,
                    RisaPalette.lcarsPeach,
                    RisaPalette.lcarsOrange,
                    RisaPalette.lcarsRoseblush
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .tos:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentGold(scheme)], startPoint: .top, endPoint: .bottom)
        case .ds9:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentSecondary(scheme)], startPoint: .top, endPoint: .bottom)
        case .voyager:
            return LinearGradient(colors: [RisaTheme.accent(scheme), RisaTheme.accentSecondary(scheme), RisaTheme.accentGold(scheme)], startPoint: .top, endPoint: .bottom)
        case .enterprise:
            return LinearGradient(colors: [RisaTheme.accentSecondary(scheme), RisaTheme.accent(scheme)], startPoint: .top, endPoint: .bottom)
        case .tng:
            let top = scheme == .dark ? RisaPalette.lcarsOrange : RisaPalette.lcarsLavender
            let bottom = scheme == .dark ? RisaPalette.lcarsPeach : RisaPalette.lcarsBlue
            return LinearGradient(
                colors: [top, bottom],
                startPoint: .top,
                endPoint: .bottom
            )
        case .starfleet:
            return LinearGradient(
                colors: [
                    RisaTheme.accentGold(scheme),
                    RisaTheme.accent(scheme),
                    RisaTheme.accentSecondary(scheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func lcarsPanelFill(_ scheme: ColorScheme) -> LinearGradient {
        let theme = RisaTheme.currentTheme
        let base = RisaTheme.cardBackground(scheme)
        let accentTint = RisaTheme.accentSoft(scheme).opacity(scheme == .dark ? 0.32 : 0.20)
        switch theme {
        case .lcars:
            let middle = scheme == .dark
                ? RisaPalette.lcarsPanelBlack
                : RisaPalette.lcarsVioletCreme.opacity(0.92)
            return LinearGradient(
                colors: [
                    base,
                    middle,
                    scheme == .dark ? RisaPalette.lcarsC51.opacity(0.86) : accentTint,
                    scheme == .dark ? RisaPalette.lcarsBluey.opacity(0.07) : RisaPalette.lcarsAfricanViolet.opacity(0.08),
                    scheme == .dark ? RisaPalette.lcarsOrange.opacity(0.05) : RisaPalette.lcarsPeach.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tng:
            let middle = scheme == .dark
                ? Color(red: 42/255, green: 22/255, blue: 40/255).opacity(0.92)
                : Color(red: 0.90, green: 0.82, blue: 0.77).opacity(0.94)
            return LinearGradient(colors: [base, middle, accentTint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tos:
            let glow = scheme == .dark
                ? RisaTheme.accentGold(scheme).opacity(0.18)
                : RisaTheme.accent(scheme).opacity(0.10)
            return LinearGradient(colors: [base, glow, Color.white.opacity(scheme == .dark ? 0.05 : 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ds9:
            let glow = scheme == .dark
                ? RisaTheme.accent(scheme).opacity(0.12)
                : RisaTheme.accentSecondary(scheme).opacity(0.08)
            return LinearGradient(colors: [base, glow, Color.black.opacity(scheme == .dark ? 0.14 : 0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .voyager:
            let glow = scheme == .dark
                ? RisaTheme.accentSecondary(scheme).opacity(0.16)
                : RisaTheme.accent(scheme).opacity(0.10)
            return LinearGradient(colors: [base, glow, Color.white.opacity(scheme == .dark ? 0.04 : 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .enterprise:
            let glow = scheme == .dark
                ? RisaTheme.accent(scheme).opacity(0.10)
                : RisaTheme.accentSecondary(scheme).opacity(0.07)
            return LinearGradient(colors: [base, glow, Color.white.opacity(scheme == .dark ? 0.03 : 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .starfleet:
            let glow = scheme == .dark
                ? RisaTheme.accentSecondary(scheme).opacity(0.18)
                : Color.white.opacity(0.18)
            let command = scheme == .dark
                ? RisaTheme.accentGold(scheme).opacity(0.14)
                : RisaTheme.accent(scheme).opacity(0.10)
            return LinearGradient(colors: [base, glow, command, accentTint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .risa:
            let glow = scheme == .dark
                ? RisaTheme.accentSecondary(scheme).opacity(0.18)
                : RisaTheme.accentGold(scheme).opacity(0.12)
            return LinearGradient(colors: [base, glow, accentTint], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Global UIKit Appearance

#if os(iOS)
enum AppUIAppearance {
    /// Call this once in your `@main` app initializer, e.g.:
    ///   AppUIAppearance.configure()
    static func configure() {
        configureNavigationBar()
        configureTabBar()
        configureToolbars()
    }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = RisaTheme.navBarBackgroundUIColor

        appearance.titleTextAttributes = [
            .foregroundColor: RisaTheme.navTitleUIColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        appearance.largeTitleTextAttributes = [
            .foregroundColor: RisaTheme.navTitleUIColor,
            .font: UIFont.systemFont(ofSize: 30, weight: .bold)
        ]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = RisaTheme.accentUIColor
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = RisaTheme.tabBarBackgroundUIColor

        // Configure item states properly
        let itemAppearance = appearance.stackedLayoutAppearance

        // Normal (unselected)
        itemAppearance.normal.iconColor = RisaTheme.tabIconInactiveUIColor
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: RisaTheme.tabLabelInactiveUIColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        // Selected
        itemAppearance.selected.iconColor = RisaTheme.tabIconActiveUIColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: RisaTheme.tabLabelActiveUIColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        // Reuse same look across layout variants
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = RisaTheme.accentUIColor
        tabBar.unselectedItemTintColor = RisaTheme.tabIconInactiveUIColor
    }

    private static func configureToolbars() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = RisaTheme.navBarBackgroundUIColor.withAlphaComponent(0.9)

        UIToolbar.appearance().standardAppearance = appearance
        UIToolbar.appearance().scrollEdgeAppearance = appearance
        UIToolbar.appearance().compactAppearance = appearance
        UIToolbar.appearance().tintColor = RisaTheme.accentUIColor
    }
}
#endif

// MARK: - View Helpers

extension View {
    /// Convenience nav bar style used in several Trek LI views.
    @ViewBuilder
    func tliNavBarStyle() -> some View {
        self.modifier(TLINavBarStyleModifier())
    }

    /// Legacy alias used in some views (`.risaNavBarStyle()`).
    @ViewBuilder
    func risaNavBarStyle() -> some View {
        self.tliNavBarStyle()
    }

    /// Simple glowing halo effect for headings.
    @ViewBuilder
    func risaTextHalo() -> some View {
        switch RisaTheme.currentTheme {
        case .lcars, .tng:
            self
                .shadow(color: RisaTheme.accentSecondary(.dark).opacity(0.22), radius: 4, x: 0, y: 0)
                .shadow(color: RisaTheme.accentGold(.dark).opacity(0.10), radius: 10, x: 0, y: 0)
        case .tos:
            self
                .shadow(color: RisaTheme.accentGold(.dark).opacity(0.18), radius: 4, x: 0, y: 0)
                .shadow(color: RisaTheme.accent(.dark).opacity(0.10), radius: 10, x: 0, y: 0)
        case .ds9:
            self
                .shadow(color: RisaTheme.accent(.dark).opacity(0.14), radius: 3, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 0)
        case .voyager:
            self
                .shadow(color: RisaTheme.accent(.dark).opacity(0.16), radius: 4, x: 0, y: 0)
                .shadow(color: RisaTheme.accentSecondary(.dark).opacity(0.10), radius: 9, x: 0, y: 0)
        case .enterprise:
            self
                .shadow(color: RisaTheme.accent(.dark).opacity(0.10), radius: 3, x: 0, y: 0)
                .shadow(color: Color.white.opacity(0.08), radius: 7, x: 0, y: 0)
        case .starfleet, .risa:
            self
                .shadow(color: Color.white.opacity(0.40), radius: 3, x: 0, y: 0)
                .shadow(color: Color.white.opacity(0.18), radius: 8, x: 0, y: 0)
        }
    }

    /// Warm “parchment” text color (legacy `.risaTextParchment()` helper).
    @ViewBuilder
    func risaTextParchment() -> some View {
        self
            .foregroundStyle(
                Color(red: 0.99, green: 0.94, blue: 0.82) // warm off-white
            )
    }
}

private struct TLINavBarStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(RisaTheme.navBarBackground(scheme), for: .navigationBar)
    }
}

// MARK: - LCARS Overlays

struct LCARSPanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                if RisaTheme.isLCARSThemeEnabled {
                    lcarsStackedRail
                        .padding(.vertical, 10)
                        .padding(.leading, 8)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(TLITheme.lcarsRailGradient(scheme))
                        .frame(width: 14)
                        .padding(.vertical, 12)
                        .padding(.leading, 8)
                }

                Spacer(minLength: 0)
            }

            if RisaTheme.isLCARSThemeEnabled {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("LCARS")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(TLITheme.textTertiary(scheme))

                        HStack(spacing: 4) {
                            lcarsMetadataBar(width: 68, color: RisaPalette.lcarsLavender)
                            lcarsMetadataBar(width: 18, color: RisaPalette.lcarsRoseblush)
                        }

                        HStack(spacing: 4) {
                            lcarsMetadataBar(width: 30, color: RisaPalette.lcarsBluey)
                            lcarsMetadataBar(width: 42, color: RisaPalette.lcarsGold)
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        lcarsMetadataBar(width: 24, color: RisaPalette.lcarsHoney)
                        lcarsMetadataBar(width: 52, color: RisaPalette.lcarsPeach)
                        lcarsMetadataBar(width: 34, color: RisaPalette.lcarsLavender)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 22)
                .opacity(0.96)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LCARS")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(TLITheme.textTertiary(scheme))

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(scheme == .dark ? RisaPalette.lcarsLavender : RisaPalette.lcarsOrange)
                        .frame(width: 76, height: 6)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(scheme == .dark ? RisaPalette.lcarsBlue : RisaPalette.lcarsPeach)
                        .frame(width: 46, height: 6)
                }
                .padding(.top, 12)
                .padding(.leading, 26)
                .opacity(0.95)
            }
        }
        .allowsHitTesting(false)
    }

    private var lcarsStackedRail: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RisaPalette.lcarsLavender)
                .frame(width: 16)

            VStack(spacing: 6) {
                Color.clear.frame(height: 12)
                railSegment(color: RisaPalette.lcarsBluey, height: 24)
                railSegment(color: RisaPalette.lcarsRoseblush, height: 38)
                railSegment(color: RisaPalette.lcarsGold, height: 22)
                railSegment(color: RisaPalette.lcarsOrange, height: 56)
                railSegment(color: RisaPalette.lcarsAfricanViolet, height: 28)
                Spacer(minLength: 10)
            }
            .frame(width: 8)
        }
        .frame(width: 16)
    }

    private func railSegment(color: Color, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .frame(width: 8, height: height)
    }

    private func lcarsMetadataBar(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .frame(width: width, height: 8)
    }
}

struct TOSPanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(RisaTheme.accent(.dark))
                    .frame(width: 10)
                    .padding(.vertical, 10)
                    .padding(.leading, 8)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    tosBar(width: 42, color: RisaTheme.accent(.dark))
                    tosBar(width: 28, color: RisaTheme.accentSecondary(.dark))
                    tosBar(width: 18, color: RisaTheme.accentGold(.dark))
                }
                .padding(.top, 10)
                .padding(.leading, 24)

                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    tosBar(width: 56, color: RisaTheme.accentGold(.dark))
                        .padding(.trailing, 18)
                        .padding(.bottom, 12)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func tosBar(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color.opacity(scheme == .dark ? 0.95 : 0.72))
            .frame(width: width, height: 6)
    }
}

struct DS9PanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.55 : 0.34))
                    .frame(width: 14)
                    .padding(.vertical, 12)
                    .padding(.leading, 10)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ds9Bar(width: 52)
                ds9Bar(width: 30)
            }
            .padding(.top, 12)
            .padding(.leading, 30)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ds9Bar(width: 24)
                        ds9Bar(width: 44)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 14)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func ds9Bar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(RisaTheme.accent(.dark).opacity(scheme == .dark ? 0.80 : 0.48))
            .frame(width: width, height: 6)
    }
}

struct VoyagerPanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            RisaTheme.accent(.dark).opacity(0.85),
                            RisaTheme.accentSecondary(.dark).opacity(0.75),
                            RisaTheme.accentGold(.dark).opacity(0.70)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14)
                .padding(.vertical, 12)
                .padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    voyagerBar(width: 46, color: RisaTheme.accent(.dark))
                    voyagerBar(width: 22, color: RisaTheme.accentGold(.dark))
                }
                HStack(spacing: 6) {
                    voyagerBar(width: 24, color: RisaTheme.accentSecondary(.dark))
                    voyagerBar(width: 36, color: RisaTheme.accent(.dark))
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.leading, 16)
        }
        .allowsHitTesting(false)
    }

    private func voyagerBar(width: CGFloat, color: Color) -> some View {
        Capsule(style: .continuous)
            .fill(color.opacity(scheme == .dark ? 0.85 : 0.55))
            .frame(width: width, height: 6)
    }
}

struct EnterprisePanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.42 : 0.28))
                    .frame(width: 8)
                    .padding(.vertical, 12)
                    .padding(.leading, 10)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 5) {
                enterpriseBar(width: 54)
                enterpriseBar(width: 38)
                enterpriseBar(width: 20)
            }
            .padding(.top, 12)
            .padding(.leading, 24)
        }
        .allowsHitTesting(false)
    }

    private func enterpriseBar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(RisaTheme.accent(scheme).opacity(scheme == .dark ? 0.54 : 0.34))
            .frame(width: width, height: 4)
    }
}

struct StarfleetPanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                Capsule(style: .continuous)
                    .fill(RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.90 : 0.68))
                    .frame(width: 44, height: 7)
                Capsule(style: .continuous)
                    .fill(RisaTheme.accent(scheme).opacity(scheme == .dark ? 0.86 : 0.68))
                    .frame(width: 58, height: 7)
                Capsule(style: .continuous)
                    .fill(RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.76 : 0.56))
                    .frame(width: 22, height: 7)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Capsule(style: .continuous)
                            .fill(RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.44 : 0.28))
                            .frame(width: 54, height: 5)
                        Capsule(style: .continuous)
                            .fill(RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.34 : 0.22))
                            .frame(width: 26, height: 5)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct RisaPanelDecoration: View {
    let scheme: ColorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(RisaTheme.accentGold(scheme).opacity(scheme == .dark ? 0.18 : 0.14))
                .frame(width: 42, height: 42)
                .padding(.top, 10)
                .padding(.trailing, 16)

            VStack {
                Spacer()
                HStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    RisaTheme.accent(scheme).opacity(scheme == .dark ? 0.80 : 0.60),
                                    RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.72 : 0.52)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 72, height: 8)
                        .padding(.leading, 16)
                    Spacer()
                }
                .padding(.bottom, 12)
            }
        }
        .allowsHitTesting(false)
    }
}

struct LCARSGridOverlay: View {
    let scheme: ColorScheme

    var body: some View {
        Canvas { context, size in
            let lineColor: Color
            switch (RisaTheme.currentTheme, scheme) {
            case (.tos, .dark):
                lineColor = RisaTheme.accentGold(scheme).opacity(0.12)
            case (.tng, .dark), (.lcars, .dark):
                lineColor = Color.white.opacity(0.10)
            case (.ds9, .dark):
                lineColor = RisaTheme.accent(scheme).opacity(0.08)
            case (.voyager, .dark):
                lineColor = RisaTheme.accent(scheme).opacity(0.10)
            case (.enterprise, .dark):
                lineColor = RisaTheme.accentSecondary(scheme).opacity(0.07)
            case (.starfleet, .dark):
                lineColor = Color.white.opacity(0.08)
            case (.risa, .dark):
                lineColor = RisaTheme.accentSecondary(scheme).opacity(0.06)
            case (.tos, .light):
                lineColor = RisaTheme.accent(scheme).opacity(0.05)
            case (.tng, .light), (.lcars, .light):
                lineColor = Color.black.opacity(0.06)
            case (.ds9, .light):
                lineColor = RisaTheme.accentSecondary(scheme).opacity(0.05)
            case (.voyager, .light):
                lineColor = RisaTheme.accent(scheme).opacity(0.05)
            case (.enterprise, .light):
                lineColor = RisaTheme.accentSecondary(scheme).opacity(0.04)
            case (.starfleet, .light):
                lineColor = Color.black.opacity(0.05)
            case (.risa, .light):
                lineColor = RisaTheme.accentSecondary(scheme).opacity(0.03)
            @unknown default:
                lineColor = scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
            }

            var path = Path()
            let verticalStep: CGFloat = 72
            let horizontalStep: CGFloat = 56

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += verticalStep
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += horizontalStep
            }

            context.stroke(path, with: .color(lineColor), lineWidth: 1)
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

struct LCARSWallpaperOverlay: View {
    let scheme: ColorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Image("LCARSBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width * (scheme == .dark ? 1.18 : 1.10),
                        height: proxy.size.height * 1.02
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .clipped()
                    .saturation(scheme == .dark ? 0.86 : 0.48)
                    .contrast(scheme == .dark ? 1.02 : 0.90)
                    .brightness(scheme == .dark ? -0.08 : 0.01)
                    .opacity(scheme == .dark ? 0.14 : 0.08)
                    .blendMode(scheme == .dark ? .screen : .multiply)
                    .mask(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(scheme == .dark ? 1.0 : 0.85),
                                Color.black.opacity(scheme == .dark ? 0.50 : 0.28),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                LinearGradient(
                    colors: [
                        RisaPalette.lcarsOrange.opacity(scheme == .dark ? 0.12 : 0.08),
                        RisaPalette.lcarsBluey.opacity(scheme == .dark ? 0.08 : 0.05),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)

                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RisaPalette.lcarsBluey)
                            .frame(width: min(proxy.size.width * 0.18, 132), height: 12)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RisaPalette.lcarsOrange)
                            .frame(width: min(proxy.size.width * 0.09, 72), height: 12)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RisaPalette.lcarsAfricanViolet)
                            .frame(width: min(proxy.size.width * 0.16, 124), height: 12)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 24)
                    .padding(.leading, 112)

                    Spacer(minLength: 0)
                }
                .opacity(scheme == .dark ? 0.26 : 0.14)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

struct StarfieldOverlay: View {
    let scheme: ColorScheme

    private func fract(_ value: Double) -> Double {
        value - floor(value)
    }

    var body: some View {
        Canvas { context, size in
            let starColor: Color
            let totalStars: Int
            switch (RisaTheme.currentTheme, scheme) {
            case (.tos, .dark):
                starColor = RisaTheme.accentGold(scheme)
                totalStars = 48
            case (.tng, .dark):
                starColor = Color.white
                totalStars = 72
            case (.ds9, .dark):
                starColor = Color(red: 0.92, green: 0.80, blue: 0.64)
                totalStars = 34
            case (.voyager, .dark):
                starColor = Color(red: 0.86, green: 0.96, blue: 1.00)
                totalStars = 104
            case (.enterprise, .dark):
                starColor = Color(red: 0.82, green: 0.88, blue: 0.92)
                totalStars = 28
            case (.starfleet, .dark):
                starColor = Color.white
                totalStars = 78
            case (.lcars, .dark):
                starColor = Color.white
                totalStars = 90
            case (.risa, .dark):
                starColor = RisaTheme.accentGold(scheme)
                totalStars = 18
            case (.tos, .light):
                starColor = RisaTheme.accent(scheme)
                totalStars = 20
            case (.tng, .light), (.lcars, .light):
                starColor = Color.black
                totalStars = 52
            case (.ds9, .light):
                starColor = RisaTheme.accent(scheme)
                totalStars = 18
            case (.voyager, .light):
                starColor = RisaTheme.accent(scheme)
                totalStars = 34
            case (.enterprise, .light):
                starColor = RisaTheme.accentSecondary(scheme)
                totalStars = 16
            case (.starfleet, .light):
                starColor = Color.black
                totalStars = 30
            case (.risa, .light):
                starColor = RisaTheme.accentGold(scheme)
                totalStars = 8
            @unknown default:
                starColor = scheme == .dark ? Color.white : Color.black
                totalStars = scheme == .dark ? 72 : 40
            }

            for index in 0..<totalStars {
                let seed = Double(index) + 1.0
                let x = fract(sin(seed * 12.9898) * 43758.5453) * size.width
                let y = fract(sin(seed * 78.233) * 24634.6345) * size.height
                let sizeSeed = fract(sin(seed * 44.123) * 12741.371)
                let radius = CGFloat(0.45 + sizeSeed * (scheme == .dark ? 1.55 : 1.10))
                let alpha = 0.12 + sizeSeed * (scheme == .dark ? 0.34 : 0.20)
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(starColor.opacity(alpha)))
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}
