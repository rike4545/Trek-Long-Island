import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

@MainActor
struct StarTrekCostumeGuideView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    @State private var safariItem: CostumeGuideSafariItem?

    private struct GuideLink: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let url: URL
        let accent: Color
    }

    private struct EraGuide: Identifiable {
        let id = UUID()
        let era: String
        let summary: String
        let destination: URL
        let accent: Color
    }

    private let homeURL = URL(string: "https://startrekcostumeguide.com/")!
    private let resourcesURL = URL(string: "https://startrekcostumeguide.com/resources/")!
    private let patternsURL = URL(string: "https://startrekcostumeguide.com/sewing-patterns/")!
    private let youtubeURL = URL(string: "https://www.youtube.com/@obsessivecostumingdude")!

    private let supplierLinks: [GuideLink] = [
        .init(
            title: "Star Trek on Amazon",
            subtitle: "Existing app affiliate link for books, references, and starter supplies.",
            icon: "cart.fill",
            url: URL(string: "https://amzn.to/3OI8pdH")!,
            accent: .orange
        ),
        .init(
            title: "Autograph Sheet Protectors",
            subtitle: "Existing Amazon affiliate link for convention-safe document sleeves and storage.",
            icon: "rectangle.stack.badge.plus",
            url: URL(string: "https://amzn.to/45RMt5y")!,
            accent: .blue
        ),
        .init(
            title: "Volante Design",
            subtitle: "Browse jackets and layers that pair well with Trek-inspired outfits. Discount code: JAKRU6511",
            icon: "sparkles.tv",
            url: URL(string: "https://www.volantedesign.us/collections/master-collection")!,
            accent: .yellow
        )
    ]

    private let eraGuides: [EraGuide] = [
        .init(
            era: "TMP",
            summary: "Motion Picture-era uniforms, Class D jumpsuits, and Fletcher-era reference work.",
            destination: URL(string: "https://startrekcostumeguide.com/tmp-era-starfleet-uniforms/")!,
            accent: .mint
        ),
        .init(
            era: "TWOK",
            summary: "Monster maroons, movie-era jumpsuits, radiation suits, and fabric color matching.",
            destination: URL(string: "https://startrekcostumeguide.com/twok-era-starfleet-uniforms/")!,
            accent: .red
        ),
        .init(
            era: "TNG",
            summary: "Jumpsuits, skants, admiral jackets, medical smocks, and deep season-by-season analysis.",
            destination: URL(string: "https://startrekcostumeguide.com/tng-era-starfleet-uniforms/")!,
            accent: .blue
        ),
        .init(
            era: "DS9 / NEM",
            summary: "Late-24th-century greys, First Contact-era structure, and station-to-film refinements.",
            destination: URL(string: "https://startrekcostumeguide.com/ds9-nem-era-starfleet-uniforms/")!,
            accent: .indigo
        ),
        .init(
            era: "VOY",
            summary: "Voyager-era variants and field-uniform reference points.",
            destination: URL(string: "https://startrekcostumeguide.com/voy-era-starfleet-uniforms/")!,
            accent: .teal
        ),
        .init(
            era: "ENT",
            summary: "NX-era utility uniforms and early-Starfleet construction cues.",
            destination: URL(string: "https://startrekcostumeguide.com/ent-era-starfleet-uniforms/")!,
            accent: .cyan
        )
    ]

    private var starterLinks: [GuideLink] {
        [
            .init(
                title: "Open the main guide",
                subtitle: "Browse the latest articles, costume essays, and sewing updates from the site.",
                icon: "globe",
                url: homeURL,
                accent: RisaTheme.accent(scheme)
            ),
            .init(
                title: "Free sewing patterns",
                subtitle: "The site includes free downloads for select TNG and movie-era builds, plus Tailors Gone Wild pattern links.",
                icon: "scissors",
                url: patternsURL,
                accent: RisaTheme.accentSecondary(scheme)
            ),
            .init(
                title: "Resources and research",
                subtitle: "Use the guide’s research pages to compare screen-used details, materials, and construction notes.",
                icon: "books.vertical.fill",
                url: resourcesURL,
                accent: RisaTheme.accentGold(scheme)
            ),
            .init(
                title: "Watch the walkthroughs",
                subtitle: "Video walkthroughs help with pattern prep, fitting, and movie/TNG build decisions.",
                icon: "play.rectangle.fill",
                url: youtubeURL,
                accent: .pink
            )
        ]
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    starterSection
                    eraSection
                    supplierSection
                    footerNote
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: 18,
                    verticalPadding: 14
                )
            }
        }
        .navigationTitle(RisaTheme.isLCARSThemeEnabled ? "Costume Database" : "Cosplay Guide")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: homeURL)
                Button {
                    presentSafari(homeURL)
                } label: {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open costume guide")
            }
        }
        #if canImport(SafariServices)
        .sheet(item: $safariItem) { item in
            CostumeGuideSafariSheet(url: item.url)
                .ignoresSafeArea()
        }
        #endif
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(TLITheme.accentSoft(scheme))
                        .frame(width: 56, height: 56)

                    Image(systemName: "theatermasks.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(RisaTheme.isLCARSThemeEnabled ? "Starfleet Costume Archive" : "Star Trek Costume Guide")
                        .font(
                            RisaTheme.isLCARSThemeEnabled
                                ? .system(size: 26, weight: .black, design: .monospaced)
                                : .title2.weight(.bold)
                        )
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text("A research-first companion for building or improving your Trek cosplay.")
                        .font(.subheadline)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
            }

            Text("Use it for costume analysis, sewing tutorials, free pattern downloads, materials research, and era-by-era reference hunting. The site is especially strong if you care about screen-used details and fit accuracy.")
                .font(.body)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            HStack(spacing: 10) {
                Button {
                    presentSafari(homeURL)
                } label: {
                    Label("Open guide", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    openURL(homeURL)
                } label: {
                    Label("Safari", systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .tliCard()
    }

    private var starterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Start Here", detail: "Best first stops for planning a build.")
            ForEach(starterLinks) { link in
                resourceCard(link)
            }
        }
    }

    private var eraSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("By Era", detail: "Jump straight to the uniform family you want to build.")

            LazyVGrid(columns: TLILayout.columns(for: .compact, minTileWidth: 220, spacing: 12), spacing: 12) {
                ForEach(eraGuides) { era in
                    Button {
                        presentSafari(era.destination)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(era.era)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(TLITheme.textPrimary(scheme))
                                Spacer(minLength: 8)
                                Circle()
                                    .fill(era.accent)
                                    .frame(width: 10, height: 10)
                            }

                            Text(era.summary)
                                .font(.footnote)
                                .foregroundStyle(TLITheme.textSecondary(scheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(TLITheme.cardBackground(scheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(era.accent.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var supplierSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Supplies & Partners", detail: "Fast links for reference shopping and jacket-friendly layers.")

            ForEach(supplierLinks) { link in
                resourceCard(link)
            }

            Text("Amazon links use the app’s existing affiliate setup. Volante uses the current in-app destination and discount code already listed in Discounts.")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private var footerNote: some View {
        Text("Guide content lives on the official website. This in-app view is a curated launchpad for cosplay research and shopping prep.")
            .font(.footnote)
            .foregroundStyle(TLITheme.textSecondary(scheme))
            .padding(.top, 4)
    }

    private func resourceCard(_ link: GuideLink) -> some View {
        Button {
            presentSafari(link.url)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(link.accent.opacity(scheme == .dark ? 0.22 : 0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: link.icon)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(link.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(link.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text(link.subtitle)
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            .padding(14)
            .tliPanelSurface(
                cornerRadius: 18,
                fillOpacity: scheme == .dark ? 0.88 : 0.96,
                borderOpacity: 0.72,
                shadowRadius: 6,
                shadowY: 3
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Text(detail)
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
    }

    private func presentSafari(_ url: URL) {
        #if canImport(SafariServices)
        safariItem = CostumeGuideSafariItem(url: url)
        #else
        openURL(url)
        #endif
    }
}

private struct CostumeGuideSafariItem: Identifiable {
    let url: URL
    var id: URL { url }
}

#if canImport(SafariServices)
private struct CostumeGuideSafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        StarTrekCostumeGuideView()
    }
    .preferredColorScheme(.dark)
}
