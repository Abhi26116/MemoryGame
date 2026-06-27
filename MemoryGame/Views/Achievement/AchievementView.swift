//
//  AchievementView.swift
//  Memory Match Kids
//

import SwiftUI

struct AchievementView: View {
    /// Observed so newly-unlocked achievements appear without leaving the tab.
    @ObservedObject var progressStore: ProgressStore
    @StateObject private var viewModel: ProgressViewModel

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        _viewModel = StateObject(wrappedValue: ProgressViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                ForEach(viewModel.achievements, id: \.0.id) { achievement, unlocked in
                    HStack(spacing: DS.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(unlocked
                                      ? AnyShapeStyle(DS.Gradient.brand)
                                      : AnyShapeStyle(Color.gray.opacity(0.3)))
                                .frame(width: 52, height: 52)
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundStyle(unlocked ? .white : .gray)
                        }
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(achievement.title)
                                .font(.DSText.headline)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text(achievement.description)
                                .font(.DSText.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                            .foregroundStyle(unlocked ? DS.Color.success : .gray)
                    }
                    .dsCard()
                    .opacity(unlocked ? 1 : 0.75)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(achievement.title). \(achievement.description). \(unlocked ? "Unlocked" : "Locked")")
                }
            }
            .padding(DS.Layout.screenPadding)
        }
        .dsScreenBackground()
        .navigationTitle("Achievements")
    }
}
