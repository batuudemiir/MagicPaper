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


// MARK: - Legacy ProfileManager removed
// Now using MagicPaper/Services/ProfileManager.swift for multi-profile support
