import Foundation
import SwiftUI

/// Metin bazlı hikaye modeli (görselsiz)
struct TextStory: Identifiable, Codable {
    let id: UUID
    var title: String
    var childName: String
    var gender: Gender
    var theme: StoryTheme
    var language: StoryLanguage
    var content: String
    var status: TextStoryStatus
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        childName: String,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        content: String = "",
        status: TextStoryStatus = .generating
    ) {
        self.id = id
        self.title = title
        self.childName = childName
        self.gender = gender
        self.theme = theme
        self.language = language
        self.content = content
        self.status = status
        self.createdAt = Date()
    }
}

enum TextStoryStatus: String, Codable {
    case generating = "generating"
    case completed = "completed"
    case failed = "failed"
}
