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
            title: tr("Level {0}", number),
            subtitle: "\(theme) · \(grid.rawValue)",
            objective: objective(for: number, mode: mode),
            matchMode: mode,
            gridSize: grid,
            gameRules: gameRules(for: number, pairs: pairCount, mode: mode),
            pairs: pairs
        )
    }

    private static func gridSize(for number: Int) -> GridSize {
        switch number {
        case 1...2: return .twoByTwo      // 4 cards  (2 pairs)
        case 3...5: return .twoByThree    // 6 cards  (3 pairs)
        case 6...8: return .twoByFour     // 8 cards  (4 pairs)
        case 9...14: return .threeByFour  // 12 cards (6 pairs)
        case 15...28: return .fourByFour  // 16 cards (8 pairs)
        case 29...40: return .fourByFive  // 20 cards (10 pairs)
        default: return .fiveBySix        // 30 cards (15 / 10 triples)
        }
    }

    private static func matchMode(for number: Int) -> MatchMode {
        if number >= 42 { return .triple }
        if number >= 20 { return .association }
        return .identical
    }

    /// Pressure is layered in gradually rather than all at once. The "do I run out?"
    /// mechanic is the 3–5 hearts (a mismatch costs a life), not a hard move cap.
    ///   1–2    pure intro — no move counter, no preview (boards too small to fail)
    ///   3–24   move counter + hearts
    ///   25–34  + timer, introduced generously (timer alone bites before it's tight)
    ///   35–50  tighter timer
    /// Hearts scale with board size; the move counter stays only as a star guide.
    private static func gameRules(for number: Int, pairs: Int, mode: MatchMode) -> LevelGameRules {
        let preview = number >= 3
        let seconds = previewSeconds(forPairs: pairs, mode: mode)
        let hearts = lives(forPairs: pairs, mode: mode)

        switch number {
        case 1...2:
            return LevelGameRules(
                showsMoveCounter: false, hasTimer: false, timerSeconds: 0, maxMoves: nil,
                showInitialPreview: false, previewSeconds: seconds, maxLives: hearts
            )
        case 3...24:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: false, timerSeconds: 0, maxMoves: nil,
                showInitialPreview: preview, previewSeconds: seconds, maxLives: hearts
            )
        case 25...34:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: true,
                timerSeconds: timeBudget(pairs: pairs, mode: mode, generous: true),
                maxMoves: nil,
                showInitialPreview: preview, previewSeconds: seconds, maxLives: hearts
            )
        default:
            return LevelGameRules(
                showsMoveCounter: true, hasTimer: true,
                timerSeconds: timeBudget(pairs: pairs, mode: mode, generous: false),
                maxMoves: nil,
                showInitialPreview: preview, previewSeconds: seconds, maxLives: hearts
            )
        }
    }

    /// Memorize-preview length scales with the board — bigger boards get more time to study.
    /// (Levels 1–2 don't show a preview at all.)
    private static func previewSeconds(forPairs pairs: Int, mode: MatchMode) -> Int {
        let cards = mode == .triple ? pairs * 3 : pairs * 2
        switch cards {
        case ...8: return 6      // 2×2 … 2×4
        case 9...12: return 8    // 3×4
        case 13...20: return 10  // 4×4, 4×5
        default: return 12       // 5×6 (30 cards)
        }
    }

    /// Hearts scale with the board so a fixed mistake budget stays fair as boards grow:
    /// 3 on small boards (≤12 cards), 4 on medium (4×4 / 4×5), 5 on the 30-card board,
    /// and 6 on the triple-match levels (42–50) since matching three is harder.
    private static func lives(forPairs pairs: Int, mode: MatchMode) -> Int {
        if mode == .triple { return 6 }
        let cards = pairs * 2
        switch cards {
        case ...12: return 3
        case 13...20: return 4
        default: return 5
        }
    }

    /// Timer scales with the board: bigger boards get MORE time, not less.
    /// Triple match needs longer because each move turns over three cards.
    private static func timeBudget(pairs: Int, mode: MatchMode, generous: Bool) -> Int {
        let perPair = mode == .triple ? 16 : 12
        let base = generous ? 40 : 25
        let budget = base + pairs * perPair
        return (budget / 5) * 5   // round to a tidy 5-second display
    }

    private static let associationThemeNames = [
        tr("Letters"), tr("Animal Match"), tr("Opposites"), tr("Addition"), tr("Word Match"), tr("Countries"),
        tr("Goes Together"), tr("Baby Animals")
    ]

    private static let tripleThemeNames = [tr("Colors"), tr("Fruits"), tr("Stars"), tr("Animals"), tr("Vehicles"), tr("Food")]

    /// Association level where the mechanic is first introduced.
    private static let firstAssociationLevel = 20

    /// Association themes ordered easiest → hardest so the new mechanic ramps up
    /// (symbol matching → semantic → reading → arithmetic) instead of appearing at random.
    /// Values index into `associationSets` / `associationThemeNames`.
    private static let associationDifficultyOrder = [0, 2, 1, 6, 4, 7, 5, 3]

    private static func associationThemeIndex(for level: Int) -> Int {
        let offset = max(0, level - firstAssociationLevel)
        return associationDifficultyOrder[offset % associationDifficultyOrder.count]
    }

    private static func displayThemeName(for number: Int, mode: MatchMode) -> String {
        if mode == .association {
            return associationThemeNames[associationThemeIndex(for: number)]
        }
        if mode == .triple {
            return tr("Triple · {0}", (tripleThemeNames[(number - 1) % tripleThemeNames.count]))
        }
        let themes = [
            tr("Animals"), tr("Colors"), tr("Fruits"), tr("Vehicles"), tr("Shapes"),
            tr("Faces"), tr("Weather"), tr("Toys"), tr("Nature"), tr("Sports")
        ]
        return themes[themeIndex(for: number)]
    }

    /// Kid-friendly "what to do" line shown on the play screen and memorize phase.
    private static func objective(for number: Int, mode: MatchMode) -> String {
        switch mode {
        case .triple:
            return tr("Find all three cards that are the same!")
        case .association:
            switch associationThemeIndex(for: number) {
            case 0: return tr("Match each capital letter to its small letter.")
            case 1: return tr("Match each animal to its favorite food.")
            case 2: return tr("Match each picture to its opposite.")
            case 3: return tr("Match each sum to the correct answer.")
            case 4: return tr("Match each animal to its name.")
            case 5: return tr("Match each flag to its country.")
            case 6: return tr("Match the things that go together.")
            case 7: return tr("Match each animal to its baby's name.")
            default: return tr("Match the two cards that go together!")
            }
        default:
            return tr("Find and match the pairs that look the same!")
        }
    }

    // MARK: - Card content pools

    private static let identicalSets: [[(String, String)]] = [
        [("🐶", tr("Puppy")), ("🐱", tr("Kitten")), ("🐰", tr("Bunny")), ("🐥", tr("Duck")), ("🐻", tr("Bear")), ("🦊", tr("Fox")),
         ("🐼", tr("Panda")), ("🐨", tr("Koala")), ("🐯", tr("Tiger")), ("🦁", tr("Lion")), ("🐷", tr("Pig")), ("🐸", tr("Frog")),
         ("🐙", tr("Octopus")), ("🦒", tr("Giraffe")), ("🐘", tr("Elephant"))],
        [("🔴", tr("Red")), ("🔵", tr("Blue")), ("🟢", tr("Green")), ("🟡", tr("Yellow")), ("🟠", tr("Orange")), ("🟣", tr("Purple")),
         ("🟤", tr("Brown")), ("⚫️", tr("Black")), ("⚪️", tr("White")), ("🩷", tr("Pink")), ("🩵", tr("Light Blue")), ("💚", tr("Light Green")),
         ("💛", tr("Light Yellow")), ("🧡", tr("Light Orange")), ("💜", tr("Light Purple"))],
        [("🍎", tr("Apple")), ("🍌", tr("Banana")), ("🍊", tr("Orange (fruit)")), ("🍇", tr("Grapes")), ("🍓", tr("Strawberry")), ("🍉", tr("Watermelon")),
         ("🍑", tr("Peach")), ("🍒", tr("Cherry")), ("🥝", tr("Kiwi")), ("🍍", tr("Pineapple")), ("🥭", tr("Mango")), ("🫐", tr("Blueberry")),
         ("🍋", tr("Lemon")), ("🥥", tr("Coconut")), ("🍈", tr("Melon"))],
        [("🚗", tr("Car")), ("🚂", tr("Train")), ("✈️", tr("Plane")), ("🚲", tr("Bike")), ("🚌", tr("Bus")), ("🚁", tr("Helicopter")),
         ("🚢", tr("Ship")), ("🏍️", tr("Motorcycle")), ("🛴", tr("Scooter")), ("🚕", tr("Taxi")), ("🚑", tr("Ambulance")), ("🚒", tr("Fire Truck")),
         ("🚜", tr("Tractor")), ("🛸", tr("UFO")), ("🚀", tr("Rocket"))],
        [("⭐", tr("Star")), ("🔴", tr("Circle")), ("🟦", tr("Square")), ("🔺", tr("Triangle")), ("💠", tr("Diamond")), ("⬛️", tr("Block")),
         ("⭕️", tr("Ring")), ("🔶", tr("Orange Shape")), ("🔷", tr("Blue Shape")), ("💟", tr("Heart")), ("✨", tr("Sparkle")), ("☀️", tr("Sun Shape")),
         ("🌙", tr("Moon Shape")), ("🌈", tr("Rainbow")), ("❇️", tr("Asterisk"))],
        [("😊", tr("Happy")), ("😢", tr("Sad")), ("😮", tr("Wow")), ("🤩", tr("Excited")), ("😴", tr("Sleepy")), ("😎", tr("Cool")),
         ("🥳", tr("Party")), ("😇", tr("Angel")), ("🤔", tr("Thinking")), ("😍", tr("Love")), ("😜", tr("Silly")), ("🤗", tr("Hug")),
         ("😱", tr("Surprised")), ("🥰", tr("Blush")), ("😋", tr("Yummy"))],
        [("☀️", tr("Sun")), ("🌧️", tr("Rain")), ("❄️", tr("Snow")), ("☁️", tr("Cloud")), ("⛈️", tr("Storm")), ("🌈", tr("Rainbow")),
         ("🌪️", tr("Tornado")), ("🌫️", tr("Fog")), ("💨", tr("Wind")), ("🌤️", tr("Partly Sunny")), ("🌥️", tr("Cloudy")), ("🌦️", tr("Sun Shower")),
         ("🌨️", tr("Snow Cloud")), ("🌩️", tr("Lightning")), ("🌬️", tr("Breeze"))],
        [("🧸", tr("Teddy")), ("🪀", tr("Yo-yo")), ("🚙", tr("Toy Car")), ("🧱", tr("Blocks")), ("🪁", tr("Kite")), ("🎲", tr("Dice")),
         ("🪆", tr("Doll")), ("🧩", tr("Puzzle")), ("🎠", tr("Carousel")), ("🛼", tr("Skates")), ("🎯", tr("Target")), ("🪅", tr("Piñata")),
         ("🪩", tr("Disco")), ("🧵", tr("Thread")), ("🪄", tr("Wand"))],
        [("🌸", tr("Flower")), ("🌳", tr("Tree")), ("🦋", tr("Butterfly")), ("🐝", tr("Bee")), ("🌻", tr("Sunflower")), ("🍀", tr("Clover")),
         ("🌵", tr("Cactus")), ("🍄", tr("Mushroom")), ("🌺", tr("Hibiscus")), ("🌷", tr("Tulip")), ("🪴", tr("Plant")), ("🌿", tr("Leaf")),
         ("🪺", tr("Nest")), ("🐚", tr("Shell")), ("🪸", tr("Coral"))],
        [("⚽", tr("Soccer")), ("🏀", tr("Basketball")), ("🎾", tr("Tennis")), ("🏈", tr("Football")), ("🏐", tr("Volleyball")), ("🏓", tr("Ping Pong")),
         ("🏸", tr("Badminton")), ("🥊", tr("Boxing")), ("⛳️", tr("Golf")), ("🎳", tr("Bowling")), ("🏏", tr("Cricket")), ("🥏", tr("Frisbee")),
         ("🛹", tr("Skateboard")), ("⛷️", tr("Skiing")), ("🏊", tr("Swimming"))]
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
         ("7+1", "8"), ("8+1", "9"), ("9+1", "10"), ("10+1", "11"), ("10+2", "12"), ("10+3", "13"),
         ("10+4", "14"), ("10+5", "15"), ("10+6", "16")],
        [("🦈", tr("SHARK")), ("🐋", tr("WHALE")), ("🦭", tr("SEAL")), ("🐊", tr("CROCODILE")), ("🦎", tr("LIZARD")), ("🐍", tr("SNAKE")),
         ("🦘", tr("KANGAROO")), ("🦏", tr("RHINO")), ("🦛", tr("HIPPO")), ("🐪", tr("CAMEL")), ("🦬", tr("BISON")), ("🦙", tr("LLAMA")),
         ("🦥", tr("SLOTH")), ("🦨", tr("SKUNK")), ("🦫", tr("BEAVER"))],
        [("🇺🇸", tr("USA")), ("🇬🇧", tr("UK")), ("🇫🇷", tr("France")), ("🇯🇵", tr("Japan")), ("🇮🇳", tr("India")), ("🇧🇷", tr("Brazil")),
         ("🇨🇦", tr("Canada")), ("🇩🇪", tr("Germany")), ("🇮🇹", tr("Italy")), ("🇪🇸", tr("Spain")), ("🇦🇺", tr("Australia")), ("🇲🇽", tr("Mexico")),
         ("🇰🇷", tr("Korea")), ("🇨🇳", tr("China")), ("🇿🇦", tr("South Africa"))],
        [("🧦", "👟"), ("🔑", "🔒"), ("✏️", "📓"), ("🪥", "🦷"), ("☂️", "🌧️"), ("🧤", "❄️"),
         ("🐝", "🌻"), ("🐟", "🐠"), ("🍴", "🍽️"), ("🔌", "💡"), ("🎁", "🎀"), ("⚽", "🥅"),
         ("🖍️", "🎨"), ("🧩", "🧠"), ("🌱", "💧")],
        [("🐶", tr("Puppy")), ("🐱", tr("Kitten")), ("🐮", tr("Calf")), ("🐑", tr("Lamb")), ("🐴", tr("Foal")), ("🐻", tr("Cub")),
         ("🦌", tr("Fawn")), ("🐔", tr("Chick")), ("🦘", tr("Joey")), ("🐸", tr("Tadpole")), ("🦢", tr("Cygnet")), ("🐐", tr("Kid")),
         ("🦅", tr("Eaglet")), ("🐷", tr("Piglet")), ("🦉", tr("Owlet"))]
    ]

    private static let tripleSets: [[(String, String)]] = [
        [("🔴", tr("Red")), ("🔵", tr("Blue")), ("🟢", tr("Green")), ("🟡", tr("Yellow")), ("🟠", tr("Orange")), ("🟣", tr("Purple")),
         ("⚫️", tr("Black")), ("⚪️", tr("White")), ("🩷", tr("Pink")), ("🩵", tr("Cyan"))],
        [("🍎", tr("Apple")), ("🍌", tr("Banana")), ("🍊", tr("Orange (fruit)")), ("🍇", tr("Grapes")), ("🍓", tr("Strawberry")), ("🍉", tr("Watermelon")),
         ("🍑", tr("Peach")), ("🍒", tr("Cherry")), ("🥝", tr("Kiwi")), ("🍍", tr("Pineapple"))],
        [("⭐", tr("Star")), ("🌙", tr("Moon")), ("☀️", tr("Sun")), ("🌈", tr("Rainbow")), ("☁️", tr("Cloud")), ("❄️", tr("Snow")),
         ("🔥", tr("Fire")), ("💧", tr("Water")), ("🌸", tr("Flower")), ("🍀", tr("Clover"))],
        [("🐶", tr("Dog")), ("🐱", tr("Cat")), ("🐰", tr("Rabbit")), ("🐻", tr("Bear")), ("🦊", tr("Fox")), ("🐼", tr("Panda")),
         ("🦁", tr("Lion")), ("🐯", tr("Tiger")), ("🐸", tr("Frog")), ("🐵", tr("Monkey"))],
        [("🚗", tr("Car")), ("🚌", tr("Bus")), ("🚓", tr("Police Car")), ("🚑", tr("Ambulance")), ("🚒", tr("Fire Truck")), ("✈️", tr("Plane")),
         ("🚀", tr("Rocket")), ("🚁", tr("Helicopter")), ("🚲", tr("Bike")), ("⛵", tr("Boat"))],
        [("🍕", tr("Pizza")), ("🍔", tr("Burger")), ("🌭", tr("Hot Dog")), ("🍟", tr("Fries")), ("🍩", tr("Donut")), ("🍪", tr("Cookie")),
         ("🍰", tr("Cake")), ("🍦", tr("Ice Cream")), ("🍫", tr("Chocolate")), ("🍿", tr("Popcorn"))]
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
        let theme = associationSets[associationThemeIndex(for: level)]
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
