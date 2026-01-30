#!/bin/bash

echo "🔧 Firebase LevelDB Hatası Düzeltiliyor..."
echo ""

# 1. SPM cache temizle
echo "1️⃣  SPM cache temizleniyor..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null
rm -rf .build 2>/dev/null
echo "✅ SPM cache temizlendi"
echo ""

# 2. Package.resolved sil
echo "2️⃣  Package.resolved siliniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved 2>/dev/null
echo "✅ Package.resolved silindi"
echo ""

# 3. Workspace state temizle
echo "3️⃣  Workspace state temizleniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcuserdata 2>/dev/null
echo "✅ Workspace state temizlendi"
echo ""

echo "🎉 Temizlik tamamlandı!"
echo ""
echo "📱 Şimdi Xcode'da:"
echo "   1. Xcode'u KAPAT (⌘ + Q)"
echo "   2. Xcode'u AÇ"
echo "   3. File → Packages → Reset Package Caches"
echo "   4. File → Packages → Resolve Package Versions"
echo "   5. ⌘ + Shift + K (Clean Build Folder)"
echo "   6. ⌘ + B (Build)"
echo ""
echo "⏰ Eğer hala HTTP 502 hatası alırsan:"
echo "   - 5-10 dakika bekle (GitHub geçici sorun olabilir)"
echo "   - WiFi değiştir veya VPN dene"
echo "   - Tekrar bu scripti çalıştır"
