import SwiftUI

struct TextOnlyStoryViewerView: View {
    let story: TextOnlyStory
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.6, blue: 0.86).opacity(0.1),
                        Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1),
                        Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Story content
                    TabView(selection: $currentPage) {
                        ForEach(Array(story.pages.enumerated()), id: \.element.id) { index, page in
                            storyPageView(page: page, pageNumber: index + 1)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Custom page indicator and controls
                    controlsView
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle(story.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Kapat")
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareButton
                }
            }
        }
    }
    
    // MARK: - Story Page View
    
    private func storyPageView(page: TextOnlyStoryPage, pageNumber: Int) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Page number badge
                HStack {
                    Spacer()
                    Text("Sayfa \(pageNumber)/\(story.pages.count)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.6, blue: 0.86),
                                            Color(red: 0.4, green: 0.8, blue: 0.6)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    Spacer()
                }
                .padding(.top, 8)
                
                // Page title
                Text(page.title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Decorative divider
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color(red: 0.2, green: 0.6, blue: 0.86).opacity(0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                    
                    Text(story.theme.emoji)
                        .font(.title3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.86).opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                }
                .padding(.horizontal, 40)
                
                // Page text
                Text(page.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(8)
                    .multilineTextAlignment(story.language.isRTL ? .trailing : .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                
                // Reading tip for kids
                if pageNumber == 1 {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Okuma İpucu")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Text("Yavaş yavaş okuyun ve hayal edin!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Controls View
    
    private var controlsView: some View {
        VStack(spacing: 16) {
            // Page dots indicator
            HStack(spacing: 8) {
                ForEach(0..<story.pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? 
                              LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.86),
                                    Color(red: 0.4, green: 0.8, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ) :
                              LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                        .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            
            // Navigation buttons
            HStack(spacing: 20) {
                // Previous button
                Button(action: previousPage) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Önceki")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(currentPage > 0 ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentPage > 0 ? 
                                  LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.86),
                                        Color(red: 0.4, green: 0.8, blue: 0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  ) :
                                  LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                            )
                    )
                }
                .disabled(currentPage == 0)
                
                // Next button
                Button(action: nextPage) {
                    HStack(spacing: 8) {
                        Text(currentPage < story.pages.count - 1 ? "Sonraki" : "Bitir")
                        Image(systemName: currentPage < story.pages.count - 1 ? "chevron.right" : "checkmark")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.86),
                                        Color(red: 0.4, green: 0.8, blue: 0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }
    
    // MARK: - Share Button
    
    private var shareButton: some View {
        Button(action: shareStory) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Actions
    
    private func previousPage() {
        withAnimation(.spring(response: 0.3)) {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
    }
    
    private func nextPage() {
        withAnimation(.spring(response: 0.3)) {
            if currentPage < story.pages.count - 1 {
                currentPage += 1
            } else {
                dismiss()
            }
        }
    }
    
    private func shareStory() {
        var storyText = "\(story.title)\n\n"
        storyText += "Kahraman: \(story.childName)\n"
        storyText += "Tema: \(story.theme.displayName)\n\n"
        
        for (index, page) in story.pages.enumerated() {
            storyText += "--- Sayfa \(index + 1): \(page.title) ---\n\n"
            storyText += "\(page.text)\n\n"
        }
        
        storyText += "\n✨ MagicPaper ile oluşturuldu"
        
        let activityVC = UIActivityViewController(
            activityItems: [storyText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    TextOnlyStoryViewerView(
        story: TextOnlyStory(
            title: "Sihirli Orman Macerası",
            childName: "Ayşe",
            gender: .girl,
            theme: .fantasy,
            language: .turkish,
            pages: [
                TextOnlyStoryPage(
                    title: "Başlangıç",
                    text: "Bir zamanlar Ayşe adında çok meraklı bir kız vardı. Bir gün bahçede oynarken parlak bir kapı gördü..."
                ),
                TextOnlyStoryPage(
                    title: "Sihirli Kapı",
                    text: "Ayşe kapıya yaklaştı. Kapı mor ve mavi ışıklarla parlıyordu. İçeriden güzel bir müzik geliyordu..."
                )
            ]
        )
    )
}
