//
//  LevelCatalog.swift
//  Memory Match Kids — 50 progressive levels
//

import Foundation

enum LevelCatalog {
    static let levelCount = 50

    static var allLevels: [LevelModel] {
        (1...levelCount).map { buildLevel($0) }
    }

    static func level(number: Int) -> LevelModel? {
        guard (1...levelCount).contains(number) else { return nil }
        return buildLevel(number)
    }

    static func level(id: String) -> LevelModel? {
        allLevels.first { $0.id == id }
    }

    // MARK: - Level builder

    private static func buildLevel(_ number: Int) -> LevelModel {
        let grid = gridSize(for: number)
        let mode = matchMode(for: number)
        let slots = grid.gridRows * grid.gridColumns
        let pairCount = mode == .triple ? slots / 3 : slots / 2
        let pairs = makePairs(level: number, count: pairCount, mode: mode)
        let theme = themeName(for: number)

        return LevelModel(
            id: "level_\(number)",
            levelNumber: number,
            title: "Level \(number)",
            subtitle: "\(theme) · \(grid.rawValue) · \(difficultyLabel(for: number))",
            matchMode: mode,
            gridSize: grid,
            gameRules: gameRules(for: number),
            pairs: pairs
        )
    }

    private static func gridSize(for number: Int) -> GridSize {
        switch number {
        case 1...2: return .twoByTwo
        case 3...6: return .threeByFour
        case 7...16: return .fourByFour
        case 17...28: return .fourByFour
        case 29...40: return .fourByFive
        default: return .fiveBySix
        }
    }

    private static func matchMode(for number: Int) -> MatchMode {
        if number >= 42 { return .triple }
        if number >= 20 { return .association }
        return .identical
    }

    private static func gameRules(for number: Int) -> LevelGameRules {
        let preview = number >= 3
        switch number {
        case 1...2:
            return LevelGameRules(
                showsMoveCounter: false, hasTimer: false, timerSeconds: 0, maxMoves: nil,
                showInitialPreview: false, previewSeconds: LevelGameRules.defaultPreviewSeconds
            )
        case 3...6:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: false, timerSeconds: 0, maxMoves: 15,
                showInitialPreview: preview, previewSeconds: LevelGameRules.defaultPreviewSeconds
            )
        case 7...14:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: false, timerSeconds: 0, maxMoves: 22,
                showInitialPreview: preview, previewSeconds: LevelGameRules.defaultPreviewSeconds
            )
        case 15...30:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: false, timerSeconds: 0, maxMoves: nil,
                showInitialPreview: preview, previewSeconds: LevelGameRules.defaultPreviewSeconds
            )
        default:
            let timer = max(75, 200 - number * 2)
            let moves = max(25, 55 - number / 2)
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: true, timerSeconds: timer, maxMoves: moves,
                showInitialPreview: preview, previewSeconds: LevelGameRules.defaultPreviewSeconds
            )
        }
    }

    private static func difficultyLabel(for number: Int) -> String {
        switch number {
        case 1...2: return "Easy"
        case 3...6: return "Medium"
        case 7...18: return "Medium"
        case 19...32: return "Hard"
        default: return "Expert"
        }
    }

    private static func themeName(for number: Int) -> String {
        let themes = [
            "Animals", "Colors", "Fruits", "Vehicles", "Shapes",
            "Faces", "Weather", "Toys", "Nature", "Sports"
        ]
        return themes[themeIndex(for: number)]
    }

    // MARK: - Card content pools

    private static let identicalSets: [[(String, String)]] = [
        [("🐶", "Puppy"), ("🐱", "Kitten"), ("🐰", "Bunny"), ("🐥", "Duck")],
        [("🔴", "Red"), ("🔵", "Blue"), ("🟢", "Green"), ("🟡", "Yellow")],
        [("🍎", "Apple"), ("🍌", "Banana"), ("🍊", "Orange"), ("🍇", "Grapes"), ("🍓", "Strawberry"), ("🍉", "Watermelon")],
        [("🚗", "Car"), ("🚂", "Train"), ("✈️", "Plane"), ("🚲", "Bike")],
        [("⭐", "Star"), ("🔵", "Circle"), ("🟦", "Square"), ("🔺", "Triangle")],
        [("😊", "Happy"), ("😢", "Sad"), ("😮", "Wow"), ("🤩", "Excited")],
        [("☀️", "Sun"), ("🌧️", "Rain"), ("❄️", "Snow"), ("☁️", "Cloud")],
        [("🧸", "Teddy"), ("⚽", "Ball"), ("🚙", "Toy Car"), ("🧱", "Blocks")],
        [("🌸", "Flower"), ("🌳", "Tree"), ("🦋", "Butterfly"), ("🐝", "Bee")],
        [("⚽", "Soccer"), ("🏀", "Basket"), ("🎾", "Tennis"), ("🏈", "Football")]
    ]

    private static let associationSets: [[(String, String)]] = [
        [("A", "a"), ("B", "b"), ("C", "c"), ("D", "d"), ("E", "e"), ("F", "f")],
        [("🐵", "🍌"), ("🐰", "🥕"), ("🐄", "🌿"), ("🐟", "🌊"), ("🐝", "🍯"), ("🐧", "🧊")],
        [("🔥", "❄️"), ("⬆️", "⬇️"), ("☀️", "🌙"), ("🌧️", "☁️"), ("🏖️", "🏔️"), ("🚗", "⛽️")],
        [("5+1", "6"), ("2+4", "6"), ("3+3", "6"), ("7+2", "9"), ("5+5", "10"), ("8+1", "9")],
        [("🐶", "DOG"), ("🐱", "CAT"), ("🐸", "FROG"), ("🦁", "LION"), ("🐮", "COW"), ("🐷", "PIG")],
        [("🇺🇸", "USA"), ("🇬🇧", "UK"), ("🇫🇷", "France"), ("🇯🇵", "Japan"), ("🇮🇳", "India"), ("🇧🇷", "Brazil")]
    ]

    private static let tripleSets: [[(String, String)]] = [
        [("🔴", "Red"), ("🔵", "Blue"), ("🟢", "Green")],
        [("🍎", "Apple"), ("🍌", "Banana"), ("🍊", "Orange")],
        [("⭐", "Star"), ("🌙", "Moon"), ("☀️", "Sun")]
    ]

    private static func makePairs(level: Int, count: Int, mode: MatchMode) -> [LevelPairDefinition] {
        switch mode {
        case .triple:
            return makeTriplePairs(level: level, groups: count)
        case .association:
            return makeAssociationPairs(level: level, count: count)
        default:
            return makeIdenticalPairs(level: level, count: count)
        }
    }

    private static func themeIndex(for level: Int) -> Int {
        (level - 1) % identicalSets.count
    }

    private static func makeIdenticalPairs(level: Int, count: Int) -> [LevelPairDefinition] {
        let set = identicalSets[themeIndex(for: level)]
        return (0..<count).map { index in
            let item = set[index % set.count]
            let id = "L\(level)_\(index)"
            let content = CardContent(id: id, label: item.1, emoji: item.0)
            return LevelPairDefinition(id: id, left: content, right: content, groupId: id)
        }
    }

    private static func makeAssociationPairs(level: Int, count: Int) -> [LevelPairDefinition] {
        let set = associationSets[(level - 1) % associationSets.count]
        return (0..<count).map { i in
            let item = set[i % set.count]
            let pairId = "L\(level)_\(i)"
            let left = cardContent(id: "\(pairId)_L", text: item.0, accent: "5B8DEF")
            let right = cardContent(id: "\(pairId)_R", text: item.1, accent: "FF6B9D")
            return LevelPairDefinition(id: pairId, left: left, right: right, groupId: pairId)
        }
    }

    private static func cardContent(id: String, text: String, accent: String) -> CardContent {
        let isEmoji = text.unicodeScalars.first?.properties.isEmoji == true
        if isEmoji {
            return CardContent(id: id, label: text, emoji: text, accentColorHex: accent)
        }
        return CardContent(id: id, label: text, accentColorHex: accent)
    }

    private static func makeTripleGroups(level: Int, groups: Int) -> [LevelPairDefinition] {
        let set = tripleSets[(level - 1) % tripleSets.count]
        return (0..<groups).map { g in
            let item = set[g % set.count]
            let gid = "L\(level)_g\(g)"
            let content = CardContent(id: gid, label: item.1, emoji: item.0, accentColorHex: "AF52DE")
            return LevelPairDefinition(id: gid, left: content, right: content, groupId: gid)
        }
    }

    private static func makeTriplePairs(level: Int, groups: Int) -> [LevelPairDefinition] {
        makeTripleGroups(level: level, groups: groups)
    }
}
