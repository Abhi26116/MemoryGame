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
    @State private var livesShake = 0
    @State private var showTutorial = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("cardBackStyle") private var cardBackRaw = CardBackStyle.classic.rawValue
    private var cardBackStyle: CardBackStyle { CardBackStyle(rawValue: cardBackRaw) ?? .classic }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        viewModel.levelWon && nextLevel != nil
    }

    private var milestoneMessage: String? {
        guard viewModel.levelWon else { return nil }
        switch activeLevel.levelNumber {
        case 10: return "🔥 10 levels done — you're on a roll!"
        case 25: return "⭐️ 25 levels complete — amazing!"
        case 50: return "🏆 Memory Master! You beat every level!"
        default: return nil
        }
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = DS.Spacing.sm
            let cols = CGFloat(viewModel.columns)
            let horizontalPad: CGFloat = DS.Layout.screenPadding
            let cardWidth = (geo.size.width - horizontalPad * 2 - spacing * (cols - 1)) / cols

            ZStack {
                DSScreenBackground()

                VStack(spacing: 0) {
                    gameHud
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.top, DS.Spacing.sm)
                        .padding(.bottom, viewModel.isPreviewPhase ? DS.Spacing.sm : DS.Spacing.md)

                    if viewModel.isPreviewPhase {
                        previewBanner
                            .padding(.horizontal, DS.Spacing.lg)
                            .padding(.bottom, DS.Spacing.sm + 2)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        objectiveBanner
                            .padding(.horizontal, DS.Spacing.lg)
                            .padding(.bottom, DS.Spacing.sm + 2)
                    }

                    Spacer(minLength: DS.Spacing.md)

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
                                colorBlindMode: viewModel.colorBlindMode,
                                cardBackStyle: cardBackStyle
                            ) {
                                if viewModel.canInteract {
                                    viewModel.tapCard(at: index)
                                }
                            }
                        }
                        .allowsHitTesting(viewModel.canInteract)
                    }
                    .padding(.horizontal, horizontalPad)

                    Spacer(minLength: DS.Spacing.md)
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

                if showTutorial {
                    tutorialOverlay
                }
            }
        }
        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring), value: viewModel.isPreviewPhase)
        .onAppear {
            if activeLevel.levelNumber == 1 && !hasSeenTutorial {
                showTutorial = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .kidBackButton()
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: DS.Spacing.xxs) {
                    Text(activeLevel.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text(activeLevel.subtitle)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isPaused.toggle()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DS.Color.link)
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume" : "Pause")
            }
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished {
                AdsManager.shared.handleLevelFinished(
                    adsRemoved: StoreManager.shared.adsRemoved
                ) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showResult = true
                    }
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
                moves: viewModel.moves,
                elapsed: viewModel.elapsed,
                accuracy: viewModel.accuracy,
                maxCombo: viewModel.maxCombo,
                bestTime: viewModel.bestTime,
                isNewBestTime: viewModel.isNewBestTime,
                lossReasonText: viewModel.lossReasonText,
                milestoneText: milestoneMessage,
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

    // MARK: - HUD

    private var gameHud: some View {
        VStack(spacing: DS.Spacing.sm + 2) {
            HStack(spacing: DS.Spacing.sm + 2) {
                if showsMovesHud {
                    hudTile(
                        icon: "arrow.left.arrow.right",
                        tint: DS.Color.brand,
                        label: "Moves",
                        value: movesText
                    )
                }

                hudTile(
                    icon: viewModel.rules.hasTimer ? "timer" : "clock.fill",
                    tint: DS.Color.accent,
                    label: viewModel.rules.hasTimer ? "Time left" : "Time",
                    value: timeText
                )

                hudTile(
                    icon: "square.grid.2x2.fill",
                    tint: DS.Color.success,
                    label: "Pairs",
                    value: "\(viewModel.matchedPairs)/\(viewModel.totalPairs)"
                )
            }

            if viewModel.livesEnabled {
                livesRow
            }
        }
        .padding(DS.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Color.surface)
                .dsShadow(.card)
        )
    }

    private var livesRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text("Lives")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: 5) {
                ForEach(0..<viewModel.maxLives, id: \.self) { index in
                    let alive = index < viewModel.livesRemaining
                    Image(systemName: alive ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(alive ? DS.Color.danger : DS.Color.track)
                        .scaleEffect(alive ? 1 : 0.85)
                }
            }
            .animation(DS.Motion.respecting(reduceMotion, DS.Motion.snappy), value: viewModel.livesRemaining)
            .modifier(ShakeEffect(shakes: livesShake))
        }
        .frame(maxWidth: .infinity)
        .onChange(of: viewModel.livesRemaining) { old, new in
            if new < old, !reduceMotion {
                withAnimation(.linear(duration: 0.4)) { livesShake += 2 }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.livesRemaining) of \(viewModel.maxLives) lives left")
    }

    private var objectiveBanner: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "target")
                .font(.caption.bold())
                .foregroundStyle(DS.Color.brand)
            Text(activeLevel.objective)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(DS.Color.brand.opacity(0.12))
        )
        .accessibilityLabel("Goal: \(activeLevel.objective)")
    }

    private var showsMovesHud: Bool {
        viewModel.rules.showsMoveCounter || viewModel.rules.maxMoves != nil
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

    private func hudTile(icon: String, tint: Color, label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.xs + 2) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundStyle(tint)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(1)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.sm + 2)
        .padding(.horizontal, DS.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(tint.opacity(0.1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value.replacingOccurrences(of: "/", with: " of "))")
    }

    // MARK: - Preview

    private var previewProgress: CGFloat {
        let total = CGFloat(viewModel.rules.previewSeconds)
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.previewSecondsLeft) / total
    }

    private var previewBanner: some View {
        HStack(spacing: DS.Spacing.lg - 2) {
            previewCountdownRing

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.xs + 2) {
                    Image(systemName: "eye.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(DS.Color.brand)
                    Text("Memorize!")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(DS.Gradient.accent)
                }

                Text(activeLevel.objective)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                previewSecondDots
            }

            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.lg - 2)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Color.surface)
                .dsShadow(.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [DS.Color.accent.opacity(0.35), DS.Color.brand.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memorize the cards. \(viewModel.previewSecondsLeft) seconds remaining")
        .onChange(of: viewModel.previewSecondsLeft) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                previewTickScale = 1.12
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.12)) {
                previewTickScale = 1
            }
        }
    }

    private var previewCountdownRing: some View {
        ProgressRing(
            progress: Double(previewProgress),
            lineWidth: 7,
            gradient: LinearGradient(
                colors: [DS.Color.warning, DS.Color.accent, DS.Color.brand],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            animation: DS.Motion.respecting(reduceMotion, .linear(duration: 0.95))
        ) {
            Text("\(viewModel.previewSecondsLeft)")
                .font(.DSText.timer)
                .monospacedDigit()
                .foregroundStyle(DS.Color.textPrimary)
                .contentTransition(.numericText())
                .scaleEffect(previewTickScale)
        }
        .frame(width: 76, height: 76)
    }

    private var previewSecondDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<viewModel.rules.previewSeconds, id: \.self) { index in
                Capsule()
                    .fill(index < viewModel.previewSecondsLeft
                          ? AnyShapeStyle(DS.Gradient.cta)
                          : AnyShapeStyle(DS.Color.track))
                    .frame(width: index < viewModel.previewSecondsLeft ? 13 : 6, height: 7)
                    .animation(DS.Motion.respecting(reduceMotion, DS.Motion.snappy), value: viewModel.previewSecondsLeft)
            }
        }
    }

    // MARK: - Overlays

    private var tutorialOverlay: some View {
        Dialog {
            Text("👋")
                .font(.system(size: 54))
            Text("How to play")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(DS.Color.textPrimary)
            Text("Tap two cards to flip them over and find the matching pairs. Match them all to win!")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Got it!", gradient: DS.Gradient.cta) {
                withAnimation(.easeInOut) { showTutorial = false }
                hasSeenTutorial = true
            }
            .padding(.top, DS.Spacing.xs)
        }
        .transition(.opacity)
    }

    private var pauseOverlay: some View {
        Dialog {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(DS.Color.brand)
            Text("Paused")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            PrimaryButton(title: "Resume", gradient: DS.Gradient.cta) {
                viewModel.isPaused = false
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
