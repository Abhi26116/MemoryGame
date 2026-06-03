//
//  MatchStrategy.swift
//  Memory Match Kids
//

import Foundation

protocol MatchStrategy {
    func isMatch(cards: [CardModel], mode: MatchMode) -> Bool
    func requiredSelectionCount(mode: MatchMode) -> Int
}

struct NormalMatchStrategy: MatchStrategy {
    func requiredSelectionCount(mode: MatchMode) -> Int { 2 }

    func isMatch(cards: [CardModel], mode: MatchMode) -> Bool {
        guard cards.count == 2 else { return false }
        if cards[0].pairId == cards[1].pairId { return true }
        if cards[0].content.id == cards[1].content.id { return true }
        if mode == .identical {
            return cards[0].content.visuallyMatches(cards[1].content)
        }
        return false
    }
}

struct AssociationMatchStrategy: MatchStrategy {
    func requiredSelectionCount(mode: MatchMode) -> Int { 2 }

    func isMatch(cards: [CardModel], mode: MatchMode) -> Bool {
        guard cards.count == 2 else { return false }
        let groupA = cards[0].groupId ?? cards[0].matchingPairId ?? cards[0].pairId
        let groupB = cards[1].groupId ?? cards[1].matchingPairId ?? cards[1].pairId
        guard groupA == groupB else { return false }
        return cards[0].content.id != cards[1].content.id
    }
}

struct TripleMatchStrategy: MatchStrategy {
    func requiredSelectionCount(mode: MatchMode) -> Int { 3 }

    func isMatch(cards: [CardModel], mode: MatchMode) -> Bool {
        guard cards.count == 3 else { return false }
        let gid = cards[0].groupId ?? cards[0].matchingPairId ?? cards[0].pairId
        return cards.allSatisfy {
            ($0.groupId ?? $0.matchingPairId ?? $0.pairId) == gid
        }
    }
}

enum MatchStrategyFactory {
    static func strategy(for mode: MatchMode) -> MatchStrategy {
        switch mode {
        case .identical, .sequence, .maze:
            return NormalMatchStrategy()
        case .association:
            return AssociationMatchStrategy()
        case .triple:
            return TripleMatchStrategy()
        }
    }
}
