#!/bin/bash

echo "🔍 PremiumView.swift Değişiklik Kontrolü"
echo "========================================"
echo ""

# Renk kodları
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SUCCESS=0
FAIL=0

# 1. Header metni kontrolü
echo "1️⃣  Header metni kontrolü..."
if grep -q "Hikayelerinizi sınırsızca oluşturun" MagicPaper/Views/PremiumView.swift; then
    echo -e "${GREEN}✅ Header metni güncellendi${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${RED}❌ Header metni eski${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 2. Tab ikonları kontrolü
echo "2️⃣  Tab ikonları kontrolü..."
if grep -q "cart.fill" MagicPaper/Views/PremiumView.swift && grep -q "crown.fill" MagicPaper/Views/PremiumView.swift; then
    echo -e "${GREEN}✅ Tab ikonları eklendi (cart.fill, crown.fill)${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${RED}❌ Tab ikonları yok${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 3. Özellikler listesi kontrolü
echo "3️⃣  Özellikler listesi kontrolü..."
if grep -q "Aylık 10 görselli hikaye" MagicPaper/Views/PremiumView.swift; then
    echo -e "${GREEN}✅ Özellikler listesi güncellendi${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${RED}❌ Özellikler listesi eski${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 4. Tab spacing kontrolü
echo "4️⃣  Tab spacing kontrolü..."
if grep -q "HStack(spacing: 12)" MagicPaper/Views/PremiumView.swift; then
    echo -e "${GREEN}✅ Tab spacing güncellendi (12px)${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${RED}❌ Tab spacing eski${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 5. Dosya timestamp kontrolü
echo "5️⃣  Dosya timestamp kontrolü..."
FILE_TIME=$(stat -f "%Sm" -t "%H:%M" MagicPaper/Views/PremiumView.swift)
echo "   Son değişiklik: $FILE_TIME"
echo -e "${GREEN}✅ Dosya güncel${NC}"
SUCCESS=$((SUCCESS+1))
echo ""

# Özet
echo "========================================"
echo "📊 SONUÇ:"
echo -e "${GREEN}✅ Başarılı: $SUCCESS${NC}"
echo -e "${RED}❌ Hata: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 Tüm değişiklikler dosyada mevcut!${NC}"
    echo ""
    echo "💡 Eğer Xcode'da görünmüyorsa:"
    echo "   1. Xcode'u TAMAMEN KAPAT"
    echo "   2. ./clean_build.sh çalıştır"
    echo "   3. Xcode'u aç"
    echo "   4. ⌘ + Shift + K (Clean Build Folder)"
    echo "   5. ⌘ + B (Build)"
    echo "   6. ⌘ + R (Run)"
    echo ""
    echo "🔄 Veya simulator'ı sıfırla:"
    echo "   Device → Erase All Content and Settings"
else
    echo -e "${RED}❌ Bazı değişiklikler eksik!${NC}"
fi
