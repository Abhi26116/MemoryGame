//
//  HomeViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    static let starsRequiredToUnlockNext = 2

    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        syncFromStore()
    }

    func syncFromStore() {
        guard let settings = progressStore.settings else { return }
        AudioManager.shared.soundEnabled = settings.soundEnabled
        AudioManager.shared.musicEnabled = settings.musicEnabled
    }

    var levels: [LevelModel] { LevelCatalog.allLevels }

    var totalStars: Int { progressStore.totalStars }
    var completedLevels: Int { progressStore.completedLevels }
    var totalLevels: Int { LevelCatalog.levelCount }

    var progressFraction: Double {
        guard totalLevels > 0 else { return 0 }
        return Double(completedLevels) / Double(totalLevels)
    }

    func stars(for levelId: String) -> Int {
        progressStore.progress(for: levelId)?.stars ?? 0
    }

    func isCompleted(_ levelId: String) -> Bool {
        (progressStore.progress(for: levelId)?.completedCount ?? 0) > 0
    }

    /// Level 1 is always open; level N unlocks when level N−1 has at least 2 stars.
    func isUnlocked(_ level: LevelModel) -> Bool {
        if level.levelNumber <= 1 { return true }
        guard let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return false }
        return stars(for: previous.id) >= Self.starsRequiredToUnlockNext
    }

    func unlockHint(for level: LevelModel) -> String? {
        guard !isUnlocked(level), level.levelNumber > 1 else { return nil }
        return "Earn \(Self.starsRequiredToUnlockNext) stars on Level \(level.levelNumber - 1)"
    }

    /// Next unlocked level that still needs 2+ stars (for Continue).
    var suggestedLevel: LevelModel? {
        levels.first { isUnlocked($0) && stars(for: $0.id) < Self.starsRequiredToUnlockNext }
    }
}
