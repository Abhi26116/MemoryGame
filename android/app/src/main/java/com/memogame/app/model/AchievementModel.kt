package com.memogame.app.model

import com.memogame.app.core.tr
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
                "first_match", tr("First Match"), tr("Complete your first level"),
                "star", 0, 1
            ),
            AchievementModel(
                "five_levels", tr("Warming Up"), tr("Complete 5 levels"),
                "flame", 0, 5
            ),
            AchievementModel(
                "ten_levels", tr("On a Roll"), tr("Complete 10 levels"),
                "bolt", 0, 10
            ),
            AchievementModel(
                "perfectionist", tr("Perfect!"), tr("Earn 3 stars on a level"),
                "seal", 0, 1
            ),
            AchievementModel(
                "rising_star", tr("Rising Star"), tr("Earn 25 stars"),
                "star_circle", 25, 0
            ),
            AchievementModel(
                "twentyfive_levels", tr("Memory Buff"), tr("Complete 25 levels"),
                "books", 0, 25
            ),
            AchievementModel(
                "star_collector", tr("Star Collector"), tr("Earn 100 stars"),
                "sparkles", 100, 0
            ),
            AchievementModel(
                "perfect_gold", tr("Gold Champion"), tr("Earn 3 stars on 15 levels"),
                "crown", 0, 15
            ),
            AchievementModel(
                "speed_demon", tr("Speed Demon"), tr("Finish a timed level under 60 seconds"),
                "stopwatch", 0, 0
            ),
            AchievementModel(
                "memory_master", tr("Memory Master"), tr("Complete every level"),
                "graduation", 0, LevelCatalog.LEVEL_COUNT
            )
        )
    }
}
