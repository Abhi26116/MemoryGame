//
//  WelcomeView.swift
//  Memory Match Kids
//
//  One-time first-launch onboarding: a quick "how it works" page, then a
//  skippable "go ad-free" page. Kept to two pages — mechanics are still taught
//  in context by the Level 1 tutorial.
//

import SwiftUI

struct WelcomeView: View {
    /// Called when onboarding is finished (skipped, started, or purchased).
    let onFinish: () -> Void

    @State private var page = 0
    @ObservedObject private var store = StoreManager.shared
    @State private var showParentalGate = false

    var body: some View {
        ZStack {
            DSScreenBackground()

            TabView(selection: $page) {
                welcomePage.tag(0)
                removeAdsPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView {
                Task { await store.purchaseRemoveAds() }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: store.adsRemoved) { _, removed in
            if removed { onFinish() }
        }
    }

    // MARK: - Page 1 — welcome

    private var welcomePage: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.brand.opacity(0.22), DS.Color.accent.opacity(0.22)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Circle().stroke(DS.Gradient.accent, lineWidth: 2.5)
                Text("🧠")
                    .font(.system(size: 58))
                    .accessibilityHidden(true)
            }
            .frame(width: 112, height: 112)
            .dsShadow(.card)

            VStack(spacing: DS.Spacing.sm) {
                Text("Welcome to \(AppTheme.appName)")
                    .font(.DSText.largeTitle)
                    .foregroundStyle(DS.Gradient.accent)
                    .multilineTextAlignment(.center)
                Text("Train your memory with delightful, bite-sized levels.")
                    .font(.DSText.callout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: DS.Spacing.md) {
                featureRow(icon: "square.grid.2x2.fill", tint: DS.Color.brand,
                           title: "Flip & Match",
                           subtitle: "Find every matching pair to clear a level.")
                featureRow(icon: "star.fill", tint: DS.Color.star,
                           title: "Earn Stars",
                           subtitle: "Finish fast with few moves to earn 3 stars.")
                featureRow(icon: "lock.open.fill", tint: DS.Color.success,
                           title: "Unlock Levels",
                           subtitle: "Beat a level to open the next challenge.")
            }

            Spacer(minLength: 0)

            PrimaryButton(title: "Next", icon: "arrow.right") {
                withAnimation { page = 1 }
            }
        }
        .padding(.horizontal, DS.Layout.screenPadding)
        .padding(.top, DS.Spacing.xxl)
        .padding(.bottom, DS.Spacing.xxxl + DS.Spacing.md)
        .tag(0)
    }

    // MARK: - Page 2 — go ad-free (skippable)

    private var removeAdsPage: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(DS.Color.accent.opacity(0.16))
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DS.Color.accent)
            }
            .frame(width: 112, height: 112)

            VStack(spacing: DS.Spacing.sm) {
                Text("Play Ad-Free")
                    .font(.DSText.title)
                    .foregroundStyle(DS.Gradient.accent)
                    .multilineTextAlignment(.center)
                Text("Remove all ads with a one-time purchase and keep the focus on play. You can always do this later in Settings.")
                    .font(.DSText.callout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: DS.Spacing.sm) {
                PrimaryButton(title: "Remove Ads", icon: "heart.slash.fill") {
                    showParentalGate = true
                }
                Button { Task { await store.restore() } } label: {
                    Text("Restore Purchases")
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.link)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(store.isWorking)

                Button(action: onFinish) {
                    Text("Skip for now")
                        .font(.DSText.button)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, DS.Layout.screenPadding)
        .padding(.top, DS.Spacing.xxl)
        .padding(.bottom, DS.Spacing.xxxl + DS.Spacing.md)
        .tag(1)
    }

    private func featureRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(tint.opacity(0.16)))
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(subtitle)
                    .font(.DSText.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dsCard(padding: DS.Spacing.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
