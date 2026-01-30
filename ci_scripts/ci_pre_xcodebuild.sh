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

# Secrets.xcconfig kontrolü
echo "🔐 Secrets.xcconfig kontrolü..."
if [ -f "Secrets.xcconfig" ]; then
    echo "✅ Secrets.xcconfig bulundu"
    cat Secrets.xcconfig | grep -v "GEMINI_API_KEY" || echo "✅ API key var"
else
    echo "⚠️ Secrets.xcconfig bulunamadı!"
    if [ -n "$GEMINI_API_KEY" ]; then
        echo "🔧 Environment variable'dan oluşturuluyor..."
        echo "GEMINI_API_KEY = $GEMINI_API_KEY" > Secrets.xcconfig
        echo "✅ Secrets.xcconfig oluşturuldu"
    else
        echo "❌ GEMINI_API_KEY environment variable bulunamadı!"
        exit 1
    fi
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
