// Copyright Bryan Carroll. All rights reserved.
//
//  ZenSFX.swift
//  Trek Long Island
//
//  Small UI sound helper (optional).
//  Logs missing resources instead of failing silently.
//
//  Swift 6 • iOS 17+
//

import Foundation
import AVFoundation

enum TLIAudioSettings {
    static let uiSoundsEnabledKey = "TLI.Audio.uiSoundsEnabled"
}

@MainActor
final class ZenSFX {
    static let shared = ZenSFX()

    var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: TLIAudioSettings.uiSoundsEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: TLIAudioSettings.uiSoundsEnabledKey)
        }
    }

    private var player: AVAudioPlayer?

    private init() {}

    func play(_ name: String, ext: String = "wav", volume: Float = 0.14) {
        guard isEnabled else {
            print("ZenSFX: disabled")
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("ZenSFX: missing resource \(name).\(ext) (check target membership / Copy Bundle Resources)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.soloAmbient, mode: .default)
            try session.setActive(true, options: [])

            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = volume
            p.prepareToPlay()
            p.play()
            player = p

            print("ZenSFX: played \(name).\(ext)")
        } catch {
            print("ZenSFX: error \(error.localizedDescription)")
        }
    }
}
