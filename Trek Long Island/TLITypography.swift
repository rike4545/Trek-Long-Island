import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TLIAppBranding {
    static let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Trek Long Island"
    static let shortAppName = "Trek Long Island"
}

enum TLIAppFeatureFlags {
    private static func boolValue(for key: String) -> Bool {
        Bundle.main.object(forInfoDictionaryKey: key) as? Bool ?? false
    }

    static let areAdsDisabled = boolValue(for: "TLI_ADS_DISABLED")
    static let isCustomSplashDisabled = boolValue(for: "TLI_DISABLE_CUSTOM_SPLASH")
    static let isWelcomePopupDisabled = boolValue(for: "TLI_DISABLE_WELCOME_POPUP")
}

enum TLITypographyPreference: String, CaseIterable, Identifiable {
    static let storageKey = "TLI.Accessibility.typography"
    static let defaultPreference: TLITypographyPreference = .roundedSystem

    case roundedSystem
    case systemSans
    case atkinsonHyperlegible

    var id: String { rawValue }

    static func fromStoredRawValue(_ rawValue: String?) -> TLITypographyPreference {
        guard let rawValue, let preference = TLITypographyPreference(rawValue: rawValue) else {
            return .defaultPreference
        }
        return preference
    }

    var title: String {
        switch self {
        case .roundedSystem:
            return "Rounded System"
        case .systemSans:
            return "System Sans"
        case .atkinsonHyperlegible:
            return "Atkinson Hyperlegible"
        }
    }

    var subtitle: String {
        switch self {
        case .roundedSystem:
            return "Friendly default with rounded SF styling."
        case .systemSans:
            return "Standard iOS system typography."
        case .atkinsonHyperlegible:
            return "Open licensed accessibility-focused font."
        }
    }

    var bodyFont: Font {
        switch self {
        case .roundedSystem:
            return .system(.body, design: .rounded)
        case .systemSans:
            return .system(.body, design: .default)
        case .atkinsonHyperlegible:
            return .custom("AtkinsonHyperlegible-Regular", size: 17, relativeTo: .body)
        }
    }

    func font(
        _ textStyle: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design? = nil
    ) -> Font {
        switch self {
        case .roundedSystem:
            return .system(textStyle, design: design ?? .rounded).weight(weight)
        case .systemSans:
            return .system(textStyle, design: design ?? .default).weight(weight)
        case .atkinsonHyperlegible:
            return .custom(fontName(for: weight), size: pointSize(for: textStyle), relativeTo: textStyle)
        }
    }

    func font(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body,
        design: Font.Design? = nil
    ) -> Font {
        switch self {
        case .roundedSystem:
            return .system(size: size, weight: swiftUIWeight(weight), design: design ?? .rounded)
        case .systemSans:
            return .system(size: size, weight: swiftUIWeight(weight), design: design ?? .default)
        case .atkinsonHyperlegible:
            return .custom(fontName(for: weight), size: size, relativeTo: textStyle)
        }
    }

    #if canImport(UIKit)
    func uiFont(
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        design: UIFontDescriptor.SystemDesign? = nil
    ) -> UIFont {
        switch self {
        case .roundedSystem:
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let descriptor = base.fontDescriptor.withDesign(design ?? .rounded) ?? base.fontDescriptor
            return UIFont(descriptor: descriptor, size: size)
        case .systemSans:
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .atkinsonHyperlegible:
            return UIFont(name: uiFontName(for: weight), size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
    #endif

    private func fontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black, .semibold:
            return "AtkinsonHyperlegible-Bold"
        default:
            return "AtkinsonHyperlegible-Regular"
        }
    }

    #if canImport(UIKit)
    private func uiFontName(for weight: UIFont.Weight) -> String {
        weight.rawValue >= UIFont.Weight.semibold.rawValue ? "AtkinsonHyperlegible-Bold" : "AtkinsonHyperlegible-Regular"
    }
    #endif

    private func pointSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }

    private func swiftUIWeight(_ weight: Font.Weight) -> Font.Weight {
        weight
    }
}

private struct TLITypographyModifier: ViewModifier {
    let preference: TLITypographyPreference

    func body(content: Content) -> some View {
        content
            .font(preference.bodyFont)
            .lineSpacing(2)
    }
}

extension View {
    func tliAppTypography(_ preference: TLITypographyPreference) -> some View {
        modifier(TLITypographyModifier(preference: preference))
    }
}
