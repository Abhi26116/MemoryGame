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
    @State private var showRemoveAdsShowcase = false
    /// Soft Remove-Ads nudge is shown at most once, after the player has gotten
    /// some value from the game. Never repeats or blocks play. Shares
    /// `RemoveAdsPromptGate`'s daily mark with the recurring showcase (RootView)
    /// so a player is never shown two ad-free pitches on the same day.
    @AppStorage("hasSeenRemoveAdsPrompt") private var hasSeenRemoveAdsPrompt = false
    // Captured from GeometryReader, but only re-adopted when the WIDTH also
    // changes (a real rotation/size-class change — the app supports
    // landscape). The tab bar's reserved space taking a moment to settle on
    // every pop back to Home only ever perturbs HEIGHT, never width, so
    // gating on width change makes the centering below immune to that
    // transient reflow (which used to visibly re-center/slide this content)
    // while still adapting correctly on an actual rotation.
    @State private var stableContentHeight: CGFloat = 0
    @State private var stableContentWidth: CGFloat = 0

    var body: some View {
        // On iPad the dashboard is a readable-width column, centered both ways —
        // full-bleed cards on a 10"+ canvas left a big dead zone below the Tip
        // card. On iPhone this changes nothing: the column cap exceeds the
        // screen width and the content already fills the height.
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    header
                    progressCard
                    if let next = viewModel.suggestedLevel {
                        playNextLevel(next)
                    }
                    dailyHighlightCard
                }
                .frame(maxWidth: DS.Layout.contentMaxWidth)
                .padding(.horizontal, DS.Layout.screenPadding)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.lg)
                .frame(
                    maxWidth: .infinity,
                    minHeight: stableContentHeight > 0 ? stableContentHeight : geo.size.height,
                    alignment: .center
                )
            }
            .onAppear {
                stableContentHeight = geo.size.height
                stableContentWidth = geo.size.width
            }
            .onChange(of: geo.size.width) { _, newWidth in
                guard newWidth != stableContentWidth else { return }
                stableContentWidth = newWidth
                stableContentHeight = geo.size.height
            }
        }
        .dsScreenBackground()
        .fullScreenCover(isPresented: $showRemoveAdsShowcase) {
            RemoveAdsShowcaseView { showRemoveAdsShowcase = false }
        }
        .onAppear(perform: maybeShowRemoveAdsPrompt)
    }

    private func maybeShowRemoveAdsPrompt() {
        guard !store.adsRemoved, !hasSeenRemoveAdsPrompt,
              progressStore.completedLevels >= 3,
              !RemoveAdsPromptGate.shownToday() else { return }
        hasSeenRemoveAdsPrompt = true   // mark immediately so it never nags
        RemoveAdsPromptGate.markShownToday()
        showRemoveAdsShowcase = true
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
                    .font(.system(size: DS.Layout.isPad ? 62 : 48))
                    .accessibilityHidden(true)
            }
            .frame(width: DS.Layout.isPad ? 124 : 96, height: DS.Layout.isPad ? 124 : 96)
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
