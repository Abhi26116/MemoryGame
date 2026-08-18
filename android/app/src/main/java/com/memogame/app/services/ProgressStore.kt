package com.memogame.app.services

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.memogame.app.model.AchievementModel
import com.memogame.app.model.AppSettings
import com.memogame.app.model.AppearanceMode
import com.memogame.app.model.BadgeTier
import com.memogame.app.model.CardBackStyle
import com.memogame.app.model.LevelProgress
import org.json.JSONArray
import org.json.JSONObject

/**
 * Single source of truth for player progress + settings, persisted as JSON in
 * SharedPreferences (the Android stand-in for the iOS SwiftData store). All
 * fields are Compose state so screens recompose the moment anything changes.
 */
class ProgressStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("memory_game_store", Context.MODE_PRIVATE)

    var settings by mutableStateOf(loadSettings())
        private set

    val levelProgress = mutableStateMapOf<String, LevelProgress>()

    // iOS @AppStorage equivalents (val + backing state so the explicit setXxx
    // functions below don't clash with generated JVM setters)
    private val hasSeenWelcomeState = mutableStateOf(prefs.getBoolean("hasSeenWelcome", false))
    val hasSeenWelcome: Boolean get() = hasSeenWelcomeState.value

    private val hasSeenRemoveAdsPromptState = mutableStateOf(prefs.getBoolean("hasSeenRemoveAdsPrompt", false))
    val hasSeenRemoveAdsPrompt: Boolean get() = hasSeenRemoveAdsPromptState.value

    private val hasSeenTutorialState = mutableStateOf(prefs.getBoolean("hasSeenTutorial", false))
    val hasSeenTutorial: Boolean get() = hasSeenTutorialState.value

    /** Defaults to on: reminders are opt-out, not opt-in. */
    private val remindersEnabledState = mutableStateOf(prefs.getBoolean("remindersEnabled", true))
    val remindersEnabled: Boolean get() = remindersEnabledState.value

    private val cardBackStyleState = mutableStateOf(CardBackStyle.fromRaw(prefs.getString("cardBackStyle", null)))
    val cardBackStyle: CardBackStyle get() = cardBackStyleState.value

    init {
        loadProgress()
    }

    // MARK: - Derived stats

    val totalStars: Int get() = settings.totalStars
    val completedLevels: Int get() = levelProgress.values.count { it.completedCount > 0 }
    val goldLevels: Int get() = levelProgress.values.count { it.stars >= 3 }
    val achievementsUnlocked: Int get() = settings.unlockedAchievementIds.size
    val appearanceMode: AppearanceMode get() = settings.appearanceMode
    val memorizePreviewEnabled: Boolean get() = settings.memorizePreviewEnabled

    fun progress(levelId: String): LevelProgress? = levelProgress[levelId]

    // MARK: - Mutations

    fun recordCompletion(
        levelId: String,
        stars: Int,
        elapsedSeconds: Double,
        levelWon: Boolean = true,
        hasTimer: Boolean = false,
        onAchievementUnlocked: () -> Unit = {}
    ) {
        val existing = levelProgress[levelId] ?: LevelProgress(levelId)
        val updated = existing.copy(
            completedCount = existing.completedCount + 1,
            stars = maxOf(existing.stars, stars),
            fastestTime = existing.fastestTime?.let { minOf(it, elapsedSeconds) } ?: elapsedSeconds,
            lastPlayed = System.currentTimeMillis(),
            badgeRaw = BadgeTier.forStars(stars)?.rawValue ?: existing.badgeRaw
        )
        levelProgress[levelId] = updated

        settings = settings.copy(totalStars = settings.totalStars + stars)
        checkAchievements(
            lastElapsed = elapsedSeconds,
            lastLevelWon = levelWon,
            lastLevelTimed = hasTimer,
            onAchievementUnlocked = onAchievementUnlocked
        )
        save()
    }

    fun updateSettings(block: (AppSettings) -> AppSettings) {
        settings = block(settings)
        save()
    }

    /** Clears level progress and achievements; keeps sound, appearance, accessibility. */
    fun resetAllProgress() {
        levelProgress.clear()
        settings = settings.copy(totalStars = 0, unlockedAchievementIds = emptySet())
        save()
    }

    fun setHasSeenWelcome(value: Boolean) {
        hasSeenWelcomeState.value = value
        prefs.edit().putBoolean("hasSeenWelcome", value).apply()
    }

    fun setHasSeenRemoveAdsPrompt(value: Boolean) {
        hasSeenRemoveAdsPromptState.value = value
        prefs.edit().putBoolean("hasSeenRemoveAdsPrompt", value).apply()
    }

    fun setHasSeenTutorial(value: Boolean) {
        hasSeenTutorialState.value = value
        prefs.edit().putBoolean("hasSeenTutorial", value).apply()
    }

    fun setRemindersEnabled(value: Boolean) {
        remindersEnabledState.value = value
        prefs.edit().putBoolean("remindersEnabled", value).apply()
    }

    fun setCardBackStyle(style: CardBackStyle) {
        cardBackStyleState.value = style
        prefs.edit().putString("cardBackStyle", style.rawValue).apply()
    }

    // MARK: - Achievements

    private fun checkAchievements(
        lastElapsed: Double,
        lastLevelWon: Boolean,
        lastLevelTimed: Boolean,
        onAchievementUnlocked: () -> Unit
    ) {
        val unlocked = settings.unlockedAchievementIds.toMutableSet()
        val goldCount = levelProgress.values.count { it.stars >= 3 }
        for (achievement in AchievementModel.catalog) {
            if (achievement.id in unlocked) continue
            val earned = when (achievement.id) {
                "first_match", "five_levels", "ten_levels", "twentyfive_levels", "memory_master" ->
                    completedLevels >= achievement.requiredLevels
                "rising_star", "star_collector" ->
                    settings.totalStars >= achievement.requiredStars
                "perfectionist", "perfect_gold" ->
                    goldCount >= achievement.requiredLevels
                "speed_demon" ->
                    lastLevelWon && lastLevelTimed && lastElapsed > 0 && lastElapsed < 60
                else -> false
            }
            if (earned) unlocked.add(achievement.id)
        }
        if (unlocked.size > settings.unlockedAchievementIds.size) {
            onAchievementUnlocked()
        }
        settings = settings.copy(unlockedAchievementIds = unlocked)
    }

    // MARK: - Persistence

    private fun save() {
        val settingsJson = JSONObject().apply {
            put("soundEnabled", settings.soundEnabled)
            put("hapticsEnabled", settings.hapticsEnabled)
            put("highContrast", settings.highContrast)
            put("colorBlindMode", settings.colorBlindMode)
            put("largeText", settings.largeText)
            put("appearanceModeRaw", settings.appearanceModeRaw)
            put("memorizePreviewEnabled", settings.memorizePreviewEnabled)
            put("totalStars", settings.totalStars)
            put("unlockedAchievementIds", JSONArray(settings.unlockedAchievementIds.toList()))
        }

        val progressJson = JSONObject()
        for ((levelId, progress) in levelProgress) {
            progressJson.put(levelId, JSONObject().apply {
                put("stars", progress.stars)
                progress.fastestTime?.let { put("fastestTime", it) }
                put("completedCount", progress.completedCount)
                progress.lastPlayed?.let { put("lastPlayed", it) }
                progress.badgeRaw?.let { put("badgeRaw", it) }
            })
        }

        prefs.edit()
            .putString("settings", settingsJson.toString())
            .putString("levelProgress", progressJson.toString())
            .apply()
    }

    private fun loadSettings(): AppSettings {
        val raw = prefs.getString("settings", null) ?: return AppSettings()
        return try {
            val json = JSONObject(raw)
            val ids = mutableSetOf<String>()
            val array = json.optJSONArray("unlockedAchievementIds") ?: JSONArray()
            for (i in 0 until array.length()) ids.add(array.getString(i))
            AppSettings(
                soundEnabled = json.optBoolean("soundEnabled", true),
                hapticsEnabled = json.optBoolean("hapticsEnabled", true),
                highContrast = json.optBoolean("highContrast", false),
                colorBlindMode = json.optBoolean("colorBlindMode", false),
                largeText = json.optBoolean("largeText", false),
                appearanceModeRaw = json.optString("appearanceModeRaw", AppearanceMode.SYSTEM.rawValue),
                memorizePreviewEnabled = json.optBoolean("memorizePreviewEnabled", true),
                totalStars = json.optInt("totalStars", 0),
                unlockedAchievementIds = ids
            )
        } catch (_: Exception) {
            AppSettings()
        }
    }

    private fun loadProgress() {
        val raw = prefs.getString("levelProgress", null) ?: return
        try {
            val json = JSONObject(raw)
            for (levelId in json.keys()) {
                val entry = json.getJSONObject(levelId)
                levelProgress[levelId] = LevelProgress(
                    levelId = levelId,
                    stars = entry.optInt("stars", 0),
                    fastestTime = if (entry.has("fastestTime")) entry.getDouble("fastestTime") else null,
                    completedCount = entry.optInt("completedCount", 0),
                    lastPlayed = if (entry.has("lastPlayed")) entry.getLong("lastPlayed") else null,
                    badgeRaw = entry.optString("badgeRaw", "").ifEmpty { null }
                )
            }
        } catch (_: Exception) {
            // Corrupt store — start fresh rather than crash (mirrors the iOS
            // ModelContainerFactory reset-and-retry behaviour).
            levelProgress.clear()
        }
    }
}
