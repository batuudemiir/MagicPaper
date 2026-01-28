import SwiftUI

struct CreateTextStoryView: View {
    @StateObject private var textStoryManager = TextStoryManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var adManager = AdMobManager.shared
    
    @State private var childName = ""
    @State private var selectedGender = Gender.other
    @State private var selectedTheme = StoryTheme.fantasy
    @State private var selectedLanguage = StoryLanguage.turkish
    @State private var customTitle = ""
    
    @State private var isGenerating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Bilgi"
    @State private var showingPremiumSheet = false
    @State private var generatedStory: TextStory?
    @State private var showingStoryViewer = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Basic Info
                        basicInfoSection
                        
                        // Theme Selection
                        themeSection
                        
                        // Language Selection
                        languageSection
                        
                        // Generate Button
                        generateButton
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 20, 40))
                    .frame(minHeight: geometry.size.height)
                }
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85),
                                Color(red: 1.0, green: 0.45, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.08)
                        
                        Color.white.opacity(0.92)
                    }
                    .ignoresSafeArea()
                )
            }
            .navigationTitle("Metin Hikaye")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Tamam") {
                if generatedStory != nil {
                    showingStoryViewer = true
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showingStoryViewer) {
            if let story = generatedStory {
                TextStoryViewerView(story: story)
            }
        }
        .overlay(
            loadingOverlay
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
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
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.4), radius: 12, x: 0, y: 6)
                
                Text("📖")
                    .font(.system(size: 44))
            }
            
            VStack(spacing: 6) {
                Text("Metin Hikaye Oluştur")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Görsel olmadan, sadece metin hikaye")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Karakter Bilgileri")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 16) {
                // İsim
                VStack(alignment: .leading, spacing: 8) {
                    Text("Çocuğun İsmi")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Örn: Ayşe, Mehmet", text: $childName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Cinsiyet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cinsiyet")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedGender = gender
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: gender.icon)
                                        .font(.system(size: 18))
                                    Text(gender.displayName)
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(selectedGender == gender ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedGender == gender ?
                                              LinearGradient(
                                                colors: [
                                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              ) :
                                              LinearGradient(
                                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Hikaye Teması")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            
            Text("Maceranın türünü seçin")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Ücretsiz Temalar
            VStack(alignment: .leading, spacing: 12) {
                Text("Ücretsiz Temalar")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(StoryTheme.freeThemes, id: \.self) { theme in
                        themeCard(theme: theme)
                    }
                }
            }
            
            // Premium Temalar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Premium Temalar")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("👑")
                        .font(.caption)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(StoryTheme.premiumThemes, id: \.self) { theme in
                        themeCard(theme: theme)
                    }
                }
            }
            
            if selectedTheme == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Özel Hikaye Konusu")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Örn: Dinozorlarla macera", text: $customTitle)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func themeCard(theme: StoryTheme) -> some View {
        Button(action: {
            if theme.isPremium && !subscriptionManager.isPremium {
                showingPremiumSheet = true
                return
            }
            
            withAnimation(.spring(response: 0.3)) {
                selectedTheme = theme
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Text(theme.emoji)
                        .font(.system(size: 40))
                    
                    Text(theme.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(selectedTheme == theme ? .white : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedTheme == theme ? theme.color : Color(.systemGray6))
                        .shadow(color: selectedTheme == theme ? theme.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.isPremium && !subscriptionManager.isPremium ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                
                if theme.isPremium && !subscriptionManager.isPremium {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Text("👑")
                            .font(.system(size: 14))
                    }
                    .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(theme.isPremium && !subscriptionManager.isPremium ? 0.7 : 1.0)
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Hikaye Dili")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            
            Text("Hikayenin hangi dilde yazılmasını istersiniz?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StoryLanguage.allCases, id: \.self) { language in
                        languageButton(language: language)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func languageButton(language: StoryLanguage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedLanguage = language
            }
        }) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 32))
                
                Text(language.displayName)
                    .font(.caption.bold())
                    .foregroundColor(selectedLanguage == language ? .white : .primary)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedLanguage == language ?
                          LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .shadow(color: selectedLanguage == language ? Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        VStack(spacing: 16) {
            Button(action: generateStory) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "pencil.and.list.clipboard")
                    }
                    
                    Text(isGenerating ? "Hikaye Yazılıyor..." : "Hikaye Oluştur")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if isGenerating {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.58, green: 0.29, blue: 0.98),
                                            Color(red: 0.85, green: 0.35, blue: 0.85),
                                            Color(red: 1.0, green: 0.45, blue: 0.55)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                )
            }
            .disabled(isGenerating || !isFormValid)
            
            if !isFormValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Lütfen çocuğun ismini girin")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Group {
            if isGenerating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Hikaye yazılıyor...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Bu işlem 30-60 saniye sürebilir")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                    )
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        !childName.isEmpty
    }
    
    private func generateStory() {
        guard isFormValid else {
            alertTitle = "⚠️ Eksik Bilgi"
            alertMessage = "Lütfen çocuğun ismini girin."
            showingAlert = true
            return
        }
        
        if selectedTheme.isPremium && !subscriptionManager.isPremium {
            alertTitle = "👑 Premium Tema"
            alertMessage = "\(selectedTheme.displayName) teması premium üyelere özeldir."
            showingAlert = true
            showingPremiumSheet = true
            return
        }
        
        isGenerating = true
        
        Task {
            let story = await textStoryManager.createTextStory(
                childName: childName,
                gender: selectedGender,
                theme: selectedTheme,
                language: selectedLanguage,
                customTitle: selectedTheme == .custom ? customTitle : nil
            )
            
            await MainActor.run {
                isGenerating = false
                
                if let story = story {
                    generatedStory = story
                    
                    // Ücretsiz kullanıcılara reklam göster
                    if !subscriptionManager.isPremium {
                        adManager.showInterstitialAd()
                    }
                    
                    alertTitle = "✨ Hikaye Hazır!"
                    alertMessage = "Hikayeniz başarıyla oluşturuldu. Okumak için Tamam'a tıklayın."
                    showingAlert = true
                    
                    // Formu temizle
                    childName = ""
                    customTitle = ""
                } else {
                    alertTitle = "❌ Hata"
                    alertMessage = "Hikaye oluşturulurken bir hata oluştu. Lütfen tekrar deneyin."
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    CreateTextStoryView()
}
