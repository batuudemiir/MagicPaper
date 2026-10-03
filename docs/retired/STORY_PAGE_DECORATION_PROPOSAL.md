# Dekoratif Masal Sayfası — Denetim ve Öneri

**Tarih:** 2026-09-16
**Durum:** Faz 1 (denetim) + Faz 2 (öneri). Kod yazılmadı.
**Kapsam:** yalnızca okuma deneyimi. Uygulamanın geri kalanı yeniden tasarlanmıyor.

---

## FAZ 1 — Bugün ne var

### 1.1 Okuyucu mimarisi

`MagicPaper/Screens/StoryReader/` altında 14 dosya (bu oturumda kuruldu):

```
StoryReaderView            SwiftUI · durum, kontroller, erişilebilirlik
  └── StoryReaderContainer UIViewControllerRepresentable
        └── UIPageViewController(.pageCurl)
              └── StoryPageHostController (UIHostingController)
                    └── StoryLeafView
                          ├── StoryCoverLeaf
                          ├── StoryPageView
                          └── StoryEndingLeaf
```

Yapraklar: `[kapak] + sayfalar + [kapanış]`. Kapak sayfa değildir; künye kapaktan
sonra "1 / 8" diye başlar.

### 1.2 Sayfada bugün ne çiziliyor

| Katman | Dosya | Durum |
|---|---|---|
| Kâğıt | `ReaderPaper.swift` | Düz sıcak renk + süreç başına bir kez üretilen 64×64 statik doku (opaklık 0.035) + 14pt cilt payı gradyanı |
| Çizim | `StoryPageView` + `ReaderImageLoader` | `actor` + `NSCache` + `CGImageSource` ile küçültme, ana iş parçacığı dışında |
| Metin | `StoryPageView.textColumn` | Paragraflara bölünmüş, `MP.F.read`, satır yüksekliği 1.72, ölçü sınırı `punto × 30`, taşınca kaydırılır |
| Süsleme | `ReaderPageOrnament.swift` | **Zaten var**: `sade / versal / cerceve / spot`. `UserDefaults["mp_readerOrnament"]`'tan okunuyor, arayüzde yok |
| Künye | `StoryPageView.folioLine` | Kontroller görünürken, `MP.F.caption()`, opaklık 0.75 |

### 1.3 Süsleme için kullanılabilir malzeme — **ve asıl kısıt**

Brief şunu açıkça yasaklıyor: *"Avoid generic SF Symbols or basic geometric UI
icons… Do NOT make decorations look like app icons, emojis, generic vector
stickers."* İstenen dil: *hand-drawn, watercolor / gouache / colored pencil
inspired, slightly imperfect.*

Elde olan:

- **51 Lucide SVG** (`Assets.xcassets/Icons/`). `MPIcon.swift`'in kendi başlığı
  ne olduklarını söylüyor: *"2px kontur, geometrik, yuvarlak uç"*, ve
  `template-rendering-intent: template` — yani tek renk, konturlu, geometrik.
  **Bu, brief'in tarif ettiği şeyin tam tersi.**
- **Sıfır illüstre dekoratif varlık.** Uygulamadaki tek gerçek illüstrasyon,
  bugün eklenen kapak JPEG'i.

**Bunu en başa koyuyorum çünkü dekorasyonun kalite tavanını kod değil varlıklar
belirliyor.** Mimariyi, anlamsal seçimi, yoğunluğu, yerleşimi kodla kurabilirim;
"suluboya yaprak"ı kodla çizemem. §4'te üç seçenek sunuyorum.

### 1.4 Ortam sinyali var, ruh hâli yok

**Ortam (environment) — var ama kaba:**

`MP.World` 12 dünya tanımlıyor (`orman`, `deniz`, `uzay`, `peri`, `kar`, …) ve
`MP.World.from(theme:)` ile `StoryTheme`'den türüyor. Ama `StoryTheme`'i üreten
yer `OfflineStoryMapper.theme(for:)` ve şunu yapıyor:

```swift
if tags ∩ ["sea","water","ocean"]      → .underwater
if tags ∩ ["forest","jungle","garden"] → .jungle
if tags ∩ ["space","sky","moon"]       → .space
else                                    → .custom     // → MP.World.dinozor
```

Yani motorun ürettiği masalların büyük kısmı `.custom`'a düşüyor ve dünya
"dinozor" oluyor — içeriğiyle ilgisiz bir pençe izi ve kahverengi. **Masala
duyarlı dekorasyon bu eşlemenin üstüne kurulursa çoğu masal yanlış dekorasyon
alır.**

**Sayfa başına ortam — aslında var, kullanılmıyor:**

`ComposedPage.visualScene` → `StoryPage.imagePrompt` olarak uygulamaya *geliyor*
(`OfflineStoryMapper.swift`). İçeriği İngilizce sahne yönergesi: *"child pausing
mid-step at the edge of the place, something faint further in"*. Hiçbir yerde
okunmuyor. Sayfa başına ortam çıkarmak için gerçek bir sinyal.

**Ruh hâli (mood) — yok.** Motorda `ComposedPage.emotion` var ama
`OfflineStoryMapper` onu uygulama modeline taşımıyor. Sayfa başına mood istiyorsak
mapper'ı genişletmek gerekir — bu, okuyucu işi değil, motor sınırı işi.

### 1.5 Sayfa kıvrımının dayattığı iki kısıt

Bunlar tasarım tercihi değil, `.pageCurl` kullanmanın bedeli:

1. **Yaprak opak ve baştan başa olmak zorunda.** Kıvrım sayfanın *arkasını*
   gösterir. Dolayısıyla brief'teki *"illustration extending beyond its
   container", "clouds extending outside page boundaries"* **sayfa sınırı için
   mümkün değil** — sayfanın kendisi sınırdır. Kutu *içinde* taşma (çizimin
   metin alanına girmesi) mümkün; sayfa *dışına* taşma değil.
2. **Çevirme sırasında görüntü kopyalanır.** Sürekli animasyon (ateşböceği
   sürüklenmesi) çevirme boyunca donar ya da yırtılır. Üçüncü katman animasyonu
   geçiş sırasında durdurulmalı.

---

## FAZ 2 — Öneri

### 2.1 Kompozisyon

Brief'teki yapıyı aynen almıyorum, çünkü bir kusuru var: metin sayfası ile
çizimli sayfa farklı kompozisyon ister. Önerim iki şablon:

**A — Çizimli sayfa**
```
üst kenar boşluğu           köşe süsü (hafif)
ÇİZİM                       kullanılabilir yüksekliğin %50'si
ince ayırıcı                küçük, isteğe bağlı
METİN                       ölçü sınırlı, sola hizalı
alt köşe süsü               künye ile aynı bantta
```

**B — Metin sayfası** (ürünün bugünkü yaygın hâli)
```
üst köşe süsü
METİN                       optik ortada
alt köşe süsü
künye
```

Metin sayfasında boşluk *kusur değil*; dekorasyonun görevi o boşluğu doldurmak
değil, ona kenar vermek.

### 2.2 Dekorasyon sistemi

```
StoryPageDecorations              hangi süsler, nerede, ne yoğunlukta
  ├── DecorationVocabulary        ortam → süs dağarcığı
  ├── DecorationDensity           sparse / normal / rich
  ├── DecorationPlacement         köşeler, kenarlar, deterministik dağılım
  └── StoryDecorationMark         tek bir süsün çizimi
```

**Yerleşim rastgele değil, deterministik olacak.** Tohum = `story.id` +
`page.index`. Sebep: aynı sayfa her açılışta aynı görünmeli. Rastgele yerleşim,
aynı masalı ikinci kez açan çocuğa farklı bir sayfa gösterir ve kitap olmaktan
çıkar. Aynı tohum, sayfadan sayfaya farklı kompozisyon da verir — brief'in
istediği "her sayfa biraz farklı" bu şekilde, elle sayfa sayfa tasarlamadan
çıkar.

### 2.3 Ortam ve ruh hâli — nereden gelecek

Üç kademeli, her kademe bir öncekine düşer:

1. **Sayfa başına:** `imagePrompt` (`visualScene`) içinde anahtar kelime taraması
   — `forest/tree/leaf`, `sea/water/wave`, `sky/star/moon`, `door/path/bridge`.
   Zaten gelen ve kullanılmayan sinyal.
2. **Masal başına:** `MP.World` (`story.mpWorld`).
3. **Düşüş:** nötr dağarcık (nokta, kıvılcım, ince çizgi) — dünyaya bağlı değil.

**Ve §1.4'teki kusuru ayrıca bildiriyorum:** `OfflineStoryMapper.theme(for:)`
çoğu masalı `.custom` → `dinozor` yapıyor. Dekorasyon bunun üstüne kurulmadan
önce o eşlemenin düzeltilmesi gerekir; yoksa orman masalı pençe izi alır. Bu
motor tarafı bir düzeltme, okuyucu tarafı değil — ayrı bir iş olarak öneriyorum.

**Mood'u MVP'ye almıyorum.** Mapper'ı genişletmeden uydurulacak her mood
yanlış olur; ortam tek başına anlamlı dekorasyon için yeterli.

### 2.4 Varlık stratejisi — **karar vermen gereken yer**

| Seçenek | Ne verir | Maliyet |
|---|---|---|
| **A. Lucide ikonları** | Hemen çalışır | Brief'in açıkça yasakladığı şey. Konturlu, geometrik, tek renk — uygulama ikonu gibi durur. **Önermiyorum.** |
| **B. Kodla çizilmiş organik şekiller** | Lucide'den belirgin şekilde iyi: dolgu siluet, hafif asimetri, yumuşak kenar, çok tonlu. Varlık beklemez, sıfır indirme boyutu, her renkte | Suluboya değil. "Elle çizilmiş his" verir, gerçek illüstrasyon vermez |
| **C. Gerçek illüstre varlıklar** | Brief'in istediği kalite | Sende çizim/üretim gerektirir. ~20-30 mark (yaprak, mantar, dalga, yıldız, bulut…), tercihen SVG |

**Önerim: B ile mimariyi kur, C'ye geçiş dikişini hazır bırak.**
`StoryDecorationMark` bir çizim protokolü olur; kodla çizilmiş uygulaması bugün
çalışır, varlık geldiğinde aynı isimlerle değiştirilir. Kompozisyon, yoğunluk,
yerleşim ve erişilebilirlik kodu hiç değişmez.

C'yi seçersen dağarcık listesini ve boyut/format şartnamesini çıkarırım.

### 2.5 Tipografi

**Değiştirmiyorum.** `MP.F.read` + 1.72 satır yüksekliği + `punto × 30` ölçü
sınırı + paragraf ayrımı zaten çocuk yayıncılığı düzeni. Brief "do not introduce
random fonts" diyor; mevcut sistem Baloo 2 + Nunito ve yeterli.

Tek ekleme önerisi: **diyalog için ayrı bir işlem yok** (§15 zaten balon
yasaklıyor), ama diyalog paragrafına küçük bir sol girinti denenebilir — bu
tipografi, süsleme değil.

### 2.6 Çizim entegrasyonu

Bugün çizim `scaledToFit` + `MP.R.sm` köşe. Öneri:
- Köşeyi organik yapmak için hafif düzensiz bir maske (tam simetrik yuvarlak
  dikdörtgen yerine).
- **Bir-iki süsün çizimin kenarına binmesi** — brief'in istediği "kompozisyon,
  görsel + kart değil" hissi asıl buradan gelir ve sayfa sınırına dokunmadığı
  için kıvrımla sorun çıkarmaz.

### 2.7 Renk

Yeni palet yok. Süsler `MP.World.accent` ve kâğıt tonlarından (`kagit300-500`,
`murekkep300`) türetilir, opaklık 0.15–0.35 arasında. Sebep: sistemde 12 dünya
aksanı zaten "basılı" tonlarda (neon yok) ve ikinci bir palet açmak §23'ün
yasakladığı ikinci görsel dil olur.

### 2.8 Animasyon

**Üçüncü katman animasyonu MVP'de yok.** Gerekçe §1.5-2: çevirme sırasında
görüntü kopyalandığı için animasyon donuyor, ve §19 sürekli efektleri yasaklıyor.
Sonraki adımda, yalnızca çevirme bittiğinde ve yalnızca görünen yaprakta çalışan,
çok yavaş (8-12 sn döngü) bir parıltı denenebilir. Reduce Motion'da tamamen
kapalı.

### 2.9 Token'lar

Yeni `MP` token'ı açmıyorum; dekorasyona özel ölçüler `StoryPageDecorations`
içinde tek yerde toplanır (opaklık aralığı, ölçek aralığı, kenar payı, yoğunluk
sayıları). Sebep: bunlar tasarım sistemi geneli değil, tek ekranın iç ayarları.

### 2.10 Erişilebilirlik ve performans

- Bütün süsler `.accessibilityHidden(true)` — zaten `ReaderPageOrnament`'ta böyle.
- **Dynamic Type büyüdükçe yoğunluk düşer**: AX1'de `normal` → `sparse`, AX3'te
  süsler tamamen kalkar. Metin her zaman kazanır.
- Kodla çizilen şekiller `Path`/`Shape` — görüntü yüklemesi yok, önbellek yok,
  sayfa başına ek bellek yok.

---

## Ne öneriyorum, hangi sırayla

1. **Önce motor kusuru:** `OfflineStoryMapper.theme(for:)` çoğu masalı
   `dinozor`a düşürüyor. Bu düzelmeden masala duyarlı dekorasyon yanlış çalışır.
2. `StoryPageDecorations` mimarisi + kodla çizilmiş dağarcık (Seçenek B).
3. Dört ortam dikey kesiti: orman / deniz / uzay / gece.
4. Cihazda bakıp yoğunluğu kısmak.

Mevcut `ReaderPageOrnament` (`sade/versal/cerceve/spot`) bu sisteme dâhil edilir:
`spot` bu dağarcığın en seyrek hâli, `versal` tipografi tarafı, `cerceve`
muhtemelen düşer (§1.3'teki sertifika hissi).

**Kod yazmadan önce iki cevaba ihtiyacım var:** varlık yolu (A/B/C) ve motor
eşlemesinin bu işe dâhil olup olmayacağı.
