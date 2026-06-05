// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

@MainActor
struct DiscountsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var searchText = ""
    @State private var selectedCategory: DiscountCategory = .all

    private let offers = DiscountOffer.all

    private var filteredOffers: [DiscountOffer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase

        return offers.filter { offer in
            let matchesCategory = selectedCategory == .all || offer.category == selectedCategory
            guard query.isEmpty == false else { return matchesCategory }
            return matchesCategory && offer.searchableText.contains(query)
        }
    }

    private var sectionedOffers: [DiscountOfferSection] {
        DiscountSection.allCases.compactMap { section in
            let matches = filteredOffers.filter { $0.section == section }
            guard matches.isEmpty == false else { return nil }
            return DiscountOfferSection(section: section, offers: matches)
        }
    }

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    filterCard

                    if sectionedOffers.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(sectionedOffers) { offerSection in
                            offersSection(offerSection)
                        }
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
            Text("Deals, Codes & Partner Links")
                .font(.title.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("Find every current coupon code, referral offer, affiliate link, and support option in one place. Everything is grouped by purpose so it stays useful without taking over the app.")
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme).opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                headerMetric("\(offers.count)", label: "links")
                headerMetric("\(DiscountSection.allCases.count)", label: "collections")
                headerMetric("\(offers.filter { $0.kind == .couponCode }.count)", label: "codes")
            }

            Text("Some destinations are affiliate or referral links. Pricing, availability, and eligibility are managed by each partner site.")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .tliCard()
    }

    private func headerMetric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
        )
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Find Offers", systemImage: "line.3.horizontal.decrease.circle.fill")
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

                TextField("Search stores, codes, or categories", text: $searchText)
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if searchText.isEmpty == false {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary.opacity(0.72))
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
                    ForEach(DiscountCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedCategory == category ? Color.black : TLITheme.textPrimary(scheme))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
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

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No offers match the current filters.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Try clearing your search or switching to another collection.")
                .font(.footnote)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .tliCard()
    }

    @ViewBuilder
    private func offersSection(_ offerSection: DiscountOfferSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(offerSection.section.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(offerSection.section.subtitle(count: offerSection.offers.count))
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme).opacity(0.82))

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 14) {
                ForEach(offerSection.offers) { offer in
                    DiscountOfferCard(offer: offer)
                        .tliCard()
                }
            }
        }
    }
}

private struct DiscountOfferSection: Identifiable {
    let section: DiscountSection
    let offers: [DiscountOffer]

    var id: DiscountSection { section }
}

private enum DiscountCategory: String, CaseIterable, Identifiable, Equatable {
    case all
    case convention
    case fandom
    case travelTech
    case foodLocal
    case rewards
    case support

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .convention: return "Convention"
        case .fandom: return "Fandom"
        case .travelTech: return "Travel & Tech"
        case .foodLocal: return "Food & Local"
        case .rewards: return "Rewards"
        case .support: return "Support"
        }
    }
}

private enum DiscountKind: String, Equatable {
    case couponCode
    case referralLink
    case affiliateLink
    case partnerOffer
    case supportLink
    case curatedCollection

    var title: String {
        switch self {
        case .couponCode: return "Coupon Code"
        case .referralLink: return "Referral Link"
        case .affiliateLink: return "Affiliate Link"
        case .partnerOffer: return "Partner Offer"
        case .supportLink: return "Support Link"
        case .curatedCollection: return "Curated Collection"
        }
    }

    var icon: String {
        switch self {
        case .couponCode: return "ticket.fill"
        case .referralLink: return "person.2.fill"
        case .affiliateLink: return "link"
        case .partnerOffer: return "sparkles"
        case .supportLink: return "heart.fill"
        case .curatedCollection: return "square.grid.2x2.fill"
        }
    }
}

private enum DiscountSection: String, CaseIterable, Identifiable, Equatable {
    case featured
    case conventionEssentials
    case fandomAndCosplay
    case travelAndTech
    case foodAndLocal
    case rewardsAndShopping
    case supportTheApp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .featured: return "Featured Savings"
        case .conventionEssentials: return "Convention Essentials"
        case .fandomAndCosplay: return "Fandom & Cosplay"
        case .travelAndTech: return "Travel & Tech"
        case .foodAndLocal: return "Food & Local"
        case .rewardsAndShopping: return "Rewards & Shopping"
        case .supportTheApp: return "Support The App"
        }
    }

    func subtitle(count: Int) -> String {
        let label = count == 1 ? "offer" : "offers"

        switch self {
        case .featured:
            return "\(count) featured \(label) with the clearest, quickest savings."
        case .conventionEssentials:
            return "\(count) \(label) for swag, supplies, hydration, and show-floor prep."
        case .fandomAndCosplay:
            return "\(count) \(label) for uniforms, collectibles, and fan gear."
        case .travelAndTech:
            return "\(count) \(label) for connectivity, privacy, transport, and power."
        case .foodAndLocal:
            return "\(count) \(label) for local help, meals, and grocery-side savings."
        case .rewardsAndShopping:
            return "\(count) \(label) for cash back, research panels, eyewear, and general deals."
        case .supportTheApp:
            return "\(count) optional \(label) that can help offset app upkeep."
        }
    }
}

private enum DiscountDestination: String {
    case cosermart
}

private struct DiscountOffer: Identifiable {
    let title: String
    let subtitle: String
    let category: DiscountCategory
    let section: DiscountSection
    let kind: DiscountKind
    let urlString: String?
    let promoCode: String?
    let supportNote: String?
    let actionTitle: String
    let destination: DiscountDestination?

    var id: String {
        if let destination {
            return "destination-\(destination.rawValue)-\(title)"
        }

        return urlString ?? title
    }

    var url: URL? {
        guard let urlString else { return nil }
        return DiscountAffiliateLinkSanitizer.url(from: urlString)
    }

    var prettyURL: String {
        if let host = url?.host(percentEncoded: false) {
            return host.replacingOccurrences(of: "www.", with: "")
        }

        if destination != nil {
            return "In-App Collection"
        }

        return "Offer"
    }

    var searchableText: String {
        [
            title,
            subtitle,
            category.title,
            section.title,
            kind.title,
            promoCode ?? "",
            prettyURL
        ]
        .joined(separator: " ")
        .localizedLowercase
    }

    static let all: [DiscountOffer] = [
        .init(
            title: "Volante Design Master Collection",
            subtitle: "Premium fandom outerwear and accessories. Use the in-app code at checkout for the listed savings.",
            category: .fandom,
            section: .featured,
            kind: .couponCode,
            urlString: "https://www.volantedesign.us/collections/master-collection",
            promoCode: "JAKRU6511",
            supportNote: nil,
            actionTitle: "Browse Collection",
            destination: nil
        ),
        .init(
            title: "Heroes & Villains: $25 Off $75",
            subtitle: "Referral offer for fandom apparel, bags, and character-inspired gear.",
            category: .fandom,
            section: .featured,
            kind: .referralLink,
            urlString: "https://i.refs.cc/uV791gsG",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Convention Swag Bundle",
            subtitle: "Official Trek Long Island bundle pick for easy convention swag shopping.",
            category: .convention,
            section: .conventionEssentials,
            kind: .partnerOffer,
            urlString: "https://made-in-ny-shop.fourthwall.com/products/convention-bundle",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Bundle",
            destination: nil
        ),
        .init(
            title: "Trek Long Island Etsy Shop",
            subtitle: "Fan-made Trek Long Island items, small gifts, and convention extras.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://www.etsy.com/shop/TrekLongIsland",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Shop",
            destination: nil
        ),
        .init(
            title: "Autograph Sheet Protectors",
            subtitle: "Rigid sleeves for keeping prints, programs, and signed items protected.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://amzn.to/45RMt5y",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "Convention Supply Pick",
            subtitle: "A practical Amazon gear pick for smoother convention prep.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://www.amazon.com/dp/B076FGMPW5?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.3OP3LOYFG9RIR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.3OP3LOYFG9RIR_1774546660125",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "YETI Yonder Helimix Vortex Blender Shaker Bottle",
            subtitle: "20 oz shaker bottle for hydration and protein mixes on the go.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://www.amazon.com/dp/B0FZMXBNFH?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.25JY212UB4E62&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.25JY212UB4E62_1774546700647",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "LifeStraw Go Series Filter Bottle",
            subtitle: "Insulated stainless steel filtered bottle for travel and daily carry.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://www.amazon.com/dp/B0CFWX5GD4?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.FODQ21W0PZSR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.FODQ21W0PZSR_1774546755467",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "Anker Nano MagSafe Power Bank",
            subtitle: "Ultra-slim 5,000mAh magnetic charger for iPhone battery backup.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .affiliateLink,
            urlString: "https://www.amazon.com/dp/B0F8HXYD46?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.19R2WYN5D5FRR&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.19R2WYN5D5FRR_1774546737298",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Tech Pick",
            destination: nil
        ),
        .init(
            title: "Umbrella Straws for Drinks",
            subtitle: "Colorful tiki-style drink straws for themed parties and con gatherings.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://www.amazon.com/dp/B0DBH4V77S?ref=t_ac_view_request_product_image&campaignId=amzn1.campaign.100U0X9TBC6R&linkCode=tr1&tag=evcompanion-20&linkId=amzn1.campaign.100U0X9TBC6R_1774546770235",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "Amazon Gear Pick",
            subtitle: "A bonus affiliate recommendation for con-day supplies and travel prep.",
            category: .convention,
            section: .conventionEssentials,
            kind: .affiliateLink,
            urlString: "https://amzn.to/4bADhps",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Supply Pick",
            destination: nil
        ),
        .init(
            title: "Cosermart Cosplay Costumes",
            subtitle: "Open the in-app costume collection for current Star Trek uniform and cosplay picks.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .curatedCollection,
            urlString: nil,
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Costume Picks",
            destination: .cosermart
        ),
        .init(
            title: "Cosplay Finds on eBay",
            subtitle: "Search-friendly shortcut for costume pieces, props, and fandom collectibles.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .affiliateLink,
            urlString: "https://ebay.us/ghfUMp",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Star Trek on Amazon",
            subtitle: "Browse Star Trek books, gifts, accessories, and convention-ready extras.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .affiliateLink,
            urlString: "https://amzn.to/3OI8pdH",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Comfrt Lounge & Travel Wear",
            subtitle: "Affiliate link for cozy sets, hoodies, and travel-day basics. Any eligible discount applies automatically through the link.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .affiliateLink,
            urlString: "https://comfrt.com/KLAIRE11",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Sideshow Collectibles",
            subtitle: "Collectibles, statues, and premium fandom display pieces.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .affiliateLink,
            urlString: "https://www.sideshow.com/?me=8rn1vl6q",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Funny Bumper Stickers & More",
            subtitle: "Redbubble shop link for stickers, casual gifts, and small accessories.",
            category: .fandom,
            section: .fandomAndCosplay,
            kind: .affiliateLink,
            urlString: "https://www.redbubble.com/people/cspankid/shop?asc=u&ref=account-nav-dropdown",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Shop",
            destination: nil
        ),
        .init(
            title: "DeleteMe Privacy Offer",
            subtitle: "A privacy partner offer for removing personal information from data broker sites.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .partnerOffer,
            urlString: "https://www.de33watrk.com/KX59SL/KMKS9/?uid=1",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Olight Rewards Program",
            subtitle: "Earn rewards and member perks on flashlights, EDC lights, and outdoor gear.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .referralLink,
            urlString: "https://www.olight.com/earnRewardsProgram?shareUid=2047287007077703683&shareChannel=EP_copylink",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Free Month of Starlink Internet",
            subtitle: "Referral offer for Starlink residential internet service.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .referralLink,
            urlString: "https://starlink.com/residential?referral=RC-4509047-46429-69",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save $20 on Visible Service",
            subtitle: "Referral link for Visible wireless service.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .referralLink,
            urlString: "https://www.visible.com/get/?3SL9ZDM",
            promoCode: "3SL9ZDM",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save on a New Tesla",
            subtitle: "Tesla referral link for eligible vehicle offers.",
            category: .travelTech,
            section: .travelAndTech,
            kind: .referralLink,
            urlString: "https://www.tesla.com/referral/bryan627261",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Local Laundry Pickup & Delivery",
            subtitle: "A neighborhood service option for laundry help before or after the weekend.",
            category: .foodLocal,
            section: .foodAndLocal,
            kind: .referralLink,
            urlString: "https://app.trycents.com/refer/OWFh/36bfb9c6",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save on a BJ's Wholesale Membership",
            subtitle: "Referral offer for warehouse-club membership savings when available.",
            category: .foodLocal,
            section: .foodAndLocal,
            kind: .referralLink,
            urlString: "https://share.bjs.com/carrollcoupon!df756d740e!a",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save on DoorDash",
            subtitle: "Referral promo link for eligible DoorDash orders.",
            category: .foodLocal,
            section: .foodAndLocal,
            kind: .referralLink,
            urlString: "https://drd.sh/QHffx4fLgkX0bHyg",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save on Uber Eats",
            subtitle: "Promo link for eligible Uber Eats orders.",
            category: .foodLocal,
            section: .foodAndLocal,
            kind: .referralLink,
            urlString: "https://ubereats.com/feed?promoCode=eats-bryanc2843ue",
            promoCode: "eats-bryanc2843ue",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Too Good To Go App",
            subtitle: "Find surplus meals nearby and help keep good food from going to waste.",
            category: .foodLocal,
            section: .foodAndLocal,
            kind: .partnerOffer,
            urlString: "https://tgtg.onelink.me/OGjG/sxzjqj1q",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Rakuten Cash Back Bonus",
            subtitle: "Referral link for cash-back shopping and a first-purchase bonus when eligible.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://www.rakuten.com/r/CARROL1333",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "SurveySavvy Research Panel",
            subtitle: "Referral link for paid survey opportunities.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://www.surveysavvy.com/?m=7690803",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Firmoo Eyewear Offer",
            subtitle: "Referral link for prescription glasses, sunglasses, and frame deals.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://www.firmoo.com/?invite_code=eb59917f65",
            promoCode: "eb59917f65",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Fuel Savings with Upside",
            subtitle: "Cash-back app link for gas, convenience-store, and select restaurant offers.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://upside.app.link/GBNRJ",
            promoCode: "GBNRJ",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Ibotta Cash-Back App",
            subtitle: "Referral link for grocery and retail cash-back offers.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://ibotta.onelink.me/iUfE/1005cd3f?friend_code=chlaojv",
            promoCode: "chlaojv",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Fetch Rewards Bonus Points",
            subtitle: "Referral link for receipt scanning and bonus points when eligible.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://referral.fetch.com/vvv3/referralqr?code=4TC22",
            promoCode: "4TC22",
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Save on MOO Business Products",
            subtitle: "Referral offer for business cards, postcards, and printed materials.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://refer.moo.com/b2brb98",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "Chase Referral Offer",
            subtitle: "Referral offer for eligible Chase products.",
            category: .rewards,
            section: .rewardsAndShopping,
            kind: .referralLink,
            urlString: "https://accounts.chase.com/raf/share/1041134219",
            promoCode: nil,
            supportNote: nil,
            actionTitle: "Open Offer",
            destination: nil
        ),
        .init(
            title: "App Developer Support Links",
            subtitle: "Using partner links is optional, but it can help offset the time and upkeep behind this companion app.",
            category: .support,
            section: .supportTheApp,
            kind: .supportLink,
            urlString: "https://linktr.ee/teslafi",
            promoCode: nil,
            supportNote: "Supports the developer",
            actionTitle: "Open Support Links",
            destination: nil
        )
    ]
}

private struct DiscountOfferCard: View {
    @Environment(\.colorScheme) private var scheme

    let offer: DiscountOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: offer.kind.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TLITheme.accent(scheme).opacity(scheme == .dark ? 0.20 : 0.16))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(offer.kind.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                        .textCase(.uppercase)

                    Text(offer.prettyURL)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)
            }

            Text(offer.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(offer.subtitle)
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme).opacity(0.84))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                categoryBadge

                if let promoCode = offer.promoCode {
                    Label("Code: \(promoCode)", systemImage: "number")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
                        )
                }

                if let supportNote = offer.supportNote {
                    Label(supportNote, systemImage: "heart.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TLITheme.accent(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            actionView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 260, alignment: .topLeading)
        .padding(16)
        .accessibilityElement(children: .contain)
    }

    private var categoryBadge: some View {
        Text(offer.category.title)
            .font(.caption.weight(.bold))
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
            )
    }

    @ViewBuilder
    private var actionView: some View {
        switch offer.destination {
        case .cosermart:
            NavigationLink {
                CosermartCosplayView()
            } label: {
                actionLabel(title: offer.actionTitle, systemImage: "chevron.right")
            }
            .buttonStyle(.plain)
        case nil:
            if let url = offer.url {
                Button {
                    TLIExternalWebOpener.open(url)
                } label: {
                    actionLabel(title: offer.actionTitle, systemImage: "arrow.up.right")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
            Text(title)
            Spacer()
            Image(systemName: systemImage)
                .font(.footnote)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.black)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(TLITheme.accent(scheme))
        )
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
                        Text("Cosermart Cosplay Picks")
                            .font(.title.bold())
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text("Current costume and uniform deals from the affiliate catalog.")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme).opacity(0.84))
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

    var url: URL? { DiscountAffiliateLinkSanitizer.url(from: urlString) }
}

private enum DiscountAffiliateLinkSanitizer {
    private static let paidSearchClickIDNames: Set<String> = [
        "gclid",
        "gbraid",
        "wbraid",
        "msclkid",
        "dclid",
        "yclid"
    ]

    static func url(from string: String) -> URL? {
        guard let url = URL(string: string) else { return nil }
        return sanitized(url)
    }

    static func sanitized(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              queryItems.isEmpty == false else {
            return url
        }

        let filteredItems = queryItems.filter { item in
            paidSearchClickIDNames.contains(item.name.lowercased()) == false
        }
        components.queryItems = filteredItems.isEmpty ? nil : filteredItems

        return components.url ?? url
    }
}

private struct CosermartOfferCard: View {
    @Environment(\.colorScheme) private var scheme

    let offer: CosermartOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(offer.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Current price: \(offer.priceNow)")
                .font(.body.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Original price: \(offer.originalPrice) • \(offer.discount)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme).opacity(0.78))

            Spacer(minLength: 0)

            if let url = offer.url {
                Button {
                    TLIExternalWebOpener.open(url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Open Costume Offer")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TLITheme.accent(scheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 210, alignment: .topLeading)
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
