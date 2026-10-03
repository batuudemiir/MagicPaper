# Gece sanat seti — pilot

**Tarih:** 2026-09-30 · **Durum:** altyapı hazır, görseller bekleniyor

Referans uygulamaların (Orely, Kidory, StoryNest) görsel yoğunluğunu MagicPaper'a
getirmenin ilk adımı. Yöntem **karışık**: stili bir illüstratör kurar, varyasyonlar
o stile kilitli AI üretimiyle çoğaltılır, her görsel elle elenir.

Masal başına görsel üretimi **yok**. Set bir kez üretilir, uygulamaya gömülür.

---

## 1. Set neye bağlanır

"Gece" bir `MP.World` değil. `StoryMode.bedtime`'a (Uyku Zamanı) bağlanır, yani
her dünyadaki uyku masalı bu seti alır. Mod dünyadan önce gelir: ormanda geçen
bir uyku masalı orman gibi değil, gece gibi görünür.

| Parça | Dosya |
|---|---|
| Manifest (içerik) | `MagicPaper/Screens/ArtKit/art_kits.json` |
| Model, katalog, masal → set | `MagicPaper/Screens/ArtKit/StoryArtKit.swift` |
| Tam genişlik sahne + başlık bileşeni | `MagicPaper/DesignSystem/MPArtHero.swift` |
| Görsel üstü metin token'ları | `MP.C.textOnArt`, `textOnArtMuted`, `surfaceNight`, `MP.Scrim` |
| Varlıkların yeri | `Assets.xcassets/ArtKit/` (namespace: `ArtKit/...`) |
| Testler | `MagicPaperTests/StoryArtKitTests.swift` |

Görsel yoksa bileşen setin yer tutucu motiflerine düşer (`Storybook/bedtime_*`).
Varlık kataloğa eklendiği anda kod değişmeden gerçek görsel çizilir.

---

## 2. Teslim listesi

| Varlık adı | Rol | Oran | Sessiz bant | Nerede görünür |
|---|---|---|---|---|
| `artkit_gece_hero_01` | hero | 3:4 | alt %38 | Masal detayının başı, başlık üstünde |
| `artkit_gece_cover_01` | cover | 3:4 | x .06 · y .76 · w .88 · h .20 | Raf ve okuyucu kapağı (başlık resmin altında) |
| `artkit_gece_spot_window_01` | spot | 1:1, şeffaf | — | Sayfa başı sahnesi |
| `artkit_gece_spot_lantern_01` | spot | 1:1, şeffaf | — | Sayfa başı sahnesi |
| `artkit_gece_spot_companion_01` | spot | 1:1, şeffaf | — | Sayfa başı sahnesi |
| `artkit_gece_spot_stars_01` | spot | 1:1, şeffaf | — | Sayfa başı sahnesi |

**Teknik şartlar**
- Hero ve kapak: en az 1536 × 2048 px, sRGB, PNG. Kalite kaybı yoksa HEIC de olur.
- Spot'lar: 1024 × 1024 px, şeffaf PNG, kenarda en az %8 boşluk.
- Dosya `Assets.xcassets/ArtKit/<ad>.imageset/` içine konur.
- **Sessiz bant:** detaysız, yüzsüz, düşük kontrastlı. Başlık ya da kırpma buraya
  gelir. Bu bantta karakter yüzü, el ya da odak nesnesi olmaz.

---

## 3. Stil kitabı (illüstratör kurar, AI buna kilitlenir)

Temel stil zaten VisualSystem'de tanımlı. Yeni bir stil icat edilmez, bu stil
somutlaştırılır:

- **Stil:** `storybook_painted_v1`. Elle boyanmış çocuk kitabı, guaj ve kuru boya
  dokusu, görünür kâğıt grenı, yumuşak yuvarlak formlar.
- **Palet:** `night_calm`. Derin çivit gökyüzü, ay ışığı mavileri, küçük sıcak
  lamba ışığı. Baskın renkler `26385C 9BAAC6 E0A32E 0B1322`, `MP.Palette.gece*`
  ile aynı aile.
- **Işık:** yumuşak, dağınık, düşük kontrastlı gölge. Sıcak tek ışık kaynağı
  (fener, pencere, ay) sahnenin duygusal merkezidir.

**İllüstratörün ilk teslimi:** hero + kapak + bir spot, ayrıca **stil sayfası**
(renk kartelası, fırça/doku örneği, çizgi kalınlığı, bir nesnenin üç ölçekte
çizimi). AI varyasyonları bu stil sayfasına referansla üretilir.

**Kaçınılacaklar** (CLAUDE.md §9 ve katalogdaki `forbiddenClauses`):
- 3D, Pixar görünümü, parlak ve plastik yüzeyler
- neon, gökkuşağı gradientleri, doygun elektrik moru
- resim içinde yazı, harf, rakam, imza, filigran
- korkutucu karanlık: gece **güvenli ve sıcak**, tehditkâr değil
- jenerik "AI masal" görünümü: aşırı detay, parıltı yağmuru, simetrik poz

---

## 4. AI varyasyon hattı

1. **Referans.** İllüstratörün stil sayfası ve onaylı hero'su görsel referans
   olarak verilir (image reference / style reference).
2. **Prompt.** Katalogdan derlenir, elle yazılmaz:
   `mediumClauses` + `lightingClauses` + `night_calm.paletteClauses` + slotun
   `brief`'i (manifestte) + sessiz bant tarifi. Negatifler: `forbiddenClauses` +
   `globalNegativeClauses`.
3. **Eleme.** Her aday için stil sayfasına uyum, sessiz bandın boş olması, gece
   güvenli mi, çocuk yüzü yok mu (pilotta sahneler çocuksuz). Onaylanmayan
   görsel repo'ya girmez.
4. **Kayıt.** Onaylanan görselin kaynağı ve lisansı `AssetCatalog/LICENSES.md`
   biçiminde kaydedilir (süs sisteminde olduğu gibi).

Çocuk pilotta sahnede yok. Kişiselleştirme arayüzden gelir: başlık, "… için"
künyesi, sonra avatar. Çocuğun sahneye girmesi Character Bible ile, görselli
masal açıldığında gelir.

---

## 5. Görsel üstü metin kuralı

Design law'daki gradient istisnası yalnızca `MP.Scrim` içindir ve yalnızca
`MPArtHero` kullanır. Karartma metin bloğuna bağlıdır, kadraja değil: Dynamic Type
büyüdükçe koyu bölge de büyür. `StoryArtKitTests`, `textOnArt` ve
`textOnArtMuted` token'larının bembeyaz bir resim üstünde bile ≥ 4.5:1 kaldığını
ölçer.

---

## 6. Bu turda yapılmayanlar

- Masal detay ekranı kurulmadı; o ekranı İrem tasarlıyor. `MPArtHero` bileşeni
  ve önizlemesi hazır, ekran tasarımı gelince bağlanacak.
- Kapak (`StoryCover`) henüz sanat setini okumuyor. Kapak görseli teslim
  edilince `mpDefaultCoverAsset` ile tek satırlık bir bağlantı gerekiyor.
- Spot'ların sayfaya yerleşimi süs motoruyla (`StoryDecorationEngine`)
  çakışmamalı. Bu, ilk spot geldiğinde okuyucu ajanıyla karara bağlanacak.
- Uyku modu şu an geçici olarak `charge` ailesine bağlı (`STORY_MODE.md`). Set
  bundan etkilenmez, mod'a bağlıdır.
