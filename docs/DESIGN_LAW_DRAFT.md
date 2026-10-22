# Design Law — ölçüm ve açık sorular

> Durum: **CLAUDE.md'ye eklendi (2026-09-30)** — kök `CLAUDE.md`, §9 altında
> "Design law". Kuralların güncel metni orada; bu dosya yalnızca ölçüm
> (Ek) ve açık sorular için tutuluyor. Aşağıdaki kural metni ilk taslaktır.

---

## Design law

Token'ların tek kaynağı `DesignSystem/MPTheme.swift`. Aşağıdaki kurallar
ölçülebilir; her biri sonundaki grep kontrolüyle doğrulanır.

### Tipografi
- İki aile, rolleri sabit: **Baloo 2** yalnızca başlık ve kapak (`MP.F.display*`),
  **Nunito** geri kalan her şey (`MP.F.body*`, `label*`, `caption`, `read`).
- Font yalnızca `MP.F` fonksiyonlarından gelir. Satır içi `.custom(...)` yok,
  `.custom(_:fixedSize:)` hiç yok (Dynamic Type'ı öldürür).
- `.system(...)` yalnızca `MP.F.glyph(_:)` üzerinden ve boyutu `MP.G`'den.
- Ölçekte olmayan boyut açma. Hiyerarşi önce boşlukla, sonra boyutla,
  en son ağırlıkla kurulur.
- Masal metni yalnızca `MP.F.read(ReadSize.points)` + `lineSpacing = points × 0.72`.

### Renk
- `Color(hex:)` yalnızca `MP.Palette` içinde. Tek istisna:
  `MagicPaperCoverColor` (kapak sanatının paleti, arayüz rengi değil).
- Bileşenler `MP.C` okur, `MP.Palette` okumaz (istisnalar: `World`,
  `ReadTheme`, `C.avatarAccents`).
- Saf siyah ve soğuk gri yok. `.black.opacity(...)` yerine
  `MP.Palette.murekkep900.opacity(...)` ya da ilgili `MP.C` token'ı.
- `sepya` yalnızca okuyucu kâğıdında. Dünya aksanları arayüzde tek başına yok.

### Boşluk ve biçim
- Boşluk yalnızca `MP.S`. `.padding(12)` gibi çıplak sayı yok.
- Ekran kenarı `MP.S.screenGutter` (20). Dokunma alanı en az `MP.S.tapMin` (48).
- Köşe yarıçapı `MP.R` — önce semantik olan (`card`, `button`, `sheet`, `input`).

### Derinlik
- Sistemin imzası sert alt kenar: `mpEdge`. Kart derinliği gölgeden gelmez.
- Gölge yalnızca `mpShadow(MP.Sh.*)`. Çıplak `.shadow(...)` yok.
- Gradient arayüz yüzeyinde ve butonda yok. Yalnızca malzeme taklidi için
  izinli: kâğıt gölgelemesi, sayfa kıvrımı, kapak sanatı, parlaklık maskesi.

### Hareket
- Süre ve eğri yalnızca `MP.M` (`press` 0.11, `easeOut` 0.18, `base` 0.26,
  `slow` 0.42, `page` 0.52). Tek spring: `MP.M.spring`.
- Her animasyon Reduce Motion'dan geçer: `MP.M.gated(...)` ya da
  `@Environment(\.accessibilityReduceMotion)`. Kapalıyken anlamı koruyan
  alternatif (çapraz geçiş), boşluk değil.
- Basma davranışı yalnızca `MPPressStyle`.
- Sürüklerken hiçbir şey zıplamaz, parlamaz, titremez.

### Dokunsallık
- Titreşim yalnızca `MPHaptics` üzerinden (kullanıcı ayarına bağlı).
  Doğrudan `UIFeedbackGenerator` ya da `.sensoryFeedback` yok.
- Tamamlanan eylem başına en fazla bir titreşim; sürükleme sırasında hiç.

### Erişilebilirlik (her yeni ya da değişen ekran)
- Her etkileşimli öğenin Türkçe `accessibilityLabel`'ı var; süs öğeleri
  `accessibilityHidden(true)`.
- En büyük Dynamic Type boyutunda kesilme yok, yatay taşma yok.
- Bilgi yalnızca renkle verilmez (Differentiate Without Color).
- Gövde metni, üç okuma temasında da (`Gündüz`, `Sepya`, `Gece`)
  kâğıda karşı en az 4.5:1 kontrast.

### Üst başlık (karar: 22 Ekim 2026)
- Ebeveyn alanında yalnızca `MPParentHeader`. Kök sayfa (Özet, Güvenlik, Ayarlar) `MPParentHeader(title:subtitle:)`: büyük başlık + "Çocuk modu". Alt sayfa `MPParentHeader(title:subtitle:onBack:)`: "Geri" + küçük başlık; "Çocuk modu" alt sayfada görünmez.
- Çocuk alanının alt sayfalarında `MPTopBar`. Çocuk kök sekmelerinin başlıkları ve illüstrasyonlu üst bölgeler (`GunlukHeader`, klasik detay) henüz bu kurala dahil değil; hedef `MPArtHero` (`docs/BUTUNLUK_DENETIMI.md`).
- Geri her yerde `MPCircleButton("chevron.left")` + "Geri"; başlık metni `isHeader` trait'i taşır.
- Başlık kendi kenar boşluğunu eklemez: yatay boşluk `screenGutter`, üst boşluk sayfanın. Ekran kendi başlık satırını yazmaz, negatif boşlukla başlığı kaydırmaz.

### Bölüm başlığı ve boş durum (karar: 22 Ekim 2026)
- Bölüm başlığı yalnızca `MPSectionHeader`: çocuk alanında `title3`, ebeveyn alanında `headline` (`area:`); "Tümü ›" `link:`, sayaç `note:`, ekranın kendi denetimi `trailing:`. `HomeSection` ve `ParentSection` bunun üstüne kurulu. Kart içi bölüm (`GunlukSection`) ayrı tasarım, kural dışı.
- Boş ve hata durumu yalnızca `MPStateView`: Ragi + bir başlık + bir cümle + tek eylem; yalnızca çocuk alanında. Ebeveyn alanında boş durum liste satırı (`MPListRow`) dilinde, Ragi'siz. Ekranda Ragi zaten görünüyorsa (Kitaplık'ta "Eşleşen kitap yok") ikinci Ragi konmaz, yalnızca söz kalır.

### İkon
- İkon yalnızca `MPIcon`, boyut `MP.G`'den.

### Doğrulama
Bir ekranı "bitti" saymadan önce:

1. Aşağıdaki kontroller değiştirilen dosyalarda boş dönmeli.
2. Simülatörde ekran görüntüsü: açık + koyu, en büyük Dynamic Type,
   küçük ekran (iPhone SE) + büyük ekran (Pro Max).

```bash
grep -rn "Color(hex:" --include='*.swift' MagicPaper/MagicPaper | grep -v -e MPTheme.swift -e MagicPaperCoverPalette.swift
grep -rn "\.shadow(" --include='*.swift' MagicPaper/MagicPaper | grep -v "func mpShadow"
grep -rnE "\.padding\((\.[a-z]+, )?[0-9]" --include='*.swift' MagicPaper/MagicPaper
grep -rn "fixedSize:" --include='*.swift' MagicPaper/MagicPaper
grep -rn -e "UIImpactFeedbackGenerator" -e "sensoryFeedback" --include='*.swift' MagicPaper/MagicPaper | grep -v MPHaptics.swift
```

---

## Ek — taslağı yazarken ölçülen durum (2026-09-30)

Kurallar bugünkü kodla çelişmiyor ama kod henüz tamamen uymuyor. CLAUDE.md'ye
girdikten sonra yeni kod bu kurallara uyar; mevcut ihlaller ayrı bir turda,
dosya sahibi ajanla düzeltilir.

| Kontrol | İhlal | Nerede |
|---|---|---|
| `Color(hex:)` palet dışı | 59 | `Screens/CoverSystem/MagicPaperCoverView.swift` — Design System dokümanı 18 Eylül'de "0" diyordu; kapak sistemi sonradan ekleniyor ve kural hiçbir yerde otomatik uygulanmıyordu |
| Çıplak `.shadow(` | 6 | `MagicPaperCoverView` (2), `MagicPaperCoverGalleryPreview` (3, preview), `SimpleSubscriptionView` (1) |
| Çıplak sayı padding | 100 | birçok dosya — dağılımı ayrıca çıkarılmalı |
| Çıplak sayı `cornerRadius:` | 22 | birçok dosya |
| `.font(.system(size:))` | 8 / 5 dosya | çoğu preview/galeri; canlı olan `SimpleSubscriptionView` |

## Açık sorular (art director kararı)

1. **Spring'in karakteri.** `MP.M.spring` = `response 0.32, dampingFraction 0.62`.
   Bu belirgin bir zıplama verir (~%38 bounce). "Sakin, editoryal" hedefe göre
   canlı. Aynen kalsın mı, `dampingFraction ≈ 0.85`'e mi çekilsin?
2. **Emoji.** "Emoji ikon olarak kullanılmaz" kuralı eklensin mi? `MP.G`
   emoji boyutlarını da kapsıyor; yani şu an emoji kasıtlı olarak kullanılıyor.
3. **`hardal` = "ödül".** Palette yorumu "sıcaklık, ödül" diyor. CLAUDE.md
   rozet ve ödül ekonomisini yasaklıyor. Token'ın anlamı "premium / sıcaklık"
   olarak yeniden adlandırılsın mı?
4. **`MagicPaperCoverView`'daki 59 ham hex** `MagicPaperCoverColor`'a mı taşınsın,
   yoksa kapak sanatı istisnası o dosyayı da mı kapsasın?
