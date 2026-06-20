// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct SponsorsListView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        SponsorsScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    SponsorCategoryLink(
                        title: RisaTheme.isLCARSThemeEnabled ? "Fan Sponsor Registry" : "Fan Sponsors",
                        subtitle: "A thank-you wall for the fans who chipped in to support the convention directly.",
                        systemImage: "heart.fill",
                        count: "24 names",
                        accent: RisaTheme.accentGold(scheme)
                    ) {
                        FanSponsorsListView()
                    }

                    SponsorCategoryLink(
                        title: RisaTheme.isLCARSThemeEnabled ? "Corporate Ally Registry" : "Corporate Sponsors",
                        subtitle: "Meet the organizations, creators, podcasts, and local businesses backing Trek Long Island.",
                        systemImage: "building.2.fill",
                        count: "11 sponsors",
                        accent: RisaTheme.accentSecondary(scheme)
                    ) {
                        CorporateSponsorsListView()
                    }

                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .adaptiveContentWidth()
            }
        }
        .navigationTitle(TLILCARSLabel.sponsors)
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RisaTheme.isLCARSThemeEnabled ? "Federation Support Registry" : "2026 Sponsors")
                .font(.largeTitle.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .shadow(
                    color: scheme == .dark ? .black.opacity(0.7) : .clear,
                    radius: scheme == .dark ? 6 : 0,
                    x: 0,
                    y: 1
                )

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "Choose a support registry to review."
                 : "Every contribution helps keep Trek Long Island welcoming, accessible, and boldly fan-powered.")
                .font(.callout.italic())
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "Fan sponsors and allied organizations are tracked separately so the mission records stay clear."
                 : "Fan Sponsors are individual supporters. Corporate Sponsors are the organizations and businesses helping bring the convention to life.")
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .tliCard()
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentGold(scheme),
            contentTopInset: 34
        )
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(TLITheme.border(scheme))

            Text("Interested in sponsoring Trek Long Island?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Choose a section to see who is helping make Trek Long Island 2026 possible.")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(.top, 8)
    }
}

// MARK: - Corporate Sponsors

@MainActor
struct CorporateSponsorsListView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        SponsorsScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    ForEach(sponsors, id: \.title) { sponsor in
                        SponsorEntry(
                            logoName: sponsor.logoName,
                            title: sponsor.title,
                            description: sponsor.description,
                            link: sponsor.link
                        )
                        .tliCard()
                    }

                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .adaptiveContentWidth()
            }
        }
        .navigationTitle(RisaTheme.isLCARSThemeEnabled ? "Allied Organizations" : "Corporate Sponsors")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RisaTheme.isLCARSThemeEnabled ? "Allied Organization Registry" : "2026 Corporate Sponsors")
                .font(.largeTitle.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .shadow(
                    color: scheme == .dark ? .black.opacity(0.7) : .clear,
                    radius: scheme == .dark ? 6 : 0,
                    x: 0,
                    y: 1
                )

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "Allied organizations supporting this mission profile."
                 : "Organizations, podcasts, creators, and businesses supporting Trek Long Island.")
                .font(.callout.italic())
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "These allied worlds and supporting organizations help keep the convention operational. Review their records and support them in return."
                 : "These partners help make our inclusive, fan-driven convention possible. Please consider supporting them the way they support Trek Long Island.")
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .tliCard()
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentGold(scheme),
            contentTopInset: 34
        )
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(TLITheme.border(scheme))

            Text("Interested in sponsoring Trek Long Island?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Reach out via our website or social channels to learn more about sponsorship opportunities for future events.")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(.top, 8)
    }

    // MARK: - Data

    private var sponsors: [Sponsor] {
        [
            Sponsor(
                logoName: "Syfysistas",
                title: "The SyFy Sistas",
                description: "Registration Sponsor. The SyFy Sistas: Where We Give You Our Point of View. Four Black women passionate about science fiction and fantasy, promoting Black creativity and expression through podcasting, book clubs, and live YouTube shows.",
                link: "https://syfysistas.com/"
            ),
            Sponsor(
                logoName: "coolwaters",
                title: "Coolwaters Productions LLC",
                description: "Main Stage Sponsor. Coolwaters represents talented performers and has spent decades connecting fans with celebrities from Star Trek, Star Wars, Ghostbusters, ALIENS, Disney, and more.",
                link: "https://www.coolwatersprods.com/"
            ),
            Sponsor(
                logoName: "Buddies (1)",
                title: "Buddies",
                description: "The Queer Spa DC. Buddies Spa is committed to offering a safe and affirming space for the LGBTQIA+ community where every client feels respected, valued, and empowered.",
                link: "https://www.buddiesspa.com/"
            ),
            Sponsor(
                logoName: "PMAConsulting",
                title: "PMA Consulting",
                description: "Diversity Panel Room Sponsor. PMA Consulting brings creative people together for events and business best practices, serving clients across the Mid-Atlantic region and supporting the queer community.",
                link: "https://www.paulmichaeladams.com/"
            ),
            Sponsor(
                logoName: "The Transporter Room Logo",
                title: "The Transporter Room Podcast",
                description: "Phone App Sponsor. The Transporter Room explores and celebrates lives transformed by the Star Trek universe through conversations with cast, crew, scientists, and fans.",
                link: "https://thetransporterroom.net/"
            ),
            Sponsor(
                logoName: "Trekatecture",
                title: "Trekatecture",
                description: "Signage Sponsor. A residential architecture firm serving Long Island and Queens, Trekatecture designs for the needs of the many, the few, or the one, and also creates Trek-themed laser-cut art.",
                link: "http://www.trekatecture.com/"
            ),
            Sponsor(
                logoName: "Brown White Open House for Sale Instagram Post",
                title: "Moonlight and Mawazo",
                description: "Info Desk Sponsor. A science fiction and fantasy short story competition culminating in an anthology, celebrating the written word and its ability to transform dreams and build worlds.",
                link: "https://moonlightandmawazo.com/"
            ),
            Sponsor(
                logoName: "BeadleGrimm",
                title: "Beadle & Grimm’s Pandemonium Warehouse",
                description: "Kid’s Track Ops Sponsor. Beadle & Grimm’s creates immersive, officially licensed Star Trek game-night experiences, including murder mystery and escape-room adventures.",
                link: "https://beadleandgrimms.com/collections/star-trek-games"
            ),
            Sponsor(
                logoName: nil,
                title: "Big Gay Smiles",
                description: "Big Gay Smiles Dental is an LGBTQ2IA+ owned practice focused on comfort, quality, and community, redefining queer- and ally-focused dental care.",
                link: "https://www.biggaysmiles.com/"
            ),
            Sponsor(
                logoName: nil,
                title: "The Game Map",
                description: "Gaming Sponsor. The Game Map publishes rules-light roleplaying games and maintains a website for finding and posting public gaming events and conventions.",
                link: "https://www.thegamemap.com/"
            ),
            Sponsor(
                logoName: "Knispel",
                title: "The Law Offices of Jay S. Knispel Personal Injury Lawyers",
                description: "The Law Offices of Jay S. Knispel represents NYC injury victims in car crashes, construction accidents, slips and falls, and wrongful death cases, offering free consultations.",
                link: "https://jknylaw.com/new-york-slip-and-fall-lawyer/"
            )
        ]
    }

    struct Sponsor {
        let logoName: String?
        let title: String
        let description: String
        let link: String
    }
}

// MARK: - Fan Sponsors

@MainActor
struct FanSponsorsListView: View {
    var body: some View {
        SponsorsScreenBackground {
            ScrollView {
                FanSponsorsThankYouView()
                    .tliCard()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .adaptiveContentWidth()
            }
        }
        .navigationTitle(RisaTheme.isLCARSThemeEnabled ? "Fan Registry" : "Fan Sponsors")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }
}

@MainActor
struct FanSponsorsThankYouView: View {
    @Environment(\.colorScheme) private var scheme

    private let fanSponsors = [
        "Marina Kravchuk",
        "Joseph Mulry",
        "Barb Concilio",
        "Carolyn Fansler",
        "Richard Chang",
        "Melissa Gabel",
        "Tara Polen",
        "Wayne Hall",
        "Time Lumpkins",
        "David Gregory",
        "Ann Harding",
        "Shari Sugarman",
        "Kelly Maude Schmitt",
        "Theodore Herman",
        "Elizabeth Ammenwerth",
        "Laurie Boullianne",
        "Colleen Skadl",
        "Heather Hilton",
        "Natalie J",
        "Barbara Viohl",
        "Catherine Meyers",
        "Melissa Nathan",
        "Patricia Hughes Casey",
        "Cassandra Girard"
    ]

    private let fanSponsorURL = URL(string: "https://www.paypal.com/donate/?hosted_button_id=6ZKX7M6VF52WQ")
    private let sponsorPageURL = URL(string: "https://treklongisland.com/2026-sponsors/")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(RisaTheme.isLCARSThemeEnabled ? "2026 Fan Sponsor Registry" : "2026 Fan Sponsors")
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(RisaTheme.accentGold(scheme))
                }
                .font(.title2.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(RisaTheme.isLCARSThemeEnabled
                     ? "Thank you to every fan sponsor whose support keeps this mission moving."
                     : "Thank you to all of our fan sponsors for your generous sponsorships.")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("These funds go straight to the convention to help with costs such as accessibility needs, technology, and other convention costs.")
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 10, alignment: .leading)
                ],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(fanSponsors, id: \.self) { sponsor in
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .imageScale(.small)
                            .foregroundStyle(RisaTheme.accentGold(scheme))

                        Text(sponsor)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.48 : 0.82))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(TLITheme.border(scheme), lineWidth: 0.7)
                    )
                }
            }

            HStack(spacing: 10) {
                if let fanSponsorURL {
                    Link(destination: fanSponsorURL) {
                        Label("Become a Fan Sponsor", systemImage: "heart.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(TLITheme.accent(scheme).opacity(0.96))
                            )
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Become a 2026 Fan Sponsor")
                }

                if let sponsorPageURL {
                    Link(destination: sponsorPageURL) {
                        Label("Sponsor Page", systemImage: "safari")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(TLITheme.border(scheme), lineWidth: 0.9)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .accessibilityLabel("Open Trek Long Island 2026 sponsors page")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentGold(scheme)
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Sponsor Navigation

@MainActor
struct SponsorsScreenBackground<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.28)
                }
            }
            .ignoresSafeArea()

            content
        }
    }
}

@MainActor
struct SponsorCategoryLink<Destination: View>: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String
    let systemImage: String
    let count: String
    let accent: Color
    @ViewBuilder let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(scheme == .dark ? 0.22 : 0.16))
                            .frame(width: 50, height: 50)

                        Image(systemName: systemImage)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(accent)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(count)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.48 : 0.82))
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tliCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Sponsor Entry

@MainActor
struct SponsorEntry: View {
    @Environment(\.colorScheme) private var scheme
    let logoName: String?
    let title: String
    let description: String
    let link: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let logoName {
                Image(logoName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: TLITheme.cardShadowColor(scheme), radius: 8, y: 3)
                    .accessibilityHidden(true)
            }

            // Title
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            // Description
            Text(description)
                .font(.callout)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            // Link button
            if let url = URL(string: link) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .imageScale(.small)
                        Text("Visit Website")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(TLITheme.accent(scheme).opacity(0.96))
                    )
                    .overlay(
                        Capsule()
                            .stroke(TLITheme.border(scheme), lineWidth: 0.8)
                    )
                    .foregroundStyle(Color.black)
                    .shadow(
                        color: scheme == .dark ? .black.opacity(0.6) : .clear,
                        radius: scheme == .dark ? 4 : 0,
                        x: 0,
                        y: 1
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Visit \(title) website")
            }
        }
        .padding(14)
        .tliLCARSPanelChrome(
            accent: RisaTheme.accentSecondary(scheme)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SponsorsListView()
    }
    .environment(\.colorScheme, .dark)
}
#endif
