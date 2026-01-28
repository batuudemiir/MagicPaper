import SwiftUI

struct FirebaseTestView: View {
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var uploadedURL: String?
    @State private var errorMessage: String?
    @State private var statusMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Photo Selection
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let selectedPhoto = selectedPhoto {
                        Image(uiImage: selectedPhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Fotoğraf Seç")
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: $selectedPhoto, photoData: .constant(nil))
                }
                
                // Upload Button
                Button(action: testFirebaseUpload) {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isUploading ? "Yükleniyor..." : "Firebase'e Yükle")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPhoto == nil || isUploading ? Color.gray : Color.blue)
                    )
                }
                .disabled(selectedPhoto == nil || isUploading)
                .padding(.horizontal)
                
                // Status Messages
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                // Success URL
                if let url = uploadedURL {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✅ Başarılı!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Firebase URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(url)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(3)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Button("URL'yi Kopyala") {
                            UIPasteboard.general.string = url
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text("❌ Hata: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Firebase Test")
        }
    }
    
    private func testFirebaseUpload() {
        guard let photo = selectedPhoto else { return }
        
        isUploading = true
        errorMessage = nil
        uploadedURL = nil
        statusMessage = "Firebase'e bağlanılıyor..."
        
        Task {
            do {
                statusMessage = "Fotoğraf sıkıştırılıyor..."
                try await Task.sleep(nanoseconds: 500_000_000)
                
                statusMessage = "Firebase Storage'a yükleniyor..."
                let url = try await FirebaseImageUploader.shared.uploadImageToFirebase(image: photo)
                
                await MainActor.run {
                    self.uploadedURL = url
                    self.statusMessage = "Yükleme tamamlandı!"
                    self.isUploading = false
                    print("✅ Firebase URL: \(url)")
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = ""
                    self.isUploading = false
                    print("❌ Firebase Error: \(error)")
                }
            }
        }
    }
}

#Preview {
    FirebaseTestView()
}
