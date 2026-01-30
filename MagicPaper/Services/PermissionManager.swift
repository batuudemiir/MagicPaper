import Foundation
import AppTrackingTransparency
import UserNotifications
import UIKit

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkTrackingStatus()
        Task {
            await checkNotificationStatus()
        }
    }
    
    // MARK: - App Tracking Transparency (ATT)
    
    func checkTrackingStatus() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    func requestTrackingPermission() async {
        // iOS 14+ için ATT izni
        if #available(iOS 14, *) {
            trackingStatus = await ATTrackingManager.requestTrackingAuthorization()
            print("📊 Tracking Permission: \(trackingStatus.description)")
        }
    }
    
    // MARK: - Notifications
    
    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await checkNotificationStatus()
            print("🔔 Notification Permission: \(granted ? "Granted" : "Denied")")
            return granted
        } catch {
            print("❌ Notification Permission Error: \(error)")
            return false
        }
    }
    
    // MARK: - Request All Permissions
    
    func requestAllPermissions() async {
        // 1. Tracking izni (AdMob için)
        await requestTrackingPermission()
        
        // 2. Bildirim izni
        _ = await requestNotificationPermission()
    }
    
    // MARK: - Permission Status Helpers
    
    var hasTrackingPermission: Bool {
        trackingStatus == .authorized
    }
    
    var hasNotificationPermission: Bool {
        notificationStatus == .authorized
    }
    
    var allPermissionsGranted: Bool {
        hasTrackingPermission && hasNotificationPermission
    }
}

// MARK: - ATTrackingManager.AuthorizationStatus Extension

extension ATTrackingManager.AuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
