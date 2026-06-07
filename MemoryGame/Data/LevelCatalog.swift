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
        let theme = displayThemeName(for: number, mode: mode)

        return LevelModel(
            id: "level_\(number)",
            levelNumber: number,
            title: "Level \(number)",
            subtitle: "\(theme) · \(grid.rawValue)",
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

    private static let associationThemeNames = [
        "Letters", "Animal Match", "Opposites", "Addition", "Word Match", "Countries"
    ]

    private static func displayThemeName(for number: Int, mode: MatchMode) -> String {
        if mode == .association {
            return associationThemeNames[(number - 1) % associationThemeNames.count]
        }
        if mode == .triple {
            return "Triple Match"
        }
        let themes = [
            "Animals", "Colors", "Fruits", "Vehicles", "Shapes",
            "Faces", "Weather", "Toys", "Nature", "Sports"
        ]
        return themes[themeIndex(for: number)]
    }

    // MARK: - Card content pools

    private static let identicalSets: [[(String, String)]] = [
        [("🐶", "Puppy"), ("🐱", "Kitten"), ("🐰", "Bunny"), ("🐥", "Duck"), ("🐻", "Bear"), ("🦊", "Fox"),
         ("🐼", "Panda"), ("🐨", "Koala"), ("🐯", "Tiger"), ("🦁", "Lion"), ("🐷", "Pig"), ("🐸", "Frog"),
         ("🐙", "Octopus"), ("🦒", "Giraffe"), ("🐘", "Elephant")],
        [("🔴", "Red"), ("🔵", "Blue"), ("🟢", "Green"), ("🟡", "Yellow"), ("🟠", "Orange"), ("🟣", "Purple"),
         ("🟤", "Brown"), ("⚫️", "Black"), ("⚪️", "White"), ("🩷", "Pink"), ("🩵", "Light Blue"), ("💚", "Light Green"),
         ("💛", "Light Yellow"), ("🧡", "Light Orange"), ("💜", "Light Purple")],
        [("🍎", "Apple"), ("🍌", "Banana"), ("🍊", "Orange"), ("🍇", "Grapes"), ("🍓", "Strawberry"), ("🍉", "Watermelon"),
         ("🍑", "Peach"), ("🍒", "Cherry"), ("🥝", "Kiwi"), ("🍍", "Pineapple"), ("🥭", "Mango"), ("🫐", "Blueberry"),
         ("🍋", "Lemon"), ("🥥", "Coconut"), ("🍈", "Melon")],
        [("🚗", "Car"), ("🚂", "Train"), ("✈️", "Plane"), ("🚲", "Bike"), ("🚌", "Bus"), ("🚁", "Helicopter"),
         ("🚢", "Ship"), ("🏍️", "Motorcycle"), ("🛴", "Scooter"), ("🚕", "Taxi"), ("🚑", "Ambulance"), ("🚒", "Fire Truck"),
         ("🚜", "Tractor"), ("🛸", "UFO"), ("🚀", "Rocket")],
        [("⭐", "Star"), ("🔴", "Circle"), ("🟦", "Square"), ("🔺", "Triangle"), ("💠", "Diamond"), ("⬛️", "Block"),
         ("⭕️", "Ring"), ("🔶", "Orange Shape"), ("🔷", "Blue Shape"), ("💟", "Heart"), ("✨", "Sparkle"), ("☀️", "Sun Shape"),
         ("🌙", "Moon Shape"), ("🌈", "Rainbow"), ("❇️", "Asterisk")],
        [("😊", "Happy"), ("😢", "Sad"), ("😮", "Wow"), ("🤩", "Excited"), ("😴", "Sleepy"), ("😎", "Cool"),
         ("🥳", "Party"), ("😇", "Angel"), ("🤔", "Thinking"), ("😍", "Love"), ("😜", "Silly"), ("🤗", "Hug"),
         ("😱", "Surprised"), ("🥰", "Blush"), ("😋", "Yummy")],
        [("☀️", "Sun"), ("🌧️", "Rain"), ("❄️", "Snow"), ("☁️", "Cloud"), ("⛈️", "Storm"), ("🌈", "Rainbow"),
         ("🌪️", "Tornado"), ("🌫️", "Fog"), ("💨", "Wind"), ("🌤️", "Partly Sunny"), ("🌥️", "Cloudy"), ("🌦️", "Sun Shower"),
         ("🌨️", "Snow Cloud"), ("🌩️", "Lightning"), ("🌬️", "Breeze")],
        [("🧸", "Teddy"), ("🪀", "Yo-yo"), ("🚙", "Toy Car"), ("🧱", "Blocks"), ("🪁", "Kite"), ("🎲", "Dice"),
         ("🪆", "Doll"), ("🧩", "Puzzle"), ("🎠", "Carousel"), ("🛼", "Skates"), ("🎯", "Target"), ("🪅", "Piñata"),
         ("🪩", "Disco"), ("🧵", "Thread"), ("🪄", "Wand")],
        [("🌸", "Flower"), ("🌳", "Tree"), ("🦋", "Butterfly"), ("🐝", "Bee"), ("🌻", "Sunflower"), ("🍀", "Clover"),
         ("🌵", "Cactus"), ("🍄", "Mushroom"), ("🌺", "Hibiscus"), ("🌷", "Tulip"), ("🪴", "Plant"), ("🌿", "Leaf"),
         ("🪺", "Nest"), ("🐚", "Shell"), ("🪸", "Coral")],
        [("⚽", "Soccer"), ("🏀", "Basketball"), ("🎾", "Tennis"), ("🏈", "Football"), ("🏐", "Volleyball"), ("🏓", "Ping Pong"),
         ("🏸", "Badminton"), ("🥊", "Boxing"), ("⛳️", "Golf"), ("🎳", "Bowling"), ("🏏", "Cricket"), ("🥏", "Frisbee"),
         ("🛹", "Skateboard"), ("⛷️", "Skiing"), ("🏊", "Swimming")]
    ]

    private static let associationSets: [[(String, String)]] = [
        [("A", "a"), ("B", "b"), ("C", "c"), ("D", "d"), ("E", "e"), ("F", "f"), ("G", "g"), ("H", "h"),
         ("I", "i"), ("J", "j"), ("K", "k"), ("L", "l"), ("M", "m"), ("N", "n"), ("O", "o")],
        [("🐵", "🍌"), ("🦌", "🥕"), ("🐄", "🌿"), ("🐟", "🌊"), ("🐝", "🍯"), ("🐧", "🧊"),
         ("🐭", "🧀"), ("🦉", "🌙"), ("🐔", "🥚"), ("🦛", "💧"), ("🦜", "🌴"), ("🐢", "🪨"),
         ("🦆", "🌾"), ("🐿️", "🌰"), ("🦔", "🍂")],
        [("🔥", "❄️"), ("⬆️", "⬇️"), ("☀️", "🌙"), ("🌧️", "☁️"), ("🏖️", "🏔️"), ("🚗", "⛽️"),
         ("🌞", "🌜"), ("🌝", "🌛"), ("🗻", "🏕️"), ("⚡️", "🔋"), ("🌑", "🌕"), ("🏠", "🛏️"),
         ("📖", "✏️"), ("🎨", "🖌️"), ("🎵", "🎹")],
        [("1+1", "2"), ("2+1", "3"), ("3+1", "4"), ("4+1", "5"), ("5+1", "6"), ("6+1", "7"),
         ("7+1", "8"), ("8+1", "9"), ("9+1", "10"), ("6+5", "11"), ("7+5", "12"), ("8+5", "13"),
         ("9+5", "14"), ("7+8", "15"), ("8+8", "16")],
        [("🦈", "SHARK"), ("🐋", "WHALE"), ("🦭", "SEAL"), ("🐊", "CROCODILE"), ("🦎", "LIZARD"), ("🐍", "SNAKE"),
         ("🦘", "KANGAROO"), ("🦏", "RHINO"), ("🦛", "HIPPO"), ("🐪", "CAMEL"), ("🦬", "BISON"), ("🦙", "LLAMA"),
         ("🦥", "SLOTH"), ("🦨", "SKUNK"), ("🦫", "BEAVER")],
        [("🇺🇸", "USA"), ("🇬🇧", "UK"), ("🇫🇷", "France"), ("🇯🇵", "Japan"), ("🇮🇳", "India"), ("🇧🇷", "Brazil"),
         ("🇨🇦", "Canada"), ("🇩🇪", "Germany"), ("🇮🇹", "Italy"), ("🇪🇸", "Spain"), ("🇦🇺", "Australia"), ("🇲🇽", "Mexico"),
         ("🇰🇷", "Korea"), ("🇨🇳", "China"), ("🇿🇦", "South Africa")]
    ]

    private static let tripleSets: [[(String, String)]] = [
        [("🔴", "Red"), ("🔵", "Blue"), ("🟢", "Green"), ("🟡", "Yellow"), ("🟠", "Orange"), ("🟣", "Purple"),
         ("⚫️", "Black"), ("⚪️", "White"), ("🩷", "Pink"), ("🩵", "Cyan")],
        [("🍎", "Apple"), ("🍌", "Banana"), ("🍊", "Orange"), ("🍇", "Grapes"), ("🍓", "Strawberry"), ("🍉", "Watermelon"),
         ("🍑", "Peach"), ("🍒", "Cherry"), ("🥝", "Kiwi"), ("🍍", "Pineapple")],
        [("⭐", "Star"), ("🌙", "Moon"), ("☀️", "Sun"), ("🌈", "Rainbow"), ("☁️", "Cloud"), ("❄️", "Snow"),
         ("🔥", "Fire"), ("💧", "Water"), ("🌸", "Flower"), ("🍀", "Clover")]
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
        let theme = identicalSets[themeIndex(for: level)]
        let rotated = rotatedPool(theme, level: level, poolCount: identicalSets.count)
        let items = uniqueEmojiItems(count: count, from: rotated)
        return items.enumerated().map { index, item in
            let id = "L\(level)_\(index)"
            let content = CardContent(id: id, label: item.1, emoji: item.0)
            return LevelPairDefinition(id: id, left: content, right: content, groupId: id)
        }
    }

    private static func makeAssociationPairs(level: Int, count: Int) -> [LevelPairDefinition] {
        let theme = associationSets[(level - 1) % associationSets.count]
        let rotated = rotatedPool(theme, level: level, poolCount: associationSets.count)
        let items = isMathAssociationSet(theme)
            ? uniqueMathPairs(count: count, from: rotated)
            : uniqueAssociationItems(count: count, from: rotated)
        return items.enumerated().map { index, item in
            let pairId = "L\(level)_\(index)"
            let left = associationCardContent(id: "\(pairId)_L", text: item.0, accent: "5B8DEF")
            let right = associationCardContent(id: "\(pairId)_R", text: item.1, accent: "FF6B9D")
            return LevelPairDefinition(id: pairId, left: left, right: right, groupId: pairId)
        }
    }

    private static func isMathAssociationSet(_ set: [(String, String)]) -> Bool {
        set.contains { MathAssociationHelper.isExpression($0.0) }
    }

    private static func associationCardContent(id: String, text: String, accent: String) -> CardContent {
        if MathAssociationHelper.isExpression(text) || MathAssociationHelper.isNumericAnswer(text) {
            return CardContent(id: id, label: text, symbolName: "plus.forwardslash.minus", accentColorHex: accent)
        }
        return cardContent(id: id, text: text, accent: accent)
    }

    private static func cardContent(id: String, text: String, accent: String) -> CardContent {
        let isEmoji = text.unicodeScalars.first?.properties.isEmoji == true
        if isEmoji {
            return CardContent(id: id, label: text, emoji: text, accentColorHex: accent)
        }
        return CardContent(id: id, label: text, accentColorHex: accent)
    }

    private static func makeTripleGroups(level: Int, groups: Int) -> [LevelPairDefinition] {
        let theme = tripleSets[(level - 1) % tripleSets.count]
        let rotated = rotatedPool(theme, level: level, poolCount: tripleSets.count)
        let items = uniqueEmojiItems(count: groups, from: rotated)
        return items.enumerated().map { index, item in
            let gid = "L\(level)_g\(index)"
            let content = CardContent(id: gid, label: item.1, emoji: item.0, accentColorHex: "AF52DE")
            return LevelPairDefinition(id: gid, left: content, right: content, groupId: gid)
        }
    }

    /// Shifts which items are picked so level 26 ≠ level 20 even on the same theme.
    private static func rotatedPool<T>(_ pool: [T], level: Int, poolCount: Int) -> [T] {
        guard !pool.isEmpty else { return pool }
        let offset = ((level - 1) / max(poolCount, 1) + (level - 1)) % pool.count
        guard offset > 0 else { return pool }
        return Array(pool[offset...] + pool[..<offset])
    }

    /// Unique emojis from one theme only — no repeats, no mixing other themes.
    private static func uniqueEmojiItems(
        count: Int,
        from pool: [(String, String)]
    ) -> [(String, String)] {
        var seen = Set<String>()
        var result: [(String, String)] = []
        var pass = 0
        while result.count < count && pass < 2 {
            for item in pool where result.count < count {
                if seen.insert(item.0).inserted {
                    result.append(item)
                }
            }
            pass += 1
        }
        return result
    }

    /// Addition levels: one unique sum per pair so "10" never appears on two different pairs.
    private static func uniqueMathPairs(count: Int, from pool: [(String, String)]) -> [(String, String)] {
        var seenExpressions = Set<String>()
        var seenAnswers = Set<String>()
        var result: [(String, String)] = []

        for item in pool where result.count < count {
            guard seenExpressions.insert(item.0).inserted else { continue }
            guard seenAnswers.insert(item.1).inserted else { continue }
            result.append(item)
        }
        return result
    }

    /// Each card face (emoji or text) appears only once on the board.
    private static func uniqueAssociationItems(
        count: Int,
        from pool: [(String, String)]
    ) -> [(String, String)] {
        var seenPairKeys = Set<String>()
        var seenVisuals = Set<String>()
        var result: [(String, String)] = []
        var index = 0
        let maxPasses = pool.count * 2

        while result.count < count && index < maxPasses {
            let item = pool[index % pool.count]
            index += 1
            let key = "\(item.0)|\(item.1)"
            guard seenPairKeys.insert(key).inserted else { continue }
            guard !seenVisuals.contains(item.0), !seenVisuals.contains(item.1) else { continue }
            seenVisuals.insert(item.0)
            seenVisuals.insert(item.1)
            result.append(item)
        }
        return result
    }

    private static func makeTriplePairs(level: Int, groups: Int) -> [LevelPairDefinition] {
        makeTripleGroups(level: level, groups: groups)
    }
}
