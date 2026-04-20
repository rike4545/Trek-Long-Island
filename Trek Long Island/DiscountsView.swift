// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct DiscountsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @AppStorage(TLIAdSettings.removeAdsPurchasedKey) private var removeAdsPurchased: Bool = false
    @State private var showSponsoredOffers: Bool = false
    @State private var searchText: String = ""
    @State private var selectedCategory: DiscountOffer.Category = .all
    private let simonAdOneClickURL = URL(string: "https://click.linksynergy.com/link?id=rG4d7%2fdjvVM&offerid=1949172.507459946392012825333997&type=2&murl=https%3A%2F%2Fshop.simon.com%2Fproducts%2Fwomens-adidas-avacourt-2-tennis-shoes-2%3Fvariant%3D43416018583612")!
    private let simonAdOneImpressionURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1949172.507459946392012825333997&type=2&subid=0")!
    private let simonAdOneImageURL = URL(string: "https://cdn.shopify.com/s/files/1/0291/4536/6588/files/a8dde58a39e04a0695a071f44da116e1.jpg?v=1755340558")!
    private let simonAdTwoClickURL = URL(string: "https://click.linksynergy.com/link?id=rG4d7%2fdjvVM&offerid=1949172.507457585247832956740401&type=2&murl=https%3a%2f%2fshop.simon.com%2fproducts%2fwomens-adidas-adizero-adios-og-shoes%3fvariant%3d43678648926268")!
    private let simonAdTwoImpressionURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1949172.507457585247832956740401&type=2&subid=0")!
    private let simonAdTwoImageURL = URL(string: "https://cdn.shopify.com/s/files/1/0291/4536/6588/files/3de20d7bea0b4988a3f448bc2d51ac04.jpg?v=1763435238")!
    private let simonGridAdClickURL = URL(string: "https://click.linksynergy.com/fs-bin/click?id=rG4d7%2fdjvVM&offerid=1949172.488&subid=0&type=4")!
    private let simonGridAdImageURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1949172.488&subid=0&type=4&gridnum=0")!
    private let hillsAdClickURL = URL(string: "https://click.linksynergy.com/fs-bin/click?id=rG4d7%2fdjvVM&offerid=1658571.5&subid=0&type=4")!
    private let hillsAdImageURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1658571.5&subid=0&type=4&gridnum=0")!
    private let partnerBoostClickURL = URL(string: "https://click.linksynergy.com/fs-bin/click?id=rG4d7%2fdjvVM&offerid=1817204.4&type=3&subid=0")!
    private let partnerBoostImpressionURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1817204.4&type=3&subid=0")!
    private let taobaoGlobalClickURL = URL(string: "https://click.linksynergy.com/fs-bin/click?id=rG4d7%2fdjvVM&offerid=1927697.22&type=3&subid=0")!
    private let taobaoGlobalImpressionURL = URL(string: "https://ad.linksynergy.com/fs-bin/show?id=rG4d7%2fdjvVM&bids=1927697.22&type=3&subid=0")!

    private let offers: [DiscountOffer] = [
        .init(
            title: "Local Ad: Try Local Laundry Delivery Service",
            subtitle: "Neighborhood support partner",
            urlString: "https://app.trycents.com/refer/OWFh/36bfb9c6"
        ),
        .init(
            title: "DeleteMe Privacy Offer",
            subtitle: "Remove personal info from data broker sites.",
            urlString: "https://www.de33watrk.com/KX59SL/KMKS9/?uid=1"
        ),
        .init(
            title: "Comfrt Lounge & Travel Wear",
            subtitle: "Use code KLAIRE10 for savings on cozy sets, hoodies, and travel-day basics.",
            urlString: "https://comfrt.com/KLAIRE10"
        ),
        .init(
            title: "Cosplay needs on Ebay",
            subtitle: nil,
            urlString: "https://ebay.us/ghfUMp"
        ),
        .init(
            title: "Star Trek on Amazon",
            subtitle: nil,
            urlString: "https://amzn.to/3OI8pdH"
        ),
        .init(
            title: "Heros & Villains, $25 Off $75",
            subtitle: nil,
            urlString: "https://i.refs.cc/uV791gsG"
        ),
        .init(
            title: "Autograph Sheet Protectors",
            subtitle: nil,
            urlString: "https://amzn.to/45RMt5y"
        ),
        .init(
            title: "Amazon Convention Supply Pick",
            subtitle: "Extra gear recommendation added for convention prep.",
            urlString: "https://www.amazon.com/dp/B076FGMPW5?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.3OP3LOYFG9RIR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.3OP3LOYFG9RIR_1774546660125"
        ),
        .init(
            title: "YETI Yonder Helimix Vortex Blender Shaker Bottle",
            subtitle: "20 oz shaker bottle for hydration and protein mixes on the go.",
            urlString: "https://www.amazon.com/dp/B0FZMXBNFH?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.25JY212UB4E62&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.25JY212UB4E62_1774546700647"
        ),
        .init(
            title: "Anker Nano MagSafe Power Bank",
            subtitle: "Ultra-slim 5,000mAh magnetic charger for iPhone battery backup.",
            urlString: "https://www.amazon.com/dp/B0F8HXYD46?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.19R2WYN5D5FRR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.19R2WYN5D5FRR_1774546737298"
        ),
        .init(
            title: "LifeStraw Go Series Filter Bottle",
            subtitle: "Insulated stainless steel filtered bottle for travel and daily carry.",
            urlString: "https://www.amazon.com/dp/B0CFWX5GD4?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.FODQ21W0PZSR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.FODQ21W0PZSR_1774546755467"
        ),
        .init(
            title: "Umbrella Straws for Drinks",
            subtitle: "Colorful tiki-style drink straws for themed parties and con gatherings.",
            urlString: "https://www.amazon.com/dp/B0DBH4V77S?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.100U0X9TBC6R&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.100U0X9TBC6R_1774546770235"
        ),
        .init(
            title: "Amazon Gear Pick",
            subtitle: "Another affiliate recommendation for con-day supplies and travel prep.",
            urlString: "https://amzn.to/4bADhps"
        ),
        .init(
            title: "Rakuten, Get $50 on First Order",
            subtitle: nil,
            urlString: "https://www.rakuten.com/r/CARROL1333"
        ),
        .init(
            title: "Sideshow Collectibles",
            subtitle: nil,
            urlString: "https://www.sideshow.com/?me=8rn1vl6q"
        ),
        .init(
            title: "Free Month of Starlink Internet",
            subtitle: nil,
            urlString: "https://starlink.com/residential?referral=RC-4509047-46429-69"
        ),
        .init(
            title: "Save $20 Off Visible Service",
            subtitle: nil,
            urlString: "https://www.visible.com/get/?3SL9ZDM"
        ),
        .init(
            title: "Save $1,000 on your Next Tesla",
            subtitle: nil,
            urlString: "https://www.tesla.com/referral/bryan627261"
        ),
        .init(
            title: "Funny Bumper Stickers and More",
            subtitle: nil,
            urlString: "https://www.redbubble.com/people/cspankid/shop?asc=u&ref=account-nav-dropdown"
        ),
        .init(
            title: "Save on BJ Wholesale Membership",
            subtitle: nil,
            urlString: "https://share.bjs.com/carrollcoupon!df756d740e!a"
        ),
        .init(
            title: "Get Paid $3 Per Month for Completing Surveys",
            subtitle: nil,
            urlString: "https://www.surveysavvy.com/?m=7690803"
        ),
        .init(
            title: "Fantastic Glasses Designs",
            subtitle: nil,
            urlString: "https://www.firmoo.com/?invite_code=eb59917f65"
        ),
        .init(
            title: "Save $5 on your Next DoorDash Order",
            subtitle: nil,
            urlString: "https://drd.sh/QHffx4fLgkX0bHyg"
        ),
        .init(
            title: "Save $15 on your Next UberEats Order",
            subtitle: nil,
            urlString: "https://ubereats.com/feed?promoCode=eats-bryanc2843ue"
        ),
        .init(
            title: "Fuel Discounts",
            subtitle: nil,
            urlString: "https://upside.app.link/GBNRJ"
        ),
        .init(
            title: "Ibotta App Suggestion, Get $7",
            subtitle: nil,
            urlString: "https://ibotta.onelink.me/iUfE/1005cd3f?friend_code=chlaojv"
        ),
        .init(
            title: "Fetch App Suggestion, Get 2000 Bonus Points",
            subtitle: nil,
            urlString: "https://referral.fetch.com/vvv3/referralqr?code=4TC22"
        ),
        .init(
            title: "Save $25 Off Moo Business Products",
            subtitle: nil,
            urlString: "https://refer.moo.com/b2brb98"
        ),
        .init(
            title: "Good to Go App",
            subtitle: "Get the app here, and help save good food from going to waste.",
            urlString: "https://tgtg.onelink.me/OGjG/sxzjqj1q"
        ),
        .init(
            title: "Chase Referral Offer",
            subtitle: nil,
            urlString: "https://accounts.chase.com/raf/share/1041134219"
        ),
        
    ]

    private var filteredOffers: [DiscountOffer] {
        offers.filter { offer in
            let matchesCategory = selectedCategory == .all || offer.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch: Bool
            if query.isEmpty {
                matchesSearch = true
            } else {
                let haystack = [offer.title, offer.subtitle ?? "", offer.prettyURL, offer.category.title]
                    .joined(separator: " ")
                    .localizedLowercase
                matchesSearch = haystack.contains(query.localizedLowercase)
            }
            return matchesCategory && matchesSearch
        }
    }

    private var featuredOffers: [DiscountOffer] {
        filteredOffers.filter(\.isFeatured)
    }

    private var standardOffers: [DiscountOffer] {
        filteredOffers.filter { !$0.isFeatured }
    }

    private var shouldShowStandardOffersSection: Bool {
        !standardOffers.isEmpty || featuredOffers.isEmpty || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    filterCard

                    if !featuredOffers.isEmpty && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        offersSection(
                            title: "Featured Picks",
                            subtitle: "Quick wins for cosplay, privacy, local support, and fandom shopping.",
                            offers: featuredOffers
                        )
                    }

                    if shouldShowStandardOffersSection {
                        offersSection(
                            title: standardOffers.isEmpty ? "Matching Links" : "Discount Links",
                            subtitle: standardOffers.isEmpty ? "Try a different search or category." : "\(filteredOffers.count) offers ready to open.",
                            offers: standardOffers
                        )
                    }

                    if !removeAdsPurchased {
                        sponsoredOffersSection
                    }

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 20)
                .adaptiveContentWidth()
            }
        }
        .navigationTitle("Discounts")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    private var gridColumns: [GridItem] {
        if hSizeClass == .regular {
            return [
                GridItem(.flexible(minimum: 260), spacing: 14),
                GridItem(.flexible(minimum: 260), spacing: 14)
            ]
        }
        return [GridItem(.flexible(minimum: 0), spacing: 0)]
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deals & Discounts")
                .font(.largeTitle.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Save on fandom gear, travel tools, privacy offers, and a few local-support picks that help keep the app going.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Text("Volante Design Discount: `JAKRU6511` to receive `10%` off")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Link("Browse Volante Master Collection", destination: URL(string: "https://www.volantedesign.us/collections/master-collection")!)
                .font(.subheadline.weight(.semibold))

            NavigationLink {
                CosermartCosplayView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "tshirt.fill")
                    Text("Open Cosermart Cosplay Costumes")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.7)
                }
                .font(.subheadline.weight(.semibold))
            }

            Text("Some links may be affiliate links that help support Trek Long Island.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .tliCard()
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Find an offer", systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer()
                Text("\(filteredOffers.count) shown")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                TextField("Search discounts, stores, or categories", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.72))
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DiscountOffer.Category.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedCategory == category ? Color.black : TLITheme.textPrimary(scheme))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? TLITheme.accent(scheme) : Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .tliCard()
    }

    @ViewBuilder
    private func offersSection(title: String, subtitle: String, offers: [DiscountOffer]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            if offers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No offers match the current filters.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Text("Try clearing your search or switching to another category.")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .tliCard()
            } else {
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 14) {
                    ForEach(offers) { offer in
                        DiscountOfferCard(offer: offer)
                            .tliCard()
                    }
                }
            }
        }
    }

    private var sponsoredOffersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $showSponsoredOffers) {
                VStack(spacing: 12) {
                    ShopSimonAffiliateAdView(
                        clickURL: simonAdOneClickURL,
                        impressionURL: simonAdOneImpressionURL,
                        creativeImageURL: simonAdOneImageURL
                    )
                    .tliCard()

                    ShopSimonAffiliateAdView(
                        clickURL: simonAdTwoClickURL,
                        impressionURL: simonAdTwoImpressionURL,
                        creativeImageURL: simonAdTwoImageURL
                    )
                    .tliCard()

                    ShopSimonAffiliateAdView(
                        clickURL: hillsAdClickURL,
                        creativeImageURL: hillsAdImageURL
                    )
                    .tliCard()

                    ShopSimonAffiliateAdView(
                        clickURL: simonGridAdClickURL,
                        creativeImageURL: simonGridAdImageURL
                    )
                    .tliCard()

                    LinkShareTextAdCard(
                        title: "Partner Boost",
                        clickURL: partnerBoostClickURL,
                        impressionURL: partnerBoostImpressionURL
                    )
                    .tliCard()

                    LinkShareTextAdCard(
                        title: "Taobao-Global",
                        clickURL: taobaoGlobalClickURL,
                        impressionURL: taobaoGlobalImpressionURL
                    )
                    .tliCard()
                }
                .padding(.top, 10)
            } label: {
                HStack {
                    Label("Sponsored Offers", systemImage: "megaphone.fill")
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text("Optional")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(TLITheme.textPrimary(scheme))
        }
        .padding(16)
        .tliCard()
    }
}

private struct DiscountOffer: Identifiable {
    enum Category: String, CaseIterable, Identifiable {
        case all
        case fandom
        case local
        case tech
        case food
        case shopping
        case travel

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .fandom: return "Fandom"
            case .local: return "Local"
            case .tech: return "Tech"
            case .food: return "Food"
            case .shopping: return "Shopping"
            case .travel: return "Travel"
            }
        }
    }

    let title: String
    let subtitle: String?
    let urlString: String
    var id: String { urlString }

    var url: URL? { URL(string: urlString) }

    var prettyURL: String {
        if let host = url?.host(percentEncoded: false) {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return urlString
    }

    var category: Category {
        let text = "\(title) \(subtitle ?? "") \(prettyURL)".localizedLowercase

        if text.contains("trek") || text.contains("cosplay") || text.contains("autograph") || text.contains("collectible") || text.contains("volante") || text.contains("redbubble") {
            return .fandom
        }
        if text.contains("local") || text.contains("laundry") || text.contains("made-in-ny") {
            return .local
        }
        if text.contains("privacy") || text.contains("starlink") || text.contains("visible") || text.contains("tesla") {
            return .tech
        }
        if text.contains("doordash") || text.contains("ubereats") || text.contains("food") || text.contains("bjs") || text.contains("ibotta") || text.contains("fetch") {
            return .food
        }
        if text.contains("uber") || text.contains("fuel") || text.contains("upside") {
            return .travel
        }
        return .shopping
    }

    var isFeatured: Bool {
        let text = title.localizedLowercase
        return text.contains("volante")
            || text.contains("cosplay")
            || text.contains("deleteme")
            || text.contains("local")
            || text.contains("star trek")
    }
}

private struct DiscountOfferCard: View {
    @Environment(\.colorScheme) private var scheme
    let offer: DiscountOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(offer.category.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
                    )

                Spacer()

                Text(offer.prettyURL)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Text(offer.title)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = offer.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let url = offer.url {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text("Open Link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(TLITheme.accent(scheme))
                    )
                }
                .buttonStyle(.plain)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

private struct WisprTextAdCard: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sponsored")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Try Wispr Flow")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Voice-first writing workflow for faster notes and updates.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Link(destination: URL(string: "https://ref.wisprflow.ai/bryan-c")!) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("Open Sponsor Link")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(TLITheme.accent(scheme))
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

private struct LinkShareTextAdCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    let title: String
    let clickURL: URL
    let impressionURL: URL

    @State private var didTrackImpression = false

    var body: some View {
        Button {
            openURL(clickURL)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sponsored")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("Open Offer")
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(TLITheme.accent(scheme))
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .buttonStyle(.plain)
        .onAppear {
            sendImpressionIfNeeded()
        }
    }

    private func sendImpressionIfNeeded() {
        guard didTrackImpression == false else { return }
        didTrackImpression = true

        var request = URLRequest(url: impressionURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request).resume()
    }
}

@MainActor
private struct CosermartCosplayView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private let offers: [CosermartOffer] = [
        .init(
            name: "Star TNG The Next Generation Trek Red Yellow Blue Shirt Uniform Cosplay Costume For Men Coat Halloween Party",
            priceNow: "USD 42.08",
            originalPrice: "USD 56.67",
            discount: "26% off",
            urlString: "https://s.click.aliexpress.com/e/_c4OUfqWb"
        ),
        .init(
            name: "Star Discovery 4 Rek Cosplay Michael Burnham Starfleet Uniforms Top Shirt Red Yellow ST Cosplay Costume Halloween",
            priceNow: "USD 50.59",
            originalPrice: "USD 64.04",
            discount: "21% off",
            urlString: "https://s.click.aliexpress.com/e/_c3SAj9s7"
        ),
        .init(
            name: "First Contact Undershirt Deep Space Nine Captain Picard Sisko Starfleet Uniforms Costume Top Prop",
            priceNow: "USD 36.05",
            originalPrice: "USD 48.54",
            discount: "26% off",
            urlString: "https://s.click.aliexpress.com/e/_c4Km4yOb"
        ),
        .init(
            name: "Star The Next Generation Trek Captain Picard Duty Uniform Jacket TNG Red Costume Man Winter Coat Warm Cosplay Costume Prop",
            priceNow: "USD 55.62",
            originalPrice: "USD 115.25",
            discount: "52% off",
            urlString: "https://s.click.aliexpress.com/e/_c3zdmzrh"
        ),
        .init(
            name: "Star Cosplay Costume Trek Picard 3 Captain Riker Geordi Laforge Red Gold Blue Leather Jackets Starfleet Costumes Halloween Party",
            priceNow: "USD 74.60",
            originalPrice: "USD 149.20",
            discount: "50% off",
            urlString: "https://s.click.aliexpress.com/e/_c3E2KneJ"
        ),
        .init(
            name: "Cosplay First Contact Picard Captain Riker Starfleet Uniforms Jackets Costumes Coat Tops for Men",
            priceNow: "USD 83.42",
            originalPrice: "USD 105.59",
            discount: "21% off",
            urlString: "https://s.click.aliexpress.com/e/_c3f8pKvZ"
        ),
        .init(
            name: "Star for Strange New Worlds Cosplay Captain Pike MM Jackets Undershirts Starfleet Uniforms Men's Tops Coat",
            priceNow: "USD 41.53",
            originalPrice: "USD 83.06",
            discount: "50% off",
            urlString: "https://s.click.aliexpress.com/e/_c31Em3C7"
        ),
        .init(
            name: "Strange New Worlds Lower Decks Red Blue Gold Shirts Starfleet Uniforms Cosplay Costumes Men's Jackets",
            priceNow: "USD 60.76",
            originalPrice: "USD 76.91",
            discount: "21% off",
            urlString: "https://s.click.aliexpress.com/e/_c4OegQdZ"
        )
    ]

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cosermart Cosplay Costumes")
                            .font(.largeTitle.bold())
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                        Text("Top On Sale Product Recommendations")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .tliCard()

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(offers) { offer in
                            CosermartOfferCard(offer: offer)
                                .tliCard()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .adaptiveContentWidth()
            }
        }
        .navigationTitle("Cosermart")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .tliFixedBottomAdSlot()
    }

    private var columns: [GridItem] {
        if hSizeClass == .regular {
            return [
                GridItem(.flexible(minimum: 280), spacing: 14),
                GridItem(.flexible(minimum: 280), spacing: 14)
            ]
        }
        return [GridItem(.flexible(minimum: 0), spacing: 0)]
    }
}

private struct CosermartOffer: Identifiable {
    let name: String
    let priceNow: String
    let originalPrice: String
    let discount: String
    let urlString: String
    var id: String { urlString }

    var url: URL? { URL(string: urlString) }
}

private struct CosermartOfferCard: View {
    @Environment(\.colorScheme) private var scheme
    let offer: CosermartOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(offer.name)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("Price Now: \(offer.priceNow)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Original price: \(offer.originalPrice) • \(offer.discount)")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            if let url = offer.url {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Click & Buy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(TLITheme.accent(scheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DiscountsView()
    }
    .environment(\.colorScheme, .dark)
}
#endif
