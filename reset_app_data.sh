#!/bin/bash

# Reset app data for testing
echo "🔄 Uygulama verilerini sıfırlıyorum..."

# Get simulator ID
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 17" | grep -v "unavailable" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ iPhone 17 simulator bulunamadı"
    exit 1
fi

echo "📱 Simulator ID: $SIMULATOR_ID"

# Uninstall app
echo "🗑️  Uygulamayı kaldırıyorum..."
xcrun simctl uninstall "$SIMULATOR_ID" com.batu.magicpaper.v1 2>/dev/null || true

echo "✅ Uygulama verisi temizlendi!"
echo ""
echo "Şimdi Xcode'dan uygulamayı çalıştırabilirsiniz."
