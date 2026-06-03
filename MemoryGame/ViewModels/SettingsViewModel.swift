//
//  SettingsViewModel.swift
//  Memory Match Kids
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var soundEnabled = true
    @Published var musicEnabled = true
    @Published var hapticsEnabled = true
    @Published var highContrast = false
    @Published var colorBlindMode = false
    @Published var largeText = false

    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        syncFromStore()
    }

    func syncFromStore() {
        guard let s = progressStore.settings else { return }
        soundEnabled = s.soundEnabled
        musicEnabled = s.musicEnabled
        hapticsEnabled = s.hapticsEnabled
        highContrast = s.highContrast
        colorBlindMode = s.colorBlindMode
        largeText = s.largeText
    }

    func setSound(_ value: Bool) {
        soundEnabled = value
        AudioManager.shared.soundEnabled = value
        progressStore.updateSettings { $0.soundEnabled = value }
    }

    func setMusic(_ value: Bool) {
        musicEnabled = value
        AudioManager.shared.musicEnabled = value
        progressStore.updateSettings { $0.musicEnabled = value }
    }

    func setHaptics(_ value: Bool) {
        hapticsEnabled = value
        progressStore.updateSettings { $0.hapticsEnabled = value }
    }

    func setHighContrast(_ value: Bool) {
        highContrast = value
        progressStore.updateSettings { $0.highContrast = value }
    }

    func setColorBlind(_ value: Bool) {
        colorBlindMode = value
        progressStore.updateSettings { $0.colorBlindMode = value }
    }

    func setLargeText(_ value: Bool) {
        largeText = value
        progressStore.updateSettings { $0.largeText = value }
    }
}
