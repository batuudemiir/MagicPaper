import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    
    // ✅ API Key artık Info.plist'ten okunuyor (güvenli)
    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.isEmpty else {
            fatalError("❌ GEMINI_API_KEY bulunamadı! Secrets.xcconfig dosyasını oluşturun ve Xcode'da projeye ekleyin.")
        }
        return key
    }()
    
    // ✅ GEMINI 2.5 FLASH - En yeni ve en hızlı model (Haziran 2025)
    private let modelName = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    private init() {}
    
    struct StoryPageData: Codable {
        let title: String
        let text: String
        let imagePrompt: String
    }
    
    struct StoryResponse: Codable {
        let title: String
        let pages: [StoryPageData]
    }
    
    func generateStructuredStory(
        childName: String,
        age: Int,
        theme: String,
        language: String,
        photoData: Data?
    ) async throws -> StoryResponse {
        
        print("📝 GEMINI FLASH: Hikaye Oluşturuluyor...")
        
        let languageName = language == "tr" ? "Turkish" : "English"
        
        // � YAŞ GRUBUNA GÖRE HİKAYE SEVİYESİ
        let ageLevel = getAgeLevelGuidance(age: age, childName: childName)
        
        // �🎨 TEMA-SPESIFIK HİKAYE YAPILARI
        let themeGuidance = getThemeSpecificGuidance(theme: theme, childName: childName, age: age)
        
        // 🔥 ULTRA GÜÇLENDİRİLMİŞ PROMPT (ÇOK UZUN HİKAYE İÇİN)
        let prompt = """
        You are a professional children's book author. Write a 7-page story in \(languageName).
        
        CHARACTER: \(childName), age \(age)
        THEME: \(theme)
        
        \(ageLevel)
        
        \(themeGuidance)
        
        🚨 CRITICAL RULE: FOLLOW THE WORD COUNT FOR AGE \(age) 🚨
        
        I will REJECT the story if any page has less than 150 words!
        
        STRUCTURE:
        
        PAGE 1 (150-200 words): THE BEGINNING
        - \(childName) wakes up in their room
        - Describe the room in detail (colors, objects, smells)
        - Show morning routine (getting dressed, breakfast)
        - Include dialogue with family members
        - Something magical catches their attention
        - Build curiosity and excitement
        - End with decision to investigate
        
        PAGE 2 (150-200 words): THE DISCOVERY
        - \(childName) finds something magical
        - Describe the magical object/portal in vivid detail
        - Show \(childName)'s emotions (surprise, wonder, fear, excitement)
        - Include inner thoughts ("What is this? Should I touch it?")
        - Describe sensory details (glowing lights, strange sounds, unusual smells)
        - \(childName) makes the brave decision to interact
        - Transition begins to magical world
        
        PAGE 3 (150-200 words): THE NEW WORLD
        - \(childName) enters a completely different world
        - Describe the landscape in rich detail (colors, sky, plants, buildings)
        - Show how everything is different from home
        - Include sounds of this new world (birds, wind, music)
        - \(childName) explores cautiously
        - Express feelings of wonder and slight nervousness
        - Something friendly approaches
        
        PAGE 4 (150-200 words): THE FRIEND
        - \(childName) meets a magical creature or friend
        - Describe the friend's appearance in detail (size, color, features, clothing)
        - Include full dialogue conversation (at least 4-5 exchanges)
        - Show how they become friends
        - Friend explains the world and its magic
        - Friend mentions a challenge or quest
        - They decide to work together
        
        PAGE 5 (150-200 words): THE CHALLENGE
        - A problem or obstacle appears
        - Describe the challenge in detail (what it looks like, why it's difficult)
        - Show \(childName)'s initial doubt ("Can I do this?")
        - Include dialogue with the friend (encouragement, planning)
        - Describe the environment where challenge takes place
        - Build tension and excitement
        - \(childName) gathers courage to try
        
        PAGE 6 (150-200 words): THE VICTORY
        - \(childName) attempts to solve the challenge
        - Describe the action step-by-step
        - Show the friend helping
        - Include moments of struggle and perseverance
        - The breakthrough moment (detailed description)
        - Success! Describe the celebration
        - Show feelings of pride, joy, and accomplishment
        - Receive a reward or magical gift
        
        PAGE 7 (150-200 words): THE RETURN HOME
        - Time to go back home
        - \(childName) says goodbye to the friend (emotional dialogue)
        - Promise to return someday
        - Journey back through the portal
        - Arrive home (describe familiar surroundings)
        - Evening routine (dinner, bath, bedtime)
        - \(childName) reflects on the adventure while falling asleep
        - End with warm, cozy, satisfied feeling
        
        WRITING STYLE:
        - Use descriptive language (colors, sounds, smells, textures)
        - Include dialogue in every page
        - Show emotions and inner thoughts
        - Use varied sentence lengths
        - Make it immersive and engaging
        - Write like a real children's book (not a summary!)
        
        OUTPUT FORMAT (JSON):
        {
          "title": "Story Title",
          "pages": [
            {
              "title": "Page Title",
              "text": "FULL TEXT HERE - MUST BE 150-200 WORDS - Include dialogue, descriptions, emotions, and sensory details. Write complete sentences and paragraphs. Make it feel like a real book page.",
              "imagePrompt": "A cinematic illustration of \(age) year old child [doing specific action] in [detailed setting], 3d pixar style, vibrant colors, children's book art"
            }
          ]
        }
        
        REMEMBER: 
        - Each "text" field MUST be 150-200 words
        - Count your words carefully
        - Write FULL paragraphs, not summaries
        - Include dialogue, descriptions, and emotions
        - Make it feel like reading a real children's book
        
        Now write the story!
        """
        
        let responseText = try await callGeminiAPI(prompt: prompt, photoData: photoData)
        
        // JSON Temizliği
        var cleanText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let startIndex = cleanText.firstIndex(of: "{"),
           let endIndex = cleanText.lastIndex(of: "}") {
            cleanText = String(cleanText[startIndex...endIndex])
        }
        
        guard let data = cleanText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        let storyResponse = try JSONDecoder().decode(StoryResponse.self, from: data)
        
        print("✅ Hikaye Başlığı: \(storyResponse.title)")
        print("📊 UZUNLUK KONTROLÜ (Yaş: \(age)):")
        
        // Yaş grubuna göre hedef kelime sayısı
        let (minWords, maxWords) = getTargetWordCount(age: age)
        
        // Detaylı uzunluk kontrolü
        var totalWords = 0
        for (i, page) in storyResponse.pages.enumerated() {
            let wordCount = page.text.split(separator: " ").count
            totalWords += wordCount
            let status = wordCount >= minWords && wordCount <= maxWords ? "✅" : "⚠️"
            print("\(status) Sayfa \(i+1): \(wordCount) kelime (hedef: \(minWords)-\(maxWords))")
        }
        
        print("📊 TOPLAM: \(totalWords) kelime (\(storyResponse.pages.count) sayfa)")
        print("📊 ORTALAMA: \(totalWords / storyResponse.pages.count) kelime/sayfa")
        
        return storyResponse
    }
    
    // MARK: - Age-Based Word Count
    
    private func getTargetWordCount(age: Int) -> (min: Int, max: Int) {
        switch age {
        case 0...3:
            return (50, 80)    // Toddler: Very short
        case 4...5:
            return (80, 120)   // Preschool: Short
        case 6...7:
            return (120, 150)  // Early reader: Medium
        case 8...9:
            return (150, 200)  // Middle reader: Long
        default:
            return (200, 250)  // Advanced: Very long
        }
    }
    
    private func callGeminiAPI(prompt: String, photoData: Data?) async throws -> String {
        // ✅ Doğru URL yapısı: /v1/models/{model}:generateContent
        let endpoint = "\(baseURL)/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        print("🌐 API Endpoint: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90  // Uzun hikaye için daha fazla zaman
        
        var requestBody: [String: Any] = [
            "generationConfig": [
                "temperature": 1.0,        // Maksimum yaratıcılık
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 8192,  // Uzun metin için
                "candidateCount": 1
            ]
        ]
        
        // Multimodal Veri
        if let photoData = photoData {
            let base64Image = photoData.base64EncodedString()
            requestBody["contents"] = [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        } else {
            requestBody["contents"] = [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Bilinmiyor"
            print("❌ API Hatası: \(errorText)")
            throw URLError(.badServerResponse)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            print("❌ JSON parse hatası")
            throw URLError(.cannotParseResponse)
        }
        
        print("✅ Gemini yanıtı alındı: \(text.count) karakter")
        
        return text
    }
    
    // MARK: - Theme-Specific Story Guidance
    
    private func getAgeLevelGuidance(age: Int, childName: String) -> String {
        switch age {
        case 0...3:
            return """
            📚 AGE LEVEL: TODDLER (0-3 years) - VERY SIMPLE
            
            WORD COUNT: 50-80 words per page
            
            LANGUAGE STYLE:
            - Very simple words (mama, dada, cat, dog, ball, happy, sleep)
            - Short sentences (3-5 words each)
            - Repetitive phrases ("Look! A cat!" "Big cat!" "Nice cat!")
            - Present tense only
            - No complex emotions or abstract concepts
            
            STORY ELEMENTS:
            - Focus on familiar objects and animals
            - Simple actions (eat, sleep, play, run, jump)
            - Happy, positive tone
            - Clear cause and effect
            - Lots of sounds (meow, woof, splash, boom)
            
            EXAMPLE PAGE:
            "\(childName) woke up. The sun was bright. 'Good morning!' said Mama. \(childName) smiled. Time for breakfast! Yummy pancakes. \(childName) ate and ate. Then \(childName) saw something. A shiny door! 'Wow!' said \(childName). The door opened. Magic!"
            """
            
        case 4...5:
            return """
            📚 AGE LEVEL: PRESCHOOL (4-5 years) - SIMPLE
            
            WORD COUNT: 80-120 words per page
            
            LANGUAGE STYLE:
            - Simple vocabulary with some new words
            - Short to medium sentences (5-8 words)
            - Some descriptive words (big, small, colorful, shiny)
            - Present and simple past tense
            - Basic emotions (happy, sad, scared, excited)
            
            STORY ELEMENTS:
            - Familiar settings (home, park, school)
            - Simple adventures
            - Clear good vs. bad
            - Friendly characters
            - Problem-solving with help
            
            EXAMPLE PAGE:
            "\(childName) was playing in the backyard. The sun was shining and birds were singing. Suddenly, \(childName) saw something special behind the big tree. It was a glowing door! 'What is this?' \(childName) wondered. The door was purple and sparkly. \(childName) felt excited and a little nervous. Should I open it? \(childName) took a deep breath and touched the door. It opened slowly. Wow!"
            """
            
        case 6...7:
            return """
            📚 AGE LEVEL: EARLY READER (6-7 years) - MODERATE
            
            WORD COUNT: 120-150 words per page
            
            LANGUAGE STYLE:
            - Expanded vocabulary
            - Mix of simple and compound sentences
            - More descriptive language (colors, sizes, feelings)
            - Past tense storytelling
            - Range of emotions and reactions
            
            STORY ELEMENTS:
            - Adventures beyond home
            - New friends and helpers
            - Small challenges to overcome
            - Learning moments
            - Dialogue between characters
            
            EXAMPLE PAGE:
            "\(childName) couldn't believe what was happening. Behind the old oak tree in the backyard, there was a magical glowing door that hadn't been there before. It shimmered with purple and blue lights, and \(childName) could hear soft music coming from the other side. 'This is amazing!' \(childName) whispered. Heart beating fast with excitement, \(childName) reached out and touched the golden doorknob. It felt warm and tingly. The door swung open, revealing a world filled with floating castles and talking animals. \(childName) took a brave step forward into the magical kingdom."
            """
            
        case 8...9:
            return """
            📚 AGE LEVEL: MIDDLE READER (8-9 years) - ADVANCED
            
            WORD COUNT: 150-200 words per page
            
            LANGUAGE STYLE:
            - Rich vocabulary with challenging words
            - Complex sentences with varied structure
            - Vivid descriptions (sensory details)
            - Multiple tenses and perspectives
            - Complex emotions and inner thoughts
            
            STORY ELEMENTS:
            - Detailed world-building
            - Character development
            - Moral dilemmas and choices
            - Suspense and plot twists
            - Meaningful dialogue and relationships
            
            EXAMPLE PAGE:
            "\(childName) stood frozen, staring at the impossible sight before them. The ancient oak tree, which had been a constant presence in the backyard for as long as \(childName) could remember, now concealed something extraordinary. A door—no, a portal—materialized from thin air, its surface rippling with iridescent purple and sapphire light. Strange symbols danced across its frame, and a melody unlike anything \(childName) had ever heard drifted through the air like silk. 'This can't be real,' \(childName) thought, but the tingling sensation in their fingertips said otherwise. Every instinct screamed both danger and adventure. Taking a deep breath to steady racing nerves, \(childName) reached for the ornate golden handle. The moment skin met metal, warmth flooded through their body, and the door swung open to reveal a breathtaking kingdom of floating castles, rainbow rivers, and creatures that existed only in dreams. This was the beginning of something incredible."
            """
            
        case 10...12:
            return """
            📚 AGE LEVEL: ADVANCED READER (10-12 years) - COMPLEX
            
            WORD COUNT: 200-250 words per page
            
            LANGUAGE STYLE:
            - Sophisticated vocabulary
            - Literary devices (metaphors, similes)
            - Varied sentence structures
            - Rich sensory descriptions
            - Deep emotional complexity
            - Internal monologue
            
            STORY ELEMENTS:
            - Complex plots with subplots
            - Character growth and transformation
            - Ethical questions and consequences
            - Detailed world-building
            - Nuanced relationships
            - Themes of identity and belonging
            
            EXAMPLE PAGE:
            "\(childName) had always believed that magic was nothing more than stories told to children, fairy tales meant to spark imagination before reality set in. But standing here, in the fading golden light of late afternoon, staring at the impossible door that had materialized behind the gnarled oak tree, every certainty crumbled like ancient parchment. The portal—for that's what it truly was—pulsed with an otherworldly luminescence, its surface a mesmerizing dance of deep purples and electric blues that seemed to breathe with life. Intricate symbols, reminiscent of languages long forgotten, spiraled across its frame, and from beyond came a haunting melody that tugged at something deep within \(childName)'s chest. Fear and exhilaration warred within, creating a cocktail of emotions that left hands trembling and heart racing. 'What lies beyond?' \(childName) wondered, knowing that crossing this threshold would change everything. The old oak's leaves rustled as if whispering encouragement. With a resolve born from equal parts courage and curiosity, \(childName) grasped the ornate handle, feeling ancient magic surge through veins like electricity. The door opened, revealing a kingdom that defied imagination—floating citadels of crystal and gold, rivers that flowed upward into clouds, and creatures of legend walking freely. This was no longer childhood fantasy. This was destiny calling."
            """
            
        default: // 13+
            return """
            📚 AGE LEVEL: YOUNG ADULT (13+ years) - SOPHISTICATED
            
            WORD COUNT: 200-250 words per page
            
            LANGUAGE STYLE:
            - Advanced vocabulary and literary style
            - Complex narrative techniques
            - Layered meanings and symbolism
            - Philosophical undertones
            - Mature emotional depth
            
            STORY ELEMENTS:
            - Multi-layered plots
            - Complex character arcs
            - Moral ambiguity
            - Coming-of-age themes
            - Social and personal challenges
            - Meaningful life lessons
            """
        }
    }
    
    // MARK: - Theme-Specific Story Guidance
    
    private func getThemeSpecificGuidance(theme: String, childName: String, age: Int) -> String {
        switch theme.lowercased() {
        case "fantasy", "sihirli krallık":
            return """
            FANTASY ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName) discovers a magical portal in an unexpected place (old tree, mirror, book)
            - Describe ordinary day turning magical
            - Sensory details: glowing lights, strange sounds, tingling feeling
            - Decision to step through
            
            PAGE 2: Arrival in magical kingdom
            - Talking animals, floating castles, rainbow rivers
            - Meet a friendly guide (wise owl, playful fairy, talking fox)
            - Learn about the kingdom's magic
            
            PAGE 3: The kingdom's problem revealed
            - Evil sorcerer/dark force threatens the land
            - Missing magical artifact (crown, crystal, wand)
            - Only a pure-hearted child can help
            
            PAGE 4: Journey through enchanted forest
            - Magical creatures help along the way
            - Learn spells or magical skills
            - Overcome first obstacle (riddle, maze, river crossing)
            
            PAGE 5: Face the main challenge
            - Enter dark castle/cave/mountain
            - Confront fears and doubts
            - Use courage and kindness to succeed
            
            PAGE 6: Victory and celebration
            - Restore magic to the kingdom
            - Crowned as honorary hero
            - Grand celebration with all creatures
            
            PAGE 7: Return home with magical gift
            - Emotional goodbye to friends
            - Promise to return
            - Back home, treasure the memory and gift
            """
            
        case "space", "uzay":
            return """
            SPACE ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName) builds/finds a rocket ship
            - Fascination with stars and planets
            - Discovery of mysterious spaceship in backyard/attic
            - Preparation for launch
            
            PAGE 2: Blast off into space
            - Countdown and liftoff excitement
            - Passing through atmosphere
            - First view of Earth from space, stars everywhere
            
            PAGE 3: Meet alien friend
            - Land on colorful alien planet
            - Meet friendly alien (different appearance, kind heart)
            - Learn about their world and technology
            
            PAGE 4: Explore alien civilization
            - Visit crystal cities, floating gardens
            - Try alien food, play alien games
            - Learn alien language or customs
            
            PAGE 5: Space emergency
            - Asteroid storm, broken ship, lost in space
            - Work together with alien friend
            - Use science and teamwork to solve problem
            
            PAGE 6: Save the day
            - Fix the ship or help alien planet
            - Become space hero
            - Celebration with alien friends
            
            PAGE 7: Journey home
            - Fly back to Earth
            - Promise to visit again
            - Look at stars differently now, knowing friends are out there
            """
            
        case "jungle", "orman":
            return """
            JUNGLE ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName) goes on jungle expedition
            - Family trip or school adventure
            - Enter dense, mysterious jungle
            - Sounds of exotic birds and animals
            
            PAGE 2: Get separated from group
            - Follow a beautiful butterfly/bird
            - Realize they're alone but not scared
            - Discover hidden jungle path
            
            PAGE 3: Meet jungle animal friend
            - Friendly monkey, parrot, or jaguar cub
            - Animal shows the way
            - Learn to communicate with nature
            
            PAGE 4: Discover ancient temple
            - Hidden ruins covered in vines
            - Mysterious symbols and treasures
            - Legend of jungle guardian
            
            PAGE 5: Solve temple puzzle
            - Ancient riddle or maze
            - Use observation and cleverness
            - Avoid traps (friendly, not scary)
            
            PAGE 6: Find treasure and help jungle
            - Discover magical artifact that protects jungle
            - Return it to rightful place
            - Jungle comes alive with gratitude
            
            PAGE 7: Reunite with family
            - Animal friends guide back
            - Share incredible story
            - Forever connected to the jungle
            """
            
        case "hero", "kahraman", "süper kahraman":
            return """
            SUPERHERO ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName) discovers special power
            - Ordinary day, something unusual happens
            - Realize they have a superpower (flying, strength, invisibility, etc.)
            - Initial surprise and excitement
            
            PAGE 2: Learn to control powers
            - Practice in secret
            - Small accidents (funny, not dangerous)
            - Decide to use powers for good
            
            PAGE 3: City needs help
            - Hear about problem (lost pets, park in danger, bully situation)
            - Create superhero costume
            - Make decision to help
            
            PAGE 4: First hero mission
            - Use powers to help
            - Meet other kids who need help
            - Work together as team
            
            PAGE 5: Face bigger challenge
            - Main problem appears
            - Doubt creeps in ("Am I strong enough?")
            - Remember that being hero is about heart, not just powers
            
            PAGE 6: Save the day
            - Use powers AND kindness/intelligence
            - Everyone works together
            - Realize everyone can be a hero
            
            PAGE 7: Hero's rest
            - Return home as secret hero
            - Know they can help anytime
            - Dream of next adventure
            """
            
        case "underwater", "denizaltı":
            return """
            UNDERWATER ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName) visits the beach/aquarium
            - Fascination with ocean
            - Find magical seashell/pearl
            - Suddenly can breathe underwater
            
            PAGE 2: Dive into ocean world
            - Swim with colorful fish
            - Discover coral reef city
            - Everything sparkles and glows
            
            PAGE 3: Meet mermaid/dolphin friend
            - Friendly sea creature
            - Learn about ocean life
            - Invited to underwater kingdom
            
            PAGE 4: Explore underwater palace
            - Made of pearls and coral
            - Meet sea king/queen
            - Learn ocean is in danger
            
            PAGE 5: Ocean cleanup mission
            - Help sea creatures
            - Remove pollution/solve problem
            - Use creativity and teamwork
            
            PAGE 6: Ocean celebration
            - Underwater festival
            - Dance with dolphins, sing with whales
            - Given special ocean guardian title
            
            PAGE 7: Return to surface
            - Promise to protect ocean
            - Back on beach with magical shell
            - Forever connected to sea friends
            """
            
        default: // custom or other themes
            return """
            CREATIVE ADVENTURE STRUCTURE:
            
            PAGE 1: \(childName)'s ordinary day becomes extraordinary
            - Something magical/unusual happens
            - Curiosity leads to discovery
            
            PAGE 2: Enter new world/situation
            - Everything is different and exciting
            - Meet interesting characters
            
            PAGE 3: Learn about this new world
            - Make friends
            - Discover a problem that needs solving
            
            PAGE 4: Begin the quest/adventure
            - Face challenges with new friends
            - Learn new skills
            
            PAGE 5: Main challenge appears
            - Seems difficult at first
            - Use courage and creativity
            
            PAGE 6: Success through teamwork
            - Overcome challenge
            - Celebration and rewards
            
            PAGE 7: Return home changed
            - Bring back lessons learned
            - Ready for next adventure
            """
        }
    }
    
    // MARK: - Category-Specific Story Generation (for Daily Stories)
    
    func generateCategorySpecificStory(
        childName: String,
        age: Int,
        category: String, // bedtime, morning, educational, values, adventure, nature
        language: String,
        photoData: Data?
    ) async throws -> StoryResponse {
        
        print("📝 GEMINI FLASH: Kategoriye Özel Hikaye Oluşturuluyor...")
        print("📂 Kategori: \(category)")
        
        let languageName = language == "tr" ? "Turkish" : "English"
        let ageLevel = getAgeLevelGuidance(age: age, childName: childName)
        let categoryGuidance = getCategorySpecificGuidance(category: category, childName: childName, age: age)
        
        let prompt = """
        You are a professional children's book author. Write a 7-page story in \(languageName).
        
        CHARACTER: \(childName), age \(age)
        CATEGORY: \(category)
        
        \(ageLevel)
        
        \(categoryGuidance)
        
        🚨 CRITICAL RULE: FOLLOW THE WORD COUNT FOR AGE \(age) 🚨
        
        STRUCTURE:
        
        PAGE 1 (150-200 words): THE BEGINNING
        PAGE 2 (150-200 words): THE DISCOVERY
        PAGE 3 (150-200 words): THE NEW WORLD
        PAGE 4 (150-200 words): THE FRIEND
        PAGE 5 (150-200 words): THE CHALLENGE
        PAGE 6 (150-200 words): THE SOLUTION
        PAGE 7 (150-200 words): THE ENDING
        
        RESPONSE FORMAT (JSON):
        {
          "title": "Story title in \(languageName)",
          "pages": [
            {
              "title": "Page 1 title",
              "text": "150-200 word story text for page 1",
              "imagePrompt": "Detailed English image description for AI art generation"
            },
            ... (7 pages total)
          ]
        }
        
        IMPORTANT:
        - Each page MUST have 150-200 words
        - Story must match the \(category) category theme
        - Include dialogue and emotions
        - Make it engaging and age-appropriate
        - Image prompts in English, detailed for AI generation
        """
        
        // Call Gemini API
        let responseText = try await callGeminiAPI(prompt: prompt, photoData: photoData)
        
        // JSON Cleanup
        var cleanText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let startIndex = cleanText.firstIndex(of: "{"),
           let endIndex = cleanText.lastIndex(of: "}") {
            cleanText = String(cleanText[startIndex...endIndex])
        }
        
        guard let data = cleanText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        let storyResponse = try JSONDecoder().decode(StoryResponse.self, from: data)
        
        print("✅ Category Story Title: \(storyResponse.title)")
        print("📂 Category: \(category)")
        print("📊 LENGTH CHECK (Age: \(age)):")
        
        let (minWords, maxWords) = getTargetWordCount(age: age)
        
        var totalWords = 0
        for (i, page) in storyResponse.pages.enumerated() {
            let wordCount = page.text.split(separator: " ").count
            totalWords += wordCount
            let status = wordCount >= minWords && wordCount <= maxWords ? "✅" : "⚠️"
            print("\(status) Page \(i+1): \(wordCount) words (target: \(minWords)-\(maxWords))")
        }
        
        print("📊 TOTAL: \(totalWords) words (\(storyResponse.pages.count) pages)")
        print("📊 AVERAGE: \(totalWords / storyResponse.pages.count) words/page")
        
        return storyResponse
    }
    
    // MARK: - Category-Specific Guidance
    
    private func getCategorySpecificGuidance(category: String, childName: String, age: Int) -> String {
        switch category.lowercased() {
        case "bedtime", "uyku öncesi":
            return """
            🌙 BEDTIME STORY STRUCTURE (Calming & Soothing):
            
            TONE: Gentle, peaceful, reassuring, slow-paced
            THEME: Comfort, safety, dreams, nighttime magic
            
            PAGE 1: Peaceful evening routine
            - \(childName) getting ready for bed
            - Soft lighting, cozy pajamas, warm milk
            - Looking out window at stars and moon
            - Feeling sleepy but curious about the night
            
            PAGE 2: Magical nighttime visitor
            - Gentle creature appears (moon fairy, dream keeper, sleepy cloud)
            - Soft voice, calming presence
            - Invites \(childName) on a peaceful journey
            
            PAGE 3: Journey through dreamland
            - Floating on soft clouds
            - Visiting peaceful places (quiet forest, calm ocean, starry meadow)
            - Everything moves slowly and gently
            
            PAGE 4: Meeting dream friends
            - Friendly animals preparing for sleep
            - Everyone shares what makes them feel safe
            - Soft lullabies and gentle stories
            
            PAGE 5: Helping others sleep peacefully
            - Tucking in baby animals
            - Singing soft songs
            - Spreading comfort and calm
            
            PAGE 6: Return to cozy bed
            - Gentle goodbye to dream friends
            - Floating back home on moonbeams
            - Feeling safe and loved
            
            PAGE 7: Peaceful sleep
            - Back in own bed, feeling warm and safe
            - Stars watching over
            - Drifting into sweet dreams
            - "Goodnight" message
            
            LANGUAGE STYLE:
            - Use soft, gentle words
            - Slow, calming rhythm
            - Repetitive, soothing phrases
            - Positive, peaceful imagery
            - No excitement or action
            """
            
        case "morning", "sabah":
            return """
            ☀️ MORNING STORY STRUCTURE (Energetic & Uplifting):
            
            TONE: Bright, cheerful, energetic, motivating
            THEME: New beginnings, energy, excitement, possibilities
            
            PAGE 1: Sunrise awakening
            - Sun peeking through window
            - Birds singing cheerfully
            - \(childName) waking up with energy
            - Excited for the new day
            
            PAGE 2: Morning magic
            - Breakfast smells amazing
            - Everything seems brighter and more colorful
            - Magical morning creature appears (sunrise sprite, morning bird)
            - Invites to morning adventure
            
            PAGE 3: Energetic exploration
            - Running, jumping, playing
            - Discovering morning wonders
            - Dew on grass, flowers opening
            - Energy and joy everywhere
            
            PAGE 4: Morning challenges
            - Fun morning activities
            - Racing, climbing, exploring
            - Using energy positively
            - Making new friends
            
            PAGE 5: Breakfast celebration
            - Sharing delicious food
            - Talking about plans for the day
            - Feeling strong and ready
            
            PAGE 6: Morning lessons
            - Learning something new
            - Trying something brave
            - Feeling confident and capable
            
            PAGE 7: Ready for the day
            - Full of energy and ideas
            - Excited about possibilities
            - Grateful for the new day
            - "Good morning, world!" message
            
            LANGUAGE STYLE:
            - Upbeat, energetic words
            - Fast-paced, exciting rhythm
            - Action verbs
            - Bright, colorful imagery
            - Motivational tone
            """
            
        case "educational", "eğitici":
            return """
            📚 EDUCATIONAL STORY STRUCTURE (Learning & Discovery):
            
            TONE: Curious, informative, engaging, wonder-filled
            THEME: Learning, discovery, questions, understanding
            
            PAGE 1: Curious question
            - \(childName) wonders about something
            - "How does...?" "Why is...?" "What makes...?"
            - Decides to find answers
            
            PAGE 2: Meeting a teacher
            - Wise character appears (professor, scientist, nature guide)
            - Offers to show and explain
            - Journey of discovery begins
            
            PAGE 3: First lesson
            - Hands-on learning experience
            - Seeing how things work
            - Understanding through doing
            
            PAGE 4: Deeper exploration
            - More complex concepts explained simply
            - Connections between ideas
            - "Aha!" moments
            
            PAGE 5: Practical application
            - Using new knowledge
            - Solving a problem
            - Helping others with what was learned
            
            PAGE 6: Teaching others
            - \(childName) shares knowledge
            - Explaining to friends
            - Feeling proud of understanding
            
            PAGE 7: Lifelong learning
            - Realizing there's always more to learn
            - Excited about future discoveries
            - Encouraging curiosity
            
            LANGUAGE STYLE:
            - Clear, simple explanations
            - Question-and-answer format
            - Real-world examples
            - Encouraging curiosity
            - Age-appropriate facts
            """
            
        case "values", "değerler":
            return """
            💝 VALUES STORY STRUCTURE (Moral & Character):
            
            TONE: Thoughtful, warm, meaningful, inspiring
            THEME: Kindness, honesty, courage, friendship, respect
            
            PAGE 1: Normal day with a choice
            - \(childName) faces a moral decision
            - Easy way vs. right way
            - Feeling uncertain
            
            PAGE 2: Seeing both paths
            - Imagining consequences of each choice
            - Meeting characters who made different choices
            - Understanding impact on others
            
            PAGE 3: Choosing the right path
            - Making the difficult but good choice
            - Feeling nervous but determined
            - Taking action
            
            PAGE 4: Challenges of doing right
            - Not always easy
            - Others might not understand
            - Staying true to values
            
            PAGE 5: Positive impact revealed
            - Seeing how choice helped others
            - Unexpected good outcomes
            - Others inspired by example
            
            PAGE 6: Recognition and growth
            - Feeling proud of choice
            - Others appreciate the action
            - Character strengthened
            
            PAGE 7: Lasting lesson
            - Understanding the value learned
            - Commitment to living by it
            - Inspiring others
            - Clear moral message
            
            LANGUAGE STYLE:
            - Thoughtful, reflective
            - Emotional depth
            - Clear cause and effect
            - Empathy-building
            - Positive reinforcement
            """
            
        case "adventure", "macera":
            return """
            🗺️ ADVENTURE STORY STRUCTURE (Exciting & Bold):
            
            TONE: Thrilling, brave, exciting, dynamic
            THEME: Courage, exploration, overcoming fears, discovery
            
            PAGE 1: Call to adventure
            - \(childName) finds mysterious map/message
            - Exciting opportunity appears
            - Decision to embark on quest
            
            PAGE 2: Journey begins
            - Packing supplies
            - Saying goodbye
            - First steps into unknown
            - Mix of excitement and nervousness
            
            PAGE 3: First obstacle
            - Unexpected challenge appears
            - Must use cleverness
            - Small victory builds confidence
            
            PAGE 4: Meeting adventure companion
            - Finding unexpected ally
            - Learning to work together
            - Combining strengths
            
            PAGE 5: Major challenge
            - Biggest obstacle yet
            - Seems impossible at first
            - Must dig deep for courage
            
            PAGE 6: Triumphant success
            - Overcoming the challenge
            - Discovering inner strength
            - Achieving the goal
            
            PAGE 7: Hero's return
            - Coming home changed
            - Sharing the story
            - Ready for next adventure
            - Confidence and growth
            
            LANGUAGE STYLE:
            - Action-packed
            - Vivid descriptions
            - Exciting pace
            - Brave, bold words
            - Triumphant tone
            """
            
        case "nature", "doğa":
            return """
            🌳 NATURE STORY STRUCTURE (Wonder & Connection):
            
            TONE: Peaceful, observant, appreciative, connected
            THEME: Nature, animals, environment, seasons, growth
            
            PAGE 1: Stepping into nature
            - \(childName) goes outside
            - Noticing details (sounds, smells, sights)
            - Feeling connected to natural world
            
            PAGE 2: Meeting nature guide
            - Animal or nature spirit appears
            - Offers to show nature's secrets
            - Beginning of nature walk
            
            PAGE 3: Discovering ecosystem
            - How everything connects
            - Plants, animals, water, soil
            - Each part important
            
            PAGE 4: Seasonal changes
            - Understanding cycles
            - Growth and change
            - Beauty in each season
            
            PAGE 5: Helping nature
            - Small actions make difference
            - Planting, cleaning, protecting
            - Being nature's friend
            
            PAGE 6: Nature's gifts
            - Appreciating what nature provides
            - Beauty, food, shelter, joy
            - Gratitude and respect
            
            PAGE 7: Becoming nature guardian
            - Commitment to protect
            - Sharing love of nature
            - Feeling part of natural world
            
            LANGUAGE STYLE:
            - Descriptive, sensory
            - Peaceful, flowing
            - Observational
            - Appreciative tone
            - Environmental awareness
            """
            
        default:
            return """
            GENERAL STORY STRUCTURE:
            
            PAGE 1: Introduction and normal world
            PAGE 2: Something magical/special happens
            PAGE 3: New world or situation
            PAGE 4: Making friends and learning
            PAGE 5: Facing a challenge
            PAGE 6: Overcoming with courage
            PAGE 7: Return home with new wisdom
            """
        }
    }
    
    // MARK: - Text-Only Story Generation (No Images)
    
    struct TextOnlyStoryPageData: Codable {
        let title: String
        let text: String
    }
    
    struct TextOnlyStoryResponse: Codable {
        let title: String
        let pages: [TextOnlyStoryPageData]
    }
    
    func generateTextOnlyStory(
        childName: String,
        gender: Gender,
        theme: String,
        language: String,
        customTitle: String? = nil
    ) async throws -> TextOnlyStoryResponse {
        
        print("📖 GEMINI FLASH: Metin Hikaye Oluşturuluyor...")
        print("👤 Çocuk: \(childName)")
        print("🎭 Cinsiyet: \(gender.displayName)")
        print("🎨 Tema: \(theme)")
        print("🌍 Dil: \(language)")
        
        let languageName = language == "tr" ? "Turkish" : language == "en" ? "English" : "Turkish"
        let genderPronoun = getGenderPronoun(gender: gender, language: language)
        
        let themeTitle = customTitle ?? theme
        
        // Yaş 6-8 arası ortalama bir çocuk için optimize edilmiş prompt
        let prompt = """
        You are a professional children's book author. Write a 7-page story in \(languageName).
        
        CHARACTER: \(childName) (\(gender.displayName))
        THEME: \(themeTitle)
        
        📚 TARGET AUDIENCE: Children aged 6-8 years
        
        WORD COUNT: 120-150 words per page
        
        LANGUAGE STYLE:
        - Simple but engaging vocabulary
        - Short to medium sentences (5-8 words)
        - Descriptive language (colors, sounds, feelings)
        - Present and past tense
        - Include dialogue
        - Show emotions clearly
        
        STORY STRUCTURE:
        
        PAGE 1 (120-150 words): THE BEGINNING
        - \(childName) in their normal world
        - Describe the setting (home, school, park)
        - Show \(childName)'s personality
        - Something unusual catches \(genderPronoun) attention
        - Build curiosity
        
        PAGE 2 (120-150 words): THE DISCOVERY
        - \(childName) finds something magical or special
        - Describe it in vivid detail
        - Show \(genderPronoun) emotions (surprise, wonder, excitement)
        - Include inner thoughts
        - Decision to explore
        
        PAGE 3 (120-150 words): THE NEW WORLD
        - \(childName) enters a different place or situation
        - Rich sensory descriptions
        - Everything feels new and exciting
        - \(childName) explores carefully
        - Something friendly appears
        
        PAGE 4 (120-150 words): THE FRIEND
        - \(childName) meets a helper or friend
        - Describe the friend in detail
        - Include dialogue (at least 3-4 exchanges)
        - They become friends
        - Friend explains the situation
        - A challenge is mentioned
        
        PAGE 5 (120-150 words): THE CHALLENGE
        - A problem appears
        - Describe the challenge clearly
        - \(childName) feels uncertain at first
        - Friend encourages \(genderPronoun)
        - They make a plan together
        - \(childName) decides to be brave
        
        PAGE 6 (120-150 words): THE VICTORY
        - \(childName) faces the challenge
        - Describe the action step-by-step
        - Show effort and determination
        - The breakthrough moment
        - Success! Celebration
        - \(childName) feels proud and happy
        - Receives a special gift or reward
        
        PAGE 7 (120-150 words): THE RETURN
        - Time to go home
        - Emotional goodbye to friend
        - Promise to remember this adventure
        - Return to normal world
        - \(childName) reflects on what \(genderPronoun) learned
        - End with warm, happy feeling
        - Hint at future adventures
        
        WRITING GUIDELINES:
        - Use \(childName)'s name frequently
        - Include dialogue in every page
        - Show emotions through actions and words
        - Use sensory details (what they see, hear, feel)
        - Make it immersive and engaging
        - Write complete paragraphs, not summaries
        - Each page should feel like a real book page
        
        IMPORTANT RULES:
        - Each page MUST be 120-150 words
        - Write in \(languageName) language
        - Use appropriate pronouns for \(gender.displayName)
        - Make it age-appropriate (6-8 years)
        - Include moral lessons naturally
        - End on a positive, uplifting note
        
        OUTPUT FORMAT (JSON):
        {
          "title": "Story Title in \(languageName)",
          "pages": [
            {
              "title": "Page Title",
              "text": "FULL TEXT HERE - 120-150 words - Complete paragraphs with dialogue, descriptions, and emotions"
            }
          ]
        }
        
        Now write the story!
        """
        
        // ✅ Use the same working API call as the image story generation
        let responseText = try await callGeminiAPI(prompt: prompt, photoData: nil)
        
        // JSON Temizliği
        var cleanText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let startIndex = cleanText.firstIndex(of: "{"),
           let endIndex = cleanText.lastIndex(of: "}") {
            cleanText = String(cleanText[startIndex...endIndex])
        }
        
        guard let data = cleanText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        let storyResponse = try JSONDecoder().decode(TextOnlyStoryResponse.self, from: data)
        
        print("✅ Hikaye Başlığı: \(storyResponse.title)")
        print("📊 UZUNLUK KONTROLÜ:")
        
        var totalWords = 0
        for (i, page) in storyResponse.pages.enumerated() {
            let wordCount = page.text.split(separator: " ").count
            totalWords += wordCount
            let status = wordCount >= 120 && wordCount <= 150 ? "✅" : "⚠️"
            print("\(status) Sayfa \(i+1): \(wordCount) kelime (hedef: 120-150)")
        }
        
        print("📊 TOPLAM: \(totalWords) kelime (\(storyResponse.pages.count) sayfa)")
        print("📊 ORTALAMA: \(totalWords / storyResponse.pages.count) kelime/sayfa")
        
        return storyResponse
    }
    
    private func getGenderPronoun(gender: Gender, language: String) -> String {
        if language == "tr" {
            return "onun" // Turkish doesn't have gendered pronouns
        } else {
            switch gender {
            case .boy: return "his"
            case .girl: return "her"
            case .other: return "their"
            }
        }
    }
}
