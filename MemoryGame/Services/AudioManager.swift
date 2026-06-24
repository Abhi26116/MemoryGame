//
//  AudioManager.swift
//  Memory Match Kids
//

import AVFoundation
import AudioToolbox
import UIKit

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var soundEnabled = true

    private init() {
        configureSession()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playFlip() { playSystemSound(1104) }
    func playSuccess() { playSystemSound(1057) }
    func playComplete() { playSystemSound(1025) }
    func playMismatch() { playSystemSound(1053) }

    private func playSystemSound(_ id: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
