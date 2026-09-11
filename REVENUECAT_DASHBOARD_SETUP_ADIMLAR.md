# 🎨 RevenueCat Dashboard Paywall Setup - Adım Adım

## 🚀 Hızlı Başlangıç

**Dashboard:** https://app.revenuecat.com/

## 📋 Adım 1: Entitlements Oluştur

### 1.1 Entitlements Sayfasına Git
```
Sol menü > Entitlements
```

### 1.2 Yeni Entitlement Oluştur
```
+ New Entitlement butonu
```

### 1.3 Bilgileri Gir
```
Identifier: premium
Display Name: Premium Access
Description: Full access to all premium features
```

### 1.4 Kaydet
```
Create butonu
```

**✅ Kontrol:** Entitlements listesinde "premium" görünmeli

---

## 📦 Adım 2: Products Oluştur

### 2.1 Products Sayfasına Git
```
Sol menü > Products
```

### 2.2 Product 1: Basic (Yıldız Kaşifi)
```
+ New butonu

Product ID: magicpaper_basic_monthly
Store: App Store
Type: Subscription
Entitlement: premium (dropdown'dan seç)

Save
```

### 2.3 Product 2: Premium (Hikaye Kahramanı)
```
+ New butonu

Product ID: magicpaper_premium_monthly
Store: App Store
Type: Subscription
Entitlement: premium

Save
```

### 2.4 Product 3: Ultimate (Sihir Ustası)
```
+ New butonu

Product ID: magicpaper_ultimate_monthly
Store: App Store
Type: Subscription
Entitlement: premium

Save
```

**✅ Kontrol:** Products listesinde 3 product görünmeli

---

## 🎁 Adım 3: Offering Oluştur

### 3.1 Offerings Sayfasına Git
```
Sol menü > Offerings
```

### 3.2 Yeni Offering Oluştur
```
+ New Offering butonu
```

### 3.3 Offering Bilgileri
```
Identifier: default
Display Name: Hikaye Kulübü Paketleri
Description: Çocuğunuza okuma alışkanlığı kazandırın

✅ Make this the current offering (ÖNEMLİ!)

Create butonu
```

**✅ Kontrol:** "default" offering oluştu ve "Current" badge'i var

---

## 📦 Adım 4: Packages Ekle

### 4.1 Default Offering'i Aç
```
Offerings listesinde "default" tıkla
```

### 4.2 Package 1: Basic
```
+ Add Package butonu

Identifier: $rc_monthly (dropdown'dan seç veya custom)
Product: magicpaper_basic_monthly (dropdown'dan seç)

Add butonu
```

### 4.3 Package 2: Premium
```
+ Add Package butonu

Identifier: $rc_monthly (veya custom: monthly_premium)
Product: magicpaper_premium_monthly

Add butonu
```

### 4.4 Package 3: Ultimate
```
+ Add Package butonu

Identifier: $rc_monthly (veya custom: monthly_ultimate)
Product: magicpaper_ultimate_monthly

Add butonu
```

**✅ Kontrol:** Default offering'de 3 package görünmeli

---

## 🎨 Adım 5: Paywall Tasarımı (Opsiyonel)

### 5.1 Paywall Editörü Aç
```
Offerings > default > Paywall tab > Edit Paywall butonu
```

### 5.2 Template Seç
```
Template: Multi-package (önerilen)
```

### 5.3 Header Ayarları
```
Title: Hikaye Kulübü 📚
Subtitle: Çocuğunuza okuma alışkanlığı kazandırın
```

### 5.4 Renkler
```
Primary Color: #FF9500 (Orange)
Secondary Color: #FFD700 (Gold)
Background: Gradient veya Solid
```

### 5.5 Package Descriptions
```
Basic Package:
- Title: ⭐ Yıldız Kaşifi
- Description: 1 görselli hikaye/ay + Sınırsız metin

Premium Package:
- Title: 👑 Hikaye Kahramanı
- Description: 5 görselli hikaye/ay + Sınırsız metin
- ✅ Mark as popular

Ultimate Package:
- Title: 🌟 Sihir Ustası
- Description: 10 görselli hikaye/ay + Sınırsız metin
```

### 5.6 Features (Her paket için)
```
✅ Görselli hikayeler
✅ Sınırsız metin hikaye
✅ Sınırsız günlük hikaye
✅ Reklamsız deneyim
✅ Tüm karakterler
```

### 5.7 Footer
```
Terms of Use: https://www.magicpaperkids.com/kullanim-sartlari
Privacy Policy: https://www.magicpaperkids.com/gizlilik
```

### 5.8 Kaydet
```
Save butonu
```

---

## ✅ Adım 6: Test Et

### 6.1 Uygulamayı Çalıştır
```
Xcode > Cmd + R
```

### 6.2 Paywall'ı Aç
```
Premium özellik tıkla veya "Kulübe Katıl"
```

### 6.3 Kontrol Et
```
✅ RevenueCat paywall görünüyor
✅ 3 paket görünüyor
✅ Fiyatlar görünüyor (eğer App Store Connect'te oluşturulduysa)
✅ Close butonu çalışıyor
```

### 6.4 Console Kontrol
```
Xcode Console'da:
✅ RevenueCat offerings loaded: 1 offerings
📦 Current offering: default
📦 Available packages: 3
```

---

## 🛍️ Adım 7: App Store Connect Products (Gerekli)

### 7.1 App Store Connect'e Git
```
https://appstoreconnect.apple.com/
```

### 7.2 In-App Purchases
```
My Apps > MagicPaper > In-App Purchases
```

### 7.3 Subscription Group Oluştur
```
+ butonunun yanındaki dropdown > Subscription Group

Name: MagicPaper Subscriptions
Reference Name: magicpaper_subscriptions

Create
```

### 7.4 Product 1: Basic
```
+ butonu > Auto-Renewable Subscription

Reference Name: Yıldız Kaşifi
Product ID: magicpaper_basic_monthly
Subscription Group: MagicPaper Subscriptions

Subscription Duration: 1 Month
Subscription Prices: ₺89.99

Localization (Turkish):
- Display Name: ⭐ Yıldız Kaşifi
- Description: Ayda 1 görselli hikaye + Sınırsız metin ve günlük hikaye

Save
```

### 7.5 Product 2: Premium
```
+ butonu > Auto-Renewable Subscription

Reference Name: Hikaye Kahramanı
Product ID: magicpaper_premium_monthly
Subscription Group: MagicPaper Subscriptions

Subscription Duration: 1 Month
Subscription Prices: ₺149.99

Localization (Turkish):
- Display Name: 👑 Hikaye Kahramanı
- Description: Ayda 5 görselli hikaye + Sınırsız metin ve günlük hikaye

Save
```

### 7.6 Product 3: Ultimate
```
+ butonu > Auto-Renewable Subscription

Reference Name: Sihir Ustası
Product ID: magicpaper_ultimate_monthly
Subscription Group: MagicPaper Subscriptions

Subscription Duration: 1 Month
Subscription Prices: ₺349.99

Localization (Turkish):
- Display Name: 🌟 Sihir Ustası
- Description: Ayda 10 görselli hikaye + Sınırsız metin ve günlük hikaye

Save
```

### 7.7 Submit for Review
```
Her product için:
- Ready to Submit > Submit for Review
```

**⚠️ Not:** Products onaylanana kadar (1-2 gün) gerçek fiyatlar görünmez. Test için sandbox kullan.

---

## 🧪 Adım 8: Sandbox Test

### 8.1 Sandbox Account Oluştur
```
App Store Connect > Users and Access > Sandbox Testers
+ butonu
Email ve şifre oluştur
```

### 8.2 iOS Cihazda/Simulator'da
```
Settings > App Store > Sign Out (gerçek hesap varsa)
Sandbox hesabı ile GİRİŞ YAPMA (uygulama soracak)
```

### 8.3 Satın Alma Test
```
1. Uygulamayı aç
2. Paywall'ı aç
3. Bir paket seç
4. Subscribe tıkla
5. Sandbox hesabı ile giriş yap
6. Satın al
```

### 8.4 Console Kontrol
```
✅ Purchase completed!
🎉 Premium aktif!
🔄 Updating SubscriptionManager...
   → Setting tier: Premium
```

---

## 📊 Checklist

### RevenueCat Dashboard
- [ ] Entitlement oluşturuldu (`premium`)
- [ ] 3 Product eklendi
- [ ] Offering oluşturuldu (`default`)
- [ ] Current offering işaretli
- [ ] 3 Package eklendi
- [ ] Paywall tasarımı yapıldı (opsiyonel)

### App Store Connect
- [ ] Subscription group oluşturuldu
- [ ] 3 In-App Purchase oluşturuldu
- [ ] Fiyatlar ayarlandı
- [ ] Localization eklendi
- [ ] Submit for review yapıldı

### Test
- [ ] Uygulamada paywall görünüyor
- [ ] 3 paket görünüyor
- [ ] Sandbox satın alma çalışıyor
- [ ] Premium aktif oluyor
- [ ] Restore çalışıyor

---

## 🎯 Şimdi Ne Yapmalısın?

### 1. RevenueCat Dashboard Setup (10 dakika)
```
1. Entitlements > + New > premium
2. Products > 3 product ekle
3. Offerings > + New > default
4. Packages > 3 package ekle
```

### 2. Test Et (2 dakika)
```
Xcode > Run
Paywall aç
Console kontrol et
```

### 3. App Store Connect (15 dakika)
```
In-App Purchases > 3 subscription oluştur
Submit for review
```

### 4. Sandbox Test (5 dakika)
```
Sandbox account oluştur
Satın alma test et
```

---

## 🆘 Sorun Giderme

### Paywall Boş Görünüyor
**Çözüm:** RevenueCat Dashboard'da offerings oluştur

### Fiyatlar Görünmüyor
**Çözüm:** App Store Connect'te products oluştur ve onay bekle

### Satın Alma Çalışmıyor
**Çözüm:** 
1. Product ID'ler eşleşiyor mu kontrol et
2. Sandbox account kullanıyor musun?
3. Products onaylandı mı?

### "No current offering"
**Çözüm:** Offering'i "Current" olarak işaretle

---

## 📚 Kaynaklar

- **RevenueCat Dashboard:** https://app.revenuecat.com/
- **App Store Connect:** https://appstoreconnect.apple.com/
- **RevenueCat Docs:** https://docs.revenuecat.com/
- **Paywall Builder:** https://docs.revenuecat.com/docs/paywalls

---

**Şimdi:** RevenueCat Dashboard'a git ve adımları takip et! 🚀
