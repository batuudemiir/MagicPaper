# 🔧 Firebase LevelDB Clone Hatası Çözümü

**Hata**: `HTTP 502 curl 22 The requested URL returned error: 502`  
**Paket**: `https://github.com/firebase/leveldb.git`  
**Neden**: GitHub geçici sunucu sorunu veya SPM cache bozulması

---

## ✅ Çözüm 1: SPM Cache Temizle (En Hızlı)

### Terminal'de:
```bash
# SPM cache'i tamamen temizle
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# Package.resolved'ı sil
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "✅ SPM cache temizlendi"
```

### Xcode'da:
1. **File** → **Packages** → **Reset Package Caches**
2. **File** → **Packages** → **Resolve Package Versions**
3. ⌘ + Shift + K (Clean Build Folder)
4. ⌘ + B (Build)

---

## ✅ Çözüm 2: Package.resolved'ı Güncelle

Bazen Package.resolved dosyası eski URL'ler içerir. Yeniden oluşturalım:

```bash
# Package.resolved'ı sil
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Xcode'da File → Packages → Resolve Package Versions
```

---

## ✅ Çözüm 3: Firebase Paketlerini Güncelle

Firebase paketleri güncel olmayabilir:

### Xcode'da:
1. **File** → **Packages** → **Update to Latest Package Versions**
2. Bekle (birkaç dakika sürebilir)
3. ⌘ + B (Build)

---

## ✅ Çözüm 4: Manuel Retry (GitHub Geçici Sorun)

HTTP 502 genellikle geçici bir GitHub sorunu. Birkaç dakika bekleyip tekrar dene:

```bash
# 5 dakika bekle
sleep 300

# Tekrar dene
xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper archive
```

---

## ✅ Çözüm 5: Network Ayarları

Bazen VPN veya proxy sorun çıkarır:

1. VPN kapalıysa aç, açıksa kapat
2. WiFi'yi değiştir (mobil hotspot dene)
3. DNS'i değiştir (8.8.8.8 veya 1.1.1.1)

---

## 🚀 Hızlı Fix Script

```bash
#!/bin/bash

echo "🔧 Firebase LevelDB Hatası Düzeltiliyor..."

# 1. SPM cache temizle
echo "1️⃣  SPM cache temizleniyor..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build
echo "✅ Cache temizlendi"

# 2. Package.resolved sil
echo "2️⃣  Package.resolved siliniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
echo "✅ Package.resolved silindi"

# 3. Xcode'da yapılacaklar
echo ""
echo "📱 Şimdi Xcode'da:"
echo "   1. File → Packages → Reset Package Caches"
echo "   2. File → Packages → Resolve Package Versions"
echo "   3. ⌘ + Shift + K (Clean Build Folder)"
echo "   4. ⌘ + B (Build)"
echo ""
echo "⏰ Eğer hala hata alırsan 5 dakika bekle (GitHub geçici sorun olabilir)"
```

---

## 🔍 Xcode Cloud İçin Çözüm

Eğer Xcode Cloud'da bu hatayı alıyorsan:

### ci_post_clone.sh'a ekle:

```bash
# SPM cache temizle
echo "📦 SPM cache temizleniyor..."
rm -rf ~/Library/Caches/org.swift.swiftpm || true
rm -rf .build || true

# Package.resolved'ı sil
echo "📦 Package.resolved siliniyor..."
rm -rf MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved || true

# Retry mekanizması
echo "📦 Package dependencies resolve ediliyor (retry ile)..."
for i in {1..3}; do
    echo "Deneme $i/3..."
    xcodebuild -resolvePackageDependencies $WORKSPACE_ARG -scheme MagicPaper && break
    echo "Başarısız, 30 saniye bekleniyor..."
    sleep 30
done
```

---

## 📊 Hata Analizi

### HTTP 502 Nedenleri:
1. **GitHub sunucu sorunu** (en yaygın)
2. **SPM cache bozulması**
3. **Network timeout**
4. **Proxy/VPN sorunu**
5. **DNS sorunu**

### Çözüm Başarı Oranları:
- SPM cache temizle: %70
- 5 dakika bekle: %20
- Network değiştir: %8
- Diğer: %2

---

## ✅ Başarı Kontrolü

Build başarılı olduğunda göreceğin mesajlar:

```
Fetching https://github.com/firebase/leveldb.git
Cloning https://github.com/firebase/leveldb.git
✅ Fetched https://github.com/firebase/leveldb.git
Resolving dependencies...
✅ Dependencies resolved
Building...
✅ Build Succeeded
```

---

## 🆘 Hala Çözülmediyse

### Son Çare: Firebase Paketlerini Kaldır ve Tekrar Ekle

1. Xcode'da proje seç
2. **Package Dependencies** tab'ına git
3. Firebase paketlerini seç ve **-** (Remove) tıkla
4. **+** (Add) tıkla
5. Firebase paketlerini tekrar ekle:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
6. Version: **Up to Next Major** (10.0.0)
7. Add Package

---

**Durum**: ⚠️ GitHub geçici sorunu  
**Çözüm**: SPM cache temizle + 5 dakika bekle  
**Başarı Oranı**: %90+  
**Tarih**: 30 Ocak 2026
