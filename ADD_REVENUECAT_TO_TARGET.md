# 🔧 RevenueCat Package'ını Target'a Ekleme

## ⚠️ Sorun
RevenueCat package'ı projeye eklenmiş ama target'a link edilmemiş.

**Hata:**
```
Unable to find module dependency: 'RevenueCat'
```

## ✅ Çözüm: Xcode'da Package'ı Target'a Ekle

### Adım 1: Xcode'da Projeyi Aç
```bash
open MagicPaper.xcodeproj
```

### Adım 2: Project Navigator'da Projeyi Seç
1. Sol panelde en üstteki "MagicPaper" projesine tıklayın (mavi ikon)
2. Orta panelde "TARGETS" altında "MagicPaper" target'ını seçin

### Adım 3: General Tab
1. Üst menüden "General" tab'ına tıklayın
2. Aşağı scroll edin "Frameworks, Libraries, and Embedded Content" bölümüne

### Adım 4: RevenueCat Ekle
1. "Frameworks, Libraries, and Embedded Content" altındaki **+** butonuna tıklayın
2. Açılan pencerede "RevenueCat" arayın
3. "RevenueCat" seçin (package icon ile)
4. "Add" butonuna tıklayın

### Adım 5: Build Settings Kontrol (Opsiyonel)
1. "Build Settings" tab'ına gidin
2. "Other Linker Flags" arayın
3. Eğer yoksa ekleyin: `-ObjC`

### Adım 6: Clean Build
```bash
# Xcode'da:
Cmd + Shift + K  (Clean Build Folder)

# Veya terminal'de:
cd /Users/batudemir/Desktop/MagicPaperAPP/MagicPaper
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-*
```

### Adım 7: Build
```bash
# Xcode'da:
Cmd + B  (Build)
```

## 🎯 Alternatif Yöntem: Package Dependencies

### Adım 1: Project Settings
1. Project Navigator'da "MagicPaper" projesine tıklayın
2. "Package Dependencies" tab'ına gidin

### Adım 2: Package Kontrol
1. "purchases-ios-spm" package'ının listede olduğunu görün
2. Sağ tıklayın > "Update to Latest Package Versions"

### Adım 3: Target'a Ekle
1. "TARGETS" > "MagicPaper" seçin
2. "General" > "Frameworks, Libraries, and Embedded Content"
3. **+** butonuna tıklayın
4. "RevenueCat" seçin

## 🔍 Doğrulama

Build başarılı olduktan sonra:

1. **Console'da şu mesajları görmelisiniz:**
   ```
   ✅ RevenueCat yapılandırıldı
   🔑 RevenueCatManager: Initializing...
   📦 RevenueCat: Fetching offerings...
   ```

2. **Import çalışmalı:**
   ```swift
   import RevenueCat  // ✅ Hata vermemeli
   ```

## 🐛 Hala Çalışmıyorsa

### Yöntem 1: Package'ı Yeniden Ekle

1. **Package'ı Kaldır:**
   - Project Settings > Package Dependencies
   - "purchases-ios-spm" seçin
   - **-** butonuna tıklayın

2. **Package'ı Tekrar Ekle:**
   - File > Add Package Dependencies
   - URL: `https://github.com/RevenueCat/purchases-ios-spm.git`
   - Version: "Up to Next Major" - 5.0.0
   - Add to Target: **MagicPaper** (✅ işaretli olmalı)
   - Add Package

### Yöntem 2: DerivedData Temizle

```bash
# Terminal'de:
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*

# Xcode'da:
Cmd + Shift + K  (Clean Build Folder)
Cmd + Option + Shift + K  (Clean Build Folder + Delete DerivedData)
```

### Yöntem 3: Xcode'u Yeniden Başlat

```bash
# Xcode'u kapat
killall Xcode

# Xcode'u tekrar aç
open MagicPaper.xcodeproj
```

## 📝 Notlar

- Package zaten `Package.resolved` dosyasında var (version 5.59.2)
- Sadece target'a link edilmesi gerekiyor
- Kod `#if canImport(RevenueCat)` ile korunmuş durumda
- Package eklendikten sonra otomatik çalışacak

## ✅ Başarı Kontrolü

Build başarılı olduktan sonra:

```swift
// MagicPaperApp.swift
import RevenueCat  // ✅ Hata yok

// Console output:
✅ Firebase yapılandırıldı
✅ RevenueCat yapılandırıldı: appl_OIeeP...
🔑 RevenueCatManager: Initializing...
📦 RevenueCat: Fetching offerings...
```

---

**Özet:** Xcode'da Project > Target > General > Frameworks'e RevenueCat ekleyin ve build edin.
