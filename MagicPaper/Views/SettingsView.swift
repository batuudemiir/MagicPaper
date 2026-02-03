import SwiftUI

struct SettingsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var highQualityImages = true
    @State private var showingUpgradeSheet = false
    @State private var showingCreditSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingAboutSheet = false
    @State private var showingProfileEdit = false
    @State private var showingParentalGate = false
    @State private var parentalGateAction: (() -> Void)?
    @AppStorage("defaultTheme") private var defaultTheme = "fantasy"
    @AppStorage("defaultAgeRange") private var defaultAgeRange = 6
    @AppStorage("defaultLanguage") private var defaultLanguageRaw = "tr"
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profil Bölümü
                    profileSection
                    
                    // Hikaye Kulübü Bölümü
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
                .padding(.horizontal, DeviceHelper.horizontalPadding)
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
            .navigationTitle(localizationManager.localized(.settings))
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack) // iPad'de split view'ı devre dışı bırak
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
        .sheet(isPresented: $showingParentalGate) {
            ParentalGateView(onSuccess: {
                if let action = parentalGateAction {
                    action()
                    parentalGateAction = nil
                }
            })
        }
        .alert(localizationManager.localized(.clearAllData), isPresented: $showingClearDataAlert) {
            Button(localizationManager.localized(.cancel), role: .cancel) { }
            Button(localizationManager.localized(.clearData), role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(localizationManager.localized(.clearDataWarning))
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
                    
                    // Hikaye Kulübü durumu
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
        let isPremium = subscriptionManager.isPremium
        let circleGradient = LinearGradient(
            colors: isPremium ? 
                [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)] :
                [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let iconGradient = LinearGradient(
            colors: isPremium ? 
                [Color.yellow, Color.orange] :
                [Color.purple, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Button(action: {
            showingUpgradeSheet = true
        }) {
            VStack(spacing: 0) {
                // Üst kısım - Durum ve Bilgi
                HStack(spacing: 16) {
                    // Animasyonlu ikon
                    subscriptionIcon(circleGradient: circleGradient, iconGradient: iconGradient, isPremium: isPremium)
                    
                    subscriptionTitleSection
                    
                    Spacer()
                    
                    // Sağ ok
                    Image(systemName: subscriptionManager.isPremium ? "gearshape.fill" : "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(subscriptionManager.isPremium ? Color.gray.opacity(0.5) : Color.purple)
                }
                .padding(20)
                
                // Alt kısım - Detaylar
                subscriptionDetailsSection
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(subscriptionBackground)
    }
    
    // Yardımcı view - Başlık bölümü
    private var subscriptionTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık
            HStack(spacing: 6) {
                Text(subscriptionManager.isPremium ? localizationManager.localized(.storyClubMember) : localizationManager.localized(.joinClub))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                if !subscriptionManager.isPremium {
                    Text(localizationManager.localized(.newBadge))
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                }
            }
            
            // Durum bilgisi
            if subscriptionManager.isPremium {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(localizationManager.localized(.activeMembers))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Text("☕️")
                        .font(.caption)
                    Text(localizationManager.localized(.onlyPerDay))
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // Yardımcı view - Detay bölümü
    private var subscriptionDetailsSection: some View {
        Group {
            if !subscriptionManager.isPremium {
                nonMemberDetails
            } else {
                memberQuotaDetails
            }
        }
    }
    
    // Yardımcı view - Üye olmayan detaylar
    private var nonMemberDetails: some View {
        Group {
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Faydalar
                HStack(spacing: 12) {
                    benefitBadge(icon: "infinity", text: localizationManager.localized(.unlimited), color: .purple)
                    benefitBadge(icon: "photo.fill", text: localizationManager.localized(.illustrated), color: .blue)
                    benefitBadge(icon: "sparkles", text: localizationManager.localized(.premiumBadge), color: .orange)
                }
                
                // CTA
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(localizationManager.localized(.joinNow))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    // Yardımcı view - Üye kota detayları
    private var memberQuotaDetails: some View {
        let totalStories = subscriptionManager.subscriptionTier.monthlyImageStories
        
        return Group {
            Divider()
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Görselli hikaye kotası
                quotaCard(
                    count: subscriptionManager.remainingImageStories,
                    total: totalStories,
                    label: localizationManager.localized(.imageStory),
                    color: .purple
                )
                
                // Metin hikaye
                infiniteQuotaCard(
                    label: localizationManager.localized(.textStory),
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    // Yardımcı view - Kota kartı
    private func quotaCard(count: Int, total: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(total)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    // Yardımcı view - Sınırsız kota kartı
    private func infiniteQuotaCard(label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "infinity")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    // Yardımcı view - Arka plan
    private var subscriptionBackground: some View {
        let borderGradient = LinearGradient(
            colors: subscriptionManager.isPremium ?
                [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)] :
                [Color.purple.opacity(0.5), Color.pink.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderGradient, lineWidth: subscriptionManager.isPremium ? 2 : 3)
            )
            .shadow(
                color: subscriptionManager.isPremium ? Color.orange.opacity(0.2) : Color.purple.opacity(0.25),
                radius: 20,
                x: 0,
                y: 8
            )
    }
    
    // Yardımcı fonksiyon - Fayda rozeti
    private func benefitBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
    
    // Yardımcı fonksiyon - Abonelik ikonu
    private func subscriptionIcon(circleGradient: LinearGradient, iconGradient: LinearGradient, isPremium: Bool) -> some View {
        ZStack {
            Circle()
                .fill(circleGradient)
                .frame(width: 70, height: 70)
            
            RoundedRectangle(cornerRadius: 18)
                .fill(iconGradient)
                .frame(width: 56, height: 56)
                .shadow(color: isPremium ? Color.orange.opacity(0.4) : Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
            
            Text(isPremium ? "👑" : "✨")
                .font(.system(size: 32))
        }
    }
    
    private var storySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localized(.storySettings))
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Varsayılan Dil
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        settingIcon("globe", color: .blue)
                        Text(localizationManager.localized(.defaultLanguage))
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { 
                                if localizationManager.currentLanguage == .turkish {
                                    return StoryLanguage.turkish
                                } else {
                                    return StoryLanguage.english
                                }
                            },
                            set: { newValue in
                                defaultLanguageRaw = newValue.rawValue
                                // LocalizationManager'ı da güncelle
                                if newValue == .turkish {
                                    localizationManager.changeLanguage(.turkish)
                                } else {
                                    localizationManager.changeLanguage(.english)
                                }
                            }
                        )) {
                            Text("🇹🇷 Türkçe").tag(StoryLanguage.turkish)
                            Text("🇬🇧 English").tag(StoryLanguage.english)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Açıklama
                    Text(localizationManager.currentLanguage == .turkish ? 
                         "Uygulama dili ve hikaye dili" : 
                         "App language and story language")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 52)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Varsayılan Yaş Aralığı
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        settingIcon("person.fill", color: .green)
                        Text(localizationManager.localized(.defaultAge))
                            .font(.subheadline)
                        Spacer()
                        Text("\(defaultAgeRange) \(localizationManager.currentLanguage == .turkish ? "yaş" : "years")")
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
                    Text(localizationManager.localized(.highQualityImages))
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
            Text(localizationManager.localized(.appSettings))
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    settingIcon("bell.fill", color: .orange)
                    Text(localizationManager.localized(.notifications))
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
                    Text(localizationManager.localized(.autoSave))
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
            Text(localizationManager.localized(.quickActions))
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                NavigationLink(destination: CreateStoryView()) {
                    HStack {
                        settingIcon("plus.circle.fill", color: .indigo)
                        Text(localizationManager.localized(.createNewStory))
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
                        Text(localizationManager.localized(.myStoryLibrary))
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
                
                Button(action: {
                    parentalGateAction = { shareApp() }
                    showingParentalGate = true
                }) {
                    HStack {
                        settingIcon("square.and.arrow.up.fill", color: .blue)
                        Text(localizationManager.localized(.shareApp))
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
            Text(localizationManager.localized(.aboutAndSupport))
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button(action: { showingAboutSheet = true }) {
                    HStack {
                        settingIcon("info.circle.fill", color: .blue)
                        Text(localizationManager.localized(.about))
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
                
                Button(action: {
                    parentalGateAction = { rateApp() }
                    showingParentalGate = true
                }) {
                    HStack {
                        settingIcon("star.fill", color: .yellow)
                        Text(localizationManager.localized(.rateApp))
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
                
                Button(action: {
                    parentalGateAction = { contactSupport() }
                    showingParentalGate = true
                }) {
                    HStack {
                        settingIcon("envelope.fill", color: .cyan)
                        Text(localizationManager.localized(.contactSupport))
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
                
                Button(action: {
                    parentalGateAction = { openPrivacyPolicy() }
                    showingParentalGate = true
                }) {
                    HStack {
                        settingIcon("shield.checkered", color: .green)
                        Text(localizationManager.localized(.privacyPolicy))
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
                
                Button(action: {
                    parentalGateAction = { openTermsOfService() }
                    showingParentalGate = true
                }) {
                    HStack {
                        settingIcon("doc.text.fill", color: .gray)
                        Text(localizationManager.localized(.termsOfService))
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
            Text(localizationManager.localized(.dangerZone))
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
                        Text(subscriptionManager.isPremium ? 
                             "🧪 \(localizationManager.localized(.cancelMembership))" : 
                             "🧪 \(localizationManager.localized(.activateMembership))")
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
                        Text(localizationManager.localized(.clearAllData))
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
        
        defaultLanguageRaw = "tr"
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