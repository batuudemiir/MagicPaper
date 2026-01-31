import Foundation

// MARK: - Additional Localization Keys

extension LocalizedKey {
    // Onboarding
    static let skip = LocalizedKey.custom(tr: "Atla", en: "Skip")
    static let back = LocalizedKey.custom(tr: "Geri", en: "Back")
    static let next_button = LocalizedKey.custom(tr: "İleri", en: "Next")
    static let getStarted = LocalizedKey.custom(tr: "Başla", en: "Get Started")
    
    // Onboarding Pages
    static let onboardingTitle1 = LocalizedKey.custom(tr: "Fotoğraf Ekle", en: "Add Photo")
    static let onboardingDesc1 = LocalizedKey.custom(tr: "Çocuğunuzun fotoğrafını yükleyin ve hikayenin kahramanı olsun", en: "Upload your child's photo and make them the hero of the story")
    static let onboardingTitle2 = LocalizedKey.custom(tr: "Tema Seç", en: "Choose Theme")
    static let onboardingDesc2 = LocalizedKey.custom(tr: "Uzay, orman, denizaltı... Hayal gücünüzü serbest bırakın", en: "Space, forest, underwater... Let your imagination run wild")
    static let onboardingTitle3 = LocalizedKey.custom(tr: "Sihir Başlasın", en: "Let the Magic Begin")
    static let onboardingDesc3 = LocalizedKey.custom(tr: "Yapay zeka ile kişiselleştirilmiş, benzersiz hikayeler oluşturun", en: "Create personalized, unique stories with AI")
    
    // Profile Setup
    static let welcome_title = LocalizedKey.custom(tr: "Hoş Geldiniz!", en: "Welcome!")
    static let createProfile = LocalizedKey.custom(tr: "Başlamak için profilinizi oluşturun", en: "Create your profile to get started")
    static let profilePhoto = LocalizedKey.custom(tr: "Profil Fotoğrafı", en: "Profile Photo")
    static let yourName = LocalizedKey.custom(tr: "Adınız", en: "Your Name")
    static let enterName = LocalizedKey.custom(tr: "Adınızı girin", en: "Enter your name")
    static let start = LocalizedKey.custom(tr: "Başla", en: "Start")
    static let save = LocalizedKey.custom(tr: "Kaydet", en: "Save")
    static let close_button = LocalizedKey.custom(tr: "Kapat", en: "Close")
    static let editProfile = LocalizedKey.custom(tr: "Profili Düzenle", en: "Edit Profile")
    
    // Story Viewer
    static let page = LocalizedKey.custom(tr: "Sayfa", en: "Page")
    static let previous = LocalizedKey.custom(tr: "Önceki", en: "Previous")
    static let next_page = LocalizedKey.custom(tr: "Sonraki", en: "Next")
    static let premiumFeature = LocalizedKey.custom(tr: "Premium Özellik", en: "Premium Feature")
    static let premiumMessage = LocalizedKey.custom(tr: "Hikaye paylaşma ve indirme özellikleri Premium üyelere özeldir. Premium'a geçerek sınırsız hikaye oluşturabilir ve tüm özelliklere erişebilirsiniz.", en: "Story sharing and download features are exclusive to Premium members. Upgrade to Premium to create unlimited stories and access all features.")
    static let readingTip = LocalizedKey.custom(tr: "Okuma İpucu", en: "Reading Tip")
    static let readSlowly = LocalizedKey.custom(tr: "Yavaş yavaş okuyun ve hayal edin!", en: "Read slowly and imagine!")
    static let highContrastActive = LocalizedKey.custom(tr: "Yüksek Kontrast Aktif", en: "High Contrast Active")
    static let colorsOptimized = LocalizedKey.custom(tr: "Daha iyi okunabilirlik için renkler optimize edildi", en: "Colors optimized for better readability")
    static let textSize = LocalizedKey.custom(tr: "Yazı Boyutu", en: "Text Size")
    static let adjustTextSize = LocalizedKey.custom(tr: "Hikaye metninin boyutunu ayarlayın", en: "Adjust story text size")
    static let readingTheme = LocalizedKey.custom(tr: "Okuma Teması", en: "Reading Theme")
    static let lineSpacing = LocalizedKey.custom(tr: "Satır Aralığı", en: "Line Spacing")
    static let adjustLineSpacing = LocalizedKey.custom(tr: "Satırlar arasındaki boşluğu ayarlayın", en: "Adjust spacing between lines")
    static let autoPlay = LocalizedKey.custom(tr: "Otomatik Oynat", en: "Auto Play")
    static let autoPlayDesc = LocalizedKey.custom(tr: "Her 8 saniyede bir sayfa", en: "One page every 8 seconds")
    static let autoPlayFooter = LocalizedKey.custom(tr: "Hikaye sayfaları otomatik olarak ilerler", en: "Story pages advance automatically")
    static let preview = LocalizedKey.custom(tr: "Önizleme", en: "Preview")
    static let highContrastOptimized = LocalizedKey.custom(tr: "✓ Yüksek kontrast ile optimize edildi", en: "✓ Optimized with high contrast")
    static let previewText1 = LocalizedKey.custom(tr: "Bir zamanlar uzak bir diyarda,", en: "Once upon a time in a faraway land,")
    static let previewText2 = LocalizedKey.custom(tr: "küçük bir kahraman yaşardı.", en: "there lived a little hero.")
    static let previewText3 = LocalizedKey.custom(tr: "Maceraları efsanelere konu oldu.", en: "Their adventures became legendary.")
    
    // Text Story Library
    static let textStories = LocalizedKey.custom(tr: "Metin Hikayeler", en: "Text Stories")
    static let noTextStories = LocalizedKey.custom(tr: "Henüz Metin Hikaye Yok", en: "No Text Stories Yet")
    static let createFirstTextStory = LocalizedKey.custom(tr: "İlk metin hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın", en: "Create your first text story and\nenjoy reading with your child")
    static let textStoryLibrary = LocalizedKey.custom(tr: "Metin Hikaye Kütüphanesi", en: "Text Story Library")
    
    // Content View
    static let home = LocalizedKey.custom(tr: "Ana Sayfa", en: "Home")
    static let createStoryType = LocalizedKey.custom(tr: "Yeni Hikaye", en: "New Story")
    static let newStory = LocalizedKey.custom(tr: "Yeni Hikaye", en: "New Story")
    static let whichStoryType = LocalizedKey.custom(tr: "Hangi tür hikaye oluşturmak istersiniz?", en: "Which type of story would you like to create?")
    static let illustratedStory = LocalizedKey.custom(tr: "Görselli Hikaye", en: "Illustrated Story")
    static let illustratedDesc = LocalizedKey.custom(tr: "Fotoğrafla özel hikaye", en: "Custom story with photo")
    static let textStoryShort = LocalizedKey.custom(tr: "Metin Hikaye", en: "Text Story")
    static let textStoryDesc = LocalizedKey.custom(tr: "Hayal gücünü harekete geçir", en: "Spark imagination")
    static let dailyStoryShort = LocalizedKey.custom(tr: "Günlük Hikaye", en: "Daily Story")
    static let dailyStoryDesc = LocalizedKey.custom(tr: "Kategori bazlı hikayeler", en: "Category-based stories")
    static let popular = LocalizedKey.custom(tr: "Popüler", en: "Popular")
    
    // Daily Story Creation
    static let createDailyStoryTitle = LocalizedKey.custom(tr: "Hikaye Oluştur", en: "Create Story")
    static let childInfo = LocalizedKey.custom(tr: "Çocuk Bilgileri", en: "Child Information")
    static let childNameLabel = LocalizedKey.custom(tr: "Çocuğun Adı", en: "Child's Name")
    static let childAgeLabel = LocalizedKey.custom(tr: "Yaş", en: "Age")
    static let childGenderLabel = LocalizedKey.custom(tr: "Cinsiyet", en: "Gender")
    static let male = LocalizedKey.custom(tr: "Erkek", en: "Male")
    static let female = LocalizedKey.custom(tr: "Kız", en: "Female")
    static let storyCategory = LocalizedKey.custom(tr: "Hikaye Kategorisi", en: "Story Category")
    static let bedtime = LocalizedKey.custom(tr: "Uyku Vakti", en: "Bedtime")
    static let adventure = LocalizedKey.custom(tr: "Macera", en: "Adventure")
    static let educational = LocalizedKey.custom(tr: "Eğitici", en: "Educational")
    static let moral = LocalizedKey.custom(tr: "Ahlaki", en: "Moral")
    static let generating_story = LocalizedKey.custom(tr: "✨ Hikaye Oluşturuluyor", en: "✨ Story Generating")
    static let storyBeingCreated = LocalizedKey.custom(tr: "Hikayeniz oluşturuluyor! Metin Hikayeler kütüphanesinden ilerlemeyi takip edebilirsiniz.", en: "Your story is being created! You can track progress from the Text Stories library.")
    static let trackProgress = LocalizedKey.custom(tr: "İlerlemeyi takip edebilirsiniz", en: "You can track progress")
    static let okay = LocalizedKey.custom(tr: "Tamam", en: "OK")
    
    // Search and Filter
    static let searchPlaceholder = LocalizedKey.custom(tr: "Hikaye ara...", en: "Search stories...")
    static let noResults = LocalizedKey.custom(tr: "Sonuç Bulunamadı", en: "No Results Found")
    static let tryDifferentSearch = LocalizedKey.custom(tr: "Farklı bir arama terimi deneyin", en: "Try a different search term")
    static let storyOf = LocalizedKey.custom(tr: "'in Hikayesi", en: "'s Story")
    
    // Helper function for custom keys
    static func custom(tr: String, en: String) -> LocalizedKey {
        // This is a workaround - we'll add these to the main enum
        return .magicPaper // placeholder
    }
}
