//
//  LevelModel.swift
//  Memory Match Kids
//

import Foundation

struct LevelPairDefinition: Identifiable, Equatable {
    let id: String
    let left: CardContent
    let right: CardContent
    let groupId: String?
}

struct LevelGameRules: Equatable {
    var showsMoveCounter: Bool
    var hasTimer: Bool
    var timerSeconds: Int
    var maxMoves: Int?
    var showInitialPreview: Bool
    var previewSeconds: Int

    var hasMoveLimit: Bool { maxMoves != nil }

    static let defaultPreviewSeconds = 5
}

struct LevelModel: Identifiable, Equatable {
    let id: String
    let levelNumber: Int
    let title: String
    let subtitle: String
    let matchMode: MatchMode
    let gridSize: GridSize
    let gameRules: LevelGameRules
    let pairs: [LevelPairDefinition]

    var pairCount: Int { pairs.count }

    var totalPairsOnBoard: Int {
        let slots = gridSize.gridRows * gridSize.gridColumns
        return matchMode == .triple ? max(1, slots / 3) : max(1, slots / 2)
    }

    var movesToEarnTwoStars: Int {
        StarRatingRules.movesForTwoStars(totalPairs: totalPairsOnBoard)
    }

}
