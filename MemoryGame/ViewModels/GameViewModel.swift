//
//  GameViewModel.swift
//  Memory Match Kids
//

import Foundation
import SwiftUI

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
    @Published var finalScore = 0
    @Published var mismatchIndices: [Int] = []

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

    var movesForTwoStars: Int { StarRatingRules.movesForTwoStars(totalPairs: totalPairs) }
    var movesForThreeStars: Int { StarRatingRules.movesForThreeStars(totalPairs: totalPairs) }
    var movesLeftForTwoStars: Int { max(0, movesForTwoStars - moves) }
    var isOnPaceForTwoStars: Bool { moves <= movesForTwoStars }

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
        showConfetti = false
        isPaused = false
        remainingTime = rules.timerSeconds

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
            for remaining in stride(from: self.rules.previewSeconds, through: 1, by: -1) {
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
                        if self.remainingTime == 0 { self.finishGame() }
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
            HapticManager.light(enabled: hapticsEnabled)
        case .match:
            AudioManager.shared.playSuccess()
            HapticManager.success(enabled: hapticsEnabled)
            if engine.isComplete {
                finishGame()
            } else {
                endIfOutOfMoves()
            }
        case .mismatch(let indices):
            AudioManager.shared.playMismatch()
            HapticManager.error(enabled: hapticsEnabled)
            mismatchIndices = indices
            engine.markShaking(indices: indices)
            cards = engine.cards
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                await MainActor.run {
                    self.engine.hideMismatch(indices: indices)
                    self.cards = self.engine.cards
                    self.mismatchIndices = []
                    self.endIfOutOfMoves()
                }
            }
        case .sequenceStep:
            AudioManager.shared.playSuccess()
            HapticManager.light(enabled: hapticsEnabled)
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
        finishGame()
    }

    private func finishGame() {
        guard !gameFinished else { return }
        gameFinished = true
        canInteract = false
        levelWon = engine.isComplete
        previewTask?.cancel()
        timerTask?.cancel()
        if !rules.hasTimer {
            elapsed = Date().timeIntervalSince(startDate)
        }
        earnedStars = engine.calculateStars()
        finalScore = engine.score(elapsed: elapsed)
        showConfetti = levelWon
        if levelWon {
            AudioManager.shared.playComplete()
            HapticManager.success(enabled: hapticsEnabled)
        } else {
            AudioManager.shared.playMismatch()
            HapticManager.error(enabled: hapticsEnabled)
        }
        progressStore.recordCompletion(
            levelId: level.id,
            stars: earnedStars,
            score: finalScore,
            elapsed: elapsed
        )
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
