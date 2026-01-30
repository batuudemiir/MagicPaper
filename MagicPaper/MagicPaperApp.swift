import SwiftUI
import FirebaseCore
import FirebaseStorage
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("🚀 AppDelegate: didFinishLaunching başladı")
    
    FirebaseApp.configure()
    print("✅ Firebase yapılandırıldı")
    
    // AdMob SDK'yı başlat
    AdMobManager.shared.initializeSDK()
    print("✅ AdMob başlatıldı")
    
    // Request notification permission
    LocalNotificationManager.shared.requestPermission()
    print("✅ Notification izni istendi")
    
    print("✅ AppDelegate: didFinishLaunching tamamlandı")
    return true
  }
}

@main
struct MagicPaperApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var profileManager = ProfileManager.shared

  init() {
    print("🎬 MagicPaperApp: init() başladı")
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if profileManager.hasProfile() {
          ContentView()
        } else {
          ProfileSetupView()
        }
      }
      .onAppear {
        print("🎯 WindowGroup appeared")
        print("📱 Profile var mı: \(profileManager.hasProfile())")
      }
    }
  }
}
