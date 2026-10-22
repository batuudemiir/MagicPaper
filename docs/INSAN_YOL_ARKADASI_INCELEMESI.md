# İnsan yol arkadaşı: model incelemesi

**Tarih:** 22 Ekim 2026 · **Dal:** `faz-21-varyasyon` · **Durum:** karar bekliyor (Batuhan)

B turunun "Meslekler ve günlük yaşam" konusu insan yol arkadaşı istiyor: fırıncı,
postacı, öğretmen, balıkçı. Bu dosya inşaya başlamadan önce şu soruyu cevaplıyor:
**mevcut şema bunu güvenle taşıyor mu, taşımıyorsa en küçük değişiklik nedir?**

İncelenen yerler: `CatalogCompanion` (`Content/CatalogRecords.swift:91`),
`Content/ContentTraits.swift`, JSON decode yolu, `BlueprintSelector`,
`OfflineContentBinder`, `CatalogVariant.fits` (`Content/CatalogTemplate.swift:205`),
proza havuzu (`Resources/templates`), `CompanionStep.symbol(forType:)` ve
B2 `CompanionView`.

---

## Sonuç: şema zaten taşıyor, bir eksen eksik

Beklenen bulgu "model hayvan varsayımıyla yazılmış" idi. Değil. Ortak sözcük
dağarcığı tür-bağımsız çıktı ve bu bir kaza değil, `ContentTraits.swift`'in
yetenek / rol ayrımını özellikle çözmüş olmasının sonucu:

| Eksen | İnsan taşır mı | Not |
|---|---|---|
| `CompanionRole` (guide, needsCare, hesitant, reassuring) | **evet, tamamı** | Tür-bağımsız. Fırıncı `guide`, komşu çocuk `hesitant`. |
| `CompanionTrait` (hasLocalKnowledge, isPatient, isStrong, isQuick, isPlayful, isLiteralMinded, isSmall) | **evet** | Hepsi insana uyuyor. `canFly`/`canSwim`/`canCarry` yalnızca `false` kalır, bu da doğru cevap. |
| `Habitat` (= `ContentTag`) | **evet** | A turunda `village`, `civilization` etiketleri açıldı; insanın yeri hazır. |
| `type` (serbest metin) | **evet** | Prozada 34 yerde `bir {{companion.type}}` kalıbıyla geçiyor (toplam 118 referans): "bir fırıncı", "bir postacı" dilbilgisi olarak sorunsuz. |
| `isProperNoun` / `hasPossessiveEnding` | **evet** | İsim çekimi zaten kayıt başına yazılıyor. |

**Migration maliyeti: yok.** Mevcut 15 kaydın hiçbiri değişmek zorunda değil,
`decodeIfPresent` zincirine dokunulmuyor, uzak paketler (FAZ 15) aynı şemayla
decode olmaya devam ediyor.

Eksik olan tek şey bir **doğa ekseni**: prozanın "bu bir hayvan mı, insan mı,
masal yaratığı mı" sorusunu sorabileceği yer yok.

---

## Neden bu eksen gerekli: tek örnek yeter

`templates/bedtime/beat_bedtime_tend.json`, `bt_td_03`:

> "{{child.name}} pencerenin kenarına yumuşak bir yastık koydu. {{companion.name}}
> yastığa yerleşti ve hapşırdı: hapşu! Yastıktan küçük bir tüy havalandı."

Bu satır **tüylü bir beden** varsayıyor ve bunu hiçbir yerde söylemiyor. Bugün
sorun değil, çünkü havuzdaki herkes tüylü ya da kanatlı. Fırıncı havuza
girdiği gün bu satır fırıncıya da teklif edilir ve kitap, yastıktan tüy
havalanan bir fırıncı anlatır. Hiçbir test bunu göremez: satır kusursuz, kayıt
kusursuz, yalnızca ikisi birlikte saçma.

Aynı yön tersten de geçerli: "Ela tezgâhın arkasından gülümsedi" satırı
tilkiye teklif edilemez.

**Mekanizma zaten var ve zaten kullanılıyor.** `templates/v3/beat_meet_companion.json`,
`mc_guide_03` ("Yukarıdan bir kanat sesi geldi... süzülerek indi") kendi
varsayımını açıkça yazıyor: `capabilityRequire: ["canFly"]`. Yani korpus yazarı
bir satır beden varsaydığında bunu bildirme alışkanlığına sahip; eksik olan
"insan mı" diye soracak bir eksen. `bt_td_03`, canlı korpusta (v3, v3-age3,
series, bedtime) bu disiplinin kaçtığı **tek** satır — yani eklenecek eksenin
bugünkü işi bir satırlık, gelecekteki işi bir konu.

---

## Öneri: `CompanionNature`, yeni ve isteğe bağlı bir eksen

**Yetenek listesine eklemeyin.** `CompanionTrait`'e `isPerson` koymak kolay
görünüyor ama `ContentTraits.swift`'in paragraflarca uğraşıp ayırdığı şeyi geri
karıştırır: yetenek "ne yapabilir", rol "bu masalda ne oluyor". "İnsan olmak"
ikisi de değil, üçüncü bir şey: **ne olduğu.**

```swift
/// Yol arkadaşının ne olduğu. Yeteneği değil, oynadığı rol de değil.
public enum CompanionNature: String, Codable, Sendable, Hashable, CaseIterable {
    case animal      // tilki, baykuş, yunus
    case person      // fırıncı, postacı, komşu çocuk
    case fantastic   // ejderha, robot
}
```

Üç dokunuş, üçü de geriye dönük uyumlu:

1. **`CatalogCompanion.nature`**, `decodeIfPresent ?? .animal`. Aynı commit'te
   mevcut 15 kayıt elden geçirilir ve ejderha ile robot `fantastic` olarak
   işaretlenir (A turunun kuralı: etiket bir vaattir, toplu etiketleme yok).
2. **`CatalogVariant.natureRequire: Set<CompanionNature>`**, boş = herkese
   uygun. `CatalogVariant.fits`'e tek satır. Mevcut korpusun tamamı
   etkilenmeden çalışmaya devam eder, çünkü hiçbiri bu alanı yazmıyor.
3. **Beden varsayan satırlar işaretlenir.** Canlı korpusta tek aday: bedtime
   `bt_td_03` (yastıktan havalanan tüy) → `natureRequire: ["animal"]`.
   Eski v1 `templates/offline/*.json` dosyalarındaki hayvan-özgü metinler
   **hiç yüklenmiyor** (`ContentCatalogLoader` yalnızca
   `shared_content_library_v2` ve `pilot_library_v1` okuyor), yani ölü dosya;
   temizliği ayrı bir iş. v2 kütüphanesindeki "tüylü" geçişleri kayıtların
   kendi `description` alanları ve bir nesne ("renkli tüy"), proza değil.

**Varsayılanın riski ve ölçüsü:** `?? .animal`, uzak bir paketin alanı yazmadan
gönderdiği bir insanı hayvan olarak etiketler. `CatalogIntegrity`'ye uyarı
eklenir: paket şema sürümü 2'den büyükse `nature` yazılmamış companion kaydı
`warning` üretir. Sessizce yanlış etiketlenmesinden iyidir.

---

## Bu eksenin çözmediği üç şey

Model kararı bunları çözmez; B turunda içerik yazılırken ayrı ayrı karar
gerektirir. Üçü de ayrıca yazılmadan konu canlıya açılmamalı.

**1. Çocuk güvenliği, ve bu en önemlisi.** Konuşan bir tilkinin ormanda bir
çocuğa yaklaşması masaldır. Tanımadığı bir **yetişkinin** yalnız bir çocuğa
yaklaşması başka bir şeydir, ve kitap bunu normalleştirmemeli. Önerilen
yazım kuralı: insan yol arkadaşı **kendi yerinde** tanışır (fırını, dükkânı,
sınıfı, pazarı), çocuk oraya gider, ve tanışma bir yetişkinin çocuğa
yaklaşması olarak kurulmaz. `village`/`civilization` zemini bunu doğal
kılıyor. Bu kuralın `CatalogIntegrity`'de bir karşılığı olmalı mı, yoksa
editoryal kural olarak mı kalmalı: **Batuhan'ın kararı.**

**2. Ekrandaki resim.** `CompanionStep.symbol(forType:)` insanı tanımıyor,
pati ikonuna düşürür. Dünkü süzgeç onu ekranda gizler, yani insan arkadaş
karttan seçilemez. Meslek simgeleri var (`birthday.cake`, `envelope`,
`book`, `stethoscope`), eşleme eklenince ekran kendiliğinden teklif eder.
Küçük iş, B turunda yapılır.

**3. B2 sahne çizimi.** `CompanionView` yalnızca tilki, kirpi, tavşan ve
baykuş çiziyor; tanımadığı tür için hiçbir şey çizmiyor (`default: break`).
Yani görselli kitapta insan arkadaş resimde yok, yanlış değil ama eksik.
Görselli yol bayrağın arkasında kapalı ve macera zeminlerinin %60'ında
zaten sahne yok, bu yüzden engel değil. B2 Faz 2'ye not.

---

## Reddedilen alternatifler

| Alternatif | Neden reddedildi |
|---|---|
| `CompanionTrait`'e `isPerson` eklemek | Yetenek dağarcığını kirletir; dosyanın özellikle ayırdığı yetenek/rol ayrımını geri karıştırır. |
| Ayrı `CatalogPerson` kaydı ve ayrı havuz | Ortak eksenlerin (`traits`, `castRoles`, `habitat`, `interests`, `weights`) tamamı kopyalanır. Bağlayıcı, seçici, skorlama ve bütünlük denetimi ikiye ayrılır. Kazanç yok: ortak model zaten çalışıyor. |
| `type` dizesinden çıkarım ("fırıncı insandır") | Sessizce yanlış olur, ve yanlış olduğu gün hiçbir yerde görünmez. Etiket bir vaattir, tahmin değil. |
| Hiçbir şey eklemeyip tüy/pati satırlarını prozadan silmek | Korpusun en iyi cümlelerini atmak demek. `capabilityRequire` tam olarak bu yanlışı düzeltmek için var. |

---

## Karar gereken tek şey

Yukarıdaki üç dokunuş uygulanabilir (migration yok, decode bozulmuyor). Açık
kalan soru **1. madde**: insan tanışmasının güvenlik kuralı editoryal bir
kural olarak mı kalsın, yoksa `CatalogIntegrity`'de denetlenen bir kural mı
olsun. Cevap gelmeden "Meslekler ve günlük yaşam" konusu canlıya açılmayacak.
