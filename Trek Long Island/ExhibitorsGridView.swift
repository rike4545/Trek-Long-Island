// Copyright Bryan Carroll. All rights reserved.
//
//  ExhibitorsGridView.swift
//  Trek Long Island
//
//  Exhibitor grid used by ExhibitorListView / Explore.
//  - Search-aware
//  - 2-column adaptive grid
//  - TLI glass cards, dark-mode friendly
//  - Tappable cards open exhibitor website via openURL
//
//  CHANGES vs previous revision:
//  - Added `websiteURL: URL?` to Exhibitor model
//  - ExhibitorCard wrapped in Button/openURL so tap opens the website
//  - Image container clipped inside card boundary (fixes overlap bug)
//  - Increased grid spacing from 14 → 16 for breathing room
//  - Card image height reduced from 120 → 110 and pinned inside
//    a fixed-height ZStack so the card never bleeds into neighbors
//  - Added a subtle "tap to visit" affordance (arrow.up.right badge)
//  - LCARS chrome moved OUTSIDE the card clip region (was inside,
//    causing the top chrome strip to render above adjacent cards)
//

import SwiftUI

struct ExhibitorsGridView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Binding var searchText: String

    // MARK: - Model

    struct Exhibitor: Identifiable, Hashable {
        let name: String
        let imageName: String?      // optional exhibitor logo / table photo
        let blurb: String?
        let websiteURL: URL?        // ← NEW: tapping the card opens this URL

        var id: String { name }     // name is unique per roster; avoids UUID churn
    }

    /// Current 2026 exhibitor roster published on the Trek Long Island vendor page.
    var exhibitors: [Exhibitor] = .trekLongIsland2026

    private var columns: [GridItem] {
        TLILayout.adaptiveColumns(
            for: hSizeClass,
            compactMinimum: 150,
            regularMinimum: 220,
            regularMaximum: 320,
            spacing: 16          // was 14
        )
    }

    // MARK: - Derived

    private var filteredExhibitors: [Exhibitor] {
        guard !exhibitors.isEmpty else { return [] }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return exhibitors }

        return exhibitors.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            ($0.blurb ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            header

            if exhibitors.isEmpty {
                emptyStateNoData
                    .padding(.top, 24)
            } else if filteredExhibitors.isEmpty {
                emptyStateNoMatches
                    .padding(.top, 24)
            } else {
                LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                    ForEach(filteredExhibitors) { exhibitor in
                        ExhibitorCard(exhibitor: exhibitor, scheme: scheme)
                    }
                }
                .adaptiveContentWidth(
                    maxWidth: 1120,
                    horizontalPadding: 16,
                    verticalPadding: 0
                )
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TLILCARSLabel.exhibitors)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                if exhibitors.isEmpty {
                    Text(RisaTheme.isLCARSThemeEnabled
                         ? "Registry entries will be published closer to the event."
                         : "Exhibitors will be announced closer to the event.")
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                } else {
                    Text(RisaTheme.isLCARSThemeEnabled
                         ? "\(filteredExhibitors.count) registry entr\(filteredExhibitors.count == 1 ? "y" : "ies") showing"
                         : "\(filteredExhibitors.count) exhibitor\(filteredExhibitors.count == 1 ? "" : "s") showing")
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var emptyStateNoData: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .imageScale(.large)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text("No exhibitors listed yet.")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text("Check back as we get closer to the convention for our full exhibitor lineup.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var emptyStateNoMatches: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.magnifyingglass")
                .imageScale(.large)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text("No exhibitors match your search.")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text("Try a different name or clear your filters.")
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - Card
//
// KEY FIX: The image is now clipped inside a fixed-height container that lives
// INSIDE the card's padding/clip region.  Previously the image used
// `.frame(maxWidth: .infinity)` with no explicit clip on the outer ZStack,
// so `scaledToFill` content bled outside the RoundedRectangle on all four
// sides and rendered on top of neighboring cards in the LazyVGrid.
//
// The card is now a Button so tapping it opens the exhibitor's website.

private struct ExhibitorCard: View {
    @Environment(\.openURL) private var openURL

    let exhibitor: ExhibitorsGridView.Exhibitor
    let scheme: ColorScheme

    var body: some View {
        Button {
            if let url = exhibitor.websiteURL {
                openURL(url)
            }
        } label: {
            cardContent
        }
        .buttonStyle(ExhibitorPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(exhibitor.websiteURL != nil ? "Double tap to visit website" : "")
    }

    // MARK: Card layout

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Image / placeholder ──────────────────────────────────────
            // Fixed-height container + explicit .clipped() so fill
            // images never escape the card boundary.
            ZStack {
                if let imageName = exhibitor.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [
                            TLITheme.accent(scheme).opacity(0.45),
                            TLITheme.accent(scheme).opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "bag.fill")
                            .imageScale(.large)
                            .foregroundStyle(.white.opacity(0.9))
                    )
                }

                // ── "Visit website" badge (only when URL exists) ─────────
                if exhibitor.websiteURL != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // ── Text ─────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 5) {
                Text(exhibitor.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                if let blurb = exhibitor.blurb, !blurb.isEmpty {
                    Text(blurb)
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Card chrome — applied AFTER the image so it clips the whole card
        .frame(maxWidth: .infinity, alignment: .leading)
        .tliCard()
        // contentShape ensures the full card (including image) is tappable
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var accessibilityLabel: String {
        var parts = [exhibitor.name]
        if let blurb = exhibitor.blurb, !blurb.isEmpty { parts.append(blurb) }
        if exhibitor.websiteURL != nil { parts.append("Has website.") }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Press animation button style

private struct ExhibitorPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TLITheme.backgroundGradient(.dark)
        ScrollView {
            ExhibitorsGridView(searchText: .constant(""))
                .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - 2026 Roster

extension Array where Element == ExhibitorsGridView.Exhibitor {
    static let trekLongIsland2026: [ExhibitorsGridView.Exhibitor] = [
        .init(
            name: "Trekatecture",
            imageName: "Vendor2026Trekatecture",
            blurb: "Architecture, model work, and Trek-inspired design.",
            websiteURL: nil   // add URL when available
        ),
        .init(
            name: "Heroes in Action",
            imageName: "Vendor2026HeroesInAction",
            blurb: "Sci-fi and superhero collectibles.",
            websiteURL: URL(string: "https://www.heroesinaction.com")
        ),
        .init(
            name: "IDW Comics & Entertainment",
            imageName: "Vendor2026IDW",
            blurb: "Comics, entertainment, and licensed fandom titles.",
            websiteURL: URL(string: "https://www.idwpublishing.com")
        ),
        .init(
            name: "3D Infinity DC",
            imageName: "Vendor2026InfinityDC",
            blurb: "3D printed fandom and convention pieces.",
            websiteURL: nil
        ),
        .init(
            name: "Castle Books",
            imageName: "Vendor2026CastleBooks",
            blurb: "Books and royal-experience themed finds.",
            websiteURL: nil
        ),
        .init(
            name: "Pendragon Costumes",
            imageName: "Vendor2026Pendragon",
            blurb: "Costume and cosplay pieces.",
            websiteURL: nil
        ),
        .init(
            name: "Spectral Sugarfang",
            imageName: "Vendor2026SpectralSugarfang",
            blurb: "Artist goods and fantasy-inspired creations.",
            websiteURL: nil
        ),
        .init(
            name: "Miss Misery Comics",
            imageName: "Vendor2026MissMisery",
            blurb: "Comics and original art.",
            websiteURL: nil
        ),
        .init(
            name: "The Lemon Life",
            imageName: "Vendor2026LemonLife",
            blurb: "Fresh shaken lemonade.",
            websiteURL: nil
        ),
        .init(
            name: "Links and Leather",
            imageName: "Vendor2026LinksAndLeather",
            blurb: "Chainmaille and leather accessories.",
            websiteURL: nil
        ),
        .init(
            name: "Folded Flight",
            imageName: "Vendor2026FoldedFlight",
            blurb: "Paper-airplane and flight-themed creations.",
            websiteURL: nil
        ),
        .init(
            name: "Sweet Mouth Jamaican Food Pastries and Tings",
            imageName: "Vendor2026SweetMouthJamaican",
            blurb: "Authentic Jamaican and international cuisine.",
            websiteURL: nil
        ),
        .init(
            name: "Howudogin'",
            imageName: "Vendor2026Howudogin",
            blurb: "Classic melts and gourmet food.",
            websiteURL: nil
        ),
        .init(
            name: "Moonlight and Mauazo",
            imageName: "Vendor2026MoonlightMauazo",
            blurb: "Artist and vendor goods.",
            websiteURL: nil
        ),
        .init(
            name: "Magical Anthony",
            imageName: "Vendor2026MagicalAnthony",
            blurb: "Magic and character art.",
            websiteURL: nil
        ),
        .init(
            name: "Freddie Comics",
            imageName: "Vendor2026FreddieComics",
            blurb: "Comics and illustrated goods.",
            websiteURL: nil
        )
    ]
}
