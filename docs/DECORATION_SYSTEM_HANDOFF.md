# Storybook Decoration System — Devam Notu

**Tarih:** 2026-09-16 · **Durum:** derleniyor, 42 test geçiyor, simülatöre kurulu

---

## Nerede kaldık

### Biten

**Varlık kütüphanesi**
- `Tools/make_decorations.py` — 26 varlık üretir (PNG, şeffaf, şablon olarak boyanabilir)
- `Tools/sync_decorations.py` — onaylıları `Assets.xcassets/Storybook/`'a taşır + Swift katalog üretir
- `AssetCatalog/assets.json` — 26 kayıt: **12 onaylı, 5 incelemede, 9 elenen** (gerekçeleriyle)
- `AssetCatalog/external_candidates.json` — 17 Wikimedia dosyası, lisansı API'den doğrulanmış
- `AssetCatalog/LICENSES.md` — neyin neden kullanılmadığı dâhil
- `Assets/Storybook/SourceOriginals/` — indirilen kamu malı orijinaller korunuyor

**Sistem kodu** (`MagicPaper/Screens/StoryReader/`)
- `StoryDecorationTaxonomy.swift` — kategori, tür, bölge, ruh hâli, vakit, yoğunluk
- `StoryEnvironment.swift` — iki kademeli ortam çıkarımı (sahne → dünya)
- `StoryDecorationCatalog.swift` + `+Generated.swift` — varlık dizini
- `StoryDecorationEngine.swift` — semantik süzme → skorlama → güvenli bölge → yoğunluk → yerleştirme, **belirleyici** (SplitMix64, tohum = masal id + sayfa no)
- `StoryPageDecorationLayer.swift` — çizim + geliştirici debug katmanı
- `StoryPageView` / `StoryLeafView` — bağlandı

### Bitmeyen

| İş | Not |
|---|---|
| **Geliştirici galerisi** (§30) | Hiç yazılmadı. Kürasyon için en çok işe yarayacak parça |
| **4 demo sayfa** (§32) | Yazılmadı |
| **Magic / Space kategorileri** | Onaylı varlık **sıfır** — prosedürel üretim bu ikisinde çuvalladı |
| **Yoğunluk her sayfada `.normal`** | `StoryLeafView.decorationContext` sabit veriyor; §18'in sayfa kişiliği için değişmeli |
| **Mood ve timeOfDay** | `nil` / `.day` sabit. Motor taşımıyor (`ComposedPage.emotion` mapper'da düşüyor) |
| **Animasyon** (§25) | Yok. Kıvrım sırasında donacağı için bilinçli ertelendi |
| **Güvenli bölgeler kaba** | Normalize sabit dikdörtgen; gerçek metin çerçevesinden ölçülmüyor |
| `ReaderPageOrnament` (sade/versal/çerçeve/spot) | Yeni sistemle çakışıyor; `spot` ve `cerceve` muhtemelen kalkmalı |

---

## Cihazda nasıl görülür

Uygulama kurulu ve kapaktan açılacak şekilde hazırlandı.
Kütüphane → masal → **Oku** → kapak → sağdan sola çevir.

Süsler metin sayfalarında kâğıdın üstünde, metnin altında çıkar.
`ReaderPageOrnament` `"sade"`ye alındı, yani gördüğün şey **yeni sistem**.

**Debug katmanı:** `StoryPageView(... showsDecorationDebug: true)` — güvenli
bölgeleri, çapaları ve varlık kimliklerini çizer.

---

## İlk bakılacak şey

Süslemenin gerçekten kitap gibi durup durmadığı. Eğer "yapıştırılmış sticker"
gibi duruyorsa sırasıyla şunlara bakılmalı:

1. Opaklık fazla mı (`StoryDecorationEngine.place`)
2. Ölçek fazla mı (`base = 0.16 + visualWeight * 0.20`)
3. Taşma yeterli mi (`DecorationZone.bleed`) — motif sayfa dışına devam ediyor
   gibi durmalı, ortada yüzmemeli

---

## Bilinen ve **düzeltilmemiş** motor kusuru

`OfflineStoryMapper.theme(for:)` deniz/orman/uzay dışındaki her ayarı
`.custom`'a düşürüyor → `MP.World.dinozor`. Ortam çıkarımının ikinci kademesi
bu yüzden çoğu masalda içerikle ilgisiz. Birinci kademe (sahne metni) bunu
büyük ölçüde telafi ediyor ama kalıcı çözüm eşlemenin düzeltilmesi.

---

## Cihazda ilk gözlem (2026-09-16, akşam)

Sistem çalışıyor. Ekran görüntüsünde: sol/alt kenardan giren deniz yosunu
sayfa dışına taşıyor, üstte dalga izi, metne hiçbir şey değmiyor.

**Düzeltildi:** üst bölge çapaları 0.07–0.10'dan 0.17'ye indirildi; süs kapat
düğmesiyle aynı hizaya düşüyordu.

**Düzeltilmedi — asıl darboğaz:** sayfa başına 4–7 süs isteniyor ama gerçekte
2 çıkıyor. Motor doğru çalışıyor; **kütüphane çok ince.** Ortam başına onaylı
varlık sayısı 4–7'yi besleyemiyor. Bir sonraki iş, varlık üretimi:

- `magic` ve `space`: sıfır onaylı varlık
- `ocean`, `bedtime`, `adventure`: ortam başına 2–3
- Prosedürel üretim organik çizgi formlarında çalışıyor, tanınması gereken
  nesnelerde ve parçacıklarda çalışmıyor — o kategoriler gerçek illüstrasyon
  ya da ana illüstrasyonu üreten AI hattı ile doldurulmalı
