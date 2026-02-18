import SwiftUI

struct ContentView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
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
            .padding(.bottom, DeviceHelper.tabBarBottomPadding)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // Custom Tab Bar - SafeArea'nın altına sabitlendi
            VStack(spacing: 0) {
                Spacer()
                customTabBar
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light) // Sabit aydınlık mod
        .sheet(isPresented: $showingCreateSheet) {
            CreateStoryTypeSelectionView()
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(icon: "house.fill", title: localizationManager.currentLanguage == .turkish ? "Ana Sayfa" : "Home", tag: 0)
            tabBarButton(icon: "books.vertical.fill", title: localizationManager.localized(.library), tag: 1)
            
            // Center Create Button - Daha büyük ve çekici
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showingCreateSheet = true
                }
            }) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3),
                                    Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .blur(radius: 8)
                    
                    // Main button
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
                        .frame(width: 60, height: 60)
                        .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.4), radius: 16, x: 0, y: 6)
                    
                    // Inner highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    // Plus icon
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)
            
            tabBarButton(icon: "calendar", title: localizationManager.localized(.daily), tag: 3)
            tabBarButton(icon: "gearshape.fill", title: localizationManager.localized(.settings), tag: 4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            ZStack {
                // Main background with blur
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // White overlay
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: -8)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
    
    private func tabBarButton(icon: String, title: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Background indicator
                    if selectedTab == tag {
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
                            .frame(width: 48, height: 48)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: selectedTab == tag ? 22 : 20, weight: selectedTab == tag ? .semibold : .medium))
                        .foregroundStyle(
                            selectedTab == tag ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray, Color.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 28)
                        .scaleEffect(selectedTab == tag ? 1.1 : 1.0)
                }
                
                // Title
                Text(title)
                    .font(.system(size: selectedTab == tag ? 11 : 10, weight: selectedTab == tag ? .bold : .medium))
                    .foregroundStyle(
                        selectedTab == tag ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray, Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Tab Button Style

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
                                Text(L.newStory)
                                    .font(.system(size: 32, weight: .bold))
                                
                                Text(L.whichStoryType)
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
                                    title: L.illustratedStory,
                                    description: L.illustratedDesc,
                                    gradient: [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)],
                                    badge: L.popular
                                )
                            }
                            
                            NavigationLink(destination: TextOnlyStoryView(onNavigateToLibrary: {
                                selectedTab = 1 // Library tab
                            })) {
                                modernStoryCard(
                                    icon: "text.book.closed",
                                    title: L.textStory,
                                    description: L.textStoryDesc,
                                    gradient: [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)],
                                    badge: nil
                                )
                            }
                            
                            NavigationLink(destination: DailyStoryCreationView(category: .bedtime)) {
                                modernStoryCard(
                                    icon: "calendar.badge.plus",
                                    title: L.dailyStory,
                                    description: L.dailyStoryDesc,
                                    gradient: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.55, blue: 0.45)],
                                    badge: nil
                                )
                            }
                        }
                        .padding(.horizontal, DeviceHelper.horizontalPadding)
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
        .navigationViewStyle(.stack) // iPad'de split view'ı devre dışı bırak
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
