# iOS Lokalizasyon Rehberi - Otomatik Çeviri

## Yöntem 1: Xcode String Catalog (Önerilen)

### Adım 1: String Catalog Oluştur
1. Xcode'da projeyi aç
2. File > New > File
3. "String Catalog" seç
4. İsim: `Localizable.xcstrings`
5. Targets: MagicPaper seçili olsun

### Adım 2: Dil Ekle
1. Project Navigator'da `Localizable.xcstrings` dosyasını seç
2. Sağ panelde "Localizations" bölümünde "+" butonuna tıkla
3. "English" ekle

### Adım 3: Otomatik String Toplama
Xcode otomatik olarak kodunuzdaki tüm `Text("...")` stringlerini toplar.

### Adım 4: AI ile Çevir

#### Seçenek A: XCStrings Pro (En Kolay)
1. [xcstringspro.com](https://xcstringspro.com/) adresine git
2. `Localizable.xcstrings` dosyasını yükle
3. "Translate" butonuna tıkla
4. Çevrilmiş dosyayı indir ve projeye ekle

#### Seçenek B: String Catalog Translator
1. [stringcatalogtranslator.com](https://stringcatalogtranslator.com/) adresine git
2. Dosyayı yükle ve çevir

#### Seçenek C: Command Line Tool (Ücretsiz)
```bash
# XCStringsLocalizer kur
brew install xcstringslocalizer

# OpenAI API key'ini ayarla
export OPENAI_API_KEY="your-api-key"

# Çevir
xcstringslocalizer translate Localizable.xcstrings --target-language en
```

## Yöntem 2: Manuel String Catalog Kullanımı

### Kodda Kullanım
```swift
// Eski yöntem (LocalizationManager)
Text(localizationManager.localized(.home))

// Yeni yöntem (String Catalog)
Text("home", tableName: "Localizable")
// veya
Text(LocalizedStringKey("home"))
```

### String Catalog Formatı
```json
{
  "sourceLanguage" : "tr",
  "strings" : {
    "home" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Home"
          }
        },
        "tr" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Ana Sayfa"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

## Yöntem 3: Mevcut LocalizationManager'ı Kullan

Mevcut sisteminiz zaten çalışıyor. Sadece eksik çevirileri ekleyin:

```swift
// LocalizationManager.swift içinde
case .home: 
    return currentLanguage == .turkish ? "Ana Sayfa" : "Home"
```

## Önerilen Yaklaşım

**Kısa vadede:** Mevcut LocalizationManager'ınızı kullanın, eksik çevirileri manuel ekleyin.

**Uzun vadede:** String Catalog'a geçin çünkü:
- Apple'ın resmi çözümü
- Xcode ile entegre
- Otomatik string toplama
- AI araçlarıyla uyumlu
- Daha az kod

## Hızlı Çeviri Script'i

Mevcut kodunuzdaki Türkçe metinleri bulup çevirmek için:

```bash
# Tüm Türkçe metinleri bul
grep -r "Text(\"" MagicPaper/Views/ | grep -v "//" > turkish_strings.txt

# ChatGPT veya Claude'a gönder ve çevir
```

## Sonuç

En hızlı çözüm: **XCStrings Pro** veya **String Catalog Translator** web araçlarını kullanın.
En profesyonel çözüm: **Xcode String Catalog** + AI çeviri aracı kombinasyonu.
