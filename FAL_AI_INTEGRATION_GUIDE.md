# 🎨 Fal.ai Integration Guide

## Overview

The `FalImageService` provides a robust interface to Fal.ai's Flux Dev model with automatic queue handling and polling.

## Setup

### 1. Add Your API Key

Open `MagicPaper/Services/FalImageService.swift` and replace:

```swift
private let apiKey = "abceca15-0c3a-48d9-a340-a4b9fb7f0fbd:d0318d76aaff9fad1f06c5396822cc92"
```

with your actual Fal.ai API key.

### 2. Service Features

✅ **Queue-based API**: Automatically submits to queue and polls for completion  
✅ **Polling**: Checks status every 1 second (max 2 minutes)  
✅ **Reference Images**: Supports child photo URLs from Firebase  
✅ **Optimized Settings**: Pre-configured for best results  
✅ **Error Handling**: Comprehensive error types with descriptions  

## Configuration

The service uses these optimized settings:

```swift
- Model: Flux Dev (fal-ai/flux/dev)
- Image Size: landscape_4_3
- Inference Steps: 28
- Guidance Scale: 3.0
- Polling Interval: 1 second
- Max Polling Time: 2 minutes
```

## Usage Examples

### Example 1: Simple Generation (No Reference Image)

```swift
import SwiftUI

struct SimpleGenerationView: View {
    @State private var imageUrl: String?
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            Button("Generate Image") {
                Task {
                    isGenerating = true
                    
                    do {
                        let url = try await FalImageService.shared.generateImage(
                            prompt: "A magical forest with talking animals and sparkling trees",
                            referenceImageUrl: nil
                        )
                        
                        imageUrl = url
                        
                    } catch {
                        print("Error: \(error)")
                    }
                    
                    isGenerating = false
                }
            }
            .disabled(isGenerating)
            
            if isGenerating {
                ProgressView("Generating...")
            }
            
            if let url = imageUrl {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
            }
        }
    }
}
```

### Example 2: Complete Workflow (Firebase + Fal.ai)

```swift
import SwiftUI

struct CompleteWorkflowView: View {
    @State private var childPhoto: UIImage?
    @State private var generatedImageUrl: String?
    @State private var isProcessing = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Image picker for child photo
            if let photo = childPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            Button("Select Child Photo") {
                // Your image picker logic
            }
            
            Button("Generate Story Image") {
                generateStoryImage()
            }
            .disabled(childPhoto == nil || isProcessing)
            
            if isProcessing {
                ProgressView()
                Text(statusMessage)
                    .font(.caption)
            }
            
            if let url = generatedImageUrl {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 300)
            }
        }
        .padding()
    }
    
    private func generateStoryImage() {
        guard let photo = childPhoto else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Step 1: Upload child photo to Firebase
                statusMessage = "Uploading photo to Firebase..."
                let firebaseUrl = try await FirebaseImageUploader.shared
                    .uploadImageToFirebase(image: photo)
                
                print("✅ Firebase URL: \(firebaseUrl)")
                
                // Step 2: Generate image with Fal.ai
                statusMessage = "Generating story image with AI..."
                let generatedUrl = try await FalImageService.shared.generateImage(
                    prompt: "A brave child discovering a magical treasure chest in an enchanted forest, surrounded by friendly woodland creatures and glowing fireflies",
                    referenceImageUrl: firebaseUrl
                )
                
                print("✅ Generated image: \(generatedUrl)")
                
                await MainActor.run {
                    self.generatedImageUrl = generatedUrl
                    self.statusMessage = "Complete!"
                    self.isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}
```

### Example 3: Batch Generation

```swift
func generateMultipleImages() async throws -> [String] {
    let prompts = [
        "A child exploring a magical castle",
        "A child riding a friendly dragon",
        "A child discovering a secret garden"
    ]
    
    var imageUrls: [String] = []
    
    for prompt in prompts {
        let url = try await FalImageService.shared.generateImage(
            prompt: prompt,
            referenceImageUrl: firebaseChildPhotoUrl
        )
        imageUrls.append(url)
    }
    
    return imageUrls
}
```

## API Response Flow

### 1. Queue Submission

**Request:**
```json
POST https://queue.fal.run/fal-ai/flux/dev
{
  "prompt": "A magical forest...",
  "image_url": "https://firebasestorage.googleapis.com/...",
  "image_size": "landscape_4_3",
  "num_inference_steps": 28,
  "guidance_scale": 3.0
}
```

**Response:**
```json
{
  "request_id": "abc123...",
  "status_url": "https://queue.fal.run/fal-ai/flux/dev/requests/abc123..."
}
```

### 2. Polling Status

**Request:**
```
GET https://queue.fal.run/fal-ai/flux/dev/requests/abc123...
```

**Response (In Progress):**
```json
{
  "status": "in_progress"
}
```

**Response (Completed):**
```json
{
  "status": "completed",
  "images": [
    {
      "url": "https://fal.media/files/...",
      "width": 1024,
      "height": 768
    }
  ]
}
```

## Error Handling

The service provides detailed error types:

```swift
do {
    let url = try await FalImageService.shared.generateImage(
        prompt: "...",
        referenceImageUrl: nil
    )
} catch FalImageError.queueSubmissionFailed(let statusCode, let message) {
    print("Queue failed: \(statusCode) - \(message)")
} catch FalImageError.generationFailed(let message) {
    print("Generation failed: \(message)")
} catch FalImageError.pollingTimeout {
    print("Generation took too long")
} catch {
    print("Unknown error: \(error)")
}
```

## Best Practices

### 1. Prompt Engineering

Good prompts for story generation:

```swift
// ✅ Good: Specific, descriptive, child-friendly
"A brave child discovering a hidden treasure chest in a magical forest, 
surrounded by friendly talking animals and glowing fireflies, 
storybook illustration style"

// ❌ Bad: Too vague
"A child in a forest"
```

### 2. Reference Images

When using child photos:

```swift
// ✅ Upload to Firebase first
let firebaseUrl = try await FirebaseImageUploader.shared
    .uploadImageToFirebase(image: childPhoto)

// ✅ Then pass to Fal.ai
let result = try await FalImageService.shared.generateImage(
    prompt: "...",
    referenceImageUrl: firebaseUrl
)
```

### 3. Progress Feedback

Always show progress to users:

```swift
@State private var statusMessage = ""

// Update status during process
statusMessage = "Uploading photo..."
// ... upload code ...

statusMessage = "Generating image (this may take 30-60 seconds)..."
// ... generation code ...

statusMessage = "Complete!"
```

### 4. Caching Results

Consider caching generated images:

```swift
// Save URL to your Story model
story.generatedImageUrl = generatedUrl

// Or download and save locally
let imageData = try await URLSession.shared.data(from: URL(string: generatedUrl)!).0
// Save imageData to disk or database
```

## Troubleshooting

### Issue: "Missing package product 'FirebaseCore'"

**Solution:** Open Xcode → File → Packages → Resolve Package Versions

### Issue: "Queue submission failed (401)"

**Solution:** Check your API key in `FalImageService.swift`

### Issue: "Polling timeout"

**Solution:** The generation is taking longer than 2 minutes. You can increase `maxPollingAttempts` in the service.

### Issue: "Missing image URL"

**Solution:** The API response format may have changed. Check the Fal.ai documentation.

## Testing

Quick test in a playground or view:

```swift
Task {
    do {
        let url = try await FalImageService.shared.generateImage(
            prompt: "A test image of a magical castle",
            referenceImageUrl: nil
        )
        print("Success! URL: \(url)")
    } catch {
        print("Error: \(error)")
    }
}
```

## Performance Notes

- **Average generation time**: 30-60 seconds
- **Polling overhead**: ~1 second per check
- **Network requirements**: Stable internet connection
- **Image size**: ~2-5 MB per generated image

## Next Steps

1. ✅ Add your Fal.ai API key
2. ✅ Test with a simple prompt
3. ✅ Integrate with Firebase image upload
4. ✅ Build your story generation UI

**You're ready to generate amazing AI images!** 🎨✨
