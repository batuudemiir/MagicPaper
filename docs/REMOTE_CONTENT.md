# Uzaktan içerik (FAZ 15)

Günün masalı, eğitici hikâyeler ve motorun katalog paketi App Store güncellemesi olmadan değişir.
Bu belge yayın sürecini ve uygulamanın neye nasıl güvendiğini anlatır.

## Ne nerede

| Parça | Yer |
|---|---|
| Masal kaynakları (bir masal = bir dosya) | `Content/DailyFeed/stories/*.json` |
| Uygulamayla gelen yedek (ilk akış gelene kadar) | `MagicPaper/StoryEngineBridge/RemoteContent/daily_feed_fallback.json` — elle düzenlenmez, `fallback` komutu yazar |
| Yayın aracı | `Scripts/ContentPublisher` (`content-publisher`) |
| Yayımlanan dosyalar | `hosting/public/content/feed.json`, `feed.json.sig`, `catalog/<sürüm>.json` |
| Barındırma | Firebase Hosting, proje `magicpaper-393a7` → `https://magicpaper-393a7.web.app/content/` |
| Uygulama ayarı | `Info.plist`: `MPContentBaseURL`, `MPContentSigningKey` |

## Güven zinciri

1. `feed.json` Ed25519 ile imzalı; imza `feed.json.sig` (base64). Açık anahtar uygulamada
   (`MPContentSigningKey`), gizli anahtar yalnız yayıncının makinesinde (`~/.magicpaper/content-signing.key`).
   **Anahtar boşsa uygulama hiçbir uzaktan içerik almaz.**
2. Akış katalog paketinin SHA-256 özetini taşır; imza paketi de kapsar.
3. `feedVersion` her yayında artar. Uygulama saklananından büyük olmayan akışı almaz (eski bir akış tekrar oynatılamaz).
4. Paket indirilince: özet → motorun kendi yükleyicisi (`ContentCatalogLoader.load(package:)`, paketle gelen
   katalogla aynı birleştirme ve `CatalogIntegrity`) → `RemoteCatalogPolicy`: paket uygulamanın katalog
   sürümünden **yeni** olmalı ve paketle gelen katalogda olmayan tek bir hata bile getirmemeli.
   Geçen paket bekletilir, **bir sonraki açılışta** etkinleşir; her açılışta aynı denetimler yeniden yapılır.
5. Akış paket adı taşımazsa (`--package none`) uygulamalar bir sonraki açılışta paketle gelen kataloğa döner.

Uygulama akışı açılışta, öne gelişte (en az 30 dakika arayla) ve iOS'un arka plan yenilemesinde çeker.
İstekte çerez, sorgu ya da kimlik yoktur; herkes aynı iki statik dosyayı ister.

## İlk kurulum (bir kez)

```bash
cd Scripts/ContentPublisher
swift run content-publisher keygen
```

- Yazılan açık anahtarı `MagicPaper/Info.plist` → `MPContentSigningKey`'e koyun ve uygulamayı yayımlayın.
- `~/.magicpaper/content-signing.key` dosyasını güvenli bir yere yedekleyin. **Kaybolursa yüklü uygulamalara
  yeni akış gönderilemez** (anahtar ancak uygulama güncellemesiyle değişir).
- `npm i -g firebase-tools && firebase login` (Hosting `hosting/` klasöründen yayımlanır).
- Uyarı: Firebase Hosting'de yayın sitenin tamamını değiştirir. Projede Hosting'den sunulan başka bir şey
  varsa önce `hosting/public`'e alınmalı (6 Ekim 2026 itibarıyla yok).

## Yeni masal yayımlamak

1. `Content/DailyFeed/stories/` altına yeni dosya: benzersiz `id` (UUID, `uuidgen`), `publishDate`
   (`yyyy-MM-dd`; o günden önce gösterilmez), `category` (`bedtime`, `morning`, `educational`, `values`,
   `adventure`, `nature`), `ageRange` (`3-6` ya da `10+`), `readingTime` (dk), `content`, `moralLesson`, `emoji`.
   Eğitici hikâye = `category: educational`.
2. Yayınla:
   ```bash
   swift run content-publisher publish --deploy          # ilk yayında: --first
   ```
3. `hosting/public/content/feed.json` ve `.sig`'i **commit'leyin**: bir sonraki `feedVersion` buradan sayılır.
   Önceki akış yokken araç `--first` olmadan yayımlamaz.

Günün masalı kuralı (`TodaysStoryPicker`): günü gelmiş masallardan çocuğun yaşına uyanlar (yoksa hepsi),
okunmamış önce, en yeni `publishDate` önce. Gün içinde seçilen masal okunsa da gün boyu kalır; aynı gün
yayımlanan yeni masal onu geçer.

## Katalog paketi yayımlamak

1. İçerik değişikliğini repoda yapın; `shared_content_library_v2.json`'daki `version`'ı artırın
   (ör. `2.0.0` → `2.0.1`). Bu sürüm hem paketin hem de bir sonraki uygulama sürümünün katalog sürümüdür;
   uygulama aynı ya da daha yeni katalogla güncellendiğinde indirilen paket kendiliğinden devre dışı kalır.
2. ```bash
   swift run content-publisher build-package             # doğrulayıcı (taban: Content/validator_baseline.txt) + motor denetimi
   # Deney kolu da eklenecekse: build-package --experiment <id>  (Content/Experiments/README.md)
   swift run content-publisher publish --package latest --deploy
   ```
3. Paket biçimi motorun yeni kodunu gerektiriyorsa (yeni alan, yeni kural) `ContentPackage.currentSchemaVersion`
   artırılır; eski uygulamalar o paketi indirmez.

Geri alma: `publish --package none --deploy` (paketle gelen katalog) ya da `--package <eski-sürüm>`
(eski sürüm uygulamanın kendi kataloğundan yeniyse).

## Denetim

```bash
swift run content-publisher verify --public-key <MPContentSigningKey>
```

Simülatörde yerel deneme (yalnız DEBUG): `hosting/public`'i `127.0.0.1:8765`'te sunun ve uygulamayı şu
argümanlarla açın: `-mp.debug.contentBaseURL http://127.0.0.1:8765/content/ -mp.debug.contentSigningKey <açık anahtar>
-mp.debug.contentRefreshInterval 5`. Arka plan yenilemesi simülatörde çalışmaz (`BGTaskScheduler` yok);
öne gelme yolu dener.
