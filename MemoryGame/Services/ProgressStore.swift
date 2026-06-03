//
//  ProgressStore.swift
//  Memory Match Kids
//

import Combine
import Foundation
import SwiftData

@MainActor
final class ProgressStore: ObservableObject {
    private let modelContext: ModelContext

    @Published private(set) var settings: AppSettingsEntity?
    @Published private(set) var levelProgress: [String: LevelProgressEntity] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        load()
    }

    func load() {
        let settingsDescriptor = FetchDescriptor<AppSettingsEntity>()
        if let existing = try? modelContext.fetch(settingsDescriptor).first {
            settings = existing
        } else {
            let newSettings = AppSettingsEntity()
            modelContext.insert(newSettings)
            settings = newSettings
            save()
        }

        let progressDescriptor = FetchDescriptor<LevelProgressEntity>()
        let all = (try? modelContext.fetch(progressDescriptor)) ?? []
        levelProgress = Dictionary(uniqueKeysWithValues: all.map { ($0.levelId, $0) })
    }

    func save() {
        try? modelContext.save()
        objectWillChange.send()
    }

    var totalStars: Int { settings?.totalStars ?? 0 }
    var completedLevels: Int { levelProgress.values.filter { $0.completedCount > 0 }.count }
    var dailyStreak: Int { settings?.dailyStreak ?? 0 }

    func progress(for levelId: String) -> LevelProgressEntity? {
        levelProgress[levelId]
    }

    func recordCompletion(levelId: String, stars: Int, score: Int, elapsed: TimeInterval) {
        let entity: LevelProgressEntity
        if let existing = levelProgress[levelId] {
            entity = existing
        } else {
            entity = LevelProgressEntity(levelId: levelId)
            modelContext.insert(entity)
            levelProgress[levelId] = entity
        }

        entity.completedCount += 1
        entity.stars = max(entity.stars, stars)
        entity.bestScore = max(entity.bestScore, score)
        if let fastest = entity.fastestTime {
            entity.fastestTime = min(fastest, elapsed)
        } else {
            entity.fastestTime = elapsed
        }
        entity.lastPlayed = Date()
        if let badge = BadgeTier.forStars(stars) {
            entity.badgeRaw = badge.rawValue
        }

        if let settings {
            settings.totalStars += stars
            checkAchievements(settings: settings)
        }
        save()
    }

    func updateSettings(_ block: (AppSettingsEntity) -> Void) {
        guard let settings else { return }
        block(settings)
        save()
    }

    private func checkAchievements(settings: AppSettingsEntity) {
        var unlocked = Set(settings.unlockedAchievementIds)
        let goldCount = levelProgress.values.filter { $0.stars >= 3 }.count
        for achievement in AchievementModel.catalog {
            if unlocked.contains(achievement.id) { continue }
            let earned: Bool
            switch achievement.id {
            case "first_match":
                earned = completedLevels >= 1
            case "star_collector":
                earned = totalStars >= achievement.requiredStars
            case "memory_master":
                earned = completedLevels >= achievement.requiredLevels
            case "half_way":
                earned = completedLevels >= 25
            case "perfect_gold":
                earned = goldCount >= achievement.requiredLevels
            default:
                earned = false
            }
            if earned { unlocked.insert(achievement.id) }
        }
        settings.unlockedAchievementIds = Array(unlocked)
    }
}
