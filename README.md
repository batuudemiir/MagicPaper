# 📚 MagicPaper - AI-Powered Children's Story Generator

An iOS app that creates personalized, illustrated children's stories using AI. Upload a child's photo, choose a theme, and watch as AI generates a unique story with custom illustrations featuring the child as the main character.

## ✨ Features

- **Personalized Stories**: Child becomes the hero of their own adventure
- **AI-Generated Illustrations**: Custom images using Fal.ai (Flux model)
- **Multiple Themes**: Fantasy, Space, Ocean, Dinosaurs, Superheroes, and more
- **Multi-Language Support**: Turkish, English, Spanish, French, German, Italian
- **Background Processing**: Stories generate in the background with progress tracking
- **Local Storage**: Images saved locally for offline access
- **Push Notifications**: Get notified when your story is ready

## 🏗️ Architecture

### Core Components

```
MagicPaper/
├── Models/
│   └── Story.swift                    # Story data models
├── Services/
│   ├── StoryGenerationManager.swift   # Main orchestrator
│   ├── AIService.swift                # Gemini API integration
│   ├── FalImageService.swift          # Fal.ai image generation
│   ├── FirebaseImageUploader.swift    # Firebase Storage
│   ├── FileManagerService.swift       # Local file management
│   └── LocalNotificationManager.swift # Push notifications
└── Views/
    ├── HomeView.swift                 # Landing page
    ├── CreateStoryView.swift          # Story creation form
    ├── LibraryView.swift              # Story library with progress
    ├── StoryViewerView.swift          # Story reader
    └── SettingsView.swift             # App settings
```

## 🔧 Setup

### Prerequisites

- Xcode 15.0+
- iOS 15.6+
- Swift 5.9+

### API Keys Required

1. **Google Gemini API** (for story generation)
   - Get key from: https://makersuite.google.com/app/apikey
   - Model: `gemini-1.5-flash`

2. **Fal.ai API** (for image generation)
   - Get key from: https://fal.ai/dashboard
   - Endpoint: `https://queue.fal.run/fal-ai/flux/dev`

3. **Firebase** (for image storage)
   - Create project at: https://console.firebase.google.com
   - Enable Firebase Storage
   - Download `GoogleService-Info.plist`

### Installation

1. Clone the repository
2. Open `MagicPaper.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the project
4. Update API keys in respective service files:
   - `AIService.swift` - Gemini API key
   - `FalImageService.swift` - Fal.ai API key
5. Build and run (Cmd+R)

## 🚀 How It Works

### Story Generation Workflow

1. **User Input**
   - Child's name, age, gender
   - Photo upload
   - Theme selection
   - Language preference

2. **Background Processing**
   ```
   Status: .uploading
   ↓ Upload photo to Firebase
   
   Status: .writingStory
   ↓ Generate story with Gemini AI
   
   Status: .generatingImages
   ↓ Create illustrations with Fal.ai (sequential)
   
   Status: .completed
   ↓ Send notification
   ```

3. **Progress Tracking**
   - Real-time status updates in LibraryView
   - Progress bars for image generation
   - Stories locked until completion

## 📱 Usage

### Creating a Story

1. Tap "Oluştur" (Create) tab
2. Fill in child's information
3. Upload a photo
4. Select a theme
5. Tap "Hikaye Oluştur" (Create Story)
6. Monitor progress in "Kütüphane" (Library) tab

### Reading a Story

1. Go to "Kütüphane" (Library) tab
2. Wait for story status to show "Tamamlandı" (Completed)
3. Tap on the story to open
4. Swipe to navigate pages
5. Tap images for fullscreen view

## 🎨 Themes

- 🧙 **Fantasy**: Magical adventures with wizards and dragons
- 🚀 **Space**: Cosmic journeys through the stars
- 🌊 **Ocean**: Underwater explorations
- 🦕 **Dinosaurs**: Prehistoric adventures
- 🦸 **Superheroes**: Save the world with superpowers
- 🏰 **Fairy Tales**: Classic storybook adventures
- 🐉 **Dragons**: Epic quests with dragons
- 🎪 **Circus**: Fun under the big top
- 🌲 **Forest**: Nature adventures
- 🏴‍☠️ **Pirates**: Treasure hunting on the high seas

## 🔐 Data Storage

### Local Storage (Documents/Stories/)
- Story images (cover + pages)
- Organized by story ID
- Accessible offline

### UserDefaults
- Story metadata only
- No image data (prevents 4MB limit issues)

### Firebase Storage
- Temporary photo upload
- Reference images for AI generation

## 🐛 Troubleshooting

### Xcode Build Issues

If you see "Cannot find 'StoryManager' in scope" or Firebase package errors:

1. Quit Xcode (Cmd+Q)
2. Clean DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```
3. Reopen Xcode
4. Product → Clean Build Folder (Cmd+Shift+K)
5. Product → Build (Cmd+B)

### Firebase Package Missing

1. File → Add Package Dependencies...
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Version: 12.8.0
4. Select: FirebaseCore, FirebaseStorage
5. Add Package

## 📄 License

This project is for educational purposes.

## 🙏 Acknowledgments

- **Google Gemini** - Story generation
- **Fal.ai** - Image generation (Flux model)
- **Firebase** - Cloud storage
- **SwiftUI** - UI framework

---

**Made with ❤️ for magical storytelling**
