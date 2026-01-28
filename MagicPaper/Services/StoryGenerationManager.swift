import Foundation
import SwiftUI
import Combine

/// Orchestrates the entire story creation workflow
/// Handles background story generation with status updates
@MainActor
class StoryGenerationManager: ObservableObject {
    
    static let shared = StoryGenerationManager()
    
    // MARK: - Published Properties
    
    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false
    
    // MARK: - Private Properties
    
    private let firebaseUploader = FirebaseImageUploader.shared
    private let aiService = AIService.shared
    private let fileManager = FileManagerService.shared
    
    private init() {
        loadStories()
        migrateOldStoriesIfNeeded()
        createSampleStoriesIfNeeded()
    }
    
    // MARK: - Public API
    
    /// Creates a custom story with background generation
    /// - Parameters:
    ///   - childName: Name of the child
    ///   - age: Age of the child
    ///   - gender: Gender of the child
    ///   - theme: Story theme
    ///   - language: Story language
    ///   - image: Child's photo
    ///   - customTitle: Optional custom title
    /// - Returns: Story ID for tracking
    func createCustomStory(
        childName: String,
        age: Int,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        image: UIImage,
        customTitle: String? = nil
    ) async -> UUID {
        
        // Create initial story with uploading status
        let storyId = UUID()
        let initialTitle = customTitle ?? generateTitle(theme: theme, language: language)
        
        // FIX: Save cover image to file system
        var coverImageFileName: String?
        if let coverData = image.jpegData(compressionQuality: 0.8) {
            let coverName = "\(storyId.uuidString)_cover.jpg"
            coverImageFileName = fileManager.saveImage(data: coverData, fileName: coverName)
        }
        
        let story = Story(
            id: storyId,
            title: initialTitle,
            childName: childName,
            theme: theme,
            language: language,
            status: .uploading,
            coverImageFileName: coverImageFileName
        )
        
        // Add to stories array immediately
        stories.insert(story, at: 0)
        saveStories()
        
        // Start background generation
        Task {
            await generateStoryInBackground(
                storyId: storyId,
                childName: childName,
                age: age,
                gender: gender,
                theme: theme,
                language: language,
                image: image,
                customTitle: customTitle
            )
        }
        
        return storyId
    }
    
    /// Creates a category-based story (for Daily Stories feature)
    /// - Parameters:
    ///   - childName: Name of the child
    ///   - age: Age of the child
    ///   - gender: Gender of the child
    ///   - category: Story category (bedtime, morning, educational, etc.)
    ///   - language: Story language
    ///   - image: Child's photo
    /// - Returns: Story ID for tracking
    func createCategoryBasedStory(
        childName: String,
        age: Int,
        gender: Gender,
        category: DailyStoryCategory,
        language: StoryLanguage,
        image: UIImage
    ) async -> UUID {
        
        // Create initial story with uploading status
        let storyId = UUID()
        let initialTitle = generateCategoryTitle(category: category, language: language, childName: childName)
        
        // Map category to theme for visual consistency
        let theme = categoryToTheme(category)
        
        // Save cover image to file system
        var coverImageFileName: String?
        if let coverData = image.jpegData(compressionQuality: 0.8) {
            let coverName = "\(storyId.uuidString)_cover.jpg"
            coverImageFileName = fileManager.saveImage(data: coverData, fileName: coverName)
        }
        
        let story = Story(
            id: storyId,
            title: initialTitle,
            childName: childName,
            theme: theme,
            language: language,
            status: .uploading,
            coverImageFileName: coverImageFileName
        )
        
        // Add to stories array immediately
        stories.insert(story, at: 0)
        saveStories()
        
        // Start background generation with category
        Task {
            await generateCategoryStoryInBackground(
                storyId: storyId,
                childName: childName,
                age: age,
                gender: gender,
                category: category,
                language: language,
                image: image
            )
        }
        
        return storyId
    }
    
    // MARK: - Image Generation
    
    /// Download and save image to disk - ROBUST VERSION
    private func downloadAndSaveImage(from urlString: String, pageId: UUID) async -> String? {
        // 1. Validate URL
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return nil
        }
        
        do {
            // 2. Download Data (THE CRITICAL STEP!)
            print("⬇️ Downloading image from: \(urlString.prefix(60))...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Verify response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Download response: HTTP \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    print("❌ Bad HTTP status: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            print("✅ Downloaded: \(data.count) bytes (\(data.count / 1024) KB)")
            
            // 3. Create Filename
            let fileName = "\(pageId.uuidString).jpg"
            
            // 4. Save using FileManagerService (consistent with cover image)
            guard let savedFileName = fileManager.saveImage(data: data, fileName: fileName) else {
                print("❌ Failed to save image to disk")
                return nil
            }
            
            print("✅ Image saved as: \(savedFileName)")
            
            return savedFileName // Return the filename
            
        } catch {
            print("❌ Download/Save Error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URLError code: \(urlError.code.rawValue)")
            }
            return nil
        }
    }
    
    /// CLEAN REFACTORED: Generate images for all pages
    /// Flow: Fal.ai -> Download -> Save to Disk -> Update UI
    @MainActor
    private func generateImagesForStory(
        storyId: UUID,
        referencePhotoUrl: String,
        childName: String,
        theme: StoryTheme
    ) async {
        
        guard let storyIndex = stories.firstIndex(where: { $0.id == storyId }) else {
            print("❌ Story not found")
            return
        }
        
        let totalPages = stories[storyIndex].pages.count
        print("🎨 ========================================")
        print("🎨 STARTING IMAGE GENERATION")
        print("🎨 Total pages: \(totalPages)")
        print("🎨 Reference photo: \(referencePhotoUrl.prefix(60))...")
        print("🎨 Child name: \(childName)")
        print("🎨 Theme: \(theme.displayName)")
        print("🎨 ========================================\n")
        
        // CRITICAL: Generate a consistent seed for this story
        // Same seed = Same character appearance across all pages
        let storySeed = Int.random(in: 1000...999999)
        print("🎲 ========================================")
        print("🎲 STORY SEED GENERATED")
        print("🎲 Seed: \(storySeed)")
        print("🎲 Purpose: Same character across all 7 pages")
        print("🎲 Note: Nano Banana may not support seed")
        print("🎲 Primary identity: 4x reference images")
        print("🎲 ========================================\n")
        
        // Loop through each page
        for pageIndex in 0..<totalPages {
            let pageNumber = pageIndex + 1
            let page = stories[storyIndex].pages[pageIndex]
            
            print("\n📄 ========================================")
            print("📄 PAGE \(pageNumber)/\(totalPages)")
            print("📄 Title: \(page.title)")
            print("📄 ========================================")
            
            // Update status
            updateStoryStatus(
                storyId: storyId,
                status: .generatingImages,
                progress: "Sayfa \(pageNumber)/\(totalPages) çiziliyor..."
            )
            
            do {
                // ✅ FIX: Use imagePrompt instead of text!
                // imagePrompt has detailed scene description from Gemini
                let promptToUse = page.imagePrompt.isEmpty ? page.text : page.imagePrompt
                
                print("📝 Scene prompt: \(promptToUse.prefix(150))...")
                print("🎯 Identity: Using 4x reference images + seed \(storySeed)")
                
                // A. Generate Link with CONSISTENT SEED + REFERENCE PHOTO
                let remoteUrl = try await FalAIImageGenerator.shared.generateImage(
                    prompt: promptToUse,  // ✅ Use detailed imagePrompt
                    referenceImageUrl: referencePhotoUrl,  // ✅ Pass reference photo
                    style: theme.rawValue,
                    seed: storySeed  // ✅ SAME seed for all pages = consistent character
                )
                print("✅ Remote URL received: \(remoteUrl.prefix(60))...")
                
                // B. Download & Save
                print("⬇️ Downloading image...")
                if let localFileName = await downloadAndSaveImage(from: remoteUrl, pageId: page.id) {
                    // C. Update Model & Save
                    await MainActor.run {
                        stories[storyIndex].pages[pageIndex].imageUrl = localFileName
                        saveStories() // Update UI immediately
                        objectWillChange.send()
                    }
                    
                    print("✅ ========================================")
                    print("✅ PAGE \(pageNumber) COMPLETE!")
                    print("✅ Saved as: \(localFileName)")
                    print("✅ Identity: Same child as reference photo")
                    print("✅ ========================================\n")
                } else {
                    print("❌ ========================================")
                    print("❌ PAGE \(pageNumber) DOWNLOAD FAILED")
                    print("❌ Could not save image to disk")
                    print("❌ ========================================\n")
                }
                
            } catch {
                print("❌ ========================================")
                print("❌ PAGE \(pageNumber) GENERATION FAILED")
                print("❌ Error: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("❌ URLError code: \(urlError.code.rawValue)")
                }
                print("❌ Continuing with next page...")
                print("❌ ========================================\n")
                // Continue with next page
            }
            
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        print("🎉 All images generated!")
        
        // Mark story as completed
        updateStoryStatus(storyId: storyId, status: .completed, progress: "Tamamlandı!")
    }
    
    // MARK: - Story Text Generation
    
    /// Generates story in background with status updates
    private func generateStoryInBackground(
        storyId: UUID,
        childName: String,
        age: Int,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        image: UIImage,
        customTitle: String?
    ) async {
        
        print("🎬 ========================================")
        print("🎬 STORY GENERATION STARTED")
        print("🎬 Story ID: \(storyId)")
        print("🎬 Child: \(childName), Age: \(age)")
        print("🎬 Theme: \(theme.displayName)")
        print("🎬 ========================================\n")
        
        do {
            // STEP 1: Upload photo to Firebase
            print("📤 ========================================")
            print("📤 STEP 1: Uploading photo to Firebase...")
            print("📤 ========================================")
            updateStoryStatus(storyId: storyId, status: .uploading, progress: "Fotoğraf yükleniyor...")
            
            let downloadURL = try await firebaseUploader.uploadImageToFirebase(image: image)
            print("✅ Firebase upload successful!")
            print("✅ URL: \(downloadURL)\n")
            
            // Update story with Firebase URL
            updateStoryCoverUrl(storyId: storyId, url: downloadURL)
            
            // STEP 2: Generate story text with Gemini
            print("✍️ ========================================")
            print("✍️ STEP 2: Writing story with Gemini...")
            print("✍️ ========================================")
            updateStoryStatus(storyId: storyId, status: .writingStory, progress: "Hikaye yazılıyor...")
            
            let storyPages = try await generateStoryText(
                childName: childName,
                age: age,
                gender: gender,
                theme: theme,
                language: language,
                customTitle: customTitle,
                photoData: image.jpegData(compressionQuality: 0.8)
            )
            
            print("✅ Story text generated!")
            print("✅ Pages: \(storyPages.count)\n")
            
            // Update story with pages (text only)
            updateStoryPages(storyId: storyId, pages: storyPages)
            
            // STEP 3: Generate illustrations for each page
            print("🎨 ========================================")
            print("🎨 STEP 3: Generating illustrations...")
            print("🎨 Total pages: \(storyPages.count)")
            print("🎨 ========================================\n")
            updateStoryStatus(storyId: storyId, status: .generatingImages, progress: "İllüstrasyonlar oluşturuluyor... (0/\(storyPages.count))")
            
            // Generate images for all pages
            await generateImagesForStory(storyId: storyId, referencePhotoUrl: downloadURL, childName: childName, theme: theme)
            
            // STEP 4: Mark as completed and send notification
            print("🎉 ========================================")
            print("🎉 STORY GENERATION COMPLETED!")
            print("🎉 Story ID: \(storyId)")
            print("🎉 ========================================\n")
            updateStoryStatus(storyId: storyId, status: .completed, progress: "Tamamlandı!")
            
            // Send local notification
            LocalNotificationManager.shared.sendNotification(
                title: "Kitabın Hazır! 📚",
                body: "\(childName)'in hikayesi tamamlandı, şimdi okuyabilirsin!"
            )
            
        } catch {
            print("❌ ========================================")
            print("❌ STORY GENERATION FAILED!")
            print("❌ Story ID: \(storyId)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error: \(error)")
            print("❌ Error Description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error Domain: \(nsError.domain)")
                print("❌ Error Code: \(nsError.code)")
                print("❌ Error UserInfo: \(nsError.userInfo)")
            }
            print("❌ ========================================\n")
            updateStoryStatus(storyId: storyId, status: .failed, progress: "Hata: \(error.localizedDescription)")
        }
    }
    
    /// Generates category-based story in background with status updates
    private func generateCategoryStoryInBackground(
        storyId: UUID,
        childName: String,
        age: Int,
        gender: Gender,
        category: DailyStoryCategory,
        language: StoryLanguage,
        image: UIImage
    ) async {
        
        print("🎬 ========================================")
        print("🎬 CATEGORY STORY GENERATION STARTED")
        print("🎬 Story ID: \(storyId)")
        print("🎬 Child: \(childName), Age: \(age)")
        print("🎬 Category: \(category.displayName)")
        print("🎬 ========================================\n")
        
        do {
            // STEP 1: Upload photo to Firebase
            print("📤 ========================================")
            print("📤 STEP 1: Uploading photo to Firebase...")
            print("📤 ========================================")
            updateStoryStatus(storyId: storyId, status: .uploading, progress: "Fotoğraf yükleniyor...")
            
            let downloadURL = try await firebaseUploader.uploadImageToFirebase(image: image)
            print("✅ Firebase upload successful!")
            print("✅ URL: \(downloadURL)\n")
            
            // Update story with Firebase URL
            updateStoryCoverUrl(storyId: storyId, url: downloadURL)
            
            // STEP 2: Generate category-specific story text with Gemini
            print("✍️ ========================================")
            print("✍️ STEP 2: Writing category story with Gemini...")
            print("✍️ Category: \(category.displayName)")
            print("✍️ ========================================")
            updateStoryStatus(storyId: storyId, status: .writingStory, progress: "Hikaye yazılıyor...")
            
            let storyPages = try await generateCategoryStoryText(
                childName: childName,
                age: age,
                gender: gender,
                category: category,
                language: language,
                photoData: image.jpegData(compressionQuality: 0.8)
            )
            
            print("✅ Category story text generated!")
            print("✅ Pages: \(storyPages.count)\n")
            
            // Update story with pages (text only)
            updateStoryPages(storyId: storyId, pages: storyPages)
            
            // STEP 3: Generate illustrations for each page
            let theme = categoryToTheme(category)
            print("🎨 ========================================")
            print("🎨 STEP 3: Generating illustrations...")
            print("🎨 Total pages: \(storyPages.count)")
            print("🎨 Theme: \(theme.displayName)")
            print("🎨 ========================================\n")
            updateStoryStatus(storyId: storyId, status: .generatingImages, progress: "İllüstrasyonlar oluşturuluyor... (0/\(storyPages.count))")
            
            // Generate images for all pages
            await generateImagesForStory(storyId: storyId, referencePhotoUrl: downloadURL, childName: childName, theme: theme)
            
            // STEP 4: Mark as completed and send notification
            print("🎉 ========================================")
            print("🎉 CATEGORY STORY GENERATION COMPLETED!")
            print("🎉 Story ID: \(storyId)")
            print("🎉 Category: \(category.displayName)")
            print("🎉 ========================================\n")
            updateStoryStatus(storyId: storyId, status: .completed, progress: "Tamamlandı!")
            
            // Send local notification
            LocalNotificationManager.shared.sendNotification(
                title: "Kitabın Hazır! 📚",
                body: "\(childName)'in \(category.displayName) hikayesi tamamlandı!"
            )
            
        } catch {
            print("❌ ========================================")
            print("❌ CATEGORY STORY GENERATION FAILED!")
            print("❌ Story ID: \(storyId)")
            print("❌ Category: \(category.displayName)")
            print("❌ Error: \(error.localizedDescription)")
            print("❌ ========================================\n")
            updateStoryStatus(storyId: storyId, status: .failed, progress: "Hata: \(error.localizedDescription)")
        }
    }
    
    /// Generates story text using Gemini with structured JSON format
    private func generateStoryText(
        childName: String,
        age: Int,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        customTitle: String?,
        photoData: Data?
    ) async throws -> [StoryPage] {
        
        print("✍️ Generating structured story with Gemini...")
        
        // ✅ USE STRUCTURED STORY GENERATION
        do {
            let storyResponse = try await aiService.generateStructuredStory(
                childName: childName,
                age: age,
                theme: theme.rawValue,
                language: language == .turkish ? "tr" : "en",
                photoData: photoData
            )
            
            print("✅ Structured story generated!")
            print("✅ Title: \(storyResponse.title)")
            print("✅ Pages: \(storyResponse.pages.count)")
            
            // Convert to StoryPage format
            let pages = storyResponse.pages.map { pageData in
                StoryPage(
                    title: pageData.title,
                    text: pageData.text,
                    imagePrompt: pageData.imagePrompt  // ✅ Use detailed imagePrompt from Gemini
                )
            }
            
            // Verify we have exactly 7 pages
            guard pages.count == 7 else {
                print("⚠️ Warning: Got \(pages.count) pages instead of 7, using demo mode")
                return generateDemoPages(childName: childName, theme: theme, language: language)
            }
            
            return pages
            
        } catch {
            print("❌ Structured story generation failed: \(error)")
            print("⚠️ Falling back to demo mode")
            return generateDemoPages(childName: childName, theme: theme, language: language)
        }
    }
    
    /// Creates a story prompt for Gemini
    private func createStoryPrompt(
        childName: String,
        age: Int,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        customTitle: String?
    ) -> String {
        
        let languageInstruction = language == .turkish ?
            "Hikayeyi Türkçe yazın." :
            "Write the story in English."
        
        let genderPronoun = language == .turkish ?
            (gender == .boy ? "o (erkek)" : gender == .girl ? "o (kız)" : "o") :
            (gender == .boy ? "he/him" : gender == .girl ? "she/her" : "they/them")
        
        let themeDescription = theme.description
        
        let prompt = """
        \(languageInstruction)
        
        \(age) yaşındaki \(childName) adlı çocuk için \(themeDescription) temalı bir hikaye yazın.
        Çocuğun cinsiyeti: \(genderPronoun)
        
        Hikaye şu özelliklere sahip olmalı:
        - TAM OLARAK 7 bölümden oluşmalı
        - Her bölüm 2-3 cümle olmalı
        - Çocuğun yaşına uygun olmalı (\(age) yaş)
        - Eğitici ve ilham verici olmalı
        - \(childName) ana karakter olmalı ve her bölümde aktif rol almalı
        - Macera dolu ve heyecan verici olmalı
        
        ZORUNLU FORMAT - Bu formatı kesinlikle takip edin:
        BÖLÜM 1: [Kısa başlık]
        [2-3 cümlelik hikaye metni]
        
        BÖLÜM 2: [Kısa başlık]
        [2-3 cümlelik hikaye metni]
        
        ... (7 bölüm)
        
        Lütfen sadece hikayeyi yazın, başka açıklama eklemeyin.
        """
        
        if let customTitle = customTitle, !customTitle.isEmpty {
            return prompt + "\n\nHikaye genel konusu: \(customTitle)"
        }
        
        return prompt
    }
    
    /// Parses Gemini response into story pages
    private func parseStoryContent(_ content: String, language: StoryLanguage) -> [StoryPage] {
        let lines = content.components(separatedBy: .newlines)
        var pages: [StoryPage] = []
        var currentTitle = ""
        var currentText = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("BÖLÜM") || trimmedLine.hasPrefix("CHAPTER") ||
               trimmedLine.hasPrefix("Bölüm") || trimmedLine.hasPrefix("Chapter") {
                
                if !currentTitle.isEmpty && !currentText.isEmpty {
                    pages.append(StoryPage(
                        title: currentTitle,
                        text: currentText.trimmingCharacters(in: .whitespacesAndNewlines),
                        imagePrompt: currentText
                    ))
                }
                
                currentTitle = trimmedLine
                currentText = ""
            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("**") {
                currentText += trimmedLine + " "
            }
        }
        
        if !currentTitle.isEmpty && !currentText.isEmpty {
            pages.append(StoryPage(
                title: currentTitle,
                text: currentText.trimmingCharacters(in: .whitespacesAndNewlines),
                imagePrompt: currentText
            ))
        }
        
        // Ensure exactly 7 pages
        if pages.count != 7 {
            return generateDemoPages(childName: "Child", theme: .fantasy, language: language)
        }
        
        return pages
    }
    
    /// Generates category-specific story text using Gemini
    private func generateCategoryStoryText(
        childName: String,
        age: Int,
        gender: Gender,
        category: DailyStoryCategory,
        language: StoryLanguage,
        photoData: Data?
    ) async throws -> [StoryPage] {
        
        print("✍️ Generating category-specific story with Gemini...")
        print("📂 Category: \(category.displayName)")
        
        // Convert category to string for AI
        let categoryString = category.rawValue
        
        do {
            let storyResponse = try await aiService.generateCategorySpecificStory(
                childName: childName,
                age: age,
                category: categoryString,
                language: language == .turkish ? "tr" : "en",
                photoData: photoData
            )
            
            print("✅ Category story generated!")
            print("✅ Title: \(storyResponse.title)")
            print("✅ Pages: \(storyResponse.pages.count)")
            print("✅ Category: \(category.displayName)")
            
            // Convert to StoryPage format
            let pages = storyResponse.pages.map { pageData in
                StoryPage(
                    title: pageData.title,
                    text: pageData.text,
                    imagePrompt: pageData.imagePrompt
                )
            }
            
            // Verify we have exactly 7 pages
            guard pages.count == 7 else {
                print("⚠️ Warning: Got \(pages.count) pages instead of 7")
                return generateDemoPages(childName: childName, theme: categoryToTheme(category), language: language)
            }
            
            return pages
            
        } catch {
            print("❌ Category story generation failed: \(error)")
            print("⚠️ Falling back to demo mode")
            return generateDemoPages(childName: childName, theme: categoryToTheme(category), language: language)
        }
    }
    
    /// Generates demo story pages - LONG VERSION
    private func generateDemoPages(childName: String, theme: StoryTheme, language: StoryLanguage) -> [StoryPage] {
        let texts = getDemoTexts(for: theme, language: language, childName: childName)
        
        return texts.enumerated().map { index, text in
            StoryPage(
                title: language == .turkish ? "Bölüm \(index + 1)" : "Chapter \(index + 1)",
                text: text,
                imagePrompt: text
            )
        }
    }
    
    /// Gets demo texts for a theme - LONG VERSION (150+ words per page)
    private func getDemoTexts(for theme: StoryTheme, language: StoryLanguage, childName: String) -> [String] {
        // LONG demo texts (150+ words each)
        let turkishTexts: [String] = [
            "\(childName) sabah güneşinin ışıklarıyla uyandı. Pencereden içeri süzülen altın renkli ışınlar, odanın her köşesini aydınlatıyordu. Kuşların cıvıltıları ve uzaktan gelen çiçek kokuları, güzel bir günün başlangıcını müjdeliyordu. \(childName) yataktan kalktı ve pencereye koştu. Dışarıda, arka bahçedeki eski meşe ağacının arkasında garip bir ışıltı gördü. 'Bu ne olabilir?' diye düşündü merakla. Kahvaltıda annesine bu konuda bir şey söylemek istedi ama kelimeler boğazında düğümlendi. Belki de önce kendisi keşfetmeliydi. Kahvaltısını hızla bitirip bahçeye koştu. Meşe ağacının arkasına vardığında, gözlerine inanamadı. Orada, ağacın gövdesinde parlayan, mor ve mavi ışıklarla çevrili sihirli bir kapı vardı. Kalbi hızla çarpmaya başladı. Bu bir rüya mıydı yoksa gerçek mi?",
            
            "\(childName) titreyen elleriyle kapının tokmağına dokundu. Kapı yavaşça açıldı ve içeriden tatlı bir melodi duyuldu. Cesaret toplayarak içeri adım attı. Gözlerini açtığında kendini bambaşka bir dünyada buldu. Etrafı konuşan hayvanlarla doluydu. Tavşanlar şapka takıyor, sincaplar dans ediyor, kuşlar şarkı söylüyordu. Uzakta, bulutların arasında yükselen ışıltılı bir kale görünüyordu. 'Hoş geldin \(childName)!' dedi yanından geçen kırmızı bir tilki. \(childName) şaşkınlıkla etrafına bakındı. 'Burası neresi?' diye sordu. 'Burası Sihirli Krallık,' dedi tilki gülümseyerek. 'Seni bekliyorduk. Krallığımızın sana ihtiyacı var.' \(childName)'in aklı karışmıştı ama aynı zamanda heyecan doluydu. Bu maceranın başlangıcıydı ve o hazırdı. Tilkiyi takip ederek kaleye doğru yürümeye başladı.",
            
            "Yolda ilerlerken, \(childName) etrafındaki muhteşem manzarayı izliyordu. Ağaçlar gökkuşağı renklerindeydi, çiçekler müzik çalıyordu, nehir kristal gibi berraktı. Her şey o kadar güzeldi ki gözlerine inanamıyordu. Kaleye yaklaştıklarında, büyük bir baykuş onları karşıladı. 'Ben Bilge Baykuş,' dedi derin bir sesle. 'Krallığımız büyük bir tehlike altında. Kötü büyücü, krallığın gücünü veren Altın Taç'ı çaldı ve Karanlık Orman'da sakladı. Sadece saf kalpli bir çocuk onu bulabilir.' \(childName) derin bir nefes aldı. 'Ben bulabilirim,' dedi kararlılıkla. Baykuş gülümsedi. 'Biliyordum. İşte sana yardımcı olacak sihirli bir harita ve bir fener. Yolun zor olacak ama sen güçlüsün.' \(childName) haritayı ve feneri aldı. Macera başlıyordu ve o hazırdı.",
            
            "\(childName) Karanlık Orman'a doğru yola çıktı. Orman gerçekten de karanlıktı ama feneri her şeyi aydınlatıyordu. Yolda ilerlerken, bir ağacın arkasından küçük bir peri çıktı. 'Merhaba! Ben Işıltı,' dedi neşeyle. 'Sana yardım edebilir miyim?' \(childName) gülümsedi. 'Altın Taç'ı arıyorum,' dedi. 'Ah, o çok tehlikeli bir yer!' dedi Işıltı. 'Ama ben sana yol gösterebilirim. Birlikte gidelim!' İkili birlikte yürümeye başladı. Işıltı, \(childName)'e ormanın sırlarını anlattı. Hangi mantarların yenilebileceğini, hangi yolların güvenli olduğunu öğretti. \(childName) yeni arkadaşına çok minnettar oldu. Birlikte her engeli aşabileceklerini biliyordu. Sonunda, bir mağaranın girişine vardılar. 'Taç burada,' dedi Işıltı. 'Ama dikkatli ol, mağara tuzaklarla dolu.'",
            
            "Mağaraya girdiklerinde, her yer karanlıktı. Fener ışığı duvarlarda dans ediyordu. Birden, önlerinde büyük bir uçurum belirdi. 'Nasıl geçeceğiz?' diye sordu \(childName) endişeyle. Işıltı düşündü. 'Sihirli köprü büyüsü yapabilirim ama senin inancına ihtiyacım var. Gözlerini kapat ve geçebileceğimize inan.' \(childName) gözlerini kapattı ve derin bir nefes aldı. İnandı. Işıltı büyüyü yaptı ve aniden altın bir köprü belirdi. Birlikte köprüden geçtiler. Mağaranın derinliklerinde, bir kaide üzerinde parlayan Altın Taç duruyordu. \(childName) heyecanla koştu ama Işıltı onu durdurdu. 'Bekle! Etrafında koruma büyüsü var. Sadece saf kalpli biri dokunabilir.' \(childName) yavaşça yaklaştı ve taca dokundu. Taç parladı ve büyü bozuldu. Başarmışlardı!",
            
            "\(childName) ve Işıltı tacı alıp kaleye geri döndüler. Tüm krallık onları bekliyordu. Kral, tahtından kalktı ve \(childName)'e doğru yürüdü. 'Krallığımızı kurtardın genç kahraman,' dedi gururla. 'Sana nasıl teşekkür etsek az.' Tüm hayvanlar alkışladı ve şarkılar söyledi. Kral, \(childName)'in başına küçük bir taç koydu. 'Bundan böyle sen bu krallığın onursal kahramanısın. İstediğin zaman buraya gelebilirsin.' \(childName)'in gözleri doldu. Hayatının en güzel gününü yaşıyordu. Işıltı ve diğer arkadaşlarıyla dans etti, şarkılar söyledi. Ama yavaş yavaş eve dönme zamanı geliyordu. Vedalaştı ve sihirli kapıdan geçti. Arka bahçede kendini bulduğunda, her şey bir rüya gibiydi. Ama cebindeki küçük taç gerçekti.",
            
            "O gece, \(childName) yatağına uzandı ve gününü düşündü. Ne kadar inanılmaz bir macera yaşamıştı! Sihirli bir krallık, konuşan hayvanlar, cesur bir görev... Hepsi gerçekti. Annesi gelip onu öptü. 'İyi geceler tatlım,' dedi. 'Güzel rüyalar gör.' \(childName) gülümsedi. 'Anneciğim, bugün harika bir macera yaşadım,' dedi. Annesi saçlarını okşadı. 'Eminim öyle olmuştur,' dedi sevgiyle. \(childName) gözlerini kapadı. Yarın yine Sihirli Krallık'a gidebileceğini biliyordu. Işıltı ve diğer arkadaşları onu bekliyordu. Belki de yeni bir macera yaşarlardı. Kim bilir, belki de ejderhalarla tanışırdı ya da uçan bir atla gökyüzünde gezinirdi. Olasılıklar sonsuzdı. Mutlu bir gülümsemeyle uykuya daldı, rüyalarında yeni maceralara yelken açtı."
        ]
        
        return language == .turkish ? turkishTexts : turkishTexts
    }
    
    /// Creates professional children's book illustration prompt
    private func createChildFriendlyPrompt(
        storyText: String,
        childName: String,
        theme: StoryTheme,
        pageNumber: Int
    ) -> String {
        
        // Determine art style based on theme
        let artStyle = getArtStyleForTheme(theme)
        
        return """
        As an expert children's book illustrator, generate a high-quality illustration that meticulously preserves the unique identity and facial features of the child in the reference photo—ensuring their eye shape, hair details, and facial structure remain strictly recognizable—while stylizing them into a vivid \(artStyle) aesthetic as they perform the action '\(storyText)', maintaining perfect setting consistency if a scene photo is provided, and ensuring the child is the central focus of the composition while strictly avoiding generic character faces, distorted anatomy, or any loss of the child's specific likeness.
        
        Character: \(childName)
        Scene: \(storyText)
        Art Style: \(artStyle)
        Theme: \(theme.displayName)
        Page: \(pageNumber)
        
        Requirements:
        - Preserve child's exact facial features from reference photo
        - High-quality children's book illustration style
        - Child as central focus of composition
        - Vibrant, engaging colors appropriate for children
        - Professional illustration quality
        - Avoid generic faces or distorted anatomy
        """
    }
    
    /// Gets appropriate art style for theme
    private func getArtStyleForTheme(_ theme: StoryTheme) -> String {
        switch theme {
        case .fantasy:
            return "magical fantasy children's book illustration with enchanted elements"
        case .space:
            return "cosmic adventure children's book illustration with space elements"
        case .jungle:
            return "vibrant jungle adventure children's book illustration with tropical elements"
        case .hero:
            return "superhero children's book illustration with dynamic action elements"
        case .underwater:
            return "underwater adventure children's book illustration with marine elements"
        case .custom:
            return "whimsical children's book illustration with creative storytelling elements"
        }
    }
    
    /// Downloads image data from URL
    private func downloadImageData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    /// Generates a title for the story
    private func generateTitle(theme: StoryTheme, language: StoryLanguage) -> String {
        let turkishTitles: [StoryTheme: [String]] = [
            .fantasy: ["Sihirli Krallık Macerası", "Kristal Taç Arayışı", "Büyülü Orman Gizemi"],
            .space: ["Yıldızlara Yolculuk", "Kozmik Macera", "Zephyr Gezegeni Görevi"],
            .jungle: ["Büyük Orman Keşfi", "Amazon'da Kaybolmak", "Altın Tapınak Sırrı"],
            .hero: ["Süper Kahraman Doğuşu", "Şehri Kurtarmak", "İçimizdeki Güç"],
            .underwater: ["Okyanusun Sırrı", "Derin Deniz Keşfi", "Denizkızının Arayışı"],
            .custom: ["Harika Bir Macera", "İnanılmaz Yolculuk", "Sihirli Bir Hikaye"]
        ]
        
        let titles = language == .turkish ? turkishTitles : turkishTitles
        let themeTitle = titles[theme] ?? titles[.custom]!
        return themeTitle.randomElement() ?? "Sihirli Bir Macera"
    }
    
    // MARK: - Story Updates
    
    private func updateStoryStatus(storyId: UUID, status: StoryStatus, progress: String) {
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            stories[index].status = status
            stories[index].currentProgress = progress
            saveStories()
        }
    }
    
    private func updateStoryCoverUrl(storyId: UUID, url: String) {
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            stories[index].coverImageUrl = url
            saveStories()
        }
    }
    
    private func updateStoryPages(storyId: UUID, pages: [StoryPage]) {
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            stories[index].pages = pages
            saveStories()
        }
    }
    
    private func updatePageImage(storyId: UUID, pageId: UUID, imageUrl: String, imageFileName: String?) {
        if let storyIndex = stories.firstIndex(where: { $0.id == storyId }),
           let pageIndex = stories[storyIndex].pages.firstIndex(where: { $0.id == pageId }) {
            stories[storyIndex].pages[pageIndex].imageUrl = imageUrl
            stories[storyIndex].pages[pageIndex].imageFileName = imageFileName
            saveStories()
        }
    }
    
    // MARK: - Persistence
    
    private func saveStories() {
        if let encoded = try? JSONEncoder().encode(stories) {
            let dataSize = encoded.count
            print("💾 Saving stories to UserDefaults: \(dataSize) bytes (\(dataSize / 1024) KB)")
            
            // Check if size is reasonable (< 1MB for UserDefaults)
            if dataSize > 1_000_000 {
                print("⚠️ WARNING: Stories data is large (\(dataSize / 1024 / 1024) MB). Consider cleanup.")
            }
            
            UserDefaults.standard.set(encoded, forKey: "stories")
        }
    }
    
    private func loadStories() {
        if let data = UserDefaults.standard.data(forKey: "stories"),
           let decoded = try? JSONDecoder().decode([Story].self, from: data) {
            stories = decoded
            print("✅ Loaded \(stories.count) stories from UserDefaults")
        }
    }
    
    /// Migrates old stories that have Data properties to new file-based system
    private func migrateOldStoriesIfNeeded() {
        // Check if old data exists and is too large
        if let oldData = UserDefaults.standard.data(forKey: "stories") {
            let oldSize = oldData.count
            print("📊 Current UserDefaults size: \(oldSize) bytes (\(oldSize / 1024 / 1024) MB)")
            
            // If data is > 4MB, it's likely the old format with embedded images
            if oldSize > 4_000_000 {
                print("🔄 Migrating old stories to file-based storage...")
                
                // Clear the bloated data
                UserDefaults.standard.removeObject(forKey: "stories")
                UserDefaults.standard.synchronize()
                
                print("✅ Cleared old bloated UserDefaults data")
                print("⚠️ Note: Old story images were removed. New stories will use file storage.")
                
                // Reset stories array
                stories = []
            }
        }
        
        // CRITICAL FIX: Check for stories with missing imageUrl but have imageFileName
        // This happens when stories were created before the imageUrl fix
        var needsSave = false
        for (_, story) in stories.enumerated() {
            for (pageIndex, page) in story.pages.enumerated() {
                // If page has no imageUrl but has imageFileName, try to load from file
                if page.imageUrl == nil && page.imageFileName != nil {
                    print("⚠️ Found page without imageUrl: Story '\(story.title)' Page \(pageIndex + 1)")
                    print("   This is an old story that needs migration")
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            print("⚠️ Found \(stories.count) stories that may need imageUrl migration")
            print("⚠️ These stories will display placeholder images")
            print("💡 Solution: Delete old stories and create new ones, OR manually add imageUrls")
        }
    }
    
    // MARK: - Public Helpers
    
    func deleteStory(id: UUID) {
        // Delete images from file system
        fileManager.deleteStoryImages(storyId: id)
        
        // Remove from array
        stories.removeAll { $0.id == id }
        saveStories()
        
        print("✅ Story deleted: \(id)")
    }
    
    func getStory(id: UUID) -> Story? {
        return stories.first { $0.id == id }
    }
    
    // MARK: - Sample Stories
    
    private func createSampleStoriesIfNeeded() {
        // Sadece hiç hikaye yoksa örnek hikayeler oluştur
        guard stories.isEmpty else { return }
        
        print("📚 Creating sample stories...")
        
        let sampleStories = [
            createSampleStory(
                title: "Zephyr'in Sihirli Macerası",
                childName: "Zephyr",
                theme: .fantasy,
                pages: [
                    ("Sihirli Başlangıç", "Zephyr sabah güneşinin ışıklarıyla uyandı. Pencereden içeri süzülen altın renkli ışınlar, odanın her köşesini aydınlatıyordu. Kuşların cıvıltıları ve uzaktan gelen çiçek kokuları, güzel bir günün başlangıcını müjdeliyordu. Zephyr yataktan kalktı ve pencereye koştu. Dışarıda, arka bahçedeki eski meşe ağacının arkasında garip bir ışıltı gördü. 'Bu ne olabilir?' diye düşündü merakla. Kahvaltıda annesine bu konuda bir şey söylemek istedi ama kelimeler boğazında düğümlendi. Belki de önce kendisi keşfetmeliydi. Kahvaltısını hızla bitirip bahçeye koştu. Meşe ağacının arkasına vardığında, gözlerine inanamadı. Orada, ağacın gövdesinde parlayan, mor ve mavi ışıklarla çevrili sihirli bir kapı vardı."),
                    ("Sihirli Krallık", "Zephyr titreyen elleriyle kapının tokmağına dokundu. Kapı yavaşça açıldı ve içeriden tatlı bir melodi duyuldu. Cesaret toplayarak içeri adım attı. Gözlerini açtığında kendini bambaşka bir dünyada buldu. Etrafı konuşan hayvanlarla doluydu. Tavşanlar şapka takıyor, sincaplar dans ediyor, kuşlar şarkı söylüyordu. Uzakta, bulutların arasında yükselen ışıltılı bir kale görünüyordu. 'Hoş geldin Zephyr!' dedi yanından geçen kırmızı bir tilki. Zephyr şaşkınlıkla etrafına bakındı. 'Burası neresi?' diye sordu. 'Burası Sihirli Krallık,' dedi tilki gülümseyerek. 'Seni bekliyorduk. Krallığımızın sana ihtiyacı var.' Zephyr'in aklı karışmıştı ama aynı zamanda heyecan doluydu."),
                    ("Bilge Baykuş", "Yolda ilerlerken, Zephyr etrafındaki muhteşem manzarayı izliyordu. Ağaçlar gökkuşağı renklerindeydi, çiçekler müzik çalıyordu, nehir kristal gibi berraktı. Her şey o kadar güzeldi ki gözlerine inanamıyordu. Kaleye yaklaştıklarında, büyük bir baykuş onları karşıladı. 'Ben Bilge Baykuş,' dedi derin bir sesle. 'Krallığımız büyük bir tehlike altında. Kötü büyücü, krallığın gücünü veren Altın Taç'ı çaldı ve Karanlık Orman'da sakladı. Sadece saf kalpli bir çocuk onu bulabilir.' Zephyr derin bir nefes aldı. 'Ben bulabilirim,' dedi kararlılıkla. Baykuş gülümsedi. 'Biliyordum. İşte sana yardımcı olacak sihirli bir harita ve bir fener.'"),
                    ("Işıltı ile Tanışma", "Zephyr Karanlık Orman'a doğru yola çıktı. Orman gerçekten de karanlıktı ama feneri her şeyi aydınlatıyordu. Yolda ilerlerken, bir ağacın arkasından küçük bir peri çıktı. 'Merhaba! Ben Işıltı,' dedi neşeyle. 'Sana yardım edebilir miyim?' Zephyr gülümsedi. 'Altın Taç'ı arıyorum,' dedi. 'Ah, o çok tehlikeli bir yer!' dedi Işıltı. 'Ama ben sana yol gösterebilirim. Birlikte gidelim!' İkili birlikte yürümeye başladı. Işıltı, Zephyr'e ormanın sırlarını anlattı. Hangi mantarların yenilebileceğini, hangi yolların güvenli olduğunu öğretti. Zephyr yeni arkadaşına çok minnettar oldu. Birlikte her engeli aşabileceklerini biliyordu."),
                    ("Kristal Mağara", "Mağaraya girdiklerinde, her yer karanlıktı. Fener ışığı duvarlarda dans ediyordu. Birden, önlerinde büyük bir uçurum belirdi. 'Nasıl geçeceğiz?' diye sordu Zephyr endişeyle. Işıltı düşündü. 'Sihirli köprü büyüsü yapabilirim ama senin inancına ihtiyacım var. Gözlerini kapat ve geçebileceğimize inan.' Zephyr gözlerini kapattı ve derin bir nefes aldı. İnandı. Işıltı büyüyü yaptı ve aniden altın bir köprü belirdi. Birlikte köprüden geçtiler. Mağaranın derinliklerinde, bir kaide üzerinde parlayan Altın Taç duruyordu. Zephyr heyecanla koştu ama Işıltı onu durdurdu. 'Bekle! Etrafında koruma büyüsü var.' Zephyr yavaşça yaklaştı ve taca dokundu."),
                    ("Zafer Kutlaması", "Zephyr ve Işıltı tacı alıp kaleye geri döndüler. Tüm krallık onları bekliyordu. Kral, tahtından kalktı ve Zephyr'e doğru yürüdü. 'Krallığımızı kurtardın genç kahraman,' dedi gururla. 'Sana nasıl teşekkür etsek az.' Tüm hayvanlar alkışladı ve şarkılar söyledi. Kral, Zephyr'in başına küçük bir taç koydu. 'Bundan böyle sen bu krallığın onursal kahramanısın. İstediğin zaman buraya gelebilirsin.' Zephyr'in gözleri doldu. Hayatının en güzel gününü yaşıyordu. Işıltı ve diğer arkadaşlarıyla dans etti, şarkılar söyledi. Ama yavaş yavaş eve dönme zamanı geliyordu. Vedalaştı ve sihirli kapıdan geçti."),
                    ("Eve Dönüş", "O gece, Zephyr yatağına uzandı ve gününü düşündü. Ne kadar inanılmaz bir macera yaşamıştı! Sihirli bir krallık, konuşan hayvanlar, cesur bir görev... Hepsi gerçekti. Annesi gelip onu öptü. 'İyi geceler tatlım,' dedi. 'Güzel rüyalar gör.' Zephyr gülümsedi. 'Anneciğim, bugün harika bir macera yaşadım,' dedi. Annesi saçlarını okşadı. 'Eminim öyle olmuştur,' dedi sevgiyle. Zephyr gözlerini kapadı. Yarın yine Sihirli Krallık'a gidebileceğini biliyordu. Işıltı ve diğer arkadaşları onu bekliyordu. Belki de yeni bir macera yaşarlardı. Kim bilir, belki de ejderhalarla tanışırdı ya da uçan bir atla gökyüzünde gezinirdi. Mutlu bir gülümsemeyle uykuya daldı.")
                ]
            ),
            
            createSampleStory(
                title: "Luna'nın Uzay Yolculuğu",
                childName: "Luna",
                theme: .space,
                pages: [
                    ("Yıldızlara Bakış", "Luna her gece penceresinden yıldızları izlerdi. Gökyüzündeki sayısız ışık noktası onu büyülerdi. 'Acaba oralarda neler var?' diye düşünürdü. Bir gece, bahçede garip bir ışık gördü. Dışarı çıktığında, küçük ama parlak bir uzay gemisi buldu. Geminin kapısı açıktı ve içeriden davetkar bir ışık sızıyordu. Luna merakla içeri girdi. Kokpit koltuğuna oturduğunda, tüm düğmeler ve ekranlar canlandı. 'Hoş geldin Luna,' dedi geminin bilgisayarı. 'Uzay macerasına hazır mısın?' Luna heyecanla başını salladı. Kemer taktı ve büyük kırmızı butona bastı. Gemi yavaşça yerden kalktı ve gökyüzüne doğru hızla yükselmeye başladı."),
                    ("İlk Gezegen", "Luna ilk gezegenine indi. Her yer mor ve pembe renklerle doluydu. Ağaçlar kristalden, çiçekler ışık saçıyordu. Birden, üç gözlü yeşil bir yaratık belirdi. 'Merhaba! Ben Zyx,' dedi dostça. 'Hoş geldin gezegenmize!' Luna başta korkmuştu ama Zyx'in gülümsemesi onu rahatlattı. 'Ben Luna, Dünya'dan geliyorum,' dedi. Zyx heyecanlandı. 'Dünya! Orası hakkında çok şey duydum. Gel, sana gezegenmizi göstereyim!' İkili birlikte yürüdüler. Zyx, Luna'ya yüzen şehirlerini, müzik çalan çiçeklerini ve gökkuşağı renkli nehirlerini gösterdi. Luna her şeye hayran kalmıştı. Uzayın ne kadar muhteşem olduğunu şimdi anlıyordu."),
                    ("Asteroid Fırtınası", "Bir sonraki gezegene giderken, Luna büyük bir sorunla karşılaştı. Önünde dev bir asteroid fırtınası vardı. Kayalar her yöne savruluyordu. 'Ne yapacağım?' diye düşündü endişeyle. Geminin bilgisayarı devreye girdi. 'Sakin ol Luna. Sensörlerini kullan ve kayaların arasından geç.' Luna derin bir nefes aldı. Ellerini kumandaya koydu ve dikkatle ilerlemeye başladı. Sağa, sola, yukarı, aşağı... Her hareketi önemliydi. Bir kaya gemiye çarpmak üzereyken, Luna hızla manevra yaptı. Kalbi hızla çarpıyordu ama başarıyordu. Sonunda fırtınadan çıktı. 'Başardın Luna!' dedi bilgisayar. Luna gururla gülümsedi."),
                    ("Uzay İstasyonu", "Luna büyük bir uzay istasyonuna vardı. İçerisi farklı gezegenlerden gelen yaratıklarla doluydu. Herkes barış içinde yaşıyor, bilgi paylaşıyor ve birlikte çalışıyordu. Luna bir robot, bir peri ve bir bulut yaratığıyla tanıştı. Hepsi ona kendi dünyalarından bahsetti. Robot, teknoloji gezegeninden geliyordu. Peri, sihir diyarından. Bulut yaratığı ise gaz gezegeninden. 'Uzay çok büyük,' dedi robot. 'Ama hepimiz arkadaşız.' Luna mutluydu. Farklılıkların ne kadar güzel olduğunu öğrenmişti. Birlikte yemek yediler, oyunlar oynadılar ve hikayeler anlattılar. Luna Dünya'dan bahsetti ve herkes büyülenmiş dinledi."),
                    ("Kayıp Gezegen", "Uzay istasyonunda bir alarm çaldı. Bir gezegen yardım istiyordu. Güneşleri sönmek üzereydi ve her yer karanlığa gömülüyordu. 'Yardım etmeliyiz!' dedi Luna. Arkadaşları da katıldı. Hep birlikte o gezegene gittiler. Gezegen gerçekten de karanlıktı ve soğuktu. Halk üzgün ve korkmuştu. Luna düşündü. 'Belki güneşi yeniden ateşleyebiliriz!' Robot teknik bilgisini, peri sihirini, bulut yaratığı enerjisini kullandı. Luna da cesaretini ve umudunu ekledi. Hep birlikte güneşin etrafında bir enerji halkası oluşturdular. Yavaş yavaş güneş parlamaya başladı. Işık geri döndü! Gezegen halkı sevinçle bağırdı. Luna ve arkadaşları kahramandı."),
                    ("Yıldız Festivali", "Gezegeni kurtardıkları için büyük bir festival düzenlendi. Tüm uzaydan yaratıklar geldi. Müzik, dans, ışık gösterileri... Her şey muhteşemdi. Luna hiç bu kadar mutlu olmamıştı. Yeni arkadaşlarıyla dans etti, uzay yemekleri tattı ve yıldızların altında şarkılar söyledi. Kral, Luna'ya özel bir madalya verdi. 'Sen gerçek bir uzay kahramanısın,' dedi. 'Cesaretin ve kalbin sayesinde bir gezegeni kurtardın.' Luna'nın gözleri doldu. Bu macera ona çok şey öğretmişti. Cesaret, dostluk, yardımlaşma... Hepsi çok önemliydi. Gece sonunda, Luna gemisine bindi. Eve dönme zamanı gelmişti."),
                    ("Dünya'ya Dönüş", "Luna Dünya'ya dönerken, pencereden gezegenini izledi. Mavi ve yeşil, bulutlarla kaplı... Ne kadar güzeldi. Bahçeye yumuşak bir şekilde indi. Gemi ışıklarını söndürdü. 'Teşekkürler Luna,' dedi bilgisayar. 'Harika bir pilottun. İstediğin zaman geri gel.' Luna gemiye veda etti ve evine koştu. Yatağına uzandığında, tüm macera bir rüya gibi geldi. Ama cebindeki yıldız madalyası gerçekti. Annesi gelip onu öptü. 'İyi geceler Luna,' dedi. Luna gülümsedi. 'Anneciğim, bugün uzaya gittim,' dedi. Annesi saçlarını okşadı. 'Ne güzel bir hayal,' dedi. Luna gözlerini kapadı. Biliyordu ki bu sadece başlangıçtı. Uzay onu bekliyordu ve daha nice maceralar yaşayacaktı.")
                ]
            )
        ]
        
        stories = sampleStories
        saveStories()
        print("✅ Sample stories created: \(stories.count)")
    }
    
    private func createSampleStory(title: String, childName: String, theme: StoryTheme, pages: [(String, String)]) -> Story {
        let storyPages = pages.map { (pageTitle, pageText) in
            StoryPage(
                title: pageTitle,
                text: pageText,
                imagePrompt: pageText
            )
        }
        
        return Story(
            title: title,
            childName: childName,
            theme: theme,
            language: .turkish,
            status: .completed,
            pages: storyPages
        )
    }
    
    // MARK: - Category Helper Functions
    
    /// Maps DailyStoryCategory to StoryTheme for visual consistency
    private func categoryToTheme(_ category: DailyStoryCategory) -> StoryTheme {
        switch category {
        case .bedtime:
            return .fantasy // Magical, dreamy theme
        case .morning:
            return .space // Bright, energetic theme
        case .educational:
            return .custom // Flexible theme
        case .values:
            return .fantasy // Thoughtful, meaningful theme
        case .adventure:
            return .jungle // Exciting, bold theme
        case .nature:
            return .jungle // Natural, peaceful theme
        }
    }
    
    /// Generates category-specific title
    private func generateCategoryTitle(category: DailyStoryCategory, language: StoryLanguage, childName: String) -> String {
        if language == .turkish {
            switch category {
            case .bedtime:
                let titles = [
                    "\(childName)'in Rüya Yolculuğu",
                    "\(childName) ve Uyku Perisi",
                    "\(childName)'in Yıldızlı Gecesi",
                    "\(childName)'in Tatlı Rüyaları"
                ]
                return titles.randomElement() ?? "\(childName)'in Uyku Hikayesi"
                
            case .morning:
                let titles = [
                    "\(childName)'in Güneşli Sabahı",
                    "\(childName) ve Sabah Macerası",
                    "\(childName)'in Enerjik Günü",
                    "\(childName)'in Parlak Başlangıcı"
                ]
                return titles.randomElement() ?? "\(childName)'in Sabah Hikayesi"
                
            case .educational:
                let titles = [
                    "\(childName) Öğreniyor",
                    "\(childName)'in Keşif Yolculuğu",
                    "\(childName) ve Bilim Macerası",
                    "\(childName)'in Merak Dolu Günü"
                ]
                return titles.randomElement() ?? "\(childName)'in Öğretici Hikayesi"
                
            case .values:
                let titles = [
                    "\(childName)'in Kalbi",
                    "\(childName) ve Doğru Seçim",
                    "\(childName)'in İyi Kalbi",
                    "\(childName) ve Dostluk"
                ]
                return titles.randomElement() ?? "\(childName)'in Değerler Hikayesi"
                
            case .adventure:
                let titles = [
                    "\(childName)'in Büyük Macerası",
                    "\(childName) ve Hazine Arayışı",
                    "\(childName)'in Cesur Yolculuğu",
                    "\(childName) ve Gizemli Harita"
                ]
                return titles.randomElement() ?? "\(childName)'in Macera Hikayesi"
                
            case .nature:
                let titles = [
                    "\(childName) ve Doğa",
                    "\(childName)'in Orman Keşfi",
                    "\(childName) ve Hayvan Dostları",
                    "\(childName)'in Doğa Yolculuğu"
                ]
                return titles.randomElement() ?? "\(childName)'in Doğa Hikayesi"
            }
        } else {
            // English titles
            switch category {
            case .bedtime:
                return "\(childName)'s Dream Journey"
            case .morning:
                return "\(childName)'s Sunny Morning"
            case .educational:
                return "\(childName) Learns"
            case .values:
                return "\(childName)'s Kind Heart"
            case .adventure:
                return "\(childName)'s Great Adventure"
            case .nature:
                return "\(childName) and Nature"
            }
        }
    }
}
