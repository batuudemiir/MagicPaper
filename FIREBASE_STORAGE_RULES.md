# 🔥 Firebase Storage Rules Kurulumu

## Sorun
Firebase Storage'a yükleme yapılamıyor çünkü güvenlik kuralları yok veya yanlış yapılandırılmış.

## Çözüm: Storage Rules'ı Güncelle

### Adım 1: Firebase Console'a Git
1. [Firebase Console](https://console.firebase.google.com) açın
2. Projenizi seçin: **magicpaper-393a7**
3. Sol menüden **Storage** seçin
4. Üst menüden **Rules** sekmesine tıklayın

### Adım 2: Rules'ı Güncelle

Aşağıdaki kuralları kopyalayıp yapıştırın:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Child uploads klasörü - Herkes okuyabilir, herkes yazabilir (test için)
    match /child_uploads/{imageId} {
      allow read: if true;
      allow write: if true;
    }
    
    // Diğer tüm dosyalar - Sadece authenticated kullanıcılar
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Adım 3: Yayınla (Publish)
1. **Publish** butonuna tıklayın
2. Onay mesajını bekleyin

## Test İçin Geçici Rules (Daha Açık)

Eğer hala çalışmazsa, test için tamamen açık rules kullanın:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **UYARI:** Bu kurallar herkese tam erişim verir. Sadece test için kullanın!

## Production Rules (Güvenli)

Production'da kullanmak için:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Child uploads - Dosya boyutu ve tip kontrolü
    match /child_uploads/{imageId} {
      allow read: if true;
      allow write: if request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Story images
    match /story_images/{storyId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024  // 10MB limit
                   && request.resource.contentType.matches('image/.*');
    }
    
    // User profiles
    match /user_profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Doğrulama

### Test Uygulamasında:
1. Uygulamayı çalıştırın
2. **Test** sekmesine gidin
3. **Firebase Test** seçin
4. Bir fotoğraf seçin
5. **Firebase'e Yükle** butonuna tıklayın
6. Başarılı olursa URL göreceksiniz

### Firebase Console'da:
1. Storage → Files sekmesine gidin
2. `child_uploads/` klasörünü kontrol edin
3. Yüklenen dosyaları görmelisiniz

## Hata Ayıklama

### Hata: "Permission Denied"
**Çözüm:** Storage Rules'ı yukarıdaki gibi güncelleyin

### Hata: "Network Error"
**Çözüm:** 
- İnternet bağlantınızı kontrol edin
- Firebase projesinin aktif olduğundan emin olun
- GoogleService-Info.plist dosyasının doğru olduğunu kontrol edin

### Hata: "Invalid Bucket"
**Çözüm:**
- Bucket adını kontrol edin: `magicpaper-393a7.firebasestorage.app`
- GoogleService-Info.plist'te STORAGE_BUCKET değerini kontrol edin

## Console Logları

Başarılı yükleme:
```
📸 Image compressed: 245678 bytes
📤 Uploading to: child_uploads/ABC123-DEF456.jpg
✅ Upload successful
🔗 Download URL: https://firebasestorage.googleapis.com/...
```

Hatalı yükleme:
```
❌ Firebase Error: Permission denied
```

## Sonraki Adımlar

1. ✅ Storage Rules'ı güncelle
2. ✅ Test uygulamasında dene
3. ✅ Firebase Console'da dosyaları kontrol et
4. ✅ URL'i kopyala ve Fal.ai'da test et

---

**Önemli:** Rules değişikliği hemen aktif olur, uygulama yeniden başlatmaya gerek yok!
