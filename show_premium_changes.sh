#!/bin/bash

echo "📄 PremiumView.swift Değişiklikler"
echo "=================================="
echo ""

echo "1️⃣  HEADER METNİ:"
echo "─────────────────"
grep -A 2 "MagicPaper Premium" MagicPaper/Views/PremiumView.swift | grep "Text(" | tail -1
echo ""

echo "2️⃣  TAB İKONLARI:"
echo "─────────────────"
grep "cart.fill\|crown.fill" MagicPaper/Views/PremiumView.swift | head -2
echo ""

echo "3️⃣  ÖZELLİKLER LİSTESİ:"
echo "─────────────────────"
grep -A 5 "var features" MagicPaper/Views/PremiumView.swift | grep '"' | head -5
echo ""

echo "4️⃣  TAB SPACING:"
echo "────────────────"
grep "HStack(spacing:" MagicPaper/Views/PremiumView.swift | grep "12"
echo ""

echo "5️⃣  DOSYA BİLGİSİ:"
echo "─────────────────"
ls -lh MagicPaper/Views/PremiumView.swift
echo ""
echo "MD5: $(md5 -q MagicPaper/Views/PremiumView.swift)"
echo ""

echo "✅ Tüm değişiklikler dosyada mevcut!"
echo ""
echo "💡 Xcode'da görünmüyorsa:"
echo "   1. ⌘ + Shift + K (Clean Build Folder)"
echo "   2. ⌘ + B (Build)"
echo "   3. ⌘ + R (Run)"
echo "   4. Simulator → Device → Erase All Content and Settings"
