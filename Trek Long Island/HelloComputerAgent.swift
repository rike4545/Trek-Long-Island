// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerAgent.swift
//  Trek Long Island
//

import Foundation

struct AgentRequestContext: Sendable {
    let query: String
    let normalizedQuery: String
    let audience: HelloComputerAudience
}

protocol AgentAction: Sendable {
    var id: String { get }
    func canHandle(_ context: AgentRequestContext) -> Bool
    func planAction(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerPendingAction?
}

protocol AgentQueryTool: Sendable {
    var id: String { get }
    func canHandle(_ context: AgentRequestContext) -> Bool
    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer?
}

struct AgentToolRegistry: Sendable {
    let actions: [any AgentAction]
    let queryTools: [any AgentQueryTool]

    func pendingAction(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerPendingAction? {
        for action in actions where action.canHandle(context) {
            if let planned = action.planAction(for: context, events: events) {
                return planned
            }
        }
        return nil
    }

    static let `default` = AgentToolRegistry(
        actions: [
            ScheduleReminderActionTool(),
            AddFavoriteActionTool(),
            RemoveFavoriteActionTool()
        ],
        queryTools: [
            BriefingQueryTool(),
            WhatShouldIDoNextQueryTool(),
            NextUpQueryTool(),
            BuildMyDayQueryTool(),
            ConflictsQueryTool(),
            VenueRoutingQueryTool(),
            GuestLogisticsQueryTool(),
            AccessibilitySupportQueryTool(),
            SearchQueryTool()
        ]
    )
}

actor HelloComputerAgent {
    private let registry: AgentToolRegistry

    init(registry: AgentToolRegistry = .default) {
        self.registry = registry
    }

    func pendingAction(for query: String, audience: HelloComputerAudience) async -> HelloComputerPendingAction? {
        let normalized = Self.normalize(query)
        guard normalized.count >= 2 else { return nil }

        let context = AgentRequestContext(
            query: query,
            normalizedQuery: normalized,
            audience: audience
        )

        let events = await HelloComputerScheduleService.shared.events()
        guard !events.isEmpty else { return nil }

        return registry.pendingAction(for: context, events: events)
    }

    func answer(for query: String, audience: HelloComputerAudience) async -> HelloComputerAnswer? {
        let normalized = Self.normalize(query)
        guard normalized.count >= 2 else { return nil }

        let context = AgentRequestContext(
            query: query,
            normalizedQuery: normalized,
            audience: audience
        )

        let events = await HelloComputerScheduleService.shared.events()
        guard !events.isEmpty else {
            return HelloComputerAnswer(
                text: "Schedule data is not loaded yet. Please open the Schedule tab, then ask again.",
                source: .generalGuidance,
                confidence: 0.7
            )
        }

        for tool in registry.queryTools where tool.canHandle(context) {
            if let response = tool.answer(for: context, events: events) {
                return response
            }
        }
        return nil
    }
}

private struct ScheduleReminderActionTool: AgentAction {
    let id: String = "schedule_reminder"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        let q = context.normalizedQuery
        return Self.containsAny(q, ["remind", "reminder", "notify", "notification"]) &&
            Self.containsAny(q, ["before", "prior"])
    }

    func planAction(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerPendingAction? {
        guard let target = Self.targetEvent(for: context.normalizedQuery, events: events) else {
            return nil
        }

        let minutes = Self.reminderMinutes(from: context.normalizedQuery) ?? 15
        return HelloComputerPendingAction(
            kind: .scheduleReminder(
                title: target.title,
                room: target.room,
                startDate: target.startDate,
                minutesBefore: minutes
            ),
            prompt: "Set a reminder \(minutes) minutes before \"\(target.title)\"?"
        )
    }
}

private struct AddFavoriteActionTool: AgentAction {
    let id: String = "add_favorite"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        let q = context.normalizedQuery
        let explicitFavorite = Self.containsAny(q, ["favorite", "favourite", "save", "bookmark"]) &&
            Self.containsAny(q, ["add", "mark", "set", "make"])
        let explicitStarCommand = Self.containsAny(q, [
            "star the", "star this", "star next", "star panel", "star event", "star it"
        ])
        return explicitFavorite || explicitStarCommand
    }

    func planAction(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerPendingAction? {
        guard let target = Self.targetEvent(for: context.normalizedQuery, events: events) else {
            return nil
        }

        return HelloComputerPendingAction(
            kind: .addFavorite(eventID: target.id.uuidString, title: target.title),
            prompt: "Add \"\(target.title)\" to your favorites?"
        )
    }
}

private struct RemoveFavoriteActionTool: AgentAction {
    let id: String = "remove_favorite"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        let q = context.normalizedQuery
        let explicitFavoriteRemoval = Self.containsAny(q, ["favorite", "favourite", "save", "bookmark"]) &&
            Self.containsAny(q, ["remove", "unfavorite", "unfavourite", "unstar", "delete"])
        let explicitUnstarCommand = Self.containsAny(q, [
            "unstar this", "unstar the", "unstar next", "unstar panel", "unstar event"
        ])
        return explicitFavoriteRemoval || explicitUnstarCommand
    }

    func planAction(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerPendingAction? {
        guard let target = Self.targetEvent(for: context.normalizedQuery, events: events) else {
            return nil
        }

        return HelloComputerPendingAction(
            kind: .removeFavorite(eventID: target.id.uuidString, title: target.title),
            prompt: "Remove \"\(target.title)\" from your favorites?"
        )
    }
}

private struct BriefingQueryTool: AgentQueryTool {
    let id: String = "briefing"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, ["brief me", "status report", "mission brief", "happening now", "give me a briefing"])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let now = Date()
        let happeningNow = events
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
        let nextUp = events
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .prefix(3)

        let nowLine = happeningNow.first.map { "Now: \($0.title) • \($0.room)" } ?? "Now: No live panel at this moment."
        let nextLines: String
        if nextUp.isEmpty {
            nextLines = "Next: No upcoming items in the current feed window."
        } else {
            nextLines = nextUp.map { "• \($0.title) — \(Self.formatRange(start: $0.startDate, end: $0.endDate)) • \($0.room)" }
                .joined(separator: "\n")
        }

        return HelloComputerAnswer(
            text: "Mission briefing:\n\(nowLine)\n\nNext up:\n\(nextLines)",
            source: .aiAssist,
            confidence: 0.92
        )
    }
}

private struct NextUpQueryTool: AgentQueryTool {
    let id: String = "next_up"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, [
            "what's next", "whats next", "what is next",
            "what should i do next", "what do i do next",
            "next panel", "next event"
        ])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let favorites = favoriteEventIDs()
        guard let next = nextUpcomingEvent(in: events, favoriteIDs: favorites) else {
            return HelloComputerAnswer(
                text: "No upcoming events were found in the current schedule window.",
                source: .aiAssist,
                confidence: 0.9
            )
        }

        let favoriteLine = favorites.contains(next.id.uuidString)
            ? "\nSaved in your favorites."
            : ""

        return HelloComputerAnswer(
            text: "Next up:\n\(next.title)\n\(Self.formatRange(start: next.startDate, end: next.endDate)) • \(next.room)\(favoriteLine)",
            source: .aiAssist,
            confidence: 0.95
        )
    }
}

private struct BuildMyDayQueryTool: AgentQueryTool {
    let id: String = "build_my_day"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, ["build my day", "plan my day", "make me a schedule", "itinerary", "today plan"])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let cal = Calendar.current
        let now = Date()
        let favoriteIDs = favoriteEventIDs()
        let dayEvents = events
            .filter { cal.isDate($0.startDate, inSameDayAs: now) && $0.endDate >= now }
            .sorted {
                let lhsFavorite = favoriteIDs.contains($0.id.uuidString)
                let rhsFavorite = favoriteIDs.contains($1.id.uuidString)
                if lhsFavorite != rhsFavorite { return lhsFavorite && !rhsFavorite }
                return $0.startDate < $1.startDate
            }

        guard !dayEvents.isEmpty else {
            return HelloComputerAnswer(
                text: "I could not find events for today yet. Try again after schedule sync, or ask for a specific topic.",
                source: .aiAssist,
                confidence: 0.9
            )
        }

        var picks: [ICSParsedEvent] = []
        var lastEnd: Date?
        for event in dayEvents {
            let hasRoomHopConflict = picks.last.map { $0.room != event.room && event.startDate.timeIntervalSince($0.endDate) < 300 } ?? false
            if let end = lastEnd, event.startDate < end { continue }
            if hasRoomHopConflict { continue }
            picks.append(event)
            lastEnd = event.endDate
            if picks.count == 5 { break }
        }

        let header = context.audience == .staff ? "Suggested shift flow:" : "Suggested day plan:"
        let body = picks.enumerated().map { idx, event in
            "\(idx + 1). \(event.title) — \(Self.formatRange(start: event.startDate, end: event.endDate)) • \(event.room)"
        }.joined(separator: "\n")

        return HelloComputerAnswer(
            text: "\(header)\n\(body)",
            source: .aiAssist,
            confidence: 0.94
        )
    }
}

private struct WhatShouldIDoNextQueryTool: AgentQueryTool {
    let id: String = "what_should_i_do_next"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, [
            "what should i do next", "what do i do next",
            "next best move", "what now", "what should i do first"
        ])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let now = Date()
        let favorites = favoriteEventIDs()

        let liveFavorite = events
            .filter { favorites.contains($0.id.uuidString) && $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
            .first

        if let liveFavorite {
            return HelloComputerAnswer(
                text: """
                Best next move:
                Join your saved event "\(liveFavorite.title)" now.
                It is live until \(liveFavorite.endDate.formatted(date: .omitted, time: .shortened)) in \(liveFavorite.room).
                """,
                source: .aiAssist,
                confidence: 0.96
            )
        }

        guard let next = nextUpcomingEvent(in: events, favoriteIDs: favorites) else {
            return HelloComputerAnswer(
                text: "No upcoming schedule items are available yet. Try refreshing Schedule and ask again.",
                source: .aiAssist,
                confidence: 0.9
            )
        }

        let minutesUntil = max(0, Int(next.startDate.timeIntervalSince(now) / 60))
        let urgency: String
        if minutesUntil <= 10 {
            urgency = "Leave now so you arrive on time."
        } else if minutesUntil <= 30 {
            urgency = "Wrap your current stop and head over soon."
        } else {
            urgency = "You have time for a quick vendor or lounge stop first."
        }

        return HelloComputerAnswer(
            text: """
            Best next move:
            \(next.title)
            \(Self.formatRange(start: next.startDate, end: next.endDate)) • \(next.room)
            \(urgency)
            """,
            source: .aiAssist,
            confidence: 0.95
        )
    }
}

private struct ConflictsQueryTool: AgentQueryTool {
    let id: String = "conflicts"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, ["conflict", "overlap", "double booked"])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let now = Date()
        let upcoming = events
            .filter { $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }

        var conflicts: [(ICSParsedEvent, ICSParsedEvent)] = []
        for i in 0..<upcoming.count {
            for j in (i + 1)..<upcoming.count {
                let a = upcoming[i]
                let b = upcoming[j]
                if b.startDate >= a.endDate { break }
                if a.startDate < b.endDate && b.startDate < a.endDate {
                    conflicts.append((a, b))
                }
                if conflicts.count == 3 { break }
            }
            if conflicts.count == 3 { break }
        }

        if conflicts.isEmpty {
            return HelloComputerAnswer(
                text: "I don't see upcoming time conflicts in the loaded schedule.",
                source: .aiAssist,
                confidence: 0.9
            )
        }

        let lines = conflicts.map { "• \($0.0.title) overlaps \($0.1.title)" }.joined(separator: "\n")
        return HelloComputerAnswer(
            text: "Potential conflicts:\n\(lines)",
            source: .aiAssist,
            confidence: 0.93
        )
    }
}

private struct SearchQueryTool: AgentQueryTool {
    let id: String = "search"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, ["find", "search", "show me", "any ", "panels", "events"])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        let stopWords: Set<String> = [
            "find", "search", "show", "me", "any", "panels", "panel", "events",
            "today", "this", "that", "for", "with", "the", "a", "an",
            "please", "can", "you", "do", "i", "want", "need"
        ]
        let tokens = context.normalizedQuery
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 && !stopWords.contains($0) }

        let matches: [ICSParsedEvent]
        if tokens.isEmpty {
            matches = events.sorted { $0.startDate < $1.startDate }
        } else {
            let ranked = events.compactMap { event -> (ICSParsedEvent, Int)? in
                let title = event.title.lowercased()
                let room = event.room.lowercased()
                let desc = event.description.lowercased()
                let full = "\(title) \(desc) \(room)"

                var score = 0
                if context.normalizedQuery.count >= 4, title.contains(context.normalizedQuery) {
                    score += 6
                }

                for token in tokens {
                    if title.contains(token) { score += 3 }
                    if room.contains(token) { score += 2 }
                    if desc.contains(token) { score += 1 }
                    if full.contains(token) { score += 1 }
                }

                return score > 0 ? (event, score) : nil
            }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.startDate < $1.0.startDate
                }
                return $0.1 > $1.1
            }
            matches = ranked.map(\.0)
        }

        let top = Array(matches.prefix(5))
        if top.isEmpty {
            return HelloComputerAnswer(
                text: "I couldn't find matching events yet. Try another keyword like DS9, cosplay, vendor, or kids.",
                source: .aiAssist,
                confidence: 0.86
            )
        }

        let lines = top.map { "• \($0.title) — \(Self.formatRange(start: $0.startDate, end: $0.endDate)) • \($0.room)" }
            .joined(separator: "\n")
        return HelloComputerAnswer(
            text: "Best matches:\n\(lines)",
            source: .aiAssist,
            confidence: tokens.isEmpty ? 0.86 : 0.94
        )
    }
}

private struct VenueRoutingQueryTool: AgentQueryTool {
    let id: String = "venue_routing"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, [
            "where is the venue", "where is venue", "where is registration",
            "how do i get there", "parking", "address", "map", "where is the hotel"
        ])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        HelloComputerAnswer(
            text: """
            Venue routing:
            Hyatt Regency Long Island
            1717 Motor Pkwy, Hauppauge, NY 11788

            Fast path:
            1) Open the Map tab for live orientation.
            2) Use Convention Level for room layout once inside.
            3) If anything changed, check Announcements before you move.
            """,
            source: .generalGuidance,
            confidence: 0.96
        )
    }
}

private struct GuestLogisticsQueryTool: AgentQueryTool {
    let id: String = "guest_logistics"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, [
            "photo op", "photo ops", "autograph", "autographs",
            "selfie", "selfies", "guest table", "guest signing"
        ])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        HelloComputerAnswer(
            text: """
            Guest logistics:
            • Check Guests for each person's table/signing notes.
            • Buy photo-op tickets at \(TicketPurchaseLinks.photoOpsURLString)
            • Arrive early for photo ops and keep confirmation ready.
            • Ask nearby staff for current line start and cutoff updates.
            • If timing conflicts, save your must-do sessions first and use a backup plan.
            """,
            source: .generalGuidance,
            confidence: 0.94
        )
    }
}

private struct AccessibilitySupportQueryTool: AgentQueryTool {
    let id: String = "accessibility_support"

    func canHandle(_ context: AgentRequestContext) -> Bool {
        Self.containsAny(context.normalizedQuery, [
            "accessibility", "wheelchair", "ada", "mobility",
            "quiet space", "sensory", "overwhelmed"
        ])
    }

    func answer(for context: AgentRequestContext, events: [ICSParsedEvent]) -> HelloComputerAnswer? {
        HelloComputerAnswer(
            text: """
            Accessibility support:
            1) Go to Registration or the Information Desk and tell staff what support you need.
            2) Ask for the best accessible route to your next room.
            3) If you need lower-stimulation space, ask staff to route you to a quieter area.
            Official updates: https://treklongisland.com/
            """,
            source: .officialFAQ,
            confidence: 0.95
        )
    }
}

private extension AgentAction {
    static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    static func targetEvent(for normalizedQuery: String, events: [ICSParsedEvent]) -> ICSParsedEvent? {
        if containsAny(normalizedQuery, ["next", "next event", "next panel"]) {
            return nextUpcomingEvent(in: events, favoriteIDs: favoriteEventIDs())
        }
        return bestEventMatch(for: normalizedQuery, in: events)
    }

    static func bestEventMatch(for normalizedQuery: String, in events: [ICSParsedEvent]) -> ICSParsedEvent? {
        let stopWords: Set<String> = [
            "add", "remove", "favorite", "favourite", "star", "save", "mark", "to",
            "from", "my", "next", "event", "panel", "please", "the", "a", "an",
            "remind", "reminder", "notify", "notification", "before", "prior", "minutes"
        ]
        let tokens = normalizedQuery
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 && !stopWords.contains($0) }

        guard !tokens.isEmpty else { return nil }

        let ranked = events.map { event -> (ICSParsedEvent, Int) in
            let title = event.title.lowercased()
            let room = event.room.lowercased()
            let desc = event.description.lowercased()
            let score = tokens.reduce(into: 0) { partial, token in
                if title.contains(token) { partial += 3 }
                if room.contains(token) { partial += 2 }
                if desc.contains(token) { partial += 1 }
            }
            return (event, score)
        }
        .filter { $0.1 > 0 }
        .sorted {
            if $0.1 == $1.1 {
                return $0.0.startDate < $1.0.startDate
            }
            return $0.1 > $1.1
        }

        return ranked.first?.0
    }

    static func reminderMinutes(from normalizedQuery: String) -> Int? {
        let parts = normalizedQuery.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        for idx in parts.indices {
            if let value = Int(parts[idx]), value > 0, value <= 180 {
                return value
            }
            if parts[idx] == "fifteen" { return 15 }
            if parts[idx] == "thirty" { return 30 }
            if parts[idx] == "ten" { return 10 }
            if parts[idx] == "five" { return 5 }
        }
        return nil
    }
}

private extension AgentQueryTool {
    static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    static func formatRange(start: Date, end: Date) -> String {
        "\(start.formatted(date: .abbreviated, time: .shortened)) to \(end.formatted(date: .omitted, time: .shortened))"
    }

}

private func favoriteEventIDs() -> Set<String> {
    let csv = UserDefaults.standard.string(forKey: "TLI.Schedule.favoriteIDsCSV") ?? ""
    return Set(csv.split(separator: "|").map(String.init))
}

private func nextUpcomingEvent(in events: [ICSParsedEvent], favoriteIDs: Set<String>) -> ICSParsedEvent? {
    let now = Date()
    return events
        .filter { $0.endDate >= now }
        .sorted {
            let lhsFavorite = favoriteIDs.contains($0.id.uuidString)
            let rhsFavorite = favoriteIDs.contains($1.id.uuidString)
            if lhsFavorite != rhsFavorite { return lhsFavorite && !rhsFavorite }
            return $0.startDate < $1.startDate
        }
        .first
}

private extension HelloComputerAgent {
    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let scalarView = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            } else {
                return " "
            }
        }
        let cleaned = String(scalarView)
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }
}
