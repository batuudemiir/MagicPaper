import SwiftUI

struct LibraryView: View {
    @ObservedObject private var generationManager = StoryGenerationManager.shared
    @State private var selectedStory: Story?
    @State private var showingDeleteAlert = false
    @State private var storyToDelete: Story?
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "Tümü"
        case image = "Görselli"
        case text = "Metin"
        case daily = "Günlük"
        
        var icon: String {
            switch self {
            case .all: return "books.vertical.fill"
            case .image: return "photo.fill"
            case .text: return "text.book.closed.fill"
            case .daily: return "calendar"
            }
        }
    }
    
    var filteredStories: [Story] {
        var stories = generationManager.stories
        
        // Arama filtresi
        if !searchText.isEmpty {
            stories = stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.childName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Tip filtresi
        switch filterOption {
        case .all:
            break
        case .image:
            // Görselli hikayeler - pages içinde imageUrl olan
            stories = stories.filter { story in
                story.pages.contains(where: { page in
                    page.imageUrl != nil && !page.imageUrl!.isEmpty
                })
            }
        case .text:
            // Metin hikayeler - pages içinde imageUrl olmayan
            stories = stories.filter { story in
                story.pages.allSatisfy { page in
                    page.imageUrl == nil || page.imageUrl!.isEmpty
                }
            }
        case .daily:
            // Günlük hikayeler - metin hikayeler gibi
            stories = stories.filter { story in
                story.pages.allSatisfy { page in
                    page.imageUrl == nil || page.imageUrl!.isEmpty
                }
            }
        }
        
        return stories.sorted { $0.createdAt > $1.createdAt }
    }
    
    var totalStoryCount: Int {
        generationManager.stories.count
    }
    
    var completedStoryCount: Int {
        generationManager.stories.filter { $0.status == .completed }.count
    }
    
    var imageStoryCount: Int {
        generationManager.stories.filter { story in
            story.pages.contains(where: { page in
                page.imageUrl != nil && !page.imageUrl!.isEmpty
            })
        }.count
    }
    
    var textStoryCount: Int {
        generationManager.stories.filter { story in
            story.pages.allSatisfy { page in
                page.imageUrl == nil || page.imageUrl!.isEmpty
            }
        }.count
    }
    
    var body: some View {
        NavigationView {
            Group {
                if totalStoryCount == 0 {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // İstatistikler
                        statsView
                            .padding()
                        
                        // Tip filtresi
                        filterView
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        // Hikaye listesi
                        if filteredStories.isEmpty {
                            noResultsView
                        } else {
                            storyListView
                        }
                    }
                }
            }
            .navigationTitle("Kütüphanem")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Hikaye ara...")
        }
        .sheet(item: $selectedStory) { story in
            StoryViewerView(story: story)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Hikayeyi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let story = storyToDelete {
                    generationManager.deleteStory(id: story.id)
                }
            }
        } message: {
            if let story = storyToDelete {
                Text("\"\(story.title)\" hikayesini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    // MARK: - Stats View
    
    private var statsView: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "book.fill",
                value: "\(totalStoryCount)",
                label: "Toplam",
                color: .indigo
            )
            
            statCard(
                icon: "photo.fill",
                value: "\(imageStoryCount)",
                label: "Görselli",
                color: .purple
            )
            
            statCard(
                icon: "text.book.closed.fill",
                value: "\(textStoryCount)",
                label: "Metin",
                color: .green
            )
            
            statCard(
                icon: "checkmark.circle.fill",
                value: "\(completedStoryCount)",
                label: "Okunan",
                color: .orange
            )
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    // MARK: - Filter View
    
    private var filterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        withAnimation {
                            filterOption = option
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: option.icon)
                                .font(.caption)
                            Text(option.rawValue)
                                .font(.subheadline.weight(filterOption == option ? .semibold : .regular))
                        }
                        .foregroundColor(filterOption == option ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(filterOption == option ? Color.indigo : Color(.systemGray5))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 56))
                    .foregroundColor(.indigo)
            }
            
            VStack(spacing: 8) {
                Text("Henüz Hikaye Yok")
                    .font(.title2.bold())
                
                Text("İlk sihirli hikayenizi oluşturun ve çocuğunuzun kahramanı olduğu maceralara başlayın")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            NavigationLink(destination: CreateStoryView()) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("İlk Hikayeyi Oluştur")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
        }
        .padding()
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Sonuç Bulunamadı")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Farklı bir arama terimi deneyin")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Story List
    
    private var storyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredStories) { story in
                    if story.status == .completed {
                        completedStoryCard(story: story)
                    } else {
                        generatingStoryCard(story: story)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Completed Story Card
    
    private func completedStoryCard(story: Story) -> some View {
        Button(action: {
            selectedStory = story
        }) {
            HStack(spacing: 14) {
                // Kapak resmi
                Group {
                    if let coverImageFileName = story.coverImageFileName,
                       let uiImage = FileManagerService.shared.loadImage(fileName: coverImageFileName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [story.theme.color.opacity(0.6), story.theme.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(story.theme.emoji)
                                .font(.system(size: 36))
                        }
                    }
                }
                .frame(width: 90, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Bilgiler
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text("\(story.childName)'in Hikayesi")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                    
                    HStack(spacing: 8) {
                        Label(story.theme.displayName, systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("\(story.pages.count) sayfa", systemImage: "book.pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // İlerleme
                    if let lastPage = story.lastReadPage {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Sayfa \(lastPage + 1)/\(story.pages.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("%\(Int((Double(lastPage + 1) / Double(story.pages.count)) * 100))")
                                    .font(.caption2.bold())
                                    .foregroundColor(story.theme.color)
                            }
                            
                            ProgressView(value: Double(lastPage + 1), total: Double(story.pages.count))
                                .progressViewStyle(LinearProgressViewStyle(tint: story.theme.color))
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Menü butonu
                Menu {
                    Button(action: {
                        selectedStory = story
                    }) {
                        Label("Hikayeyi Oku", systemImage: "book.fill")
                    }
                    
                    Button(action: {
                        shareStory(story)
                    }) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        storyToDelete = story
                        showingDeleteAlert = true
                    }) {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                        
                        Text("Menü")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Generating Story Card
    
    private func generatingStoryCard(story: Story) -> some View {
        HStack(spacing: 14) {
            // Kapak resmi
            ZStack {
                Group {
                    if let coverImageFileName = story.coverImageFileName,
                       let uiImage = FileManagerService.shared.loadImage(fileName: coverImageFileName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(story.theme.color.opacity(0.3))
                            
                            Text(story.theme.emoji)
                                .font(.system(size: 36))
                        }
                    }
                }
                .frame(width: 90, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 90, height: 120)
                    .overlay(
                        VStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                            
                            Image(systemName: story.status.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    )
            }
            
            // Bilgiler
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("\(story.childName)'in Hikayesi")
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                
                // Durum badge
                HStack(spacing: 6) {
                    Image(systemName: story.status.icon)
                        .font(.caption2)
                    Text(story.status.displayName)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(statusColor(for: story.status))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(statusColor(for: story.status).opacity(0.15))
                )
                
                // İlerleme
                if story.status == .generatingImages {
                    let completedPages = story.pages.filter { $0.imageFileName != nil }.count
                    let totalPages = story.pages.count
                    if totalPages > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Görseller oluşturuluyor")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(completedPages)/\(totalPages)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.orange)
                            }
                            
                            ProgressView(value: Double(completedPages), total: Double(totalPages))
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        }
                    }
                }
                
                if let progress = story.currentProgress {
                    Text(progress)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(story.status == .failed ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Functions
    
    private func statusColor(for status: StoryStatus) -> Color {
        switch status {
        case .uploading: return .blue
        case .writingStory: return .purple
        case .generatingImages: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    private func shareStory(_ story: Story) {
        shareItems = [generateShareText(for: story)]
        showingShareSheet = true
    }
    
    private func generateShareText(for story: Story) -> String {
        var text = """
        📚 \(story.title)
        
        \(story.childName)'in sihirli hikayesi! ✨
        
        Tema: \(story.theme.displayName)
        Sayfa Sayısı: \(story.pages.count)
        
        """
        
        if let firstPage = story.pages.first {
            text += "\n\(firstPage.title)\n\n"
            text += firstPage.text.prefix(200) + "...\n\n"
        }
        
        text += "MagicPaper ile oluşturuldu 🎨"
        
        return text
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LibraryView()
}