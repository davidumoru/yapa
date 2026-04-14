import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {}

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func scheduleReminders(for habit: Habit) {
        removeReminders(for: habit)

        guard !habit.reminderMinutes.isEmpty else { return }

        for minutes in habit.reminderMinutes {
            let hour = minutes / 60
            let minute = minutes % 60

            if habit.scheduledWeekdays.isEmpty {
                let content = makeContent(for: habit)
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents, repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: "\(habit.id.uuidString)-daily-\(minutes)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            } else {
                for weekday in habit.scheduledWeekdays {
                    let content = makeContent(for: habit)
                    var dateComponents = DateComponents()
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    dateComponents.weekday = weekday

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: dateComponents, repeats: true
                    )
                    let request = UNNotificationRequest(
                        identifier: "\(habit.id.uuidString)-\(weekday)-\(minutes)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    func removeReminders(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(habit.id.uuidString) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func makeContent(for habit: Habit) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"
        content.body = "Time to keep your streak going!"
        content.sound = .default
        return content
    }
}
