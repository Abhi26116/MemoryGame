//
//  ResultView.swift
//  Memory Match Kids
//

import SwiftUI

struct ResultView: View {
    let levelTitle: String
    var levelWon: Bool = true
    var matchedPairs: Int = 0
    var totalPairs: Int = 0
    let stars: Int
    let moves: Int
    let elapsed: TimeInterval
    var accuracy: Int = 100
    var maxCombo: Int = 0
    var bestTime: TimeInterval = 0
    var isNewBestTime: Bool = false
    var lossReasonText: String? = nil
    var milestoneText: String? = nil
    var nextLevelUnlocked: Bool = false
    var nextLevelTitle: String?
    let onPlayAgain: () -> Void
    var onNextLevel: (() -> Void)?
    let onHome: () -> Void

    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DSScreenBackground()
            ConfettiView(isActive: levelWon).ignoresSafeArea()

            // No scrolling: pick the most comfortable layout that fits the
            // screen, falling back to a compact one on smaller devices / larger
            // text so everything stays on a single screen.
            ViewThatFits(in: .vertical) {
                resultStack(compact: false)
                resultStack(compact: true)
            }
            .padding(.horizontal, DS.Layout.screenPadding)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .onAppear {
            withAnimation(DS.Motion.respecting(reduceMotion, DS.Motion.spring)) {
                showContent = true
            }
        }
    }

    @ViewBuilder
    private func resultStack(compact: Bool) -> some View {
        VStack(spacing: compact ? DS.Spacing.sm : DS.Spacing.lg) {
            heroCard(compact: compact)
            if levelWon, let milestoneText {
                milestoneBanner(milestoneText)
            }
            unlockBanner
            rewardsCard(compact: compact)
            actionButtons
        }
        .padding(.vertical, compact ? DS.Spacing.sm : DS.Spacing.xl)
    }

    // MARK: - Hero

    private func heroCard(compact: Bool) -> some View {
        VStack(spacing: compact ? DS.Spacing.sm : DS.Spacing.lg) {
            ZStack {
                if levelWon {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DS.Color.star.opacity(0.55), DS.Color.star.opacity(0)],
                                center: .center,
                                startRadius: 2,
                                endRadius: compact ? 70 : 92
                            )
                        )
                        .frame(width: compact ? 150 : 190, height: compact ? 150 : 190)
                        .blur(radius: 6)
                        .scaleEffect(showContent ? 1 : 0.2)
                        .opacity(showContent ? 1 : 0)
                        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.bouncy).delay(0.05), value: showContent)
                }
                Text(levelWon ? "🎉" : "😅")
                    .font(.system(size: compact ? 44 : 60))
                    .scaleEffect(showContent ? 1 : 0.5)
                    .animation(DS.Motion.respecting(reduceMotion, DS.Motion.bouncy).delay(0.05), value: showContent)
            }
            .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xs + 2) {
                Text(levelWon ? "Level Complete!" : "Game Over!")
                    .font(compact ? .DSText.headline : .DSText.title)
                    .foregroundStyle(levelWon ? DS.Gradient.accent : DS.Gradient.cta)
                    .multilineTextAlignment(.center)

                if !levelWon, totalPairs > 0 {
                    Text("Matched \(matchedPairs) of \(totalPairs) pairs")
                        .font(.DSText.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Text(levelTitle)
                    .font(.DSText.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Spacing.md + 2)
                    .padding(.vertical, DS.Spacing.xs + 2)
                    .background(Capsule().fill(DS.Color.fill))
            }

            HStack(spacing: DS.Spacing.sm + 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: compact ? 30 : 36))
                        .foregroundStyle(i < stars ? DS.Color.star : DS.Color.track)
                        .shadow(color: i < stars ? DS.Color.star.opacity(0.5) : .clear, radius: 6, y: 2)
                        .scaleEffect(showContent ? 1 : 0.3)
                        .animation(
                            DS.Motion.respecting(reduceMotion, DS.Motion.bouncy).delay(0.12 + Double(i) * 0.08),
                            value: showContent
                        )
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(stars) of 3 stars earned")
        }
        .frame(maxWidth: .infinity)
        .dsCard(padding: compact ? DS.Spacing.md : DS.Spacing.xl, shadow: .elevated)
        .scaleEffect(showContent ? 1 : 0.92)
        .opacity(showContent ? 1 : 0)
        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring).delay(0.02), value: showContent)
    }

    // MARK: - Milestone

    private func milestoneBanner(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Gradient.accent)
                    .dsShadow(.elevated)
            )
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)
            .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring).delay(0.1), value: showContent)
    }

    // MARK: - Unlock banner

    @ViewBuilder
    private var unlockBanner: some View {
        if nextLevelUnlocked, let nextLevelTitle {
            HStack(spacing: DS.Spacing.sm + 2) {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(DS.Color.success)
                Text("\(nextLevelTitle) is now unlocked!")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.lg - 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Color.success.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(DS.Color.success.opacity(0.35), lineWidth: 1.5)
                    )
            )
            .scaleEffect(showContent ? 1 : 0.95)
            .opacity(showContent ? 1 : 0)
            .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring).delay(0.15), value: showContent)
        } else if !levelWon {
            HStack(spacing: DS.Spacing.sm + 2) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(DS.Color.warning)
                Text(lossReasonText ?? "Out of moves — play again to match all the pairs!")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.lg - 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Color.warning.opacity(0.15))
            )
        }
    }

    // MARK: - Stats

    private func rewardsCard(compact: Bool) -> some View {
        VStack(spacing: compact ? DS.Spacing.sm : DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm + 2) {
                StatCard(value: "\(moves)", label: "Moves",
                         icon: "arrow.left.arrow.right.circle.fill", axis: .horizontal)
                StatCard(value: formatElapsed(elapsed), label: "Time",
                         icon: "clock.fill", tint: DS.Color.accent, axis: .horizontal)
            }

            HStack(spacing: DS.Spacing.sm + 2) {
                StatCard(value: "\(accuracy)%", label: "Accuracy",
                         icon: "scope", tint: DS.Color.success, axis: .horizontal)
                StatCard(value: "×\(maxCombo)", label: "Combo",
                         icon: "flame.fill", tint: DS.Color.warning, axis: .horizontal)
            }

            if levelWon, isNewBestTime, bestTime > 0 {
                bestTimeRow
            }
        }
        .dsCard(shadow: .elevated)
        .scaleEffect(showContent ? 1 : 0.95)
        .opacity(showContent ? 1 : 0)
        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring).delay(0.2), value: showContent)
    }

    /// Only shown when the player beats their record — a small celebratory note.
    private var bestTimeRow: some View {
        HStack(spacing: DS.Spacing.sm + 2) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(DS.Color.star)
            Text("New Best Time!")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            Spacer(minLength: 0)
            Text(formatElapsed(bestTime))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(DS.Color.star)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(DS.Color.star.opacity(0.15))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New best time, \(formatElapsed(bestTime))")
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: DS.Spacing.md) {
            if nextLevelUnlocked, let onNextLevel {
                PrimaryButton(title: "Next Level", icon: "arrow.right.circle.fill",
                              gradient: DS.Gradient.accent, action: onNextLevel)
            }

            PrimaryButton(title: "Play Again", icon: "arrow.clockwise.circle.fill",
                          gradient: DS.Gradient.cta, action: onPlayAgain)

            Button(action: onHome) {
                Text("Back to Home")
                    .font(.DSText.button)
                    .foregroundStyle(DS.Color.link)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 16)
        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring).delay(0.28), value: showContent)
    }

    private func formatElapsed(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

#Preview {
    ResultView(
        levelTitle: "Level 1",
        stars: 2,
        moves: 4,
        elapsed: 6,
        nextLevelUnlocked: true,
        nextLevelTitle: "Level 2",
        onPlayAgain: {},
        onNextLevel: {},
        onHome: {}
    )
}
