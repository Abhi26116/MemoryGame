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
        AchievementModel(id: "first_match", title: tr("First Match"),
                         description: tr("Complete your first level"),
                         icon: "star.fill", requiredStars: 0, requiredLevels: 1),
        AchievementModel(id: "five_levels", title: tr("Warming Up"),
                         description: tr("Complete 5 levels"),
                         icon: "flame.fill", requiredStars: 0, requiredLevels: 5),
        AchievementModel(id: "ten_levels", title: tr("On a Roll"),
                         description: tr("Complete 10 levels"),
                         icon: "bolt.fill", requiredStars: 0, requiredLevels: 10),
        AchievementModel(id: "perfectionist", title: tr("Perfect!"),
                         description: tr("Earn 3 stars on a level"),
                         icon: "checkmark.seal.fill", requiredStars: 0, requiredLevels: 1),
        AchievementModel(id: "rising_star", title: tr("Rising Star"),
                         description: tr("Earn 25 stars"),
                         icon: "star.circle.fill", requiredStars: 25, requiredLevels: 0),
        AchievementModel(id: "twentyfive_levels", title: tr("Memory Buff"),
                         description: tr("Complete 25 levels"),
                         icon: "books.vertical.fill", requiredStars: 0, requiredLevels: 25),
        AchievementModel(id: "star_collector", title: tr("Star Collector"),
                         description: tr("Earn 100 stars"),
                         icon: "sparkles", requiredStars: 100, requiredLevels: 0),
        AchievementModel(id: "perfect_gold", title: tr("Gold Champion"),
                         description: tr("Earn 3 stars on 15 levels"),
                         icon: "crown.fill", requiredStars: 0, requiredLevels: 15),
        AchievementModel(id: "speed_demon", title: tr("Speed Demon"),
                         description: tr("Finish a timed level under 60 seconds"),
                         icon: "stopwatch.fill", requiredStars: 0, requiredLevels: 0),
        AchievementModel(id: "memory_master", title: tr("Memory Master"),
                         description: tr("Complete every level"),
                         icon: "graduationcap.fill", requiredStars: 0,
                         requiredLevels: LevelCatalog.levelCount)
    ]
}

struct DailyChallengeState: Equatable {
    var dateKey: String
    var levelId: String
    var completed: Bool
}
