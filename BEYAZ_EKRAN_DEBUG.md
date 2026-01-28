# 🐛 Beyaz Ekran Debug Rehberi

## 📊 Durum
- ✅ Uygulama başlıyor
- ✅ Notification permission granted
- ✅ 1 hikaye UserDefaults'tan yüklendi
- ❌ Ekran beyaz görünüyor
- ❌ Tab bar görünmüyor

## 🔍 Olası Sebepler

### 1. TabView Render Sorunu
TabView düzgün render olmamış olabilir.

### 2. NavigationView Çakışması
LibraryView içinde NavigationView var, bu sorun yaratabilir.

### 3. Story Data Sorunu
Hikaye yüklendi ama gösterilemiyor.

## 🛠️ Debug Adımları

### Adım 1: Console Loglarını Kontrol Et

Uygulamayı çalıştır ve console'da şunları ara:

```
🎯 ContentView appeared - Selected tab: 0
📚 LibraryView appeared - Stories count: 1
```

Eğer bu loglar görünmüyorsa, view'lar render olmuyor demektir.

### Adım 2: Tab'lar Arasında Geçiş Yap

Simulator'da alt kısımda tab bar görünüyor mu?
- Eğer görünüyorsa, her tab'a dokun ve console'u izle
- Eğer görünmüyorsa, TabView render sorunu var

### Adım 3: Basit Test

ContentView'ı geçici olarak basitleştir:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            Text("Ana Sayfa")
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
            
            Text("Kütüphane")
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical.fill")
                }
        }
    }
}
```

Eğer bu çalışıyorsa, sorun view'ların içinde.

### Adım 4: LibraryView'ı Test Et

LibraryView'ı tek başına test et:

```swift
struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}
```

## 🎯 Yapılan Değişiklikler

### 1. ContentView.swift
- `onAppear` eklendi (debug için)
- `Label` kullanımı (iOS 15 uyumlu)

### 2. LibraryView.swift
- `onAppear` eklendi (debug için)
- Story count ve status loglanıyor

## 📱 Test Senaryoları

### Senaryo 1: Tab Bar Görünüyor
1. Her tab'a dokun
2. Console loglarını kontrol et
3. Hangi view'lar render oluyor?

### Senaryo 2: Tab Bar Görünmüyor
1. ContentView render sorunu
2. Basit test yap (yukarıda)
3. Xcode'u yeniden başlat

### Senaryo 3: Kütüphane Tab'ı Boş
1. Console'da story count kontrol et
2. Eğer 0 ise, UserDefaults yükleme sorunu
3. Eğer >0 ise, UI render sorunu

## 🔧 Hızlı Düzeltmeler

### Düzeltme 1: Xcode Cache Temizle
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/
```

### Düzeltme 2: Simulator Reset
```bash
# Simulator → Device → Erase All Content and Settings
```

### Düzeltme 3: Clean Build
```bash
# Xcode: Product → Clean Build Folder (Cmd+Shift+K)
# Xcode: Product → Build (Cmd+B)
```

## 📊 Beklenen Console Çıktısı

```
✅ Notification permission granted
✅ Loaded 1 stories from UserDefaults
🎯 ContentView appeared - Selected tab: 0
📚 LibraryView appeared - Stories count: 0  ← İlk tab Ana Sayfa olduğu için
```

Kütüphane tab'ına dokunduğunda:
```
📚 LibraryView appeared - Stories count: 1
  - Hikaye Başlığı (Status: Tamamlandı)
```

## 🆘 Hala Sorun Varsa

1. **Ekran görüntüsü al**
   - Simulator'ın tamamını
   - Console loglarını

2. **Şunları kontrol et**
   - Hangi tab seçili?
   - Tab bar görünüyor mu?
   - Console'da hangi loglar var?

3. **Test et**
   - Farklı tab'lara dokun
   - Uygulamayı kapat/aç
   - Simulator'ı restart et

---

**Debug Tarihi**: 24 Ocak 2026
**Durum**: 🔍 ARAŞTIRILIYOR
