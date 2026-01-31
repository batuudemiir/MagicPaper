# Lokalizasyon Kullanım Rehberi

## Yeni Sistem: L Helper

Tüm çeviriler artık `Localization.swift` dosyasında tek bir yerde toplanmıştır.

### Kullanım

```swift
import SwiftUI

// Eski yöntem ❌
Text(localizationManager.localized(.home))

// Yeni yöntem ✅
Text(L.home)
```

### Örnekler

```swift
// Basit metin
Text(L.createStory)
Text(L.welcome)
Text(L.settings)

// Buton
Button(L.save) { }
Button(L.cancel) { }

// Navigation
.navigationTitle(L.library)
.navigationBarTitle(L.settings)

// Alert
.alert(L.deleteStory, isPresented: $showAlert) {
    Button(L.delete, role: .destructive) { }
    Button(L.cancel, role: .cancel) { }
} message: {
    Text(L.deleteConfirm)
}

// Dinamik metin
Text(L.page(currentPage, totalPages))
Text(L.trialsLeft(count))
Text(L.imageStoriesLeft(remaining))

// Koşullu metin
Text(L.isEnglish ? "English text" : "Türkçe metin")
```

### Yeni Çeviri Eklemek

`Localization.swift` dosyasına ekleyin:

```swift
extension L {
    static var myNewText: String { 
        tr("Türkçe metin", "English text") 
    }
}
```

### Avantajlar

✅ Tek dosyada tüm çeviriler
✅ Autocomplete desteği
✅ Compile-time kontrol
✅ Kolay kullanım
✅ Daha az kod

### Migration (Eski Kodları Güncelleme)

Eski:
```swift
Text(localizationManager.localized(.home))
```

Yeni:
```swift
Text(L.home)
```

### Tüm View'ları Güncellemek İçin

1. `Localization.swift` dosyası zaten hazır
2. View'larda `Text("Türkçe metin")` yerine `Text(L.key)` kullanın
3. Örnek: `Text("Ana Sayfa")` → `Text(L.home)`

### Hızlı Değiştirme

Find & Replace kullanarak:
- `Text("Ana Sayfa")` → `Text(L.home)`
- `Text("Ayarlar")` → `Text(L.settings)`
- `Text("Kütüphane")` → `Text(L.library)`

## Sonraki Adımlar

1. ✅ `Localization.swift` oluşturuldu
2. ⏳ View'ları güncelle (OnboardingView, ProfileSetupView, vb.)
3. ⏳ Eski `LocalizationManager` kullanımlarını kaldır
4. ⏳ Test et

## Örnek View Güncellemesi

### Önce:
```swift
Text("Hoş Geldiniz!")
Text("Başlamak için profilinizi oluşturun")
Button("Kaydet") { }
```

### Sonra:
```swift
Text(L.welcome)
Text(L.createProfile)
Button(L.save) { }
```
