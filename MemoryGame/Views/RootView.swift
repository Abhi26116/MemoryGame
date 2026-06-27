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
    @AppStorage("remindersEnabled") private var remindersEnabled = false

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
            }
            .appAppearance(appearanceMode)
        }
        .task {
            try? await Task.sleep(for: SplashTiming.holdDuration)
            showSplash = false
            homeViewModel.syncFromStore()
            if !hasSeenWelcome { showWelcome = true }
            await NotificationManager.shared.refreshReminders(enabled: remindersEnabled)
        }
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
