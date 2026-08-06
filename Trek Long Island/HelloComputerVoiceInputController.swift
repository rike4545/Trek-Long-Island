//
//  HelloComputerVoiceInputController.swift
//  Trek Long Island
//
//  Created by Bryan on 2/24/26.
//


// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerVoiceInput.swift
//  Trek Long Island
//
//  Voice input controller — v2.
//  Adds haptic feedback and hands-free (auto-send) mode
//  on top of the v1 fixes (isStarting race, AVAudioSession category,
//  audioLevel, silence detection).
//
//  NEW IN V2
//  ─────────────────────────────────────────────────────────────────
//  HAPTICS
//  • Heavy impact on recording start  — feels like a comm channel opening
//  • Light impact on recording stop   — clean, quiet close
//  • Notification "error" feedback    — on permission denied / STT error
//  • Notification "success" feedback  — when isFinal fires cleanly
//  All haptics are no-ops on devices without a Taptic Engine (iPad, etc.)
//
//  HANDS-FREE MODE
//  • `isHandsFreeEnabled: Bool` — off by default; toggled per-session
//    via HelloComputerHandsFreeToggle (the compact toggle view below).
//  • When enabled and silence auto-stop fires, calls `onHandsFreeSubmit`
//    with the final transcript instead of just stopping.
//  • When disabled, silence auto-stop works exactly as before — stops
//    recording and leaves the text in the field for manual review/send.
//  • `onHandsFreeSubmit` is wired to `store.send(_:)` in HelloComputerView.
//
//  Swift 6 • iOS 17+

import Foundation
import AVFoundation
import Speech
import SwiftUI

// MARK: - HelloComputerVoiceInputController

@MainActor
final class HelloComputerVoiceInputController: NSObject, ObservableObject {

    // MARK: Published

    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    /// Normalised RMS mic level 0…1. Use this to animate a waveform.
    @Published var audioLevel: Float = 0.0

    /// Hands-free mode — when true, silence auto-stop submits automatically.
    @Published var isHandsFreeEnabled: Bool = false

    // MARK: Callbacks

    /// Called with the final transcript when hands-free mode fires.
    /// Wire this to `store.send(_:)` in HelloComputerView.
    var onHandsFreeSubmit: ((String) -> Void)?

    // MARK: Configuration

    var silenceDuration: TimeInterval = 2.5
    var silenceLevelFloor: Float = 0.02

    // MARK: Private

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private lazy var recognizer: SFSpeechRecognizer? = {
        SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    }()

    private var seededText: String = ""
    private var isStarting: Bool = false  // FIX 1: never cleared by stopRecording()
    private var silenceStart: Date?
    private var levelDecayTimer: Timer?

    // Haptics
    private let impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let impactLight  = UIImpactFeedbackGenerator(style: .light)
    private let notifyGen    = UINotificationFeedbackGenerator()

    // MARK: - Public API

    func startRecording(seedText: String) {
        guard !isRecording, !isStarting else { return }
        isStarting = true
        errorMessage = nil

        // Prepare haptics ahead of time to minimise latency
        impactHeavy.prepare()

        Task {
            do {
                try await requestPermissions()
                beginRecognition(seedText: seedText)
            } catch {
                isStarting = false
                errorMessage = error.localizedDescription
                notifyGen.notificationOccurred(.error)
            }
        }
    }

    func stopRecording() {
        stopDecayTimer()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        silenceStart = nil

        withAnimation(.easeOut(duration: 0.3)) { audioLevel = 0.0 }
        deactivateAudioSession()
    }

    // MARK: - Recognition Setup

    private func beginRecognition(seedText: String) {
        stopRecording()

        guard let recognizer, recognizer.isAvailable else {
            isStarting = false
            errorMessage = "Speech recognition is currently unavailable."
            notifyGen.notificationOccurred(.error)
            return
        }

        seededText = seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        transcript = seededText

        do {
            // FIX 2: .record avoids routing conflicts with TTS / system audio
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [.allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            guard let format = validTapFormat(for: inputNode) else {
                throw NSError(
                    domain: "HelloComputerVoice",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Microphone input is unavailable right now. Check your audio route and try again."]
                )
            }
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.handleAudioBuffer(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            // FIX 1: Only clear isStarting after successful setup
            isStarting = false
            isRecording = true
            silenceStart = nil
            startDecayTimer()

            // ── HAPTIC: comm channel open ──
            impactHeavy.impactOccurred()

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let result {
                        let dictated = result.bestTranscription.formattedString
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if seededText.isEmpty {
                            transcript = dictated
                        } else if dictated.isEmpty {
                            transcript = seededText
                        } else {
                            transcript = "\(seededText) \(dictated)"
                        }
                    }

                    if let error, isRecording {
                        let nsErr = error as NSError
                        // Code 301 = cancelled — not user-visible
                        if nsErr.domain == "kAFAssistantErrorDomain" && nsErr.code == 301 {
                            stopRecording()
                            return
                        }
                        errorMessage = "Voice input stopped: \(error.localizedDescription)"
                        notifyGen.notificationOccurred(.error)
                        stopRecording()
                        return
                    }

                    if result?.isFinal ?? false {
                        // ── HAPTIC: clean completion ──
                        notifyGen.notificationOccurred(.success)
                        stopRecording()
                    }
                }
            }

        } catch {
            isStarting = false
            errorMessage = "Could not start voice input: \(error.localizedDescription)"
            notifyGen.notificationOccurred(.error)
            stopRecording()
        }
    }

    // MARK: - Audio Level + Silence Detection

    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }

        var sum: Float = 0
        let samples = data.pointee
        for i in 0..<count { let s = samples[i]; sum += s * s }
        let rms = sqrt(sum / Float(count))

        Task { @MainActor [weak self] in
            guard let self else { return }
            // A non-finite sample would poison every downstream `Int(audioLevel * …)`
            // conversion, so normalise it here at the source.
            let level = rms.isFinite ? min(max(rms * 25.0, 0), 1.0) : 0
            audioLevel = level

            if level < silenceLevelFloor {
                if silenceStart == nil { silenceStart = Date() }
                if let start = silenceStart,
                   isRecording,
                   Date().timeIntervalSince(start) >= silenceDuration {
                    handleSilenceTimeout()
                }
            } else {
                silenceStart = nil
            }
        }
    }

    private func handleSilenceTimeout() {
        let finalText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        // ── HAPTIC: stop ──
        impactLight.impactOccurred()
        stopRecording()

        // Hands-free: auto-submit if enabled and there's something to say
        if isHandsFreeEnabled, !finalText.isEmpty {
            onHandsFreeSubmit?(finalText)
        }
    }

    private func startDecayTimer() {
        stopDecayTimer()
        levelDecayTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, isRecording else { return }
                if audioLevel > 0 { audioLevel = max(0, audioLevel - 0.04) }
            }
        }
    }

    private func stopDecayTimer() {
        levelDecayTimer?.invalidate()
        levelDecayTimer = nil
    }

    private func validTapFormat(for inputNode: AVAudioInputNode) -> AVAudioFormat? {
        let output = inputNode.outputFormat(forBus: 0)
        if output.sampleRate > 0, output.channelCount > 0 {
            return output
        }

        let input = inputNode.inputFormat(forBus: 0)
        if input.sampleRate > 0, input.channelCount > 0 {
            return input
        }

        return nil
    }

    private func deactivateAudioSession() {
        Task {
            try? AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Permissions

    private func requestPermissions() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            let current = SFSpeechRecognizer.authorizationStatus()
            if current == .notDetermined {
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            } else {
                continuation.resume(returning: current)
            }
        }

        guard speechStatus == .authorized else {
            let detail: String
            switch speechStatus {
            case .denied:
                detail = "Speech recognition was denied. Enable it in Settings → Privacy → Speech Recognition."
            case .restricted:
                detail = "Speech recognition is restricted on this device."
            default:
                detail = "Speech recognition permission was not granted."
            }
            throw VoiceInputError.permissionDenied(detail)
        }

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await withCheckedContinuation { continuation in
                switch AVAudioApplication.shared.recordPermission {
                case .granted:      continuation.resume(returning: true)
                case .denied:       continuation.resume(returning: false)
                case .undetermined:
                    AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
                @unknown default:   continuation.resume(returning: false)
                }
            }
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
        }

        guard micGranted else {
            throw VoiceInputError.permissionDenied(
                "Microphone access was denied. Enable it in Settings → Privacy → Microphone."
            )
        }
    }
}

// MARK: - Error

private enum VoiceInputError: LocalizedError {
    case permissionDenied(String)
    var errorDescription: String? {
        switch self { case .permissionDenied(let msg): return msg }
    }
}

// MARK: - MicWaveformView (unchanged from v1)

struct MicWaveformView: View {
    let level: Float
    let isRecording: Bool
    let scheme: ColorScheme

    private let barCount = 5
    private let minBarHeight: CGFloat = 4
    private let maxBarHeight: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isRecording ? Color.red.opacity(0.85) : Color.secondary.opacity(0.4))
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(
                        isRecording
                            ? .easeInOut(duration: 0.12).delay(Double(index) * 0.03)
                            : .easeOut(duration: 0.25),
                        value: level
                    )
            }
        }
        .frame(height: maxBarHeight)
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard isRecording else { return minBarHeight }
        let phase = Float(index) / Float(barCount - 1)
        let boost = CGFloat((sin(.pi * phase) * 0.4) + 0.6)
        let scaled = CGFloat(level) * boost
        return minBarHeight + (maxBarHeight - minBarHeight) * max(0, min(1, scaled))
    }
}

// MARK: - HelloComputerHandsFreeToggle

/// Compact toggle to embed in the Hello Computer prompt card.
/// Shows a brief explainer when turned on so the user knows what to expect.
///
/// Usage in promptCard (add below the Mode picker):
///
///     HelloComputerHandsFreeToggle(voiceInput: voiceInput)
///
struct HelloComputerHandsFreeToggle: View {
    @ObservedObject var voiceInput: HelloComputerVoiceInputController

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $voiceInput.isHandsFreeEnabled) {
                Text("Hands-Free Mode")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(.orange)

            if voiceInput.isHandsFreeEnabled {
                Text("After you speak, silence will auto-submit your question — no tap needed.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: voiceInput.isHandsFreeEnabled)
    }
}

// MARK: ─────────────────────────────────────────────────────────────
// MARK: INTEGRATION GUIDE — HelloComputerView.swift
// MARK: ─────────────────────────────────────────────────────────────
//
//  1. WIRE onHandsFreeSubmit in the view's onAppear or init:
//
//      .onAppear {
//          voiceInput.onHandsFreeSubmit = { text in
//              store.inputText = text
//              store.send(text)
//          }
//      }
//
//  2. ADD the hands-free toggle to promptCard, below the Mode picker:
//
//      HelloComputerHandsFreeToggle(voiceInput: voiceInput)
//
//  3. WIRE TTS — add `let tts = HelloComputerTTSController()` to
//     HelloComputerStore. Then in each MainActor.run block that appends
//     an assistant message, add:
//
//      if self.tts.isEnabled {
//          self.tts.speak(answer.text)
//      }
//
//  4. ADD a TTS speaker button to the inputBar (optional — sits next
//     to the mic button) so the user can stop TTS mid-playback:
//
//      if store.tts.isSpeaking {
//          Button { store.tts.stop() } label: {
//              Image(systemName: "speaker.slash.fill")
//                  .font(.system(size: 18, weight: .semibold))
//                  .foregroundStyle(TLITheme.textPrimary(scheme))
//                  .padding(12)
//                  .background(
//                      RoundedRectangle(cornerRadius: 14, style: .continuous)
//                          .fill(TLITheme.cardBackground(scheme).opacity(0.20))
//                  )
//                  .overlay(
//                      RoundedRectangle(cornerRadius: 14, style: .continuous)
//                          .stroke(TLITheme.cardStroke(scheme), lineWidth: 1)
//                  )
//          }
//          .buttonStyle(.plain)
//          .transition(.scale.combined(with: .opacity))
//      }
