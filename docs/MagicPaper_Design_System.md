# MagicPaper — Tasarım Sistemi

**Tarih:** 2026-09-18
**Sahip:** `design-system` agent
**Kapsam:** `MagicPaper/MagicPaper/DesignSystem/**`

Token'ların **tek kaynağı** `DesignSystem/MPTheme.swift`'tir. Depoda `tokens/*.css`
diye bir klasör yoktur ve hiç olmadı; MPTheme'in başındaki o referans bu turda
kaldırıldı. Dışarıda üretilen bir token dosyası, bir kopya veya bir build adımı yoktur.

---

## 1. Değişmez kural

> Ham `Color(hex:)` YALNIZCA `MP.Palette` içinde yazılır.

`Color(hex:)` initializer'ı paletin kurucusudur ve `MPTheme.swift`'te kalır — silinmez.
Ama çağrılması palete özeldir. Bu turdan sonra uygulama hedefinde bu kural tutuyor:

```
$ grep -rn "Color(hex:" --include="*.swift" MagicPaper/MagicPaper | grep -v MPTheme.swift
(çıktı yok)
```

Katman sırası:

```
Palette   ham renk         (gul400, kagit100, sepya50 …)
   ↓
C         anlam            (brand, surfaceApp, edgeCircle …)   ← bileşenler burayı okur
   ↓
Bileşen   MPCard, MPButton, MPAvatar …
```

`Palette`'i doğrudan okuyan üç meşru istisna var, hepsi marka dışı aksan üretir:
`MP.World.accent`, `MP.ReadTheme`, `MP.C.avatarAccents`.

---

## 2. Token envanteri

| Küme | Sembol | Durum |
|---|---|---|
| Renk — ham | `MP.Palette` | ✅ gul, hardal, mercan, yeşim, gece, mürekkep, kağıt, **sepya**, **dünya aksanları** |
| Renk — semantik | `MP.C` | ✅ |
| Tipografi | `MP.F` | ✅ display XL–SM, body LG/MD/SM, label, caption, read |
| Glyph ölçeği | `MP.G` | ⚠️ **bu turda eklendi, henüz benimsenmedi** (§5) |
| Boşluk | `MP.S` | ✅ x1–x10 + screenGutter, sectionGap, stackGap, tapMin, tabBarHeight, navBarHeight |
| Yarıçap | `MP.R` | ✅ xs–xxl, pill + semantik card/button/tile/sheet/input |
| Kenar (derinlik) | `MP.E` | ✅ width 3, widthLG 4 |
| Gölge | `MP.Sh` | ✅ soft, card, lifted, sheet, brand + **art**, **knob** |
| Hareket | `MP.M` | ✅ + `MPPressStyle`, reduce-motion farkında |
| Okuma teması | `MP.ReadTheme` | ✅ background, foreground, body, muted, **paper**, **spine** |

### Bu turda eklenen token'lar

Hiçbiri yeni bir renk icat etmez; hepsi kodda zaten dolaşan değerlere ad verir.

| Token | Değer | Neden |
|---|---|---|
| `Palette.sepya50/300/500/700/900` | `F7EFDE` `B49A78` `7A6248` `503A22` `3B2A18` | `ReadTheme` içinde gömülü duruyordu |
| `Palette.gece25` / `gece50` | `E4E9F2` / `C6CFDD` | gece modunun metin mürekkepleri |
| `Palette.deniz400` `fosil400` `lila400` `kahve400` `buz400` `cimen400` `metal400` | — | `World.accent` içinde gömülü duran 7 dünya aksanı |
| `C.avatarAccents` | 6 renk | avatar kümesi üç ayrı yerde kopyalanmıştı |
| `C.edgeCircle` | mürekkep900 @18% | dairesel `mpEdge` karşılığı |
| `C.edgeOnColor` | mürekkep900 @22% | renkli zemin üstündeki kenar (toast) |
| `C.edgeGlass` | mürekkep900 @12% | `.ultraThinMaterial` kenarı |
| `Sh.art` | mürekkep900 @12%, r9 y8 | logo / boş durum illüstrasyonu |
| `Sh.knob` | mürekkep900 @20%, r1.5 y1 | `MPSwitch` topuzu |
| `MP.G` | 12–64 | ikon/emoji boyut ölçeği |

---

## 3. Bileşen envanteri

| Alan | Bileşen | Durum |
|---|---|---|
| Kart | `MPCard` (paper/sunken/brand/night/reward), `MPPressableCard` | ✅ |
| Buton | `MPButton`, `MPIconButton` | ✅ |
| Etiket | `MPChip`, `MPBadge`, `MPStarPill` | ✅ |
| Form | `MPInput`, `MPSwitch`, `MPSegmentedControl`, `MPChoiceTile` | ✅ |
| Navigasyon | `MPTabBar`, `MPNavBar`, `MPStepDots`, `MPSheet` | ✅ |
| Liste | `MPListRow`, `MPRowDivider`, `MPSectionHeader` | ✅ |
| İçerik | `MPStoryCard`, `MPStatCard`, `MPPlanCard`, `MPProgressRing`, `MPAvatar` | ✅ |
| Boş durum | `MPEmptyState` | ✅ (tek tüketici: `LibraryView`, 3 çağrı) |
| Geri bildirim | `MPToast`, `MPToastHost` | ✅ |
| İkon | `MPIcon` + `MPIconMap` (50 Lucide SVG, SF Symbol yedeği) | ✅ |
| **Yükleniyor** | — | ❌ **yok** |
| **Hata** | — | ❌ **yok** |
| Kitap yüzeyi | `ReadTheme.paper` / `.spine` token'ları | ⚠️ token var, bileşen `Screens/StoryReader/ReaderPaper.swift`'te |

### Eksik olanlar

**Yükleniyor durumu yok.** `Screens/StoryGeneratingView.swift` bir *ekrandır*, yeniden
kullanılabilir bir bileşen değil. Onun dışında `ProgressView()` üç dosyada ham hâlde
çağrılıyor (`FalAITestView`, `FirebaseTestView`) — ikisi de test ekranı.
(`TextStoryLibraryView` üçüncü çağrı yeriydi; §6.2 ile silindi.) Yani üretim
akışında merkezi bir yükleme yüzeyi hiç yok.

**Hata durumu yok.** `errorMessage` üç ekranda birbirinden bağımsız çiziliyor
(`DevStoryTestView`, `FalAITestView`, `FirebaseTestView`). Ortak bir `MPErrorState`
tanımlı değil. `MPToast`'ın `.danger` tonu var ama o geçici bildirim içindir,
kalıcı hata yüzeyi değildir.

**Kitap yüzeyi kısmen merkezi.** Renk token'ları (`paper`, `spine`) MPTheme'de ve reader
onları doğru tüketiyor. Yüzeyin kendisi (`ReaderPaper`, `StoryCoverFace`) reader
agent'ının alanında; bu turda okundu, değiştirilmedi.

---

## 4. Ölçüm — bu turun öncesi/sonrası

| Ölçüm | Önce | Sonra |
|---|---|---|
| `Color(hex:)` — DesignSystem dışı | 12 (3 dosya) | **0** |
| `Color(hex:)` — DesignSystem içi, MPTheme dışı | 8 (2 dosya) | **0** |
| `Color(hex:)` — `MP.Palette` dışında herhangi bir yerde | 20 | **0** |
| Avatar renk paleti kopyası | 3 kopya (6/6/**8** renk) | 1 token |
| `.font(.system(...))` | 33 | **5** (§5) |
| Ölü tasarım sistemi dosyası | 3 dosya / 1.399 satır | **0** (§6.1, §6.2) |

`MP.S` dışarıda 128 yerde, `MP.R` 44 yerde kullanılıyor — boşluk ve yarıçap
benimsemesi iyi durumda.

---

## 5. Tipografi: merkezi ölçek var, sorun benimseme

`MP.F` zaten merkezi bir ölçek. Başlangıçtaki 33 `.font(.system(...))` çağrısının
dağılımı ve akıbeti:

| Yer | Adet | Karar |
|---|---|---|
| `Helpers/PremiumComponents.swift` | 21 | ✅ **silindi** — §6.1 |
| `Screens/StoryReader/**` | 3 | reader agent'ının alanı, dokunulmadı |
| `Views/TextStoryViewerView.swift` | 3 | ✅ **silindi** — §6.2 |
| `Views/TextStoryLibraryView.swift` | 2 | ✅ **silindi** — §6.2 |
| `Views/SimpleSubscriptionView.swift` | 2 | canlı ama dosyanın tamamı sistem dışı — §6.3 |
| `Helpers/DeviceHelper.swift` | 1 | ✅ **silindi** (`adaptiveFont`, 0 çağrı) |
| `DesignSystem/MPIcon.swift` | 1 | ✅ **taşındı** |

**Kalan: 5 çağrı** — 3'ü reader alanında, 2'si `SimpleSubscriptionView`'da.

`.system` tamamen yasaklanamaz: SF Symbol'ler sistem fontunun metriklerine bağlıdır,
Baloo veya Nunito ile çizilemezler. Bu yüzden meşru kullanım `MP.F.glyph(_:_:)`
üzerinden geçer — amaç `.system`'i yok etmek değil, **boyutun `MP.G`'den gelmesini**
sağlamak.

**Ölü kodu token'a taşımadım, sildim.** 26/33 çağrı hiçbir ekrana çizilmeyen
dosyalardaydı. Onları migrate etmek ölü kodu canlı gibi gösterir ve gerçek borcu
gizlerdi; doğru hamle silmekti ve bu karar alındı (§6.1, §6.2). `DeviceHelper`
içindeki `adaptiveFont` da aynı gerekçeyle kaldırıldı.

### Açık borç: ikon boyutları

54 `MPIcon` çağrısı **17 ayrı boyut** kullanıyor (20, 22, 16, 26, 18, 17, 15, 14, 13,
34, 24, 19, 76, 52, 38, 28 ve varsayılan). `MP.G` bu boyutları emekliye ayırmak için
eklendi ama çağrılar **taşınmadı**: 17 boyutu 8'e indirmek her ekranda görünür bir
değişiklik demek ve bu turun kuralı "ekran ekran yeniden tasarım yok". Ayrı bir turda,
onay alınarak yapılmalı.

---

## 6. Bulgular

### 6.1 `Helpers/PremiumComponents.swift` — ✅ silindi (874 satır)

**Karar verildi ve uygulandı (2026-09-18):** dosya silindi.

Dosyadaki **13 public tipin hiçbirinin dosya dışında tüketicisi yoktu**:
`GlassCard`, `PremiumCard`, `PremiumButton`, `PremiumBackground`, `AnimatedMeshGradient`,
`PremiumBadge`, `PremiumSectionHeader`, `PremiumEmptyState`, `ShimmerEffect`,
`ReadingSettingsView`, `TextSize`, `ReadingTheme`, `LineSpacingOption`. Silme öncesi
yapılan bağımsız doğrulamada dosyada ayrıca ilk envanterde geçmeyen 5 tip daha
bulundu — `SpringPressStyle`, `ScaleButtonStyle`, `BounceAnimation`, `AppearAnimation`,
`PulsingGlow` — ve onların da dış tüketicisi çıkmadı. `ButtonStyle`'lar özellikle
kontrol edildi, çünkü tasarım sistemi dışında sessizce tüketilmeleri en olası
tiplerdi; `MPPressStyle` zaten bu işi yapıyor.

Bu, MagicPaper'ın **ikinci, paralel ve rakip bir tasarım sistemiydi**. İçeriği CLAUDE.md
İlke 9'un açıkça yasakladığı şeyler: `AnimatedMeshGradient`, `PulsingGlow`, glass
morphism, shimmer. Ayrıca `ReadingTheme` / `TextSize`, `MP.ReadTheme` / `MP.ReadSize`
ile birebir çakışan bir kavram kümesiydi.

`ReadingSettingsView` reader/monetization tarafına lazım olursa: davranışı
`MP.ReadTheme` / `MP.ReadSize` üstüne yeniden yazılmalı, bu dosya geri alınmamalı.
Silinen hâli git geçmişinde duruyor.

### 6.2 Ölü ekranlar: `TextStoryLibraryView`, `TextStoryViewerView` — ✅ silindi

**Karar verildi ve uygulandı (2026-09-18):** ikisi de silindi (244 + 281 = 525 satır).

Kapalı bir ölü küme oluşturuyorlardı: `TextStoryViewerView`'ın tek çağrı yeri
`TextStoryLibraryView`, `TextStoryLibraryView`'ın tek çağrı yeri ise kendi
`#Preview`'ıydı. `TextStoryViewerView` `design: .serif` ile **üçüncü** bir okuyucu
tipografisi taşıyordu.

**Artçı borç:** `Services/TextStoryManager.swift` böylece öksüz kaldı — tek tüketicisi
`TextStoryLibraryView`'dı. `Models/TextStory.swift` ile birlikte ayrı bir turda
gözden geçirilmeli; bu turda dokunulmadı çünkü servis/model katmanı tasarım
sisteminin alanı değil.

### 6.2.1 `Helpers/DeviceHelper.swift` — `adaptiveFont` ✅ silindi

`adaptiveFont(_:weight:)` uzantı metodu 0 çağrı ile duruyordu, kaldırıldı.

**Not:** doğrulama sırasında `DeviceHelper`'ın **tamamının** ölü olduğu görüldü —
`adaptivePadding` ve `minTouchSize` de dahil olmak üzere dosyadaki her referans
dosyanın kendi içinde. Yalnızca istenen `adaptiveFont` kaldırıldı; dosyanın tümüyle
silinmesi ayrı bir karar (§7).

### 6.3 `Views/SimpleSubscriptionView.swift` sistem dışı ama canlı

`PaywallView:85` üzerinden erişilebiliyor. İçinde `MP.` referansı **sıfır**:
`.font(.title2.bold())`, `.font(.body)`, `.font(.caption)`, `Color.gray`,
`.buttonStyle(.borderedProminent)`. İçerik zaten bir RevenueCat yapılandırma hatası
paneli (Türkçe/İngilizce karışık, "Dashboard Setup Gerekli").

2 `.system` çağrısını tek başına taşımadım: dosyanın kalan ~10 tipografi çağrısı sistem
dışı kalacağı için yarı-migrate bir dosya, migrate olmuş gibi görünürdü. Ya bütünüyle
sisteme alınmalı ya da kullanıcıya hiç gösterilmemeli.

### 6.4 Düzeltilen sessiz hata: avatar paletinde 6'ya karşı 8

`MPAvatar` kendi içinde **8 renklik** bir palet tutuyordu; `UserProfile.mpColor` ve
`ProfileCreationView` ise **6 renklik**. Üçü de `sum % count` ile addan renk türetiyor,
dolayısıyla aynı çocuk hangi bileşenin çizdiğine göre farklı renk alabiliyordu — ve
7./8. renk hiçbir zaman kaydedilemiyordu, çünkü saklanan indeks 1–6 aralığında.

Üçü de `MP.C.avatarAccents`'e bağlandı. **Sıra korundu** (doğrulandı): seçim
`UserDefaults`'ta `mp_avatarColor_<uuid>` anahtarıyla *indeks* olarak saklanıyor,
araya renk eklemek kayıtlı profillerin rengini kaydırır. Yeni renk yalnızca sona eklenir.

Üç gerçek `MPAvatar` çağrısının üçü de `color:` parametresini açıkça geçiyor, bu yüzden
8'li yedek palet üretimde zaten hiç çalışmıyordu — düzeltme görsel olarak nötr.

---

## 7. Sonraki tur için sıra

1. ~~**Karar:** `PremiumComponents.swift` + 2 ölü ekran silinsin mi?~~ ✅ **yapıldı**
   (§6.1, §6.2) — 1.399 satır silindi, build doğrulandı.
2. **Yeni:** `DeviceHelper` tamamen ölü — dosya büsbütün silinsin mi? (§6.2.1)
   Beraberinde öksüz kalan `TextStoryManager` + `TextStory` de değerlendirilmeli.
3. `MPLoadingState` ve `MPErrorState` bileşenleri — şu an ikisi de yok.
4. 54 `MPIcon` çağrısını `MP.G` ölçeğine oturt (görsel onay gerekir).
5. `SimpleSubscriptionView` — sisteme al veya kaldır. Kalan 5 `.system` çağrısının
   2'si burada.
6. Erişilebilirlik testi: dynamic type, küçük/büyük ekran. Bu turda **yapılmadı**;
   değişiklikler token adlandırmasıydı, yeni yerleşim üretilmedi.
