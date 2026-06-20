// Copyright Bryan Carroll. All rights reserved.
//
//  MyMissionPlanView.swift
//  Trek Long Island
//
//  Personal convention plan built from saved schedule and guest favorites.
//

import SwiftUI

private let missionPlanDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEEE"
    return formatter
}()

private let missionPlanTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

@MainActor
struct MyMissionPlanView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @ObservedObject private var networkMonitor = TLINetworkMonitor.shared
    @StateObject private var loader = ICSLoader()

    @AppStorage("TLI.Schedule.favoriteIDsCSV") private var favoriteEventIDsCSV: String = ""
    @AppStorage("TLI.Guests.favoriteSlugsCSV") private var favoriteGuestSlugsCSV: String = ""

    @State private var mappedEvents: [RisaScheduleEvent] = []

    private var favoriteEventIDs: Set<String> {
        Set(favoriteEventIDsCSV.split(separator: "|").map(String.init))
    }

    private var favoriteGuestSlugs: [String] {
        favoriteGuestSlugsCSV
            .split(separator: "|")
            .map(String.init)
            .sorted { displayName(forGuestSlug: $0) < displayName(forGuestSlug: $1) }
    }

    private var favoriteEvents: [RisaScheduleEvent] {
        mappedEvents
            .filter { favoriteEventIDs.contains($0.id) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var upcomingFavoriteEvents: [RisaScheduleEvent] {
        let now = Date()
        return favoriteEvents
            .filter { $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }

    private var nextFavoriteEvent: RisaScheduleEvent? {
        upcomingFavoriteEvents.first
    }

    private var conflicts: [MissionPlanConflict] {
        guard favoriteEvents.count > 1 else { return [] }
        var output: [MissionPlanConflict] = []

        for firstIndex in 0..<favoriteEvents.count {
            for secondIndex in (firstIndex + 1)..<favoriteEvents.count {
                let first = favoriteEvents[firstIndex]
                let second = favoriteEvents[secondIndex]
                if first.startDate < second.endDate && second.startDate < first.endDate {
                    output.append(.init(first: first, second: second))
                }
            }
        }

        return output
    }

    private var groupedFavoriteEvents: [(day: String, events: [RisaScheduleEvent])] {
        let grouped = Dictionary(grouping: favoriteEvents, by: \.day)
        let order = ["Friday", "Saturday", "Sunday"]

        return grouped
            .map { (day: $0.key, events: $0.value.sorted { $0.startDate < $1.startDate }) }
            .sorted { lhs, rhs in
                let lhsIndex = order.firstIndex(of: lhs.day) ?? Int.max
                let rhsIndex = order.firstIndex(of: rhs.day) ?? Int.max
                if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
                return lhs.day < rhs.day
            }
    }

    private var readinessScore: Int {
        var score = 0
        if !favoriteEvents.isEmpty { score += 40 }
        if favoriteEvents.count >= 3 { score += 20 }
        if !favoriteGuestSlugs.isEmpty { score += 25 }
        if conflicts.isEmpty { score += 15 }
        return min(score, 100)
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    scheduleStatusCard

                    if shouldShowOfflineStatusCard {
                        offlineStatusCard
                    }

                    quickActionsCard
                    nextUpCard
                    conflictCard
                    favoriteEventsSection
                    favoriteGuestsSection
                }
                .adaptiveContentWidth(
                    maxWidth: TLILayout.defaultContentMaxWidth,
                    horizontalPadding: hSizeClass == .regular ? 24 : 16,
                    verticalPadding: 12
                )
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("My Mission Plan")
        .navigationBarTitleDisplayMode(.inline)
        .tliNavBarStyle()
        .task {
            if loader.events.isEmpty {
                loader.load()
            }
            if mappedEvents.isEmpty, !loader.events.isEmpty {
                mappedEvents = mapMissionPlanEvents(loader.events)
            }
        }
        .onReceive(loader.$events) { events in
            mappedEvents = mapMissionPlanEvents(events)
        }
    }

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

    private var scheduleStatusTitle: String {
        if loader.isLoading { return "Refreshing Schedule" }
        if loader.loadedFromCache { return "Cached Schedule Ready" }
        if loader.lastLoadErrorMessage != nil { return "Schedule Needs Attention" }
        if loader.lastSyncDate != nil { return "Live Schedule Ready" }
        return "Schedule Status"
    }

    private var scheduleStatusDetail: String {
        if let message = loader.lastLoadErrorMessage {
            return message
        }
        if let date = loader.lastSyncDate {
            let prefix = loader.loadedFromCache ? "Using saved schedule data" : "Live schedule synced"
            return "\(prefix) \(date.formatted(date: .abbreviated, time: .shortened))."
        }
        return "Open Schedule once while online so your saved plan can stay useful when the floor gets busy."
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(RisaTheme.accent(scheme).opacity(0.15))

                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text("My Mission Plan")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text("Your saved events, guest targets, and next move in one command view.")
                        .font(.subheadline)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                metricPill(title: "Readiness", value: "\(readinessScore)%", icon: "gauge.with.dots.needle.67percent")
                metricPill(title: "Events", value: "\(favoriteEvents.count)", icon: "calendar")
                metricPill(title: "Guests", value: "\(favoriteGuestSlugs.count)", icon: "person.2.fill")
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.88, shadowRadius: 14, shadowY: 7)
    }

    private var scheduleStatusCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: loader.loadedFromCache ? "icloud.slash" : (networkMonitor.isConnected ? "checkmark.icloud.fill" : "wifi.slash"))
                .font(.headline.weight(.bold))
                .foregroundStyle(loader.lastLoadErrorMessage == nil ? RisaTheme.accent(scheme) : .orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(scheduleStatusTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text(scheduleStatusDetail)
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if loader.lastLoadErrorMessage != nil {
                Button("Retry") {
                    loader.retry()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .tliPanelSurface(cornerRadius: 20, fillOpacity: 0.96, borderOpacity: 0.70, shadowRadius: 8, shadowY: 4)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .imageScale(.small)
                Text(title)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(RisaTheme.textSecondary(scheme))

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TLITheme.controlShape(cornerRadius: 16).fill(TLITheme.chipBackground(scheme).opacity(0.82)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 16)
                .stroke(TLITheme.border(scheme).opacity(0.45), lineWidth: TLITheme.hairline)
        )
    }

    private var offlineStatusCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: networkMonitor.isConnected ? "wifi.exclamationmark" : "wifi.slash")
                .font(.headline)
                .foregroundStyle(RisaTheme.accent(scheme))

            VStack(alignment: .leading, spacing: 4) {
                Text(loader.loadedFromCache ? "Using Cached Schedule" : "Schedule Feed Status")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text(loader.lastLoadErrorMessage ?? "Favorites remain visible when cached schedule data is available.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .tliPanelSurface(cornerRadius: 20, fillOpacity: 0.96, borderOpacity: 0.70, shadowRadius: 8, shadowY: 4)
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Fast Access", icon: "bolt.fill")

            LazyVGrid(columns: quickActionColumns, spacing: 10) {
                missionLink(title: "Schedule", subtitle: "Add or adjust saved events", icon: "calendar") {
                    ScheduleView()
                }

                missionLink(title: "Guests", subtitle: "Pick your must-meet crew", icon: "person.2.fill") {
                    GuestsView()
                }

                missionLink(title: "Map", subtitle: "Check the next route", icon: "map.fill") {
                    MapsView()
                }

                missionLink(title: "Ops & Autos", subtitle: "Track photos and signings", icon: "camera.on.rectangle.fill") {
                    PhotoAutographTrackerView()
                }

                missionLink(title: "Support", subtitle: "Help, safety, and lost items", icon: "cross.case.fill") {
                    SupportCenterView()
                }

                missionLink(title: "Computer", subtitle: "Ask what to do next", icon: "sparkles") {
                    HelloComputerView()
                }
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var quickActionColumns: [GridItem] {
        if hSizeClass == .regular {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func missionLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RisaTheme.accent(scheme))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(13)
            .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.88)))
            .overlay(
                TLITheme.controlShape(cornerRadius: 18)
                    .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var nextUpCard: some View {
        if let nextFavoriteEvent {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Next Up", icon: "clock.badge.checkmark.fill")

                eventRow(nextFavoriteEvent, showsDay: true)
            }
            .padding(16)
            .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
        }
    }

    @ViewBuilder
    private var conflictCard: some View {
        if !conflicts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Schedule Conflicts", icon: "exclamationmark.triangle.fill")

                ForEach(conflicts.prefix(3)) { conflict in
                    Text("\(conflict.first.title) overlaps \(conflict.second.title)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TLITheme.controlShape(cornerRadius: 16).fill(Color.orange.opacity(0.16)))
                }
            }
            .padding(16)
            .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
        }
    }

    private var favoriteEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Saved Events", icon: "star.fill")

            if groupedFavoriteEvents.isEmpty {
                emptyState(
                    title: "No saved events yet",
                    detail: "Favorite schedule items to build your personal convention timeline.",
                    icon: "calendar.badge.plus"
                )
            } else {
                ForEach(groupedFavoriteEvents, id: \.day) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.day)
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(RisaTheme.textSecondary(scheme))

                        ForEach(group.events) { event in
                            eventRow(event, showsDay: false)
                        }
                    }
                }
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var favoriteGuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Saved Guests", icon: "person.crop.circle.badge.star.fill")

            if favoriteGuestSlugs.isEmpty {
                emptyState(
                    title: "No saved guests yet",
                    detail: "Favorite guests from Explore so your must-meet list stays close.",
                    icon: "person.badge.plus"
                )
            } else {
                LazyVGrid(columns: guestColumns, spacing: 10) {
                    ForEach(favoriteGuestSlugs, id: \.self) { slug in
                        guestChip(slug)
                    }
                }
            }
        }
        .padding(16)
        .tliPanelSurface(cornerRadius: 24, fillOpacity: 0.98, borderOpacity: 0.84, shadowRadius: 12, shadowY: 6)
    }

    private var guestColumns: [GridItem] {
        if hSizeClass == .regular {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible())]
    }

    private func guestChip(_ slug: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(RisaTheme.accent(scheme))
                .frame(width: 24, height: 24)
                .background(Circle().fill(RisaTheme.accent(scheme).opacity(0.14)))

            Text(displayName(forGuestSlug: slug))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.86)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
        )
    }

    private func eventRow(_ event: RisaScheduleEvent, showsDay: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 2) {
                    Text(missionPlanTimeFormatter.string(from: event.startDate))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                    Text(missionPlanTimeFormatter.string(from: event.endDate))
                        .font(.caption)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                }
                .frame(width: 72, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        if showsDay {
                            Label(event.day, systemImage: "calendar")
                        }
                        if !event.room.isEmpty {
                            Label(event.room, systemImage: "mappin.and.ellipse")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.86)))
        .overlay(
            TLITheme.controlShape(cornerRadius: 18)
                .stroke(TLITheme.border(scheme).opacity(0.55), lineWidth: TLITheme.hairline)
        )
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(RisaTheme.accent(scheme))
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
    }

    private func emptyState(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(RisaTheme.accent(scheme))
                .frame(width: 30)

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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.controlShape(cornerRadius: 18).fill(TLITheme.cardBackground(scheme).opacity(0.78)))
    }

    private func mapMissionPlanEvents(_ parsed: [ICSParsedEvent]) -> [RisaScheduleEvent] {
        parsed.map { event in
            RisaScheduleEvent(
                id: event.id.uuidString,
                title: event.title,
                description: event.description,
                location: event.room,
                room: event.room,
                startDate: event.startDate,
                endDate: event.endDate,
                day: missionPlanDayFormatter.string(from: event.startDate),
                isFavorite: favoriteEventIDs.contains(event.id.uuidString)
            )
        }
        .sorted { $0.startDate < $1.startDate }
    }

    private func displayName(forGuestSlug slug: String) -> String {
        slug
            .split(separator: "-")
            .map { part in
                let lower = part.lowercased()
                if lower.count <= 2 {
                    return lower.uppercased()
                }
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }
}

private struct MissionPlanConflict: Identifiable {
    let id = UUID()
    let first: RisaScheduleEvent
    let second: RisaScheduleEvent
}

#Preview {
    NavigationStack {
        MyMissionPlanView()
    }
}
