import Foundation
import OSLog
// import AppTrackingTransparency // ❌ REMOVED - Not allowed for Kids Category apps
import UserNotifications
import UIKit

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "PermissionManager")

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    // ❌ REMOVED - Tracking not allowed for Kids Category apps
    // @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        // ❌ REMOVED - No tracking for Kids Category apps
        // checkTrackingStatus()
        Task {
            await checkNotificationStatus()
        }
    }
    
    // MARK: - App Tracking Transparency (ATT)
    // ❌ REMOVED - Not allowed for Kids Category apps
    
    // func checkTrackingStatus() {
    //     trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    // }
    
    // func requestTrackingPermission() async {
    //     // iOS 14+ için ATT izni
    //     if #available(iOS 14, *) {
    //         trackingStatus = await ATTrackingManager.requestTrackingAuthorization()
    //         print("📊 Tracking Permission: \(trackingStatus.description)")
    //     }
    // }
    
    // MARK: - Notifications
    
    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await checkNotificationStatus()
            logger.debug("🔔 Notification Permission: \(granted ? "Granted" : "Denied")")
            return granted
        } catch {
            logger.error("❌ Notification Permission Error: \(String(describing: error))")
            return false
        }
    }
    
    // MARK: - Request All Permissions
    
    func requestAllPermissions() async {
        // ❌ REMOVED - No tracking for Kids Category apps
        // Only request notification permission
        
        // Bildirim izni
        _ = await requestNotificationPermission()
    }
    
    // MARK: - Permission Status Helpers
    
    // ❌ REMOVED - No tracking for Kids Category apps
    // var hasTrackingPermission: Bool {
    //     trackingStatus == .authorized
    // }
    
    var hasNotificationPermission: Bool {
        notificationStatus == .authorized
    }
    
    var allPermissionsGranted: Bool {
        // ✅ Only notification permission for Kids Category apps
        hasNotificationPermission
    }
}

// ❌ REMOVED - ATTrackingManager extension not needed for Kids Category apps
// extension ATTrackingManager.AuthorizationStatus {
//     var description: String {
//         switch self {
//         case .notDetermined:
//             return "Not Determined"
//         case .restricted:
//             return "Restricted"
//         case .denied:
//             return "Denied"
//         case .authorized:
//             return "Authorized"
//         @unknown default:
//             return "Unknown"
//         }
//     }
// }
