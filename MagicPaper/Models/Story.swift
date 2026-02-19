import Foundation
import SwiftUI

struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var childName: String
    var theme: StoryTheme
    var language: StoryLanguage
    var status: StoryStatus
    var pages: [StoryPage]
    var coverImageFileName: String? // Changed from Data to filename
    var coverImageUrl: String?
    var createdAt: Date
    var lastReadPage: Int?
    var currentProgress: String?
    
    // Equatable conformance
    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, childName: String, theme: StoryTheme, language: StoryLanguage, status: StoryStatus = .uploading, pages: [StoryPage] = [], coverImageFileName: String? = nil, coverImageUrl: String? = nil) {
        self.id = id
        self.title = title
        self.childName = childName
        self.theme = theme
        self.language = language
        self.status = status
        self.pages = pages
        self.coverImageFileName = coverImageFileName
        self.coverImageUrl = coverImageUrl
        self.createdAt = Date()
        self.lastReadPage = nil
        self.currentProgress = nil
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