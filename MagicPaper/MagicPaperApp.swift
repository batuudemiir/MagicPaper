import SwiftUI
import FirebaseCore
import FirebaseStorage
#if canImport(RevenueCat)
import RevenueCat
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("🚀 AppDelegate: didFinishLaunching başladı")
    
    FirebaseApp.configure()
    print("✅ Firebase yapılandırıldı")
    
    // RevenueCat Configuration
    #if canImport(RevenueCat)
    configureRevenueCat()
    #else
    print("⚠️ RevenueCat modülü bulunamadı - Xcode'da package'ı target'a ekleyin")
    #endif
    
    // AdMob KALDIRILDI - Kids Category uyumluluğu için
    // Apple ASIdentifierManager (IDFA) kullanımına izin vermiyor
    // Gelir modeli: Sadece IAP/Abonelik
    
    // Request notification permission
    LocalNotificationManager.shared.requestPermission()
    print("✅ Notification izni istendi")
    
    print("✅ AppDelegate: didFinishLaunching tamamlandı")
    return true
  }
  
  #if canImport(RevenueCat)
  private func configureRevenueCat() {
    // Get API key from Info.plist (configured via Secrets.xcconfig)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
       !apiKey.isEmpty && apiKey != "$(REVENUECAT_API_KEY)" {
      
      #if DEBUG
      Purchases.logLevel = .debug
      print("🔑 RevenueCat: Debug mode enabled")
      #else
      Purchases.logLevel = .info
      #endif
      
      // API key validation
      if apiKey.hasPrefix("sk_") {
        print("❌ HATA: Secret key (sk_) kullanılamaz! Public key (test_ veya appl_) kullanın.")
        print("❌ RevenueCat yapılandırılamadı - API key hatası")
        return
      }
      
      // Test key validation - sadece DEBUG'da kullanılabilir
      #if !DEBUG
      if apiKey.hasPrefix("test_") {
        print("❌ HATA: Test key (test_) Release build'de kullanılamaz!")
        print("❌ Production key (appl_) kullanın veya Debug build yapın.")
        print("❌ RevenueCat yapılandırılamadı - Test key hatası")
        return
      }
      #endif
      
      Purchases.configure(withAPIKey: apiKey)
      print("✅ RevenueCat yapılandırıldı: \(apiKey.prefix(10))...")
      
    } else {
      print("⚠️ RevenueCat API key bulunamadı - Info.plist ve Secrets.xcconfig kontrol edin")
      print("⚠️ Beklenen key: test_ElHyzdqEfyVopUtAWnZlTlOnTmu (Debug) veya appl_... (Release)")
      print("⚠️ Bulunan key: \(Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? "nil")")
    }
  }
  #endif
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
            } else if profileManager.profiles.isEmpty {
                // Hiç profil yok - İlk profili oluştur
                ProfileCreationView()
            } else if profileManager.currentProfile == nil {
                // Profiller var ama seçili değil - Profil seçim ekranı
                ProfileSelectorView()
            } else {
                // Profil seçili - Ana ekrana git
                ContentView()
            }
        }
        .onAppear {
            print("🎯 MainContentView appeared")
            print("📱 Onboarding tamamlandı mı: \(profileManager.hasCompletedOnboarding)")
            print("📱 Profil sayısı: \(profileManager.profiles.count)")
            print("📱 Aktif profil: \(profileManager.currentProfile?.name ?? "yok")")
        }
    }
}

// MARK: - Splash Screen View

/// Açılış ekranı. Tasarımda gradyan, arka plan görseli ve emoji yok;
/// zemin düz sıcak kağıt rengi, marka tipografiyle taşınıyor.
struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .shadow(color: Color(hex: 0x2B1D24, alpha: 0.12), radius: 9, y: 8)

            VStack(spacing: 6) {
                Text("MagicPaper")
                    .font(MP.F.displayXL())
                    .mpTightTracking(40)
                    .foregroundStyle(MP.C.textTitle)

                Text("Her akşam yeni bir masal")
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MP.C.surfaceApp.ignoresSafeArea())
        .onAppear {
            withAnimation(MP.M.spring) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(MP.M.base) { isActive = false }
            }
        }
    }
}
