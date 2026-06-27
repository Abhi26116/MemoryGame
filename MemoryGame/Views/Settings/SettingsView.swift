//
//  SettingsView.swift
//  Memory Match Kids
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    /// Observed so the progress stats stay live (gameplay happens on another tab).
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject private var store = StoreManager.shared
    @State private var showResetAlert = false
    @State private var showParentalGate = false
    @State private var showNotifDeniedAlert = false
    @AppStorage("cardBackStyle") private var cardBackRaw = CardBackStyle.classic.rawValue
    @AppStorage("remindersEnabled") private var remindersEnabled = false

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        _viewModel = StateObject(wrappedValue: SettingsViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Spacing.xl) {
                progressSection
                levelsSection
                appearanceSection
                cardStyleSection
                gameplaySection
                notificationsSection
                removeAdsSection
                accessibilitySection
                dataSection
                aboutSection
            }
            .padding(.horizontal, DS.Layout.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .dsScreenBackground()
        .navigationTitle("Settings")
        .tint(DS.Color.link)
        .onAppear { viewModel.syncFromStore() }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView {
                Task { await store.purchaseRemoveAds() }
            }
            .presentationDetents([.medium])
        }
        .alert("Reset all progress?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllProgress()
            }
        } message: {
            Text("This removes stars, level progress, and achievements. Your settings stay the same.")
        }
        .alert("Notifications are off", isPresented: $showNotifDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Enable notifications for Memory Match in the Settings app to get daily reminders.")
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        DSCard {
            SectionHeader(title: "Your Progress", icon: "chart.bar.fill")

            HStack(spacing: DS.Spacing.sm + 2) {
                StatCard(value: "\(progressStore.completedLevels)", label: "Done", icon: "flag.checkered")
                StatCard(value: "\(progressStore.totalStars)", label: "Stars",
                         icon: "star.fill", tint: DS.Color.star)
                StatCard(value: "\(progressStore.goldLevels)", label: "Gold",
                         icon: "crown.fill", tint: DS.Color.star)
            }

            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(DS.Color.star)
                Text("\(progressStore.achievementsUnlocked) achievements unlocked")
                    .font(.DSText.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    // MARK: - Levels

    private var levelsSection: some View {
        DSCard {
            SectionHeader(title: "Levels", icon: "square.grid.2x2.fill")
            NavigationLink {
                LevelsView(progressStore: progressStore)
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "list.number")
                        .font(.title3)
                        .foregroundStyle(DS.Color.link)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("All Levels")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Browse, replay, and check your stars")
                            .font(.DSText.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        DSCard {
            SectionHeader(title: "Appearance", icon: "paintbrush.fill")
            Text("Choose light, dark, or match your device.")
                .font(.DSText.caption)
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.sm) {
                ForEach(AppearanceMode.allCases) { mode in
                    appearanceButton(mode)
                }
            }
        }
    }

    private func appearanceButton(_ mode: AppearanceMode) -> some View {
        let selected = viewModel.appearanceMode == mode
        return Button {
            viewModel.setAppearance(mode)
        } label: {
            VStack(spacing: DS.Spacing.xs + 2) {
                Image(systemName: mode.icon)
                    .font(.title3)
                Text(mode.title)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .foregroundStyle(selected ? .white : DS.Color.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .fill(
                        selected
                            ? AnyShapeStyle(DS.Gradient.brand)
                            : AnyShapeStyle(DS.Color.fill)
                    )
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(mode.title) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Card Style

    private var cardStyleSection: some View {
        DSCard {
            SectionHeader(title: "Card Style", icon: "rectangle.stack.fill")
            Text("Pick the look of the card backs.")
                .font(.DSText.caption)
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.sm + 2) {
                ForEach(CardBackStyle.allCases) { style in
                    let selected = cardBackRaw == style.rawValue
                    Button {
                        cardBackRaw = style.rawValue
                    } label: {
                        VStack(spacing: DS.Spacing.xs + 2) {
                            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                .fill(style.gradient)
                                .frame(height: 58)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                        .stroke(.white, lineWidth: selected ? 3 : 0)
                                )
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .opacity(selected ? 1 : 0)
                                )
                                .dsShadow(.card)
                            Text(style.label)
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(selected ? DS.Color.textPrimary : DS.Color.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .buttonStyle(.pressable)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(style.label) card back")
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeader(title: "Gameplay", icon: "gamecontroller.fill")
            settingsToggle(
                title: "Sound Effects",
                subtitle: "Flips, matches, and level complete sounds",
                icon: "speaker.wave.2.fill",
                isOn: $viewModel.soundEnabled
            ) { viewModel.setSound($0) }
            settingsToggle(
                title: "Haptic Feedback",
                subtitle: "Gentle taps when you flip and match cards",
                icon: "hand.tap.fill",
                isOn: $viewModel.hapticsEnabled
            ) { viewModel.setHaptics($0) }
            settingsToggle(
                title: "Memorize Preview",
                subtitle: "Show all cards to memorize at the start (level 3+)",
                icon: "eye.fill",
                isOn: $viewModel.memorizePreviewEnabled
            ) { viewModel.setMemorizePreview($0) }
        }
        .dsCard()
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeader(title: "Notifications", icon: "bell.badge.fill")
            settingsToggle(
                title: "Reminders",
                subtitle: "A daily nudge, plus a friendly note if you've been away",
                icon: "bell.fill",
                isOn: $remindersEnabled
            ) { handleReminders($0) }
        }
        .dsCard()
    }

    private func handleReminders(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    NotificationManager.shared.scheduleReminders()
                } else {
                    remindersEnabled = false
                    showNotifDeniedAlert = true
                }
            }
        } else {
            NotificationManager.shared.cancelAll()
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeader(title: "Accessibility", icon: "accessibility")
            settingsToggle(
                title: "Large Text",
                subtitle: "Bigger emojis and labels on game cards",
                icon: "textformat.size",
                isOn: $viewModel.largeText
            ) { viewModel.setLargeText($0) }
            settingsToggle(
                title: "High Contrast",
                subtitle: "Thicker borders and sharper card faces",
                icon: "circle.lefthalf.filled",
                isOn: $viewModel.highContrast
            ) { viewModel.setHighContrast($0) }
            settingsToggle(
                title: "Color Blind Friendly",
                subtitle: "Uses blue accents instead of mixed colors",
                icon: "eye.trianglebadge.exclamationmark",
                isOn: $viewModel.colorBlindMode
            ) { viewModel.setColorBlind($0) }
        }
        .dsCard()
    }

    // MARK: - Remove Ads

    private var removeAdsSection: some View {
        DSCard {
            SectionHeader(title: "Ads", icon: "heart.slash.fill")

            if store.adsRemoved {
                HStack(spacing: DS.Spacing.sm + 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DS.Color.success)
                    Text("Ads removed — thank you!")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
            } else {
                Button {
                    showParentalGate = true
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "heart.slash.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                            Text("Remove Ads")
                                .font(.system(.body, design: .rounded, weight: .bold))
                            Text("One-time purchase — no more ads")
                                .font(.DSText.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .foregroundStyle(DS.Color.link)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(store.isWorking)

                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.link)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(store.isWorking)
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        DSCard {
            SectionHeader(title: "Data", icon: "externaldrive.fill")
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("Reset All Progress")
                            .font(.system(.body, design: .rounded, weight: .bold))
                        Text("Start over from Level 1")
                            .font(.DSText.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }
                .foregroundStyle(DS.Color.danger)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        DSCard {
            SectionHeader(title: "About", icon: "info.circle.fill")
            infoRow(label: "App", value: AppTheme.appName)
            infoRow(label: "Unlock rule", value: "Complete a level to open the next")
            infoRow(
                label: "Star guide",
                value: "3★ ≤ pairs moves · 2★ ≤ pairs + \(StarRatingRules.twoStarExtraMoves) · 1★ finish"
            )
        }
    }

    // MARK: - Components

    private func settingsToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(DS.Color.link)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(subtitle)
                        .font(.DSText.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(DS.Color.brand)
        .padding(.vertical, DS.Spacing.sm)
        .onChange(of: isOn.wrappedValue) { _, value in onChange(value) }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.DSText.caption)
                .foregroundStyle(DS.Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
