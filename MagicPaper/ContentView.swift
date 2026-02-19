import SwiftUI

struct ContentView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var createButtonPressed = false
    @State private var createButtonRotation: Double = 0
    @Namespace private var tabNamespace
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white
                .ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case 0:
                    HomeView(onNavigate: handleNavigation)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case 1:
                    LibraryView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case 3:
                    DailyStoriesView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case 4:
                    SettingsView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                default:
                    HomeView(onNavigate: handleNavigation)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, DeviceHelper.tabBarBottomPadding)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: selectedTab)
            
            VStack(spacing: 0) {
                Spacer()
                customTabBar
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingCreateSheet) {
            CreateStoryTypeSelectionView(onNavigateToLibrary: {
                selectedTab = 1
            })
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                createButtonRotation = 360
            }
        }
    }
    
    // MARK: - Navigation Handling
    
    private func handleNavigation(_ request: NavigationRequest) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch request {
            case .settings:
                selectedTab = 4
            case .library:
                selectedTab = 1
            case .dailyStories:
                selectedTab = 3
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(icon: "house.fill", title: localizationManager.currentLanguage == .turkish ? "Ana Sayfa" : "Home", tag: 0)
            tabBarButton(icon: "books.vertical.fill", title: localizationManager.localized(.library), tag: 1)
            
            // Center Create Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showingCreateSheet = true
                }
            }) {
                ZStack {
                    // Rotating gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85),
                                    Color(red: 1.0, green: 0.45, blue: 0.55),
                                    Color(red: 0.58, green: 0.29, blue: 0.98)
                                ],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(createButtonRotation))
                    
                    // Glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.35),
                                    Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .blur(radius: 10)
                    
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
                        .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.5), radius: createButtonPressed ? 8 : 20, x: 0, y: createButtonPressed ? 2 : 8)
                    
                    // Inner highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(createButtonPressed ? 45 : 0))
                }
                .scaleEffect(createButtonPressed ? 0.92 : 1.0)
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            createButtonPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            createButtonPressed = false
                        }
                    }
            )
            
            tabBarButton(icon: "calendar", title: localizationManager.localized(.daily), tag: 3)
            tabBarButton(icon: "gearshape.fill", title: localizationManager.localized(.settings), tag: 4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.gray.opacity(0.1)],
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
        let isSelected = selectedTab == tag
        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Sliding glass pill (matchedGeometryEffect)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.13),
                                        Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.13)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 40)
                            .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 28)
                        .scaleEffect(isSelected ? 1.12 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isSelected)
                }
                
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.6)],
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
    
    // Callback for navigation to library
    var onNavigateToLibrary: (() -> Void)?
    
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
                                dismiss()
                                onNavigateToLibrary?()
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

// MARK: - Navigation Request Enum

enum NavigationRequest {
    case settings
    case library
    case dailyStories
}

#Preview {
    ContentView()
}
