// Copyright Bryan Carroll. All rights reserved.
import SwiftUI
import SwiftSoup
import Foundation
import CryptoKit

// MARK: - Parsed event model

struct ICSParsedEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let room: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        startDate: Date,
        endDate: Date,
        room: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.room = room
    }
}

// MARK: - Loader

final class ICSLoader: ObservableObject {
    @Published var events: [ICSParsedEvent] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var loadedFromCache = false
    @Published var lastLoadErrorMessage: String?

    // Track/room label → ICS URL
    let labeledRoomURLs: [String: String] = [
        "Main Hall": "https://calendar.google.com/calendar/ical/4b61397c9c164adc781268eab68ca1b91cc419c5b0db15109103ec96cc07a054%40group.calendar.google.com/public/basic.ics",
        "Panel B": "https://calendar.google.com/calendar/ical/84a23e4aaf90f48c9f08b27bbf0f48da69c4597af7aba03d0c20afd7c7bb70e3%40group.calendar.google.com/public/basic.ics",
        "Panel C": "https://calendar.google.com/calendar/ical/3bc7ff28f764043382915fa9274e35c35a5ef9b1b9566f75c9c896127ce3b219%40group.calendar.google.com/public/basic.ics",
        "Panel D": "https://calendar.google.com/calendar/ical/83b43a61180055a7c9da44da9a723a891501698204f0499294a0db93198b3b13%40group.calendar.google.com/public/basic.ics",
        "Windwatch": "https://calendar.google.com/calendar/ical/3e9442320c8d4b1a9349ad561c2d6445167387f2fbd507c916a22798afe4350c%40group.calendar.google.com/public/basic.ics",
        "Kids Track": "https://calendar.google.com/calendar/ical/688704b695362de1cddd3611655db243616492260d8e69460a7104e2712a3628%40group.calendar.google.com/public/basic.ics",
        "Photo Sessions": "https://calendar.google.com/calendar/ical/76042d34e4a2af266c8dd469aa94c2c3713235f0d23ee40ff323dea5e67f9dbd%40group.calendar.google.com/public/basic.ics",
        "Vendor Hall Announcements": "https://calendar.google.com/calendar/ical/c1af329cac8ab9d99f5aafe3c566fa4ebd2d3be789f2132278ac0f57a4ed689e%40group.calendar.google.com/public/basic.ics",
        "Special Events": "https://calendar.google.com/calendar/ical/f96346e217449a7d8fa443a85c5c9518535157df8f0d416f25c63cdbdbf4a3b8%40group.calendar.google.com/public/basic.ics"
    ]

    private let cacheLastSyncKey = "TLI.Schedule.cacheLastSync"

    private var cacheURL: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return cacheDir.appendingPathComponent("tli-ics-events-cache-v2.json")
    }

    /// If `urls` is empty, loads all labeled feeds. Otherwise you can pass a subset.
    func load(from urls: [String] = [], debug: Bool = false) {
        isLoading = true
        lastLoadErrorMessage = nil

        // Always show cached content first (if present) for offline-first UX.
        if let cached = loadCache(), !cached.isEmpty {
            events = cached.sorted(by: { $0.startDate < $1.startDate })
            loadedFromCache = true
            if let date = UserDefaults.standard.object(forKey: cacheLastSyncKey) as? Date {
                lastSyncDate = date
            }
        }

        let session = URLSession(configuration: .default)
        let group = DispatchGroup()
        var loadedEvents: [ICSParsedEvent] = []
        let syncQueue = DispatchQueue(label: "ICSLoader.SyncQueue")

        // Decide which sources to load
        let sources = urls.isEmpty
            ? labeledRoomURLs
            : labeledRoomURLs.filter { urls.contains($0.value) || urls.contains($0.key) }

        for (room, urlString) in sources {
            guard let url = URL(string: urlString) else { continue }
            group.enter()

            session.dataTask(with: url) { data, response, error in
                defer { group.leave() }

                if let error = error {
                    if debug { print("ICSLoader: error loading \(room): \(error.localizedDescription)") }
                    return
                }

                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode),
                    let mimeType = httpResponse.mimeType,
                    mimeType.contains("text") || mimeType.contains("calendar"),
                    let data = data,
                    let content = String(data: data, encoding: .utf8)
                        ?? String(data: data, encoding: .isoLatin1)
                else {
                    if debug { print("ICSLoader: invalid or missing content from \(room)") }
                    return
                }

                let parsedEvents = ICSParser().parseICS(content, room: room)
                if debug {
                    print("ICSLoader: parsed \(parsedEvents.count) events from room: \(room)")
                }

                syncQueue.sync {
                    loadedEvents.append(contentsOf: parsedEvents)
                }
            }
            .resume()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            let sorted = loadedEvents.sorted(by: { $0.startDate < $1.startDate })
            if !sorted.isEmpty {
                self.saveCache(sorted)
            }

            DispatchQueue.main.async {
                if !sorted.isEmpty {
                    self.events = sorted
                    self.loadedFromCache = false
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(self.lastSyncDate, forKey: self.cacheLastSyncKey)
                    self.lastLoadErrorMessage = nil
                } else if self.events.isEmpty {
                    self.lastLoadErrorMessage = "Unable to reach schedule feeds. Check your connection and retry."
                } else if self.loadedFromCache {
                    self.lastLoadErrorMessage = "Live schedule is unavailable. Showing cached schedule."
                } else {
                    self.lastLoadErrorMessage = "Live schedule is currently unavailable."
                }
                self.isLoading = false

                if debug {
                    print("ICSLoader: total events after sort = \(self.events.count)")
                    if self.loadedFromCache {
                        print("ICSLoader: showing cached content")
                    }
                }
            }
        }
    }

    func retry(from urls: [String] = []) {
        load(from: urls, debug: false)
    }

    private func loadCache() -> [ICSParsedEvent]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let cached = try? decoder.decode([CachedEvent].self, from: data) else { return nil }
        return cached.map(\.asParsedEvent)
    }

    private func saveCache(_ events: [ICSParsedEvent]) {
        let payload = events.map(CachedEvent.init)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        try? data.write(to: cacheURL, options: [.atomic])
    }
}

private struct CachedEvent: Codable {
    let id: UUID
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let room: String

    init(_ event: ICSParsedEvent) {
        id = event.id
        title = event.title
        description = event.description
        startDate = event.startDate
        endDate = event.endDate
        room = event.room
    }

    var asParsedEvent: ICSParsedEvent {
        ICSParsedEvent(
            id: id,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            room: room
        )
    }
}

// MARK: - ICS Parser

class ICSParser {
    func parseICS(_ content: String, room: String) -> [ICSParsedEvent] {
        var events: [ICSParsedEvent] = []
        var currentEvent: [String: String] = [:]

        // Unfold lines per RFC5545 spec (handle wrapped DESCRIPTION, etc.)
        let unfolded = content
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        func flush() {
            // DESCRIPTION is now OPTIONAL — don’t throw the whole event away if it’s missing.
            guard
                let titleRaw = currentEvent["SUMMARY"],
                let startString = currentEvent["DTSTART"],
                let endString = currentEvent["DTEND"],
                let startDate = parseDate(startString),
                let endDate = parseDate(endString)
            else {
                return
            }

            let descRaw = currentEvent["DESCRIPTION"] ?? ""

            let title = titleRaw.strippingHTML().cleanedICSString()
            let description = descRaw.strippingHTML().cleanedICSString()
            let uidSeed = currentEvent["UID"]?.cleanedICSString().lowercased()
                ?? "\(title)|\(startString)|\(endString)|\(room)".lowercased()

            let event = ICSParsedEvent(
                id: stableUUID(from: uidSeed),
                title: title,
                description: description,
                startDate: startDate,
                endDate: endDate,
                room: room
            )
            events.append(event)
        }

        for line in unfolded.components(separatedBy: .newlines) {
            if line == "BEGIN:VEVENT" {
                currentEvent = [:]
            } else if line == "END:VEVENT" {
                flush()
            } else {
                let parts = line.components(separatedBy: ":")
                guard parts.count >= 2 else { continue }

                // Strip off any parameters (TZID, VALUE, etc.)
                let key = parts[0].components(separatedBy: ";")[0]
                let value = parts
                    .dropFirst()
                    .joined(separator: ":")
                    .replacingOccurrences(of: "\\n", with: "\n")

                currentEvent[key] = value
            }
        }

        return events
    }

    // MARK: - Date parsing

    private let formatters: [DateFormatter] = {
        let formats = [
            "yyyyMMdd'T'HHmmss'Z'",
            "yyyyMMdd'T'HHmmss",
            "yyyyMMdd"
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = format
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }
    }()

    func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    /// Build a deterministic UUID so row identity remains stable across refreshes.
    private func stableUUID(from seed: String) -> UUID {
        let digest = SHA256.hash(data: Data(seed.utf8))
        let bytes = Array(digest.prefix(16))
        let uuidString = String(
            format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

// MARK: - String helpers

extension String {
    func strippingHTML() -> String {
        do {
            return try SwiftSoup.parse(self).text()
        } catch {
            return self
        }
    }

    func cleanedICSString() -> String {
        self
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "�", with: "") // Handles encoding issues
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
