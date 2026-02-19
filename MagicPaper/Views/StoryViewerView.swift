import SwiftUI

struct StoryViewerView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    @ObservedObject private var generationManager = StoryGenerationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var currentPage = 0
    @State private var showingFullscreenImage = false
    @State private var selectedImage: UIImage?
    @State private var showingPremiumAlert = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    // Reading preferences
    @AppStorage("storyTextSize") private var textSize: TextSize = .normal
    @AppStorage("storyReadingTheme") private var readingTheme: ReadingTheme = .light
    @AppStorage("storyLineSpacing") private var lineSpacing: LineSpacingOption = .normal
    @State private var showingReadingSettings = false
    @State private var autoPlayEnabled = false
    @State private var autoPlayTimer: Timer?
    
    // High contrast mode
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }
    
    // Güncel story'yi al
    private var currentStory: Story {
        generationManager.stories.first(where: { $0.id == story.id }) ?? story
    }
    
    // MARK: - Child Name Highlighting Helper
    
    /// Highlights the child's name in the text with orange color and bold font
    private func highlightName(in text: String, name: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Case-insensitive search for the name
        if let range = attributedString.range(of: name, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .orange
            attributedString[range].font = .system(size: 19, weight: .bold)
        }
        
        return attributedString
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView(for: currentStory)
                
                TabView(selection: $currentPage) {
                    ForEach(Array(currentStory.pages.enumerated()), id: \.offset) { index, page in
                        storyPageView(page: page, index: index, story: currentStory)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    updateReadingProgress(newValue)
                }
                
                navigationControls(for: currentStory)
            }
        }
        .navigationViewStyle(.stack) // iPad'de split view'ı devre dışı bırak
        .onAppear {
            print("📖 StoryViewerView appeared")
            print("   Title: \(currentStory.title)")
            print("   Pages: \(currentStory.pages.count)")
            print("   Status: \(currentStory.status.displayName)")
            for (index, page) in currentStory.pages.enumerated() {
                print("   Page \(index + 1): \(page.text.prefix(50))...")
                print("     - imageFileName: \(page.imageFileName ?? "nil")")
                print("     - imageUrl: \(page.imageUrl ?? "nil")")
            }
            
            if let lastPage = currentStory.lastReadPage {
                currentPage = lastPage
            }
        }
        .fullScreenCover(isPresented: $showingFullscreenImage) {
            fullscreenImageView
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showingReadingSettings) {
            ReadingSettingsView(
                textSize: $textSize,
                readingTheme: $readingTheme,
                lineSpacing: $lineSpacing,
                autoPlayEnabled: $autoPlayEnabled
            )
        }
        .alert("👑 Premium Özellik", isPresented: $showingPremiumAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text("Hikaye paylaşma ve indirme özellikleri Premium üyelere özeldir. Premium'a geçerek sınırsız hikaye oluşturabilir ve tüm özelliklere erişebilirsiniz.")
        }
        .onChange(of: autoPlayEnabled) { _, enabled in
            if enabled {
                startAutoPlay()
            } else {
                stopAutoPlay()
            }
        }
        .onDisappear {
            stopAutoPlay()
        }
    }
    
    private func headerView(for story: Story) -> some View {
        let titleFontSize: CGFloat = DeviceHelper.isIPad ? 24 : 17
        let pageFontSize: CGFloat = DeviceHelper.isIPad ? 16 : 12
        let buttonFontSize: CGFloat = DeviceHelper.isIPad ? 20 : 17
        let iconSize: CGFloat = DeviceHelper.isIPad ? 28 : 20
        let padding: CGFloat = DeviceHelper.isIPad ? 24 : 16
        
        return VStack(spacing: DeviceHelper.isIPad ? 16 : 8) {
            HStack {
                Button("Kapat") {
                    dismiss()
                }
                .font(.system(size: buttonFontSize))
                
                Spacer()
                
                VStack(spacing: DeviceHelper.isIPad ? 6 : 4) {
                    Text(story.title)
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .lineLimit(1)
                    
                    Text("Sayfa \(currentPage + 1) / \(story.pages.count)")
                        .font(.system(size: pageFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Reading settings button
                    Button(action: {
                        showingReadingSettings = true
                    }) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: iconSize))
                    }
                    
                    // Auto-play button
                    Button(action: {
                        autoPlayEnabled.toggle()
                    }) {
                        Image(systemName: autoPlayEnabled ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: iconSize))
                            .foregroundColor(autoPlayEnabled ? .orange : .primary)
                    }
                    
                    // Menu button
                    Menu {
                        Button(action: shareStory) {
                            Label("Hikayeyi Paylaş", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: downloadStory) {
                            Label("Telefona İndir", systemImage: "arrow.down.circle")
                        }
                        
                        Button(action: exportPDF) {
                            Label("PDF Olarak Dışa Aktar", systemImage: "doc.text")
                        }
                        
                        if !subscriptionManager.isPremium {
                            Divider()
                            
                            Button(action: {
                                showingPremiumAlert = true
                            }) {
                                Label("Premium'a Geç", systemImage: "crown.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: iconSize))
                    }
                }
            }
            .padding(padding)
            
            ProgressView(value: Double(currentPage + 1), total: Double(story.pages.count))
                .progressViewStyle(LinearProgressViewStyle(tint: story.theme.color))
                .scaleEffect(y: DeviceHelper.isIPad ? 1.5 : 1.0)
                .padding(.horizontal, padding)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: currentPage)
        }
        .background(Color(.systemBackground))
        .shadow(radius: DeviceHelper.isIPad ? 2 : 1)
    }
    
    private func storyPageView(page: StoryPage, index: Int, story: Story) -> some View {
        let baseImageHeight: CGFloat = DeviceHelper.isIPad ? 500 : 300
        let baseTitleFontSize: CGFloat = DeviceHelper.isIPad ? 32 : 22
        let baseBodyFontSize: CGFloat = DeviceHelper.isIPad ? 22 : 17
        let cornerRadius: CGFloat = DeviceHelper.isIPad ? 24 : 16
        let spacing: CGFloat = DeviceHelper.isIPad ? 32 : 20
        let padding: CGFloat = DeviceHelper.isIPad ? 40 : 20
        
        // Apply text size multiplier
        let titleFontSize = baseTitleFontSize * textSize.multiplier
        let bodyFontSize = baseBodyFontSize * textSize.multiplier
        let currentLineSpacing = lineSpacing.spacing * textSize.multiplier
        
        // High contrast adjustments
        let backgroundColor = readingTheme.backgroundColor(highContrast: isHighContrast)
        let textColor = readingTheme.textColor(highContrast: isHighContrast)
        let shadowOpacity = readingTheme.shadowOpacity(highContrast: isHighContrast)
        
        return ScrollView {
            VStack(spacing: spacing) {
                // CLEAN REFACTORED: Load image from local file only
                Group {
                    if let imageFileName = page.imageUrl,
                       let image = FileManagerService.shared.loadImage(fileName: imageFileName) {
                        // Display local image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .onTapGesture {
                                selectedImage = image
                                showingFullscreenImage = true
                            }
                            .overlay(
                                // High contrast border
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(isHighContrast ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 2)
                            )
                    } else {
                        // Placeholder while generating
                        placeholderView(message: "Resim oluşturuluyor...", story: story)
                    }
                }
                .frame(maxHeight: baseImageHeight)
                .cornerRadius(cornerRadius)
                .shadow(color: .black.opacity(shadowOpacity), radius: DeviceHelper.isIPad ? 8 : 4)
                
                VStack(spacing: DeviceHelper.isIPad ? 24 : 16) {
                    if !page.title.isEmpty {
                        Text(page.title)
                            .font(.system(size: titleFontSize, weight: .bold))
                            .foregroundColor(isHighContrast ? textColor : story.theme.color)
                            .multilineTextAlignment(.center)
                    }
                    
                    // ✅ HIGHLIGHTED TEXT: Child's name in orange and bold with custom styling
                    Text(highlightNameWithSettings(in: page.text, name: story.childName, fontSize: bodyFontSize, textColor: textColor))
                        .lineSpacing(currentLineSpacing)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                }
                .padding(DeviceHelper.isIPad ? 32 : 20)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .overlay(
                            // High contrast border
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(isHighContrast ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(shadowOpacity), radius: DeviceHelper.isIPad ? 4 : 2)
                )
            }
            .padding(padding)
        }
        .background(backgroundColor.ignoresSafeArea())
    }
    
    /// Highlights the child's name with custom settings
    private func highlightNameWithSettings(in text: String, name: String, fontSize: CGFloat, textColor: Color) -> AttributedString {
        var attributedString = AttributedString(text)
        let nameFontSize = fontSize * 1.15 // Name is 15% larger
        
        // Apply reading theme text color
        attributedString.foregroundColor = textColor
        attributedString.font = .system(size: fontSize)
        
        // Case-insensitive search for the name
        if let range = attributedString.range(of: name, options: .caseInsensitive) {
            // High contrast: use pure colors for better visibility
            let nameColor: Color = isHighContrast ? 
                (readingTheme == .dark ? Color(red: 1.0, green: 0.6, blue: 0.0) : Color(red: 0.8, green: 0.3, blue: 0.0)) : 
                .orange
            
            attributedString[range].foregroundColor = nameColor
            attributedString[range].font = .system(size: nameFontSize, weight: .bold)
        }
        
        return attributedString
    }
    
    /// Highlights the child's name with larger font for iPad (legacy method)
    private func highlightNameLarge(in text: String, name: String) -> AttributedString {
        let baseFontSize: CGFloat = DeviceHelper.isIPad ? 22 : 17
        let fontSize = baseFontSize * textSize.multiplier
        let textColor = readingTheme.textColor(highContrast: isHighContrast)
        return highlightNameWithSettings(in: text, name: name, fontSize: fontSize, textColor: textColor)
    }
    
    private func navigationControls(for story: Story) -> some View {
        let buttonFontSize: CGFloat = DeviceHelper.isIPad ? 20 : 17
        let dotSize: CGFloat = DeviceHelper.isIPad ? 10 : 7
        let padding: CGFloat = DeviceHelper.isIPad ? 24 : 16
        let canGoPrev = currentPage > 0
        let canGoNext = currentPage < story.pages.count - 1
        
        return HStack {
            // Previous button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                previousPage()
            }) {
                HStack(spacing: DeviceHelper.isIPad ? 10 : 8) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 22 : 18))
                    Text("Önceki")
                        .font(.system(size: buttonFontSize, weight: .medium))
                }
                .foregroundColor(canGoPrev ? story.theme.color : .gray.opacity(0.35))
                .padding(.horizontal, DeviceHelper.isIPad ? 20 : 12)
                .padding(.vertical, DeviceHelper.isIPad ? 12 : 8)
            }
            .disabled(!canGoPrev)
            .buttonStyle(SpringPressStyle(scale: 0.92))
            
            Spacer()
            
            // Page dots
            HStack(spacing: DeviceHelper.isIPad ? 10 : 7) {
                ForEach(0..<story.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? story.theme.color : Color.gray.opacity(0.25))
                        .frame(
                            width: index == currentPage ? dotSize + 3 : dotSize,
                            height: index == currentPage ? dotSize + 3 : dotSize
                        )
                        .shadow(color: index == currentPage ? story.theme.color.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                currentPage = index
                            }
                        }
                }
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                nextPage()
            }) {
                HStack(spacing: DeviceHelper.isIPad ? 10 : 8) {
                    Text("Sonraki")
                        .font(.system(size: buttonFontSize, weight: .medium))
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 22 : 18))
                }
                .foregroundColor(canGoNext ? story.theme.color : .gray.opacity(0.35))
                .padding(.horizontal, DeviceHelper.isIPad ? 20 : 12)
                .padding(.vertical, DeviceHelper.isIPad ? 12 : 8)
            }
            .disabled(!canGoNext)
            .buttonStyle(SpringPressStyle(scale: 0.92))
        }
        .padding(padding)
        .background(
            ZStack {
                Color(.systemBackground)
                // Subtle top separator
                VStack {
                    Rectangle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
    }
    
    private var fullscreenImageView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let uiImage = selectedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture {
                        showingFullscreenImage = false
                    }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button("Bitti") {
                        showingFullscreenImage = false
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    private func nextPage() {
        if currentPage < story.pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    private func updateReadingProgress(_ page: Int) {
        // İlerlemeyi kaydet
        generationManager.updateLastReadPage(storyId: story.id, page: page)
    }
    
    private func shareStory() {
        // Hikaye metnini oluştur
        var shareText = """
        📚 \(currentStory.title)
        
        \(currentStory.childName)'in sihirli hikayesi! ✨
        
        Tema: \(currentStory.theme.displayName)
        Sayfa Sayısı: \(currentStory.pages.count)
        
        """
        
        // İlk sayfayı ekle
        if let firstPage = currentStory.pages.first {
            shareText += "\n\(firstPage.title)\n\n"
            shareText += firstPage.text.prefix(200) + "...\n\n"
        }
        
        shareText += "MagicPaper ile oluşturuldu 🎨"
        
        // Görselleri ekle
        var itemsToShare: [Any] = [shareText]
        
        // Mevcut sayfanın görselini ekle
        if let currentPageImage = getCurrentPageImage() {
            itemsToShare.append(currentPageImage)
        }
        
        shareItems = itemsToShare
        showingShareSheet = true
    }
    
    private func downloadStory() {
        // Tüm görselleri fotoğraf galerisine kaydet
        var savedCount = 0
        
        for page in currentStory.pages {
            if let imageFileName = page.imageUrl,
               let image = FileManagerService.shared.loadImage(fileName: imageFileName) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                savedCount += 1
            }
        }
        
        // Başarı mesajı göster
        if savedCount > 0 {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Alert göster
            let alert = UIAlertController(
                title: "✅ İndirildi",
                message: "\(savedCount) görsel fotoğraf galerinize kaydedildi.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    private func exportPDF() {
        // PDF oluştur
        let pdfData = createPDF()
        
        guard let pdfData = pdfData else {
            // Hata mesajı
            let alert = UIAlertController(
                title: "❌ Hata",
                message: "PDF oluşturulamadı. Lütfen tekrar deneyin.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
            return
        }
        
        // PDF'i kaydet ve paylaş
        let fileName = "\(currentStory.title.replacingOccurrences(of: " ", with: "_")).pdf"
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                try pdfData.write(to: fileURL)
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // PDF'i paylaş
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // iPad için popover ayarı
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = window
                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    rootVC.present(activityVC, animated: true)
                }
                
            } catch {
                print("❌ PDF kaydetme hatası: \(error)")
            }
        }
    }
    
    private func createPDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MagicPaper",
            kCGPDFContextAuthor: currentStory.childName,
            kCGPDFContextTitle: currentStory.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4 boyutu
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            // Kapak sayfası
            context.beginPage()
            
            // Başlık
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let titleString = currentStory.title
            let titleSize = titleString.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2,
                                   y: 100,
                                   width: titleSize.width,
                                   height: titleSize.height)
            titleString.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Alt başlık
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.gray
            ]
            let subtitleString = "\(currentStory.childName)'in Hikayesi"
            let subtitleSize = subtitleString.size(withAttributes: subtitleAttributes)
            let subtitleRect = CGRect(x: (pageWidth - subtitleSize.width) / 2,
                                      y: 150,
                                      width: subtitleSize.width,
                                      height: subtitleSize.height)
            subtitleString.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            
            // Tema
            let themeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            let themeString = "Tema: \(currentStory.theme.displayName)"
            let themeSize = themeString.size(withAttributes: themeAttributes)
            let themeRect = CGRect(x: (pageWidth - themeSize.width) / 2,
                                   y: 180,
                                   width: themeSize.width,
                                   height: themeSize.height)
            themeString.draw(in: themeRect, withAttributes: themeAttributes)
            
            // Her sayfa için
            for (index, page) in currentStory.pages.enumerated() {
                context.beginPage()
                
                var yPosition: CGFloat = 50
                
                // Sayfa numarası
                let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.gray
                ]
                let pageNumberString = "Sayfa \(index + 1) / \(currentStory.pages.count)"
                pageNumberString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: pageNumberAttributes)
                
                yPosition += 40
                
                // Sayfa başlığı
                if !page.title.isEmpty {
                    let pageTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 24),
                        .foregroundColor: UIColor.black
                    ]
                    let pageTitleRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 100)
                    page.title.draw(in: pageTitleRect, withAttributes: pageTitleAttributes)
                    yPosition += 60
                }
                
                // Görsel
                if let imageFileName = page.imageUrl,
                   let image = FileManagerService.shared.loadImage(fileName: imageFileName) {
                    let imageHeight: CGFloat = 250
                    let imageWidth = pageWidth - 100
                    let imageRect = CGRect(x: 50, y: yPosition, width: imageWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    yPosition += imageHeight + 20
                }
                
                // Metin
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                let textRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: pageHeight - yPosition - 50)
                page.text.draw(in: textRect, withAttributes: textAttributes)
            }
            
            // Son sayfa - MagicPaper logosu
            context.beginPage()
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.gray
            ]
            let footerString = "✨ MagicPaper ile oluşturuldu\n\(currentStory.createdAt.formatted(date: .long, time: .shortened))"
            let footerSize = footerString.size(withAttributes: footerAttributes)
            let footerRect = CGRect(x: (pageWidth - footerSize.width) / 2,
                                    y: (pageHeight - footerSize.height) / 2,
                                    width: footerSize.width,
                                    height: footerSize.height)
            footerString.draw(in: footerRect, withAttributes: footerAttributes)
        }
        
        return data
    }
    
    private func getCurrentPageImage() -> UIImage? {
        guard currentPage < currentStory.pages.count else { return nil }
        let page = currentStory.pages[currentPage]
        
        if let imageFileName = page.imageUrl {
            return FileManagerService.shared.loadImage(fileName: imageFileName)
        }
        return nil
    }
    
    private func placeholderView(message: String, story: Story) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(story.theme.color.opacity(0.3))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack {
                    Text(story.theme.emoji)
                        .font(.system(size: 64))
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
    
    // MARK: - Auto Play Functions
    
    private func startAutoPlay() {
        stopAutoPlay() // Stop any existing timer
        
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            if currentPage < currentStory.pages.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                // Reached end, stop auto-play
                autoPlayEnabled = false
            }
        }
    }
    
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
}

#Preview {
    let sampleStory = Story(
        id: UUID(),
        title: "Örnek Hikaye",
        childName: "Ahmet",
        theme: .fantasy,
        language: .turkish,
        pages: [
            StoryPage(title: "Bölüm 1", text: "Bir zamanlar...", imagePrompt: "Sihirli bir başlangıç")
        ]
    )
    
    StoryViewerView(story: sampleStory)
}
