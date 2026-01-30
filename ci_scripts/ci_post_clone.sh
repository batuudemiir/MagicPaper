#!/bin/sh

# Xcode Cloud Post-Clone Script
# Bu script Xcode Cloud build sırasında çalışır

set -e

echo "🔧 Post-clone script başlatılıyor..."

# Swift Package Manager cache'ini temizle
echo "📦 SPM cache temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# Package dependencies'i resolve et
echo "📦 Package dependencies resolve ediliyor..."
xcodebuild -resolvePackageDependencies -project MagicPaper.xcodeproj -scheme MagicPaper

echo "✅ Post-clone script tamamlandı!"
