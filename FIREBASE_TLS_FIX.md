# Firebase TLS Error Fix

## 🔴 Sorun

```
❌ Error: A TLS error caused the secure connection to fail.
❌ Error Code: -1200
❌ Error Domain: NSURLErrorDomain
```

Firebase Storage'a fotoğraf yüklerken TLS (SSL) bağlantı hatası oluşuyor.

## 🔍 Hata Analizi

### Hata Detayları
- **Error Code**: `-1200` (NSURLErrorSecureConnectionFailed)
- **Error Domain**: `NSURLErrorDomain`
- **Underlying Error**: `_kCFStreamErrorCodeKey=-9816`
- **Sorun**: TLS handshake başarısız oluyor

### Olası Nedenler
1. **Geçici Ağ Sorunu**: İnternet bağlantısı kesintisi
2. **Firebase SSL Sertifika Sorunu**: Geçici Firebase sunucu sorunu
3. **iOS App Transport Security**: Güvenlik ayarları eksik
4. **Zaman Aşımı**: Yavaş bağlantı

## ✅ Uygulanan Çözümler

### 1. Retry Mekanizması Eklendi

**Dosya**: `MagicPaper/Services/FirebaseImageUploader.swift`

```swift
// Retry logic for TLS errors
let maxRetries = 3
var lastError: Error?

for attempt in 1...maxRetries {
    do {
        print("🔄 Upload attempt \(attempt)/\(maxRetries)...")
        
        // Upload logic...
        
        return urlString // Success!
        
    } catch {
        lastError = error
        print("⚠️ Upload attempt \(attempt) failed: \(error.localizedDescription)")
        
        // Check if it's a TLS error
        let nsError = error as NSError
        if nsError.domain == "NSURLErrorDomain" && nsError.code == -1200 {
            print("⚠️ TLS error detected. Retrying...")
            
            // Wait before retry (exponential backoff)
            if attempt < maxRetries {
                let delay = UInt64(attempt * 1_000_000_000) // 1, 2, 3 seconds
                try? await Task.sleep(nanoseconds: delay)
            }
        } else {
            // Not a TLS error, throw immediately
            throw error
        }
    }
}
```

**Özellikler**:
- ✅ 3 deneme hakkı
- ✅ Exponential backoff (1s, 2s, 3s bekleme)
- ✅ Sadece TLS hatalarında retry
- ✅ Diğer hatalar hemen throw edilir

### 2. App Transport Security Ayarları

**Dosya**: `MagicPaper/Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>firebasestorage.googleapis.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

**Özellikler**:
- ✅ Firebase Storage için özel ayarlar
- ✅ TLS 1.2 minimum versiyon
- ✅ Forward Secrecy aktif
- ✅ Subdomain'ler dahil
- ✅ Güvenli bağlantı zorunlu

### 3. Geliştirilmiş Hata Mesajları

```swift
enum FirebaseImageUploadError: Error, LocalizedError {
    case compressionFailed
    case uploadFailed  // ← Yeni eklendi
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image to JPEG format"
        case .uploadFailed:
            return "Failed to upload image to Firebase after multiple attempts"
        }
    }
}
```

## 📊 Beklenen Davranış

### Başarılı Senaryo ✅
```
🔄 Upload attempt 1/3...
📸 Image compressed: 118352 bytes
📤 Uploading to: child_uploads/[UUID].jpg
✅ Upload successful on attempt 1
🔗 Download URL: https://firebasestorage.googleapis.com/...
```

### Retry Senaryosu 🔄
```
🔄 Upload attempt 1/3...
⚠️ Upload attempt 1 failed: A TLS error caused the secure connection to fail.
⚠️ TLS error detected. Retrying...
[1 saniye bekleme]

🔄 Upload attempt 2/3...
✅ Upload successful on attempt 2
🔗 Download URL: https://firebasestorage.googleapis.com/...
```

### Başarısız Senaryo ❌
```
🔄 Upload attempt 1/3...
⚠️ Upload attempt 1 failed: A TLS error caused the secure connection to fail.
⚠️ TLS error detected. Retrying...

🔄 Upload attempt 2/3...
⚠️ Upload attempt 2 failed: A TLS error caused the secure connection to fail.
⚠️ TLS error detected. Retrying...

🔄 Upload attempt 3/3...
⚠️ Upload attempt 3 failed: A TLS error caused the secure connection to fail.
❌ All 3 upload attempts failed
❌ STORY GENERATION FAILED!
```

## 🧪 Test Adımları

### 1. Clean Build
```bash
# Xcode'da:
Product → Clean Build Folder (Shift+Cmd+K)
```

### 2. Yeni Hikaye Oluştur
1. Fotoğraf seç
2. Hikaye oluştur
3. Konsol loglarını izle

### 3. Konsol Loglarını Kontrol Et

**Başarılı Upload**:
```
🔄 Upload attempt 1/3...
✅ Upload successful on attempt 1
```

**Retry ile Başarılı**:
```
🔄 Upload attempt 1/3...
⚠️ TLS error detected. Retrying...
🔄 Upload attempt 2/3...
✅ Upload successful on attempt 2
```

**Başarısız**:
```
❌ All 3 upload attempts failed
```

## 🔧 Ek Çözümler (Eğer Hala Sorun Varsa)

### Çözüm 1: Retry Sayısını Artır

```swift
let maxRetries = 5  // 3'ten 5'e çıkar
```

### Çözüm 2: Bekleme Süresini Artır

```swift
let delay = UInt64(attempt * 2_000_000_000) // 2, 4, 6 saniye
```

### Çözüm 3: Fotoğraf Kalitesini Düşür

```swift
guard let imageData = image.jpegData(compressionQuality: 0.3) else {
    // 0.5'ten 0.3'e düşür (daha küçük dosya)
}
```

### Çözüm 4: İnternet Bağlantısını Kontrol Et

```swift
// Upload öncesi bağlantı kontrolü ekle
import Network

let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    if path.status == .satisfied {
        print("✅ Internet connection available")
    } else {
        print("❌ No internet connection")
    }
}
```

### Çözüm 5: Firebase SDK Güncelle

```bash
# Package.swift veya Podfile'da Firebase SDK versiyonunu güncelle
```

## 📝 Notlar

### TLS Error -1200 Hakkında
- **-1200**: `NSURLErrorSecureConnectionFailed`
- **-9816**: `errSSLCrypto` (SSL/TLS handshake hatası)
- Genellikle geçici bir sorundur
- Retry mekanizması çoğu durumda çözer

### Firebase Storage Hakkında
- Firebase Storage güvenli HTTPS bağlantısı kullanır
- TLS 1.2 veya üzeri gerektirir
- Geçici sunucu sorunları olabilir
- Retry mekanizması önerilir

### App Transport Security Hakkında
- iOS 9+ için zorunlu
- Güvenli bağlantıları zorlar
- Firebase için özel ayarlar gerekebilir
- Info.plist'te yapılandırılır

## 🚀 Sonraki Adımlar

1. **Clean Build yap**
2. **Yeni hikaye oluştur**
3. **Konsol loglarını izle**
4. **Retry mekanizmasının çalıştığını doğrula**
5. **Eğer hala sorun varsa, ek çözümleri dene**

## 📞 Destek

Eğer sorun devam ederse:
1. Konsol loglarını kopyala
2. İnternet bağlantını kontrol et
3. Firebase Console'da Storage kurallarını kontrol et
4. Bana detaylı hata mesajını gönder

---

**Güncelleme**: 26 Ocak 2026  
**Durum**: ✅ Retry mekanizması eklendi  
**Retry Sayısı**: 3 deneme  
**Bekleme Süresi**: 1s, 2s, 3s (exponential backoff)  
**App Transport Security**: ✅ Yapılandırıldı
