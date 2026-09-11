# 🐛 Debug Build Gerekli

## ❌ Hata

```
Fatal error: Test Store API key used in Release build
```

## 🔍 Neden?

Test key (`test_`) sadece DEBUG build'lerde kullanılabilir. Şu an RELEASE build yapıyorsun.

## ✅ Çözüm: Debug Build Yap

### Xcode'da Scheme Değiştir

**Yöntem 1: Scheme Menüsünden**
```
1. Xcode üst bar > "MagicPaper" (scheme seçici)
2. "Edit Scheme..." tıkla
3. Sol menüden "Run" seç
4. "Build Configuration" > "Debug" seç
5. Close
```

**Yöntem 2: Hızlı Değiştirme**
```
1. Xcode üst bar > "MagicPaper" (scheme seçici)
2. Tıkla ve açılan menüden kontrol et
3. Eğer "Release" yazıyorsa "Debug" seç
```

### Build & Run

```bash
Cmd + Shift + K  # Clean
Cmd + B          # Build
Cmd + R          # Run
```

## 📋 Build Configuration Farkları

### Debug Build ✅
- **Test key kullanılabilir:** `test_`
- **Sandbox satın alma:** Çalışır
- **Log level:** Verbose
- **Kullanım:** Development/Testing
- **Hız:** Daha yavaş (optimizasyon yok)

### Release Build ❌
- **Test key kullanılamaz:** Sadece `appl_`
- **Production satın alma:** Gerçek para
- **Log level:** Minimal
- **Kullanım:** App Store submission
- **Hız:** Optimize edilmiş

## 🎯 Şu An Ne Yapmalısın?

### 1. Debug Build Yap (Önerilen)

Test key ile çalışmak için:

```
Xcode > Edit Scheme > Run > Debug
Cmd + R
```

### 2. VEYA Production Key Al (İleri Seviye)

Eğer Release build yapmak istiyorsan:

1. **RevenueCat Dashboard'a git**
   - https://app.revenuecat.com/
   - Project Settings > API Keys

2. **Production Key Al**
   - iOS bölümünde `appl_` ile başlayan key
   - Kopyala

3. **Secrets.xcconfig Güncelle**
   ```bash
   REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY
   ```

4. **Clean Build**
   ```bash
   Cmd + Shift + K
   Cmd + B
   ```

**⚠️ DİKKAT:** Production key ile sandbox satın alma çalışmaz! Gerçek para gerekir.

## 🧪 Test İçin Önerilen Setup

### Development (Şimdi)
```bash
# Secrets.xcconfig
REVENUECAT_API_KEY = test_ElHyzdqEfyVopUtAWnZlTlOnTmu

# Xcode
Build Configuration: Debug
```

### TestFlight
```bash
# Secrets.xcconfig
REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY

# Xcode
Build Configuration: Release
Archive > Upload to App Store
```

### App Store
```bash
# Secrets.xcconfig
REVENUECAT_API_KEY = appl_YOUR_PRODUCTION_KEY

# Xcode
Build Configuration: Release
Archive > Distribute App
```

## 🔧 Kod Değişiklikleri

MagicPaperApp.swift'e validation eklendi:

```swift
// Test key validation - sadece DEBUG'da kullanılabilir
#if !DEBUG
if apiKey.hasPrefix("test_") {
    print("❌ HATA: Test key Release build'de kullanılamaz!")
    return
}
#endif
```

Bu sayede yanlışlıkla Release build yapsan bile uygulama crash olmaz, sadece RevenueCat çalışmaz.

## ✅ Checklist

**Şimdi (Development):**
- [ ] Xcode Scheme > Debug
- [ ] Test key kullan: `test_ElHyzdqEfyVopUtAWnZlTlOnTmu`
- [ ] Clean build
- [ ] Run
- [ ] Sandbox satın alma test et

**Sonra (Production):**
- [ ] RevenueCat Dashboard'dan production key al
- [ ] Secrets.xcconfig'e ekle
- [ ] Xcode Scheme > Release
- [ ] Archive
- [ ] TestFlight'ta test et
- [ ] App Store'a gönder

## 🚀 Hızlı Başlangıç

```bash
# 1. Xcode'da Debug seç
Xcode > Edit Scheme > Run > Debug

# 2. Clean build
Cmd + Shift + K

# 3. Run
Cmd + R

# 4. Test et
Paywall'ı aç ve test et
```

## 📚 Daha Fazla Bilgi

- **RevenueCat Test Store:** https://rev.cat/sdk-test-store
- **API Keys:** https://docs.revenuecat.com/docs/authentication
- **Sandbox Testing:** https://docs.revenuecat.com/docs/sandbox

---

**Özet:** Debug build yap veya production key al. Test için Debug önerilir!
