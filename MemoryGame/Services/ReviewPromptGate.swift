//
//  ReviewPromptGate.swift
//  Memory Match Kids
//
//  Decides WHEN it's appropriate to ask iOS to show its native App Store rating
//  prompt. The actual prompt is triggered from a View via SwiftUI's
//  `@Environment(\.requestReview)` (backed by StoreKit's `AppStore.requestReview`)
//  — fully on-device, no backend, no network. Apple's own API silently caps how
//  often the system will actually display it (at most a few times per year,
//  regardless of how often it's called), but we still self-limit so we're not
//  calling it at every single win.
//

import Foundation

enum ReviewPromptGate {
    private static let lastRequestDateKey = "reviewLastRequestDate"
    private static let requestCountKey = "reviewRequestCount"
    private static let minDaysBetweenRequests = 60
    private static let maxLifetimeRequests = 4

    /// True if enough time has passed and we haven't asked too many times.
    static func shouldRequest() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: requestCountKey) < maxLifetimeRequests else { return false }

        if let lastDate = defaults.object(forKey: lastRequestDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard days >= minDaysBetweenRequests else { return false }
        }
        return true
    }

    /// Call right after triggering the system prompt, so the cooldown starts.
    static func markRequested() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: lastRequestDateKey)
        defaults.set(defaults.integer(forKey: requestCountKey) + 1, forKey: requestCountKey)
    }
}
