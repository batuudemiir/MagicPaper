# MagicPaper — İllüstrasyon Sistemi

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Tarih:** 2026-09-18
**Agent:** illustration-system
**Kapsam:** VisualSystem denetimi, prompt zinciri izi, ImageProvider envanteri, kapak planı.
**Bu turda üretim kodu değişmedi.** Denenen katalog değişikliği geri alındı; sebebi §3.4'te.

---

## 0. Tek cümlelik özet

İstenen mimari zaten var ve doğru kurulmuş; **ama üretimde çalışmıyor.** Bugün ekranda
görünen illüstrasyonlar VisualSystem'e hiç uğramadan, `3d pixar style` diyen bir legacy
yoldan geliyor. Boşluk mimaride değil, **bağlantıda**.

---

## 1. Mevcut mimari (isim karşılıkları)

Agent tanımının aradığı kavramların koddaki gerçek karşılığı:

| Kavram | Koddaki karşılık |
|---|---|
| Style Bible | `VisualSystem/Resources/visual_catalog.json` + `VisualStylePreset` |
| prompt builder | `VisualSystem/Services/PromptConstraintCompiler.swift` |
| Character Bible | `CharacterProfile` + `CharacterDescriptor` (CharacterEngine) |
| Scene spec | `SceneVisualContext` + `VisualVariant` |
| Nihai talimat | `VisualConstraintSet` |

**Paralel bir prompt sistemi kurulmadı ve kurulmamalı.**

---

## 2. Prompt zinciri — motorun içinde

`VisualConstraintSet` şöyle oluşuyor:

```
ResolvedTemplate.visualStyle        (VisualStyleResolver → ResolvedVisualStyle)
StoryScene.visualContext            (setting / timeOfDay / mood / sceneClauses)
VisualVariant                       (kamera / poz / duygu / kompozisyon)
[StoryCharacter].resolved           (CharacterEngine → CharacterIdentity)
seed                                (deterministik türetme)
        │
        ▼
VisualPlanner.compileConstraints()        StoryEngine/Services/VisualPlanner.swift:189
        │
        ▼
PromptConstraintCompiler.compile()        VisualSystem/Services/PromptConstraintCompiler.swift:48
        │
        ▼
VisualConstraintSet                       VisualSystem/Domain/VisualConstraintSet.swift:76
        │
        ▼
ImageGenerationService.generate()         StoryEngine/Services/ImageGenerationService.swift:111
        │
        ▼
ImageProvider.generateImage()             StoryEngine/Providers/ImageProvider.swift:39
```

### 2.1 Karakter kimliği bu zincire GERÇEKTEN giriyor — motorda

İlke 5 açısından motor **temiz**, hem de savunmalı biçimde:

- `PromptConstraintCompiler.compileIdentityClauses()` (satır 129–147) görünüş
  cümlelerini **yalnızca** `character.identity.descriptors` üzerinden üretir.
  Compiler'da "çocuk şöyle görünüyor" diye bir parametre **yok**.
- `VisualCompilationInput` (satır 6–32) serbest metin alanı taşımaz.
- `ImageGenerationRequest` (ImageProvider.swift:9–22) tek alan olarak
  `VisualConstraintSet` alır; yorum bunu açıkça söylüyor: "there is no free-text
  prompt parameter".
- `PromptAssembler` (StoryEngine/Services/PromptAssembler.swift:36–40) dil modeline
  görünüş yazmayı yasaklayan bir "appearance lockdown" bloğu ekler; şablon unutursa
  fallback devreye girer.
- `SceneVisualContext.sceneClauses` yorumu (VisualConstraintSet.swift:9–11):
  "Never contains character appearance — that comes from the cast, only."

Sayfa başına yeniden tanımlama yok: `identityClauses` kategoriler sabit sırada,
kategori içi alfabetik olarak derlenir — aynı kimlik her sayfada **byte-identical**
aynı cümleye derlenir. Tutarlılık ayrıca `seed` ile pekiştirilir
(`VisualPlanner.seed()`, satır 227): seed `identitySeed`'den türetilir, rastgele değil.

**Motorda İlke 5 ihlali yok.**

---

## 3. Üretimde ne oluyor — İlke 5 ve İlke 9 ihlalleri

Yukarıdaki zincirin **hiçbiri üretimde çalışmıyor.** Bugün canlı olan iki yol var ve
ikisi de VisualSystem'i atlıyor.

### 3.1 Canlı V2 yolu: hiç illüstrasyon üretmiyor

```
StoryCreationFlow.swift:148
  → StoryGenerationManager.createStory()            Services/StoryGenerationManager.swift:1450
    → OfflineStoryService.shared.compose()
    → OfflineStoryMapper.appStory()                 StoryEngineBridge/OfflineStoryMapper.swift:62
```

`OfflineStoryMapper.swift:62` sayfanın `visualScene` metnini `imagePrompt` alanına
yazar ve **orada bırakır**. Bu yolda `ImageProvider` çağrılmaz, `VisualPlanner`
çalışmaz, tek bir görsel üretilmez. Metin masalları görselsizdir.

> Bu bir hata değil, İlke 6'nın (low-cost first) sonucu. Ama şu anlama geliyor:
> **VisualSystem'in ürettiği tek bir illüstrasyon bugün üretimde yok.**

### 3.2 Canlı legacy yolu: İlke 5 ve İlke 9 ihlali

```
ContentView.swift:59 → StoryWizardView.swift:344
  → StoryGenerationManager.createCustomStory()      Services/StoryGenerationManager.swift:42
    → generateStoryInBackground()                   satır 331
      → generateImagesForStory()                    satır 397 → 218
        → FalAIImageGenerator.shared.generateImage() satır 276
```

İki somut ihlal, dosya:satır ile:

**İhlal 1 — İlke 5. Çocuğun görünüşü sayfa başına bir dil modeline yazdırılıyor.**

`Services/AIService.swift:99` — Gemini'ye verilen JSON şablonu:

```
"imagePrompt": "A cinematic illustration of \(age) year old child [doing specific
action] in [detailed setting], 3d pixar style, vibrant colors, children's book art"
```

Gemini her sayfa için bu alanı **kendi kelimeleriyle** doldurur.
`StoryGenerationManager.swift:270` bu metni alır, `:277` doğrudan görsel modeline
gönderir. Yani çocuğun sayfadaki görünüşünü **her sayfada yeniden, bir dil modeli**
tanımlıyor. `CharacterProfile`, `CharacterDescriptor`, `identitySeed` — hiçbiri bu
yola girmiyor. Kimlik yalnızca referans fotoğrafla (`referencePhotoUrl`) ve
`Int.random(in: 1000...999999)` ile üretilen bir seed'le (satır 238) taşınmaya
çalışılıyor; kodun kendi yorumu bile "Nano Banana may not support seed" diyor.

Aynı şablon `AIService.swift:828`'de de var.

**İhlal 2 — İlke 9. Görsel yön kodda sabit ve yanlış.**

`Services/FalAIImageGenerator.swift:21` — her görsele eklenen taban stil:

```
"children's storybook illustration, 3d pixar style render, cute, vibrant colors,
 soft volumetric lighting, masterpiece, 8k"
```

`3d pixar style render` + `vibrant colors` + `8k`, agent tanımının "Avoid" listesinin
(`glossy 3D`, `generic AI art`, `neon`) tam ortası. `FalImageService.swift:24` de aynı
şeyi söylüyor: `"Pixar style, vibrant colors"`.

Sonuç: bugün üretilen her illüstrasyon, MagicPaper'ın ilan ettiği görsel yönün
**tersini** uyguluyor — ve bunu VisualSystem'e hiç sormadan yapıyor.

### 3.3 Katalog, görsel yönü ne kadar temsil ediyor?

`visual_catalog.json` denetimi. **Erişilebilir tek zincir**:
`magic_paper_v1` → `storybook_painted_v1` + `paper_warm`.

| İstenen | Katalogda | Durum |
|---|---|---|
| watercolor | — | **EKSİK** |
| gouache | `soft gouache and coloured pencil texture` | var |
| paper texture | `visible paper grain` | var |
| warm cream | `warm cream paper ground` / `FDF6EE` | var |
| dusty blue | — (`night_calm`'da "moonlit blues", erişilemez) | **EKSİK** |
| muted sage | — (`forest_warm`'da "jade/moss", doygun ve erişilemez) | **EKSİK** |
| soft ochre | `mustard accents` / `E0A32E` (daha doygun) | kısmi |
| warm brown | `muted ink-brown linework` | var |
| pale peach | — (`coral_play`'de `F2B49B`, erişilemez) | **EKSİK** |
| poetic / whimsical / timeless | — | **EKSİK** |

Yasaklar tarafı (`forbiddenClauses` + `globalNegativeClauses`):

| Kaçınılacak | Katalogda | Durum |
|---|---|---|
| photorealism | `photorealistic rendering` | var |
| glossy 3D | — | **EKSİK** |
| neon | — | **EKSİK** |
| sticker aesthetics | — | **EKSİK** |
| generic AI art | — | **EKSİK** |
| inconsistent styles | `consistent character proportions across pages` | kısmi |

**En ciddi bulgu:** katalog, üretimde bugün gerçekleşen tam da o hatayı
(`3d pixar style render`) **yasaklamıyor**. Negatif listede `3d render`, `cgi`,
`pixar`, `neon`, `sticker` geçmiyor.

**İkinci bulgu — ölü veri:** `forest_warm`, `night_calm`, `coral_play` paletlerinin
hiçbirine erişilemiyor. Palet yalnızca preset üzerinden seçilir
(`VisualStylePreset.palettePresetID`) ve katalogda **tek preset** var. Üç palet
ölü veri. Kapak planının istediği "configurable palette" bugün mümkün değil.

`coral_play` ayrıca yönle çelişiyor: `bright coral and apricot tones`, `E4572E`.

### 3.4 Önerilen katalog değişikliği — denendi, geri alındı

Aşağıdaki değişiklik uygulandı, testler koşuldu ve **geri alındı**:

```jsonc
// storybook_painted_v1.mediumClauses — ekle
"soft watercolour washes with gouache body colour",
"coloured pencil texture in the edges and details",

// storybook_painted_v1.renderingConstraints — ekle
"unhurried, timeless picture-book feeling",

// storybook_painted_v1.forbiddenClauses — ekle
"3d render", "cgi", "pixar style", "glossy plastic surfaces",
"airbrushed digital gloss", "neon colours", "oversaturated colours",
"sticker art", "clip art", "vector flat illustration",

// paper_warm.paletteClauses — değiştir
"warm cream paper ground",
"dusty blue and muted sage accents",
"soft ochre and pale peach highlights",
"warm brown linework"

// paper_warm.dominantHexes — değiştir (hepsi mevcut MP token'ları)
["FDF6EE", "9BAAC6", "94CBBC", "EABA4C", "F2B49B", "7A6248"]
//  kagit100  gece200   yesim200  hardal300 mercan200 sepya500
```

Hexlerin tamamı `DesignSystem/MPTheme.swift` içinde zaten var: yeni renk icat
edilmiyor, yalnızca illüstrasyon paletinin karşılığı kaydediliyor. (Mevcut hexler
marka rampasını — `gul500`, `hardal400` — yansıtıyor; oysa alanın belgelenmiş amacı
*illüstrasyon* paletini kaydetmek.)

**Neden geri alındı:** değişiklik `GoldenFixtureTests`'te **6 testi kırıyor**
(`testSingleCharacterStory`, `testShortStory`, `testMultiCharacterStory`,
`testSceneReuseShape`, `testMaximumSupportedPageCount`,
`testPartialTextRegenerationLeavesTheRestUntouched`). Fixture `negativeClauseCount`
ve `assetFingerprints` alanlarını pinliyor; katalogdaki **her** anlamlı değişiklik
bunları oynatır — tasarım gereği.

Bu bir hata değil, **kanıt**: katalog gerçekten canlı constraint zincirini besliyor.

`GoldenFixtureTests.swift` başlığı prosedürü zaten yazıyor: *"regenerate the fixture
on purpose and say in the commit why the behaviour moved"* — `regenerateFixtures`
bayrağını bir kez `true` yapıp koşmak. Ama `Tests/StoryEngineTests/` **story-engine
agent'ının alanı**. Shared File Rule gereği fixture'ları tek başıma yeniden üretmedim.

> **Karar gerekiyor:** bu katalog değişikliği + golden fixture yenilenmesi tek
> commit'te, story-engine agent ile birlikte atılmalı. Değişiklik yukarıda hazır.

---

## 4. ImageProvider ve üç Fal servisi — D1 sonrası envanter

### 4.1 Bugünkü erişilebilirlik

| Dosya | Model / endpoint | Çağıran | Durum |
|---|---|---|---|
| `Services/FalAIImageGenerator.swift` (302) | gemini-25-flash-image/edit | `StoryGenerationManager:276`, `Views/FalAITestView.swift:217` | **CANLI** (tek gerçek yol) |
| `Services/FalImageGenerator.swift` (179) | flux/dev | **yok** | **ÖLÜ** |
| `Services/FalImageService.swift` (135) | flux/schnell | **yok** | **ÖLÜ** |
| `StoryEngineBridge/FalImageProvider.swift` (172) | gemini-25-flash-image/edit | `StoryEngineContainer:39` | **ADA** (container'ın tüketicisi yok) |

`FalImageGenerator` ve `FalImageService` bugün bile ölü: `shared` dışında hiçbir
referansları yok. Üç ayrı Fal modeli (gemini-edit, flux/dev, flux/schnell) üç ayrı
görsel dili demek — İlke 9'un "random AI illustration styles" maddesi.

### 4.2 `generateImagesForStory`'nin iki girişi

`generateImagesForStory` (satır 218) iki yerden çağrılıyor:

- satır 397 ← `generateStoryInBackground` ← `createCustomStory` ← **StoryWizardView (canlı)**
- satır 495 ← `generateCategoryStoryInBackground` ← `createCategoryBasedStory` ← **çağıran yok**

`createCategoryBasedStory`'nin dosya dışında **hiçbir çağıranı yok** — status
dokümanı bunu "günlük masallar / uzak üretim" diye canlı sayıyor ama bugün ölü.
`FalAITestView` de erişilemez (yalnızca `ImagePicker.swift:6`'da bir yorumda geçiyor).

### 4.3 D1 sonrası ne kalıyor

`createCustomStory` emekliye ayrılınca:

- `FalAIImageGenerator.swift` → **tek erişilebilir çağıranı kalmaz → ÖLÜ**
- `createCategoryBasedStory` + `generateCategoryStoryInBackground` → zaten ölü
- `generateImagesForStory` (satır 218) → her iki çağıranı da gider → **ÖLÜ**
- `AIService.swift:99` ve `:828`'deki `imagePrompt` şablonları → **İlke 5 ihlali ortadan kalkar**
- `Views/FalAITestView.swift` → zaten erişilemez

**Emeklilik listesi (illustration tarafı):**

1. `MagicPaper/Services/FalImageGenerator.swift` — bugün bile ölü, şimdi silinebilir
2. `MagicPaper/Services/FalImageService.swift` — bugün bile ölü, şimdi silinebilir
3. `MagicPaper/Views/FalAITestView.swift` — erişilemez dev aracı
4. `MagicPaper/Services/FalAIImageGenerator.swift` — `createCustomStory` ile birlikte
5. `StoryGenerationManager.generateImagesForStory` + `generateCategoryStoryInBackground`
6. `AIService.swift` `imagePrompt` alanları

1–3 bugün, D1'i beklemeden silinebilir. 4–6 `createCustomStory` ile aynı commit'te.

### 4.4 Görüşüm: kanonik olan `FalImageProvider`

**`StoryEngineBridge/FalImageProvider.swift` kanonik olmalı.** Gerekçe:

1. **Soyutlamaya uyan tek uygulama.** `ImageProvider` protokolünü uygular; UI hangi
   sağlayıcının kullanıldığını bilmez. D1'in `StoryProvider` disiplininin görsel
   karşılığı birebir budur. Üç `Services/Fal*` sınıfı ise `.shared` singleton'lar —
   view'dan da çağrılabilirler, nitekim `FalAITestView` çağırıyor.
2. **Serbest metin yolu yok.** `generateImage` yalnızca `VisualConstraintSet` alır
   (satır 40–41); prompt `constraints.positivePrompt`'tan gelir (satır 49). Kod
   yoluyla "3d pixar style" enjekte edilemez — stil yalnızca katalogdan gelir.
3. **Deterministik seed.** `Int(truncatingIfNeeded: constraints.seed)` (satır 53),
   `Int.random` değil. Aynı sayfa aynı resmi yeniden üretir.
4. **Idempotency.** `X-Request-Id` başlığı (satır 64) + `ProviderResultCache`
   (`ImageGenerationService:131`) — kayıp yanıt ikinci kez faturalanmaz. Legacy
   yolda bu yok.
5. **Referans zinciri.** `constraints.referenceLocators` → `image_urls` (satır 57):
   çoklu referans, `CharacterAssetSet.referenceChain` sırasıyla. Legacy yol tek
   `referencePhotoUrl` taşıyor.
6. **Aynı modeli kullanıyor.** Endpoint `FalAIImageGenerator` ile birebir aynı
   (`gemini-25-flash-image/edit`) — geçiş model değişikliği değil, yalnızca
   prompt'un nereden geldiğinin değişmesi.

Eksik olan tek şey `StoryEngineContainer`'ın bir tüketicisi. D1 kararı
`StoryProvider` soyutlamasını kurunca, görsel üretimi de aynı container üzerinden
`StoryOrchestrator` → `VisualPlanner` → `ImageGenerationService` →
`FalImageProvider` yolundan geçmeli. **Bu bağlantı illustration-system'in alanı
değil** (container bridge'de, orchestrator story-engine'de) — 2. dalga işi.

---

## 5. Kapak sistemi — PLAN (uygulama yok)

### 5.1 Bugünkü durum

UI tarafı **zaten toparlanmış** — reader agent'ın işi iyi:

- `Screens/StoryReader/StoryCover.swift` — uygulamadaki tek kapak bileşeni,
  iki `init` ile hem okuyucuya hem yaratma akışına hizmet ediyor (satır 95–116)
- `Screens/StoryReader/StoryCoverFace.swift` — kapağın tipografik yüzü (kart hâli)
- `Screens/StoryCreation/StoryCoverView.swift` — kendi düzeni yok, `StoryCover`'ı
  tam sayfa gösteriyor (29 satır)

**Sahiplik çakışması sanıldığı kadar büyük değil:** kapak *görünümü* tek dosyada ve
reader'ın. Eksik olan kapak *illüstrasyonu*.

### 5.2 Gerçek boşluk

- `StoryCover.coverAsset` → `Story.mpDefaultCoverAsset` (`Screens/MPStoryExtras.swift:38`)
  → sabit bundle görseli `"StoryCoverDefault"`. **Her metin masalı aynı kapağı taşıyor.**
- İllüstrasyonlu masalda `mpDefaultCoverAsset` `nil` döner → dünya işareti çizilir
  (`StoryCover.swift:83`). Yani illüstrasyonlu masalın kapağı **daha da boş**.
- `Story.coverImageFileName` legacy yolda **çocuğun ham yüklediği fotoğrafı**
  taşıyor (`StoryGenerationManager.swift:62–66` ve `129–132`). Kapak bir illüstrasyon
  değil, bir **fotoğraf**. Hem İlke 9 hem İlke 10 açısından sorunlu.
- Motor tarafında kapak kavramı **hiç yok**: `StoryScene`/`VisualAsset` sayfa
  sahneleridir; kapak için kompozisyon kuralı, layout kuralı veya asset rolü yok.

### 5.3 Önerilen mimari

Kapak, **ayrı bir sistem değil**, mevcut zincirin özel bir örneği olmalı:

```
CoverVisualContext  (= SceneVisualContext, sahne: masalın açılış setting'i)
  + VisualVariant(compositionRuleID: "cover_portrait_hero")
  + cast (protagonist, aynı CharacterIdentity)
  + seed (storyID'den türetilmiş, sayfa seed'lerinden ayrı salt)
      → PromptConstraintCompiler.compile()   ← DEĞİŞMEZ
      → VisualConstraintSet
      → ImageProvider                         ← DEĞİŞMEZ
```

Böylece kapak karakter tutarlılığını, negatif listeyi, provenance pinlerini ve
fingerprint/cache davranışını **bedava** devralır. Compiler'a tek satır eklenmez.

### 5.4 Yapılacaklar (sırayla)

**A. VisualSystem — veri ve tip (illustration-system'in alanı)**

1. `visual_catalog.json`: yeni kompozisyon kuralı `cover_portrait_hero`
   - `subjectAnchor: center`, `cameraDistance: medium`
   - `textSafeArea`: üst bant — `{ x: 0.08, y: 0.06, width: 0.84, height: 0.30 }`
     (temiz başlık alanı; `StoryCover` başlığı illüstrasyonun **altına** koyuyor,
     bu bant kararı reader ile hizalanmalı — bkz. Açık Soru 1)
   - `headroomRules`: `["illustration-led, subject reads at thumbnail size",
     "keep the title band calm and low contrast", "no action crossing the title band"]`
2. `visual_catalog.json`: yeni layout kuralı `layout_cover` (`PageLayout` için yeni
   case **gerekmez**; `fullBleedImage` yeterli).
3. **~2:3 oran sorunu.** `AspectRatio` bugün `square/portrait(3:4)/landscape/wideLandscape`
   taşıyor. **2:3 yok** (0.667 vs 0.75 — kitap kapağında gözle görülür fark).
   > **Bu enum'a case eklenemez.** `FalImageProvider.aspectRatioParameter`
   > (satır 164–171) exhaustive `switch` yapıyor ve o dosya illustration-system'e
   > **SALT OKU**. Yeni case o dosyayı derlenmez hâle getirir.
   > Seçenekler: (a) bridge sahibiyle koordineli tek commit, (b) `default` clause
   > eklenmesi, (c) V1'de `.portrait` (3:4) ile yetinilmesi. **Öneri: (c)** — kapak
   > V1'de 3:4 ile çıkar, 2:3 ayrı ve koordineli bir adım olur.

**B. StoryEngine — kapak varlığı (story-engine'in alanı, benim değil)**

4. `Story`'ye bir `coverAsset: VisualAsset?` (veya `CoverSpec`) alanı.
5. `VisualPlanner`'a `planCover(...)` — mevcut `compileConstraints` yeniden kullanılır.
6. `ImageGenerationService.generateMissing` kapak varlığını da dolaşır.

**C. Bridge + UI (bridge ve reader alanı — 2. dalga)**

7. `StoryEngineMapper`: kapak asset'ini `Story.coverImageFileName`'a bağla
   (bugün `firstImageFileName(in:)` ile ilk sayfa görselini kapak yapıyor —
   `StoryEngineMapper.swift:33`).
8. `MPStoryExtras.mpDefaultCoverAsset`: üretilmiş kapak varsa onu tercih et.
9. `StoryCover`: `artwork(width:height:)` (satır 68) illüstrasyonu `width * 1.32`
   ile ölçekliyor — 3:4 veya 2:3 asset geldiğinde bu oran gözden geçirilmeli.

**D. Yapılandırılabilirlik ("configurable palette")**

10. Kapak paletinin masala göre değişebilmesi için **birden fazla `VisualStylePreset`**
    gerekir (bugün tek preset var, üç palet erişilemez — §3.3). En küçük çözüm:
    `paper_warm` dışındaki üç paleti kullanan üç preset tanımlamak ve blueprint'in
    `visualStyleID`'sini seçtirmek. **Bu content-library ile koordinasyon ister.**

### 5.5 Açık sorular (reader agent'a)

1. `StoryCover` başlığı illüstrasyonun **altına** koyuyor (satır 35–44). Üretilecek
   illüstrasyonun `textSafeArea`'sı buna göre **alt** bant mı olmalı, yoksa kapak
   düzeni klasik "illüstrasyon altta, başlık üstte"ye mi dönmeli? Kompozisyon kuralı
   bu karara bağlı — yanlış bant, başlığın illüstrasyonun kalabalık yerine oturması
   demek.
2. `MPArcText` yay başlık, illüstrasyonlu kapakta da kalacak mı?
3. Üretilmiş kapak geldiğinde `StoryCoverFace` (kart yüzü) illüstrasyona mı dönecek,
   tipografik mi kalacak? Dosyanın kendi yorumu (satır 5–8) tipografik kalması için
   iyi bir gerekçe sunuyor: "raf, aynı görselden beş tane değil, beş farklı kitap
   sırtı gibi okunmalı." **Katılıyorum — kart yüzü tipografik kalmalı.**

---

## 6. GeneratedImageValidator

**Ne doğruluyor:** hiçbir şeyi kendisi *bakmıyor*. Bakma işi
`ImageValidationService`'te olur ve sonucu `asset.currentValidation`'a yazar;
`GeneratedImageValidator` (`Services/Validators/GeneratedImageValidator.swift`)
**yalnızca o kayıtları yayın kararına çevirir**:

- `.ready` ama kayıt yok → `image_validation_missing`
  (`.required`'da error, değilse warning)
- `.failed` → güvenlik bulgusu varsa **her modda error**; yoksa moda bağlı
- `.uncertain` → `.required`'da error
- `.providerUnavailable` → `.required`'da error
- `.skipped` → `.required`'da error, değilse info
- `imageValidationMode == .off` → hiç çalışmaz (satır 20)

Taşıyıcı kural satır 25–37'de: bir resim üretilmiş ama hiç bakılmamışsa bu sessizce
geçilmez.

**Çağrılıyor mu?** Motor içinde **evet**, üretimde **hayır**:

- `Services/Validators/StoryValidator.swift:58` — deterministik validator listesine kayıtlı
- `Domain/ChildSafetyPolicy.swift:80` — çocuk güvenliği politikasında anılıyor
- `StoryValidator` → `StoryOrchestrator` → `StoryEngineContainer` → **tüketici yok**

Yani validator doğru kurulmuş ve testleri geçiyor, ama üretimdeki tek görsel
üretim yolu (`FalAIImageGenerator`) validator'a hiç uğramıyor. **Bugün üretilen
illüstrasyonlar hiçbir doğrulamadan geçmiyor.**

Ayrıca `StoryEngineContainer.make()` `imageValidationProvider`'ı varsayılan `nil`
bırakıyor (satır 35, 73) — yorumun dediği gibi V1'de vision tabanlı denetleyici yok.
Şablonlar `.advisory` ile geliyor, yani eksik sağlayıcı raporlanır ama engellemez.

---

## 7. Blueprint Schema 2 — illüstrasyon alanları (D3 kontrolü)

`Resources/blueprints/pilot_library_v1.json`, `schemaVersion: 2`. Blueprint'lerde
**illustration requirements diye ayrı bir alan yok.** Sayfa kayıtları şunu taşıyor:

```json
{ "pageNumber": 4, "role": "problem", "beat": "hesitate",
  "supportingBeat": "commit", "emotion": "hesitation" }
```

Görsel bilgi ise template variant'larında:

```json
{ "id": "pilot_t_notice_anomaly_v1",
  "text": "...",
  "visualScene": "child pausing mid-step at the edge of the place, something faint further in" }
```

**content-library ile çelişki yok — tersine, uyum iyi.** Schema 2 üç alanıyla
VisualSystem'in üç kavramına birebir oturuyor:

| Schema 2 | VisualSystem karşılığı | Bugün bağlı mı? |
|---|---|---|
| `pages[].role` | `LayoutPredicate.beatRoles` | **evet** (layout seçimi) |
| `pages[].emotion` | `VisualVariant.emotionalBeatKey` | **HAYIR** |
| `templates[].variants[].visualScene` | `SceneVisualContext.sceneClauses` | kısmen |

İki not:

1. **`emotion` bağlı değil.** `VisualVariant.emotionalBeatKey` alanı var,
   `PromptConstraintCompiler:59-61` onu `"emotional tone: ..."` cümlesine çeviriyor —
   ama `VisualPlanner.variant(for:policy:)` (satır 175–185) yalnızca
   `compositionRuleID` set ediyor, `emotionalBeatKey` hep `nil`. Blueprint'lerin
   sayfa başına yazdığı duygu bilgisi görsele **hiç ulaşmıyor.** Bu, content-library'nin
   yazdığı veriyi bedavaya değerlendirecek küçük bir bağlantı — VisualPlanner
   story-engine'in alanında.
2. **`visualScene` iyi yazılmış.** Görünüş tarif etmiyor, kompozisyon tarif ediyor
   ("child pausing mid-step at the edge of the place"). İlke 5 açısından doğru
   alışkanlık. Yeni blueprint portlanırken bu disiplin korunmalı:
   **`visualScene` asla saç/göz/ten/kıyafet yazmamalı.**

---

## 8. Özet — sıradaki adımlar

| # | İş | Alan | Bekliyor |
|---|---|---|---|
| 1 | `FalImageGenerator.swift` + `FalImageService.swift` + `FalAITestView.swift` sil | Services/Views | hiçbir şey — bugün ölü |
| 2 | Katalog değişikliği (§3.4) + golden fixture yenileme | VisualSystem + Tests | story-engine koordinasyonu |
| 3 | `createCustomStory` emekliliği → `FalAIImageGenerator` + `AIService` imagePrompt | StoryGenerationManager | D1 uygulaması |
| 4 | `StoryEngineContainer`'ı tüketiciye bağla → görsel üretimi motora taşı | Bridge + story-engine | 2. dalga |
| 5 | `VisualPlanner`'da `emotionalBeatKey` bağla | story-engine | — |
| 6 | Kapak: kompozisyon kuralı + `planCover` + mapper | VisualSystem → engine → reader | §5.5 yanıtları |
| 7 | Çoklu `VisualStylePreset` (configurable palette) | VisualSystem + content-library | — |

---

## 9. B2 — Avatar + hazır sahne kütüphanesi (2026-10-01, Faz 1)

Ayrıntılı plan: `docs/B2_SCENE_LIBRARY_PLAN.md`. Bu bölüm yalnızca mimari yeri özetler.

B2, VisualSystem'in prompt zincirine **paralel bir prompt sistemi değildir**. Ürettiği bir prompt yok. Uzak üretim de yok. Geliştirme zamanında çizilmiş katmanları, deterministik bir seçimle üst üste koyar. `StoryArtKit` deseninin sayfa düzeyindeki karşılığıdır.

Zincir: masal → beat → sahne → avatar pozu → katmanlı birleştirme.

| Parça | Dosya | Not |
|---|---|---|
| Avatar seçimi | `Screens/ArtKit/SceneBook/AvatarSpec.swift` | yalnızca kit parça kimlikleri, `String` |
| Avatar kiti | `Screens/ArtKit/avatar_kit.json`, `SceneBook/AvatarKit.swift` | 8 poz, 512 × 768 tuval; her parça `descriptor.en/tr` taşır |
| Sahne kütüphanesi | `Screens/ArtKit/scene_library.json`, `SceneBook/SceneLibrary.swift` | 12 yer tutucu sahne (3 ortam × 4 rol), sürümlü, yaşam döngülü |
| Eylem sözleşmesi | `scene_library.json → direction` | beat → poz, rol → poz, sahnenin varsayılanı |
| Seçici | `SceneBook/SceneSelector.swift` | yalnızca Foundation, deterministik, FNV-1a (`StableHash` ile aynı) |
| Anlık görüntü | `SceneBook/StoryIllustration.swift`, `Story.illustration`, `StoryPage.scene` | çözücüler atmaz |
| Motor köprüsü | `StoryEngineBridge/IllustratedBookBinder.swift` | `ComposedStory` → seçici girdisi; Faz 4'e kadar `createStory`'ye bağlı değil |

**CharacterEngine ile ilişki.** Görünüşün anlamı CharacterEngine sözlüğündedir. `AvatarKit.descriptors(for:)` her parçayı `.parentProvided` bir `CharacterDescriptor`'a eşler. B1 geldiğinde bu liste `ProfileCharacterSource.makeProfile(parentProvidedDescriptors:)`'a girer; bugün bağlı değildir. Sözlüğe altı `t-shirt` / `tişört` ifadesi eklendi (kıyafet descriptor'ı).

**§3.3 ile ilişki.** Legacy yolun `3d pixar style` sorunu B2'yi etkilemez. B2 hiçbir zaman uzak üretim yapmaz.
