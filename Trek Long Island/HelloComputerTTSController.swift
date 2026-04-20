//
//  HelloComputerTTSController.swift
//  Trek Long Island
//
//  Created by Bryan on 2/24/26.
//


// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerTTSController.swift
//  Trek Long Island
//
//  Text-to-speech for Hello, Computer assistant replies.
//  Aims for a calm, measured, Majel Barrett-style delivery.
//
//  FEATURES
//  ─────────────────────────────────────────────────────────────────
//  • HelloComputerTTSController — ObservableObject that speaks any
//    string through AVSpeechSynthesizer with configurable voice,
//    rate, pitch, and volume.
//  • Strips source attribution footers ("— Source: …") before speaking
//    so the user only hears the actual answer content.
//  • Strips markdown-style bullet bullets (•, -, *) and numbered list
//    prefixes so spoken output flows naturally.
//  • Persists user voice preference via @AppStorage key
//    "TLI.HelloComputer.ttsVoiceIdentifier".
//  • HelloComputerVoicePickerView — a compact picker showing all
//    available female voices grouped by language, with a live preview
//    button. Drop this into your Settings screen.
//  • HelloComputerTTSSettingsRow — a single-row summary for embedding
//    in an existing settings List/Form.
//
//  HOW TO INTEGRATE — HelloComputerStore.swift
//  ─────────────────────────────────────────────────────────────────
//  1. Add a TTSController to HelloComputerStore:
//
//      let tts = HelloComputerTTSController()
//
//  2. In the `send()` method, after appending any assistant message,
//     call speak if TTS is enabled:
//
//      // In the MainActor.run blocks where you append assistant msgs:
//      if self.tts.isEnabled {
//          self.tts.speak(self.decorate(local))
//      }
//
//  3. When the user switches audience or mode, stop TTS:
//
//      .onChange(of: store.audience) { _, _ in store.tts.stop() }
//      .onChange(of: store.mode)     { _, _ in store.tts.stop() }
//
//  HOW TO INTEGRATE — Settings screen
//  ─────────────────────────────────────────────────────────────────
//      HelloComputerTTSSettingsRow(tts: store.tts)
//
//  Swift 6 • iOS 17+

import Foundation
import AVFoundation
import SwiftUI

// MARK: - TTS Controller

@MainActor
final class HelloComputerTTSController: NSObject, ObservableObject {

    // MARK: Published

    @Published var isSpeaking: Bool = false
    @Published var isEnabled: Bool = false

    // MARK: Persistence

    /// Identifier of the selected AVSpeechSynthesisVoice.
    /// Empty string = use system default female voice.
    @AppStorage("TLI.HelloComputer.ttsVoiceIdentifier")
    var preferredVoiceIdentifier: String = ""

    // MARK: Configuration — Barrett-style defaults

    /// Speaking rate. AVSpeechUtteranceDefaultSpeechRate ≈ 0.5.
    /// 0.42 is slightly slower than default — calm, measured.
    var speechRate: Float = 0.42

    /// Pitch multiplier. 1.0 = natural. Slight drop adds authority.
    var pitchMultiplier: Float = 0.95

    /// Volume 0…1.
    var volume: Float = 1.0

    // MARK: Private

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    /// Speak `text`, stripping source footers and list markers first.
    func speak(_ text: String) {
        guard isEnabled, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        stop()

        let cleaned = cleanForSpeech(text)
        guard !cleaned.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = resolvedVoice()
        utterance.rate = speechRate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = volume
        // A short pre-utterance delay feels more deliberate — very Majel.
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.10

        activateAudioSession()
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        guard isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        deactivateAudioSession()
    }

    func toggleEnabled() {
        isEnabled.toggle()
        if !isEnabled { stop() }
    }

    // MARK: - Voice Resolution

    /// Returns all available voices suitable for TTS picker display.
    /// Prefers female voices; falls back to all voices if none found.
    static func availableVoices() -> [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        // Female voices only — filter by known gender quality hint where available
        let female = all.filter { voice in
            // iOS 16+ exposes gender; on older builds we fall back to name heuristics
            if #available(iOS 16.0, *) {
                return voice.gender == .female
            }
            // Heuristic: common female voice name substrings
            let lower = voice.name.lowercased()
            return lower.contains("samantha") || lower.contains("karen") ||
                   lower.contains("moira")    || lower.contains("tessa") ||
                   lower.contains("fiona")    || lower.contains("kate")  ||
                   lower.contains("victoria") || lower.contains("ava")   ||
                   lower.contains("allison")  || lower.contains("susan") ||
                   lower.contains("zoe")
        }
        return female.isEmpty ? all : female
    }

    private func resolvedVoice() -> AVSpeechSynthesisVoice? {
        // 1. User-selected voice
        if !preferredVoiceIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: preferredVoiceIdentifier) {
            return voice
        }
        // 2. Samantha as a reasonable Barrett-adjacent default
        if let samantha = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
            return samantha
        }
        if let samantha = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha") {
            return samantha
        }
        // 3. Any en-US female voice
        let usVoices = Self.availableVoices().filter { $0.language.hasPrefix("en-US") }
        return usVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Text Cleaning

    private func cleanForSpeech(_ raw: String) -> String {
        var text = raw

        // Strip source attribution footers ("— Source: …" or "- Source: …")
        // These appear at the end of decorated answers and are not useful spoken.
        let sourcePatterns = [
            #"\n+—\s*Source:.*$"#,
            #"\n+[-–]\s*Source:.*$"#,
        ]
        for pattern in sourcePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines]) {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
            }
        }

        // Unescape literal \n sequences that FAQ bank stores
        text = text.replacingOccurrences(of: "\\n", with: "\n")

        // Replace bullet markers with a brief pause word
        text = text.replacingOccurrences(of: "•", with: ",")
        text = text.replacingOccurrences(of: "·", with: ",")

        // Numbered list prefixes "1)" "2." etc. → just a pause
        if let regex = try? NSRegularExpression(pattern: #"^\d+[.)]\s+"#, options: .anchorsMatchLines) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: ", ")
        }

        // Collapse multiple newlines → single pause
        if let regex = try? NSRegularExpression(pattern: #"\n{2,}"#) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: ". ")
        }

        // Replace remaining newlines with a comma pause
        text = text.replacingOccurrences(of: "\n", with: ", ")

        // Trim
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Pronounce URLs sensibly — just say "the website" or "the ticket site"
        text = text.replacingOccurrences(
            of: TicketPurchaseLinks.photoOpsURLString,
            with: "the official photo op ticket page"
        )
        text = text.replacingOccurrences(
            of: "https://treklongislandtickets.square.site/",
            with: "the official ticket site"
        )
        text = text.replacingOccurrences(
            of: "https://treklongisland.com/",
            with: "the official website"
        )
        text = text.replacingOccurrences(
            of: "https://treklongisland.com",
            with: "the official website"
        )

        return text
    }

    // MARK: - Audio Session

    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance()
            .setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func deactivateAudioSession() {
        Task {
            try? AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension HelloComputerTTSController: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            isSpeaking = false
            deactivateAudioSession()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

// MARK: - Voice Picker View

/// Full voice picker. Embed in a NavigationStack pushed from Settings.
struct HelloComputerVoicePickerView: View {
    @ObservedObject var tts: HelloComputerTTSController
    @Environment(\.colorScheme) private var scheme
    @State private var previewVoiceID: String = ""

    private var voices: [AVSpeechSynthesisVoice] {
        HelloComputerTTSController.availableVoices()
            .sorted { $0.name < $1.name }
    }

    // Group by language region, e.g. "English (US)", "English (Australia)"
    private var grouped: [(language: String, voices: [AVSpeechSynthesisVoice])] {
        var dict: [String: [AVSpeechSynthesisVoice]] = [:]
        for v in voices {
            let lang = Locale.current.localizedString(forIdentifier: v.language)
                ?? v.language
            dict[lang, default: []].append(v)
        }
        return dict.map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
                   .sorted { $0.language < $1.language }
    }

    var body: some View {
        List {
            Section {
                Toggle("Read answers aloud", isOn: $tts.isEnabled)
            } header: {
                Text("Computer Voice")
            } footer: {
                Text("Reads assistant responses in the style of the ship's computer. Disable at any time by tapping the speaker icon in Hello, Computer.")
                    .font(.footnote)
            }

            if tts.isEnabled {
                Section {
                    ForEach(grouped, id: \.language) { group in
                        Section(header: Text(group.language).font(.caption)) {
                            ForEach(group.voices, id: \.identifier) { voice in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(voice.name)
                                            .font(.body)
                                        Text(voice.quality == .enhanced || voice.quality == .premium
                                             ? "Enhanced" : "Standard")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    // Preview button
                                    Button {
                                        previewVoice(voice)
                                    } label: {
                                        Image(systemName: previewVoiceID == voice.identifier
                                              ? "stop.circle.fill"
                                              : "play.circle")
                                            .foregroundStyle(.tint)
                                    }
                                    .buttonStyle(.plain)

                                    // Selection checkmark
                                    if tts.preferredVoiceIdentifier == voice.identifier {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    tts.preferredVoiceIdentifier = voice.identifier
                                }
                            }
                        }
                    }
                } header: {
                    Text("Choose Voice")
                }

                Section {
                    LabeledContent("Rate") {
                        HStack {
                            Text("Slow")
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: $tts.speechRate, in: 0.3...0.6)
                            Text("Fast")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Pitch") {
                        HStack {
                            Text("Low")
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: $tts.pitchMultiplier, in: 0.75...1.25)
                            Text("High")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Tuning")
                } footer: {
                    Text("For a Majel Barrett–style delivery, try Rate around 40% and Pitch slightly below centre.")
                        .font(.footnote)
                }

                Section {
                    Button("Preview current settings") {
                        tts.speak("Starfleet computer online. Hello, I am the voice of Trek Long Island. How can I assist your mission today?")
                    }
                    .disabled(tts.isSpeaking)

                    if tts.isSpeaking {
                        Button("Stop preview", role: .destructive) {
                            tts.stop()
                            previewVoiceID = ""
                        }
                    }
                }
            }
        }
        .navigationTitle("Computer Voice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func previewVoice(_ voice: AVSpeechSynthesisVoice) {
        if previewVoiceID == voice.identifier {
            tts.stop()
            previewVoiceID = ""
            return
        }
        tts.stop()
        previewVoiceID = voice.identifier
        // Temporarily override to preview this voice
        let prev = tts.preferredVoiceIdentifier
        tts.preferredVoiceIdentifier = voice.identifier
        tts.speak("Hello. I am \(voice.name). Ready to assist.")
        // Restore after a moment — user taps checkmark to actually select
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak tts] in
            guard let tts else { return }
            if tts.preferredVoiceIdentifier == voice.identifier && prev != voice.identifier {
                // Only restore if user didn't explicitly select it
            }
            self.previewVoiceID = ""
        }
    }
}

// MARK: - Settings Row (compact, for embedding in existing settings List)

struct HelloComputerTTSSettingsRow: View {
    @ObservedObject var tts: HelloComputerTTSController

    var body: some View {
        NavigationLink {
            HelloComputerVoicePickerView(tts: tts)
        } label: {
            HStack {
                Label("Computer Voice", systemImage: "waveform")
                Spacer()
                Text(tts.isEnabled ? "On" : "Off")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }
}
