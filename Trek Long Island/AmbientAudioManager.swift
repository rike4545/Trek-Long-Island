// Copyright Bryan Carroll. All rights reserved.
//
//  AmbientAudioManager.swift
//  Trek Long Island
//
//  Ambient audio engine for Moment of Zen
//  Designed for subtle, non-intrusive soundscapes
//
//  Swift 6 • iOS 17+
//

import Foundation
import AVFoundation

@MainActor
final class AmbientAudioManager: ObservableObject {

    @Published var isMuted: Bool = true

    private var player: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?

    // MARK: - Public API

    /// Play a looping ambient sound if available in the bundle.
    /// Supports WAV or MP3 transparently.
    func playLoopIfAvailable(
        named name: String,
        fileExtension ext: String,
        volume: Float
    ) {
        guard !isMuted else { return }

        // If already playing, just adjust volume
        if let player, player.isPlaying {
            fadeTo(volume: volume, duration: 0.6)
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            // Missing asset — fail silently (important for live environments)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()

            // `.ambient` respects Silent Mode and mixes politely
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0.0
            newPlayer.prepareToPlay()
            newPlayer.play()

            self.player = newPlayer

            // Fade in gently
            fadeTo(volume: volume, duration: 1.2)

        } catch {
            // Never crash for audio
            player = nil
        }
    }

    /// Stop playback with a gentle fade-out.
    func stop() {
        fadeTask?.cancel()

        guard let player else { return }

        fadeTask = Task {
            let steps = 20
            let startVolume = player.volume

            for step in stride(from: steps, through: 0, by: -1) {
                if Task.isCancelled { return }
                player.volume = startVolume * Float(step) / Float(steps)
                try? await Task.sleep(for: .milliseconds(40))
            }

            player.stop()
            self.player = nil

            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [])
            } catch {
                // ignore
            }
        }
    }

    // MARK: - Helpers

    private func fadeTo(volume target: Float, duration: TimeInterval) {
        fadeTask?.cancel()

        guard let player else { return }

        let steps = max(1, min(600, TLISafeMath.int(duration / 0.05, fallback: 1)))
        let start = player.volume
        let delta = target - start

        fadeTask = Task {
            for i in 1...steps {
                if Task.isCancelled { return }
                let progress = Float(i) / Float(steps)
                player.volume = start + delta * progress
                try? await Task.sleep(for: .milliseconds(50))
            }
            player.volume = target
        }
    }

    deinit {
        fadeTask?.cancel()
        player?.stop()
    }
}
