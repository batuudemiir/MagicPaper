# 📚 MagicPaper - Yapay Zeka Destekli Çocuk Hikaye Oluşturucu

Yapay zeka kullanarak kişiselleştirilmiş, resimli çocuk hikayeleri oluşturan bir iOS uygulaması. Çocuğunuzun fotoğrafını yükleyin, bir tema seçin ve yapay zekanın çocuğunuzu ana karakter olarak içeren benzersiz bir hikaye oluşturmasını izleyin.

## ✨ Özellikler

- **Kişiselleştirilmiş Hikayeler**: Çocuk kendi macerasının kahramanı olur
- **Yapay Zeka ile Görseller**: Fal.ai (Flux modeli) ile özel resimler
- **Çoklu Temalar**: Fantezi, Uzay, Okyanus, Dinozorlar, Süper Kahramanlar ve daha fazlası
- **Çok Dil Desteği**: Türkçe, İngilizce, İspanyolca, Fransızca, Almanca, İtalyanca
- **Arka Plan İşleme**: Hikayeler arka planda ilerleme takibi ile oluşturulur
- **Yerel Depolama**: Çevrimdışı erişim için resimler yerel olarak kaydedilir
- **Bildirimler**: Hikayeniz hazır olduğunda bildirim alın

## 🏗️ Mimari

### Temel Bileşenler

```
MagicPaper/
├── Models/
│   └── Story.swift                    # Hikaye veri modelleri
├── Services/
│   ├── StoryGenerationManager.swift   # Ana orkestratör
│   ├── AIService.swift                # Gemini API entegrasyonu
│   ├── FalImageService.swift          # Fal.ai görsel üretimi
│   ├── FirebaseImageUploader.swift    # Firebase Storage
│   ├── FileManagerService.swift       # Yerel dosya yönetimi
│   └── LocalNotificationManager.swift # Bildirimler
└── Views/
    ├── HomeView.swift                 # Ana sayfa
    ├── CreateStoryView.swift          # Hikaye oluşturma formu
    ├── LibraryView.swift              # İlerleme ile hikaye kütüphanesi
    ├── StoryViewerView.swift          # Hikaye okuyucu
    └── SettingsView.swift             # Uygulama ayarları
```

## 🔧 Kurulum

### Gereksinimler

- Xcode 15.0+
- iOS 15.6+
- Swift 5.9+

### Gerekli API Anahtarları

1. **Google Gemini API** (hikaye oluşturma için)
   - Anahtar alın: https://makersuite.google.com/app/apikey
   - Model: `gemini-1.5-flash`

2. **Fal.ai API** (görsel oluşturma için)
   - Anahtar alın: https://fal.ai/dashboard
   - Endpoint: `https://queue.fal.run/fal-ai/flux/dev`

3. **Firebase** (görsel depolama için)
   - Proje oluşturun: https://console.firebase.google.com
   - Firebase Storage'ı etkinleştirin
   - `GoogleService-Info.plist` dosyasını indirin

### Kurulum Adımları

1. Depoyu klonlayın
2. `MagicPaper.xcodeproj` dosyasını Xcode'da açın
3. `GoogleService-Info.plist` dosyasını projeye ekleyin
4. İlgili servis dosyalarında API anahtarlarını güncelleyin:
   - `AIService.swift` - Gemini API anahtarı
   - `FalImageService.swift` - Fal.ai API anahtarı
5. Derleyin ve çalıştırın (Cmd+R)

## 🚀 Nasıl Çalışır

### Hikaye Oluşturma İş Akışı

1. **Kullanıcı Girişi**
   - Çocuğun adı, yaşı, cinsiyeti
   - Fotoğraf yükleme
   - Tema seçimi
   - Dil tercihi

2. **Arka Plan İşleme**
   ```
   Durum: .uploading (Yükleniyor)
   ↓ Fotoğrafı Firebase'e yükle
   
   Durum: .writingStory (Hikaye Yazılıyor)
   ↓ Gemini AI ile hikaye oluştur
   
   Durum: .generatingImages (Görseller Oluşturuluyor)
   ↓ Fal.ai ile görseller oluştur (sıralı)
   
   Durum: .completed (Tamamlandı)
   ↓ Bildirim gönder
   ```

3. **İlerleme Takibi**
   - LibraryView'da gerçek zamanlı durum güncellemeleri
   - Görsel oluşturma için ilerleme çubukları
   - Tamamlanana kadar hikayeler kilitli

## 📱 Kullanım

### Hikaye Oluşturma

1. "Oluştur" sekmesine dokunun
2. Çocuğun bilgilerini doldurun
3. Bir fotoğraf yükleyin
4. Bir tema seçin
5. "Hikaye Oluştur" butonuna dokunun
6. "Kütüphane" sekmesinde ilerlemeyi izleyin

### Hikaye Okuma

1. "Kütüphane" sekmesine gidin
2. Hikaye durumunun "Tamamlandı" olmasını bekleyin
3. Hikayeye dokunarak açın
4. Sayfalar arasında gezinmek için kaydırın
5. Tam ekran görünüm için resimlere dokunun

## 🎨 Temalar

- 🧙 **Fantezi**: Büyücüler ve ejderhalarla sihirli maceralar
- 🚀 **Uzay**: Yıldızlar arasında kozmik yolculuklar
- 🌊 **Okyanus**: Su altı keşifleri
- 🦕 **Dinozorlar**: Tarih öncesi maceralar
- 🦸 **Süper Kahramanlar**: Süper güçlerle dünyayı kurtarın
- 🏰 **Peri Masalları**: Klasik hikaye kitabı maceraları
- 🐉 **Ejderhalar**: Ejderhalarla destansı görevler
- 🎪 **Sirk**: Büyük çadırın altında eğlence
- 🌲 **Orman**: Doğa maceraları
- 🏴‍☠️ **Korsanlar**: Açık denizlerde hazine avı

## 🔐 Veri Depolama

### Yerel Depolama (Documents/Stories/)
- Hikaye görselleri (kapak + sayfalar)
- Hikaye ID'sine göre düzenlenmiş
- Çevrimdışı erişilebilir

### UserDefaults
- Sadece hikaye metadata'sı
- Görsel verisi yok (4MB limit sorununu önler)

### Firebase Storage
- Geçici fotoğraf yükleme
- AI üretimi için referans görseller

## 🐛 Sorun Giderme

### Xcode Derleme Sorunları

"Cannot find 'StoryManager' in scope" veya Firebase paket hataları görüyorsanız:

1. Xcode'u kapatın (Cmd+Q)
2. DerivedData'yı temizleyin:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```
3. Xcode'u yeniden açın
4. Product → Clean Build Folder (Cmd+Shift+K)
5. Product → Build (Cmd+B)

### Firebase Paketi Eksik

1. File → Add Package Dependencies...
2. Girin: `https://github.com/firebase/firebase-ios-sdk`
3. Versiyon: 12.8.0
4. Seçin: FirebaseCore, FirebaseStorage
5. Add Package

## 🎯 API Yapılandırması

### Gemini API
```swift
// AIService.swift içinde
private let apiKey = "YOUR_GEMINI_API_KEY"
private let model = "gemini-1.5-flash"
```

### Fal.ai API
```swift
// FalImageService.swift içinde
private let apiKey = "YOUR_FAL_AI_API_KEY"
private let endpoint = "https://queue.fal.run/fal-ai/flux/dev"
```

### Firebase
- Bundle ID: `com.magicpaper.kids`
- Storage Bucket: `gs://your-project.firebasestorage.app`

## 📄 Lisans

Bu proje eğitim amaçlıdır.

## 🙏 Teşekkürler

- **Google Gemini** - Hikaye oluşturma
- **Fal.ai** - Görsel oluşturma (Flux modeli)
- **Firebase** - Bulut depolama
- **SwiftUI** - UI framework

---

**Sihirli hikaye anlatımı için ❤️ ile yapıldı**
