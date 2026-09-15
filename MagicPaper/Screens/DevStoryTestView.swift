import SwiftUI

struct DevStoryTestView: View {
    @State private var generatedStory: Story?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Developer Test UI: Story Engine")
                    .font(.title)
                    .padding(.top)
                
                Button(action: {
                    generateTestStory()
                }) {
                    Text(isGenerating ? "Generating..." : "Generate Test Story")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isGenerating ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isGenerating)
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                if let story = generatedStory {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Title: \(story.title)")
                            .font(.title2)
                            .bold()
                        
                        Text("DEBUG:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Theme: \(story.theme.rawValue) | Pages: \(story.pages.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        ForEach(story.pages) { page in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Page")
                                    .font(.headline)
                                Text(page.text)
                                    .font(.body)
                                
                                Text("Visual Prompt: \(page.imagePrompt)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func generateTestStory() {
        isGenerating = true
        errorMessage = nil
        generatedStory = nil
        
        Task {
            do {
                let provider = TestOfflineTemplateStoryProvider()
                
                let request = TestOfflineStoryRequest(
                    childName: "Umut",
                    childAge: 5,
                    genre: "adventure",
                    theme: "courage",
                    settingId: nil,
                    companionId: nil,
                    length: .orta,
                    tone: .maceral,
                    language: .turkish,
                    seed: UInt64.random(in: 1...1000000),
                    readBlueprintIDs: []
                )
                
                let (story, _) = try await provider.generateStory(request: request)
                
                await MainActor.run {
                    self.generatedStory = story
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
}

