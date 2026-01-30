import SwiftUI

struct SettingsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var selectedLanguage = StoryLanguage.turkish
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var highQualityImages = true
    @State private var showingUpgradeSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingAboutSheet = false
    @State private var showingProfileEdit = false
    @AppStorage("defaultTheme") private var defaultTheme = "fantasy"
    @AppStorage("defaultAgeRange") private var defaultAgeRange = 6
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profil Bölümü
                    profileSection
                    
                    // Premium Bölümü
                    if !subscriptionManager.isPremium {
                        premiumSection
                    }
                    
                    // Hikaye Ayarları
                    storySettingsSection
                    
                    // Uygulama Ayarları
                    appSettingsSection
                    
                    // Hızlı İşlemler
                    quickActionsSection
                    
                    // Hakkında ve Destek
                    aboutSection
                    
                    // Tehlike Bölgesi
                    dangerZoneSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 1.0),
                        Color(red: 0.95, green: 0.96, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileSetupView(isEditing: true)
        }
        .alert("Tüm Verileri Temizle", isPresented: $showingClearDataAlert) {
            Button("İptal", role: .cancel) { }
            Button("Verileri Temizle", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Bu işlem tüm hikayelerinizi ve ayarlarınızı silecektir. Bu işlem geri alınamaz.")
        }
    }
    
    private var profileSection: some View {
        Button(action: {
            showingProfileEdit = true
        }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    if let profileImage = profileManager.getProfileImage() {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.58, green: 0.29, blue: 0.98),
                                        Color(red: 0.85, green: 0.35, blue: 0.85),
                                        Color(red: 1.0, green: 0.45, blue: 0.55)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Text(profileManager.profile.name.isEmpty ? "👤" : String(profileManager.profile.name.prefix(1)).uppercased())
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(profileManager.profile.name.isEmpty ? "Profil Oluştur" : profileManager.profile.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        if subscriptionManager.isPremium {
                            HStack(spacing: 4) {
                                Text("👑")
                                    .font(.caption)
                                Text("Premium Üye")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        } else {
                            Text("Ücretsiz Hesap")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(StoryGenerationManager.shared.stories.count) Hikaye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }
    
    private var premiumSection: some View {
        Button(action: {
            showingUpgradeSheet = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Text("👑")
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Premium'a Yükselt")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Text("Sınırsız hikaye ve özel temalar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color.orange)
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .orange.opacity(0.15), radius: 16, x: 0, y: 4)
        )
    }
    
    private var storySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hikaye Ayarları")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Varsayılan Dil
                HStack {
                    settingIcon("globe", color: .blue)
                    Text("Varsayılan Dil")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $selectedLanguage) {
                        Text("🇹🇷 Türkçe").tag(StoryLanguage.turkish)
                        Text("🇬🇧 English").tag(StoryLanguage.english)
                    }
                    .pickerStyle(.menu)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Varsayılan Yaş Aralığı
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        settingIcon("person.fill", color: .green)
                        Text("Varsayılan Yaş")
                            .font(.subheadline)
                        Spacer()
                        Text("\(defaultAgeRange) yaş")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(defaultAgeRange) },
                        set: { defaultAgeRange = Int($0) }
                    ), in: 3...12, step: 1)
                    .tint(.green)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Görsel Kalitesi
                HStack {
                    settingIcon("photo.fill", color: .purple)
                    Text("Yüksek Kalite Görseller")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $highQualityImages)
                        .tint(.purple)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            )
        }
    }
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Uygulama Ayarları")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    settingIcon("bell.fill", color: .orange)
                    Text("Bildirimler")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(.orange)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    settingIcon("square.and.arrow.down.fill", color: .cyan)
                    Text("Otomatik Kaydet")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $autoSaveEnabled)
                        .tint(.cyan)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            )
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı İşlemler")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                NavigationLink(destination: CreateStoryView()) {
                    HStack {
                        settingIcon("plus.circle.fill", color: .indigo)
                        Text("Yeni Hikaye Oluştur")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                NavigationLink(destination: LibraryView()) {
                    HStack {
                        settingIcon("books.vertical.fill", color: .green)
                        Text("Hikaye Kütüphanem")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(StoryGenerationManager.shared.stories.count)")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: shareApp) {
                    HStack {
                        settingIcon("square.and.arrow.up.fill", color: .blue)
                        Text("Uygulamayı Paylaş")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hakkında ve Destek")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button(action: { showingAboutSheet = true }) {
                    HStack {
                        settingIcon("info.circle.fill", color: .blue)
                        Text("Uygulama Hakkında")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: rateApp) {
                    HStack {
                        settingIcon("star.fill", color: .yellow)
                        Text("Uygulamayı Değerlendir")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: contactSupport) {
                    HStack {
                        settingIcon("envelope.fill", color: .cyan)
                        Text("Destek İletişim")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: openPrivacyPolicy) {
                    HStack {
                        settingIcon("shield.checkered", color: .green)
                        Text("Gizlilik Politikası")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: openTermsOfService) {
                    HStack {
                        settingIcon("doc.text.fill", color: .gray)
                        Text("Kullanım Şartları")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            )
        }
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tehlike Bölgesi")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Test butonu - Premium durumunu değiştir
                Button(action: {
                    if subscriptionManager.isPremium {
                        subscriptionManager.downgradeToPremium()
                    } else {
                        subscriptionManager.upgradeToPremium()
                    }
                }) {
                    HStack {
                        settingIcon("crown.fill", color: .orange)
                        Text(subscriptionManager.isPremium ? "🧪 Premium'u Kaldır (Test)" : "🧪 Premium Yap (Test)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: {
                    showingClearDataAlert = true
                }) {
                    HStack {
                        settingIcon("trash.fill", color: .red)
                        Text("Tüm Verileri Temizle")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .red.opacity(0.1), radius: 16, x: 0, y: 4)
            )
        }
    }
    
    private func settingIcon(_ systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: systemName)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    private func shareApp() {
        let text = "MagicPaper ile çocuğunuz için kişiselleştirilmiş hikayeler oluşturun! 📚✨"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:destek@magicpaper.app?subject=MagicPaper Destek") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        // Geçici olarak GitHub veya başka bir hosting'de yayınlanabilir
        // Production'da: https://magicpaper.app/gizlilik
        if let url = URL(string: "https://magicpaper.app/gizlilik") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        // Geçici olarak GitHub veya başka bir hosting'de yayınlanabilir
        // Production'da: https://magicpaper.app/kullanim-sartlari
        if let url = URL(string: "https://magicpaper.app/kullanim-sartlari") {
            UIApplication.shared.open(url)
        }
    }
    
    private func clearAllData() {
        let manager = StoryGenerationManager.shared
        for story in manager.stories {
            manager.deleteStory(id: story.id)
        }
        
        selectedLanguage = .turkish
        notificationsEnabled = true
        autoSaveEnabled = true
        highQualityImages = true
        defaultAgeRange = 6
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo ve Başlık
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.58, green: 0.29, blue: 0.98),
                                            Color(red: 0.85, green: 0.35, blue: 0.85),
                                            Color(red: 1.0, green: 0.45, blue: 0.55)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("MagicPaper")
                                .font(.title.bold())
                            
                            Text("Versiyon 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Açıklama
                    VStack(spacing: 12) {
                        Text("Sihirli Hikayeler")
                            .font(.headline)
                        
                        Text("MagicPaper, çocuğunuz için kişiselleştirilmiş hikayeler oluşturmanıza yardımcı olur. Her hikaye, çocuğunuzun fotoğrafı ve seçtiğiniz tema ile özel olarak hazırlanır.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Özellikler
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "photo.fill", color: .blue, title: "Kişiselleştirilmiş", description: "Çocuğunuzun fotoğrafı ile")
                        featureRow(icon: "paintbrush.fill", color: .purple, title: "Çeşitli Temalar", description: "Macera, uzay, orman ve daha fazlası")
                        featureRow(icon: "book.pages.fill", color: .green, title: "Yaş Uygun", description: "3-12 yaş arası içerik")
                        featureRow(icon: "sparkles", color: .orange, title: "Sihirli Görseller", description: "Her sayfa için özel illüstrasyonlar")
                    }
                    .padding(.horizontal)
                    
                    // İletişim
                    VStack(spacing: 16) {
                        Text("İletişim")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            contactButton(icon: "envelope.fill", text: "destek@magicpaper.app", color: .blue)
                            contactButton(icon: "globe", text: "magicpaper.app", color: .indigo)
                        }
                    }
                    
                    // Footer
                    Text("❤️ ile yapıldı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("Hakkında")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func contactButton(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .yearly
    @State private var showingLimitedOffer = true
    @State private var pulseAnimation = false
    @State private var floatAnimation = false
    
    enum PremiumPlan {
        case monthly, yearly
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section - Duygusal Bağ
                    heroSection
                    
                    // Social Proof Badge
                    socialProofBadge
                    
                    // Değer Karşılaştırması
                    valueComparisonSection
                    
                    // Premium Özellikler - Duygusal Faydalar
                    emotionalBenefitsSection
                    
                    // Fiyatlandırma
                    pricingSection
                    
                    // Testimonials
                    testimonialsSection
                    
                    // Garanti
                    guaranteeSection
                    
                    // CTA
                    ctaSection
                }
                .padding(.bottom, 40)
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.08),
                            Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.05),
                            Color(red: 1.0, green: 0.45, blue: 0.55).opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Color.white.opacity(0.97)
                }
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.title3)
                    }
                }
            }
            .overlay(
                limitedOfferPopup
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                floatAnimation = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                // Outer glow with pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98).opacity(pulseAnimation ? 0.4 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                
                // Main circle with float animation
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85),
                                Color(red: 1.0, green: 0.45, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.6), radius: 30, x: 0, y: 15)
                    .offset(y: floatAnimation ? -5 : 5)
                
                Text("👑")
                    .font(.system(size: 64))
                    .offset(y: floatAnimation ? -5 : 5)
            }
            .padding(.top, 16)
            
            VStack(spacing: 12) {
                // Main headline - More compact
                VStack(spacing: 4) {
                    Text("Çocuğunuzun")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    HStack(spacing: 6) {
                        Text("Hayal Gücü")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.58, green: 0.29, blue: 0.98),
                                        Color(red: 0.85, green: 0.35, blue: 0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("✨")
                            .font(.system(size: 28))
                    }
                    
                    Text("Sınırsız Olsun")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.35, blue: 0.85),
                                    Color(red: 1.0, green: 0.45, blue: 0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .multilineTextAlignment(.center)
                
                // Subheadline - Simplified
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Her gece")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("benzersiz")
                            .font(.body.bold())
                            .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                        Text("bir hikaye")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Çocuğunuz kahramanı olsun 🦸‍♂️")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Social Proof Badge
    
    private var socialProofBadge: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            Text("•")
                .foregroundColor(.secondary)
            
            Text("10,000+ mutlu aile")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            Text("•")
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("4.9")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Limited Time Offer Popup
    
    private var limitedOfferPopup: some View {
        Group {
            if showingLimitedOffer {
                ZStack {
                    // Backdrop
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4)) {
                                showingLimitedOffer = false
                            }
                        }
                    
                    // Popup Card
                    limitedOfferCard
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4), value: showingLimitedOffer)
    }
    
    private var limitedOfferCard: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        showingLimitedOffer = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    Text("🔥")
                        .font(.system(size: 48))
                }
                
                VStack(spacing: 12) {
                    Text("Özel Lansman Fiyatı!")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("İlk kullanıcılara özel %40 indirim")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    
                    Text("Bu fiyat bir daha gelmeyecek")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                
                // Countdown
                VStack(spacing: 8) {
                    Text("Teklif Sona Eriyor:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 12) {
                        timeBlock(value: "23", label: "saat")
                        Text(":")
                            .font(.title.bold())
                            .foregroundColor(.secondary)
                        timeBlock(value: "47", label: "dk")
                        Text(":")
                            .font(.title.bold())
                            .foregroundColor(.secondary)
                        timeBlock(value: "32", label: "sn")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
                
                // Price comparison
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("₺999")
                            .font(.title3.bold())
                            .foregroundColor(.red)
                            .strikethrough()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        Text("₺599,99")
                            .font(.title.bold())
                            .foregroundColor(.green)
                    }
                    
                    Text("₺400 tasarruf!")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
                
                // CTA Button
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        showingLimitedOffer = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Fırsatı Kaçırma")
                            .font(.headline)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 6)
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        )
        .padding(.horizontal, 32)
    }
    
    private func timeBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
    }
    
    // MARK: - Value Comparison
    
    private var valueComparisonSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Gerçek Değer Karşılaştırması")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 14) {
                valueComparisonRow(
                    item: "1 çocuk kitabı",
                    price: "₺150",
                    emoji: "📚"
                )
                
                valueComparisonRow(
                    item: "Özel illüstrasyon",
                    price: "₺500",
                    emoji: "🎨"
                )
                
                valueComparisonRow(
                    item: "Kişiselleştirilmiş hikaye",
                    price: "₺300",
                    emoji: "✨"
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                // Total comparison with emphasis
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Toplam Değer")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Sadece 1 hikaye için")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("₺950")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                                .strikethrough()
                            Text("₺50/ay")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Highlight box
                    HStack(spacing: 8) {
                        Image(systemName: "infinity.circle.fill")
                            .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sınırsız Hikaye")
                                .font(.headline.bold())
                                .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                            Text("Her gün yeni maceralar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("%95 tasarruf")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal)
    }
    
    private func valueComparisonRow(item: String, price: String, emoji: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
            Text(item)
                .font(.callout)
                .foregroundColor(.primary)
            Spacer()
            Text(price)
                .font(.callout.bold())
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Emotional Benefits
    
    private var emotionalBenefitsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Premium ile Kazandırdıklarınız")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 14) {
                emotionalBenefitCard(
                    icon: "heart.fill",
                    color: .red,
                    title: "Özel Anlar",
                    description: "Her gece paylaştığınız benzersiz hikayeler, ömür boyu hatıralara dönüşür"
                )
                
                emotionalBenefitCard(
                    icon: "brain.head.profile",
                    color: .purple,
                    title: "Hayal Gücü",
                    description: "Sınırsız hikayelerle yaratıcılık ve hayal gücü her gün gelişir"
                )
                
                emotionalBenefitCard(
                    icon: "book.pages.fill",
                    color: .blue,
                    title: "Okuma Sevgisi",
                    description: "Kendini kahramanı olarak gören çocuğunuz, okumayı sevmeye başlar"
                )
                
                emotionalBenefitCard(
                    icon: "star.fill",
                    color: .orange,
                    title: "Özgüven",
                    description: "Hikayelerde kahraman olan çocuğunuz, gerçek hayatta da kendine güvenir"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal)
    }
    
    private func emotionalBenefitCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 22, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.06))
        )
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Planınızı Seçin")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            // Yıllık Plan - Featured
            Button(action: { 
                withAnimation(.spring(response: 0.3)) {
                    selectedPlan = .yearly 
                }
            }) {
                VStack(spacing: 0) {
                    // Badge
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text("EN AVANTAJLI")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10, corners: [.topLeft, .topRight])
                        Spacer()
                    }
                    
                    VStack(spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Text("Yıllık Plan")
                                        .font(.title3.bold())
                                        .foregroundColor(.primary)
                                    
                                    if selectedPlan == .yearly {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                
                                HStack(spacing: 10) {
                                    Text("₺999")
                                        .font(.title2)
                                        .foregroundColor(.red.opacity(0.8))
                                        .strikethrough(color: .red)
                                    
                                    Text("₺599,99")
                                        .font(.system(size: 36, weight: .heavy))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .green.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Sadece ₺50/ay")
                                        .font(.callout.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Benefits
                        VStack(spacing: 10) {
                            benefitRow(text: "₺400 tasarruf edin 💰", highlight: true)
                            benefitRow(text: "Günde sadece ₺1,64", highlight: false)
                            benefitRow(text: "1 kahveden ucuz! ☕️", highlight: false)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    selectedPlan == .yearly ? Color.green.opacity(0.05) : Color.white
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    selectedPlan == .yearly ?
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [.gray.opacity(0.25), .gray.opacity(0.25)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: selectedPlan == .yearly ? 3 : 2
                                )
                        )
                )
                .shadow(
                    color: selectedPlan == .yearly ? Color.green.opacity(0.25) : Color.black.opacity(0.08), 
                    radius: selectedPlan == .yearly ? 20 : 12, 
                    x: 0, 
                    y: selectedPlan == .yearly ? 8 : 4
                )
                .scaleEffect(selectedPlan == .yearly ? 1.02 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            // Aylık Plan
            Button(action: { 
                withAnimation(.spring(response: 0.3)) {
                    selectedPlan = .monthly 
                }
            }) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Aylık Plan")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if selectedPlan == .monthly {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Text("₺69,99")
                                .font(.title.bold())
                                .foregroundColor(.primary)
                            Text("/ay")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("İstediğiniz zaman iptal edin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    selectedPlan == .monthly ? 
                                    Color(red: 0.58, green: 0.29, blue: 0.98) : 
                                    Color.gray.opacity(0.25),
                                    lineWidth: selectedPlan == .monthly ? 2.5 : 2
                                )
                        )
                )
                .shadow(
                    color: selectedPlan == .monthly ? Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.2) : Color.black.opacity(0.06), 
                    radius: 12, 
                    x: 0, 
                    y: 4
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
    }
    
    private func benefitRow(text: String, highlight: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(highlight ? .green : Color(red: 0.58, green: 0.29, blue: 0.98))
                .font(.callout)
            Text(text)
                .font(highlight ? .callout.bold() : .callout)
                .foregroundColor(highlight ? .green : .primary)
            Spacer()
        }
    }
    
    // MARK: - Testimonials
    
    private var testimonialsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Text("Aileler Ne Diyor?")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    testimonialCard(
                        name: "Ayşe Hanım",
                        role: "2 çocuk annesi",
                        text: "Oğlum artık her gece hikaye bekliyor. Kendini kahramanı olarak görmek onu çok mutlu ediyor. Premium'a geçtiğimize çok memnunuz!",
                        rating: 5
                    )
                    
                    testimonialCard(
                        name: "Mehmet Bey",
                        role: "Baba",
                        text: "Kızım okumayı sevmiyordu. Ama kendi hikayelerini okumaya başladıktan sonra her gün kitap istiyor. Harika bir uygulama!",
                        rating: 5
                    )
                    
                    testimonialCard(
                        name: "Zeynep Hanım",
                        role: "Öğretmen & Anne",
                        text: "Hem eğlenceli hem öğretici. Çocuğumun hayal gücü ve kelime dağarcığı gelişti. Tüm ailelere tavsiye ediyorum.",
                        rating: 5
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func testimonialCard(name: String, role: String, text: String, rating: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Rating stars
            HStack(spacing: 3) {
                ForEach(0..<rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            // Quote
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Author
            HStack(spacing: 10) {
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
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.callout.bold())
                        .foregroundColor(.primary)
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 300, height: 200)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Guarantee Section
    
    private var guaranteeSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("7 Gün Para İade Garantisi")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                
                Text("Memnun kalmazsanız, sorulsuz sualsiz paranızı iade ediyoruz.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 18) {
            Button(action: upgradeToPremium) {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                        Text(selectedPlan == .yearly ? "Yıllık Premium'a Başla" : "Aylık Premium'a Başla")
                            .font(.title3.bold())
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(.white)
                    
                    Text(selectedPlan == .yearly ? "₺599,99/yıl - ₺400 tasarruf 🎉" : "₺69,99/ay")
                        .font(.callout.bold())
                        .foregroundColor(.white.opacity(0.95))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
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
                .cornerRadius(18)
                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.5), radius: 20, x: 0, y: 10)
            }
            
            Button("Satın Alımları Geri Yükle") {
                // Restore purchases
            }
            .foregroundColor(.secondary)
            .font(.callout)
            
            VStack(spacing: 6) {
                Text("İstediğiniz zaman iptal edebilirsiniz")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Otomatik yenileme • Güvenli ödeme")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    private func upgradeToPremium() {
        SubscriptionManager.shared.upgradeToPremium()
        dismiss()
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    SettingsView()
}