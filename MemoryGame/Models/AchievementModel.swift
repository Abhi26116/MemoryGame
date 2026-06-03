//
//  AchievementModel.swift
//  Memory Match Kids
//

import Foundation

struct AchievementModel: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requiredStars: Int
    let requiredLevels: Int
}

extension AchievementModel {
    static let catalog: [AchievementModel] = [
        AchievementModel(
            id: "first_match",
            title: "First Match",
            description: "Complete your first level",
            icon: "star.fill",
            requiredStars: 0,
            requiredLevels: 1
        ),
        AchievementModel(
            id: "star_collector",
            title: "Star Collector",
            description: "Earn 100 stars total",
            icon: "sparkles",
            requiredStars: 100,
            requiredLevels: 0
        ),
        AchievementModel(
            id: "memory_master",
            title: "Memory Master",
            description: "Complete 25 levels",
            icon: "brain.head.profile",
            requiredStars: 0,
            requiredLevels: 25
        ),
        AchievementModel(
            id: "half_way",
            title: "Halfway Hero",
            description: "Reach level 25",
            icon: "flag.fill",
            requiredStars: 0,
            requiredLevels: 0
        ),
        AchievementModel(
            id: "speed_demon",
            title: "Speed Demon",
            description: "Finish a hard level under 60 seconds",
            icon: "bolt.fill",
            requiredStars: 0,
            requiredLevels: 0
        ),
        AchievementModel(
            id: "perfect_gold",
            title: "Gold Champion",
            description: "Earn 3 stars on 15 levels",
            icon: "crown.fill",
            requiredStars: 0,
            requiredLevels: 15
        )
    ]
}

struct LevelProgressRecord: Identifiable, Equatable {
    var id: String { levelId }
    let levelId: String
    var stars: Int
    var bestScore: Int
    var fastestTime: TimeInterval?
    var completedCount: Int
    var lastBadge: BadgeTier?
}

struct DailyChallengeState: Equatable {
    var dateKey: String
    var levelId: String
    var completed: Bool
}
