#!/bin/sh

# Xcode Cloud Pre-Build Script
# Bu script build başlamadan önce çalışır

set -e

echo "🚀 Pre-build script başlatılıyor..."

# Xcode versiyonunu göster
echo "📱 Xcode version:"
xcodebuild -version

# Swift versiyonunu göster
echo "🔷 Swift version:"
swift --version

# Package dependencies durumunu kontrol et
echo "📦 Package dependencies kontrol ediliyor..."
if [ -f "MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ Package.resolved bulundu"
else
    echo "⚠️ Package.resolved bulunamadı, resolve ediliyor..."
    xcodebuild -resolvePackageDependencies -project MagicPaper.xcodeproj -scheme MagicPaper
fi

echo "✅ Pre-build script tamamlandı!"
