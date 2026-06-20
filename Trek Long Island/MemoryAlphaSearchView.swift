// Copyright Bryan Carroll. All rights reserved.
//
//  MemoryAlphaSearchView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
final class MemoryAlphaSearchModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [MemoryAlphaSearchResult] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var hasSearched: Bool = false

    private var searchTask: Task<Void, Never>?

    func runSearch(with query: String? = nil) {
        let trimmed = (query ?? self.query).trimmingCharacters(in: .whitespacesAndNewlines)
        self.query = trimmed
        searchTask?.cancel()

        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            hasSearched = false
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil
        hasSearched = true

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let found = try await MemoryAlphaClient.shared.search(query: trimmed)
                guard !Task.isCancelled else { return }
                self.results = found
                self.isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                self.results = []
                self.errorMessage = "Memory Alpha is unavailable right now. Please try again."
                self.isSearching = false
            }
        }
    }

    deinit {
        searchTask?.cancel()
    }
}

struct MemoryAlphaSearchView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @StateObject private var model = MemoryAlphaSearchModel()

    private let suggestions = [
        "Spock",
        "Jean-Luc Picard",
        "Borg",
        "Deep Space 9",
        "Prime Directive",
        "Klingon"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MemoryAlphaHeroCard(scheme: scheme)

                if model.isSearching {
                    MemoryAlphaLoadingCard(scheme: scheme)
                } else if let errorMessage = model.errorMessage {
                    MemoryAlphaStatusCard(
                        scheme: scheme,
                        title: "Search interrupted",
                        message: errorMessage,
                        icon: "exclamationmark.triangle.fill"
                    )
                } else if model.results.isEmpty {
                    if model.hasSearched {
                        MemoryAlphaStatusCard(
                            scheme: scheme,
                            title: "No results found",
                            message: "Try a broader term like a character, species, ship, or episode title.",
                            icon: "magnifyingglass.circle"
                        )
                    } else {
                        MemoryAlphaSuggestionsCard(
                            scheme: scheme,
                            suggestions: suggestions,
                            onSelect: handleSuggestion
                        )
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(model.results) { result in
                            MemoryAlphaResultCard(
                                result: result,
                                scheme: scheme,
                                onOpen: { openURL(result.sourceURL) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Memory Alpha")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $model.query, prompt: "Search Star Trek lore")
        .onSubmit(of: .search) {
            submitSearch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Search", action: submitSearch)
                    .disabled(model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isSearching)
            }
        }
    }

    private func submitSearch() {
        model.runSearch()
    }

    private func handleSuggestion(_ suggestion: String) {
        model.runSearch(with: suggestion)
    }
}

private struct MemoryAlphaHeroCard: View {
    let scheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory Alpha Search")
                .font(.title3.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Look up Star Trek characters, species, ships, planets, and lore, then open source articles in your browser.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Label("Results are summarized from Memory Alpha and link back to the source article.", systemImage: "sparkles.rectangle.stack")
                .font(.caption)
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MemoryAlphaSuggestionsCard: View {
    let scheme: ColorScheme
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try one of these:")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSelect(suggestion)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TLITheme.accent(scheme))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
    }
}

private struct MemoryAlphaLoadingCard: View {
    let scheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 4) {
                Text("Searching Memory Alpha…")
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text("Scanning Star Trek records and assembling summaries.")
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
    }
}

private struct MemoryAlphaStatusCard: View {
    let scheme: ColorScheme
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
    }
}

private struct MemoryAlphaResultCard: View {
    let result: MemoryAlphaSearchResult
    let scheme: ColorScheme
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.title)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            Button(action: onOpen) {
                Label("Open article", systemImage: "safari")
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Opens the full Memory Alpha article.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
