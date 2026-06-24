//
//  MemoryGameApp.swift
//  Memory Match Kids
//

import SwiftUI
import SwiftData

@main
struct MemoryGameApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            RootView(modelContext: sharedModelContainer.mainContext)
                .task {
                    AdsManager.shared.configure()
                    await StoreManager.shared.refresh()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
