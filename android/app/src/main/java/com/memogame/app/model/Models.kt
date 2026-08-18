package com.memogame.app.model

import java.util.UUID

data class CardContent(
    val id: String,
    val label: String,
    val emoji: String? = null,
    val accentColorHex: String = "5B8DEF"
)

data class CardModel(
    val uid: String = UUID.randomUUID().toString(),
    val content: CardContent,
    val pairId: String,
    val matchingPairId: String = pairId,
    val groupId: String? = null,
    val isFaceUp: Boolean = false,
    val isMatched: Boolean = false,
    val isShaking: Boolean = false
)

data class LevelPairDefinition(
    val id: String,
    val left: CardContent,
    val right: CardContent,
    val groupId: String?
)

data class LevelGameRules(
    val showsMoveCounter: Boolean,
    val hasTimer: Boolean,
    val timerSeconds: Int,
    val maxMoves: Int?,
    val showInitialPreview: Boolean,
    val previewSeconds: Int,
    val maxLives: Int = DEFAULT_LIVES
) {
    val hasMoveLimit: Boolean get() = maxMoves != null
    val livesEnabled: Boolean get() = maxLives > 0

    companion object {
        const val DEFAULT_PREVIEW_SECONDS = 5
        const val DEFAULT_LIVES = 3
    }
}

data class LevelModel(
    val id: String,
    val levelNumber: Int,
    val title: String,
    val subtitle: String,
    val objective: String,
    val matchMode: MatchMode,
    val gridSize: GridSize,
    val gameRules: LevelGameRules,
    val pairs: List<LevelPairDefinition>
) {
    val totalPairsOnBoard: Int
        get() {
            val slots = gridSize.gridRows * gridSize.gridColumns
            return if (matchMode == MatchMode.TRIPLE) maxOf(1, slots / 3) else maxOf(1, slots / 2)
        }
}

data class LevelProgress(
    val levelId: String,
    val stars: Int = 0,
    val fastestTime: Double? = null,
    val completedCount: Int = 0,
    val lastPlayed: Long? = null,
    val badgeRaw: String? = null
) {
    val badge: BadgeTier? get() = BadgeTier.fromRaw(badgeRaw)
}

data class AppSettings(
    val soundEnabled: Boolean = true,
    val hapticsEnabled: Boolean = true,
    val highContrast: Boolean = false,
    val colorBlindMode: Boolean = false,
    val largeText: Boolean = false,
    val appearanceModeRaw: String = AppearanceMode.SYSTEM.rawValue,
    val memorizePreviewEnabled: Boolean = true,
    val totalStars: Int = 0,
    val unlockedAchievementIds: Set<String> = emptySet()
) {
    val appearanceMode: AppearanceMode get() = AppearanceMode.fromRaw(appearanceModeRaw)
}
