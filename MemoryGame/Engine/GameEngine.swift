//
//  GameEngine.swift
//  Memory Match Kids
//

import Foundation

struct GameEngineConfig {
    let level: LevelModel
    let gridSize: GridSize
}

final class GameEngine {
    private(set) var cards: [CardModel] = []
    private(set) var flippedIndices: [Int] = []
    private(set) var moves: Int = 0
    private(set) var matchedPairs: Int = 0
    private(set) var sequenceProgress: Int = 0
    private(set) var mazeRevealedPath: Set<Int> = []

    let config: GameEngineConfig
    private let strategy: MatchStrategy
    private(set) var totalPairs: Int = 0

    var isComplete: Bool { matchedPairs >= totalPairs }
    var selectionLimit: Int { strategy.requiredSelectionCount(mode: config.level.matchMode) }

    init(config: GameEngineConfig) {
        self.config = config
        self.strategy = MatchStrategyFactory.strategy(for: config.level.matchMode)
        buildDeck()
    }

    func buildDeck() {
        let level = config.level
        let grid = config.gridSize
        let slotCount = grid.gridRows * grid.gridColumns
        var deck: [CardModel] = []

        switch level.matchMode {
        case .triple:
            for pair in level.pairs {
                let group = pair.groupId ?? pair.id
                for _ in 0..<3 {
                    deck.append(CardModel(
                        content: pair.left,
                        pairId: pair.id,
                        matchingPairId: group,
                        groupId: group
                    ))
                }
            }
        case .identical:
            for pair in level.pairs {
                let group = pair.groupId ?? pair.id
                deck.append(CardModel(
                    content: pair.left,
                    pairId: pair.id,
                    matchingPairId: group,
                    groupId: group
                ))
                deck.append(CardModel(
                    content: pair.right,
                    pairId: pair.id,
                    matchingPairId: group,
                    groupId: group
                ))
            }
        case .association:
            for pair in level.pairs {
                let group = pair.groupId ?? pair.id
                deck.append(CardModel(
                    content: pair.left,
                    pairId: pair.id,
                    matchingPairId: group,
                    groupId: group
                ))
                deck.append(CardModel(
                    content: pair.right,
                    pairId: pair.id,
                    matchingPairId: group,
                    groupId: group
                ))
            }
        case .sequence, .maze:
            break
        }

        deck = Array(deck.prefix(slotCount))
        cards = deck.shuffled()
        flippedIndices = []
        moves = 0
        matchedPairs = 0
        sequenceProgress = 0
        mazeRevealedPath = []

        totalPairs = switch level.matchMode {
        case .triple: max(1, slotCount / 3)
        default: max(1, slotCount / 2)
        }
    }

    func revealAllCards() {
        for index in cards.indices where !cards[index].isMatched {
            cards[index].isFaceUp = true
        }
    }

    func concealAllCards() {
        for index in cards.indices where !cards[index].isMatched {
            cards[index].isFaceUp = false
        }
        flippedIndices = []
    }

    func canFlip(index: Int) -> Bool {
        guard cards.indices.contains(index) else { return false }
        let card = cards[index]
        if card.isMatched || card.isFaceUp { return false }
        if flippedIndices.count >= selectionLimit { return false }
        return true
    }

    func flipCard(at index: Int) -> FlipResult {
        guard canFlip(index: index) else { return .ignored }

        cards[index].isFaceUp = true
        flippedIndices.append(index)

        if flippedIndices.count < selectionLimit {
            return .waiting
        }

        moves += 1
        let selected = flippedIndices.map { cards[$0] }

        if strategy.isMatch(cards: selected, mode: config.level.matchMode) {
            let matchedIndices = flippedIndices
            markMatched(indices: matchedIndices)
            matchedPairs += 1
            flippedIndices = []
            if isComplete { return .levelComplete }
            return .match(indices: matchedIndices)
        } else {
            let mismatchIndices = flippedIndices
            flippedIndices = []
            return .mismatch(indices: mismatchIndices)
        }
    }

    func hideMismatch(indices: [Int]) {
        for i in indices where cards.indices.contains(i) {
            cards[i].isFaceUp = false
            cards[i].isShaking = false
        }
    }

    func markShaking(indices: [Int]) {
        for i in indices where cards.indices.contains(i) {
            cards[i].isShaking = true
        }
    }

    private func markMatched(indices: [Int]) {
        for i in indices where cards.indices.contains(i) {
            cards[i].isMatched = true
            cards[i].isFaceUp = true
        }
    }

    /// Stars are based on move efficiency only (not time).
    func calculateStars() -> Int {
        StarRatingRules.stars(
            forMoves: moves,
            matchedPairs: matchedPairs,
            totalPairs: totalPairs,
            levelComplete: isComplete
        )
    }

}

enum StarRatingRules {
    static let twoStarExtraMoves = 5

    static func movesForThreeStars(totalPairs: Int) -> Int {
        max(1, totalPairs)
    }

    static func movesForTwoStars(totalPairs: Int) -> Int {
        movesForThreeStars(totalPairs: totalPairs) + twoStarExtraMoves
    }

    static func stars(forMoves moves: Int, matchedPairs: Int, totalPairs: Int, levelComplete: Bool) -> Int {
        guard levelComplete else {
            return matchedPairs > 0 ? 1 : 0
        }
        let pairs = max(1, totalPairs)
        if moves <= movesForThreeStars(totalPairs: pairs) { return 3 }
        if moves <= movesForTwoStars(totalPairs: pairs) { return 2 }
        return 1
    }
}

enum FlipResult: Equatable {
    case ignored
    case waiting
    case match(indices: [Int])
    case mismatch(indices: [Int])
    case sequenceStep
    case levelComplete
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
