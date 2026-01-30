import SwiftUI

struct DailyStoriesView: View {
    @StateObject private var storyManager = DailyStoryManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedCategory: DailyStoryCategory? = nil
    @State private var selectedStory: DailyStory? = nil
    @State private var showingStoryReader = false
    @State private var showingCreateStory = false
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
        .sheet(isPresented: $showingStoryReader) {
            if let story = selectedStory {
                DailyStoryReaderView(story: story)
            }
        }
        .sheet(isPresented: $showingCreateStory) {
            if let category = selectedCategoryForCreation {
                DailyStoryCreationView(category: category)
            }
        }
        .sheet(isPresented: $showingPremiumSheet) {
            SimpleSubscriptionView()
        }
        .alert("Abonelik Gerekli", isPresented: $showingLimitAlert) {
            Button("Tamam", role: .cancel) { }
            Button("Abone Ol") {
                showingPremiumSheet = true
            }
        } message: {
            if subscriptionManager.freeTrialCount > 0 {
                Text("Ücretsiz deneme hakkınız bitti. Sınırsız hikaye için abone olun!")
            } else {
                Text("Günlük hikaye oluşturmak için abonelik gerekiyor. Günde 3₺ ile sınırsız hikaye!")
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
                    Text("Abonelik Gerekli")
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
                        Text("Abone Ol")
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
                showingCreateStory = true
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
                showingStoryReader = true
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
            showingStoryReader = true
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
    @StateObject private var storyManager = DailyStoryManager.shared
    let story: DailyStory
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(story.emoji)
                            .font(.system(size: 60))
                        
                        Text(story.title)
                            .font(.title.bold())
                            .foregroundColor(.black)
                        
                        HStack(spacing: 16) {
                            Label(story.category.displayName, systemImage: "tag.fill")
                            Label("\(story.readingTime) dakika", systemImage: "clock.fill")
                            Label(story.ageRange + " yaş", systemImage: "person.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Hikaye içeriği
                    Text(story.content)
                        .font(.body)
                        .lineSpacing(8)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                    
                    // Öğreti
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("Hikayenin Öğretisi")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        Text(story.moralLesson)
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .italic()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                }
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
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        // Hikayeyi okundu olarak işaretle
                        storyManager.markAsRead(storyId: story.id)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DailyStoriesView()
    }
}
