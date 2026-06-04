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
    let score: Int
    let moves: Int
    var movesForTwoStars: Int = 0
    let elapsed: TimeInterval
    var nextLevelUnlocked: Bool = false
    var nextLevelTitle: String?
    let onPlayAgain: () -> Void
    var onNextLevel: (() -> Void)?
    let onHome: () -> Void

    @State private var showContent = false
    @Environment(\.colorScheme) private var colorScheme

    private var earnedBadge: BadgeTier? { BadgeTier.forStars(stars) }

    var body: some View {
        ZStack {
            celebrationBackground
            ConfettiView(isActive: levelWon).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroCard
                    unlockBanner
                    rewardsCard
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                showContent = true
            }
        }
    }

    // MARK: - Background

    private var celebrationBackground: some View {
        ZStack {
            AppTheme.skyGradient(for: colorScheme).ignoresSafeArea()
            Circle()
                .fill(Color(hex: "FF6B9D").opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -80, y: -120)
            Circle()
                .fill(Color(hex: "5B8DEF").opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 36)
                .offset(x: 100, y: 200)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 16) {
            Text(levelWon ? "🎉" : "😅")
                .font(.system(size: 64))
                .scaleEffect(showContent ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05), value: showContent)

            VStack(spacing: 6) {
                Text(levelWon ? "Level Complete!" : "Game Over!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: levelWon
                                ? [Color(hex: "FF6B9D"), Color(hex: "5B8DEF")]
                                : [Color(hex: "FF9500"), Color(hex: "FF5E3A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                if !levelWon, totalPairs > 0 {
                    Text("Matched \(matchedPairs) of \(totalPairs) pairs")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Text(levelTitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.chipUnselected(for: colorScheme)))
            }

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundStyle(i < stars ? Color(hex: "FFD60A") : Color(hex: "D4DEE8"))
                        .shadow(color: i < stars ? Color(hex: "FFD60A").opacity(0.5) : .clear, radius: 6, y: 2)
                        .scaleEffect(showContent ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.65).delay(0.12 + Double(i) * 0.08),
                            value: showContent
                        )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(resultCardBackground)
        .scaleEffect(showContent ? 1 : 0.92)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.02), value: showContent)
    }

    private var unlockNextLevelHint: String {
        if moves <= movesForTwoStars {
            return "You earned \(stars) star\(stars == 1 ? "" : "s"). Need 2 stars — try ≤ \(movesForTwoStars) moves."
        }
        return "Used \(moves) moves. Unlock next level with 2 stars: finish in ≤ \(movesForTwoStars) moves."
    }

    // MARK: - Unlock banner

    @ViewBuilder
    private var unlockBanner: some View {
        if stars >= HomeViewModel.starsRequiredToUnlockNext, nextLevelUnlocked, let nextLevelTitle {
            HStack(spacing: 10) {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                Text("\(nextLevelTitle) is now unlocked!")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color(hex: "1B7A3D"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "D4F8E2"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "34C759").opacity(0.35), lineWidth: 1.5)
                    )
            )
            .scaleEffect(showContent ? 1 : 0.95)
            .opacity(showContent ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showContent)
        } else if !levelWon {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(Color(hex: "FF9500"))
                Text("Out of moves — play again to match all the pairs!")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "FFF4E5"))
            )
        } else if stars < HomeViewModel.starsRequiredToUnlockNext, levelWon, movesForTwoStars > 0 {
            HStack(spacing: 10) {
                Image(systemName: "star.leadinghalf.filled")
                    .foregroundStyle(Color(hex: "FF9500"))
                Text(unlockNextLevelHint)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.chipUnselected(for: colorScheme))
            )
        }
    }

    // MARK: - Badge + stats

    private var rewardsCard: some View {
        HStack(alignment: .top, spacing: 14) {
            if let badge = earnedBadge {
                badgeColumn(badge)
            }

            VStack(spacing: 10) {
                statTile(icon: "star.circle.fill", color: "FFD60A", label: "Score", value: "\(score)")
                statTile(icon: "arrow.left.arrow.right.circle.fill", color: "5B8DEF", label: "Moves", value: "\(moves)")
                statTile(icon: "clock.fill", color: "FF6B9D", label: "Time", value: formatElapsed(elapsed))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(resultCardBackground)
        .scaleEffect(showContent ? 1 : 0.95)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: showContent)
    }

    private func badgeColumn(_ badge: BadgeTier) -> some View {
        VStack(spacing: 8) {
            BadgeView(tier: badge, size: 72)
            Text(badge.rawValue)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text("Badge")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(width: 88)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: badge.colorHex).opacity(0.12))
        )
    }

    private func statTile(icon: String, color: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: color))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.chipUnselected(for: colorScheme))
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if levelWon,
               stars >= HomeViewModel.starsRequiredToUnlockNext,
               nextLevelUnlocked, let onNextLevel {
                resultButton(
                    title: "Next Level",
                    icon: "arrow.right.circle.fill",
                    gradient: AppTheme.primaryGradient,
                    action: onNextLevel
                )
            }

            resultButton(
                title: "Play Again",
                icon: "arrow.clockwise.circle.fill",
                gradient: AppTheme.playButtonGradient,
                action: onPlayAgain
            )

            Button(action: onHome) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text("Back to Home")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(AppTheme.linkBlue)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.minTouchTarget)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.28), value: showContent)
    }

    private func resultButton(
        title: String,
        icon: String,
        gradient: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.bold())
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            )
        }
        .buttonStyle(.plain)
    }

    private var resultCardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .fill(AppTheme.cardSurface(for: colorScheme))
            .shadow(color: Color(hex: "5B8DEF").opacity(0.12), radius: 16, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color(hex: "B8E6FF").opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
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
        score: 293,
        moves: 4,
        elapsed: 6,
        nextLevelUnlocked: true,
        nextLevelTitle: "Level 2",
        onPlayAgain: {},
        onNextLevel: {},
        onHome: {}
    )
}
