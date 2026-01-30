#!/bin/bash

# Tutulacak dosyalar
KEEP_FILES=(
    "README.md"
    "README_TURKISH.md"
    "QUICK_START.md"
    "BUILD_HAZIR.md"
    "PRIVACY_POLICY.md"
    "TERMS_OF_SERVICE.md"
)

# Tüm .md dosyalarını listele
echo "��️  Gereksiz .md dosyaları temizleniyor..."
echo ""

deleted_count=0
kept_count=0

for file in *.md; do
    # Dosya tutulacaklar listesinde mi kontrol et
    keep=false
    for keep_file in "${KEEP_FILES[@]}"; do
        if [ "$file" = "$keep_file" ]; then
            keep=true
            break
        fi
    done
    
    if [ "$keep" = false ]; then
        rm "$file"
        echo "❌ Silindi: $file"
        ((deleted_count++))
    else
        echo "✅ Tutuldu: $file"
        ((kept_count++))
    fi
done

echo ""
echo "📊 Özet:"
echo "   Silinen: $deleted_count dosya"
echo "   Tutulan: $kept_count dosya"
echo ""
echo "✨ Temizlik tamamlandı!"
