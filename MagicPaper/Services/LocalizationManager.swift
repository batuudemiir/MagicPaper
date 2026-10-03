import Foundation
import OSLog
import SwiftUI

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "LocalizationManager")

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    enum AppLanguage: String, CaseIterable {
        case turkish = "tr"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .turkish: return "Türkçe"
            case .english: return "English"
            }
        }
        
        var flag: String {
            switch self {
            case .turkish: return "🇹🇷"
            case .english: return "🇬🇧"
            }
        }
    }
    
    private init() {
        // Önce kaydedilmiş dil tercihini kontrol et
        if let savedLanguage = UserDefaults.standard.string(forKey: "defaultLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
            logger.debug("📱 Saved language loaded: \(language.displayName)")
        } else if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
                  let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
            logger.debug("📱 App language loaded: \(language.displayName)")
        } else {
            // Sistem dilini kontrol et - daha güvenilir yöntem
            let preferredLanguages = Locale.preferredLanguages
            let systemLanguageCode = preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            
            logger.debug("📱 System language code: \(systemLanguageCode)")
            logger.debug("📱 Preferred languages: \(preferredLanguages)")
            
            if systemLanguageCode == "tr" {
                currentLanguage = .turkish
                logger.debug("📱 Setting Turkish as default")
            } else {
                currentLanguage = .english
                logger.debug("📱 Setting English as default")
            }
            
            // İlk açılışta sistem dilini kaydet
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "defaultLanguage")
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    func changeLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    // MARK: - Localized Strings
    
    func localized(_ key: LocalizedKey) -> String {
        switch currentLanguage {
        case .turkish:
            return key.turkish
        case .english:
            return key.english
        }
    }
}

// MARK: - Localized Keys

enum LocalizedKey {
    // App Name
    case magicPaper
    
    // Onboarding
    case skip
    case back
    case next_button
    case getStarted
    case onboardingTitle1
    case onboardingDesc1
    case onboardingTitle2
    case onboardingDesc2
    case onboardingTitle3
    case onboardingDesc3
    case settings
    case myLibrary
    case storyClub
    case dailyStories
    case noStoriesYet
    case storiesWillBeAdded
    
    // Story Club (Subscription)
    case storyClubPackages
    case joinClub
    case clubDescription
    case starExplorer
    case storyHero
    case magicMaster
    case unlimitedTextStories
    case unlimitedDailyStories
    case imageStoriesPerMonth
    case prioritySupport
    case mostPopular
    case perMonth
    case perDay
    case superSavings
    case maximumValue
    case eachImageStoryWorth
    case monthlySavings
    case joinClubButton
    case cancelAnytime
    case securePayment
    case dayRefund
    case kvkkCompliant
    case membershipCancel
    
    // Free Package
    case freePackage
    case currentPackage
    case textStoryEvery12Hours
    case noImageStories
    case noDailyStories
    case unlimitedAccess
    case joinClubUnlimited
    
    // Benefits
    case imagination
    case confidence
    case readingLove
    case sleepRoutine
    
    // Quick Actions
    case illustrated
    case text
    case daily
    case library
    
    // Story Creation
    case createStory
    case childName
    case age
    case gender
    case boy
    case girl
    case theme
    case selectTheme
    case createButton
    case generating
    case storyCreated
    
    // Settings
    case profile
    case language
    case notifications
    case about
    case privacyPolicy
    case termsOfService
    case version
    
    // Settings - Extended
    case storySettings
    case appSettings
    case quickActions
    case aboutAndSupport
    case dangerZone
    case defaultLanguage
    case defaultAge
    case highQualityImages
    case autoSave
    case createNewStory
    case myStoryLibrary
    case shareApp
    case rateApp
    case contactSupport
    case clearAllData
    case clearDataWarning
    case cancel
    case clearData
    case stories
    case storyClubMember
    case imageStoriesLeft
    case freeTrialsLeft
    case clubMembershipRequired
    case onlyPerDay
    case activeMembers
    case newBadge
    case unlimited
    case premiumBadge
    case joinNow
    case firstDaysFree
    case imageStory
    case textStory
    case toggleMembership
    case cancelMembership
    case activateMembership
    
    // Home View
    case welcomeBack
    case letsCreateMagic
    case createIllustratedStory
    case createTextStory
    case createDailyStory
    case viewLibrary
    case recentStories
    case noRecentStories
    case startCreating
    
    // Create Story View
    case childPhoto
    case selectPhoto
    case photoDescription
    case addPhoto
    case basicInfo
    case name
    case storyTheme
    case selectAdventure
    case freeThemes
    case premiumThemes
    case customStoryTopic
    case storyLanguage
    case whichLanguage
    case generateStory
    case missingInfo
    case fillAllFields
    case photoRequired
    case selectPhotoFirst
    case storyGenerating
    case storyGeneratingMessage
    case ok
    case years
    case other
    
    // Library View
    case noStoriesInLibrary
    case createFirstStory
    case deleteStory
    case deleteConfirm
    case delete
    case completed
    case failed
    case uploading
    case generatingImages
    
    var turkish: String {
        switch self {
        // Onboarding
        case .skip: return "Atla"
        case .back: return "Geri"
        case .next_button: return "İleri"
        case .getStarted: return "Başla"
        case .onboardingTitle1: return "Fotoğraf Ekle"
        case .onboardingDesc1: return "Çocuğunuzun fotoğrafını yükleyin ve hikayenin kahramanı olsun"
        case .onboardingTitle2: return "Tema Seç"
        case .onboardingDesc2: return "Uzay, orman, denizaltı... Hayal gücünüzü serbest bırakın"
        case .onboardingTitle3: return "Sihir Başlasın"
        case .onboardingDesc3: return "Yapay zeka ile kişiselleştirilmiş, benzersiz hikayeler oluşturun"
            
        // Home
        case .magicPaper: return "MagicPaper"
        case .settings: return "Ayarlar"
        case .myLibrary: return "Kütüphanem"
        case .storyClub: return "Hikaye Kulübü"
        case .dailyStories: return "Günlük Hikayeler"
        case .noStoriesYet: return "Henüz Günlük Hikaye Yok"
        case .storiesWillBeAdded: return "Günlük hikayeler yakında eklenecek!"
            
        // Story Club
        case .storyClubPackages: return "📚 Hikaye Kulübü Paketleri"
        case .joinClub: return "Kulübe Katıl"
        case .clubDescription: return "Kulübümüze katıl, sınırsız hikaye dünyasını keşfet!"
        case .starExplorer: return "⭐ Yıldız Kaşifi"
        case .storyHero: return "👑 Hikaye Kahramanı"
        case .magicMaster: return "🌟 Sihir Ustası"
        case .unlimitedTextStories: return "Sınırsız metin hikaye"
        case .unlimitedDailyStories: return "Sınırsız günlük hikaye"
        case .imageStoriesPerMonth: return "görselli hikaye/ay"
        case .prioritySupport: return "Öncelikli destek"
        case .mostPopular: return "EN POPÜLER"
        case .perMonth: return "/ ay"
        case .perDay: return "Günde sadece"
        case .superSavings: return "Süper Tasarruf!"
        case .maximumValue: return "Maksimum Değer!"
        case .eachImageStoryWorth: return "Her görselli hikaye 14₺ değerinde"
        case .monthlySavings: return "Ayda"
        case .joinClubButton: return "Kulübe Katıl"
        case .cancelAnytime: return "İstediğiniz zaman kulüpten ayrılabilirsiniz"
        case .securePayment: return "Güvenli Ödeme"
        case .dayRefund: return "7 Gün İade"
        case .kvkkCompliant: return "KVKK Uyumlu"
        case .membershipCancel: return "Kulüp üyeliğinizi istediğiniz zaman iOS ayarlarından iptal edebilirsiniz"
            
        // Free Package
        case .freePackage: return "📦 Ücretsiz Paket"
        case .currentPackage: return "Mevcut Paketiniz"
        case .textStoryEvery12Hours: return "12 saatte 1 metin hikaye"
        case .noImageStories: return "Görselli hikaye"
        case .noDailyStories: return "Günlük hikaye"
        case .unlimitedAccess: return "Sınırsız erişim"
        case .joinClubUnlimited: return "Kulübe katıl, sınırsız hikaye keyfini çıkar!"
            
        // Benefits
        case .imagination: return "Hayal gücü ve yaratıcılık"
        case .confidence: return "Özgüven ve mutluluk"
        case .readingLove: return "Okuma sevgisi ve alışkanlığı"
        case .sleepRoutine: return "Huzurlu uyku rutini"
            
        // Quick Actions
        case .illustrated: return "Görselli"
        case .text: return "Metin"
        case .daily: return "Günlük"
        case .library: return "Kütüphane"
            
        // Story Creation
        case .createStory: return "Hikaye Oluştur"
        case .childName: return "Çocuğun Adı"
        case .age: return "Yaş"
        case .gender: return "Cinsiyet"
        case .boy: return "Erkek"
        case .girl: return "Kız"
        case .theme: return "Tema"
        case .selectTheme: return "Tema Seç"
        case .createButton: return "Hikaye Oluştur"
        case .generating: return "Oluşturuluyor..."
        case .storyCreated: return "Hikaye Oluşturuldu!"
            
        // Settings
        case .profile: return "Profil"
        case .language: return "Dil"
        case .notifications: return "Bildirimler"
        case .about: return "Hakkında"
        case .privacyPolicy: return "Gizlilik Politikası"
        case .termsOfService: return "Kullanım Şartları"
        case .version: return "Versiyon"
            
        // Settings - Extended
        case .storySettings: return "Hikaye Ayarları"
        case .appSettings: return "Uygulama Ayarları"
        case .quickActions: return "Hızlı İşlemler"
        case .aboutAndSupport: return "Hakkında ve Destek"
        case .dangerZone: return "Tehlike Bölgesi"
        case .defaultLanguage: return "Varsayılan Dil"
        case .defaultAge: return "Varsayılan Yaş"
        case .highQualityImages: return "Yüksek Kalite Görseller"
        case .autoSave: return "Otomatik Kaydet"
        case .createNewStory: return "Yeni Hikaye Oluştur"
        case .myStoryLibrary: return "Hikaye Kütüphanem"
        case .shareApp: return "Uygulamayı Paylaş"
        case .rateApp: return "Uygulamayı Değerlendir"
        case .contactSupport: return "Destek İletişim"
        case .clearAllData: return "Tüm Verileri Temizle"
        case .clearDataWarning: return "Bu işlem tüm hikayelerinizi ve ayarlarınızı silecektir. Bu işlem geri alınamaz."
        case .cancel: return "İptal"
        case .clearData: return "Verileri Temizle"
        case .stories: return "Hikaye"
        case .storyClubMember: return "Hikaye Kulübü Üyesi"
        case .imageStoriesLeft: return "görselli hikaye kaldı"
        case .freeTrialsLeft: return "deneme kaldı"
        case .clubMembershipRequired: return "Kulüp Üyeliği Gerekli"
        case .onlyPerDay: return "Günde sadece 3₺"
        case .activeMembers: return "Aktif üyelik"
        case .newBadge: return "YENİ"
        case .unlimited: return "Sınırsız"
        case .premiumBadge: return "Premium"
        case .joinNow: return "Hemen katıl, ilk 3 gün ücretsiz dene!"
        case .firstDaysFree: return "İlk 3 gün ücretsiz"
        case .imageStory: return "Görselli Hikaye"
        case .textStory: return "Metin Hikaye"
        case .toggleMembership: return "Kulüp Üyeliğini İptal (Test)"
        case .cancelMembership: return "Kulüp Üyeliğini İptal (Test)"
        case .activateMembership: return "Kulüp Üyeliğini Aktif Et (Test)"
            
        // Home View
        case .welcomeBack: return "Hoş Geldin"
        case .letsCreateMagic: return "Hadi sihirli hikayeler yaratalım!"
        case .createIllustratedStory: return "Görselli Hikaye Oluştur"
        case .createTextStory: return "Metin Hikaye Oluştur"
        case .createDailyStory: return "Günlük Hikaye Oluştur"
        case .viewLibrary: return "Kütüphaneyi Gör"
        case .recentStories: return "Son Hikayeler"
        case .noRecentStories: return "Henüz hikaye yok"
        case .startCreating: return "İlk hikayeni oluştur!"
            
        // Create Story View
        case .childPhoto: return "Çocuğun Fotoğrafı"
        case .selectPhoto: return "Fotoğraf Seç"
        case .photoDescription: return "Hikayenin kahramanı için bir fotoğraf seçin"
        case .addPhoto: return "Fotoğraf Ekle"
        case .basicInfo: return "Temel Bilgiler"
        case .name: return "İsim"
        case .storyTheme: return "Hikaye Teması"
        case .selectAdventure: return "Maceranın türünü seçin"
        case .freeThemes: return "Ücretsiz Temalar"
        case .premiumThemes: return "Premium Temalar"
        case .customStoryTopic: return "Özel Hikaye Konusu"
        case .storyLanguage: return "Hikaye Dili"
        case .whichLanguage: return "Hikayenin hangi dilde yazılmasını istersiniz?"
        case .generateStory: return "Hikaye Oluştur"
        case .missingInfo: return "Eksik Bilgi"
        case .fillAllFields: return "Lütfen tüm gerekli alanları doldurun ve bir fotoğraf ekleyin."
        case .photoRequired: return "Fotoğraf Gerekli"
        case .selectPhotoFirst: return "Lütfen bir fotoğraf seçin."
        case .storyGenerating: return "Hikaye Oluşturuluyor"
        case .storyGeneratingMessage: return "Hikayeniz oluşturuluyor!\n\nHikayenin tamamlanabilmesi için lütfen uygulamadan çıkmayınız. İlerlemeyi Kütüphane sekmesinden takip edebilirsiniz."
        case .ok: return "Tamam"
        case .years: return "yaş"
        case .other: return "Diğer"
            
        // Library View
        case .noStoriesInLibrary: return "Henüz Hikaye Yok"
        case .createFirstStory: return "İlk hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın"
        case .deleteStory: return "Hikayeyi Sil"
        case .deleteConfirm: return "Bu hikayeyi silmek istediğinizden emin misiniz?"
        case .delete: return "Sil"
        case .completed: return "Tamamlandı"
        case .failed: return "Başarısız"
        case .uploading: return "Yükleniyor"
        case .generatingImages: return "Görseller Oluşturuluyor"
        }
    }
    
    var english: String {
        switch self {
        // App Name
        case .magicPaper: return "MagicPaper"
        
        // Onboarding
        case .skip: return "Skip"
        case .back: return "Back"
        case .next_button: return "Next"
        case .getStarted: return "Get Started"
        case .onboardingTitle1: return "Add Photo"
        case .onboardingDesc1: return "Upload your child's photo and make them the hero of the story"
        case .onboardingTitle2: return "Choose Theme"
        case .onboardingDesc2: return "Space, forest, underwater... Let your imagination run wild"
        case .onboardingTitle3: return "Let the Magic Begin"
        case .onboardingDesc3: return "Create personalized, unique stories with AI"
        
        // Home
        case .settings: return "Settings"
        case .myLibrary: return "My Library"
        case .storyClub: return "Story Club"
        case .dailyStories: return "Daily Stories"
        case .noStoriesYet: return "No Daily Stories Yet"
        case .storiesWillBeAdded: return "Daily stories coming soon!"
            
        // Story Club
        case .storyClubPackages: return "📚 Story Club Packages"
        case .joinClub: return "Join Club"
        case .clubDescription: return "Join our club, discover unlimited story world!"
        case .starExplorer: return "⭐ Star Explorer"
        case .storyHero: return "👑 Story Hero"
        case .magicMaster: return "🌟 Magic Master"
        case .unlimitedTextStories: return "Unlimited text stories"
        case .unlimitedDailyStories: return "Unlimited daily stories"
        case .imageStoriesPerMonth: return "image stories/month"
        case .prioritySupport: return "Priority support"
        case .mostPopular: return "MOST POPULAR"
        case .perMonth: return "/ month"
        case .perDay: return "Only"
        case .superSavings: return "Super Savings!"
        case .maximumValue: return "Maximum Value!"
        case .eachImageStoryWorth: return "Each image story worth $5"
        case .monthlySavings: return "Monthly"
        case .joinClubButton: return "Join Club"
        case .cancelAnytime: return "You can leave the club anytime"
        case .securePayment: return "Secure Payment"
        case .dayRefund: return "7 Day Refund"
        case .kvkkCompliant: return "GDPR Compliant"
        case .membershipCancel: return "You can cancel your club membership anytime from iOS settings"
            
        // Free Package
        case .freePackage: return "📦 Free Package"
        case .currentPackage: return "Your Current Package"
        case .textStoryEvery12Hours: return "1 text story every 12 hours"
        case .noImageStories: return "Image stories"
        case .noDailyStories: return "Daily stories"
        case .unlimitedAccess: return "Unlimited access"
        case .joinClubUnlimited: return "Join club, enjoy unlimited stories!"
            
        // Benefits
        case .imagination: return "Imagination and creativity"
        case .confidence: return "Confidence and happiness"
        case .readingLove: return "Love for reading and habit"
        case .sleepRoutine: return "Peaceful sleep routine"
            
        // Quick Actions
        case .illustrated: return "Illustrated"
        case .text: return "Text"
        case .daily: return "Daily"
        case .library: return "Library"
            
        // Story Creation
        case .createStory: return "Create Story"
        case .childName: return "Child's Name"
        case .age: return "Age"
        case .gender: return "Gender"
        case .boy: return "Boy"
        case .girl: return "Girl"
        case .theme: return "Theme"
        case .selectTheme: return "Select Theme"
        case .createButton: return "Create Story"
        case .generating: return "Generating..."
        case .storyCreated: return "Story Created!"
            
        // Settings
        case .profile: return "Profile"
        case .language: return "Language"
        case .notifications: return "Notifications"
        case .about: return "About"
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        case .version: return "Version"
            
        // Settings - Extended
        case .storySettings: return "Story Settings"
        case .appSettings: return "App Settings"
        case .quickActions: return "Quick Actions"
        case .aboutAndSupport: return "About & Support"
        case .dangerZone: return "Danger Zone"
        case .defaultLanguage: return "Default Language"
        case .defaultAge: return "Default Age"
        case .highQualityImages: return "High Quality Images"
        case .autoSave: return "Auto Save"
        case .createNewStory: return "Create New Story"
        case .myStoryLibrary: return "My Story Library"
        case .shareApp: return "Share App"
        case .rateApp: return "Rate App"
        case .contactSupport: return "Contact Support"
        case .clearAllData: return "Clear All Data"
        case .clearDataWarning: return "This will delete all your stories and settings. This action cannot be undone."
        case .cancel: return "Cancel"
        case .clearData: return "Clear Data"
        case .stories: return "Stories"
        case .storyClubMember: return "Story Club Member"
        case .imageStoriesLeft: return "image stories left"
        case .freeTrialsLeft: return "trials left"
        case .clubMembershipRequired: return "Club Membership Required"
        case .onlyPerDay: return "Only $1/day"
        case .activeMembers: return "Active membership"
        case .newBadge: return "NEW"
        case .unlimited: return "Unlimited"
        case .premiumBadge: return "Premium"
        case .joinNow: return "Join now, try free for 3 days!"
        case .firstDaysFree: return "First 3 days free"
        case .imageStory: return "Image Story"
        case .textStory: return "Text Story"
        case .toggleMembership: return "Toggle Membership (Test)"
        case .cancelMembership: return "Cancel Membership (Test)"
        case .activateMembership: return "Activate Membership (Test)"
            
        // Home View
        case .welcomeBack: return "Welcome Back"
        case .letsCreateMagic: return "Let's create magical stories!"
        case .createIllustratedStory: return "Create Illustrated Story"
        case .createTextStory: return "Create Text Story"
        case .createDailyStory: return "Create Daily Story"
        case .viewLibrary: return "View Library"
        case .recentStories: return "Recent Stories"
        case .noRecentStories: return "No stories yet"
        case .startCreating: return "Create your first story!"
            
        // Create Story View
        case .childPhoto: return "Child's Photo"
        case .selectPhoto: return "Select Photo"
        case .photoDescription: return "Select a photo for the story's hero"
        case .addPhoto: return "Add Photo"
        case .basicInfo: return "Basic Information"
        case .name: return "Name"
        case .storyTheme: return "Story Theme"
        case .selectAdventure: return "Select the type of adventure"
        case .freeThemes: return "Free Themes"
        case .premiumThemes: return "Premium Themes"
        case .customStoryTopic: return "Custom Story Topic"
        case .storyLanguage: return "Story Language"
        case .whichLanguage: return "Which language would you like the story written in?"
        case .generateStory: return "Generate Story"
        case .missingInfo: return "Missing Information"
        case .fillAllFields: return "Please fill in all required fields and add a photo."
        case .photoRequired: return "Photo Required"
        case .selectPhotoFirst: return "Please select a photo."
        case .storyGenerating: return "Story Generating"
        case .storyGeneratingMessage: return "Your story is being created!\n\nPlease don't close the app. You can track progress from the Library tab."
        case .ok: return "OK"
        case .years: return "years"
        case .other: return "Other"
            
        // Library View
        case .noStoriesInLibrary: return "No Stories Yet"
        case .createFirstStory: return "Create your first story and\nenjoy reading with your child"
        case .deleteStory: return "Delete Story"
        case .deleteConfirm: return "Are you sure you want to delete this story?"
        case .delete: return "Delete"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .uploading: return "Uploading"
        case .generatingImages: return "Generating Images"
        }
    }
}

// MARK: - SwiftUI Extension

extension View {
    func localized(_ key: LocalizedKey) -> String {
        LocalizationManager.shared.localized(key)
    }
}
