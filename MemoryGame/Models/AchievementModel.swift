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
        AchievementModel(id: "first_match", title: "First Match",
                         description: "Complete your first level",
                         icon: "star.fill", requiredStars: 0, requiredLevels: 1),
        AchievementModel(id: "five_levels", title: "Warming Up",
                         description: "Complete 5 levels",
                         icon: "flame.fill", requiredStars: 0, requiredLevels: 5),
        AchievementModel(id: "ten_levels", title: "On a Roll",
                         description: "Complete 10 levels",
                         icon: "bolt.fill", requiredStars: 0, requiredLevels: 10),
        AchievementModel(id: "perfectionist", title: "Perfect!",
                         description: "Earn 3 stars on a level",
                         icon: "checkmark.seal.fill", requiredStars: 0, requiredLevels: 1),
        AchievementModel(id: "rising_star", title: "Rising Star",
                         description: "Earn 25 stars",
                         icon: "star.circle.fill", requiredStars: 25, requiredLevels: 0),
        AchievementModel(id: "twentyfive_levels", title: "Memory Buff",
                         description: "Complete 25 levels",
                         icon: "books.vertical.fill", requiredStars: 0, requiredLevels: 25),
        AchievementModel(id: "star_collector", title: "Star Collector",
                         description: "Earn 100 stars",
                         icon: "sparkles", requiredStars: 100, requiredLevels: 0),
        AchievementModel(id: "perfect_gold", title: "Gold Champion",
                         description: "Earn 3 stars on 15 levels",
                         icon: "crown.fill", requiredStars: 0, requiredLevels: 15),
        AchievementModel(id: "speed_demon", title: "Speed Demon",
                         description: "Finish a timed level under 60 seconds",
                         icon: "stopwatch.fill", requiredStars: 0, requiredLevels: 0),
        AchievementModel(id: "memory_master", title: "Memory Master",
                         description: "Complete every level",
                         icon: "graduationcap.fill", requiredStars: 0,
                         requiredLevels: LevelCatalog.levelCount)
    ]
}

struct DailyChallengeState: Equatable {
    var dateKey: String
    var levelId: String
    var completed: Bool
}
