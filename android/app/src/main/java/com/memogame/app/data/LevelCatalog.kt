package com.memogame.app.data

import com.memogame.app.core.tr

import com.memogame.app.engine.MathAssociationHelper
import com.memogame.app.model.CardContent
import com.memogame.app.model.GridSize
import com.memogame.app.model.LevelGameRules
import com.memogame.app.model.LevelModel
import com.memogame.app.model.LevelPairDefinition
import com.memogame.app.model.MatchMode

/** Memory Match Kids — 50 progressive levels. Direct port of the iOS catalog. */
object LevelCatalog {
    const val LEVEL_COUNT = 50

    val allLevels: List<LevelModel> by lazy { (1..LEVEL_COUNT).map { buildLevel(it) } }

    fun level(number: Int): LevelModel? =
        if (number in 1..LEVEL_COUNT) allLevels[number - 1] else null

    fun level(id: String): LevelModel? = allLevels.firstOrNull { it.id == id }

    // MARK: - Level builder

    private fun buildLevel(number: Int): LevelModel {
        val grid = gridSize(number)
        val mode = matchMode(number)
        val slots = grid.gridRows * grid.gridColumns
        val pairCount = if (mode == MatchMode.TRIPLE) slots / 3 else slots / 2
        val pairs = makePairs(number, pairCount, mode)
        val theme = displayThemeName(number, mode)

        return LevelModel(
            id = "level_$number",
            levelNumber = number,
            title = tr("Level {0}", number),
            subtitle = "$theme · ${grid.label}",
            objective = objective(number, mode),
            matchMode = mode,
            gridSize = grid,
            gameRules = gameRules(number, pairCount, mode),
            pairs = pairs
        )
    }

    private fun gridSize(number: Int): GridSize = when (number) {
        in 1..2 -> GridSize.TWO_BY_TWO      // 4 cards  (2 pairs)
        in 3..5 -> GridSize.TWO_BY_THREE    // 6 cards  (3 pairs)
        in 6..8 -> GridSize.TWO_BY_FOUR     // 8 cards  (4 pairs)
        in 9..14 -> GridSize.THREE_BY_FOUR  // 12 cards (6 pairs)
        in 15..28 -> GridSize.FOUR_BY_FOUR  // 16 cards (8 pairs)
        in 29..40 -> GridSize.FOUR_BY_FIVE  // 20 cards (10 pairs)
        else -> GridSize.FIVE_BY_SIX        // 30 cards (15 / 10 triples)
    }

    private fun matchMode(number: Int): MatchMode = when {
        number >= 42 -> MatchMode.TRIPLE
        number >= 20 -> MatchMode.ASSOCIATION
        else -> MatchMode.IDENTICAL
    }

    /// Pressure is layered in gradually rather than all at once. The "do I run out?"
    /// mechanic is the 3–5 hearts (a mismatch costs a life), not a hard move cap.
    ///   1–2    pure intro — no move counter, no preview (boards too small to fail)
    ///   3–24   move counter + hearts
    ///   25–34  + timer, introduced generously (timer alone bites before it's tight)
    ///   35–50  tighter timer
    /// Hearts scale with board size; the move counter stays only as a star guide.
    private fun gameRules(number: Int, pairs: Int, mode: MatchMode): LevelGameRules {
        val preview = number >= 3
        val seconds = previewSeconds(pairs, mode)
        val hearts = lives(pairs, mode)

        return when (number) {
            in 1..2 -> LevelGameRules(
                showsMoveCounter = false, hasTimer = false, timerSeconds = 0, maxMoves = null,
                showInitialPreview = false, previewSeconds = seconds, maxLives = hearts
            )
            in 3..24 -> LevelGameRules(
                showsMoveCounter = true, hasTimer = false, timerSeconds = 0, maxMoves = null,
                showInitialPreview = preview, previewSeconds = seconds, maxLives = hearts
            )
            in 25..34 -> LevelGameRules(
                showsMoveCounter = true, hasTimer = true,
                timerSeconds = timeBudget(pairs, mode, generous = true),
                maxMoves = null,
                showInitialPreview = preview, previewSeconds = seconds, maxLives = hearts
            )
            else -> LevelGameRules(
                showsMoveCounter = true, hasTimer = true,
                timerSeconds = timeBudget(pairs, mode, generous = false),
                maxMoves = null,
                showInitialPreview = preview, previewSeconds = seconds, maxLives = hearts
            )
        }
    }

    /** Memorize-preview length scales with the board — bigger boards get more time. */
    private fun previewSeconds(pairs: Int, mode: MatchMode): Int {
        val cards = if (mode == MatchMode.TRIPLE) pairs * 3 else pairs * 2
        return when {
            cards <= 8 -> 6       // 2×2 … 2×4
            cards <= 12 -> 8      // 3×4
            cards <= 20 -> 10     // 4×4, 4×5
            else -> 12            // 5×6 (30 cards)
        }
    }

    /** Hearts scale with the board so a fixed mistake budget stays fair as boards grow. */
    private fun lives(pairs: Int, mode: MatchMode): Int {
        if (mode == MatchMode.TRIPLE) return 6
        val cards = pairs * 2
        return when {
            cards <= 12 -> 3
            cards <= 20 -> 4
            else -> 5
        }
    }

    /** Timer scales with the board: bigger boards get MORE time, not less. */
    private fun timeBudget(pairs: Int, mode: MatchMode, generous: Boolean): Int {
        val perPair = if (mode == MatchMode.TRIPLE) 16 else 12
        val base = if (generous) 40 else 25
        val budget = base + pairs * perPair
        return (budget / 5) * 5   // round to a tidy 5-second display
    }

    private val associationThemeNames = listOf(
        tr("Letters"), tr("Animal Match"), tr("Opposites"), tr("Addition"), tr("Word Match"), tr("Countries"),
        tr("Goes Together"), tr("Baby Animals")
    )

    private val tripleThemeNames = listOf(tr("Colors"), tr("Fruits"), tr("Stars"), tr("Animals"), tr("Vehicles"), tr("Food"))

    /** Association level where the mechanic is first introduced. */
    private const val FIRST_ASSOCIATION_LEVEL = 20

    /**
     * Association themes ordered easiest → hardest so the new mechanic ramps up
     * (symbol matching → semantic → reading → arithmetic) instead of appearing at random.
     */
    private val associationDifficultyOrder = listOf(0, 2, 1, 6, 4, 7, 5, 3)

    private fun associationThemeIndex(level: Int): Int {
        val offset = maxOf(0, level - FIRST_ASSOCIATION_LEVEL)
        return associationDifficultyOrder[offset % associationDifficultyOrder.size]
    }

    private fun displayThemeName(number: Int, mode: MatchMode): String {
        if (mode == MatchMode.ASSOCIATION) {
            return associationThemeNames[associationThemeIndex(number)]
        }
        if (mode == MatchMode.TRIPLE) {
            return tr("Triple · {0}", tripleThemeNames[(number - 1) % tripleThemeNames.size])
        }
        val themes = listOf(
            tr("Animals"), tr("Colors"), tr("Fruits"), tr("Vehicles"), tr("Shapes"),
            tr("Faces"), tr("Weather"), tr("Toys"), tr("Nature"), tr("Sports")
        )
        return themes[themeIndex(number)]
    }

    /** Kid-friendly "what to do" line shown on the play screen and memorize phase. */
    private fun objective(number: Int, mode: MatchMode): String = when (mode) {
        MatchMode.TRIPLE -> tr("Find all three cards that are the same!")
        MatchMode.ASSOCIATION -> when (associationThemeIndex(number)) {
            0 -> tr("Match each capital letter to its small letter.")
            1 -> tr("Match each animal to its favorite food.")
            2 -> tr("Match each picture to its opposite.")
            3 -> tr("Match each sum to the correct answer.")
            4 -> tr("Match each animal to its name.")
            5 -> tr("Match each flag to its country.")
            6 -> tr("Match the things that go together.")
            7 -> tr("Match each animal to its baby's name.")
            else -> tr("Match the two cards that go together!")
        }
        else -> tr("Find and match the pairs that look the same!")
    }

    // MARK: - Card content pools

    private val identicalSets: List<List<Pair<String, String>>> = listOf(
        listOf("🐶" to tr("Puppy"), "🐱" to tr("Kitten"), "🐰" to tr("Bunny"), "🐥" to tr("Duck"), "🐻" to tr("Bear"), "🦊" to tr("Fox"),
            "🐼" to tr("Panda"), "🐨" to tr("Koala"), "🐯" to tr("Tiger"), "🦁" to tr("Lion"), "🐷" to tr("Pig"), "🐸" to tr("Frog"),
            "🐙" to tr("Octopus"), "🦒" to tr("Giraffe"), "🐘" to tr("Elephant")),
        listOf("🔴" to tr("Red"), "🔵" to tr("Blue"), "🟢" to tr("Green"), "🟡" to tr("Yellow"), "🟠" to tr("Orange"), "🟣" to tr("Purple"),
            "🟤" to tr("Brown"), "⚫️" to tr("Black"), "⚪️" to tr("White"), "🩷" to tr("Pink"), "🩵" to tr("Light Blue"), "💚" to tr("Light Green"),
            "💛" to tr("Light Yellow"), "🧡" to tr("Light Orange"), "💜" to tr("Light Purple")),
        listOf("🍎" to tr("Apple"), "🍌" to tr("Banana"), "🍊" to tr("Orange (fruit)"), "🍇" to tr("Grapes"), "🍓" to tr("Strawberry"), "🍉" to tr("Watermelon"),
            "🍑" to tr("Peach"), "🍒" to tr("Cherry"), "🥝" to tr("Kiwi"), "🍍" to tr("Pineapple"), "🥭" to tr("Mango"), "🫐" to tr("Blueberry"),
            "🍋" to tr("Lemon"), "🥥" to tr("Coconut"), "🍈" to tr("Melon")),
        listOf("🚗" to tr("Car"), "🚂" to tr("Train"), "✈️" to tr("Plane"), "🚲" to tr("Bike"), "🚌" to tr("Bus"), "🚁" to tr("Helicopter"),
            "🚢" to tr("Ship"), "🏍️" to tr("Motorcycle"), "🛴" to tr("Scooter"), "🚕" to tr("Taxi"), "🚑" to tr("Ambulance"), "🚒" to tr("Fire Truck"),
            "🚜" to tr("Tractor"), "🛸" to tr("UFO"), "🚀" to tr("Rocket")),
        listOf("⭐" to tr("Star"), "🔴" to tr("Circle"), "🟦" to tr("Square"), "🔺" to tr("Triangle"), "💠" to tr("Diamond"), "⬛️" to tr("Block"),
            "⭕️" to tr("Ring"), "🔶" to tr("Orange Shape"), "🔷" to tr("Blue Shape"), "💟" to tr("Heart"), "✨" to tr("Sparkle"), "☀️" to tr("Sun Shape"),
            "🌙" to tr("Moon Shape"), "🌈" to tr("Rainbow"), "❇️" to tr("Asterisk")),
        listOf("😊" to tr("Happy"), "😢" to tr("Sad"), "😮" to tr("Wow"), "🤩" to tr("Excited"), "😴" to tr("Sleepy"), "😎" to tr("Cool"),
            "🥳" to tr("Party"), "😇" to tr("Angel"), "🤔" to tr("Thinking"), "😍" to tr("Love"), "😜" to tr("Silly"), "🤗" to tr("Hug"),
            "😱" to tr("Surprised"), "🥰" to tr("Blush"), "😋" to tr("Yummy")),
        listOf("☀️" to tr("Sun"), "🌧️" to tr("Rain"), "❄️" to tr("Snow"), "☁️" to tr("Cloud"), "⛈️" to tr("Storm"), "🌈" to tr("Rainbow"),
            "🌪️" to tr("Tornado"), "🌫️" to tr("Fog"), "💨" to tr("Wind"), "🌤️" to tr("Partly Sunny"), "🌥️" to tr("Cloudy"), "🌦️" to tr("Sun Shower"),
            "🌨️" to tr("Snow Cloud"), "🌩️" to tr("Lightning"), "🌬️" to tr("Breeze")),
        listOf("🧸" to tr("Teddy"), "🪀" to tr("Yo-yo"), "🚙" to tr("Toy Car"), "🧱" to tr("Blocks"), "🪁" to tr("Kite"), "🎲" to tr("Dice"),
            "🪆" to tr("Doll"), "🧩" to tr("Puzzle"), "🎠" to tr("Carousel"), "🛼" to tr("Skates"), "🎯" to tr("Target"), "🪅" to tr("Piñata"),
            "🪩" to tr("Disco"), "🧵" to tr("Thread"), "🪄" to tr("Wand")),
        listOf("🌸" to tr("Flower"), "🌳" to tr("Tree"), "🦋" to tr("Butterfly"), "🐝" to tr("Bee"), "🌻" to tr("Sunflower"), "🍀" to tr("Clover"),
            "🌵" to tr("Cactus"), "🍄" to tr("Mushroom"), "🌺" to tr("Hibiscus"), "🌷" to tr("Tulip"), "🪴" to tr("Plant"), "🌿" to tr("Leaf"),
            "🪺" to tr("Nest"), "🐚" to tr("Shell"), "🪸" to tr("Coral")),
        listOf("⚽" to tr("Soccer"), "🏀" to tr("Basketball"), "🎾" to tr("Tennis"), "🏈" to tr("Football"), "🏐" to tr("Volleyball"), "🏓" to tr("Ping Pong"),
            "🏸" to tr("Badminton"), "🥊" to tr("Boxing"), "⛳️" to tr("Golf"), "🎳" to tr("Bowling"), "🏏" to tr("Cricket"), "🥏" to tr("Frisbee"),
            "🛹" to tr("Skateboard"), "⛷️" to tr("Skiing"), "🏊" to tr("Swimming"))
    )

    private val associationSets: List<List<Pair<String, String>>> = listOf(
        listOf("A" to "a", "B" to "b", "C" to "c", "D" to "d", "E" to "e", "F" to "f", "G" to "g", "H" to "h",
            "I" to "i", "J" to "j", "K" to "k", "L" to "l", "M" to "m", "N" to "n", "O" to "o"),
        listOf("🐵" to "🍌", "🦌" to "🥕", "🐄" to "🌿", "🐟" to "🌊", "🐝" to "🍯", "🐧" to "🧊",
            "🐭" to "🧀", "🦉" to "🌙", "🐔" to "🥚", "🦛" to "💧", "🦜" to "🌴", "🐢" to "🪨",
            "🦆" to "🌾", "🐿️" to "🌰", "🦔" to "🍂"),
        listOf("🔥" to "❄️", "⬆️" to "⬇️", "☀️" to "🌙", "🌧️" to "☁️", "🏖️" to "🏔️", "🚗" to "⛽️",
            "🌞" to "🌜", "🌝" to "🌛", "🗻" to "🏕️", "⚡️" to "🔋", "🌑" to "🌕", "🏠" to "🛏️",
            "📖" to "✏️", "🎨" to "🖌️", "🎵" to "🎹"),
        listOf("1+1" to "2", "2+1" to "3", "3+1" to "4", "4+1" to "5", "5+1" to "6", "6+1" to "7",
            "7+1" to "8", "8+1" to "9", "9+1" to "10", "10+1" to "11", "10+2" to "12", "10+3" to "13",
            "10+4" to "14", "10+5" to "15", "10+6" to "16"),
        listOf("🦈" to tr("SHARK"), "🐋" to tr("WHALE"), "🦭" to tr("SEAL"), "🐊" to tr("CROCODILE"), "🦎" to tr("LIZARD"), "🐍" to tr("SNAKE"),
            "🦘" to tr("KANGAROO"), "🦏" to tr("RHINO"), "🦛" to tr("HIPPO"), "🐪" to tr("CAMEL"), "🦬" to tr("BISON"), "🦙" to tr("LLAMA"),
            "🦥" to tr("SLOTH"), "🦨" to tr("SKUNK"), "🦫" to tr("BEAVER")),
        listOf("🇺🇸" to tr("USA"), "🇬🇧" to tr("UK"), "🇫🇷" to tr("France"), "🇯🇵" to tr("Japan"), "🇮🇳" to tr("India"), "🇧🇷" to tr("Brazil"),
            "🇨🇦" to tr("Canada"), "🇩🇪" to tr("Germany"), "🇮🇹" to tr("Italy"), "🇪🇸" to tr("Spain"), "🇦🇺" to tr("Australia"), "🇲🇽" to tr("Mexico"),
            "🇰🇷" to tr("Korea"), "🇨🇳" to tr("China"), "🇿🇦" to tr("South Africa")),
        listOf("🧦" to "👟", "🔑" to "🔒", "✏️" to "📓", "🪥" to "🦷", "☂️" to "🌧️", "🧤" to "❄️",
            "🐝" to "🌻", "🐟" to "🐠", "🍴" to "🍽️", "🔌" to "💡", "🎁" to "🎀", "⚽" to "🥅",
            "🖍️" to "🎨", "🧩" to "🧠", "🌱" to "💧"),
        listOf("🐶" to tr("Puppy"), "🐱" to tr("Kitten"), "🐮" to tr("Calf"), "🐑" to tr("Lamb"), "🐴" to tr("Foal"), "🐻" to tr("Cub"),
            "🦌" to tr("Fawn"), "🐔" to tr("Chick"), "🦘" to tr("Joey"), "🐸" to tr("Tadpole"), "🦢" to tr("Cygnet"), "🐐" to tr("Kid"),
            "🦅" to tr("Eaglet"), "🐷" to tr("Piglet"), "🦉" to tr("Owlet"))
    )

    private val tripleSets: List<List<Pair<String, String>>> = listOf(
        listOf("🔴" to tr("Red"), "🔵" to tr("Blue"), "🟢" to tr("Green"), "🟡" to tr("Yellow"), "🟠" to tr("Orange"), "🟣" to tr("Purple"),
            "⚫️" to tr("Black"), "⚪️" to tr("White"), "🩷" to tr("Pink"), "🩵" to tr("Cyan")),
        listOf("🍎" to tr("Apple"), "🍌" to tr("Banana"), "🍊" to tr("Orange (fruit)"), "🍇" to tr("Grapes"), "🍓" to tr("Strawberry"), "🍉" to tr("Watermelon"),
            "🍑" to tr("Peach"), "🍒" to tr("Cherry"), "🥝" to tr("Kiwi"), "🍍" to tr("Pineapple")),
        listOf("⭐" to tr("Star"), "🌙" to tr("Moon"), "☀️" to tr("Sun"), "🌈" to tr("Rainbow"), "☁️" to tr("Cloud"), "❄️" to tr("Snow"),
            "🔥" to tr("Fire"), "💧" to tr("Water"), "🌸" to tr("Flower"), "🍀" to tr("Clover")),
        listOf("🐶" to tr("Dog"), "🐱" to tr("Cat"), "🐰" to tr("Rabbit"), "🐻" to tr("Bear"), "🦊" to tr("Fox"), "🐼" to tr("Panda"),
            "🦁" to tr("Lion"), "🐯" to tr("Tiger"), "🐸" to tr("Frog"), "🐵" to tr("Monkey")),
        listOf("🚗" to tr("Car"), "🚌" to tr("Bus"), "🚓" to tr("Police Car"), "🚑" to tr("Ambulance"), "🚒" to tr("Fire Truck"), "✈️" to tr("Plane"),
            "🚀" to tr("Rocket"), "🚁" to tr("Helicopter"), "🚲" to tr("Bike"), "⛵" to tr("Boat")),
        listOf("🍕" to tr("Pizza"), "🍔" to tr("Burger"), "🌭" to tr("Hot Dog"), "🍟" to tr("Fries"), "🍩" to tr("Donut"), "🍪" to tr("Cookie"),
            "🍰" to tr("Cake"), "🍦" to tr("Ice Cream"), "🍫" to tr("Chocolate"), "🍿" to tr("Popcorn"))
    )

    private fun makePairs(level: Int, count: Int, mode: MatchMode): List<LevelPairDefinition> =
        when (mode) {
            MatchMode.TRIPLE -> makeTripleGroups(level, count)
            MatchMode.ASSOCIATION -> makeAssociationPairs(level, count)
            else -> makeIdenticalPairs(level, count)
        }

    private fun themeIndex(level: Int): Int = (level - 1) % identicalSets.size

    private fun makeIdenticalPairs(level: Int, count: Int): List<LevelPairDefinition> {
        val theme = identicalSets[themeIndex(level)]
        val rotated = rotatedPool(theme, level, identicalSets.size)
        val items = uniqueEmojiItems(count, rotated)
        return items.mapIndexed { index, item ->
            val id = "L${level}_$index"
            val content = CardContent(id = id, label = item.second, emoji = item.first)
            LevelPairDefinition(id = id, left = content, right = content, groupId = id)
        }
    }

    private fun makeAssociationPairs(level: Int, count: Int): List<LevelPairDefinition> {
        val theme = associationSets[associationThemeIndex(level)]
        val rotated = rotatedPool(theme, level, associationSets.size)
        val items = if (isMathAssociationSet(theme)) {
            uniqueMathPairs(count, rotated)
        } else {
            uniqueAssociationItems(count, rotated)
        }
        return items.mapIndexed { index, item ->
            val pairId = "L${level}_$index"
            val left = cardContent(id = "${pairId}_L", text = item.first, accent = "5B8DEF")
            val right = cardContent(id = "${pairId}_R", text = item.second, accent = "FF6B9D")
            LevelPairDefinition(id = pairId, left = left, right = right, groupId = pairId)
        }
    }

    private fun isMathAssociationSet(set: List<Pair<String, String>>): Boolean =
        set.any { MathAssociationHelper.isExpression(it.first) }

    private fun cardContent(id: String, text: String, accent: String): CardContent =
        if (isEmojiText(text)) {
            CardContent(id = id, label = text, emoji = text, accentColorHex = accent)
        } else {
            CardContent(id = id, label = text, accentColorHex = accent)
        }

    /** Plain letters/words/math stay text cards; anything pictographic is an emoji card. */
    private fun isEmojiText(text: String): Boolean {
        if (text.isEmpty()) return false
        return text.codePointAt(0) > 0x2100
    }

    private fun makeTripleGroups(level: Int, groups: Int): List<LevelPairDefinition> {
        val theme = tripleSets[(level - 1) % tripleSets.size]
        val rotated = rotatedPool(theme, level, tripleSets.size)
        val items = uniqueEmojiItems(groups, rotated)
        return items.mapIndexed { index, item ->
            val gid = "L${level}_g$index"
            val content = CardContent(id = gid, label = item.second, emoji = item.first, accentColorHex = "AF52DE")
            LevelPairDefinition(id = gid, left = content, right = content, groupId = gid)
        }
    }

    /** Shifts which items are picked so level 26 ≠ level 20 even on the same theme. */
    private fun <T> rotatedPool(pool: List<T>, level: Int, poolCount: Int): List<T> {
        if (pool.isEmpty()) return pool
        val offset = ((level - 1) / maxOf(poolCount, 1) + (level - 1)) % pool.size
        if (offset <= 0) return pool
        return pool.subList(offset, pool.size) + pool.subList(0, offset)
    }

    /** Unique emojis from one theme only — no repeats, no mixing other themes. */
    private fun uniqueEmojiItems(
        count: Int,
        pool: List<Pair<String, String>>
    ): List<Pair<String, String>> {
        val seen = mutableSetOf<String>()
        val result = mutableListOf<Pair<String, String>>()
        var pass = 0
        while (result.size < count && pass < 2) {
            for (item in pool) {
                if (result.size >= count) break
                if (seen.add(item.first)) result.add(item)
            }
            pass += 1
        }
        return result
    }

    /** Addition levels: one unique sum per pair so "10" never appears on two different pairs. */
    private fun uniqueMathPairs(count: Int, pool: List<Pair<String, String>>): List<Pair<String, String>> {
        val seenExpressions = mutableSetOf<String>()
        val seenAnswers = mutableSetOf<String>()
        val result = mutableListOf<Pair<String, String>>()

        for (item in pool) {
            if (result.size >= count) break
            if (!seenExpressions.add(item.first)) continue
            if (!seenAnswers.add(item.second)) continue
            result.add(item)
        }
        return result
    }

    /** Each card face (emoji or text) appears only once on the board. */
    private fun uniqueAssociationItems(
        count: Int,
        pool: List<Pair<String, String>>
    ): List<Pair<String, String>> {
        val seenPairKeys = mutableSetOf<String>()
        val seenVisuals = mutableSetOf<String>()
        val result = mutableListOf<Pair<String, String>>()
        var index = 0
        val maxPasses = pool.size * 2

        while (result.size < count && index < maxPasses) {
            val item = pool[index % pool.size]
            index += 1
            val key = "${item.first}|${item.second}"
            if (!seenPairKeys.add(key)) continue
            if (seenVisuals.contains(item.first) || seenVisuals.contains(item.second)) continue
            seenVisuals.add(item.first)
            seenVisuals.add(item.second)
            result.add(item)
        }
        return result
    }
}
