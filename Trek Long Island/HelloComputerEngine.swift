// Copyright Bryan Carroll. All rights reserved.
//  HelloComputerEngine.swift
//  Trek Long Island
//
//  Lightweight FAQ matcher for "Hello Computer".
//
//  IMPORTANT:
//  Hard rule enforced FIRST (before scoring):
//   - Ticket purchase / checkout / order / pricing questions → treklongislandtickets.square.site
//   - Everything else → treklongisland.com
//
//  Swift 6 • iOS 17+
//

import Foundation
import NaturalLanguage

enum HelloComputerEngine {
    private struct RankedFAQ {
        let faq: HelloComputerFAQ
        let semantic: Double
        let lexical: Double
        let neural: Double
    }

    static func answer(for query: String, audience: HelloComputerAudience = .attendee) -> HelloComputerAnswer? {
        let q = normalize(query)
        guard q.count >= 2 else { return nil }

        if let missionAnswer = HelloComputerMissionRouter.answer(for: q, audience: audience) {
            return missionAnswer
        }

        // ✅ Hard rule wins, always.
        if HelloComputerHardRuleRouter.isTicketPurchaseQuery(q) {
            return HelloComputerAnswer(
                text: HelloComputerHardRuleRouter.ticketPurchaseAnswerText(),
                source: .officialFAQ,
                confidence: 1.0
            )
        }

        // Blend lexical matching, semantic similarity, and a tiny neural reranker.
        var best: (faq: HelloComputerFAQ, score: Double, lexical: Double, semantic: Double, neural: Double)? = nil

        for faq in HelloComputerFAQBank.allFAQs {
            let features = faqFeatures(for: faq, against: q)
            let lexicalScore = features.lexical
            let semanticScore = features.semantic
            let neuralScore = HelloComputerFAQNeuralNetwork.shared.predict(features: features.vector).confidence
            let score = lexicalScore + (semanticScore * 2.4) + (neuralScore * 3.4)
            if let b = best {
                if score > b.score { best = (faq, score, lexicalScore, semanticScore, neuralScore) }
            } else {
                best = (faq, score, lexicalScore, semanticScore, neuralScore)
            }
        }

        guard let chosen = best else { return nil }

        let lexicalConfidence = min(max(chosen.lexical / 10.0, 0.0), 1.0)
        let confidence = max(lexicalConfidence, max(chosen.semantic, chosen.neural))

        // Require at least one strong signal before we answer.
        if chosen.lexical < 2.25 && chosen.semantic < 0.63 && chosen.neural < 0.60 { return nil }
        if confidence < 0.28 { return nil }

        return HelloComputerAnswer(
            text: chosen.faq.answer,
            source: chosen.faq.source,
            confidence: confidence
        )
    }

    static func semanticFallbackAnswer(for query: String, audience: HelloComputerAudience = .attendee) -> HelloComputerAnswer? {
        let q = normalize(query)
        guard q.count >= 2 else { return nil }

        if let direct = answer(for: query, audience: audience) {
            return direct
        }

        let ranked = HelloComputerFAQBank.allFAQs
            .map { faq in
                let features = faqFeatures(for: faq, against: q)
                return RankedFAQ(
                    faq: faq,
                    semantic: features.semantic,
                    lexical: features.lexical,
                    neural: HelloComputerFAQNeuralNetwork.shared.predict(features: features.vector).confidence
                )
            }
            .sorted(by: { (lhs: RankedFAQ, rhs: RankedFAQ) -> Bool in
                if lhs.neural == rhs.neural {
                    if lhs.semantic == rhs.semantic {
                        return lhs.lexical > rhs.lexical
                    }
                    return lhs.semantic > rhs.semantic
                }
                return lhs.neural > rhs.neural
            })

        guard let candidate = ranked.first,
              candidate.semantic >= 0.56 || candidate.neural >= 0.62 else {
            return nil
        }

        return HelloComputerAnswer(
            text: candidate.faq.answer,
            source: candidate.faq.source,
            confidence: max(candidate.semantic, candidate.neural)
        )
    }

    private static func faqFeatures(for faq: HelloComputerFAQ, against normalizedQuery: String) -> FAQFeatureSet {
        let queryTokens = Set(tokens(normalizedQuery))
        let tagTokens = Set(faq.tags.flatMap { tokens(normalize($0)) })
        let questionTokens = Set(tokens(normalize(faq.question)))

        let tagOverlapCount = queryTokens.intersection(tagTokens).count
        let questionOverlapCount = queryTokens.intersection(questionTokens).count

        // Bonus if the query contains a full tag phrase
        var phraseBonus: Double = 0
        var matchedTagPhrases = 0
        for tag in faq.tags {
            let t = normalize(tag)
            if t.count >= 3 && normalizedQuery.contains(t) {
                phraseBonus += 1.25
                matchedTagPhrases += 1
            }
        }

        // Bonus if query contains meaningful parts of question
        let questionPhrase = normalize(faq.question)
        let containsQuestionPhrase = questionPhrase.count >= 6 && normalizedQuery.contains(questionPhrase)
        if containsQuestionPhrase {
            phraseBonus += 2.0
        }

        let sourceBonus: Double = (faq.source == .officialFAQ) ? 0.35 : 0.0
        let lexical = (Double(tagOverlapCount) * 2.0) + (Double(questionOverlapCount) * 1.5) + phraseBonus + sourceBonus
        let semantic = semanticFAQScore(faq, against: normalizedQuery)

        let vector: [Double] = [
            min(Double(tagOverlapCount) / 6.0, 1.0),
            min(Double(questionOverlapCount) / 8.0, 1.0),
            min(phraseBonus / 4.5, 1.0),
            semantic,
            min(Double(matchedTagPhrases) / 3.0, 1.0),
            containsQuestionPhrase ? 1.0 : 0.0,
            faq.source == .officialFAQ ? 1.0 : 0.0,
            min(Double(queryTokens.count) / 14.0, 1.0)
        ]

        return FAQFeatureSet(lexical: lexical, semantic: semantic, vector: vector)
    }

    private static func scoreFAQ(_ faq: HelloComputerFAQ, against normalizedQuery: String) -> Double {
        faqFeatures(for: faq, against: normalizedQuery).lexical
    }

    private static func semanticFAQScore(_ faq: HelloComputerFAQ, against normalizedQuery: String) -> Double {
        let semanticCorpus = ([faq.question] + faq.tags)
            .joined(separator: ". ")
        return HelloComputerSemanticRetrieval.similarity(
            normalizedQuery,
            normalize(semanticCorpus)
        )
    }

    private static func tokens(_ s: String) -> [String] {
        s
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0) }
            .filter { $0.count >= 2 }
    }

    private static func normalize(_ s: String) -> String {
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

private struct FAQFeatureSet {
    let lexical: Double
    let semantic: Double
    let vector: [Double]
}

private enum HelloComputerSemanticRetrieval {
    private static let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        guard let embedding else { return 0 }

        let left = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !left.isEmpty, !right.isEmpty else { return 0 }

        let distance = embedding.distance(between: left, and: right)
        guard distance.isFinite else { return 0 }

        return max(0, min(1, 1 / (1 + distance)))
    }
}

private struct HelloComputerDenseLayer {
    let name: String
    let weights: [[Double]]
    let biases: [Double]
    let activation: HelloComputerActivation

    func forward(_ inputs: [Double]) -> [Double] {
        guard !weights.isEmpty,
              weights.count == biases.count,
              weights.allSatisfy({ $0.count == inputs.count }) else {
            return []
        }

        return zip(weights, biases).map { row, bias in
            activation.apply(dot(row, inputs) + bias)
        }
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0) { $0 + ($1.0 * $1.1) }
    }
}

private enum HelloComputerActivation {
    case tanh
    case sigmoid

    func apply(_ x: Double) -> Double {
        switch self {
        case .tanh:
            return Foundation.tanh(x)
        case .sigmoid:
            return 1 / (1 + exp(-x))
        }
    }
}

private struct HelloComputerNeuralNetwork {
    let layers: [HelloComputerDenseLayer]

    func predict(_ inputs: [Double]) -> [Double] {
        layers.reduce(inputs) { activations, layer in
            layer.forward(activations)
        }
    }
}

private struct HelloComputerNeuralInference: Hashable {
    let hiddenActivations: [Double]
    let output: [Double]

    var confidence: Double {
        output.first ?? 0
    }
}

private struct HelloComputerFAQNeuralNetwork {
    static let shared = HelloComputerFAQNeuralNetwork()

    // Generated by scripts/train_hello_computer_nn.py after supervised warmstart
    // and offline preference optimization on the curated Hello Computer dataset.
    private let hiddenLayer = HelloComputerDenseLayer(
        name: "faq_hidden_1",
        weights: [
            [1.3727, 0.9632, 0.8927, 1.3099, 0.5806, 0.3011, -0.1484, -0.3143],
            [0.4940, 1.3808, 0.7536, 1.1496, 0.4937, 0.4512, -0.1260, -0.2340],
            [0.3553, 0.4000, 1.5537, 0.7308, 1.0441, 0.6006, -0.0347, -0.2898],
            [0.8342, 0.7156, 0.6004, 1.7627, 0.4478, 0.1049, -0.2354, -0.1013],
            [0.9169, 0.5154, 0.4260, 0.8990, 0.3078, 0.2063, 0.1612, -0.4168],
            [0.3027, 0.3618, 0.3070, 0.8853, 0.2763, 0.3538, 0.3206, -0.0098]
        ],
        biases: [-0.8931, -0.7665, -0.6258, -0.9228, -0.6182, -0.5108],
        activation: .tanh
    )

    private let outputLayer = HelloComputerDenseLayer(
        name: "faq_output",
        weights: [
            [2.2431, 1.8976, 1.8010, 2.3069, 1.4648, 1.1514]
        ],
        biases: [-1.3402],
        activation: .sigmoid
    )

    private var network: HelloComputerNeuralNetwork {
        HelloComputerNeuralNetwork(
            layers: [hiddenLayer, outputLayer]
        )
    }

    func predict(features: [Double]) -> HelloComputerNeuralInference {
        guard features.count == hiddenLayer.weights.first?.count else {
            return HelloComputerNeuralInference(hiddenActivations: [], output: [0])
        }

        let hidden = hiddenLayer.forward(features)
        let output = outputLayer.forward(hidden)
        return HelloComputerNeuralInference(hiddenActivations: hidden, output: output)
    }

    func outputForDebug(features: [Double]) -> [String: [Double]] {
        let inference = predict(features: features)
        return [
            hiddenLayer.name: inference.hiddenActivations,
            outputLayer.name: inference.output
        ]
    }
}

// MARK: - Embedded Assistant (Schedule-first)

private enum HelloComputerAssistantIntent {
    case briefing
    case nextUp
    case buildMyDay
    case conflicts
    case search(query: String)
}

enum HelloComputerAssistantEngine {
    static func answer(for query: String, audience: HelloComputerAudience) async -> HelloComputerAnswer? {
        let normalized = normalize(query)
        guard normalized.count >= 2 else { return nil }

        let intent = inferIntent(from: normalized)
        guard intent != nil else { return nil }

        let events = await HelloComputerScheduleService.shared.events()
        guard !events.isEmpty else {
            return HelloComputerAnswer(
                text: "Schedule data is not loaded yet. Please open the Schedule tab, then ask again.",
                source: .generalGuidance,
                confidence: 0.7
            )
        }

        let answerText: String
        switch intent! {
        case .briefing:
            answerText = briefingAnswer(events: events)
        case .nextUp:
            answerText = nextUpAnswer(events: events)
        case .buildMyDay:
            answerText = buildMyDayAnswer(events: events, audience: audience)
        case .conflicts:
            answerText = conflictsAnswer(events: events)
        case .search(let search):
            answerText = searchAnswer(events: events, query: search)
        }

        return HelloComputerAnswer(
            text: answerText,
            source: .aiAssist,
            confidence: 0.92
        )
    }

    private static func inferIntent(from normalizedQuery: String) -> HelloComputerAssistantIntent? {
        if containsAny(normalizedQuery, ["brief me", "status report", "mission brief", "happening now", "give me a briefing"]) {
            return .briefing
        }

        if containsAny(normalizedQuery, ["what's next", "whats next", "what is next", "what should i do next", "what do i do next", "next panel", "next event"]) {
            return .nextUp
        }

        if containsAny(normalizedQuery, ["build my day", "plan my day", "make me a schedule", "itinerary", "today plan"]) {
            return .buildMyDay
        }

        if containsAny(normalizedQuery, ["conflict", "overlap", "double booked"]) {
            return .conflicts
        }

        if containsAny(normalizedQuery, ["find", "search", "show me", "any ", "panels", "events"]) {
            return .search(query: normalizedQuery)
        }

        return nil
    }

    static func actionRequest(for query: String) async -> HelloComputerPendingAction? {
        let normalized = normalize(query)
        guard normalized.count >= 2 else { return nil }

        let wantsReminder = containsAny(normalized, ["remind", "reminder", "notify", "notification"]) &&
            containsAny(normalized, ["before", "prior"])
        let wantsAddFavorite = containsAny(normalized, ["favorite", "favourite", "star", "save"]) &&
            containsAny(normalized, ["add", "mark", "favorite", "favourite", "star", "save"])

        let wantsRemoveFavorite = containsAny(normalized, ["favorite", "favourite", "star", "save"]) &&
            containsAny(normalized, ["remove", "unfavorite", "unfavourite", "unstar", "delete"])

        guard wantsReminder || wantsAddFavorite || wantsRemoveFavorite else { return nil }

        let events = await HelloComputerScheduleService.shared.events()
        guard !events.isEmpty else { return nil }

        let target: ICSParsedEvent?
        if containsAny(normalized, ["next", "next event", "next panel"]) {
            target = events
                .filter { $0.endDate >= Date() }
                .sorted { $0.startDate < $1.startDate }
                .first
        } else {
            target = bestEventMatch(for: normalized, in: events)
        }

        guard let target else { return nil }

        if wantsReminder {
            let minutes = reminderMinutes(from: normalized) ?? 15
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

        if wantsAddFavorite {
            return HelloComputerPendingAction(
                kind: .addFavorite(eventID: target.id.uuidString, title: target.title),
                prompt: "Add \"\(target.title)\" to your favorites?"
            )
        }

        return HelloComputerPendingAction(
            kind: .removeFavorite(eventID: target.id.uuidString, title: target.title),
            prompt: "Remove \"\(target.title)\" from your favorites?"
        )
    }

    private static func briefingAnswer(events: [ICSParsedEvent]) -> String {
        let now = Date()
        let happeningNow = events
            .filter { $0.startDate <= now && $0.endDate >= now }
            .sorted { $0.endDate < $1.endDate }
        let nextUp = events
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .prefix(3)

        let nowLine: String
        if let live = happeningNow.first {
            nowLine = "Now: \(live.title) • \(live.room)"
        } else {
            nowLine = "Now: No live panel at this moment."
        }

        let nextLines: String
        if nextUp.isEmpty {
            nextLines = "Next: No upcoming items in the current feed window."
        } else {
            nextLines = nextUp.map {
                "• \($0.title) — \(formatRange(start: $0.startDate, end: $0.endDate)) • \($0.room)"
            }.joined(separator: "\n")
        }

        return """
        Mission briefing:
        \(nowLine)

        Next up:
        \(nextLines)
        """
    }

    private static func nextUpAnswer(events: [ICSParsedEvent]) -> String {
        let now = Date()
        guard let next = events
            .filter({ $0.endDate >= now })
            .sorted(by: { $0.startDate < $1.startDate })
            .first else {
            return "No upcoming events were found in the current schedule window."
        }

        return """
        Next up:
        \(next.title)
        \(formatRange(start: next.startDate, end: next.endDate)) • \(next.room)
        """
    }

    private static func buildMyDayAnswer(events: [ICSParsedEvent], audience: HelloComputerAudience) -> String {
        let cal = Calendar.current
        let now = Date()
        let dayEvents = events
            .filter { cal.isDate($0.startDate, inSameDayAs: now) && $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }

        guard !dayEvents.isEmpty else {
            return "I could not find events for today yet. Try again after schedule sync, or ask for a specific topic."
        }

        // Keep first 5 non-overlapping events to create a practical plan.
        var picks: [ICSParsedEvent] = []
        var lastEnd: Date?
        for event in dayEvents {
            if let end = lastEnd, event.startDate < end {
                continue
            }
            picks.append(event)
            lastEnd = event.endDate
            if picks.count == 5 { break }
        }

        let header = audience == .staff ? "Suggested shift flow:" : "Suggested day plan:"
        let body = picks.enumerated().map { idx, event in
            "\(idx + 1). \(event.title) — \(formatRange(start: event.startDate, end: event.endDate)) • \(event.room)"
        }.joined(separator: "\n")

        return "\(header)\n\(body)"
    }

    private static func conflictsAnswer(events: [ICSParsedEvent]) -> String {
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

        guard !conflicts.isEmpty else {
            return "I don't see upcoming time conflicts in the loaded schedule."
        }

        let lines = conflicts.map { first, second in
            "• \(first.title) overlaps \(second.title)"
        }.joined(separator: "\n")
        return "Potential conflicts:\n\(lines)"
    }

    private static func searchAnswer(events: [ICSParsedEvent], query: String) -> String {
        let stopWords: Set<String> = [
            "find", "search", "show", "me", "any", "panels", "panel", "events",
            "today", "this", "that", "for", "with", "the", "a", "an"
        ]
        let tokens = query
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0) }
            .filter { $0.count >= 2 && !stopWords.contains($0) }

        let ranked = events
            .map { event in
                (event: event, score: eventSearchScore(for: event, normalizedQuery: query, tokens: tokens))
            }
            .filter { $0.score > 0.45 }
            .sorted {
                if $0.score == $1.score {
                    return $0.event.startDate < $1.event.startDate
                }
                return $0.score > $1.score
            }

        let matches = ranked.map(\.event)

        let top = Array(matches.prefix(5))
        guard !top.isEmpty else {
            return "I couldn't find matching events yet. Try another keyword like DS9, cosplay, vendor, or kids."
        }

        let lines = top.map {
            "• \($0.title) — \(formatRange(start: $0.startDate, end: $0.endDate)) • \($0.room)"
        }.joined(separator: "\n")

        return "Best matches:\n\(lines)"
    }

    private static func bestEventMatch(for normalizedQuery: String, in events: [ICSParsedEvent]) -> ICSParsedEvent? {
        let stopWords: Set<String> = [
            "add", "remove", "favorite", "favourite", "star", "save", "mark", "to",
            "from", "my", "next", "event", "panel", "please", "the", "a", "an"
        ]
        let tokens = normalizedQuery
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 && !stopWords.contains($0) }

        guard !tokens.isEmpty else { return nil }

        let ranked = events.map { event -> (ICSParsedEvent, Double) in
            let score = eventSearchScore(for: event, normalizedQuery: normalizedQuery, tokens: tokens)
            return (event, score)
        }
        .filter { $0.1 > 0.65 }
        .sorted {
            if $0.1 == $1.1 {
                return $0.0.startDate < $1.0.startDate
            }
            return $0.1 > $1.1
        }

        return ranked.first?.0
    }

    private static func reminderMinutes(from normalizedQuery: String) -> Int? {
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

    private static func formatRange(start: Date, end: Date) -> String {
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .short
        let time = DateFormatter()
        time.dateStyle = .none
        time.timeStyle = .short
        return "\(date.string(from: start)) to \(time.string(from: end))"
    }

    private static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    private static func eventSearchScore(for event: ICSParsedEvent, normalizedQuery: String, tokens: [String]) -> Double {
        let haystack = normalize("\(event.title) \(event.description) \(event.room)")
        let tokenHits = Double(tokens.reduce(into: 0) { partial, token in
            if haystack.contains(token) { partial += 1 }
        })
        let phraseBoost = haystack.contains(normalizedQuery) ? 1.75 : 0
        let semanticBoost = HelloComputerSemanticRetrieval.similarity(normalizedQuery, haystack) * 2.6
        return tokenHits + phraseBoost + semanticBoost
    }

    private static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }
}

actor HelloComputerScheduleService {
    static let shared = HelloComputerScheduleService()

    private var cachedEvents: [ICSParsedEvent] = []
    private var lastLoaded: Date?
    private let ttl: TimeInterval = 60 * 5
    private let session: URLSession = .shared
    private let sources: [String: String] = ICSLoader().labeledRoomURLs

    func events() async -> [ICSParsedEvent] {
        let now = Date()
        if let lastLoaded, now.timeIntervalSince(lastLoaded) < ttl, !cachedEvents.isEmpty {
            return cachedEvents
        }

        var all: [ICSParsedEvent] = []
        await withTaskGroup(of: [ICSParsedEvent].self) { group in
            for (room, urlString) in sources {
                guard let url = URL(string: urlString) else { continue }
                group.addTask { [session] in
                    do {
                        let (data, response) = try await session.data(from: url)
                        guard let http = response as? HTTPURLResponse,
                              (200...299).contains(http.statusCode) else {
                            return []
                        }

                        guard let text = String(data: data, encoding: .utf8)
                            ?? String(data: data, encoding: .isoLatin1) else {
                            return []
                        }
                        return ICSParser().parseICS(text, room: room)
                    } catch {
                        return []
                    }
                }
            }

            for await batch in group {
                all.append(contentsOf: batch)
            }
        }

        let sorted = all.sorted { $0.startDate < $1.startDate }
        if !sorted.isEmpty {
            cachedEvents = sorted
            lastLoaded = now
        }
        return sorted
    }
}
