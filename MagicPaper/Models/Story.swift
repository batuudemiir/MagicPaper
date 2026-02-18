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
        switch self {
        case .uploading: return "Fotoğraf yükleniyor..."
        case .writingStory: return "Hikaye yazılıyor..."
        case .generatingImages: return "İllüstrasyonlar oluşturuluyor..."
        case .completed: return "Tamamlandı"
        case .failed: return "Hata oluştu"
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
        switch self {
        case .fantasy: return "Sihirli Krallık"
        case .space: return "Uzay Macerası"
        case .jungle: return "Orman Macerası"
        case .hero: return "Süper Kahraman"
        case .underwater: return "Okyanus Sırları"
        case .custom: return "Özel Macera"
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
        switch self {
        case .fantasy: return "Sihirli diyarları keşfedin ve efsanevi yaratıklarla tanışın"
        case .space: return "Kozmosu keşfedin ve yeni dünyalar keşfedin"
        case .jungle: return "Vahşi ormanları keşfedin ve harika hayvanlarla tanışın"
        case .hero: return "Süper kahraman olun ve dünyayı kurtarın"
        case .underwater: return "Derinlere dalın ve sualtı gizemlerini keşfedin"
        case .custom: return "Kendi benzersiz maceranızı yaratın"
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
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "İngilizce"
        case .spanish: return "İspanyolca"
        case .french: return "Fransızca"
        case .german: return "Almanca"
        case .italian: return "İtalyanca"
        case .russian: return "Rusça"
        case .arabic: return "Arapça"
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
        switch self {
        case .boy: return "Erkek"
        case .girl: return "Kız"
        case .other: return "Diğer"
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