import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Sabit beyaz arka plan
            Color.white
                .ignoresSafeArea()
            
            // Main Content - Her view ayrı ayrı gösterilir
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                        .transition(.opacity)
                case 1:
                    LibraryView()
                        .transition(.opacity)
                case 3:
                    DailyStoriesView()
                        .transition(.opacity)
                case 4:
                    SettingsView()
                        .transition(.opacity)
                default:
                    HomeView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light) // Sabit aydınlık mod
        .sheet(isPresented: $showingCreateSheet) {
            CreateStoryTypeSelectionView()
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(icon: "house.fill", title: "Ana Sayfa", tag: 0)
            tabBarButton(icon: "books.vertical.fill", title: "Kütüphane", tag: 1)
            
            // Center Create Button
            Button(action: {
                showingCreateSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 12, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -8)
            .frame(maxWidth: .infinity)
            
            tabBarButton(icon: "calendar", title: "Günlük", tag: 3)
            tabBarButton(icon: "gearshape.fill", title: "Ayarlar", tag: 4)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            ZStack {
                // Glassmorphism effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.7))
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func tabBarButton(icon: String, title: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: selectedTab == tag ? 20 : 18, weight: .medium))
                    .foregroundColor(selectedTab == tag ? Color(red: 0.58, green: 0.29, blue: 0.98) : .gray)
                    .frame(height: 24)
                
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundColor(selectedTab == tag ? Color(red: 0.58, green: 0.29, blue: 0.98) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selectedTab == tag ?
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.1))
                    : nil
            )
        }
    }
}

// MARK: - Create Story Type Selection View

struct CreateStoryTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Sabit beyaz arka plan
                Color.white
                    .ignoresSafeArea()
                
                // Modern gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 1.0),
                        Color(red: 0.95, green: 0.96, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.5)
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.15),
                                                Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                            }
                            
                            VStack(spacing: 8) {
                                Text("Yeni Hikaye")
                                    .font(.system(size: 32, weight: .bold))
                                
                                Text("Hangi tür hikaye oluşturmak istersiniz?")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 24)
                        
                        // Story Type Cards
                        VStack(spacing: 16) {
                            NavigationLink(destination: CreateStoryView()) {
                                modernStoryCard(
                                    icon: "photo.on.rectangle.angled",
                                    title: "Görselli Hikaye",
                                    description: "Fotoğrafla kişiselleştirilmiş",
                                    gradient: [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)],
                                    badge: "Popüler"
                                )
                            }
                            
                            NavigationLink(destination: TextOnlyStoryView()) {
                                modernStoryCard(
                                    icon: "text.book.closed",
                                    title: "Metin Hikaye",
                                    description: "Hayal gücünü harekete geçir",
                                    gradient: [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)],
                                    badge: nil
                                )
                            }
                            
                            NavigationLink(destination: DailyStoryCreationView(category: .bedtime)) {
                                modernStoryCard(
                                    icon: "calendar.badge.plus",
                                    title: "Günlük Hikaye",
                                    description: "Her gün yeni bir macera",
                                    gradient: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.55, blue: 0.45)],
                                    badge: "Yeni"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light) // Sabit aydınlık mod
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.3))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
    
    private func modernStoryCard(icon: String, title: String, description: String, gradient: [Color], badge: String?) -> some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: gradient[0].opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }
}

#Preview {
    ContentView()
}
