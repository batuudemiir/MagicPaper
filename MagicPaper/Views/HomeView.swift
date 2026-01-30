import SwiftUI

struct HomeView: View {
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var dailyStoryManager = DailyStoryManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedStory: Story?
    @State private var selectedDailyStory: DailyStory?
    @State private var showingSubscriptionSheet = false
    @State private var showingDailyStoryReader = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero Section - Tanıtıcı
                    heroSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Header - Abonelik ve Hızlı Aksiyonlar
                    headerSection
                        .padding(.horizontal, 20)
                    
                    // Günlük Hikayeler Feed - Instagram tarzı
                    dailyStoriesFeed
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        NavigationLink(destination: SettingsView()) {
                            Label("Ayarlar", systemImage: "gearshape.fill")
                        }
                        
                        NavigationLink(destination: LibraryView()) {
                            Label("Kütüphanem", systemImage: "books.vertical.fill")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingSubscriptionSheet = true
                        }) {
                            Label("Abonelik", systemImage: "crown.fill")
                        }
                        
                        Divider()
                        
                        NavigationLink(destination: DailyStoriesView()) {
                            Label("Günlük Hikayeler", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("MagicPaper")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSubscriptionSheet = true
                    }) {
                        Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "plus.circle.fill")
                            .foregroundColor(subscriptionManager.isPremium ? .yellow : .orange)
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(item: $selectedStory) { story in
            StoryViewerView(story: story)
        }
        .sheet(isPresented: $showingDailyStoryReader) {
            if let story = selectedDailyStory {
                DailyStoryReaderView(story: story)
            }
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            SimpleSubscriptionView()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        ZStack {
            // Arka plan - İkon renklerine uygun gradient (mor → pembe → kırmızı-pembe)
            LinearGradient(
                colors: [
                    Color(red: 0.58, green: 0.29, blue: 0.98), // Mor (#9449FA)
                    Color(red: 0.85, green: 0.35, blue: 0.85), // Pembe (#D959D9)
                    Color(red: 1.0, green: 0.45, blue: 0.55)   // Kırmızı-pembe (#FF738C)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dekoratif elementler
            GeometryReader { geometry in
                // Sol üst daire
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: -60, y: -40)
                
                // Sağ alt daire
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .offset(x: geometry.size.width - 70, y: geometry.size.height - 60)
                
                // Orta parlama efekti
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            // İçerik
            VStack(spacing: 20) {
                // İkon ve başlık grubu
                VStack(spacing: 14) {
                    // İkon
                    ZStack {
                        // Arka plan halka
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 76, height: 76)
                        
                        // İç daire
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                        
                        // İkon
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Başlık
                    VStack(spacing: 5) {
                        Text("Sihirli Hikayeler")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Çocuğunuz Kahramanı Olsun")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))
                    }
                }
                .padding(.top, 32)
                
                // Özellikler - Horizontal pills
                HStack(spacing: 12) {
                    featurePill(icon: "photo.fill", text: "Fotoğraf")
                    featurePill(icon: "paintbrush.fill", text: "Tema")
                    featurePill(icon: "sparkles", text: "Sihir")
                }
                
                // CTA Butonu
                NavigationLink(destination: CreateStoryView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                        Text("Hemen Başla")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98)) // Mor
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.35), radius: 18, x: 0, y: 8)
    }
    
    // Kompakt özellik pill
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Abonelik durumu kartı
            subscriptionStatusCard
            
            // Hızlı aksiyonlar
            quickActionsRow
        }
    }
    
    private var subscriptionStatusCard: some View {
        Button(action: {
            showingSubscriptionSheet = true
        }) {
            HStack(spacing: 12) {
                // İkon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: subscriptionManager.isPremium ?
                                    [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)] :
                                    subscriptionManager.freeTrialCount > 0 ?
                                    [Color.green.opacity(0.3), Color.blue.opacity(0.3)] :
                                    [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(subscriptionManager.isPremium ? "👑" : subscriptionManager.freeTrialCount > 0 ? "🎁" : "✨")
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if subscriptionManager.isPremium {
                        Text(subscriptionManager.subscriptionTier.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text("\(subscriptionManager.remainingImageStories) görselli kaldı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if subscriptionManager.freeTrialCount > 0 {
                        Text("🎁 \(subscriptionManager.freeTrialCount) Deneme Kaldı")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        
                        Text("Ücretsiz hikayelerinizi kullanın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("☕️ Kahveden Ucuz!")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                        
                        Text("Günde 3₺ ile sınırsız hikaye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.4))
                    .font(.caption)
            }
            .padding(12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: CreateStoryView()) {
                quickActionButton(icon: "photo.fill", title: "Görselli", color: .purple)
            }
            
            NavigationLink(destination: TextOnlyStoryView()) {
                quickActionButton(icon: "text.book.closed.fill", title: "Metin", color: .blue)
            }
            
            NavigationLink(destination: DailyStoriesView()) {
                quickActionButton(icon: "calendar", title: "Günlük", color: .orange)
            }
            
            NavigationLink(destination: LibraryView()) {
                quickActionButton(icon: "books.vertical.fill", title: "Kütüphane", color: .green)
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Daily Stories Feed (Instagram Style)
    
    private var dailyStoriesFeed: some View {
        LazyVStack(spacing: 16) {
            ForEach(dailyStoryManager.dailyStories) { story in
                dailyStoryCard(story)
            }
            
            // Boş durum
            if dailyStoryManager.dailyStories.isEmpty {
                emptyFeedView
                    .padding(.top, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
    
    private func dailyStoryCard(_ story: DailyStory) -> some View {
        Button(action: {
            selectedDailyStory = story
            showingDailyStoryReader = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header - Kategori bilgisi
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(story.category.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(story.category.emoji)
                            .font(.system(size: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(story.category.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text("\(story.readingTime) dakika • \(story.ageRange) yaş")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if story.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                .padding(16)
                
                // Hikaye içeriği
                VStack(alignment: .leading, spacing: 12) {
                    Text(story.title)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(story.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Footer - Aksiyon butonları
                HStack(spacing: 20) {
                    Label("Oku", systemImage: "book.fill")
                        .font(.caption.bold())
                        .foregroundColor(story.category.color)
                    
                    Spacer()
                    
                    if !story.isRead {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("Yeni")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Text("📚")
                    .font(.system(size: 50))
            }
            
            VStack(spacing: 8) {
                Text("Henüz Günlük Hikaye Yok")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Günlük hikayeler yakında eklenecek!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    

    

}

#Preview {
    HomeView()
}
