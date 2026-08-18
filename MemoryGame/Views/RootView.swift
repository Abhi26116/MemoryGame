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

    // SHOT-TEMP
    private var shotLevel: LevelModel? {
        guard let raw = ProcessInfo.processInfo.environment["SHOT_LEVEL"],
              let n = Int(raw) else { return nil }
        return LevelCatalog.level(number: n)
    }
    private var shotTabIndex: Int { Int(ProcessInfo.processInfo.environment["SHOT_TAB"] ?? "0") ?? 0 }

    private var mainTabView: some View {
        Group {
        if let shotLevel {
            NavigationStack { GameView(level: shotLevel, progressStore: progressStore) }
        } else {
        TabView(selection: .constant(shotTabIndex)) {
            NavigationStack {
                HomeView(viewModel: homeViewModel, progressStore: progressStore)
            }
            .tabItem { Label("Play", systemImage: "gamecontroller.fill") }
            .tag(0)

            NavigationStack {
                AchievementView(progressStore: progressStore)
            }
            .tabItem { Label("Awards", systemImage: "trophy.fill") }
            .tag(1)

            NavigationStack {
                SettingsView(progressStore: progressStore)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(2)
        }
        .tint(DS.Color.link)
        .toolbarBackground(DS.Color.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: store.adsRemoved) { _, removed in
            if removed { ads.setBannerVisible(false) }
        }
        }
        }
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
        if UserDefaults.standard.bool(forKey: "SCREENSHOT_MODE") { return }  // SHOT-TEMP
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
