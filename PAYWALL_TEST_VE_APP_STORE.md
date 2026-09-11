# ✅ Paywall Yayınlandı - Test ve App Store Setup

## 🎉 Tebrikler!

RevenueCat Dashboard'da paywall oluşturuldu ve yayınlandı!

## 🧪 Adım 1: Uygulamada Test Et (2 dakika)

### 1.1 Uygulamayı Yeniden Başlat

```bash
Xcode'da:
Cmd + .  (Stop)
Cmd + R  (Run)
```

### 1.2 Paywall'ı Aç

```
Ana ekranda premium özellik tıkla
VEYA
"Kulübe Katıl" butonu
```

### 1.3 Kontrol Et

**Görmeli:**
- ✅ RevenueCat paywall görünüyor
- ✅ 3 paket görünüyor
- ✅ Tasarımın yayınlandı
- ✅ Close butonu çalışıyor

**Console'da:**
```
✅ RevenueCat offerings loaded: 1 offerings
📦 Current offering: default
📦 Available packages: 3
   - magicpaper_basic_monthly: [fiyat]
   - magicpaper_premium_monthly: [fiyat]
   - magicpaper_ultimate_monthly: [fiyat]
```

### 1.4 Eğer Fiyatlar Görünmüyorsa

**Normal!** App Store Connect'te products henüz oluşturulmadı.

**Göreceksin:**
- Package isimleri
- "Loading..." veya placeholder fiyatlar

**Çözüm:** App Store Connect'te subscriptions oluştur (Adım 2)

---

## 🛍️ Adım 2: App Store Connect Subscriptions (15 dakika)

### 2.1 App Store Connect'e Git

```
https://appstoreconnect.apple.com/
```

### 2.2 Uygulamayı Seç

```
My Apps > MagicPaper
```

### 2.3 In-App Purchases Sayfası

```
Sol menü > Monetization > In-App Purchases
```

### 2.4 Subscription Group Oluştur

```
+ butonunun yanındaki dropdown > Subscription Group

Group Reference Name: MagicPaper Subscriptions
Group Display Name: Hikaye Kulübü

Create
```

### 2.5 Subscription 1: Basic (Yıldız Kaşifi)

```
Subscription Group içinde + butonu

Reference Name: Yıldız Kaşifi
Product ID: magicpaper_basic_monthly

Subscription Duration: 1 Month

Subscription Prices:
- Turkey (TRY): ₺89.99

Localization (Turkish - Turkey):
- Subscription Display Name: ⭐ Yıldız Kaşifi
- Description: Ayda 1 görselli hikaye + Sınırsız metin ve günlük hikaye

App Store Promotion (Optional):
- Promotional Image: [Opsiyonel]

Review Information:
- Screenshot: [Paywall screenshot]
- Review Notes: Test subscription for MagicPaper app

Save
```

### 2.6 Subscription 2: Premium (Hikaye Kahramanı)

```
+ butonu

Reference Name: Hikaye Kahramanı
Product ID: magicpaper_premium_monthly

Subscription Duration: 1 Month

Subscription Prices:
- Turkey (TRY): ₺149.99

Localization (Turkish - Turkey):
- Subscription Display Name: 👑 Hikaye Kahramanı
- Description: Ayda 5 görselli hikaye + Sınırsız metin ve günlük hikaye

Review Information:
- Screenshot: [Paywall screenshot]

Save
```

### 2.7 Subscription 3: Ultimate (Sihir Ustası)

```
+ butonu

Reference Name: Sihir Ustası
Product ID: magicpaper_ultimate_monthly

Subscription Duration: 1 Month

Subscription Prices:
- Turkey (TRY): ₺349.99

Localization (Turkish - Turkey):
- Subscription Display Name: 🌟 Sihir Ustası
- Description: Ayda 10 görselli hikaye + Sınırsız metin ve günlük hikaye

Review Information:
- Screenshot: [Paywall screenshot]

Save
```

### 2.8 Submit for Review

```
Her subscription için:
1. Subscription'ı aç
2. Sağ üstte "Submit for Review" butonu
3. Confirm

Status: "Waiting for Review" olmalı
```

**⚠️ Not:** Review süreci 1-2 gün sürebilir. Ama sandbox test için beklemeye gerek yok!

---

## 🧪 Adım 3: Sandbox Test (5 dakika)

### 3.1 Sandbox Account Oluştur

```
App Store Connect > Users and Access > Sandbox Testers
+ butonu

First Name: Test
Last Name: User
Email: test@example.com (gerçek email olmasına gerek yok)
Password: [güçlü şifre]
Confirm Password: [aynı şifre]
Country/Region: Turkey

Create
```

### 3.2 iOS Cihazda/Simulator'da Hazırlık

```
Settings > App Store

Eğer gerçek Apple ID ile giriş yaptıysan:
- Sign Out (çıkış yap)

Sandbox hesabı ile GİRİŞ YAPMA!
(Uygulama ilk satın almada soracak)
```

### 3.3 Satın Alma Test

```
1. Uygulamayı aç (Xcode > Run)
2. Paywall'ı aç
3. Bir paket seç (örn: Premium)
4. "Subscribe" veya satın alma butonuna tıkla
5. Apple satın alma ekranı açılacak
6. Sandbox hesabı ile giriş yap (ilk kez sorulacak)
7. Şifre gir
8. "Subscribe" tıkla
9. Confirm
```

### 3.4 Beklenen Sonuç

**Console'da:**
```
💳 Purchasing with RevenueCat: 👑 Hikaye Kahramanı
💳 RevenueCat: Purchasing package...
✅ Purchase completed!
Entitlements: [premium: active]
🎉 Premium aktif!
🔄 Updating SubscriptionManager...
   Premium active: true
   Active subscriptions: ["magicpaper_premium_monthly"]
   → Setting tier: Premium
```

**Uygulamada:**
- Paywall kapanır
- Premium özelliklere erişim açılır
- SubscriptionManager.shared.isPremium = true

### 3.5 Restore Test

```
1. Uygulamayı kapat ve sil
2. Xcode'dan tekrar yükle
3. Paywall'ı aç
4. "Restore Purchases" butonu (eğer varsa)
5. Sandbox hesabı ile giriş yap
6. Premium geri gelmeli
```

**Console'da:**
```
🔄 RevenueCat: Restoring purchases...
✅ Restore successful
✅ Premium entitlement restored
🔄 Updating SubscriptionManager...
   → Setting tier: Premium
```

---

## 📊 Checklist

### RevenueCat Dashboard ✅
- [x] Entitlement: premium
- [x] 3 Product
- [x] Offering: default (current)
- [x] 3 Package
- [x] Paywall yayınlandı

### App Store Connect
- [ ] Subscription group oluşturuldu
- [ ] 3 Subscription oluşturuldu
- [ ] Fiyatlar ayarlandı (₺89, ₺149, ₺349)
- [ ] Localization eklendi
- [ ] Submit for review yapıldı

### Test
- [ ] Uygulamada paywall görünüyor
- [ ] 3 paket görünüyor
- [ ] Sandbox account oluşturuldu
- [ ] Sandbox satın alma test edildi
- [ ] Premium aktif oluyor
- [ ] Restore test edildi

---

## 🎯 Şimdi Yapılacaklar

### 1. Uygulamayı Test Et (2 dakika)

```bash
Xcode > Cmd + R
Paywall aç
Console kontrol et
```

### 2. App Store Connect Setup (15 dakika)

```
1. Subscription group oluştur
2. 3 Subscription oluştur
3. Fiyatları ayarla
4. Submit for review
```

### 3. Sandbox Test (5 dakika)

```
1. Sandbox account oluştur
2. Satın alma test et
3. Premium kontrolü
4. Restore test et
```

---

## 🐛 Sorun Giderme

### Paywall Boş Görünüyor

**Çözüm:**
```bash
# Uygulamayı yeniden başlat
Cmd + .
Cmd + R

# Console kontrol et
✅ RevenueCat offerings loaded: 1 offerings
```

### Fiyatlar Görünmüyor

**Normal!** App Store Connect'te products henüz oluşturulmadı.

**Çözüm:** App Store Connect'te subscriptions oluştur

### Satın Alma Çalışmıyor

**Kontrol Et:**
1. Product ID'ler eşleşiyor mu?
   - RevenueCat: magicpaper_basic_monthly
   - App Store: magicpaper_basic_monthly
2. Sandbox account kullanıyor musun?
3. Settings > App Store'dan gerçek hesap çıkış yaptın mı?

### "No products available"

**Çözüm:**
1. App Store Connect'te products oluştur
2. 1-2 saat bekle (Apple sync)
3. Uygulamayı yeniden başlat

---

## 📱 Production'a Geçiş (Sonra)

### 1. Production API Key Al

```
RevenueCat Dashboard > Project Settings > API Keys
iOS > Production Key (appl_ ile başlar)
Kopyala
```

### 2. Secrets.xcconfig Güncelle

```bash
# Production için
REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY
```

### 3. Release Build

```
Xcode > Edit Scheme > Run > Release
Archive > Upload to App Store
```

### 4. TestFlight Test

```
TestFlight'ta test et
Gerçek satın alma test et (gerçek para!)
```

---

## 🎉 Başarı Kriterleri

Tüm bunları görüyorsan başarılısın:

✅ RevenueCat paywall görünüyor
✅ 3 paket görünüyor
✅ Sandbox satın alma çalışıyor
✅ Premium aktif oluyor
✅ SubscriptionManager güncelleniyor
✅ Restore çalışıyor

---

**Şimdi:** Uygulamayı test et ve App Store Connect'te subscriptions oluştur! 🚀
