//
//  SwiftDataModels.swift
//  Memory Match Kids
//

import Foundation
import SwiftData

@Model
final class LevelProgressEntity {
    @Attribute(.unique) var levelId: String
    var stars: Int
    var fastestTime: Double?
    var completedCount: Int
    var lastPlayed: Date?
    var badgeRaw: String?

    init(
        levelId: String,
        stars: Int = 0,
        fastestTime: Double? = nil,
        completedCount: Int = 0,
        lastPlayed: Date? = nil,
        badgeRaw: String? = nil
    ) {
        self.levelId = levelId
        self.stars = stars
        self.fastestTime = fastestTime
        self.completedCount = completedCount
        self.lastPlayed = lastPlayed
        self.badgeRaw = badgeRaw
    }

    var badge: BadgeTier? {
        guard let badgeRaw else { return nil }
        return BadgeTier(rawValue: badgeRaw)
    }
}

@Model
final class AppSettingsEntity {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var highContrast: Bool
    var colorBlindMode: Bool
    var largeText: Bool
    var appearanceModeRaw: String
    var memorizePreviewEnabled: Bool
    var dailyStreak: Int
    var lastDailyDate: String?
    var totalStars: Int
    var dailyChallengeCompleted: Bool
    var dailyChallengeLevelId: String?
    var dailyChallengeDateKey: String?
    var unlockedAchievementIds: [String]

    init(
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        highContrast: Bool = false,
        colorBlindMode: Bool = false,
        largeText: Bool = false,
        appearanceModeRaw: String = AppearanceMode.system.rawValue,
        memorizePreviewEnabled: Bool = true,
        dailyStreak: Int = 0,
        lastDailyDate: String? = nil,
        totalStars: Int = 0,
        dailyChallengeCompleted: Bool = false,
        dailyChallengeLevelId: String? = nil,
        dailyChallengeDateKey: String? = nil,
        unlockedAchievementIds: [String] = []
    ) {
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.highContrast = highContrast
        self.colorBlindMode = colorBlindMode
        self.largeText = largeText
        self.appearanceModeRaw = appearanceModeRaw
        self.memorizePreviewEnabled = memorizePreviewEnabled
        self.dailyStreak = dailyStreak
        self.lastDailyDate = lastDailyDate
        self.totalStars = totalStars
        self.dailyChallengeCompleted = dailyChallengeCompleted
        self.dailyChallengeLevelId = dailyChallengeLevelId
        self.dailyChallengeDateKey = dailyChallengeDateKey
        self.unlockedAchievementIds = unlockedAchievementIds
    }
}
