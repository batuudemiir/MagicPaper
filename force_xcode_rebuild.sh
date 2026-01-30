#!/bin/bash

echo "🔨 Xcode'u Zorla Yeniden Build Ettirme"
echo "======================================"
echo ""

# 1. Xcode process'lerini kontrol et
echo "1️⃣  Xcode process'leri kontrol ediliyor..."
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  Xcode çalışıyor! Lütfen Xcode'u KAPAT (⌘ + Q)"
    echo ""
    read -p "Xcode'u kapattıktan sonra Enter'a bas..."
fi
echo "✅ Xcode kapalı"
echo ""

# 2. Tüm cache'leri temizle
echo "2️⃣  Tüm cache'ler temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null
rm -rf ~/Library/Caches/org.swift.swiftpm/* 2>/dev/null
rm -rf .build 2>/dev/null
rm -rf build 2>/dev/null
echo "✅ Cache'ler temizlendi"
echo ""

# 3. Workspace state'i temizle
echo "3️⃣  Workspace state temizleniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcuserdata/* 2>/dev/null
rm -rf MagicPaper.xcodeproj/xcuserdata/* 2>/dev/null
echo "✅ Workspace state temizlendi"
echo ""

# 4. PremiumView.swift'i touch et (timestamp güncelle)
echo "4️⃣  PremiumView.swift timestamp güncelleniyor..."
touch MagicPaper/Views/PremiumView.swift
TIMESTAMP=$(stat -f "%Sm" -t "%H:%M:%S" MagicPaper/Views/PremiumView.swift)
echo "✅ Timestamp güncellendi: $TIMESTAMP"
echo ""

# 5. Dosya içeriğini kontrol et
echo "5️⃣  Değişiklikleri kontrol ediliyor..."
if grep -q "cart.fill" MagicPaper/Views/PremiumView.swift; then
    echo "✅ Tab ikonları mevcut (cart.fill)"
else
    echo "❌ Tab ikonları YOK!"
fi

if grep -q "Hikayelerinizi sınırsızca oluşturun" MagicPaper/Views/PremiumView.swift; then
    echo "✅ Header metni güncel"
else
    echo "❌ Header metni ESKİ!"
fi

if grep -q "Aylık 10 görselli hikaye" MagicPaper/Views/PremiumView.swift; then
    echo "✅ Özellikler listesi güncel"
else
    echo "❌ Özellikler listesi ESKİ!"
fi
echo ""

# 6. MD5 hash
echo "6️⃣  Dosya hash'i:"
md5 MagicPaper/Views/PremiumView.swift
echo ""

echo "🎉 Hazırlık tamamlandı!"
echo ""
echo "📱 ŞİMDİ YAPILACAKLAR:"
echo ""
echo "1. Xcode'u AÇ:"
echo "   open MagicPaper.xcodeproj"
echo ""
echo "2. Xcode açıldıktan sonra:"
echo "   a) Product → Clean Build Folder (⌘ + Shift + K)"
echo "   b) Bekle (temizlik bitsin)"
echo "   c) Product → Build (⌘ + B)"
echo "   d) Bekle (build bitsin)"
echo "   e) Product → Run (⌘ + R)"
echo ""
echo "3. Simulator'da:"
echo "   a) Settings → Premium'a git"
echo "   b) Yeni tab tasarımını gör (🛒 ve 👑 ikonları)"
echo ""
echo "💡 HALA ESKİ GÖRÜNÜYORSA:"
echo "   - Simulator → Device → Erase All Content and Settings"
echo "   - Sonra tekrar Run yap"
