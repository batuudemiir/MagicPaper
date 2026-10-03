import Foundation
import OSLog
import SwiftUI
import Combine
import StoryEngine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryGenerationManager")

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
        // Before anything reads the library: the migration needs the legacy
        // store exactly as the last launch left it, and it is the only thing
        // allowed to touch the `stories` key besides `save`/`load` below.
        LibraryPersistence.bootstrap()
        loadStories()
        auditStoriesMissingImageURLs()
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
        /// Whose story this is. Optional only so older call sites keep
        /// compiling; every real caller passes it.
        childProfileID: UUID? = nil,
        age: Int,
        gender: Gender,
        theme: StoryTheme,
        language: StoryLanguage,
        image: UIImage,
        customTitle: String? = nil,
        pageCount: Int = 7,
        tone: String? = nil
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
            childProfileID: childProfileID,
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
                customTitle: customTitle,
                pageCount: pageCount,
                tone: tone
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
        childProfileID: UUID? = nil,
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
            childProfileID: childProfileID,
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
            logger.error("❌ Invalid URL: \(urlString)")
            return nil
        }
        
        do {
            // 2. Download Data (THE CRITICAL STEP!)
            logger.debug("⬇️ Downloading image...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Verify response
            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("📡 Download response: HTTP \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    logger.error("❌ Bad HTTP status: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            logger.debug("✅ Downloaded: \(data.count) bytes (\(data.count / 1024) KB)")
            
            // 3. Create Filename
            let fileName = "\(pageId.uuidString).jpg"
            
            // 4. Save using FileManagerService (consistent with cover image)
            guard let savedFileName = fileManager.saveImage(data: data, fileName: fileName) else {
                logger.error("❌ Failed to save image to disk")
                return nil
            }
            
            logger.debug("✅ Image saved as: \(savedFileName)")
            
            return savedFileName // Return the filename
            
        } catch {
            logger.error("❌ Download/Save Error: \(String(describing: error))")
            logger.error("❌ Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                logger.error("❌ URLError code: \(urlError.code.rawValue)")
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
            logger.error("❌ Story not found")
            return
        }
        
        let totalPages = stories[storyIndex].pages.count
        logger.debug("🎨 STARTING IMAGE GENERATION")
        logger.debug("🎨 Total pages: \(totalPages)")
        logger.debug("🎨 Theme: \(theme.displayName)")
        
        // CRITICAL: Generate a consistent seed for this story
        // Same seed = Same character appearance across all pages
        let storySeed = Int.random(in: 1000...999999)
        logger.debug("🎲 STORY SEED GENERATED")
        logger.debug("🎲 Seed: \(storySeed)")
        logger.debug("🎲 Purpose: Same character across all 7 pages")
        logger.debug("🎲 Note: Nano Banana may not support seed")
        logger.debug("🎲 Primary identity: 4x reference images")
        
        // Loop through each page
        for pageIndex in 0..<totalPages {
            let pageNumber = pageIndex + 1
            let page = stories[storyIndex].pages[pageIndex]
            
            logger.debug("\n📄 ========================================")
            logger.debug("📄 PAGE \(pageNumber)/\(totalPages)")
            
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
                
                logger.debug("🎯 Identity: Using 4x reference images + seed \(storySeed)")
                
                // A. Generate Link with CONSISTENT SEED + REFERENCE PHOTO
                let remoteUrl = try await FalAIImageGenerator.shared.generateImage(
                    prompt: promptToUse,  // ✅ Use detailed imagePrompt
                    referenceImageUrl: referencePhotoUrl,  // ✅ Pass reference photo
                    style: theme.rawValue,
                    seed: storySeed  // ✅ SAME seed for all pages = consistent character
                )
                logger.debug("✅ Remote URL received: \(remoteUrl.prefix(60))...")
                
                // B. Download & Save
                logger.debug("⬇️ Downloading image...")
                if let localFileName = await downloadAndSaveImage(from: remoteUrl, pageId: page.id) {
                    // C. Update Model & Save
                    await MainActor.run {
                        stories[storyIndex].pages[pageIndex].imageUrl = localFileName
                        saveStories() // Update UI immediately
                        objectWillChange.send()
                    }
                    
                    logger.debug("✅ PAGE \(pageNumber) COMPLETE!")
                    logger.debug("✅ Saved as: \(localFileName)")
                    logger.debug("✅ Identity: Same child as reference photo")
                } else {
                    logger.error("❌ PAGE \(pageNumber) DOWNLOAD FAILED")
                    logger.error("❌ Could not save image to disk")
                }
                
            } catch {
                logger.error("❌ PAGE \(pageNumber) GENERATION FAILED")
                logger.error("❌ Error: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    logger.error("❌ URLError code: \(urlError.code.rawValue)")
                }
                logger.error("❌ Continuing with next page...")
                // Continue with next page
            }
            
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        logger.debug("🎉 All images generated!")
        
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
        customTitle: String?,
        pageCount: Int = 7,
        tone: String? = nil
    ) async {
        
        logger.debug("🎬 STORY GENERATION STARTED")
        logger.debug("🎬 Story ID: \(storyId)")
        logger.debug("🎬 Theme: \(theme.displayName)")
        
        // The raw child photo lives in Storage only while the pages are drawn.
        var uploadedPhotoURL: String?

        do {
            // STEP 1: Upload photo to Firebase
            logger.debug("📤 STEP 1: Uploading photo to Firebase...")
            updateStoryStatus(storyId: storyId, status: .uploading, progress: "Fotoğraf yükleniyor...")
            
            let downloadURL = try await firebaseUploader.uploadImageToFirebase(image: image)
            uploadedPhotoURL = downloadURL
            logger.debug("✅ Firebase upload successful!")
            
            // Update story with Firebase URL
            updateStoryCoverUrl(storyId: storyId, url: downloadURL)
            
            // STEP 2: Generate story text with Gemini
            logger.debug("✍️ STEP 2: Writing story with Gemini...")
            updateStoryStatus(storyId: storyId, status: .writingStory, progress: "Hikaye yazılıyor...")
            
            let storyPages = try await generateStoryText(
                childName: childName,
                age: age,
                gender: gender,
                theme: theme,
                language: language,
                customTitle: customTitle,
                photoData: image.jpegData(compressionQuality: 0.8),
                pageCount: pageCount,
                tone: tone
            )
            
            logger.debug("✅ Story text generated!")
            logger.debug("✅ Pages: \(storyPages.count)")
            
            // Update story with pages (text only)
            updateStoryPages(storyId: storyId, pages: storyPages)
            
            // STEP 3: Generate illustrations for each page
            logger.debug("🎨 STEP 3: Generating illustrations...")
            logger.debug("🎨 Total pages: \(storyPages.count)")
            updateStoryStatus(storyId: storyId, status: .generatingImages, progress: "İllüstrasyonlar oluşturuluyor... (0/\(storyPages.count))")
            
            // Generate images for all pages
            await generateImagesForStory(storyId: storyId, referencePhotoUrl: downloadURL, childName: childName, theme: theme)
            
            // STEP 4: Mark as completed and send notification
            logger.debug("🎉 STORY GENERATION COMPLETED!")
            logger.debug("🎉 Story ID: \(storyId)")
            updateStoryStatus(storyId: storyId, status: .completed, progress: L.tr("Tamamlandı!", "Completed!"))
            
            // Send local notification
            let notificationTitle = L.tr("Kitabın Hazır! 📚", "Your Book is Ready! 📚")
            let notificationBody = L.tr("\(childName)'in hikayesi tamamlandı, şimdi okuyabilirsin!", "\(childName)'s story is complete, you can read it now!")
            LocalNotificationManager.shared.sendNotification(
                title: notificationTitle,
                body: notificationBody
            )
            
        } catch {
            logger.error("❌ STORY GENERATION FAILED!")
            logger.error("❌ Story ID: \(storyId)")
            logger.error("❌ Error Type: \(type(of: error))")
            logger.error("❌ Error: \(String(describing: error))")
            logger.error("❌ Error Description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                logger.error("❌ Error Domain: \(nsError.domain)")
                logger.error("❌ Error Code: \(nsError.code)")
                logger.error("❌ Error UserInfo: \(nsError.userInfo)")
            }
            updateStoryStatus(storyId: storyId, status: .failed, progress: "Hata: \(error.localizedDescription)")
        }

        if let uploadedPhotoURL {
            await firebaseUploader.deleteUploadedImage(at: uploadedPhotoURL)
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
        
        logger.debug("🎬 CATEGORY STORY GENERATION STARTED")
        logger.debug("🎬 Story ID: \(storyId)")
        logger.debug("🎬 Category: \(category.displayName)")
        
        // The raw child photo lives in Storage only while the pages are drawn.
        var uploadedPhotoURL: String?

        do {
            // STEP 1: Upload photo to Firebase
            logger.debug("📤 STEP 1: Uploading photo to Firebase...")
            updateStoryStatus(storyId: storyId, status: .uploading, progress: "Fotoğraf yükleniyor...")
            
            let downloadURL = try await firebaseUploader.uploadImageToFirebase(image: image)
            uploadedPhotoURL = downloadURL
            logger.debug("✅ Firebase upload successful!")
            
            // Update story with Firebase URL
            updateStoryCoverUrl(storyId: storyId, url: downloadURL)
            
            // STEP 2: Generate category-specific story text with Gemini
            logger.debug("✍️ STEP 2: Writing category story with Gemini...")
            logger.debug("✍️ Category: \(category.displayName)")
            updateStoryStatus(storyId: storyId, status: .writingStory, progress: "Hikaye yazılıyor...")
            
            let storyPages = try await generateCategoryStoryText(
                childName: childName,
                age: age,
                gender: gender,
                category: category,
                language: language,
                photoData: image.jpegData(compressionQuality: 0.8)
            )
            
            logger.debug("✅ Category story text generated!")
            logger.debug("✅ Pages: \(storyPages.count)")
            
            // Update story with pages (text only)
            updateStoryPages(storyId: storyId, pages: storyPages)
            
            // STEP 3: Generate illustrations for each page
            let theme = categoryToTheme(category)
            logger.debug("🎨 STEP 3: Generating illustrations...")
            logger.debug("🎨 Total pages: \(storyPages.count)")
            logger.debug("🎨 Theme: \(theme.displayName)")
            updateStoryStatus(storyId: storyId, status: .generatingImages, progress: "İllüstrasyonlar oluşturuluyor... (0/\(storyPages.count))")
            
            // Generate images for all pages
            await generateImagesForStory(storyId: storyId, referencePhotoUrl: downloadURL, childName: childName, theme: theme)
            
            // STEP 4: Mark as completed and send notification
            logger.debug("🎉 CATEGORY STORY GENERATION COMPLETED!")
            logger.debug("🎉 Story ID: \(storyId)")
            logger.debug("🎉 Category: \(category.displayName)")
            updateStoryStatus(storyId: storyId, status: .completed, progress: L.tr("Tamamlandı!", "Completed!"))
            
            // Send local notification
            let notificationTitle = L.tr("Kitabın Hazır! 📚", "Your Book is Ready! 📚")
            let notificationBody = L.tr("\(childName)'in \(category.displayName) hikayesi tamamlandı!", "\(childName)'s \(category.displayName) story is complete!")
            LocalNotificationManager.shared.sendNotification(
                title: notificationTitle,
                body: notificationBody
            )
            
        } catch {
            logger.error("❌ CATEGORY STORY GENERATION FAILED!")
            logger.error("❌ Story ID: \(storyId)")
            logger.error("❌ Category: \(category.displayName)")
            logger.error("❌ Error: \(error.localizedDescription)")
            updateStoryStatus(storyId: storyId, status: .failed, progress: "Hata: \(error.localizedDescription)")
        }

        if let uploadedPhotoURL {
            await firebaseUploader.deleteUploadedImage(at: uploadedPhotoURL)
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
        photoData: Data?,
        pageCount: Int = 7,
        tone: String? = nil
    ) async throws -> [StoryPage] {
        
        logger.debug("✍️ Generating structured story with Gemini...")
        
        // ✅ USE STRUCTURED STORY GENERATION
        do {
            let storyResponse = try await aiService.generateStructuredStory(
                childName: childName,
                age: age,
                theme: theme.rawValue,
                language: language == .turkish ? "tr" : "en",
                photoData: photoData,
                pageCount: pageCount,
                tone: tone
            )
            
            logger.debug("✅ Structured story generated!")
            logger.debug("✅ Title: \(storyResponse.title)")
            logger.debug("✅ Pages: \(storyResponse.pages.count)")
            
            // Convert to StoryPage format
            let pages = storyResponse.pages.map { pageData in
                StoryPage(
                    title: pageData.title,
                    text: pageData.text,
                    imagePrompt: pageData.imagePrompt  // ✅ Use detailed imagePrompt from Gemini
                )
            }
            
            // Sayfa sayısı artık sihirbazdaki seçime bağlı. Model istenenden
            // sapabilir; boş değilse kabul edilir, fazlası kırpılır.
            guard !pages.isEmpty else {
                logger.warning("⚠️ Model hiç sayfa döndürmedi, demo moda düşülüyor")
                return generateDemoPages(childName: childName, theme: theme,
                                         language: language, pageCount: pageCount)
            }
            if pages.count != pageCount {
                logger.debug("ℹ️ \(pageCount) sayfa istendi, \(pages.count) geldi")
            }
            return Array(pages.prefix(pageCount))
            
        } catch {
            logger.error("❌ Structured story generation failed: \(String(describing: error))")
            logger.warning("⚠️ Falling back to demo mode")
            return generateDemoPages(childName: childName, theme: theme,
                                     language: language, pageCount: pageCount)
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
        
        // Boş sonuç gelirse demo moda düşülür; sayfa sayısı artık serbest.
        if pages.isEmpty {
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
        
        logger.debug("✍️ Generating category-specific story with Gemini...")
        logger.debug("📂 Category: \(category.displayName)")
        
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
            
            logger.debug("✅ Category story generated!")
            logger.debug("✅ Title: \(storyResponse.title)")
            logger.debug("✅ Pages: \(storyResponse.pages.count)")
            logger.debug("✅ Category: \(category.displayName)")
            
            // Convert to StoryPage format
            let pages = storyResponse.pages.map { pageData in
                StoryPage(
                    title: pageData.title,
                    text: pageData.text,
                    imagePrompt: pageData.imagePrompt
                )
            }
            
            guard !pages.isEmpty else {
                logger.warning("⚠️ Model hiç sayfa döndürmedi, demo moda düşülüyor")
                return generateDemoPages(childName: childName,
                                         theme: categoryToTheme(category), language: language)
            }
            
            return pages
            
        } catch {
            logger.error("❌ Category story generation failed: \(String(describing: error))")
            logger.warning("⚠️ Falling back to demo mode")
            return generateDemoPages(childName: childName, theme: categoryToTheme(category), language: language)
        }
    }
    
    /// Generates demo story pages - LONG VERSION
    private func generateDemoPages(childName: String, theme: StoryTheme,
                                   language: StoryLanguage, pageCount: Int = 7) -> [StoryPage] {
        let texts = getDemoTexts(for: theme, language: language, childName: childName)
        guard !texts.isEmpty else { return [] }

        // Demo metinler 7 bölüm; istenen uzunluğa göre kırpılır ya da döngüyle uzatılır.
        let wanted = max(pageCount, 1)
        return (0..<wanted).map { index in
            StoryPage(
                title: language == .turkish ? "Bölüm \(index + 1)" : "Chapter \(index + 1)",
                text: texts[index % texts.count],
                imagePrompt: texts[index % texts.count]
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
        do {
            let encoded = try JSONEncoder().encode(stories)
            let dataSize = encoded.count
            logger.debug("💾 Saving stories to UserDefaults: \(dataSize) bytes (\(dataSize / 1024) KB)")

            // Check if size is reasonable (< 1MB for UserDefaults)
            if dataSize > 1_000_000 {
                logger.warning("⚠️ WARNING: Stories data is large (\(dataSize / 1024 / 1024) MB). Consider cleanup.")
            }

            UserDefaults.standard.set(encoded, forKey: "stories")
            // Keep the verified copy on disk in step with the write that just
            // happened, deletions included. Does nothing until the migration
            // has verified; never the source of a failure here, because this
            // store is still the authoritative one.
            LibraryPersistence.reconcileAfterWrite(stories: stories)
        } catch {
            // Önceden `try?` idi: kodlama başarısız olduğunda hiçbir şey
            // yazılmıyor ve hiçbir şey söylenmiyordu. Kütüphane o andan sonra
            // sessizce kalıcılığını yitiriyor, uygulama kusursuz çalışmaya
            // devam ediyor ve kayıp ancak bir sonraki açılışta görülüyordu.
            assertionFailure("Masallar kaydedilemedi: \(error)")
            logger.error("🛑 Masallar KAYDEDİLEMEDİ, bu oturumdaki değişiklikler kaybolacak: \(String(describing: error))")
        }
    }
    
    private func loadStories() {
        guard let data = UserDefaults.standard.data(forKey: "stories") else { return }
        do {
            stories = try JSONDecoder().decode([Story].self, from: data)
            logger.debug("✅ Loaded \(self.stories.count) stories from UserDefaults")
        } catch {
            // Bu, uygulamadaki en pahalı sessiz arıza yoluydu.
            //
            // Çözümleme başarısız olunca `stories` boş kalıyor, hemen ardından
            // `createSampleStoriesIfNeeded()` örnekleri kuruyor ve ilk kayıtta
            // gerçek kütüphanenin üstüne yazıyordu. Tek bir bozuk kayıt —
            // tanınmayan bir enum değeri yeter — bir çocuğun bütün masallarını
            // götürüyor, yerine üç örnek koyuyor ve kimseye bir şey söylemiyor.
            //
            // Ham veri artık tarihli bir anahtara alınıyor. Hâlâ ekranda
            // görünmüyor, ama geri getirilebilir: kurtarılamayan bir kayıp ile
            // kurtarılabilir bir kayıp arasındaki fark, kullanıcının o çocuğun
            // ebeveyni olması.
            //
            // The backup itself had no second half. Each failure minted a new
            // dated key and nothing ever read one, pruned one, or told anyone
            // they existed — a store that only grows, inside the store whose
            // size is already the problem. It is capped now.
            let backupKey = "stories.undecodable.\(Int(Date().timeIntervalSince1970))"
            UserDefaults.standard.set(data, forKey: backupKey)
            Self.pruneUndecodableBackups(keeping: Self.undecodableBackupLimit)
            assertionFailure("Masallar çözümlenemedi: \(error)")
            logger.error("🛑 Masallar ÇÖZÜMLENEMEDİ. Ham veri '\(backupKey)' altına alındı: \(String(describing: error))")
        }
    }

    /// How many `stories.undecodable.*` blobs to keep.
    ///
    /// More than one because the same fault can strike twice before anyone
    /// looks, and the oldest copy is the one that predates the damage. Not
    /// unbounded, because these are whole libraries and they sit in
    /// `UserDefaults`.
    static let undecodableBackupLimit = 3

    static let undecodableBackupPrefix = "stories.undecodable."

    /// Keeps the newest `limit` recovery blobs and removes the rest.
    static func pruneUndecodableBackups(
        keeping limit: Int,
        in defaults: UserDefaults = .standard
    ) {
        let keys = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(undecodableBackupPrefix) }
            // The suffix is a unix timestamp, so it sorts newest-first
            // numerically. String order would put "1000000000" after
            // "999999999" and drop the wrong one.
            .sorted { lhs, rhs in
                let l = Int(lhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                let r = Int(rhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                return l > r
            }
        for key in keys.dropFirst(max(0, limit)) {
            defaults.removeObject(forKey: key)
            logger.debug("🧹 Eski kurtarma yedeği kaldırıldı: \(key)")
        }
    }
    
    /// Reports stories written before `imageUrl` existed.
    ///
    /// This used to be the tail of `migrateOldStoriesIfNeeded()`. The head of
    /// that function deleted `UserDefaults["stories"]` outright whenever the
    /// blob passed four megabytes — no copy, no confirmation, on a launch —
    /// and set `stories = []` over a child's whole shelf. It has moved to
    /// `LibraryMigration`, which copies the blob to quarantine, reads the copy
    /// back, and then leaves the original alone. Nothing on the launch path
    /// removes user data any more.
    ///
    /// What remains here reads and reports. It never wrote anything.
    private func auditStoriesMissingImageURLs() {
        var needsSave = false
        for (_, story) in stories.enumerated() {
            for (pageIndex, page) in story.pages.enumerated() {
                // If page has no imageUrl but has imageFileName, try to load from file
                if page.imageUrl == nil && page.imageFileName != nil {
                    logger.warning("⚠️ Found page without imageUrl: Story \(story.id) Page \(pageIndex + 1)")
                    logger.debug("   This is an old story that needs migration")
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            logger.warning("⚠️ Found \(self.stories.count) stories that may need imageUrl migration")
            logger.warning("⚠️ These stories will display placeholder images")
            logger.debug("💡 Solution: Delete old stories and create new ones, OR manually add imageUrls")
        }
    }
    
    // MARK: - Public Helpers
    
    func deleteStory(id: UUID) {
        // Delete images from file system
        fileManager.deleteStoryImages(storyId: id)
        
        // Remove from array
        stories.removeAll { $0.id == id }
        saveStories()
        
        logger.debug("✅ Story deleted: \(id)")
    }

    /// Deletes several stories with one save — used when a child's profile,
    /// and with it their shelf, is deleted.
    func deleteStories(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        for id in ids {
            fileManager.deleteStoryImages(storyId: id)
        }
        stories.removeAll { ids.contains($0.id) }
        saveStories()

        logger.debug("✅ \(ids.count) stories deleted")
    }
    
    // Kütüphaneye hikaye ekle (metin/günlük hikayeler için)
    func addStoryToLibrary(_ story: Story) {
        // Aynı ID'ye sahip hikaye varsa güncelle, yoksa ekle
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = story
        } else {
            stories.insert(story, at: 0)
        }
        saveStories()
        logger.debug("✅ Story added to library: \(story.id)")
    }
    
    /// İlk profil oluşturulduğunda örnek masallar yeni çocuğun adına uyarlanır
    /// (04-STATE-INTERACTIONS.md, akış 1) — aksi hâlde yeni kullanıcının ana
    /// sayfası boş görünür.
    func adoptSampleStories(childName: String, childProfileID: UUID? = nil) {
        guard !childName.isEmpty else { return }
        let samples = ["Zephyr", "Luna"]
        var changed = false
        for index in stories.indices where samples.contains(stories[index].childName) {
            let old = stories[index].childName
            stories[index].childName = childName
            stories[index].childProfileID = childProfileID
            stories[index].title = stories[index].title.replacingOccurrences(of: old, with: childName)
            for pageIndex in stories[index].pages.indices {
                stories[index].pages[pageIndex].text =
                    stories[index].pages[pageIndex].text.replacingOccurrences(of: old, with: childName)
            }
            changed = true
        }
        if changed {
            saveStories()
            logger.debug("✅ Örnek masallar profile uyarlandı")
        }
    }

    /// Okuma ilerlemesini yazar.
    ///
    /// **Anında diske indirilir.** Okuma ilerlemesi, kaybolması en olası
    /// veridir çünkü tam da uygulamanın kapanmasından hemen önce değişir:
    /// çocuk son sayfayı çevirir, ebeveyn uygulamadan çıkar. `UserDefaults`
    /// yazımı tembel; süreç o arada sonlandırılırsa değer hiç diske inmez ve
    /// "kaldığın yer" bir sonraki açılışta yok olur. Ana sayfanın birincil
    /// kartı buna bağlı olduğu için burada bekleyemeyiz.
    ///
    /// Maliyeti bilerek kabul ediliyor: `saveStories()` bütün kütüphaneyi
    /// yeniden kodluyor (~37 KB) ve bu her sayfa çevirmede oluyor. Doğru çözüm
    /// ilerlemeyi kendi küçük deposuna almak, ama o zaman aynı olgunun iki
    /// kaynağı olur — bu projede defalarca canımızı yakan şey. Tek kaynak
    /// kalsın, yazı da gerçekten insin.
    func updateLastReadPage(storyId: UUID, page: Int) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else {
            // Sessizce dönüyordu. Okuyucuya kütüphanede olmayan bir masal
            // verildiğinde ilerleme hiçbir yere yazılmıyor, hiçbir şey de
            // söylenmiyordu — okuma çalışıyor, kayıt çalışmıyor, arada fark
            // yok gibi görünüyordu.
            assertionFailure("İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            logger.error("🛑 İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            return
        }

        guard stories[index].lastReadPage != page else { return }
        stories[index].lastReadPage = page
        stories[index].lastReadAt = Date()
        saveStories()
        // Tembel yazımı zorla indir. `synchronize()` kullanımdan kaldırıldı
        // sayılır ve çoğu yerde gereksizdir; burada gereklidir, çünkü bu değeri
        // yazan an ile sürecin öldüğü an arasında saniyeler olabiliyor.
        UserDefaults.standard.synchronize()

        logger.debug("📖 Updated reading progress for story \(storyId): page \(page)")
    }
    
    /// Masal açıldı — sayfa ilerlemese bile.
    ///
    /// `updateLastReadPage` yalnızca EN İLERİ sayfa değiştiğinde yazar, ki
    /// doğrusu budur: gereksiz yazma bütün `[Story]` dizisini yeniden JSON'a
    /// çevirmek demek. Ama o kural tek başına "en son hangi masalı okudu"
    /// sorusunu yanlış cevaplıyor: 3. sayfada bıraktığı masalı bu akşam açıp
    /// aynı sayfayı tekrar okuyan bir çocuk hiçbir iz bırakmıyor, ve ana sayfa
    /// başka bir masalı "kaldığın yer" diye gösteriyor.
    ///
    /// Açmak da okumaktır. Oturum başına bir yazma.
    func markOpened(storyId: UUID) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else { return }
        stories[index].lastReadAt = Date()
        saveStories()
    }

    func getStory(id: UUID) -> Story? {
        return stories.first { $0.id == id }
    }
    
    // MARK: - Sample Stories
    
    private func createSampleStoriesIfNeeded() {
        // Sadece hiç hikaye yoksa örnek hikayeler oluştur
        guard stories.isEmpty else { return }
        
        logger.debug("📚 Creating sample stories...")
        
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
        logger.debug("✅ Sample stories created: \(self.stories.count)")
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

extension StoryGenerationManager {
    @MainActor
    /// Builds a story from the two choices the new creation flow collects, and
    /// saves it.
    ///
    /// Replaces `createOfflineTextStory`, which took a genre string, a theme
    /// string and hard-coded ids — `setting_forest_001` and
    /// `companion_fox_001` — so every choice the user made was discarded (B3).
    /// Here the choices are stable ids, the seed is kept so the story can be
    /// rebuilt (B5), and a failure is thrown rather than printed (B2).
    ///
    /// Returns the saved story. The caller opens it; nothing here navigates.
    ///
    /// `mode` is already resolved — a surprise has been turned into one of the
    /// three modes by `OfflineStoryService.resolveMode` — and `strategy` records
    /// how. Both nil builds a story the way it was built before modes existed.
    @discardableResult
    func createStory(
        for profile: UserProfile,
        mode: StoryMode? = nil,
        strategy: StorySelectionStrategy? = nil,
        storyIdeaID: String?,
        companionID: String?,
        seed: String? = nil
    ) async throws -> Story {
        isGenerating = true
        defer { isGenerating = false }

        let service = OfflineStoryService.shared
        let composed = try service.compose(
            childName: profile.name,
            ideaID: storyIdeaID,
            companionID: companionID,
            mode: mode,
            age: profile.age,
            seed: seed
        )

        let mapped = OfflineStoryMapper.appStory(
            from: composed.story,
            childName: profile.name,
            childProfileID: profile.id,
            storyIdeaID: storyIdeaID,
            catalogVersion: composed.catalogVersion,
            mode: mode,
            selectionStrategy: strategy,
            ageBand: service.servedBand(forAge: profile.age)
        )
        // Görselli kitap (B2): kayıtlı bir kitap karakteri varsa ve bayrak
        // açıksa hazır sahneler eklenir; yoksa masal bugünkü gibi metin çıkar.
        let story = await IllustratedBookBinder.illustrateIfEnabled(
            mapped,
            composed: composed.story,
            profile: profile,
            mode: mode,
            ageBand: service.servedBand(forAge: profile.age),
            existing: stories
        )

        recordBlueprintRead(composed.story.blueprintID.rawValue, for: profile)

        stories.insert(story, at: 0)
        saveStories()
        return story
    }

    /// The modes of this child's most recent stories, newest first.
    ///
    /// What "Bana sürpriz yap" looks at so it does not repeat itself. Only
    /// stories that recorded a mode count; older ones say nothing.
    func recentModes(for profile: UserProfile, limit: Int = StoryModeResolver.historyWindow) -> [StoryMode] {
        stories
            .filter { $0.belongs(to: profile) }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { $0.origin?.modeID.flatMap(StoryMode.init(rawValue:)) }
            .prefix(limit)
            .map { $0 }
    }

    /// Feeds the per-child blueprint cooldown, so the next story is less likely
    /// to repeat this one's shape. It is the only novelty mechanism that exists
    /// today; proper scoring is still ahead.
    private func recordBlueprintRead(_ blueprintID: String, for profile: UserProfile) {
        let key = "read_history_\(profile.id.uuidString)"
        var seen = UserDefaults.standard.stringArray(forKey: key) ?? []
        seen.append(blueprintID)
        // Bounded: this is a cooldown signal, not an archive.
        UserDefaults.standard.set(Array(seen.suffix(40)), forKey: key)
    }

}
