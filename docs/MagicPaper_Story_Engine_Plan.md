# MagicPaper — Story Engine Plan

**Tarih:** 2026-09-18
**Rol:** story-engine agent
**Kapsam:** `StoryEngine/Sources/StoryEngine/**`, `StoryEngine/Tests/StoryEngineTests/**`, bu doküman.
**Salt okunan:** `MagicPaper/**` (app katmanı), `Resources/**`, `CharacterEngine/**`, `VisualSystem/**`.

`StoryGenerationManager.swift` bu turda **yazılmadı**. D1 kararı geldi ama dosya hâlâ
inceleme kilidinde; bu doküman onun yerine geçen emeklilik planıdır.

---

## 1. Motorun haritası

### 1.1 Canlı yol — deterministik, uzak çağrısız

```
ContentView:56 → StoryCreationFlow:148
  → StoryGenerationManager.createStory()            (SGM:1450)
    → OfflineStoryService.compose()                 (bridge)
      → BlueprintSelector.ranked()                  (paket)
      → OfflineContentBinder.bind()                 (paket)
      → OfflineStoryComposer.compose()              (paket)
    → OfflineStoryMapper.appStory()                 (bridge)
  → Story (app modeli) → UserDefaults
```

Bu yol CLAUDE.md İlke 6'ya uyuyor: model çağrısı yok, maliyet yok, çıktı tekrarlanabilir.

### 1.2 Ölü yol — AI orkestrasyonu

`StoryOrchestrator` (779 satır) **üretimde erişilemez**. Doğrulandı:

| Referans | Yer |
|---|---|
| `StoryOrchestrator(dependencies:)` | `StoryEngineBridge/StoryEngineContainer.swift:65` |
| `StoryEngineContainer` çağıranı | **yok** — yalnızca kendi dosyası |
| Test referansları | `Fakes/OrchestratorHarness.swift:87`, `OrchestratorTests.swift:280` |

Yani zincir `StoryOrchestrator ← StoryEngineContainer ← (hiçbir şey)`. Motorun
**deterministik yarısı canlı, AI orkestrasyon yarısı ada.** Ada boş değil: 761 testin
kayda değer bir kısmı orayı tutuyor. Silinmemeli, yalnızca "bugün üretimde değil" diye
etiketlenmeli.

### 1.3 Dosya ağırlıkları

`StoryOrchestrator` 779 · `CatalogIntegrity` 536 · `StoryTemplate` 502 ·
`OfflineStoryComposer` 475 · `TurkishGrammar` 451 · `ContentTraits` 429 ·
`StoryWriter` 383 · `OfflineSelection` 353.

Ağırlığın büyük kısmı (`StoryOrchestrator`, `StoryWriter`, `StoryTemplate`,
`PromptAssembler`, `StoryPlanner`) ölü yolda. Canlı yol yaklaşık 1 500 satır.

---

## 2. Determinizm denetimi

### 2.1 Sonuç: canlı yol deterministik, ve bu artık ölçüldü

Aynı intent üç ayrı **süreçte** çalıştırıldı; fingerprint, blueprint, içerik ve 11
variant ID'sinin hepsi birebir aynı çıktı:

```
fingerprint = f9af6638d72da2cd
blueprint   = blueprint_absence_looking_001
variants    = na_neutral_03, ex_s_light_02, mc_calm_01, ra_p_07, cm_p_09,
              ob_gen_04, fa_s_09, ps_s_02, rs_any_05, wc_p_restore_04, cf_p_02
```

Bunlar artık `Tests/StoryEngineTests/OfflineDeterminismTests.swift` içinde **literal
olarak sabitli**.

Neden literal: mevcut `OfflineCompositionTests.testSameIntentProducesTheSameBook` iki
kez besteleyip karşılaştırıyor ve **korktuğumuz kusuru göremez**. Swift `Hashable`'ı
süreç başına tohumlar; `Set`/`Dictionary` bir koşu içinde tutarlı, sonraki açılışta
farklı sırada gezer. Tek süreç içindeki iki çağrı, kod sıra-bağımlı olsa bile
uyuşur. Asıl kusur tam olarak budur: ebeveyn yarın uygulamayı açar, masal kayıtlı
seed'inden yeniden kurulur ve **başka bir masal** gelir.

### 2.2 Zaman / locale / UUID bağımlılığı

| Kaynak | Yer | Değerlendirme |
|---|---|---|
| `UUID()` seed | `OfflineStoryService.swift` (`compose`, `seed ?? UUID().uuidString`) | **Doğru desen.** Rastgelelik bir kez üretilip sonuca iliştiriliyor ve saklanıyor; yeniden kurulum saklı seed'i veriyor. |
| `Date()` | `Providers/Repositories.swift:65` (`SystemClock.now()`) | Enjekte edilmiş, testlerde sahte saat. Metni etkilemiyor. |
| `UUID()` | `Repositories.swift:79`, `GenerationBudgetManager.swift:72`, `GenerationConcurrency.swift:88` | Hepsi ölü yolda; kayıt/rezervasyon kimliği, metne girmiyor. |
| Locale | `TurkishGrammar.swift:59,392` | `Locale(identifier: "tr_TR")` **açıkça** veriliyor — cihaz locale'i sızmıyor. Doğru. |
| Locale | `CharacterDescriptor.swift:68` | `en_US_POSIX` ile katlama. Doğru. |
| `lowercased()` (locale'siz) | `ContentPrimitives.swift:35`, `TextMetrics.swift:70,76` | Foundation'ın locale'siz `lowercased()`'i değişmez Unicode eşlemesi kullanır; cihaz locale'ine duyarlı **değil**. Sorun yok. |
| `StableHash` | `EngineFoundation/StableHash.swift` | FNV-1a, süreçler arası sabit. `EngineFoundationTests` literalle sabitlemiş. |

**Hiçbir yerde `Int.random`, `randomElement`, `shuffled` ya da `arc4random` yok.**
Seçim tamamen `DeterministicPicker` üzerinden.

### 2.3 StableHash nerede kullanılıyor, nerede kullanılmıyor

Kullanılıyor: `OfflineStoryComposer:110` (storySeed), `:189` (fingerprint),
`OfflineSelection:347` (picker), `ContentCatalog:120`, `Story:178` (contentHash),
`StoryScene:176`, `VisualPlanner:243` (image seed),
`ProviderRequestIdentity:32,124`, `VisualConstraintSet:131`.

Kullanılmadığı ve kullanılması gerekmeyen yer kalmadı — kimlik/parmak izi üreten her
nokta buradan geçiyor. Swift'in `Hashable`'ı hiçbir kalıcı değerde kullanılmıyor.

### 2.4 Bulunan ihlaller

**İ-1 — `Dictionary` gezinme sırası doğrulama çıktısına sızıyor. DÜZELTİLDİ.**
`Services/Validators/DeterministicValidators.swift:108`
`repeated_openers` uyarıları `openers` sözlüğü ham gezilerek üretiliyordu. Sorun
kümesi her zaman doğruydu, **sırası** her açılışta değişiyordu — ve bu liste masala
yazıldığı için, değişmemiş bir kitabın iki doğrulaması farklı karşılaştırılıyordu.
`sorted(by: { $0.key < $1.key })` eklendi.

**İ-2 — `Set.intersection` gezinme sırası bütünlük raporuna sızıyor. DÜZELTİLDİ.**
`Content/CatalogBlueprint.swift:159-161`
`contradictoryTraits` üç eksenin kesişimini sırasız topluyordu; rapor aynı çelişkileri
her koşuda başka sırada yazıyordu. Eksen içi `sorted()` eklendi, eksenlerin kendi
sırası (setting → companion → discovery) korundu.

**İ-3 — İçerik seçimi katalog dizi sırasına bağlı. DÜZELTİLMEDİ — karar gerekiyor.**
`Offline/OfflineSelection.swift:252` (`orderedCandidates`) ve `:290` (`choose`)

`admissible` listesi katalog dizi sırasında kuruluyor, sonra tohumlu bir ofsetle
indeksleniyor. Ofset **sayıya** bağlı; o ofsette hangi kaydın durduğu **sıraya** bağlı.
Sonuç: bir yazarın kozmetik saydığı bir düzenleme — JSON'da bir setting'i yukarı almak —
kayıtlı her seed'i sessizce başka içeriğe yöneltir ve bir ailenin sakladığı masal
başka bir masal olarak yeniden kurulur.

Aynı savunma **blueprint ekseninde zaten var**: `BlueprintSelector.ranked` döndürmeden
önce `id`'ye göre sıralıyor ("Sorted before picking so the choice cannot depend on
catalog order"). Üç içerik ekseni bu savunmayı almamış. Tutarsızlık kasıtlı görünmüyor.

Düzeltmedim çünkü `sorted(by: id)` eklemek **her mevcut seed'in çözdüğü içeriği
değiştirir** — bu bir refactor değil, içerik kararı. Bunun yerine
`testContentSelectionStillFollowsCatalogOrder` bugünkü davranışı sabitliyor; karar
alındığında ters çevrilecek test odur.

> **Karar D-E1 (content-library + story-engine):** içerik eksenleri `id` sırasına
> alınsın mı? Alınırsa golden'lar bilerek yeniden sabitlenmeli ve kayıtlı seed'lerin
> geçersizleşeceği kabul edilmeli. Bugün sahada yayınlanmış V2 masalı yoksa maliyet
> sıfır; varsa migration gerekir.

---

## 3. Age adaptation

### 3.1 Korpus, blueprint'lere karşı: boşluk yok

6 pilot blueprint'in **her** beat'i, kendi bandında şablona sahip:

| Blueprint | Bant | Beat | Durum |
|---|---|---|---|
| threshold_crossing_001 | 5-6 | 11 | tamamı karşılanıyor |
| unexplained_reading_001 | 5-6 | 12 | tamamı karşılanıyor |
| appeal_together_001 | 5-6 | 10 | tamamı karşılanıyor |
| absence_looking_001 | 5-6 | 11 | tamamı karşılanıyor |
| misreading_tracks_001 | 5-6 | 10 | tamamı karşılanıyor |
| charge_tending_age3_001 | 3-4 | 8 | tamamı karşılanıyor |

Bant eşleşmesi `CatalogTemplate.suits(band:)` ile **örtüşme** üzerinden yapılıyor; 3-4
ile 5-6 örtüşmediği için 3-4 masalına 5-6 cümlesi giremiyor. Doğru.

**Kullanılmayan 8 beat (v3, 5-6):** `ask_for_help`, `exchange_views`,
`give_up_something`, `let_go`, `prepare`, `retrace`, `speak_for`, `take_charge`.
Yazılmış ama hiçbir blueprint'in istemediği beat'ler — D10'daki 14 blueprint portu
tam olarak bunları tüketecek aday.

### 3.2 Asıl boşluk: yaş motora hiç girmiyor

`OfflineStoryIntent` **yaş taşımıyor**. `BlueprintSelector` yaşa göre süzmüyor. Yaş
motora yalnızca çocuğun seçtiği fikir kartı üzerinden ulaşıyor — ve "Sürpriz" kart
seçmiyor.

Sonuç zinciri:

1. `OfflineStoryService.storyIdeas(forAge:)` kartları süzüyor (bridge, app katmanı).
2. Fikrin `preferredFamilies`'i `ranked()`'te **tercih**, filtre değil.
3. Tercih edilen blueprint bağlanamazsa `rotated(leaning) + rotated(rest)` diğer
   banda düşüyor.
4. "Sürpriz"de hiç yaş girdisi yok.

Yani dokuz yaşındaki bir çocuk 5-6 bandına yazılmış bir kitap alabiliyor: Türkçesi
doğru, kurgusu doğru, **yanlış çocuğa yazılmış**, ve hiçbir yer bunu raporlamıyor.

### 3.3 `AgeBandCoverageTests` ile karşılaştırma

`MagicPaperTests/AgeBandCoverageTests.swift` bu boşluğu **zaten** biliyor ve
`testSurpriseStillProducesAStoryOutsideTheAuthoredBand` ile kayda geçirmiş. İki sorun:

- Test **app target'ında**; `swift test` onu hiç koşmuyor (bkz. §6.2). Motorun kendi
  süiti kendi boşluğu hakkında sessizdi.
- Uygulamanın sunduğu bantlar (`MPAgeRange`: 3-4, **5-7**, 8-10, 11-12) korpusun
  bantlarıyla (**5-6**, 3-4) hizalı değil. 8-10 ve 11-12 için **sıfır** içerik var;
  `storyIdeas(forAge:)` en yakın banda düşüyor ve 11 yaşına 5-6 metni gönderiyor.
  Ölçüldü: `suits(age: 9)` → **0 fikir**, `suits(age: 4)` → 1 fikir.

Bu turda paket tarafına iki test eklendi (`testSurpriseHasNoAgeInputAndLandsInThe
AuthoredBand`, `testTheAuthoredBandsAreStillOnlyThreeToFourAndFiveToSix`) — boşluk
artık `swift test`'te görünür.

> **Öneri:** `OfflineStoryIntent`'e `age` alanı eklemek doğru düzeltme, ama canlı yolun
> imzasını değiştirir ve bridge + üç view'a dokunur. D1 ameliyatının 2. dalgasıyla
> birlikte yapılmalı, tek başına değil.

---

## 4. Doğrulama hattı: ne çağrılıyor, ne ölü

| Doğrulama | Nerede | Canlı yolda? |
|---|---|---|
| `CatalogIntegrity` | `ContentCatalogLoader.load()` | **Evet** — yükleme anında, `fatals` varsa `CatalogLoadError.unusable` |
| `BeatSequenceValidator` | `CatalogIntegrity.swift:304` | **Evet** — bütünlük denetiminin içinden |
| `TraitMatch` reddi + tipli hata | `OfflineSelection` | **Evet** — sessiz fallback yok, her ret gerekçeli |
| `OfflineStoryComposer.pool` bozulmayan süzgeçler | `OfflineStoryComposer:~330` | **Evet** — rol / conflict / state / closing / sıra ihlali hata fırlatıyor |
| `ComposedStory.isClean` | `OfflineStoryComposer:37` | **HAYIR — tanımlı, testlerde kullanılıyor, üretimde tüketicisi yok** |
| `StoryValidator` + 6 deterministik validator | `StoryOrchestrator:478,487,652` | Hayır — ölü yol |
| `SemanticValidators` (2) | `StoryValidator` üzerinden | Hayır — ölü yol |
| `ChildSafetyGate` | `StoryOrchestrator:350,495,596` | Hayır — ölü yol |
| `ImageValidationService`, `GeneratedImageValidator` | `StoryOrchestrator:321` | Hayır — ölü yol |

### 4.1 Bulgu: `isClean` üretimde hiç sorulmuyor

`ComposedStory.isClean`, bir sayfanın eksik slot ya da tanınmayan Türkçe ek taşıyıp
taşımadığını söylüyor. On test dosyası bunu doğruluyor. **`OfflineStoryService.compose`
sormuyor.** Yani yerine konmamış bir `{{discovery.name}}` ya da bozuk bir ek, ekrana
sessizce çıkar — motorun bunu tespit edecek mekanizması var ve kullanılmıyor.

Düzeltme yeri bridge (`OfflineStoryService.compose`), benim yazma alanımda değil.
Tek satırlık bir kontrol: `guard composed.isClean else { throw ... }` ya da en azından
temiz olmayan sayfaları raporlamak.

> **İş kalemi B-1 (bridge sahibi):** `compose` dönmeden önce `isClean` denetlensin.

---

## 5. D1 — Emeklilik planı

### 5.1 Hedef

```
Story Creation UI → Story Engine → StoryProvider → OfflineTemplateAIProvider
```

Koddaki karşılıklar: `OfflineStoryComposer` (paket) + `OfflineStoryService` (bridge).
UI hangi provider'ın kullanıldığını bilmemeli.

### 5.2 Bugünkü ihlal: UI provider'ı adıyla tanıyor

| Dosya | Satır | İhlal |
|---|---|---|
| `Screens/StoryCreation/StoryIdeaStep.swift` | 2, 21 | `import StoryEngine`; `CatalogStoryIdea` tipini görüyor; `OfflineStoryService.shared` çağırıyor |
| `Screens/StoryCreation/CompanionStep.swift` | 2, 21-22, 69, 105 | `import StoryEngine`; `CatalogCompanion` tipini görüyor; `OfflineStoryService.shared` çağırıyor |
| `Screens/StoryCreation/StoryCreationFlow.swift` | 2, 160 | `import StoryEngine`; `OfflineStoryService.Failure` yakalıyor |

İronik olan: `OfflineStoryService`'in kendi başlık yorumu "The engine's own types stay
behind this seam — no view ever sees a blueprint, a beat or a trait" diyor. Blueprint
ve beat sızmıyor — ama `CatalogStoryIdea` ve `CatalogCompanion` sızıyor, ve view
singleton'ı adıyla çağırıyor. Dikiş yarı çekilmiş.

### 5.3 Üretim yolu envanteri — düzeltilmiş

| Giriş | Yer | Çağıran | Durum |
|---|---|---|---|
| `createStory` | SGM:1450 | `StoryCreationFlow.swift:148` | **Canlı — kanonik yol** |
| `createCustomStory` | SGM:42 | `StoryWizardView.swift:344` (`createStory()` :321 ← buton :309) ← `ContentView.swift:59` | **Canlı — tek illüstrasyonlu yol** |
| `createCategoryBasedStory` | SGM:111 | **yok** | **Zaten ölü — sil** |
| `TestOfflineTemplateStoryProvider` | SGM:1306 | `DevStoryTestView.swift:80` — onun da çağıranı **yok** | **Çift ölü — sil** |

Yani canlı üretim yolu **dört değil iki**.

### 5.4 Kritik kısıt: illüstrasyon yeteneği

`createCustomStory` kaldırılırsa **illüstrasyonlu masal üretme yeteneği tamamen
kaybolur.** V2 offline yolu metin üretiyor, görsel üretmiyor. Yerini alacak özellik
henüz yok ve bu kodda açıkça yazılı — `Screens/MPAppState.swift:79-85`:

> "Kept deliberately and temporarily. It is the only way to create an *illustrated*
> story, and the feature meant to replace it — turning an existing story into a
> picture book — does not exist yet. … Retire it with that feature."

**Emeklilik tek adımda yapılamaz.** Adımlar, legacy yola bağımlılığına göre ayrılmalı.

### 5.5 Adımlar

#### Dalga 0 — legacy yola dokunmaz, bugün yapılabilir

**0.1 Ölü kodu sil.** `createCategoryBasedStory` (SGM:111), `TestOfflineStoryRequest`
(SGM:1244), `TestOfflineTemplateStoryProvider` (SGM:1306-~1440),
`DevStoryTestView.swift` (tamamı). Hiçbirinin canlı çağıranı yok.
*Kazanç:* SGM'den ~250 satır; ve SGM:1322'deki **sabit mutlak geliştirici yolu**
(`/Users/batudemir/Desktop/...`) üretim kaynağından çıkar.
*Kırılacak test:* yok — bu tiplere değen test yok.
*Not:* `ContentCatalogLoader` başlık yorumu bu yolun neden yanlış olduğunu zaten
yazmış: "there is deliberately **no absolute filesystem path** fallback, because one of
those is what currently makes the prototype work on a developer's Mac and fail on a
device." Silinecek sınıf tam olarak o fallback'i taşıyor.

**0.2 `isClean` denetimi.** §4.1. Bridge'de tek guard.

**0.3 Test planı boşluğunu kapat.** §6.2.

**0.4 UI seam'ini çek.** Üç view'dan `import StoryEngine`'i kaldır. Gereken arayüz:

```swift
// StoryEngineBridge — app katmanı, motor tipi sızdırmaz
struct StoryCardVM: Identifiable, Equatable {   // CatalogStoryIdea yerine
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
}
struct CompanionCardVM: Identifiable, Equatable { // CatalogCompanion yerine
    let id: String
    let name: String
    let description: String
    let symbol: String
}

protocol StoryComposing {                        // "provider" soyutlaması
    func storyCards(forAge age: Int) -> [StoryCardVM]
    func companionCards(forCardID id: String?) -> [CompanionCardVM]
    func compose(childName: String, cardID: String?, companionID: String?,
                 seed: String?) throws -> ComposedStoryVM
}
```

View'lar `StoryComposing`'i enjeksiyonla alır, `OfflineStoryService.shared`'ı adıyla
çağırmaz. `OnDeviceAIProvider`/`RemoteAIProvider` sonradan aynı protokolü uygular; UI
değişmez. `CompanionStep.swift:105`'teki `symbol(for:)` eşlemesi VM'e taşınır —
`CompanionSymbolTests` orayı takip etmeli.
*Kırılacak test:* `MagicPaperTests/CompanionSymbolTests.swift`,
`AgeBandCoverageTests.swift` (ikisi de `OfflineStoryService`'i doğrudan çağırıyor).
Protokol üzerinden yeniden yazılmalı — **silinmemeli**.

> Bu dalga boyunca yeni bir paralel soyutlama kurulmuyor: `StoryComposing`,
> `OfflineStoryService`'in zaten yaptığı işin protokol hâli. `StoryAIProvider`'la
> karıştırılmamalı — o, LLM sınırı (instructions in, text out), hikâye üretim sınırı
> değil. D1 metnindeki "StoryProvider" `StoryComposing`'e karşılık gelir,
> `StoryAIProvider`'a değil.

#### Dalga 1 — illüstrasyon ikamesini bekler

**1.1** "Var olan masalı resimli kitaba çevir" özelliği. `VisualSystem` +
`FalImageProvider` + `PromptConstraintCompiler` bu iş için zaten duruyor; eksik olan
onları canlı yola bağlayan akış. (illustration-system agent'ının alanı.)

**1.2** Özellik çalıştıktan **sonra**: `createCustomStory` (SGM:42) ve
`StoryWizardView` emekliye ayrılır; `ContentView.swift:59` ve `MPAppState.showWizard`
kaldırılır.

**1.3** SGM kalan hâliyle tek girişli olur (`createStory`) ve adı artık doğruyu söyler.

#### Dalga 2 — motorun ada yarısı

**2.1** Karar: `StoryOrchestrator` + `StoryEngineContainer` + `GeminiStoryAIProvider`
canlandırılacak mı, yoksa "gelecekteki RemoteAIProvider için referans uygulama" diye
etiketlenip dondurulacak mı? Bugün 761 testin bir kısmı orayı tutuyor; **silmek test
kapsamını kaybetmek demek.** Önerim: dondur, `StoryEngineContainer`'a "no production
caller by design — see Plan §5.5 Dalga 2" yorumu ekle.

### 5.6 Sıra bağımlılıkları

```
0.1 (ölü kod) ─┐
0.2 (isClean) ─┼─→ bağımsız, paralel
0.3 (test planı)┘
0.4 (UI seam) ──→ 1.2'nin ön koşulu
1.1 (illüstrasyon) ──→ 1.2'nin ön koşulu
1.2 (legacy emeklilik) ──→ 1.3
```

`0.4` ve `1.1` bittiğinde, ve ancak o zaman, `1.2` yapılabilir.

---

## 6. Diğer bulgular

### 6.1 `swift test` varsayılan build system'de kırılıyor

`swift test` Xcode build system'ini kullanıyor ve codesign'da düşüyor:

```
StoryEngine_StoryEngine.bundle: resource fork, Finder information, or similar detritus not allowed
error: CodeSign ... failed with a nonzero exit code
```

Sebep: `Sources/StoryEngine/Resources` altındaki `com.apple.macl` / `com.apple.provenance`
genişletilmiş öznitelikleri derlenmiş bundle'a taşınıyor. `xattr -rc` bunları
temizlemiyor (sistem öznitelikleri).

**Geçici çözüm, ve bu turda kullanılan:** `swift test --build-system native`.
CI'a girecekse bu bayrak yazılmalı, yoksa boru hattı ilk koşuda kırmızı yanar.

### 6.2 Paket testleri Xcode/CI akışında koşmuyor

`TestPlan.xctestplan` yalnızca `MagicPaperTests` hedefini listeliyor. Paketin dört test
hedefi (`StoryEngineTests`, `CharacterEngineTests`, `VisualSystemTests`,
`EngineFoundationTests`) — 761 test — planda **yok**. `swift test` ile koşuyorlar, Xcode
şemasıyla koşmuyorlar. Ters yön de doğru: `AgeBandCoverageTests` app hedefinde olduğu
için `swift test` onu koşmuyor. İki süit birbirini görmüyor.

### 6.3 Üretim kaynağında sabit geliştirici yolu

`Services/StoryGenerationManager.swift:1322`

```swift
let devPath = "/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/StoryEngine/Sources/StoryEngine/Resources/templates/offline/v2/shared_content_library_v2.json"
```

Üretim kaynağında, geliştiricinin kullanıcı adını ve dizin yapısını taşıyan mutlak yol.
Cihazda hiçbir zaman çalışmaz; ayrıca derlenmiş ikiliye string olarak girer. Dalga 0.1
bunu zaten kaldırıyor — ama kaldırılana kadar bilinen bir sızıntıdır.

---

## 7. Bu turda değişenler

| Dosya | Değişiklik |
|---|---|
| `Sources/StoryEngine/Services/Validators/DeterministicValidators.swift` | İ-1 düzeltmesi: `repeated_openers` sıralı |
| `Sources/StoryEngine/Content/CatalogBlueprint.swift` | İ-2 düzeltmesi: `contradictoryTraits` eksen içi sıralı |
| `Tests/StoryEngineTests/OfflineDeterminismTests.swift` | **Yeni** — 7 test |

`swift test --build-system native`: **761 test, 0 hata.**

---

## 8. Açık kararlar

| No | Karar | Sahip |
|---|---|---|
| D-E1 | İçerik eksenleri `id` sırasına alınsın mı? (§2.4 İ-3) | content-library + story-engine |
| D-E2 | `OfflineStoryIntent` yaş taşısın mı? (§3.3) | story-engine, Dalga 0.4 ile |
| D-E3 | `StoryOrchestrator` canlandırılacak mı, dondurulacak mı? (§5.5 Dalga 2) | product-architect |
| D-E4 | `TestPlan.xctestplan` paket hedeflerini alsın mı? (§6.2) | lead / CI sahibi |
