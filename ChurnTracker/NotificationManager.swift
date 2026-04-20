import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Notification auth failed: \(error)")
        }
    }

    func scheduleNotifications(for offer: ChurnOffer) {
        Task {
            let center = UNUserNotificationCenter.current()
            let identifierPrefix = "offer-\(offer.persistentModelID)"

            let existing = await center.pendingNotificationRequests()
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)

            if !existing.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: existing)
            }

            guard let deadlineDate = offer.deadlineDate else { return }

            let schedules: [(String, Int, String)] = [
                ("week", -7, "Deadline in 7 days"),
                ("two-day", -2, "Deadline in 2 days"),
                ("day-of", 0, "Deadline is today")
            ]

            for (suffix, dayOffset, title) in schedules {
                guard let triggerDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: deadlineDate),
                      triggerDate > .now else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = "\(offer.displayName): \(offer.nextAction)"
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(identifierPrefix)-\(suffix)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
}
