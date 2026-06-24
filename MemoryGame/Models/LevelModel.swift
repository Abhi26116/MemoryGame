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
    var maxLives: Int = LevelGameRules.defaultLives

    var hasMoveLimit: Bool { maxMoves != nil }
    var livesEnabled: Bool { maxLives > 0 }

    static let defaultPreviewSeconds = 5
    static let defaultLives = 3
}

struct LevelModel: Identifiable, Equatable {
    let id: String
    let levelNumber: Int
    let title: String
    let subtitle: String
    let objective: String
    let matchMode: MatchMode
    let gridSize: GridSize
    let gameRules: LevelGameRules
    let pairs: [LevelPairDefinition]

    var pairCount: Int { pairs.count }

    var totalPairsOnBoard: Int {
        let slots = gridSize.gridRows * gridSize.gridColumns
        return matchMode == .triple ? max(1, slots / 3) : max(1, slots / 2)
    }

}
