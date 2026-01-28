import SwiftUI

struct LocalImageView: View {
    let imageName: String
    
    var body: some View {
        if let uiImage = loadImageFromDocuments(fileName: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                
                VStack {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Image not found locally")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func loadImageFromDocuments(fileName: String) -> UIImage? {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ LocalImageView: Could not access documents directory")
            return nil
        }
        
        // Check both with and without Stories subdirectory
        let storiesURL = documentsURL.appendingPathComponent("Stories").appendingPathComponent(fileName)
        let directURL = documentsURL.appendingPathComponent(fileName)
        
        print("🔍 LocalImageView: Looking for image: \(fileName)")
        print("   Trying: \(storiesURL.path)")
        print("   Trying: \(directURL.path)")
        
        // Try Stories subdirectory first
        if fileManager.fileExists(atPath: storiesURL.path) {
            if let image = UIImage(contentsOfFile: storiesURL.path) {
                print("✅ LocalImageView: Loaded image from Stories/\(fileName)")
                return image
            } else {
                print("⚠️ LocalImageView: File exists but failed to load: Stories/\(fileName)")
            }
        }
        
        // Try direct path as fallback
        if fileManager.fileExists(atPath: directURL.path) {
            if let image = UIImage(contentsOfFile: directURL.path) {
                print("✅ LocalImageView: Loaded image from \(fileName)")
                return image
            } else {
                print("⚠️ LocalImageView: File exists but failed to load: \(fileName)")
            }
        }
        
        print("❌ LocalImageView: File does not exist at either location")
        return nil
    }
}
