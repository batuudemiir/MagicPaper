# Lokalizasyon Uygulama Rehberi

## Otomatik Değiştirme Listesi

Xcode'da Find & Replace (⌘⇧F) kullanarak:

### Common Texts
- `Text("İptal")` → `Text(L.cancel)`
- `Text("Tamam")` → `Text(L.ok)`
- `Text("Kaydet")` → `Text(L.save)`
- `Text("Sil")` → `Text(L.delete)`
- `Text("Kapat")` → `Text(L.close)`
- `Text("Geri")` → `Text(L.back)`
- `Text("İleri")` → `Text(L.next)`
- `Text("Atla")` → `Text(L.skip)`
- `Text("Başla")` → `Text(L.start)`
- `Text("Oluştur")` → `Text(L.create)`
- `Text("Yükleniyor...")` → `Text(L.loading)`

### Navigation
- `Text("Ana Sayfa")` → `Text(L.home)`
- `Text("Kütüphane")` → `Text(L.library)`
- `Text("Ayarlar")` → `Text(L.settings)`
- `Text("Günlük")` → `Text(L.daily)`

### Story Types
- `Text("Görselli Hikaye")` → `Text(L.illustratedStory)`
- `Text("Metin Hikaye")` → `Text(L.textStory)`
- `Text("Günlük Hikaye")` → `Text(L.dailyStory)`
- `Text("Hikaye Oluştur")` → `Text(L.createStory)`

### Story Creation
- `Text("Çocuğun Adı")` → `Text(L.childName)`
- `Text("Yaş")` → `Text(L.age)`
- `Text("Cinsiyet")` → `Text(L.gender)`
- `Text("Erkek")` → `Text(L.boy)`
- `Text("Kız")` → `Text(L.girl)`
- `Text("Hikaye Teması")` → `Text(L.storyTheme)`
- `Text("Tema Seç")` → `Text(L.selectTheme)`

### Library
- `Text("Henüz Hikaye Yok")` → `Text(L.noStoriesInLibrary)`
- `Text("Hikayeyi Sil")` → `Text(L.deleteStory)`
- `Text("Bu hikayeyi silmek istediğinizden emin misiniz?")` → `Text(L.deleteConfirm)`

### Settings
- `Text("Profil")` → `Text(L.profile)`
- `Text("Dil")` → `Text(L.language)`
- `Text("Bildirimler")` → `Text(L.notifications)`
- `Text("Hakkında")` → `Text(L.about)`
- `Text("Gizlilik Politikası")` → `Text(L.privacyPolicy)`
- `Text("Kullanım Şartları")` → `Text(L.termsOfService)`

### Story Viewer
- `Text("Önceki")` → `Text(L.previous)`
- `Text("Sonraki")` → `Text(L.nextPage)`
- `Text("Okuma İpucu")` → `Text(L.readingTip)`
- `Text("Yavaş yavaş okuyun ve hayal edin!")` → `Text(L.readSlowly)`

### Subscription
- `Text("Hikaye Kulübü")` → `Text(L.storyClub)`
- `Text("Kulübe Katıl")` → `Text(L.joinClub)`
- `Text("EN POPÜLER")` → `Text(L.mostPopular)`
- `Text("Ücretsiz Paket")` → `Text(L.freePackage)`

## Manuel Güncelleme Gereken Yerler

### Dinamik Metinler
```swift
// Önce
Text("Sayfa \(currentPage)/\(totalPages)")

// Sonra
Text(L.page(currentPage, totalPages))
```

```swift
// Önce
Text("\(count) deneme kaldı")

// Sonra
Text(L.trialsLeft(count))
```

```swift
// Önce
Text("\(count) görselli hikaye kaldı")

// Sonra
Text(L.imageStoriesLeft(count))
```

## Adım Adım Uygulama

1. **Xcode'da Find & Replace aç** (⌘⇧F)
2. **"Text("" ile başlayan Türkçe metinleri bul**
3. **Yukarıdaki listeden uygun L.key ile değiştir**
4. **Build et ve test et**
5. **Dil değiştir ve kontrol et**

## Test Etme

```swift
// SettingsView'da dil değiştirme
LocalizationManager.shared.changeLanguage(.english)
LocalizationManager.shared.changeLanguage(.turkish)
```

## Sonuç

✅ Tüm metinler `L.key` formatında
✅ Tek dosyada yönetim
✅ Kolay bakım
✅ Autocomplete desteği
✅ Compile-time güvenlik
