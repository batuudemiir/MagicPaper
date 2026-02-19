import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isRequestingPermissions = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "photo.on.rectangle.angled",
            title: "Fotoğraf Ekle",
            description: "Çocuğunuzun fotoğrafını yükleyin ve hikayenin kahramanı olsun",
            gradient: [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)],
            floatingEmojis: ["📸", "🌟", "✨", "💫", "🎭"]
        ),
        OnboardingPage(
            icon: "paintpalette.fill",
            title: "Tema Seç",
            description: "Uzay, orman, denizaltı... Hayal gücünüzü serbest bırakın",
            gradient: [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)],
            floatingEmojis: ["🎨", "🚀", "🦁", "🐬", "🏰"]
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Sihir Başlasın",
            description: "Yapay zeka ile kişiselleştirilmiş, benzersiz hikayeler oluşturun",
            gradient: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.55, blue: 0.45)],
            floatingEmojis: ["✨", "⭐", "🌈", "🎉", "📖"]
        )
    ]
    
    var body: some View {
        ZStack {
            // Morphing gradient background
            LinearGradient(
                colors: pages[currentPage].gradient.map { $0.opacity(0.12) } + [Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // White base
            Color.white.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        ProfileManager.shared.completeOnboarding()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isOnboardingComplete = true
                        }
                    }) {
                        Text(L.skip)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Custom page indicator - pill style
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(
                                currentPage == index ?
                                LinearGradient(
                                    colors: pages[index].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: currentPage == index ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    // Geri butonu
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(L.back)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.58, green: 0.29, blue: 0.98), lineWidth: 2)
                            )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    // İleri/Başla butonu
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } else {
                            // Son sayfada - İzinleri iste
                            Task {
                                isRequestingPermissions = true
                                await permissionManager.requestAllPermissions()
                                isRequestingPermissions = false
                                
                                ProfileManager.shared.completeOnboarding()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isOnboardingComplete = true
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isRequestingPermissions {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(currentPage < pages.count - 1 ? L.next : L.getStarted)
                                    .font(.system(size: 17, weight: .bold))
                                Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: pages[currentPage].gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: pages[currentPage].gradient[0].opacity(0.3), radius: 12, x: 0, y: 6)
                        )
                    }
                    .disabled(isRequestingPermissions)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .preferredColorScheme(.light) // Sabit aydınlık mod
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let floatingEmojis: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var floatOffsets: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with gradient background + floating emojis
            ZStack {
                // Floating emoji decorations
                ForEach(0..<min(page.floatingEmojis.count, 5), id: \.self) { i in
                    let angle = Double(i) * (360.0 / Double(min(page.floatingEmojis.count, 5)))
                    let radius: CGFloat = 110
                    Text(page.floatingEmojis[i])
                        .font(.system(size: 22))
                        .offset(
                            x: CGFloat(cos(angle * .pi / 180)) * radius,
                            y: CGFloat(sin(angle * .pi / 180)) * radius + floatOffsets[i]
                        )
                        .opacity(appeared ? 0.85 : 0)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...2.5)).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                            value: floatOffsets[i]
                        )
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { $0.opacity(0.25) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)
                
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 40)
            .onAppear {
                appeared = true
                for i in 0..<floatOffsets.count {
                    withAnimation(
                        .easeInOut(duration: Double.random(in: 1.5...2.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2)
                    ) {
                        floatOffsets[i] = CGFloat.random(in: -12...12)
                    }
                }
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
