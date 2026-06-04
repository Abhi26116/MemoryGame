//
//  SettingsViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var soundEnabled = true
    @Published var hapticsEnabled = true
    @Published var highContrast = false
    @Published var colorBlindMode = false
    @Published var largeText = false
    @Published var appearanceMode: AppearanceMode = .system
    @Published var memorizePreviewEnabled = true

    @Published private(set) var completedLevels = 0
    @Published private(set) var totalLevels = LevelCatalog.levelCount
    @Published private(set) var totalStars = 0
    @Published private(set) var goldLevels = 0
    @Published private(set) var achievementsUnlocked = 0

    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        syncFromStore()
    }

    func syncFromStore() {
        guard let s = progressStore.settings else { return }
        soundEnabled = s.soundEnabled
        hapticsEnabled = s.hapticsEnabled
        highContrast = s.highContrast
        colorBlindMode = s.colorBlindMode
        largeText = s.largeText
        appearanceMode = s.appearanceModeRaw.isEmpty
            ? .system
            : (AppearanceMode(rawValue: s.appearanceModeRaw) ?? .system)
        memorizePreviewEnabled = s.memorizePreviewEnabled

        completedLevels = progressStore.completedLevels
        totalStars = progressStore.totalStars
        goldLevels = progressStore.levelProgress.values.filter { $0.stars >= 3 }.count
        achievementsUnlocked = s.unlockedAchievementIds.count
    }

    func setSound(_ value: Bool) {
        soundEnabled = value
        AudioManager.shared.soundEnabled = value
        progressStore.updateSettings { $0.soundEnabled = value }
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

    func setAppearance(_ mode: AppearanceMode) {
        appearanceMode = mode
        progressStore.updateSettings { $0.appearanceModeRaw = mode.rawValue }
    }

    func setMemorizePreview(_ value: Bool) {
        memorizePreviewEnabled = value
        progressStore.updateSettings { $0.memorizePreviewEnabled = value }
    }

    func resetAllProgress() {
        progressStore.resetAllProgress()
        syncFromStore()
    }
}
