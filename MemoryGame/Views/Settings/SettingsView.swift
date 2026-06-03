//
//  SettingsView.swift
//  Memory Match Kids
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(progressStore: ProgressStore) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(progressStore: progressStore))
    }

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Sound Effects", isOn: $viewModel.soundEnabled)
                    .onChange(of: viewModel.soundEnabled) { _, v in viewModel.setSound(v) }
                Toggle("Background Music", isOn: $viewModel.musicEnabled)
                    .onChange(of: viewModel.musicEnabled) { _, v in viewModel.setMusic(v) }
            }

            Section("Feedback") {
                Toggle("Haptic Feedback", isOn: $viewModel.hapticsEnabled)
                    .onChange(of: viewModel.hapticsEnabled) { _, v in viewModel.setHaptics(v) }
            }

            Section("Accessibility") {
                Toggle("Large Text", isOn: $viewModel.largeText)
                    .onChange(of: viewModel.largeText) { _, v in viewModel.setLargeText(v) }
                Toggle("High Contrast", isOn: $viewModel.highContrast)
                    .onChange(of: viewModel.highContrast) { _, v in viewModel.setHighContrast(v) }
                Toggle("Color Blind Friendly", isOn: $viewModel.colorBlindMode)
                    .onChange(of: viewModel.colorBlindMode) { _, v in viewModel.setColorBlind(v) }
            }

            Section("About") {
                LabeledContent("App", value: AppTheme.appName)
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
        .onAppear { viewModel.syncFromStore() }
    }
}
