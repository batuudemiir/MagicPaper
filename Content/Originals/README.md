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

1. Bildirim gelince `drafts/<slug>/review.md`'yi ve `tale.json`'u okuyun, `cover.jpg`'ye bakın.
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

Kapak: ajan (Claude) SVG çizer ya da Batuhan ChatGPT'den getirir (COVER_GUIDE.md): `drafts/<slug>/cover.svg` → `python3 Tools/render_cover.py <slug>` → `cover.jpg`.
Görsel üretim servisi kullanılmaz. Kılavuz: `COVER_GUIDE.md`. Kapağı beğenmezseniz `review.md` Notlar'a yazın.
