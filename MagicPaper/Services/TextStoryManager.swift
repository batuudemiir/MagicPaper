import Foundation
import SwiftUI

@MainActor
class TextStoryManager: ObservableObject {
    static let shared = TextStoryManager()
    
    @Published var textStories: [TextStory] = []
    @Published var isGenerating = false
    
    private let userDefaultsKey = "textStories"
    private let aiService = AIService.shared
    
    private init() {
        loadStories()
    }
    
    // MARK: - Story Management
    
    func createTextStory(
        childName: String,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        customTitle: String? = nil
    ) async -> TextStory? {
        
        isGenerating = true
        
        // Hikaye başlığını oluştur
        let storyTitle = customTitle ?? "\(childName) ve \(theme.displayName)"
        
        // Yeni hikaye oluştur
        let story = TextStory(
            title: storyTitle,
            childName: childName,
            gender: gender,
            theme: theme,
            language: language,
            status: .generating
        )
        
        // Listeye ekle
        textStories.insert(story, at: 0)
        saveStories()
        
        // Hikaye içeriğini oluştur
        let success = await generateStoryContent(for: story.id)
        
        isGenerating = false
        
        if success {
            return textStories.first(where: { $0.id == story.id })
        } else {
            return nil
        }
    }
    
    private func generateStoryContent(for storyId: UUID) async -> Bool {
        guard let index = textStories.firstIndex(where: { $0.id == storyId }) else {
            return false
        }
        
        let story = textStories[index]
        
        // Gemini ile hikaye oluştur
        do {
            let storyResponse = try await aiService.generateTextOnlyStory(
                childName: story.childName,
                gender: story.gender,
                theme: story.theme.displayName,
                language: story.language.rawValue,
                customTitle: story.theme == .custom ? story.title : nil
            )
            
            // Sayfaları birleştir
            let fullContent = storyResponse.pages.map { page in
                "\(page.title)\n\n\(page.text)"
            }.joined(separator: "\n\n---\n\n")
            
            // Hikayeyi güncelle
            textStories[index].content = fullContent
            textStories[index].status = .completed
            saveStories()
            
            print("✅ Text hikaye başarıyla oluşturuldu: \(story.title)")
            return true
            
        } catch {
            print("❌ Text hikaye oluşturma hatası: \(error.localizedDescription)")
            textStories[index].status = .failed
            saveStories()
            return false
        }
    }
    
    // MARK: - Storage
    
    func saveStories() {
        if let encoded = try? JSONEncoder().encode(textStories) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 \(textStories.count) text hikaye kaydedildi")
        }
    }
    
    func loadStories() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TextStory].self, from: data) {
            textStories = decoded
            print("📖 \(textStories.count) text hikaye yüklendi")
        }
    }
    
    func deleteStory(_ story: TextStory) {
        textStories.removeAll { $0.id == story.id }
        saveStories()
        print("🗑️ Text hikaye silindi: \(story.title)")
    }
    
    func deleteAllStories() {
        textStories.removeAll()
        saveStories()
        print("🗑️ Tüm text hikayeler silindi")
    }
}
