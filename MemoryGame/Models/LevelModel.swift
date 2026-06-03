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

    var difficultyLabel: String {
        switch levelNumber {
        case 1...2: return "Easy"
        case 3...6: return "Medium"
        case 7...18: return "Medium"
        case 19...32: return "Hard"
        default: return "Expert"
        }
    }
}
