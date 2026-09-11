# 🧪 RevenueCat Test Rehberi

## ✅ API Key Güncellendi

**Test/Sandbox Key:**
```
test_ElHyzdqEfyVopUtAWnZlTlOnTmu
```

Bu key Secrets.xcconfig'e eklendi ve test için hazır!

## 🚀 Hızlı Test

### 1. Clean Build

```bash
# Xcode'da:
Cmd + Shift + K  # Clean Build Folder
Cmd + B          # Build
```

### 2. Run

```bash
# Xcode'da:
Cmd + R  # Run
```

### 3. Console Kontrol

Xcode console'da şunları görmelisiniz:

```
🚀 AppDelegate: didFinishLaunching başladı
✅ Firebase yapılandırıldı
✅ RevenueCat yapılandırıldı: test_ElHyz...
🔑 RevenueCatManager: Initializing...
📦 RevenueCat: Fetching offerings...
✅ RevenueCat customer info loaded
```

## 📱 Paywall Test

### Adım 1: Paywall'ı Açın

1. Uygulamayı çalıştırın
2. Ana ekranda bir premium özellik tıklayın
3. Veya "Kulübe Katıl" butonuna tıklayın

### Adım 2: Loading Kontrolü

Paywall açıldığında:
- ✅ Loading indicator görünmeli
- ✅ "Paketler yükleniyor..." yazısı görünmeli
- ✅ 2-3 saniye içinde paketler yüklenmeli

**Console'da:**
```
💳 SimpleSubscriptionView appeared
📦 Loading RevenueCat offerings...
📦 RevenueCat: Fetching offerings...
```

### Adım 3: Offerings Kontrolü

#### Başarılı Senaryo ✅

**Console'da görmelisiniz:**
```
✅ RevenueCat offerings loaded: 1 offerings
📦 Current offering: default
📦 Available packages: 3
   - $rc_monthly_basic: ₺89.99
   - $rc_monthly_premium: ₺149.99
   - $rc_monthly_ultimate: ₺349.99
```

**Paywall'da görmelisiniz:**
- ⭐ Yıldız Kaşifi - ₺89/ay
- 👑 Hikaye Kahramanı - ₺149/ay (POPÜLER)
- 🌟 Sihir Ustası - ₺349/ay

#### Başarısız Senaryo ⚠️

**Console'da görürseniz:**
```
⚠️ RevenueCat offerings yüklenemedi, fallback mode
```

**Nedenleri:**
1. RevenueCat Dashboard'da offerings oluşturulmamış
2. Products eklenmemiş
3. Internet bağlantısı yok
4. API key yanlış

**Çözüm:** Aşağıdaki "RevenueCat Dashboard Setup" bölümüne bakın

## 🎯 RevenueCat Dashboard Setup

### Adım 1: Login

https://app.revenuecat.com/ adresine gidin ve login yapın

### Adım 2: Project Seçin

"MagicPaper" projenizi seçin (veya yeni oluşturun)

### Adım 3: Entitlements Oluşturun

1. Sol menüden **Entitlements** tıklayın
2. **+ New Entitlement** butonuna tıklayın
3. **Identifier:** `premium`
4. **Display Name:** `Premium Access`
5. **Save** tıklayın

### Adım 4: Products Ekleyin

1. Sol menüden **Products** tıklayın
2. **+ New** butonuna tıklayın

**Product 1: Basic**
- **Product ID:** `magicpaper_basic_monthly`
- **Store:** App Store
- **Type:** Subscription
- **Entitlement:** `premium`
- **Save**

**Product 2: Premium**
- **Product ID:** `magicpaper_premium_monthly`
- **Store:** App Store
- **Type:** Subscription
- **Entitlement:** `premium`
- **Save**

**Product 3: Ultimate**
- **Product ID:** `magicpaper_ultimate_monthly`
- **Store:** App Store
- **Type:** Subscription
- **Entitlement:** `premium`
- **Save**

### Adım 5: Offerings Oluşturun

1. Sol menüden **Offerings** tıklayın
2. **+ New Offering** butonuna tıklayın
3. **Identifier:** `default`
4. **Display Name:** `Hikaye Kulübü Paketleri`
5. **Make this the current offering** ✅ işaretleyin
6. **Save**

### Adım 6: Packages Ekleyin

Offering'i açın ve packages ekleyin:

**Package 1:**
- **Identifier:** `$rc_monthly_basic`
- **Product:** `magicpaper_basic_monthly`
- **Add**

**Package 2:**
- **Identifier:** `$rc_monthly_premium`
- **Product:** `magicpaper_premium_monthly`
- **Add**

**Package 3:**
- **Identifier:** `$rc_monthly_ultimate`
- **Product:** `magicpaper_ultimate_monthly`
- **Add**

### Adım 7: Verify

Dashboard'da kontrol edin:
- ✅ 1 Entitlement (`premium`)
- ✅ 3 Products (basic, premium, ultimate)
- ✅ 1 Offering (`default` - current)
- ✅ 3 Packages

## 🛍️ Sandbox Purchase Test

### Önce: Sandbox Account Oluşturun

1. **App Store Connect**: https://appstoreconnect.apple.com/
2. **Users and Access** > **Sandbox Testers**
3. **+** butonuna tıklayın
4. Test kullanıcısı oluşturun
5. Email ve şifre kaydedin

### Test Adımları

1. **iOS Cihazda/Simulator'da:**
   - Settings > App Store
   - Sign Out (eğer gerçek hesap varsa)
   - Sandbox Account ile giriş YAPMAYIN (uygulama ilk satın almada soracak)

2. **Uygulamayı Çalıştırın:**
   - Paywall'ı açın
   - Bir paket seçin
   - "Kulübe Katıl" butonuna tıklayın

3. **Parental Gate:**
   - Matematik sorusunu çözün
   - Devam edin

4. **Sandbox Purchase:**
   - Apple satın alma ekranı açılacak
   - Sandbox hesabı ile giriş yapın
   - "Subscribe" tıklayın
   - Şifre girin

5. **Verify:**
   - Success mesajı görmelisiniz
   - Premium özelliklere erişim olmalı

**Console'da:**
```
💳 Purchasing with RevenueCat: 👑 Hikaye Kahramanı
💳 RevenueCat: Purchasing package $rc_monthly_premium...
✅ Purchase successful!
🔄 Updating SubscriptionManager...
   Premium active: true
   Active subscriptions: ["magicpaper_premium_monthly"]
   → Setting tier: Premium
```

## 🔄 Restore Purchases Test

### Adım 1: Uygulamayı Silin

Simulator'da veya cihazda uygulamayı silin

### Adım 2: Yeniden Yükleyin

Xcode'dan tekrar run edin

### Adım 3: Restore

1. Paywall'ı açın
2. "Satın Alımları Geri Yükle" butonuna tıklayın
3. Sandbox hesabı ile giriş yapın (gerekirse)

**Console'da:**
```
🔄 RevenueCat: Restoring purchases...
✅ Restore successful
✅ Premium entitlement restored
🔄 Updating SubscriptionManager...
   → Setting tier: Premium
```

## 🐛 Sorun Giderme

### Offerings Yüklenmiyor

**Hata:**
```
⚠️ RevenueCat offerings yüklenemedi, fallback mode
```

**Çözümler:**
1. RevenueCat Dashboard'da offerings oluşturun
2. Products ekleyin
3. Current offering olarak işaretleyin
4. Uygulamayı yeniden başlatın

### Purchase Başarısız

**Hata:**
```
❌ Purchase error: ...
```

**Çözümler:**
1. Sandbox hesabı doğru mu kontrol edin
2. App Store Connect'te products oluşturun
3. Product ID'lerin eşleştiğinden emin olun
4. Sandbox hesabının aktif olduğunu kontrol edin

### Premium Aktif Olmuyor

**Hata:**
```
🔄 Updating SubscriptionManager...
   Premium active: false
```

**Çözümler:**
1. Entitlement identifier'ı kontrol edin (`premium`)
2. Products'ın entitlement'a bağlı olduğunu kontrol edin
3. RevenueCat Dashboard'da customer'ı kontrol edin

## 📊 Test Checklist

### Build & Run
- [ ] Clean build başarılı
- [ ] Uygulama açılıyor
- [ ] Console'da RevenueCat log'ları var

### Paywall
- [ ] Paywall açılıyor
- [ ] Loading indicator çalışıyor
- [ ] 3 paket görünüyor
- [ ] Fiyatlar doğru

### RevenueCat Dashboard
- [ ] Entitlement oluşturuldu (`premium`)
- [ ] 3 product eklendi
- [ ] Offering oluşturuldu (`default`)
- [ ] 3 package eklendi
- [ ] Current offering işaretli

### Purchase Flow
- [ ] Paket seçimi çalışıyor
- [ ] Parental gate çalışıyor
- [ ] Sandbox satın alma açılıyor
- [ ] Purchase başarılı
- [ ] Premium aktif oluyor
- [ ] Success mesajı görünüyor

### Restore
- [ ] Restore butonu görünüyor
- [ ] Restore çalışıyor
- [ ] Premium geri geliyor
- [ ] Success mesajı görünüyor

## 🎉 Başarı Kriterleri

Tüm bunları görüyorsanız başarılısınız:

✅ Build başarılı
✅ RevenueCat initialize oluyor
✅ Offerings yükleniyor
✅ Paywall çalışıyor
✅ Sandbox purchase çalışıyor
✅ Premium aktif oluyor
✅ Restore çalışıyor

## 🚀 Production'a Geçiş

Test başarılı olduktan sonra:

1. **Production API Key Alın**
   - RevenueCat Dashboard > API Keys
   - Production key kopyalayın (appl_ ile başlar)

2. **Secrets.xcconfig Güncelleyin**
   ```bash
   REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY
   ```

3. **App Store Connect'te Products Oluşturun**
   - In-App Purchases
   - Auto-Renewable Subscriptions
   - 3 product oluşturun

4. **Final Test**
   - Production key ile test edin
   - Gerçek cihazda test edin
   - TestFlight'ta test edin

---

**Şimdi:** Xcode'da build edin ve test edin!
**Sonraki:** RevenueCat Dashboard'da setup yapın
**Rehber:** Bu dosya
