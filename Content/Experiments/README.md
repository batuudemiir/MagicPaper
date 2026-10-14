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

## Yayından önce açık işler (Batuhan)

1. `content-publisher build-package` bu klasörü okumuyor: varyantların pakete girmesi için bir adım gerekiyor.
2. Paket yeni bir alan (`refrain`) taşıdığı için `ContentPackage.currentSchemaVersion` artırılmalı; yoksa eski
   uygulamalar nakaratı görmeden varyantı gösterir ve deney kolu bozulur.
3. `ba experiment preflight x_refrain_bedtime_56 --package <paket.json>`, sonra yayın ve `experiment mark … live`.
