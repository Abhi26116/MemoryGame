//
//  HomeViewModel.swift
//  Memory Match Kids
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    /// Testing override: set true to play every level without earning stars first.
    /// Off in production — only Level 1 is open; each level unlocks by earning 2★ on the previous one.
    static let allLevelsUnlocked = false

    private let progressStore: ProgressStore

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        syncFromStore()
    }

    func syncFromStore() {
        guard let settings = progressStore.settings else { return }
        AudioManager.shared.soundEnabled = settings.soundEnabled
    }

    var levels: [LevelModel] { LevelCatalog.allLevels }

    /// Only the levels the player has reached, plus the next locked one as a teaser —
    /// so the total number of levels stays a mystery and the list grows as they play.
    var visibleLevels: [LevelModel] {
        if Self.allLevelsUnlocked { return levels }
        var result: [LevelModel] = []
        for level in levels {
            result.append(level)
            if !isUnlocked(level) { break }   // include the first locked level, then stop
        }
        return result
    }

    var totalStars: Int { progressStore.totalStars }
    var completedLevels: Int { progressStore.completedLevels }
    var totalLevels: Int { LevelCatalog.levelCount }

    var progressFraction: Double {
        guard totalLevels > 0 else { return 0 }
        return Double(completedLevels) / Double(totalLevels)
    }

    func stars(for levelId: String) -> Int {
        progressStore.progress(for: levelId)?.stars ?? 0
    }

    func isCompleted(_ levelId: String) -> Bool {
        (progressStore.progress(for: levelId)?.completedCount ?? 0) > 0
    }

    func isUnlocked(_ level: LevelModel) -> Bool {
        if Self.allLevelsUnlocked { return true }
        if level.levelNumber <= 1 { return true }
        guard let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return false }
        return isCompleted(previous.id)
    }

    func unlockHint(for level: LevelModel) -> String? {
        guard !isUnlocked(level), level.levelNumber > 1,
              let previous = LevelCatalog.level(number: level.levelNumber - 1) else { return nil }
        return "Complete Level \(previous.levelNumber) to unlock"
    }

    /// Next unlocked level the player hasn't finished yet (for Continue).
    var suggestedLevel: LevelModel? {
        levels.first { isUnlocked($0) && !isCompleted($0.id) }
    }

    /// Offline "Daily Highlight" — a memory tip that rotates once per calendar day.
    /// Deterministic (no network, no storage) so it's stable for the whole day.
    /// 100 tips means a full ~100-day cycle before any repeat. Kept in sync
    /// with Android's copy of the same list (`HomeViewModel.kt`) so a given
    /// calendar day shows the same tip on both platforms.
    var dailyTip: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.dailyTips[day % Self.dailyTips.count]
    }

    static let dailyTips: [String] = [
        "Glance at the whole board first — your eyes remember more than you think.",
        "Match in a steady pattern, like left to right, to track what you've seen.",
        "Say each card out loud in your head — naming it helps it stick.",
        "Group cards by what they have in common to recall them faster.",
        "Slow down on the first few flips; speed comes once you've mapped the board.",
        "Take a breath before a tricky pair — calm focus beats rushing.",
        "Chain your matches! A combo streak shows off real memory power.",
        "Picture each card in its spot like a tiny photograph in your mind.",
        "Flip two new cards before repeating one you've seen — more info, faster.",
        "Corners and edges are easy to remember first — start your search there.",
        "A short pause between flips gives your brain time to file the picture away.",
        "Three stars come from fewer moves, not from speed — think before you tap.",
        "Losing a heart isn't the end — every mismatch teaches you something new.",
        "Stuck on a pair? Ask a grown-up to watch an ad for a hint.",
        "The bigger the board, the more hints you get — use them wisely.",
        "Try humming while you play — a calm mind remembers better.",
        "Matching pairs by color first can make patterns easier to spot.",
        "Your brain gets stronger every time you play, just like a muscle.",
        "Take your time during Memorize — that preview is your best tool.",
        "Repeat the card names in your head twice to lock them in.",
        "If two cards look similar, look for the small detail that makes them different.",
        "Practice makes perfect — replay a level to beat your own best time.",
        "A tidy mental map beats a rushed guess almost every time.",
        "Try memorizing four cards at once instead of just one or two.",
        "Cards you've matched are safe to forget — focus only on what's left.",
        "Mismatches happen to everyone, even memory champions — shake it off and keep going.",
        "The middle of the board is often the last place people check — remember it.",
        "Break the board into small sections and memorize one at a time.",
        "A confident tap beats a hesitant one — trust what you remember.",
        "Every level gets trickier, but so does your memory — you're leveling up too!",
        "Try closing your eyes for a second and picturing the board from memory.",
        "The fewer moves you use, the shinier your stars will be.",
        "A new best time is worth celebrating — check your personal record after each win.",
        "Keep your eyes moving evenly across the board instead of staring at one spot.",
        "Two heads remember better than one — play with a friend or family member.",
        "If you forget a card, it's okay to guess — sometimes you'll surprise yourself.",
        "Warm up on an easy level before trying a bigger board.",
        "A short break between games helps your memory reset and refocus.",
        "Cards that made you laugh are the easiest ones to remember.",
        "Try naming the card's color AND its shape to double your memory clues.",
        "The first match of the game sets your rhythm — start calm and careful.",
        "Counting your moves out loud can help you stay mindful while you play.",
        "A steady hand and a steady mind go together — take it one tap at a time.",
        "Every completed level unlocks something new — keep your streak going!",
        "If a level feels hard, that means you're right where you should be growing.",
        "Try to remember pairs in twos — thinking in pairs is faster than singles.",
        "A hint reveals the matching card once you've picked one — use it to seal a tricky match!",
        "Losing all your lives just means it's time for a fresh look at the board.",
        "A big smile while you play can make the whole game more fun — try it!",
        "Your accuracy score shows how many of your guesses were matches — aim to raise it.",
        "Take a peek at the moves counter — can you finish with fewer than last time?",
        "Some boards use a timer — plan your first few flips before it starts ticking.",
        "Some levels pair related pictures instead of identical ones — think about how two things connect.",
        "Some levels need you to find three matching cards instead of two — remember one extra spot.",
        "A relaxed grip on the phone helps you tap more accurately.",
        "The best memory players aren't the fastest — they're the most careful.",
        "Try to beat your combo record from your last game.",
        "Reviewing a mistake for a second can help you avoid repeating it.",
        "A good night's sleep helps your memory work its best the next day.",
        "Snacks and water breaks are great for young memory athletes too!",
        "Your progress is always saved — come back anytime and pick up where you left off.",
        "Gold levels are the toughest — save them for when you're feeling extra sharp.",
        "Silver and bronze stars still count — every level finished is a win.",
        "Try playing the same level twice in a row to see how much faster you get.",
        "A cluttered mind forgets more — clear your thoughts before you start a level.",
        "The card you flip last is often the easiest to remember — save tricky guesses for later.",
        "Counting the pairs left on the board can help you know how close you are to winning.",
        "If your hands are shaky, rest the phone on a table for steadier taps.",
        "Some kids remember shapes best, others remember colors — find out which works for you.",
        "A memory game is a mini workout for your brain — enjoy the exercise!",
        "Try whispering the card's name as you flip it — quiet repetition really helps.",
        "The corners of the board are often forgotten last — double-check them if you're stuck.",
        "Playing regularly, even for a few minutes, builds stronger memory over time.",
        "Don't be afraid to lose — every attempt makes your next try sharper.",
        "The memorize preview goes by fast — use every second wisely.",
        "If a match seems obvious, trust your gut — hesitation can cost you moves.",
        "The pause button is there when you need a real break — use it guilt-free.",
        "Keep a steady breathing rhythm while playing — it keeps your mind clear.",
        "Try to spot patterns in how the cards were shuffled — sometimes they cluster.",
        "A cheerful attitude makes losing a life feel a lot less scary.",
        "The higher the level, the more pairs — but also, the more practice you've had.",
        "Some children find it easier to remember pictures than words — notice what works for you.",
        "A quick stretch between levels can help refresh your focus.",
        "Remember: even memory experts started as beginners once.",
        "Try setting a small goal, like matching three pairs before you rest.",
        "The best time to ask for help is right when you feel stuck, not after you've given up.",
        "Building move-by-move confidence beats trying to memorize the whole board at once.",
        "A short countdown before each level gives your brain time to get ready.",
        "Cheering yourself on, even quietly, can boost focus and confidence.",
        "Every mismatch narrows down what's left — treat it like a clue, not a failure.",
        "Try playing your favorite level again just for fun, no pressure.",
        "A good memory habit is checking the board calmly before making your first move.",
        "The most memorable cards are often the funniest or most colorful ones.",
        "Take pride in finishing a level, no matter how many stars you earned.",
        "Some days your memory feels sharper than others — that's totally normal.",
        "Practicing a little every day beats a big session once in a while.",
        "If you match two pairs in a row, you're building a combo — keep it going!",
        "A relaxed player notices more than a rushed one.",
        "You don't need to be perfect — you just need to keep trying.",
        "Every level you complete adds a star to your journey — watch your collection grow!"
    ]
}
