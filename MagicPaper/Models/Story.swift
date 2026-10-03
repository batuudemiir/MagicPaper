import Foundation
import SwiftUI

struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    /// The child's name, for display and for personalising the text.
    ///
    /// **Not identity.** Use `childProfileID` to decide whose story this is:
    /// a name changes, and two children can share one.
    var childName: String
    /// Which profile this story belongs to.
    ///
    /// Optional because stories written before this field existed decode with
    /// `nil`, and are matched by name instead (see `belongs(to:)`). New stories
    /// always carry it.
    var childProfileID: UUID?
    var theme: StoryTheme
    var language: StoryLanguage
    var status: StoryStatus
    var pages: [StoryPage]
    var coverImageFileName: String? // Changed from Data to filename
    var coverImageUrl: String?
    var createdAt: Date
    var lastReadPage: Int?
    /// Bu masal en son ne zaman okundu.
    ///
    /// `lastReadPage` "nerede kalındı"yı söylüyordu, "ne zaman"ı hiçbir şey
    /// söylemiyordu — ve ana sayfadaki "kaldığın yer" kartı tam olarak bu
    /// soruyu sormak zorunda. Bu alan olmadan en iyi tahmin masalın
    /// **oluşturulma** sırasıydı: dün yaratılıp bir sayfa okunup bırakılan
    /// masal, bu akşam okunan iki haftalık masalın önüne geçiyordu.
    ///
    /// Bu alandan önce okunmuş masallarda `nil` — bir defalık bir boşluk,
    /// çocuk o masalı bir kez daha açtığında kapanır.
    var lastReadAt: Date?
    var currentProgress: String?
    /// Where an engine-built story came from.
    ///
    /// Nil for stories the old pipeline made. Carrying it is what makes
    /// "the same story again" mean something: every input that determined the
    /// text is here, so a regeneration can be checked rather than hoped for.
    /// It is also the only thing that can answer which ideas and companions
    /// people actually choose, and it answers with ids rather than with
    /// Turkish display strings.
    var origin: StoryOrigin?
    /// Görselli kitabın anlık görüntüsü (B2): kaydedildiği andaki avatar ve
    /// kütüphane sürümleri. `nil` = metin kitabı, bugünkü her masal gibi.
    /// Çözücüsü atmaz; bkz. `StoryIllustration`.
    var illustration: StoryIllustration?

    // Equatable conformance
    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, childName: String, childProfileID: UUID? = nil, theme: StoryTheme, language: StoryLanguage, status: StoryStatus = .uploading, pages: [StoryPage] = [], coverImageFileName: String? = nil, coverImageUrl: String? = nil, origin: StoryOrigin? = nil) {
        self.id = id
        self.title = title
        self.childName = childName
        self.childProfileID = childProfileID
        self.theme = theme
        self.language = language
        self.status = status
        self.pages = pages
        self.coverImageFileName = coverImageFileName
        self.coverImageUrl = coverImageUrl
        self.createdAt = Date()
        self.lastReadPage = nil
        self.lastReadAt = nil
        self.currentProgress = nil
        self.origin = origin
    }
}

/// Everything that decided a story's text, kept with the story.
struct StoryOrigin: Codable, Equatable {
    /// The seed the story was built from. Same seed and same inputs, same book.
    var seed: String
    /// The card the child chose. Nil means they chose "surprise me".
    var storyIdeaID: String?
    var blueprintID: String
    var settingID: String
    var companionID: String
    var discoveryID: String
    /// Stable over the inputs that determine the text, so two builds can be
    /// compared without diffing prose.
    var fingerprint: String
    /// Which catalog produced it. Content grows; without this, "the same seed"
    /// stops meaning the same story and nobody can tell why.
    var catalogVersion: String
    /// The cover this story was given, decided once from where it is set.
    ///
    /// Stored rather than derived on demand: a cover is a property of the book,
    /// not of whatever the catalog happens to hold when a list is drawn. Nil for
    /// stories written before covers were tied to the setting.
    var worldID: String?
    /// The parent's intent the story was built for (`StoryMode.rawValue`).
    ///
    /// Always one of the three modes, never "surprise": a surprise is resolved
    /// to a mode before composing, and `selectionStrategy` records that it
    /// was one. Nil for stories written before modes existed.
    var modeID: String?
    /// `StorySelectionStrategy.rawValue`: whether the parent picked the mode
    /// or asked MagicPaper to. Nil for stories written before modes existed.
    var selectionStrategy: String?
    /// The age band the story was written for (`"5-6"`). Nil for older stories.
    var ageBand: String?
}

extension Story {
    /// Whether this story belongs to a profile.
    ///
    /// Stated once because it was previously written out at six call sites, in
    /// two different ways: four compared names, and two also admitted any story
    /// whose name was empty — which quietly showed one child's story in every
    /// other child's library.
    ///
    /// Prefers the id. Falls back to the name only for stories saved before the
    /// id existed, and never treats an empty name as a match.
    func belongs(to profile: UserProfile) -> Bool {
        if let childProfileID { return childProfileID == profile.id }
        return !childName.isEmpty && childName == profile.name
    }

    /// The same test against an optional profile, for the many call sites that
    /// read `currentProfile`.
    func belongs(to profile: UserProfile?) -> Bool {
        guard let profile else { return false }
        return belongs(to: profile)
    }

    /// Whether deleting `profile` should delete this story too.
    ///
    /// Stricter than `belongs(to:)`, because this answer destroys data. A story
    /// saved before `childProfileID` existed is matched by name, and a name is
    /// not unique: if any other profile shares it, the story could be that
    /// child's, so it is kept. Showing a story on the wrong shelf is a display
    /// bug; deleting it from the wrong child is unrecoverable.
    func isSolelyOwned(by profile: UserProfile, among profiles: [UserProfile]) -> Bool {
        guard belongs(to: profile) else { return false }
        if childProfileID != nil { return true }
        return !profiles.contains { $0.id != profile.id && $0.name == childName }
    }
}

enum StoryStatus: String, Codable {
    case uploading = "uploading"
    case writingStory = "writingStory"
    case generatingImages = "generatingImages"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .uploading: return isEnglish ? "Uploading photo..." : "Fotoğraf yükleniyor..."
        case .writingStory: return isEnglish ? "Writing story..." : "Hikaye yazılıyor..."
        case .generatingImages: return isEnglish ? "Generating illustrations..." : "İllüstrasyonlar oluşturuluyor..."
        case .completed: return isEnglish ? "Completed" : "Tamamlandı"
        case .failed: return isEnglish ? "Error occurred" : "Hata oluştu"
        }
    }
    
    var icon: String {
        switch self {
        case .uploading: return "arrow.up.circle"
        case .writingStory: return "pencil.circle"
        case .generatingImages: return "paintbrush.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

struct StoryPage: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var text: String
    var imagePrompt: String
    var imageFileName: String? // Changed from Data to filename
    var imageUrl: String?
    /// Sayfanın hazır sahnesi (B2). `nil` = metin sayfası.
    var scene: ScenePlate?

    // Equatable conformance
    static func == (lhs: StoryPage, rhs: StoryPage) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, text: String, imagePrompt: String, imageFileName: String? = nil, imageUrl: String? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.imagePrompt = imagePrompt
        self.imageFileName = imageFileName
        self.imageUrl = imageUrl
    }
}

enum StoryTheme: String, CaseIterable, Codable {
    case fantasy = "fantasy"
    case space = "space"
    case jungle = "jungle"
    case hero = "hero"
    case underwater = "underwater"
    case custom = "custom"
    
    var displayName: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .fantasy: return isEnglish ? "Magical Kingdom" : "Sihirli Krallık"
        case .space: return isEnglish ? "Space Adventure" : "Uzay Macerası"
        case .jungle: return isEnglish ? "Jungle Adventure" : "Orman Macerası"
        case .hero: return isEnglish ? "Superhero" : "Süper Kahraman"
        case .underwater: return isEnglish ? "Ocean Secrets" : "Okyanus Sırları"
        case .custom: return isEnglish ? "Custom Adventure" : "Özel Macera"
        }
    }
    
    // English theme names for API
    var englishName: String {
        switch self {
        case .fantasy: return "Magical Kingdom"
        case .space: return "Space Adventure"
        case .jungle: return "Jungle Adventure"
        case .hero: return "Superhero"
        case .underwater: return "Ocean Secrets"
        case .custom: return "Custom Adventure"
        }
    }
    
    var emoji: String {
        switch self {
        case .fantasy: return "🏰"
        case .space: return "🚀"
        case .jungle: return "🦁"
        case .hero: return "⚡"
        case .underwater: return "🐬"
        case .custom: return "✨"
        }
    }
    
    var color: Color {
        switch self {
        case .fantasy: return .purple
        case .space: return .blue
        case .jungle: return .green
        case .hero: return .orange
        case .underwater: return .cyan
        case .custom: return .pink
        }
    }
    
    var description: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .fantasy: return isEnglish ? "Explore magical lands and meet legendary creatures" : "Sihirli diyarları keşfedin ve efsanevi yaratıklarla tanışın"
        case .space: return isEnglish ? "Explore the cosmos and discover new worlds" : "Kozmosu keşfedin ve yeni dünyalar keşfedin"
        case .jungle: return isEnglish ? "Explore wild forests and meet amazing animals" : "Vahşi ormanları keşfedin ve harika hayvanlarla tanışın"
        case .hero: return isEnglish ? "Become a superhero and save the world" : "Süper kahraman olun ve dünyayı kurtarın"
        case .underwater: return isEnglish ? "Dive deep and discover underwater mysteries" : "Derinlere dalın ve sualtı gizemlerini keşfedin"
        case .custom: return isEnglish ? "Create your own unique adventure" : "Kendi benzersiz maceranızı yaratın"
        }
    }
    
    // Premium tema kontrolü
    var isPremium: Bool {
        switch self {
        case .jungle, .hero, .underwater, .custom:
            return true
        case .fantasy, .space:
            return false
        }
    }
    
    // Ücretsiz temalar
    static var freeThemes: [StoryTheme] {
        return [.fantasy, .space]
    }
    
    // Premium temalar
    static var premiumThemes: [StoryTheme] {
        return [.jungle, .hero, .underwater, .custom]
    }
}

enum StoryLanguage: String, CaseIterable, Codable {
    case turkish = "tr"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case russian = "ru"
    case arabic = "ar"
    
    var displayName: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .turkish: return isEnglish ? "Turkish" : "Türkçe"
        case .english: return isEnglish ? "English" : "İngilizce"
        case .spanish: return isEnglish ? "Spanish" : "İspanyolca"
        case .french: return isEnglish ? "French" : "Fransızca"
        case .german: return isEnglish ? "German" : "Almanca"
        case .italian: return isEnglish ? "Italian" : "İtalyanca"
        case .russian: return isEnglish ? "Russian" : "Rusça"
        case .arabic: return isEnglish ? "Arabic" : "Arapça"
        }
    }
    
    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .russian: return "🇷🇺"
        case .arabic: return "🇸🇦"
        }
    }
    
    var isRTL: Bool {
        return self == .arabic
    }
}

enum Gender: String, CaseIterable, Codable {
    case boy = "boy"
    case girl = "girl"
    case other = "other"
    
    var displayName: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .boy: return isEnglish ? "Boy" : "Erkek"
        case .girl: return isEnglish ? "Girl" : "Kız"
        case .other: return isEnglish ? "Other" : "Diğer"
        }
    }
    
    var icon: String {
        switch self {
        case .boy: return "figure.child"
        case .girl: return "figure.child"
        case .other: return "person"
        }
    }
}