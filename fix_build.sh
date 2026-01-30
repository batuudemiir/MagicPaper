#!/bin/bash

echo "🧹 Xcode cache temizleniyor..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-*

echo "🧹 Build klasörü temizleniyor..."
rm -rf build/

echo "✅ Temizlik tamamlandı!"
echo ""
echo "📝 Şimdi Xcode'da şunları yap:"
echo "1. Xcode'u kapat"
echo "2. Xcode'u tekrar aç"
echo "3. Product > Clean Build Folder (Cmd+Shift+K)"
echo "4. Product > Build (Cmd+B)"
echo ""
echo "Eğer hala hata varsa:"
echo "- Xcode'u tamamen kapat"
echo "- Terminal'de: killall Xcode"
echo "- Xcode'u tekrar aç"
