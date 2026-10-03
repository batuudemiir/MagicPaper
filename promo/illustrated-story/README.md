# MagicPaper — "Görselli Hikaye" piksel tanıtım videosu

1080×1920, 30 fps, H.264 · 37,5 sn · TR ve EN.

- `out/magicpaper_gorselli-hikaye_tr.mp4`
- `out/magicpaper_gorselli-hikaye_en.mp4`

Uygulama ekranlarını birebir kopyalamaz. Akışı ve duyguyu anlatan bir masal kurgusudur:

1. **Yatak odası (0–3 sn):** masal saati, ebeveyn yatağın kenarında.
2. **Oluşturma (3–15,9 sn):** 3 adım (fotoğraf → isim → tema), ardından "Hikaye Oluştur",
   7 sayfanın tek tek çizilmesi ve "Kitabın Hazır!" bildirimi.
3. **Okuma (15,9–31,9 sn):** kağıt çerçeveli 5 örnek sayfa (1, 2, 3, 5, 7 / 7), sayfa çevirme
   geçişleriyle.
4. **Uyku (31,9–34,6 sn):** ebeveyn gitmiş, lamba söner, zemine ay ışığı düşer.
5. **Kapanış kartı** ve siyaha kararma.

Masal sayfaları örnektir. Uygulamada hikayeyi yapay zeka yazar. Sayfalar,
`Services/AIService.swift` içindeki "SPACE ADVENTURE STRUCTURE" planını izler: bahçede roket,
kalkış, uzaylı dost, fırtına, eve dönüş.

Telefondaki etiketlerin kaynağı: `Helpers/Localization.swift`, `Services/LocalizationManager.swift`
(`childPhoto`, `photoDescription`, `name`, `childName`), `Models/Story.swift` (tema adları).
Bildirim metninin kaynağı: `Services/StoryGenerationManager.swift` (emoji çıkarıldı).

## Yeniden üretme

`../text-story/README.md` ile aynıdır: fontu `fonts/` klasörüne indirin, sonra şunları çalıştırın:

```sh
node render.js tr 1.4,4,7.8,13.2,15.2,18.5,24.5,30.5,33.8   # önizleme → out/preview/
node render.js tr    # → out/magicpaper_gorselli-hikaye_tr.mp4
node render.js en
```

Çizim altyapısı (ızgara, katmanlar, gökyüzü/şehir, el imleci, logo) `../text-story/index.html`
ile aynıdır ve bu dosyaya kopyalanmıştır. Her `index.html` tek başına çalışır.
