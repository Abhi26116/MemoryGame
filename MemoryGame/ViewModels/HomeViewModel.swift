//
//  HomeViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    /// Testing override: set true to play every level without earning stars first.
    /// Off in production — only Level 1 is open; each level unlocks by earning 2★ on the previous one.
    static let allLevelsUnlocked = false

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
        return isCompleted(previous.id)
    }

    func unlockHint(for level: LevelModel) -> String? {
        guard !isUnlocked(level), level.levelNumber > 1,
              let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return nil }
        return "Complete Level \(previous.levelNumber) to unlock"
    }

    /// Next unlocked level the player hasn't finished yet (for Continue).
    var suggestedLevel: LevelModel? {
        levels.first { isUnlocked($0) && !isCompleted($0.id) }
    }
}
