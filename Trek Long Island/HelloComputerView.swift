// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerView.swift
//  Trek Long Island
//
//  “Hello, Computer”
//  - No quick questions chips
//  - Scotty prompt + subtle Easter egg link
//  - Normalizes FAQ text so "\n" renders as real line breaks
//  - Auto-scrolls to newest answer
//  - Opens links externally
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Foundation
import AVFoundation
import Speech
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct HelloComputerView: View {

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var store: HelloComputerStore

    @FocusState private var inputFocused: Bool
    @StateObject private var voiceInput = HelloComputerVoiceInputController()
    @State private var showsExpandedShortcuts = false
    @State private var topBarActivatedAt = Date()
    @AppStorage("TLI.EasterEggs.scottyVideo") private var foundScottyVideo = false
    @AppStorage("TLI.EasterEggs.facebookReel") private var foundFacebookReel = false
    private let sfx = ZenSFX.shared

    private let bottomAnchorID = "helloComputerBottomAnchor"

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            VStack(spacing: 12) {

                // Slightly slimmer LCARS chrome
                LCARSTopBar(
                    scheme: scheme,
                    isActive: store.isThinking || voiceInput.isRecording || inputFocused,
                    activatedAt: topBarActivatedAt
                )

                // One unified “prompt” card (Scotty + what this is)
                promptCard

                // Conversation
                conversationCard
                    .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 14)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(.clear)
        }
        .navigationTitle("Hello, Computer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(inputFocused ? .hidden : .visible, for: .tabBar)
        .alert("Voice Input", isPresented: Binding(
            get: { voiceInput.errorMessage != nil },
            set: { if !$0 { voiceInput.errorMessage = nil } }
        ), actions: {
            Button("OK") {
                voiceInput.errorMessage = nil
            }
        }, message: {
            Text(voiceInput.errorMessage ?? "")
        })
        .sheet(item: $store.pendingAction) { action in
            PendingActionSheet(
                action: action,
                scheme: scheme,
                onApprove: { store.approvePendingAction() },
                onCancel: { store.cancelPendingAction() }
            )
        }
        .onChange(of: store.isThinking) { _, isThinking in
            guard isThinking else { return }
            topBarActivatedAt = .now
        }
        .onAppear {
            voiceInput.onHandsFreeSubmit = { text in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.inputText = trimmed
                send()
            }
        }
        .onDisappear {
            voiceInput.onHandsFreeSubmit = nil
        }
    }

    // MARK: - Unified Prompt

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topLeading) {
                if usesCompactPromptCard {
                    compactPromptSummary
                        .id("compactPromptSummary")
                        .transition(.opacity)
                } else {
                    expandedPromptSummary
                        .id("expandedPromptSummary")
                        .transition(.opacity)
                }
            }

            HelloComputerHandsFreeToggle(voiceInput: voiceInput)

        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 18,
            emphasis: showsExpandedShortcuts || store.isThinking || voiceInput.isRecording
        )
        .animation(.easeOut(duration: 0.18), value: showsExpandedShortcuts)
        .animation(nil, value: usesCompactPromptCard)
        .contentTransition(.identity)
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    private var expandedPromptSummary: some View {
        VStack(alignment: .leading, spacing: 9) {
            headerChrome

            Text("Computer core online.")
                .font(.headline)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Computer core online.")

            Text(store.persona == .scotty ? "Scotty persona is active. Ask for a live briefing, day plan, reminders, or help keeping your convention engines running." : "Ask for a live briefing, plan your day, or get venue and guest help without bouncing between tabs.")
                .font(.subheadline)
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            personaPicker

            QuickCommandDeck(
                scheme: scheme,
                prompts: priorityPrompts,
                onAskNow: { prompt in
                    sendShortcut(prompt, submitImmediately: true)
                }
            )

            if let lastSource = store.lastSource {
                sourceAndResetRow(lastSource: lastSource)
            }

            Label("Auto-routing enabled. Questions choose the right computer mode automatically.", systemImage: "wand.and.stars")
                .font(.footnote)
                .foregroundStyle(TLITheme.textTertiary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            shortcutDisclosure

            utilityLinksRow
        }
    }

    private var compactPromptSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.persona == .scotty ? "Hello, Scotty" : "Hello, Computer")
                        .font(.headline)
                        .foregroundStyle(TLITheme.textPrimary(scheme))

                    Text(store.persona == .scotty ? "Engineering tone active for your next command." : "Ask a follow-up or fire off another fast command.")
                        .font(.footnote)
                        .foregroundStyle(TLITheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let lastSource = store.lastSource {
                    Label(sourceLabel(for: lastSource), systemImage: sourceSystemImage(for: lastSource))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.accent(scheme))
                }
            }

            CompactPromptRail(
                scheme: scheme,
                prompts: compactPrompts,
                onAskNow: { prompt in
                    sendShortcut(prompt, submitImmediately: true)
                }
            )

            personaPicker

            HStack(spacing: 12) {
                Button(showsExpandedShortcuts ? "Hide shortcut library" : "More shortcuts") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsExpandedShortcuts.toggle()
                    }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TLITheme.accent(scheme))
                .buttonStyle(
                    LCARSInteractiveButtonStyle(
                        accent: TLITheme.accent(scheme),
                        cornerRadius: 12,
                        idleEmphasis: showsExpandedShortcuts,
                        pressedScale: 0.985
                    )
                )

                Button("Clear Log") {
                    store.resetConversation()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .buttonStyle(
                    LCARSInteractiveButtonStyle(
                        accent: TLITheme.textTertiary(scheme),
                        cornerRadius: 12,
                        idleEmphasis: false,
                        pressedScale: 0.985
                    )
                )

                Spacer(minLength: 0)

                NavigationLink {
                    MemoryAlphaSearchView()
                } label: {
                    Image(systemName: "books.vertical")
                        .font(.body.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(TLITheme.cardBackground(scheme).opacity(0.24))
                        )
                }
                .foregroundStyle(TLITheme.accent(scheme))
                .buttonStyle(
                    LCARSInteractiveButtonStyle(
                        accent: TLITheme.accent(scheme),
                        cornerRadius: 12,
                        idleEmphasis: false,
                        pressedScale: 0.97
                    )
                )
                .accessibilityLabel("Open Memory Alpha search")
            }

            if showsExpandedShortcuts {
                InformationDeskShortcutPanel(
                    scheme: scheme,
                    sections: shortcutSections,
                    onAskNow: { prompt in
                        sendShortcut(prompt, submitImmediately: true)
                    },
                    onFillInput: { prompt in
                        sendShortcut(prompt, submitImmediately: false)
                    }
                )
                .padding(.top, 4)
            }
        }
    }

    private var headerChrome: some View {
        HStack(spacing: 8) {
            TLITheme.controlShape(cornerRadius: 10)
                .fill(TLITheme.accent(scheme))
                .frame(width: 34, height: 10)
            TLITheme.controlShape(cornerRadius: 10)
                .fill(TLITheme.chipBackground(scheme))
                .frame(width: 20, height: 10)
            Text(promptHeaderTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
            Spacer(minLength: 8)
        }
    }

    private var personaPicker: some View {
        Picker("Assistant persona", selection: Binding(
            get: { store.persona },
            set: { store.setPersona($0) }
        )) {
            ForEach(HelloComputerPersona.allCases, id: \.self) { persona in
                Label(persona.title, systemImage: persona.systemImage)
                    .tag(persona)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Assistant persona")
    }

    private func sourceAndResetRow(lastSource: HelloComputerAnswerSource) -> some View {
        HStack(spacing: 8) {
            Label(sourceLabel(for: lastSource), systemImage: sourceSystemImage(for: lastSource))
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.accent(scheme))

            Spacer(minLength: 8)

            if hasConversation {
                Button("Clear Log") {
                    store.resetConversation()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLITheme.textSecondary(scheme))
                .buttonStyle(
                    LCARSInteractiveButtonStyle(
                        accent: TLITheme.textTertiary(scheme),
                        cornerRadius: 10,
                        idleEmphasis: false,
                        pressedScale: 0.985
                    )
                )
                .accessibilityHint("Clears the current Hello, Computer conversation.")
            }
        }
    }

    private var shortcutDisclosure: some View {
        DisclosureGroup(isExpanded: $showsExpandedShortcuts) {
            VStack(alignment: .leading, spacing: 12) {
                Text("More mission shortcuts")
                    .font(.footnote)
                    .foregroundStyle(TLITheme.textSecondary(scheme))

                InformationDeskShortcutPanel(
                    scheme: scheme,
                    sections: shortcutSections,
                    onAskNow: { prompt in
                        sendShortcut(prompt, submitImmediately: true)
                    },
                    onFillInput: { prompt in
                        sendShortcut(prompt, submitImmediately: false)
                    }
                )
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showsExpandedShortcuts ? "rectangle.compress.vertical" : "square.grid.2x2")
                    .foregroundStyle(TLITheme.accent(scheme))
                Text(showsExpandedShortcuts ? "Hide shortcut library" : "Browse all shortcut missions")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TLITheme.textPrimary(scheme))
                Spacer(minLength: 8)
            }
            .contentShape(Rectangle())
        }
        .tint(TLITheme.textPrimary(scheme))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 14,
            emphasis: showsExpandedShortcuts,
            idleSweepDuration: 2.6
        )
    }

    private var utilityLinksRow: some View {
        HStack(spacing: 10) {
            Label("No prompts are preserved.", systemImage: "checkmark.seal")
                .font(.footnote)
                .foregroundStyle(TLITheme.textTertiary(scheme))

            Spacer(minLength: 12)

            NavigationLink {
                MemoryAlphaSearchView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical")
                    Text("Memory Alpha")
                }
                .font(.caption.weight(.semibold))
            }
            .foregroundStyle(TLITheme.accent(scheme))
            .buttonStyle(
                LCARSInteractiveButtonStyle(
                    accent: TLITheme.accent(scheme),
                    cornerRadius: 12,
                    idleEmphasis: false,
                    pressedScale: 0.985
                )
            )
            .accessibilityLabel("Open Memory Alpha search")

            Button {
                if let url = URL(string: "https://www.youtube.com/watch?v=hShY6xZWVGE") {
                    foundScottyVideo = true
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles.tv")
                    Text("Easter egg")
                }
                .font(.caption.weight(.semibold))
            }
            .foregroundStyle(TLITheme.accent(scheme))
            .buttonStyle(
                LCARSInteractiveButtonStyle(
                    accent: TLITheme.accent(scheme),
                    cornerRadius: 12,
                    idleEmphasis: false,
                    pressedScale: 0.985
                )
            )
            .accessibilityLabel("Open Scotty easter egg video")

            Button {
                if let url = URL(string: "https://www.facebook.com/reel/1980360026020488") {
                    foundFacebookReel = true
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.tv")
                    Text("Reel")
                }
                .font(.caption.weight(.semibold))
            }
            .foregroundStyle(TLITheme.accent(scheme))
            .buttonStyle(
                LCARSInteractiveButtonStyle(
                    accent: TLITheme.accent(scheme),
                    cornerRadius: 12,
                    idleEmphasis: false,
                    pressedScale: 0.985
                )
            )
            .accessibilityLabel("Open hidden Facebook reel")
        }
    }

    // MARK: - Conversation

    private var conversationCard: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        if !hasConversation {
                            EmptyStateBubble(
                                scheme: scheme,
                                suggestions: suggestionsForCurrentMode(),
                                onTapSuggestion: { suggestion in
                                    store.inputText = suggestion
                                    inputFocused = true
                                }
                            )
                            .padding(.top, 2)
                        }

                        ForEach(store.messages) { msg in
                            MessageBubble(
                                message: msg,
                                scheme: scheme,
                                normalize: normalized,
                                reduceMotion: reduceMotion,
                                isNewestAssistant: msg.id == store.messages.last(where: { $0.role == .assistant })?.id,
                                onOpenURL: { url in openURL(url) }
                            )
                        }

                        if store.isThinking {
                            ThinkingBubble(scheme: scheme)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorID)
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        dismissKeyboard()
                    }
                )
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                    }
                }
                .onChange(of: store.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.35)) {
                        proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                    }
                }
                .onChange(of: voiceInput.transcript) { _, newValue in
                    if !newValue.isEmpty {
                        store.inputText = newValue
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 20,
            emphasis: store.isThinking,
            idleSweepDuration: store.isThinking ? 1.8 : 3.8
        )
    }

    // MARK: - Input

    private var inputBar: some View {
        ViewThatFits(in: .horizontal) {
            compactInputRow
            stackedInputRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 16,
            emphasis: inputFocused || voiceInput.isRecording || canSend,
            idleSweepDuration: voiceInput.isRecording ? 1.5 : 2.4
        )
    }

    private var compactInputRow: some View {
        HStack(spacing: 10) {
            inputField
            micButton(buttonSize: 46)
            sendButton(buttonSize: 46)
        }
    }

    private var stackedInputRow: some View {
        VStack(spacing: 10) {
            inputField
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                micButton(buttonSize: 42)
                sendButton(buttonSize: 42)
            }
        }
    }

    private var promptHeaderTitle: String {
        switch RisaTheme.currentTheme {
        case .tos: "BRIDGE BRIEFING"
        case .tng: "OPS BRIEFING"
        case .ds9: "PROMENADE BRIEFING"
        case .voyager: "ASTROMETRICS BRIEFING"
        case .enterprise: "NX OPS BRIEFING"
        case .starfleet: "STARFLEET BRIEFING"
        case .lcars: "LCARS BRIEFING"
        case .risa: "RISA CONCIERGE"
        }
    }

    private var inputField: some View {
        TextField("Ask the computer…", text: $store.inputText, axis: .vertical)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)
            .lineLimit(1...4)
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .focused($inputFocused)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TLITheme.cardBackground(scheme))
                    .opacity(0.32)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(inputFocused ? TLITheme.accent(scheme) : TLITheme.border(scheme),
                            lineWidth: inputFocused ? 1.5 : 1)
            )
            .foregroundStyle(TLITheme.textPrimary(scheme))
            .submitLabel(.send)
            .onSubmit { send() }
            .accessibilityLabel("Ask the computer")
    }

    private func micButton(buttonSize: CGFloat) -> some View {
        Button {
            toggleVoiceInput()
        } label: {
            Image(systemName: voiceInput.isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(voiceInput.isRecording ? Color.black : TLITheme.textPrimary(scheme))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(voiceInput.isRecording ? Color.red.opacity(0.85) : TLITheme.cardBackground(scheme).opacity(0.20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                )
        }
        .buttonStyle(
            LCARSInteractiveButtonStyle(
                accent: voiceInput.isRecording ? .red : TLITheme.accent(scheme),
                cornerRadius: 14,
                idleEmphasis: voiceInput.isRecording,
                pressedScale: 0.96
            )
        )
        .disabled(store.isThinking)
        .accessibilityLabel(voiceInput.isRecording ? "Stop voice input" : "Start voice input")
        .accessibilityInputLabels([voiceInput.isRecording ? "Stop voice input" : "Start voice input", "Microphone", "Mic"])
        .accessibilityHint(voiceInput.isRecording ? "Stops listening and keeps your captured text." : "Starts listening for a spoken request.")
    }

    private func sendButton(buttonSize: CGFloat) -> some View {
        Button(action: send) {
            Image(systemName: store.isThinking ? "hourglass" : "paperplane.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(canSend ? Color.black : TLITheme.textTertiary(scheme))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canSend ? TLITheme.accent(scheme) : TLITheme.cardBackground(scheme).opacity(0.20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                )
        }
        .buttonStyle(
            LCARSInteractiveButtonStyle(
                accent: canSend ? TLITheme.accent(scheme) : TLITheme.textTertiary(scheme),
                cornerRadius: 14,
                idleEmphasis: canSend,
                pressedScale: 0.96
            )
        )
        .disabled(!canSend)
        .accessibilityLabel("Send")
        .accessibilityInputLabels(["Send", "Send message", "Ask the computer"])
        .accessibilityHint(store.isThinking ? "Wait for the computer to finish responding." : "Sends your current request to Hello, Computer.")
    }

    private var canSend: Bool {
        !store.isThinking && !voiceInput.isRecording &&
        !store.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        if voiceInput.isRecording {
            voiceInput.stopRecording()
        }
        let text = store.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        playCommandAcceptedFeedback()
        store.send(text)
        inputFocused = false
    }

    private func toggleVoiceInput() {
        if voiceInput.isRecording {
            voiceInput.stopRecording()
            playSoftTapFeedback()
        } else {
            inputFocused = false
            voiceInput.startRecording(seedText: store.inputText)
            playSoftTapFeedback()
        }
    }

    private func dismissKeyboard() {
        inputFocused = false
    }

    // MARK: - Normalization (fixes literal "\n" artifacts from FAQ bank)

    private func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func suggestionsForCurrentMode() -> [String] {
        var merged = HelloComputerMissionRouter.suggestedQuestions(for: store.audience)
        merged.append(contentsOf: HelloComputerFAQBank.allSuggestedQuestions)
        merged.append(contentsOf: [
            "Brief me",
            "Happening now",
            "What's next?",
            "What should I do next?",
            "Build my day",
            "Find DS9 panels",
            "Show conflicts",
            "Star the next event",
            "Remind me 15 min before next event"
        ])
        var seen = Set<String>()
        return merged.filter { seen.insert($0.lowercased()).inserted }.prefix(8).map { $0 }
    }

    private var hasConversation: Bool {
        store.messages.contains { $0.role == .user }
    }

    private var usesCompactPromptCard: Bool {
        hasConversation || store.isThinking
    }

    private var priorityPrompts: [String] {
        [
            "Brief me",
            "What should I do next?",
            "What's next?",
            "Build my day",
            "Where is the venue?"
        ]
    }

    private var compactPrompts: [String] {
        [
            "What should I do next?",
            "What's next?",
            "Show conflicts",
            "Where is the venue?"
        ]
    }

    private var shortcutSections: [DeskShortcutSection] {
        [
            DeskShortcutSection(
                title: "Bridge Briefing",
                prompts: [
                    "Brief me",
                    "Happening now",
                    "What should I do next?",
                    "What's next?",
                    "Show conflicts"
                ]
            ),
            DeskShortcutSection(
                title: "Mission Planning",
                prompts: [
                    "Build my day",
                    "Help me choose between panels",
                    "What should I do first when I arrive?",
                    "I have 30 minutes free, what should I do?"
                ]
            ),
            DeskShortcutSection(
                title: "Information Desk",
                prompts: [
                    "What are the convention dates and hours?",
                    "Where is the venue?",
                    "How do photo ops work?",
                    "What accessibility options are available?"
                ]
            ),
            DeskShortcutSection(
                title: "Guest & Fandom Intel",
                prompts: [
                    "Find DS9 panels",
                    "Which guests are here for Strange New Worlds?",
                    "Show me autograph help",
                    "Open Memory Alpha"
                ]
            )
        ]
    }

    private func sendShortcut(_ prompt: String, submitImmediately: Bool) {
        store.inputText = prompt
        if submitImmediately {
            send()
        } else {
            inputFocused = true
        }
    }

    private func sourceLabel(for source: HelloComputerAnswerSource) -> String {
        switch source {
        case .officialFAQ:
            return "Official convention info"
        case .generalGuidance:
            return "Desk guidance"
        case .aiAssist:
            return "Schedule assistant"
        }
    }

    private func sourceSystemImage(for source: HelloComputerAnswerSource) -> String {
        switch source {
        case .officialFAQ:
            return "checkmark.seal"
        case .generalGuidance:
            return "person.text.rectangle"
        case .aiAssist:
            return "calendar.badge.clock"
        }
    }

    private func playCommandAcceptedFeedback() {
        sfx.play("lcars_tap_soft", ext: "wav", volume: 0.14)
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func playSoftTapFeedback() {
        sfx.play("lcars_tap_soft", ext: "wav", volume: 0.10)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

}

private struct DeskShortcutSection: Identifiable {
    let id = UUID()
    let title: String
    let prompts: [String]
}

private struct InformationDeskShortcutPanel: View {
    let scheme: ColorScheme
    let sections: [DeskShortcutSection]
    let onAskNow: (String) -> Void
    let onFillInput: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TLITheme.textSecondary(scheme))

                    WrapChips(items: section.prompts) { prompt in
                        Menu {
                            Button("Ask Now") {
                                onAskNow(prompt)
                            }
                            Button("Add to Input") {
                                onFillInput(prompt)
                            }
                        } label: {
                            Text(prompt)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TLITheme.chipForeground(scheme))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(
                                    TLITheme.controlShape(cornerRadius: 12)
                                        .fill(TLITheme.chipBackground(scheme))
                                )
                                .overlay(
                                    TLITheme.controlShape(cornerRadius: 12)
                                        .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                                )
                                .lcarsReactiveSurface(
                                    accent: TLITheme.accent(scheme),
                                    cornerRadius: 12,
                                    emphasis: false,
                                    idleSweepDuration: 3.1
                                )
                        }
                        .accessibilityHint("Double tap to ask right away or choose to add it to the input field.")
                    }
                }
            }
        }
    }

}

private struct QuickCommandDeck: View {
    let scheme: ColorScheme
    let prompts: [String]
    let onAskNow: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start here")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onAskNow(prompt)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon(for: prompt))
                                .foregroundStyle(TLITheme.accent(scheme))
                            Text(prompt)
                                .font(.subheadline.weight(.bold))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(TLITheme.textPrimary(scheme))
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(TLITheme.cardBackground(scheme).opacity(0.28))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(
                        LCARSInteractiveButtonStyle(
                            accent: TLITheme.accent(scheme),
                            cornerRadius: 14,
                            idleEmphasis: false,
                            pressedScale: 0.98
                        )
                    )
                    .accessibilityHint("Sends this request to Hello, Computer right away.")
                }
            }
        }
    }

    private func icon(for prompt: String) -> String {
        switch prompt {
        case "Brief me":
            return "sparkles.rectangle.stack"
        case "What's next?":
            return "clock.arrow.circlepath"
        case "Build my day":
            return "calendar.badge.plus"
        case "Where is the venue?":
            return "mappin.and.ellipse"
        default:
            return "command"
        }
    }
}

private struct CompactPromptRail: View {
    let scheme: ColorScheme
    let prompts: [String]
    let onAskNow: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onAskNow(prompt)
                    } label: {
                        Text(prompt)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TLITheme.textPrimary(scheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(TLITheme.cardBackground(scheme).opacity(0.28))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                            )
                    }
                    .buttonStyle(
                        LCARSInteractiveButtonStyle(
                            accent: TLITheme.accent(scheme),
                            cornerRadius: 22,
                            idleEmphasis: false,
                            pressedScale: 0.985
                        )
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Empty State

private struct EmptyStateBubble: View {
    let scheme: ColorScheme
    let suggestions: [String]
    let onTapSuggestion: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Convention Concierge")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLITheme.textPrimary(scheme))

            Text("Use these fast prompts when you want a briefing, need help shaping your day, or want quicker answers than tab-hopping.")
                .font(.caption)
                .foregroundStyle(TLITheme.textSecondary(scheme))

            WrapChips(items: suggestions) { item in
                Button {
                    onTapSuggestion(item)
                } label: {
                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLITheme.chipForeground(scheme))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            TLITheme.controlShape(cornerRadius: 12)
                                .fill(TLITheme.chipBackground(scheme))
                        )
                        .overlay(
                            TLITheme.controlShape(cornerRadius: 12)
                                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                        )
                }
                .buttonStyle(
                    LCARSInteractiveButtonStyle(
                        accent: TLITheme.accent(scheme),
                        cornerRadius: 12,
                        idleEmphasis: false,
                        pressedScale: 0.985
                    )
                )
            }

            Text("Ticket and checkout requests route to official purchase info. Schedule and logistics requests stay inside the companion flow.")
                .font(.caption)
                .foregroundStyle(TLITheme.textTertiary(scheme))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 18,
            emphasis: false,
            idleSweepDuration: 3.6
        )
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: HelloComputerMessage
    let scheme: ColorScheme
    let normalize: (String) -> String
    let reduceMotion: Bool
    let isNewestAssistant: Bool
    let onOpenURL: (URL) -> Void
    @State private var revealedText: String = ""
    @State private var revealTask: Task<Void, Never>?

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble(alignment: .leading)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble(alignment: .trailing)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func bubble(alignment: HorizontalAlignment) -> some View {
        let cleaned = normalize(message.text)

        VStack(alignment: alignment, spacing: 10) {
            Text(revealedDisplayText(for: cleaned))
                .font(.body)
                .foregroundStyle(TLITheme.textPrimary(scheme))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            let urls = URLDetector.urls(in: cleaned)
            if !urls.isEmpty {
                VStack(alignment: alignment, spacing: 6) {
                    ForEach(urls, id: \.absoluteString) { url in
                        Button {
                            onOpenURL(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "safari")
                                Text(url.host ?? url.absoluteString)
                                    .lineLimit(1)
                            }
                            .font(.footnote.weight(.semibold))
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(TLITheme.accent(scheme))
                        .accessibilityLabel("Open link")
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(message.role == .assistant
                      ? TLITheme.cardBackground(scheme).opacity(0.32)
                      : TLITheme.accentSoft(scheme).opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .onAppear {
            beginRevealIfNeeded(cleaned)
        }
        .onChange(of: cleaned) { _, newValue in
            beginRevealIfNeeded(newValue)
        }
        .onDisappear {
            revealTask?.cancel()
        }
    }

    private func revealedDisplayText(for cleaned: String) -> String {
        if message.role == .assistant && isNewestAssistant {
            return revealedText
        }
        return cleaned
    }

    private func beginRevealIfNeeded(_ cleaned: String) {
        revealTask?.cancel()
        guard message.role == .assistant, isNewestAssistant else {
            revealedText = cleaned
            return
        }

        guard !reduceMotion else {
            revealedText = cleaned
            return
        }

        revealedText = ""
        let characters = Array(cleaned)
        revealTask = Task {
            for character in characters {
                if Task.isCancelled { return }
                await MainActor.run {
                    revealedText.append(character)
                }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }
}

private struct ThinkingBubble: View {
    let scheme: ColorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Computer is processing your request…")
                        .font(.body)
                }
                .foregroundStyle(TLITheme.textPrimary(scheme))

                Text("Checking local guidance, schedule tools, and fallback routes.")
                    .font(.caption)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
            }
            Spacer(minLength: 40)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TLITheme.cardBackground(scheme).opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 18,
            emphasis: true,
            idleSweepDuration: 1.4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computer is processing your request.")
        .accessibilityHint("A response will appear when the lookup is complete.")
    }
}

// MARK: - Trek-inspired chrome (slimmer)

private struct LCARSTopBar: View {
    let scheme: ColorScheme
    let isActive: Bool
    let activatedAt: Date

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let phase = phase(at: context.date)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TLITheme.accent(scheme))
                    .frame(width: 14, height: 64)
                    .overlay(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(.white.opacity(isActive ? 0.40 : 0.18))
                            .frame(width: 10, height: isActive ? 22 : 12)
                            .padding(.top, 6)
                            .blur(radius: isActive ? 2 : 0)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("HELLO, COMPUTER")
                            .font(
                                RisaTheme.isLCARSThemeEnabled
                                    ? .system(size: 12, weight: .heavy, design: .monospaced)
                                    : .caption.weight(.semibold)
                            )
                            .foregroundStyle(TLITheme.textPrimary(scheme))

                        Text(isActive ? "LIVE" : "BETA")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(TLITheme.accent(scheme))
                            )
                            .accessibilityLabel(isActive ? "Live" : "Beta")
                    }

                    HStack(spacing: 8) {
                        lcarsBlock(width: 52, height: 12, style: .accent, phase: phase, phaseOffset: 0.00)
                        lcarsBlock(width: 30, height: 12, style: .muted, phase: phase, phaseOffset: 0.18)
                        lcarsBlock(width: 18, height: 12, style: .muted2, phase: phase, phaseOffset: 0.36)
                        Spacer()
                        lcarsBlock(width: 44, height: 12, style: .muted, phase: phase, phaseOffset: 0.54)
                    }
                }

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(TLITheme.chipBackground(scheme))
                        .frame(width: 38, height: 64)
                        .overlay(
                            VStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { index in
                                    Capsule(style: .continuous)
                                        .fill(TLITheme.accent(scheme).opacity(indicatorOpacity(for: index, phase: phase)))
                                        .frame(width: 18, height: 8)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
                        )
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().stroke(TLITheme.cardStroke(scheme), lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
        )
        .lcarsReactiveSurface(
            accent: TLITheme.accent(scheme),
            cornerRadius: 18,
            emphasis: isActive,
            idleSweepDuration: isActive ? 1.4 : 3.2
        )
    }

    private enum BlockStyle { case accent, muted, muted2 }

    @ViewBuilder
    private func lcarsBlock(
        width: CGFloat,
        height: CGFloat,
        style: BlockStyle,
        phase: Double,
        phaseOffset: Double
    ) -> some View {
        let energy = blockEnergy(phase: phase, offset: phaseOffset)

        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(color(for: style))
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.white.opacity(0.10 + (0.12 * energy)))
                    .padding(1)
                    .blur(radius: isActive ? 1.6 : 0.8)
            }
            .scaleEffect(x: 1.0 + (isActive ? energy * 0.03 : 0.0), y: 1.0, anchor: .leading)
    }

    private func color(for style: BlockStyle) -> Color {
        switch style {
        case .accent: return TLITheme.accent(scheme).opacity(isActive ? 0.98 : 0.95)
        case .muted:  return TLITheme.chipBackground(scheme)
        case .muted2: return TLITheme.cardBackground(scheme).opacity(0.55)
        }
    }

    private func phase(at date: Date) -> Double {
        guard RisaTheme.isLCARSThemeEnabled else { return 0.0 }
        let relativeTime = max(0, date.timeIntervalSince(activatedAt))
        if isActive {
            return relativeTime.truncatingRemainder(dividingBy: 1.8) / 1.8
        }
        return date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 5.5) / 5.5
    }

    private func blockEnergy(phase: Double, offset: Double) -> Double {
        let shifted = (phase + offset).truncatingRemainder(dividingBy: 1.0)
        let distance = abs(shifted - 0.5)
        let normalized = max(0.0, 1.0 - (distance / 0.5))
        return isActive ? normalized : normalized * 0.42
    }

    private func indicatorOpacity(for index: Int, phase: Double) -> Double {
        let shifted = (phase + (Double(index) * 0.16)).truncatingRemainder(dividingBy: 1.0)
        let distance = abs(shifted - 0.5)
        let normalized = max(0.18, 1.0 - (distance / 0.5))
        return isActive ? normalized : 0.20 + (Double(index) * 0.08)
    }
}

// MARK: - Simple wrap layout for suggestion chips (no custom FlowLayout types)

private struct WrapChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Two-line, compact “wrap” without custom layouts:
            // this keeps it compile-safe and accessible.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    content(item)
                }
            }
        }
    }
}

private struct PendingActionSheet: View {
    let action: HelloComputerPendingAction
    let scheme: ColorScheme
    let onApprove: () -> Void
    let onCancel: () -> Void
    private let sfx = ZenSFX.shared

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Confirm Assistant Action")
                    .font(.headline)
                    .foregroundStyle(TLITheme.textPrimary(scheme))

                Text(action.prompt)
                    .font(.body)
                    .foregroundStyle(TLITheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                HStack(spacing: 10) {
                    Button("Cancel") {
                        feedbackTap(isSuccess: false)
                        onCancel()
                    }
                        .buttonStyle(.bordered)
                    Button("Approve") {
                        feedbackTap(isSuccess: true)
                        onApprove()
                    }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TLITheme.backgroundGradient(scheme).ignoresSafeArea())
            .navigationTitle("Approval Required")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func feedbackTap(isSuccess: Bool) {
        sfx.play("lcars_tap_soft", ext: "wav", volume: 0.12)
        #if canImport(UIKit)
        if isSuccess {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        #endif
    }
}

// MARK: - URL Helpers

private enum URLDetector {
    static func urls(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var urls: [URL] = []
        detector.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let url = match?.url { urls.append(url) }
        }
        var seen = Set<String>()
        return urls.filter { seen.insert($0.absoluteString).inserted }
    }
}
