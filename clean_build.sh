#!/bin/bash

echo "🧹 Xcode Clean Build Başlatılıyor..."
echo ""

# DerivedData temizle
echo "1️⃣  DerivedData temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-* 2>/dev/null
echo "✅ DerivedData temizlendi"
echo ""

# Build folder temizle
echo "2️⃣  Build folder temizleniyor..."
rm -rf build 2>/dev/null
echo "✅ Build folder temizlendi"
echo ""

# Xcode cache temizle
echo "3️⃣  Xcode cache temizleniyor..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null
echo "✅ Xcode cache temizlendi"
echo ""

# Module cache temizle
echo "4️⃣  Module cache temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null
echo "✅ Module cache temizlendi"
echo ""

echo "🎉 Temizlik tamamlandı!"
echo ""
echo "📱 Şimdi Xcode'da:"
echo "   1. ⌘ + Shift + K (Clean Build Folder)"
echo "   2. ⌘ + B (Build)"
echo "   3. ⌘ + R (Run)"
echo ""
echo "💡 Eğer hala yansımıyorsa:"
echo "   - Xcode'u tamamen kapat"
echo "   - Bu scripti tekrar çalıştır"
echo "   - Xcode'u aç ve build yap"
