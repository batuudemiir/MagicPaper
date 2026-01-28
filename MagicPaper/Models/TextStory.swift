import Foundation
import SwiftUI

// Text-only hikaye modeli (görsel olmadan)
struct TextStory: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var childName: String
    var gender: Gender
    var theme: StoryTheme
    var language: StoryLanguage
    var status: TextStoryStatus
    var content: String // Tam hikaye metni
    var createdAt: Date
    
    static func == (lhs: TextStory, rhs: TextStory) -> Bool {
        lhs.id == rhs.id
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        childName: String,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        status: TextStoryStatus = .generating,
        content: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.childName = childName
        self.gender = gender
        self.theme = theme
        self.language = language
        self.status = status
        self.content = content
        self.createdAt = createdAt
    }
}

enum TextStoryStatus: String, Codable {
    case generating = "generating"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .generating: return "Hikaye yazılıyor..."
        case .completed: return "Tamamlandı"
        case .failed: return "Hata oluştu"
        }
    }
    
    var icon: String {
        switch self {
        case .generating: return "pencil.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}
