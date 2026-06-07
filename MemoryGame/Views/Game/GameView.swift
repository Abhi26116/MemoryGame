//
//  GameView.swift
//  Memory Match Kids
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var activeLevel: LevelModel
    @State private var previewTickScale: CGFloat = 1
    @Environment(\.colorScheme) private var colorScheme

    let progressStore: ProgressStore

    init(level: LevelModel, progressStore: ProgressStore) {
        self.progressStore = progressStore
        _activeLevel = State(initialValue: level)
        _viewModel = StateObject(wrappedValue: GameViewModel(
            level: level,
            progressStore: progressStore
        ))
    }

    private var nextLevel: LevelModel? {
        LevelCatalog.level(number: activeLevel.levelNumber + 1)
    }

    private var nextLevelJustUnlocked: Bool {
        viewModel.earnedStars >= HomeViewModel.starsRequiredToUnlockNext
            && nextLevel != nil
    }

    private var currentLevelStars: Int {
        progressStore.progress(for: activeLevel.id)?.stars ?? 0
    }

    private var showsUnlockMoveGoal: Bool {
        nextLevel != nil
            && currentLevelStars < HomeViewModel.starsRequiredToUnlockNext
            && !viewModel.gameFinished
            && !viewModel.isPreviewPhase
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let cols = CGFloat(viewModel.columns)
            let horizontalPad: CGFloat = 20
            let cardWidth = (geo.size.width - horizontalPad * 2 - spacing * (cols - 1)) / cols

            ZStack {
                gameBackground

                VStack(spacing: 0) {
                    gameHud
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, showsUnlockMoveGoal ? 6 : (viewModel.isPreviewPhase ? 8 : 12))

                    if showsUnlockMoveGoal {
                        unlockMoveGoalBanner
                            .padding(.horizontal, 16)
                            .padding(.bottom, viewModel.isPreviewPhase ? 6 : 8)
                    }

                    if viewModel.isPreviewPhase {
                        previewBanner
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 12)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: viewModel.columns),
                        spacing: spacing
                    ) {
                        ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                            MemoryCardView(
                                card: card,
                                size: cardWidth,
                                largeText: viewModel.accessibilityLargeText,
                                highContrast: viewModel.highContrast,
                                colorBlindMode: viewModel.colorBlindMode
                            ) {
                                if viewModel.canInteract {
                                    viewModel.tapCard(at: index)
                                }
                            }
                        }
                        .allowsHitTesting(viewModel.canInteract)
                    }
                    .padding(.horizontal, horizontalPad)

                    Spacer(minLength: 12)
                }

                if viewModel.isPaused {
                    pauseOverlay
                }

                ConfettiView(isActive: viewModel.showConfetti)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                if viewModel.gameFinished {
                    Color.black.opacity(0.2).ignoresSafeArea()
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.isPreviewPhase)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(activeLevel.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text(activeLevel.subtitle)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isPaused.toggle()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume" : "Pause")
            }
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showResult = true
                }
            }
        }
        .fullScreenCover(isPresented: $showResult) {
            ResultView(
                levelTitle: viewModel.level.title,
                levelWon: viewModel.levelWon,
                matchedPairs: viewModel.matchedPairs,
                totalPairs: viewModel.totalPairs,
                stars: viewModel.earnedStars,
                score: viewModel.finalScore,
                moves: viewModel.moves,
                movesForTwoStars: viewModel.movesForTwoStars,
                elapsed: viewModel.elapsed,
                nextLevelUnlocked: nextLevelJustUnlocked,
                nextLevelTitle: nextLevel?.title,
                onPlayAgain: {
                    showResult = false
                    viewModel.reset()
                },
                onNextLevel: nextLevelJustUnlocked ? {
                    guard let next = nextLevel else { return }
                    showResult = false
                    activeLevel = next
                    viewModel.loadLevel(next)
                } : nil,
                onHome: {
                    showResult = false
                    dismiss()
                }
            )
        }
    }

    // MARK: - Background

    private var gameBackground: some View {
        ZStack {
            AppTheme.skyGradient(for: colorScheme).ignoresSafeArea()
            Circle()
                .fill(Color(hex: "5B8DEF").opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 30)
                .offset(x: -100, y: -80)
            Circle()
                .fill(Color(hex: "FF6B9D").opacity(0.1))
                .frame(width: 180, height: 180)
                .blur(radius: 28)
                .offset(x: 120, y: geoBottomGlowOffset)
        }
    }

    private var geoBottomGlowOffset: CGFloat { 280 }

    // MARK: - HUD

    private var gameHud: some View {
        HStack(spacing: 10) {
            if showsMovesHud {
                hudTile(
                    icon: "arrow.left.arrow.right",
                    tint: "5B8DEF",
                    label: "Moves",
                    value: movesText
                )
            }

            hudTile(
                icon: viewModel.rules.hasTimer ? "timer" : "clock.fill",
                tint: "FF6B9D",
                label: viewModel.rules.hasTimer ? "Time left" : "Time",
                value: timeText
            )

            hudTile(
                icon: "square.grid.2x2.fill",
                tint: "34C759",
                label: "Pairs",
                value: "\(viewModel.matchedPairs)/\(viewModel.totalPairs)"
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardSurface(for: colorScheme))
                .shadow(color: Color(hex: "5B8DEF").opacity(0.1), radius: 12, y: 4)
        )
    }

    private var showsMovesHud: Bool {
        viewModel.rules.showsMoveCounter || viewModel.rules.maxMoves != nil
    }

    private var unlockMoveGoalBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: "FFD60A"))

            VStack(alignment: .leading, spacing: 3) {
                if let next = nextLevel {
                    Text("Unlock \(next.title)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
                if viewModel.isOnPaceForTwoStars {
                    Text("≤ \(viewModel.movesForTwoStars) moves for 2★ · \(viewModel.movesLeftForTwoStars) move\(viewModel.movesLeftForTwoStars == 1 ? "" : "s") left")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                } else {
                    Text("Over 2★ pace — finish in ≤ \(viewModel.movesForTwoStars) moves total")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF9500"))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "FFD60A").opacity(colorScheme == .dark ? 0.15 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "FFD60A").opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityLabel(unlockMoveGoalAccessibilityLabel)
    }

    private var unlockMoveGoalAccessibilityLabel: String {
        if viewModel.isOnPaceForTwoStars {
            return "Unlock next level with 2 stars in \(viewModel.movesForTwoStars) moves or fewer. \(viewModel.movesLeftForTwoStars) moves remaining."
        }
        return "Unlock next level with 2 stars in \(viewModel.movesForTwoStars) moves or fewer. You are over the 2 star move limit."
    }

    private var movesText: String {
        if let max = viewModel.rules.maxMoves {
            return "\(viewModel.moves)/\(max)"
        }
        return "\(viewModel.moves)"
    }

    private var timeText: String {
        if viewModel.rules.hasTimer {
            return formatTime(viewModel.remainingTime)
        }
        return formatTime(Int(viewModel.elapsed))
    }

    private func hudTile(icon: String, tint: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundStyle(Color(hex: tint))

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: tint).opacity(0.1))
        )
    }

    // MARK: - Preview

    private var previewProgress: CGFloat {
        let total = CGFloat(viewModel.rules.previewSeconds)
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.previewSecondsLeft) / total
    }

    private var previewBanner: some View {
        HStack(spacing: 14) {
            previewCountdownRing

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(hex: "5B8DEF"))
                    Text("Memorize!")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FF6B9D"), Color(hex: "5B8DEF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("Look at every card — they flip over soon!")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                previewSecondDots
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardSurface(for: colorScheme))
                .shadow(color: Color(hex: "FF6B9D").opacity(0.15), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FF6B9D").opacity(0.35), Color(hex: "5B8DEF").opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memorize the cards. \(viewModel.previewSecondsLeft) seconds remaining")
        .onChange(of: viewModel.previewSecondsLeft) { _, _ in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                previewTickScale = 1.12
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.12)) {
                previewTickScale = 1
            }
        }
    }

    private var previewCountdownRing: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.progressTrack(for: colorScheme), lineWidth: 7)

            Circle()
                .trim(from: 0, to: previewProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FF9500"), Color(hex: "FF6B9D"), Color(hex: "5B8DEF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.95), value: viewModel.previewSecondsLeft)

            Text("\(viewModel.previewSecondsLeft)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                .contentTransition(.numericText())
                .scaleEffect(previewTickScale)
        }
        .frame(width: 76, height: 76)
    }

    private var previewSecondDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.rules.previewSeconds, id: \.self) { index in
                Capsule()
                    .fill(index < viewModel.previewSecondsLeft
                          ? AnyShapeStyle(AppTheme.playButtonGradient)
                          : AnyShapeStyle(AppTheme.progressTrack(for: colorScheme)))
                    .frame(width: index < viewModel.previewSecondsLeft ? 22 : 10, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.previewSecondsLeft)
            }
        }
    }

    // MARK: - Pause

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                Text("Paused")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Button {
                    viewModel.isPaused = false
                } label: {
                    Text("Resume")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(AppTheme.playButtonGradient))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardSurface(for: colorScheme))
            )
            .padding(40)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
