import SwiftUI

struct TextStoryLibraryView: View {
    @StateObject private var textStoryManager = TextStoryManager.shared
    @State private var selectedStory: TextStory?
    @State private var showingStoryViewer = false
    @State private var showingDeleteAlert = false
    @State private var storyToDelete: TextStory?
    
    var body: some View {
        NavigationView {
            ZStack {
                if textStoryManager.textStories.isEmpty {
                    emptyStateView
                } else {
                    storyListView
                }
            }
            .navigationTitle("Metin Hikayeler")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.05),
                        Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $showingStoryViewer) {
            if let story = selectedStory {
                TextStoryViewerView(story: story)
            }
        }
        .alert("Hikayeyi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let story = storyToDelete {
                    textStoryManager.deleteStory(story)
                }
            }
        } message: {
            Text("Bu hikayeyi silmek istediğinizden emin misiniz?")
        }
    }
    
    // MARK: - Story List View
    
    private var storyListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(textStoryManager.textStories) { story in
                    storyCard(story: story)
                }
            }
            .padding()
        }
    }
    
    private func storyCard(story: TextStory) -> some View {
        Button(action: {
            if story.status == .completed {
                selectedStory = story
                showingStoryViewer = true
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(story.theme.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(story.theme.emoji)
                        .font(.system(size: 32))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(story.childName, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(story.language.flag)
                            .font(.caption)
                    }
                    
                    // Status
                    HStack(spacing: 6) {
                        Image(systemName: story.status.icon)
                            .font(.caption2)
                        Text(story.status.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(story.status == .completed ? .green : 
                                   story.status == .failed ? .red : .orange)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    if story.status == .completed {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if story.status == .generating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Menu {
                        if story.status == .completed {
                            Button(action: {
                                shareStory(story)
                            }) {
                                Label("Paylaş", systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        Button(role: .destructive, action: {
                            storyToDelete = story
                            showingDeleteAlert = true
                        }) {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(story.status != .completed)
        .opacity(story.status == .completed ? 1.0 : 0.7)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.2),
                                Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text("📖")
                    .font(.system(size: 64))
            }
            
            VStack(spacing: 12) {
                Text("Henüz Metin Hikaye Yok")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("İlk metin hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: CreateTextStoryView()) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Hikaye Oluştur")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.29, blue: 0.98),
                            Color(red: 0.85, green: 0.35, blue: 0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func shareStory(_ story: TextStory) {
        let text = """
        \(story.title)
        
        \(story.content)
        
        ---
        MagicPaper ile oluşturuldu 📖✨
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    TextStoryLibraryView()
}
