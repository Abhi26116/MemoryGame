//
//  GameViewModel.swift
//  Memory Match Kids
//

import Foundation
import SwiftUI

enum GameOverReason: Equatable {
    case won
    case outOfMoves
    case outOfTime
    case outOfLives
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var cards: [CardModel] = []
    @Published private(set) var moves: Int = 0
    @Published private(set) var matchedPairs: Int = 0
    @Published private(set) var totalPairs: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var remainingTime: Int = 0
    @Published var showConfetti = false
    @Published var isPaused = false
    @Published var gameFinished = false
    @Published private(set) var levelWon = false
    @Published var earnedStars = 0
    @Published var accuracy: Int = 100
    @Published var maxCombo: Int = 0
    @Published var bestTime: TimeInterval = 0
    @Published var isNewBestTime = false
    @Published var mismatchIndices: [Int] = []
    @Published private(set) var livesRemaining = LevelGameRules.defaultLives
    @Published private(set) var failReason: GameOverReason = .won

    @Published private(set) var isPreviewPhase = false
    @Published private(set) var previewSecondsLeft = 0
    @Published private(set) var canInteract = true

    private(set) var level: LevelModel
    private(set) var gridSize: GridSize
    private(set) var rules: LevelGameRules

    private var engine: GameEngine!
    private let progressStore: ProgressStore
    private var timerTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?
    private var startDate = Date()

    var rows: Int { gridSize.gridRows }
    var columns: Int { gridSize.gridColumns }
    var hapticsEnabled: Bool { progressStore.settings?.hapticsEnabled ?? true }
    var accessibilityLargeText: Bool { progressStore.settings?.largeText ?? false }
    var highContrast: Bool { progressStore.settings?.highContrast ?? false }
    var colorBlindMode: Bool { progressStore.settings?.colorBlindMode ?? false }

    var maxLives: Int { rules.maxLives }
    var livesEnabled: Bool { rules.livesEnabled }

    /// Encouraging reason shown on the result screen after a loss (nil when won).
    var lossReasonText: String? {
        switch failReason {
        case .won: return nil
        case .outOfLives: return "Out of hearts — play again to match all the pairs!"
        case .outOfMoves: return "Out of moves — play again to match all the pairs!"
        case .outOfTime: return "Time's up — play again to match all the pairs!"
        }
    }

    init(level: LevelModel, progressStore: ProgressStore) {
        self.level = level
        self.gridSize = level.gridSize
        self.rules = level.gameRules
        self.progressStore = progressStore
        startGame()
    }

    func startGame() {
        previewTask?.cancel()
        let config = GameEngineConfig(level: level, gridSize: gridSize)
        engine = GameEngine(config: config)
        cards = engine.cards
        moves = 0
        matchedPairs = engine.matchedPairs
        totalPairs = engine.totalPairs
        elapsed = 0
        gameFinished = false
        levelWon = false
        failReason = .won
        accuracy = 100
        maxCombo = 0
        bestTime = 0
        isNewBestTime = false
        livesRemaining = rules.maxLives
        showConfetti = false
        isPaused = false
        remainingTime = rules.timerSeconds

        HapticManager.prepare()
        let previewOn = progressStore.memorizePreviewEnabled
        if rules.showInitialPreview && previewOn {
            beginPreviewPhase()
        } else {
            canInteract = true
            isPreviewPhase = false
            startDate = Date()
            startGameplayTimer()
        }
    }

    private func beginPreviewPhase() {
        engine.revealAllCards()
        cards = engine.cards
        isPreviewPhase = true
        canInteract = false
        previewSecondsLeft = rules.previewSeconds

        previewTask = Task { [weak self] in
            guard let self else { return }
            // Count down one number per second: 5,4,3,2,1 then reveal — exactly previewSeconds long.
            for remaining in stride(from: self.rules.previewSeconds - 1, through: 1, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.previewSecondsLeft = remaining
                }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.endPreviewPhase()
            }
        }
    }

    private func endPreviewPhase() {
        engine.concealAllCards()
        cards = engine.cards
        isPreviewPhase = false
        previewSecondsLeft = 0
        canInteract = true
        startDate = Date()
        startGameplayTimer()
    }

    private func startGameplayTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self, !self.isPaused, !self.gameFinished, !self.isPreviewPhase else { return }
                    self.elapsed = Date().timeIntervalSince(self.startDate)
                    if self.rules.hasTimer, self.remainingTime > 0 {
                        self.remainingTime -= 1
                        if self.remainingTime == 0 { self.finishGame(reason: .outOfTime) }
                    }
                }
            }
        }
    }

    func tapCard(at index: Int) {
        guard canInteract, !isPreviewPhase, !gameFinished, !isPaused else { return }
        if moveLimitReached { return }

        let result = engine.flipCard(at: index)
        cards = engine.cards
        moves = engine.moves
        matchedPairs = engine.matchedPairs

        if !rules.hasTimer {
            elapsed = Date().timeIntervalSince(startDate)
        }

        switch result {
        case .ignored:
            break
        case .waiting:
            AudioManager.shared.playFlip()
            HapticManager.cardFlip(enabled: hapticsEnabled)
        case .match:
            AudioManager.shared.playSuccess()
            HapticManager.match(enabled: hapticsEnabled)
            if engine.isComplete {
                finishGame()
            } else {
                endIfOutOfMoves()
            }
        case .mismatch(let indices):
            AudioManager.shared.playMismatch()
            if livesEnabled {
                livesRemaining = max(0, livesRemaining - 1)
                HapticManager.lifeLost(enabled: hapticsEnabled)
            } else {
                HapticManager.mismatch(enabled: hapticsEnabled)
            }
            mismatchIndices = indices
            engine.markShaking(indices: indices)
            cards = engine.cards
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                await MainActor.run {
                    self.engine.hideMismatch(indices: indices)
                    self.cards = self.engine.cards
                    self.mismatchIndices = []
                    if self.livesEnabled, self.livesRemaining == 0 {
                        self.finishGame(reason: .outOfLives)
                    } else {
                        self.endIfOutOfMoves()
                    }
                }
            }
        case .sequenceStep:
            AudioManager.shared.playSuccess()
            HapticManager.cardFlip(enabled: hapticsEnabled)
        case .levelComplete:
            finishGame()
        }
    }

    private var moveLimitReached: Bool {
        guard rules.hasMoveLimit, let max = rules.maxMoves else { return false }
        return moves >= max
    }

    private func endIfOutOfMoves() {
        guard moveLimitReached, !engine.isComplete else { return }
        finishGame(reason: .outOfMoves)
    }

    private func finishGame(reason: GameOverReason = .won) {
        guard !gameFinished else { return }
        gameFinished = true
        canInteract = false
        levelWon = engine.isComplete
        failReason = levelWon ? .won : reason
        previewTask?.cancel()
        timerTask?.cancel()
        if !rules.hasTimer {
            elapsed = Date().timeIntervalSince(startDate)
        }
        earnedStars = engine.calculateStars()
        maxCombo = engine.maxCombo
        accuracy = moves > 0 ? Int((Double(matchedPairs) / Double(moves) * 100).rounded()) : 100
        showConfetti = levelWon
        if levelWon {
            AudioManager.shared.playComplete()
            HapticManager.levelComplete(enabled: hapticsEnabled)
        } else {
            AudioManager.shared.playMismatch()
            HapticManager.levelFailed(enabled: hapticsEnabled)
        }
        // Only a win counts as completing the level — a loss (out of hearts / time)
        // records nothing, so it can't unlock the next level or inflate progress.
        if levelWon {
            let previousBest = progressStore.progress(for: level.id)?.fastestTime
            isNewBestTime = previousBest == nil || elapsed < previousBest!
            progressStore.recordCompletion(
                levelId: level.id,
                stars: earnedStars,
                elapsed: elapsed,
                levelWon: true,
                hasTimer: rules.hasTimer
            )
            bestTime = progressStore.progress(for: level.id)?.fastestTime ?? elapsed
        }
    }

    func reset() {
        previewTask?.cancel()
        timerTask?.cancel()
        startGame()
    }

    func loadLevel(_ newLevel: LevelModel) {
        level = newLevel
        gridSize = newLevel.gridSize
        rules = newLevel.gameRules
        previewTask?.cancel()
        timerTask?.cancel()
        startGame()
    }

    deinit {
        previewTask?.cancel()
        timerTask?.cancel()
    }
}
