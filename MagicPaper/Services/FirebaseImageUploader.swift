import Foundation
import UIKit
import FirebaseStorage

/// Simple Firebase image uploader for child photos
/// Uploads images to Firebase Storage and returns download URLs for use with Fal.ai API
class FirebaseImageUploader {
    
    static let shared = FirebaseImageUploader()
    
    private init() {}
    
    /// Uploads an image to Firebase Storage and returns the download URL
    /// - Parameter image: The UIImage to upload
    /// - Returns: The download URL as a String (ready to pass to Fal.ai API)
    /// - Throws: Error if compression or upload fails
    func uploadImageToFirebase(image: UIImage) async throws -> String {
        
        // Step 1: Compress the UIImage to JPEG data (quality 0.5)
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw FirebaseImageUploadError.compressionFailed
        }
        
        print("📸 Image compressed: \(imageData.count) bytes")
        
        // Retry logic for TLS errors
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 Upload attempt \(attempt)/\(maxRetries)...")
                
                // Step 2: Create a reference to Firebase Storage
                let storage = Storage.storage()
                let storageRef = storage.reference()
                
                // Step 3: Create unique filename with UUID
                let filename = "\(UUID().uuidString).jpg"
                let imageRef = storageRef.child("child_uploads/\(filename)")
                
                print("📤 Uploading to: child_uploads/\(filename)")
                
                // Step 4: Create metadata
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                // Step 5: Upload the data
                let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
                print("✅ Upload successful on attempt \(attempt)")
                
                // Step 6: Get and return the download URL
                let downloadURL = try await imageRef.downloadURL()
                let urlString = downloadURL.absoluteString
                
                print("🔗 Download URL: \(urlString)")
                return urlString
                
            } catch {
                lastError = error
                print("⚠️ Upload attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Check if it's a TLS error
                let nsError = error as NSError
                if nsError.domain == "NSURLErrorDomain" && nsError.code == -1200 {
                    print("⚠️ TLS error detected. Retrying...")
                    
                    // Wait before retry (exponential backoff)
                    if attempt < maxRetries {
                        let delay = UInt64(attempt * 1_000_000_000) // 1, 2, 3 seconds
                        try? await Task.sleep(nanoseconds: delay)
                    }
                } else {
                    // Not a TLS error, throw immediately
                    throw error
                }
            }
        }
        
        // All retries failed
        print("❌ All \(maxRetries) upload attempts failed")
        throw lastError ?? FirebaseImageUploadError.uploadFailed
    }
}

// MARK: - Error Types

enum FirebaseImageUploadError: Error, LocalizedError {
    case compressionFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image to JPEG format"
        case .uploadFailed:
            return "Failed to upload image to Firebase after multiple attempts"
        }
    }
}
