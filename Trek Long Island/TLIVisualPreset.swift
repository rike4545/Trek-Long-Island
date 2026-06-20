import SwiftUI

enum TLIVisualPreset: String, CaseIterable, Identifiable {
    case tos
    case tng
    case ds9
    case voyager
    case enterprise
    case starfleet
    case lcars
    case risa

    var id: String { rawValue }

    static var defaultPreset: TLIVisualPreset { .starfleet }
    static var supportedPresets: [TLIVisualPreset] { [.starfleet, .lcars, .risa] }

    static func fromStoredRawValue(_ rawValue: String?) -> TLIVisualPreset {
        switch rawValue?.lowercased() {
        case "lcars":
            .lcars
        case "risa":
            .risa
        case "tos", "tng", "ds9", "voyager", "enterprise", "starfleet":
            .starfleet
        default:
            .defaultPreset
        }
    }

    enum Group: String {
        case series
        case federation
    }

    var group: Group {
        switch self {
        case .tos, .tng, .ds9, .voyager, .enterprise:
            .series
        case .starfleet, .lcars, .risa:
            .federation
        }
    }

    var title: String {
        switch self {
        case .tos: "The Original Series"
        case .tng: "The Next Generation"
        case .ds9: "Deep Space Nine"
        case .voyager: "Voyager"
        case .enterprise: "Enterprise NX-01"
        case .starfleet: "Federation Command"
        case .lcars: "LCARS Ops"
        case .risa: "Risa"
        }
    }

    var shortLabel: String {
        switch self {
        case .tos: "TOS"
        case .tng: "TNG"
        case .ds9: "DS9"
        case .voyager: "Voyager"
        case .enterprise: "Enterprise"
        case .starfleet: "Command"
        case .lcars: "LCARS"
        case .risa: "Risa"
        }
    }

    var description: String {
        switch self {
        case .tos:
            "Bold bridge primaries, dramatic contrast, and the classic feel of a 2260s command deck."
        case .tng:
            "Soft Enterprise-D warmth with polished console tones and late-24th-century confidence."
        case .ds9:
            "Station-side bronze, gunmetal structure, and a tougher frontier mood."
        case .voyager:
            "Cooler shipboard lighting, blue instrumentation, and long-range mission energy."
        case .enterprise:
            "Steel framing, blue readouts, and the practical feel of early deep-space exploration."
        case .starfleet:
            "A cinematic bridge look with deep console tones, command red, and blue instrumentation glow."
        case .lcars:
            "Black-backed LCARS with signal-green title glow, blue shadow, and wide rounded category rails."
        case .risa:
            "Teal skies, electric lime fields, hot-pink sun discs, and coral rails inspired by the 2026 promo art."
        }
    }

    var theme: TLIColorTheme {
        switch self {
        case .tos: .tos
        case .tng: .tng
        case .ds9: .ds9
        case .voyager: .voyager
        case .enterprise: .enterprise
        case .starfleet: .starfleet
        case .lcars: .lcars
        case .risa: .risa
        }
    }

    var appearance: AppAppearance {
        switch self {
        case .tos, .tng, .ds9, .voyager, .enterprise, .lcars:
            .dark
        case .starfleet:
            .system
        case .risa:
            .light
        }
    }

    static func resolve(theme: TLIColorTheme, appearance: AppAppearance) -> TLIVisualPreset {
        switch theme {
        case .starfleet, .tos, .tng, .ds9, .voyager, .enterprise:
            .starfleet
        case .lcars:
            .lcars
        case .risa: .risa
        }
    }
}
