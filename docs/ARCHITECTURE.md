# MagicPaper mimarisi

Uygulamanın kod düzeni ve yeni kodun uyacağı kurallar. Ürün kararları: `CLAUDE.md`. Sayfa ağacı: `docs/SAYFA_MIMARISI.md`. Marka: `docs/MARKA.md`. Yol haritası: `docs/STARTUP_PLANI.md`.

**İlke:** aşamalı temizlik. Çalışan sistem yeniden yazılmaz; **dokunulan ekran taşınır**. TCA, Coordinator ve tam paket parçalama yok.

## Katmanlar

| Katman | Yer | Sorumluluk |
|---|---|---|
| Masal motoru | `StoryEngine` paketi | Cihazda masal yazma, bulut yok. |
| Köprü | `MagicPaper/StoryEngineBridge` | Motoru uygulama modellerine bağlar. |
| Servisler | `MagicPaper/Services` | Kalıcı veri, hesap, abonelik. Çoğu bugün `.shared`. |
| Oturum | `MPAppState` | Okuyucu, masal yazma, akşam akışı, bildirim. Kalıcı veri tutmaz. |
| Gezinme | `MPRouter` | Sekme, yığın, sheet, ebeveyn odası. İş mantığı tutmaz. |
| Tasarım sistemi | `MagicPaper/DesignSystem` | Token'lar ve ortak bileşenler. |
| Ekranlar | `MagicPaper/Screens`, `Views` | Durumu çizer, dokunuşu iletir. |

## Gezinme: `MPRouter`

Tek gezinme kaynağı `Screens/MPRouter.swift`. Görünümler `app.router` ile erişir:

```swift
app.router.tab = .library
app.router.openKidPage(.series(childID))
app.router.closeSheet { app.read(story) }
```

| Tür | Yol | Çıkış |
|---|---|---|
| Sekme | `router.tab` | Çubuk |
| Çocuk alt sayfası | `router.openKidPage(_:)`, `MPKidRoute` | "Geri" ve kenardan kaydırma |
| Masallar yığını | `router.masallarPath`, `GunlukRoute` | "Geri" |
| Ebeveyn odası | `router.requestParentMode()`, kapıdan geçer | "Çocuk modu" |
| Ebeveyn alt sayfası | `router.parentRoute`, `MPParentRoute` | "Geri" |
| Kısa iş | `router.sheet`, `MPSheetRoute` | Aşağı çekme, Kapat |
| Tam ekran akış | `app.readerStory`, `app.showStoryCreation`… | X |

Kurallar:

- Bir modal açıkken başka modal açılmaz; sheet'ten sonra modal için `router.closeSheet(then:)`.
- Yeni route bir enum vakasıdır; ekran kendi `@State` bayrağıyla sayfa itmez.
- `MPRouter` servis çağırmaz. Hem gezinme hem veri gerektiren iş (`MPAppState.open(_:childID:)`) `MPAppState`'te kalır.

`MPAppState`, `router`'ın değişikliklerini kendi `objectWillChange`'ine iletir; bu yüzden mevcut gözlemciler aynı şekilde güncellenir. Bir görünüm yalnızca gezinmeye bakıyorsa ileride `router`'ı doğrudan gözleyebilir.

**Sıradaki bölme (dokunuldukça):** okuyucu oturumu, sonra akşam akışı. Faz 3'teki tek okuyucu işi ilkini doğal olarak taşır.

## Bağımlılık

Bugün `.shared` yaygın (yaklaşık 266 referans, 33 tip). Toplu taşınmıyor.

- **Yeni kod `.shared` çağırmaz:** bağımlılık başlatıcıyla ya da `@Environment` ile gelir. Varsayılan değer olarak `= .shared` kabul edilir (`readClassic(_:progress:)` gibi), test yazılabilsin diye.
- Depolamaya dokunan yeni servis protokol arkasında olur.
- Dokunulan tip, uygunsa `@Observable`'a geçer.

## Görünüm

- İş mantığı görünümde değil: servis, model ya da `MPAppState`.
- Masal içeriği görünümde değil: Story Engine ve içerik kütüphanesi.
- Yazı yalnızca `MPTextStyle` rolleriyle (`.mpText(.section)`), düğme `MPButton`, avatar `MPAvatar`.
- Etkileşimli her öğenin Türkçe etiketi var, süs öğesi gizli.

## Testler

| Hedef | Kapsam | Nerede çalışır |
|---|---|---|
| `MagicPaperTests` | Mantık, modeller, router | Her yerde, CI dahil |
| `DesignSystemSnapshotTests` | Ortak bileşenler, masal sayfası | Yalnızca iPhone 17 Pro iOS 27 |
| `MagicPaperUITests/AccessibilityAuditTests` | Apple denetimi, kontrast hariç | Yerel |
| `MagicPaperUITests/NavigationFlowTests` | Sekme, push, geri, masal yazma, oda | Yerel |
| `StoryEngine` paketi | Motor | Her yerde |

Görsel değişiklik referansı değiştirir: fark bir hatadır ya da bilinçli değişikliktir. Bilinçliyse referans silinip yeniden kaydedilir ve gözle bakılır. `xcodebuild test` test bitince kapanmayabilir, sonuç `Executed` satırındadır.

Görüntü testinde tam ekran yok: ekranlar saate ve tekil servislere bağlı. Bağımlılıklar `@Environment`'a geçtikçe eklenir.

## Bilinen borç

- `MPColor` ve `MP.C` iki ad sistemi aynı renklere bakıyor. `MP.*` kalır, `MPColor`, `MPSpacing` gibi takma adlar dokunuldukça kalkar.
- `MP.F` ve `MPTextStyle` iki yazı girişi; boyutlar hizalı ama `MP.F` `relativeTo` kullanmıyor.
- Ebeveyn odasında çocuk öğeleri erişilebilirlik ağacında duruyor (`testParentRoomHidesKidScreen`).
- Performans ölçümü yok: `ReaderImageLoader` eşzamanlı çözüyor, `os_signpost` eklenmedi.
