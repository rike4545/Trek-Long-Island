// Copyright Bryan Carroll. All rights reserved.
//
//  FerengiRulesView.swift
//  Trek Long Island
//

import SwiftUI

@MainActor
struct FerengiRulesView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""

    private var filteredRules: [FerengiRuleEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return FerengiRuleLibrary.canonicalRules }
        return FerengiRuleLibrary.canonicalRules.filter {
            $0.matches(query: query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                if filteredRules.isEmpty {
                    emptyStateCard
                } else {
                    rulesSection(title: "Canonical highlights", rules: filteredRules)
                }

                rulesSection(title: "Unofficial sayings", rules: FerengiRuleLibrary.unofficialSayings)

                sourceCard
            }
            .adaptiveContentWidth(maxWidth: TLILayout.tightContentMaxWidth, horizontalPadding: 16, verticalPadding: 16)
        }
        .scrollContentBackground(.hidden)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .navigationTitle("Rules of Acquisition")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by rule or keyword")
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fandom: Ferengi Rules of Acquisition")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("A compact list of famous on-screen Ferengi rules, plus a few favorite unofficial sayings for extra lobes-and-latinum flavor.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var emptyStateCard: some View {
        ContentUnavailableView.search(text: searchText)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func rulesSection(title: String, rules: [FerengiRuleEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            ForEach(rules) { rule in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        if let number = rule.number {
                            Text("#\(number)")
                                .font(.footnote.monospaced().weight(.bold))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(TLITheme.accent(scheme)))
                        } else {
                            Text("Quote")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(TLITheme.accentSoft(scheme)))
                        }

                        Text(rule.text)
                            .font(.body)
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }

                    Text(rule.source)
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reference")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("These entries are based on the on-screen and commonly cited Rules of Acquisition cataloged by Memory Alpha.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: "https://memory-alpha.fandom.com/wiki/Rules_of_Acquisition") {
                Link(destination: url) {
                    Label("Open Memory Alpha reference", systemImage: "book")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(TLITheme.accent(scheme))
            }
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

private struct FerengiRuleEntry: Identifiable {
    let id: String
    let number: Int?
    let text: String
    let source: String

    init(number: Int? = nil, text: String, source: String) {
        self.number = number
        self.text = text
        self.source = source
        if let number {
            self.id = "rule-\(number)-\(text)"
        } else {
            self.id = "quote-\(text)"
        }
    }

    func matches(query: String) -> Bool {
        let normalized = query.lowercased()
        if let number, "#\(number)".contains(normalized) || "\(number)".contains(normalized) {
            return true
        }
        return text.lowercased().contains(normalized) || source.lowercased().contains(normalized)
    }
}

private enum FerengiRuleLibrary {
    static let canonicalRules: [FerengiRuleEntry] = [
        .init(number: 1, text: "Once you have their money, you never give it back.", source: "DS9: The Nagus; Heart of Stone"),
        .init(number: 3, text: "Never spend more for an acquisition than you have to.", source: "DS9: The Maquis, Part II"),
        .init(number: 6, text: "Never allow family to stand in the way of opportunity.", source: "DS9: The Nagus"),
        .init(number: 9, text: "Opportunity plus instinct equals profit.", source: "DS9: The Storyteller"),
        .init(number: 10, text: "Greed is eternal.", source: "DS9: Prophet Motive; VOY: False Profits"),
        .init(number: 17, text: "A contract is a contract is a contract… but only between Ferengi.", source: "DS9: Body Parts"),
        .init(number: 21, text: "Never place friendship above profit.", source: "DS9: Rules of Acquisition"),
        .init(number: 22, text: "A wise man can hear profit in the wind.", source: "DS9: Rules of Acquisition"),
        .init(number: 33, text: "It never hurts to suck up to the boss.", source: "DS9: Rules of Acquisition"),
        .init(number: 34, text: "War is good for business.", source: "DS9: Destiny"),
        .init(number: 35, text: "Peace is good for business.", source: "TNG: The Perfect Mate; DS9: Destiny"),
        .init(number: 48, text: "The bigger the smile, the sharper the knife.", source: "DS9: Rules of Acquisition"),
        .init(number: 57, text: "Good customers are as rare as latinum. Treasure them.", source: "DS9: Armageddon Game"),
        .init(number: 59, text: "Free advice is seldom cheap.", source: "DS9: Rules of Acquisition"),
        .init(number: 62, text: "The riskier the road, the greater the profit.", source: "DS9: Rules of Acquisition"),
        .init(number: 74, text: "Knowledge equals profit.", source: "VOY: Inside Man"),
        .init(number: 76, text: "Every once in a while, declare peace. It confuses the hell out of your enemies.", source: "DS9: The Homecoming"),
        .init(number: 111, text: "Treat people in your debt like family… exploit them.", source: "DS9: Past Tense, Part I"),
        .init(number: 190, text: "Hear all, trust nothing.", source: "DS9: Call to Arms"),
        .init(number: 211, text: "Employees are the rungs on the ladder of success. Don't hesitate to step on them.", source: "DS9: Bar Association"),
        .init(number: 214, text: "Never begin a business negotiation on an empty stomach.", source: "DS9: The Maquis, Part I"),
        .init(number: 229, text: "Latinum lasts longer than lust.", source: "DS9: Ferengi Love Songs"),
        .init(number: 239, text: "Never be afraid to mislabel a product.", source: "DS9: Body Parts"),
        .init(number: 285, text: "No good deed ever goes unpunished.", source: "DS9: The Collaborator")
    ]

    static let unofficialSayings: [FerengiRuleEntry] = [
        .init(text: "When no appropriate rule applies, make one up.", source: "VOY: False Profits"),
        .init(text: "Exploitation begins at home.", source: "VOY: False Profits"),
        .init(text: "Always inspect the merchandise before making a deal.", source: "DS9: The Abandoned"),
        .init(text: "Why ask, when you can take?", source: "DS9: Babel")
    ]
}

#Preview {
    NavigationStack {
        FerengiRulesView()
    }
}
