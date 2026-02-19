import SwiftUI
import FirebaseCore
import FirebaseStorage

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("🚀 AppDelegate: didFinishLaunching başladı")
    
    FirebaseApp.configure()
    print("✅ Firebase yapılandırıldı")
    
    // AdMob KALDIRILDI - Kids Category uyumluluğu için
    // Apple ASIdentifierManager (IDFA) kullanımına izin vermiyor
    // Gelir modeli: Sadece IAP/Abonelik
    
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

struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var emoji: String
}

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @State private var logoPulse: CGFloat = 1.0
    @State private var particles: [SplashParticle] = []
    @State private var particleOffsets: [CGFloat] = []
    
    private let emojis = ["⭐", "✨", "🌟", "💫", "⚡", "🎨", "📖", "🦋"]
    
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
            
            // Floating particles
            GeometryReader { geo in
                ForEach(Array(particles.enumerated()), id: \.element.id) { index, particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .opacity(particle.opacity)
                        .position(
                            x: particle.x * geo.size.width,
                            y: (particle.y * geo.size.height) - (index < particleOffsets.count ? particleOffsets[index] : 0)
                        )
                        .animation(
                            .easeInOut(duration: particle.speed).repeatForever(autoreverses: true),
                            value: index < particleOffsets.count ? particleOffsets[index] : 0
                        )
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Logo with SF Symbol
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(logoPulse)
                    
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
                VStack(spacing: 8) {
                    Text("Magic Paper")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    // Tagline
                    Text("Where stories come alive ✨")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            print("🎬 SplashScreenView appeared")
            
            // Generate particles
            particles = (0..<12).map { i in
                SplashParticle(
                    x: CGFloat.random(in: 0.05...0.95),
                    y: CGFloat.random(in: 0.05...0.95),
                    size: CGFloat.random(in: 14...28),
                    opacity: Double.random(in: 0.3...0.7),
                    speed: Double.random(in: 1.5...3.5),
                    emoji: emojis[i % emojis.count]
                )
            }
            particleOffsets = Array(repeating: 0, count: particles.count)
            
            // Animate particles floating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for i in 0..<particles.count {
                    withAnimation(.easeInOut(duration: particles[i].speed).repeatForever(autoreverses: true)) {
                        if i < particleOffsets.count {
                            particleOffsets[i] = CGFloat.random(in: 20...50)
                        }
                    }
                }
            }
            
            // Animate logo appearance
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    logoPulse = 1.08
                }
            }
            
            // Tagline fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    taglineOpacity = 1.0
                }
            }
            
            // Transition to main app after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                print("⏰ Splash timer completed, transitioning to main app")
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = false
                }
            }
        }
    }
}
