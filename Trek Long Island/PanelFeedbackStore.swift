// Copyright Bryan Carroll. All rights reserved.
//
//  PanelFeedbackStore.swift
//  Trek Long Island
//
//  Local feedback capture + organizer insights for schedule sessions.
//

import Foundation
import FirebaseFirestore

enum PanelFeedbackTag: String, CaseIterable, Codable, Identifiable {
    case content
    case moderation
    case av

    var id: String { rawValue }

    var title: String {
        switch self {
        case .content: return "Content"
        case .moderation: return "Moderation"
        case .av: return "A/V"
        }
    }
}

struct PanelFeedbackEntry: Identifiable, Codable {
    let id: String
    let eventID: String
    let eventTitle: String
    let room: String
    let attendeeID: String
    var rating: Int
    var tags: [PanelFeedbackTag]
    var comment: String
    var isIssueReported: Bool
    var isIssueResolved: Bool
    var isHidden: Bool
    let submittedAt: Date
    var updatedAt: Date

    var isEditable: Bool {
        Date().timeIntervalSince(submittedAt) <= (15 * 60)
    }
}

struct PanelFeedbackInsight: Identifiable {
    let eventID: String
    let eventTitle: String
    let room: String
    let responseCount: Int
    let averageRating: Double
    let issueCount: Int
    let lastSubmittedAt: Date
    let lowRatingCount: Int
    let topTags: [PanelFeedbackTag]

    var id: String { eventID }
}

@MainActor
final class PanelFeedbackStore: ObservableObject {
    enum SubmitOutcome {
        case created
        case updated
        case locked
    }

    static let shared = PanelFeedbackStore()

    @Published private(set) var entries: [PanelFeedbackEntry] = []
    @Published private(set) var lowScoreThreshold: Double = 3.0
    @Published private(set) var minResponsesForAlert: Int = 5

    private let feedbackKey = "TLI.PanelFeedback.entries.v1"
    private let attendeeIDKey = "TLI.PanelFeedback.attendeeID.v1"
    private let thresholdKey = "TLI.PanelFeedback.lowScoreThreshold.v1"
    private let minResponsesKey = "TLI.PanelFeedback.minResponses.v1"
    private let conventionID = "trekli-2026"
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {
        load()
        startListening()
    }

    deinit {
        listener?.remove()
    }

    var totalResponses: Int {
        entries.count
    }

    var globalAverageRating: Double {
        guard !entries.isEmpty else { return 0 }
        let sum = entries.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(entries.count)
    }

    var issueReportCount: Int {
        entries.filter(\.isIssueReported).count
    }

    var flaggedEntries: [PanelFeedbackEntry] {
        entries
            .filter { !$0.isHidden && ($0.isIssueReported || $0.rating <= 2) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func submission(for eventID: String) -> PanelFeedbackEntry? {
        let attendee = currentAttendeeID()
        return entries.first { $0.eventID == eventID && $0.attendeeID == attendee }
    }

    func insights(limit: Int = 10) -> [PanelFeedbackInsight] {
        guard !entries.isEmpty else { return [] }

        let grouped = Dictionary(grouping: entries, by: \.eventID)
        var out: [PanelFeedbackInsight] = []
        out.reserveCapacity(grouped.count)

        for group in grouped.values {
            guard let first = group.first else { continue }
            let responseCount = group.count
            let sum = group.reduce(0) { $0 + $1.rating }
            let average = Double(sum) / Double(responseCount)
            let issueCount = group.filter(\.isIssueReported).count
            let lowRatingCount = group.filter { $0.rating <= 2 }.count
            let lastDate = group.map(\.updatedAt).max() ?? first.updatedAt

            let tags = group.flatMap(\.tags)
            let tagCounts = Dictionary(tags.map { ($0, 1) }, uniquingKeysWith: +)
            let sortedTags = tagCounts
                .sorted { lhs, rhs in
                    if lhs.value == rhs.value { return lhs.key.rawValue < rhs.key.rawValue }
                    return lhs.value > rhs.value
                }
                .map(\.key)

            out.append(
                PanelFeedbackInsight(
                    eventID: first.eventID,
                    eventTitle: first.eventTitle,
                    room: first.room,
                    responseCount: responseCount,
                    averageRating: average,
                    issueCount: issueCount,
                    lastSubmittedAt: lastDate,
                    lowRatingCount: lowRatingCount,
                    topTags: Array(sortedTags.prefix(3))
                )
            )
        }

        return out
            .sorted { lhs, rhs in
                if lhs.lastSubmittedAt == rhs.lastSubmittedAt {
                    return lhs.eventTitle < rhs.eventTitle
                }
                return lhs.lastSubmittedAt > rhs.lastSubmittedAt
            }
            .prefix(limit)
            .map { $0 }
    }

    func shouldAlert(for insight: PanelFeedbackInsight) -> Bool {
        insight.responseCount >= minResponsesForAlert &&
        insight.averageRating <= lowScoreThreshold
    }

    func makeExportFile() throws -> URL {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmm"

        let filename = "trek-long-island-panel-feedback-\(formatter.string(from: .now)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try exportCSV().write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportCSV() -> String {
        let header = [
            "event_id",
            "event_title",
            "room",
            "rating",
            "tags",
            "comment",
            "issue_reported",
            "issue_resolved",
            "comment_hidden",
            "anonymous_attendee_id",
            "submitted_at",
            "updated_at"
        ]

        let rows = entries
            .sorted { lhs, rhs in
                if lhs.eventTitle == rhs.eventTitle {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.eventTitle < rhs.eventTitle
            }
            .map { entry in
                [
                    entry.eventID,
                    entry.eventTitle,
                    entry.room,
                    "\(entry.rating)",
                    entry.tags.map(\.title).joined(separator: "; "),
                    entry.comment,
                    entry.isIssueReported ? "yes" : "no",
                    entry.isIssueResolved ? "yes" : "no",
                    entry.isHidden ? "yes" : "no",
                    entry.attendeeID,
                    Self.exportDateFormatter.string(from: entry.submittedAt),
                    Self.exportDateFormatter.string(from: entry.updatedAt)
                ].map(Self.csvField).joined(separator: ",")
            }

        return ([header.map(Self.csvField).joined(separator: ",")] + rows).joined(separator: "\n")
    }

    func submit(
        event: RisaScheduleEvent,
        rating: Int,
        tags: Set<PanelFeedbackTag>,
        comment: String,
        isIssueReported: Bool,
        now: Date = .now
    ) -> SubmitOutcome {
        let boundedRating = max(1, min(5, rating))
        let attendeeID = currentAttendeeID()
        let normalizedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        if let index = entries.firstIndex(where: { $0.eventID == event.id && $0.attendeeID == attendeeID }) {
            guard now.timeIntervalSince(entries[index].submittedAt) <= (15 * 60) else {
                return .locked
            }

            entries[index].rating = boundedRating
            entries[index].tags = Array(tags).sorted { $0.rawValue < $1.rawValue }
            entries[index].comment = normalizedComment
            entries[index].isIssueReported = isIssueReported
            entries[index].updatedAt = now
            save()
            syncEntry(entries[index])
            return .updated
        }

        let roomValue = event.room.isEmpty ? event.location : event.room
        let entry = PanelFeedbackEntry(
            id: UUID().uuidString,
            eventID: event.id,
            eventTitle: event.title,
            room: roomValue,
            attendeeID: attendeeID,
            rating: boundedRating,
            tags: Array(tags).sorted { $0.rawValue < $1.rawValue },
            comment: normalizedComment,
            isIssueReported: isIssueReported,
            isIssueResolved: false,
            isHidden: false,
            submittedAt: now,
            updatedAt: now
        )
        entries.insert(entry, at: 0)
        save()
        syncEntry(entry)
        return .created
    }

    func hideComment(entryID: String) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[index].isHidden = true
        entries[index].updatedAt = .now
        save()
        syncEntry(entries[index])
    }

    func resolveIssue(entryID: String) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[index].isIssueResolved = true
        entries[index].updatedAt = .now
        save()
        syncEntry(entries[index])
    }

    func setLowScoreThreshold(_ value: Double) {
        lowScoreThreshold = max(1.0, min(5.0, value))
        UserDefaults.standard.set(lowScoreThreshold, forKey: thresholdKey)
    }

    func setMinResponsesForAlert(_ value: Int) {
        minResponsesForAlert = max(1, min(100, value))
        UserDefaults.standard.set(minResponsesForAlert, forKey: minResponsesKey)
    }

    private func currentAttendeeID() -> String {
        if let existing = UserDefaults.standard.string(forKey: attendeeIDKey), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: attendeeIDKey)
        return created
    }

    private var feedbackCollection: CollectionReference {
        db.collection("conventions")
            .document(conventionID)
            .collection("panel_feedback")
    }

    private func startListening() {
        listener?.remove()

        listener = feedbackCollection
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        print("❌ Firestore panel feedback error: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else {
                        self.entries = []
                        self.save()
                        return
                    }

                    self.entries = docs.compactMap(Self.makeEntry(from:))
                    self.save()
                }
            }
    }

    private func syncEntry(_ entry: PanelFeedbackEntry) {
        feedbackCollection.document(entry.id).setData(Self.makeFirestoreData(from: entry), merge: true) { error in
            if let error {
                print("❌ Firestore panel feedback sync error: \(error.localizedDescription)")
            }
        }
    }

    private static func makeFirestoreData(from entry: PanelFeedbackEntry) -> [String: Any] {
        [
            "eventID": entry.eventID,
            "eventTitle": entry.eventTitle,
            "room": entry.room,
            "attendeeID": entry.attendeeID,
            "rating": entry.rating,
            "tags": entry.tags.map(\.rawValue),
            "comment": entry.comment,
            "isIssueReported": entry.isIssueReported,
            "isIssueResolved": entry.isIssueResolved,
            "isHidden": entry.isHidden,
            "submittedAt": Timestamp(date: entry.submittedAt),
            "updatedAt": Timestamp(date: entry.updatedAt)
        ]
    }

    private static func makeEntry(from doc: QueryDocumentSnapshot) -> PanelFeedbackEntry? {
        let data = doc.data()

        guard
            let eventID = data["eventID"] as? String,
            let eventTitle = data["eventTitle"] as? String,
            let attendeeID = data["attendeeID"] as? String
        else {
            return nil
        }

        let room = data["room"] as? String ?? ""
        let rating = max(1, min(5, data["rating"] as? Int ?? 1))
        let tags = (data["tags"] as? [String] ?? []).compactMap(PanelFeedbackTag.init(rawValue:))
        let comment = data["comment"] as? String ?? ""
        let isIssueReported = data["isIssueReported"] as? Bool ?? false
        let isIssueResolved = data["isIssueResolved"] as? Bool ?? false
        let isHidden = data["isHidden"] as? Bool ?? false

        let submittedAt: Date = {
            if let timestamp = data["submittedAt"] as? Timestamp {
                return timestamp.dateValue()
            }
            return .now
        }()

        let updatedAt: Date = {
            if let timestamp = data["updatedAt"] as? Timestamp {
                return timestamp.dateValue()
            }
            return submittedAt
        }()

        return PanelFeedbackEntry(
            id: doc.documentID,
            eventID: eventID,
            eventTitle: eventTitle,
            room: room,
            attendeeID: attendeeID,
            rating: rating,
            tags: tags,
            comment: comment,
            isIssueReported: isIssueReported,
            isIssueResolved: isIssueResolved,
            isHidden: isHidden,
            submittedAt: submittedAt,
            updatedAt: updatedAt
        )
    }

    private func load() {
        let defaults = UserDefaults.standard

        let threshold = defaults.double(forKey: thresholdKey)
        if threshold > 0 {
            lowScoreThreshold = threshold
        }

        let minResponses = defaults.integer(forKey: minResponsesKey)
        if minResponses > 0 {
            minResponsesForAlert = minResponses
        }

        guard let data = defaults.data(forKey: feedbackKey) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([PanelFeedbackEntry].self, from: data)
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            entries = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: feedbackKey)
        } catch {
            // Non-fatal: app should continue even if persistence fails.
        }
    }

    private static let exportDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
