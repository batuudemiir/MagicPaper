# MagicPaper — Content Library

**Tarih:** 2026-09-18
**Sahip:** content-library agent
**Karar dayanağı:** D3 — *Schema 2 tek kanonik blueprint formatıdır*
**Önceki turun kaydı:** `docs/retired/SCHEMA_MERGE_PLAN.md` (D1–D9 kapalı, **D10 bu turda kapandı**)

---

## 0. Tek cümle

Üretim blueprint'lerinin tamamı **Schema 2** formatındadır ve
`StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json`
içinde yaşar. Başka hiçbir yerde üretim blueprint'i yoktur ve başka hiçbir
formatta yenisi yazılmayacaktır.

---

## 1. Korpus üç rakip değil, üç KATMAN

`ContentCatalogLoader` üç kaynağı çalışma anında tek bir `ContentCatalog`'a
birleştirir. Bunlar birbirinin alternatifi değildir; sırayla üst üste biner.

| # | Katman | Dosya | Zorunlu mu | Ne taşır |
|---|---|---|---|---|
| 1 | Taban içerik | `templates/offline/v2/shared_content_library_v2.json` | **Zorunlu** — yoksa katalog hiç yok | 16 setting, 15 companion, 20 object, 20 event, 15 challenge, 10 ending, **52 rol-anahtarlı template** |
| 2 | Blueprint + traitli içerik | `blueprints/pilot_library_v1.json` | Opsiyonel | **15 Schema 2 blueprint**, 6 setting, 5 companion, 8 object, 23 template, **4 storyIdea** |
| 3 | Beat prose korpusu | `templates/v3/` (33 dosya) + `templates/v3-age3/` (8 dosya) | Opsiyonel | 358 varyant, beat başına bir dosya |

Birleşme kuralları (`ContentCatalogLoader.load()`):

- Katman 1 bulunamazsa `CatalogLoadError.resourceNotFound` atılır.
- Katman 2 bulunamazsa uygulama çalışır ama **hiçbir hikâye üretilemez** —
  beat'li blueprint'lerin ve traitli içeriğin tamamı buradadır.
- Katman 3, kapsadığı beat'ler için katman 1–2'nin template'lerini **değiştirir**
  (birleştirmez). `BeatCorpusLoader` yalnızca `beat_` ön ekli dosyaları okur.
- `Package.swift` `.process("Resources")` kullandığı için dizin yapısı düzleşir;
  41 beat dosyası da paket bundle'ının kökünde yan yana durur.

**Sonuç:** "içerik kütüphanesi ikiye bölünmüş" tespiti eskimiştir. Bölünme değil,
katmanlama var ve runtime'da zaten birleşiyor.

---

## 2. Schema 2 — kanonik blueprint şeması

Okuyan tip: `StoryEngine/Sources/StoryEngine/Content/CatalogBlueprint.swift`.
**Alan adı uydurulmaz**; aşağıdaki liste `CatalogBlueprint`'in `CodingKeys`'inden
çıkarılmıştır.

| Alan | Zorunlu | Not |
|---|---|---|
| `id` | ✔ | `ContentID` |
| `schemaVersion` | — | `2` |
| `version` | — | metin |
| `family` | ✔ (pratikte) | `unexplained · threshold · appeal · absence · misreading · charge` |
| `editorialName` | — | insan okuru için |
| `genre` | ✔ | snake_case: `adventure`, `gentle_adventure` |
| `theme` | ✔ | snake_case (§6) |
| `ageRange` | ✔ | `"5-6"` / `"3-4"` |
| `pageCount` | ✔ | banda uymalı: 5-6 → 8, 3-4 → 6 |
| `premise` | — | bir cümlelik iddia |
| `editorialGuidance` | — | yazara talimat |
| `requires` | ✔ | `setting` / `companion` / `discovery` / `casting` / `thresholdKind` |
| `forbids` | ✔ | `setting` / `companion` / `discovery` — **düz küme**, disjunction yok |
| `titlePatterns` | ✔ | `{{child.name}}`, `{{setting.name}}`, `{{companion.name}}`, `{{discovery.title}}` |
| `pages` | ✔ | `pageNumber` · `role` · `beat` · `supportingBeat?` · `emotion` |

`requires.setting/companion/discovery` bir `TraitRequirement`'tır:

```json
"setting": ["hasThreshold"]
"setting": { "allOf": ["hasThreshold"], "anyOf": [["isOpen", "isTended"]] }
```

`casting` ve `thresholdKind` **`TraitRequirement` değildir** — ikisi de "bunlardan
BİRİ" anlamına gelen düz kümelerdir. Bir hikâye tek bir rol seçer.

### Taksonomi düzeltmesi

`.claude/agents/content-library.md` içindeki **genre / theme / world / mechanic**
taksonomisi Schema 2 ile uyuşmadığı ölçüde **geçersizdir**:

- `world` ve `mechanic` diye bir blueprint alanı **yoktur**. Yerlerine
  `settings[]` kayıtları ve `requires` / `forbids` kısıtları geçer.
- `genre` ve `theme` vardır ama çok daha dardır ve snake_case'tir.
- Asıl eksen **`family`**'dir: anlatının hangi çatışma mekanizmasıyla
  çözüldüğünü `NarrativeFamily` belirler, `genre`/`theme` yalnızca etikettir.

---

## 3. Bu turda ne oldu — KEEP / MIGRATE / MERGE / RETIRE

### 3.1 v2 blueprint korpusu (12 kayıt) → **RETIRE**

Onikisi de **aynı** yayı bildiriyordu: `adventure` / `courage` / `5-6` / 8 sayfa
ve aynı sekiz `pageRole` dizisi. Yalnızca `id`'leri farklıydı — yani on iki
blueprint değil, bir blueprint'in on iki kopyasıydı.

- Hiçbiri beat bildirmediği için `CatalogBlueprint.isBeatAuthored == false`.
- `BlueprintSelector.admissible` yalnızca `isBeatAuthored` olanları dolaşır, yani
  **bu on iki kayıt hiçbir zaman seçilemedi**. Yüklenip atlanıyorlardı.
- Her katalog yüklemesinde 12 `blueprint_without_beats` hatası + 12
  `blueprint_without_family` uyarısı üretiyorlardı.

**Kayıp yok:** taşıdıkları tek yay, 14 beat'li Schema 2 blueprint tarafından
fazlasıyla karşılanıyor.

**Geri alınabilirlik:** on ikisi de birebir
`docs/retired/retired_blueprints_2026-09-18.json` içinde duruyor. Geri almak için
o dosyadaki `blueprints` dizisini `shared_content_library_v2.json`'ın
`blueprints` anahtarına yapıştırmak yeterli.

**Seçim etkisi: YOK.** §5'teki sıra duyarlılığı `settings`/`companions`/`objects`
eksenleri içindir; blueprint'ler `BlueprintSelector.ranked` içinde `id`'ye göre
sıralanır, üstelik bu on iki kayıt zaten havuzun dışındaydı.

### 3.2 Pilot blueprint korpusu (6 kayıt)

| Pilot | Karar | Gerekçe |
|---|---|---|
| `blueprint_threshold_crossing_001` | **MERGE** ← II-1 | Aynı `id` korundu (8 test referansı). Yay ve kısıtlar katalog II-1'e yükseltildi |
| `blueprint_unexplained_reading_001` | **MERGE** ← I-1 | Aynı `id` korundu; katalog I-1 `insight` yayına yükseltildi |
| `blueprint_appeal_together_001` | **MERGE** ← III-1 | Aynı `id` korundu; `cooperative_effort` yayı |
| `blueprint_absence_looking_001` | **MERGE** ← IV-1 | Aynı `id` korundu; `persist` yayı |
| `blueprint_misreading_tracks_001` | **MERGE** ← V-1 | Aynı `id` korundu; `reveal_truth` yayı |
| `blueprint_charge_tending_age3_001` | **KEEP** | Kütüphanedeki tek 3-4 bandı blueprint'i; `v3-age3` korpusunun tek tüketicisi. 14'lük katalog tamamen 5-6 bandı olduğu için bu bir duplicate DEĞİL |

`id`'ler bilerek korundu: yeni `bp_*` id'si vermek, bu beş blueprint'e bağlı
saklanmış hikâyelerin blueprint referansını kopartırdı.

### 3.3 14 blueprint → **MIGRATE** (D10 kapandı)

`BLUEPRINT_CATALOG_V2.md` §3'teki on dört blueprint Schema 2'ye taşındı. Beşi
yukarıdaki pilot `id`'lerinin üzerine, dokuzu yeni `bp_*` kaydı olarak.

| Aile | Blueprint |
|---|---|
| unexplained | `blueprint_unexplained_reading_001` (I-1) · `bp_unexplained_moment_002` (I-2) · `bp_unexplained_askingout_003` (I-3) |
| threshold | `blueprint_threshold_crossing_001` (II-1) · `bp_threshold_joining_002` (II-2) |
| appeal | `blueprint_appeal_together_001` (III-1) · `bp_appeal_speakingup_002` (III-2) · `bp_appeal_sharing_003` (III-3) |
| absence | `blueprint_absence_looking_001` (IV-1) · `bp_absence_retracing_002` (IV-2) |
| misreading | `blueprint_misreading_tracks_001` (V-1) · `bp_misreading_twosides_002` (V-2) |
| charge | `bp_charge_tending_001` (VI-1) · `bp_charge_release_002` (VI-2) · `blueprint_charge_tending_age3_001` (3-4) |

### 3.4 KEEP edilenler (dokunulmadı)

- **52 rol-anahtarlı v2 template** — beat bildirmedikleri için besteci onları
  seçmiyor (`OfflineStoryComposer` yalnızca `realizesBeat`'e bakar), ama tema
  kapsamını (`checkThemeCoverage`) bunlar taşıyor. Silmek yeni hata üretirdi.
- **23 pilot template** — hepsi v3 tarafından yükleme anında değiştiriliyor,
  yani bugün ölü. v3 dosyalarından biri okunamazsa geri düşülecek katman olarak
  bırakıldı. Emekliye ayrılmadılar.
- **Tüm setting / companion / object kayıtları** — §5 gereği tek bir kayıt bile
  eklenmedi, çıkarılmadı, yeri değiştirilmedi.
- **4 `storyIdea`** — sırası ve içeriği birebir korundu (§4).

---

## 4. `storyIdeas` — yaratma akışının ilk ekranı

`storyIdeas` **yalnızca** `pilot_library_v1.json` içinde vardır (4 kayıt) ve
`StoryIdeaStep`'i besler. Bu turda **taşınmadı, değiştirilmedi, yeniden
sıralanmadı** — dosyadaki yerlerinde duruyorlar.

| id | `preferredFamilies` | Yaş | Bugün karşılığı olan blueprint |
|---|---|---|---|
| `idea_mysterious_signal_001` | unexplained, threshold | 5-6 | I-1, I-2, I-3, II-1, II-2 |
| `idea_someone_needs_us_001` | appeal | 5-6 | III-1, III-2, III-3 |
| `idea_follow_the_traces_001` | absence, misreading | 5-6 | IV-1, IV-2, V-1, V-2 |
| `idea_someone_to_look_after_001` | charge | 3-4 | `blueprint_charge_tending_age3_001` |

Migration'dan sonra **dört fikrin dördü de öncekinden daha fazla blueprint'e**
çözülüyor; hiçbiri boşta kalmadı. Yeni `bp_charge_tending_001` ve
`bp_charge_release_002` (5-6 bandı, charge) şu an hiçbir `storyIdea`'nın
`ageRange`'ine denk gelmiyor — 5-6 bandı için bir "bakılacak biri" fikri
eklenmesi açık iş olarak kalıyor (§7.4).

---

## 5. ⚠ Kayıt SIRASI ve SAYISI yük taşıyor

`OfflineSelection.orderedCandidates` (`OfflineSelection.swift:252`, `:290`)
uygun kayıtları **katalog dizi sırasında** toplar, sonra
`DeterministicPicker.index(count: admissible.count, seed:, salt:)` ile bir
başlangıç indeksi seçer.

Bunun anlamı:

1. `settings`, `companions`, `objects` dizilerinde bir kaydı **yeniden
   sıralamak, silmek veya araya eklemek** — hatta **sona eklemek** — o eksendeki
   `count` değerini veya sırayı değiştirir ve **saklanmış seed'ler başka içeriğe
   çözülür**. Sessizdir; hata vermez.
2. `blueprints` bu sorundan korunuyor: `BlueprintSelector.ranked` seçmeden önce
   `id`'ye göre sıralıyor.
3. Bir blueprint'in `requires`/`forbids` kısıtını değiştirmek de aynı etkiyi
   yaratır — dizi değişmese bile **uygun havuzun üyeliği ve boyutu** değişir.

**Bu turda uygulanan kural:** üç içerik ekseninin hiçbirine dokunulmadı.
Doğrulama migration script'ine gömülü ve her çalıştırmada yeniden kanıtlanıyor:

```
settings:   order + membership identical (6 records)
companions: order + membership identical (5 records)
objects:    order + membership identical (8 records)
templates:  order + membership identical (23 records)
storyIdeas: order + membership identical (4 records)
shared library content axes: order + membership identical
```

### ⚠ Yine de bu migration mevcut saklanmış seed'leri GEÇERSİZ KILAR

Üç eksen sabit kalsa da, §3.2'deki beş MERGE blueprint'in `requires`/`forbids`
kısıtları ve sayfa/beat dizileri değişti. Dolayısıyla:

> **Bu beş blueprint'ten üretilmiş bir hikâye, aynı seed ile yeniden
> bestelenirse farklı setting/companion/discovery ve farklı metin verir.**

`OfflineDeterminismTests.testAStoredSeedRebuildsTheSameBookInAFreshProcess`
bunu tam olarak gösteriyor: sabitlenmiş seed eskiden
`setting_coral_sea_001` + `companion_dolphin_pilot_001` çözerken artık
`setting_whispering_forest_001` + `companion_rabbit_pilot_001` çözüyor, başlık
*"Yeliz'in Mercan Denizi'ndeki Arayışı"* yerine *"Yeliz ve Kayıp Yırtık Harita"*
oluyor.

Bu **ürün kararıdır**, teknik bir kaza değil: on dört blueprint'i benimsemek,
tanım gereği eski blueprint'lerin bağlama davranışını değiştirmek demektir.
Pratik risk, hikâyelerin bugün metin olarak saklanıp saklanmadığına bağlıdır —
`UserDefaults["stories"]` blob'u bestelenmiş metni tutuyorsa okuma akışı
etkilenmez, yalnızca yeniden besteleme yolları etkilenir. **Bu doğrulanmadı.**

---

## 6. Sözlükler — yalnızca bunlar geçerli

Uydurulan bir değer decode'u kırar. Kaynak: `ContentTraits.swift`,
`StoryBeat.swift`, `EmotionalArc.swift`, `ContentPrimitives.swift`.

- **`SettingTrait`** — `canConceal` `hasThreshold` `hasHeight` `hasWater`
  `isEnclosed` `isOpen` `showsTraces` `isTended` `hasWeather` `isHazardous`
- **`ThresholdKind`** — `opening` `span` `social`
- **`CompanionTrait`** — `hasLocalKnowledge` `isLiteralMinded` `canFly`
  `canCarry` `canSwim` `isSmall` `isStrong` `isQuick` `isPlayful` `isPatient`
- **`CompanionRole`** (casting) — `guide` `needsCare` `hesitant` `reassuring`
- **`DiscoveryTrait`** — `isUnexplained` `emitsSignal` `impliesPresence`
  `impliesNeed` `isFragmentary` `isFragile` `isBeautiful` `isVisible` `isAudible`
- **`NarrativeFamily`** — `unexplained` `threshold` `appeal` `absence`
  `misreading` `charge`
- **`PageRole`** — `hook` `discovery` `companion` `problem` `attempt` `challenge`
  `resolution` `emotional_ending` `celebration` `bedtime_transition`
- **`StoryBeat`** — 34 değer, `StoryBeat.swift`
- **`EmotionalState`** — yoğunluk 0: `ease` `calm` `warmth` `joy` `relief`
  `pride` `delight` `insight` `satisfaction` · yoğunluk 1: `curiosity` `wonder`
  `puzzlement` `determination` `surprise` `tenderness` `certainty` `duty`
  `sympathy` · yoğunluk 2: `unease` `hesitation` `concern` `doubt` `effort`
  `frustration` `patience` · yoğunluk 3 (**5-6'da yasak**): `fear` `panic`
  `grief` `despair`

**Bugün kullanılan `theme` değerleri** (snake_case): `courage` `discovery`
`friendship` `problem_solving` `kindness` `helping_others` `patience`
`responsibility` `trying_again` `calm` `good_night`.
Bunlardan yalnızca ilk dördü template `compatibleThemes` tarafından kapsanıyor;
kalanlar **migration'dan önce de** `theme_without_templates` hatası üretiyordu
(hata seviyesi, fatal değil). Bu migration yeni bir kapsanmayan tema eklemedi.

---

## 7. Yeni blueprint yazma kuralları

### 7.1 Geçmesi gereken kapılar

`BeatSequenceValidator` + `CatalogIntegrityChecker` 8 sayfalık bir yay için:

- Her beat'in `requires` ön koşulu, kendisinden önceki sayfalarca üretilmiş
  olmalı (`StoryBeat.requires` / `.produces`).
- `obstacleNamed` **5. sayfaya kadar** doğru olmalı — tek istisna `duration`
  mekanizması, yani **Aile VI**. VI bir engel adlandırmamalı.
- Hikâye **tam 7. sayfada** çözülmeli (`resolved`): ne erken ne geç.
- Son sayfa yalnızca kapanış beat'i taşıyabilir: `warm_close` `carry_forward`
  `self_recognize`.
- Hiçbir sayfa yoğunluk 2'yi aşmamalı; **üst üste en fazla iki** sayfa yoğunluk
  2'de durabilir; son sayfanın duygusu `permittedLandings` içinde olmalı.
- Blueprint'in `ageRange` alt sınırı, ailesinin `minimumAge` değerinden küçük
  olamaz (`revelation` ve `insight` çözümleri → en az 5).
- **En az dört yasal bağlama** üretmeli — `BlueprintSatisfiabilityTests`.

### 7.2 Bilinen ve kabul edilen uyarı: `inert_page`

Aile I ve V'in 3. sayfası (`meet_companion`) `companionPresent` üretir ama
çözüm beat'i (`insight`, `reveal_truth`) arkadaşı gerektirmez — yani sayfa
yapısal olarak silinebilir. `liveness` kuralı bunu **uyarı** olarak bildirir.

Bu yeni değil: `blueprint_unexplained_reading_001` ve
`blueprint_misreading_tracks_001` bu uyarıyı migration'dan **önce de**
taşıyordu. Port bir yeni örnek ekledi (`bp_unexplained_moment_002`).

`BLUEPRINT_CATALOG_V2.md` §5 "yapısal olarak atıl sayfa: 0" diyor. Bu motorun
doğrulayıcısına göre **doğru değil** — iki doğrulayıcı 3 blueprint'te
anlaşmıyor. `SCHEMA_MERGE_PLAN.md` §5 bunu öngörmüştü: *"her anlaşmazlığı bir
porting hatası değil, bir bulgu olarak değerlendir."* Bulgu olarak kaydedildi;
katalog metnine sadık kalındı.

### 7.3 Port sırasında katalogdan bilinçli sapmalar

Hepsi gerekçeli; hiçbiri sessiz değil.

| Blueprint | Sapma | Gerekçe |
|---|---|---|
| I-2 | 5. sayfaya `obstacle_raises` destek beat'i eklendi | Katalog dizisinde hiç engel yok; motor `duration` dışındaki her ailede 5. sayfaya kadar `obstacleNamed` istiyor |
| I-1, I-3, IV-1, IV-2 | `forbids.companion: hasLocalKnowledge` geri eklendi | `MatrixCoverageTests`: *"zaten bilen bir arkadaş cevabı elden veriyor."* Pilotlarda vardı, katalogda düşmüştü |
| I-1, I-3, IV-2 | `casting` katalogdaki `guide`'a `hesitant`/`reassuring` eklenerek genişletildi | Kütüphanede 5 companion var; `guide` + `hasLocalKnowledge` yasağı havuzu tek kayda düşürüyordu. Yasak asıl işi yapıyor, `casting` dar kalmasına gerek yok |
| I-2 | `hasLocalKnowledge` yasağı **uygulanmadı** | Cevap *beklenerek* bulunuyor, bilinerek değil — yer bilen bir arkadaş premise'i kısa devre etmiyor |
| I-3 | discovery `isUnexplained ∧ isFragmentary` → `isUnexplained ∧ (isFragmentary ∨ emitsSignal)` | Kütüphanedeki tek `isUnexplained ∧ isFragmentary` keşif yırtık harita ve `explainedBy: isTended` bildiriyor; bu her bakımlı mekânı eliyor ve blueprint 3 bağlamaya düşüyordu (kapı: 4) |
| I-3 | setting kümesine `showsTraces` eklendi | Aynı sebep |
| V-1 | `forbids.companion: isLiteralMinded` geri eklendi | `MatrixCoverageTests`: *"gördüğünü aynen söyleyen bir arkadaş çocuğu 3. sayfada düzeltir."* Pilotta vardı |
| II-2 | `requires.setting` içine `allOf: ["hasThreshold"]` eklendi | §7.5'teki motor açığı — `thresholdKind` blueprint uygunluğunda hiç denetlenmiyor |

### 7.4 Açık işler

1. **5-6 bandı charge için `storyIdea` yok.** `bp_charge_tending_001` ve
   `bp_charge_release_002` hiçbir fikrin `ageRange`'ine denk gelmiyor.
   `storyIdeas`'a ekleme yapmak diziyi büyütür — §5 gereği ürün kararı.
2. **Companion arzı dar.** Katalog "hiçbir blueprint 3'ten az companion
   görmesin" diyor; kütüphanede 5 companion var ve 9 blueprint 2 companion
   görüyor. Yeni companion eklemek §5 gereği seed kaydırır.
3. **`setting_coral_sea_001` sahipsiz kaldı.** On dört blueprint'in hepsi
   setting'e bir kısıt koyuyor; mercan denizi yalnızca `hasWater` + `isOpen`
   bildiriyor ve hiçbirini karşılamıyor. Phase-4 matrisindeki
   `sea + dolphin + shell` satırı artık hiçbir blueprint'e oturmuyor.
   Seçenekler: (a) denize dürüst bir trait eklemek, (b) deniz uyumlu bir
   blueprint yazmak, (c) matrisin o satırını emekliye ayırmak.

   **Ölçüldü, uygulanmadı.** Denemede `setting_coral_sea_001`'e `canConceal`
   eklemek başarısız test sayısını **38 → 35**'e indiriyor; üstüne `showsTraces`
   eklemek **hiçbir ek fayda vermiyor** (yine 35). Yani (a) tek başına sorunun
   üçte birini çözüyor: `sea + dolphin + shell` satırı hâlâ sahipsiz, çünkü
   deniz kabuğu `impliesPresence + isBeautiful` taşıyor ve on dört blueprint
   içinde bu ikiliyi deniz'le birlikte kabul eden yok.

   Değişiklik **uygulanmadı**: bir içerik kaydının trait'ini değiştirmek uygun
   havuzun üyeliğini değiştirir (§5) ve kazanç kısmi. **Ürün kararı.**

### 7.5 Motor tarafında bildirilen açık (kod DEĞİŞTİRİLMEDİ)

> `BlueprintSelector.admissible` `requires.thresholdKind`'ı **denetlemiyor**.

`admissible` yalnızca setting/companion/discovery **trait**'lerini kontrol eder.
Bir blueprint `thresholdKind: ["social"]` istese bile, sosyal eşiği olmayan bir
setting sabitlenmişken blueprint uygun sayılır, sonra bağlama anında
`requestedContentRejected` ile patlar. Kullanıcıya "seçimlerine uyan blueprint
yok" yerine anlamsız bir ret döner.

Bu `bp_threshold_joining_002` ile ilk kez tetiklendi (`requires.thresholdKind`
kullanan ilk blueprint). İçerik tarafından `hasThreshold` trait'i eklenerek
geçici olarak kapatıldı, ama **asıl düzeltme `BlueprintSelector`'dadır —
story-engine agent'ının alanı.**

---

## 8. Kopya dosya — KALDIRILMADI

`MagicPaper/templates/offline/v2/shared_content_library_v2.json` ile paket
içindeki eşi **byte düzeyinde aynıdır** (migration sonrası da:
`c17678cd61d78c5c…`). App kopyası `project.pbxproj`'da Resources build
phase'indedir, yani `MagicPaper.app` içine kopyalanır.

`ContentCatalogLoader.locate` önce `Bundle.module`'e bakar, yani **bugün paket
kopyası kazanıyor** ve app kopyası ölü yük gibi *görünüyor*.

**Kaldırılmadı.** Gerçek cihazda paket resource bundle'ının bulunduğu
kanıtlanmadan bu kopya bir emniyet ağıdır. Kaldırmadan önce istenen kanıt:

> Gerçek bir cihazda `CatalogLoadReport.source == .packageBundle(...)`
> — `.otherBundle(...)` değil.

O kanıt gelene kadar iki kopya **senkron tutulur**; ikisine de aynı değişiklik
uygulanır ve `shasum` ile eşitlik doğrulanır.

---

## 9. Değişen dosyalar

| Dosya | Değişiklik |
|---|---|
| `StoryEngine/.../Resources/blueprints/pilot_library_v1.json` | 6 → **15 blueprint** (Schema 2). `schemaVersion: 2`, `version: 2.0.0`, yeni `note`. İçerik ekseni ve `storyIdeas` **dokunulmadı** |
| `StoryEngine/.../Resources/templates/offline/v2/shared_content_library_v2.json` | `blueprints: []` (12 emekli). `schemaVersion: 2`, açıklayıcı `note`. İçerik ve 52 template **dokunulmadı** |
| `MagicPaper/templates/offline/v2/shared_content_library_v2.json` | Yukarıdakiyle birebir aynı (senkron) |
| `docs/retired/retired_blueprints_2026-09-18.json` | **YENİ** — emekli 12 blueprint, gerekçe ve geri alma talimatı |
| `docs/MagicPaper_Content_Library.md` | **YENİ** — bu doküman |

Hiçbir `.swift` dosyası değiştirilmedi.

---

## 10. Gelecekteki katkıcılar için

1. **Schema 2 dışında üretim blueprint'i yazma.** `pageRoles`'lü eski biçim
   emeklidir; o biçimdeki bir kayıt yüklenir ama **asla seçilmez**.
2. **Yeni blueprint'in yeri** `pilot_library_v1.json` → `blueprints`.
3. **`settings` / `companions` / `objects` dizilerini yeniden sıralama, kayıt
   silme veya ekleme** — §5. Gerekiyorsa önce ürün kararı al.
4. **Prose** `templates/v3/` (5-6) ve `templates/v3-age3/` (3-4) içine, beat
   başına bir dosya. Dosya adı `beat_` ile başlamazsa **okunmaz**.
5. **`ageBand` alanını yazmayı unutma** — yoksa 3-4 satırları 5-6 masallarına
   karışır.
6. Değişiklikten sonra: `cd MagicPaper/StoryEngine && swift test --build-system native`
   (düz `swift test` bu repoda codesign hatası veriyor; `xattr -cr Sources Tests .build`
   gerekebilir).

## 11. Masal ailem satırları (FAZ 11, 4 Ekim 2026)

**Alanlar:**
- Bir v3 varyantı `familyRelations: ["sibling" | "friend" | "animal" | "imaginary"]` taşıyorsa aile satırıdır.
- Aile satırının metni `{{family.name}}` içermek zorunda.
- Hayvan satırları `{{family.kind}}` ("köpek", yumuşar) ya da `{{family.possessive}}` ("köpeği") da kullanabilir. Bu iki yuva yalnızca `["animal"]` satırında geçerlidir.

**Aile anları:**
- Katalogda `familyMoments` tanımlıdır; bugün `notice_anomaly` ve `warm_close`.
- Karakter seçildiyse bu beat'lerde yalnızca o ilişki türünün satırları kullanılır, başka beat'lerde aile satırı hiç kullanılmaz.
- Bir blueprint'in herhangi bir aile anında o tür için satır yoksa blueprint o karakterle seçilmez.

**Hayvan türleri:** `familyAnimalKinds` (`id`, `name`, `possessive`, `blocksSoftening`). Liste sabittir ve ekranda buradan gelir.

**Yazım kuralları** (`validate_beat_corpus.py` ve `CatalogIntegrity.checkFamily` denetler):
- Her aile beat'inde her ilişki türü için en az 2 satır olmalı.
- `{{…}}` ile `da/de` arasına bağlaç yazılmaz ("Ela da" ve "Bulut de" aynı satırdan çıkar).
- "Hayali varlık" yazılmaz; "hayali arkadaşı" yazılır ya da yalnızca ad kullanılır.
- Hayvan satırı türden bağımsız olmalı; balık ya da kaplumbağa da olabilir.
- `afterBeat`/`afterClosing` kısıtı konmazsa satır her blueprint'e oturur.

**Doğrulayıcı:** artık 3-4 korpusunu da (`v3-age3/`) aile kapısı için okur.

**Kapsama raporu:** `BlueprintSelector.familyCoverage`; test: `testEveryShippedBlueprintCarriesEveryRelation`.

## 12. İlgi alanı sözlüğü (FAZ 12, 4 Ekim 2026)

**Sözlük katalog verisidir**, kodda kapalı küme değil. `pilot_library_v1.json` üst düzeyinde:
`"interests": [{ "id": "animals", "name": "Hayvanlar", "symbol": "hare" }, …]`. Bugün 12 kelime
(İrem'in demosundan). `symbol` bir SF Symbol adı; `MPIcon` Lucide karşılığı varsa onu çizer, simge
seçerken `MPIconMap`'e bakın (`leaf` traktör, `pawprint` kemik çiziyor).

**Etiket alanı:** ortam, yol arkadaşı, nesne ve blueprint kayıtlarında `interests: ["animals", …]`.
`tags` ile karıştırılmaz: ortam `tags`'ı kapak dünyasını seçer, ilgi kelimesi kapağı değiştirmemeli.

**Etiketleme kuralı:** çocuk o kelimeyi seçtiğinde "bu masal bununla ilgili" denebiliyorsa etiketlenir.
Zorlama etiket yok; eşleşmenin değeri eşleşmeyenlerden ayrışmasından gelir. Etiketleme içerik kararıdır
(Batuhan onaylar); taslak `MagicPaperAPP/FAZ12_ILGI_ETIKETLERI.md`.

**Görünürlük:** bir kelime ebeveyne yalnızca **içeriği olan her bantta** kurulabilir bir masala ulaşıyorsa
gösterilir (`BlueprintSelector.availableInterests`; ulaşım binder'a sorularak hesaplanır, habitat dahil).
Ulaşmayan kelime `interest_unreachable_in_band` uyarısıyla içerik hattına düşer. Kelime eklemek için
içeriği **her iki bantta** (bugün 3-4 ve 5-6) bir masala ulaştırmak gerekir; 3-4 tek blueprint'le dar boğaz.

**Denetim:** `CatalogIntegrity.checkInterests` (tanımsız kelime ve çift tanım hata, ulaşmayan kelime uyarı),
`validate_beat_corpus.py` → `check_interest_vocabulary`. Testler: `InterestCatalogTests`
(`testTheShippedInterestMatrix` içerik eklendikçe güncellenir).

**Bulgu (4 Ekim):** Mercan Denizi, Köpük (yunus) ve Deniz Kabuğu hiçbir blueprint'e bağlanamıyor;
"Deniz" bu yüzden hiçbir banda ulaşmıyor.

## 13. Seri bölümleri (FAZ 13, 6 Ekim 2026)

Onaylı pilot: bantta iki continuation, mekanizmaları isimler silinince de ayrılır. **A, beklemek**: çocuk kalır, bakar, bekler; hiçbir şey taşınmaz. **B, yerine götürmek**: çocuk bir şeyi alıp ait olduğu yere bırakır; kimse beklemez. 3-4'te yalnız Uyku öncesi, 5-6'da üç mod. Gözden geçirme dosyası: `MagicPaperAPP/FAZ13_SERI_TASLAK.md` (repo dışı).

**Nerede:** blueprint'ler `pilot_library_v1.json` → `series.continuations`; satırlar `templates/series/beat_series_*.json` (3-4: `beat_series_age3_*`), her dosyada `"series": true`. Tek seferlik masal bu satırları görmez; bir bölüm önce seri satırlarını, o beat için yoksa normal satırları kullanır.

**Yazım kuralları (normal kuralların üstüne):**
- Yol arkadaşı tanıdık bir dosttur: tanıştırılmaz, bakıma muhtaç olan o değil. Satırlarda `castRoles` yok.
- Açılış `revisit`: çocuk tanıdık yere döner. Aile satırında ilk cümle çocuğun adını söyler. Aile karakteri her bölümde vardır: "yeni misafir", "tanışmayı merak ediyordu" gibi ilk karşılaşma dili yazılmaz.
- Hatıra `{{keepsake.name}}` hatırlanan bir şeydir, sahip olunan değil ("İkisi küçük yuvayı hatırladı"). Cümle başına konmaz (küçük harfle başlar).
- Son sayfa (`warm_close`) sakin kapanır: `?`, "yarın", "acaba", "birden", "sonra ne olacak" yok. Doğrulayıcı (`check_series_lines`) ve motor ikisi de denetler.
- 3-4'te bakım satırları bulunan şeyi adlandırmaz ("küçük şey"), çünkü yuva, fide ve ses aynı cümleye oturmalı; açılış satırları adlandırır.
- Her bölüm önceki bölümlerin satırlarından kaçınır; bu yüzden her beat için en az 4, aile anında ilişki türü başına en az 4 satır gerekir (4 bölüm).
- Yeni nesne eklenirse `keepsakeName` yazılır (yoksa `keepsake_name_missing` uyarısı).

**Bilinen sınır:** katalogda 8 nesne var. Bir yer dört yeni keşif veremezse bir keşif geri gelir (üst üste değil). Daha çok nesne bu tekrarı kaldırır.

## 14. Kitap araştırmasından gelen yazım kuralları (14 Ekim 2026)

Kaynak: çocuk kitabı araştırması (`book-intelligence` dalı, `docs/research/`). Batuhan iki öneriyi **yalnızca yazım
kuralı** olarak onayladı; motor değişmez, mevcut satırlar yeniden yazılmaz. Kurallar **yeni yazılan satırlar** için geçerlidir.
Kanıt küçük (7 kitap, tek yayınevi), bu yüzden "her sayfada yap" değil, "yerinde kullan" kurallarıdır.

### 14.1 Sayfa sonunda açık uç (`p_spread_end_hook`)

İncelenen kitapların çoğunda bazı sayfalar küçük bir soruyla biter ve cevap sayfa çevrilince gelir.

- **Yalnızca** `adventure` ve `learning` modunda, **hikâyenin ortasında** (8 sayfalık yayda 3-6. sayfalar), masal başına en fazla 2 kez.
- Soru **genel** kalır, ayrıntı vaat etmez: "Ama nasıl?", "Peki şimdi ne olacaktı?", "Bunu kim yapmıştı?".
  Sayfalar havuzdan bağımsız çekildiği için "Ama ışık nereye gitmişti?" gibi bir soru, sonraki sayfanın her varyantı o ışığı
  anlatmıyorsa çelişki üretir (bkz. PROSE_PRODUCTION_GUIDE.md, ışık/ses hatası).
- Soruyu taşıyan bir beat yazılırsa, **sonraki beat'in bütün varyantları** soruyu karşılayabilecek bir açılışla başlar
  (eylemle cevap: "Kıyı boyunca yürüyerek."). Bu sağlanmadan soru satırı eklenmez.
- **Asla:** `bedtime` modunda; son iki sayfada; seri bölüm sonunda (zaten `CalmEnding` yasaklar); tehlike ya da bilinmeyen
  üzerine soru ("Karanlıkta ne vardı?" yok, "Bunu nasıl taşıyacaktı?" olur). Sayfanın duygusu yoğunluk tavanını (2) aşmaz.
- 3-4 bandında soru 3-5 kelimedir; cümle tavanı aynen geçerli.

### 14.2 Arkadaş duyguyu yansıtır, çözmez (`p_companion_mirrors_feeling`)

İncelenen kitapların bir kısmında oyuncak ya da hayvan arkadaş çocuğun duygusunu konuşmadan yansıtır; sorunu çocuk çözer.
Resimli masallar canlı olmadığı için yalnızca **metin hali** onaylandı.

- `hesitate` ve çözüm sayfalarında (`succeed`, `restore`) arkadaşa **kısa, sessiz bir yansıtma** satırı yazılabilir:
  çocuk durunca arkadaş da durur; çocuk adım atınca arkadaş da rahatlar. Örnek: "{{companion.name}} da olduğu yerde kaldı."
  / "{{companion.name}} da derin bir nefes aldı."
- Arkadaş bu satırda **konuşmaz, öneri vermez, gerilimi çözmez.** Kararı ve eylemi çocuk yapar (ajans kuralı, §2).
- Duygunun adı konmaz; `beat_hesitate.json` kuralı gibi beden diliyle gösterilir ("korktu" yok).
- Beden varsayımı yapılmaz: arkadaş listesinde robot da var (`beat_meet_companion.json`). "Kuyruğunu salladı" yerine
  "durdu", "yanına geldi", "bekledi" gibi her türe uyan fiiller.
- `{{companion.name}}` sonrası "da/de" uyumu çözümleyiciye bırakılır; elle yazılmaz (`check_conjunctions`).
- Resim tarafı (arkadaşın çizilen duygusu) resimli masallar kendi bayrağıyla canlıya çıkana ve görsel güvenlik kapısı
  arkadaşın duygusunu sayfanın tavanına bağlayana kadar **bekliyor**.
