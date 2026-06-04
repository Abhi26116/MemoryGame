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
    @Environment(\.colorScheme) private var systemColorScheme

    init(modelContext: ModelContext) {
        let store = ProgressStore(modelContext: modelContext)
        _progressStore = StateObject(wrappedValue: store)
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(progressStore: store))
    }

    private var appearanceMode: AppearanceMode {
        progressStore.appearanceMode
    }

    private var resolvedScheme: ColorScheme {
        switch appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return systemColorScheme
        }
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    HomeView(
                        viewModel: homeViewModel,
                        progressStore: progressStore
                    )
                }
                .tint(AppTheme.linkBlue(for: resolvedScheme))
                .transition(.opacity)
            }
        }
        .appAppearance(appearanceMode)
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .task {
            try? await Task.sleep(for: SplashTiming.holdDuration)
            showSplash = false
            homeViewModel.syncFromStore()
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
