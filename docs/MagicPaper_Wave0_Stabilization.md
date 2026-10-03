# MagicPaper — Grup 1.5: Stabilizasyon Kapısı

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Tarih:** 2026-09-18 · **Rol:** Lead / integration · **Grup 2 BAŞLATILMADI**

| | Giriş | Çıkış |
|---|---|---|
| App build | ✅ SUCCEEDED | ✅ **SUCCEEDED** |
| Paket testleri | 761 / **38 hata** / 24 distinct | 761 / **23 hata** / 15 distinct |
| TestPlan kapsamı | 1 target (app) | **5 target** (app + 4 paket) |

---

## 1. K1 — KESİN CEVAP: **A. Üretilmiş içerik saklanıyor**

`UserDefaults["stories"]` **tam üretilmiş hikâye metnini** saklıyor; seed'den yeniden
üretilmiyor. Bu, model adlarından veya dokümandan değil, **encode/decode yolunun
izlenmesinden** çıkarıldı.

**Kanıt 1 — model.** `Story: Codable` → `pages: [StoryPage]` → `StoryPage.text: String`.
Düzyazının kendisi kodlanıyor. `StoryOrigin` (seed, blueprintID, settingID, companionID,
discoveryID, fingerprint, catalogVersion, worldID) metnin **yanında** saklanıyor,
yerine değil. Kendi doküman yorumu bunu söylüyor: *"a regeneration can be **checked**
rather than hoped for."*

**Kanıt 2 — `StoryOrigin`'in sıfır okuyucusu var.** Tüm kod tabanında bir yerde
yazılıyor (`OfflineStoryMapper.swift:35`), hiçbir yerde okunmuyor. `origin.seed`'i
tüketen kod yok.

**Kanıt 3 — `compose()` yalnızca yaratma yolunda.** İki çağrı yeri:
`OfflineStoryService.swift:136` (içsel) ve `StoryGenerationManager.swift:1459`
(`createStory`). **Hiçbiri açma/okuma yolunda değil.**

**Kanıt 4 — okuyucu saklanan metni okuyor.** `ReaderStory.swift:120-124`
doğrudan `story.pages[].text` üzerinden `paragraphs(of:)` çağırıyor.

### Sonuç

> **Mevcut kitaplar blueprint değişikliklerinden korunuyor.** Bir çocuğun
> kütüphanesindeki masal seed'inden yeniden inşa edilmiyor, dolayısıyla korpus
> değiştiğinde altından kayamaz.

**D4 seed drift açısından BLOKE DEĞİL.** Bu, D4'ün diğer risklerini kaldırmaz (§5).

Bu bulgu `OfflineDeterminismTests`'in yeniden sabitlenmesini de meşrulaştırdı: testin
amacı süreçler arası kararlılık, ve katalog D3 ile meşru biçimde değişti.

---

## 2. Test denetimi — 38 hatanın sınıflandırması

### Düzeltilenler (38 → 23 hata, 24 → 15 distinct)

| Test | Sınıf | Yapılan |
|---|---|---|
| `CatalogBundleTests.testTheShippedCatalogHasTheExpectedRecordCounts` | STALE_EXPECTATION | V1 blueprint 12→0, toplam 18→15 |
| `CatalogBeatMigrationTests.testTheBeatGapIsReportedRatherThanHidden` | STALE_EXPECTATION | `blueprint_without_beats` artık boş, `blueprint_without_family` 12→0 |
| `CatalogBeatMigrationTests.testTheShippedCatalogIsNowSelectableWithoutChangingV1` | STALE_EXPECTATION | 12→0 |
| `CatalogMergeTests.testTheLoadedCatalogContainsBeatAuthoredBlueprints` | STALE_EXPECTATION | aile başına tek blueprint varsayımı kaldırıldı |
| `CatalogMergeTests.testLegacyContentSurvivesTheMerge` | CONTENT_MIGRATION | V1 blueprint emekliliği beklentiye yazıldı; V1'in diğer kayıtlarının korunması hâlâ assert ediliyor |
| `MatrixCoverageTests.testLibraryHoldsOneBlueprintPerFamily` | STALE_EXPECTATION | **yeniden adlandırıldı** → `testEveryBlueprintDeclaresAFamilyAndEveryFamilyIsRepresented` |
| `PilotBlueprintTests.testV1ContentIsUntouchedAndTheMergeHappensAtLoadTime` | CONTENT_MIGRATION | 12→0 + V1'in settings/objects'inin korunduğu **eklendi** |
| `OfflineDeterminismTests.testAStoredSeedRebuildsTheSameBookInAFreshProcess` | CONTENT_MIGRATION | yeni katalog değerlerine yeniden sabitlendi |
| `OfflineDeterminismTests.testTheFingerprintIsAFunctionOfTheInputsAlone` | CONTENT_MIGRATION | fingerprint yeniden sabitlendi |

Hiçbir assert zayıflatılmadı. İki testte **daha güçlü** assert eklendi
(V1'in diğer kayıtlarının hayatta kalması, ailelerin temsil edilmesi). Anlamı tersine
dönen test susturulmak yerine **yeniden adlandırıldı**.

### Kalan 15 — tek kök neden

**REAL_PRODUCTION_BUG: yok.** Aday üçü de incelendi ve elendi:

- **`BlueprintSelector` thresholdKind** — selector hatası değil. Kodun kendi yorumu
  (`BlueprintSelector.swift:100-111`) tek-eksende-denetleme sınırını açıkça kabul ediyor
  ve mimari çözümü zaten uyguluyor: `ranked` bir **liste** döndürüyor, çağıran bağlanana
  kadar yürüyor. `:119` ancak **hiçbir** blueprint kabul etmediğinde patlıyor.
- **`setting_coral_sea_001`** — sahipsiz değil. `isOpen` üzerinden **5 blueprint** onu
  kabul ediyor. Hatta yeniden sabitlenen determinizm testinde bir seed mercan denizi +
  yunusa çözülüp temiz hikâye üretiyor.
- **`ComposedStory.isClean`** — üretim köprüsünde zorlanmıyor (gerçek bir açık, §4),
  ama bu testlerin hiçbirinin sebebi değil.

**Gerçek kök neden — CONTENT_MIGRATION, üç eksenli kapsama boşluğu.**

Phase-4 matrisinin `sea+dolphin+shell` satırı hiçbir blueprint'e oturmuyor. Hesaplanmış
kabul matrisi:

```
object_shell_pilot_001 sunar : impliesPresence, isBeautiful, isVisible
companion_dolphin_pilot_001  : isPlayful, canCarry, canSwim
setting_coral_sea_001        : hasWater, isOpen
```

| Blueprint | setting | companion | discovery |
|---|---|---|---|
| `bp_appeal_speakingup_002` | ✅ | ✗ `isSmall` ister | ✅ |
| `bp_misreading_twosides_002` | ✅ | ✅ | ✗ `impliesNeed` ister |
| `bp_unexplained_moment_002` | ✅ | ✅ | ✗ `isUnexplained + emitsSignal` ister |
| diğer 12 | çoğu ✗ | — | — |

İki blueprint tek bir trait uzağında. **Bu bir içerik tasarım kararı, refactor değil** —
uydurulmadı.

| Kalan test | Sınıf | Sebep |
|---|---|---|
| `MatrixCoverageTests` ×6 | CONTENT_MIGRATION | yukarıdaki kapsama boşluğu + aile mimarisi beklentileri |
| `OfflineCompositionTests` ×4 | CONTENT_MIGRATION | `object_shell_pilot_001` → *"no such discovery"*, `object_faint_sound_001` → *"offers forbidden impliesNeed"* |
| `PilotBlueprintTests` ×3 | STALE_EXPECTATION | 5 pilot MERGE ile katalog yaylarına yükseltildi; `requires`/`forbids`/beat dizileri değişti. **Kapsama arttı:** `["forest+fox+light"]` → `["forest+fox+light", "garden+hedgehog+sound"]` |
| `SettingAxisTests` ×1 | CONTENT_MIGRATION (kaskad) | composer artık farklı bir nedenle daha erken reddediyor, ret mesajı "explained" kelimesini içermiyor |
| `OfflineDeterminismTests.testContentSelectionStillFollowsCatalogOrder` | **OTHER — kasıtlı bırakıldı** | aşağıda |

### `testContentSelectionStillFollowsCatalogOrder` — neden düzeltilmedi

Bu test bir **tehlikeyi** kayda geçiriyor: `OfflineContentBinder.choose` `admissible`
havuzunu katalog dizi sırasında kurup seed'li offset ile indeksliyor, yani JSON'da bir
kaydı yukarı taşımak saklanmış seed'leri başka içeriğe yönlendiriyor.

Test, sırayı ters çevirmenin seçimi **değiştirmesini** bekliyor. Artık değiştirmiyor —
çünkü bu seed'in çözüldüğü blueprint'in setting kısıtı havuzu tek adaya indiriyor.

**Assert'i ters çevirmek yanlış olurdu:** tehlike kodda aynen duruyor, yalnızca bu prob
onu artık göstermiyor. Testi "yeşil" yapmak için tehlikenin yokmuş gibi assert edilmesi
kabul edilmedi. Prob'un üç ekseni birden ters çevirecek şekilde güçlendirilmesi gerekiyor.

### Grup 2'yi bloke ediyor mu?

**Hayır.** On beşinin tamamı Schema 2 korpusunun kapsama profiliyle ilgili; hiçbiri
üretim kodunda hata değil ve app build yeşil. Ama **`sea+dolphin+shell` satırı için bir
içerik kararı verilmeden matris kapsaması tamamlanmış sayılamaz.**

---

## 3. MPStreak — RETAINED

Bu madde **Grup 1.5'ten önce tamamlandı**, burada yalnızca doğrulanıyor:

- Mimari denetim (10 soru, 6 bulgu): `docs/MagicPaper_Streak_System.md`
- `CLAUDE.md` İlke 7 yeniden yazıldı — artık "streaks are prohibited" **demiyor**
- `.claude/agents/` içinde `parent-ux.md`, `planner.md`, `ui-agent.md` düzeltildi
- Tarama temiz: kalan tek "streak" geçişi, yasaklanan **dil örnekleri**

Özet: durum `UserDefaults` `mp_readDays` + `mp_readSeconds`'te, cihaz genelinde;
tetikleyici `markReadToday()` iki yerden (`StoryReaderView:168`, `DailyStoriesView:311`);
uygulama açılışı artırmıyor ✅, **hikâye açılışı artırıyor** ⚠️, tamamlama şart değil ⚠️;
aynı gün idempotent ✅. Gerçek hata **H1**: `SettingsView:462` "tüm veriyi sil"
`mp_readSeconds`'i bırakıyor.

---

## 4. D1 — Migration haritası (silme YAPILMADI)

`createCustomStory` **duruyor**. `StoryWizardView:344` → `SGM:42`.

### Neden tek adımda kaldırılamaz
`createCustomStory` **tek illüstrasyonlu üretim yolu.** V2 offline yolu metin üretiyor,
görsel üretmiyor. İkamesi `MPAppState.swift:79-85`'te niyet olarak yazılı, **yok**.

### Hedef boru hattı ve eksikler

| Aşama | Bugün | Eksik |
|---|---|---|
| Story Creation UI | `StoryCreationFlow` | ⚠️ `import StoryEngine` yapıp `OfflineStoryService`'i adıyla çağırıyor — UI provider'ı biliyor |
| → StoryEngine | ✅ canlı | — |
| → StoryProvider | ✅ `StoryAIProvider` protokolü var | ⚠️ dikiş app bridge'inde kurulmalı, `StoryAIProvider` üzerinde değil (LLM sınırı) |
| → Character / CharacterBible | `CharacterProfile` + lexicons ✅ yazılı | ❌ **köprü ölü** — `ProfileCharacterSource` → `StoryEngineContainer` → tüketici yok. Canlı akışta `CharacterProfile` hiç yaratılmıyor |
| → Validation | 8 validator ✅ yazılı ve test edilmiş | ❌ hiçbiri erişilebilir değil; `ComposedStory.isClean` üretimde **sıfır tüketici** |
| → Visual Story Pipeline | `VisualSystem` ✅ tam | ❌ üretim ona hiç uğramıyor |
| → Illustration System | `FalImageProvider` (kanonik aday) | ❌ `StoryEngineContainer` inşa edilmediği için ölü; canlı olan `FalAIImageGenerator` |
| → Reader | ✅ canlı, 24 dosya | — |

### Migration kontrol listesi

**Dalga 0 — bugün güvenli, legacy yola dokunmuyor**
1. `ComposedStory.isClean` guard'ını bridge'e ekle (yerine konmamış `{{...}}` okuyucuya gidiyor)
2. UI dikişini çek: `StoryCreationFlow`/`StoryIdeaStep`/`CompanionStep` protokole karşı yazılsın
   — `CompanionSymbolTests` ve `AgeBandCoverageTests` **yeniden yazılacak, silinmeyecek**
3. `StoryEngineContainer`'a tüketici bağla → validator zinciri ve karakter köprüsü canlansın
4. Ölü kodu sil: `FalImageGenerator`, `FalImageService`, `FalAITestView` (§6)
5. `SGM:1306` `TestOfflineTemplateStoryProvider` + `DevStoryTestView`'ı üretim
   hedefinden çıkar (**testlerin ihtiyaç duyduğu mock'lar korunacak**);
   `SGM:1322`'deki sabit mutlak geliştirici yolu da böylece gider
6. `OfflineStoryIntent`'e yaş ve zamir ekle (bugün yalnızca `childName: String`)

**Dalga 1 — illüstrasyon ikamesine bağlı**
7. `FalImageProvider`'ı kanonik yap; `VisualSystem` kısıtları prompt'u üretsin
8. Karakter kimliğini görsel zincire bağla (İlke 5 ihlali böylece kapanır)
9. Ancak ondan sonra `createCustomStory` + `generateImagesForStory` +
   `AIService` imagePrompt şablonları emekliye ayrılsın

---

## 5. D4 — Persistence hazırlığı (göç YAPILMADI)

K1 çözüldü, yani D4 hazırlığı meşru. **Hiçbir kullanıcı verisi yazılmadı veya silinmedi.**

### UserDefaults'ta saklanan domain nesneleri

| Anahtar | İçerik | Hedef |
|---|---|---|
| `stories` | `[Story]` tek blob, **üretilmiş metin dahil** | FileStores, kayıt başına bir JSON |
| `user_profiles` | `[UserProfile]` | FileStores |
| `current_profile_id` | seçili profil | UserDefaults'ta kalabilir (küçük tercih) |
| `mp_favoriteStoryIDs` | favoriler | FileStores |
| `mp_approvedStoryIDs` | ebeveyn onayı | FileStores |
| `mp_readDays`, `mp_readSeconds` | streak + okuma süresi | profil kapsamına alınmalı (Streak H2) |
| `mp_avatarColor_<UUID>`, `read_history_<UUID>` | profil başına | zaten profil kapsamında |
| onboarding tamamlandı, UI tercihleri | küçük ayarlar | **UserDefaults'ta kalır** |

### Göç gereksinimleri
1. **Önce yaz, sonra doğrula, sonra işaretle, sonra beklet, en son sil.** 5. adım
   1. adım gönderilmeden **önce** yazılmalı — `stories.undecodable.*` bu kalıbın
   kanıtlanmış başarısızlığı (sınırsız, hiç temizlenmeyen yedekler).
2. **⚠️ ÖNCE KAPATILMALI: `migrateOldStoriesIfNeeded()` (`SGM:939`)** 4 MB üstünde
   `UserDefaults["stories"]`'i **yedeksiz siliyor**. Göçün okuyacağı veri bir açılışta
   yok olabilir. D4'ün birinci adımı bu kolu kapatmaktır.
3. **`FileStores` üç yerde sessiz:** `save` Documents erişilemezse sessizce "başarılı";
   `load`/`loadAll` çözümlenemeyen dosyayı atlıyor. Hikâye için kabul edilebilir,
   **karakter için değil** — `nil` "karakter yok" diye okunur.
4. **`FileProtection` hiçbir yerde yok** — üç yazma noktası da çıplak `write(to:)`.

### Versiyonlama ve CharacterVersionID
`CharacterVersionID` ve `CharacterAsset.id` **taze UUID**: birebir aynı girdiden üretilen
iki `CharacterVersion` eşit değil. **Göç sürümleri kopyalamalı, yeniden inşa etmemeli** —
aksi hâlde çocuğun görsel kimliği kalıcı kayar.

**Zamanlama avantajı:** köprü ölü olduğu için bugün pinli kitap yok →
**risk bugün sıfır, köprü canlanınca yüksek.** D4'ü D1 Dalga 0 adım 3'ten **önce**
yapmak belirgin biçimde ucuz.

---

## 6. Ölü kod denetimi

### Silinmiş üç dosya — geri alınmadı, doğrulandı

| Dosya | Üretim referansı | Karar |
|---|---|---|
| `PremiumComponents.swift` (874) | **0** — 4 public tipin (`PremiumBadge`/`Gate`/`Card`/`Lock`) hiçbiri kullanılmıyor | **SİLİ KALSIN** |
| `TextStoryLibraryView.swift` (244) | **0** | **SİLİ KALSIN** |
| `TextStoryViewerView.swift` (281) | **0** | **SİLİ KALSIN** |

Tek kalan geçiş `MPHaptics.swift:7`'de bir **yorum** referansıydı; artık silinmiş
dosyaya işaret etmiyor, düzeltildi. Build silmeden sonra yeşil. Üçü de
`git show HEAD:<yol>` ile hâlâ kurtarılabilir.

### Fal servisleri

| Dosya | Dış referans | Karar |
|---|---|---|
| `FalImageGenerator.swift` | **0** | **ÖLÜ — silinebilir** (D1 Dalga 0 adım 4) |
| `FalImageService.swift` | **0** | **ÖLÜ — silinebilir** |
| `FalAITestView.swift` | 1, ve o da bir **yorum** (`ImagePicker.swift:6`) | **ÖLÜ — silinebilir** |
| `FalAIImageGenerator.swift` | **3, biri canlı: `SGM:276`** | ❌ **SİLME** — `createCustomStory` yolunda, D1 Dalga 1'e kadar kalır |

Bu turda hiçbiri silinmedi — silme D1 Dalga 0'ın işi, burada yalnızca doğrulandı.

---

## 7. Test altyapısı

### TestPlan düzeltildi
`TestPlan.xctestplan` yalnızca `MagicPaperTests`'i içeriyordu; paketin **761 testi**
Xcode/CI akışında hiç koşmuyordu. Dört paket target'ı eklendi:

```
MagicPaperTests · EngineFoundationTests · CharacterEngineTests
VisualSystemTests · StoryEngineTests
```

`xcodebuild -showTestPlans` planı görüyor; app build yeşil kaldı.

### Agent'lar için izole build/test komutu

```bash
# Paket testleri — düz `swift test` bu repoda codesign hatasıyla düşer
cd MagicPaper/StoryEngine
xattr -cr Sources Tests .build
swift test --build-system native --scratch-path .build-agent-<ad>
```

İki gerekçe, ikisi de Grup 1'de gözlemlendi:
- **Codesign/xattr:** proje `~/Desktop` altında; fileprovider `com.apple.macl` ve
  `provenance` xattr'ları `Resources`'a yapışıp codesign'ı *"resource fork, Finder
  information, or similar detritus not allowed"* ile kırıyor.
- **Paylaşılan `.build`:** Grup 1'de agent'lar aynı dizini paylaştı, *"Another instance
  of SwiftPM is already running"* çakışması yaşandı ve bir agent başka bir agent
  mid-edit'teyken test koşup **hayalet kırmızı** gördü. `--scratch-path` zorunlu.

```bash
# App build
cd MagicPaper && xattr -cr .
xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## 8. Definition of Done

| # | Madde | Durum |
|---|---|---|
| 1 | K1 kesin cevaplandı | ✅ **A — üretilmiş içerik saklanıyor**, dört kanıtla |
| 2 | 38 hata sınıflandırıldı | ✅ tamamı, beş sınıfa |
| 3 | Gerçek üretim hataları düzeltildi | ✅ **kalanlar arasında üretim hatası yok** — üç aday incelenip elendi |
| 4 | Schema 2 beklentileri güncellendi | ✅ 9 test, hiçbiri zayıflatılmadan; ikisine daha güçlü assert eklendi |
| 5 | Suite yeşil **veya** kalanlar belgelendi | ⚠️ **23 hata / 15 distinct, tek kök nedenle belgelendi** |
| 6 | MPStreak korundu ve belgelendi | ✅ `docs/MagicPaper_Streak_System.md` |
| 7 | CLAUDE.md MPStreak'i yasaklamıyor | ✅ İlke 7 yeniden yazıldı + 3 agent tanımı |
| 8 | D1 haritalandı, `createCustomStory` silinmedi | ✅ 9 maddelik kontrol listesi, iki dalga |
| 9 | D4 haritalandı, veri yok edilmedi | ✅ hiçbir kullanıcı verisine dokunulmadı |
| 10 | TestPlan kapsamı doğrulandı | ✅ 1 → 5 target |
| 11 | Ölü kod kararları belgelendi | ✅ 3 silme onaylandı, 3 Fal dosyası ölü, 1'i canlı |

### Açık kalan tek içerik kararı

`sea+dolphin+shell` matris satırı. İki blueprint tek trait uzağında:
`bp_misreading_twosides_002` deniz kabuğunda `impliesNeed` istiyor;
`bp_appeal_speakingup_002` yunusta `isSmall` istiyor. İkisi de anlatısal olarak
zorlama olurdu — doğru çözüm muhtemelen su ailesi için bir blueprint eklemek veya
matris satırını emekliye ayırmak. **Uydurulmadı.**
