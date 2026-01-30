# MagicPaper - Kurulum Talimatları

## API Anahtarı Yapılandırması

Bu proje Gemini API kullanır. API anahtarınızı güvenli bir şekilde yapılandırmak için:

### 1. Secrets.xcconfig Dosyası Oluşturun

Proje kök dizininde `Secrets.xcconfig` dosyası oluşturun:

```bash
cp Secrets.xcconfig.template Secrets.xcconfig
```

### 2. API Anahtarınızı Ekleyin

`Secrets.xcconfig` dosyasını açın ve API anahtarınızı ekleyin:

```
GEMINI_API_KEY = YOUR_ACTUAL_API_KEY_HERE
```

### 3. Xcode'da Yapılandırın

1. Xcode'da projeyi açın
2. Project Navigator'da projeyi seçin (en üstteki mavi ikon)
3. "Info" sekmesine gidin
4. "Configurations" bölümünde:
   - Debug için: Secrets.xcconfig dosyasını seçin
   - Release için: Secrets.xcconfig dosyasını seçin

**Alternatif Yöntem:**
1. Project Navigator'da projeyi seçin
2. Target'ı seçin (MagicPaper)
3. "Build Settings" sekmesine gidin
4. "+" butonuna tıklayın → "Add User-Defined Setting"
5. İsim: `GEMINI_API_KEY`
6. Değer: API anahtarınız

### 4. Gemini API Anahtarı Nasıl Alınır?

1. https://aistudio.google.com/app/apikey adresine gidin
2. Google hesabınızla giriş yapın
3. "Create API Key" butonuna tıklayın
4. Anahtarı kopyalayın ve `Secrets.xcconfig` dosyasına yapıştırın

### 5. Güvenlik Notları

⚠️ **ÖNEMLİ:**
- `Secrets.xcconfig` dosyası `.gitignore`'a eklenmiştir
- Bu dosyayı asla Git'e commit etmeyin
- API anahtarınızı kimseyle paylaşmayın
- Eğer anahtarınız sızdıysa, hemen yeni bir tane oluşturun

### 6. Sorun Giderme

**"GEMINI_API_KEY bulunamadı" hatası alıyorsanız:**

1. `Secrets.xcconfig` dosyasının proje kök dizininde olduğundan emin olun
2. Xcode'u kapatıp tekrar açın
3. Product → Clean Build Folder
4. Projeyi yeniden build edin

**API çağrıları 403 hatası veriyorsa:**

- API anahtarınızın geçerli olduğundan emin olun
- Google AI Studio'da anahtarın aktif olduğunu kontrol edin
- Gerekirse yeni bir anahtar oluşturun

## Firebase Yapılandırması

1. `GoogleService-Info.plist` dosyasını Firebase Console'dan indirin
2. Dosyayı `MagicPaper/` klasörüne ekleyin
3. Xcode'da projeye ekleyin (Copy items if needed seçili olmalı)

## Çalıştırma

```bash
# Projeyi açın
open MagicPaper.xcodeproj

# Veya Xcode'dan:
# File → Open → MagicPaper.xcodeproj
```

Simulator veya gerçek cihazda çalıştırın.
