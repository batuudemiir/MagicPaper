# Otomatik Çeviri Yardımcısı

## Bulunan Türkçe Metinler (182 adet)

Aşağıdaki metinleri İngilizceye çevirin:

1. "Adınız" → "Your Name"
2. "Aktif Paketiniz" → "Your Active Package"
3. "Atla" → "Skip"
4. "Aç" → "Open"
5. "Başlamak için profilinizi oluşturun" → "Create your profile to get started"
6. "Bir kahveden ucuz!" → "Cheaper than a coffee!"
7. "Cinsiyet" → "Gender"
8. "Daha iyi okunabilirlik için renkler optimize edildi" → "Colors optimized for better readability"
9. "Farklı bir arama terimi deneyin" → "Try a different search term"
10. "Fotoğraf Seç" → "Select Photo"
11. "Geri" → "Back"
12. "Görseller oluşturuluyor" → "Generating images"
13. "Görselli Hikaye" → "Illustrated Story"
14. "Günün Hikayesi" → "Story of the Day"
15. "Hemen Başla" → "Start Now"
16. "Henüz Günlük Hikaye Yok" → "No Daily Stories Yet"
17. "Henüz Metin Hikaye Yok" → "No Text Stories Yet"
18. "Her 8 saniyede bir sayfa" → "One page every 8 seconds"
19. "Hikaye Oluştur" → "Create Story"
20. "Hikaye Teması" → "Story Theme"
21. "Hikaye metninin boyutunu ayarlayın" → "Adjust story text size"
22. "Hikaye sayfaları otomatik olarak ilerler" → "Story pages advance automatically"
23. "Hikayenin Öğretisi" → "Story's Lesson"
24. "Hikayeniz oluşturuluyor!" → "Your story is being created!"
25. "Hikayeyi Oluştur" → "Create Story"
26. "Hızlı Hikaye Oluştur" → "Quick Story Create"
27. "Hızlı Seçim" → "Quick Select"
28. "Kapat" → "Close"
29. "Kategoriler" → "Categories"
30. "Kredi Satın Al" → "Buy Credits"
31. "Kulübe Katıl" → "Join Club"
32. "Kulüp Üyeliği Gerekli" → "Club Membership Required"
33. "Lütfen çocuğun ismini girin" → "Please enter child's name"
34. "Maceranın türünü seçin" → "Select adventure type"
35. "Maksimum Değer!" → "Maximum Value!"
36. "Menü" → "Menu"
37. "Metin & Günlük" → "Text & Daily"
38. "Mevcut Paketiniz" → "Your Current Package"
39. "Nasıl Çalışır?" → "How It Works?"
40. "Neden Kredi Sistemi?" → "Why Credit System?"
41. "Okuma Teması" → "Reading Theme"
42. "Okuma alışkanlığı kazandırın!" → "Build reading habit!"
43. "Okuma İpucu" → "Reading Tip"
44. "Okundu" → "Read"
45. "Oluştur" → "Create"
46. "Otomatik Oynat" → "Auto Play"
47. "Premium Temalar" → "Premium Themes"
48. "Premium Üye" → "Premium Member"
49. "Profil Fotoğrafı" → "Profile Photo"
50. "Satır Aralığı" → "Line Spacing"
51. "Satırlar arasındaki boşluğu ayarlayın" → "Adjust spacing between lines"
52. "Sayfa" → "Page"
53. "Sihir" → "Magic"
54. "Sihirli Hikayeler" → "Magic Stories"
55. "Sonraki" → "Next"
56. "Sonuç Bulunamadı" → "No Results Found"
57. "Süper Tasarruf!" → "Super Savings!"
58. "Sınırsız Hikaye Dünyası" → "Unlimited Story World"
59. "Temel Bilgiler" → "Basic Information"
60. "Yavaş yavaş okuyun ve hayal edin!" → "Read slowly and imagine!"
61. "Yazı Boyutu" → "Text Size"
62. "Yaş" → "Age"
63. "Yeni" → "New"
64. "Yükleniyor..." → "Loading..."
65. "Yüksek Kontrast Aktif" → "High Contrast Active"
66. "Yükselt" → "Upgrade"
67. "Çocuk Bilgileri" → "Child Information"
68. "Çocuğun İsmi" → "Child's Name"
69. "Çocuğunuz Kahramanı Olsun" → "Make Your Child the Hero"
70. "Çocuğunuza Okuma" → "Reading for Your Child"
71. "Önizleme" → "Preview"
72. "Önceki" → "Previous"
73. "Özel Hikaye Konusu" → "Custom Story Topic"
74. "Ücretsiz Deneme" → "Free Trial"
75. "Ücretsiz Deneme Aktif" → "Free Trial Active"
76. "Ücretsiz Hikaye Hazır!" → "Free Story Ready!"
77. "Ücretsiz Paket" → "Free Package"
78. "Ücretsiz Temalar" → "Free Themes"
79. "İletişim" → "Contact"
80. "İsim" → "Name"

## Önerilen Yaklaşım

Bu metinleri LocalizationManager'a eklemek yerine, **Xcode String Catalog** kullanmanızı öneriyorum:

### Hızlı Kurulum (5 dakika)

1. **String Catalog Oluştur:**
   - Xcode'da: File > New > File > String Catalog
   - İsim: `Localizable.xcstrings`

2. **Web Aracı ile Çevir:**
   - [xcstringspro.com](https://xcstringspro.com/) veya
   - [stringcatalogtranslator.com](https://stringcatalogtranslator.com/)

3. **Kodda Kullan:**
```swift
// Eski
Text(localizationManager.localized(.home))

// Yeni (otomatik)
Text("Ana Sayfa")
// Xcode otomatik olarak çevirir
```

Bu yöntem:
- ✅ Otomatik string toplama
- ✅ AI ile çeviri
- ✅ Xcode entegrasyonu
- ✅ Daha az kod
- ✅ Apple'ın resmi yöntemi
