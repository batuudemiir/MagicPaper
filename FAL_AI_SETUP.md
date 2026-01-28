# Fal.ai Integration Setup Guide

## Overview

This implementation separates the responsibilities:
- **Gemini Flash**: Story text generation and page prompts
- **Fal.ai**: High-quality image generation with character consistency

## Setup Instructions

### 1. Get Fal.ai API Key

1. Visit [fal.ai](https://fal.ai)
2. Sign up for an account
3. Go to your dashboard and generate an API key
4. Copy the API key

### 2. Configure API Key

Open `MagicPaper/MagicPaper/Services/FalImageGenerator.swift` and replace:

```swift
private let apiKey = "YOUR_FAL_AI_API_KEY_HERE"
```

With your actual API key:

```swift
private let apiKey = "abceca15-0c3a-48d9-a340-a4b9fb7f0fbd:d0318d76aaff9fad1f06c5396822cc92" // Your real API key
```

### 3. Test the Integration

1. Build and run the app
2. Navigate to the test view (you can add a button in your main view)
3. Select a child's photo
4. Click "Generate with Fal.ai"
5. Wait for the generation process (usually 30-60 seconds)

## How It Works

### Architecture

```
Story Creation Flow:
1. User inputs child info + photo
2. Gemini Flash generates story text (7 pages)
3. For each page:
   - Create child-friendly prompt
   - Upload child's photo to Fal.ai
   - Generate illustration with character consistency
   - Download and display result
```

### Key Features

#### Character Consistency
- Uses the child's photo as a reference image
- Fal.ai's IP-Adapter ensures the generated character looks like the uploaded child
- Maintains consistency across all story pages

#### Queue-Based Processing
- Fal.ai uses a queue system for processing
- Implementation includes polling mechanism
- Progress updates keep users informed

#### Fallback System
- If Fal.ai fails, falls back to local image processing
- Ensures the app always produces results
- Graceful error handling

## Code Structure

### FalImageGenerator.swift
- Main service class for Fal.ai integration
- Handles image upload, generation, and download
- Implements queue polling and error handling

### Key Methods

```swift
// Main generation method
func generateImage(
    prompt: String,
    childPhotoData: Data,
    progressCallback: @escaping (String) -> Void
) async throws -> Data?

// Creates child-friendly prompts
func createChildFriendlyPrompt(
    storyText: String,
    childName: String,
    theme: StoryTheme,
    pageNumber: Int
) -> String
```

### Integration with AIService

The `AIService` now:
1. Uses Gemini Flash ONLY for story text
2. Calls `FalImageGenerator` for each page illustration
3. Passes child's name and photo for consistency

## Usage Examples

### Basic Usage in Your View

```swift
import SwiftUI

struct MyStoryView: View {
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            // Your existing UI
            
            Button("Generate Illustration") {
                generateImage()
            }
            .disabled(isGenerating)
            
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
    
    private func generateImage() {
        guard let childPhotoData = getChildPhotoData() else { return }
        
        isGenerating = true
        
        Task {
            do {
                let imageData = try await FalImageGenerator.shared.generateImage(
                    prompt: "A child exploring a magical forest",
                    childPhotoData: childPhotoData
                ) { progress in
                    print("Progress: \(progress)")
                }
                
                if let imageData = imageData,
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.generatedImage = image
                        self.isGenerating = false
                    }
                }
            } catch {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func getChildPhotoData() -> Data? {
        // Return your child's photo data
        return nil
    }
}
```

### Advanced Usage with Custom Prompts

```swift
// Create a custom prompt
let customPrompt = """
Create a beautiful children's book illustration featuring the child as a brave explorer.
The child is standing in front of a magical castle with rainbow bridges.
Style: Disney-like animation, bright colors, child-friendly.
The child should be the main focus and look exactly like the reference photo.
"""

// Generate with custom prompt
let imageData = try await FalImageGenerator.shared.generateImage(
    prompt: customPrompt,
    childPhotoData: childPhotoData
) { progress in
    print("Generation progress: \(progress)")
}
```

## Error Handling

The implementation includes comprehensive error handling:

```swift
enum FalImageError: Error {
    case missingAPIKey
    case invalidURL
    case imageUploadFailed
    case invalidResponse
    case apiError(Int, String)
    case generationFailed(String)
    case timeout
    case downloadFailed
}
```

## Performance Considerations

- **Generation Time**: 30-60 seconds per image
- **API Limits**: Check your Fal.ai plan limits
- **Fallback**: Local processing if API fails
- **Caching**: Consider implementing image caching for better UX

## Troubleshooting

### Common Issues

1. **API Key Error**
   - Ensure your API key is correct
   - Check if your Fal.ai account has sufficient credits

2. **Timeout Issues**
   - Increase timeout duration if needed
   - Check your internet connection

3. **Image Upload Fails**
   - Ensure image data is valid JPEG
   - Check image size (should be reasonable, e.g., < 10MB)

4. **Generation Fails**
   - Check the prompt for inappropriate content
   - Ensure the reference image is clear and shows a person

### Debug Tips

- Enable console logging to see detailed progress
- Check the Fal.ai dashboard for generation history
- Test with simple prompts first

## Next Steps

1. **Add the API key** to `FalImageGenerator.swift`
2. **Test the integration** using the provided test view
3. **Customize prompts** for your specific story themes
4. **Implement caching** for better performance
5. **Add error UI** for better user experience

## Support

For issues with:
- **Fal.ai API**: Check [Fal.ai documentation](https://fal.ai/docs)
- **Integration code**: Review the implementation in `FalImageGenerator.swift`
- **Story generation**: Check `AIService.swift` for Gemini integration