# 🛍️ App Store Connect - 3 Subscription Oluştur

## 📋 Subscription 1: Yıldız Kaşifi (Basic)

### Type
```
Consumable değil!
Auto-Renewable Subscription seç
```

### Reference Name
```
Yıldız Kaşifi
```

### Product ID
```
magicpaper_basic_monthly
```

⚠️ **ÖNEMLİ:** Product ID RevenueCat'teki ile AYNI olmalı!

### Subscription Group
```
Mevcut group'u seç (zaten oluşturmuşsun)
```

### Subscription Duration
```
1 Month
```

### Subscription Prices
```
Turkey (TRY): ₺89.99
```

### Localization (Turkish - Turkey)
```
Subscription Display Name: ⭐ Yıldız Kaşifi
Description: Ayda 1 görselli hikaye + Sınırsız metin ve günlük hikaye
```

### Review Information
```
Screenshot: Paywall ekran görüntüsü yükle
Review Notes: Basic subscription tier for MagicPaper app
```

### Save
```
Create butonu
```

---

## 📋 Subscription 2: Hikaye Kahramanı (Premium)

### Type
```
Auto-Renewable Subscription
```

### Reference Name
```
Hikaye Kahramanı
```

### Product ID
```
magicpaper_premium_monthly
```

### Subscription Group
```
Aynı group
```

### Subscription Duration
```
1 Month
```

### Subscription Prices
```
Turkey (TRY): ₺149.99
```

### Localization (Turkish - Turkey)
```
Subscription Display Name: 👑 Hikaye Kahramanı
Description: Ayda 5 görselli hikaye + Sınırsız metin ve günlük hikaye (EN POPÜLER)
```

### Review Information
```
Screenshot: Paywall ekran görüntüsü
Review Notes: Premium subscription tier (most popular)
```

### Save
```
Create butonu
```

---

## 📋 Subscription 3: Sihir Ustası (Ultimate)

### Type
```
Auto-Renewable Subscription
```

### Reference Name
```
Sihir Ustası
```

### Product ID
```
magicpaper_ultimate_monthly
```

### Subscription Group
```
Aynı group
```

### Subscription Duration
```
1 Month
```

### Subscription Prices
```
Turkey (TRY): ₺349.99
```

### Localization (Turkish - Turkey)
```
Subscription Display Name: 🌟 Sihir Ustası
Description: Ayda 10 görselli hikaye + Sınırsız metin ve günlük hikaye
```

### Review Information
```
Screenshot: Paywall ekran görüntüsü
Review Notes: Ultimate subscription tier with maximum benefits
```

### Save
```
Create butonu
```

---

## ✅ Tamamlandıktan Sonra

### 1. Submit for Review (Her biri için)

```
Her subscription'ı aç
Sağ üstte "Submit for Review" butonu
Confirm
```

**Status:** "Waiting for Review" olmalı

### 2. Uygulamayı Yeniden Başlat

```bash
Xcode'da:
Cmd + .  (Stop)
Cmd + R  (Run)
```

### 3. Paywall'ı Test Et

```
Paywall'ı aç
Şimdi fiyatlar görünmeli!
```

**⚠️ Not:** Fiyatlar hemen görünmeyebilir. Apple sync 1-2 saat sürebilir.

---

## 🧪 Sandbox Test

### Sandbox Account Oluştur

```
App Store Connect > Users and Access > Sandbox Testers
+ butonu

Email: test@example.com (gerçek email olmasına gerek yok)
Password: [güçlü şifre]
Country: Turkey

Create
```

### iOS'ta Hazırlık

```
Settings > App Store > Sign Out (gerçek hesap varsa)
Sandbox hesabı ile GİRİŞ YAPMA (uygulama soracak)
```

### Satın Alma Test

```
1. Uygulamayı aç
2. Paywall'ı aç
3. Bir paket seç
4. Subscribe tıkla
5. Sandbox hesabı ile giriş yap
6. Satın al
```

**Console'da görmeli:**
```
✅ Purchase completed!
🎉 Premium aktif!
```

---

## 📊 Product ID Kontrolü

RevenueCat ve App Store Connect'te AYNI olmalı:

| Tier | Product ID |
|------|-----------|
| Basic | `magicpaper_basic_monthly` |
| Premium | `magicpaper_premium_monthly` |
| Ultimate | `magicpaper_ultimate_monthly` |

---

## 🎯 Checklist

- [ ] Subscription 1: Basic oluşturuldu
- [ ] Subscription 2: Premium oluşturuldu
- [ ] Subscription 3: Ultimate oluşturuldu
- [ ] Fiyatlar ayarlandı (₺89, ₺149, ₺349)
- [ ] Localization eklendi
- [ ] Submit for review yapıldı
- [ ] Sandbox account oluşturuldu
- [ ] Satın alma test edildi

---

**Şimdi:** 3 subscription'ı oluştur ve submit et! 🚀
