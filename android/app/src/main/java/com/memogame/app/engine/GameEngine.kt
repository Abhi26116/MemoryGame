package com.memogame.app.engine

import com.memogame.app.model.CardModel
import com.memogame.app.model.GridSize
import com.memogame.app.model.LevelModel
import com.memogame.app.model.MatchMode

sealed class FlipResult {
    data object Ignored : FlipResult()
    data object Waiting : FlipResult()
    data class Match(val indices: List<Int>) : FlipResult()
    data class Mismatch(val indices: List<Int>) : FlipResult()
    data object LevelComplete : FlipResult()
}

object StarRatingRules {
    const val TWO_STAR_EXTRA_MOVES = 5

    fun movesForThreeStars(totalPairs: Int): Int = maxOf(1, totalPairs)

    fun movesForTwoStars(totalPairs: Int): Int =
        movesForThreeStars(totalPairs) + TWO_STAR_EXTRA_MOVES

    fun stars(moves: Int, matchedPairs: Int, totalPairs: Int, levelComplete: Boolean): Int {
        if (!levelComplete) return if (matchedPairs > 0) 1 else 0
        val pairs = maxOf(1, totalPairs)
        if (moves <= movesForThreeStars(pairs)) return 3
        if (moves <= movesForTwoStars(pairs)) return 2
        return 1
    }
}

class GameEngine(val level: LevelModel, val gridSize: GridSize) {
    private val cardList = mutableListOf<CardModel>()

    /**
     * Snapshot copy — callers hold this in Compose state, so it must be a NEW
     * list instance on every read or recomposition never sees mutations.
     */
    val cards: List<CardModel> get() = cardList.toList()

    private val flippedIndices = mutableListOf<Int>()

    /** How many cards are currently selected mid-match-check (0, 1, or up to [selectionLimit]). */
    val flippedCount: Int get() = flippedIndices.size

    var moves = 0; private set
    var matchedPairs = 0; private set
    var totalPairs = 0; private set

    /** Longest run of consecutive matches without a mismatch. */
    var maxCombo = 0; private set
    private var currentCombo = 0

    private val strategy: MatchStrategy = MatchStrategyFactory.strategy(level.matchMode)

    val isComplete: Boolean get() = matchedPairs >= totalPairs
    val selectionLimit: Int get() = strategy.requiredSelectionCount

    init {
        buildDeck()
    }

    fun buildDeck() {
        val slotCount = gridSize.gridRows * gridSize.gridColumns
        val deck = mutableListOf<CardModel>()

        when (level.matchMode) {
            MatchMode.TRIPLE -> {
                for (pair in level.pairs) {
                    val group = pair.groupId ?: pair.id
                    repeat(3) {
                        deck.add(
                            CardModel(
                                content = pair.left,
                                pairId = pair.id,
                                matchingPairId = group,
                                groupId = group
                            )
                        )
                    }
                }
            }
            MatchMode.IDENTICAL, MatchMode.ASSOCIATION -> {
                for (pair in level.pairs) {
                    val group = pair.groupId ?: pair.id
                    deck.add(
                        CardModel(
                            content = pair.left,
                            pairId = pair.id,
                            matchingPairId = group,
                            groupId = group
                        )
                    )
                    deck.add(
                        CardModel(
                            content = pair.right,
                            pairId = pair.id,
                            matchingPairId = group,
                            groupId = group
                        )
                    )
                }
            }
        }

        cardList.clear()
        cardList.addAll(deck.take(slotCount).shuffled())
        flippedIndices.clear()
        moves = 0
        matchedPairs = 0
        maxCombo = 0
        currentCombo = 0

        totalPairs = when (level.matchMode) {
            MatchMode.TRIPLE -> maxOf(1, slotCount / 3)
            else -> maxOf(1, slotCount / 2)
        }
    }

    fun revealAllCards() {
        for (i in cardList.indices) {
            if (!cardList[i].isMatched) cardList[i] = cardList[i].copy(isFaceUp = true)
        }
    }

    fun concealAllCards() {
        for (i in cardList.indices) {
            if (!cardList[i].isMatched) cardList[i] = cardList[i].copy(isFaceUp = false)
        }
        flippedIndices.clear()
    }

    fun canFlip(index: Int): Boolean {
        val card = cardList.getOrNull(index) ?: return false
        if (card.isMatched || card.isFaceUp) return false
        if (flippedIndices.size >= selectionLimit) return false
        return true
    }

    fun flipCard(index: Int): FlipResult {
        if (!canFlip(index)) return FlipResult.Ignored

        cardList[index] = cardList[index].copy(isFaceUp = true)
        flippedIndices.add(index)

        if (flippedIndices.size < selectionLimit) return FlipResult.Waiting

        moves += 1
        val selected = flippedIndices.map { cardList[it] }

        return if (strategy.isMatch(selected)) {
            val matchedIndices = flippedIndices.toList()
            markMatched(matchedIndices)
            matchedPairs += 1
            currentCombo += 1
            maxCombo = maxOf(maxCombo, currentCombo)
            flippedIndices.clear()
            if (isComplete) FlipResult.LevelComplete else FlipResult.Match(matchedIndices)
        } else {
            val mismatchIndices = flippedIndices.toList()
            flippedIndices.clear()
            currentCombo = 0
            FlipResult.Mismatch(mismatchIndices)
        }
    }

    fun hideMismatch(indices: List<Int>) {
        for (i in indices) {
            if (i in cardList.indices) {
                cardList[i] = cardList[i].copy(isFaceUp = false, isShaking = false)
            }
        }
    }

    fun markShaking(indices: List<Int>) {
        for (i in indices) {
            if (i in cardList.indices) {
                cardList[i] = cardList[i].copy(isShaking = true)
            }
        }
    }

    private fun markMatched(indices: List<Int>) {
        for (i in indices) {
            if (i in cardList.indices) {
                cardList[i] = cardList[i].copy(isMatched = true, isFaceUp = true)
            }
        }
    }

    /**
     * Given exactly one card the player has already selected themselves
     * (mid-selection, waiting on its match), finds an unmatched, still-
     * hidden card that completes its pair/group — for a rewarded hint that
     * resolves the player's OWN pending pick rather than picking a fresh one
     * for them. Returns null unless the player is genuinely mid-selection
     * (exactly one card flipped, none yet matched for it).
     */
    fun hintPartnerIndex(): Int? {
        if (flippedIndices.size != 1) return null
        val selected = flippedIndices.first()
        if (selected !in cardList.indices) return null
        val target = cardList[selected].groupId ?: cardList[selected].matchingPairId
        return cardList.indices.firstOrNull { i ->
            val c = cardList[i]
            i != selected && !c.isMatched && !c.isFaceUp && (c.groupId ?: c.matchingPairId) == target
        }
    }

    /** Stars are based on move efficiency only (not time). */
    fun calculateStars(): Int =
        StarRatingRules.stars(moves, matchedPairs, totalPairs, isComplete)
}
