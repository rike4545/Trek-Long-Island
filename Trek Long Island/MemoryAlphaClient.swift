// Copyright Bryan Carroll. All rights reserved.
//
//  MemoryAlphaClient.swift
//  Trek Long Island
//

import Foundation

struct MemoryAlphaSearchResult: Identifiable, Hashable {
    let pageID: Int
    let title: String
    let summary: String
    let sourceURL: URL

    var id: Int { pageID }
}

actor MemoryAlphaClient {
    static let shared = MemoryAlphaClient()

    private struct SearchEnvelope: Decodable {
        let query: SearchQuery?
    }

    private struct SearchQuery: Decodable {
        let search: [SearchItem]
    }

    private struct SearchItem: Decodable {
        let title: String
        let pageid: Int
    }

    private struct ExtractEnvelope: Decodable {
        let query: ExtractQuery?
    }

    private struct ExtractQuery: Decodable {
        let pages: [String: ExtractPage]
    }

    private struct ExtractPage: Decodable {
        let extract: String?
    }

    func answer(for userQuery: String) async -> HelloComputerAnswer? {
        guard let topResult = await topResult(for: userQuery) else { return nil }

        return HelloComputerAnswer(
            text: """
            Memory Alpha summary (\(topResult.title)):
            \(topResult.summary)

            Source: \(topResult.sourceURL.absoluteString)
            """,
            source: .generalGuidance,
            confidence: 0.82
        )
    }

    func search(query: String, limit: Int = 8) async throws -> [MemoryAlphaSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let candidates = try await rankedCandidates(for: trimmed)
        guard !candidates.isEmpty else { return [] }

        var results: [MemoryAlphaSearchResult] = []
        for match in candidates.prefix(limit) {
            guard let extract = try await fetchExtract(pageID: match.pageid) else { continue }
            let summary = Self.summarize(extract)
            guard !summary.isEmpty else { continue }

            let wikiTitle = match.title.replacingOccurrences(of: " ", with: "_")
            guard let sourceURL = URL(string: "https://memory-alpha.fandom.com/wiki/\(wikiTitle)") else {
                continue
            }

            results.append(
                MemoryAlphaSearchResult(
                    pageID: match.pageid,
                    title: match.title,
                    summary: summary,
                    sourceURL: sourceURL
                )
            )
        }

        return results
    }

    private func topResult(for query: String) async -> MemoryAlphaSearchResult? {
        try? await search(query: query, limit: 1).first
    }

    private func rankedCandidates(for query: String) async throws -> [SearchItem] {
        let terms = Self.candidateSearchTerms(from: query)
        guard !terms.isEmpty else { return [] }

        var candidates: [SearchItem] = []
        for term in terms.prefix(4) {
            let found = try await searchTopPages(for: term, limit: 6)
            candidates.append(contentsOf: found)
        }

        var seen = Set<Int>()
        let unique = candidates.filter { seen.insert($0.pageid).inserted }

        return unique.sorted {
            Self.scoreTitle($0.title, query: query) > Self.scoreTitle($1.title, query: query)
        }
    }

    private func searchTopPages(for term: String, limit: Int) async throws -> [SearchItem] {
        var components = URLComponents(string: "https://memory-alpha.fandom.com/api.php")
        components?.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "list", value: "search"),
            .init(name: "srsearch", value: term),
            .init(name: "srlimit", value: String(limit)),
            .init(name: "format", value: "json")
        ]
        guard let url = components?.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(SearchEnvelope.self, from: data)
        return decoded.query?.search ?? []
    }

    private func fetchExtract(pageID: Int) async throws -> String? {
        var components = URLComponents(string: "https://memory-alpha.fandom.com/api.php")
        components?.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "prop", value: "extracts"),
            .init(name: "exintro", value: "1"),
            .init(name: "explaintext", value: "1"),
            .init(name: "pageids", value: String(pageID)),
            .init(name: "format", value: "json")
        ]
        guard let url = components?.url else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ExtractEnvelope.self, from: data)
        return decoded.query?.pages.values.first?.extract
    }

    private static func candidateSearchTerms(from query: String) -> [String] {
        let lowered = query.lowercased()
        let stripped = lowered
            .replacingOccurrences(of: "what is", with: "")
            .replacingOccurrences(of: "what are", with: "")
            .replacingOccurrences(of: "who is", with: "")
            .replacingOccurrences(of: "who was", with: "")
            .replacingOccurrences(of: "who are", with: "")
            .replacingOccurrences(of: "why is", with: "")
            .replacingOccurrences(of: "why did", with: "")
            .replacingOccurrences(of: "how did", with: "")
            .replacingOccurrences(of: "how does", with: "")
            .replacingOccurrences(of: "tell me about", with: "")
            .replacingOccurrences(of: "explain", with: "")
            .replacingOccurrences(of: "star trek", with: "")
            .replacingOccurrences(of: "in star trek", with: "")
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = stripped
            .split(whereSeparator: { $0 == "," || $0 == ";" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var terms: [String] = []
        if !stripped.isEmpty { terms.append(stripped) }
        terms.append(contentsOf: parts)

        if stripped.contains(" and ") {
            terms.append(contentsOf: stripped
                .components(separatedBy: " and ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty })
        }

        let tokenized = stripped
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" && $0 != "'" })
            .map(String.init)
        let stop: Set<String> = [
            "the", "a", "an", "is", "are", "was", "were", "did", "does", "do",
            "in", "on", "of", "to", "for", "from", "about", "explain", "tell", "me",
            "what", "who", "why", "how", "when", "where", "actor", "character",
            "cast", "crew", "played", "play", "portrayed"
        ]
        let focused = tokenized.filter { $0.count > 2 && !stop.contains($0) }
        if !focused.isEmpty {
            terms.append(focused.joined(separator: " "))
            if focused.count >= 2 {
                terms.append(focused.prefix(2).joined(separator: " "))
            }
        }

        terms.append("Star Trek")
        var seen = Set<String>()
        return terms
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    private static func summarize(_ extract: String) -> String {
        let cleaned = extract
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return "" }

        let sentences = cleaned
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let firstTwo = sentences.prefix(2).joined(separator: ". ")
        let candidate = firstTwo.isEmpty ? cleaned : firstTwo + "."
        return String(candidate.prefix(420))
    }

    private static func scoreTitle(_ title: String, query: String) -> Int {
        let qTokens = Set(query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        let tTokens = Set(title.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        let overlap = qTokens.intersection(tTokens).count
        let containsBonus = query.lowercased().contains(title.lowercased()) ? 3 : 0
        return overlap * 2 + containsBonus
    }
}
