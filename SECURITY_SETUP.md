# 🔒 Güvenlik ve API Anahtarı Kurulumu

## ⚠️ ÖNEMLİ: API Anahtarlarını GitHub'a Göndermeyin!

Bu proje API anahtarlarını güvenli bir şekilde saklamak için `.gitignore` kullanır.

## 📋 Kurulum Adımları

### 1. Gemini API Anahtarı

1. [Google AI Studio](https://aistudio.google.com/app/apikey) adresine gidin
2. Yeni bir API anahtarı oluşturun
3. `Secrets.xcconfig` dosyasını açın
4. `YOUR_NEW_API_KEY_HERE` yerine yeni anahtarınızı yazın:

```
GEMINI_API_KEY = AIzaSy...YourActualKey
```

### 2. Firebase Kurulumu

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin veya yeni proje oluşturun
3. iOS uygulaması ekleyin (Bundle ID: `com.magicpaper.kids`)
4. `GoogleService-Info.plist` dosyasını indirin
5. `MagicPaper/` klasörüne kopyalayın

**Alternatif:** Template dosyasını kullanın:
```bash
cp MagicPaper/GoogleService-Info.plist.template MagicPaper/GoogleService-Info.plist
# Sonra dosyayı düzenleyip kendi değerlerinizi girin
```

### 3. Xcode Cloud (CI/CD için)

Xcode Cloud kullanıyorsanız:

1. App Store Connect → Xcode Cloud → Settings → Environment Variables
2. Yeni environment variable ekleyin:
   - Name: `GEMINI_API_KEY`
   - Value: [Yeni API anahtarınız]

## 🛡️ Güvenlik Kontrol Listesi

- [ ] `Secrets.xcconfig` dosyası `.gitignore`'da
- [ ] `GoogleService-Info.plist` dosyası `.gitignore`'da
- [ ] `project.pbxproj` içinde hardcoded API anahtarı yok
- [ ] Hiçbir `.md` dosyasında gerçek API anahtarı yok
- [ ] Git history'de API anahtarı varsa temizlendi

## 🔍 API Anahtarı Kontrolü

Projenizde hardcoded API anahtarı olup olmadığını kontrol edin:

```bash
# Tüm dosyalarda API anahtarı ara
grep -r "AIzaSy" . --exclude-dir=.git --exclude-dir=DerivedData

# Sonuç boş olmalı!
```

## 🚨 API Anahtarı Sızdıysa Ne Yapmalı?

1. **Hemen iptal edin:**
   - [Google AI Studio](https://aistudio.google.com/app/apikey) → Eski anahtarı sil

2. **Yeni anahtar oluşturun:**
   - Yeni API anahtarı oluştur
   - `Secrets.xcconfig` dosyasını güncelle

3. **Git history'yi temizleyin:**
   ```bash
   # BFG Repo-Cleaner kullanın
   # https://rtyley.github.io/bfg-repo-cleaner/
   ```

4. **GitHub'a bildirin:**
   - Eğer public repo ise, GitHub otomatik tespit edebilir
   - Secret scanning alerts'i kontrol edin

## 📚 Daha Fazla Bilgi

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [iOS Security Best Practices](https://developer.apple.com/documentation/security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

---

**Son Güncelleme:** 2025-01-30
**Durum:** ✅ Güvenli Kurulum Hazır
