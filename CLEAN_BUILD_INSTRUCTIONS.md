# Clean Build Talimatları

## Sorun
Xcode eski derlenmiş kodu kullanıyor. Yeni yaptığımız değişiklikler uygulanmıyor.

## Kanıt
Konsol çıktısında eski loglar görünüyor:
```
⚠️ Polling sırasında hata: 405
🔄 Sonuç bekleniyor (Polling)...
```

Ama yeni kod şöyle olmalı:
```
📡 Polling attempt 1/180 - HTTP Status: 405
🔍 Trying alternative endpoint...
```

## Çözüm

### Yöntem 1: Clean Build Folder (Hızlı)
1. Xcode'da **Product → Clean Build Folder** (Shift+Cmd+K)
2. Uygulamayı durdur (Cmd+.)
3. Simulatörü kapat
4. Yeniden çalıştır (Cmd+R)

### Yöntem 2: Derived Data Temizle (Kapsamlı)
1. Xcode'da **Window → Organizer** (Shift+Cmd+2)
2. **Projects** sekmesine git
3. **MagicPaper** projesini seç
4. **Delete Derived Data** butonuna bas
5. Xcode'u kapat
6. Xcode'u yeniden aç
7. Projeyi aç
8. Yeniden derle (Cmd+B)
9. Çalıştır (Cmd+R)

### Yöntem 3: Manuel Temizlik (En Kapsamlı)
Terminal'de şu komutları çalıştır:

```bash
# Derived Data'yı temizle
rm -rf ~/Library/Developer/Xcode/DerivedData/MagicPaper-*

# Build klasörünü temizle
cd ~/Desktop/MagicPaper
rm -rf build/

# Xcode cache'i temizle
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

Sonra Xcode'u aç ve yeniden derle.

## Test

Clean build'den sonra yeni bir hikaye oluştur ve konsol çıktısını kontrol et:

**Beklenen çıktı:**
```
🚀 Fal.ai İsteği Başlatılıyor...
✅ İstek Sıraya Alındı. ID: xxx
📡 Status URL: https://queue.fal.run/fal-ai/flux/dev/requests/xxx/status
📡 Polling attempt 1/180 - HTTP Status: 200
📄 Raw Response (attempt 1):
{"status":"IN_QUEUE",...}
🔄 Durum (1/180): IN_QUEUE
...
🔄 Durum (X/180): COMPLETED
🎉 GÖRSEL HAZIR (Format 1): https://v3b.fal.media/...
✅ Image URL: https://v3b.fal.media/...
💾 Image URL saved to story page 1
⬇️ Downloading image data from: ...
✅ Image data downloaded: XXXXX bytes
✅ Image saved to file: xxx.jpg
```

**Eğer hala 405 hatası alıyorsan:**
- Yeni kod uygulanmamış demektir
- Derived Data'yı manuel temizle (Yöntem 3)
- Simulatörü sıfırla: Device → Erase All Content and Settings

## Neden Bu Oluyor?

Xcode bazen değişiklikleri algılamaz ve eski derlenmiş kodu kullanır. Özellikle:
- String literal'ler değiştiğinde
- Fonksiyon içi kod değiştiğinde
- Debug print'ler eklendiğinde

Clean build bu sorunu çözer.
