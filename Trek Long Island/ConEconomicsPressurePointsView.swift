import SwiftUI

// MARK: - Focus field enum
private enum Field: Hashable {
    case venueCost, baseProduction, guestAndTalent, securityAndStaff
    case insuranceAndPermits, marketing, paymentAndPlatform, contingency
    case sponsorship, vendorBooth, other
    case ticketPrice, netTicketPercent
}

// MARK: - Design tokens
private enum TLI {
    static let gold    = Color(red: 0.82, green: 0.67, blue: 0.22)
    static let red     = Color(red: 0.85, green: 0.25, blue: 0.25)
    static let green   = Color(red: 0.18, green: 0.72, blue: 0.42)
    static let cardBG  = Color(.secondarySystemGroupedBackground)
    static let pageBG  = Color(.systemGroupedBackground)
}

private struct AdmissionComparisonEntry: Identifiable {
    let id = UUID()
    let eventName: String
    let edition: String
    let multiDayLabel: String
    let multiDayPrice: String
    let fridayPrice: String
    let saturdayPrice: String
    let sundayPrice: String
    let note: String
    let sourceURL: URL
}

// MARK: - Main View
/// Trek Long Island — Fan-Made Convention Economics
/// Drop into your app and route via NavigationLink.
struct ConEconomicsPressurePointsView: View {
    private let admissionComparisonEntries: [AdmissionComparisonEntry] = [
        AdmissionComparisonEntry(
            eventName: "Trek Long Island",
            edition: "June 12-14, 2026",
            multiDayLabel: "3-Day",
            multiDayPrice: "$70",
            fridayPrice: "$30",
            saturdayPrice: "$40",
            sundayPrice: "$30",
            note: "Current Trek Long Island working admission model used in this calculator.",
            sourceURL: URL(string: "https://treklongislandtickets.square.site/")!
        ),
        AdmissionComparisonEntry(
            eventName: "SpaceCon San Antonio",
            edition: "June 12-14, 2026",
            multiDayLabel: "3-Day",
            multiDayPrice: "$189",
            fridayPrice: "$85",
            saturdayPrice: "$99",
            sundayPrice: "$89",
            note: "General admission prices shown before checkout; site also advertises a temporary code.",
            sourceURL: URL(string: "https://www.spaceconsa.com/")!
        ),
        AdmissionComparisonEntry(
            eventName: "FAN EXPO Philadelphia",
            edition: "May 29-31, 2026",
            multiDayLabel: "3-Day",
            multiDayPrice: "$89",
            fridayPrice: "$40",
            saturdayPrice: "$55",
            sundayPrice: "$45",
            note: "Advanced pricing listed on the official buy-tickets page.",
            sourceURL: URL(string: "https://fanexpohq.com/fanexpophiladelphia/?utm_source=FanCons.com&utm_medium=web&utm_campaign=FanCons.com")!
        ),
        AdmissionComparisonEntry(
            eventName: "TerrifiCon",
            edition: "August 7-9, 2026",
            multiDayLabel: "3-Day",
            multiDayPrice: "$132",
            fridayPrice: "$45",
            saturdayPrice: "$49",
            sundayPrice: "$42",
            note: "Official tickets page notes single-day door sales are $5 higher if still available.",
            sourceURL: URL(string: "https://www.terrificon.com/tickets-1.html")!
        ),
        AdmissionComparisonEntry(
            eventName: "MEGACON Orlando",
            edition: "May 20-23, 2027",
            multiDayLabel: "4-Day",
            multiDayPrice: "TBD",
            fridayPrice: "TBD",
            saturdayPrice: "TBD",
            sundayPrice: "TBD",
            note: "Official page is live, but ticket pricing is not posted yet.",
            sourceURL: URL(string: "https://fanexpohq.com/megaconorlando/?utm_source=FanCons.com&utm_medium=web&utm_campaign=FanCons.com")!
        ),
        AdmissionComparisonEntry(
            eventName: "FAN EXPO Cleveland",
            edition: "March 12-14, 2027",
            multiDayLabel: "3-Day",
            multiDayPrice: "TBD",
            fridayPrice: "TBD",
            saturdayPrice: "TBD",
            sundayPrice: "TBD",
            note: "Official page is live, but ticket pricing is not posted yet.",
            sourceURL: URL(string: "https://fanexpohq.com/fanexpocleveland/?utm_source=FanCons.com&utm_medium=web&utm_campaign=FanCons.com")!
        ),
        AdmissionComparisonEntry(
            eventName: "FAN EXPO Portland",
            edition: "January 29-31, 2027",
            multiDayLabel: "3-Day",
            multiDayPrice: "TBD",
            fridayPrice: "TBD",
            saturdayPrice: "TBD",
            sundayPrice: "TBD",
            note: "Official page says tickets will go on sale soon.",
            sourceURL: URL(string: "https://fanexpohq.com/fanexpoportland/?utm_source=FanCons.com&utm_medium=web&utm_campaign=FanCons.com")!
        )
    ]

    // MARK: - Inputs
    // HISTORICAL: these defaults model Trek Long Island 4 (June 12–14, 2026) at the
    // Hyatt Regency Long Island, 1717 Motor Pkwy, Hauppauge NY. The convention has
    // since moved to the Melville Marriott for 2027 — the venue cost, ballroom
    // capacity, F&B minimum, and house AV assumptions below all need re-basing
    // against the new contract before this calculator is used for 2027 planning.
    //
    // Ticket prices: Adult 3-Day $70 · Sat $40 · Fri/Sun $30 · Child $25/$10
    // Blended avg across buyer mix (~55% 3-day, ~30% Sat-only, ~15% child) ≈ $58
    // Square fee: ~2.9% + $0.30/txn → ~3.4% effective on $58 → net ~97%
    //
    // Square vendor page checked Apr 23, 2026:
    // Vendor tables (2026): Booth $425–450 · Exhibitor $325–350
    //   Crafter $225–250 · Hallway/Fan $200 · Artist Alley $150
    //   $50 price increase after May 1, 2026. Each table includes 2 passes.
    //
    // Sponsorship page checked Apr 23, 2026:
    //   SOLD: Main Stage $4,000 · Signage $2,000 · Panel Room $2,000
    //         Phone App $1,500 · Kid's Track Ops $300 = $9,800 confirmed
    //   OPEN: DEI $6,000 · Vendor Room $4,000 · Room Pkg 2 $1,500
    //         Info Desk Ops $500 · Fan $25+
    //   Published package ceiling remains ~$21,800 before any Fan Package support.
    //   NOTE: Packages ≥$500 include a free hallway table — not independent of vendor revenue.
    //
    // Hyatt venue: Grand Ballroom 9,779 sq ft / 1,000 cap (8 divisible salons)
    //   Terrace Ballroom + Garden Patio ~6,500 sq ft (VIP dinner)
    //   Breakout rooms: 500–617 sq ft, 14–150 cap each
    //   Surprise costs: F&B minimums, mandatory house AV labor, extra Wi-Fi charges

    @State private var venueCost: Double               = 65_000
    @State private var baseProductionCost: Double      = 22_000
    @State private var guestAndTalentCost: Double      = 18_000
    @State private var securityAndStaffCost: Double    =  9_500
    @State private var insuranceAndPermitsCost: Double =  4_500
    @State private var marketingCost: Double           =  6_000
    @State private var paymentAndPlatformCost: Double  =  1_800
    @State private var contingencyPercent: Double      =     10
    @State private var ticketPrice: Double             =     58
    @State private var averageNetTicketPercent: Double =     97
    @State private var sponsorshipRevenue: Double      =  9_800
    @State private var vendorBoothRevenue: Double      =  7_500
    @State private var otherRevenue: Double            =  3_500

    @FocusState private var focusedField: Field?

    // MARK: - Formatters
    private let money: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 0; return f
    }()

    // MARK: - Derived math
    private var subtotalCosts: Double {
        venueCost + baseProductionCost + guestAndTalentCost
        + securityAndStaffCost + insuranceAndPermitsCost
        + marketingCost + paymentAndPlatformCost
    }
    private var contingencyDollars: Double { subtotalCosts * (contingencyPercent / 100) }
    private var totalCosts: Double         { subtotalCosts + contingencyDollars }
    private var totalNonTicketRevenue: Double { sponsorshipRevenue + vendorBoothRevenue + otherRevenue }
    private var netTicketPerAttendee: Double  { ticketPrice * (averageNetTicketPercent / 100) }
    private var breakEvenTickets: Double {
        max(0, totalCosts - totalNonTicketRevenue) / max(1, netTicketPerAttendee)
    }
    private var breakEvenTicketsRounded: Int {
        let value = breakEvenTickets
        // Int(_:) traps on non-finite or out-of-range Doubles; clamp first.
        guard value.isFinite, value >= 0, value < Double(Int.max) else { return 0 }
        return Int(ceil(value))
    }

    private var venueCostSharePercent: Int {
        guard subtotalCosts > 0 else { return 0 }
        let ratio = venueCost / subtotalCosts * 100
        guard ratio.isFinite else { return 0 }
        return Int(ratio.rounded())
    }

    private func marginAt(_ count: Int) -> Double {
        Double(count) * netTicketPerAttendee + totalNonTicketRevenue - totalCosts
    }

    private func fmt(_ v: Double) -> String { money.string(from: v as NSNumber) ?? "$0" }

    // MARK: - Body
    var body: some View {
        ZStack {
            TLI.pageBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    heroHeader
                    disclaimerBanner
                    contentStack
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .navigationTitle("Con Economics")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { focusedField = nil }
    }

    // MARK: - Hero header
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.10, blue: 0.22),
                         Color(red: 0.10, green: 0.16, blue: 0.32)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("TREK LONG ISLAND 4")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLI.gold)
                    .kerning(1.5)
                Text("Convention\nEconomics")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("June 12–14, 2026 · Hyatt Regency Long Island")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 2)

                Text("Historical model. Venue, F&B, and AV assumptions below are the 2026 Hyatt contract and have not been re-based for the \(TLIEventInfo.current.venue.name).")
                    .font(.caption)
                    .foregroundStyle(TLI.gold.opacity(0.9))
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    chip("🎟 \(fmt(ticketPrice)) avg ticket", color: TLI.gold)
                    chip("🏛 \(fmt(venueCost)) venue", color: .white.opacity(0.15))
                    chip("⚖️ BEP \(breakEvenTicketsRounded) tickets",
                         color: marginAt(400) >= 0 ? TLI.green : TLI.red)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private func chip(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Disclaimer
    private var disclaimerBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "theatermasks.fill")
                .foregroundStyle(TLI.gold)
            Text("Fiction & illustrative only — figures are estimates for educational use, not actual Trek Long Island financials.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLI.gold.opacity(0.08))
    }

    // MARK: - Content
    private var contentStack: some View {
        VStack(spacing: 20) {
            breakEvenDashboard
            calculatorSection
            ticketPriceHistorySection
            admissionComparisonSection
            pressurePointsSection
            riskReducersSection
            vendorPricingSection
            sponsorshipSection
            scenarioInsightSection
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Break-even dashboard
    private var breakEvenDashboard: some View {
        VStack(spacing: 0) {
            sectionHeader("Break-Even Snapshot", icon: "gauge.with.needle")

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    kpiTile(label: "Total Costs",    value: fmt(totalCosts),              icon: "arrow.down.circle", color: TLI.red)
                    kpiTile(label: "Non-Ticket Rev", value: fmt(totalNonTicketRevenue),   icon: "arrow.up.circle",   color: TLI.green)
                    kpiTile(label: "Net / Ticket",   value: fmt(netTicketPerAttendee),    icon: "ticket",            color: TLI.gold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Tickets needed to break even")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(breakEvenTicketsRounded)")
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(TLI.gold)
                    }

                    let maxDisplay = max(Double(breakEvenTicketsRounded) * 1.5, 600)
                    let progress = min(1.0, Double(breakEvenTicketsRounded) / maxDisplay)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemFill))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    colors: [TLI.red, TLI.gold],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progress, height: 12)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("0")
                        Spacer()
                        Text("\(Int(maxDisplay))")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }

                scenarioMarginRow
            }
            .padding(16)
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func kpiTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var scenarioMarginRow: some View {
        VStack(spacing: 8) {
            Text("Scenario margin")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                marginPill(attendees: 400, margin: marginAt(400))
                marginPill(attendees: 600, margin: marginAt(600))
            }
        }
    }

    private func marginPill(attendees: Int, margin: Double) -> some View {
        let positive = margin >= 0
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(attendees) attendees")
                    .font(.caption.weight(.medium))
                Text(fmt(margin))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(positive ? TLI.green : TLI.red)
            }
            Spacer()
            Image(systemName: positive ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(positive ? TLI.green : TLI.red)
                .font(.title3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background((positive ? TLI.green : TLI.red).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calculator
    private var calculatorSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Adjust the Numbers", icon: "slider.horizontal.3")

            VStack(spacing: 0) {
                inputGroupHeader("Costs", icon: "minus.circle.fill", color: TLI.red)
                inputRow { MoneyField("Venue / location",                value: $venueCost,               field: .venueCost,           focus: $focusedField) }
                inputRow { MoneyField("Production (AV, staging, Wi-Fi)", value: $baseProductionCost,      field: .baseProduction,      focus: $focusedField) }
                inputRow { MoneyField("Guests & talent",                 value: $guestAndTalentCost,      field: .guestAndTalent,      focus: $focusedField) }
                inputRow { MoneyField("Security & staffing",             value: $securityAndStaffCost,    field: .securityAndStaff,    focus: $focusedField) }
                inputRow { MoneyField("Insurance & permits",             value: $insuranceAndPermitsCost, field: .insuranceAndPermits, focus: $focusedField) }
                inputRow { MoneyField("Marketing",                       value: $marketingCost,           field: .marketing,           focus: $focusedField) }
                inputRow { MoneyField("Payment platform (fixed)",        value: $paymentAndPlatformCost,  field: .paymentAndPlatform,  focus: $focusedField) }
                inputRow { PercentField("Contingency buffer",            value: $contingencyPercent,      field: .contingency,         focus: $focusedField) }

                costSummaryRow("Subtotal costs",                value: subtotalCosts,      dimmed: true)
                costSummaryRow("Contingency (\(TLISafeMath.int(contingencyPercent))%)", value: contingencyDollars, dimmed: true)
                costSummaryRow("Total costs",                   value: totalCosts,         dimmed: false)

                Divider().padding(.vertical, 4)

                inputGroupHeader("Revenue", icon: "plus.circle.fill", color: TLI.green)
                inputRow { MoneyField("Sponsorships",                    value: $sponsorshipRevenue,      field: .sponsorship,         focus: $focusedField) }
                inputRow { MoneyField("Vendor tables",                   value: $vendorBoothRevenue,      field: .vendorBooth,         focus: $focusedField) }
                inputRow { MoneyField("Other (VIP, workshops, etc.)",    value: $otherRevenue,            field: .other,               focus: $focusedField) }
                inputRow { MoneyField("Avg ticket price",                value: $ticketPrice,             field: .ticketPrice,         focus: $focusedField) }
                inputRow { PercentField("Ticket net after fees",         value: $averageNetTicketPercent, field: .netTicketPercent,    focus: $focusedField) }

                costSummaryRow("Non-ticket revenue",            value: totalNonTicketRevenue, dimmed: true)
                costSummaryRow("Net per ticket",                value: netTicketPerAttendee,  dimmed: true)
            }
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Real budgets may also include room-block penalties, gratuities, union labor minimums, sales tax obligations on admission or membership fees, per-attendee variable costs (badges, lanyards, printing), and ticket refunds.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .padding(.top, 8)
                .padding(.horizontal, 4)
        }
    }

    private func inputGroupHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.footnote)
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
    }

    private func inputRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            Divider().padding(.leading, 14)
        }
    }

    private func costSummaryRow(_ label: String, value: Double, dimmed: Bool) -> some View {
        HStack {
            Text(label)
                .font(dimmed ? .subheadline : .subheadline.weight(.semibold))
                .foregroundStyle(dimmed ? .secondary : .primary)
            Spacer()
            Text(fmt(value))
                .font(dimmed ? .subheadline.monospacedDigit() : .subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(dimmed ? .secondary : .primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(dimmed ? Color.clear : TLI.gold.opacity(0.06))
    }

    // MARK: - Ticket price history
    private var ticketPriceHistorySection: some View {
        VStack(spacing: 0) {
            sectionHeader("Ticket Price History", icon: "clock.arrow.circlepath")

            VStack(spacing: 0) {
                ticketHistoryRow(
                    "2023",
                    "Trek Long Island launched its first convention ticket cycle."
                )
                ticketHistoryRow(
                    "2024",
                    "Ticket pricing continued to evolve as the event returned and expanded."
                )
                ticketHistoryRow(
                    "2025",
                    "Presale pricing was active before the June 9, 2025 increase for the 2026 3-day adult badge."
                )
                ticketHistoryRow(
                    "2026 to present",
                    "Check the official ticket site for the latest live ticket amounts, package details, and availability."
                )
            }
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("This timeline is illustrative and should be checked against the official ticket site for exact live pricing.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .padding(.top, 8)
                .padding(.horizontal, 4)
        }
    }

    private func ticketHistoryRow(_ year: String, _ detail: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(year)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(TLI.gold)
                    .frame(width: 88, alignment: .leading)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            Divider().padding(.leading, 14)
        }
    }

    // MARK: - Admission comparison
    private var admissionComparisonSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Admission Snapshot", icon: "ticket.fill")

            VStack(spacing: 10) {
                ForEach(admissionComparisonEntries) { entry in
                    admissionComparisonCard(entry)
                }
            }
            .padding(4)
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Snapshot checked April 2, 2026. Prices and on-sale status can change.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .padding(.top, 8)
                .padding(.horizontal, 4)
        }
    }

    private func admissionComparisonCard(_ entry: AdmissionComparisonEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.eventName)
                        .font(.subheadline.weight(.semibold))
                    Text(entry.edition)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }

                Spacer(minLength: 8)

                Text(entry.multiDayPrice)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(entry.multiDayPrice == "TBD" ? .secondary : TLI.gold)
            }

            HStack(spacing: 10) {
                admissionPricePill(entry.multiDayLabel, price: entry.multiDayPrice)
                admissionPricePill("Fri", price: entry.fridayPrice)
                admissionPricePill("Sat", price: entry.saturdayPrice)
                admissionPricePill("Sun", price: entry.sundayPrice)
            }

            Text(entry.note)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Link("Source", destination: entry.sourceURL)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func admissionPricePill(_ label: String, price: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))
            Text(price)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(price == "TBD" ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(TLI.gold.opacity(price == "TBD" ? 0.05 : 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Pressure points
    private var pressurePointsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Where Money Pressure Hits", icon: "exclamationmark.triangle.fill")

            VStack(spacing: 10) {
                pressureCard("🏛", "Venue minimums & labor",
                    "The Hyatt Regency's Grand Ballroom is 9,779 sq ft — holding it for 3 days means 3× the daily rate plus mandatory F&B spend. Union AV labor and Wi-Fi are extra line items on top.",
                    color: TLI.red)
                pressureCard("🎛", "AV & production creep",
                    "Projectors, mics, mixing, streaming, power drops, pipe & drape, and signage snowball fast. House AV is often contractually required; outside vendors may owe the Hyatt a patch fee.",
                    color: TLI.red)
                pressureCard("🌟", "Guest costs & volatility",
                    "Travel, hotel blocks, appearance fees, and last-minute cancellations. A drop reduces ticket sales but rarely reduces costs.",
                    color: .orange)
                pressureCard("📋", "Insurance & compliance",
                    "General liability, event cancellation coverage, vendor COI requirements, fire marshal rules, security/EMS staffing, and making sure the convention collects and remits any required sales tax on admission or membership fees.",
                    color: .orange)
                pressureCard("💳", "Processing & refunds",
                    "Square charges ~2.9% + $0.30/transaction. If a headline guest cancels, refund volume can spike dramatically.",
                    color: .orange)
                pressureCard("🎯", "Sponsor concentration",
                    "Trek LI's top published tiers ($6k + $4k + $4k) represent ~$14,000. One no-show creates an immediate gap. The sponsorship page already shows Main Stage, Signage, Panel Room, Phone App, and Kid's Track Operations sold, which is a strong early-risk reducer.",
                    color: .purple)
                pressureCard("⏱", "Cash-flow timing",
                    "Venue deposits, insurance premiums, and AV commitments are due months before ticket revenue peaks. Plan for 60–90 days of float.",
                    color: .purple)
            }
            .padding(4)
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func pressureCard(_ emoji: String, _ title: String, _ body: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Risk reducers
    private var riskReducersSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Practical Risk Reducers", icon: "shield.fill")
            VStack(spacing: 1) {
                reduceRow("✅", "Negotiate venue flexibility",  "Attrition clauses, reschedule rights, clear definition of what's included (tables, chairs, Wi-Fi, PA).")
                reduceRow("✅", "Tiered ticketing",             "Presale + early-bird improves cash-flow. Define VIP deliverables clearly before selling them.")
                reduceRow("✅", "Cap AV early",                 "Lock a production spec. Separate must-haves from nice-to-haves before signing anything.")
                reduceRow("✅", "Diversify revenue",            "Vendor tables + sponsorships + workshops + add-ons reduce dependency on head count alone.")
                reduceRow("✅", "Keep the contingency",         "10% is the minimum. Without it, one surprise invoice can flip a profitable event into a loss.")
            }
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func reduceRow(_ emoji: String, _ title: String, _ body: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(emoji).font(.body).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(body).font(.caption).foregroundStyle(Color.primary.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            Divider().padding(.leading, 50)
        }
    }

    // MARK: - Vendor pricing
    private var vendorPricingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("2026 Vendor Pricing", icon: "shippingbox.fill")

            VStack(spacing: 0) {
                vendorPriceRow("$425–450", "Vendor Booth", "Premium booth option from the Square vendor page.")
                vendorPriceRow("$325–350", "Exhibitor Table", "Standard exhibitor table pricing band.")
                vendorPriceRow("$225–250", "Crafter Table", "Lower-cost maker and crafter table option.")
                vendorPriceRow("$200", "Hallway / Fan Table", "Hallway table option; also overlaps with some sponsor benefits.")
                vendorPriceRow("$150", "Artist Alley", "Lowest published vendor table tier.")
            }
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.exclamationmark")
                    Text("$50 increase after May 1, 2026. Each table includes 2 passes.")
                }

                HStack(spacing: 4) {
                    Image(systemName: "envelope")
                    Text("Vendor questions: brothersgrimgames@gmail.com with “Vendor” in the subject.")
                }

                Link("Source: Square vendor page", destination: TicketPurchaseLinks.vendorTablingURL)
            }
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.72))
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
    }

    private func vendorPriceRow(_ price: String, _ name: String, _ description: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(price)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(TLI.gold)
                    .frame(width: 78, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().padding(.leading, 14)
        }
    }

    // MARK: - Sponsorship tiers
    private var sponsorshipSection: some View {
        VStack(spacing: 0) {
            sectionHeader("2026 Sponsorship Tiers", icon: "star.fill")

            VStack(spacing: 0) {
                sponsorRow("$6,000", "DEI Package",              "ASL interpreter + inclusivity resources. 6 passes + sponsor pin.", soldOut: false)
                sponsorRow("$4,000", "Main Stage",               "Sold to Coolwaters Productions. Main stage banner, table, bag flyer.", soldOut: true)
                sponsorRow("$4,000", "Vendor Room",              "Banner at vendor room entrance. 4 passes, hallway table, bag flyer.", soldOut: false)
                sponsorRow("$2,000", "Signage Package",          "Sold to TrekAtecture. Logo placed across convention signage.", soldOut: true)
                sponsorRow("$2,000", "Panel Room",               "Diversity Room sold to PMA Consulting from the panel room package.", soldOut: true)
                sponsorRow("$1,500", "Room Package 2",           "Kid's Track or Photo Studio room rental. Sponsor chooses.", soldOut: false)
                sponsorRow("$1,500", "Phone App",                "Sold to Transporter Room Podcast. Logo appears on app opening screen.", soldOut: true)
                sponsorRow("$500",   "Operations (Info Desk)",   "Offsets Information Desk and convention operations costs.", soldOut: false)
                sponsorRow("$300",   "Operations (Kid's Track)", "Sold to Beadle & Grimm's to support Kid's Track operations.", soldOut: true)
                sponsorRow("$25+",   "Fan Package",              "Name on sponsorship page plus a special lanyard pin.", soldOut: false)
            }
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                Text("Packages ≥$500 include a free hallway table — these are not independent of vendor revenue.")
            }
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.72))
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
    }

    private func sponsorRow(_ price: String, _ name: String, _ description: String, soldOut: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(price)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(soldOut ? .secondary : TLI.gold)
                    .frame(width: 58, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name).font(.subheadline.weight(.semibold))
                        if soldOut {
                            Text("SOLD OUT")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(TLI.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(soldOut ? 0.7 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            Divider().padding(.leading, 14)
        }
    }

    // MARK: - Scenario insight
    private var scenarioInsightSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Reading the Numbers", icon: "chart.line.uptrend.xyaxis")

            VStack(alignment: .leading, spacing: 14) {
                insightBlock("Confirmed revenue head start",
                    "The sponsorship page shows five sold package commitments: Main Stage ($4,000) to Coolwaters Productions, Signage ($2,000) to TrekAtecture, Diversity/Panel Room ($2,000) to PMA Consulting, Phone App ($1,500) to The Transporter Room Podcast, and Kid's Track Operations ($300) to Beadle & Grimm's. That's \(fmt(9_800)) locked in before a single ticket is sold, which meaningfully lowers the break-even attendee count.")

                insightBlock("The hallway table offset",
                    "Every sponsorship package ≥$500 includes a complimentary hallway table. Each sponsor who takes one displaces a paid vendor slot. Vendor and sponsorship revenue are partially linked — don't count both independently.")

                insightBlock("Venue dominates the cost structure",
                    "At \(fmt(venueCost)), the Hyatt venue represents about \(venueCostSharePercent)% of subtotal costs. Watch for F&B minimums, house AV surcharges, and Wi-Fi fees — these are the most common surprises in hotel convention contracts.")

                insightBlock("What the break-even number means",
                    "With \(fmt(totalNonTicketRevenue)) in non-ticket revenue, tickets only need to cover \(fmt(max(0, totalCosts - totalNonTicketRevenue))). At \(fmt(netTicketPerAttendee)) net per ticket, that's \(breakEvenTicketsRounded) paid attendees to reach zero. Every attendee above that is pure margin.")
            }
            .padding(16)
            .background(TLI.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func insightBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLI.gold)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Shared section header
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(TLI.gold)
                .font(.subheadline)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
    }
}

// MARK: - MoneyField
private struct MoneyField: View {
    let title: String
    @Binding var value: Double
    let field: Field
    var focus: FocusState<Field?>.Binding

    @State private var text: String = ""
    @State private var isEditing = false

    init(_ title: String, value: Binding<Double>, field: Field, focus: FocusState<Field?>.Binding) {
        self.title = title; self._value = value; self.field = field; self.focus = focus
    }

    private var displayText: String { isEditing ? text : formatted(value) }

    private func formatted(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 0
        return f.string(from: v as NSNumber) ?? "$0"
    }

    var body: some View {
        HStack {
            Text(title).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Spacer()
            TextField("$0", text: Binding(get: { displayText }, set: { text = $0 }))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .font(.subheadline.monospacedDigit())
                .focused(focus, equals: field)
                .onChange(of: focus.wrappedValue) { _, newFocus in
                    if newFocus == field {
                        isEditing = true
                        text = value == 0 ? "" : String(Int(value))
                    } else if isEditing { commit() }
                }
        }
    }

    private func commit() {
        let clean = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        value = Double(clean) ?? value
        isEditing = false
    }
}

// MARK: - PercentField
private struct PercentField: View {
    let title: String
    @Binding var value: Double
    let field: Field
    var focus: FocusState<Field?>.Binding

    @State private var text: String = ""
    @State private var isEditing = false

    init(_ title: String, value: Binding<Double>, field: Field, focus: FocusState<Field?>.Binding) {
        self.title = title; self._value = value; self.field = field; self.focus = focus
    }

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            TextField("0", text: Binding(
                get: { isEditing ? text : String(Int(value)) },
                set: { text = $0 }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 50)
            .font(.subheadline.monospacedDigit())
            .focused(focus, equals: field)
            .onChange(of: focus.wrappedValue) { _, newFocus in
                if newFocus == field {
                    isEditing = true
                    text = value == 0 ? "" : String(Int(value))
                } else if isEditing { commit() }
            }
            Text("%").font(.subheadline).foregroundStyle(Color.primary.opacity(0.72))
        }
    }

    private func commit() {
        let clean = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        value = Double(clean) ?? value
        isEditing = false
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ConEconomicsPressurePointsView()
    }
}
