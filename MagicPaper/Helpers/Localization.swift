import Foundation
import SwiftUI

// MARK: - Simple Localization Helper

struct L {
    static var isEnglish: Bool {
        LocalizationManager.shared.currentLanguage == .english
    }
    
    static var isTurkish: Bool {
        LocalizationManager.shared.currentLanguage == .turkish
    }
    
    // Helper function
    static func tr(_ turkish: String, _ english: String) -> String {
        isEnglish ? english : turkish
    }
}

// MARK: - All Translations in One Place

extension L {
    // MARK: - Common
    static var cancel: String { tr("İptal", "Cancel") }
    static var ok: String { tr("Tamam", "OK") }
    static var save: String { tr("Kaydet", "Save") }
    static var delete: String { tr("Sil", "Delete") }
    static var close: String { tr("Kapat", "Close") }
    static var back: String { tr("Geri", "Back") }
    static var next: String { tr("İleri", "Next") }
    static var skip: String { tr("Atla", "Skip") }
    static var start: String { tr("Başla", "Start") }
    static var create: String { tr("Oluştur", "Create") }
    static var loading: String { tr("Yükleniyor...", "Loading...") }
    static var new: String { tr("Yeni", "New") }
    static var popular: String { tr("Popüler", "Popular") }
    static var unlimited: String { tr("Sınırsız", "Unlimited") }
    static var premium: String { tr("Premium", "Premium") }
    
    // MARK: - Onboarding
    static var onboardingTitle1: String { tr("Fotoğraf Ekle", "Add Photo") }
    static var onboardingDesc1: String { tr("Çocuğunuzun fotoğrafını yükleyin ve hikayenin kahramanı olsun", "Upload your child's photo and make them the hero of the story") }
    static var onboardingTitle2: String { tr("Tema Seç", "Choose Theme") }
    static var onboardingDesc2: String { tr("Uzay, orman, denizaltı... Hayal gücünüzü serbest bırakın", "Space, forest, underwater... Let your imagination run wild") }
    static var onboardingTitle3: String { tr("Sihir Başlasın", "Let the Magic Begin") }
    static var onboardingDesc3: String { tr("Yapay zeka ile kişiselleştirilmiş, benzersiz hikayeler oluşturun", "Create personalized, unique stories with AI") }
    static var getStarted: String { tr("Başla", "Get Started") }
    
    // MARK: - Profile Setup
    static var welcome: String { tr("Hoş Geldiniz!", "Welcome!") }
    static var createProfile: String { tr("Başlamak için profilinizi oluşturun", "Create your profile to get started") }
    static var profilePhoto: String { tr("Profil Fotoğrafı", "Profile Photo") }
    static var yourName: String { tr("Adınız", "Your Name") }
    static var enterName: String { tr("Adınızı girin", "Enter your name") }
    static var editProfile: String { tr("Profili Düzenle", "Edit Profile") }
    
    // MARK: - Home
    static var home: String { tr("Ana Sayfa", "Home") }
    static var welcomeBack: String { tr("Hoş Geldin", "Welcome Back") }
    static var letsCreateMagic: String { tr("Hadi sihirli hikayeler yaratalım!", "Let's create magical stories!") }
    static var recentStories: String { tr("Son Hikayeler", "Recent Stories") }
    static var noRecentStories: String { tr("Henüz hikaye yok", "No stories yet") }
    static var startCreating: String { tr("İlk hikayeni oluştur!", "Create your first story!") }
    
    // MARK: - Navigation
    static var library: String { tr("Kütüphane", "Library") }
    static var myLibrary: String { tr("Kütüphanem", "My Library") }
    static var settings: String { tr("Ayarlar", "Settings") }
    static var daily: String { tr("Günlük", "Daily") }
    static var dailyStories: String { tr("Günlük Hikayeler", "Daily Stories") }
    
    // MARK: - Story Types
    static var newStory: String { tr("Yeni Hikaye", "New Story") }
    static var whichStoryType: String { tr("Hangi tür hikaye oluşturmak istersiniz?", "Which type of story would you like to create?") }
    static var illustratedStory: String { tr("Görselli Hikaye", "Illustrated Story") }
    static var illustratedDesc: String { tr("Fotoğrafla özel hikaye", "Custom story with photo") }
    static var textStory: String { tr("Metin Hikaye", "Text Story") }
    static var textStoryDesc: String { tr("Hayal gücünü harekete geçir", "Spark imagination") }
    static var dailyStory: String { tr("Günlük Hikaye", "Daily Story") }
    static var dailyStoryDesc: String { tr("Kategori bazlı hikayeler", "Category-based stories") }
    
    // MARK: - Story Creation
    static var createStory: String { tr("Hikaye Oluştur", "Create Story") }
    static var childPhoto: String { tr("Çocuğun Fotoğrafı", "Child's Photo") }
    static var selectPhoto: String { tr("Fotoğraf Seç", "Select Photo") }
    static var addPhoto: String { tr("Fotoğraf Ekle", "Add Photo") }
    static var basicInfo: String { tr("Temel Bilgiler", "Basic Information") }
    static var childInfo: String { tr("Çocuk Bilgileri", "Child Information") }
    static var childName: String { tr("Çocuğun Adı", "Child's Name") }
    static var name: String { tr("İsim", "Name") }
    static var age: String { tr("Yaş", "Age") }
    static var years: String { tr("yaş", "years") }
    static var gender: String { tr("Cinsiyet", "Gender") }
    static var boy: String { tr("Erkek", "Boy") }
    static var girl: String { tr("Kız", "Girl") }
    static var other: String { tr("Diğer", "Other") }
    static var male: String { tr("Erkek", "Male") }
    static var female: String { tr("Kız", "Female") }
    
    // MARK: - Story Theme
    static var storyTheme: String { tr("Hikaye Teması", "Story Theme") }
    static var selectTheme: String { tr("Tema Seç", "Select Theme") }
    static var selectAdventure: String { tr("Maceranın türünü seçin", "Select the type of adventure") }
    static var freeThemes: String { tr("Ücretsiz Temalar", "Free Themes") }
    static var premiumThemes: String { tr("Premium Temalar", "Premium Themes") }
    static var customStoryTopic: String { tr("Özel Hikaye Konusu", "Custom Story Topic") }
    
    // MARK: - Story Language
    static var storyLanguage: String { tr("Hikaye Dili", "Story Language") }
    static var whichLanguage: String { tr("Hikayenin hangi dilde yazılmasını istersiniz?", "Which language would you like the story written in?") }
    
    // MARK: - Story Generation
    static var generateStory: String { tr("Hikaye Oluştur", "Generate Story") }
    static var generating: String { tr("Oluşturuluyor...", "Generating...") }
    static var generatingImages: String { tr("Görseller Oluşturuluyor", "Generating Images") }
    static var storyGenerating: String { tr("Hikaye Oluşturuluyor", "Story Generating") }
    static var storyGeneratingMessage: String { tr("Hikayeniz oluşturuluyor!\n\nHikayenin tamamlanabilmesi için lütfen uygulamadan çıkmayınız. İlerlemeyi Kütüphane sekmesinden takip edebilirsiniz.", "Your story is being created!\n\nPlease don't close the app. You can track progress from the Library tab.") }
    static var storyCreated: String { tr("Hikaye Oluşturuldu!", "Story Created!") }
    static var storyBeingCreated: String { tr("Hikayeniz oluşturuluyor! Metin Hikayeler kütüphanesinden ilerlemeyi takip edebilirsiniz.", "Your story is being created! You can track progress from the Text Stories library.") }
    
    // MARK: - Library
    static var noStoriesInLibrary: String { tr("Henüz Hikaye Yok", "No Stories Yet") }
    static var createFirstStory: String { tr("İlk hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın", "Create your first story and\nenjoy reading with your child") }
    static var noTextStories: String { tr("Henüz Metin Hikaye Yok", "No Text Stories Yet") }
    static var createFirstTextStory: String { tr("İlk metin hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın", "Create your first text story and\nenjoy reading with your child") }
    static var deleteStory: String { tr("Hikayeyi Sil", "Delete Story") }
    static var deleteConfirm: String { tr("Bu hikayeyi silmek istediğinizden emin misiniz?", "Are you sure you want to delete this story?") }
    static var completed: String { tr("Tamamlandı", "Completed") }
    static var failed: String { tr("Başarısız", "Failed") }
    static var uploading: String { tr("Yükleniyor", "Uploading") }
    
    // MARK: - Story Viewer
    static func page(_ current: Int, _ total: Int) -> String { 
        tr("Sayfa \(current)/\(total)", "Page \(current)/\(total)") 
    }
    static var previous: String { tr("Önceki", "Previous") }
    static var nextPage: String { tr("Sonraki", "Next") }
    static var readingTip: String { tr("Okuma İpucu", "Reading Tip") }
    static var readSlowly: String { tr("Yavaş yavaş okuyun ve hayal edin!", "Read slowly and imagine!") }
    static var storyLesson: String { tr("Hikayenin Öğretisi", "Story's Lesson") }
    
    // MARK: - Reading Settings
    static var textSize: String { tr("Yazı Boyutu", "Text Size") }
    static var adjustTextSize: String { tr("Hikaye metninin boyutunu ayarlayın", "Adjust story text size") }
    static var readingTheme: String { tr("Okuma Teması", "Reading Theme") }
    static var lineSpacing: String { tr("Satır Aralığı", "Line Spacing") }
    static var adjustLineSpacing: String { tr("Satırlar arasındaki boşluğu ayarlayın", "Adjust spacing between lines") }
    static var autoPlay: String { tr("Otomatik Oynat", "Auto Play") }
    static var autoPlayDesc: String { tr("Her 8 saniyede bir sayfa", "One page every 8 seconds") }
    static var autoPlayFooter: String { tr("Hikaye sayfaları otomatik olarak ilerler", "Story pages advance automatically") }
    static var highContrastActive: String { tr("Yüksek Kontrast Aktif", "High Contrast Active") }
    static var colorsOptimized: String { tr("Daha iyi okunabilirlik için renkler optimize edildi", "Colors optimized for better readability") }
    static var preview: String { tr("Önizleme", "Preview") }
    static var highContrastOptimized: String { tr("✓ Yüksek kontrast ile optimize edildi", "✓ Optimized with high contrast") }
    
    // MARK: - Subscription
    static var storyClub: String { tr("Hikaye Kulübü", "Story Club") }
    static var storyClubPackages: String { tr("📚 Hikaye Kulübü Paketleri", "📚 Story Club Packages") }
    static var joinClub: String { tr("Kulübe Katıl", "Join Club") }
    static var clubDescription: String { tr("Kulübümüze katıl, sınırsız hikaye dünyasını keşfet!", "Join our club, discover unlimited story world!") }
    static var mostPopular: String { tr("EN POPÜLER", "MOST POPULAR") }
    static var perMonth: String { tr("/ ay", "/ month") }
    static var perDay: String { tr("Günde sadece", "Only") }
    static var superSavings: String { tr("Süper Tasarruf!", "Super Savings!") }
    static var maximumValue: String { tr("Maksimum Değer!", "Maximum Value!") }
    static var joinNow: String { tr("Hemen katıl, ilk 3 gün ücretsiz dene!", "Join now, try free for 3 days!") }
    static var firstDaysFree: String { tr("İlk 3 gün ücretsiz", "First 3 days free") }
    static var cancelAnytime: String { tr("İstediğiniz zaman iptal edebilirsiniz", "You can cancel anytime") }
    static var membershipCancel: String { tr("Üyeliğinizi istediğiniz zaman iOS ayarlarından iptal edebilirsiniz", "You can cancel your membership anytime from iOS settings") }
    
    // MARK: - Packages
    static var freePackage: String { tr("📦 Ücretsiz Paket", "📦 Free Package") }
    static var currentPackage: String { tr("Mevcut Paketiniz", "Your Current Package") }
    static var yourActivePackage: String { tr("Aktif Paketiniz", "Your Active Package") }
    static var freeTrial: String { tr("Ücretsiz Deneme", "Free Trial") }
    static var freeTrialActive: String { tr("Ücretsiz Deneme Aktif", "Free Trial Active") }
    static var clubMembershipRequired: String { tr("Kulüp Üyeliği Gerekli", "Club Membership Required") }
    static var unlimitedTextStories: String { tr("Sınırsız metin hikaye", "Unlimited text stories") }
    static var unlimitedDailyStories: String { tr("Sınırsız günlük hikaye", "Unlimited daily stories") }
    static var textStoryEvery12Hours: String { tr("12 saatte 1 metin hikaye", "1 text story every 12 hours") }
    
    // MARK: - Settings
    static var profile: String { tr("Profil", "Profile") }
    static var language: String { tr("Dil", "Language") }
    static var defaultLanguage: String { tr("Varsayılan Dil", "Default Language") }
    static var defaultAge: String { tr("Varsayılan Yaş", "Default Age") }
    static var notifications: String { tr("Bildirimler", "Notifications") }
    static var about: String { tr("Hakkında", "About") }
    static var privacyPolicy: String { tr("Gizlilik Politikası", "Privacy Policy") }
    static var termsOfService: String { tr("Kullanım Şartları", "Terms of Service") }
    static var version: String { tr("Versiyon", "Version") }
    static var contact: String { tr("İletişim", "Contact") }
    static var contactSupport: String { tr("Destek İletişim", "Contact Support") }
    static var shareApp: String { tr("Uygulamayı Paylaş", "Share App") }
    static var rateApp: String { tr("Uygulamayı Değerlendir", "Rate App") }
    
    // MARK: - Settings Sections
    static var storySettings: String { tr("Hikaye Ayarları", "Story Settings") }
    static var appSettings: String { tr("Uygulama Ayarları", "App Settings") }
    static var quickActions: String { tr("Hızlı İşlemler", "Quick Actions") }
    static var aboutAndSupport: String { tr("Hakkında ve Destek", "About & Support") }
    static var dangerZone: String { tr("Tehlike Bölgesi", "Danger Zone") }
    static var clearAllData: String { tr("Tüm Verileri Temizle", "Clear All Data") }
    static var clearDataWarning: String { tr("Bu işlem tüm hikayelerinizi ve ayarlarınızı silecektir. Bu işlem geri alınamaz.", "This will delete all your stories and settings. This action cannot be undone.") }
    static var clearData: String { tr("Verileri Temizle", "Clear Data") }
    
    // MARK: - Search
    static var searchPlaceholder: String { tr("Hikaye ara...", "Search stories...") }
    static var noResults: String { tr("Sonuç Bulunamadı", "No Results Found") }
    static var tryDifferentSearch: String { tr("Farklı bir arama terimi deneyin", "Try a different search term") }
    
    // MARK: - Errors & Alerts
    static var missingInfo: String { tr("Eksik Bilgi", "Missing Information") }
    static var fillAllFields: String { tr("Lütfen tüm gerekli alanları doldurun ve bir fotoğraf ekleyin.", "Please fill in all required fields and add a photo.") }
    static var photoRequired: String { tr("Fotoğraf Gerekli", "Photo Required") }
    static var selectPhotoFirst: String { tr("Lütfen bir fotoğraf seçin.", "Please select a photo.") }
    static var enterChildName: String { tr("Lütfen çocuğun ismini girin", "Please enter child's name") }
    static var premiumFeature: String { tr("Premium Özellik", "Premium Feature") }
    static var premiumMessage: String { tr("Hikaye paylaşma ve indirme özellikleri Premium üyelere özeldir. Premium'a geçerek sınırsız hikaye oluşturabilir ve tüm özelliklere erişebilirsiniz.", "Story sharing and download features are exclusive to Premium members. Upgrade to Premium to create unlimited stories and access all features.") }
    
    // MARK: - Categories
    static var categories: String { tr("Kategoriler", "Categories") }
    static var storyCategory: String { tr("Hikaye Kategorisi", "Story Category") }
    static var bedtime: String { tr("Uyku Vakti", "Bedtime") }
    static var adventure: String { tr("Macera", "Adventure") }
    static var educational: String { tr("Eğitici", "Educational") }
    static var moral: String { tr("Ahlaki", "Moral") }
    
    // MARK: - Misc
    static var menu: String { tr("Menü", "Menu") }
    static var quickSelect: String { tr("Hızlı Seçim", "Quick Select") }
    static var upgrade: String { tr("Yükselt", "Upgrade") }
    static var read: String { tr("Okundu", "Read") }
    static var stories: String { tr("Hikaye", "Stories") }
    static var storyOf: String { tr("'in Hikayesi", "'s Story") }
    static var cheaperThanCoffee: String { tr("Bir kahveden ucuz!", "Cheaper than a coffee!") }
    static var onlyPerDay: String { tr("Günde sadece 3₺", "Only $1/day") }
    static var buildReadingHabit: String { tr("Okuma alışkanlığı kazandırın!", "Build reading habit!") }
    static var makeChildHero: String { tr("Çocuğunuz Kahramanı Olsun", "Make Your Child the Hero") }
    static var howItWorks: String { tr("Nasıl Çalışır?", "How It Works?") }
    static var magicStories: String { tr("Sihirli Hikayeler", "Magic Stories") }
    static var unlimitedStoryWorld: String { tr("Sınırsız Hikaye Dünyası", "Unlimited Story World") }
    
    // MARK: - TextOnlyStoryView
    static var quickStoryCreate: String { tr("Hızlı Hikaye Oluştur", "Quick Story Create") }
    static var textOnlyStory: String { tr("Görselsiz, sadece metin tabanlı hikaye", "Text-only story without images") }
    static var basicInformation: String { tr("Temel Bilgiler", "Basic Information") }
    static var childNameLabel: String { tr("Çocuğun İsmi", "Child's Name") }
    static var enterNamePlaceholder: String { tr("İsim girin", "Enter name") }
    static var selectAdventureType: String { tr("Maceranın türünü seçin", "Select the type of adventure") }
    static var customStorySubject: String { tr("Özel Hikaye Konusu", "Custom Story Subject") }
    static var exampleDinosaurs: String { tr("Örn: Dinozorlarla macera", "e.g: Adventure with dinosaurs") }
    static var freeStoryReady: String { tr("Ücretsiz Hikaye Hazır!", "Free Story Ready!") }
    static var freeTextStoryEvery12Hours: String { tr("12 saatte 1 ücretsiz metin hikaye hakkınız var", "You have 1 free text story every 12 hours") }
    static var unlimitedStoriesJoinClub: String { tr("Sınırsız hikaye için kulübe katıl - Günde 3₺", "Join club for unlimited stories - $1/day") }
    static var missingInformation: String { tr("⚠️ Eksik Bilgi", "⚠️ Missing Information") }
    static var pleaseEnterChildName: String { tr("Lütfen çocuğun ismini girin.", "Please enter child's name.") }
    static var pleaseEnterChildNameShort: String { tr("Lütfen çocuğun ismini girin", "Please enter child's name") }
    static var premiumTheme: String { tr("👑 Premium Tema", "👑 Premium Theme") }
    static var waitingTime: String { tr("⏰ Bekleme Süresi", "⏰ Waiting Time") }
    static var nextFreeStoryIn: String { tr("Bir sonraki ücretsiz hikaye için", "Next free story in") }
    static var hoursWait: String { tr("saat beklemeniz gerekiyor.", "hours wait required.") }
    static var storyCreating: String { tr("Hikaye oluşturuluyor...", "Story creating...") }
    static var success: String { tr("✅ Başarılı", "✅ Success") }
    static var storyLoadingInLibrary: String { tr("Hikayeniz kütüphanede yükleniyor!", "Your story is loading in library!") }
    static var error: String { tr("❌ Hata", "❌ Error") }
    static var storyCreationError: String { tr("Hikaye oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.", "An error occurred while creating the story. Please try again.") }
    static var info: String { tr("Bilgi", "Info") }
    
    // MARK: - Story Status
    static func trialsLeft(_ count: Int) -> String {
        tr("\(count) deneme kaldı", "\(count) trials left")
    }
    static func imageStoriesLeft(_ count: Int) -> String {
        tr("\(count) görselli hikaye kaldı", "\(count) image stories left")
    }
    static func hoursUntilNext(_ hours: Int) -> String {
        tr("\(hours) saat sonra", "in \(hours) hours")
    }
    
    // MARK: - Additional UI Strings
    static var storyClubMember: String { tr("Hikaye Kulübü Üyesi", "Story Club Member") }
    static var newBadge: String { tr("YENİ", "NEW") }
    static var activeMembers: String { tr("Aktif üye", "Active member") }
    static var cancelMembership: String { tr("Üyeliği İptal Et", "Cancel Membership") }
    static var activateMembership: String { tr("Üyeliği Aktifleştir", "Activate Membership") }
    static var imageStory: String { tr("Görselli", "Illustrated") }
    static var illustrated: String { tr("Görselli", "Illustrated") }
    static var premiumBadge: String { tr("Premium", "Premium") }
    static var autoSave: String { tr("Otomatik Kaydet", "Auto Save") }
    static var highQualityImages: String { tr("Yüksek Kalite Görseller", "High Quality Images") }
    static var createNewStory: String { tr("Yeni Hikaye Oluştur", "Create New Story") }
    static var myStoryLibrary: String { tr("Hikaye Kütüphanem", "My Story Library") }
    static var congratulations: String { tr("🎉 Tebrikler!", "🎉 Congratulations!") }
    static var great: String { tr("Harika!", "Great!") }
    static var securePayment: String { tr("Güvenli Ödeme", "Secure Payment") }
    static var dayRefund: String { tr("7 Gün İade", "7 Day Refund") }
    static var kvkkCompliant: String { tr("KVKK Uyumlu", "GDPR Compliant") }
    static var happyFamilies: String { tr("mutlu aile", "happy families") }
    static var perMonthShort: String { tr("ay", "month") }
    static var remaining: String { tr("kalan", "remaining") }
    static var illustratedStoryShort: String { tr("görselli hikaye", "illustrated story") }
    static var textAndDaily: String { tr("Metin & Günlük", "Text & Daily") }
    static var yourRemainingQuota: String { tr("kalan hakkınız", "remaining quota") }
    static var readingMinutes: String { tr("dakika", "minutes") }
    static var ageYears: String { tr("yaş", "years") }
    static var readAction: String { tr("Oku", "Read") }
    static var noDailyStoriesYet: String { tr("Henüz Günlük Hikaye Yok", "No Daily Stories Yet") }
    static var dailyStoriesComingSoon: String { tr("Günlük hikayeler yakında eklenecek!", "Daily stories coming soon!") }
    static var getStartedNow: String { tr("Hemen Başla", "Get Started Now") }
    static var photo: String { tr("Fotoğraf", "Photo") }
    static var theme: String { tr("Tema", "Theme") }
    static var magic: String { tr("Sihir", "Magic") }
    static var unlockMagic: String { tr("Sihri aç, sınırsız hikaye!", "Unlock magic, unlimited stories!") }
    static var illustratedRemaining: String { tr("görselli kaldı", "illustrated remaining") }
    static var storiesRemaining: String { tr("hikaye hakkın var!", "stories remaining!") }
    static var text: String { tr("Metin", "Text") }
    static var description: String { tr("Açıklama", "Description") }
    static var personalized: String { tr("Kişiselleştirilmiş", "Personalized") }
    static var withChildPhoto: String { tr("Çocuğunuzun fotoğrafı ile", "With your child's photo") }
    static var variousThemes: String { tr("Çeşitli Temalar", "Various Themes") }
    static var adventureSpaceForest: String { tr("Macera, uzay, orman ve daha fazlası", "Adventure, space, forest and more") }
    static var ageAppropriate: String { tr("Yaş Uygun", "Age Appropriate") }
    static var ageRangeContent: String { tr("3-12 yaş arası içerik", "Content for ages 3-12") }
    static var magicIllustrations: String { tr("Sihirli Görseller", "Magic Illustrations") }
    static var specialIllustrations: String { tr("Her sayfa için özel illüstrasyonlar", "Special illustrations for each page") }
    static var madeWithLove: String { tr("❤️ ile yapıldı", "Made with ❤️") }
    static var appLanguageAndStory: String { tr("Uygulama dili ve hikaye dili", "App language and story language") }
    static var shareAppMessage: String { tr("MagicPaper ile çocuğunuz için kişiselleştirilmiş hikayeler oluşturun! 📚✨", "Create personalized stories for your child with MagicPaper! 📚✨") }
    static var aboutDescription: String { tr("MagicPaper, çocuğunuz için kişiselleştirilmiş hikayeler oluşturmanıza yardımcı olur. Her hikaye, çocuğunuzun fotoğrafı ve seçtiğiniz tema ile özel olarak hazırlanır.", "MagicPaper helps you create personalized stories for your child. Each story is specially prepared with your child's photo and the theme you choose.") }
    
    // MARK: - Profile Management
    static var profiles: String { tr("Profiller", "Profiles") }
    static var selectProfile: String { tr("Profil Seç", "Select Profile") }
    static var addProfile: String { tr("Profil Ekle", "Add Profile") }
    static var addNewProfile: String { tr("Yeni Profil Ekle", "Add New Profile") }
    static var switchProfile: String { tr("Profil Değiştir", "Switch Profile") }
    static var deleteProfile: String { tr("Profili Sil", "Delete Profile") }
    static var profileType: String { tr("Profil Tipi", "Profile Type") }
    static var childProfile: String { tr("Çocuk Profili", "Child Profile") }
    static var parentProfile: String { tr("Ebeveyn Profili", "Parent Profile") }
    static var childMode: String { tr("Çocuk Modu", "Child Mode") }
    static var parentMode: String { tr("Ebeveyn Modu", "Parent Mode") }
    static var childLockActive: String { tr("Çocuk Kilidi Aktif", "Child Lock Active") }
    static var childLockDesc: String { tr("Ayarlar ve satın alma işlemleri kilitli", "Settings and purchases are locked") }
    static var switchToParent: String { tr("Ebeveyn Moduna Geç", "Switch to Parent Mode") }
    static var switchToChild: String { tr("Çocuk Moduna Geç", "Switch to Child Mode") }
    static var whoIsUsing: String { tr("Kim kullanıyor?", "Who is using?") }
    static var selectOrCreateProfile: String { tr("Profil seçin veya yeni profil oluşturun", "Select a profile or create a new one") }
    static var profileName: String { tr("Profil Adı", "Profile Name") }
    static var enterProfileName: String { tr("Profil adını girin", "Enter profile name") }
    static var profileAge: String { tr("Yaş", "Age") }
    static var selectProfileType: String { tr("Profil tipini seçin", "Select profile type") }
    static var forChildren: String { tr("Çocuklar için", "For children") }
    static var forParents: String { tr("Ebeveynler için", "For parents") }
    static var restrictedAccess: String { tr("Kısıtlı erişim", "Restricted access") }
    static var fullAccess: String { tr("Tam erişim", "Full access") }
    static var deleteProfileConfirm: String { tr("Bu profili silmek istediğinizden emin misiniz?", "Are you sure you want to delete this profile?") }
    static var cannotDeleteLastProfile: String { tr("Son profil silinemez", "Cannot delete last profile") }
    static var profileCreated: String { tr("Profil oluşturuldu", "Profile created") }
    static var profileUpdated: String { tr("Profil güncellendi", "Profile updated") }
    static var profileDeleted: String { tr("Profil silindi", "Profile deleted") }
    
    // MARK: - Legal & Compliance (Apple Guideline 3.1.2)
    static var termsOfUse: String { tr("Kullanım Şartları", "Terms of Use") }
    // privacyPolicy already defined in Settings section (line 190)
    static var termsAndPrivacy: String { tr("Şartlar ve Gizlilik", "Terms & Privacy") }
}
