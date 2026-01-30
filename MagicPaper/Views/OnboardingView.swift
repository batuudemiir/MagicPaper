import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "photo.on.rectangle.angled",
            title: "Fotoğraf Ekle",
            description: "Çocuğunuzun fotoğrafını yükleyin ve hikayenin kahramanı olsun",
            gradient: [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)]
        ),
        OnboardingPage(
            icon: "paintpalette.fill",
            title: "Tema Seç",
            description: "Uzay, orman, denizaltı... Hayal gücünüzü serbest bırakın",
            gradient: [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)]
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Sihir Başlasın",
            description: "Yapay zeka ile kişiselleştirilmiş, benzersiz hikayeler oluşturun",
            gradient: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.55, blue: 0.45)]
        )
    ]
    
    var body: some View {
        ZStack {
            // Sabit beyaz arka plan
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isOnboardingComplete = true
                        }
                    }) {
                        Text("Atla")
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
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? 
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
                                Text("Geri")
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
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isOnboardingComplete = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "İleri" : "Başla")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 16, weight: .bold))
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
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
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with gradient background
            ZStack {
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
