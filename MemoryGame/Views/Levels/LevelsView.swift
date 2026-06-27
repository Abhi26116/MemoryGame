//
//  LevelsView.swift
//  Memory Match Kids
//
//  Full level browser, reached from Settings → All Levels. Extracted from the
//  Home screen so the level list gets a dedicated, scrollable surface instead of
//  being stacked beneath the Home dashboard.
//

import SwiftUI

struct LevelsView: View {
    /// Observed so unlocks/stars update live after finishing a level.
    @ObservedObject var progressStore: ProgressStore
    @StateObject private var viewModel: HomeViewModel

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        _viewModel = StateObject(wrappedValue: HomeViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.sm + 2) {
                ForEach(viewModel.visibleLevels) { level in
                    if viewModel.isUnlocked(level) {
                        NavigationLink {
                            GameView(level: level, progressStore: progressStore)
                        } label: {
                            levelRow(level, locked: false)
                        }
                        .buttonStyle(.pressable)
                    } else {
                        levelRow(level, locked: true)
                    }
                }
            }
            .padding(.horizontal, DS.Layout.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .dsScreenBackground()
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
        .kidBackButton()
    }

    private func levelRow(_ level: LevelModel, locked: Bool) -> some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            levelNumberBadge(level: level, locked: locked)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(level.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(locked ? DS.Color.textSecondary : DS.Color.textPrimary)
                    .lineLimit(1)

                if let hint = viewModel.unlockHint(for: level) {
                    Text(hint)
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(level.subtitle)
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(level.objective)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(DS.Color.link)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !locked {
                levelTrailingActions(level: level)
            }
        }
        .dsCard(padding: DS.Spacing.md)
        .opacity(locked ? 0.65 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: level, locked: locked))
        .accessibilityHint(locked ? "" : "Double tap to play")
        .accessibilityAddTraits(locked ? [] : .isButton)
    }

    private func accessibilityLabel(for level: LevelModel, locked: Bool) -> String {
        if locked {
            let hint = viewModel.unlockHint(for: level) ?? "Locked"
            return "\(level.title), locked. \(hint)"
        }
        let stars = viewModel.stars(for: level.id)
        let status = viewModel.isCompleted(level.id)
            ? "Completed, \(stars) of 3 stars"
            : "Not played yet"
        return "\(level.title). \(status). \(level.objective)"
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
        VStack(spacing: DS.Spacing.xs + 2) {
            StarRatingView(stars: viewModel.stars(for: level.id), size: 11)
            if viewModel.isCompleted(level.id) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(DS.Color.success)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(DS.Color.link)
            }
        }
        .frame(width: 52)
    }

    private func levelGradient(_ number: Int) -> LinearGradient {
        let colors: [Color] = [DS.Color.accent, DS.Color.brand, DS.Color.success, DS.Color.warning]
        let c = colors[(number - 1) % colors.count]
        return LinearGradient(colors: [c, c.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
