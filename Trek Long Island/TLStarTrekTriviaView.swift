// Copyright Bryan Carroll. All rights reserved.
//
//  TLStarTrekTriviaView.swift
//  Trek Long Island
//
//  Created by Bryan on 1/10/26.
//

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct TLStarTrekTriviaView: View {
    enum StartMode: Hashable {
        case normal
        case quick10
    }

    enum Phase: Hashable {
        case setup
        case playing
        case results
    }

    enum DifficultyFilter: Hashable, CaseIterable, Identifiable {
        case all
        case easy
        case medium
        case hard

        var id: String { title }

        var title: String {
            switch self {
            case .all: return "All"
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }

        var symbol: String {
            switch self {
            case .all: return "sparkles"
            case .easy: return "star"
            case .medium: return "star.leadinghalf.filled"
            case .hard: return "flame"
            }
        }

        func matches(_ q: TLTriviaQuestion) -> Bool {
            switch self {
            case .all: return true
            case .easy: return q.difficulty == .easy
            case .medium: return q.difficulty == .medium
            case .hard: return q.difficulty == .hard
            }
        }
    }

    struct DisplayChoice: Identifiable, Hashable {
        let id: Int
        let originalIndex: Int
        let text: String
    }

    struct MissedAnswer: Identifiable, Hashable {
        let id: Int
        let question: TLTriviaQuestion
        let selectedIndex: Int?
    }

    let startMode: StartMode

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var phase: Phase = .setup
    @State private var selectedCategory: String = "All"
    @State private var difficulty: DifficultyFilter = .all
    @State private var questionCount: Int = 25
    @State private var shuffleChoices: Bool = true
    @State private var autoShowExplanation: Bool = true

    @State private var quiz: [TLTriviaQuestion] = []
    @State private var index: Int = 0
    @State private var score: Int = 0

    @State private var displayedChoices: [DisplayChoice] = []
    @State private var selectedOriginalIndex: Int? = nil
    @State private var revealed = false

    @State private var missed: [MissedAnswer] = []
    @State private var showMissed = true

    init(startMode: StartMode = .normal) {
        self.startMode = startMode
    }

    private var categories: [String] {
        let cats = Set(TLStarTrekTriviaBank.allQuestions.map(\.category))
        return ["All"] + cats.sorted()
    }

    private var currentQuestion: TLTriviaQuestion? {
        guard quiz.indices.contains(index) else { return nil }
        return quiz[index]
    }

    private var progressText: String {
        "Question \(min(index + 1, max(quiz.count, 1))) of \(max(quiz.count, 0))"
    }

    private var canProceed: Bool { revealed }

    private var percentScore: Int {
        guard !quiz.isEmpty else { return 0 }
        let value = (Double(score) / Double(quiz.count)) * 100
        return Int(value.rounded())
    }

    private var filteredQuestionCount: Int {
        TLStarTrekTriviaBank.allQuestions.filter { question in
            (selectedCategory == "All" || question.category.caseInsensitiveCompare(selectedCategory) == .orderedSame)
            && difficulty.matches(question)
        }.count
    }

    private var streakEstimate: Int {
        max(score - missed.count, 0)
    }

    var body: some View {
        Group {
            switch phase {
            case .setup:
                setupView
            case .playing:
                playingView
            case .results:
                resultsView
            }
        }
        .navigationTitle("Star Trek Trivia")
        .navigationBarTitleDisplayMode(.inline)
        .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
        .toolbar {
            switch phase {
            case .setup:
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        applyQuickDefaults()
                        startGame()
                    } label: {
                        Label("Quick 10", systemImage: "bolt.circle")
                    }
                    .accessibilityInputLabels(["Quick 10", "Start quick trivia"])
                }
            case .playing:
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        resetToSetup()
                    } label: {
                        Label("Quit", systemImage: "xmark.circle")
                    }
                }
            case .results:
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        resetToSetup()
                    } label: {
                        Label("New Round", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .tint(TLITheme.accent(scheme))
        .onAppear {
            if startMode == .quick10 && phase == .setup {
                applyQuickDefaults()
                startGame()
            }
        }
        .onChange(of: index) { _, _ in
            prepareChoicesForCurrentQuestion()
        }
        .onChange(of: quiz) { _, _ in
            prepareChoicesForCurrentQuestion()
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 16) {
                triviaHeroCard
                presetRow
                setupStatsCard
                setupControlsCard
                startButtonCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var triviaHeroCard: some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Federation Knowledge Trial")
                            .font(.title2.bold())
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text("Test your Star Trek memory across crews, captains, aliens, science, and deep-cut canon.")
                            .font(.subheadline)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(TLITheme.accent(scheme))
                        .padding(12)
                        .background(TLITheme.accentSoft(scheme), in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)
                }

                HStack(spacing: 10) {
                    infoPill("Bank", value: "\(TLStarTrekTriviaBank.allQuestions.count)")
                    infoPill("Pool", value: "\(filteredQuestionCount)")
                    infoPill("Mode", value: startMode == .quick10 ? "Quick" : "Custom")
                }
            }
        }
    }

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                presetButton(
                    title: "Quick 10",
                    subtitle: "Fast mixed round",
                    systemImage: "bolt.fill"
                ) {
                    applyQuickDefaults()
                }

                presetButton(
                    title: "Bridge Crew",
                    subtitle: "Captains and crews",
                    systemImage: "person.3.fill"
                ) {
                    selectedCategory = categories.first(where: { $0.localizedCaseInsensitiveContains("Characters") }) ?? "All"
                    difficulty = .all
                    questionCount = 25
                }

                presetButton(
                    title: "Deep Cut",
                    subtitle: "Harder challenge",
                    systemImage: "flame.fill"
                ) {
                    selectedCategory = "All"
                    difficulty = .hard
                    questionCount = 25
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private var setupStatsCard: some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Current Configuration")
                    .font(.headline.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    setupMetric(title: "Category", value: selectedCategory == "All" ? "Mixed" : selectedCategory)
                    setupMetric(title: "Difficulty", value: difficulty.title)
                    setupMetric(title: "Questions", value: "\(min(questionCount, max(filteredQuestionCount, 1)))")
                    setupMetric(title: "Explanations", value: autoShowExplanation ? "On" : "Off")
                }
            }
        }
    }

    private var setupControlsCard: some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quiz Builder")
                    .font(.headline.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.subheadline.bold())
                        .foregroundStyle(TLITheme.textSecondary(scheme))

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Difficulty")
                        .font(.subheadline.bold())
                        .foregroundStyle(TLITheme.textSecondary(scheme))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        ForEach(DifficultyFilter.allCases) { level in
                            Button {
                                difficulty = level
                            } label: {
                                Label(level.title, systemImage: level.symbol)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(difficulty == level ? TLITheme.accent(scheme) : TLITheme.cardBackground(scheme))
                            .foregroundStyle(difficulty == level ? Color.black : TLITheme.textPrimary(scheme))
                        }
                    }
                }

                LabeledContent("Questions") {
                    Picker("Questions", selection: $questionCount) {
                        Text("10").tag(10)
                        Text("25").tag(25)
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .pickerStyle(.segmented)
                }
                .foregroundStyle(TLITheme.textPrimary(scheme))

                toggleRow(
                    title: "Shuffle choices",
                    subtitle: "Mix answer order for each question",
                    isOn: $shuffleChoices
                )

                toggleRow(
                    title: "Show explanation after answer",
                    subtitle: "Reveal extra canon context automatically",
                    isOn: $autoShowExplanation
                )
            }
        }
    }

    private var startButtonCard: some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Launch Round")
                    .font(.headline.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("You’ll answer once per question, then review the canon explanation before moving forward.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                Button {
                    startGame()
                } label: {
                    Label("Start Trivia", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(TLITheme.accent(scheme))
                .accessibilityInputLabels(["Start trivia", "Begin quiz"])
            }
        }
    }

    private func applyQuickDefaults() {
        selectedCategory = "All"
        difficulty = .all
        questionCount = 10
        shuffleChoices = true
        autoShowExplanation = true
    }

    private var playingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                topStatusCard

                if let question = currentQuestion {
                    questionCard(question)

                    VStack(spacing: 10) {
                        ForEach(displayedChoices) { choice in
                            choiceRow(choice: choice, question: question)
                        }
                    }

                    if revealed, autoShowExplanation {
                        explanationCard(for: question)
                    }

                    bottomBar
                } else {
                    ContentUnavailableView(
                        "No Questions",
                        systemImage: "questionmark.circle",
                        description: Text("Try starting a new quiz.")
                    )
                    .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .snappy(duration: 0.25), value: revealed)
    }

    private var topStatusCard: some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(progressText)
                                .font(.subheadline)
                                .foregroundStyle(TLITheme.textSecondary(scheme))

                            Text("Score \(score)")
                                .font(.title3.bold())
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 8) {
                            infoPill("Correct", value: "\(score)")
                            infoPill("Missed", value: "\(missed.count)")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(progressText)
                            .font(.subheadline)
                            .foregroundStyle(TLITheme.textSecondary(scheme))
                        HStack(spacing: 8) {
                            infoPill("Correct", value: "\(score)")
                            infoPill("Missed", value: "\(missed.count)")
                        }
                    }
                }

                ProgressView(
                    value: quiz.isEmpty ? 0 : Double(index + 1),
                    total: Double(max(quiz.count, 1))
                )
                .tint(TLITheme.accent(scheme))
            }
        }
    }

    private func questionCard(_ question: TLTriviaQuestion) -> some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    pill(question.category, color: TLITheme.accentSoft(scheme), foreground: TLITheme.textPrimary(scheme))
                    pill(question.difficulty.rawValue.uppercased(), color: difficultyColor(question.difficulty).opacity(0.18), foreground: difficultyColor(question.difficulty))
                    Spacer(minLength: 0)
                }

                Text(question.prompt)
                    .font(.title3.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("Select the strongest match from the options below.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
        }
    }

    private func choiceRow(choice: DisplayChoice, question: TLTriviaQuestion) -> some View {
        let state = choiceState(for: choice, question: question)

        return Button {
            choose(originalIndex: choice.originalIndex, question: question)
        } label: {
            HStack(spacing: 12) {
                Text(choiceLetter(for: choice))
                    .font(.subheadline.bold())
                    .foregroundStyle(state.badgeForeground)
                    .frame(width: 32, height: 32)
                    .background(state.badgeBackground, in: Circle())

                Text(choice.text)
                    .font(.body.bold())
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let icon = state.icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(state.iconColor)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(state.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(state.border, lineWidth: state.borderWidth)
            )
        }
        .buttonStyle(.plain)
        .disabled(revealed)
        .accessibilityLabel("Answer \(choiceLetter(for: choice)), \(choice.text)")
        .accessibilityHint(revealed ? "Answer locked" : "Select this answer")
    }

    private func explanationCard(for question: TLTriviaQuestion) -> some View {
        TriviaPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Correct Answer: \(question.answer)", systemImage: "checkmark.seal.fill")
                    .font(.headline.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                if let explanation = question.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var bottomBar: some View {
        TriviaPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    bottomSecondaryButtons
                    Spacer(minLength: 0)
                    nextButton
                }

                VStack(spacing: 12) {
                    nextButton
                    bottomSecondaryButtons
                }
            }
        }
    }

    private var bottomSecondaryButtons: some View {
        HStack(spacing: 10) {
            Button {
                resetToSetup()
            } label: {
                Label("Quit", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)

            if !revealed {
                Button {
                    revealWithoutAnswer()
                } label: {
                    Label("Reveal", systemImage: "eye")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var nextButton: some View {
        Button {
            next()
        } label: {
            Label(index + 1 >= quiz.count ? "Finish Round" : "Next Question", systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(TLITheme.accent(scheme))
        .disabled(!canProceed)
        .accessibilityInputLabels(["Next question", "Finish round"])
    }

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                resultsHeroCard
                resultsActionsCard

                if missed.isEmpty {
                    TriviaPanel {
                        ContentUnavailableView(
                            "Perfect Score!",
                            systemImage: "checkmark.seal.fill",
                            description: Text("You didn’t miss any questions this round.")
                        )
                        .foregroundStyle(TLITheme.textPrimary(scheme))
                    }
                } else {
                    TriviaPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Show missed questions", isOn: $showMissed)
                                .font(.headline.bold())
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                                .tint(TLITheme.accent(scheme))

                            if showMissed {
                                VStack(spacing: 12) {
                                    ForEach(missed) { item in
                                        missedCard(item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var resultsHeroCard: some View {
        TriviaPanel {
            VStack(spacing: 14) {
                Image(systemName: percentScore >= 80 ? "sparkles" : "shield.lefthalf.filled")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(TLITheme.accent(scheme))
                    .accessibilityHidden(true)

                Text("Round Complete")
                    .font(.title2.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("\(score) / \(quiz.count)")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("\(percentScore)% accuracy")
                    .font(.headline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    setupMetric(title: "Correct", value: "\(score)")
                    setupMetric(title: "Missed", value: "\(missed.count)")
                    setupMetric(title: "Streak", value: "\(streakEstimate)")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resultsActionsCard: some View {
        TriviaPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Button {
                        startGame()
                    } label: {
                        Label("Play Again", systemImage: "repeat")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TLITheme.accent(scheme))

                    Button {
                        resetToSetup()
                    } label: {
                        Label("Change Settings", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                VStack(spacing: 12) {
                    Button {
                        startGame()
                    } label: {
                        Label("Play Again", systemImage: "repeat")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TLITheme.accent(scheme))

                    Button {
                        resetToSetup()
                    } label: {
                        Label("Change Settings", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func missedCard(_ item: MissedAnswer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                pill(item.question.category, color: TLITheme.cardBackground(scheme), foreground: TLITheme.textPrimary(scheme))
                pill(item.question.difficulty.rawValue.uppercased(), color: difficultyColor(item.question.difficulty).opacity(0.18), foreground: difficultyColor(item.question.difficulty))
                Spacer(minLength: 0)
            }

            Text(item.question.prompt)
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if let selected = item.selectedIndex, item.question.choices.indices.contains(selected) {
                Text("You chose: \(item.question.choices[selected])")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            } else {
                Text("You revealed the answer.")
                    .font(.subheadline)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }

            Text("Correct: \(item.question.answer)")
                .font(.subheadline.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))

            if let explanation = item.question.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func startGame() {
        let base = TLStarTrekTriviaBank.allQuestions
        var filtered = base

        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category.caseInsensitiveCompare(selectedCategory) == .orderedSame }
        }

        filtered = filtered.filter { difficulty.matches($0) }

        if filtered.isEmpty {
            filtered = base
        }

        let count = max(1, min(questionCount, filtered.count))
        quiz = Array(filtered.shuffled().prefix(count))

        index = 0
        score = 0
        missed = []
        selectedOriginalIndex = nil
        revealed = false
        phase = .playing

        prepareChoicesForCurrentQuestion()
    }

    private func prepareChoicesForCurrentQuestion() {
        guard let question = currentQuestion else {
            displayedChoices = []
            return
        }

        let mapped = question.choices.enumerated().map { idx, text in
            DisplayChoice(id: idx, originalIndex: idx, text: text)
        }

        displayedChoices = shuffleChoices ? mapped.shuffled() : mapped
    }

    private func choose(originalIndex: Int, question: TLTriviaQuestion) {
        guard !revealed else { return }

        selectedOriginalIndex = originalIndex
        revealed = true

        if originalIndex == question.answerIndex {
            score += 1
            haptic(.success)
        } else {
            missed.append(.init(id: question.id, question: question, selectedIndex: originalIndex))
            haptic(.error)
        }
    }

    private func revealWithoutAnswer() {
        guard !revealed else { return }
        guard let question = currentQuestion else { return }

        selectedOriginalIndex = nil
        revealed = true
        missed.append(.init(id: question.id, question: question, selectedIndex: nil))
        haptic(.warning)
    }

    private func next() {
        guard revealed else { return }

        if index + 1 >= quiz.count {
            phase = .results
        } else {
            index += 1
            selectedOriginalIndex = nil
            revealed = false
            prepareChoicesForCurrentQuestion()
        }
    }

    private func resetToSetup() {
        quiz = []
        index = 0
        score = 0
        displayedChoices = []
        selectedOriginalIndex = nil
        revealed = false
        missed = []
        phase = .setup
    }

    private func choiceLetter(for choice: DisplayChoice) -> String {
        let offset = displayedChoices.firstIndex(of: choice) ?? 0
        let base = UnicodeScalar(65 + offset) ?? UnicodeScalar(65)!
        return String(Character(base))
    }

    private func difficultyColor(_ difficulty: TLTriviaQuestion.Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return Color.green
        case .medium:
            return RisaTheme.accentGold(scheme)
        case .hard:
            return Color.red
        }
    }

    private func choiceState(for choice: DisplayChoice, question: TLTriviaQuestion) -> TriviaChoiceVisualState {
        if !revealed {
            return .idle(scheme: scheme)
        }

        if choice.originalIndex == question.answerIndex {
            return .correct(scheme: scheme, differentiate: differentiateWithoutColor)
        }

        if selectedOriginalIndex == choice.originalIndex {
            return .incorrect(scheme: scheme, differentiate: differentiateWithoutColor)
        }

        return .inactive(scheme: scheme)
    }

    private func pill(_ text: String, color: Color, foreground: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func infoPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(TLITheme.textTertiary(scheme))
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLITheme.cardBackground(scheme), in: Capsule())
        .overlay(
            Capsule()
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func setupMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(TLITheme.textTertiary(scheme))
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(TLITheme.border(scheme), lineWidth: 1)
        )
    }

    private func presetButton(title: String, subtitle: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            .padding(14)
            .frame(width: 180, alignment: .leading)
            .background(TLITheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
        }
        .tint(TLITheme.accent(scheme))
    }

    private enum TLHaptic {
        case success
        case warning
        case error
    }

    private func haptic(_ kind: TLHaptic) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        switch kind {
        case .success:
            generator.notificationOccurred(.success)
        case .warning:
            generator.notificationOccurred(.warning)
        case .error:
            generator.notificationOccurred(.error)
        }
        #endif
    }
}

private struct TriviaPanel<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                TLITheme.cardBackground(scheme),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(TLITheme.border(scheme), lineWidth: 1)
            )
            .shadow(color: TLITheme.cardShadowColor(scheme).opacity(0.6), radius: 10, y: 6)
    }
}

private struct TriviaChoiceVisualState {
    let background: Color
    let border: Color
    let borderWidth: CGFloat
    let badgeBackground: Color
    let badgeForeground: Color
    let icon: String?
    let iconColor: Color

    static func idle(scheme: ColorScheme) -> TriviaChoiceVisualState {
        TriviaChoiceVisualState(
            background: TLITheme.cardBackground(scheme),
            border: TLITheme.border(scheme),
            borderWidth: 1,
            badgeBackground: TLITheme.accentSoft(scheme),
            badgeForeground: TLITheme.textPrimary(scheme),
            icon: nil,
            iconColor: TLITheme.textPrimary(scheme)
        )
    }

    static func correct(scheme: ColorScheme, differentiate: Bool) -> TriviaChoiceVisualState {
        TriviaChoiceVisualState(
            background: Color.green.opacity(scheme == .dark ? 0.22 : 0.16),
            border: differentiate ? TLITheme.accent(scheme) : Color.green.opacity(0.9),
            borderWidth: 2,
            badgeBackground: Color.green,
            badgeForeground: .black,
            icon: differentiate ? "checkmark.seal.fill" : "checkmark.circle.fill",
            iconColor: Color.green
        )
    }

    static func incorrect(scheme: ColorScheme, differentiate: Bool) -> TriviaChoiceVisualState {
        TriviaChoiceVisualState(
            background: Color.red.opacity(scheme == .dark ? 0.20 : 0.14),
            border: differentiate ? RisaTheme.accentGold(scheme) : Color.red.opacity(0.9),
            borderWidth: 2,
            badgeBackground: Color.red,
            badgeForeground: .white,
            icon: differentiate ? "exclamationmark.triangle.fill" : "xmark.circle.fill",
            iconColor: Color.red
        )
    }

    static func inactive(scheme: ColorScheme) -> TriviaChoiceVisualState {
        TriviaChoiceVisualState(
            background: TLITheme.cardBackground(scheme),
            border: TLITheme.border(scheme).opacity(0.75),
            borderWidth: 1,
            badgeBackground: TLITheme.cardBackground(scheme),
            badgeForeground: TLITheme.textSecondary(scheme),
            icon: nil,
            iconColor: TLITheme.textSecondary(scheme)
        )
    }
}

#Preview {
    NavigationStack {
        TLStarTrekTriviaView()
    }
}
