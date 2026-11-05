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

    /// iCloud key-value store, so progress survives a delete + reinstall and
    /// follows the player to other devices on the same Apple ID. A no-op when
    /// iCloud is signed out or the entitlement is missing.
    private let cloud = NSUbiquitousKeyValueStore.default
    private static let cloudKey = "progressSnapshot.v1"
    /// Pushes are held until the first cloud merge, so a fresh install's empty
    /// store can never overwrite the saved snapshot.
    private var cloudReady = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        load()
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.mergeFromCloud() }
        }
        cloud.synchronize()
        cloudReady = true
        mergeFromCloud()
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
        if UserDefaults.standard.bool(forKey: "SCREENSHOT_MODE") { seedForScreenshots() }  // SHOT-TEMP
    }

    // SHOT-TEMP
    private func seedForScreenshots() {
        let starPattern = [3, 3, 2, 3, 3, 3, 2, 3, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3, 3, 2, 3, 3, 3]
        for (index, stars) in starPattern.enumerated() {
            let levelId = "level_\(index + 1)"
            let entity = levelProgress[levelId] ?? {
                let new = LevelProgressEntity(levelId: levelId)
                modelContext.insert(new)
                levelProgress[levelId] = new
                return new
            }()
            entity.stars = stars
            entity.completedCount = max(entity.completedCount, 1)
            entity.fastestTime = Double(18 + index)
            entity.lastPlayed = Date()
        }
        settings?.totalStars = starPattern.reduce(0, +)
        settings?.dailyStreak = 7
        settings?.unlockedAchievementIds = [
            "first_match", "five_levels", "ten_levels", "perfectionist",
            "rising_star", "twentyfive_levels", "speed_demon"
        ]
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
        objectWillChange.send()
        pushToCloud()
    }

    var totalStars: Int { settings?.totalStars ?? 0 }
    var completedLevels: Int { levelProgress.values.filter { $0.completedCount > 0 }.count }
    var goldLevels: Int { levelProgress.values.filter { $0.stars >= 3 }.count }
    var achievementsUnlocked: Int { settings?.unlockedAchievementIds.count ?? 0 }
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
        try? modelContext.save()
        objectWillChange.send()
        // Overwrite rather than merge, or the cloud copy would bring it all back.
        if cloudReady, let data = try? JSONEncoder().encode(localSnapshot()) {
            cloud.set(data, forKey: Self.cloudKey)
        }
    }

    // MARK: - iCloud sync

    private func localSnapshot() -> CloudProgressSnapshot {
        CloudProgressSnapshot(
            levels: levelProgress.mapValues {
                .init(
                    stars: $0.stars,
                    fastestTime: $0.fastestTime,
                    completedCount: $0.completedCount,
                    lastPlayed: $0.lastPlayed,
                    badgeRaw: $0.badgeRaw
                )
            },
            totalStars: settings?.totalStars ?? 0,
            unlockedAchievementIds: (settings?.unlockedAchievementIds ?? []).sorted(),
            dailyStreak: settings?.dailyStreak ?? 0
        )
    }

    private func cloudSnapshot() -> CloudProgressSnapshot? {
        guard let data = cloud.data(forKey: Self.cloudKey) else { return nil }
        return try? JSONDecoder().decode(CloudProgressSnapshot.self, from: data)
    }

    /// Writes local ∪ cloud, so a device that is behind never erases progress
    /// made elsewhere.
    private func pushToCloud() {
        guard cloudReady else { return }
        let local = localSnapshot()
        let remote = cloudSnapshot()
        let merged = remote.map { local.merged(with: $0) } ?? local
        guard !merged.isEmpty, merged != remote,
              let data = try? JSONEncoder().encode(merged) else { return }
        cloud.set(data, forKey: Self.cloudKey)
    }

    /// Pulls the cloud snapshot into SwiftData, keeping the best of each side.
    private func mergeFromCloud() {
        guard let remote = cloudSnapshot() else {
            pushToCloud()
            return
        }
        let local = localSnapshot()
        let merged = local.merged(with: remote)
        guard merged != local else {
            pushToCloud()
            return
        }

        for (levelId, level) in merged.levels {
            let entity = levelProgress[levelId] ?? {
                let new = LevelProgressEntity(levelId: levelId)
                modelContext.insert(new)
                levelProgress[levelId] = new
                return new
            }()
            entity.stars = level.stars
            entity.fastestTime = level.fastestTime
            entity.completedCount = level.completedCount
            entity.lastPlayed = level.lastPlayed
            entity.badgeRaw = level.badgeRaw
        }
        settings?.totalStars = merged.totalStars
        settings?.unlockedAchievementIds = merged.unlockedAchievementIds
        settings?.dailyStreak = merged.dailyStreak

        // A restored player has already been through onboarding.
        if !merged.levels.isEmpty {
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
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
            case "first_match", "five_levels", "ten_levels", "twentyfive_levels", "memory_master":
                earned = completedLevels >= achievement.requiredLevels
            case "rising_star", "star_collector":
                earned = totalStars >= achievement.requiredStars
            case "perfectionist", "perfect_gold":
                earned = goldCount >= achievement.requiredLevels
            case "speed_demon":
                earned = lastLevelWon && lastLevelTimed && lastElapsed > 0 && lastElapsed < 60
            default:
                earned = false
            }
            if earned { unlocked.insert(achievement.id) }
        }
        if unlocked.count > settings.unlockedAchievementIds.count {
            HapticManager.achievement(enabled: settings.hapticsEnabled)
        }
        settings.unlockedAchievementIds = Array(unlocked)
    }
}

/// Compact copy of player progress stored in iCloud KVS (well under the 1 MB
/// per-key limit). Settings like sound and appearance stay per-device.
struct CloudProgressSnapshot: Codable, Equatable {
    struct Level: Codable, Equatable {
        var stars: Int
        var fastestTime: Double?
        var completedCount: Int
        var lastPlayed: Date?
        var badgeRaw: String?
    }

    var levels: [String: Level]
    var totalStars: Int
    var unlockedAchievementIds: [String]
    var dailyStreak: Int

    var isEmpty: Bool { levels.isEmpty && totalStars == 0 && unlockedAchievementIds.isEmpty }

    func merged(with other: CloudProgressSnapshot) -> CloudProgressSnapshot {
        var levels = self.levels
        for (levelId, theirs) in other.levels {
            guard let mine = levels[levelId] else {
                levels[levelId] = theirs
                continue
            }
            let fastest = [mine.fastestTime, theirs.fastestTime].compactMap { $0 }.min()
            let lastPlayed = [mine.lastPlayed, theirs.lastPlayed].compactMap { $0 }.max()
            levels[levelId] = Level(
                stars: max(mine.stars, theirs.stars),
                fastestTime: fastest,
                completedCount: max(mine.completedCount, theirs.completedCount),
                lastPlayed: lastPlayed,
                badgeRaw: theirs.stars > mine.stars ? theirs.badgeRaw : (mine.badgeRaw ?? theirs.badgeRaw)
            )
        }
        return CloudProgressSnapshot(
            levels: levels,
            totalStars: max(totalStars, other.totalStars),
            unlockedAchievementIds: Set(unlockedAchievementIds).union(other.unlockedAchievementIds).sorted(),
            dailyStreak: max(dailyStreak, other.dailyStreak)
        )
    }
}
