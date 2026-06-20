import SwiftUI

@MainActor
struct SpecialEventsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    private let eventsURL = URL(string: "https://treklongisland.com/special-events-2/")!
    private let admissionURL = TicketPurchaseLinks.admissionURL

    private let highlights: [SpecialEventHighlight] = [
        .init(
            imageName: "painting",
            title: "Creative sessions",
            detail: "Hands-on featured experiences like celebrity painting and other art-forward activities."
        ),
        .init(
            imageName: "cheeseandwine",
            title: "Social events",
            detail: "Cocktail, lounge, and after-hours style events that give fans a more intimate hangout vibe."
        ),
        .init(
            imageName: "yoga",
            title: "Wellness and fun",
            detail: "Relaxed specialty programming that adds something different alongside panels and the main floor."
        )
    ]

    private let purchaseLinks: [SpecialEventPurchaseLink] = [
        .init(
            imageName: "Lounge",
            title: "Risa Luau: Cocktails Across the Final Frontier",
            detail: "Special cocktail event",
            url: TicketPurchaseLinks.risaLuauURL
        ),
        .init(
            imageName: "cheeseandwine",
            title: "Wine and Cheese Tasting with Jeffery Combs",
            detail: "Tasting experience",
            url: TicketPurchaseLinks.wineCheeseCombsURL
        ),
        .init(
            imageName: "painting",
            title: "Painting with Nana Visitor: Art of the Resistance",
            detail: "Celebrity painting session",
            url: TicketPurchaseLinks.nanaPaintingURL
        ),
        .init(
            imageName: "Blackwell",
            title: "Hands on with Avaah Blackwell: Stunt Action Workshop",
            detail: "Stunt workshop",
            url: TicketPurchaseLinks.avaahBlackwellStuntWorkshopURL
        ),
        .init(
            imageName: "Lounge",
            title: "Slut Trek Risa: Burlesque Show",
            detail: "21 and over, Saturday evening",
            url: TicketPurchaseLinks.slutTrekRisaBurlesqueURL
        ),
        .init(
            imageName: "glass1",
            title: "Glass Etching Art with Nicole de Boer",
            detail: "Saturday event",
            url: TicketPurchaseLinks.nicoleDeBoerGlassEtchingURL
        ),
        .init(
            imageName: "glass2",
            title: "Glass Etching Art with Jennifer Hetrick",
            detail: "Sunday event",
            url: TicketPurchaseLinks.jenniferHetrickGlassEtchingURL
        ),
        .init(
            imageName: "Czajkowski",
            title: "Starfleet Fusion Flow with Stephanie Czajkowski",
            detail: "Saturday event",
            url: TicketPurchaseLinks.starfleetFusionFlowURL
        ),
        .init(
            imageName: "MusettaVander",
            title: "Qigong Exercise Class with Musetta Vander",
            detail: "Saturday, 9 AM",
            url: TicketPurchaseLinks.musettaQigongSaturdayURL
        ),
        .init(
            imageName: "MusettaVander",
            title: "Qigong Exercise Class with Musetta Vander",
            detail: "Sunday, 9 AM",
            url: TicketPurchaseLinks.musettaQigongSundayURL
        ),
        .init(
            imageName: "healing",
            title: "Golden Key Qigong Healing Method Class with Musetta Vander",
            detail: "Saturday event",
            url: TicketPurchaseLinks.musettaGoldenKeyQigongURL
        ),
        .init(
            imageName: "moustache",
            title: "Moustache You a Question with Dan Jeannotte",
            detail: "Sam Kirk event",
            url: TicketPurchaseLinks.danJeannotteMoustacheURL
        )
    ]

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    actionsCard
                    purchaseLinksCard
                    ticketNoteCard
                    highlightsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Special Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openURL(eventsURL)
                } label: {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open special events page")
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                heroImageStrip

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Special Events")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Official Trek Long Island experiences beyond the standard panel flow.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .frame(height: 250)

            Text("Browse the official special-events page for the latest lineup, timing, and availability.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroImageStrip: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            HStack(spacing: 8) {
                heroImage("painting", width: width * 0.42)
                VStack(spacing: 8) {
                    heroImage("cheeseandwine", width: width * 0.52, height: 120)
                    heroImage("yoga", width: width * 0.52, height: 120)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func heroImage(_ name: String, width: CGFloat, height: CGFloat? = nil) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height ?? 248)
            .clipped()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Open Official Pages", systemImage: "link.circle.fill")

            Button {
                openURL(eventsURL)
            } label: {
                Label("View Special Events", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                openURL(eventsURL)
            } label: {
                Label("Open Website", systemImage: "arrow.up.right.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                openURL(admissionURL)
            } label: {
                Label("2027 Tickets", systemImage: "ticket.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var ticketNoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Admission Note", systemImage: "info.circle.fill")

            Text("Some special events may also require a convention admission badge. Use the individual event links above for the special-event purchase, and this link for 2027 tickets.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openURL(admissionURL)
            } label: {
                Text(admissionURL.absoluteString)
                    .font(.footnote.monospaced())
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RisaTheme.chipBackground(scheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var purchaseLinksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Purchase Special Events", systemImage: "ticket.fill")

            Text("Choose the event you want and the app will open that exact Square purchase page.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            ForEach(purchaseLinks) { event in
                Button {
                    openURL(event.url)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(event.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                                .foregroundStyle(RisaTheme.textPrimary(scheme))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(event.detail)
                                .font(.subheadline)
                                .foregroundStyle(RisaTheme.textSecondary(scheme))
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.title3)
                            .foregroundStyle(RisaTheme.accent(scheme))
                            .accessibilityHidden(true)
                    }
                    .padding(12)
                    .background(RisaTheme.chipBackground(scheme).opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Purchase \(event.title)")
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("What To Expect", systemImage: "star.fill")

            ForEach(highlights) { highlight in
                HStack(alignment: .top, spacing: 12) {
                    Image(highlight.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 86, height: 86)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(highlight.title)
                            .font(.headline)
                            .foregroundStyle(RisaTheme.textPrimary(scheme))

                        Text(highlight.detail)
                            .font(.subheadline)
                            .foregroundStyle(RisaTheme.textSecondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(RisaTheme.chipBackground(scheme).opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(RisaTheme.accent(scheme))
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
    }

}

private struct SpecialEventHighlight: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let detail: String
}

private struct SpecialEventPurchaseLink: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let detail: String
    let url: URL
}
