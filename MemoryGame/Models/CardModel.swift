//
//  CardModel.swift
//  Memory Match Kids
//

import Foundation

struct CardContent: Identifiable, Equatable, Hashable {
    let id: String
    let label: String
    let symbolName: String
    let emoji: String?
    let accentColorHex: String

    init(
        id: String,
        label: String,
        symbolName: String = "star.fill",
        emoji: String? = nil,
        accentColorHex: String = "5B8DEF"
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.emoji = emoji
        self.accentColorHex = accentColorHex
    }

    /// Same picture/symbol on two cards (fixes duplicate items with different pair ids).
    func visuallyMatches(_ other: CardContent) -> Bool {
        if id == other.id { return true }
        if let e1 = emoji, let e2 = other.emoji, e1 == e2 { return true }
        if emoji == nil, other.emoji == nil,
           label == other.label, symbolName == other.symbolName { return true }
        return false
    }
}

struct CardModel: Identifiable, Equatable {
    let id: UUID
    let content: CardContent
    let pairId: String
    let matchingPairId: String?
    let groupId: String?
    let sequenceIndex: Int?
    var isFaceUp: Bool
    var isMatched: Bool
    var isShaking: Bool
    var isMazePath: Bool

    init(
        content: CardContent,
        pairId: String,
        matchingPairId: String? = nil,
        groupId: String? = nil,
        sequenceIndex: Int? = nil,
        isMazePath: Bool = false
    ) {
        self.id = UUID()
        self.content = content
        self.pairId = pairId
        self.matchingPairId = matchingPairId ?? pairId
        self.groupId = groupId
        self.sequenceIndex = sequenceIndex
        self.isFaceUp = false
        self.isMatched = false
        self.isShaking = false
        self.isMazePath = isMazePath
    }

    var voiceOverLabel: String {
        if isMatched { return "\(content.label), matched" }
        if isFaceUp { return content.label }
        return "Hidden card"
    }
}
