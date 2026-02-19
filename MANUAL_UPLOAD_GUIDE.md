# 📦 Manuel Upload - Xcode'dan App Store Connect'e

## Xcode Cloud Build Alıyor Ama Upload Etmiyor

Xcode Cloud workflow'u sadece "archive" yapıyor, TestFlight'a upload etmiyor. Manuel olarak upload edelim:

---

## Yöntem 1: Xcode'dan Archive ve Upload (EN KOLAY)

### Adım 1: Xcode'u Aç
```bash
cd /path/to/MagicPaper
open MagicPaper.xcodeproj
```

### Adım 2: Scheme ve Destination Ayarla
1. Üst bar'da **"MagicPaper"** scheme seçili olmalı
2. Destination: **"Any iOS Device (arm64)"** seç
   - Eğer simulator seçiliyse, tıkla ve "Any iOS Device" seç

### Adım 3: Clean Build (Önemli!)
```
Product → Clean Build Folder (⇧⌘K)
```

### Adım 4: Archive Oluştur
```
Product → Archive (⌘B tuşuna basılı tut)
```

**Veya menüden**:
```
Product → Archive
```

**Süre**: 5-10 dakika

### Adım 5: Organizer Penceresi Açılacak
Archive tamamlandığında otomatik olarak **"Organizer"** penceresi açılır.

Eğer açılmazsa:
```
Window → Organizer (⇧⌘⌥O)
```

### Adım 6: Archive'i Seç
1. Sol tarafta **"Archives"** sekmesi
2. **"MagicPaper"** uygulamasını seç
3. En üstteki (en son) archive'i seç
4. Sağ tarafta **"Distribute App"** butonuna tıkla

### Adım 7: Distribution Seçenekleri

#### 1. Distribution Method
- ✅ **"App Store Connect"** seç
- **"Next"** butonuna tıkla

#### 2. Destination
- ✅ **"Upload"** seç (TestFlight ve App Store için)
- **"Next"** butonuna tıkla

#### 3. App Store Connect Distribution Options
- ✅ **"Upload your app's symbols"** işaretli olsun (crash reports için)
- ✅ **"Manage Version and Build Number"** işaretli olsun
- **"Next"** butonuna tıkla

#### 4. Signing
- ✅ **"Automatically manage signing"** seç
- **"Next"** butonuna tıkla

#### 5. Review
- Tüm bilgileri kontrol et
- **"Upload"** butonuna tıkla

### Adım 8: Upload Başladı! ⏳
- Progress bar göreceksin
- **Süre**: 5-10 dakika
- İnternet hızına bağlı

### Adım 9: Upload Tamamlandı! ✅
**"Upload Successful"** mesajını göreceksin.

**"Done"** butonuna tıkla.

---

## Yöntem 2: Xcode Cloud Archive'ini İndir ve Upload Et

Eğer Xcode Cloud zaten archive aldıysa, onu indirebilir ve upload edebilirsin:

### Adım 1: Xcode Cloud Archive'ini İndir
1. App Store Connect → **"Xcode Cloud"** sekmesi
2. **"Builds"** → Build #32'yi seç
3. **"Artifacts"** bölümünde **"MagicPaper.xcarchive"** göreceksin
4. **"Download"** butonuna tıkla

### Adım 2: Archive'i Xcode'da Aç
```bash
# İndirilen archive'i aç
open ~/Downloads/MagicPaper.xcarchive
```

### Adım 3: Organizer'da Upload Et
1. Organizer penceresi açılacak
2. Archive seçili olacak
3. **"Distribute App"** → Yukarıdaki adımları takip et

---

## Yöntem 3: Xcode Cloud Workflow'unu Güncelle (Gelecek İçin)

Xcode Cloud'un otomatik upload yapması için workflow'u güncelle:

### Adım 1: Xcode Cloud Workflow Ayarları
1. Xcode'u aç
2. **"Product"** → **"Xcode Cloud"** → **"Manage Workflows"**

### Adım 2: Workflow'u Düzenle
1. **"Magic"** workflow'unu seç
2. **"Edit Workflow"** butonuna tıkla

### Adım 3: Post-Actions Ekle
1. **"Archive"** action'ını seç
2. **"Post-Actions"** bölümüne git
3. **"+"** butonuna tıkla
4. **"TestFlight Internal Testing"** seç
5. **"Save"**

### Adım 4: Sonraki Build'lerde Otomatik Upload
Artık her commit'te:
1. Build alınacak
2. Archive oluşturulacak
3. **Otomatik olarak TestFlight'a upload edilecek** ✅

---

## 🔍 Upload Sonrası Kontrol

### 1. Email Bildirimi
Apple şu email'i gönderecek:
```
Subject: Your app has been uploaded to App Store Connect
```

### 2. App Store Connect'te Kontrol
1. https://appstoreconnect.apple.com
2. **"Apps"** → **"MagicPaper"**
3. **"TestFlight"** sekmesi
4. **"iOS"** bölümü

### 3. Build Processing
Upload sonrası:
- ⏳ **"Processing"** durumunda olacak
- **Süre**: 10-30 dakika
- Email gelecek: **"Your build is ready for testing"**

### 4. Export Compliance
Build processing tamamlandığında:
1. TestFlight'ta build'e tıkla
2. **"Provide Export Compliance Information"**
3. **"No"** seç (encryption kullanmıyoruz)
4. **"Start Internal Testing"**

---

## ⚠️ Olası Hatalar ve Çözümler

### Hata 1: "No signing certificate found"
**Çözüm**:
```
Xcode → Settings → Accounts → Apple ID seç → Download Manual Profiles
```

### Hata 2: "Archive failed"
**Çözüm**:
```bash
# Clean build
Product → Clean Build Folder (⇧⌘K)

# Derived Data sil
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Tekrar dene
Product → Archive
```

### Hata 3: "Invalid binary"
**Çözüm**:
- Scheme'in "Release" configuration kullandığından emin ol
- Product → Scheme → Edit Scheme → Archive → Build Configuration: Release

### Hata 4: "Upload failed"
**Çözüm**:
- İnternet bağlantını kontrol et
- VPN kapalı olmalı
- Tekrar dene

---

## 📋 Checklist: Upload Öncesi

- [ ] ✅ isDevelopmentMode = false
- [ ] ✅ GoogleMobileAds kaldırıldı
- [ ] ✅ Secrets.xcconfig var ve API key içeriyor
- [ ] ✅ Version number doğru (1.0)
- [ ] ✅ Build number artırıldı (32 veya üzeri)
- [ ] ✅ Scheme: MagicPaper
- [ ] ✅ Destination: Any iOS Device (arm64)
- [ ] ✅ Clean Build yapıldı

---

## 🎯 Hızlı Özet

### EN KOLAY YOL:
```
1. Xcode'u aç: open MagicPaper.xcodeproj
2. Destination: Any iOS Device (arm64)
3. Product → Clean Build Folder (⇧⌘K)
4. Product → Archive
5. Distribute App → App Store Connect → Upload
6. 10-15 dakika bekle
7. TestFlight'ta görünecek!
```

### SONRA:
```
1. App Store Connect → TestFlight
2. Build'i gör
3. Export Compliance: No
4. App Store sekmesine git
5. Build'i seç
6. Submit for Review!
```

---

## 📞 Yardım

### Archive Sırasında Hata Alırsan:
```bash
# Log'ları kontrol et
# Xcode → Report Navigator (⌘9) → Son build'i seç
```

### Upload Sırasında Hata Alırsan:
```bash
# Organizer'da "Export" butonunu dene
# IPA dosyasını kaydet
# Application Loader ile upload et (eski yöntem)
```

---

## 🎉 Başarı!

Upload başarılı olduğunda:
- ✅ Email gelecek
- ✅ TestFlight'ta görünecek
- ✅ 10-30 dakika processing
- ✅ Ready to Submit!

**Şimdi yapman gereken**: Xcode'u aç ve Archive al! 🚀
