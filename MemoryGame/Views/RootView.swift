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
    @State private var showSplash = true
    @State private var showWelcome = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasSeenRemoveAdsPrompt") private var hasSeenRemoveAdsPrompt = false
    /// Defaults to on: reminders are opt-out, not opt-in. `syncReminders()`
    /// requests system permission on the player's behalf the first time.
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @State private var availableUpdate: UpdateCheckManager.AvailableUpdate?
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
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                TabView {
                    NavigationStack {
                        HomeView(viewModel: homeViewModel, progressStore: progressStore)
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
                .transition(.opacity)
            }
        }
        .appAppearance(appearanceMode)
        .environment(\.hapticsEnabled, progressStore.settings?.hapticsEnabled ?? true)
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView {
                hasSeenWelcome = true
                // Onboarding already showed the Remove-Ads page, so don't nag
                // again with the in-game soft prompt.
                hasSeenRemoveAdsPrompt = true
                showWelcome = false
                // Ask for notification permission / check for updates after
                // onboarding closes, not while it's still animating in.
                Task { await runPostOnboardingChecks() }
            }
            .appAppearance(appearanceMode)
        }
        .overlay {
            if let availableUpdate {
                updateAvailableDialog(availableUpdate)
            }
        }
        .task {
            try? await Task.sleep(for: SplashTiming.holdDuration)
            showSplash = false
            homeViewModel.syncFromStore()
            if !hasSeenWelcome {
                showWelcome = true
            } else {
                await runPostOnboardingChecks()
            }
        }
    }

    private func runPostOnboardingChecks() async {
        await syncReminders()
        availableUpdate = await UpdateCheckManager.checkForUpdate(
            bundleID: Bundle.main.bundleIdentifier ?? ""
        )
    }

    /// Re-arms local reminders and keeps the stored flag honest if the player
    /// declines the system permission prompt.
    private func syncReminders() async {
        let active = await NotificationManager.shared.refreshReminders(enabled: remindersEnabled)
        if remindersEnabled != active {
            remindersEnabled = active
        }
    }

    /// Soft, dismissible nudge — never blocks the app. Silent no-op if the
    /// lookup failed or the player is already up to date (see
    /// `UpdateCheckManager`), so this only appears when there's a real update.
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
