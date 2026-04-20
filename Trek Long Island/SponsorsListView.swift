// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct SponsorsListView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Background in line with other TLI views
            ZStack {
                TLITheme.backgroundGradient(scheme)
                if scheme == .dark {
                    Color.black.opacity(0.28)
                }
            }
            .ignoresSafeArea()

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
                .adaptiveContentWidth() // 👈 centers content on iPad, full-width on iPhone
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
            Text(RisaTheme.isLCARSThemeEnabled ? "Federation Support Registry" : "Trek Long Island’s 2026 Sponsors")
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
                 : "Helping us spread kindness all the way to the Delta Quadrant.")
                .font(.callout.italic())
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text(RisaTheme.isLCARSThemeEnabled
                 ? "These allied worlds and supporting organizations help keep the convention operational. Review their records and support them in return."
                 : "These partners help make our inclusive, fan-driven convention possible. Please consider supporting them the way they support Trek Long Island.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
                description: "The SyFy Sistas: Where We Give You Our Point of View. We are four Black women passionate about Science Fiction and Fantasy. Fran and Subrina offer an OG Trekkie perspective, while Yvette and Tamia bring a Gen X vibe. Through SyFy Sistas Inc., our podcast, book club, and live YouTube shows, we promote Black creativity and expression in films, TV, books, and graphic novels.",
                link: "https://syfysistas.com/"
            ),
            Sponsor(
                logoName: "Buddies (1)",
                title: "Buddies Spa DC",
                description: "While serving the D.C. community, Buddies Spa is committed to offering a safe and affirming space for the LGBTQIA+ community, ensuring that every client feels respected, valued, and empowered. Founded by Kris Otto in 2024, an immigrant from Vietnam, Kris founded Buddies Spa as the only queer spa in D.C. and to build a community that is supportive and gives back through fundraising and other community efforts.",
                link: "https://www.buddiesspa.com/"
            ),
            Sponsor(
                logoName: "PMAConsulting",
                title: "PMA Consulting",
                description: "PMA Consulting offers tailored consulting services, bringing creative people together to deliver desired outcomes, whether it’s a celebratory event or implementing best practices for businesses or teams. Based out of Washington, D.C., PMA Consulting serves clients across the Mid-Atlantic region from D.C. to New York City. PMA Consulting is a proud member of the D.C. Equality Chamber of Commerce and is committed to serving the creative needs of the queer community.",
                link: "https://www.paulmichaeladams.com/"
            ),
            Sponsor(
                logoName: "Knispel",
                title: "The Law Offices of Jay S. Knispel: Personal Injury Lawyers",
                description: "Their commitment to bringing the fans together helps make this event possible. The connections we make with the local community are what make us strong. With 15+ years of experience, The Law Offices of Jay S. Knispel represents NYC injury victims in car crashes, construction accidents, slips and falls, and wrongful death cases. Their team fights for justice and offers free consultations to help you get the compensation you deserve. 450 7th Ave Suite 1605, New York, NY 10123. Contact them at (212) 564-2800.",
                link: "http://jknylaw.com/new-york-slip-and-fall-lawyer/"
            ),
            Sponsor(
                logoName: "The Transporter Room Logo",
                title: "The Transporter Room Podcast",
                description: "Welcome to The Transporter Room, where we explore and celebrate the lives forever transformed by the Star Trek universe. Each week, we sit down with a new friend—be it former or future cast and crew members, scientists, or fans—whose personal and professional journeys have been shaped by the franchise.",
                link: "https://thetransporterroom.net/"
            ),
            Sponsor(
                logoName: "coolwaters",
                title: "Coolwaters Productions LLC",
                description: "We represent some of the most talented people in the business.For 29 years Coolwaters has traveled the world bringing its clients face to face with fans. Working with virtually every “comic-con” style event globally promoters and fans alike have been able to meet & greet their favorite celebrities from various franchises that include “Star Trek:, “Star Wars”, “Ghostbusters”, “ALIENS”, Disney and more. Doug Jones & Billy Dee Williams are just a couple names of the amazing talent we represent. We are proud to be a sponsor this year of Trek Long Island and hope that we can continue to bring amazing talent to this event… who knows, maybe Doug will come back for more “Doug Hugs”?!",
                link: "www.coolwatersprods.com"
            ),
            Sponsor(
                logoName: "Trekatecture",
                title: "Trekatecture",
                description: "A residential architecture firm that thinks outside the box. Servicing Long Island and Queens, we design for the needs of the many, or the few, or the one. Specializing in single family homes, we develop projects that range from decks and porticos, to alterations and additions and full new custom homes. No project too big or too small. Very well versed in all local zoning and building codes. 'Scotty like' timelines for completion. Oh, and we also create laser cut wood and acrylic models of Trek themed art too!",
                link: "http://www.trekatecture.com/"
            ),
            Sponsor(
                logoName: "Beadle & Grimm’s Pandemonium Warehouse",
                title: "BeadleGrimm",
                description: "Beadle & Grimm’s Pandemonium Warehouse was summoned up by the five founders (including Matthew Lillard of Scream and Scooby-Doo fame) as a mid-life crisis. And like any good summoning, it has gone awry and grown into an actual company, only nominally under our control. We are gamers. We love games. We play games. And now we, or at least this thing we have summoned, make loot for gamers like us.",
                link: "http://beadleandgrimms.com"
            )
        ]
    }

    struct Sponsor {
        let logoName: String
        let title: String
        let description: String
        let link: String
    }
}

// MARK: - Sponsor Entry

@MainActor
struct SponsorEntry: View {
    @Environment(\.colorScheme) private var scheme
    let logoName: String
    let title: String
    let description: String
    let link: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(logoName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: TLITheme.cardShadowColor(scheme), radius: 8, y: 3)
                .accessibilityHidden(true)

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
