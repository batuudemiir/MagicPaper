# 📄 Politika Dosyaları - Yayınlama Rehberi

## 📋 Mevcut Dosyalar

✅ **privacy_policy.html** - Gizlilik Politikası (Türkçe) - Tam içerik
✅ **privacy.html** - Gizlilik Politikası Yönlendirme → https://www.magicpaperkids.com/gizlilik
✅ **terms_of_service.html** - Kullanım Şartları (Türkçe)
✅ **accessibility.html** - Erişilebilirlik Yönlendirme → https://www.magicpaperkids.com/erisilebilirlik

Her dosya:
- Modern ve responsive tasarım
- MagicPaper branding (mor-pembe gradient)
- Mobil uyumlu
- KVKK uyumlu içerik
- Otomatik yönlendirme (yönlendirme dosyaları için)

---

## 🌐 Yayınlama Seçenekleri

### Seçenek 1: GitHub Pages (ÜCRETSİZ - ÖNERİLEN)

#### Adım 1: GitHub Repository Ayarları
1. GitHub'da repository'nize gidin
2. Settings → Pages
3. Source: Deploy from a branch
4. Branch: main
5. Folder: / (root)
6. Save

#### Adım 2: Dosyaları Yayınlayın
```bash
# Dosyalar zaten root'ta, otomatik yayınlanacak
# URL'ler:
https://batuudemiir.github.io/MagicPaper/privacy_policy.html
https://batuudemiir.github.io/MagicPaper/terms_of_service.html
```

#### Adım 3: Test Edin
- 5-10 dakika bekleyin
- URL'leri tarayıcıda açın
- Mobil görünümü test edin

---

### Seçenek 2: Firebase Hosting (ÜCRETSİZ)

#### Adım 1: Firebase CLI Kurulumu
```bash
npm install -g firebase-tools
firebase login
```

#### Adım 2: Firebase Projesi Başlatın
```bash
firebase init hosting

# Seçenekler:
# - Use existing project: magicpaper-393a7
# - Public directory: .
# - Single-page app: No
# - GitHub auto-deploy: No
```

#### Adım 3: Deploy Edin
```bash
firebase deploy --only hosting

# URL'ler:
https://magicpaper-393a7.web.app/privacy_policy.html
https://magicpaper-393a7.web.app/terms_of_service.html
```

---

### Seçenek 3: Netlify (ÜCRETSİZ)

#### Adım 1: Netlify'a Giriş
1. https://www.netlify.com/ → Sign up
2. GitHub ile giriş yapın

#### Adım 2: Site Oluşturun
1. "Add new site" → "Import an existing project"
2. GitHub repository'nizi seçin
3. Build settings:
   - Build command: (boş bırakın)
   - Publish directory: /
4. Deploy

#### Adım 3: URL'leri Alın
```
https://magicpaper.netlify.app/privacy_policy.html
https://magicpaper.netlify.app/terms_of_service.html
```

---

### Seçenek 4: Vercel (ÜCRETSİZ)

#### Adım 1: Vercel'e Giriş
1. https://vercel.com/ → Sign up
2. GitHub ile giriş yapın

#### Adım 2: Proje İmport Edin
1. "Add New" → "Project"
2. GitHub repository'nizi seçin
3. Deploy

#### Adım 3: URL'leri Alın
```
https://magicpaper.vercel.app/privacy_policy.html
https://magicpaper.vercel.app/terms_of_service.html
```

---

## 🎯 ÖNERİLEN: GitHub Pages

**Neden?**
- ✅ Tamamen ücretsiz
- ✅ GitHub'da zaten var
- ✅ Otomatik güncelleme
- ✅ SSL sertifikası dahil
- ✅ Hızlı ve güvenilir

**Kurulum:**
```bash
# 1. GitHub Settings → Pages → Enable
# 2. 5 dakika bekle
# 3. Test et:
https://batuudemiir.github.io/MagicPaper/privacy_policy.html
https://batuudemiir.github.io/MagicPaper/terms_of_service.html
```

---

## 📱 App Store Connect'e Ekleme

### Adım 1: URL'leri Hazırlayın

**Gizlilik Politikası URL:**
```
https://batuudemiir.github.io/MagicPaper/privacy_policy.html
```

**Kullanım Şartları URL:**
```
https://batuudemiir.github.io/MagicPaper/terms_of_service.html
```

### Adım 2: App Store Connect

1. **App Information:**
   - Privacy Policy URL: [Gizlilik URL'si]

2. **Version Information:**
   - Terms of Service URL: [Kullanım Şartları URL'si]

3. **In-App Purchase:**
   - Her abonelik için aynı URL'leri kullanın

---

## 🔄 Güncelleme Süreci

### Politikaları Güncellemek İçin:

1. **Dosyaları Düzenleyin:**
   ```bash
   # privacy_policy.html veya terms_of_service.html
   ```

2. **Tarihi Güncelleyin:**
   ```html
   <p class="last-updated">Son Güncelleme: [YENİ TARİH]</p>
   ```

3. **GitHub'a Push Edin:**
   ```bash
   git add privacy_policy.html terms_of_service.html
   git commit -m "📄 Politikalar güncellendi"
   git push origin main
   ```

4. **Otomatik Yayınlanır:**
   - GitHub Pages: 2-5 dakika
   - Firebase/Netlify/Vercel: 1-2 dakika

---

## ✅ Test Kontrol Listesi

### Gizlilik Politikası:
- [ ] URL açılıyor
- [ ] Mobil görünüm düzgün
- [ ] Tüm bölümler okunabilir
- [ ] İletişim bilgileri doğru
- [ ] Tarih güncel

### Kullanım Şartları:
- [ ] URL açılıyor
- [ ] Mobil görünüm düzgün
- [ ] Tüm bölümler okunabilir
- [ ] Abonelik bilgileri doğru
- [ ] Tarih güncel

### App Store Connect:
- [ ] Privacy URL eklendi
- [ ] Terms URL eklendi
- [ ] URL'ler test edildi
- [ ] Mobil Safari'de test edildi

---

## 🎨 Özelleştirme

### Renkleri Değiştirmek:
```css
/* privacy_policy.html ve terms_of_service.html içinde */
background: linear-gradient(135deg, #9449FA 0%, #D959D9 50%, #FF738C 100%);
```

### Logo Değiştirmek:
```html
<div class="logo">📚</div>
```

### İletişim Bilgileri:
```html
<p>E-posta: support@magicpaper.app</p>
<p>Web: www.magicpaper.app</p>
```

---

## 🆘 Sorun Giderme

### GitHub Pages Çalışmıyor:
1. Settings → Pages → Source kontrol edin
2. Repository public olmalı
3. 10 dakika bekleyin
4. Cache temizleyin (Ctrl+Shift+R)

### URL 404 Veriyor:
1. Dosya adını kontrol edin (küçük harf)
2. Branch'i kontrol edin (main)
3. Commit'lendiğinden emin olun

### Mobil Görünüm Bozuk:
1. Viewport meta tag'i var mı kontrol edin
2. Responsive CSS'i kontrol edin
3. Farklı cihazlarda test edin

---

## 📞 Destek

**Sorularınız için:**
- GitHub Issues: https://github.com/batuudemiir/MagicPaper/issues
- Email: support@magicpaper.app

---

## 🎯 Hızlı Başlangıç

```bash
# 1. GitHub Pages'i Aktifleştir
# GitHub → Settings → Pages → Enable

# 2. 5 Dakika Bekle

# 3. Test Et
open https://batuudemiir.github.io/MagicPaper/privacy_policy.html
open https://batuudemiir.github.io/MagicPaper/terms_of_service.html

# 4. App Store Connect'e Ekle
# Privacy URL: https://batuudemiir.github.io/MagicPaper/privacy_policy.html
# Terms URL: https://batuudemiir.github.io/MagicPaper/terms_of_service.html
```

---

**Durum:** ✅ Politika Dosyaları Hazır
**Önerilen:** GitHub Pages
**Süre:** 5 dakika
**Maliyet:** Ücretsiz
