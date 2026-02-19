import SwiftUI

struct DailyStoriesView: View {
    @StateObject private var storyManager = DailyStoryManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedCategory: DailyStoryCategory? = nil
    @State private var selectedStory: DailyStory? = nil
    @State private var selectedCategoryForCreation: DailyStoryCategory? = nil
    @State private var showingLimitAlert = false
    @State private var showingPremiumSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Günlük Kota Bilgisi
                dailyQuotaSection
                    .padding(.horizontal, 20)
                
                // Günün Hikayesi
                if let todaysStory = storyManager.todaysStory {
                    todaysStorySection(todaysStory)
                        .padding(.horizontal, 20)
                }
                
                // Kendi Hikayeni Oluştur Bölümü
                createYourOwnSection
                    .padding(.horizontal, 20)
                
                // Kategoriler
                categoriesSection
                    .padding(.horizontal, 20)
                
                // Hikayeler
                storiesSection
                    .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                // İkon renklerine uygun gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.29, blue: 0.98), // Mor
                        Color(red: 0.85, green: 0.35, blue: 0.85), // Pembe
                        Color(red: 1.0, green: 0.45, blue: 0.55)   // Kırmızı-pembe
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.08)
                
                // Beyaz overlay
                Color.white.opacity(0.92)
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Günlük Hikayeler")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.light)
        .fullScreenCover(item: $selectedStory) { story in
            DailyStoryReaderView(story: story)
                .ignoresSafeArea(.all, edges: .all)
        }
        .sheet(item: $selectedCategoryForCreation) { category in
            DailyStoryCreationView(category: category)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            SimpleSubscriptionView()
        }
        .alert("Hikaye Kulübü Gerekli", isPresented: $showingLimitAlert) {
            Button("Tamam", role: .cancel) { }
            Button("Kulübe Katıl") {
                showingPremiumSheet = true
            }
        } message: {
            if subscriptionManager.freeTrialCount > 0 {
                Text("Ücretsiz deneme hakkınız bitti. Sınırsız hikaye için kulübe katıl!")
            } else {
                Text("Günlük hikaye oluşturmak için kulüp üyeliği gerekiyor. Günde 3₺ ile sınırsız hikaye!")
            }
        }
    }
    
    // MARK: - Günlük Kota Section
    
    private var dailyQuotaSection: some View {
        HStack(spacing: 12) {
            Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "gift.fill")
                .font(.title2)
                .foregroundColor(subscriptionManager.isPremium ? .yellow : .green)
            
            VStack(alignment: .leading, spacing: 4) {
                if subscriptionManager.isPremium {
                    Text("Premium Üye")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Sınırsız günlük hikaye oluşturabilirsiniz")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                } else if subscriptionManager.freeTrialCount > 0 {
                    Text("Ücretsiz Deneme")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("\(subscriptionManager.freeTrialCount) hikaye hakkınız kaldı")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Kulüp Üyeliği Gerekli")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("☕️ Kahveden ucuz - Günde 3₺")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if !subscriptionManager.isPremium {
                Button(action: {
                    showingPremiumSheet = true
                }) {
                    HStack(spacing: 4) {
                        Text("✨")
                            .font(.caption)
                        Text("Kulübe Katıl")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98), // Mor
                                Color(red: 0.85, green: 0.35, blue: 0.85)  // Pembe
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Kendi Hikayeni Oluştur Section
    
    private var createYourOwnSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Çocuğunuza Özel Hikaye Oluşturun ✨")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    Text("Kategoriye göre çocuğunuza özel metin hikayeler oluşturun")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DailyStoryCategory.allCases, id: \.self) { category in
                        createCategoryCard(category)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private func createCategoryCard(_ category: DailyStoryCategory) -> some View {
        Button(action: {
            if subscriptionManager.canCreateStory(type: .daily) {
                selectedCategoryForCreation = category
            } else {
                showingLimitAlert = true
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.6), category.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(category.emoji)
                        .font(.system(size: 36))
                }
                
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                    
                    Text(category.description)
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("Oluştur")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(category.color)
                .cornerRadius(8)
            }
            .frame(width: 140)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(category.color.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: category.color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Günün Hikayesi
    
    private func todaysStorySection(_ story: DailyStory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Günün Hikayesi")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("🌟")
                    .font(.title)
            }
            
            Button(action: {
                selectedStory = story
            }) {
                ZStack(alignment: .topLeading) {
                    // Arka plan gradient
                    LinearGradient(
                        colors: [
                            story.category.color.opacity(0.7),
                            story.category.color
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 180)
                    .cornerRadius(20)
                    
                    // İçerik
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(story.category.emoji)
                                .font(.system(size: 40))
                            
                            Spacer()
                            
                            if story.isRead {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Okundu")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(story.title)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                Label("\(story.readingTime) dk", systemImage: "clock.fill")
                                Label(story.ageRange + " yaş", systemImage: "person.fill")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(20)
                }
                .shadow(color: story.category.color.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Kategoriler
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategoriler")
                .font(.headline)
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Tümü butonu
                    categoryButton(category: nil, title: "Tümü", emoji: "📚")
                    
                    // Kategori butonları
                    ForEach(DailyStoryCategory.allCases, id: \.self) { category in
                        categoryButton(
                            category: category,
                            title: category.displayName,
                            emoji: category.emoji
                        )
                    }
                }
            }
        }
    }
    
    private func categoryButton(category: DailyStoryCategory?, title: String, emoji: String) -> some View {
        Button(action: {
            selectedCategory = category
        }) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.title3)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(selectedCategory == category ? .white : .black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedCategory == category ?
                          (category?.color ?? Color.indigo) :
                          Color.white)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Hikayeler Listesi
    
    private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedCategory?.displayName ?? "Tüm Hikayeler")
                .font(.headline)
                .foregroundColor(.black)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredStories) { story in
                    storyCard(story)
                }
            }
        }
    }
    
    private var filteredStories: [DailyStory] {
        if let category = selectedCategory {
            return storyManager.dailyStories.filter { $0.category == category }
        }
        return storyManager.dailyStories
    }
    
    private func storyCard(_ story: DailyStory) -> some View {
        Button(action: {
            selectedStory = story
        }) {
            HStack(spacing: 16) {
                // Emoji icon
                ZStack {
                    Circle()
                        .fill(story.category.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Text(story.emoji)
                        .font(.system(size: 30))
                }
                
                // İçerik
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(story.category.displayName)
                            .font(.caption)
                            .foregroundColor(story.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(story.category.color.opacity(0.15))
                            .cornerRadius(6)
                        
                        Text("\(story.readingTime) dk")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        
                        Text(story.ageRange + " yaş")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }
                
                Spacer()
                
                // Okundu işareti
                if story.isRead {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Story Reader View

struct DailyStoryReaderView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    @StateObject private var storyManager = DailyStoryManager.shared
    let story: DailyStory
    
    // Reading preferences - same as StoryViewerView
    @AppStorage("storyTextSize") private var textSize: TextSize = .normal
    @AppStorage("storyReadingTheme") private var readingTheme: ReadingTheme = .light
    @AppStorage("storyLineSpacing") private var lineSpacing: LineSpacingOption = .normal
    @State private var showingReadingSettings = false
    
    // High contrast mode
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    storyContentView
                        .padding(.bottom, DeviceHelper.isIPad ? 60 : 40)
                }
            }
            .background(readingTheme.backgroundColor(highContrast: isHighContrast))
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingReadingSettings) {
            ReadingSettingsView(
                textSize: $textSize,
                readingTheme: $readingTheme,
                lineSpacing: $lineSpacing,
                autoPlayEnabled: .constant(false)
            )
        }
        .onAppear {
            print("📖 DailyStoryReaderView appeared")
            print("   Title: \(story.title)")
            print("   Content length: \(story.content.count)")
            print("   Emoji: \(story.emoji)")
            print("   Category: \(story.category.displayName)")
        }
        .onDisappear {
            // Hikayeyi okundu olarak işaretle
            storyManager.markAsRead(storyId: story.id)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        let titleFontSize: CGFloat = DeviceHelper.isIPad ? 24 : 17
        let buttonFontSize: CGFloat = DeviceHelper.isIPad ? 20 : 17
        let iconSize: CGFloat = DeviceHelper.isIPad ? 28 : 20
        let padding: CGFloat = DeviceHelper.isIPad ? 24 : 16
        
        return VStack(spacing: 0) {
            HStack {
                Button("Kapat") {
                    dismiss()
                }
                .font(.system(size: buttonFontSize))
                .foregroundColor(readingTheme.textColor(highContrast: isHighContrast))
                
                Spacer()
                
                VStack(spacing: DeviceHelper.isIPad ? 6 : 4) {
                    Text(story.title)
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .foregroundColor(readingTheme.textColor(highContrast: isHighContrast))
                        .lineLimit(1)
                    
                    Text("\(story.readingTime) dk • \(story.ageRange) yaş")
                        .font(.system(size: DeviceHelper.isIPad ? 16 : 12))
                        .foregroundColor(readingTheme.textColor(highContrast: isHighContrast).opacity(0.7))
                }
                
                Spacer()
                
                // Reading settings button
                Button(action: {
                    showingReadingSettings = true
                }) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: iconSize))
                        .foregroundColor(readingTheme.textColor(highContrast: isHighContrast))
                }
            }
            .padding(padding)
            .background(readingTheme.backgroundColor(highContrast: isHighContrast))
            
            Divider()
                .opacity(isHighContrast ? 0.5 : 0.2)
        }
        .shadow(color: .black.opacity(readingTheme.shadowOpacity(highContrast: isHighContrast)), radius: DeviceHelper.isIPad ? 2 : 1)
    }
    
    // MARK: - Story Content View
    
    private var storyContentView: some View {
        let baseTitleFontSize: CGFloat = DeviceHelper.isIPad ? 36 : 26
        let baseBodyFontSize: CGFloat = DeviceHelper.isIPad ? 22 : 18
        let cornerRadius: CGFloat = DeviceHelper.isIPad ? 24 : 16
        let spacing: CGFloat = DeviceHelper.isIPad ? 32 : 24
        let padding: CGFloat = DeviceHelper.isIPad ? 40 : 24
        
        // Apply text size multiplier
        let titleFontSize = baseTitleFontSize * textSize.multiplier
        let bodyFontSize = baseBodyFontSize * textSize.multiplier
        let currentLineSpacing = lineSpacing.spacing * textSize.multiplier
        
        let backgroundColor = readingTheme.backgroundColor(highContrast: isHighContrast)
        let textColor = readingTheme.textColor(highContrast: isHighContrast)
        let shadowOpacity = readingTheme.shadowOpacity(highContrast: isHighContrast)
        
        return VStack(spacing: spacing) {
            // Emoji and Category Badge
            VStack(spacing: DeviceHelper.isIPad ? 20 : 16) {
                if !story.emoji.isEmpty {
                    Text(story.emoji)
                        .font(.system(size: DeviceHelper.isIPad ? 80 : 60))
                }
                
                // Category badge
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 14 : 12))
                    Text(story.category.displayName)
                        .font(.system(size: DeviceHelper.isIPad ? 16 : 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, DeviceHelper.isIPad ? 20 : 16)
                .padding(.vertical, DeviceHelper.isIPad ? 12 : 10)
                .background(
                    Capsule()
                        .fill(story.category.color)
                )
                .shadow(color: story.category.color.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, padding)
            
            // Story Title
            Text(story.title)
                .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                .foregroundColor(isHighContrast ? textColor : story.category.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, padding)
            
            // Story Content
            VStack(spacing: DeviceHelper.isIPad ? 24 : 20) {
                Text(story.content)
                    .font(.system(size: bodyFontSize, weight: .regular))
                    .lineSpacing(currentLineSpacing)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .padding(padding)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(isHighContrast ? textColor.opacity(0.3) : Color.clear, lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(shadowOpacity), radius: DeviceHelper.isIPad ? 12 : 8, x: 0, y: DeviceHelper.isIPad ? 6 : 4)
            }
            .padding(.horizontal, DeviceHelper.isIPad ? 32 : 20)
            
            // Moral Lesson
            VStack(alignment: .leading, spacing: DeviceHelper.isIPad ? 16 : 12) {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 24 : 20))
                        .foregroundColor(.orange)
                    Text("Hikayenin Öğretisi")
                        .font(.system(size: DeviceHelper.isIPad ? 22 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                }
                
                Text(story.moralLesson)
                    .font(.system(size: (DeviceHelper.isIPad ? 18 : 15) * textSize.multiplier, weight: .regular))
                    .lineSpacing(currentLineSpacing * 0.8)
                    .foregroundColor(textColor.opacity(0.85))
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(isHighContrast ? 0.2 : 0.1),
                                Color.yellow.opacity(isHighContrast ? 0.15 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.orange.opacity(isHighContrast ? 0.4 : 0.2), lineWidth: isHighContrast ? 2 : 1)
                    )
            )
            .shadow(color: Color.orange.opacity(shadowOpacity * 2), radius: DeviceHelper.isIPad ? 12 : 8, x: 0, y: DeviceHelper.isIPad ? 6 : 4)
            .padding(.horizontal, DeviceHelper.isIPad ? 32 : 20)
        }
    }
}

#Preview {
    NavigationView {
        DailyStoriesView()
    }
}
