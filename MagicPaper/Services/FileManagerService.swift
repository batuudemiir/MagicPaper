import Foundation
import UIKit
import SwiftUI

/// Simple file storage service
/// Saves images to Documents/Stories/ directory
class FileManagerService {
    
    static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    private let storiesDirectory = "Stories"
    
    private init() {
        createStoriesDirectoryIfNeeded()
    }
    
    // MARK: - Directory Setup
    
    private func createStoriesDirectoryIfNeeded() {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let storiesURL = documentsURL.appendingPathComponent(storiesDirectory)
        
        if !fileManager.fileExists(atPath: storiesURL.path) {
            try? fileManager.createDirectory(at: storiesURL, withIntermediateDirectories: true)
            print("✅ FileManager: Stories directory created")
        }
    }
    
    func getStoriesDirectoryURL() -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(storiesDirectory)
    }
    
    // MARK: - Save Image
    
    /// Save image data to disk and return filename
    func saveImage(data: Data, fileName: String) -> String? {
        guard let storiesURL = getStoriesDirectoryURL() else {
            print("❌ FileManager: Cannot get directory")
            return nil
        }
        
        let fileURL = storiesURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("✅ FileManager: Saved \(fileName) (\(data.count / 1024) KB)")
            return fileName
        } catch {
            print("❌ FileManager: Save failed - \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    
    /// Load image from disk by filename
    func loadImage(fileName: String) -> UIImage? {
        guard let storiesURL = getStoriesDirectoryURL() else {
            return nil
        }
        
        let fileURL = storiesURL.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    /// Load image data from disk by filename
    func loadImageData(fileName: String) -> Data? {
        guard let storiesURL = getStoriesDirectoryURL() else {
            return nil
        }
        
        let fileURL = storiesURL.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Delete
    
    /// Delete all images for a story
    func deleteStoryImages(storyId: UUID) {
        guard let storiesURL = getStoriesDirectoryURL() else {
            return
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: storiesURL, includingPropertiesForKeys: nil)
            let storyFiles = files.filter { $0.lastPathComponent.contains(storyId.uuidString) }
            
            for file in storyFiles {
                try fileManager.removeItem(at: file)
            }
            
            print("✅ FileManager: Deleted \(storyFiles.count) files for story")
        } catch {
            print("❌ FileManager: Delete failed - \(error)")
        }
    }
}


// MARK: - User Profile Manager

struct UserProfile: Codable {
    var name: String
    var profileImageFileName: String?
    var createdAt: Date
    
    init(name: String = "", profileImageFileName: String? = nil) {
        self.name = name
        self.profileImageFileName = profileImageFileName
        self.createdAt = Date()
    }
}

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profile: UserProfile
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "userProfile"
    
    private init() {
        // Load profile from UserDefaults
        if let data = userDefaults.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = UserProfile()
        }
    }
    
    func updateProfile(name: String, image: UIImage? = nil) {
        profile.name = name
        
        // Save image if provided
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let fileName = "profile_\(UUID().uuidString).jpg"
            if let savedFileName = FileManagerService.shared.saveImage(data: imageData, fileName: fileName) {
                // Delete old profile image if exists
                if let oldFileName = profile.profileImageFileName {
                    deleteProfileImage(fileName: oldFileName)
                }
                profile.profileImageFileName = savedFileName
            }
        }
        
        saveProfile()
    }
    
    func updateProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = "profile_\(UUID().uuidString).jpg"
        if let savedFileName = FileManagerService.shared.saveImage(data: imageData, fileName: fileName) {
            // Delete old profile image if exists
            if let oldFileName = profile.profileImageFileName {
                deleteProfileImage(fileName: oldFileName)
            }
            profile.profileImageFileName = savedFileName
            saveProfile()
        }
    }
    
    private func deleteProfileImage(fileName: String) {
        guard let storiesURL = FileManagerService.shared.getStoriesDirectoryURL() else { return }
        let fileURL = storiesURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func getProfileImage() -> UIImage? {
        guard let fileName = profile.profileImageFileName else { return nil }
        return FileManagerService.shared.loadImage(fileName: fileName)
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: profileKey)
        }
    }
    
    func hasProfile() -> Bool {
        return !profile.name.isEmpty
    }
}
