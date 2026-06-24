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

    func recordCompletion(
        levelId: String,
        stars: Int,
        elapsed: TimeInterval,
        levelWon: Bool = true,
        hasTimer: Bool = false
    ) {
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
            checkAchievements(
                settings: settings,
                lastElapsed: elapsed,
                lastLevelWon: levelWon,
                lastLevelTimed: hasTimer
            )
        }
        save()
    }

    func updateSettings(_ block: (AppSettingsEntity) -> Void) {
        guard let settings else { return }
        block(settings)
        save()
    }

    /// Clears level progress and achievements; keeps sound, appearance, and accessibility settings.
    func resetAllProgress() {
        for entity in levelProgress.values {
            modelContext.delete(entity)
        }
        levelProgress = [:]

        if let settings {
            settings.totalStars = 0
            settings.unlockedAchievementIds = []
            settings.dailyChallengeCompleted = false
            settings.dailyStreak = 0
            settings.lastDailyDate = nil
        }
        save()
    }

    var appearanceMode: AppearanceMode {
        guard let raw = settings?.appearanceModeRaw, !raw.isEmpty,
              let mode = AppearanceMode(rawValue: raw) else {
            return .system
        }
        return mode
    }

    var memorizePreviewEnabled: Bool {
        settings?.memorizePreviewEnabled ?? true
    }

    private func checkAchievements(
        settings: AppSettingsEntity,
        lastElapsed: TimeInterval,
        lastLevelWon: Bool,
        lastLevelTimed: Bool
    ) {
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
            case "memory_master", "half_way":
                earned = completedLevels >= achievement.requiredLevels
            case "speed_demon":
                earned = lastLevelWon && lastLevelTimed && lastElapsed > 0 && lastElapsed < 60
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
