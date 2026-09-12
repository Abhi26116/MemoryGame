package com.memogame.app.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.memogame.app.engine.FlipResult
import com.memogame.app.engine.GameEngine
import com.memogame.app.model.CardModel
import com.memogame.app.model.LevelGameRules
import com.memogame.app.model.LevelModel
import com.memogame.app.services.GameAudio
import com.memogame.app.services.HapticManager
import com.memogame.app.services.ProgressStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

enum class GameOverReason { WON, OUT_OF_MOVES, OUT_OF_TIME, OUT_OF_LIVES }

/**
 * Port of the iOS GameViewModel: owns the engine, preview phase, timers,
 * lives and the win/loss flow. All fields are Compose state.
 */
class GameViewModel(
    level: LevelModel,
    private val progressStore: ProgressStore
) {
    companion object {
        /** Extra seconds granted by a rewarded "continue" after an out-of-time loss. */
        private const val CONTINUE_EXTRA_TIME_SECONDS = 20
    }

    var level: LevelModel = level
        private set
    var rules: LevelGameRules = level.gameRules
        private set

    val rows: Int get() = level.gridSize.gridRows
    val columns: Int get() = level.gridSize.gridColumns

    var cards by mutableStateOf<List<CardModel>>(emptyList())
        private set
    var moves by mutableStateOf(0)
        private set
    var matchedPairs by mutableStateOf(0)
        private set
    var totalPairs by mutableStateOf(0)
        private set
    var elapsed by mutableStateOf(0.0)
        private set
    var remainingTime by mutableStateOf(0)
        private set
    var showConfetti by mutableStateOf(false)
    var isPaused by mutableStateOf(false)
    var gameFinished by mutableStateOf(false)
        private set
    var levelWon by mutableStateOf(false)
        private set
    var earnedStars by mutableStateOf(0)
        private set
    var accuracy by mutableStateOf(100)
        private set
    var maxCombo by mutableStateOf(0)
        private set
    var bestTime by mutableStateOf(0.0)
        private set
    var isNewBestTime by mutableStateOf(false)
        private set
    var livesRemaining by mutableStateOf(LevelGameRules.DEFAULT_LIVES)
        private set
    var failReason by mutableStateOf(GameOverReason.WON)
        private set

    var isPreviewPhase by mutableStateOf(false)
        private set
    var previewSecondsLeft by mutableStateOf(0)
        private set
    var canInteract by mutableStateOf(true)
        private set

    val hapticsEnabled: Boolean get() = progressStore.settings.hapticsEnabled
    val accessibilityLargeText: Boolean get() = progressStore.settings.largeText
    val highContrast: Boolean get() = progressStore.settings.highContrast
    val colorBlindMode: Boolean get() = progressStore.settings.colorBlindMode

    val maxLives: Int get() = rules.maxLives
    val livesEnabled: Boolean get() = rules.livesEnabled

    /** Encouraging reason shown on the result screen after a loss (null when won). */
    val lossReasonText: String?
        get() = when (failReason) {
            GameOverReason.WON -> null
            GameOverReason.OUT_OF_LIVES -> "Out of hearts — play again to match all the pairs!"
            GameOverReason.OUT_OF_MOVES -> "Out of moves — play again to match all the pairs!"
            GameOverReason.OUT_OF_TIME -> "Time's up — play again to match all the pairs!"
        }

    private lateinit var engine: GameEngine
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var timerJob: Job? = null
    private var previewJob: Job? = null
    private var startTimeMs = System.currentTimeMillis()

    // Rewarded-ad grants: capped per attempt so watching ads can't turn into
    // free infinite replays or trivially solve the whole board.
    private var hasUsedContinueThisAttempt = false
    var hintsUsedThisAttempt by mutableStateOf(0)
        private set

    /** True while a lost game can still be resumed via a rewarded "continue". */
    val canWatchAdToContinue: Boolean
        get() = gameFinished && !levelWon && !hasUsedContinueThisAttempt

    /**
     * How many rewarded hints this attempt gets, scaled to board size —
     * bigger boards mean more to remember, so they earn more help. Levels
     * 1-8 top out at 2x4 (<=4 pairs); 9-14 are 3x4 (6 pairs); 15+ are 4x4
     * and up (8+ pairs). Matches LevelCatalog's grid-size progression.
     */
    val maxHintsAllowed: Int
        get() = when (level.totalPairsOnBoard) {
            in 0..3 -> 1
            in 4..6 -> 2
            in 7..10 -> 3
            else -> 4
        }

    val hintsRemaining: Int get() = maxOf(0, maxHintsAllowed - hintsUsedThisAttempt)

    /**
     * True while the player has flipped exactly one card themselves and is
     * waiting on its match — a hint only ever resolves the player's OWN
     * pending pick (never picks a fresh pair for them), so it isn't offered
     * until they're actually mid-selection.
     *
     * Reads [cards] so Compose recomposes the hint chip whenever the board
     * selection changes (engine.flippedCount alone is not observable state).
     */
    val canUseHint: Boolean
        get() {
            // Establish a Compose snapshot dependency on the board.
            cards
            return canInteract && !isPreviewPhase && !gameFinished && !isPaused && !moveLimitReached &&
                hintsUsedThisAttempt < maxHintsAllowed && engine.flippedCount == 1
        }

    /**
     * Snapshot the matching partner while the player is mid-selection, before
     * a rewarded ad pauses the board. Returns null if a hint isn't available.
     */
    fun reserveHintPartner(): Int? {
        if (!canUseHint) return null
        return engine.hintPartnerIndex()
    }
    init {
        startGame()
    }

    fun startGame() {
        previewJob?.cancel()
        engine = GameEngine(level, level.gridSize)
        cards = engine.cards
        moves = 0
        matchedPairs = engine.matchedPairs
        totalPairs = engine.totalPairs
        elapsed = 0.0
        gameFinished = false
        levelWon = false
        failReason = GameOverReason.WON
        accuracy = 100
        maxCombo = 0
        bestTime = 0.0
        isNewBestTime = false
        livesRemaining = rules.maxLives
        showConfetti = false
        isPaused = false
        remainingTime = rules.timerSeconds
        hasUsedContinueThisAttempt = false
        hintsUsedThisAttempt = 0

        val previewOn = progressStore.memorizePreviewEnabled
        if (rules.showInitialPreview && previewOn) {
            beginPreviewPhase()
        } else {
            canInteract = true
            isPreviewPhase = false
            startTimeMs = System.currentTimeMillis()
            startGameplayTimer()
        }
    }

    private fun beginPreviewPhase() {
        engine.revealAllCards()
        cards = engine.cards
        isPreviewPhase = true
        canInteract = false
        previewSecondsLeft = rules.previewSeconds

        previewJob = scope.launch {
            // Count down one number per second: 5,4,3,2,1 then conceal.
            for (remaining in (rules.previewSeconds - 1) downTo 1) {
                delay(1000)
                if (!isActive) return@launch
                previewSecondsLeft = remaining
            }
            delay(1000)
            if (!isActive) return@launch
            endPreviewPhase()
        }
    }

    private fun endPreviewPhase() {
        engine.concealAllCards()
        cards = engine.cards
        isPreviewPhase = false
        previewSecondsLeft = 0
        canInteract = true
        startTimeMs = System.currentTimeMillis()
        startGameplayTimer()
    }

    private fun startGameplayTimer() {
        timerJob?.cancel()
        timerJob = scope.launch {
            while (isActive) {
                delay(1000)
                if (isPaused || gameFinished || isPreviewPhase) continue
                elapsed = (System.currentTimeMillis() - startTimeMs) / 1000.0
                if (rules.hasTimer && remainingTime > 0) {
                    remainingTime -= 1
                    if (remainingTime == 0) finishGame(GameOverReason.OUT_OF_TIME)
                }
            }
        }
    }

    fun tapCard(index: Int) {
        if (!canInteract || isPreviewPhase || gameFinished || isPaused) return
        if (moveLimitReached) return

        val result = engine.flipCard(index)
        cards = engine.cards
        moves = engine.moves
        matchedPairs = engine.matchedPairs

        if (!rules.hasTimer) {
            elapsed = (System.currentTimeMillis() - startTimeMs) / 1000.0
        }

        when (result) {
            FlipResult.Ignored -> Unit
            FlipResult.Waiting -> {
                GameAudio.playFlip()
                HapticManager.cardFlip(hapticsEnabled)
            }
            is FlipResult.Match -> {
                GameAudio.playSuccess()
                HapticManager.match(hapticsEnabled)
                if (engine.isComplete) finishGame() else endIfOutOfMoves()
            }
            is FlipResult.Mismatch -> {
                GameAudio.playMismatch()
                if (livesEnabled) {
                    livesRemaining = maxOf(0, livesRemaining - 1)
                    HapticManager.lifeLost(hapticsEnabled)
                } else {
                    HapticManager.mismatch(hapticsEnabled)
                }
                engine.markShaking(result.indices)
                cards = engine.cards
                scope.launch {
                    delay(700)
                    engine.hideMismatch(result.indices)
                    cards = engine.cards
                    if (livesEnabled && livesRemaining == 0) {
                        finishGame(GameOverReason.OUT_OF_LIVES)
                    } else {
                        endIfOutOfMoves()
                    }
                }
            }
            FlipResult.LevelComplete -> {
                GameAudio.playSuccess()
                HapticManager.match(hapticsEnabled)
                finishGame()
            }
        }
    }

    private val moveLimitReached: Boolean
        get() {
            val max = rules.maxMoves ?: return false
            return rules.hasMoveLimit && moves >= max
        }

    private fun endIfOutOfMoves() {
        if (!moveLimitReached || engine.isComplete) return
        finishGame(GameOverReason.OUT_OF_MOVES)
    }

    private fun finishGame(reason: GameOverReason = GameOverReason.WON) {
        if (gameFinished) return
        gameFinished = true
        canInteract = false
        levelWon = engine.isComplete
        failReason = if (levelWon) GameOverReason.WON else reason
        previewJob?.cancel()
        timerJob?.cancel()
        if (!rules.hasTimer) {
            elapsed = (System.currentTimeMillis() - startTimeMs) / 1000.0
        }
        earnedStars = engine.calculateStars()
        maxCombo = engine.maxCombo
        accuracy = if (moves > 0) {
            (matchedPairs.toDouble() / moves.toDouble() * 100).roundToInt()
        } else 100
        showConfetti = levelWon
        if (levelWon) {
            GameAudio.playComplete()
            HapticManager.levelComplete(hapticsEnabled)
        } else {
            GameAudio.playMismatch()
            HapticManager.levelFailed(hapticsEnabled)
        }
        // Only a win counts as completing the level — a loss records nothing,
        // so it can't unlock the next level or inflate progress.
        if (levelWon) {
            val previousBest = progressStore.progress(level.id)?.fastestTime
            isNewBestTime = previousBest == null || elapsed < previousBest
            progressStore.recordCompletion(
                levelId = level.id,
                stars = earnedStars,
                elapsedSeconds = elapsed,
                levelWon = true,
                hasTimer = rules.hasTimer,
                onAchievementUnlocked = { HapticManager.achievement(hapticsEnabled) }
            )
            bestTime = progressStore.progress(level.id)?.fastestTime ?: elapsed
        }
    }

    /**
     * Called once a rewarded ad grants a continue: resumes the SAME board
     * (matched pairs stay matched) instead of restarting the level.
     */
    fun continueAfterAd() {
        if (!canWatchAdToContinue) return
        hasUsedContinueThisAttempt = true
        when (failReason) {
            GameOverReason.OUT_OF_LIVES -> livesRemaining = maxOf(livesRemaining, 1)
            GameOverReason.OUT_OF_TIME -> remainingTime = maxOf(remainingTime, CONTINUE_EXTRA_TIME_SECONDS)
            else -> Unit
        }
        gameFinished = false
        showConfetti = false
        canInteract = true
        // Keep elapsed continuous across the pause rather than jumping.
        startTimeMs = System.currentTimeMillis() - (elapsed * 1000).toLong()
        startGameplayTimer()
    }

    /**
     * Called once a rewarded ad grants a hint: completes the pair/group the
     * player has ALREADY started selecting themselves — the ad never picks a
     * fresh pair for them, it only resolves their own pending pick, and it
     * plays out through the exact same [tapCard] flow a real tap would
     * (still counts as a move, still runs the normal win/combo/lives logic;
     * it can never mismatch since the partner is the correct one by
     * construction).
     *
     * Prefer passing the [partnerIndex] reserved before the ad started —
     * Android fires the reward callback while the ad activity is still up
     * (and the game is paused), so re-checking [canUseHint] at that moment
     * would incorrectly no-op. Apply this after the ad closes.
     */
    fun revealHint(partnerIndex: Int? = null) {
        if (hintsUsedThisAttempt >= maxHintsAllowed) return
        if (gameFinished || isPreviewPhase || !canInteract) return
        val target = partnerIndex ?: engine.hintPartnerIndex() ?: return
        if (target !in cards.indices) return
        val partner = cards[target]
        if (partner.isMatched || partner.isFaceUp) return
        // Still must be mid-selection on exactly one card (the player's pick).
        if (engine.flippedCount != 1) return

        hintsUsedThisAttempt += 1
        // Ad flow pauses the game; clear pause so tapCard isn't ignored.
        isPaused = false
        tapCard(target)
    }
    fun reset() {
        previewJob?.cancel()
        timerJob?.cancel()
        startGame()
    }

    fun loadLevel(newLevel: LevelModel) {
        level = newLevel
        rules = newLevel.gameRules
        previewJob?.cancel()
        timerJob?.cancel()
        startGame()
    }

    fun dispose() {
        scope.cancel()
    }
}
