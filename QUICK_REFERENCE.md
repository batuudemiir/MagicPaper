# 🚀 Quick Reference Card

## ⚠️ BEFORE YOU START

**Add your Fal.ai API key:**
```
File: MagicPaper/Services/FalImageService.swift
Line: private let apiKey = "abceca15-0c3a-48d9-a340-a4b9fb7f0fbd:d0318d76aaff9fad1f06c5396822cc92"
```

## 📦 One-Line Usage

### Upload to Firebase
```swift
let url = try await FirebaseImageUploader.shared.uploadImageToFirebase(image: photo)
```

### Generate with Fal.ai
```swift
let url = try await FalImageService.shared.generateImage(
    prompt: "A magical forest...",
    referenceImageUrl: firebaseUrl
)
```

## 🎯 Complete Workflow

```swift
Task {
    // 1. Upload
    let firebaseUrl = try await FirebaseImageUploader.shared
        .uploadImageToFirebase(image: childPhoto)
    
    // 2. Generate
    let imageUrl = try await FalImageService.shared.generateImage(
        prompt: "A child in a magical forest",
        referenceImageUrl: firebaseUrl
    )
    
    // 3. Use
    print("Done: \(imageUrl)")
}
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `FalImageService.swift` | Fal.ai generation ⚠️ ADD KEY |
| `FirebaseImageUploader.swift` | Firebase upload |
| `FalAITestView.swift` | Test interface |
| `GoogleService-Info.plist` | Firebase config |

## ⏱️ Timing

- Upload: 1-3 seconds
- Generate: 30-60 seconds
- Total: ~35-65 seconds

## 🧪 Test

1. Open: `open MagicPaper.xcodeproj`
2. Add API key to `FalImageService.swift`
3. Build & Run
4. Use `FalAITestView` to test

## 📚 Full Docs

- `COMPLETE_INTEGRATION_SUMMARY.md` - Everything
- `FAL_AI_INTEGRATION_GUIDE.md` - Fal.ai details
- `FIREBASE_INTEGRATION_COMPLETE.md` - Firebase details

That's it! 🎉
