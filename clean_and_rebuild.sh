#!/bin/bash

echo "🧹 Cleaning Xcode build cache..."

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-*

# Clean project build
xcodebuild clean -project MagicPaper.xcodeproj -scheme MagicPaper

echo "✅ Clean complete!"
echo ""
echo "📱 Now run the app in Xcode:"
echo "   1. Open MagicPaper.xcodeproj"
echo "   2. Select iPhone 17 Pro simulator"
echo "   3. Press Cmd+R to build and run"
echo ""
echo "💡 If issue persists:"
echo "   - In Simulator: Device > Erase All Content and Settings"
echo "   - Restart Xcode"
