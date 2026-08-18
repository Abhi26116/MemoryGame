//
//  GameView.swift
//  Memory Match Kids
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @ObservedObject private var ads = AdsManager.shared
    @ObservedObject private var store = StoreManager.shared
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
    @Environment(\.scenePhase) private var scenePhase
    // Returning from the lock screen (or Control Center / notification pull-
    // down) can leave `cardGrid`'s GeometryReader holding a stale size from
    // right before the app went to the background — cards would visibly
    // resize a beat later, but only once SOME other interaction (e.g. a
    // scroll) forced SwiftUI to recompute layout. Changing this `.id()` on
    // scenePhase becoming active again forces `cardGrid` to be torn down and
    // freshly measured immediately, instead of waiting on an unrelated nudge.
    @State private var layoutRefreshID = UUID()

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
        ZStack {
            DSScreenBackground()

            VStack(spacing: 0) {
                gameHud
                    .frame(maxWidth: DS.Layout.contentMaxWidth)
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.sm)
                    .padding(.bottom, viewModel.isPreviewPhase ? DS.Spacing.sm : DS.Spacing.md)

                if viewModel.isPreviewPhase {
                    previewBanner
                        .frame(maxWidth: DS.Layout.contentMaxWidth)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.bottom, DS.Spacing.sm + 2)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    objectiveBanner
                        .frame(maxWidth: DS.Layout.contentMaxWidth)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.bottom, DS.Spacing.sm + 2)
                }

                cardGrid
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
        // Forces the WHOLE main content (including cardGrid's GeometryReader)
        // to be torn down and freshly remeasured whenever layoutRefreshID
        // changes — deliberately scoped to just this ZStack, NOT the
        // `.safeAreaInset` content below: that hosts the live `BannerAdView`,
        // and resetting ITS identity would tear down and reload the ad that
        // just finished loading (repeating forever, since a fresh load would
        // re-trigger the same refresh).
        .id(layoutRefreshID)
        // Reserves space at the bottom BEFORE the grid above it is measured, so
        // the GeometryReader's height already excludes the banner — cards never
        // size themselves into the space the ad ends up occupying.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerSlot(adsRemoved: store.adsRemoved)
        }
        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring), value: viewModel.isPreviewPhase)
        .onAppear {
            if activeLevel.levelNumber == 1 && !hasSeenTutorial {
                showTutorial = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                layoutRefreshID = UUID()
            }
        }
        // Deliberately NOT reacting to `ads.bannerIsVisible` here anymore —
        // `AdBannerSlot` now reserves its 50pt immediately regardless of
        // whether the ad has actually loaded (see its doc comment), so the
        // grid's available height no longer changes when the ad comes in.
        // This used to force a full `cardGrid` remount at that exact moment,
        // which was the actual glitch: cards visibly popping/shrinking ~1.3s
        // after the screen appeared, right as the ad loaded in.
        .navigationBarTitleDisplayMode(.inline)
        // Reverted from a custom `TabBarHider` (UIViewControllerRepresentable
        // walking up to `tabBarController`) back to this — SwiftUI's TabView
        // isn't guaranteed to be backed by a real UITabBarController, so that
        // walk-up could silently resolve to nil and hide NOTHING, which is
        // almost certainly why the tab bar was visibly showing on the game
        // screen (and fighting the grid/banner for space, explaining a lot of
        // the layout jumping). This is the official, reliably-working API;
        // its only downside is a brief blank gap where the tab bar should be
        // right after popping back to Home — a much smaller problem.
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
                // Hidden during the memorize countdown — there's nothing to
                // pause yet (the gameplay timer hasn't started), so the
                // button had no real function there.
                if !viewModel.isPreviewPhase {
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
        }
        .onAppear {
            // SHOT-TEMP
            if ProcessInfo.processInfo.environment["SHOT_AUTOPLAY"] != nil { viewModel.startAutoPlay() }
            if ProcessInfo.processInfo.environment["SHOT_WIN"] != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showResult = true }
            }
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished {
                AdsManager.shared.handleLevelFinished(
                    adsRemoved: store.adsRemoved
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
                eligibleForReviewPrompt: progressStore.completedLevels >= 5,
                onPlayAgain: {
                    showResult = false
                    viewModel.reset()
                },
                onWatchAdToContinue: (viewModel.canWatchAdToContinue && ads.rewardedAdAvailable) ? {
                    AdsManager.shared.showRewardedAd(onReward: {
                        viewModel.continueAfterAd()
                        showResult = false
                    }, onClosed: {})
                } : nil,
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

    // MARK: - Grid

    /// Sized from the ACTUAL leftover space below the HUD/banner — measured
    /// via `GeometryReader` here, rather than the whole screen's height minus
    /// a hand-picked "how much chrome is above the grid" estimate. The old
    /// estimate had to be one fixed number for both the compact objective
    /// banner AND the taller preview banner, so it was never quite right for
    /// both — cards (and their card-scaled fonts) ended up sized differently
    /// between the two, which read as preview text being smaller/blurrier
    /// than gameplay for the exact same level. Measuring what's actually left
    /// makes that impossible: whatever real height the HUD + banner take,
    /// this is exactly what's left, every time.
    private var cardGrid: some View {
        GeometryReader { geo in
            let spacing: CGFloat = DS.Spacing.sm
            let cols = CGFloat(viewModel.columns)
            let rows = CGFloat(viewModel.rows)
            let horizontalPad: CGFloat = DS.Layout.screenPadding
            let verticalPad: CGFloat = DS.Spacing.md
            let availableWidth = max(0, geo.size.width - horizontalPad * 2)
            let availableHeight = max(0, geo.size.height - verticalPad * 2)
            // A card renders taller than it is wide (art plus its caption).
            // This is the ratio the height-based sizing budgets for; naming it
            // matters because anything else that reasons about total grid
            // height has to use the same figure or the bottom row overflows.
            let cardAspect: CGFloat = 1.15
            let widthBasedCardSize = (availableWidth - spacing * (cols - 1)) / cols
            let heightBasedCardSize = (availableHeight - spacing * (rows - 1)) / rows / cardAspect
            // Absolute cap too: sparse grids (2x2, 2x3) on iPad would otherwise
            // produce comically huge cards. 200pt is above anything an iPhone's
            // width can yield, so phones are unaffected by the cap.
            let maxCardSize: CGFloat = 200
            // Floored to a whole point so sub-pixel changes in the space above
            // the grid can't retrigger a relayout of every card.
            let cardWidth = max(44, min(widthBasedCardSize, heightBasedCardSize, maxCardSize))
                .rounded(.down)
            // Constrain the grid to its natural width so capped cards form a
            // tight centered block instead of spreading across the screen.
            let gridWidth = cardWidth * cols + spacing * (cols - 1)
            // Row and column gaps are deliberately the SAME value. An earlier
            // attempt padded the row gaps out to absorb the leftover vertical
            // space, which did fill the board area but made the grid read as
            // separated rows rather than one block — worse than the gap it
            // removed. A board is width-constrained on these aspect ratios, so
            // some leftover height is unavoidable; it stays centered below.
            // Explicit VStack-of-HStacks, NOT a LazyVGrid.
            //
            // LazyVGrid derives its row heights from cell content it measures
            // lazily, so while anything above the board was still settling it
            // could place rows closer together than the cards were tall — the
            // bottom row drew straight over the labels of the row above. It was
            // intermittent, which made it survive several rounds of "fixed".
            //
            // A board is at most 30 cards, so laziness buys nothing here. Here
            // every row is pinned to exactly `cardWidth * cardAspect` and every
            // gap to exactly `spacing`, in both directions, so the rows cannot
            // collide no matter what the surrounding layout is doing.
            VStack(spacing: spacing) {
                ForEach(0..<viewModel.rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<viewModel.columns, id: \.self) { column in
                            let index = row * viewModel.columns + column
                            if index < viewModel.cards.count {
                                MemoryCardView(
                                    card: viewModel.cards[index],
                                    size: cardWidth,
                                    largeText: viewModel.accessibilityLargeText,
                                    highContrast: viewModel.highContrast,
                                    colorBlindMode: viewModel.colorBlindMode,
                                    cardBackStyle: cardBackStyle,
                                    labelFontSize: cardLabelFontSize
                                ) {
                                    if viewModel.canInteract {
                                        viewModel.tapCard(at: index)
                                    }
                                }
                                .id(viewModel.cards[index].id)
                            } else {
                                Color.clear
                                    .frame(width: cardWidth, height: cardWidth * cardAspect)
                            }
                        }
                    }
                    .frame(height: cardWidth * cardAspect)
                }
            }
            .allowsHitTesting(viewModel.canInteract)
            .frame(width: gridWidth)
            .frame(width: geo.size.width, height: geo.size.height)
            // NO implicit animation on `cardWidth`. The grid resizes once per
            // level, when the taller memorize banner gives way to the one-line
            // objective banner; animating every card's frame through that made
            // the resize a moving target for layout. It now happens in one step.
            // Per-card flip, pulse and shake animations are unaffected — they
            // live in MemoryCardView and don't touch layout.
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
                        .font(.system(size: DS.Layout.isPad ? 20 : 16, weight: .bold))
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
            // Always laid out (never conditionally inserted/removed) — an
            // `if` here made the objective text reflow to a different number
            // of lines depending on whether the chip was competing for
            // width, which changed the WHOLE banner's height every time hint
            // availability toggled (i.e. constantly during play) and made
            // the card grid below it resize along with it. Hiding via
            // opacity keeps the reserved width constant either way.
            hintButton
                .opacity(viewModel.canUseHint && ads.rewardedAdAvailable ? 1 : 0)
                .allowsHitTesting(viewModel.canUseHint && ads.rewardedAdAvailable)
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

    private var hintButton: some View {
        Button {
            AdsManager.shared.showRewardedAd(onReward: {
                viewModel.revealHint()
            }, onClosed: {})
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .bold))
                // Always a single digit (max 4 hints) — the count showing
                // or changing never affects this chip's width/height, which
                // matters here since the whole objective banner reflows
                // around it (see the `hintButton` call site's note).
                Text("Hint ×\(max(1, viewModel.hintsRemaining))")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
            }
            .foregroundStyle(DS.Color.warning)
            .padding(.horizontal, DS.Spacing.sm + 2)
            .padding(.vertical, DS.Spacing.xs + 2)
            .background(Capsule().fill(DS.Color.warning.opacity(0.18)))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Watch an ad for a hint, \(viewModel.hintsRemaining) remaining")
    }

    /// One label font size for the WHOLE grid, sized to the longest label
    /// among the dealt cards — otherwise each card shrinks its own text
    /// independently based on its own word length, so a short word like
    /// "Dice" renders visibly bigger than "Carousel" right next to it.
    // A fixed size for every card's label — NOT reduced based on the
    // longest label on the board. That tiered reduction was overly
    // cautious: on a board like "Toys" (longest label "Carousel", 8
    // letters), it dragged EVERY card's label down from 11pt to 9pt, even
    // short ones like "Dice" that never needed to shrink — 8-letter bold
    // rounded text fits a card's width fine at 11pt without wrapping. That
    // unnecessary shrink read as the whole board's text going blurry/small.
    // `MemoryCardView`'s own `.lineLimit(2)` + `.minimumScaleFactor(0.6)`
    // is still there as a per-card safety net for a genuinely long label.
    private var cardLabelFontSize: CGFloat {
        viewModel.accessibilityLargeText ? 14 : 11
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
                .font(.system(size: DS.Layout.isPad ? 13 : 10, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(1)

            Text(value)
                .font(.system(size: DS.Layout.isPad ? 19 : 15, weight: .bold, design: .rounded))
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
        .frame(width: DS.Layout.isPad ? 96 : 76, height: DS.Layout.isPad ? 96 : 76)
    }

    /// Reserved width for the dots row: every dot at its ACTIVE width.
    ///
    /// A spent dot is narrower than an active one, so without a reservation the
    /// row shrank by 7pt on every countdown tick. That shrank the banner's
    /// VStack, which re-wrapped the objective text next to it, which changed the
    /// banner's HEIGHT, which changed the height left for `cardGrid` — and the
    /// resulting animated card resize made grid rows visibly overlap each other
    /// once a second during the memorize phase.
    private var previewDotsWidth: CGFloat {
        let count = CGFloat(viewModel.rules.previewSeconds)
        guard count > 0 else { return 0 }
        return count * 13 + (count - 1) * 3
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
            Spacer(minLength: 0)
        }
        .frame(width: previewDotsWidth, alignment: .leading)
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
