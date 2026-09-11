import SwiftUI

struct HomeView: View {
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var dailyStoryManager = DailyStoryManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedStory: Story?
    @State private var selectedDailyStory: DailyStory?
    @State private var showingSubscriptionSheet = false
    @State private var showingSettings = false
    @State private var showingLibrary = false
    @State private var showingDailyStories = false
    
    // Animation states
    @State private var heroAppeared = false
    @State private var cardsAppeared = false
    @State private var scrollOffset: CGFloat = 0
    
    // Navigation callback
    var onNavigate: ((NavigationRequest) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    // Premium animated background
                    PremiumBackground()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DeviceHelper.isIPad ? DeviceHelper.cardSpacing : 12) {
                            // Hero Section with parallax
                            premiumHeroSection
                                .frame(height: heroHeight(for: geometry.size.height))
                                .padding(.top, DeviceHelper.isIPad ? 8 : 4)
                                .opacity(heroAppeared ? 1 : 0)
                                .scaleEffect(heroAppeared ? 1 : 0.95)
                            
                            // Cards with staggered animation
                            Group {
                                premiumSubscriptionCard
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .offset(y: cardsAppeared ? 0 : 20)
                                
                                premiumQuickActions
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .offset(y: cardsAppeared ? 0 : 30)
                                
                                premiumDailyStoriesFeed
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .offset(y: cardsAppeared ? 0 : 40)
                            }
                        }
                        .padding(.horizontal, DeviceHelper.horizontalPadding)
                        .padding(.bottom, DeviceHelper.isIPad ? 32 : 20)
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
        }
        .fullScreenCover(item: $selectedStory) { story in
            StoryViewerView(story: story)
                .ignoresSafeArea(.all, edges: .all)
        }
        .fullScreenCover(item: $selectedDailyStory) { story in
            DailyStoryReaderView(story: story)
                .ignoresSafeArea(.all, edges: .all)
                .onAppear {
                    print("✅ DailyStoryReaderView presented with story: \(story.title)")
                }
        }
        .fullScreenCover(isPresented: $showingSubscriptionSheet) {
            SimpleSubscriptionView()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingLibrary) {
            NavigationView {
                LibraryView()
            }
        }
        .sheet(isPresented: $showingDailyStories) {
            NavigationView {
                DailyStoriesView()
            }
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    // MARK: - Helper Functions
    
    private func heroHeight(for screenHeight: CGFloat) -> CGFloat {
        if DeviceHelper.isIPad {
            return 420
        } else {
            // iPhone: Hero section ekranın maksimum %18'i olsun, max 160px
            let calculatedHeight = screenHeight * 0.18
            return min(calculatedHeight, 160)
        }
    }
    
    // MARK: - Animations
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            heroAppeared = true
        }
        
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
            cardsAppeared = true
        }
    }
    
    // MARK: - Premium Components
    
    
    // MARK: - Hero Section
    
    private var premiumHeroSection: some View {
        NavigationLink(destination: CreateStoryView()) {
            if DeviceHelper.isIPad {
                // iPad: Premium büyük tasarım
                iPadHeroSection
            } else {
                // iPhone: Kompakt tasarım
                iPhoneHeroSection
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - iPad Hero Section
    
    private var iPadHeroSection: some View {
        ZStack {
            // Dynamic gradient background with mesh effect
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.9),
                        Color(red: 0.7, green: 0.3, blue: 0.9),
                        Color(red: 0.9, green: 0.4, blue: 0.7),
                        Color(red: 1.0, green: 0.5, blue: 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: -50 + (scrollOffset * 0.1), y: -50 + (scrollOffset * 0.1))
                        .blur(radius: 30)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                        .frame(width: 240, height: 240)
                        .offset(x: geometry.size.width - 100 - (scrollOffset * 0.08), y: geometry.size.height - 80 - (scrollOffset * 0.08))
                        .blur(radius: 25)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .blur(radius: 20)
                }
            }
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text(L.magicStories)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                        
                        Text(L.makeChildHero)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        heroFeaturePill(icon: "photo.fill", text: L.photo)
                        heroFeaturePill(icon: "paintbrush.fill", text: L.theme)
                        heroFeaturePill(icon: "wand.and.stars", text: L.magic)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(L.getStartedNow)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.9))
                    .frame(maxWidth: 600)
                    .padding(.vertical, 22)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: DeviceHelper.cornerRadius, style: .continuous)
                                .fill(Color.white)
                            
                            RoundedRectangle(cornerRadius: DeviceHelper.cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.purple.opacity(0.4), radius: 24, x: 0, y: 10)
                    )
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: DeviceHelper.cornerRadius + 4, style: .continuous))
        .shadow(color: Color.purple.opacity(0.5), radius: 28, x: 0, y: 14)
        .overlay(
            RoundedRectangle(cornerRadius: DeviceHelper.cornerRadius + 4, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    // MARK: - iPhone Hero Section (Kompakt)
    
    private var iPhoneHeroSection: some View {
        HStack(spacing: 10) {
            // Sol taraf - Icon ve başlık
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.15), Color.pink.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text("✨")
                        .font(.system(size: 22))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.magicStories)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(L.makeChildHero)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Sağ taraf - CTA button
            HStack(spacing: 5) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(L.tr("Oluştur", "Create"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.purple.opacity(0.12), radius: 10, x: 0, y: 4)
        )
    }
    
    // Helper for iPad hero pills
    private func heroFeaturePill(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(text)
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                
                Capsule()
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
    }
    
    
    // MARK: - Subscription Card
    
    private var premiumSubscriptionCard: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showingSubscriptionSheet = true
        }) {
            PremiumCard(
                padding: DeviceHelper.isIPad ? 24 : 12,
                cornerRadius: DeviceHelper.isIPad ? DeviceHelper.cornerRadius : 16
            ) {
                HStack(spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 16 : 10)) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: subscriptionManager.isPremium ?
                                        [Color.yellow.opacity(0.2), Color.orange.opacity(0.2)] :
                                        subscriptionManager.freeTrialCount > 0 ?
                                        [Color.green.opacity(0.2), Color.blue.opacity(0.2)] :
                                        [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: DeviceHelper.isIPad ? 70 : 44,
                                height: DeviceHelper.isIPad ? 70 : 44
                            )
                        
                        Text(subscriptionManager.isPremium ? "👑" : subscriptionManager.freeTrialCount > 0 ? "🎁" : "✨")
                            .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 30 : 22)))
                    }
                    
                    VStack(alignment: .leading, spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 6 : 4)) {
                        if subscriptionManager.isPremium {
                            Text(subscriptionManager.subscriptionTier.displayName)
                                .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 16 : 13), weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Text("\(subscriptionManager.remainingImageStories)")
                                    .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 20 : 16), weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                Text(L.illustratedRemaining)
                                    .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 13 : 11), weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        } else if subscriptionManager.freeTrialCount > 0 {
                            Text(L.tr("🎁 Deneme Aktif", "🎁 Trial Active"))
                                .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 16 : 13), weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            HStack(spacing: 4) {
                                Text("\(subscriptionManager.freeTrialCount)")
                                    .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 20 : 16), weight: .bold))
                                    .foregroundColor(.green)
                                Text(L.storiesRemaining)
                                    .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 13 : 11), weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(L.tr("📦 Ücretsiz Paket", "📦 Free Package"))
                                .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 16 : 13), weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(L.unlockMagic)
                                .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 13 : 11), weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if !subscriptionManager.isPremium {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 24 : 20), weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Actions
    
    private var premiumQuickActions: some View {
        HStack(spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 12 : 8)) {
            NavigationLink(destination: CreateStoryView()) {
                premiumQuickActionButton(
                    icon: "photo.fill",
                    title: L.illustrated,
                    gradient: [.purple, .pink]
                )
            }
            
            NavigationLink(destination: TextOnlyStoryView(onNavigateToLibrary: {
                onNavigate?(.library)
            })) {
                premiumQuickActionButton(
                    icon: "text.book.closed.fill",
                    title: L.text,
                    gradient: [.blue, .cyan]
                )
            }
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                showingDailyStories = true
            }) {
                premiumQuickActionButton(
                    icon: "calendar",
                    title: L.daily,
                    gradient: [.orange, .red]
                )
            }
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                showingLibrary = true
            }) {
                premiumQuickActionButton(
                    icon: "books.vertical.fill",
                    title: L.library,
                    gradient: [.green, .mint]
                )
            }
        }
    }
    
    private func premiumQuickActionButton(icon: String, title: String, gradient: [Color]) -> some View {
        VStack(spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 10 : 6)) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [gradient[0].opacity(0.15), gradient[1].opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: DeviceHelper.isIPad ? 60 : 36,
                        height: DeviceHelper.isIPad ? 60 : 36
                    )
                
                Image(systemName: icon)
                    .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 20 : 15), weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.system(size: DeviceHelper.fontSize(DeviceHelper.isIPad ? 12 : 10), weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DeviceHelper.isIPad ? 20 : 10)
        .background(
            RoundedRectangle(cornerRadius: DeviceHelper.isIPad ? (DeviceHelper.cornerRadius - 4) : 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    
    // MARK: - Daily Stories Feed
    
    private var premiumDailyStoriesFeed: some View {
        VStack(alignment: .leading, spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 16 : 12)) {
            if !dailyStoryManager.dailyStories.isEmpty {
                PremiumSectionHeader(
                    title: L.dailyStories,
                    subtitle: L.tr("Her gün yeni hikayeler", "New stories every day"),
                    icon: "calendar.badge.clock"
                )
                
                LazyVStack(spacing: DeviceHelper.spacing(DeviceHelper.isIPad ? 16 : 12)) {
                    ForEach(dailyStoryManager.dailyStories) { story in
                        premiumDailyStoryCard(story)
                    }
                }
            } else {
                PremiumEmptyState(
                    icon: "calendar.badge.clock",
                    title: L.noDailyStoriesYet,
                    subtitle: L.dailyStoriesComingSoon,
                    actionTitle: L.tr("Günlük Hikayeleri Keşfet", "Explore Daily Stories"),
                    action: {
                        showingDailyStories = true
                    }
                )
            }
        }
    }
    
    private func premiumDailyStoryCard(_ story: DailyStory) -> some View {
        Button(action: {
            print("🔵 Daily story card tapped: \(story.title)")
            print("   Story ID: \(story.id)")
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            selectedDailyStory = story
            print("   selectedDailyStory set to: \(selectedDailyStory?.title ?? "nil")")
        }) {
            PremiumCard(padding: DeviceHelper.isIPad ? 20 : 16, cornerRadius: DeviceHelper.cornerRadius) {
                VStack(alignment: .leading, spacing: DeviceHelper.spacing(12)) {
                    // Header
                    HStack(spacing: DeviceHelper.spacing(12)) {
                        ZStack {
                            Circle()
                                .fill(story.category.color.opacity(0.15))
                                .frame(width: DeviceHelper.isIPad ? 52 : 44, height: DeviceHelper.isIPad ? 52 : 44)
                            
                            Text(story.category.emoji)
                                .font(.system(size: DeviceHelper.fontSize(22)))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.category.displayName)
                                .font(.system(size: DeviceHelper.fontSize(14), weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Label("\(story.readingTime) \(L.readingMinutes)", systemImage: "clock.fill")
                                    .font(.system(size: DeviceHelper.fontSize(11), weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Label("\(story.ageRange) \(L.ageYears)", systemImage: "person.fill")
                                    .font(.system(size: DeviceHelper.fontSize(11), weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if story.isRead {
                            PremiumBadge(
                                text: L.tr("Okundu", "Read"),
                                icon: "checkmark",
                                colors: [.green, .mint]
                            )
                        } else {
                            PremiumBadge(
                                text: L.new,
                                icon: "sparkles",
                                colors: [.orange, .red]
                            )
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: DeviceHelper.spacing(8)) {
                        Text(story.title)
                            .font(.system(size: DeviceHelper.fontSize(18), weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(story.content)
                            .font(.system(size: DeviceHelper.fontSize(14), weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(DeviceHelper.isIPad ? 4 : 3)
                    }
                    
                    // Action
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill")
                                .font(.system(size: DeviceHelper.fontSize(12), weight: .semibold))
                            Text(L.readAction)
                                .font(.system(size: DeviceHelper.fontSize(13), weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [story.category.color, story.category.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Views

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
}
