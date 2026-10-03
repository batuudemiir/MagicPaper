import SwiftUI

/// Test view for Fal.ai image generation
/// Use this to test your API key and generation workflow
struct FalAITestView: View {
    
    @State private var prompt = "A magical forest with talking animals and sparkling trees, storybook illustration style"
    @State private var selectedImage: UIImage?
    @State private var firebaseUrl: String?
    @State private var generatedImageUrl: String?
    
    @State private var isProcessing = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Step 1: Select Child Photo (Optional)
                    
                    GroupBox(label: Label("Step 1: Child Photo (Optional)", systemImage: "photo")) {
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                if firebaseUrl != nil {
                                    Text("✅ Uploaded to Firebase")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 150)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                            Text("Tap to select photo")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Label(selectedImage == nil ? "Select Photo" : "Change Photo", 
                                      systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - Step 2: Enter Prompt
                    
                    GroupBox(label: Label("Step 2: Story Prompt", systemImage: "text.bubble")) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $prompt)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Tip: Be specific and descriptive for best results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - Step 3: Generate
                    
                    GroupBox(label: Label("Step 3: Generate", systemImage: "sparkles")) {
                        VStack(spacing: 12) {
                            Button(action: generateImage) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text(isProcessing ? "Generating..." : "Generate Image")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isProcessing ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing || prompt.isEmpty)
                            
                            if !statusMessage.isEmpty {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(statusMessage)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if let error = errorMessage {
                                Text("❌ \(error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - Result
                    
                    if let imageUrl = generatedImageUrl {
                        GroupBox(label: Label("Generated Image", systemImage: "photo.fill")) {
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 300)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    case .failure:
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                            Text("Failed to load image")
                                                .font(.caption)
                                        }
                                        .frame(height: 300)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                
                                Text("URL: \(imageUrl)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Button(action: {
                                    UIPasteboard.general.string = imageUrl
                                }) {
                                    Label("Copy URL", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Fal.ai Test")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, photoData: .constant(nil))
        }
    }
    
    // MARK: - Generate Image
    
    private func generateImage() {
        isProcessing = true
        errorMessage = nil
        statusMessage = ""
        
        Task {
            do {
                // Step 1: Upload child photo to Firebase (if selected)
                var firebaseImageUrl: String?
                
                if let image = selectedImage {
                    await MainActor.run {
                        statusMessage = "Uploading photo to Firebase..."
                    }
                    
                    firebaseImageUrl = try await FirebaseImageUploader.shared
                        .uploadImageToFirebase(image: image)
                    
                    await MainActor.run {
                        self.firebaseUrl = firebaseImageUrl
                    }
                    
                    print("✅ Firebase URL: \(firebaseImageUrl ?? "none")")
                }
                
                // Step 2: Generate image with Fal.ai
                await MainActor.run {
                    statusMessage = "Generating image with AI (30-60 seconds)..."
                }
                
                let imageUrl = try await FalAIImageGenerator.shared.generateImage(
                    prompt: prompt,
                    referenceImageUrl: firebaseImageUrl,
                    style: "fantasy",
                    seed: nil
                )
                
                print("✅ Generated image: \(imageUrl)")
                
                await MainActor.run {
                    self.generatedImageUrl = imageUrl
                    self.statusMessage = "Complete! 🎉"
                    self.isProcessing = false
                    
                    // Clear status message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.statusMessage = ""
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = ""
                    self.isProcessing = false
                }
                print("❌ Error: \(error)")
            }
        }
    }
}

#Preview {
    FalAITestView()
}
