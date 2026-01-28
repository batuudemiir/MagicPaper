# Test Talimatları - Resim Görüntüleme Sorunu

## Durum
Ekran görüntüsünde hikaye açık ama resimler görünmüyor. Bu eski bir hikaye olabilir.

## Test Adımları

### Test 1: Debug View ile Veriyi Kontrol Et

1. Uygulamayı çalıştır
2. **Ayarlar** sekmesine git (en sağdaki tab)
3. **"🔧 Debug Story Data"** butonuna bas
4. Hikayeni seç
5. **"Print Full Story Data"** butonuna bas
6. Konsol çıktısını kontrol et ve buraya yapıştır

**Aradığımız:**
```
Page 1:
  imageFileName: nil veya "xxx.jpg"
  imageUrl: nil veya "https://v3b.fal.media/..."
  File exists: true/false
```

### Test 2: Yeni Hikaye Oluştur

1. **Ana Sayfa** → **"Yeni Hikaye Oluştur"**
2. Çocuk fotoğrafı seç
3. İsim, yaş, cinsiyet gir
4. Tema seç (örn: Orman Macerası)
5. **"Hikaye Oluştur"** butonuna bas
6. Kütüphaneye git ve hikayenin durumunu izle
7. Hikaye tamamlandığında aç
8. Resimlerin görünüp görünmediğini kontrol et

**Konsol loglarını takip et:**
```
🚀 Fal.ai İsteği Başlatılıyor...
✅ İstek Sıraya Alındı. ID: xxx
📡 Polling attempt 1/180 - HTTP Status: 200
🔄 Durum (1/180): IN_QUEUE
...
🔄 Durum (X/180): COMPLETED
🎉 GÖRSEL HAZIR: https://v3b.fal.media/...
✅ Image URL: https://v3b.fal.media/...
💾 Image URL saved to story page X
⬇️ Downloading image data from: ...
✅ Image data downloaded: XXXXX bytes
✅ Image saved to file: xxx.jpg
```

### Test 3: Fal.ai Test View

1. **Ana Sayfa** → **"Fal.ai Test"** (eğer varsa)
2. Bir fotoğraf seç
3. Prompt gir: "A child playing in a magical forest"
4. **"Generate Image"** butonuna bas
5. 30-120 saniye bekle
6. Resmin görünüp görünmediğini kontrol et

## Beklenen Sonuçlar

### Eski Hikaye (Mevcut)
- ❌ imageUrl: nil
- ❌ imageFileName: nil veya dosya yok
- ❌ Resimler görünmüyor
- **Çözüm**: Hikayeyi sil ve yeni oluştur

### Yeni Hikaye (Test 2)
- ✅ imageUrl: https://v3b.fal.media/...
- ✅ imageFileName: xxx.jpg
- ✅ File exists: true
- ✅ Resimler görünüyor

## Sorun Giderme

### Sorun: Yeni hikayede de resimler görünmüyor

**Kontrol 1: Konsol logları**
```
🎉 GÖRSEL HAZIR: https://...
```
Bu log görünüyor mu? 
- ✅ Evet → Fal.ai çalışıyor, download sorunu var
- ❌ Hayır → Fal.ai timeout oluyor

**Kontrol 2: Timeout hatası**
```
❌ FAILED to generate illustration for page X
❌ Error Domain=NSURLErrorDomain Code=-1001
```
Bu hata görünüyor mu?
- ✅ Evet → Polling timeout oluyor, Fal.ai yavaş
- ❌ Hayır → Başka bir hata var

**Kontrol 3: Download hatası**
```
⬇️ Downloading image data from: ...
❌ Download failed: ...
```
Bu log görünüyor mu?
- ✅ Evet → Download başarısız ama URL var, AsyncImage göstermeli
- ❌ Hayır → Download kodu hiç çalışmıyor

### Sorun: Timeout alıyorum ama Fal.ai dashboard'da resim var

**Çözüm**: Fal.ai API response formatı değişmiş olabilir.

1. Konsol loglarında şunu ara:
```
📄 Raw Response (attempt X):
```

2. Bu response'u buraya yapıştır

3. Response formatına göre `parseCompletionResponse` fonksiyonunu güncelleyelim

## Hızlı Çözüm

Eğer test yapmak istemiyorsan:

1. **Eski hikayeyi sil**:
   - Kütüphane → Hikayeyi sola kaydır → Sil

2. **Yeni hikaye oluştur**:
   - Ana Sayfa → Yeni Hikaye Oluştur
   - Aynı fotoğraf ve ayarları kullan
   - Bekle (5-10 dakika)
   - Yeni hikayede resimler görünmeli

## Konsol Loglarını Nasıl Paylaşırım?

1. Xcode'da **View → Debug Area → Show Debug Area** (Cmd+Shift+Y)
2. Konsol çıktısını seç ve kopyala (Cmd+A, Cmd+C)
3. Buraya yapıştır

Ya da:

1. Xcode'da konsol çıktısını sağ tık
2. **"Export Console Output..."**
3. Dosyayı kaydet ve paylaş
