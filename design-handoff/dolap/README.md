# Masal dolabım: tam boy kahraman (entegrasyon notu)

Hazırlayan: İrem (Claude ile), 22 Kasım 2026. Dal: `irem`.

İki teslim paketi:

- **v2-tam-dolap/** ("MagicPaper-Tam-Dolap-v2", asıl sistem): katmanlı tam boy insan kahraman. 17 seçim
  yuvası, 16 kombin, 8 başlangıç yüzü, 36 boyalı parça. Uygulamaya bu entegre edildi.
- **v1-ilk-dolap/** ("MagicPaper-Dolap-Handoff"): tek bir örnek çocuğun 3 takımlı tam boy çizimleri ve
  2 şapka, 2 gözlük. Kendi belgesi bunu "demo" ve sonraki çizimlerin planı olarak tanımlıyor; v2 bu planın
  tamamlanmış hali (bere ve gezgin şapkası v2'de `hat-2`, `hat-3`). Yüzü resmin içinde sabit olduğu için
  uygulamaya alınmadı (CLAUDE.md ilke 5: çocuğun kimliği tek kaynaktan). Belgeleri ve referansları burada.

Etkileşimli prototip: `design-preview/dolap/Dolap.html` (parçaları uygulamanın asset kataloğundan okur).

## Uygulamada nerede

| Teslim | Uygulama |
|---|---|
| `katalog.json` | `Screens/Hero/Figure/hero_figure_catalog.json`, değiştirilmeden |
| `secim.js` (başlangıç, kombin, tek parça kuralları) | `HeroFigure.selecting`, `isSelected` |
| `kahraman.js` (240 × 360 sahne, katmanlar) | `HeroFigureArt` (Canvas), `HeroSVGPath` (yol okuyucu) |
| Saç boyası filtresi | `HeroHairDye` (Core Image, sRGB renk küpü, önbellek) |
| `assets/` 36 PNG | `Assets.xcassets/HeroFigure/*`; saç ve şapka tam çözünürlük, giysi ve ayakkabı %65 (7 MB) |
| Dolap ekranı | `HeroStudioView`: Profil → kahraman kartı ve Büyükler için → kahraman |
| Tek tarayıcı kaydı | `HeroLook.figure`, çocuk başına (`HeroLookStore`), hesap eşitlemesi (`heroes`) aynı kayıtla |
| Profil portresi | `HeroAvatarView`: tam boy kaydı olan çocuk aynı kayıttan büst kadrajıyla |
| Hayvanlar | Eski büst dolabı (`HeroWardrobeView`) sürer; "Tür" rafından geçilir (`HeroDressingRoom`) |
| Kontrol betiği (`kontrol.cjs`) | `HeroFigureTests` |

Eski alanlara yansıma (`HeroFigure+Legacy.swift`): kaydedilince ten, saç, saç rengi, başörtüsü, gözlük ve
giysi rengi eski `HeroLook` alanlarına da yazılır; görselli kitabın parça seçimi aynı çocuğu görür.
Eski kahraman otomatik dönüştürülmez: dolap ilk açılışta "Kiraz bahçesi" başlangıcıyla açılır, kayıt
çocuk kaydedince olur.

## Davranış sözleşmesi (01-iOS-Handoff.md)

| Durum | Uygulamada |
|---|---|
| Başlangıç yüzü | Yalnızca kimlik; giysi ve aksesuar korunur. Geri al bir adım. |
| Kombin | Üst, alt, tek parça, ayakkabı; kimlik, gözlük, başlık, çanta korunur. |
| Tek parça + ayakkabı / üst / alt | Ayakkabı tek parçayı korur; üst ya da alt iki parçaya döner. |
| Başörtüsü | Saç seçimi saklanır, not: "Saç seçimin başörtünün altında korunur." |
| Şapka | Saçın üstü maskelenir (y < 78). |
| Peş peşe deneme | Son seçim kazanır; geri al 60 adıma kadar tek tek. |
| Hareketi Azalt | Prova eğilmesi yok, parça doğrudan değişir. |
| Kaydetmeden çıkma | "Dolaptan çıkalım mı?" · Kaydetmeden çık / Denemeye devam et. |
| Yakın plan | Yüzle ilgili rafta kamera yaklaşır; "Yüzü gör / Tam boy gör" elle. |
| VoiceOver | Her karo adı ve seçili durumu; seçimde duyuru. |
| Büyük yazı | Raf iki sütun, prova nişi kısalır. |

## Açık noktalar (Batuhan)

1. **Yıldız fiyatı.** v2 "bütün yüzler ve kıyafetler herkese açık" diyor; tam boy dolapta fiyat yok.
   Eski büst dolabında (hayvanlar) yıldızla açılan kozmetikler aynen duruyor. İstersen bazı şapka ve tek
   parçalara yıldız fiyatı eklenebilir (`HeroShop` gibi); kimlik, başörtüsü ve gözlük her zaman ücretsiz.
2. **Çizim paleti.** `HeroFigurePalette.swift` illüstrasyonun kendi renkleri (kapak paleti gibi), tasarım
   yasasının "renk yalnızca `MP.Palette`" kuralının dışında tek dosyada. Onayın gerekiyor.
3. **Kenardan kaydırarak geri.** Kaydedilmemiş değişiklikte onay "Geri" düğmesinde var; sistemin kenar
   hareketi yığından doğrudan çıkabilir. Cihazda bakılmalı.
4. **Test çalıştırılmadı** (Windows). `HeroFigureTests` Mac'te; `[ekran]` turu derlemeyi ve dolabın
   ekran görüntüsünü verir.
