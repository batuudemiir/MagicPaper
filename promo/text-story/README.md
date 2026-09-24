# MagicPaper — "Metin Hikaye" piksel tanıtım videosu

1080×1920, 30 fps, H.264 · 24 sn · TR ve EN.

- `out/magicpaper_metin-hikaye_tr.mp4`
- `out/magicpaper_metin-hikaye_en.mp4`

Sahne `index.html` içinde 180×320'lik bir canvas'a çizilir ve 6 kat büyütülür. Yazılar
Pixelify Sans ile aynı 6 px ızgarada basılır. `draw(t)` deterministiktir. Zamanlama `K`
nesnesinde, metinler `STR` tablosunda.

## Yeniden üretme

Gerekenler: Node 18+, Playwright (Chromium ile), ffmpeg (ya da `pip install imageio-ffmpeg`).

```sh
cd promo/text-story

# 1) Font (repoya girmez)
mkdir -p fonts && cd fonts
npm pack @fontsource/pixelify-sans
tar xzf fontsource-pixelify-sans-*.tgz
cp package/files/pixelify-sans-latin{,-ext}-{400,700}-normal.woff2 .
rm -rf package fontsource-pixelify-sans-*.tgz
cd ..

# 2) Önizleme kareleri (saniye listesi) → out/preview/
node render.js tr 2,5.5,9,12.9,15.5,19.5,22.8

# 3) Tam video
node render.js tr      # → out/magicpaper_metin-hikaye_tr.mp4
node render.js en      # → out/magicpaper_metin-hikaye_en.mp4
```

Tarayıcıda izlemek için klasörü bir HTTP sunucusundan açın:
`python3 -m http.server` → `http://localhost:8000/?lang=tr&play=1`.

ffmpeg PATH'te değilse `render.js` önce `imageio_ffmpeg`'i dener; ikisi de yoksa
`FFMPEG=/yol/ffmpeg node render.js tr` kullanın.

## Kaynak eşlemesi

| Sahne | Ekran | Kaynak |
|---|---|---|
| Kanca, bağlam | Ana Sayfa + sekme çubuğu | `Views/HomeView.swift`, `ContentView.swift` (`customTabBar`) |
| Tür seçimi | "Yeni Hikaye" sheet'i | `ContentView.swift` (`CreateStoryTypeSelectionView`) |
| İsim, tema, oluştur | Metin Hikaye formu | `Views/TextOnlyStoryView.swift` |
| Sonuç | Kütüphanem | `Views/LibraryView.swift`, `Services/TextStoryManager.swift` |

Metinler `Helpers/Localization.swift` (`L.*`), `Models/Story.swift` (tema adları, cinsiyet)
ve `Services/LocalizationManager.swift`'ten alındı. Renkler koddaki
`Color(red:green:blue:)` değerleri ve iOS sistem renkleri.
