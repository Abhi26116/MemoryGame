//
//  HomeViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    static let starsRequiredToUnlockNext = StarRatingRules.starsRequiredToUnlockNextLevel
    /// Temporary: all levels playable without earning stars on the previous level.
    static let allLevelsUnlocked = true

    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        syncFromStore()
    }

    func syncFromStore() {
        guard let settings = progressStore.settings else { return }
        AudioManager.shared.soundEnabled = settings.soundEnabled
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

    func isUnlocked(_ level: LevelModel) -> Bool {
        if Self.allLevelsUnlocked { return true }
        if level.levelNumber <= 1 { return true }
        guard let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return false }
        return stars(for: previous.id) >= Self.starsRequiredToUnlockNext
    }

    func unlockHint(for level: LevelModel) -> String? {
        guard !isUnlocked(level), level.levelNumber > 1,
              let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return nil }
        let moves = previous.movesToEarnTwoStars
        return "Earn 2 stars on Level \(previous.levelNumber) (≤ \(moves) moves)"
    }

    /// Next unlocked level that still needs 2+ stars (for Continue).
    var suggestedLevel: LevelModel? {
        levels.first { isUnlocked($0) && stars(for: $0.id) < Self.starsRequiredToUnlockNext }
    }
}
