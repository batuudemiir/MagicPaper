import SwiftUI

struct StoryViewerView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var generationManager = StoryGenerationManager.shared
    
    @State private var currentPage = 0
    @State private var showingFullscreenImage = false
    @State private var selectedImage: UIImage?
    
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
                .onChange(of: currentPage) { newValue in
                    updateReadingProgress(newValue)
                }
                
                navigationControls(for: currentStory)
            }
        }
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
    }
    
    private func headerView(for story: Story) -> some View {
        VStack(spacing: 8) {
            HStack {
                Button("Kapat") {
                    dismiss()
                }
                
                Spacer()
                
                VStack {
                    Text(story.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Sayfa \(currentPage + 1) / \(story.pages.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: shareStory) {
                        Label("Hikayeyi Paylaş", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: exportPDF) {
                        Label("PDF Olarak Dışa Aktar", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()
            
            ProgressView(value: Double(currentPage + 1), total: Double(story.pages.count))
                .progressViewStyle(LinearProgressViewStyle(tint: story.theme.color))
                .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private func storyPageView(page: StoryPage, index: Int, story: Story) -> some View {
        ScrollView {
            VStack(spacing: 20) {
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
                    } else {
                        // Placeholder while generating
                        placeholderView(message: "Resim oluşturuluyor...", story: story)
                    }
                }
                .frame(maxHeight: 300)
                .cornerRadius(16)
                .shadow(radius: 4)
                
                VStack(spacing: 16) {
                    if !page.title.isEmpty {
                        Text(page.title)
                            .font(.title2.bold())
                            .foregroundColor(story.theme.color)
                            .multilineTextAlignment(.center)
                    }
                    
                    // ✅ HIGHLIGHTED TEXT: Child's name in orange and bold
                    Text(highlightName(in: page.text, name: story.childName))
                        .font(.body)
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
            }
            .padding()
        }
    }
    
    private func navigationControls(for story: Story) -> some View {
        HStack {
            Button(action: previousPage) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Önceki")
                }
                .foregroundColor(currentPage > 0 ? .primary : .gray)
            }
            .disabled(currentPage <= 0)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(0..<story.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? story.theme.color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                currentPage = index
                            }
                        }
                }
            }
            
            Spacer()
            
            Button(action: nextPage) {
                HStack {
                    Text("Sonraki")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(currentPage < story.pages.count - 1 ? .primary : .gray)
            }
            .disabled(currentPage >= story.pages.count - 1)
        }
        .padding()
        .background(Color(.systemBackground))
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
    }
    
    private func shareStory() {
    }
    
    private func exportPDF() {
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
