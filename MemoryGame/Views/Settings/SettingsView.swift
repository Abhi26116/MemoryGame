//
//  SettingsView.swift
//  Memory Match Kids
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showResetAlert = false
    @State private var showParentalGate = false

    init(progressStore: ProgressStore) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                progressSection
                appearanceSection
                gameplaySection
                removeAdsSection
                accessibilitySection
                dataSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .kidBackground()
        .navigationTitle("Settings")
        .kidBackButton()
        .tint(AppTheme.linkBlue(for: colorScheme))
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
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your Progress", icon: "chart.bar.fill")

            HStack(spacing: 10) {
                statPill(value: "\(viewModel.completedLevels)/\(viewModel.totalLevels)", label: "Levels", icon: "flag.checkered")
                statPill(value: "\(viewModel.totalStars)", label: "Stars", icon: "star.fill")
                statPill(value: "\(viewModel.goldLevels)", label: "Gold", icon: "crown.fill")
            }

            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color(hex: "FFD60A"))
                Text("\(viewModel.achievementsUnlocked) achievements unlocked")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Appearance", icon: "paintbrush.fill")
            Text("Choose light, dark, or match your device.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    appearanceButton(mode)
                }
            }
        }
        .settingsCard(colorScheme: colorScheme)
    }

    private func appearanceButton(_ mode: AppearanceMode) -> some View {
        let selected = viewModel.appearanceMode == mode
        return Button {
            viewModel.setAppearance(mode)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.title3)
                Text(mode.title)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(selected ? .white : AppTheme.textPrimary(for: colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        selected
                            ? AnyShapeStyle(AppTheme.primaryGradient)
                            : AnyShapeStyle(AppTheme.chipUnselected(for: colorScheme))
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Gameplay", icon: "gamecontroller.fill")
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
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Accessibility", icon: "accessibility")
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
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - Remove Ads

    private var removeAdsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Ads", icon: "heart.slash.fill")

            if store.adsRemoved {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.successGreen)
                    Text("Ads removed — thank you!")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
            } else {
                Button {
                    showParentalGate = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.slash.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remove Ads")
                                .font(.system(.body, design: .rounded, weight: .bold))
                            Text("One-time purchase — no more ads")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                }
                .buttonStyle(.plain)
                .disabled(store.isWorking)

                Button("Restore Purchases") {
                    Task { await store.restore() }
                }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                .disabled(store.isWorking)
            }
        }
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Data", icon: "externaldrive.fill")
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Progress")
                            .font(.system(.body, design: .rounded, weight: .bold))
                        Text("Start over from Level 1")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                }
                .foregroundStyle(Color(hex: "FF3B30"))
            }
            .buttonStyle(.plain)
        }
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("About", icon: "info.circle.fill")
            infoRow(label: "App", value: AppTheme.appName)
            infoRow(label: "Levels", value: "\(viewModel.totalLevels)")
            infoRow(label: "Unlock rule", value: "Complete a level to open the next")
            infoRow(
                label: "Star guide",
                value: "3★ ≤ pairs moves · 2★ ≤ pairs + \(StarRatingRules.twoStarExtraMoves) · 1★ finish"
            )
        }
        .settingsCard(colorScheme: colorScheme)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(AppTheme.headlineFont)
            .foregroundStyle(AppTheme.sectionTitle(for: colorScheme))
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.chipUnselected(for: colorScheme))
        )
    }

    private func settingsToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color(hex: "5B8DEF"))
        .padding(.vertical, 8)
        .onChange(of: isOn.wrappedValue) { _, value in onChange(value) }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SettingsCardModifier: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardSurface(for: colorScheme))
                    .shadow(
                        color: .black.opacity(AppTheme.cardShadowOpacity(for: colorScheme)),
                        radius: 8,
                        y: 4
                    )
            )
    }
}

private extension View {
    func settingsCard(colorScheme: ColorScheme) -> some View {
        modifier(SettingsCardModifier(colorScheme: colorScheme))
    }
}
