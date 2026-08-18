package com.memogame.app.engine

import com.memogame.app.model.CardModel
import com.memogame.app.model.MatchMode

interface MatchStrategy {
    fun isMatch(cards: List<CardModel>): Boolean
    val requiredSelectionCount: Int
}

class NormalMatchStrategy : MatchStrategy {
    override val requiredSelectionCount = 2

    override fun isMatch(cards: List<CardModel>): Boolean {
        if (cards.size != 2) return false
        val groupA = cards[0].groupId ?: cards[0].pairId
        val groupB = cards[1].groupId ?: cards[1].pairId
        if (groupA == groupB) return true
        return cards[0].content.id == cards[1].content.id
    }
}

class AssociationMatchStrategy : MatchStrategy {
    override val requiredSelectionCount = 2

    override fun isMatch(cards: List<CardModel>): Boolean {
        if (cards.size != 2) return false
        val first = cards[0].content
        val second = cards[1].content
        if (first.id == second.id) return false

        val groupA = cards[0].groupId ?: cards[0].matchingPairId
        val groupB = cards[1].groupId ?: cards[1].matchingPairId
        if (groupA == groupB) return true

        return MathAssociationHelper.expressionMatchesAnswer(first.label, second.label)
    }
}

class TripleMatchStrategy : MatchStrategy {
    override val requiredSelectionCount = 3

    override fun isMatch(cards: List<CardModel>): Boolean {
        if (cards.size != 3) return false
        val gid = cards[0].groupId ?: cards[0].matchingPairId
        return cards.all { (it.groupId ?: it.matchingPairId) == gid }
    }
}

object MatchStrategyFactory {
    fun strategy(mode: MatchMode): MatchStrategy = when (mode) {
        MatchMode.IDENTICAL -> NormalMatchStrategy()
        MatchMode.ASSOCIATION -> AssociationMatchStrategy()
        MatchMode.TRIPLE -> TripleMatchStrategy()
    }
}
