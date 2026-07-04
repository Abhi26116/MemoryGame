//
//  RootView.swift
//  Memory Match Kids
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressStore: ProgressStore
    @StateObject private var homeViewModel: HomeViewModel

    private enum LaunchPhase {
        case splash
        case onboarding
        case main
    }

    @State private var phase: LaunchPhase = .splash
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasSeenRemoveAdsPrompt") private var hasSeenRemoveAdsPrompt = false
    /// Defaults to on: reminders are opt-out, not opt-in. `syncReminders()`
    /// requests system permission on the player's behalf the first time.
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @State private var availableUpdate: UpdateCheckManager.AvailableUpdate?
    @State private var showDailyRemoveAdsShowcase = false
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var ads = AdsManager.shared
    @Environment(\.openURL) private var openURL

    init(modelContext: ModelContext) {
        let store = ProgressStore(modelContext: modelContext)
        _progressStore = StateObject(wrappedValue: store)
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(progressStore: store))
    }

    private var appearanceMode: AppearanceMode {
        progressStore.appearanceMode
    }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                WelcomeView(onFinish: finishOnboarding)
                    .transition(.opacity)
            case .main:
                mainTabView
                    .transition(.opacity)
            }
        }
        .appAppearance(appearanceMode)
        .dsIPadTypeScale()
        .environment(\.hapticsEnabled, progressStore.settings?.hapticsEnabled ?? true)
        .animation(.easeInOut(duration: 0.45), value: phase)
        .fullScreenCover(isPresented: $showDailyRemoveAdsShowcase) {
            RemoveAdsShowcaseView { showDailyRemoveAdsShowcase = false }
        }
        .overlay {
            if let availableUpdate {
                updateAvailableDialog(availableUpdate)
            }
        }
        .task(id: phase) {
            guard phase == .splash else { return }
            try? await Task.sleep(for: SplashTiming.holdDuration)
            finishSplash()
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: homeViewModel, progressStore: progressStore)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bannerAdSlot
            }
            .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            NavigationStack {
                AchievementView(progressStore: progressStore)
            }
            .tabItem { Label("Awards", systemImage: "trophy.fill") }

            NavigationStack {
                SettingsView(progressStore: progressStore)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(DS.Color.link)
        .toolbarBackground(DS.Color.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: store.adsRemoved) { _, removed in
            if removed { ads.setBannerVisible(false) }
        }
    }

    /// Banner sits above the tab bar on the Play tab only. Mounted always so the
    /// ad can load; inset height expands once visible. Must NOT be on TabView
    /// itself — that hides the tab bar on iPad.
    @ViewBuilder
    private var bannerAdSlot: some View {
        Group {
            if !store.adsRemoved {
                BannerAdView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(DS.Color.surface)
                    .opacity(ads.bannerIsVisible ? 1 : 0)
            }
        }
        .frame(height: (!store.adsRemoved && ads.bannerIsVisible) ? 50 : 0)
        .clipped()
    }

    private func finishSplash() {
        homeViewModel.syncFromStore()
        phase = hasSeenWelcome ? .main : .onboarding
        if hasSeenWelcome {
            Task { await runPostOnboardingChecks() }
        }
    }

    private func finishOnboarding() {
        hasSeenWelcome = true
        hasSeenRemoveAdsPrompt = true
        RemoveAdsPromptGate.markShownToday()
        phase = .main
        Task { await runPostOnboardingChecks() }
    }

    private func runPostOnboardingChecks() async {
        await syncReminders()
        availableUpdate = await UpdateCheckManager.checkForUpdate(
            bundleID: Bundle.main.bundleIdentifier ?? ""
        )
        if availableUpdate == nil,
           !StoreManager.shared.adsRemoved,
           !RemoveAdsPromptGate.shownToday() {
            RemoveAdsPromptGate.markShownToday()
            showDailyRemoveAdsShowcase = true
        }
    }

    private func syncReminders() async {
        let active = await NotificationManager.shared.refreshReminders(enabled: remindersEnabled)
        if remindersEnabled != active {
            remindersEnabled = active
        }
    }

    private func updateAvailableDialog(_ update: UpdateCheckManager.AvailableUpdate) -> some View {
        Dialog {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.brand)
            Text("Update Available")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Version \(update.version) of \(AppTheme.appName) is ready, with the latest levels and improvements.")
                .font(.DSText.callout)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Update Now", icon: "arrow.up.circle.fill") {
                openURL(update.storeURL)
                availableUpdate = nil
            }
            Button {
                availableUpdate = nil
            } label: {
                Text("Later")
                    .font(.DSText.button)
                    .foregroundStyle(DS.Color.link)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .transition(.opacity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: LevelProgressEntity.self, AppSettingsEntity.self,
        configurations: config
    )
    return RootView(modelContext: container.mainContext)
}
