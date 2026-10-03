import Foundation
import OSLog
import UserNotifications

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "LocalNotificationManager")

/// Manages local notifications for story completion
class LocalNotificationManager {
    
    static let shared = LocalNotificationManager()
    
    private init() {}
    
    /// Request notification permission from user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                logger.debug("✅ Notification permission granted")
            } else if let error = error {
                logger.error("❌ Notification permission error: \(String(describing: error))")
            } else {
                logger.warning("⚠️ Notification permission denied")
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
                logger.error("❌ Failed to send notification: \(String(describing: error))")
            } else {
                logger.debug("✅ Notification sent: \(title)")
            }
        }
    }
}
