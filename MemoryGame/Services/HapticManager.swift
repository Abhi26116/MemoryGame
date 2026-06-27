//
//  HapticManager.swift
//  Memory Match Kids
//
//  Semantic haptic feedback. Each event maps to the most fitting Taptic pattern,
//  and generators are pre-warmed via `prepare()` to minimise first-fire latency.
//  Every call takes the player's `enabled` preference so haptics stay off when
//  the setting is disabled.
//

import UIKit

enum HapticManager {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGen = UISelectionFeedbackGenerator()

    /// Warm up the engines at the start of a game to cut first-tap latency.
    static func prepare() {
        lightImpact.prepare()
        notification.prepare()
    }

    // MARK: - Semantic events

    /// A card is flipped face-up.
    static func cardFlip(enabled: Bool) {
        guard enabled else { return }
        lightImpact.impactOccurred(intensity: 0.7)
        lightImpact.prepare()
    }

    /// A pair / group matched.
    static func match(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// A wrong guess.
    static func mismatch(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.error)
    }

    /// A life / heart was lost.
    static func lifeLost(enabled: Bool) {
        guard enabled else { return }
        rigidImpact.impactOccurred()
    }

    /// Level finished with a win.
    static func levelComplete(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Level lost (out of moves / time / lives).
    static func levelFailed(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// A new achievement unlocked.
    static func achievement(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Light selection tick (toggles, segmented choices, theme change).
    static func selection(enabled: Bool) {
        guard enabled else { return }
        selectionGen.selectionChanged()
    }

    // MARK: - Legacy generic names (retained for any older call sites)

    static func light(enabled: Bool) { cardFlip(enabled: enabled) }
    static func success(enabled: Bool) { match(enabled: enabled) }
    static func error(enabled: Bool) { mismatch(enabled: enabled) }
    static func medium(enabled: Bool) {
        guard enabled else { return }
        mediumImpact.impactOccurred()
    }
}
