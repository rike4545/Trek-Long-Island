// Copyright Bryan Carroll. All rights reserved.
//
//  ScheduleView.swift
//  Trek Long Island
//
//  Risa / TLI–themed schedule
//  • ICS-backed via ICSLoader / ICSParsedEvent
//  • Day filters: All / per-day / Favorites
//  • Track filter chips (multi-select)
//  • Search (title / description / location / room)
//  • Local favorites (in-memory)
//

import SwiftUI

// MARK: - Formatters

private let weekdayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "EEEE" // Friday, Saturday, Sunday
    return df
}()

private let scheduleRelativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
}()

private let scheduleTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - Convention date window

/// Active convention window.
private let scheduleConventionCalendar = Calendar(identifier: .gregorian)

private let activeConventionWindow: (start: Date, end: Date) = {
    let calendar = scheduleConventionCalendar

    var startComponents = DateComponents()
    startComponents.calendar = calendar
    startComponents.timeZone = .current
    startComponents.year = 2026
    startComponents.month = 6
    startComponents.day = 12
    startComponents.hour = 0
    startComponents.minute = 0
    startComponents.second = 0

    var endComponents = DateComponents()
    endComponents.calendar = calendar
    endComponents.timeZone = .current
    endComponents.year = 2026
    endComponents.month = 6
    endComponents.day = 14
    endComponents.hour = 23
    endComponents.minute = 59
    endComponents.second = 59

    return (
        start: startComponents.date ?? .distantPast,
        end: endComponents.date ?? .distantFuture
    )
}()

private let conventionStartDate: Date = activeConventionWindow.start
private let conventionEndDate: Date = activeConventionWindow.end

// MARK: - Mapping ICS → RisaScheduleEvent

/// Map parsed ICS events into RisaScheduleEvent, clamped to the
/// convention window (any event that overlaps the window is kept).
private func mapEvents(_ parsed: [ICSParsedEvent]) -> [RisaScheduleEvent] {
    var out: [RisaScheduleEvent] = []
    out.reserveCapacity(parsed.count)

    for p in parsed {
        let start = p.startDate
        let end   = p.endDate

        // Keep events that overlap the convention window:
        // [start, end] ∩ [conventionStartDate, conventionEndDate] ≠ ∅
        let overlapsWindow =
            start <= conventionEndDate &&
            end   >= conventionStartDate

        guard overlapsWindow else { continue }

        let id = p.id.uuidString
        let dayString = weekdayFormatter.string(from: start)

        out.append(
            RisaScheduleEvent(
                id: id,
                title: p.title,
                description: p.description,
                location: p.room, // use room label as location
                room: p.room,
                startDate: start,
                endDate: end,
                day: dayString,
                isFavorite: false
            )
        )
    }

    return out.sorted { $0.startDate < $1.startDate }
}

// MARK: - Day filter model

private enum DayFilter: Hashable, Identifiable {
    case all
    case day(String)
    case favorites

    var id: String { label }

    var label: String {
        switch self {
        case .all:        return "All Days"
        case .day(let d): return d
        case .favorites:  return "Favorites"
        }
    }

    var isFavorites: Bool {
        if case .favorites = self { return true }
        return false
    }
}

// MARK: - Schedule View

@MainActor
struct ScheduleView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.sizeCategory) private var sizeCategory

    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var networkMonitor = TLINetworkMonitor.shared
    @StateObject private var loader = ICSLoader()

    /// Minimum gap between automatic schedule refetches (foreground / tab return).
    private let autoRefreshMinInterval: TimeInterval = 90
    @State private var lastAutoRefresh: Date = .distantPast

    @State private var selectedDay: DayFilter = .all
    @State private var selectedFeeds: Set<String> = []   // multi-select rooms
    @State private var searchText: String = ""
    @State private var favorites: Set<String> = []
    @AppStorage("TLI.Schedule.favoriteIDsCSV") private var storedFavoritesCSV: String = ""
    @AppStorage("TLI.NotificationPrefs.trackedRoomsCSV") private var trackedRoomsCSV: String = ""

    // NEW: event currently being viewed in a sheet
    @State private var selectedEvent: RisaScheduleEvent?
    @State private var mappedEvents: [RisaScheduleEvent] = []

    // MARK: - Derived data

    private var dayFilters: [DayFilter] {
        var set = Set(mappedEvents.map { $0.day })

        let preferredOrder = ["Friday", "Saturday", "Sunday"]
        var items: [DayFilter] = [.all]

        for d in preferredOrder where set.contains(d) {
            items.append(.day(d))
            set.remove(d)
        }

        for d in set.sorted() {
            items.append(.day(d))
        }

        items.append(.favorites)
        return items
    }

    private var feedOptions: [String] {
        let rooms = Set(mappedEvents.map { $0.room }.filter { !$0.isEmpty })
        if rooms.isEmpty {
            // Fallback: use configured feeds so chips exist even before load
            return loader.labeledRoomURLs.keys.sorted()
        }
        return Array(rooms).sorted()
    }

    private var dayFiltered: [RisaScheduleEvent] {
        switch selectedDay {
        case .all:
            return mappedEvents
        case .favorites:
            return mappedEvents.filter { favorites.contains($0.id) }
        case .day(let name):
            return mappedEvents.filter { $0.day == name }
        }
    }

    private var feedFiltered: [RisaScheduleEvent] {
        guard !selectedFeeds.isEmpty else { return dayFiltered }

        let filtered = dayFiltered.filter { selectedFeeds.contains($0.room) }

        // If track filtering would zero out the list but the day has events,
        // fall back so the user still sees something.
        if filtered.isEmpty, !dayFiltered.isEmpty {
            return dayFiltered
        }
        return filtered
    }

    private var filteredEvents: [RisaScheduleEvent] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return feedFiltered }

        return feedFiltered.filter { e in
            e.title.localizedCaseInsensitiveContains(q) ||
            e.description.localizedCaseInsensitiveContains(q) ||
            e.location.localizedCaseInsensitiveContains(q) ||
            e.room.localizedCaseInsensitiveContains(q)
        }
    }

    private var happeningNowEvents: [RisaScheduleEvent] {
        let now = Date()
        let active = filteredEvents
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
        return prioritizeFavorites(in: active)
    }

    private var nextUpEvents: [RisaScheduleEvent] {
        let now = Date()
        let upcoming = filteredEvents
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
        return prioritizeFavorites(in: upcoming)
    }

    private var nextHourEvents: [RisaScheduleEvent] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return nextUpEvents.filter { $0.startDate <= cutoff }
    }

    private var laterEvents: [RisaScheduleEvent] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return nextUpEvents.filter { $0.startDate > cutoff }
    }

    private var favoriteEvents: [RisaScheduleEvent] {
        mappedEvents
            .filter { favorites.contains($0.id) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var upcomingFavoriteEvents: [RisaScheduleEvent] {
        let now = Date()
        return favoriteEvents
            .filter { $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }

    private var favoriteConflicts: [PlanConflict] {
        guard favoriteEvents.count > 1 else { return [] }
        var conflicts: [PlanConflict] = []
        for i in 0..<favoriteEvents.count {
            for j in (i + 1)..<favoriteEvents.count {
                let lhs = favoriteEvents[i]
                let rhs = favoriteEvents[j]
                let overlaps = lhs.startDate < rhs.endDate && rhs.startDate < lhs.endDate
                if overlaps {
                    conflicts.append(PlanConflict(first: lhs, second: rhs))
                }
            }
        }
        return conflicts
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                        .padding(.top, 8)

                    if shouldShowOfflineStatusCard {
                        offlineStatusCard
                    }

                    filterDeck

                    if !filteredEvents.isEmpty {
                        missionTimelineSection
                    }

                    if !favoriteEvents.isEmpty {
                        myPlanCard
                    }

                    eventsList
                        .padding(.top, 4)

                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: 20,
                    verticalPadding: 0
                )
                // Extra space so cards don’t feel glued to the tab bar
                .padding(.bottom, 40)
            }
            .refreshable { await pullToRefresh() }
        }
        .navigationTitle(TLILCARSLabel.schedule)
        .navigationBarTitleDisplayMode(.inline)
        .risaNavBarStyle()
        .task {
            if loader.events.isEmpty {
                loader.load()
            }
            if mappedEvents.isEmpty, !loader.events.isEmpty {
                mappedEvents = mapEvents(loader.events)
            }
            if favorites.isEmpty, !storedFavoritesCSV.isEmpty {
                favorites = Set(storedFavoritesCSV.split(separator: "|").map(String.init))
            }
            if selectedFeeds.isEmpty, !trackedRoomsCSV.isEmpty {
                selectedFeeds = Set(trackedRoomsCSV.split(separator: "|").map(String.init))
            }
        }
        .onAppear { maybeAutoRefresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { maybeAutoRefresh() }
        }
        .onReceive(loader.$events) { events in
            mappedEvents = mapEvents(events)
            // When events arrive, choose sane default tracks.
            let rooms = Set(mappedEvents.map { $0.room }.filter { !$0.isEmpty })
            if selectedFeeds.isEmpty {
                selectedFeeds = rooms
            } else {
                let newSelection = selectedFeeds.intersection(rooms)
                selectedFeeds = newSelection.isEmpty ? rooms : newSelection
            }
        }
        .onChange(of: favorites) { _, newValue in
            storedFavoritesCSV = newValue.sorted().joined(separator: "|")
        }
        .onChange(of: storedFavoritesCSV) { _, newValue in
            let syncedFavorites = Set(newValue.split(separator: "|").map(String.init))
            if syncedFavorites != favorites {
                favorites = syncedFavorites
            }
        }
        .onChange(of: selectedFeeds) { _, newValue in
            trackedRoomsCSV = newValue.sorted().joined(separator: "|")
        }
        .onChange(of: trackedRoomsCSV) { _, newValue in
            let syncedFeeds = Set(newValue.split(separator: "|").map(String.init))
            if syncedFeeds != selectedFeeds {
                selectedFeeds = syncedFeeds
            }
        }
        // NEW: Detail sheet for tapped events
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(
                event: event,
                isFavorite: favorites.contains(event.id),
                scheme: scheme
            ) {
                toggleFavorite(event)
            }
        }
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
            if scheme == .dark {
                Color.black.opacity(0.30)
            }
        }
        .ignoresSafeArea()
    }

    private var shouldShowOfflineStatusCard: Bool {
        !networkMonitor.isConnected || loader.loadedFromCache || loader.lastLoadErrorMessage != nil
    }

    private var offlineStatusDetail: String {
        if let error = loader.lastLoadErrorMessage, !error.isEmpty {
            return error
        }
        if !networkMonitor.isConnected {
            return "You are offline. Cached timeline entries remain available when possible."
        }
        if loader.loadedFromCache {
            return "Showing cached schedule while live feeds reconnect."
        }
        return "Schedule connectivity is healthy."
    }

    private var offlineStatusCard: some View {
        TLIOfflineStatusCard(
            title: "Schedule Data Link",
            detail: offlineStatusDetail,
            isOffline: !networkMonitor.isConnected,
            lastSyncDate: loader.lastSyncDate,
            loadedFromCache: loader.loadedFromCache,
            actionTitle: "Retry Sync",
            action: {
                loader.retry(from: Array(selectedFeeds))
            }
        )
    }

    private var header: some View {
        let isCompactLayout = hSizeClass != .regular

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Capsule(style: .continuous)
                    .fill(TLITheme.sectionAccentGradient(scheme))
                    .frame(width: 76, height: 8)

                Capsule(style: .continuous)
                    .fill(TLITheme.chipBackground(scheme).opacity(0.9))
                    .frame(width: 32, height: 8)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(RisaTheme.isLCARSThemeEnabled ? "Mission Timeline" : "Mission Schedule")
                    .font(
                        RisaTheme.isLCARSThemeEnabled
                            ? .system(size: isCompactLayout ? 26 : 34, weight: .black, design: .monospaced)
                            : .largeTitle.bold()
                    )
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .risaTextHalo()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(RisaTheme.isLCARSThemeEnabled
                     ? "Track panels, detect conflicts, and keep your away team on-mission."
                     : "See what is happening now, filter the deck fast, and keep your saved plan in sync.")
                    .font(.callout)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                scheduleMetricChip(
                    title: "Showing",
                    value: "\(filteredEvents.count)",
                    icon: "list.bullet.rectangle.portrait"
                )

                scheduleMetricChip(
                    title: "Saved",
                    value: "\(favoriteEvents.count)",
                    icon: "star.fill"
                )

                scheduleMetricChip(
                    title: "Live",
                    value: "\(happeningNowEvents.count)",
                    icon: "dot.radiowaves.left.and.right"
                )
            }

            HStack(alignment: .center, spacing: 10) {
                Label("Stardate \(scheduleStardate())", systemImage: "sparkles")
                    .font(.footnote.monospacedDigit().weight(.medium))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(TLITheme.chipBackground(scheme).opacity(0.88))
                    )

                if let lastSync = loader.lastSyncDate {
                    Label(
                        loader.loadedFromCache
                            ? "Offline cache • \(lastSync.formatted(date: .abbreviated, time: .shortened))"
                            : "Synced \(lastSync.formatted(date: .abbreviated, time: .shortened))",
                        systemImage: loader.loadedFromCache ? "icloud.slash" : "arrow.trianglehead.clockwise"
                    )
                    .font(RisaTheme.isLCARSThemeEnabled ? .system(size: 12, weight: .semibold, design: .monospaced) : .caption.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .tliPanelSurface(
            cornerRadius: 28,
            fillOpacity: 1,
            borderOpacity: 0.92,
            shadowRadius: 16,
            shadowY: 8
        )
        .tliLCARSPanelChrome(accent: RisaTheme.accent(scheme), contentTopInset: RisaTheme.isLCARSThemeEnabled ? 8 : 0)
    }

    private var filterDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(RisaTheme.isLCARSThemeEnabled ? "Filter Matrix" : "Refine Your Timeline")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(filterSummaryText)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

            DayChipsRow(
                days: dayFilters,
                selectedDay: $selectedDay
            )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Search")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                ThemedSearchField(text: $searchText, scheme: scheme)
            }

            FeedChipsRow(
                feeds: feedOptions,
                selected: $selectedFeeds,
                scheme: scheme
            )
        }
        .padding(16)
        .tliPanelSurface(
            cornerRadius: 24,
            fillOpacity: 0.98,
            borderOpacity: 0.82,
            shadowRadius: 12,
            shadowY: 6
        )
    }

    private var filterSummaryText: String {
        let dayLabel = selectedDay.label
        let roomCount = selectedFeeds.count
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            return "\(dayLabel) • \(roomCount) room\(roomCount == 1 ? "" : "s") tracked • Searching for “\(query)”"
        }

        return "\(dayLabel) • \(roomCount) room\(roomCount == 1 ? "" : "s") tracked"
    }

    private func scheduleMetricChip(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TLITheme.accent(scheme))

                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(title == "Live" ? "Happening now" : title == "Saved" ? "Bookmarked plan" : "Filtered sessions")
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.chipBackground(scheme).opacity(0.92)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
        )
    }

    private var eventsList: some View {
        Group {
            if loader.isLoading && mappedEvents.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Synchronizing convention manifest…")
                        .font(.callout)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
            } else if mappedEvents.isEmpty {
                // No events loaded at all. Distinguish "the grid isn't published yet"
                // from "something went wrong" — before the convention the calendars
                // are legitimately empty, and a warning triangle there reads as an
                // outage and sends people to support for a non-problem.
                let isAwaitingPublication = Date() < TLIEventInfo.current.startDate
                VStack(spacing: 10) {
                    Image(systemName: isAwaitingPublication ? "calendar.badge.clock" : "exclamationmark.triangle")
                        .imageScale(.large)
                        .foregroundStyle(Color.primary.opacity(0.72))

                    Text(isAwaitingPublication
                         ? (RisaTheme.isLCARSThemeEnabled
                            ? "Mission timeline for \(TLIEventInfo.current.displayRange) has not been transmitted yet."
                            : "Programming for \(TLIEventInfo.current.displayRange) hasn't been published yet.")
                         : (RisaTheme.isLCARSThemeEnabled
                            ? "No mission timeline data is available at the moment."
                            : "No schedule data is available at the moment."))
                        .font(.callout)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if isAwaitingPublication {
                        Text("Panels, photo ops, and events appear here as soon as the schedule is released.")
                            .font(.footnote)
                            .foregroundStyle(Color.primary.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 32)
            } else if filteredEvents.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredEvents) { event in
                        RisaScheduleCard(
                            event: event,
                            isFavorite: favorites.contains(event.id)
                        ) {
                            toggleFavorite(event)
                        }
                        // NEW: tap anywhere on the card to view details
                        .onTapGesture {
                            selectedEvent = event
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .imageScale(.large)
                .foregroundStyle(Color.primary.opacity(0.72))
            Text(RisaTheme.isLCARSThemeEnabled ? "No timeline entries match the current scan, Captain." : "No events match your current scan, Captain.")
                .font(.callout)
                .foregroundStyle(Color.primary.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var myPlanCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(RisaTheme.isLCARSThemeEnabled ? "Saved Timeline" : "My Plan", systemImage: "checklist")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer(minLength: 8)
                Text("\(favoriteEvents.count) saved")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            if let next = upcomingFavoriteEvents.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next mission: \(next.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .lineLimit(2)
                    Text(relativeStartText(for: next))
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                    if shouldLeaveNow(for: next) {
                        Text("Leave now to reach \(next.room) on time.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TLITheme.accent(scheme))
                    }
                }
            } else {
                Text("No upcoming favorites in the current schedule window.")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            if !favoriteConflicts.isEmpty {
                Divider().overlay(TLITheme.border(scheme))
                HStack {
                    Text("Conflicts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    Spacer(minLength: 8)
                    Text("\(favoriteConflicts.count) overlap\(favoriteConflicts.count == 1 ? "" : "s")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }
                ForEach(favoriteConflicts.prefix(3)) { conflict in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(conflict.first.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .lineLimit(2)
                        Text("overlaps \(conflict.second.title)")
                            .font(.footnote)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .lineLimit(2)
                    }
                }
            } else if favoriteEvents.count > 1 {
                Divider().overlay(TLITheme.border(scheme))
                Text("No conflicts detected in your saved itinerary.")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
        }
        .padding(14)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private var missionTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(RisaTheme.isLCARSThemeEnabled ? "Timeline Status" : "Mission Timeline")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer(minLength: 8)
                Text(timelineSummary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))
            }

            VStack(alignment: .leading, spacing: 14) {
                TimelineGroupCard(
                    title: "Now",
                    systemImage: "dot.radiowaves.left.and.right",
                    accent: TLITheme.accent(scheme),
                    events: Array(happeningNowEvents.prefix(3)),
                    emptyMessage: "No sessions are live for the current filters.",
                    scheme: scheme,
                    favoriteIDs: favorites,
                    onSelect: { selectedEvent = $0 }
                )

                TimelineGroupCard(
                    title: "Next",
                    systemImage: "calendar.badge.clock",
                    accent: .orange,
                    events: Array(nextHourEvents.prefix(3)),
                    emptyMessage: "Nothing starts in the next hour.",
                    scheme: scheme,
                    favoriteIDs: favorites,
                    onSelect: { selectedEvent = $0 }
                )

                TimelineGroupCard(
                    title: "Later",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    accent: .teal,
                    events: Array(laterEvents.prefix(3)),
                    emptyMessage: "No later sessions match the current filters.",
                    scheme: scheme,
                    favoriteIDs: favorites,
                    onSelect: { selectedEvent = $0 }
                )
            }
        }
        .padding(16)
        .tliPanelSurface(
            cornerRadius: 22,
            fillOpacity: 0.98,
            borderOpacity: 0.84,
            shadowRadius: 12,
            shadowY: 6
        )
        .overlay(alignment: .topLeading) {
            Capsule(style: .continuous)
                .fill(TLITheme.sectionAccentGradient(scheme))
                .frame(width: 68, height: 7)
                .padding(.top, 12)
                .padding(.leading, 16)
        }
    }

    private var timelineSummary: String {
        if let savedNext = nextUpEvents.first(where: { favorites.contains($0.id) }) {
            return "Saved next: \(savedNext.startDate.formatted(date: .omitted, time: .shortened))"
        }
        if !happeningNowEvents.isEmpty {
            return "\(happeningNowEvents.count) live"
        }
        if let next = nextUpEvents.first {
            return "Next: \(next.startDate.formatted(date: .omitted, time: .shortened))"
        }
        return "Standing by"
    }

    // MARK: - Actions

    /// Refetch the live schedule when the app returns to foreground or the user
    /// re-opens this tab — but only while the schedule can still change, when
    /// online, not already loading, and no more often than the throttle allows.
    /// Initial population is handled by `.task`; this only refreshes a loaded grid.
    private func maybeAutoRefresh() {
        guard Date() <= conventionEndDate else { return }
        guard !loader.events.isEmpty else { return }
        guard networkMonitor.isConnected else { return }
        guard !loader.isLoading else { return }
        guard Date().timeIntervalSince(lastAutoRefresh) >= autoRefreshMinInterval else { return }

        lastAutoRefresh = Date()
        loader.retry() // all feeds, so newly added rooms and any edits both appear
    }

    /// Pull-to-refresh: always refetch all feeds and keep the spinner up until
    /// the loader settles (bounded so it can't hang).
    private func pullToRefresh() async {
        guard networkMonitor.isConnected else { return }

        lastAutoRefresh = Date()
        loader.retry()

        let deadline = Date().addingTimeInterval(8)
        while loader.isLoading && Date() < deadline {
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    private func toggleFavorite(_ event: RisaScheduleEvent) {
        if favorites.contains(event.id) {
            favorites.remove(event.id)
        } else {
            favorites.insert(event.id)
        }
    }

    private func shouldLeaveNow(for event: RisaScheduleEvent) -> Bool {
        let minutesUntilStart = event.startDate.timeIntervalSinceNow / 60
        return minutesUntilStart >= 0 && minutesUntilStart <= 15
    }

    private func relativeStartText(for event: RisaScheduleEvent) -> String {
        if shouldLeaveNow(for: event) {
            return "Starts in \(max(0, TLISafeMath.minutes(event.startDate.timeIntervalSinceNow))) min • \(event.room)"
        }
        return "\(scheduleRelativeFormatter.localizedString(for: event.startDate, relativeTo: Date())) • \(event.room)"
    }

    private func prioritizeFavorites(in events: [RisaScheduleEvent]) -> [RisaScheduleEvent] {
        events.sorted { lhs, rhs in
            let lhsFavorite = favorites.contains(lhs.id)
            let rhsFavorite = favorites.contains(rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite && !rhsFavorite }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.title < rhs.title
        }
    }

}

private struct PlanConflict: Identifiable {
    let first: RisaScheduleEvent
    let second: RisaScheduleEvent
    var id: String { "\(first.id)-\(second.id)" }
}

private struct TimelineGroupCard: View {
    let title: String
    let systemImage: String
    let accent: Color
    let events: [RisaScheduleEvent]
    let emptyMessage: String
    let scheme: ColorScheme
    let favoriteIDs: Set<String>
    let onSelect: (RisaScheduleEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 24, height: 24)

                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
            }

            if events.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(TLITheme.cardBackground(scheme).opacity(0.55))
                    )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(events) { event in
                        Button {
                            onSelect(event)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(event.title)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(TLITheme.textPrimary(scheme))
                                        .lineLimit(2)

                                    Spacer(minLength: 6)

                                    if favoriteIDs.contains(event.id) {
                                        Text("Saved")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(accent.opacity(0.18))
                                            )
                                            .foregroundStyle(accent)
                                    }
                                }
                                Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened)) • \(event.room)")
                                    .font(.caption)
                                    .foregroundStyle(Color.primary.opacity(0.72))
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TLITheme.cardBackground(scheme).opacity(0.58))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(scheme == .dark ? 0.84 : 0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }
}

// MARK: - Day chips (single-select)

private struct DayChipsRow: View {
    @Environment(\.colorScheme) private var scheme
    let days: [DayFilter]
    @Binding var selectedDay: DayFilter

    private let columns = [
        GridItem(.adaptive(minimum: 112), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(days) { filter in
                DayChip(
                    filter: filter,
                    isSelected: selectedDay == filter,
                    scheme: scheme
                ) {
                    selectedDay = filter
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day filter")
    }
}

private struct DayChip: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    let filter: DayFilter
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void

    private var iconName: String? {
        switch filter {
        case .all:       return "calendar"
        case .favorites: return "star.fill"
        case .day:       return nil
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .imageScale(.small)
                }
                Text(filter.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if differentiateWithoutColor {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                chipBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
            .foregroundColor(isSelected ? .black : TLITheme.textPrimary(scheme))
            .shadow(
                color: scheme == .dark && isSelected
                    ? .black.opacity(0.6)
                    : .clear,
                radius: scheme == .dark && isSelected ? 5 : 0,
                x: 0,
                y: 1
            )
            .tliButtonShapeOutline(
                shape: RoundedRectangle(cornerRadius: 12, style: .continuous),
                strokeColor: isSelected ? TLITheme.textPrimary(scheme) : TLITheme.border(scheme)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filter.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(showButtonShapes ? nil : .default, value: isSelected)
    }

    private var chipBackground: some ShapeStyle {
        isSelected
        ? TLITheme.accent(scheme).opacity(0.90)
        : TLITheme.cardBackground(scheme)
    }
}

// MARK: - Feed chips (multi-select)

private struct FeedChipsRow: View {
    let feeds: [String]
    @Binding var selected: Set<String>
    let scheme: ColorScheme

    private var allSelected: Bool { !feeds.isEmpty && selected.count == feeds.count }
    private let columns = [
        GridItem(.adaptive(minimum: 142), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tracks")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer()
                Button(allSelected ? "Clear" : "Select All") {
                    if allSelected {
                        selected.removeAll()
                    } else {
                        selected = Set(feeds)
                    }
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(TLITheme.accent(scheme))
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(feeds, id: \.self) { feed in
                    SelectableChip(
                        title: feed,
                        isOn: selected.contains(feed),
                        scheme: scheme
                    ) {
                        if selected.contains(feed) {
                            selected.remove(feed)
                        } else {
                            selected.insert(feed)
                        }
                    }
                }
            }
        }
    }
}

private struct SelectableChip: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    let title: String
    let isOn: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.seal.fill" : "seal")
                    .imageScale(.small)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if differentiateWithoutColor {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                (isOn ? TLITheme.accent(scheme).opacity(0.90)
                      : TLITheme.cardBackground(scheme)),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
            .foregroundStyle(isOn ? Color.black : TLITheme.textPrimary(scheme))
            .shadow(
                color: scheme == .dark && isOn ? .black.opacity(0.6) : .clear,
                radius: scheme == .dark && isOn ? 5 : 0,
                x: 0,
                y: 1
            )
            .tliButtonShapeOutline(
                shape: RoundedRectangle(cornerRadius: 12, style: .continuous),
                strokeColor: isOn ? TLITheme.textPrimary(scheme) : TLITheme.border(scheme)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .animation(showButtonShapes ? nil : .default, value: isOn)
    }
}

// MARK: - Search field

private struct ThemedSearchField: View {
    @Binding var text: String
    let scheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.primary.opacity(0.72))
            TextField("Scan manifest…", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            TLITheme.cardBackground(scheme),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }
}

// MARK: - Event detail sheet

private struct EventDetailSheet: View {
    let event: RisaScheduleEvent
    let isFavorite: Bool
    let scheme: ColorScheme
    let toggleFavorite: () -> Void
    @ObservedObject private var feedbackStore = PanelFeedbackStore.shared

    @State private var rating: Int = 0
    @State private var selectedTags: Set<PanelFeedbackTag> = []
    @State private var comment: String = ""
    @State private var reportIssue: Bool = false
    @State private var feedbackMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(event.title)
                        .font(.title.bold())
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        Text(dayAndTime)
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.72))

                    if !event.room.isEmpty || !event.location.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(locationLine)
                            Spacer()
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.72))
                    }

                    Divider()
                        .overlay(TLITheme.border(scheme))

                    let trimmedDescription = event.description
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !trimmedDescription.isEmpty {
                        LinkifiedText(
                            text: trimmedDescription,
                            font: .body,
                            foregroundStyle: TLITheme.textPrimary(scheme)
                        )
                    } else {
                        Text("No additional description is available for this event.")
                            .font(.callout)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .multilineTextAlignment(.leading)
                    }

                    Divider()
                        .overlay(TLITheme.border(scheme))

                    panelFeedbackSection
                }
                .padding(20)
            }
            .background(
                ZStack {
                    TLITheme.backgroundGradient(scheme)
                    if scheme == .dark {
                        Color.black.opacity(0.5)
                    }
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            isFavorite ? "Remove Favorite" : "Mark Favorite",
                            systemImage: isFavorite ? "star.fill" : "star"
                        )
                    }
                }
            }
            .onAppear {
                hydrateFromExisting()
            }
        }
    }

    private var panelFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Panel Feedback")
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            if hasLockedSubmission {
                if let existing = existingSubmission {
                    Text("Your response was submitted \(existing.submittedAt.formatted(date: .abbreviated, time: .shortened)).")
                        .font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.72))
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { idx in
                            Image(systemName: idx <= existing.rating ? "star.fill" : "star")
                                .foregroundStyle(TLITheme.accent(scheme))
                        }
                    }
                    Text("Feedback edits are available for 15 minutes after submitting.")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
            } else {
                ratingControl
                tagsControl
                commentControl

                Toggle("Report issue to organizers", isOn: $reportIssue)
                    .font(.subheadline)
                    .tint(TLITheme.accent(scheme))

                Button {
                    submitFeedback()
                } label: {
                    Text(existingSubmission == nil ? "Submit Feedback" : "Update Feedback")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canSubmitFeedback ? Color.black : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(canSubmitFeedback ? TLITheme.accent(scheme) : TLITheme.cardBackground(scheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(TLITheme.border(scheme), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmitFeedback)
            }

            if let feedbackMessage, !feedbackMessage.isEmpty {
                Text(feedbackMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            } else if !hasLockedSubmission {
                Text("One response per session per device. You can edit for 15 minutes after submitting.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
        }
    }

    private var ratingControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How was this session?")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(value <= rating ? TLITheme.accent(scheme) : .secondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
                }
            }
        }
    }

    private var tagsControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What stood out?")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                ForEach(PanelFeedbackTag.allCases) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        if isSelected {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        Text(tag.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? TLITheme.accent(scheme).opacity(0.85) : TLITheme.cardBackground(scheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(TLITheme.border(scheme), lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Color.black : TLITheme.textPrimary(scheme))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var commentControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Optional note")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            TextEditor(text: $comment)
                .frame(minHeight: 88)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TLITheme.cardBackground(scheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TLITheme.border(scheme), lineWidth: 1)
                )
        }
    }

    private var canSubmitFeedback: Bool {
        rating > 0
    }

    private var existingSubmission: PanelFeedbackEntry? {
        feedbackStore.submission(for: event.id)
    }

    private var hasLockedSubmission: Bool {
        guard let existingSubmission else { return false }
        return !existingSubmission.isEditable
    }

    private func hydrateFromExisting() {
        guard let submission = existingSubmission else {
            rating = 0
            selectedTags = []
            comment = ""
            reportIssue = false
            return
        }
        rating = submission.rating
        selectedTags = Set(submission.tags)
        comment = submission.comment
        reportIssue = submission.isIssueReported
    }

    private func submitFeedback() {
        guard canSubmitFeedback else { return }
        let outcome = feedbackStore.submit(
            event: event,
            rating: rating,
            tags: selectedTags,
            comment: comment,
            isIssueReported: reportIssue
        )
        switch outcome {
        case .created:
            feedbackMessage = "Thanks. Your feedback was submitted."
        case .updated:
            feedbackMessage = "Feedback updated."
        case .locked:
            feedbackMessage = "Feedback can only be edited during the first 15 minutes."
        }
    }

    private var dayAndTime: String {
        let start = event.startDate
        let end   = event.endDate

        let day = weekdayFormatter.string(from: start)
        let startTime = scheduleTimeFormatter.string(from: start)
        let endTime   = scheduleTimeFormatter.string(from: end)

        return "\(day) • \(startTime) – \(endTime)"
    }

    private var locationLine: String {
        if event.room.isEmpty { return event.location }
        if event.location.isEmpty { return event.room }
        if event.room == event.location { return event.room }
        return "\(event.room) • \(event.location)"
    }
}

// MARK: - Trek-ish stardate helper

private func scheduleStardate() -> String {
    TLIStardate.formatted()
}
