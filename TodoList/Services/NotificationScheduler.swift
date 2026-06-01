import Foundation
import UserNotifications

actor NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    func syncReminder(for task: TodoTask) async {
        await cancelReminder(for: task.id)

        guard !task.isCompleted, let reminderDate = task.reminderDate, reminderDate > Date() else {
            return
        }

        guard await requestAuthorizationIfNeeded() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.subtitle = "\(task.category.title) - \(task.priority.title) priority"
        content.body = task.notes.isEmpty ? "You have a task reminder." : task.notes
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: task.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelReminder(for taskID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: taskID)])
    }

    func syncReminders(for tasks: [TodoTask]) async {
        for task in tasks {
            await syncReminder(for: task)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    private func notificationIdentifier(for taskID: UUID) -> String {
        "todo-reminder-\(taskID.uuidString)"
    }
}
