// Copyright Bryan Carroll. All rights reserved.
//
//  HomeView.swift
//  Trek Long Island
//
//  Today view — Apple Design Foundations + subtle Star Trek flair
//  Includes "Hello Computer" quick access
//  Swift 6 • iOS 17+
//
//  Changes in this revision:
//  - Boothby link now uses UIApplication.shared.open() — fixes white-screen sheet bug
//  - Mission readiness score cached in @State, recomputed only on data change
//  - HeroSlideCard uses EquatableView to skip unnecessary re-renders
//  - backgroundView wrapped in drawingGroup() to reduce GPU overdraw
//  - Carousel task re-keyed on isCarouselRunning bool so it truly exits on .onDisappear
//  - NotificationManager observation isolated to a child view (NotificationBadgeView)
//    so full HomeView body is not re-evaluated on every badge count change
//  - Removed @State activeLink / SafariView sheet (no longer needed)
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private let homeWeekdayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "EEEE"
    return df
}()

// MARK: - Hero Slides

private struct HeroSlide: Identifiable, Hashable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String

    static let sample: [HeroSlide] = [
        .init(imageName: "Slide3",        title: "Main Stage Moments",        subtitle: "Panels, Q&A, and live podcast recordings."),
        .init(imageName: "Slide4",        title: "Breakout Sessions",          subtitle: "Explore Trek, STEM, art, and more."),
        .init(imageName: "Slide1",        title: "Cadets & Families",          subtitle: "Family-friendly Starfleet Academies."),
        .init(imageName: "khan",          title: "Deep Space Frequencies",     subtitle: "Live podcasts, interviews, and surprises."),
        .init(imageName: "SuluMovie",          title: "Holodeck Features",     subtitle: "Join the Directors for a special screening"),
        .init(imageName: "painting",      title: "Painting With a Celebrity",  subtitle: "A creative session with your favorite crew."),
        .init(imageName: "healing",       title: "Yoga With a Celebrity",      subtitle: "A calm reset between missions."),
        .init(imageName: "cheeseandwine", title: "Cheese & Wine With a Celebrity", subtitle: "Relaxed social time—off duty."),
        .init(imageName: "twomoons",      title: "Exclusive Experiences",      subtitle: "Upgrades, add-ons, and unique moments."),
        .init(imageName: "yoga",          title: "Holodeck Wellness",          subtitle: "Stretch, breathe, and return to duty refreshed."),
        .init(imageName: "glass1",        title: "Holodeck Art",               subtitle: "Come enjoy making your own Risian artifact."),
        .init(imageName: "glass2",        title: "Holodeck Art",               subtitle: "Come enjoy making your own Risian artifact."),
        .init(imageName: "moustache",     title: "Holodeck Fun",               subtitle: "'Mad Libs' and so much more."),
        .init(imageName: "FoodTrucks",     title: "Working Replicators",               subtitle: "'Food, Food, Food."),
        .init(imageName: "Hanging",     title: "Guest Fun",               subtitle: "'Paradise."),
        .init(imageName: "2027 Tickets Promo 1",     title: "2027 Tickets",               subtitle: "'2027 Tickets."),
        .init(imageName: "2027 Hotel Promo",     title: "2027 Hotel Block Open",               subtitle: "'2027 Hotel.")
    ]
}

// MARK: - Mission Directives

private enum HomeMissionDestination: Hashable {
    case schedule, guests, map, computer
}

private struct HomeMissionDirective: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let destination: HomeMissionDestination

    static let livePresets: [HomeMissionDirective] = [
        .init(title: "Scan the schedule",    detail: "Check what is live now and pin your next two must-see events.",     icon: "calendar.badge.clock",             destination: .schedule),
        .init(title: "Acquire guest intel",  detail: "Find one must-meet guest and add them to your favorites.",           icon: "person.2.badge.gearshape",         destination: .guests),
        .init(title: "Confirm your route",   detail: "Open maps now so you are not navigating under red alert.",           icon: "map.fill",                         destination: .map),
        .init(title: "Run a command check",  detail: "Use Hello, Computer and ask: happening now.",                        icon: "sparkles",                         destination: .computer)
    ]

    static let preConPresets: [HomeMissionDirective] = [
        .init(title: "Build your first mission plan", detail: "Star 3 events now so your convention weekend is pre-locked.",          icon: "calendar.badge.plus",              destination: .schedule),
        .init(title: "Research your away team",       detail: "Pick your must-see guests and favorite them before Day 1.",            icon: "person.2.crop.square.stack",       destination: .guests),
        .init(title: "Learn the deck layout",         detail: "Open the map now to reduce navigation stress on arrival.",             icon: "map.circle.fill",                  destination: .map),
        .init(title: "Run a command dry-run",         detail: "Open Hello, Computer and test: build my day.",                         icon: "sparkles.rectangle.stack.fill",    destination: .computer)
    ]
}

// MARK: - Convention Day Context

private struct ConventionDayContext {
    let label: String
    let detail: String

    static func forToday(reference: Date = .now) -> ConventionDayContext {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: reference)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            return .init(label: "Convention", detail: "Schedule not available.")
        }
        if year == 2026, month == 6 {
            switch day {
            case 12: return .init(label: "Day 1 • Friday",  detail: "Opening ceremonies & evening programming.")
            case 13: return .init(label: "Day 2 • Saturday", detail: "Full schedule of panels & events.")
            case 14: return .init(label: "Day 3 • Sunday",  detail: "Closing panels & final photo ops.")
            default: break
            }
        }
        let start = cal.date(from: DateComponents(timeZone: .current, year: 2026, month: 6, day: 12)) ?? reference
        if reference < start {
            return .init(label: "Convention schedule", detail: "Browse panels, guests, and events.")
        } else {
            return .init(label: "After the con",  detail: "Thanks for joining us at Trek Long Island!")
        }
    }
}

// Simple flavor "stardate" — just for fun, not canon.
private func stardateString(for date: Date = .now) -> String {
    TLIStardate.formatted(for: date)
}

// MARK: - Isolated Notification Badge (prevents HomeView full re-render)

/// Observes NotificationManager independently so badge changes don't cause
/// the entire HomeView body to re-evaluate.
private struct NotificationBadgeView: View {
    @ObservedObject var manager: NotificationManager

    var body: some View {
        if manager.unreadCount > 0 {
            Text(manager.unreadCount > 99 ? "99+" : "\(manager.unreadCount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, manager.unreadCount > 9 ? 6 : 0)
                .frame(minWidth: 16, minHeight: 16)
                .background(Capsule().fill(Color.red))
                .accessibilityLabel("\(manager.unreadCount) unread announcements")
        }
    }
}

// MARK: - HomeView

@MainActor
struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    // Boothby: no longer using a sheet — we open directly via UIApplication
    // Carousel
    @StateObject private var scheduleLoader = ICSLoader()
    @State private var currentSlideIndex: Int = 0
    @State private var isCarouselRunning: Bool = false

    // Mission control
    @State private var missionDirective: HomeMissionDirective = HomeMissionDirective.preConPresets[0]
    @State private var mappedEvents: [RisaScheduleEvent] = []

    // Easter eggs
    @State private var stardateTapCount: Int = 0
    @State private var welcomeTapCount: Int = 0
    @State private var picardDayTapCount: Int = 0
    @State private var nasaTapCount: Int = 0
    @State private var tribbleTapCount: Int = 0
    @State private var borgTapCount: Int = 0
    @State private var wormholeTapCount: Int = 0
    @State private var daystromTapCount: Int = 0
    @State private var viewportSize: CGSize = .zero
    @State private var easterEggMessage: String = ""
    @State private var showEasterEggAlert: Bool = false

    // Readiness — cached to avoid per-render CSV splitting
    @State private var cachedReadinessScore: Int = 8

    @AppStorage("TLI.Profile.displayName") private var displayName: String = ""
    @AppStorage("TLI.Profile.rank") private var rankRaw: String = TLIProfileRank.captain.rawValue
    @AppStorage("TLI.Profile.division") private var divisionRaw: String = TLIProfileDivision.command.rawValue
    @AppStorage("TLI.Profile.role") private var roleRaw: String = TLIProfileRole.firstTimer.rawValue
    @AppStorage("TLI.Profile.objectives") private var objectivesRaw: String = ""
    @AppStorage("TLI.Schedule.favoriteIDsCSV")  private var favoriteEventIDsCSV:   String = ""
    @AppStorage("TLI.Guests.favoriteSlugsCSV")  private var favoriteGuestSlugsCSV: String = ""
    @AppStorage("TLI.Home.showMissionControl") private var showMissionControl: Bool = true
    @AppStorage("TLI.Home.dismissedPicardDayYear") private var dismissedPicardDayYear = 0
    @AppStorage("TLI.EasterEggs.welcome") private var foundWelcomeSignal = false
    @AppStorage("TLI.EasterEggs.stardate") private var foundStardateSignal = false
    @AppStorage("TLI.EasterEggs.picardDay") private var foundPicardDaySignal = false
    @AppStorage("TLI.EasterEggs.teaOrder") private var foundTeaOrderSignal = false
    @AppStorage("TLI.EasterEggs.makeItSo") private var foundMakeItSoSignal = false
    @AppStorage("TLI.EasterEggs.nasaSignal") private var foundNASASignal = false
    @AppStorage("TLI.EasterEggs.starfleetSecurity") private var foundStarfleetSecuritySignal = false
    @AppStorage("TLI.EasterEggs.tribbles") private var foundTribbleSignal = false
    @AppStorage("TLI.EasterEggs.daystrom") private var foundDaystromSignal = false
    @AppStorage("TLI.EasterEggs.borg") private var foundBorgSignal = false
    @AppStorage("TLI.EasterEggs.wormhole") private var foundWormholeSignal = false

    private let heroSlides = HeroSlide.sample
    private var dayContext: ConventionDayContext { .forToday() }

    private var layoutWidth: CGFloat {
        viewportSize.width > 0 ? viewportSize.width : 390
    }
    private var layoutHeight: CGFloat {
        viewportSize.height > 0 ? viewportSize.height : 844
    }
    private var isCompactPhoneLayout: Bool {
        hSizeClass != .regular && TLILayout.isSmallPhone(width: layoutWidth, height: layoutHeight)
    }
    private var homeTopPadding: CGFloat {
        if RisaTheme.isLCARSThemeEnabled {
            return isCompactPhoneLayout ? 14 : 10
        }
        return isCompactPhoneLayout ? 10 : 6
    }
    private var heroAspectRatio: CGFloat {
        if hSizeClass == .regular { return 1.55 }
        return isCompactPhoneLayout ? 1.16 : 1.40
    }
    private var isIPadLayout: Bool { hSizeClass == .regular }
    private var selectedRank: TLIProfileRank { TLIProfileRank(rawValue: rankRaw) ?? .captain }
    private var selectedDivision: TLIProfileDivision { TLIProfileDivision(rawValue: divisionRaw) ?? .command }
    private var selectedRole: TLIProfileRole { TLIProfileRole(rawValue: roleRaw) ?? .firstTimer }
    private var selectedObjectives: Set<TLIProfileObjective> { TLIProfilePreferences.objectives(from: objectivesRaw) }
    private var captainName: String { TLIProfilePreferences.captainName(from: displayName) }
    private var commandName: String { TLIProfilePreferences.commandName(rank: selectedRank, displayName: displayName) }
    private var activeObjectives: Set<TLIProfileObjective> {
        selectedObjectives.isEmpty ? Set(TLIProfileObjective.defaultSet) : selectedObjectives
    }
    private var activeMissionPresets: [HomeMissionDirective] {
        personalizedMissionPresets()
    }
    private var favoriteEventIDs: Set<String> {
        Set(
            favoriteEventIDsCSV
                .split(separator: "|")
                .map(String.init)
        )
    }
    private var favoriteScheduleEvents: [RisaScheduleEvent] {
        mappedEvents
            .filter { favoriteEventIDs.contains($0.id) }
            .sorted { $0.startDate < $1.startDate }
    }
    private var nextFavoriteEvent: RisaScheduleEvent? {
        let now = Date.now
        return favoriteScheduleEvents.first { $0.endDate >= now }
    }
    private var liveEvents: [RisaScheduleEvent] {
        let now = Date.now
        return mappedEvents
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
    }
    private var upcomingEvents: [RisaScheduleEvent] {
        let now = Date.now
        return mappedEvents
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
    }
    private var nextGeneralEvent: RisaScheduleEvent? {
        upcomingEvents.first(where: { !isVendorRoomOpening($0) }) ?? upcomingEvents.first
    }
    private var nextAdditionalEvents: [RisaScheduleEvent] {
        guard let primary = nextGeneralEvent else { return [] }
        return upcomingEvents
            .filter { $0.id != primary.id }
            .filter { !isVendorRoomOpening($0) || upcomingEvents.count <= 3 }
            .prefix(3)
            .map { $0 }
    }
    private var shouldShowTicketPresaleBanner: Bool {
        let calendar = Calendar.current
        let cutoff = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9)) ?? .distantPast
        return Date.now < cutoff
    }
    private var shouldShowPicardDayBanner: Bool {
        (TLIConventionDates.isCaptainPicardDay() && dismissedPicardDayYear != currentYear) || foundPicardDaySignal
    }
    private var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }
    private var isConventionWeekend: Bool {
        switch dayContext.label {
        case "Day 1 • Friday", "Day 2 • Saturday", "Day 3 • Sunday":
            return true
        default:
            return false
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: TLILayout.sectionSpacing(for: layoutWidth)) {
                headerSection
                if shouldShowPicardDayBanner {
                    picardDaySection
                }
                if isConventionWeekend {
                    nasaSignalSection
                }
                strangeNewWorldsPremiereBanner
                conDayEssentialsSection
                if showMissionControl {
                    missionControlSection
                }
                operationalStatusSection
                heroCarouselSection
                primaryActionsSection
                if shouldShowTicketPresaleBanner {
                    ticketPresaleBanner
                }

                if isIPadLayout {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            todayHighlightSection
                            gettingStartedSection
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        VStack(alignment: .leading, spacing: 20) {
                            infoAndPoliciesSection
                            sponsorsSection
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                } else {
                    todayHighlightSection
                    gettingStartedSection
                    infoAndPoliciesSection
                    sponsorsSection
                }

            }
            .adaptiveContentWidth(
                maxWidth: TLILayout.defaultContentMaxWidth,
                horizontalPadding: TLILayout.compactHorizontalPadding(for: layoutWidth),
                verticalPadding: 0
            )
            .padding(.top, homeTopPadding)
            .padding(.bottom, isCompactPhoneLayout ? 8 : 12)
        }
        .contentMargins(.top, homeTopPadding, for: .scrollContent)
        .scrollIndicators(.hidden)
        .background(backgroundView.ignoresSafeArea())
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        viewportSize = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newValue in
                        viewportSize = newValue
                    }
            }
        }
        .alert("Hidden Frequency Detected", isPresented: $showEasterEggAlert) {
            Button("Acknowledge") {}
        } message: {
            Text(easterEggMessage)
        }
        .onAppear {
            isCarouselRunning = true
            missionDirective = activeMissionPresets.randomElement() ?? activeMissionPresets[0]
            recomputeReadiness()
            if scheduleLoader.events.isEmpty {
                scheduleLoader.load()
            } else if mappedEvents.isEmpty {
                mappedEvents = mapHomeEvents(scheduleLoader.events)
            }
        }
        .onDisappear {
            isCarouselRunning = false
        }
        .onChange(of: dayContext.label) { _, _ in
            recomputeReadiness()
            missionDirective = activeMissionPresets.randomElement() ?? missionDirective
        }
        .onChange(of: favoriteEventIDsCSV)   { _, _ in recomputeReadiness() }
        .onChange(of: favoriteGuestSlugsCSV) { _, _ in recomputeReadiness() }
        .onChange(of: roleRaw) { _, _ in
            missionDirective = activeMissionPresets.randomElement() ?? missionDirective
        }
        .onChange(of: objectivesRaw) { _, _ in
            missionDirective = activeMissionPresets.randomElement() ?? missionDirective
        }
        .onReceive(NotificationManager.shared.$unreadCount) { _ in
            recomputeReadiness()
        }
        .onReceive(scheduleLoader.$events) { events in
            mappedEvents = mapHomeEvents(events)
        }
    }

    // MARK: - Readiness (cached)

    private func recomputeReadiness() {
        let favoriteEvents  = favoriteEventIDsCSV.split(separator: "|").count
        let favoriteGuests  = favoriteGuestSlugsCSV.split(separator: "|").count
        let unread          = NotificationManager.shared.unreadCount
        let dayBonus: Int
        switch dayContext.label {
        case "Day 1 • Friday", "Day 2 • Saturday", "Day 3 • Sunday": dayBonus = 20
        case "Convention schedule":                                    dayBonus = 12
        default:                                                       dayBonus = 5
        }
        cachedReadinessScore = min(100, max(8, (favoriteEvents * 12) + (favoriteGuests * 8) + min(unread, 5) * 4 + dayBonus))
    }

    private var missionReadinessSummary: String {
        if cachedReadinessScore >= 80 {
            return "Bridge status: ready for red-alert schedule shifts."
        } else if cachedReadinessScore >= 50 {
            return "Bridge status: stable. Add more favorites for faster navigation."
        } else {
            return "Bridge status: configure your mission plan to avoid missing key panels."
        }
    }

    private func personalizedMissionPresets() -> [HomeMissionDirective] {
        var directives = HomeMissionDirective.livePresets

        if activeObjectives.contains(.neverMissPanels) {
            directives.append(
                .init(
                    title: "Protect your must-see panels",
                    detail: "Open Schedule and star the sessions you would regret missing most.",
                    icon: "calendar.badge.exclamationmark",
                    destination: .schedule
                )
            )
        }

        if activeObjectives.contains(.meetGuests) {
            directives.append(
                .init(
                    title: "Lock in guest sightings",
                    detail: "Visit Explore and favorite the guests your away team wants to meet.",
                    icon: "person.crop.circle.badge.star",
                    destination: .guests
                )
            )
        }

        if activeObjectives.contains(.navigateFast) {
            directives.append(
                .init(
                    title: "Plot your route",
                    detail: "Open the map and figure out your next move before the hallway traffic does.",
                    icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                    destination: .map
                )
            )
        }

        if activeObjectives.contains(.stayUpdated) {
            directives.append(
                .init(
                    title: "Ask for the latest",
                    detail: "Open Hello, Computer and ask what changed so your bridge stays current.",
                    icon: "sparkles.rectangle.stack.fill",
                    destination: .computer
                )
            )
        }

        if activeObjectives.contains(.familyFriendly) {
            directives.append(
                .init(
                    title: "Keep the crew synchronized",
                    detail: "Check Bridge and Map together so your family crew can pivot without a scramble.",
                    icon: "figure.2.and.child.holdinghands",
                    destination: .map
                )
            )
        }

        if selectedRole == .volunteer {
            directives.append(
                .init(
                    title: "Stay ahead of live changes",
                    detail: "Use Hello, Computer and announcements as your fastest operational status board.",
                    icon: "person.crop.circle.badge.checkmark",
                    destination: .computer
                )
            )
        }

        return directives
    }

    private func mapHomeEvents(_ parsed: [ICSParsedEvent]) -> [RisaScheduleEvent] {
        parsed
            .map { event in
                RisaScheduleEvent(
                    id: event.id.uuidString,
                    title: event.title,
                    description: event.description,
                    location: event.room,
                    room: event.room,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    day: homeWeekdayFormatter.string(from: event.startDate),
                    isFavorite: favoriteEventIDs.contains(event.id.uuidString)
                )
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func eventTimeRange(_ event: RisaScheduleEvent) -> String {
        "\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened))"
    }

    private func nextUpSubtitle(for event: RisaScheduleEvent) -> String {
        let relative = event.startDate.formatted(.relative(presentation: .named))
        return "\(relative) • \(eventTimeRange(event)) • \(event.room)"
    }

    private func isVendorRoomOpening(_ event: RisaScheduleEvent) -> Bool {
        let normalizedTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedTitle == "vendor room opening" || normalizedTitle == "vendor hall opening"
    }

    private func happeningNowSummary(for events: [RisaScheduleEvent]) -> String {
        guard let first = events.first else {
            return "No sessions are live right now."
        }

        if events.count == 1 {
            return "\(first.title) is active until \(first.endDate.formatted(date: .omitted, time: .shortened)) in \(first.room)."
        }

        return "\(first.title) and \(events.count - 1) more sessions are live right now."
    }
}

// MARK: - Sections

private extension HomeView {

    var operationalStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Operations Feed" : "Bridge status",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Live mission telemetry" : "Live convention intelligence"
            )

            let columns = [
                GridItem(.adaptive(minimum: hSizeClass == .regular ? 260 : 220), spacing: 14, alignment: .top)
            ]

            LazyVGrid(columns: columns, spacing: 14) {
                nextUpCard
                happeningNowCard
            }
        }
        .onLongPressGesture(minimumDuration: 1.1) {
            revealEasterEgg(from: .starfleetSecurity)
        }
    }

    // MARK: Header

    var nextUpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Next up", systemImage: "calendar.badge.clock")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                Spacer(minLength: 8)
                if let event = nextFavoriteEvent {
                    Text(favoriteEventIDs.contains(event.id) ? "Saved plan" : "")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))
                }
            }

            if let event = nextFavoriteEvent ?? nextGeneralEvent {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                    .lineLimit(2)

                Text(nextUpSubtitle(for: event))
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text(nextFavoriteEvent != nil
                     ? "Your saved itinerary is ready. Open Schedule to review details or make changes."
                     : "No saved events yet. Open Schedule and star a few anchors so the bridge can guide you better.")
                    .font(.caption)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                if nextFavoriteEvent == nil, !nextAdditionalEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Also upcoming")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RisaTheme.textPrimary(colorScheme))

                        ForEach(nextAdditionalEvents) { additionalEvent in
                            Text("\(additionalEvent.startDate.formatted(date: .omitted, time: .shortened)) • \(additionalEvent.title)")
                                .font(.caption)
                                .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                                .lineLimit(2)
                        }
                    }
                }

                NavigationLink {
                    ScheduleView()
                } label: {
                    Label(
                        nextFavoriteEvent != nil
                            ? (RisaTheme.isLCARSThemeEnabled ? "Open saved timeline" : "Open my plan")
                            : (RisaTheme.isLCARSThemeEnabled ? "Assemble timeline" : "Build my plan"),
                        systemImage: "arrow.right.circle.fill"
                    )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(RisaTheme.accent(colorScheme))
            } else {
                Text("No upcoming schedule data is available yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                Text("The bridge will surface your next mission here once schedule feeds are loaded.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .tliCardStyle(scheme: colorScheme, cornerRadius: 18)
    }

    var happeningNowCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Happening now", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                Spacer(minLength: 8)
                Text(liveEvents.isEmpty ? "Standby" : "\(liveEvents.count) live")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(liveEvents.isEmpty ? RisaTheme.textSecondary(colorScheme) : RisaTheme.accentSecondary(colorScheme))
            }

            if !liveEvents.isEmpty {
                Text(happeningNowSummary(for: liveEvents))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(liveEvents.prefix(3)) { event in
                        Text("• \(event.title) • \(event.room)")
                            .font(.footnote)
                            .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                            .lineLimit(2)
                    }
                }
            } else if let event = nextGeneralEvent {
                Text("The convention floor is quiet right now.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                Text("Next scheduled mission: \(event.title) at \(event.startDate.formatted(date: .omitted, time: .shortened)) in \(event.room).")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No live sessions detected.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                Text("Once schedule feeds are available, this card will surface panels, appearances, and room activity in real time.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink {
                ScheduleView()
            } label: {
                Label(RisaTheme.isLCARSThemeEnabled ? "Open timeline" : "Open schedule", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .tliCardStyle(scheme: colorScheme, cornerRadius: 18)
        .onTapGesture {
            borgTapCount += 1
            if borgTapCount >= 4 {
                revealEasterEgg(from: .borg)
                borgTapCount = 0
            }
        }
    }

    var ticketPresaleBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "ticket.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))

                    Text("2027 Tickets")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))

                    Text("On sale")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(RisaTheme.chipBackground(colorScheme).opacity(0.92)))
                        .foregroundStyle(RisaTheme.chipForeground(colorScheme))
                }

                Text("Buy 2027 Trek Long Island tickets on the official Square ticket site.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                UIApplication.shared.open(TicketPurchaseLinks.admissionURL)
            } label: {
                HStack(spacing: 6) {
                    Text("Tickets")
                    Image(systemName: "arrow.up.right")
                }
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(RisaTheme.accent(colorScheme))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(RisaTheme.cardBackground(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    RisaTheme.accent(colorScheme).opacity(0.7),
                                    RisaTheme.accentGold(colorScheme).opacity(0.5),
                                    RisaTheme.cardStroke(colorScheme).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    var strangeNewWorldsPremiereBanner: some View {
        Group {
            if isIPadLayout {
                HStack(alignment: .center, spacing: 12) {
                    premiereCopy

                    Spacer(minLength: 8)

                    premiereDateBadge
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    premiereCopy

                    HStack(spacing: 10) {
                        premiereDateBadge
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(RisaTheme.cardBackground(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    RisaTheme.accentSecondary(colorScheme).opacity(0.75),
                                    RisaTheme.accent(colorScheme).opacity(0.55),
                                    RisaTheme.cardStroke(colorScheme).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    private var picardDaySection: some View {
        PicardDayBannerView {
            withAnimation(.easeInOut(duration: 0.25)) {
                dismissedPicardDayYear = currentYear
            }
        }
        .onTapGesture {
            picardDayTapCount += 1
            if picardDayTapCount >= 4 {
                revealEasterEgg(from: .picardDay)
                picardDayTapCount = 0
                dismissedPicardDayYear = 0
            }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            revealEasterEgg(from: .picardDay)
            dismissedPicardDayYear = 0
            picardDayTapCount = 0
        }
        .accessibilityHint("Tap several times for a hidden Captain Picard Day signal")
    }

    private var nasaSignalSection: some View {
        VStack(alignment: .leading, spacing: isCompactPhoneLayout ? 14 : 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    RisaTheme.accentSecondary(colorScheme).opacity(0.24),
                                    RisaTheme.accent(colorScheme).opacity(0.10),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 26
                            )
                        )
                        .frame(width: 54, height: 54)

                    Image(systemName: "dot.scope")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Orbital Science Relay")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(colorScheme))

                    Text("Convention-only NASA signal. Mission architecture, astronomy, and hopeful future-tech energy are on the air.")
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack {
                Spacer(minLength: 0)
                Text("LIVE")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(RisaTheme.chipBackground(colorScheme).opacity(0.92))
                    )
                    .foregroundStyle(RisaTheme.textPrimary(colorScheme))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(RisaTheme.cardBackground(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            RisaTheme.accentSecondary(colorScheme).opacity(0.7),
                            RisaTheme.accent(colorScheme).opacity(0.45),
                            RisaTheme.cardStroke(colorScheme).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            nasaTapCount += 1
            if nasaTapCount >= 3 {
                revealEasterEgg(from: .nasa)
                nasaTapCount = 0
            }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            revealEasterEgg(from: .nasa)
            nasaTapCount = 0
        }
        .accessibilityHint("Tap or long-press for a hidden NASA-related transmission")
    }

    private var premiereCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(RisaTheme.accent(colorScheme).opacity(0.14))
                        .frame(width: 24, height: 24)

                    Image(systemName: "sparkles.tv.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))
                }

                Text("Premiere Date")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RisaTheme.accent(colorScheme))

                Text("Strange New Worlds")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(RisaTheme.chipBackground(colorScheme).opacity(0.92)))
                    .foregroundStyle(RisaTheme.chipForeground(colorScheme))
            }

            Text("'Star Trek: Strange New Worlds' returns July 23.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("Mark your calendar for the next transmission from the Enterprise crew.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var premiereDateBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "calendar.badge.clock")
                .imageScale(.small)
            Text("July 23")
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(RisaTheme.textPrimary(colorScheme))
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            Capsule(style: .continuous)
                .fill(RisaTheme.accentSecondary(colorScheme).opacity(0.18))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(RisaTheme.accentSecondary(colorScheme).opacity(0.55), lineWidth: 1)
        )
        .fixedSize()
    }

    var headerSection: some View {
        let stardate      = stardateString()
        let textPrimary   = RisaTheme.textPrimary(colorScheme)
        let textSecondary = RisaTheme.textSecondary(colorScheme)

        return VStack(alignment: .leading, spacing: isCompactPhoneLayout ? 12 : 14) {
            TLIBrandHeader(
                title: TLIBrandIdentity.heroTitle,
                subtitle: RisaTheme.isLCARSThemeEnabled
                    ? "Command the weekend with a cleaner bridge view."
                    : TLIBrandIdentity.heroTagline,
                supportingText: TLIBrandIdentity.rallyingCall,
                compact: isCompactPhoneLayout
            )

            Text("WELCOME")
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: 12, weight: .heavy, design: .monospaced)
                        : .caption.weight(.bold)
                )
                .textCase(.uppercase)
                .foregroundStyle(textSecondary)
                .onTapGesture {
                    welcomeTapCount += 1
                    if welcomeTapCount >= 3 {
                        revealEasterEgg(from: .welcome)
                        welcomeTapCount = 0
                    }
                }

            Text(RisaTheme.isLCARSThemeEnabled ? "Station ready, \(commandName)" : "Welcome back, \(commandName)")
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: isCompactPhoneLayout ? 28 : 32, weight: .black, design: .monospaced)
                        : .system(.title, design: .rounded).weight(.bold)
                )
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .foregroundStyle(textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("\(selectedRank.title) • \(selectedDivision.title) • \(selectedRole.title) • Hyatt Regency Long Island • June 12–14")
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: 13, weight: .semibold, design: .monospaced)
                        : .subheadline
                )
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .imageScale(.medium)
                        .foregroundStyle(textPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayContext.label)
                            .font(
                                RisaTheme.isLCARSThemeEnabled
                                    ? .system(size: 13, weight: .bold, design: .monospaced)
                                    : .subheadline.weight(.semibold)
                            )
                            .foregroundStyle(textPrimary)
                        Text(dayContext.detail)
                            .font(.footnote)
                            .foregroundStyle(textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RisaTheme.chipBackground(colorScheme).opacity(0.84))
                )

                HStack {
                    Spacer(minLength: 0)

                    Button {
                        stardateTapCount += 1
                        if stardateTapCount >= 5 {
                            revealEasterEgg(from: .stardate)
                            stardateTapCount = 0
                        }
                    } label: {
                        Label {
                            Text("Stardate \(stardate)")
                                .font(.caption.weight(.medium))
                        } icon: {
                            Image(systemName: "sparkles")
                                .imageScale(.small)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(RisaTheme.chipBackground(colorScheme)))
                        .foregroundStyle(RisaTheme.chipForeground(colorScheme))
                        .tliButtonShapeOutline(
                            shape: Capsule(style: .continuous),
                            strokeColor: differentiateWithoutColor ? RisaTheme.textPrimary(colorScheme) : RisaTheme.accent(colorScheme)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stardate \(stardate)")
                    .accessibilityHint("Tap five times for a hidden message")
                    .animation(showButtonShapes || reduceMotion ? nil : .default, value: stardateTapCount)
                    .onLongPressGesture(minimumDuration: 1.0) {
                        revealEasterEgg(from: .tea)
                    }
                }
            }

            Text(selectedRole.guidance)
                .font(.subheadline)
                .foregroundStyle(textSecondary)
                .lineSpacing(2)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(isCompactPhoneLayout ? 16 : 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(TLITheme.cardBackground(colorScheme).opacity(colorScheme == .dark ? 0.86 : 0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(TLIBrandIdentity.crestGradient(colorScheme).opacity(colorScheme == .dark ? 0.34 : 0.20), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(TLITheme.border(colorScheme).opacity(0.18), lineWidth: TLITheme.hairline)
        )
        .shadow(
            color: TLITheme.cardShadowColor(colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }

    // MARK: Mission Control

    var missionControlSection: some View {
        let isCompactMissionLayout = hSizeClass != .regular
        let contentSpacing = isCompactMissionLayout ? 10.0 : 12.0
        let cardPadding = isCompactMissionLayout ? 14.0 : 16.0

        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Command Protocols" : "Mission Control",
                flavor: RisaTheme.isLCARSThemeEnabled ? "\(commandName)'s active duty panel" : "\(commandName)'s personal command deck"
            )

            VStack(alignment: .leading, spacing: contentSpacing + 2) {
                if isCompactPhoneLayout {
                    VStack(spacing: 8) {
                        MissionMetricChip(
                            title: "Day state",
                            value: dayContext.label,
                            icon: "calendar",
                            scheme: colorScheme,
                            compact: isCompactMissionLayout
                        )
                        MissionMetricChip(
                            title: "Objective",
                            value: activeObjectives.first?.title ?? "Explore freely",
                            icon: "scope",
                            scheme: colorScheme,
                            compact: isCompactMissionLayout
                        )
                    }
                } else {
                    HStack(spacing: 8) {
                        MissionMetricChip(
                            title: "Day state",
                            value: dayContext.label,
                            icon: "calendar",
                            scheme: colorScheme,
                            compact: isCompactMissionLayout
                        )
                        MissionMetricChip(
                            title: "Objective",
                            value: activeObjectives.first?.title ?? "Explore freely",
                            icon: "scope",
                            scheme: colorScheme,
                            compact: isCompactMissionLayout
                        )
                    }
                }

                HStack(alignment: .top, spacing: isCompactMissionLayout ? 10 : 12) {
                    ZStack {
                        Circle()
                            .fill(RisaTheme.chipBackground(colorScheme))
                            .frame(width: isCompactMissionLayout ? 30 : 38, height: isCompactMissionLayout ? 30 : 38)
                        Image(systemName: missionDirective.icon)
                            .foregroundStyle(RisaTheme.accent(colorScheme))
                            .font(isCompactMissionLayout ? .subheadline : .headline)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(missionDirective.title)
                            .font((isCompactMissionLayout ? Font.footnote : .subheadline).weight(.semibold))
                            .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                            .lineLimit(2)
                        Text(missionDirective.detail)
                            .font(isCompactMissionLayout ? .caption : .footnote)
                            .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                            .lineLimit(isCompactMissionLayout ? 2 : nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority focus: \(TLIProfilePreferences.objectivesSummary(from: selectedObjectives))")
                        .font((isCompactMissionLayout ? Font.caption2 : .caption).weight(.semibold))
                        .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                        .lineLimit(isCompactMissionLayout ? 1 : 2)

                    HStack {
                        Text("Readiness")
                            .font((isCompactMissionLayout ? Font.caption : .footnote).weight(.semibold))
                            .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                        Spacer()
                        Text("\(cachedReadinessScore)%")
                            .font((isCompactMissionLayout ? Font.caption : .footnote).monospacedDigit().weight(.semibold))
                            .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                    }
                    ProgressView(value: Double(cachedReadinessScore), total: 100)
                        .tint(RisaTheme.accent(colorScheme))
                    Text(missionReadinessSummary)
                        .font(isCompactMissionLayout ? .caption2 : .caption)
                        .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                        .lineLimit(isCompactMissionLayout ? 2 : nil)
                }

                if isCompactPhoneLayout {
                    VStack(spacing: 10) {
                        missionEngageButton(isCompactMissionLayout: isCompactMissionLayout)
                        missionRerollButton(isCompactMissionLayout: isCompactMissionLayout)
                    }
                } else {
                    HStack(spacing: 10) {
                        missionEngageButton(isCompactMissionLayout: isCompactMissionLayout)
                        missionRerollButton(isCompactMissionLayout: isCompactMissionLayout)
                    }
                }
            }
            .padding(cardPadding)
            .tliCardStyle(scheme: colorScheme, cornerRadius: 18)
            .overlay(alignment: .topLeading) {
                Capsule(style: .continuous)
                    .fill(TLITheme.sectionAccentGradient(colorScheme))
                    .frame(width: 60, height: 7)
                    .padding(.top, 12)
                    .padding(.leading, 14)
            }
        }
    }

    @ViewBuilder
    var missionDestinationView: some View {
        switch missionDirective.destination {
        case .schedule: ScheduleView()
        case .guests:   ExploreView()
        case .map:      MapsView()
        case .computer: HelloComputerView()
        }
    }

    private func missionEngageButton(isCompactMissionLayout: Bool) -> some View {
        NavigationLink {
            missionDestinationView
        } label: {
            Label(RisaTheme.isLCARSThemeEnabled ? "Authorize" : "Engage", systemImage: "paperplane.fill")
                .font((isCompactMissionLayout ? Font.footnote : .subheadline).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompactMissionLayout ? 8 : 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(RisaTheme.accent(colorScheme))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    revealEasterEgg(from: .makeItSo)
                }
        )
    }

    private func missionRerollButton(isCompactMissionLayout: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                missionDirective = activeMissionPresets.randomElement() ?? missionDirective
            }
        } label: {
            Label(RisaTheme.isLCARSThemeEnabled ? "Recompute" : "Reroll", systemImage: "shuffle")
                .font((isCompactMissionLayout ? Font.footnote : .subheadline).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompactMissionLayout ? 8 : 12)
        }
        .buttonStyle(.bordered)
        .onLongPressGesture(minimumDuration: 1.1) {
            revealEasterEgg(from: .reroll)
        }
    }

    // MARK: Carousel
    // - task re-keyed on isCarouselRunning so cancellation is immediate on .onDisappear
    // - HeroSlideCard wrapped in EquatableView to skip re-renders on unrelated state changes

    var heroCarouselSection: some View {
        // Progress bar overlaid inside the carousel frame — no separate dots row below.
        ZStack(alignment: .bottom) {
            TabView(selection: $currentSlideIndex) {
                ForEach(Array(heroSlides.enumerated()), id: \.element.id) { index, slide in
                    EquatableView(content: HeroSlideCard(slide: slide, scheme: colorScheme))
                        .tag(index)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(slide.title). \(slide.subtitle)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .aspectRatio(heroAspectRatio, contentMode: .fit)
            .frame(maxHeight: hSizeClass == .regular ? 520 : (isCompactPhoneLayout ? 280 : 360))
            .task(id: isCarouselRunning) {
                guard isCarouselRunning, heroSlides.count > 1, !reduceMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(4500))
                    guard !Task.isCancelled else { break }
                    withAnimation(.easeInOut(duration: 0.55)) {
                        currentSlideIndex = (currentSlideIndex + 1) % heroSlides.count
                    }
                }
            }

            // Thin segmented progress bar — sits on top of the image near the bottom
            HStack(spacing: 4) {
                ForEach(Array(heroSlides.enumerated()), id: \.element.id) { index, _ in
                    Capsule()
                        .fill(
                            index == currentSlideIndex
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(Color.white.opacity(0.35))
                        )
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.22), value: currentSlideIndex)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .accessibilityHidden(true)
        }
    }

    // MARK: Primary Actions
    // NotificationBadgeView is a separate @ObservedObject child so badge updates
    // do not trigger a full HomeView body re-evaluation.

    var conDayEssentialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Con Day Essentials" : "Con day essentials",
                flavor: RisaTheme.isLCARSThemeEnabled ? "High-priority convention channels" : "The things you will reach for fastest"
            )

            LazyVGrid(columns: TLILayout.quickLinkColumns(for: hSizeClass, availableWidth: layoutWidth), spacing: 12) {
                essentialLink(title: "My Plan", subtitle: "Next saved event", icon: "list.bullet.clipboard.fill") {
                    MyMissionPlanView()
                }

                essentialLink(title: "Ops & Autos", subtitle: "Photo/signing reminders", icon: "camera.on.rectangle.fill") {
                    PhotoAutographTrackerView()
                }

                essentialLink(title: "Map", subtitle: "Rooms and floor", icon: "map.fill") {
                    MapsView()
                }

                HomeAlertsEssentialLink(scheme: colorScheme)

                essentialLink(title: "Support", subtitle: "Help and lost items", icon: "cross.case.fill") {
                    SupportCenterView()
                }
            }
        }
    }

    private func essentialLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    RisaTheme.accent(colorScheme).opacity(0.28),
                                    RisaTheme.accent(colorScheme).opacity(0.08)
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: 20
                            )
                        )
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(colorScheme))
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(colorScheme))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RisaTheme.textSecondary(colorScheme))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RisaTheme.textSecondary(colorScheme).opacity(0.55))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .background(TLITheme.controlShape(cornerRadius: 18).fill(RisaTheme.cardBackground(colorScheme)))
            .overlay(
                TLITheme.controlShape(cornerRadius: 18)
                    .stroke(RisaTheme.cardStroke(colorScheme).opacity(0.62), lineWidth: TLITheme.hairline)
            )
            .contentShape(TLITheme.controlShape(cornerRadius: 18))
        }
        .buttonStyle(EssentialLinkPressStyle())
    }

    var primaryActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Command Shortcuts" : "Quick actions",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Primary access channels" : "Primary mission controls"
            )

            let columns = TLILayout.quickLinkColumns(for: hSizeClass, availableWidth: layoutWidth)

            LazyVGrid(columns: columns, spacing: hSizeClass == .regular ? 16 : (isCompactPhoneLayout ? 12 : 14)) {

                NavigationLink { MyMissionPlanView() } label: {
                    PrimaryActionTile(
                        icon: "list.bullet.clipboard.fill",
                        title: "My Mission Plan",
                        subtitle: "Saved events, guests, and your next move",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Priority" : "Personal plan",
                        scheme: colorScheme
                    )
                }

                NavigationLink { ScheduleView() } label: {
                    PrimaryActionTile(
                        icon: "calendar",
                        title: RisaTheme.isLCARSThemeEnabled ? TLILCARSLabel.schedule : "Full Schedule",
                        subtitle: "Browse by day, track, or room",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Timeline" : "Mission log",
                        scheme: colorScheme
                    )
                }

                NavigationLink { ExploreView() } label: {
                    PrimaryActionTile(
                        icon: "person.2.fill",
                        title: RisaTheme.isLCARSThemeEnabled ? TLILCARSLabel.explore : "Explore",
                        subtitle: RisaTheme.isLCARSThemeEnabled ? "Personnel files, registries, deck references, and support channels" : "Guests, exhibitors, sponsors, and fan support",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Databanks" : "Crew & contacts",
                        scheme: colorScheme
                    )
                }

                NavigationLink { MapsView() } label: {
                    PrimaryActionTile(
                        icon: "map",
                        title: RisaTheme.isLCARSThemeEnabled ? TLILCARSLabel.map : "Convention Map",
                        subtitle: RisaTheme.isLCARSThemeEnabled ? "Track decks, rooms, and approach routes" : "Find stages, rooms, and vendors",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Schematic" : "Deck layout",
                        scheme: colorScheme
                    )
                }

                NavigationLink { HelloComputerView() } label: {
                    PrimaryActionTile(
                        icon: "sparkles",
                        title: "Hello, Computer",
                        subtitle: "Your convention concierge for schedules and logistics",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Core" : "Concierge",
                        scheme: colorScheme
                    )
                }

                NavigationLink { Section31View() } label: {
                    PrimaryActionTile(
                        icon: "checkmark.seal.fill",
                        title: "Section 31",
                        subtitle: "Transparency notes and supporting evidence",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Records" : "Evidence",
                        scheme: colorScheme
                    )
                }

                NavigationLink { SpecialEventsView() } label: {
                    PrimaryActionTile(
                        icon: "sparkles.rectangle.stack.fill",
                        title: "Special Events",
                        subtitle: "Featured experiences, parties, and ticketed extras",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Highlights" : "Official",
                        scheme: colorScheme
                    )
                }

                NavigationLink { NotificationsView() } label: {
                    // Badge count displayed via isolated child view
                    PrimaryActionTileWithBadge(
                        icon: "bell.badge",
                        title: RisaTheme.isLCARSThemeEnabled ? "Priority Alerts" : "Announcements",
                        subtitle: "Live updates from staff",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Alert feed" : "Live",
                        scheme: colorScheme
                    )
                }

                NavigationLink { OpsCenterView() } label: {
                    PrimaryActionTile(
                        icon: "person.crop.rectangle.stack.fill",
                        title: "Ops Center",
                        subtitle: "Live ops, comms, tickets, CRM",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Control room" : "Bridge portal",
                        scheme: colorScheme
                    )
                }

                NavigationLink { SupportCenterView() } label: {
                    PrimaryActionTile(
                        icon: "cross.case.fill",
                        title: RisaTheme.isLCARSThemeEnabled ? "Support Services" : "Support Center",
                        subtitle: "Medical, safety, lost & found",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Aid station" : "Assistance",
                        scheme: colorScheme
                    )
                }

                Button {
                    UIApplication.shared.open(TicketPurchaseLinks.admissionURL)
                } label: {
                    PrimaryActionTile(
                        icon: "ticket.fill",
                        title: RisaTheme.isLCARSThemeEnabled ? "Access Passes" : "Tickets",
                        subtitle: "Buy 2027 tickets on the official ticket site",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Authorization" : "On sale",
                        scheme: colorScheme
                    )
                }

                Button {
                    UIApplication.shared.open(TicketPurchaseLinks.photoOpsURL)
                } label: {
                    PrimaryActionTile(
                        icon: "camera.viewfinder",
                        title: "Photo Ops",
                        subtitle: "Buy photo-op tickets on the official site",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Imaging" : "Book now",
                        scheme: colorScheme
                    )
                }

                if TicketPurchaseLinks.areAutographPreSalesAvailable() {
                    Button {
                        UIApplication.shared.open(TicketPurchaseLinks.autographPreSalesURL)
                    } label: {
                        PrimaryActionTile(
                            icon: "pencil.and.scribble",
                            title: "Autograph Pre-Sales",
                            subtitle: "Pre-order autographs through The Autograph Concierge",
                            badge: RisaTheme.isLCARSThemeEnabled ? "Signatures" : "Pre-order",
                            scheme: colorScheme
                        )
                    }
                } else {
                    PrimaryActionTile(
                        icon: "pencil.slash",
                        title: "Autograph Pre-Sales Closed",
                        subtitle: "Check guest tables and autograph hall staff during the convention",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Closed" : "At event",
                        scheme: colorScheme
                    )
                }

                // MARK: Boothby — Fixed: opens directly in Safari, no sheet/SafariView
                Button {
                    if let url = URL(string: "https://www.reddit.com/r/DaystromInstitute/comments/jqlnbw/boothby_isnt_just_a_groundskeeper_hes_an_integral/") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    PrimaryActionTile(
                        icon: "safari",
                        title: "Boothby",
                        subtitle: "The Boothby Test",
                        badge: RisaTheme.isLCARSThemeEnabled ? "Reference" : "Database",
                        scheme: colorScheme
                    )
                }
            }
        }
    }

    // MARK: Live At A Glance

    var todayHighlightSection: some View {
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Live Readout" : "Live at a glance",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Current bridge traffic" : "What's active right now"
            )

            HomeInfoCard(
                symbol: "antenna.radiowaves.left.and.right",
                title: "Live transmissions",
                detail: "Use the \"Happening Now\" filter in the Schedule tab to see active missions on each stage.",
                bullets: [
                    "Tap the star in Schedule to build your personal mission plan.",
                    "Recheck announcements between panels for room changes and fresh drops."
                ],
                tint: RisaTheme.accent(colorScheme),
                scheme: colorScheme
            )
        }
        .onTapGesture {
            wormholeTapCount += 1
            if wormholeTapCount >= 3 {
                revealEasterEgg(from: .wormhole)
                wormholeTapCount = 0
            }
        }
    }

    // MARK: Getting Started

    var gettingStartedSection: some View {
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Cadet Orientation" : "New to Trek Long Island?",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Onboarding for incoming personnel" : "Onboarding for new crew"
            )

            HomeInfoCard(
                symbol: "figure.wave.circle.fill",
                title: "Fastest way to get oriented",
                detail: "Start in Schedule, then pin a few anchors so the rest of the weekend becomes easier to navigate.",
                bullets: [
                    "Tap a session for guests, room, and accessibility notes.",
                    "Watch for banners at the top of the app for red-alert updates."
                ],
                tint: RisaTheme.accentSecondary(colorScheme),
                scheme: colorScheme
            )
        }
    }

    // MARK: Info & Policies

    var infoAndPoliciesSection: some View {
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Protocol & Policy" : "Info & policies",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Operational guidance and regulations" : "Starfleet-style rules of engagement"
            )

            HomeInfoCard(
                symbol: "checkmark.shield.fill",
                title: "Rules of engagement",
                detail: "Core event policies live on the website and in Settings so you can verify them quickly during the weekend.",
                bullets: [
                    "Photo op, autograph, and line procedures appear inside guest and vendor listings.",
                    "Accessibility services and quiet spaces can be found through the Information Desk."
                ],
                tint: RisaTheme.accentGold(colorScheme),
                scheme: colorScheme
            )
        }
        .onTapGesture {
            daystromTapCount += 1
            if daystromTapCount >= 3 {
                revealEasterEgg(from: .daystrom)
                daystromTapCount = 0
            }
        }
    }

    // MARK: Sponsors

    var sponsorsSection: some View {
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: RisaTheme.isLCARSThemeEnabled ? "Alliance Support" : "Presented with support from",
                flavor: RisaTheme.isLCARSThemeEnabled ? "Partnering worlds and organizations" : "Our allied worlds"
            )

            HomeInfoCard(
                symbol: "person.3.sequence.fill",
                title: "Allied worlds",
                detail: "Guests, staff, volunteers, partners, vendors, and sponsors all keep the convention humming.",
                bullets: [
                    "Visit the Sponsors tab for featured support across the fleet.",
                    "The full sponsor list remains available on the event website."
                ],
                tint: RisaTheme.textPrimary(colorScheme),
                scheme: colorScheme
            )
        }
        .onTapGesture {
            tribbleTapCount += 1
            if tribbleTapCount >= 5 {
                revealEasterEgg(from: .tribbles)
                tribbleTapCount = 0
            }
        }
    }

    // MARK: Background
    // drawingGroup() flattens the ZStack into a single Metal layer, reducing GPU overdraw on scroll.

    var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: RisaTheme.backgroundGradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("RisaStarfieldBackground")
                .resizable()
                .scaledToFill()
                .opacity(colorScheme == .dark ? 0.44 : 0.16)
        }
        .drawingGroup()
    }

    // MARK: Easter Eggs

    private enum EasterEggSource {
        case stardate, welcome, reroll, picardDay, tea, makeItSo, nasa
        case starfleetSecurity, tribbles, daystrom, borg, wormhole
    }

    private func revealEasterEgg(from source: EasterEggSource) {
        let stardateLines = [
            "Captain's log: You found a hidden subspace channel. The universe rewards curiosity.",
            "Temporal variance detected. Do not feed tribbles after midnight.",
            "Computer note: This mission is now officially classified as fun."
        ]
        let welcomeLines = [
            "Authorization denied. Self-destruct remains disabled for fan safety.",
            "Hailing frequencies open. Morale levels: excellent.",
            "Directive update: Hydration is canonical."
        ]
        let rerollLines = [
            "Q is disappointed you needed a reroll. Proceed anyway.",
            "Warp core stable. Random mission assigned with dramatic flair.",
            "Ferengi advisory: Budget shields at maximum."
        ]
        let picardDayLines = [
            "Captain Picard Day protocol acknowledged. The children have made a banner and Picard is enduring it with admirable dignity.",
            "Picard Day unlocked. Somewhere, a flute solo and a hand-drawn Enterprise are being judged with diplomatic grace.",
            "Jean-Luc advisory: Accept the sash, praise the art, and never underestimate a school celebration."
        ]
        let teaLines = [
            "Replicator confirmed: Earl Grey, hot.",
            "Tea service routed to ready room. Biscuit pairing remains unofficial.",
            "Beverage protocol complete. The captain prefers his tea with absolute confidence."
        ]
        let makeItSoLines = [
            "Command accepted: Make it so.",
            "Bridge crew acknowledged your order with suspiciously perfect timing.",
            "Execution confirmed. Leadership posture: calm, direct, very Jean-Luc."
        ]
        let nasaLines = [
            "Orbital relay opened. Trek optimism and NASA engineering remain extremely compatible.",
            "Mission architect uplink confirmed. Real-world space science just hailed your convention weekend.",
            "Deep-space note: exploration is still a team sport, whether the badge says Starfleet or NASA."
        ]
        let starfleetSecurityLines = [
            "Security division acknowledged. Yellow alert protocols remain stylishly intact.",
            "Starfleet Security sweep complete. Corridor patrols are calm, alert, and deeply suspicious of contraband tribbles.",
            "Security note: keep your combadge visible and your phaser on metaphorical stun."
        ]
        let tribbleLines = [
            "Warning: a tribble has entered the sponsor registry and is multiplying with suspicious efficiency.",
            "Trouble with tribbles detected. Inventory control has collapsed into soft chirping.",
            "Biological advisory: do not feed the fuzzy sponsor unless you want seventeen more by lunch."
        ]
        let daystromLines = [
            "Daystrom Station archive unlocked. Someone really should label the dangerous drawers more clearly.",
            "Daystrom note: every storage wing is safe until a rogue android proves otherwise.",
            "Research uplink complete. The station insists this was all perfectly contained."
        ]
        let borgLines = [
            "Collective traffic detected. Your distinctiveness remains temporarily your own.",
            "Borg signal intercepted. Resistance is not recommended, but witty commentary is still allowed.",
            "Subspace advisory: the hive noticed your schedule taps and would like your itinerary."
        ]
        let wormholeLines = [
            "Bajoran wormhole aperture stabilized. Traffic to the Gamma Quadrant is purely recreational at this time.",
            "Celestial Temple reading confirmed. Linear time remains optional for prophets and convention planning.",
            "Wormhole contact achieved. Please avoid asking the Prophets for room directions."
        ]

        switch source {
        case .stardate: easterEggMessage = stardateLines.randomElement() ?? stardateLines[0]
        case .welcome:  easterEggMessage = welcomeLines.randomElement()  ?? welcomeLines[0]
        case .reroll:   easterEggMessage = rerollLines.randomElement()   ?? rerollLines[0]
        case .picardDay: easterEggMessage = picardDayLines.randomElement() ?? picardDayLines[0]
        case .tea: easterEggMessage = teaLines.randomElement() ?? teaLines[0]
        case .makeItSo: easterEggMessage = makeItSoLines.randomElement() ?? makeItSoLines[0]
        case .nasa: easterEggMessage = nasaLines.randomElement() ?? nasaLines[0]
        case .starfleetSecurity: easterEggMessage = starfleetSecurityLines.randomElement() ?? starfleetSecurityLines[0]
        case .tribbles: easterEggMessage = tribbleLines.randomElement() ?? tribbleLines[0]
        case .daystrom: easterEggMessage = daystromLines.randomElement() ?? daystromLines[0]
        case .borg: easterEggMessage = borgLines.randomElement() ?? borgLines[0]
        case .wormhole: easterEggMessage = wormholeLines.randomElement() ?? wormholeLines[0]
        }

        switch source {
        case .welcome:
            foundWelcomeSignal = true
        case .stardate:
            foundStardateSignal = true
        case .picardDay:
            foundPicardDaySignal = true
        case .tea:
            foundTeaOrderSignal = true
        case .makeItSo:
            foundMakeItSoSignal = true
        case .nasa:
            foundNASASignal = true
        case .starfleetSecurity:
            foundStarfleetSecuritySignal = true
        case .tribbles:
            foundTribbleSignal = true
        case .daystrom:
            foundDaystromSignal = true
        case .borg:
            foundBorgSignal = true
        case .wormhole:
            foundWormholeSignal = true
        case .reroll:
            break
        }

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        showEasterEggAlert = true
    }
}

private struct EssentialLinkPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.13), value: configuration.isPressed)
    }
}

private struct HomeAlertsEssentialLink: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    let scheme: ColorScheme

    var body: some View {
        NavigationLink {
            NotificationsView()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(RisaTheme.accent(scheme).opacity(0.14))
                    Image(systemName: "bell.badge.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Alerts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))
                        .lineLimit(1)

                    Text(notificationManager.unreadCount > 0 ? "\(notificationManager.unreadCount) unread" : "Staff updates")
                        .font(.caption)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .background(TLITheme.controlShape(cornerRadius: 18).fill(RisaTheme.cardBackground(scheme)))
            .overlay(
                TLITheme.controlShape(cornerRadius: 18)
                    .stroke(RisaTheme.cardStroke(scheme).opacity(0.62), lineWidth: TLITheme.hairline)
            )
            .contentShape(TLITheme.controlShape(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero Slide Card
// Conforms to Equatable so EquatableView can skip re-renders when slide + scheme unchanged.

private struct HeroSlideCard: View, Equatable {
    let slide: HeroSlide
    let scheme: ColorScheme

    static func == (lhs: HeroSlideCard, rhs: HeroSlideCard) -> Bool {
        lhs.slide == rhs.slide && lhs.scheme == rhs.scheme
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                // Image
                Image(slide.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .drawingGroup()

                // Vignette — bottom-only, lighter than before
                LinearGradient(
                    colors: [
                        .black.opacity(0),
                        .black.opacity(0.08),
                        .black.opacity(scheme == .dark ? 0.68 : 0.52)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Frosted-glass caption pill at bottom-leading
                VStack(alignment: .leading, spacing: 3) {
                    Text(slide.title)
                        .font(.system(.subheadline, design: .default).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(slide.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.6)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.65), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(scheme == .dark ? 0.50 : 0.16),
            radius: scheme == .dark ? 16 : 10,
            x: 0, y: 6
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Announcements Tile with Isolated Badge Observer
// Wraps PrimaryActionTile and reads unreadCount from a child @ObservedObject
// so HomeView's body is NOT re-evaluated on badge changes.

private struct PrimaryActionTileWithBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String
    let scheme: ColorScheme

    @ObservedObject private var manager = NotificationManager.shared

    var body: some View {
        PrimaryActionTile(
            icon: icon,
            title: title,
            subtitle: subtitle,
            badge: badge,
            scheme: scheme,
            alertCount: manager.unreadCount
        )
    }
}

// MARK: - Reusable: SectionHeader

private struct SectionHeader: View {
    let title: String
    let flavor: String?

    @Environment(\.colorScheme) private var scheme

    init(title: String, flavor: String? = nil) {
        self.title = title
        self.flavor = flavor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left accent stripe — replaces the small pill shapes
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(TLITheme.sectionAccentGradient(scheme))
                .frame(width: 4, height: 22)
                .accessibilityHidden(true)

            Text(title)
                .font(
                    RisaTheme.isLCARSThemeEnabled
                        ? .system(size: 17, weight: .bold, design: .monospaced)
                        : .headline.weight(.semibold)
                )
                .foregroundStyle(RisaTheme.textPrimary(scheme))
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 4)

            if let flavor {
                Text(flavor)
                    .font(
                        RisaTheme.isLCARSThemeEnabled
                            ? .system(size: 10, weight: .semibold, design: .monospaced)
                            : .caption2.weight(.medium)
                    )
                    .foregroundStyle(RisaTheme.textMuted(scheme))
                    .lineLimit(1)
            }
        }
    }
}

private struct MissionMetricChip: View {
    let title: String
    let value: String
    let icon: String
    let scheme: ColorScheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(RisaTheme.accent(scheme).opacity(0.12))
                        .frame(width: compact ? 20 : 24, height: compact ? 20 : 24)

                    Image(systemName: icon)
                        .font((compact ? Font.caption2 : .caption).weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }

                Text(title)
            }
            .font((compact ? Font.caption2 : .caption).weight(.semibold))
            .foregroundStyle(RisaTheme.textSecondary(scheme))

            Text(value)
                .font((compact ? Font.footnote : .subheadline).weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 9 : 12)
        .background(TLITheme.controlShape(cornerRadius: 16).fill(RisaTheme.chipBackground(scheme).opacity(0.88)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 16)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.4), lineWidth: 0.8)
        )
    }
}

private struct HomeInfoCard: View {
    let symbol: String
    let title: String
    let detail: String
    let bullets: [String]
    let tint: Color
    let scheme: ColorScheme

    var body: some View {
        let lcarsTopInset = RisaTheme.isLCARSThemeEnabled ? 14.0 : 0.0

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(scheme == .dark ? 0.22 : 0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: symbol)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, lcarsTopInset)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(tint)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.footnote)
                            .foregroundStyle(RisaTheme.textSecondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .tliCardStyle(scheme: scheme, cornerRadius: 18)
        .tliLCARSPanelChrome(accent: tint)
    }
}

// MARK: - Reusable: PrimaryActionTile

private struct PrimaryActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String
    let scheme: ColorScheme
    var alertCount: Int = 0

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // Left accent stripe
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            RisaTheme.accent(scheme),
                            RisaTheme.accentSecondary(scheme).opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 6)
                .padding(.trailing, 11)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Icon — larger, richer gradient
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RisaTheme.accent(scheme).opacity(0.38),
                                        RisaTheme.accentSecondary(scheme).opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(RisaTheme.accent(scheme).opacity(0.22), lineWidth: 1)
                            )

                        Image(systemName: icon)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RisaTheme.accent(scheme))
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        if alertCount > 0 {
                            Text(alertCount > 99 ? "99+" : "\(alertCount)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, alertCount > 9 ? 6 : 0)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Capsule().fill(Color.red))
                                .accessibilityLabel("\(alertCount) unread announcements")
                        }

                        // Quieter badge
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(RisaTheme.chipBackground(scheme).opacity(0.80))
                            )
                            .foregroundStyle(RisaTheme.chipForeground(scheme).opacity(0.80))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .lineLimit(2)
                }

                HStack(spacing: 5) {
                    Text(RisaTheme.isLCARSThemeEnabled ? "Access" : "Open")
                        .font(.caption.weight(.medium))
                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(RisaTheme.accent(scheme).opacity(0.78))
            }
            .padding(.trailing, 14)
        }
        .padding(.vertical, 14)
        .padding(.leading, 10)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .tliQuickActionCardStyle(scheme: scheme, cornerRadius: 22)
        .tliLCARSPanelChrome(accent: RisaTheme.accent(scheme))
        .contentShape(TLITheme.panelShape(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to open")
    }

    private var accessibilitySummary: String {
        alertCount > 0 ? "\(title). \(subtitle). \(alertCount) unread items." : "\(title). \(subtitle)."
    }
}

// MARK: - Card Styling

private extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder then trueTransform: (Self) -> TrueContent,
        @ViewBuilder else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }

    func tliCardStyle(scheme: ColorScheme, cornerRadius: CGFloat) -> some View {
        self
            .background(
                TLITheme.panelShape(cornerRadius: cornerRadius)
                    .fill(RisaTheme.cardBackground(scheme))
            )
            .overlay(
                TLITheme.panelShape(cornerRadius: cornerRadius)
                    .stroke(RisaTheme.cardStroke(scheme).opacity(0.65), lineWidth: 0.8)
            )
            .shadow(
                color: Color.black.opacity(scheme == .dark ? 0.28 : 0.10),
                radius: scheme == .dark ? 10 : 6,
                x: 0, y: 3
            )
            .clipShape(TLITheme.panelShape(cornerRadius: cornerRadius))
    }

    func tliQuickActionCardStyle(scheme: ColorScheme, cornerRadius: CGFloat) -> some View {
        self
            .background(
                TLITheme.panelShape(cornerRadius: cornerRadius)
                    .fill(RisaTheme.cardBackground(scheme))
                    .overlay(
                        TLITheme.panelShape(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        RisaTheme.accent(scheme).opacity(0.35),
                                        RisaTheme.accentSecondary(scheme).opacity(0.20),
                                        RisaTheme.cardStroke(scheme).opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(scheme == .dark ? 0.30 : 0.10),
                radius: scheme == .dark ? 10 : 6,
                x: 0, y: 3
            )
            .clipShape(TLITheme.panelShape(cornerRadius: cornerRadius))
    }
}
