//
//  AchievementView.swift
//  Memory Match Kids
//

import SwiftUI

struct AchievementView: View {
    @StateObject private var viewModel: ProgressViewModel

    init(progressStore: ProgressStore) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressBarView(
                    progress: viewModel.progressFraction,
                    label: "Overall progress"
                )
                .padding(.horizontal, 4)

                ForEach(viewModel.achievements, id: \.0.id) { achievement, unlocked in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(unlocked ? AppTheme.primaryGradient : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 52, height: 52)
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundStyle(unlocked ? .white : .gray)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(achievement.title)
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(achievement.description)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                            .foregroundStyle(unlocked ? AppTheme.successGreen : .gray)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.cardSurface)
                    )
                    .foregroundStyle(AppTheme.textPrimary)
                    .opacity(unlocked ? 1 : 0.75)
                    .accessibilityLabel("\(achievement.title). \(unlocked ? "Unlocked" : "Locked")")
                }
            }
            .padding(20)
        }
        .kidBackground()
        .navigationTitle("Achievements")
    }
}
