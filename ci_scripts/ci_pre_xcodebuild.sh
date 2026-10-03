#!/bin/sh

# Xcode Cloud Pre-Build Script
# Bu script build başlamadan önce çalışır

# Hata durumunda devam et
set +e

echo "🚀 Pre-build script başlatılıyor..."

# Xcode versiyonunu göster
echo "📱 Xcode version:"
xcodebuild -version || echo "⚠️ xcodebuild version alınamadı"

# Swift versiyonunu göster
echo "🔷 Swift version:"
swift --version || echo "⚠️ swift version alınamadı"

# Secrets.xcconfig kontrolü (içeriği asla log'a yazma)
echo "🔐 Secrets.xcconfig kontrolü..."
if [ -f "Secrets.xcconfig" ]; then
    echo "✅ Secrets.xcconfig bulundu"
else
    echo "⚠️ Secrets.xcconfig bulunamadı; bulut anahtarları olmadan devam ediliyor"
fi

# Package dependencies durumunu kontrol et
echo "📦 Package dependencies kontrol ediliyor..."
if [ -f "MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ Package.resolved bulundu"
else
    echo "⚠️ Package.resolved bulunamadı, resolve ediliyor..."
    xcodebuild -resolvePackageDependencies -project MagicPaper.xcodeproj -scheme MagicPaper || {
        echo "⚠️ Package resolve başarısız, devam ediliyor..."
    }
fi

echo "✅ Pre-build script tamamlandı!"
exit 0
