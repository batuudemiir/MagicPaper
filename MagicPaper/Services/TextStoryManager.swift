import Foundation
import OSLog
import SwiftUI

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "TextStoryManager")

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
            // Kütüphaneye de ekle (Story modeline dönüştür)
            if let textStory = textStories.first(where: { $0.id == story.id }) {
                addToLibrary(textStory: textStory)
            }
            return textStories.first(where: { $0.id == story.id })
        } else {
            return nil
        }
    }
    
    // Kategori bazlı metin hikaye oluştur (Günlük Hikayeler için)
    func createCategoryTextStory(
        childName: String,
        age: Int,
        gender: Gender,
        category: String,
        language: StoryLanguage
    ) async -> TextStory? {
        
        isGenerating = true
        
        // Kategori adını Türkçe'ye çevir
        let categoryName = getCategoryDisplayName(category)
        let storyTitle = "\(childName) ve \(categoryName)"
        
        // Kategoriye uygun tema seç
        let theme = getThemeForCategory(category)
        
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
        
        // Kategori bazlı hikaye içeriğini oluştur
        let success = await generateCategoryStoryContent(for: story.id, age: age, category: category)
        
        isGenerating = false
        
        if success {
            // Kütüphaneye de ekle (Story modeline dönüştür)
            if let textStory = textStories.first(where: { $0.id == story.id }) {
                addToLibrary(textStory: textStory)
            }
            return textStories.first(where: { $0.id == story.id })
        } else {
            return nil
        }
    }
    
    // Metin hikayeyi kütüphaneye ekle
    private func addToLibrary(textStory: TextStory) {
        // TextStory'yi Story modeline dönüştür
        let storyPages = textStory.content.components(separatedBy: "\n\n---\n\n").enumerated().map { index, section in
            let parts = section.components(separatedBy: "\n\n")
            let title = parts.first ?? "Sayfa \(index + 1)"
            let text = parts.dropFirst().joined(separator: "\n\n")
            return StoryPage(
                title: title,
                text: text,
                imagePrompt: "",
                imageFileName: nil,
                imageUrl: nil
            )
        }
        
        let libraryStory = Story(
            id: textStory.id,
            title: textStory.title,
            childName: textStory.childName,
            theme: textStory.theme,
            language: textStory.language,
            status: textStory.status == .completed ? .completed : .failed,
            pages: storyPages
        )
        
        // StoryGenerationManager'a ekle
        StoryGenerationManager.shared.addStoryToLibrary(libraryStory)
    }
    
    private func generateStoryContent(for storyId: UUID) async -> Bool {
        guard let index = textStories.firstIndex(where: { $0.id == storyId }) else {
            logger.error("❌ Hikaye bulunamadı: \(storyId)")
            return false
        }
        
        let story = textStories[index]
        
        logger.debug("📝 Hikaye oluşturuluyor...")
        logger.debug("   - ID: \(story.id)")
        logger.debug("   - Tema: \(story.theme.rawValue)")
        logger.debug("   - Dil: \(story.language.rawValue)")
        
        // Gemini ile hikaye oluştur
        do {
            // Dile göre tema adını seç
            let themeName = story.language == .turkish ? story.theme.displayName : story.theme.englishName
            logger.debug("   - Tema Adı (API): \(themeName)")
            
            let storyResponse = try await aiService.generateTextOnlyStory(
                childName: story.childName,
                gender: story.gender,
                theme: themeName,
                language: story.language.rawValue,
                customTitle: story.theme == .custom ? story.title : nil
            )
            
            logger.debug("✅ API yanıtı alındı")
            logger.debug("   - Başlık: \(storyResponse.title)")
            logger.debug("   - Sayfa sayısı: \(storyResponse.pages.count)")
            
            // Sayfaları birleştir
            let fullContent = storyResponse.pages.map { page in
                "\(page.title)\n\n\(page.text)"
            }.joined(separator: "\n\n---\n\n")
            
            // Hikayeyi güncelle
            textStories[index].content = fullContent
            textStories[index].status = .completed
            saveStories()
            
            logger.debug("✅ Text hikaye başarıyla oluşturuldu")
            return true
            
        } catch let error as URLError {
            logger.error("❌ Network hatası: \(error.localizedDescription)")
            logger.debug("   - Code: \(error.code.rawValue)")
            logger.debug("   - URL: \(error.failureURLString ?? "N/A")")
            textStories[index].status = .failed
            saveStories()
            return false
        } catch let error as DecodingError {
            logger.error("❌ JSON parse hatası: \(String(describing: error))")
            switch error {
            case .keyNotFound(let key, let context):
                logger.debug("   - Missing key: \(key.stringValue)")
                logger.debug("   - Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.debug("   - Type mismatch: \(type)")
                logger.debug("   - Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.debug("   - Value not found: \(type)")
                logger.debug("   - Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                logger.debug("   - Data corrupted: \(context.debugDescription)")
            @unknown default:
                logger.debug("   - Unknown decoding error")
            }
            textStories[index].status = .failed
            saveStories()
            return false
        } catch {
            logger.error("❌ Text hikaye oluşturma hatası: \(error.localizedDescription)")
            logger.debug("   - Error type: \(type(of: error))")
            logger.debug("   - Error: \(String(describing: error))")
            textStories[index].status = .failed
            saveStories()
            return false
        }
    }
    
    private func generateCategoryStoryContent(for storyId: UUID, age: Int, category: String) async -> Bool {
        guard let index = textStories.firstIndex(where: { $0.id == storyId }) else {
            return false
        }
        
        let story = textStories[index]
        
        // Gemini ile kategori bazlı hikaye oluştur
        do {
            let storyResponse = try await aiService.generateCategorySpecificStory(
                childName: story.childName,
                age: age,
                category: category,
                language: story.language == .turkish ? "tr" : "en",
                photoData: nil
            )
            
            // Sayfaları birleştir
            let fullContent = storyResponse.pages.map { page in
                "\(page.title)\n\n\(page.text)"
            }.joined(separator: "\n\n---\n\n")
            
            // Hikayeyi güncelle
            textStories[index].content = fullContent
            textStories[index].status = .completed
            saveStories()
            
            logger.debug("✅ Kategori bazlı text hikaye başarıyla oluşturuldu")
            return true
            
        } catch {
            logger.error("❌ Kategori bazlı text hikaye oluşturma hatası: \(error.localizedDescription)")
            textStories[index].status = .failed
            saveStories()
            return false
        }
    }
    
    // Kategori adını Türkçe'ye çevir
    private func getCategoryDisplayName(_ category: String) -> String {
        switch category {
        case "bedtime": return "Uyku Öncesi"
        case "morning": return "Sabah Hikayeleri"
        case "educational": return "Öğretici"
        case "values": return "Değerler"
        case "adventure": return "Macera"
        case "nature": return "Doğa"
        default: return "Hikaye"
        }
    }
    
    // Kategoriye uygun tema seç
    private func getThemeForCategory(_ category: String) -> StoryTheme {
        switch category {
        case "bedtime": return .fantasy
        case "morning": return .space
        case "educational": return .hero
        case "values": return .fantasy
        case "adventure": return .jungle
        case "nature": return .underwater
        default: return .fantasy
        }
    }
    
    // MARK: - Storage
    
    func saveStories() {
        if let encoded = try? JSONEncoder().encode(textStories) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            logger.debug("💾 \(self.textStories.count) text hikaye kaydedildi")
        }
    }
    
    func loadStories() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TextStory].self, from: data) {
            textStories = decoded
            logger.debug("📖 \(self.textStories.count) text hikaye yüklendi")
        }
    }
    
    func deleteStory(_ story: TextStory) {
        textStories.removeAll { $0.id == story.id }
        saveStories()
        logger.debug("🗑️ Text hikaye silindi")
    }
    
    func deleteAllStories() {
        textStories.removeAll()
        saveStories()
        logger.debug("🗑️ Tüm text hikayeler silindi")
    }
}
