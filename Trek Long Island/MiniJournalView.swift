// Copyright Bryan Carroll. All rights reserved.
//
//  MiniJournalView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct MiniJournalView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("TLI.MiniJournal.day1") private var day1Entry = ""
    @AppStorage("TLI.MiniJournal.day2") private var day2Entry = ""
    @AppStorage("TLI.MiniJournal.day3") private var day3Entry = ""
    @AppStorage("TLI.MiniJournal.guidedMode") private var guidedModeEnabled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                introCard

                ForEach(TLIConventionDates.conventionDays) { day in
                    journalCard(for: day)
                }
            }
            .adaptiveContentWidth(maxWidth: TLILayout.tightContentMaxWidth, horizontalPadding: 16, verticalPadding: 16)
        }
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Mini Journal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Three-Day Captain's Log")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Keep a quick personal log for each day of Trek Long Island. The stardates below use the app's shared TNG-style convention formula.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $guidedModeEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guided writing mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text("Show reader-response prompts if you want help reflecting on what the convention meant to you.")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func journalCard(for day: TLIConventionDates.ConventionDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(day.title) • \(day.subtitle)")
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text("Stardate \(day.stardate)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(TLITheme.accent(scheme))
                }

                Spacer(minLength: 8)

                Button("Clear") {
                    binding(for: day).wrappedValue = ""
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            Text(day.prompt)
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if guidedModeEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reader-response prompts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    ForEach(readerResponsePrompts(for: day), id: \.self) { prompt in
                        Label(prompt, systemImage: "quote.bubble")
                            .font(.footnote)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TLITheme.cardBackground(scheme).opacity(0.22))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                )
            }

            TextField("Captain's log entry", text: binding(for: day), axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(5...10)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TLITheme.cardBackground(scheme).opacity(0.28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                )
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func binding(for day: TLIConventionDates.ConventionDay) -> Binding<String> {
        switch day.id {
        case 1:
            return $day1Entry
        case 2:
            return $day2Entry
        default:
            return $day3Entry
        }
    }

    private func readerResponsePrompts(for day: TLIConventionDates.ConventionDay) -> [String] {
        switch day.id {
        case 1:
            return [
                "What moment pulled you into the convention world most strongly today?",
                "Which panel, person, or place changed your expectations once you experienced it?",
                "What did you notice yourself feeling, and what do you think sparked that reaction?"
            ]
        case 2:
            return [
                "What stood out as especially meaningful or surprising during the busiest day?",
                "Did anything connect to your own memories, values, or fandom history in a new way?",
                "What part of today do you think another attendee might read differently than you did?"
            ]
        default:
            return [
                "What will stay with you after the convention is over, and why that moment?",
                "How did your understanding of the weekend change from day one to day three?",
                "If this weekend had a theme or message for you personally, what would it be?"
            ]
        }
    }
}

#Preview {
    NavigationStack {
        MiniJournalView()
    }
}
