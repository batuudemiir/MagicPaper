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
    FirebaseApp.configure()
    // Ebeveyn hesabı ve senkron (FAZ 16): Firestore ayarı ilk kullanımdan
    // önce yapılmak zorunda; ardından önceki oturum varsa geri alınır.
    FirebaseBackend.configure()
    AccountService.shared.bootstrap()

    // Günün masalı ve içerik paketleri arka planda da yenilenir (FAZ 15).
    // Kayıt, açılış bitmeden yapılmak zorunda.
    RemoteContentService.registerBackgroundRefresh()
    RemoteContentService.scheduleBackgroundRefresh()

    // Uygulama uyku modundayken kapatıldıysa Live Activity kilit ekranında
    // kalmasın (FAZ 19).
    MPSleepActivity.endAll()
    
    // RevenueCat Configuration
    #if canImport(RevenueCat)
    configureRevenueCat()
    #else
    logger.error("RevenueCat modülü bulunamadı")
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
    
    MPMetrics.shared.start()
    return true
  }
  
  #if canImport(RevenueCat)
  private func configureRevenueCat() {
    // Get API key from Info.plist (configured via Secrets.xcconfig)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
       !apiKey.isEmpty && apiKey != "$(REVENUECAT_API_KEY)" {
      
      #if DEBUG
      Purchases.logLevel = .debug
      #else
      Purchases.logLevel = .info
      #endif
      
      // API key validation
      if apiKey.hasPrefix("sk_") {
        logger.error("RevenueCat yapılandırılamadı: secret key kullanılamaz, public key gerekir")
        return
      }
      
      // Test key validation - sadece DEBUG'da kullanılabilir
      #if !DEBUG
      if apiKey.hasPrefix("test_") {
        logger.error("RevenueCat yapılandırılamadı: test key Release derlemesinde kullanılamaz")
        return
      }
      #endif
      
      Purchases.configure(withAPIKey: apiKey)
    } else {
      // Anahtarın kendisi ya da öneki yazılmaz; eksik olduğu yeter.
      logger.error("RevenueCat API key bulunamadı: Info.plist ve Secrets.xcconfig kontrol edilmeli")
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

  var body: some Scene {
    WindowGroup {
      ZStack {
        if showSplash {
          // Splash screen
          SplashScreenView(isActive: $showSplash)
        } else {
          // Main app content
          MainContentView()
            .environmentObject(profileManager)
        }
      }
      // Uygulama Türkçe: büyük harf (İ), tarih ve saat seçicileri tr_TR.
      .environment(\.locale, Locale(identifier: "tr_TR"))
      // Google ile giriş tarayıcıdan bu adrese döner (FAZ 16).
      .onOpenURL { url in
        // Widget ve Live Activity (FAZ 19): çocuk alanında bir yer.
        if let link = MPSurfaceLink(url: url) {
          MPSurfaceRouter.shared.pending = link
          return
        }
        // Aile daveti (FAZ 18): kod bekler, ebeveyn kapısından sonra açılır.
        if FamilyFeatureAccess.isEnabled(.familyMembers), let code = FamilyInviteCode.from(url: url) {
          AccountService.shared.pendingInviteCode = code
          return
        }
        _ = GIDSignIn.sharedInstance.handle(url)
      }
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

/// Açılış ekranı (01 · Marka): yazı markası ve kitaptaki Ragi, karşılamanın
/// sabah ışığı zemininde.
struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            MPGlowBackground(style: .dawn)
            VStack(spacing: MPSpacing.xxl) {
                Image("Brand/wordmarkLight")
                    .resizable().scaledToFit()
                    .frame(maxWidth: 240)
                    .accessibilityLabel("MagicPaper")
                MascotImage(mascot: .onBook, width: 220)
                    .accessibilityHidden(true)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.94)
        }
        .onAppear {
            withAnimation(MP.M.spring) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(MP.M.base) { isActive = false }
            }
        }
    }
}
