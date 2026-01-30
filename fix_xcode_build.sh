#!/bin/bash

echo "🧹 Xcode Build Temizleniyor..."

# DerivedData temizle
echo "📦 DerivedData temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-*

# Build klasörünü temizle
echo "🗑️  Build klasörü temizleniyor..."
rm -rf build/

# Xcode cache temizle
echo "💾 Xcode cache temizleniyor..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# SPM cache temizle
echo "📦 SPM cache temizleniyor..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build/

# Xcode workspace temizle
echo "🔧 Workspace temizleniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcuserdata/
rm -rf MagicPaper.xcodeproj/xcuserdata/

echo "✅ Temizlik tamamlandı!"
echo ""
echo "📱 Şimdi Xcode'u açın ve:"
echo "   1. Product > Clean Build Folder (Shift + Cmd + K)"
echo "   2. Product > Build (Cmd + B)"
echo ""
echo "veya komut satırından:"
echo "   xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper clean build"
