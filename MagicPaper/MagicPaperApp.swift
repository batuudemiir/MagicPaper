import SwiftUI
import OSLog
import FirebaseCore
import FirebaseStorage
import GoogleSignIn
#if canImport(RevenueCat)
import RevenueCat
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "MagicPaperApp")

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("🚀 AppDelegate: didFinishLaunching başladı")
    
    FirebaseApp.configure()
    // Ebeveyn hesabı ve senkron (FAZ 16): Firestore ayarı ilk kullanımdan
    // önce yapılmak zorunda; ardından önceki oturum varsa geri alınır.
    FirebaseBackend.configure()
    AccountService.shared.bootstrap()
    print("✅ Firebase yapılandırıldı")

    // Günün masalı ve içerik paketleri arka planda da yenilenir (FAZ 15).
    // Kayıt, açılış bitmeden yapılmak zorunda.
    RemoteContentService.registerBackgroundRefresh()
    RemoteContentService.scheduleBackgroundRefresh()
    
    // RevenueCat Configuration
    #if canImport(RevenueCat)
    configureRevenueCat()
    #else
    print("⚠️ RevenueCat modülü bulunamadı - Xcode'da package'ı target'a ekleyin")
    #endif
    
    // AdMob KALDIRILDI - Kids Category uyumluluğu için
    // Apple ASIdentifierManager (IDFA) kullanımına izin vermiyor
    // Gelir modeli: Sadece IAP/Abonelik
    
    // Bildirim izni burada İSTENMİYOR.
    //
    // Açılışta, ortada tek bir masal yokken sorulan izin, hiçbir şey vaat
    // etmeden sorulmuş izindir; üstelik izin verilse bile uygulama bugüne
    // kadar tek bir bildirim planlamıyordu. İzin artık ebeveyn "Masal saati
    // hatırlatması"nı açtığı anda isteniyor (MPReminder), yani istenen şeyin
    // ne işe yarayacağı ekranda yazarken. iOS bir kez reddedilen izni bir daha
    // sormaz — o yüzden hangi anda sorulduğu geri alınamaz bir karar.
    
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
      // Only the scheme prefix, never key material: `prefix(10)` revealed five
      // characters of the secret itself, and `print` survives into Release.
      print("✅ RevenueCat yapılandırıldı: \(apiKey.prefix(5))… (\(apiKey.count) karakter)")
      
    } else {
      print("⚠️ RevenueCat API key bulunamadı - Info.plist ve Secrets.xcconfig kontrol edin")
      // Neither the expected key nor the found one is printed. The expected one
      // was a real test key literal sitting in source; the found one printed
      // whatever Info.plist held, in full. Both stay diagnosable from the shape
      // alone — which prefix arrived, and how long it was.
      let found = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String
      print("⚠️ Beklenen önek: test_ (Debug) veya appl_ (Release)")
      print("⚠️ Bulunan: \(found.map { "\($0.prefix(5))… (\($0.count) karakter)" } ?? "yok")")
    }
  }
  #endif
}

@main
struct MagicPaperApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @ObservedObject private var profileManager = ProfileManager.shared
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
      // Google ile giriş tarayıcıdan bu adrese döner (FAZ 16).
      .onOpenURL { url in _ = GIDSignIn.sharedInstance.handle(url) }
    }
  }
}

// MARK: - Main Content View

struct MainContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var sync = AccountService.shared.sync
    @Environment(\.scenePhase) private var scenePhase

    /// Karşılama → Giriş → Ebeveyn onayı → Profil → Neleri sever → İlk masal
    /// (FAZ 16). Already-installed apps meet Giriş and Onay once, on the first
    /// launch after the update; their children and stories then go to the
    /// account.
    private var gate: AppGate {
        AppGate.resolve(.init(
            onboardingDone: profileManager.hasCompletedOnboarding,
            signedIn: account.account != nil,
            deferredSignIn: account.deferredSignIn,
            consentCurrent: account.consent != nil,
            restoreSettled: sync.restored,
            hasProfiles: !profileManager.profiles.isEmpty,
            hasCurrentProfile: profileManager.currentProfile != nil))
    }

    var body: some View {
        Group {
            switch gate {
            case .intro:
                OnboardingView(isOnboardingComplete: $profileManager.hasCompletedOnboarding)
            case .signIn:
                AccountSignInView()
            case .consent:
                if account.checkingConsent { AccountWaitView() } else { ParentConsentView() }
            case .restoring:
                AccountRestoreView()
            case .createProfile:
                ProfileCreationView()
            case .selectProfile:
                ProfileSelectorView()
            case .app:
                ContentView()
            }
        }
        .animation(MP.M.gated(MP.M.base), value: gate)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { sync.schedule(after: 0) }
        }
        .onAppear {
            #if DEBUG
            MPDebugLaunch.applyBeforeGate()
            #endif
            // Çocuğun adı loglanmaz (CLAUDE.md §10); yalnızca seçili profil var mı.
            logger.debug("Aktif profil seçili: \(profileManager.currentProfile != nil, privacy: .public)")
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
                .mpShadow(MP.Sh.art)

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
