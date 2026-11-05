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
    /// Re-read on every appearance: the launch consent flow may still have
    /// been in flight the first time this screen was built.
    @State private var showPrivacyOptions = false
    @AppStorage("cardBackStyle") private var cardBackRaw = CardBackStyle.classic.rawValue
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @Environment(\.openURL) private var openURL

    init(progressStore: ProgressStore) {
        self.progressStore = progressStore
        _viewModel = StateObject(wrappedValue: SettingsViewModel(progressStore: progressStore))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DS.Spacing.xl) {
                progressSection
                levelsSection
                appearanceSection
                languageSection
                cardStyleSection
                gameplaySection
                notificationsSection
                removeAdsSection
                accessibilitySection
                dataSection
                aboutSection
                legalSection
            }
            .frame(maxWidth: DS.Layout.contentMaxWidth)
            .padding(.horizontal, DS.Layout.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
            .frame(maxWidth: .infinity)
        }
        .dsScreenBackground()
        .navigationTitle(tr("Settings"))
        .tint(DS.Color.link)
        .onAppear {
            viewModel.syncFromStore()
            showPrivacyOptions = ConsentManager.shared.privacyOptionsRequired
        }
        .task {
            if store.removeAdsProduct == nil {
                await store.loadProduct()
            }
        }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView {
                Task { await store.purchaseRemoveAds() }
            }
            .presentationDetents([.medium])
        }
        .alert(tr("Reset all progress?"), isPresented: $showResetAlert) {
            Button(tr("Cancel"), role: .cancel) {}
            Button(tr("Reset"), role: .destructive) {
                viewModel.resetAllProgress()
            }
        } message: {
            Text(tr("This removes stars, level progress, and achievements. Your settings stay the same."))
        }
        .alert(tr("Notifications are off"), isPresented: $showNotifDeniedAlert) {
            Button(tr("Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(tr("Not Now"), role: .cancel) {}
        } message: {
            Text(tr("Enable notifications for Memory Match in the Settings app to get daily reminders."))
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        DSCard {
            SectionHeader(title: tr("Your Progress"), icon: "chart.bar.fill")

            HStack(spacing: DS.Spacing.sm + 2) {
                StatCard(value: "\(progressStore.completedLevels)", label: tr("Done"), icon: "flag.checkered")
                StatCard(value: "\(progressStore.totalStars)", label: tr("Stars"),
                         icon: "star.fill", tint: DS.Color.star)
                StatCard(value: "\(progressStore.goldLevels)", label: tr("Gold"),
                         icon: "crown.fill", tint: DS.Color.star)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)

            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(DS.Color.star)
                Text(tr("{0} achievements unlocked", progressStore.achievementsUnlocked))
                    .font(.DSText.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    // MARK: - Levels

    private var levelsSection: some View {
        DSCard {
            SectionHeader(title: tr("Levels"), icon: "square.grid.2x2.fill")
            NavigationLink {
                LevelsView(progressStore: progressStore)
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "list.number")
                        .font(.title3)
                        .foregroundStyle(DS.Color.link)
                        .frame(width: DS.Layout.isPad ? 34 : 28)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text(tr("All Levels"))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text(tr("Browse, replay, and check your stars"))
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
            SectionHeader(title: tr("Appearance"), icon: "paintbrush.fill")
            Text(tr("Choose light, dark, or match your device."))
                .font(.DSText.caption)
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.sm) {
                ForEach(AppearanceMode.allCases) { mode in
                    appearanceButton(mode)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }

    // MARK: - Language

    /// iOS keeps the per-app language in the Settings app (it appears there
    /// because the bundle ships several .lproj folders) and relaunches the app
    /// when it changes, so the row just sends the parent there.
    private var languageSection: some View {
        DSCard {
            SectionHeader(title: tr("Language"), icon: "globe")
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "character.bubble.fill")
                        .font(.title3)
                        .foregroundStyle(DS.Color.link)
                        .frame(width: DS.Layout.isPad ? 34 : 28)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text(L10n.nativeNames[L10n.language] ?? "English")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text(tr("Change it in the Settings app"))
                            .font(.DSText.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
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
        .accessibilityLabel(tr("{0} theme", mode.title))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Card Style

    private var cardStyleSection: some View {
        DSCard {
            SectionHeader(title: tr("Card Style"), icon: "rectangle.stack.fill")
            Text(tr("Pick the look of the card backs."))
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
                    .accessibilityLabel(tr("{0} card back", style.label))
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeader(title: tr("Gameplay"), icon: "gamecontroller.fill")
            settingsToggle(
                title: tr("Sound Effects"),
                subtitle: tr("Flips, matches, and level complete sounds"),
                icon: "speaker.wave.2.fill",
                isOn: $viewModel.soundEnabled
            ) { viewModel.setSound($0) }
            settingsToggle(
                title: tr("Haptic Feedback"),
                subtitle: tr("Gentle taps when you flip and match cards"),
                icon: "hand.tap.fill",
                isOn: $viewModel.hapticsEnabled
            ) { viewModel.setHaptics($0) }
            settingsToggle(
                title: tr("Memorize Preview"),
                subtitle: tr("Show all cards to memorize at the start (level 3+)"),
                icon: "eye.fill",
                isOn: $viewModel.memorizePreviewEnabled
            ) { viewModel.setMemorizePreview($0) }
        }
        .dsCard()
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeader(title: tr("Notifications"), icon: "bell.badge.fill")
            settingsToggle(
                title: tr("Reminders"),
                subtitle: tr("A daily nudge, plus a friendly note if you've been away"),
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
            SectionHeader(title: tr("Accessibility"), icon: "accessibility")
            settingsToggle(
                title: tr("Large Text"),
                subtitle: tr("Bigger emojis and labels on game cards"),
                icon: "textformat.size",
                isOn: $viewModel.largeText
            ) { viewModel.setLargeText($0) }
            settingsToggle(
                title: tr("High Contrast"),
                subtitle: tr("Thicker borders and sharper card faces"),
                icon: "circle.lefthalf.filled",
                isOn: $viewModel.highContrast
            ) { viewModel.setHighContrast($0) }
            settingsToggle(
                title: tr("Color Blind Friendly"),
                subtitle: tr("Uses blue accents instead of mixed colors"),
                icon: "eye.trianglebadge.exclamationmark",
                isOn: $viewModel.colorBlindMode
            ) { viewModel.setColorBlind($0) }
        }
        .dsCard()
    }

    // MARK: - Remove Ads

    private var removeAdsSection: some View {
        DSCard {
            SectionHeader(title: tr("Ads"), icon: "heart.slash.fill")

            if store.adsRemoved {
                HStack(spacing: DS.Spacing.sm + 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DS.Color.success)
                    Text(tr("Ads removed — thank you!"))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
            } else {
                Button {
                    store.clearStatus()
                    showParentalGate = true
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "heart.slash.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                            Text(tr("Remove Ads"))
                                .font(.system(.body, design: .rounded, weight: .bold))
                            Text(store.removeAdsProduct.map { tr("One-time purchase — {0}, no more ads", $0.displayPrice) }
                                 ?? tr("One-time purchase — no more ads"))
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

                StoreStatusBanner(store: store)

                Button {
                    Task { await store.restore() }
                } label: {
                    Text(tr("Restore Purchases"))
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
            SectionHeader(title: tr("Data"), icon: "externaldrive.fill")
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text(tr("Reset All Progress"))
                            .font(.system(.body, design: .rounded, weight: .bold))
                        Text(tr("Start over from Level 1"))
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
            SectionHeader(title: tr("About"), icon: "info.circle.fill")
            infoRow(label: tr("App"), value: AppTheme.appName)
            infoRow(label: tr("Unlock rule"), value: tr("Complete a level to open the next"))
            infoRow(
                label: tr("Star guide"),
                value: tr("3★ ≤ pairs moves · 2★ ≤ pairs + {0} · 1★ finish", StarRatingRules.twoStarExtraMoves)
            )
        }
    }

    // MARK: - Legal

    private static let siteBaseURL = "https://tinygeniushubmemorymatch.netlify.app"
    private static let privacyPolicyURL = URL(string: "\(siteBaseURL)/privacy-policy.html")!
    private static let termsURL = URL(string: "\(siteBaseURL)/terms-and-conditions.html")!
    private static let supportURL = URL(string: "\(siteBaseURL)/")!

    private var legalSection: some View {
        DSCard {
            SectionHeader(title: tr("Support & Privacy"), icon: "hand.raised.fill")
            // Only shown where UMP says this user is owed a way back to their
            // consent answer — elsewhere there is no form to re-present, so the
            // row would dead-end.
            if showPrivacyOptions {
                privacyOptionsRow
            }
            legalLink(title: tr("Privacy Policy"), icon: "lock.doc.fill", url: Self.privacyPolicyURL)
            legalLink(title: tr("Terms & Conditions"), icon: "doc.text.fill", url: Self.termsURL)
            legalLink(title: tr("Contact Support"), icon: "questionmark.circle.fill", url: Self.supportURL)
        }
    }

    private var privacyOptionsRow: some View {
        Button {
            ConsentManager.shared.presentPrivacyOptions { _ in
                // UMP owns the form's own error UI; all this needs to do is
                // re-check whether the row still applies afterwards.
                showPrivacyOptions = ConsentManager.shared.privacyOptionsRequired
            }
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "hand.raised.square.fill")
                    .font(.body)
                    .foregroundStyle(DS.Color.link)
                    .frame(width: DS.Layout.isPad ? 34 : 28)
                Text(tr("Privacy Options"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.vertical, DS.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    private func legalLink(title: String, icon: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(DS.Color.link)
                    .frame(width: DS.Layout.isPad ? 34 : 28)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.vertical, DS.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
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
                    .frame(width: DS.Layout.isPad ? 34 : 28)
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
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
