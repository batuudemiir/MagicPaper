import SwiftUI

struct TextOnlyStoryView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var aiService = AIService.shared
    
    @State private var childName = ""
    @State private var selectedGender = Gender.other
    @State private var selectedTheme = StoryTheme.fantasy
    @AppStorage("defaultLanguage") private var defaultLanguageRaw = "tr"
    @State private var selectedLanguage = StoryLanguage.turkish
    @State private var customTitle = ""
    
    @State private var isGenerating = false
    @State private var generationProgress = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Bilgi"
    @State private var showingPremiumSheet = false
    @State private var generatedStory: TextOnlyStory?
    @State private var showingStoryViewer = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        headerSection
                        basicInfoSection
                        themeSection
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
                                Color(red: 0.2, green: 0.6, blue: 0.86),
                                Color(red: 0.4, green: 0.8, blue: 0.6),
                                Color(red: 0.95, green: 0.77, blue: 0.06)
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
        .onAppear {
            // Varsayılan dili yükle
            selectedLanguage = StoryLanguage(rawValue: defaultLanguageRaw) ?? .turkish
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            SimpleSubscriptionView()
        }
        .sheet(isPresented: $showingStoryViewer) {
            if let story = generatedStory {
                TextOnlyStoryViewerView(story: story)
            }
        }
        .overlay(
            loadingOverlay
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.86),
                                Color(red: 0.4, green: 0.8, blue: 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.86).opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text("📖")
                    .font(.system(size: 50))
            }
            
            VStack(spacing: 8) {
                Text("Hızlı Hikaye Oluştur")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Görselsiz, sadece metin tabanlı hikaye")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
            Text("Temel Bilgiler")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // İsim
                VStack(alignment: .leading, spacing: 8) {
                    Text("Çocuğun İsmi")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("İsim girin", text: $childName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Cinsiyet - Modern Segmented Control
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
                                                    Color(red: 0.2, green: 0.6, blue: 0.86),
                                                    Color(red: 0.4, green: 0.8, blue: 0.6)
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
            Text("Hikaye Teması")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
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
    
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        VStack(spacing: 16) {
            // Ücretsiz kullanıcı için 12 saatlik bilgi
            if !subscriptionManager.isPremium && subscriptionManager.freeTrialCount == 0 {
                freeStoryInfoBanner
            }
            
            Button(action: generateStory) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "text.book.closed")
                    }
                    
                    Text(isGenerating ? generationProgress : "Hikaye Oluştur")
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
                                            Color(red: 0.2, green: 0.6, blue: 0.86),
                                            Color(red: 0.4, green: 0.8, blue: 0.6),
                                            Color(red: 0.95, green: 0.77, blue: 0.06)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.86).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                )
            }
            .disabled(isGenerating || !isFormValid)
            .scaleEffect(isGenerating ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isGenerating)
            
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
    
    private var creditCostBanner: some View {
        EmptyView()
    }
    
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
                            
                            Text(generationProgress)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
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
    
    private var isFormValid: Bool {
        !childName.isEmpty
    }
    
    // MARK: - Free Story Info Banner
    
    private var freeStoryInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: subscriptionManager.canCreateFreeTextStory ? "checkmark.circle.fill" : "clock.fill")
                .font(.title2)
                .foregroundColor(subscriptionManager.canCreateFreeTextStory ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 4) {
                if subscriptionManager.canCreateFreeTextStory {
                    Text("Ücretsiz Hikaye Hazır!")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                    Text("12 saatte 1 ücretsiz metin hikaye hakkınız var")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(subscriptionManager.hoursUntilNextFreeStory) saat sonra")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                    Text("Sınırsız hikaye için kulübe katıl - Günde 3₺")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !subscriptionManager.canCreateFreeTextStory {
                Button(action: {
                    showingPremiumSheet = true
                }) {
                    Text("Kulübe Katıl")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(subscriptionManager.canCreateFreeTextStory ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(subscriptionManager.canCreateFreeTextStory ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Generate Story
    
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
        
        if !subscriptionManager.canCreateStory(type: .text) {
            if subscriptionManager.freeTrialCount > 0 {
                alertTitle = "🎁 Ücretsiz Deneme"
                alertMessage = "\(subscriptionManager.freeTrialCount) ücretsiz deneme hakkınız kaldı!"
            } else if subscriptionManager.canCreateFreeTextStory {
                alertTitle = "✨ Ücretsiz Hikaye"
                alertMessage = "12 saatte 1 ücretsiz metin hikaye hakkınız var!"
            } else {
                alertTitle = "⏰ Bekleme Süresi"
                alertMessage = "Bir sonraki ücretsiz hikaye için \(subscriptionManager.hoursUntilNextFreeStory) saat beklemeniz gerekiyor.\n\nSınırsız hikaye için günde 3₺ ile kulübe katıl!"
                showingAlert = true
                showingPremiumSheet = true
                return
            }
        }
        
        // Hikaye kullanımını kaydet
        guard subscriptionManager.useStory(type: .text) else {
            alertTitle = "❌ Hata"
            alertMessage = "Hikaye oluşturma işlemi başarısız oldu."
            showingAlert = true
            return
        }
        
        isGenerating = true
        generationProgress = "Hikaye yazılıyor..."
        
        Task {
            do {
                let storyResponse = try await aiService.generateTextOnlyStory(
                    childName: childName,
                    gender: selectedGender,
                    theme: selectedTheme.rawValue,
                    language: selectedLanguage.rawValue,
                    customTitle: selectedTheme == .custom ? customTitle : nil
                )
                
                await MainActor.run {
                    let story = TextOnlyStory(
                        title: storyResponse.title,
                        childName: childName,
                        gender: selectedGender,
                        theme: selectedTheme,
                        language: selectedLanguage,
                        pages: storyResponse.pages.map { page in
                            TextOnlyStoryPage(
                                title: page.title,
                                text: page.text
                            )
                        }
                    )
                    
                    self.generatedStory = story
                    self.isGenerating = false
                    self.generationProgress = ""
                    
                    // Hikayeyi göster
                    self.showingStoryViewer = true
                    
                    // Formu temizle
                    self.childName = ""
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.generationProgress = ""
                    self.alertTitle = "❌ Hata"
                    self.alertMessage = "Hikaye oluşturulurken bir hata oluştu. Lütfen tekrar deneyin."
                    self.showingAlert = true
                }
            }
        }
    }
}

#Preview {
    TextOnlyStoryView()
}
