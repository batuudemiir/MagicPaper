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
  @State private var showSplash = true

  init() {
    print("🎬 MagicPaperApp: init() başladı")
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        if showSplash {
          // Splash screen
          SplashScreenView(isActive: $showSplash)
            .onAppear {
              print("🎬 Splash screen görünüyor")
            }
        } else {
          // Main app content
          MainContentView()
            .environmentObject(profileManager)
        }
      }
    }
  }
}

// MARK: - Main Content View

struct MainContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        Group {
            if !profileManager.hasCompletedOnboarding {
                // İlk açılış - Onboarding göster
                OnboardingView(isOnboardingComplete: $profileManager.hasCompletedOnboarding)
            } else if profileManager.hasProfile() {
                // Profil var - Ana ekrana git
                ContentView()
            } else {
                // Onboarding tamamlandı ama profil yok - Profil oluştur
                ProfileSetupView()
            }
        }
        .onAppear {
            print("🎯 MainContentView appeared")
            print("📱 Onboarding tamamlandı mı: \(profileManager.hasCompletedOnboarding)")
            print("📱 Profile var mı: \(profileManager.hasProfile())")
        }
    }
}

// MARK: - Splash Screen View

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.58, green: 0.29, blue: 0.98),
                    Color(red: 0.85, green: 0.35, blue: 0.85),
                    Color(red: 1.0, green: 0.45, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Logo with SF Symbol
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // App Name
                Text("Magic Paper")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            print("🎬 SplashScreenView appeared")
            
            // Animate logo appearance
            withAnimation(.easeInOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Transition to main app after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("⏰ Splash timer completed, transitioning to main app")
                print("⏰ isActive değeri değiştiriliyor: \(isActive) -> false")
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = false
                }
            }
        }
    }
}
