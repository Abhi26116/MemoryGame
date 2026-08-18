package com.memogame.app.model

import com.memogame.app.data.LevelCatalog

data class AchievementModel(
    val id: String,
    val title: String,
    val description: String,
    val icon: String,
    val requiredStars: Int,
    val requiredLevels: Int
) {
    companion object {
        val catalog: List<AchievementModel> = listOf(
            AchievementModel(
                "first_match", "First Match", "Complete your first level",
                "star", 0, 1
            ),
            AchievementModel(
                "five_levels", "Warming Up", "Complete 5 levels",
                "flame", 0, 5
            ),
            AchievementModel(
                "ten_levels", "On a Roll", "Complete 10 levels",
                "bolt", 0, 10
            ),
            AchievementModel(
                "perfectionist", "Perfect!", "Earn 3 stars on a level",
                "seal", 0, 1
            ),
            AchievementModel(
                "rising_star", "Rising Star", "Earn 25 stars",
                "star_circle", 25, 0
            ),
            AchievementModel(
                "twentyfive_levels", "Memory Buff", "Complete 25 levels",
                "books", 0, 25
            ),
            AchievementModel(
                "star_collector", "Star Collector", "Earn 100 stars",
                "sparkles", 100, 0
            ),
            AchievementModel(
                "perfect_gold", "Gold Champion", "Earn 3 stars on 15 levels",
                "crown", 0, 15
            ),
            AchievementModel(
                "speed_demon", "Speed Demon", "Finish a timed level under 60 seconds",
                "stopwatch", 0, 0
            ),
            AchievementModel(
                "memory_master", "Memory Master", "Complete every level",
                "graduation", 0, LevelCatalog.LEVEL_COUNT
            )
        )
    }
}
