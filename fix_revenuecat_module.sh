#!/bin/bash

# RevenueCat Module Error Fix Script
# Usage: ./fix_revenuecat_module.sh

echo "🔧 RevenueCat Module Error Fix"
echo "================================"
echo ""

# Change to project directory
cd /Users/batudemir/Desktop/MagicPaperAPP/MagicPaper

echo "1️⃣ Closing Xcode..."
killall Xcode 2>/dev/null
sleep 2

echo "2️⃣ Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "3️⃣ Cleaning SPM cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm/*

echo "4️⃣ Cleaning build folder..."
rm -rf build/

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode: open MagicPaper.xcodeproj"
echo "2. File > Packages > Reset Package Caches"
echo "3. Wait for packages to resolve (30-60 seconds)"
echo "4. Cmd + Shift + K (Clean Build)"
echo "5. Cmd + B (Build)"
echo ""
echo "If still not working:"
echo "- Check: Project > Target > General > Frameworks"
echo "- RevenueCat should be listed there"
echo "- If not, add it with + button"
echo ""

read -p "Open Xcode now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🚀 Opening Xcode..."
    open MagicPaper.xcodeproj
fi
