package com.memogame.app.model

enum class GridSize(val label: String, val gridRows: Int, val gridColumns: Int) {
    TWO_BY_TWO("2×2", 2, 2),
    TWO_BY_THREE("2×3", 2, 3),
    TWO_BY_FOUR("2×4", 2, 4),
    THREE_BY_FOUR("3×4", 3, 4),
    FOUR_BY_FOUR("4×4", 4, 4),
    FOUR_BY_FIVE("4×5", 4, 5),
    FIVE_BY_SIX("5×6", 5, 6);

    val pairCount: Int get() = (gridRows * gridColumns) / 2
}

enum class MatchMode {
    IDENTICAL,
    ASSOCIATION,
    TRIPLE
}

enum class BadgeTier(val rawValue: String, val colorHex: String) {
    BRONZE("Bronze", "CD7F32"),
    SILVER("Silver", "C0C0C0"),
    GOLD("Gold", "FFD700");

    companion object {
        fun forStars(stars: Int): BadgeTier? = when {
            stars >= 3 -> GOLD
            stars >= 2 -> SILVER
            stars >= 1 -> BRONZE
            else -> null
        }

        fun fromRaw(raw: String?): BadgeTier? = entries.firstOrNull { it.rawValue == raw }
    }
}

enum class AppearanceMode(val rawValue: String, val title: String) {
    SYSTEM("system", "System"),
    LIGHT("light", "Light"),
    DARK("dark", "Dark");

    companion object {
        fun fromRaw(raw: String?): AppearanceMode =
            entries.firstOrNull { it.rawValue == raw } ?: SYSTEM
    }
}

enum class CardBackStyle(val rawValue: String, val label: String, val colorHexes: List<String>) {
    CLASSIC("classic", "Classic", listOf("5B8DEF", "7B5BEF", "9B4DEF")),
    OCEAN("ocean", "Ocean", listOf("2BC0E4", "1A6FB5")),
    SUNSET("sunset", "Sunset", listOf("FF9500", "FF5E3A", "FF2D55")),
    FOREST("forest", "Forest", listOf("34C759", "1A8F50")),
    CANDY("candy", "Candy", listOf("FF6B9D", "C44DFF"));

    companion object {
        fun fromRaw(raw: String?): CardBackStyle =
            entries.firstOrNull { it.rawValue == raw } ?: CLASSIC
    }
}
