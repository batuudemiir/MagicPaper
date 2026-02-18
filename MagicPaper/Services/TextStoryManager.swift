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
            print("❌ Hikaye bulunamadı: \(storyId)")
            return false
        }
        
        let story = textStories[index]
        
        print("📝 Hikaye oluşturuluyor...")
        print("   - ID: \(story.id)")
        print("   - Başlık: \(story.title)")
        print("   - Çocuk: \(story.childName)")
        print("   - Tema: \(story.theme.rawValue)")
        print("   - Dil: \(story.language.rawValue)")
        
        // Gemini ile hikaye oluştur
        do {
            // Dile göre tema adını seç
            let themeName = story.language == .turkish ? story.theme.displayName : story.theme.englishName
            print("   - Tema Adı (API): \(themeName)")
            
            let storyResponse = try await aiService.generateTextOnlyStory(
                childName: story.childName,
                gender: story.gender,
                theme: themeName,
                language: story.language.rawValue,
                customTitle: story.theme == .custom ? story.title : nil
            )
            
            print("✅ API yanıtı alındı")
            print("   - Başlık: \(storyResponse.title)")
            print("   - Sayfa sayısı: \(storyResponse.pages.count)")
            
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
            
        } catch let error as URLError {
            print("❌ Network hatası: \(error.localizedDescription)")
            print("   - Code: \(error.code)")
            print("   - URL: \(error.failureURLString ?? "N/A")")
            textStories[index].status = .failed
            saveStories()
            return false
        } catch let error as DecodingError {
            print("❌ JSON parse hatası: \(error)")
            switch error {
            case .keyNotFound(let key, let context):
                print("   - Missing key: \(key.stringValue)")
                print("   - Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   - Type mismatch: \(type)")
                print("   - Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   - Value not found: \(type)")
                print("   - Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   - Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   - Unknown decoding error")
            }
            textStories[index].status = .failed
            saveStories()
            return false
        } catch {
            print("❌ Text hikaye oluşturma hatası: \(error.localizedDescription)")
            print("   - Error type: \(type(of: error))")
            print("   - Error: \(error)")
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
            
            print("✅ Kategori bazlı text hikaye başarıyla oluşturuldu: \(story.title)")
            return true
            
        } catch {
            print("❌ Kategori bazlı text hikaye oluşturma hatası: \(error.localizedDescription)")
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
