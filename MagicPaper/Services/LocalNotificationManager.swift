import Foundation
import UserNotifications

/// Manages local notifications for story completion
class LocalNotificationManager {
    
    static let shared = LocalNotificationManager()
    
    private init() {}
    
    /// Request notification permission from user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    /// Send a local notification
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("✅ Notification sent: \(title)")
            }
        }
    }
}
