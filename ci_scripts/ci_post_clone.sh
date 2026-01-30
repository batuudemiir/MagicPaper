#!/bin/sh

# Xcode Cloud Post-Clone Script
# Bu script Xcode Cloud build sırasında çalışır

echo "🔧 Post-clone script başlatılıyor..."

# Hata durumunda devam et (set -e kaldırıldı)
set +e

# Swift Package Manager cache'ini temizle
echo "📦 SPM cache temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData || true
rm -rf .build || true

# Xcode version kontrolü
echo "� Xcode version:"
xcodebuild -version || echo "⚠️ xcodebuild bulunamadı"

# Workspace var mı kontrol et
if [ -f "MagicPaper.xcworkspace" ]; then
    echo "📦 Workspace bulundu, workspace kullanılıyor..."
    WORKSPACE_ARG="-workspace MagicPaper.xcworkspace"
else
    echo "📦 Project kullanılıyor..."
    WORKSPACE_ARG="-project MagicPaper.xcodeproj"
fi

# Package dependencies'i resolve et
echo "📦 Package dependencies resolve ediliyor (retry ile)..."
RETRY_COUNT=0
MAX_RETRIES=3

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "🔄 Deneme $((RETRY_COUNT + 1))/$MAX_RETRIES..."
    
    if xcodebuild -resolvePackageDependencies $WORKSPACE_ARG -scheme MagicPaper; then
        echo "✅ Package dependencies başarıyla resolve edildi"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⚠️ Başarısız, 30 saniye bekleniyor..."
            sleep 30
        else
            echo "⚠️ Package resolve başarısız oldu, devam ediliyor..."
        fi
    fi
done

# Secrets.xcconfig oluştur (Xcode Cloud için)
echo "🔐 Secrets.xcconfig oluşturuluyor..."
if [ -n "$GEMINI_API_KEY" ]; then
    echo "GEMINI_API_KEY = $GEMINI_API_KEY" > Secrets.xcconfig
    echo "✅ Secrets.xcconfig oluşturuldu"
else
    echo "⚠️ GEMINI_API_KEY environment variable bulunamadı"
    echo "GEMINI_API_KEY = PLACEHOLDER" > Secrets.xcconfig
fi

echo "✅ Post-clone script tamamlandı!"
exit 0
