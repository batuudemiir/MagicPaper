# MagicPaper Original

Masallar sekmesindeki "MagicPaper Original" rafının kaynağı. Tasarım:
`docs/superpowers/specs/2026-11-12-magicpaper-original-design.md`.

## Klasörler

| Yer | Ne |
|---|---|
| `WORLD.md` | Dünya kitabı: mekân, karakterler (`## Karakterler` altında her biri `### Ad`), ton, `## Kapak stili`. Ajan her turda önce bunu okur |
| `world-proposals.md` | Yalnız ilk tur: ajanın üç dünya önerisi |
| `drafts/<slug>/` | Onay bekleyen masal: `tale.json`, `cover.jpg`, `review.md` |
| `published/<slug>/` | Onaylanmış masal: `tale.json`, `cover.jpg` |

## Batuhan'ın işi

1. Bildirim gelince `drafts/<slug>/review.md`'yi ve `tale.json`'u okuyun.
   Kapak: `review.md`'deki "Kapak promptu (ChatGPT)" bloğunu ChatGPT'ye yapıştırın, referans kapağı
   (`published/saatin-icindeki-ninni/cover.jpg`) ekleyin. Gelen görseli yerleştirin:
   ```bash
   python3 Tools/place_cover.py <slug> ~/Downloads/<görsel>
   ```
2. Beğendiyseniz (karar: 13 Kasım 2026, şimdilik uzaktan akış yok, masallar uygulamayla gelir):
   ```bash
   cd Scripts/ContentPublisher
   swift run --scratch-path "$TMPDIR/mp-publisher-build" content-publisher originals approve <slug>
   cd ../..
   python3 Scripts/ClassicsCatalog/build_classics_catalog.py
   ```
   Derleyici masalı `classics_catalog.json`'a, kapağı `Assets.xcassets/Originals/`'a ekler. Masal bir sonraki
   uygulama sürümüyle gelir. `Content/Originals/published/<slug>`, katalog ve asset değişikliklerini commit'leyin.
3. Beğenmediyseniz `review.md`'nin en altındaki `## Notlar`'a yazın. Ajan sonraki turda önce onu düzeltir.
4. Hiç istemiyorsanız klasörü silin.

Denetim her zaman: `swift run content-publisher originals check [<slug>]`.

## Uzaktan akış (şimdilik kapalı)

Uzaktan yol (`content-publisher publish --deploy`, imzalı `feed.json`) kodda hazır ama kullanılmıyor: uygulamanın
içerik adresi (`magicpaper-393a7.web.app`) ile Firebase sitesi (`magicpaper-393a7-f2d31`) uyuşmuyor ve uzaktan sistem
şimdilik kurulmayacak. Açılırsa aynı masal hem katalogda hem akışta olsa da rafta bir kez görünür.

Kapak: ajan prompt yazar, görseli Batuhan ChatGPT'de üretir (karar: 16 Kasım 2026). Ayrıntı: `COVER_GUIDE.md`.

## Sayfa çizimleri (20 Kasım 2026)

Her metin sayfasına bir sabit çizim eşlenir; kişiselleştirme ve uzak görsel isteği yoktur.
Kaynaklar `published/<slug>/illustrations/page-01.jpg` … `page-07.jpg`; sıra, Türkçe görsel
açıklaması ve tam hazırlama promptu aynı klasördeki `illustrations.json` dosyasındadır:

```json
{
  "pages": [
    {"page": 1, "file": "page-01.jpg", "altText": "Saatin içindeki iki fare.", "prompt": "..."}
  ]
}
```

Sayfa sayısı metinle eşleşmeli; eksik sıra, boş açıklama, yanlış dosya adı ya da JPEG olmayan
kaynak derlemeyi durdurur. Manifesti olmayan eski masallar görselsiz çalışır.
`python3 Scripts/ClassicsCatalog/build_classics_catalog.py` çizimleri
`Assets.xcassets/Originals/original-<slug>-page-NN.imageset` içine kopyalar ve katalogdaki
`soft.illustrations` alanına asset adı ile açıklamayı yazar. Okuyucu mevcut sahne düzenini kullanır;
varlık yüklenemezse metin görünür kalır. Çizim dili `WORLD.md` son bölümündedir; mor zorunlu ana renk değildir.
Kapak promptları `cover-prompt.json` içinde, kullanılan araç built-in `image_gen`’dir.
