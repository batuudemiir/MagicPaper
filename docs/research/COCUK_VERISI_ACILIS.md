# Çocuk verisini açmak: adım adım (Batuhan için)

Araştırma ajanı bugün yalnızca kitaplardan öğreniyor. Bir önerinin çocuklarda gerçekten
işe yarayıp yaramadığını görmesi için aşağıdaki beş adım bir kez yapılmalı. Hepsi hazır;
kodu yazıldı ve test edildi, yalnızca yayın ve dağıtım adımları kaldı.

Ne toplanır: hiçbir kişisel veri. Uygulama zaten `readingEvents` koleksiyonuna hesap
kimliği olmadan "hangi blueprint, hangi yaş bandı, hangi mod, bitti mi, yeniden okundu mu,
hangi gün" yazıyor (FAZ 14/16). Sunucu bunları haftalık toplar; 50 okumanın ya da 7 günün
altındaki hücreler hiç yayımlanmaz. Araştırma tarafı tek tek olay görmez, yalnızca bu toplamı görür.

## 1. Araştırma dalını main'e al

`aggregateOutcomes` fonksiyonu yalnızca `book-intelligence` dalında. Main'e girmeden deploy edilemez.

- GitHub'da `book-intelligence` → `main` PR'ı (dal origin'de).
- Dalın uygulama koduna dokunmadığını PR açıklaması söyler; çakışma yalnızca
  `design-handoff/reference/DEMO_CHANGELOG.md` dosyasında olabilir.

## 2. Sunucu fonksiyonunu dağıt

```bash
cd MagicPaper/firebase/functions && npm test
cd .. && firebase deploy --only functions:aggregateOutcomes
```

Her pazartesi 04:00 (İstanbul) son 28 günü toplar, `outcomeAggregates/{periodEnd}` belgesine yazar.

## 3. Deney kolunu yayımla

Kollar hazır: `Content/Experiments/x_refrain_bedtime.json` (nakarat deneyi, 14 Ekim onayın).
Kardeş blueprint'ler uygulamayla gelmez; yalnızca bu paketle ulaşır.

```bash
cd MagicPaper/scripts/ContentPublisher
swift run content-publisher build-package --experiment x_refrain_bedtime --repo ../.. --key <imza anahtarı>
swift run content-publisher publish --package latest --repo ../.. --key <imza anahtarı> --deploy
```

`build-package` doğrulayıcı ve motor denetiminden geçirip `hosting/public/content/catalog/<sürüm>.json`
yazar; `publish --package latest` akışı o pakete bağlar, `--deploy` hosting'e gönderir.
Anahtar yalnızca sende. Ön kontrolde `--package` olarak bu `catalog/<sürüm>.json` dosyasını ver.

## 4. Ön kontrol ve canlıya alma (senin kararın)

```bash
cd MagicPaper-research
python3 Research/BookIntelligence/book_agent.py experiment preflight x_refrain_bedtime_56 --package <yayınlanan paket.json>
python3 Research/BookIntelligence/book_agent.py experiment preflight x_refrain_bedtime_34 --package <yayınlanan paket.json>
```

İkisi de "READY" derse, paketin uygulamalara ulaştığı gün:

```bash
python3 Research/BookIntelligence/book_agent.py experiment mark x_refrain_bedtime_56 live
python3 Research/BookIntelligence/book_agent.py experiment mark x_refrain_bedtime_34 live
```

Bu, çocuğa ulaşan tek insan onayıdır; ajanlar bu komutu hiçbir zaman çalıştırmaz.

## 5. Her hafta: toplamı araştırma ajanına indir

```bash
gcloud auth application-default login      # bir kez
cd MagicPaper/firebase/functions && npm install   # bir kez
node scripts/export-outcomes.mjs
```

Son 4 haftanın toplamını `MagicPaper-research/Research/BookIntelligence/inbox/usage/` klasörüne yazar
(git'e girmez). Pazartesi koşusu (`ba cycle`) dosyaları alır, gizlilik eşiğini yeniden denetler,
deneyleri değerlendirir. Kol başına 200 okumaya ulaşınca sonuç haftalık sayfada görünür ve
bulguların güvenine çocuk kanıtı olarak işlenir.

Haftalık koşu da bu komutu dener: bilgisayarda `gcloud` kimliği varsa kendisi indirir, yoksa
"çocuk verisi indirilemedi" diye not düşer ve devam eder.
