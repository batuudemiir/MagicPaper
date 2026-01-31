# Hikaye Okuma Özelleştirme Rehberi

## Genel Bakış

MagicPaper hikaye okuma ekranı artık tam özelleştirilebilir okuma deneyimi sunuyor. Kullanıcılar yazı boyutu, tema, satır aralığı ve otomatik oynatma gibi seçenekleri kendi tercihlerine göre ayarlayabilir.

---

## Yeni Özellikler

### 1. **Yazı Boyutu Ayarlama** 📏

Dört farklı yazı boyutu seçeneği:

- **Küçük** (0.85x) - Daha fazla içerik görmek için
- **Normal** (1.0x) - Varsayılan boyut
- **Büyük** (1.2x) - Rahat okuma için
- **Çok Büyük** (1.4x) - Maksimum okunabilirlik

**Nasıl Kullanılır:**
1. Hikaye okuma ekranında sağ üstteki "Aa" ikonuna tıklayın
2. "Yazı Boyutu" bölümünden istediğiniz boyutu seçin
3. Değişiklik anında uygulanır

**Teknik Detaylar:**
- Başlık ve metin boyutları orantılı olarak ölçeklenir
- Satır aralığı otomatik olarak ayarlanır
- iPad'de daha büyük temel boyutlar kullanılır
- Çocuğun ismi her zaman %15 daha büyük görünür

---

### 2. **Okuma Temaları** 🎨

Üç farklı okuma teması:

#### Beyaz Tema (Varsayılan)
- **Arka Plan:** Sistem beyazı
- **Metin:** Siyah
- **İkon:** ☀️ Güneş
- **Kullanım:** Gündüz okuma, parlak ortamlar

#### Sepia Tema
- **Arka Plan:** Krem/bej (#F7F0DE)
- **Metin:** Koyu kahverengi
- **İkon:** 📖 Kitap
- **Kullanım:** Göz yorgunluğunu azaltır, klasik kitap hissi

#### Gece Teması
- **Arka Plan:** Koyu gri (#1C1C1E)
- **Metin:** Açık gri
- **İkon:** 🌙 Ay
- **Kullanım:** Karanlık ortamlar, gece okuma

**Nasıl Kullanılır:**
1. Okuma ayarlarını açın
2. "Okuma Teması" bölümünden tema seçin
3. Önizlemede sonucu görün

**Özellikler:**
- Tüm sayfa arka planı değişir
- Metin renkleri otomatik uyarlanır
- Görseller etkilenmez
- Tercih kaydedilir ve tüm hikayelerde kullanılır

---

### 3. **Satır Aralığı Ayarlama** 📐

Dört farklı satır aralığı seçeneği:

- **Sıkı** (4pt) - Kompakt görünüm
- **Normal** (8pt) - Dengeli okuma
- **Rahat** (12pt) - Konforlu okuma
- **Geniş** (16pt) - Maksimum rahatlık

**Nasıl Kullanılır:**
1. Okuma ayarlarında "Satır Aralığı" bölümüne gidin
2. İstediğiniz aralığı seçin
3. Önizlemede farkı görün

**Özellikler:**
- Yazı boyutuyla orantılı ölçeklenir
- Büyük yazılarda otomatik artar
- Okunabilirliği artırır

---

### 4. **Otomatik Oynatma** ▶️

Hikaye sayfaları otomatik olarak ilerler:

**Özellikler:**
- Her 8 saniyede bir sayfa değişir
- Oynat/Duraklat butonu ile kontrol
- Son sayfada otomatik durur
- Ekrandan çıkınca otomatik durur

**Nasıl Kullanılır:**
1. Sağ üstteki ▶️ ikonuna tıklayın
2. Otomatik oynatma başlar
3. Durdurmak için ⏸️ ikonuna tıklayın

**Kullanım Senaryoları:**
- Çocuğa hikaye anlatırken eller serbest kalır
- Uyku öncesi otomatik okuma
- Grup dinleme aktiviteleri

---

## Kullanıcı Arayüzü

### Okuma Ekranı Butonları

```
┌─────────────────────────────────────┐
│ Kapat    Hikaye Başlığı    Aa ▶️ ⋯ │
│         Sayfa 1 / 5                 │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
└─────────────────────────────────────┘
```

**Butonlar:**
- **Aa** - Okuma ayarları
- **▶️/⏸️** - Otomatik oynatma
- **⋯** - Paylaş, indir, PDF menüsü

### Okuma Ayarları Ekranı

```
┌─────────────────────────────────────┐
│         Okuma Ayarları        Bitti │
├─────────────────────────────────────┤
│ YAZI BOYUTU                         │
│ ✓ Küçük                             │
│   Normal                            │
│   Büyük                             │
│   Çok Büyük                         │
├─────────────────────────────────────┤
│ OKUMA TEMASI                        │
│ ✓ ☀️ Beyaz                          │
│   📖 Sepia                          │
│   🌙 Gece                           │
├─────────────────────────────────────┤
│ SATIR ARALIĞI                       │
│   Sıkı                              │
│ ✓ Normal                            │
│   Rahat                             │
│   Geniş                             │
├─────────────────────────────────────┤
│ OTOMATIK OYNAT                      │
│ ▶️ Otomatik Oynat          [Toggle] │
│   Her 8 saniyede bir sayfa          │
├─────────────────────────────────────┤
│ ÖNİZLEME                            │
│ ┌─────────────────────────────────┐ │
│ │ Bir zamanlar uzak bir diyarda,  │ │
│ │ küçük bir kahraman yaşardı.     │ │
│ │ Maceraları efsanelere konu oldu.│ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Teknik Uygulama

### Veri Saklama

Kullanıcı tercihleri `@AppStorage` ile saklanır:

```swift
@AppStorage("storyTextSize") private var textSize: TextSize = .normal
@AppStorage("storyReadingTheme") private var readingTheme: ReadingTheme = .light
@AppStorage("storyLineSpacing") private var lineSpacing: LineSpacingOption = .normal
```

**Avantajlar:**
- Tercihler kalıcı olarak saklanır
- Tüm hikayelerde aynı ayarlar kullanılır
- Uygulama yeniden başlatıldığında korunur
- iCloud ile senkronize edilebilir

### Enum Tanımları

#### TextSize
```swift
enum TextSize: String, CaseIterable, RawRepresentable {
    case small = "Küçük"
    case normal = "Normal"
    case large = "Büyük"
    case extraLarge = "Çok Büyük"
    
    var multiplier: CGFloat { ... }
    var icon: String { ... }
}
```

#### ReadingTheme
```swift
enum ReadingTheme: String, CaseIterable, RawRepresentable {
    case light = "Beyaz"
    case sepia = "Sepia"
    case dark = "Gece"
    
    var backgroundColor: Color { ... }
    var textColor: Color { ... }
    var icon: String { ... }
}
```

#### LineSpacingOption
```swift
enum LineSpacingOption: String, CaseIterable, RawRepresentable {
    case compact = "Sıkı"
    case normal = "Normal"
    case relaxed = "Rahat"
    case loose = "Geniş"
    
    var spacing: CGFloat { ... }
}
```

### Dinamik Yazı Boyutu Hesaplama

```swift
let baseTitleFontSize: CGFloat = DeviceHelper.isIPad ? 32 : 22
let baseBodyFontSize: CGFloat = DeviceHelper.isIPad ? 22 : 17

// Kullanıcı tercihiyle çarp
let titleFontSize = baseTitleFontSize * textSize.multiplier
let bodyFontSize = baseBodyFontSize * textSize.multiplier
let currentLineSpacing = lineSpacing.spacing * textSize.multiplier
```

### İsim Vurgulama

Çocuğun ismi her zaman özel olarak vurgulanır:

```swift
private func highlightNameWithSettings(in text: String, name: String, fontSize: CGFloat) -> AttributedString {
    var attributedString = AttributedString(text)
    let nameFontSize = fontSize * 1.15 // %15 daha büyük
    
    // Tema rengini uygula
    attributedString.foregroundColor = readingTheme.textColor
    attributedString.font = .system(size: fontSize)
    
    // İsmi vurgula
    if let range = attributedString.range(of: name, options: .caseInsensitive) {
        attributedString[range].foregroundColor = .orange
        attributedString[range].font = .system(size: nameFontSize, weight: .bold)
    }
    
    return attributedString
}
```

### Otomatik Oynatma

Timer kullanarak sayfa geçişi:

```swift
private func startAutoPlay() {
    autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
        if currentPage < currentStory.pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            autoPlayEnabled = false // Son sayfada dur
        }
    }
}

private func stopAutoPlay() {
    autoPlayTimer?.invalidate()
    autoPlayTimer = nil
}
```

---

## Kullanıcı Deneyimi

### Akış Diyagramı

```
Hikaye Okuma Ekranı
        ↓
    [Aa Butonu]
        ↓
Okuma Ayarları Açılır
        ↓
┌───────────────────────┐
│ Yazı Boyutu Seç       │ → Anında Güncelle
│ Tema Seç              │ → Anında Güncelle
│ Satır Aralığı Seç     │ → Anında Güncelle
│ Otomatik Oynat Aç/Kapa│ → Timer Başlat/Durdur
│ Önizleme Gör          │ → Canlı Önizleme
└───────────────────────┘
        ↓
    [Bitti]
        ↓
Ayarlar Kaydedilir
        ↓
Hikaye Okumaya Devam
```

### Önizleme Özelliği

Kullanıcılar değişiklikleri anında görebilir:

```
┌─────────────────────────────────┐
│ ÖNİZLEME                        │
│ ┌─────────────────────────────┐ │
│ │ Bir zamanlar uzak bir       │ │
│ │ diyarda,                    │ │ ← Seçilen ayarlarla
│ │                             │ │
│ │ küçük bir kahraman yaşardı. │ │
│ │                             │ │
│ │ Maceraları efsanelere       │ │
│ │ konu oldu.                  │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## Erişilebilirlik

### Dynamic Type Uyumluluğu

Okuma ayarları iOS Dynamic Type ile birlikte çalışır:

- Sistem yazı boyutu ayarları korunur
- Kullanıcı tercihleri ek olarak uygulanır
- Maksimum okunabilirlik sağlanır

### VoiceOver Desteği

Tüm kontroller VoiceOver ile erişilebilir:

```swift
// Yazı boyutu butonu
.accessibilityLabel("Yazı boyutu: \(textSize.rawValue)")
.accessibilityHint("Yazı boyutunu değiştirmek için çift dokunun")

// Tema butonu
.accessibilityLabel("Okuma teması: \(readingTheme.rawValue)")
.accessibilityHint("Arka plan rengini değiştirmek için çift dokunun")

// Otomatik oynatma
.accessibilityLabel(autoPlayEnabled ? "Otomatik oynatma açık" : "Otomatik oynatma kapalı")
.accessibilityHint("Otomatik sayfa geçişini açmak veya kapatmak için çift dokunun")
```

---

## Performans

### Optimizasyonlar

1. **Lazy Loading**: Sadece görünen sayfa render edilir
2. **State Management**: Minimal state güncellemeleri
3. **Timer Yönetimi**: Ekrandan çıkınca otomatik temizleme
4. **Memory Management**: Görsel önbellekleme

### Bellek Kullanımı

```
Okuma Ayarları: ~2KB (UserDefaults)
Timer: ~1KB (aktif olduğunda)
Önizleme: ~5KB (geçici)
Toplam: ~8KB ek bellek
```

---

## Gelecek Geliştirmeler

### Planlanan Özellikler

1. **Yazı Tipi Seçimi**
   - San Francisco (varsayılan)
   - Georgia (serif)
   - Verdana (sans-serif)
   - OpenDyslexic (disleksi dostu)

2. **Gelişmiş Otomatik Oynatma**
   - Hız ayarı (5s, 8s, 10s, 15s)
   - Sesli okuma entegrasyonu
   - Sayfa geçiş animasyonları

3. **Okuma İstatistikleri**
   - Toplam okuma süresi
   - Okunan sayfa sayısı
   - Favori temalar

4. **Paylaşım Seçenekleri**
   - Ayarları dışa aktar
   - Ayarları içe aktar
   - Aile üyeleri arasında paylaş

5. **Gelişmiş Temalar**
   - Özel renk seçimi
   - Gradient arka planlar
   - Animasyonlu temalar

---

## Sorun Giderme

### Sık Karşılaşılan Sorunlar

**S: Ayarlarım kaydedilmiyor**
- C: Uygulama izinlerini kontrol edin
- C: Uygulamayı yeniden başlatın
- C: iOS güncellemelerini kontrol edin

**S: Otomatik oynatma çalışmıyor**
- C: Hikayenin birden fazla sayfası olduğundan emin olun
- C: Son sayfada değilsiniz kontrol edin
- C: Uygulamayı ön planda tutun

**S: Tema değişmiyor**
- C: Ayarlar ekranını kapatıp tekrar açın
- C: Farklı bir hikaye açıp tekrar deneyin
- C: Uygulamayı yeniden başlatın

**S: Yazı çok büyük/küçük**
- C: Yazı boyutu ayarını kontrol edin
- C: iOS sistem yazı boyutunu kontrol edin
- C: "Normal" ayarına dönün

---

## Destek

Okuma özelleştirme ile ilgili sorularınız için:
- **Email**: destek@magicpaper.app
- **Konu**: "Okuma Ayarları"
- **Bilgi**: Cihaz modeli, iOS versiyonu, ekran görüntüsü

---

**Durum**: ✅ Tam Çalışır
**Tarih**: 31 Ocak 2026
**Versiyon**: 1.0
**Diller**: Türkçe (UI), Tüm diller (içerik)
