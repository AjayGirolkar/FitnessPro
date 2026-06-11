//
//  NotificationService.swift
//  FitnessPro
//
//  Local workout reminders. Protocol-first so the scheduler can be mocked in
//  tests and the UNUserNotificationCenter dependency stays at the edge.
//

import Foundation
import UserNotifications

/// Persisted reminder preference (time + active weekdays). Weekday uses the
/// `Calendar` convention: 1 = Sunday … 7 = Saturday.
struct ReminderSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool = false
    var hour: Int = 18
    var minute: Int = 0
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]   // Mon–Fri

    static let `default` = ReminderSettings()

    var timeLabel: String {
        var comps = DateComponents(); comps.hour = hour; comps.minute = minute
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

protocol NotificationScheduling: Sendable {
    /// Prompts for permission. Returns whether notifications are allowed.
    func requestAuthorization() async -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    /// Replaces any existing reminders with ones matching `settings`.
    func reschedule(_ settings: ReminderSettings) async
    func cancelAll() async
}

final class LocalNotificationService: NotificationScheduling {
    private let center: UNUserNotificationCenter
    private static let category = "workout.reminder"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func reschedule(_ settings: ReminderSettings) async {
        await cancelAll()
        guard settings.isEnabled, !settings.weekdays.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to train 💪"
        content.body = "Your FitnessPro session is waiting. Let's keep the streak alive."
        content.sound = .default
        content.categoryIdentifier = Self.category

        for weekday in settings.weekdays {
            var comps = DateComponents()
            comps.weekday = weekday
            comps.hour = settings.hour
            comps.minute = settings.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(Self.category).\(weekday)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        let ids = (2...8).map { "\(Self.category).\($0 % 7 + 1)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removePendingNotificationRequests(withIdentifiers: (1...7).map { "\(Self.category).\($0)" })
    }
}
