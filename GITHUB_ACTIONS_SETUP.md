# GitHub Actions iOS Build Setup

Xcode Cloud bağlantı sorunu nedeniyle GitHub Actions ile otomatik build sistemi kuruldu.

## Kurulum Tamamlandı ✅

### 1. Workflow Dosyaları
- `.github/workflows/ios-build.yml` - Ana build ve deploy workflow
- `.github/workflows/test-build.yml` - Hızlı test build'i
- `ExportOptions.plist` - App Store export ayarları

### 2. Otomatik Tetiklenme
- **Ana Build**: `main` veya `master` branch'e push
- **Test Build**: Feature branch'lere push veya PR açma
- **Manuel**: GitHub'da Actions sekmesinden manuel çalıştırma

### 3. Build Özellikleri
- ✅ Swift Package Manager cache
- ✅ Simulator build (test için)
- ✅ Archive build (release için)
- ✅ Build artifact'ları saklama (30 gün)
- ⏳ App Store Connect upload (kurulum gerekli)

## App Store Connect Entegrasyonu (Opsiyonel)

### Gerekli Secrets (GitHub Repository Settings > Secrets):
```
APPLE_ID: Apple ID email adresin
APP_SPECIFIC_PASSWORD: App-specific password
```

### App-Specific Password Oluşturma:
1. https://appleid.apple.com > Sign-In and Security
2. App-Specific Passwords > Generate Password
3. "GitHub Actions" adıyla oluştur

### Secrets Ekleme:
1. GitHub repository > Settings > Secrets and variables > Actions
2. New repository secret ile ekle

## Kullanım

### Manuel Build Çalıştırma:
1. GitHub repository > Actions sekmesi
2. "iOS Build and Deploy" workflow'u seç
3. "Run workflow" butonuna tıkla

### Build Durumunu İzleme:
- Actions sekmesinde tüm build'ları görebilirsin
- Her commit için otomatik build çalışır
- Build başarısız olursa email bildirim gelir

### Build Artifact'larını İndirme:
1. Başarılı build'a tıkla
2. "Artifacts" bölümünden "MagicPaper-Archive" indir
3. Bu dosyayı Xcode'da açıp App Store'a manuel yükleyebilirsin

## Avantajlar
- ✅ Xcode Cloud'a ihtiyaç yok
- ✅ Ücretsiz (GitHub Actions 2000 dakika/ay)
- ✅ Tam kontrol
- ✅ Özelleştirilebilir
- ✅ Tüm branch'ler için ayrı ayarlar

## Sonraki Adımlar
1. Repository'yi GitHub'a push et
2. Actions sekmesinde build'ları izle
3. İsteğe bağlı: App Store Connect entegrasyonu kur

Artık her kod değişikliğinde otomatik build çalışacak!