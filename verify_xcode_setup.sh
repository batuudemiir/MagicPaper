#!/bin/bash

# Xcode Cloud Setup Verification Script
# Bu script local setup'ın doğru olup olmadığını kontrol eder

echo "🔍 MagicPaper Xcode Cloud Setup Kontrolü"
echo "========================================"
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Başarı/hata sayacı
SUCCESS=0
FAIL=0
WARNING=0

# 1. Secrets.xcconfig dosyası var mı?
echo "1️⃣  Secrets.xcconfig dosyası kontrolü..."
if [ -f "Secrets.xcconfig" ]; then
    echo -e "${GREEN}✅ Secrets.xcconfig bulundu${NC}"
    SUCCESS=$((SUCCESS+1))
    
    # API key var mı?
    if grep -q "GEMINI_API_KEY" Secrets.xcconfig; then
        echo -e "${GREEN}✅ GEMINI_API_KEY tanımlı${NC}"
        SUCCESS=$((SUCCESS+1))
    else
        echo -e "${RED}❌ GEMINI_API_KEY bulunamadı${NC}"
        FAIL=$((FAIL+1))
    fi
else
    echo -e "${RED}❌ Secrets.xcconfig bulunamadı${NC}"
    echo -e "${YELLOW}💡 Secrets.xcconfig.template'i kopyalayıp API key ekleyin${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 2. Secrets.xcconfig Xcode projesinde mi?
echo "2️⃣  Xcode projesi kontrolü..."
if grep -q "Secrets.xcconfig" MagicPaper.xcodeproj/project.pbxproj; then
    echo -e "${GREEN}✅ Secrets.xcconfig Xcode projesinde${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${RED}❌ Secrets.xcconfig Xcode projesinde değil${NC}"
    echo -e "${YELLOW}💡 XCODE_CLOUD_FIX.md dosyasındaki adımları takip edin${NC}"
    FAIL=$((FAIL+1))
fi
echo ""

# 3. Info.plist doğru mu?
echo "3️⃣  Info.plist kontrolü..."
if grep -q '\$(GEMINI_API_KEY)' MagicPaper/Info.plist; then
    echo -e "${GREEN}✅ Info.plist \$(GEMINI_API_KEY) kullanıyor${NC}"
    SUCCESS=$((SUCCESS+1))
else
    if grep -q 'GEMINI_API_KEY' MagicPaper/Info.plist; then
        echo -e "${YELLOW}⚠️  Info.plist'te GEMINI_API_KEY var ama hardcoded olabilir${NC}"
        WARNING=$((WARNING+1))
    else
        echo -e "${RED}❌ Info.plist'te GEMINI_API_KEY bulunamadı${NC}"
        FAIL=$((FAIL+1))
    fi
fi
echo ""

# 4. CI scripts executable mi?
echo "4️⃣  CI scripts kontrolü..."
if [ -x "ci_scripts/ci_post_clone.sh" ]; then
    echo -e "${GREEN}✅ ci_post_clone.sh executable${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${YELLOW}⚠️  ci_post_clone.sh executable değil${NC}"
    echo -e "${YELLOW}💡 chmod +x ci_scripts/ci_post_clone.sh${NC}"
    WARNING=$((WARNING+1))
fi

if [ -x "ci_scripts/ci_pre_xcodebuild.sh" ]; then
    echo -e "${GREEN}✅ ci_pre_xcodebuild.sh executable${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${YELLOW}⚠️  ci_pre_xcodebuild.sh executable değil${NC}"
    echo -e "${YELLOW}💡 chmod +x ci_scripts/ci_pre_xcodebuild.sh${NC}"
    WARNING=$((WARNING+1))
fi
echo ""

# 5. .gitignore kontrolü
echo "5️⃣  .gitignore kontrolü..."
if grep -q "Secrets.xcconfig" .gitignore; then
    echo -e "${GREEN}✅ Secrets.xcconfig .gitignore'da${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${YELLOW}⚠️  Secrets.xcconfig .gitignore'da değil${NC}"
    echo -e "${YELLOW}💡 API key'i GitHub'a push etmeyin!${NC}"
    WARNING=$((WARNING+1))
fi
echo ""

# 6. AIService.swift fallback kontrolü
echo "6️⃣  AIService.swift fallback kontrolü..."
if grep -q "ProcessInfo.processInfo.environment\[\"GEMINI_API_KEY\"\]" MagicPaper/Services/AIService.swift; then
    echo -e "${GREEN}✅ AIService.swift environment variable fallback var${NC}"
    SUCCESS=$((SUCCESS+1))
else
    echo -e "${YELLOW}⚠️  AIService.swift environment variable fallback yok${NC}"
    WARNING=$((WARNING+1))
fi
echo ""

# Özet
echo "========================================"
echo "📊 SONUÇ:"
echo -e "${GREEN}✅ Başarılı: $SUCCESS${NC}"
echo -e "${YELLOW}⚠️  Uyarı: $WARNING${NC}"
echo -e "${RED}❌ Hata: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ] && [ $WARNING -eq 0 ]; then
    echo -e "${GREEN}🎉 Tüm kontroller başarılı! Xcode Cloud'a push edebilirsiniz.${NC}"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Bazı uyarılar var ama build çalışmalı.${NC}"
    exit 0
else
    echo -e "${RED}❌ Kritik hatalar var! XCODE_CLOUD_FIX.md dosyasını okuyun.${NC}"
    exit 1
fi
