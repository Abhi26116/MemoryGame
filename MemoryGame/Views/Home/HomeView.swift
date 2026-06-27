//
//  HomeView.swift
//  Memory Match Kids
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject private var store = StoreManager.shared
    /// Observed (not a plain `let`) so the level list re-renders the moment a win
    /// updates progress — otherwise the next level stays visually locked until relaunch.
    @ObservedObject var progressStore: ProgressStore
    @State private var showRemoveAdsPrompt = false
    @State private var showParentalGate = false
    /// Soft Remove-Ads nudge is shown at most once, after the player has gotten
    /// some value from the game. Never repeats or blocks play.
    @AppStorage("hasSeenRemoveAdsPrompt") private var hasSeenRemoveAdsPrompt = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                header
                progressCard
                if let next = viewModel.suggestedLevel {
                    playNextLevel(next)
                }
                dailyHighlightCard
            }
            .padding(.horizontal, DS.Layout.screenPadding)
            .padding(.top, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xxxl)
        }
        .dsScreenBackground()
        .safeAreaInset(edge: .bottom) {
            if !store.adsRemoved {
                BannerAdView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Color.surface)
            }
        }
        .overlay {
            if showRemoveAdsPrompt {
                removeAdsPrompt
            }
        }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView {
                Task { await store.purchaseRemoveAds() }
            }
            .presentationDetents([.medium])
        }
        .onAppear(perform: maybeShowRemoveAdsPrompt)
    }

    private func maybeShowRemoveAdsPrompt() {
        guard !store.adsRemoved, !hasSeenRemoveAdsPrompt,
              progressStore.completedLevels >= 3 else { return }
        hasSeenRemoveAdsPrompt = true   // mark immediately so it never nags
        showRemoveAdsPrompt = true
    }

    private var removeAdsPrompt: some View {
        Dialog {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(DS.Color.accent)
            Text("Enjoying \(AppTheme.appName)?")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Remove ads forever with a one-time purchase and keep the focus on play.")
                .font(.DSText.callout)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Remove Ads", icon: "heart.slash.fill") {
                showRemoveAdsPrompt = false
                showParentalGate = true
            }
            Button {
                showRemoveAdsPrompt = false
            } label: {
                Text("Maybe Later")
                    .font(.DSText.button)
                    .foregroundStyle(DS.Color.link)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .transition(.opacity)
    }

    private var header: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.brand.opacity(0.22), DS.Color.accent.opacity(0.22)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .stroke(DS.Gradient.accent, lineWidth: 2.5)
                Text("🧠")
                    .font(.system(size: 48))
                    .accessibilityHidden(true)
            }
            .frame(width: 96, height: 96)
            .dsShadow(.card)

            VStack(spacing: DS.Spacing.xs) {
                Text(AppTheme.appName)
                    .font(.DSText.largeTitle)
                    .foregroundStyle(DS.Gradient.accent)
                    .shadow(color: DS.Color.accent.opacity(0.35), radius: 12, y: 4)
                    .multilineTextAlignment(.center)
                Text("Complete a level to unlock the next one!")
                    .font(.DSText.callout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, DS.Spacing.sm)
    }

    private var progressCard: some View {
        DSCard {
            SectionHeader(title: "Your Journey", icon: "map.fill")
            HStack(spacing: DS.Spacing.sm + 2) {
                StatCard(value: "\(viewModel.completedLevels)", label: "Completed",
                         icon: "flag.checkered")
                StatCard(value: "\(viewModel.totalStars)", label: "Stars",
                         icon: "star.fill", tint: DS.Color.star)
                StatCard(value: "\(progressStore.goldLevels)", label: "Gold",
                         icon: "crown.fill", tint: DS.Color.warning)
            }
        }
    }

    private var dailyHighlightCard: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(DS.Color.star)
                .frame(width: 44, height: 44)
                .background(Circle().fill(DS.Color.star.opacity(0.16)))
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Tip of the Day")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DS.Color.sectionTitle)
                Text(viewModel.dailyTip)
                    .font(.DSText.callout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dsCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tip of the day. \(viewModel.dailyTip)")
    }

    private func playNextLevel(_ level: LevelModel) -> some View {
        NavigationLink {
            GameView(level: level, progressStore: progressStore)
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text("Continue")
                        .font(.DSText.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .textCase(.uppercase)
                    Text(level.title)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(level.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Gradient.cta)
                    .dsShadow(.elevated)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Continue, \(level.title)")
        .accessibilityHint("Plays your next level")
        .accessibilityAddTraits(.isButton)
    }

}
