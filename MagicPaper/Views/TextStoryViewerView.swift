import SwiftUI

struct TextStoryViewerView: View {
    let story: TextStory
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 18
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.92),
                        Color(red: 0.96, green: 0.94, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Story Content
                        storyContentSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "textformat.size")
                            .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            fontSettingsSheet
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 12, x: 0, y: 6)
                
                Text(story.theme.emoji)
                    .font(.system(size: 44))
            }
            
            // Title
            VStack(spacing: 8) {
                Text(story.title)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Label(story.childName, systemImage: "person.fill")
                    Text("•")
                    Label(story.theme.displayName, systemImage: "sparkles")
                    Text("•")
                    Text(story.language.flag)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // Date
            Text(story.createdAt.formatted(date: .long, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Story Content Section
    
    private var storyContentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Decorative top border
            HStack {
                Spacer()
                Image(systemName: "book.fill")
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .font(.title3)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Story text
            Text(story.content)
                .font(.system(size: fontSize, weight: .regular, design: .serif))
                .lineSpacing(8)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            // Decorative bottom border
            HStack {
                Spacer()
                Text("✨")
                    .font(.title2)
                Spacer()
            }
            .padding(.top, 16)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Font Settings Sheet
    
    private var fontSettingsSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Önizleme")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Bir zamanlar \(story.childName) adında cesur bir çocuk varmış...")
                        .font(.system(size: fontSize, weight: .regular, design: .serif))
                        .lineSpacing(8)
                        .foregroundColor(.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Font size slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Yazı Boyutu")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Text("A")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $fontSize, in: 14...28, step: 2)
                            .tint(Color(red: 0.58, green: 0.29, blue: 0.98))
                        
                        Text("A")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preset buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hızlı Seçim")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        presetButton(title: "Küçük", size: 16)
                        presetButton(title: "Normal", size: 18)
                        presetButton(title: "Büyük", size: 22)
                        presetButton(title: "Çok Büyük", size: 26)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Yazı Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        showingSettings = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func presetButton(title: String, size: CGFloat) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                fontSize = size
            }
        }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(fontSize == size ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fontSize == size ?
                              LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ) :
                              LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TextStoryViewerView(
        story: TextStory(
            title: "Ayşe ve Sihirli Krallık",
            childName: "Ayşe",
            gender: .girl,
            theme: .fantasy,
            language: .turkish,
            status: .completed,
            content: """
            Bir zamanlar Ayşe adında cesur bir kız varmış. Ayşe her gece yıldızlara bakarak hayal kurar, uzak diyarları düşlermiş.
            
            Bir gün, bahçede oynarken parlak bir ışık görmüş. Işığın peşinden gittiğinde kendini sihirli bir krallıkta bulmuş...
            
            (Hikaye devam ediyor...)
            """
        )
    )
}
