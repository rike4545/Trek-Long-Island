import SwiftUI

enum TLIBrandIdentity {
    static let appBadge = "OFFICIAL CONVENTION GUIDE"
    static let heroTitle = "Trek Long Island"
    static let heroTagline = "Your pocket command deck for the convention weekend."
    static let heroSupport = "Built for fast schedule pivots, clear wayfinding, and a more inclusive convention experience."
    static let rallyingCall = "Navigate boldly. Stay on mission. Keep the crew together."

    static func crestGradient(_ scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                TLITheme.accent(scheme),
                RisaTheme.accentSecondary(scheme),
                RisaTheme.accentGold(scheme)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func haloGradient(_ scheme: ColorScheme) -> RadialGradient {
        RadialGradient(
            colors: [
                RisaTheme.accentSecondary(scheme).opacity(scheme == .dark ? 0.36 : 0.22),
                TLITheme.accent(scheme).opacity(scheme == .dark ? 0.18 : 0.12),
                .clear
            ],
            center: .center,
            startRadius: 8,
            endRadius: 130
        )
    }

    static func panelGradient(_ scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.98 : 0.96),
                TLITheme.accentSoft(scheme).opacity(scheme == .dark ? 0.24 : 0.14),
                TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.94 : 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct TLIBrandHeader: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(TLIAppIconChoice.storageKey) private var selectedAppIconRaw: String = TLIAppIconChoice.appIcon.rawValue

    let title: String
    let subtitle: String
    let supportingText: String?
    let compact: Bool

    init(
        title: String = TLIBrandIdentity.heroTitle,
        subtitle: String = TLIBrandIdentity.heroTagline,
        supportingText: String? = TLIBrandIdentity.heroSupport,
        compact: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.supportingText = supportingText
        self.compact = compact
    }

    var body: some View {
        Group {
            if compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(compact ? 16 : 18)
        .background(backgroundPanel)
        .accessibilityElement(children: .combine)
    }

    private var selectedAppIconChoice: TLIAppIconChoice {
        (TLIAppIconChoice(rawValue: selectedAppIconRaw) ?? .appIcon).preferredChoice
    }

    private var regularLayout: some View {
        HStack(alignment: .center, spacing: 18) {
            brandMark(tileSize: 104, imageSize: 84)

            VStack(alignment: .leading, spacing: 8) {
                badgeLabel

                Text(title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                textStack(subtitleFont: .headline.weight(.semibold), supportFont: .subheadline)
            }

            Spacer(minLength: 0)
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                badgeLabel
                Spacer(minLength: 10)
                brandMark(tileSize: 82, imageSize: 64)
            }

            Text(title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            textStack(
                subtitleFont: .system(.title3, design: .rounded).weight(.bold),
                supportFont: .footnote
            )
        }
    }

    private var badgeLabel: some View {
        Text(TLIBrandIdentity.appBadge)
            .font(.caption2.weight(.heavy))
            .tracking(1.4)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.72 : 0.78))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(TLITheme.border(scheme).opacity(0.22), lineWidth: TLITheme.hairline)
            )
            .accessibilityAddTraits(.isHeader)
    }

    private func textStack(subtitleFont: Font, supportFont: Font) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 6) {
            Text(subtitle)
                .font(subtitleFont)
                .foregroundStyle(TLITheme.accent(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let supportingText, !supportingText.isEmpty {
                Text(supportingText)
                    .font(supportFont)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func brandMark(tileSize: CGFloat, imageSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: tileSize * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.16, blue: 0.28).opacity(scheme == .dark ? 0.96 : 0.92),
                            Color(red: 0.06, green: 0.09, blue: 0.18).opacity(scheme == .dark ? 0.98 : 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: tileSize * 0.28, style: .continuous)
                        .stroke(TLIBrandIdentity.crestGradient(scheme).opacity(scheme == .dark ? 0.56 : 0.34), lineWidth: 1.2)
                )
                .shadow(
                    color: TLITheme.cardShadowColor(scheme).opacity(scheme == .dark ? 0.24 : 0.12),
                    radius: compact ? 10 : 14,
                    x: 0,
                    y: compact ? 6 : 8
                )
                .frame(width: tileSize, height: tileSize)

            RoundedRectangle(cornerRadius: tileSize * 0.24, style: .continuous)
                .fill(TLIBrandIdentity.haloGradient(scheme))
                .padding(tileSize * 0.08)
                .frame(width: tileSize, height: tileSize)

            Image(selectedAppIconChoice.brandAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .shadow(
                    color: Color.black.opacity(scheme == .dark ? 0.30 : 0.14),
                    radius: compact ? 6 : 10,
                    x: 0,
                    y: compact ? 4 : 6
                )
        }
        .accessibilityHidden(true)
    }

    private var backgroundPanel: some View {
        RoundedRectangle(cornerRadius: compact ? 24 : 28, style: .continuous)
            .fill(TLIBrandIdentity.panelGradient(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 24 : 28, style: .continuous)
                    .stroke(TLIBrandIdentity.crestGradient(scheme).opacity(scheme == .dark ? 0.50 : 0.28), lineWidth: 1.1)
            )
            .shadow(
                color: TLITheme.cardShadowColor(scheme).opacity(scheme == .dark ? 0.22 : 0.08),
                radius: compact ? 10 : 14,
                x: 0,
                y: compact ? 4 : 8
            )
    }
}
