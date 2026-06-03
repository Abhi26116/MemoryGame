//
//  ProgressViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
    }

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

    func badge(for levelId: String) -> BadgeTier? {
        progressStore.progress(for: levelId)?.badge
    }

    var achievements: [(AchievementModel, Bool)] {
        let unlocked = Set(progressStore.settings?.unlockedAchievementIds ?? [])
        return AchievementModel.catalog.map { ($0, unlocked.contains($0.id)) }
    }

    var goldCount: Int {
        progressStore.levelProgress.values.filter { $0.stars >= 3 }.count
    }
}
