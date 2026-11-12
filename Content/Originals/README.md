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
2. Beğendiyseniz:
   ```bash
   cd Scripts/ContentPublisher
   swift run content-publisher originals approve <slug>
   swift run content-publisher publish --deploy
   ```
   Ardından `Content/Originals/published/<slug>` ve `hosting/public/content/` değişikliklerini commit'leyin.
3. Beğenmediyseniz `review.md`'nin en altındaki `## Notlar`'a yazın. Ajan sonraki turda önce onu düzeltir.
4. Hiç istemiyorsanız klasörü silin.

Denetim her zaman: `swift run content-publisher originals check [<slug>]`.

## Rafın görünmesi için

- Uygulamanın `Info.plist`'inde `MPContentBaseURL` ve `MPContentSigningKey` dolu olmalı; boşsa raf hiç görünmez.
- `~/.magicpaper/content-signing.key`'in açık yarısı (`swift run content-publisher public-key`) `Info.plist`'teki
  anahtarla aynı olmalı; değilse cihaz akışı reddeder.
- Original rafını taşıyan uygulama sürümü yayımlanmış olmalı. Eski sürümler `originals`'ı yok sayar.

Kapağı ajan çizer: `python3 Tools/originals_cover.py <slug>` (anahtar `Secrets.xcconfig`'teki `GEMINI_API_KEY`).
