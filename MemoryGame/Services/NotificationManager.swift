//
//  NotificationManager.swift
//  Memory Match Kids
//
//  On-device (local) notifications only — no backend, no push tokens, fully
//  offline. Used for a gentle daily re-engagement reminder the player opts into
//  from Settings.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderID = "daily_reminder"
    private let inactivityReminderID = "inactivity_reminder"

    private init() {}

    /// Current system permission status.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Prompts for permission (first time) and returns whether it's granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted
    }

    /// Schedules all opt-in local reminders (daily + inactivity).
    func scheduleReminders() {
        scheduleDailyReminder()
        scheduleInactivityReminder()
    }

    /// Schedules a single repeating daily reminder at the given local time.
    func scheduleDailyReminder(hour: Int = 18, minute: Int = 0) {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = AppTheme.appName
        content.body = "🧠 Ready for today's challenge? Train your memory and keep your streak going!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Schedules a one-off "we miss you" reminder N days out. Re-armed on every
    /// launch, so it only fires if the player stays away that long.
    func scheduleInactivityReminder(afterDays days: Int = 2) {
        center.removePendingNotificationRequests(withIdentifiers: [inactivityReminderID])

        let content = UNMutableNotificationContent()
        content.title = AppTheme.appName
        content.body = "We miss you! 🧩 Your next memory challenge is waiting."
        content.sound = .default

        let interval = TimeInterval(days) * 24 * 60 * 60
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: inactivityReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Re-arms reminders on launch if enabled (and resets the inactivity clock).
    /// Reminders default to on, so if permission hasn't been decided yet this
    /// requests it here rather than waiting for a manual Settings toggle.
    /// Returns whether reminders ended up active, so callers can keep a stored
    /// "enabled" flag honest if the player declines the system prompt.
    @discardableResult
    func refreshReminders(enabled: Bool) async -> Bool {
        guard enabled else {
            cancelAll()
            return false
        }
        switch await authorizationStatus() {
        case .authorized, .provisional:
            scheduleReminders()
            return true
        case .notDetermined:
            guard await requestAuthorization() else { return false }
            scheduleReminders()
            return true
        default:
            return false
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
