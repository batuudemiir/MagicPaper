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
        let prompt = createStoryPrompt(
            childName: story.childName,
            gender: story.gender,
            theme: story.theme,
            language: story.language,
            customTitle: story.title
        )
        
        do {
            let content = try await aiService.generateText(prompt: prompt)
            
            // Hikayeyi güncelle
            textStories[index].content = content
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
    
    private func createStoryPrompt(
        childName: String,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        customTitle: String
    ) -> String {
        
        let genderPronoun: String
        let genderAdjective: String
        
        switch gender {
        case .boy:
            genderPronoun = "o"
            genderAdjective = "cesur"
        case .girl:
            genderPronoun = "o"
            genderAdjective = "cesur"
        case .other:
            genderPronoun = "o"
            genderAdjective = "cesur"
        }
        
        let themeContext: String
        switch theme {
        case .fantasy:
            themeContext = "sihirli bir krallıkta, ejderhalar ve perilerle dolu bir dünyada"
        case .space:
            themeContext = "uzayda, yıldızlar arasında, yeni gezegenler keşfederken"
        case .jungle:
            themeContext = "vahşi bir ormanda, egzotik hayvanlar ve gizli hazinelerle dolu"
        case .hero:
            themeContext = "bir süper kahraman olarak, dünyayı kötülüklerden korurken"
        case .underwater:
            themeContext = "okyanusun derinliklerinde, deniz yaratıkları ve kayıp şehirlerle"
        case .custom:
            themeContext = "benzersiz bir macerada"
        }
        
        let languageInstruction: String
        switch language {
        case .turkish:
            languageInstruction = "Hikayeyi Türkçe yaz."
        case .english:
            languageInstruction = "Write the story in English."
        case .spanish:
            languageInstruction = "Escribe la historia en español."
        case .french:
            languageInstruction = "Écris l'histoire en français."
        case .german:
            languageInstruction = "Schreibe die Geschichte auf Deutsch."
        case .italian:
            languageInstruction = "Scrivi la storia in italiano."
        case .russian:
            languageInstruction = "Напиши историю на русском языке."
        case .arabic:
            languageInstruction = "اكتب القصة بالعربية."
        }
        
        return """
        Sen profesyonel bir çocuk kitabı yazarısın. Görevin, çocuklar için eğitici, eğlenceli ve duygusal olarak zengin bir hikaye yazmak.
        
        KARAKTER BİLGİLERİ:
        - İsim: \(childName)
        - Cinsiyet: \(gender.displayName)
        - Karakter özellikleri: \(genderAdjective), meraklı, nazik, zeki
        
        HİKAYE AYARLARI:
        - Tema: \(theme.displayName)
        - Ortam: \(themeContext)
        - Başlık: \(customTitle)
        
        HİKAYE GEREKSİNİMLERİ:
        1. Hikaye 1500-2000 kelime uzunluğunda olmalı
        2. \(childName) hikayenin ana kahramanı olmalı
        3. Hikaye 5-8 yaş arası çocuklar için uygun olmalı
        4. Eğitici bir mesaj içermeli (dostluk, cesaret, dürüstlük, vb.)
        5. Macera dolu ve heyecan verici olmalı
        6. Pozitif ve mutlu bir sonla bitmeli
        7. Çocuğun hayal gücünü geliştirmeli
        8. Duygusal bağ kurulabilir karakterler içermeli
        
        YAZIM TARZI:
        - Basit ve anlaşılır cümleler kullan
        - Canlı ve renkli betimlemeler yap
        - Diyaloglar ekle
        - Duygusal anlar oluştur
        - Çocuğun kendini kahramanla özdeşleştirmesini sağla
        
        DİL: \(languageInstruction)
        
        Hikayeyi şimdi yaz. Sadece hikaye metnini yaz, başka açıklama ekleme.
        """
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
