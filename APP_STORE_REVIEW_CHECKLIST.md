# App Store Review Kontrol Listesi 🔍

## Review Tarihi: 3 Şubat 2026
## Submission ID: 38788f23-caae-4a98-bc8a-4c29a43b048b

---

## ❌ SORUNLAR VE ÇÖZÜMLER

### 1. ❌ Guideline 2.3.3 - iPad Screenshots
**Sorun**: iPad ekran görüntüleri iPhone görüntülerinin uzatılmış hali.

**Çözüm**:
- [ ] iPad'de gerçek ekran görüntüleri çek
- [ ] iPad Air 11-inch (M3) cihazında test et
- [ ] App Store Connect'te "View All Sizes in Media Manager" ile güncelle
- [ ] Her ekran boyutu için doğru görüntüler yükle

---

### 2. ❌ Guideline 1.3 - ASIdentifierManager / IDFA
**Sorun**: AdMob kaldırıldı ama ASIdentifierManager referansları hala binary'de var!

**ÇÖZÜM GEREKLİ**:
```
Binary'de bulundu:
• /System/Library/Frameworks/AdSupport.framework/AdSupport
• MagicPaper
```

**Yapılması Gerekenler**:
- [ ] ✅ GoogleMobileAds paketini Xcode'dan tamamen kaldır
- [ ] ✅ AdSupport.framework'ü kaldır (eğer manuel eklendiyse)
- [ ] ✅ Projeyi temizle (Clean Build Folder)
- [ ] ✅ Derived Data'yı sil
- [ ] ✅ Yeni build al
- [ ] ✅ Binary'de ASIdentifierManager kontrolü yap

**Komutlar**:
```bash
# Derived Data temizle
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Build klasörünü temizle
cd /path/to/project
rm -rf build/
```

---

### 3. ❌ Guideline 1.3 - App Privacy Information
**Sorun**: App Store Connect'te "Advertising Data" ve "Device ID" tracking olarak işaretlenmiş.

**Çözüm**:
- [ ] App Store Connect → App Privacy bölümüne git
- [ ] "Data Used to Track You" bölümünü güncelle
- [ ] Advertising Data ve Device ID'yi KALDIR
- [ ] Sadece gerekli data collection'ları işaretle:
  - Analytics (anonim)
  - Crash Data (anonim)

---

### 4. ❌ Guideline 4.0 - iPad Layout
**Sorun**: iPad Air 11-inch (M3) üzerinde UI kalabalık ve kullanımı zor.

**Kontrol Edilmesi Gerekenler**:
- [ ] ✅ DeviceHelper.swift - iPad için padding'ler doğru mu?
- [ ] ✅ Tüm view'larda `.navigationViewStyle(.stack)` var mı?
- [ ] ✅ Font boyutları iPad'de okunabilir mi?
- [ ] ✅ Button'lar yeterince büyük mü?
- [ ] ✅ Spacing'ler yeterli mi?

**Mevcut Durum**:
- ✅ DeviceHelper.swift var ve iPad desteği mevcut
- ✅ `.navigationViewStyle(.stack)` kullanılıyor
- ⚠️ iPad Air 11-inch (M3) üzerinde test edilmeli

---

### 5. ❌ Guideline 2.1 - In-App Purchases
**Sorun**: IAP ürünleri review için submit edilmemiş.

**Çözüm**:
- [ ] App Store Connect → In-App Purchases bölümüne git
- [ ] Her IAP için screenshot ekle
- [ ] IAP'leri "Submit for Review" yap
- [ ] Ürünler:
  - [ ] Yıldız Kaşifi (₺79,99/ay)
  - [ ] Hikaye Kahramanı (₺149,99/ay)
  - [ ] Sihir Ustası (₺349,99/ay)

---

### 6. ⚠️ Guideline 1.3 - Parental Gate
**Sorun**: External links ve IAP için parental gate yok.

**Mevcut Durum**:
- ✅ ParentalGateView.swift var
- ✅ SettingsView'de external linkler için parental gate var
- ✅ SimpleSubscriptionView'de IAP için parental gate var
- ⚠️ **ANCAK**: `isDevelopmentMode = true` AÇIK!

**KRİTİK**:
```swift
// SimpleSubscriptionView.swift - Satır ~9
private let isDevelopmentMode = true  // ❌ FALSE OLMALI!

// SettingsView.swift - Satır ~22
private let isDevelopmentMode = true  // ❌ FALSE OLMALI!
```

**HEMEN YAPILMALI**:
- [ ] ✅ SimpleSubscriptionView.swift → `isDevelopmentMode = false`
- [ ] ✅ SettingsView.swift → `isDevelopmentMode = false`

---

### 7. ❌ Guideline 2.1 - Analytics & Advertising Questions
**Sorun**: Apple ek bilgi istiyor.

**Cevaplar (App Store Connect'te Reply)**:

```
Dear App Review Team,

Thank you for your feedback. Here are the answers to your questions:

1. Third-party analytics:
   - We do NOT use any third-party analytics in our app.
   - We only use Apple's built-in analytics (App Store Connect Analytics).

2. Third-party advertising:
   - We do NOT include any third-party advertising in our app.
   - The app is completely ad-free.

3. Data sharing:
   - We do NOT share any user data with third parties.
   - All data is stored locally on the user's device.

4. Data collection:
   - We do NOT collect any user or device data beyond what's necessary for app functionality.
   - We only store:
     * Story content (locally on device)
     * User preferences (locally on device)
     * Profile information (locally on device)

Note: We previously had Google AdMob integrated but it has been completely removed from the app. We will ensure all references to AdSupport framework are removed in the next build.

Best regards,
MagicPaper Team
```

---

## ✅ YAPILMASI GEREKENLER (Öncelik Sırasına Göre)

### Yüksek Öncelik (Hemen)
1. ✅ **isDevelopmentMode = false** yap (2 dosya)
2. ✅ **GoogleMobileAds paketini tamamen kaldır**
3. ✅ **AdSupport framework referanslarını temizle**
4. ✅ **Clean Build + Derived Data sil**
5. ✅ **Yeni build al**

### Orta Öncelik (Build öncesi)
6. ✅ **iPad ekran görüntüleri çek**
7. ✅ **App Privacy bilgilerini güncelle**
8. ✅ **IAP'leri submit et**

### Düşük Öncelik (Submit sırasında)
9. ✅ **Review notlarına cevapları yaz**
10. ✅ **iPad layout'u test et**

---

## 🔧 TEKNIK KONTROLLER

### Binary Temizliği
```bash
# ASIdentifierManager kontrolü
nm -u YourApp.app/YourApp | grep ASIdentifierManager

# AdSupport framework kontrolü
otool -L YourApp.app/YourApp | grep AdSupport
```

### Xcode Temizliği
1. Product → Clean Build Folder (⇧⌘K)
2. Derived Data sil
3. Pods klasörünü sil (eğer CocoaPods kullanıyorsa)
4. Package Dependencies'i yeniden resolve et

---

## 📱 TEST CİHAZLARI

- [ ] iPhone 15 Pro
- [ ] iPhone SE (3rd gen)
- [ ] iPad Air 11-inch (M3) ⚠️ **Review cihazı**
- [ ] iPad Pro 12.9-inch

---

## 📋 CHECKLIST ÖZET

### Kod Değişiklikleri
- [ ] isDevelopmentMode = false (SimpleSubscriptionView.swift)
- [ ] isDevelopmentMode = false (SettingsView.swift)
- [ ] GoogleMobileAds paketi kaldırıldı
- [ ] AdSupport framework referansları temizlendi

### App Store Connect
- [ ] iPad screenshots güncellendi
- [ ] App Privacy bilgileri güncellendi
- [ ] IAP'ler submit edildi
- [ ] Review sorularına cevap verildi

### Test
- [ ] iPad Air 11-inch'te test edildi
- [ ] Parental gate çalışıyor
- [ ] IAP satın alma çalışıyor
- [ ] External linkler parental gate ile açılıyor

---

**SON KONTROL**: isDevelopmentMode = false ✅
