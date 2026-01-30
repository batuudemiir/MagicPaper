import SwiftUI

struct SettingsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var selectedLanguage = StoryLanguage.turkish
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var highQualityImages = true
    @State private var showingUpgradeSheet = false
    @State private var showingCreditSheet = false
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
                    
                    // Abonelik Bölümü
                    subscriptionSection
                    
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
            SimpleSubscriptionView()
        }
        .sheet(isPresented: $showingCreditSheet) {
            SimpleSubscriptionView()
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
                    
                    // Abonelik durumu
                    if subscriptionManager.isPremium {
                        HStack(spacing: 4) {
                            Text("👑")
                                .font(.caption)
                            Text(subscriptionManager.subscriptionTier.displayName)
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
                    } else if subscriptionManager.freeTrialCount > 0 {
                        HStack(spacing: 4) {
                            Text("🎁")
                                .font(.caption)
                            Text("\(subscriptionManager.freeTrialCount) deneme kaldı")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
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
    
    private var subscriptionSection: some View {
        Button(action: {
            showingUpgradeSheet = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: subscriptionManager.isPremium ? 
                                    [Color.yellow, Color.orange] :
                                    [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Text(subscriptionManager.isPremium ? "👑" : "✨")
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(subscriptionManager.isPremium ? "Premium Üye" : "Abone Olun")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        
                        if !subscriptionManager.isPremium {
                            Text("☕️ Kahveden ucuz!")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                    }
                    
                    if subscriptionManager.isPremium {
                        Text("\(subscriptionManager.remainingImageStories) görselli hikaye kaldı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Günde 3₺ ile sınırsız hikaye")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(subscriptionManager.isPremium ? Color.yellow : Color.purple)
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
                                colors: subscriptionManager.isPremium ?
                                    [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)] :
                                    [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
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
                // Test butonu - Abonelik toggle
                Button(action: {
                    subscriptionManager.toggleSubscription()
                }) {
                    HStack {
                        settingIcon(subscriptionManager.isPremium ? "crown.fill" : "crown", color: subscriptionManager.isPremium ? .yellow : .gray)
                        Text(subscriptionManager.isPremium ? "🧪 Abonelik İptal (Test)" : "🧪 Abonelik Aktif Et (Test)")
                            .font(.subheadline)
                            .foregroundColor(subscriptionManager.isPremium ? .orange : .blue)
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


// MARK: - Deprecated Views
// PremiumUpgradeView removed - use PremiumView instead

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