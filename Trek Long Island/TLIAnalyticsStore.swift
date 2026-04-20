// Copyright Bryan Carroll. All rights reserved.
//
//  TLIAnalyticsStore.swift
//  Trek Long Island
//
//  Unified analytics pipeline:
//  - Local event history for in-app operations analytics
//  - Optional Firebase Analytics forwarding (sanitized)
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

struct TLIAnalyticsEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let name: String
    let domain: String
    let actor: String
    let value: Double?
    let metadata: [String: String]

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        name: String,
        domain: String,
        actor: String,
        value: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.domain = domain
        self.actor = actor
        self.value = value
        self.metadata = metadata
    }
}

struct TLIAnalyticsDailyPoint: Identifiable, Hashable {
    let id: String
    let dayStart: Date
    let label: String
    let count: Int
}

struct TLIAnalyticsSnapshot {
    let events1h: Int
    let events24h: Int
    let events7d: Int
    let uniqueActors24h: Int
    let failures24h: Int
    let topActions24h: [(name: String, count: Int)]
    let topDomains24h: [(domain: String, count: Int)]
    let recentFailures24h: [TLIAnalyticsEvent]
    let dailyPoints7d: [TLIAnalyticsDailyPoint]

    var failureRate24h: Double {
        guard events24h > 0 else { return 0 }
        return Double(failures24h) / Double(events24h)
    }
}

@MainActor
final class TLIAnalyticsStore: ObservableObject {
    static let shared = TLIAnalyticsStore()

    @Published private(set) var events: [TLIAnalyticsEvent] = []

    private let key = "TLI.Analytics.events.v1"
    private let maxEvents = 5000

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        load()
    }

    func track(
        name: String,
        domain: String,
        actor: String,
        value: Double? = nil,
        metadata: [String: String] = [:],
        timestamp: Date = .now
    ) {
        let safeName = normalizedIdentifier(name)
        let safeDomain = normalizedIdentifier(domain)
        let safeActor = actor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "system"
            : actor.trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedMetadata = Dictionary(
            metadata
                .map { (normalizedIdentifier($0.key), String($0.value.prefix(80))) }
                .prefix(12),
            uniquingKeysWith: { _, newer in newer }
        )

        let event = TLIAnalyticsEvent(
            timestamp: timestamp,
            name: safeName,
            domain: safeDomain,
            actor: safeActor,
            value: value,
            metadata: trimmedMetadata
        )

        events.insert(event, at: 0)
        if events.count > maxEvents {
            events = Array(events.prefix(maxEvents))
        }
        persist()

        forwardToFirebase(event)
    }

    func snapshot(reference: Date = .now) -> TLIAnalyticsSnapshot {
        let oneHourAgo = reference.addingTimeInterval(-3600)
        let oneDayAgo = reference.addingTimeInterval(-24 * 3600)
        let sevenDaysAgo = reference.addingTimeInterval(-7 * 24 * 3600)

        let hourEvents = events.filter { $0.timestamp >= oneHourAgo }
        let dayEvents = events.filter { $0.timestamp >= oneDayAgo }
        let weekEvents = events.filter { $0.timestamp >= sevenDaysAgo }

        let failures = dayEvents.filter { isFailure($0) }.count
        let actors = Set(dayEvents.map(\.actor)).count

        let grouped = Dictionary(dayEvents.map { ($0.name, 1) }, uniquingKeysWith: +)
        let top = grouped
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(6)
            .map { (name: $0.key, count: $0.value) }

        let groupedDomains = Dictionary(dayEvents.map { ($0.domain, 1) }, uniquingKeysWith: +)
        let topDomains = groupedDomains
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(6)
            .map { (domain: $0.key, count: $0.value) }

        let recentFailures = dayEvents.filter { isFailure($0) }.prefix(5).map { $0 }

        return TLIAnalyticsSnapshot(
            events1h: hourEvents.count,
            events24h: dayEvents.count,
            events7d: weekEvents.count,
            uniqueActors24h: actors,
            failures24h: failures,
            topActions24h: top,
            topDomains24h: topDomains,
            recentFailures24h: recentFailures,
            dailyPoints7d: dailyPoints(reference: reference, days: 7)
        )
    }

    func clear() {
        events = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func dailyPoints(reference: Date, days: Int) -> [TLIAnalyticsDailyPoint] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: reference)
        let labelFormatter = DateFormatter()
        labelFormatter.locale = Locale(identifier: "en_US_POSIX")
        labelFormatter.dateFormat = "E"

        var out: [TLIAnalyticsDailyPoint] = []
        out.reserveCapacity(days)

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: dayStart),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }

            let count = events.reduce(0) { acc, event in
                (event.timestamp >= start && event.timestamp < end) ? acc + 1 : acc
            }

            out.append(
                TLIAnalyticsDailyPoint(
                    id: ISO8601DateFormatter().string(from: start),
                    dayStart: start,
                    label: labelFormatter.string(from: start),
                    count: count
                )
            )
        }

        return out
    }

    private func isFailure(_ event: TLIAnalyticsEvent) -> Bool {
        if event.name.contains("fail") || event.name.contains("error") || event.name.contains("denied") {
            return true
        }
        if let status = event.metadata["status"], status == "failed" || status == "error" {
            return true
        }
        return false
    }

    private func normalizedIdentifier(_ raw: String) -> String {
        let lower = raw.lowercased()
        let mapped = lower.map { ch -> Character in
            if ch.isLetter || ch.isNumber { return ch }
            return "_"
        }
        let collapsed = String(mapped)
            .replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        if collapsed.isEmpty { return "event" }
        return String(collapsed.prefix(40))
    }

    private func forwardToFirebase(_ event: TLIAnalyticsEvent) {
        #if canImport(FirebaseAnalytics)
        let firebaseName = sanitizedFirebaseEventName(from: "tli_\(event.name)")

        var params: [String: Any] = [
            "domain": String(event.domain.prefix(40)),
            "actor": String(event.actor.prefix(40))
        ]

        if let value = event.value {
            params["value"] = value
        }

        for (key, value) in event.metadata.prefix(8) {
            let safeKey = sanitizedFirebaseParamName(from: key)
            params[safeKey] = String(value.prefix(100))
        }

        Analytics.logEvent(firebaseName, parameters: params)
        #endif
    }

    private func sanitizedFirebaseEventName(from raw: String) -> String {
        var name = normalizedIdentifier(raw)
        if name.first?.isNumber == true {
            name = "e_\(name)"
        }
        if name.count < 1 {
            return "tli_event"
        }
        return String(name.prefix(40))
    }

    private func sanitizedFirebaseParamName(from raw: String) -> String {
        var name = normalizedIdentifier(raw)
        if name.first?.isNumber == true {
            name = "p_\(name)"
        }
        if name.hasPrefix("firebase_") || name.hasPrefix("ga_") || name.hasPrefix("google_") {
            name = "tli_\(name)"
        }
        return String(name.prefix(40))
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? decoder.decode([TLIAnalyticsEvent].self, from: data) else {
            events = []
            return
        }
        events = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    private func persist() {
        guard let data = try? encoder.encode(events) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
