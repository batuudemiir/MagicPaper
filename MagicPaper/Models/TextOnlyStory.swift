import Foundation
import SwiftUI

struct TextOnlyStory: Identifiable, Codable {
    let id: UUID
    var title: String
    var childName: String
    var gender: Gender
    var theme: StoryTheme
    var language: StoryLanguage
    var pages: [TextOnlyStoryPage]
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, childName: String, gender: Gender, theme: StoryTheme, language: StoryLanguage, pages: [TextOnlyStoryPage]) {
        self.id = id
        self.title = title
        self.childName = childName
        self.gender = gender
        self.theme = theme
        self.language = language
        self.pages = pages
        self.createdAt = Date()
    }
}

struct TextOnlyStoryPage: Identifiable, Codable {
    let id: UUID
    var title: String
    var text: String
    
    init(id: UUID = UUID(), title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}
