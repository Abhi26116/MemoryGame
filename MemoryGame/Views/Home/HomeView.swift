//
//  HomeView.swift
//  Memory Match Kids
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject private var store = StoreManager.shared
    let progressStore: ProgressStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                progressCard
                if let next = viewModel.suggestedLevel {
                    playNextLevel(next)
                }
                levelsList
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .bottom) {
            if !store.adsRemoved {
                BannerAdView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardSurface(for: colorScheme))
            }
        }
        .kidBackground()
        .overlay(alignment: .topLeading) {
            NavigationLink {
                AchievementView(progressStore: progressStore)
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "FFD60A"))
                    .padding(12)
                    .background(Circle().fill(AppTheme.cardSurface(for: colorScheme).opacity(0.95)))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.top, 8)
            .padding(.leading, 20)
            .accessibilityLabel("Awards")
        }
        .overlay(alignment: .topTrailing) {
            NavigationLink {
                SettingsView(progressStore: progressStore)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.sectionTitle(for: colorScheme))
                    .padding(12)
                    .background(Circle().fill(AppTheme.cardSurface(for: colorScheme).opacity(0.95)))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.top, 8)
            .padding(.trailing, 20)
            .accessibilityLabel("Settings")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🧠")
                .font(.system(size: 52))
            Text(AppTheme.appName)
                .font(AppTheme.titleFont)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B9D"), Color(hex: "5B8DEF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
            Text("Complete a level to unlock the next one!")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your Journey", systemImage: "map.fill")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.sectionTitle(for: colorScheme))
            HStack(spacing: 12) {
                miniStat("\(viewModel.completedLevels)/\(viewModel.totalLevels)", "Levels", "flag.checkered")
                miniStat("\(viewModel.totalStars)", "Stars", "star.fill")
            }
            ProgressBarView(
                progress: viewModel.progressFraction,
                label: "Overall progress"
            )
        }
        .padding(16)
        .background(cardBackground)
        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
    }

    private func playNextLevel(_ level: LevelModel) -> some View {
        NavigationLink {
            GameView(level: level, progressStore: progressStore)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(level.title)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.playButtonGradient)
                    .shadow(color: Color(hex: "FF5E3A").opacity(0.35), radius: 10, y: 5)
            )
        }
        .buttonStyle(.plain)
    }

    private var levelsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Levels")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.sectionTitle(for: colorScheme))

            LazyVStack(spacing: 10) {
                ForEach(viewModel.levels) { level in
                    if viewModel.isUnlocked(level) {
                        NavigationLink {
                            GameView(level: level, progressStore: progressStore)
                        } label: {
                            levelRow(level, locked: false)
                        }
                        .buttonStyle(.plain)
                    } else {
                        levelRow(level, locked: true)
                    }
                }
            }
        }
    }

    private func levelRow(_ level: LevelModel, locked: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            levelNumberBadge(level: level, locked: locked)

            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(locked ? AppTheme.textSecondary(for: colorScheme) : AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                if let hint = viewModel.unlockHint(for: level) {
                    Text(hint)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(level.subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(level.objective)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !locked {
                levelTrailingActions(level: level)
            }
        }
        .padding(12)
        .background(cardBackground)
        .opacity(locked ? 0.65 : 1)
        .accessibilityLabel(locked ? "\(level.title), locked" : level.title)
    }

    private func levelNumberBadge(level: LevelModel, locked: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    locked
                        ? LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                        : levelGradient(level.levelNumber)
                )
                .frame(width: 44, height: 44)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            } else {
                Text("\(level.levelNumber)")
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
            }
        }
    }

    private func levelTrailingActions(level: LevelModel) -> some View {
        VStack(spacing: 6) {
            StarRatingView(stars: viewModel.stars(for: level.id), size: 11)
            if viewModel.isCompleted(level.id) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(AppTheme.successGreen)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
            }
        }
        .frame(width: 52)
    }

    private func miniStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.chipUnselected(for: colorScheme)))
    }

    private func levelGradient(_ number: Int) -> LinearGradient {
        let colors: [Color] = [
            Color(hex: "FF6B9D"), Color(hex: "5B8DEF"), Color(hex: "34C759"), Color(hex: "FF9500")
        ]
        let c = colors[(number - 1) % colors.count]
        return LinearGradient(colors: [c, c.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .fill(AppTheme.cardSurface(for: colorScheme))
            .shadow(color: .black.opacity(AppTheme.cardShadowOpacity(for: colorScheme)), radius: 8, y: 4)
    }
}
