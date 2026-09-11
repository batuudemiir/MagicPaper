# 📋 Subscription Compliance Checklist - Apple Review

## ❌ Apple'ın Red Sebebi (Guideline 3.1.2)

**Sorun:** Auto-renewable subscription bilgileri ve EULA/Privacy Policy linkleri eksik.

**Tarih:** February 19, 2026  
**Submission ID:** a44bb478-dd8a-45fc-9814-104ad4ca720e

---

## ✅ ZORUNLU: Uygulama İçinde (Paywall'da)

RevenueCat paywall'ı otomatik gösteriyor ama kontrol edelim:

### 1. Subscription Bilgileri (Paywall'da Görünmeli)

- [ ] **Subscription Title** (Ürün adı)
  - Yıldız Kaşifi
  - Hikaye Kahramanı
  - Sihir Ustası

- [ ] **Subscription Length** (Süre)
  - 1 Month / Aylık

- [ ] **Price** (Fiyat)
  - ₺89.99/ay
  - ₺149.99/ay
  - ₺349.99/ay

- [ ] **Privacy Policy Link** (Çalışan link)
  - Paywall'da tıklanabilir link olmalı

- [ ] **Terms of Use (EULA) Link** (Çalışan link)
  - Paywall'da tıklanabilir link olmalı

---

## ✅ ZORUNLU: App Store Connect Metadata

### 2. Privacy Policy URL

```
App Store Connect > My Apps > MagicPaper
> App Information
> Privacy Policy URL: [URL buraya]
```

**Durum:** [ ] Eklendi / [ ] Eksik

### 3. Terms of Use (EULA)

**Seçenek A: Apple'ın Standart EULA'sı (Kolay)**

```
App Store Connect > My Apps > MagicPaper
> App Information
> App Description (açıklama)

Açıklamanın sonuna ekle:
"Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
```

**Seçenek B: Özel EULA (Daha İyi)**

```
App Store Connect > My Apps > MagicPaper
> App Information
> License Agreement (EULA) bölümü
> Özel EULA yükle
```

**Durum:** [ ] Eklendi / [ ] Eksik

---

## 🔍 Kontrol Adımları

### Adım 1: Paywall'ı Kontrol Et

```
1. Uygulamayı aç
2. Premium özelliğe tıkla (paywall açılsın)
3. Kontrol et:
   ✓ Ürün adları görünüyor mu?
   ✓ Fiyatlar görünüyor mu?
   ✓ "1 Month" veya "Aylık" yazıyor mu?
   ✓ Privacy Policy linki var mı?
   ✓ Terms of Use linki var mı?
```

**Sonuç:** [ ] Tamam / [ ] Eksik

### Adım 2: Linkleri Test Et

```
1. Paywall'da Privacy Policy linkine tıkla
2. Sayfa açılıyor mu? ✓ / ✗
3. Paywall'da Terms of Use linkine tıkla
4. Sayfa açılıyor mu? ✓ / ✗
```

**Sonuç:** [ ] Tamam / [ ] Eksik

### Adım 3: App Store Connect Metadata

```
App Store Connect > My Apps > MagicPaper
> App Information

1. Privacy Policy URL dolu mu? [ ]
2. App Description'da EULA linki var mı? [ ]
   VEYA
   License Agreement (EULA) yüklendi mi? [ ]
```

**Sonuç:** [ ] Tamam / [ ] Eksik

---

## 🛠️ Eksikleri Tamamla

### 1. Privacy Policy Oluştur (Yoksa)

**Hızlı Çözüm:** Privacy Policy Generator kullan

```
https://www.privacypolicygenerator.info/
veya
https://app-privacy-policy-generator.firebaseapp.com/

Bilgiler:
- App Name: Magic Paper
- Developer: [Senin adın]
- Contact: [Email]
- Data Collection: 
  * User profiles (names, ages)
  * Story preferences
  * Subscription status
- Third Party Services:
  * Google Gemini AI
  * Firebase Storage
  * RevenueCat
```

**Nereye Koy:**
- GitHub Pages (ücretsiz)
- Firebase Hosting (ücretsiz)
- Kendi website'in

**Link Örneği:** `https://yourusername.github.io/magicpaper-privacy`

### 2. Terms of Use (EULA)

**Seçenek A: Apple Standart EULA (En Kolay)**

App Description'a ekle:
```
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

**Seçenek B: Özel EULA Oluştur**

Template: https://www.termsfeed.com/terms-conditions-generator/

---

## 📱 RevenueCat Paywall Kontrolü

RevenueCat'in native paywall'ı otomatik olarak şunları gösterir:
- ✅ Ürün adları
- ✅ Fiyatlar
- ✅ Subscription süreleri

**Ama Privacy Policy ve Terms linkleri manuel eklenmeli!**

### RevenueCat Dashboard'da Paywall'ı Güncelle

```
1. RevenueCat Dashboard > Paywalls
2. "default" paywall'ı aç
3. "Go to editor" tıkla
4. Footer'a ekle:
   - Privacy Policy linki
   - Terms of Use linki
```

**VEYA**

### Kodda Manuel Ekle (SimpleSubscriptionView)

Paywall'ın altına link butonları ekle.

---

## ✅ Final Checklist (Gönderim Öncesi)

### Uygulama İçi (Paywall)
- [ ] Subscription adları görünüyor
- [ ] Fiyatlar görünüyor (₺89.99, ₺149.99, ₺349.99)
- [ ] Süre görünüyor (1 Month / Aylık)
- [ ] Privacy Policy linki var ve çalışıyor
- [ ] Terms of Use linki var ve çalışıyor

### App Store Connect
- [ ] Privacy Policy URL eklendi
- [ ] Terms of Use (EULA) eklendi:
  - [ ] App Description'da Apple EULA linki
  - [ ] VEYA özel EULA yüklendi

### Test
- [ ] Paywall açılıyor
- [ ] Tüm linkler çalışıyor
- [ ] Bilgiler doğru görünüyor

### Build
- [ ] StoreKit Configuration: None
- [ ] Production API Key aktif
- [ ] Clean Build yapıldı
- [ ] Archive başarılı
- [ ] Validate geçti

---

## 🎯 Öncelikli Yapılacaklar

1. **Privacy Policy oluştur ve yayınla** (30 dakika)
2. **App Store Connect'e Privacy Policy URL ekle** (2 dakika)
3. **App Description'a Apple EULA linki ekle** (2 dakika)
4. **RevenueCat paywall'ına Privacy/Terms linkleri ekle** (10 dakika)
5. **Test et** (5 dakika)
6. **Yeni build yükle** (20 dakika)

---

## 📞 Apple'a Cevap Şablonu

App Store Connect'te rejection'a cevap ver:

```
Hello,

Thank you for the feedback. I have updated the app to include all required subscription information:

1. Privacy Policy: Added to App Store Connect and visible in the paywall
2. Terms of Use (EULA): Using Apple's Standard EULA, link added to App Description
3. Subscription details (title, price, duration) are displayed in the paywall

All links have been tested and are functional. The updated build has been submitted.

Please let me know if you need any additional information.

Best regards,
[Your Name]
```

---

## 🚨 Kritik Notlar

1. **Privacy Policy ve EULA linkleri ÇALIŞMALI** - Broken link = instant rejection
2. **Paywall'da görünür olmalı** - Settings'te gizli olması yetmez
3. **Her subscription için bilgi göster** - 3 ürün varsa 3'ü de net olmalı
4. **Test et!** - Apple reviewer'ın göreceği gibi test et

---

**Şimdi:** Privacy Policy var mı? Yoksa oluşturalım mı?
