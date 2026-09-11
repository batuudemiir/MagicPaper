# ✅ RevenueCat: Production Key ZORUNLU

## 🎯 Kesin Cevap

**App Store Connect'e (TestFlight dahil) gönderirken:**

```
❌ Test Key (test_) KULLANMA
✅ Production Key (appl_) KULLAN
```

## 📚 RevenueCat Resmi Dokümantasyonu

> **"You MUST replace your Test Store API key with the correct platform-specific API key (iOS, Android, etc.) before submitting your app for review."**
> 
> **"Never submit an app configured with a Test Store API key to app review"**
> 
> **"Using a Test Store API key in production will crash your app."**

Kaynak: [RevenueCat Launch Checklist](https://docs.revenuecat.com/docs/launch-checklist)

## 🔍 Neden?

### Test Key (test_)
- **Kullanım:** Sadece local development
- **Xcode'dan direkt run:** ✅
- **TestFlight:** ❌ CRASH
- **App Store:** ❌ CRASH
- **Apple Review:** ❌ RED

### Production Key (appl_)
- **Kullanım:** Her yerde
- **Xcode'dan direkt run:** ✅
- **TestFlight:** ✅
- **App Store:** ✅
- **Apple Review:** ✅

## 🧪 Test Ortamları

### 1. Local Development (Xcode)
```
API Key: test_ veya appl_ (ikisi de çalışır)
Build: Debug
Satın Alma: Sandbox
```

### 2. TestFlight
```
API Key: appl_ (ZORUNLU!)
Build: Release
Satın Alma: Sandbox (Apple otomatik)
```

### 3. App Store
```
API Key: appl_ (ZORUNLU!)
Build: Release
Satın Alma: Production (gerçek para)
```

## 💡 Önemli: Apple Otomatik Sandbox

**Güzel haber:** Apple, TestFlight ve Review sırasında otomatik olarak sandbox kullanır!

```
Production Key (appl_) kullansan bile:
- TestFlight → Sandbox satın alma (ücretsiz)
- Apple Review → Sandbox satın alma (ücretsiz)
- App Store → Production satın alma (gerçek para)
```

RevenueCat bunu otomatik algılar, sen bir şey yapman gerekmiyor!

## 📋 Doğru Workflow

### 1. Development (Şimdi)
```
Secrets.xcconfig:
REVENUECAT_API_KEY = test_ElHyzdqEfyVopUtAWnZlTlOnTmu

Xcode: Debug build
Test: Sandbox account
```

### 2. TestFlight'a Gönderme (Sonra)
```
Secrets.xcconfig:
REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY

Xcode: Release build
Archive > Upload
TestFlight: Sandbox otomatik
```

### 3. App Store (En Son)
```
Aynı production key
Apple Review: Sandbox otomatik
Yayınlandıktan sonra: Production otomatik
```

## ✅ Adım Adım

### 1. Production Key Al

```
RevenueCat Dashboard:
1. Project Settings (⚙️)
2. API Keys tab
3. iOS bölümü
4. Production key kopyala (appl_ ile başlar)
```

### 2. Secrets.xcconfig Güncelle

**Her iki dosyayı da:**
- `Secrets.xcconfig`
- `MagicPaper/Secrets.xcconfig`

```bash
# Değiştir
REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY
```

### 3. Clean Build

```bash
Xcode:
Cmd + Shift + K
Cmd + Shift + Option + K
```

### 4. Release Build Test

```bash
Xcode > Edit Scheme > Run > Release
Cmd + B

Console'da:
✅ RevenueCat yapılandırıldı: appl_...
```

### 5. Archive

```bash
Product > Archive
```

### 6. Upload

```bash
Distribute App > App Store Connect
```

## 🧪 TestFlight'ta Test

Production key ile TestFlight'a yükledikten sonra:

```
1. TestFlight app'i indir
2. Uygulamayı aç
3. Paywall'ı aç
4. Satın al

→ Sandbox otomatik kullanılır
→ Gerçek para ÇEKİLMEZ
→ Test edebilirsin
```

## ⚠️ Kritik Uyarı

```
❌ Test key ile Archive yaparsan:
→ Build başarısız
→ "Test key in Release build" hatası

❌ Test key ile TestFlight'a yüklersen:
→ Uygulama crash olur
→ RevenueCat çalışmaz

❌ Test key ile Apple Review'a gönderirsen:
→ Instant rejection
→ "App crashes" nedeniyle red
```

## 📊 Özet Tablo

| Ortam | API Key | Build | Satın Alma |
|-------|---------|-------|------------|
| Xcode (Dev) | test_ ✅ | Debug | Sandbox |
| Xcode (Dev) | appl_ ✅ | Debug | Sandbox |
| TestFlight | test_ ❌ | Release | CRASH |
| TestFlight | appl_ ✅ | Release | Sandbox (otomatik) |
| Apple Review | test_ ❌ | Release | CRASH |
| Apple Review | appl_ ✅ | Release | Sandbox (otomatik) |
| App Store | appl_ ✅ | Release | Production |

## 🎯 Sonuç

**Kesin cevap:**

1. ✅ Production key'e geç (appl_)
2. ✅ Clean build
3. ✅ Archive
4. ✅ TestFlight'a yükle
5. ✅ Test et (sandbox otomatik)
6. ✅ Apple Review'a gönder

**Test key ile gönderme!** Uygulama crash olur.

---

**Kaynak:** [RevenueCat Official Documentation](https://docs.revenuecat.com/docs/launch-checklist)

**Şimdi:** Production key'e geç ve Archive yap! 🚀
