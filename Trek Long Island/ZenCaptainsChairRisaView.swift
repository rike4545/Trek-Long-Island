// Copyright Bryan Carroll. All rights reserved.
//
//  ZenCaptainsChairRisaView.swift
//  Trek Long Island
//
//  Moment of Zen — Captain’s Chair on Risa
//  - User-configurable duration + sound
//  - Start / Stop controls
//  - Touch-safe: backdrop never steals taps
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import AVFoundation

@MainActor
struct ZenCaptainsChairRisaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Config

    @State private var selectedMode: RisaZenMode = .sunsetCruise
    @State private var durationSeconds: Int = 60
    @State private var selectedSound: ZenSoundOption = .bridgeHum

    // MARK: - Session state

    @State private var isRunning: Bool = false
    @State private var secondsRemaining: Int = 60
    @State private var timerTask: Task<Void, Never>?

    // MARK: - UI

    @State private var showControls: Bool = true

    // MARK: - Audio

    @StateObject private var audio = ZenLoopAudioPlayer()
    private let sfx = ZenSFX.shared
    @AppStorage(TLIAudioSettings.uiSoundsEnabledKey) private var uiSoundEnabled: Bool = true

    var body: some View {
        ZStack {
            // Background: MUST be non-interactive
            RisaSkyBackdrop(mode: selectedMode, reduceMotion: reduceMotion)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            chairLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            overlayChrome
                .zIndex(100)
                .allowsHitTesting(true)
        }
        .onAppear {
            // Initialize session values
            secondsRemaining = durationSeconds
            sfx.isEnabled = uiSoundEnabled
        }
        .onChange(of: durationSeconds) { _, newValue in
            // Only update remaining time when not running
            guard !isRunning else { return }
            secondsRemaining = newValue
        }
        .onChange(of: selectedMode) { _, _ in
            // Mode is visual only; keep running session stable
            tick()
        }
        .onChange(of: selectedSound) { _, newValue in
            tick()
            // If running, switch loop instantly
            if isRunning {
                playSelectedLoop(newValue)
            }
        }
        .onDisappear {
            stopSession()
        }
        .statusBarHidden(true)
    }

    // MARK: - Layers

    private var chairLayer: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                CaptainsChairSilhouette()
                    .fill(.white.opacity(0.08))
                    .blur(radius: 18)
                    .offset(y: size.height * 0.09)
                    .scaleEffect(1.02)

                CaptainsChairSilhouette()
                    .fill(.black.opacity(0.76))
                    .overlay {
                        CaptainsChairSilhouette()
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    }
                    .shadow(radius: 24)
                    .frame(width: min(size.width, size.height) * 0.78,
                           height: min(size.width, size.height) * 0.78)
                    .position(x: size.width * 0.5, y: size.height * 0.68)

                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.18), .black.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size.height * 0.42)
                .position(x: size.width * 0.5, y: size.height * 0.80)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Overlay

    private var overlayChrome: some View {
        VStack(spacing: 14) {
            topBar

            Spacer()

            if isRunning {
                countdownChip
                    .padding(.bottom, 6)
                    .allowsHitTesting(false)
            }

            if showControls {
                bottomPanel
            }
        }
        .foregroundStyle(.white)
    }

    private var topBar: some View {
        HStack {
            Button {
                tick()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(.black.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Exit")

            Spacer()

            Button {
                tick(quiet: true)
                withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
            } label: {
                Image(systemName: showControls ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(.black.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showControls ? "Hide controls" : "Show controls")
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .contentShape(Rectangle())
    }

    private var countdownChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 13, weight: .semibold))
            Text(timeString(secondsRemaining))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.black.opacity(0.25), in: Capsule())
        .accessibilityLabel("Time remaining \(timeString(secondsRemaining))")
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            headerRow
            interactionGuide
            modePicker
            durationControl
            soundPicker
            actionButtons
        }
        .padding(14)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .contentShape(Rectangle())
        .onChange(of: isRunning) { _, running in
            // Auto-hide after start
            if running {
                Task {
                    try? await Task.sleep(for: .milliseconds(1800))
                    if isRunning {
                        withAnimation(.easeInOut(duration: 0.35)) { showControls = false }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { showControls = true }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Label("Moment of Zen", systemImage: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Button {
                uiSoundEnabled.toggle()
                sfx.isEnabled = uiSoundEnabled
                tick(quiet: true)
            } label: {
                Label(
                    uiSoundEnabled ? "UI Sound On" : "UI Sound Off",
                    systemImage: uiSoundEnabled ? "waveform" : "waveform.slash"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(.black.opacity(0.18), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var interactionGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How to use this")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Text("""
Choose a duration and a sound, then press Start.
Press Stop at any time to end early.
Use the eye button to hide/show controls. Use X to exit.
""")
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.80))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(RisaZenMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark)
    }

    private var durationControl: some View {
        HStack(spacing: 12) {
            Label("Duration", systemImage: "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Stepper {
                Text(durationLabel(durationSeconds))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .monospacedDigit()
            } onIncrement: {
                tick(quiet: true)
                durationSeconds = min(durationSeconds + 15, 300)
            } onDecrement: {
                tick(quiet: true)
                durationSeconds = max(durationSeconds - 15, 15)
            }
            .disabled(isRunning)
        }
        .padding(.vertical, 6)
    }

    private var soundPicker: some View {
        HStack(spacing: 10) {
            Label("Sound", systemImage: "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Picker("Sound", selection: $selectedSound) {
                ForEach(ZenSoundOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .disabled(isRunning == false ? false : false) // allow switching while running
        }
        .padding(.vertical, 6)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                tick()
                startSession()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(isRunning ? "Running…" : "Start")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isRunning)

            Button {
                tick(quiet: true)
                stopSession()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isRunning)
        }
    }

    // MARK: - Session

    private func startSession() {
        guard !isRunning else { return }

        isRunning = true
        secondsRemaining = durationSeconds

        playSelectedLoop(selectedSound)

        timerTask?.cancel()
        timerTask = Task {
            while secondsRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                secondsRemaining -= 1
            }
            if !Task.isCancelled {
                stopSession()
                dismiss()
            }
        }
    }

    private func stopSession() {
        timerTask?.cancel()
        timerTask = nil

        isRunning = false
        audio.stop()

        // Reset remaining time to selected duration for next start
        secondsRemaining = durationSeconds
    }

    private func playSelectedLoop(_ option: ZenSoundOption) {
        switch option {
        case .none:
            audio.stop()
        case .bridgeHum:
            audio.playLoop(resourceName: "bridge_hum_soft", fileExtension: "wav", volume: 0.22)
        case .quietRoomtone:
            audio.playLoop(resourceName: "quiet_roomtone", fileExtension: "wav", volume: 0.20)
        }
    }

    // MARK: - Helpers

    private func tick(quiet: Bool = false) {
        guard uiSoundEnabled else { return }
        sfx.play("lcars_tap_soft", ext: "wav", volume: quiet ? 0.10 : 0.14)
    }

    private func durationLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    private func timeString(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Sound Options

enum ZenSoundOption: String, CaseIterable, Identifiable, Hashable {
    case none
    case bridgeHum
    case quietRoomtone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .bridgeHum: return "Bridge Hum"
        case .quietRoomtone: return "Quiet Roomtone"
        }
    }
}

// MARK: - Looping Audio Player (self-contained, no mute surprises)

@MainActor
final class ZenLoopAudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func playLoop(resourceName: String, fileExtension: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            print("ZenLoopAudioPlayer: missing resource \(resourceName).\(fileExtension) (check target membership)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            // Respect silent mode but be reliable
            try session.setCategory(.soloAmbient, mode: .default)
            try session.setActive(true, options: [])

            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = volume
            p.prepareToPlay()
            p.play()
            player = p

            print("ZenLoopAudioPlayer: playing \(resourceName).\(fileExtension)")
        } catch {
            print("ZenLoopAudioPlayer: audio error \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
