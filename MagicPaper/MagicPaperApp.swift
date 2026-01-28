import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // AdMob SDK'yı başlat
    AdMobManager.shared.initializeSDK()
    
    // Request notification permission
    LocalNotificationManager.shared.requestPermission()
    
    return true
  }
}

@main
struct MagicPaperApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var profileManager = ProfileManager.shared

  var body: some Scene {
    WindowGroup {
      if profileManager.hasProfile() {
        ContentView()
      } else {
        ProfileSetupView()
      }
    }
  }
}
