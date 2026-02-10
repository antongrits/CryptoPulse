import Foundation
import UserNotifications
import os

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            AppLogger.alerts.error("Notification permission request failed: \(error.localizedDescription)")
            return false
        }
    }

    func sendPriceAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLogger.alerts.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
