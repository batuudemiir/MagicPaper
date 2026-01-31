#!/bin/bash

echo "🔍 Türkçe metinleri buluyorum..."

# Tüm Swift dosyalarındaki Text("...") pattern'lerini bul
find MagicPaper/Views -name "*.swift" -exec grep -h 'Text("' {} \; | \
    sed 's/.*Text("\([^"]*\)").*/\1/' | \
    sort -u > turkish_strings.txt

echo "✅ $(wc -l < turkish_strings.txt) adet metin bulundu"
echo "📄 Sonuçlar turkish_strings.txt dosyasına kaydedildi"
echo ""
echo "Bu metinleri çevirmek için:"
echo "1. turkish_strings.txt dosyasını açın"
echo "2. ChatGPT/Claude'a gönderin: 'Bu Türkçe metinleri İngilizceye çevir'"
echo "3. Sonuçları LocalizationManager'a ekleyin"
