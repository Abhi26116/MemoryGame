//
//  RemoveAdsShowcaseView.swift
//  Memory Match Kids
//
//  A premium, benefit-led "Remove Ads" showcase. Used as both the one-time
//  milestone nudge (Home, after a few completed levels) and the recurring
//  once-a-day reminder (app launch) — one screen, two trigger points, so the
//  pitch always looks and feels the same. Always dismissible (explicit close
//  button — full-screen covers don't support swipe-to-dismiss) and routes any
//  purchase through the existing parental gate.
//

import SwiftUI

struct RemoveAdsShowcaseView: View {
    /// Called when the player dismisses the screen, whether by closing it or
    /// after a successful purchase.
    let onDismiss: () -> Void

    @ObservedObject private var store = StoreManager.shared
    @State private var showParentalGate = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DSScreenBackground()

            VStack(spacing: 0) {
                closeButton

                Spacer(minLength: 0)

                heroSection
                    .padding(.bottom, DS.Spacing.xl)

                VStack(spacing: DS.Spacing.md) {
                    benefitRow(icon: "bolt.slash.fill", tint: DS.Color.brand,
                               title: "No Interruptions",
                               subtitle: "Play level after level without a single ad break.")
                    benefitRow(icon: "heart.fill", tint: DS.Color.accent,
                               title: "Support the Game",
                               subtitle: "Your purchase directly funds new levels and features.")
                    benefitRow(icon: "checkmark.seal.fill", tint: DS.Color.success,
                               title: "Pay Once, Keep Forever",
                               subtitle: "No subscription — a single purchase, forever ad-free.")
                }
                .padding(.horizontal, DS.Layout.screenPadding)

                Spacer(minLength: 0)

                actionSection
                    .padding(.horizontal, DS.Layout.screenPadding)
                    .padding(.bottom, DS.Spacing.xl)
            }
            .frame(maxWidth: DS.Layout.contentMaxWidth)
            .scaleEffect(appeared ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
        }
        .dsIPadTypeScale()
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onAppear {
            withAnimation(DS.Motion.respecting(reduceMotion, DS.Motion.spring)) {
                appeared = true
            }
        }
        .task {
            // Re-fetch every time this screen shows, not just once at app
            // launch — covers the case where the first fetch had no network
            // yet, or this is the first moment StoreKit is actually needed.
            if store.removeAdsProduct == nil {
                await store.loadProduct()
            }
        }
        .onChange(of: store.adsRemoved) { _, removed in
            if removed { onDismiss() }
        }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView {
                Task { await store.purchaseRemoveAds() }
            }
            .presentationDetents([.medium])
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            IconButton(systemName: "xmark", tint: DS.Color.textSecondary,
                       size: 36, accessibilityLabel: "Close") {
                onDismiss()
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.sm)
    }

    private var heroSection: some View {
        VStack(spacing: DS.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DS.Color.accent.opacity(0.5), DS.Color.accent.opacity(0)],
                            center: .center, startRadius: 4, endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 4)
                Circle()
                    .fill(DS.Gradient.accent)
                    .frame(width: DS.Layout.isPad ? 132 : 108, height: DS.Layout.isPad ? 132 : 108)
                    .dsShadow(.elevated)
                Image(systemName: "sparkles")
                    .font(.system(size: DS.Layout.isPad ? 58 : 46, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xs) {
                Text("Go Ad-Free")
                    .font(.DSText.largeTitle)
                    .foregroundStyle(DS.Gradient.accent)
                    .multilineTextAlignment(.center)
                Text("Unlock the calmest way to play \(AppTheme.appName).")
                    .font(.DSText.callout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func benefitRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: DS.Layout.isPad ? 52 : 44, height: DS.Layout.isPad ? 52 : 44)
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

    /// "Remove Ads" while the price is still loading, "Remove Ads — $2.99"
    /// (localized) once StoreKit has it — never a bare, confusing dash.
    private var ctaTitle: String { store.removeAdsButtonTitle }

    private var actionSection: some View {
        VStack(spacing: DS.Spacing.sm + 2) {
            StoreStatusBanner(store: store)

            PrimaryButton(
                title: ctaTitle,
                icon: "heart.slash.fill",
                gradient: DS.Gradient.accent
            ) {
                store.clearStatus()
                showParentalGate = true
            }
            .disabled(store.isWorking)

            HStack(spacing: DS.Spacing.md) {
                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.link)
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(store.isWorking)

                Text("·")
                    .foregroundStyle(DS.Color.textTertiary)

                Button(action: onDismiss) {
                    Text("Not Now")
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }
}
