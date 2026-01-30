# ⚡ MagicPaper - Hızlı Başlangıç

## 🚀 2 Dakikada Çalıştır

### 1️⃣ Xcode Cloud Environment Variable (ZORUNLU)
```
App Store Connect → Xcode Cloud → Settings → Environment Variables

Name:  GEMINI_API_KEY
Value: AIzaSyDxWbb_OO45kHZQCUPilZtqAN-dYTcEudc
```

### 2️⃣ Dosyaları Xcode'a Ekle
```bash
# Xcode'u aç
open MagicPaper.xcodeproj

# Şu dosyaları ekle (Add Files to MagicPaper):
# ✅ MagicPaper/Services/PermissionManager.swift
# ✅ MagicPaper/Views/OnboardingView.swift  
# ✅ MagicPaper/Views/PremiumView.swift
# ✅ Secrets.xcconfig (target olmadan)
```

### 3️⃣ Test Et
```bash
# Setup kontrolü
./verify_xcode_setup.sh

# Build
⌘ + B

# Run
⌘ + R
```

## 📚 Detaylı Dokümantasyon

| Konu | Dosya |
|------|-------|
| Xcode Cloud Hatası | `XCODE_CLOUD_QUICK_FIX.md` |
| Dosya Ekleme | `MANUAL_XCODE_ADDITIONS.md` |
| Fiyatlandırma | `PRICING_STRATEGY.md` |
| Tam Özet | `CONTEXT_TRANSFER_SUMMARY.md` |

## ✅ Kontrol Listesi

- [ ] Xcode Cloud environment variable tanımlı
- [ ] PermissionManager.swift eklendi
- [ ] OnboardingView.swift eklendi
- [ ] PremiumView.swift eklendi
- [ ] Secrets.xcconfig eklendi
- [ ] Build başarılı (⌘+B)
- [ ] App çalışıyor (⌘+R)

## 🎯 Özellikler

### Onboarding
- 3 sayfa (Fotoğraf, Tema, Sihir)
- İleri/Geri/Atla butonları
- İzin istekleri (ATT + Bildirimler)

### Fiyatlandırma
**Tek Seferlik:**
- Görselli: ₺29
- Metin: ₺9
- 5'li: ₺119
- 10'lu: ₺199

**Abonelik:**
- Aylık: ₺149
- Yıllık: ₺1.199

### UX
- Sabit light theme
- Siyah/gri metinler
- Beyaz arka plan
- Alt tab sabitlendi

## 🆘 Sorun mu Var?

```bash
# Setup kontrolü
./verify_xcode_setup.sh

# Detaylı log
cat XCODE_CLOUD_FIX.md
```

---

**Durum**: ✅ HAZIR
**Yapman Gereken**: 2 manuel adım
**Süre**: 2 dakika
