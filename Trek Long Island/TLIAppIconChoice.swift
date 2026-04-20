import Foundation

enum TLIAppIconChoice: String, CaseIterable, Identifiable {
    case appIcon = "AppIcon" // default (nil for UIApplication)
    case risa = "Risa"
    case risaSunset = "RisaSunset"
    case trekLongIsland2024 = "TrekLongIsland2024"
    case goKindly = "GoKindly"
    case libraryforKind = "LibraryforKind"
    case paws = "Paws"
    case trekRealLong = "TrekRealLong"
    case starDelta = "StarDelta"
    case trekLongIslandLogo = "TrekLongIslandLogo"

    static let storageKey = "tli.selectedAppIcon"
    static let pickerChoices: [TLIAppIconChoice] = [
        .appIcon,
        .risaSunset,
        .trekLongIsland2024,
        .trekRealLong,
        .starDelta,
        .goKindly,
        .libraryforKind
    ]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appIcon: return "Trek Long Island Logo"
        case .risa: return "Risa Badge"
        case .risaSunset: return "Risa Sunset"
        case .trekLongIsland2024: return "Book Rocket"
        case .goKindly: return "Go Kindly"
        case .libraryforKind: return "Library for the Kind"
        case .paws: return "Paws"
        case .trekRealLong: return "Delta Voyage"
        case .starDelta: return "Delta"
        case .trekLongIslandLogo: return "Trek Long Island Logo"
        }
    }

    var isDeprecatedChoice: Bool {
        switch self {
        case .risa, .paws, .trekLongIslandLogo:
            return true
        default:
            return false
        }
    }

    var preferredChoice: TLIAppIconChoice {
        isDeprecatedChoice ? .appIcon : self
    }

    var alternateIconName: String? {
        self == .appIcon ? nil : self.rawValue
    }

    var brandAssetName: String {
        switch preferredChoice {
        case .appIcon: return "Trek Long Island Logo"
        case .risa: return "BrandMarkRisa"
        case .risaSunset: return "BrandMarkRisaSunset"
        case .trekLongIsland2024: return "BrandMarkTrekLongIsland2024"
        case .goKindly: return "BrandMarkGoKindly"
        case .libraryforKind: return "BrandMarkLibraryforKind"
        case .paws: return "BrandMarkPaws"
        case .trekRealLong: return "BrandMarkTrekRealLong"
        case .starDelta: return "BrandMarkAppIcon"
        case .trekLongIslandLogo: return "Trek Long Island Logo"
        }
    }

    static func fromSystemAlternateIconName(_ name: String?) -> TLIAppIconChoice {
        guard let name else { return .appIcon }
        return TLIAppIconChoice(rawValue: name) ?? .appIcon
    }
}
