# Firebase Storage Setup Guide

## 1. Firebase Project Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `MagicPaper`
4. Enable Google Analytics (optional)
5. Click "Create project"

### Enable Storage
1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Choose "Start in test mode" (we'll configure security later)
4. Select a location (choose closest to your users)
5. Click "Done"

### Get Configuration File
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click on **iOS** tab
3. Click "Add app"
4. Enter your iOS Bundle ID (e.g., `com.yourcompany.magicpaper`)
5. Download `GoogleService-Info.plist`
6. **IMPORTANT**: Add this file to your Xcode project

## 2. Swift Package Manager Dependencies

Add these packages to your Xcode project:

1. **File → Add Package Dependencies**
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Select these products:
   - `FirebaseStorage`
   - `FirebaseCore`

## 3. App Configuration

### Update Info.plist
Add these privacy permissions to your `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to select child photos for story creation.</string>

<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to take photos for story creation.</string>
```

### Update AppDelegate or App.swift

#### For SwiftUI App (MagicPaperApp.swift):
```swift
import SwiftUI
import FirebaseCore

@main
struct MagicPaperApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### For UIKit App (AppDelegate.swift):
```swift
import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
```

## 4. Firebase Storage Security Rules

In Firebase Console → Storage → Rules, update to:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read/write access to child_images folder
    match /child_images/{imageId} {
      allow read, write: if true; // For development - restrict in production
    }
  }
}
```

**For Production**, use more restrictive rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /child_images/{imageId} {
      allow read: if true;
      allow write: if request.resource.size < 10 * 1024 * 1024 // 10MB limit
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 5. Usage in Your Views

### Basic Implementation
```swift
import SwiftUI

struct MyView: View {
    @State private var selectedImage: UIImage?
    @State private var uploadedURL: String?
    @State private var isUploading = false
    
    var body: some View {
        VStack {
            // Image picker here
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 200, height: 200)
                
                if isUploading {
                    ProgressView("Uploading...")
                } else if uploadedURL != nil {
                    Text("✅ Uploaded successfully!")
                        .foregroundColor(.green)
                }
            }
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                uploadImage(image)
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        isUploading = true
        
        Task {
            do {
                let url = try await ImageUploader.shared.uploadImage(image)
                await MainActor.run {
                    self.uploadedURL = url
                    self.isUploading = false
                }
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    print("Upload failed: \(error)")
                }
            }
        }
    }
}
```

### With Progress Tracking
```swift
private func uploadImageWithProgress(_ image: UIImage) {
    isUploading = true
    
    Task {
        do {
            let url = try await ImageUploader.shared.uploadImageWithProgress(image) { progress in
                DispatchQueue.main.async {
                    self.uploadProgress = progress
                }
            }
            
            await MainActor.run {
                self.uploadedURL = url
                self.isUploading = false
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                print("Upload failed: \(error)")
            }
        }
    }
}
```

## 6. Integration with Fal.ai

### Updated FalImageGenerator Usage
```swift
// Instead of passing Data, pass the Firebase URL
let imageData = try await FalImageGenerator.shared.generateImage(
    prompt: "A child exploring a magical forest",
    childPhotoURL: uploadedPhotoURL // Use Firebase URL
) { progress in
    print("Generation progress: \(progress)")
}
```

### Complete Flow
```swift
struct StoryCreationView: View {
    @State private var selectedPhoto: UIImage?
    @State private var uploadedPhotoURL: String?
    @State private var isUploading = false
    @State private var generatedStoryImage: UIImage?
    
    var body: some View {
        VStack {
            // 1. Photo Selection
            PhotosPicker("Select Child Photo", selection: $selectedPhoto)
            
            // 2. Upload Status
            if isUploading {
                ProgressView("Uploading to Firebase...")
            } else if uploadedPhotoURL != nil {
                Text("✅ Photo uploaded successfully")
            }
            
            // 3. Generate Story Button
            Button("Generate Story") {
                generateStoryWithFalAI()
            }
            .disabled(uploadedPhotoURL == nil)
            
            // 4. Generated Image
            if let storyImage = generatedStoryImage {
                Image(uiImage: storyImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onChange(of: selectedPhoto) { photo in
            if let photo = photo {
                uploadPhotoToFirebase(photo)
            }
        }
    }
    
    private func uploadPhotoToFirebase(_ image: UIImage) {
        isUploading = true
        
        Task {
            do {
                let url = try await ImageUploader.shared.uploadImage(image)
                await MainActor.run {
                    self.uploadedPhotoURL = url
                    self.isUploading = false
                }
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    // Handle error
                }
            }
        }
    }
    
    private func generateStoryWithFalAI() {
        guard let photoURL = uploadedPhotoURL else { return }
        
        Task {
            do {
                let imageData = try await FalImageGenerator.shared.generateImage(
                    prompt: "A magical adventure story illustration",
                    childPhotoURL: photoURL
                )
                
                if let imageData = imageData,
                   let image = UIImage(data: imageData) {
                    await MainActor.run {
                        self.generatedStoryImage = image
                    }
                }
            } catch {
                print("Story generation failed: \(error)")
            }
        }
    }
}
```

## 7. Testing

1. **Build and run** your app
2. **Select a photo** - should automatically upload to Firebase
3. **Check Firebase Console** - verify image appears in Storage
4. **Generate story** - should use the Firebase URL with Fal.ai
5. **Monitor console logs** for debugging

## 8. Troubleshooting

### Common Issues

1. **"GoogleService-Info.plist not found"**
   - Ensure the file is added to your Xcode project
   - Check it's in the app target

2. **"Permission denied" errors**
   - Check Firebase Storage rules
   - Verify the rules allow write access

3. **Upload fails silently**
   - Check console logs for detailed errors
   - Verify internet connection
   - Check Firebase project configuration

4. **Large file uploads fail**
   - Reduce image compression quality
   - Check Firebase Storage quotas
   - Verify file size limits in Storage rules

### Debug Tips

- Enable detailed Firebase logging:
  ```swift
  FirebaseConfiguration.shared.setLoggerLevel(.debug)
  ```

- Monitor uploads in Firebase Console → Storage
- Check Xcode console for detailed error messages
- Test with small images first

## 9. Production Considerations

### Security
- Implement proper authentication
- Restrict Storage rules to authenticated users
- Add file type and size validation

### Performance
- Implement image caching
- Add retry logic for failed uploads
- Consider image optimization before upload

### Cost Management
- Monitor Firebase Storage usage
- Implement cleanup for old images
- Consider CDN for frequently accessed images

## 10. Next Steps

1. **Add the ImageUploader.swift** to your project
2. **Configure Firebase** following steps 1-4
3. **Update your views** to use Firebase URLs
4. **Test the complete flow** from photo selection to story generation
5. **Implement error handling** and user feedback
6. **Add production security rules**