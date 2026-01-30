#!/bin/bash

echo "🧪 Build Test Başlatılıyor..."
echo ""

# Clean
echo "🧹 Clean build..."
xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper clean 2>&1 | grep -E "(error|warning|succeeded|failed)" || echo "Clean tamamlandı"

echo ""
echo "🔨 Build başlatılıyor..."
echo ""

# Build
xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper build 2>&1 | tee build_output.log

# Sonuçları kontrol et
if grep -q "BUILD SUCCEEDED" build_output.log; then
    echo ""
    echo "✅ BUILD BAŞARILI!"
    echo ""
    echo "🎉 Tüm hatalar düzeltildi!"
    echo ""
    echo "📱 Şimdi yapabilecekleriniz:"
    echo "   1. Xcode'da Cmd + R ile simulator'da çalıştırın"
    echo "   2. Ana sayfada kredi banner'ını göreceksiniz"
    echo "   3. Hikaye oluşturma ekranlarında kredi maliyetlerini göreceksiniz"
    echo ""
else
    echo ""
    echo "❌ BUILD BAŞARISIZ"
    echo ""
    echo "Hatalar:"
    grep "error:" build_output.log | head -10
    echo ""
    echo "Çözüm için:"
    echo "   1. ./fix_xcode_build.sh çalıştırın"
    echo "   2. Xcode'u yeniden başlatın"
    echo "   3. Bu scripti tekrar çalıştırın"
    echo ""
fi

# Log dosyasını temizle
rm -f build_output.log
