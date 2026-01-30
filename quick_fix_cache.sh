#!/bin/bash

echo "🧹 Xcode Cache Temizleniyor..."

# Xcode'u kapat
killall Xcode 2>/dev/null
killall xcodebuild 2>/dev/null
killall SourceKitService 2>/dev/null

# Cache temizle
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

echo "✅ Cache temizlendi!"
echo ""
echo "📝 Şimdi:"
echo "1. Xcode'u aç"
echo "2. Product > Clean Build Folder (⌘⇧K)"
echo "3. Product > Build (⌘B)"
echo ""
echo "✨ Hazır!"
