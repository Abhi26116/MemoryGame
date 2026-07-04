//
//  RemoveAdsPromptGate.swift
//  Memory Match Kids
//
//  Tracks the last time ANY "Remove Ads" showcase was shown — whether the
//  one-time milestone nudge (Home, after a few completed levels) or the
//  recurring once-a-day reminder (app launch) — so a player is never shown
//  more than one ad-free pitch per calendar day, regardless of which trigger
//  fires first.
//

import Foundation

enum RemoveAdsPromptGate {
    private static let lastShownDateKey = "removeAdsPromptLastShownDate"

    /// True if a showcase has already been shown today (player's local calendar day).
    static func shownToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastShownDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    static func markShownToday() {
        UserDefaults.standard.set(Date(), forKey: lastShownDateKey)
    }
}
