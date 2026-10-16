# Deney kolları

Bu klasördeki dosyalar **uygulamayla gelmez**: `ContentCatalogLoader` yalnızca motorun paketlediği kataloğu okur.
Bir deney kolu çocuğa yalnızca yayımlanmış bir uzaktan katalog paketiyle (FAZ 15, `docs/REMOTE_CONTENT.md`) ve
ürün sahibi deneyi `live` işaretledikten sonra ulaşır (`MagicPaper-research/docs/research/EXCHANGE_PROTOCOL.md`).

## `x_refrain_bedtime.json` (p_repeated_line, 14 Ekim 2026 onayı)

Kitap araştırmasının "bilinçli nakarat" önerisi. İki kardeş blueprint, uyku öncesi (`charge` ailesi):

| Kontrol (yayında) | Varyant (bu dosya) | Bant | Nakarat sayfaları | Değişen son |
|---|---|---|---|---|
| `bp_charge_tending_001` | `bp_charge_tending_001_refrain` | 5-6 | 2, 4, 6 | 8 |
| `blueprint_charge_tending_age3_001` | `blueprint_charge_tending_age3_001_refrain` | 3-4 | 2, 4, 5 | 6 |

Varyant kontrolün birebir aynısıdır; yalnızca `refrain` alanı eklenir: sayfanın sonunda aynı kısa satır
("Usul usul, yavaş yavaş."), son sayfada bir kez değişir ("Usul usul, yavaş yavaş, uyku geldi.").

- **Motor:** `RefrainSpec` (`CatalogBlueprint.swift`), `OfflineStoryComposer` satırı sayfanın sonuna ekler ve
  `ComposedPage.refrain` olarak işaretler; `CatalogIntegrity.checkRefrains` kısa (≤ 6 kelime), slotsuz, en az iki kez,
  son sayfada değişen ve sakin biten nakarat ister. Yayındaki hiçbir blueprint nakarat taşımaz (test bunu denetler).
- **Sayfa bütçesi:** sayfanın kendi satırları bandın içinde kalır; nakarat en çok 6 kelimeyle üstüne eklenir.
- **Tekrar:** kaza tekrarı hâlâ kusur; testler nakaratın kendisinden başka tekrar eklemediğini denetler
  (`RefrainExperimentTests`).
- **Ölçüt:** uyku öncesinde tekrar okuma (bitirmemek başarısızlık değildir). Deney kayıtları ve tahmin:
  `x_refrain_bedtime_56`, `x_refrain_bedtime_34` (book-intelligence dalı, `ba experiment list`).

## Paketleme (15 Ekim 2026)

Kol pakete açık istekle girer; varsayılan paket hâlâ uygulamanın taşıdığı içeriğin aynısıdır:

```bash
swift run content-publisher build-package --experiment x_refrain_bedtime
swift run content-publisher publish --package latest --deploy
```

- Belge paketin **son** kütüphanesi olarak eklenir. Sıra kozmetik değil: `ContentCatalog.merging` ilk
  `0.0.0` olmayan sürümü kataloğun sürümü sayar, ve paket belgelerinin taşıdığı sürümü ilan etmek zorundadır.
  Bu dosya kendini adlandırdığı için (`"version": "experiment-x_refrain_bedtime"`) başa konsa paketin sürümü o
  olur ve cihaz paketi reddeder. Sonda yalnızca kayıt ekler — bir kolun yapması gereken de bu.
- Dosya adı ile belgedeki `experiment.id` aynı olmalı; publisher ayrışırsa yayımlamaz. Yanlış adla yayımlanan bir
  kol veri üretir ama yanlış kolun verisini üretir, ki bu hiç yayımlamamaktan kötüdür.
- Aynı sürümle iki ayrı katalog yayımlanamaz: kol eklemek "içerik farklı" demektir, bu yüzden
  `shared_content_library_v2.json`'daki `version` artırılır.
- `ContentPackage.currentSchemaVersion` **2**: paket `refrain` taşıyabildiği için nakaratı bilmeyen uygulama
  paketi indirmez (karşılaştırma eşitlik, `RemoteContentService`). O uygulama yayındaki kataloğu okur — veride
  yanlış cevap, cevapsızlıktan kötüdür.

## Yayından önce açık işler (Batuhan)

1. `ba experiment preflight x_refrain_bedtime_56 --package <paket.json>`, sonra yayın ve `experiment mark … live`.
