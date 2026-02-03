# 🔴 Güvenlik Olayı - API Anahtarı Sızıntısı (ÇÖZÜLDÜ)

## Olay Özeti
**Tarih**: 3 Şubat 2026  
**Durum**: ✅ ÇÖZÜLDÜ  
**Etkilenen API**: Google Gemini API  
**Sızdırılan Anahtar**: `***REMOVED***` (DEVREDİŞI)

## Sorun
- Gemini API anahtarı `MagicPaper/Secrets.xcconfig` dosyasında hardcoded edilmişti
- Dosya yanlışlıkla Git'e commit edilmişti
- Google tarafından tespit edilip devre dışı bırakıldı
- Hata mesajı: `"Your API key was reported as leaked. Please use another API key."`

## Alınan Aksiyonlar

### 1. ✅ Sızdırılmış Anahtarı Temizleme
- [x] `MagicPaper/Secrets.xcconfig` dosyasından anahtar kaldırıldı
- [x] Placeholder değer eklendi: `YOUR_NEW_API_KEY_HERE`
- [x] Değişiklikler commit edildi

### 2. ✅ .gitignore Kontrolü
- [x] `Secrets.xcconfig` zaten `.gitignore`'da
- [x] `MagicPaper/Info.plist` zaten `.gitignore`'da
- [x] `GoogleService-Info.plist` zaten `.gitignore`'da

### 3. ⏳ Yeni API Anahtarı Alma
**Yapılması Gereken:**
1. Google AI Studio'ya git: https://aistudio.google.com/app/apikey
2. Yeni API anahtarı oluştur
3. `MagicPaper/Secrets.xcconfig` dosyasını güncelle:
   ```
   GEMINI_API_KEY = YOUR_NEW_API_KEY
   ```
4. Dosyayı **ASLA** Git'e commit etme!

### 4. ⏳ Git Geçmişini Temizleme (Opsiyonel ama Önerilen)

**Seçenek A: BFG Repo-Cleaner (Önerilen)**
```bash
# BFG'yi yükle
brew install bfg

# Sızdırılmış anahtarı içeren dosyaları temizle
bfg --delete-files Secrets.xcconfig
bfg --replace-text <(echo 'LEAKED_API_KEY==>***REMOVED***')

# Değişiklikleri uygula
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (DİKKAT: Tehlikeli!)
git push origin --force --all
```

**Seçenek B: Yeni Repo Oluştur (En Güvenli)**
```bash
# Mevcut repo'yu yedekle
cp -r . ../MagicPaper-backup

# Yeni temiz repo oluştur
cd ..
mkdir MagicPaper-clean
cd MagicPaper-clean
git init

# Sadece güncel dosyaları kopyala
cp -r ../MagicPaper/* .

# Secrets.xcconfig'i temizle
echo "GEMINI_API_KEY = YOUR_NEW_API_KEY_HERE" > MagicPaper/Secrets.xcconfig

# Yeni repo'yu push et
git add .
git commit -m "Initial commit - clean history"
git remote add origin <your-repo-url>
git push -u origin main --force
```

## Güvenlik İyileştirmeleri

### ✅ Zaten Yapılmış
1. **Secrets.xcconfig Pattern**
   - API anahtarları xcconfig dosyasında
   - .gitignore'da listelenmiş
   - Template dosyası mevcut

2. **Environment Variable Fallback**
   - AIService.swift önce environment variable'ı kontrol ediyor
   - Xcode Cloud için hazır

3. **CI/CD Güvenliği**
   - `ci_post_clone.sh` environment variable'dan anahtar alıyor
   - Secrets.xcconfig otomatik oluşturuluyor

### 📋 Yapılması Gerekenler

1. **GitHub Secrets Kullan**
   ```
   GitHub Repo → Settings → Secrets and variables → Actions
   
   Yeni secret ekle:
   Name: GEMINI_API_KEY
   Value: [Yeni API anahtarınız]
   ```

2. **Xcode Cloud Environment Variables**
   ```
   App Store Connect → Xcode Cloud → Settings → Environment Variables
   
   Name: GEMINI_API_KEY
   Value: [Yeni API anahtarınız]
   ```

3. **Pre-commit Hook Ekle**
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   
   # API anahtarı kontrolü
   if git diff --cached | grep -E "AIzaSy[A-Za-z0-9_-]{33}"; then
       echo "❌ HATA: API anahtarı tespit edildi!"
       echo "Lütfen API anahtarını kaldırın ve Secrets.xcconfig kullanın."
       exit 1
   fi
   
   # Secrets.xcconfig kontrolü
   if git diff --cached --name-only | grep -q "Secrets.xcconfig"; then
       echo "❌ HATA: Secrets.xcconfig commit edilmeye çalışılıyor!"
       echo "Bu dosya .gitignore'da olmalı."
       exit 1
   fi
   
   exit 0
   ```

4. **Git Guardian veya TruffleHog Kullan**
   - Otomatik secret tarama
   - CI/CD pipeline'a entegre et

## Test Checklist

- [ ] Yeni API anahtarı alındı
- [ ] `MagicPaper/Secrets.xcconfig` güncellendi
- [ ] Uygulama build ediliyor
- [ ] Hikaye oluşturma çalışıyor
- [ ] API çağrıları başarılı
- [ ] Git geçmişi temizlendi (opsiyonel)
- [ ] GitHub'a push edildi
- [ ] Xcode Cloud environment variable eklendi

## Öğrenilen Dersler

1. **ASLA** API anahtarlarını kod içine yazmayın
2. **DAIMA** .gitignore kullanın
3. **MUTLAKA** pre-commit hook'ları ekleyin
4. **DÜZENLI** olarak secret tarama yapın
5. **ACİL** durumlarda anahtarları rotate edin

## İletişim

Sorular için: batuudemiir@gmail.com

---

**Son Güncelleme**: 3 Şubat 2026  
**Durum**: Sızdırılmış anahtar temizlendi, yeni anahtar bekleniyor
