# MagicPaper — Mimari Referans

**Tarih:** 2026-09-18
**Rol:** product-architect
**Durum:** Bu doküman bugünün mimarisinin tek doğru referansıdır.
**Kapsam:** Salt inceleme. Bu turda hiçbir üretim kodu değiştirilmedi.

Bu doküman `docs/ARCHITECTURE_AUDIT.md` (2026-09-15) yerine geçer; o doküman
**eskimiştir** ve §10'da hangi iddialarının artık yanlış olduğu tek tek yazılıdır.
`docs/MagicPaper_MultiAgent_Status.md` bugünün lead audit'idir; bu doküman onu
bağımsız olarak doğruladı, dört noktada düzeltti (§11) ve genişletti.

**Doğrulama yöntemi:** her iddia `project.pbxproj`, kaynak dosya veya JSON
üzerinde tek tek okundu. Doğrulanamayan hiçbir iddia buraya alınmadı.
Doküman içindeki satır numaraları bu tarihteki çalışma kopyasına aittir.

---

## 1. Katman haritası

Dört katman var ve sınırları gerçekten ayrı.

```
┌─ Swift Package: MagicPaper/StoryEngine (yerel, target'a BAĞLI) ─────────┐
│                                                                        │
│  EngineFoundation      SemanticVersion, StableHash                     │
│        ↑                                                               │
│  CharacterEngine       CharacterProfile, CharacterDescriptor,          │
│        ↑               CharacterResolver, DescriptorLexicon            │
│        │               Resources/lexicons.json                         │
│  VisualSystem          VisualStylePreset, PromptConstraintCompiler,    │
│        ↑               VisualCatalog · Resources/visual_catalog.json   │
│        │                                                               │
│  StoryEngine           Content/ · Domain/ · Offline/ · Providers/ ·    │
│                        Services/ · Resources/ (korpus)                 │
└────────────────────────────────────────────────────────────────────────┘
                                   ↑ import
┌─ Bridge: MagicPaper/MagicPaper/StoryEngineBridge ──────────────────────┐
│  OfflineStoryService · OfflineStoryMapper          ← CANLI             │
│  StoryEngineContainer · StoryOrchestrator sarmalı  ← ÖLÜ               │
│  FileStores · StoryEngineMapper · FalImageProvider ← ÖLÜ               │
│  GeminiStoryAIProvider · ProfileCharacterSource    ← ÖLÜ               │
│  FileAssetDeleter                                  ← ÖLÜ               │
└────────────────────────────────────────────────────────────────────────┘
                                   ↑
┌─ App servisleri: MagicPaper/MagicPaper/Services ───────────────────────┐
│  StoryGenerationManager (1540) · AIService (1397) · ProfileManager     │
│  SubscriptionManager · RevenueCatManager · DailyStoryManager           │
│  FalAIImageGenerator · FirebaseImageUploader · FileManagerService      │
│  TextStoryManager · LocalizationManager · LocalNotificationManager     │
└────────────────────────────────────────────────────────────────────────┘
                                   ↑
┌─ Ekranlar: Screens/ + Views/ + DesignSystem/ ──────────────────────────┐
│  ContentView (kök) → MPTabBar → Home · Library · Daily · Parent        │
│  fullScreenCover: StoryCreationFlow · StoryWizardView ·                │
│                   StoryReaderView · PaywallView · ParentalGateView     │
└────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Xcode bağlantısı — doğrulandı

`MagicPaper.xcodeproj/project.pbxproj`:

| Bulgu | Satır | Değer |
|---|---|---|
| `XCLocalSwiftPackageReference` | 732-735 | `relativePath = StoryEngine` |
| Ürün bağımlılıkları (app target) | 768-779 | `StoryEngine`, `CharacterEngine`, `VisualSystem` |
| `StoryEngineBridge` | 115 | `PBXFileSystemSynchronizedRootGroup` |
| App target `fileSystemSynchronizedGroups` | 318-322 | `DesignSystem`, `Screens`, `Helpers`, `StoryEngineBridge` |
| `MagicPaperTests` target | 290-301 | mevcut, `fileSystemSynchronizedGroups` ile |
| Uzak paketler | 739-756 | firebase-ios-sdk, purchases-ios-spm |

**Engine bağlı.** `EngineFoundation` doğrudan ürün bağımlılığı değil — transitif
olarak geliyor. Bu bugün sorun değil; app kodu `EngineFoundation`'ı doğrudan
import etmiyor. Etmek isterse ürün listesine eklenmesi gerekir.

`StoryEngineBridge` bir *senkronize klasör grubu*. Yani klasöre konan her `.swift`
otomatik derlenir; `project.pbxproj` düzenlemek gerekmez. Bu, ölü bridge
dosyalarının fark edilmeden derlenmeye devam etmesinin de sebebi.

---

## 2. Canlı üretim yolu

Tek canlı hikâye üretim yolu budur:

```
MPTabBar "Masal yarat" → MPAppState.startStoryCreation()
  → ContentView.fullScreenCover → StoryCreationFlow            (Screens/StoryCreation/)
      phase .idea      → StoryIdeaStep    → OfflineStoryService.storyIdeas(forAge:)
      phase .companion → CompanionStep    → OfflineStoryService.companionCandidates(forIdeaID:)
      phase .preparing → StoryGenerationManager.createStory()  (Services/…:1450)
          → OfflineStoryService.shared.compose()               (Bridge:118)
              → ContentCatalogLoader().load()                  (Paket)
              → OfflineStoryComposer().compose()               (Paket)
          → OfflineStoryMapper.appStory()                      (Bridge)
          → recordBlueprintRead()  → UserDefaults "read_history_<profileID>"
          → stories.insert(at: 0) → saveStories() → UserDefaults "stories"
      phase .cover     → StoryCoverView
      phase .reading   → StoryReaderView (akışın *içinde*, ayrı sunum değil)
      phase .failed    → StoryCreationFailureView
```

Bu yol CLAUDE.md İlke 6'ya uyuyor: deterministik, uzak AI çağrısı yok, seed
saklanıyor (`Story.origin: StoryOrigin` → `seed`, `storyIdeaID`, `blueprintID`,
`settingID`, `companionID`). Aynı seed + aynı girdi = aynı kitap.

### 2.1 Katalog gerçekte ne yüklüyor

`ContentCatalogLoader.load()` **üç katmanı birleştirir** — bu, lead audit'in
"iki ayrı şema, birini seç" tablosunun düzeltilmesi gereken yeri:

| Sıra | Belge | Zorunlu mu | Ne katıyor |
|---|---|---|---|
| 1 | `shared_content_library_v2.json` | **Zorunlu** | settings/companions/objects/events/challenges/endings/templates/blueprints (V1 şema) |
| 2 | `pilot_library_v1.json` | Opsiyonel katman | schema 2 blueprint'ler, trait'ler, **`storyIdeas`** |
| 3 | `templates/v3/*` + `templates/v3-age3/*` | Opsiyonel katman | beat başına düzyazı; kapsadığı beat'lerde katalog template'lerini **değiştirir**, eklemez |

Sonuç üç önemli gerçek:

1. **`storyIdeas` yalnızca `pilot_library_v1.json` içinde var (4 adet).** Yaratma
   akışının ilk ekranı tamamen bu dosyadan besleniyor. Yani "pilot kütüphane"
   deneysel bir yan dal değil — **canlı UI'ın kaynağı.**
2. Arama sırası `Bundle.module` → diğer bundle'lar. Paket bundle'ı her zaman
   kazanır. `MagicPaper/templates/offline/v2/shared_content_library_v2.json`
   (app bundle kopyası, md5 `4e80091…` ile paket kopyasıyla **birebir aynı**)
   canlı yolda hiç okunmuyor. Gölge kopya.
3. SwiftPM `.process` kuralı `Resources/**`'ı bundle kökünde **düzleştirir**.
   Bu yüzden `BeatCorpusLoader` ve `BuiltInTemplates` `subdirectory: nil` ile
   arıyor. Klasör yapısı yalnızca yazım kolaylığı; çalışma zamanında yok.
   Dosya adları bu yüzden globalde benzersiz olmak zorunda
   (`beat_commit.json` / `beat_age3_commit.json` bu yüzden ayrı adlandırılmış).

### 2.2 Korpus envanteri (sayılmış)

| Dosya / klasör | İçerik |
|---|---|
| `…/Resources/templates/offline/v2/shared_content_library_v2.json` | version `2.0.0`, schemaVersion **yok**; 12 blueprint, 16 setting, 15 companion, 20 object, 20 event, 15 challenge, 10 ending, 52 template, 0 resolution |
| `…/Resources/blueprints/pilot_library_v1.json` | schemaVersion **2**, version `1.0.0`; 6 blueprint, 6 setting, 5 companion, 8 object, 23 template, **4 storyIdea** |
| `…/Resources/templates/v3/` | 33 dosya (beat başına düzyazı, 5-6 bandı) |
| `…/Resources/templates/v3-age3/` | 8 dosya (3-4 bandı) |
| `…/Resources/templates/offline/*.json` | 13 dosya — V1 template'leri, yalnızca `BuiltInTemplates` üzerinden, o da ölü yolda |
| `MagicPaper/templates/shared_content_library_v2.json` | paket kopyasının **birebir ikizi**, canlı yolda okunmuyor |
| `MagicPaper/templates/adventure_01.json` | paket kopyasının ikizi, canlı yolda okunmuyor |

Blueprint şema farkı somut olarak şu:

| | v2 blueprint | pilot blueprint (schema 2) |
|---|---|---|
| Eksen | `genre` + `theme` | `family` (threshold / unexplained / appeal / absence / misreading / charge) |
| Sayfa tanımı | `pageRoles: [{pageNumber, role}]` | `pages: [{pageNumber, role, beat, supportingBeat, emotion}]` |
| Uyumluluk | yok | `requires` / `forbids` (trait bazlı) |
| Editöryel | yok | `editorialName`, `premise`, `editorialGuidance` |
| Başlık | yok | `titlePatterns` |

`pilot_library_v1.json` kendi `note` alanında bunu zaten yazmış: *"Deliberately
NOT merged into shared_content_library_v2.json."*

---

## 3. Ölü yollar

Aşağıdakiler **derleniyor** ama üretimde erişilemez.

### 3.1 Engine'in AI orkestrasyon yarısı

`StoryEngineContainer` yalnızca kendi dosyasında geçiyor. Tek tüketicisi yok.
Ada halindeki her şey:

| Tip | Dosya | Satır | Tek erişim yolu |
|---|---|---|---|
| `StoryEngineContainer` | `StoryEngineBridge/StoryEngineContainer.swift` | 163 | — (hiç) |
| `StoryOrchestrator` | `StoryEngine/…/Services/StoryOrchestrator.swift` | 779 | Container |
| `ProfileCharacterSource` | `StoryEngineBridge/ProfileCharacterSource.swift` | 117 | Container |
| `FalImageProvider` | `StoryEngineBridge/FalImageProvider.swift` | 172 | Container |
| `GeminiStoryAIProvider` | `StoryEngineBridge/GeminiStoryAIProvider.swift` | 160 | Container (ayrıca `FalImageProvider` hata sınıflandırması için statik olarak kullanıyor) |
| `FileStoryRepository` + kardeşleri | `StoryEngineBridge/FileStores.swift` | 145 | Container |
| `FileAssetDeleter` | `StoryEngineBridge/FileAssetDeleter.swift` | 53 | Container |
| `StoryEngineMapper` | `StoryEngineBridge/StoryEngineMapper.swift` | 85 | — (hiç) |
| `BuiltInTemplates` + `TemplateResolver` | paket | — | Container |

**Yaklaşık 1670 satır erişilemez kod**, üstelik `StoryEngineTests` altında ciddi
test kapsamıyla (`OrchestratorTests`, `RetryTests`, `IdempotencyTests`,
`PartialRegenerationTests`, `ProvenanceTests`, `DataLifecycleTests` …).

Bu kod **çöp değil**. D1'in "gelecekte `RemoteAIProvider` eklenebilir" maddesinin
hedef iskeleti tam olarak burası. Silinmemeli; bağlanmamış durumu bilinçli olarak
kayıt altına alınmalı.

### 3.2 `createCategoryBasedStory` — hiçbir çağıranı yok

`Services/StoryGenerationManager.swift:111`. Tüm kaynak ağacında tek geçtiği yer
kendi tanımı.

Lead audit bunu "Günlük masallar" yolu sanıyordu. **Değil.** `DailyStoriesView`
→ `DailyStoryManager.shared` → `createDefaultStories()`, yani **elle yazılmış,
koda gömülü Türkçe masal metinleri** (`Services/DailyStoryManager.swift:115`+,
dosya 504 satır). Bu ayrıca CLAUDE.md İlke 4 ihlali: hikâye içeriği bir servis
dosyasının içinde, Story Engine'de değil.

### 3.3 `TestOfflineTemplateStoryProvider` — çift ölü

`Services/StoryGenerationManager.swift:1306`. Tek tüketicisi `DevStoryTestView`.
`DevStoryTestView`'ın da hiçbir referansı yok — hiçbir ekrandan, hiçbir
`fullScreenCover`'dan açılmıyor.

Ayrıca **üretim kaynağında sabit bir geliştirici mutlak yolu** taşıyor:

`Services/StoryGenerationManager.swift:1322`
```
let devPath = "/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/StoryEngine/…"
```

Bu, ARCHITECTURE_AUDIT'in "cihazda `missingSharedLibrary` olarak patlar" teşhisinin
kaynağı. Paket `ContentCatalogLoader`'ı bu yüzden mutlak yol fallback'ini bilinçli
olarak reddediyor (kendi doc comment'inde yazıyor).

### 3.4 Erişilemez servisler ve ekranlar

| Dosya | Satır | Durum |
|---|---|---|
| `Services/FalImageGenerator.swift` | 179 | Hiçbir tüketici — ölü |
| `Services/FalImageService.swift` | 135 | Hiçbir tüketici — ölü |
| `Models/TextOnlyStory.swift` | 36 | Hiçbir tüketici — ölü |
| `Views/TextStoryLibraryView.swift` | 243 | Yalnızca kendi `#Preview`'u — erişilemez |
| `Views/FalAITestView.swift` | 251 | Yalnızca kendi `#Preview`'u — erişilemez dev aracı |
| `Views/FirebaseTestView.swift` | 164 | Yalnızca kendi `#Preview`'u — erişilemez dev aracı |
| `Screens/DevStoryTestView.swift` | — | Hiçbir referans — erişilemez dev aracı |
| `MagicPaper/patch.swift` | 15 | Serbest fonksiyon `getAllSearchableBundles()`, çağıranı yok |

`Services/FalAIImageGenerator.swift` (302) **canlı** ama yalnızca legacy yoldan:
`StoryGenerationManager:276` ve `FalAITestView:217`.

### 3.5 Legacy illüstrasyonlu yol — kasıtlı olarak canlı

`StoryWizardView` (456 satır) hâlâ erişilebilir: `MPAppState.startWizard(world:)`
→ `HomeView:352` ve `ParentPanelView:200` (dünya kartları). `MPAppState:79-85`'te
gerekçesi yazılı: *illüstrasyonlu masal üretmenin tek yolu bu.* Birincil eylem
değil, yan kapı.

Yani `createCustomStory` (`:42`) **canlı ve tek illüstrasyon yolu**. D1 bunu
emekliye ayırıyor; §11.1'de bunun ne anlama geldiği yazılı.

---

## 4. Bağımlılık yönü ve ihlaller

### 4.1 Doğru olan

Paketin tüm import'ları: `Foundation` (95), `EngineFoundation` (27),
`VisualSystem` (17), `CharacterEngine` (14). **Sıfır** UIKit, SwiftUI, Firebase,
RevenueCat, fal. Paket gerçekten vendor-free ve platformdan bağımsız.
Paket kaynaklarında **sıfır `print()`** var.

Ok yönü doğru: `App → Bridge → Package`. Paket hiçbir yerde app'i bilmiyor.

### 4.2 İhlal 1 — UI doğrudan engine tipleriyle konuşuyor

D1 diyor ki: *"UI hangi provider'ın kullanıldığını BİLMEMELİ."* Bugün biliyor.

| Dosya | İhlal |
|---|---|
| `Screens/StoryCreation/StoryIdeaStep.swift:2,21` | `import StoryEngine`; `[CatalogStoryIdea]` view property'si; `OfflineStoryService.shared` singleton'ına doğrudan erişim |
| `Screens/StoryCreation/CompanionStep.swift:2,22` | `import StoryEngine`; `[CatalogCompanion]`; aynı singleton erişimi |
| `Screens/StoryCreation/StoryCreationFlow.swift:2,160` | `import StoryEngine`; `catch` bloğu `OfflineStoryService.Failure` tipini tanıyor |

View'lar `Offline…` adında bir servisi ismen tanıdığı sürece ikinci bir provider
eklendiğinde her üç dosya da değişmek zorunda. D1 bunu kabul etmiyor.

### 4.3 İhlal 2 — `StoryGenerationManager` hem servis hem store hem içerik

`Services/StoryGenerationManager.swift` (1540 satır) tek dosyada şunları tutuyor:

- 4 üretim giriş noktası (`:42`, `:111`, `:1306`, `:1450`)
- Kalıcılık (`saveStories`, `loadStories`, `migrateOldStoriesIfNeeded`)
- Kütüphane davranışı (`deleteStory`, `markOpened`, `updateLastReadPage`, `adoptSampleStories`)
- Gömülü örnek hikâye içeriği (`createSampleStory`, `:1125`)
- Bir V2 DTO seti (`TestV2*`, `:1258`-`:1279`)
- Bir LCG (`TestLCG`, `:1281`)
- Türkçe ek çözümleyici adaptörü (`TurkishSuffixResolver`, `:1501`)
- 154 `print()` çağrısı

Bu dosya §12'de yazıldığı gibi beş agent'ın birden talip olduğu dosya.

### 4.4 İhlal 3 — içerik koda gömülü

- `DailyStoryManager.createDefaultStories()` — tam masal metinleri Swift içinde
- `StoryGenerationManager.createSampleStory()` / `getDemoTexts()` — aynı şey
- `StoryGenerationManager.generateCategoryTitle()` (`:1165`) — başlık tabloları

CLAUDE.md İlke 4 ihlali. Story Engine korpusuna ait.

### 4.5 İhlal 4 — entitlement dağınık

`isPremium`: 19 kullanım, 10 dosya. Kota anahtarları (`remainingImageStories`,
`freeTrialCount`, `freeImageStoryUsed`, `subscriptionTier`, `freeTrialUsed`,
`lastFreeTextStoryDate`) `SubscriptionManager`'da 72 yerde, ama ayrıca
`StoryWizardView`, `HomeView`, `SettingsView`, `ParentPanelView` içinde ikişer
yerde doğrudan okunuyor. `RevenueCatManager` (314) ile `SubscriptionManager`
(353) yan yana duruyor ve ikisi de `isPremium` yayınlıyor. Tek bir
entitlement kaynağı yok.

---

## 5. Persistence gerçeği

### 5.1 Bugün fiilen nerede ne duruyor

| Veri | Yer | Anahtar / yol | Sorun |
|---|---|---|---|
| Hikâyeler | UserDefaults | `"stories"` — tek JSON blob | 1 MB üstünde kendi kendine uyarı basıyor (`:888`); 4 MB üstünde **veriyi siliyor** (`:939`) |
| Profiller | UserDefaults | `ProfileManager` | — |
| Onboarding | UserDefaults | `hasLaunchedBefore` | Doğru yerde |
| Okuma geçmişi (novelty) | UserDefaults | `read_history_<profileID>` | Son 40 blueprint id |
| Okuma günleri | UserDefaults | `mp_readDays` | MPStreak |
| Okuma süresi | UserDefaults | `mp_readSeconds` (gün→saniye) | MPStreak; **ebeveyn ekran limiti buna bağlı** |
| Abonelik/kota | UserDefaults | 6 anahtar | — |
| Avatar rengi | UserDefaults | `mp_avatarColor_<uuid>` | Doğru yerde |
| Dil | UserDefaults | `appLanguage`, `defaultLanguage` | Doğru yerde |
| Okuyucu süsü | UserDefaults | `mp_readerOrnament` | Doğru yerde |
| Günlük masallar | UserDefaults | `DailyStoryManager` blob | Sabit içerik, saklanmasına gerek yok |
| Sayfa/kapak görselleri | Documents | dosya adı ile | Doğru yerde |
| Çocuk fotoğrafı | Documents | JPEG | Doğru yerde |

### 5.2 Kayıp koruması bugün ne durumda

`loadStories()` (`:905`) çözümleme hatasında ham veriyi
`"stories.undecodable.<epoch>"` anahtarına yedekliyor ve `assertionFailure`
atıyor. Bu **iyi** ve korunmalı — D4 migration'ında aynı davranış FileStores
tarafında da bulunmalı.

`migrateOldStoriesIfNeeded()` (`:931`) 4 MB üstünde `UserDefaults["stories"]`'i
**yedeklemeden siliyor**. D4 öncesi bu yol dokunulmadan bırakılırsa migration
sırasında veri kaybı riski var (§11.4).

### 5.3 `FileStores.swift` ne öneriyor

`StoryEngineBridge/FileStores.swift` (145) `Documents/StoryEngine` altında
hikâye/istek/iş/karakter başına birer JSON kaydı tarif ediyor
(`FileStoryRepository: StoryRepository`). Devrede değil — tek referansı ölü
`StoryEngineContainer`. D4'ün hedef tasarımı bu dosyada zaten yazılı.

---

## 6. Duplicate / deprecated envanteri

### 6.1 Çoğaltılmış dosyalar

| # | Ne | Nerede |
|---|---|---|
| 1 | `shared_content_library_v2.json` | app bundle + paket Resources — md5 aynı |
| 2 | `adventure_01.json` | app bundle + paket Resources |
| 3 | Fal görsel istemcisi ×3 | `FalAIImageGenerator` (canlı), `FalImageGenerator` (ölü), `FalImageService` (ölü) |
| 4 | Entitlement yöneticisi ×2 | `SubscriptionManager` + `RevenueCatManager` |
| 5 | Metin hikâye modeli ×2 | `TextStory` (yarı canlı) + `TextOnlyStory` (ölü) |
| 6 | Türkçe morfoloji | Tek kaynak `StoryEngine/Services/TurkishGrammar.swift`; `TurkishSuffixResolver` artık ince bir adaptör — **çözülmüş**, tekrar bölünmemeli |
| 7 | Mapper ×2 | `OfflineStoryMapper` (canlı) + `StoryEngineMapper` (ölü) |
| 8 | Hikâye domain modeli ×2 | `MagicPaper.Story` (app) + `StoryEngine.Story` (paket) — kasıtlı sınır, mapper ile köprüleniyor |

### 6.2 Ölçülmüş borç (bağımsız olarak sayıldı)

| Bulgu | Ölçüm | İlke |
|---|---|---|
| `print()` — app target | **430** (bridge'te 2) | İlke 10 |
| `print()` — paket | **0** | — |
| `os.Logger` / OSLog kullanan dosya | **0** | İlke 10 |
| — `StoryGenerationManager` | 154 | |
| — `FalAIImageGenerator` | 64 | |
| — `RevenueCatManager` | 35 | |
| — `TextStoryManager` | 33 | |
| — `AIService` | 31 | |
| — `ProfileManager` | 20 | çocuk verisi geçen dosya |
| — `MagicPaperApp` | 20 | |
| DesignSystem dışı `Color(hex:)` | 12 (MagicPaperApp 1, MPStoryExtras 8, ProfileCreationView 3) | İlke 9 |
| `.font(.system(...))` | 33 | İlke 9 |
| `isPremium` | 19 kullanım / 10 dosya | — |
| `MPStreak` | 5 dosya | İlke 7 |
| Üretim kaynağında mutlak geliştirici yolu | 1 (`StoryGenerationManager:1322`) | İlke 10 |

**Lead audit'ten fark:** lead 441 `print()` saydı, bağımsız sayım 430 veriyor.
Fark büyük olasılıkla `MagicPaperTests` veya çalışma kopyası farkı. Büyüklük
sırası aynı; karar için önemsiz.

En büyük dosyalar: `StoryGenerationManager` 1540, `AIService` 1397,
`PremiumComponents` 874, `MPSurfaces` 787, `StoryOrchestrator` 779,
`StoryDecorationCatalog+Generated` 678, `LocalizationManager` 619,
`CatalogIntegrity` 536, `DailyStoryManager` 504.

---

## 7. Test ve doğrulama durumu

| Süit | Dosya | Çalıştırma |
|---|---|---|
| `MagicPaperTests` | 10 | `TestPlan.xctestplan` içinde — Xcode ile çalışır |
| `StoryEngineTests` | 45 | `swift test` — **test planında yok** |
| `CharacterEngineTests` | 7 | `swift test` — test planında yok |
| `VisualSystemTests` | 5 | `swift test` — test planında yok |
| `EngineFoundationTests` | 2 | `swift test` — test planında yok |

**Boşluk:** `TestPlan.xctestplan` yalnızca `MagicPaperTests` hedefini içeriyor.
Paketin 59 test dosyası Xcode/CI akışında koşmuyor. D1–D4'ün her biri paket
testlerine dayanacak; bu boşluk kapatılmadan "testler geçti" ifadesi anlamsız.

`MagicPaperTests` şu anda tam olarak canlı yolu koruyor: `AgeBandCoverageTests`,
`CompanionSymbolTests`, `OfflineStoryMappingTests`, `StoryPersistenceTests`,
`ReaderStoryMappingTests`, `ReaderProgressTests`, `ContinueReadingTests`,
`StoryReaderModelTests`, `ParentControlsTests`. **D4 `StoryPersistenceTests`'i,
D2 `ParentControlsTests`'i doğrudan etkiler.**

---

## 8. Agent metinleri ile kod arasındaki isim eşlemesi

Lead audit §4'teki tablo doğrulandı ve genişletildi. ✅ = doğrulandı.

| Agent metninin aradığı | Koddaki gerçek karşılık | |
|---|---|---|
| `ChildProfile` | `UserProfile` (`Services/ProfileManager.swift:26`) — id, name, age, profileType, imageFileName, createdAt | ✅ |
| `CharacterBible` | `CharacterProfile` + `CharacterDescriptor` + `CharacterStyleProfile` + `CharacterEngine/Resources/lexicons.json` | ✅ |
| `StoryProvider` | `StoryAIProvider` protokolü (`StoryEngine/Providers/StoryAIProvider.swift`) | ✅ |
| `OfflineTemplateAIProvider` | Bugün **protokolü uygulamıyor**: `OfflineStoryService` (bridge) + `OfflineStoryComposer` + `BlueprintSelector` (paket). D1 bunu `StoryAIProvider` arkasına almayı istiyor | ⚠️ |
| `RemoteAIProvider` | `GeminiStoryAIProvider` (bridge, ölü) | ✅ |
| `OnDeviceAIProvider` | **yok** | ✅ |
| `StyleBible` | `VisualSystem/Resources/visual_catalog.json` + `VisualStylePreset` + `VisualStyleResolver` | ✅ |
| prompt builder | `PromptConstraintCompiler` (VisualSystem) ve `PromptAssembler` (StoryEngine) — **iki ayrı şey**, biri görsel kısıt biri metin promptu | ✅+ |
| `StoryBlueprint` (tip) | `CatalogBlueprint` (`StoryEngine/Content/CatalogBlueprint.swift`) — lead "tip yok" demişti, **var** | ❌ düzeltildi |
| `StoryMemory` | **yok**. En yakın şey `UserDefaults["read_history_<profileID>"]`, son 40 blueprint id'si | ✅ |
| `seriesID`, `sequenceNumber` | **yok** | ✅ |
| `Favorites` | **yok** | + |
| Story provenance | `StoryOrigin` (`Models/Story.swift:73`) — seed, storyIdeaID, blueprintID, settingID, companionID. Ayrıca paket tarafında `GenerationProvenance` | + |
| `StoryIdea` | `CatalogStoryIdea` (paket) — yalnızca `pilot_library_v1.json`'da veri var | + |
| `TemplateRepository` | `StaticTemplateRepository` + `BuiltInTemplates` — ölü yolda | + |
| Beat modeli | `StoryBeat`, `BeatPlanner`, `BeatCorpusLoader`, `BeatSequenceValidator`, `NarrativeStateModel` | + |
| `docs/` (root) | `MagicPaper/docs/` | ✅ |
| `MagicPaper/MagicPaper` | App target kaynak kökü (repo kökünden `MagicPaper/MagicPaper/`) | + |

---

## 9. Eski audit'in artık yanlış olan iddiaları

`docs/ARCHITECTURE_AUDIT.md` (2026-09-15) şu noktalarda **eskimiştir**:

| Eski iddia | Bugünkü gerçek |
|---|---|
| *"neither the local package nor bridge sources are linked by `MagicPaper.xcodeproj`"* | Yanlış. `XCLocalSwiftPackageReference` var (pbxproj:732), üç ürün bağlı, bridge senkronize grup |
| *"`MagicPaper.xcodeproj` has Firebase and RevenueCat package dependencies only"* | Yanlış. StoryEngine/CharacterEngine/VisualSystem de bağlı |
| *"The app target has no XCTest target"* | Yanlış. `MagicPaperTests` var, 10 dosya, test planı mevcut |
| *"the production app cannot use the packaged engine"* | Yanlış. Üretim akışı paketi **kullanıyor** |
| *"Prototype offline V2 path … reachable only through the secondary button in `StoryWizardView`"* | Yanlış. `StoryWizardView` artık onu çağırmıyor; tek tüketicisi erişilemez `DevStoryTestView` |
| *"The current wizard asks child → type → direction → world … does not offer the requested three-choice V2 ritual"* | Kısmen. Yeni ritüel `StoryCreationFlow` olarak var ve **iki** adım (fikir → yoldaş); wizard yan kapı olarak duruyor |
| *"False determinism … creates its request seed with `UInt64.random`"* | Düzeltilmiş. `OfflineStoryService.compose()` seed'i üretiyor **ve saklıyor**; `Story.origin.seed` |
| *"Library filtering uses child name rather than profile ID"* | Düzeltilmiş. `Story.childProfileID` + `belongs(to:)` var; eski kayıtlar isimle eşleşiyor |
| *"World and companion are hardcoded to `setting_forest_001` / `companion_fox_001`"* | Düzeltilmiş — `createStory` doc comment'inde gerekçesiyle yazılı |
| *"`swift test` fails due to resource-bundle code-signing error"* | Bu turda doğrulanmadı. Yeniden ölçülmeli |

Hâlâ **geçerli** olan eski uyarılar: iki hikâye modeli, UserDefaults blob'u,
`FileStores` atıl, katalog kopyası, `TestOfflineTemplateStoryProvider`'ın
üretim dosyasında oluşu.

---

## 10. Lead audit'e yapılan dört düzeltme

1. **`createCategoryBasedStory` günlük masalları üretmiyor.** Hiçbir çağıranı
   yok. Günlük masallar `DailyStoryManager.createDefaultStories()` içinde koda
   gömülü. Yani üretim yolu sayısı fiilen **dört değil iki**: `createCustomStory`
   (legacy, illüstrasyonlu, canlı) ve `createStory` (V2, offline, canlı).
   Kalan ikisi ölü.
2. **`TestOfflineTemplateStoryProvider` çift ölü.** Tek tüketicisi
   `DevStoryTestView`, onun da hiçbir referansı yok. Ayrıca sabit bir mutlak
   geliştirici yolu taşıyor (`:1322`).
3. **İçerik kütüphanesi "ikiye bölünmüş" değil, üç katmanlı ve birleşiyor.**
   `ContentCatalogLoader` v2'yi zorunlu taban, pilot'u opsiyonel katman, v3
   korpusunu üstüne yazan katman olarak yüklüyor. Kritik olan: **`storyIdeas`
   yalnızca pilot kütüphanede var**, yani canlı UI'ın ilk ekranı pilot
   kütüphaneden besleniyor. "Hangisi kalacak" sorusu bu yüzden basit bir
   seçim değil.
4. **`StoryBlueprint` tipi var:** `CatalogBlueprint`. Lead "tip yok" demişti.

Ek olarak lead'in listelemediği ölü kod: `FalImageGenerator`, `FalImageService`,
`TextOnlyStory`, `StoryEngineMapper`, `patch.swift`, `FalAITestView`,
`FirebaseTestView`, `TextStoryLibraryView` (~1100 satır).

---

## 11. Alınmış kararlar ve teknik sonuçları

D1–D4 kullanıcı tarafından karara bağlanmıştır. Aşağıda kararlar tartışılmaz;
yalnızca uygulama sonuçları haritalanır.

### 11.1 D1 — Tek kanonik üretim yolu

**Karar.** Hedef mimari:

```
Story Creation UI → Story Engine → StoryProvider → OfflineTemplateAIProvider
```

- UI hangi provider'ın kullanıldığını bilmeyecek (soyutlama gereksinimi).
- Legacy `createCustomStory` emekliye ayrılacak.
- `TestOfflineTemplateStoryProvider` üretim kodundan çıkacak.
- Test mock/stub'ları **silinmeyecek**; test altyapısı üretim mimarisinden ayrılacak.
- Gelecekte `OnDeviceAIProvider` / `RemoteAIProvider` eklenebilir.

**Etkilenen dosyalar**

| Dosya | Ne olacak |
|---|---|
| `StoryEngine/Providers/StoryAIProvider.swift` | Offline composer'ın uyacağı protokol. Bugün AI-merkezli imzası offline'a uyuyor mu — **ilk iş bu kontrol.** |
| `StoryEngine/Offline/OfflineStoryComposer.swift` | `StoryAIProvider` uygulamasıyla sarılacak (`OfflineTemplateAIProvider`) |
| `StoryEngineBridge/OfflineStoryService.swift` | Provider-nötr bir cepheye dönüşecek; adı `Offline` içermemeli |
| `Screens/StoryCreation/StoryIdeaStep.swift` | `import StoryEngine` kalkacak; `CatalogStoryIdea` yerine view DTO |
| `Screens/StoryCreation/CompanionStep.swift` | Aynı |
| `Screens/StoryCreation/StoryCreationFlow.swift` | Aynı; `catch` provider-nötr hata tipine bakacak |
| `Services/StoryGenerationManager.swift` | `:42`, `:111`, `:1244`-`:1435` bloğu çıkacak; `:1450` cepheye taşınacak |
| `Screens/StoryWizardView.swift` (456) | `createCustomStory` çağrısı düşünce ekranın kendisi de düşer |
| `Screens/MPAppState.swift:79-87` | `showWizard` / `wizardPreset` / `startWizard` kalkar |
| `Views/HomeView.swift:352`, `Screens/ParentPanelView.swift:200` | Dünya kartlarının hedefi değişir |
| `Screens/DevStoryTestView.swift` | Silinir veya `#if DEBUG` altına alınır |
| `Services/AIService.swift` (1397) | Yalnızca legacy yolun tüketicisiyse emekliye ayrılır |
| `Services/FalAIImageGenerator.swift` (302) | Aynı |

**Sıra (bozulmayı önleyen tek sıra budur)**

1. `StoryAIProvider` imzasının offline composer'a uyduğunu doğrula. Uymuyorsa
   **önce protokolü genişlet** — yeni protokol yazma.
2. `OfflineTemplateAIProvider` sarmalını paket içinde yaz + test et. Davranış
   değişmemeli: `OfflineStoryMappingTests` ve `AgeBandCoverageTests` yeşil kalmalı.
3. Provider-nötr cepheyi ve view DTO'larını (`StoryIdeaCard`, `CompanionCard`)
   ekle. Üç view'ı DTO'ya geçir. Bu adımda `import StoryEngine` üç dosyadan kalkar.
4. `createStory` gövdesini cepheye taşı, `StoryGenerationManager`'da yalnızca
   kütüphaneye yazan ince bir çağrı bırak.
5. `TestOfflineTemplateStoryProvider` + `TestV2*` + `TestLCG` + `DevStoryTestView`
   bloğunu kaldır (~190 satır, mutlak geliştirici yolu dahil).
6. **En son:** legacy illüstrasyon yolunu emekliye ayır.

**Riskler**

- **⚠️ En kritik:** `createCustomStory` kaldırıldığında **illüstrasyonlu masal
  üretme yeteneği tamamen kaybolur.** `MPAppState:79-85` bunu açıkça yazıyor:
  yerini alacak özellik ("var olan bir masalı resimli kitaba çevirmek") **henüz
  yok**. Adım 6, o özellik gelene kadar **beklemelidir**. D1'i bu adım olmadan
  da "tek kanonik yol" olarak tamamlamak mümkün: adımlar 1-5 legacy yolu
  ellemeden hedef mimariyi kurar.
- Adım 5, üretimde erişilemez kodu siliyor — düşük risk. Ama `TestV2*` DTO'ları
  başka bir yerde kullanılıyorsa derleme kırılır; kaldırmadan önce grep şart.
- Adım 3 üç view dosyasını değiştiriyor; `ui-agent` ve `parent-ux` ile çakışır.

**2. dalgaya kalan**

- `OnDeviceAIProvider` ve `RemoteAIProvider`. Ada halindeki
  `StoryOrchestrator` + `StoryEngineContainer` bunun iskeleti — **silinmemeli**,
  bağlanmamış durumu kayıtlı kalmalı.
- `AIService` (1397) ve `FalAIImageGenerator` (302) emekliliği, illüstrasyon
  özelliği geldiğinde.

### 11.2 D2 — `MPStreak` tamamen kaldırılacak

**Karar.** Model, persistence, hesaplama, UI, navigasyon, analytics, helper,
artık kullanılmayan bağımlılıklar. Yerine başka oyunlaştırma konmayacak.
Vurgu: koleksiyon, süreklilik, Story Memory, favoriler, seri, ailece okuma,
kişisel hikâye geçmişi.

**⚠️ Kaldırmadan önce bilinmesi gereken:** `MPStreak` **iki işi birden yapıyor.**

| Yarım | Üyeler | Niteliği |
|---|---|---|
| A — Seri / oyunlaştırma | `readDays`, `markReadToday`, `readToday`, `currentStreak`, `weekStates`, `thisWeek`, `DayState`, `weekdayLabels`, `UserDefaults["mp_readDays"]` | İlke 7 ihlali — **kaldırılacak olan bu** |
| B — Okuma süresi defteri | `readSeconds`, `addReadingTime`, `secondsToday`, `minutesToday`, `minutesThisWeek`, `UserDefaults["mp_readSeconds"]` | **Ebeveyn kontrolü.** Günlük ekran süresi limitini bu besliyor |

B kaldırılırsa `StoryReaderView`'daki günlük okuma bütçesi ve `ReaderTimeUpLeaf`
çalışmaz; `ParentPanelView`'daki "bu hafta okuma" değeri kaybolur. Bunlar
oyunlaştırma değil, ebeveyn güvenlik özelliği. **B, `MPReadingTime` (veya
`MPParentControls` içine) taşınmalı; silinmemeli.**

**Tam referans envanteri (5 dosya, 32 referans noktası)**

| # | Dosya | Satır | Bağımlılık türü | Yarım |
|---|---|---|---|---|
| 1 | `Screens/MPStreak.swift` | 7-8 | Tip + singleton tanımı | A+B |
| | | 10, 20, 26 | `UserDefaults["mp_readDays"]` | A |
| | | 24-33 | `markReadToday`, `readToday` | A |
| | | 36-49 | `currentStreak` hesabı | A |
| | | 57-79 | `DayState`, `weekStates` | A |
| | | 81-90 | `thisWeek` | A |
| | | 96-134 | `mp_readSeconds`, `addReadingTime`, `secondsToday`, `minutesToday`, `minutesThisWeek` | **B** |
| | | 136 | `weekdayLabels` | A |
| 2 | `Views/HomeView.swift` | 27 | `@StateObject` | A |
| | | 36, 284-318 | `streakRow` görünümü, `currentStreak`, `thisWeek`, `readToday`, accessibility etiketi, Günlük sekmesine navigasyon | A |
| 3 | `Views/DailyStoriesView.swift` | 12 | `@StateObject` | A |
| | | 21, 39-79 | `streakCard`, 7 günlük şerit, `DayState`, `weekdayLabels` | A |
| | | 147, 151 | 7 gün / 30 gün **hedef rozetleri** | A |
| | | 233 | İkinci `@StateObject` (okuyucu alt görünümü) | A+B |
| | | 311 | `markReadToday()` | A |
| | | 316 | `addReadingTime()` | **B** |
| 4 | `Screens/StoryReader/StoryReaderView.swift` | 21 | `@StateObject` | A+B |
| | | 168 | `markReadToday()` | A |
| | | 210 | `addReadingTime()` | **B** |
| | | 235 | `secondsToday` → günlük bütçe | **B** |
| 5 | `Screens/ParentPanelView.swift` | 11 | `@StateObject` | A+B |
| | | 93 | `currentStreak` → "gün" istatistik kartı | A |
| | | 99, 127 | `minutesToday`, `minutesThisWeek` | **B** |
| | | 122 | Özet metninde "N günlük seri" | A |

**Ek bulgu — rozetler.** `Views/DailyStoriesView.swift:143-153` bir `goals`
dizisi tutuyor: "7 günlük seri" (`trophy.fill`), "10 masal" (`book`),
"30 günlük seri" (`flame.fill`). İlk ve üçüncü `streak.currentStreak`'e bağlı;
ikincisi `readCount`'a bağlı ve **MPStreak'ten bağımsız olarak** var olmaya
devam eder. Üçü de "badge" kategorisinde ve İlke 7 kapsamında — MPStreak
kaldırılırken ikincisi kendiliğinden düşmez, ayrıca kaldırılmalı.

**Önerilen kaldırma sırası**

1. B yarısını yeni bir `MPReadingTime` tipine taşı, `UserDefaults["mp_readSeconds"]`
   anahtarını koru. `ParentControlsTests` yeşil kalmalı. *Bu adım tek başına
   davranışı değiştirmez.*
2. Üç çağrı noktasını B'ye yönlendir: `StoryReaderView:210,235`,
   `DailyStoriesView:316`, `ParentPanelView:99,127`.
3. UI'dan A'yı çıkar — en dıştan içe: `HomeView.streakRow` → `DailyStoriesView`
   `streakCard` + hedef rozetleri → `ParentPanelView:93,122`.
4. `markReadToday()` çağrılarını kaldır (`StoryReaderView:168`,
   `DailyStoriesView:311`). Dikkat: `StoryReaderView:169`'daki
   `markOpened(storyId:)` **farklı bir şey** — "kaldığın yer" kartını besliyor,
   kalmalı.
5. `MPStreak.swift`'i sil.
6. `UserDefaults["mp_readDays"]` için tek seferlik temizlik. Silmeden önce
   D4 ile ilişkisine bak: bu veri "kişisel hikâye geçmişi"nin ham malzemesi
   olabilir (hangi günler okundu). Kararı `library-memory` agent'ı vermeli.

**Riskler**

- A ve B'yi ayırmadan silmek ebeveyn ekran limitini sessizce kırar. Bu, çocuk
  güvenliği özelliği; regression testi olmadan dokunulmamalı.
- `DailyStoriesView` streak kaldırılınca ekranın yarısı boşalır — `ui-agent`
  briefi gerekir. İçerik boşluğu D2'nin "vurgu" listesiyle doldurulmalı.
- `HomeView:318` accessibility etiketi streak metnine bağlı; kaldırılırken
  ekranın VoiceOver akışı yeniden kontrol edilmeli.

**2. dalgaya kalan:** Story Memory, favoriler, seri, ailece okuma —
D2'nin "yerine ne gelecek" tarafı. Bunlar D4 (persistence) olmadan
yapılamaz, çünkü hepsi kalıcı domain verisi.

### 11.3 D3 — Schema 2 tek kanonik blueprint formatı

**Karar.** Schema 2 kanonik. v2 korpusu ve pilot korpusu blueprint bazında
KEEP / MIGRATE / MERGE / RETIRE kararına bağlanacak. Dosyalar körü körüne
birleştirilmeyecek. Schema 2 dışında yeni üretim blueprint'i yazılmayacak.

**Etkilenen içerik**

| Varlık | Adet | Şema | Blueprint bazında karar gerekiyor mu |
|---|---|---|---|
| `shared_content_library_v2.json` blueprint'leri | 12 | V1 (`genre`+`theme`, `pageRoles`) | **Evet — 12 karar** |
| `pilot_library_v1.json` blueprint'leri | 6 | Schema 2 (`family`, `pages[].beat`, `requires`/`forbids`) | KEEP (kanonik referans) |
| v2 setting / companion / object / event / challenge / ending | 16/15/20/20/15/10 | trait'siz | Schema 2 trait'leri eklenmeli |
| pilot setting / companion / object | 6/5/8 | trait'li | KEEP |
| `storyIdeas` | 4 | yalnızca pilot'ta | KEEP — **canlı UI kaynağı** |
| v3 beat korpusu | 33 + 8 | beat başına dosya | KEEP |

**Etkilenen kod**

| Dosya | Neden |
|---|---|
| `StoryEngine/Content/ContentCatalogLoader.swift` | Katman sırası ve `additionalResourceNames` |
| `StoryEngine/Content/CatalogBlueprint.swift` | İki şemayı da çözümlüyor; kanonikleşme sonrası sadeleşir |
| `StoryEngine/Content/CatalogIntegrity.swift` (536) | Bütünlük kuralları schema 2'ye göre sıkılaşır |
| `StoryEngine/Content/ContentTraits.swift` | v2 içeriğine trait yazılması bunu genişletir |
| `StoryEngine/Offline/BlueprintSelector.swift` | `requires`/`forbids` her blueprint'te olacaksa fallback yolları kalkar |
| `MagicPaper/templates/…/shared_content_library_v2.json` | Gölge kopya — silinecek |
| `MagicPaper.xcodeproj` Resources fazı | Gölge kopya kaldırılınca resource referansı da kalkmalı |

**Sıra**

1. `MagicPaper/templates/offline/v2/shared_content_library_v2.json` gölge
   kopyasını kaldır (paket bundle'ı zaten kazanıyor — davranış değişmez, ama
   önce `ContentCatalogLoader`'ın `Bundle.module`'u bulduğunu cihazda doğrula).
2. 12 v2 blueprint'i için **karar tablosu** üret: her biri için
   KEEP/MIGRATE/MERGE/RETIRE + gerekçe. Bu bir `content-library` işi, kod işi değil.
3. MIGRATE kararı alanları schema 2'ye port et. `PortedBlueprintSpikeTests`
   zaten bu işin iskeleti — mevcut spike'ı referans al.
4. MIGRATE edilen blueprint'lerin ihtiyaç duyduğu setting/companion/object'lere
   trait yaz. Aksi halde `requires`/`forbids` hiçbir aday bulamaz.
5. `CatalogIntegrity`'yi sıkılaştır: schema 2 olmayan blueprint artık `error`
   olsun. Bu adım geriye dönük kırıcı — RETIRE listesi tamamlanmadan yapılmamalı.
6. Tek belge mi iki belge mi kalacağı bundan **sonra** kararlaştırılır.

**Riskler**

- **⚠️ Adım 1 sırası önemli:** Gölge kopya `ContentCatalogLoader`'ın `otherBundle`
  fallback'i için bir emniyet ağı. Kaldırmadan önce paket resource bundle'ının
  gerçek cihazda bulunduğu kanıtlanmalı (`CatalogLoadReport.source ==
  .packageBundle`). Kanıt yoksa uygulama içerik olmadan açılır.
- Adım 5 sırası kritik: `BlueprintSelector` bugün trait'siz içerikle çalışıyor.
  Trait'ler yazılmadan sıkılaştırma yaparsan `noStoryForChoices` üretilir.
- `MatrixCoverageTests`, `PilotBlueprintTests`, `TraitRequirementTests`,
  `CatalogMergeTests`, `AgeBandCoverageTests` bu işin güvenlik ağı. Hepsi
  `swift test` altında — §7'deki test planı boşluğu **D3 başlamadan** kapanmalı.
- 8-10 ve 11-12 yaş bantları için yazılmış **hiçbir içerik yok**
  (`OfflineStoryService.storyIdeas` doc comment'i bunu geçici çözüm olarak
  adlandırıyor). Profil ekranı bu bantları sunmaya devam ediyor. D3 kapsamında
  ya içerik yazılmalı ya bant kapatılmalı.

**2. dalgaya kalan:** `templates/offline/*.json` (13 V1 template) ve
`adventure_01.json` emekliliği — bunlar `BuiltInTemplates` üzerinden ölü
yolda; D1'in 2. dalgasıyla birlikte ele alınmalı.

### 11.4 D4 — Domain persistence FileStores'a taşınacak

**Karar.** `ChildProfile`, `Character`, `Story`, `StoryMemory`, `Library`,
`Favorites`, `StorySeries` → FileStores. UserDefaults yalnızca gerçekten küçük
uygulama tercihleri için (onboarding tamamlandı, hafif UI tercihleri).
Güvenli migration şart. Mevcut kullanıcı verisi **kaybolmayacak**, eski veri
öylece silinmeyecek.

**Taşınacak / kalacak ayrımı**

| Anahtar | Karar |
|---|---|
| `"stories"` | **Taşınacak** — hikâye başına bir kayıt |
| `ProfileManager` profil blob'u | **Taşınacak** |
| `"read_history_<profileID>"` | **Taşınacak** — StoryMemory'nin bugünkü ilkel hâli |
| `"mp_readDays"` | D2 ile birlikte; geçmiş sayılacaksa taşınır, sayılmayacaksa silinir |
| `"mp_readSeconds"` | D2-B; ebeveyn kontrolü verisi, taşınabilir |
| `DailyStoryManager` blob'u | Taşınmaz — sabit içerik, korpusa ait (§4.4) |
| `hasLaunchedBefore` | **Kalacak** |
| `appLanguage`, `defaultLanguage` | **Kalacak** |
| `mp_avatarColor_<uuid>` | **Kalacak** |
| `mp_readerOrnament` | **Kalacak** |
| `subscriptionTier`, `freeTrialCount`, `freeTrialUsed`, `freeImageStoryUsed`, `remainingImageStories`, `lastQuotaReset`, `lastFreeTextStoryDate` | **Kalacak** — entitlement, ama tek sahibe (`monetization`) devredilmeli |

**Etkilenen dosyalar**

| Dosya | Ne olacak |
|---|---|
| `StoryEngineBridge/FileStores.swift` (145) | Ölü durumdan çıkıp kanonik store olacak. Hedef tasarım zaten burada yazılı |
| `Services/StoryGenerationManager.swift:881-972` | `saveStories`/`loadStories`/`migrateOldStoriesIfNeeded` çıkacak |
| `Services/ProfileManager.swift` | Profil persistence çıkacak |
| `Models/Story.swift` | `Codable` şeması kayıt formatı olacak — `StoryOrigin` dahil |
| `MagicPaperTests/StoryPersistenceTests.swift` | Doğrudan etkilenir; **önce genişletilmeli** |
| `MagicPaperTests/ContinueReadingTests.swift` | `lastReadAt`/`lastReadPage` yazımı store'a taşınır |

**Sıra**

1. `StoryPersistenceTests`'i bugünkü UserDefaults davranışını **tam olarak**
   tanımlayacak şekilde genişlet — özellikle çözümleme hatası → yedek anahtar
   davranışını (`:905`). Bu, migration'ın doğruluk ölçütü.
2. **`migrateOldStoriesIfNeeded()`'in 4 MB üstünde veriyi yedeksiz silen kolunu
   kapat** (`:939-948`). D4 bu koddan önce gelmeli; aksi halde migration'ın
   okuyacağı veri bir açılışta yok olabilir.
3. `FileStores`'u store protokolü arkasında canlıya al (yalnızca `Story` ile başla).
   Repository protokolü arkasında iki uygulama: UserDefaults (okuma) ve File (yazma).
4. **Tek yönlü, idempotent migration:** UserDefaults → FileStores. Eski blob
   **silinmez**, `"stories.migrated.<epoch>"` gibi bir anahtara taşınır ve
   okunabilir kalır. Migration tamamlandı bayrağı UserDefaults'ta tutulur
   (küçük tercih — D4'ün kalan kapsamı içinde meşru).
5. Doğrulama: migration sonrası hikâye sayısı, `origin`, `lastReadAt`,
   `childProfileID` ve görsel dosya adları birebir eşleşmeli. Eşleşmezse
   migration **başarısız sayılır**, eski yola düşülür.
6. Aynı deseni `ProfileManager` ve `read_history_*` için tekrarla.
7. `StoryMemory`, `Favorites`, `StorySeries` — **yeni** domain, migration yok.
   FileStores üstüne doğrudan yazılır.

**Riskler**

- **⚠️ En kritik:** `:939`'daki yedeksiz silme kolu. D4'ün 2. adımı bu.
- Görsel dosyaları zaten Documents'ta; hikâye kaydı taşınırken dosya adı
  referansları kırılmamalı. Bu, migration doğrulamasının (adım 5) asıl konusu.
- `StoryGenerationManager` D1 ile aynı anda değişiyor. **İkisi aynı anda
  çalışamaz** — §12'deki tek sahip kuralı.
- `Documents/` iCloud yedeklemesine giriyor. Çocuk fotoğrafları ve hikâye
  metinleri oraya yazılırken `isExcludedFromBackup` ve dosya koruma sınıfı
  kararı gerekir — bu bir `privacy-safety` işi, D4'ün parçası olarak
  planlanmalı.

**2. dalgaya kalan:** `StoryMemory`, `Favorites`, `StorySeries` domain'leri
(adım 7). Bunlar D2'nin "yerine ne gelecek" listesiyle aynı işler.

### 11.5 Kararlar arası bağımlılık

```
D3 (içerik, korpus)   ──┐   bağımsız, hemen başlayabilir
                        │   (§7 test planı boşluğu kapatıldıktan sonra)
D1 (üretim yolu)      ──┼── StoryGenerationManager'ı yeniden şekillendirir
                        │
D4 (persistence)      ──┘   StoryGenerationManager'ın diğer yarısını alır
                            → D1 ile ARDIŞIK, paralel değil

D2 (MPStreak)         ─────  UI + ebeveyn kontrolü; D1/D4'ten bağımsız
                            ama "yerine ne gelecek" kısmı D4'ü bekler
```

Önerilen dalga:
- **Dalga A (paralel):** D3 adım 1-2 (`content-library`) · D2 adım 1-5
  (`reader` + `parent-ux`) · test planı boşluğu (`builder`)
- **Dalga B:** D1 adım 1-5 (`story-engine`, `StoryGenerationManager` tek sahipli)
- **Dalga C:** D4 (aynı dosya, D1 bittikten sonra)
- **Dalga D:** D1 adım 6 (illüstrasyon özelliği geldiğinde) · D2/D4 2. dalga
  domain'leri (StoryMemory, Favorites, Series)

---

## 12. Dosya sahipliği (Shared File Rule)

Aynı anda birden fazla agent'ın talip olduğu dosyalar ve tek sahipleri:

| Dosya | Talipler | **Tek sahip** |
|---|---|---|
| `Services/StoryGenerationManager.swift` | story-engine, monetization, library-memory, privacy-safety, content-library | **story-engine** (D1 boyunca), sonra **library-memory** (D4 boyunca). Asla ikisi aynı anda |
| `DesignSystem/MPTheme.swift`, `MPSurfaces.swift` | design-system, ui-agent | **design-system** — ui-agent yalnızca tüketir |
| `Screens/StoryReader/StoryCover.swift` | reader, illustration-system | **reader** |
| `Screens/StoryReader/StoryReaderView.swift` | reader, parent-ux (D2-B ekran limiti) | **reader** |
| `shared_content_library_v2.json` | content-library, story-engine | **content-library** |
| `Screens/StoryCreation/*` | story-engine (D1 adım 3), ui-agent, parent-ux | **story-engine** D1 adım 3 boyunca |
| `Screens/MPStreak.swift` | reader, parent-ux | **parent-ux** (B yarısı ebeveyn kontrolü) |
| `MagicPaper.xcodeproj/project.pbxproj` | herkes | **product-architect** — değişiklik talebi buradan geçer |

`StoryEngineBridge/` senkronize klasör grubu olduğundan yeni dosya eklemek
pbxproj düzenlemesi gerektirmez — ama silmek de sessizce derlemeden düşürür.

---

## 13. Bu turda değişen dosyalar

Yalnızca bu doküman oluşturuldu. Üretim kodu değiştirilmedi.
