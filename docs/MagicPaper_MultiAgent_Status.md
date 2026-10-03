# MagicPaper — Multi-Agent Status

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Tarih:** 2026-09-18
**Rol:** Lead / integration
**Durum:** Grup 1 + Grup 1.5 (Stabilizasyon Kapısı) tamamlandı. Grup 2 BAŞLATILMADI.

> **Grup 1.5 çıktısı:** `docs/MagicPaper_Wave0_Stabilization.md` — K1 kesin cevabı,
> 38 hatanın sınıflandırması, D1/D4 haritaları, ölü kod kararları, test altyapısı.

Önceki sürüm (Grup 1 öncesi audit) bu dokümanın git geçmişinde.

---

## 1. Doğrulanmış son durum

Entegrasyon liderinin kendi ölçümü — agent raporları kabul edilmedi, tekrar koşuldu.

| Kontrol | Komut | Sonuç |
|---|---|---|
| App build | `xcodebuild -scheme MagicPaper -destination 'iPhone 17 Pro' build` | ✅ **BUILD SUCCEEDED** |
| Paket testleri | `swift test --build-system native` | ⚠️ **761 test, 23 failure / 15 distinct** (Grup 1.5 girişinde 38/24) |
| TestPlan kapsamı | `xcodebuild -showTestPlans` | ✅ **5 target** (Grup 1.5 girişinde 1) |

### Grup 1.5 ile kapanan maddeler

- **K1 KESİN CEVAP: A — üretilmiş içerik saklanıyor.** `Story.pages[].text` düzyazıyı
  kodluyor; `StoryOrigin`'in kod tabanında **sıfır okuyucusu** var; `compose()` yalnızca
  yaratma yolundan çağrılıyor; `ReaderStory:124` saklanan metni okuyor.
  **Mevcut kitaplar blueprint değişikliklerinden korunuyor. D4 seed drift açısından
  BLOKE DEĞİL.**
- **9 bayat Schema 2 beklentisi güncellendi**, hiçbiri zayıflatılmadan. İkisine daha
  güçlü assert eklendi; anlamı tersine dönen bir test susturulmak yerine yeniden
  adlandırıldı.
- **Kalan 15 distinct hatada üretim kodu hatası yok.** Üç aday (BlueprintSelector
  thresholdKind · coral sea · isClean) incelenip elendi. Tek kök neden:
  `sea+dolphin+shell` matris satırının içerik kapsama boşluğu — **bir içerik tasarım
  kararı gerektiriyor, uydurulmadı.**
- **TestPlan 1 → 5 target.** Paketin 761 testi artık Xcode/CI akışında.
- **Ölü kod:** üç silme doğrulandı (0 üretim referansı), `FalImageGenerator` /
  `FalImageService` / `FalAITestView` ölü teyit edildi, **`FalAIImageGenerator` canlı**
  (`SGM:276`) — D1 Dalga 1'e kadar silinmeyecek.

**Not:** düz `swift test` bu repoda codesign hatasıyla düşüyor (`Resources` üzerindeki
`com.apple.macl`/provenance xattr'ları "resource fork… detritus" sayılıyor).
`xattr -cr Sources Tests .build` + `--build-system native` gerekiyor. CI bunu bilmeli.

---

## 2. Grup 1'in gerçekten değiştirdiği dosyalar (33)

`git status` bunu **abartıyor** — çalışma ağacında 17 Eylül tarihli, commit edilmemiş
önceki iş de duruyor (MPStreak, MPParentControls, MPReminder, MPContinueReading,
ContentView, SettingsView, StoryReaderView, HomeView, LibraryView, Story.swift,
StoryGenerationManager, ReaderTimeUpLeaf, StoryCoverFace, MPArcText, MPVocabulary,
MPSettingsStore, MPAppState, ParentPanelView + iki test dosyası).
**Bunlar Grup 1'in işi değildir.** Ayrım dosya zaman damgalarıyla yapıldı.

### Kod (10)
```
DesignSystem/MPTheme.swift MPSurfaces.swift MPControls.swift MPIcon.swift
Helpers/DeviceHelper.swift · MagicPaperApp.swift
Screens/MPStoryExtras.swift · Views/ProfileCreationView.swift
CharacterEngine/Domain/: CharacterIdentity CharacterAssetSet CharacterStyleProfile CharacterProfile
StoryEngine/Content/CatalogBlueprint.swift
StoryEngine/Providers/StoryAIProvider.swift        (yalnızca doküman yorumu)
StoryEngine/Services/Validators/DeterministicValidators.swift
```
### İçerik (3)
```
Resources/blueprints/pilot_library_v1.json                 6 → 15 blueprint
Resources/templates/offline/v2/shared_content_library_v2.json   blueprints: []
MagicPaper/templates/offline/v2/...v2.json                 senkron (shasum eşit)
```
### Test (4 yeni)
```
CharacterEngineTests/: CharacterStoreTests CharacterIdentityStabilityTests CharacterCompatibilityTests
StoryEngineTests/OfflineDeterminismTests.swift
```
### Doküman (8 yeni)
```
docs/MagicPaper_Architecture.md · _Story_Engine_Plan.md · _Character_System.md
docs/MagicPaper_Content_Library.md · _Illustration_System.md · _Design_System.md
docs/MagicPaper_Privacy_Architecture.md · docs/retired/retired_blueprints_2026-09-18.json
```

`visual_catalog.json` yazıldı ve **geri alındı** (HEAD ile birebir) — kasıtlı, bkz. §6.

---

## 3. Yapılan migration

### D3 — Schema 2 kanonik ✅ TAMAMLANDI
- `pilot_library_v1.json`: 6 → **15 blueprint**, hepsi `schemaVersion: 2`
- **RETIRE 12:** v2 blueprint'lerinin on ikisi de aynı yayın kopyasıydı
  (adventure/courage/5-6/8 sayfa, aynı 8 rol). Hiçbiri beat bildirmediği için
  `isBeatAuthored == false` — `BlueprintSelector` onları **hiç seçemiyordu**.
  Anlatı kaybı yok; `docs/retired/retired_blueprints_2026-09-18.json` içinde
  birebir + geri alma talimatıyla duruyorlar.
- **MERGE 5 / KEEP 1 / YENİ 9.** Pilot id'leri korundu (8 test referansı +
  saklanmış hikâyelerin blueprint bağı). `storyIdeas` (4) sırası ve içeriğiyle korundu.
- Schema 2 dışı üretim blueprint'i: **0** (doğrulandı).

### D2 — GERİ ALINDI ❌ → **MPStreak: RETAINED**

Kullanıcı kararı (2026-09-18): **`MPStreak` MagicPaper Kids ürününün parçası olarak
kalıyor.** Kaldırma hiç uygulanmadığı için geri alınacak değişiklik yok.

**Ürün anlamı.** `MPStreak` genel oyunlaştırma değildir. Şunu temsil eder:

> okuma sürekliliği ve ailece hikâye ritüeli — uygulama bağımlılığı değil.

Bir gün sayılmalıdır çünkü aile gerçekten birlikte bir hikâye okudu, ebeveyn
uygulamayı açtığı için değil. Hedeflenen semantik olay `StoryReadingSessionCompleted`;
`AppOpened`/`AppLaunched` değil.

**Genişletilmeyecek:** puan · rozet · liderlik tablosu · rekabetçi sıralama ·
ödül ekonomisi · yapay etkileşim döngüsü.

**Dil kaydı:** "3 gün üst üste birlikte okudunuz." / "Bu hafta 4 hikâye tamamlandı."
Asla: "Serini bozma!" / "Hemen geri dön!" / "Sadece 2 saat kaldı!"

**Denetim yapıldı, kod değiştirilmedi.** On soruluk mimari denetim ve altı bulgu
`docs/MagicPaper_Streak_System.md` içinde. Özet:

- Durum: `UserDefaults` `mp_readDays` (`[String]`) + `mp_readSeconds` (`[String: Double]`),
  **cihaz genelinde, profile bağlı değil**
- Tetikleyici: `markReadToday()`, iki yerden — `StoryReaderView:168` (`open()`) ve
  `DailyStoriesView:311` (`.onAppear`)
- Uygulamayı açmak artırmıyor ✅ · **Hikâyeyi açmak artırıyor** ⚠️ ·
  Tamamlamak şart değil ⚠️
- Aynı gün tekrar okuma idempotent ✅ · Kaçırılan gün seriyi sıfırlıyor ✅
- **H1 gerçek hata:** `SettingsView:462` "tüm veriyi sil" akışı `mp_readDays`'i
  temizliyor ama **`mp_readSeconds`'i bırakıyor** — tek satırlık düzeltme
- **H2:** profile bağlı değil; çok çocuklu ailede sayaç paylaşılıyor
- **H3:** açmak = okumak; ürün niyeti ile uyuşmuyor

**`CLAUDE.md` İlke 7 güncellendi.** Artık "streaks are prohibited" yazmıyor;
hafif süreklilik mekanizmalarına izin veriyor, puan/rozet/liderlik tablosu/
ödül ekonomisi/baskı dilini yasaklıyor. `.claude/agents/parent-ux.md` de güncellendi —
gelecekteki agent'lar `MPStreak`'i kaldırmayı önermeyecek.

### D1, D4 — planlandı, uygulanmadı
Gerekçeler §7'de.

---

## 4. Emekliye ayrılan sistemler

| Sistem | Durum |
|---|---|
| 12 v2 blueprint | ✅ Emekli, arşivlendi |
| `createCustomStory` | ❌ Duruyor — `StoryWizardView:344` + `SGM:42` |
| `TestOfflineTemplateStoryProvider` | ❌ Duruyor — `SGM:1306`, `DevStoryTestView:80` |
| `MPStreak` | ✅ **RETAINED — okuma sürekliliği mekanizması** (D2 geri alındı, 2026-09-18) |
| `FalImageGenerator`, `FalImageService`, `FalAITestView` | ❌ Duruyor (ölü, silinebilir) |

---

## 5. Raporlanmamış üç silme ⚠️

Oturum başındaki envanterde **var olan**, şimdi diskte **olmayan** üç dosya.
Hiçbir agent bunları sildiğini raporlamadı:

```
MagicPaper/Helpers/PremiumComponents.swift    874 satır
MagicPaper/Views/TextStoryLibraryView.swift   244 satır
MagicPaper/Views/TextStoryViewerView.swift    281 satır
                                       toplam 1399 satır
```

Üçü de `git show HEAD:<yol>` ile **kurtarılabilir**. Üçü de bağımsız olarak
"ölü kod" tespit edilmişti (product-architect: referanssız; design-system:
`PremiumComponents`'in 13 public tipi dışarıdan referanssız, gradient/glass/shimmer
ile İlke 9'u ihlal eden ikinci bir tasarım sistemi). Build silmeden sonra da yeşil,
yani gerçekten referanssızlardı.

**Yani silme muhtemelen doğru, ama raporlanmamış ve onaylanmamış.** Karar kullanıcının:
kalsın mı, `git restore` ile geri mi alınsın.

`Helpers/DeviceHelper.swift` de Grup 1 penceresinde değişmiş ama hiçbir raporda geçmiyor.

---

## 6. Çözülmemiş çakışmalar

### Ç1 — 38 test kırmızı, üç kova
| Kova | Test | Sahip |
|---|---|---|
| Bayat sabitleme (sayım/fingerprint) | ~11 | story-engine |
| **Seed drift** | 3 (`OfflineDeterminismTests`) | **ürün kararı** |
| Motor/içerik uyuşmazlığı | ~10 | story-engine + content-library |

İki hata **üretim kaynağından** geliyor, testten değil:
`BlueprintSelector.swift:119`, `OfflineSelection.swift:181`. Bunlar bayat pin değil.

### Ç2 — Seed drift: ürün kararı gerekiyor
5 MERGE blueprint'in `requires`/`forbids`'i değişti → havuz üyeliği değişti.
`testAStoredSeedRebuildsTheSameBookInAFreshProcess`: sabit seed artık
deniz+yunus yerine orman+tavşan çözüyor, başlık değişiyor.
**Soru:** mevcut kullanıcıların saklanmış hikâyeleri yeniden açıldığında değişecek mi?
Pratik risk `UserDefaults` blob'unun üretilmiş metni saklayıp saklamadığına bağlı —
**bu doğrulanmadı.** Doğrulanmadan D4 migration'ı yapılmamalı.

### Ç3 — Motor açığı
`BlueprintSelector.admissible` `requires.thresholdKind`'ı denetlemiyor, sadece trait'lere
bakıyor. content-library içerik tarafından geçici kapattı; asıl düzeltme story-engine'in.

### Ç4 — `setting_coral_sea_001` sahipsiz
14 blueprint'in hepsi setting'e kısıt koyuyor; mercan denizi sadece `hasWater + isOpen`
bildiriyor. Phase-4 matrisinin `sea+dolphin+shell` satırı hiçbir blueprint'e oturmuyor.
Ölçüldü: `canConceal` eklemek 38→35 yapıyor. Kısmi kazanç için içerik değiştirilmedi.

### Ç5 — Katalog düzeltmesi + fixture tek commit olmalı
illustration-system'in `visual_catalog.json` düzeltmesi 6 `GoldenFixtureTests`'i kırıyor
(fixture `negativeClauseCount` ve `assetFingerprints` pinliyor). Bu, katalogun canlı
zinciri beslediğinin **kanıtı**. Diff hazır (`_Illustration_System.md` §3.4).
Fixture yenileme story-engine'in alanı → **birlikte atılmalı**.

### Ç6 — Paralel çalıştırma altyapısı
Agent'lar aynı `.build` dizinini paylaştı → "Another instance of SwiftPM is already running".
Bir agent, başka bir agent mid-edit'teyken test koştu ve hayalet kırmızı gördü.
**Grup 2'de her agent `--scratch-path` ile ayrı dizin kullanmalı.**

---

## 7. Kalan teknik borç

### Güvenlik — acil
1. **RevenueCat `sk_` secret key repoda ve git geçmişinde.** `REVENUECAT_API_KEY_FIX.md`
   (3 satır), commit `4101e29`. `.gitignore` markdown'ı kapsamıyor. → **iptal edilmeli**
2. **Gemini API anahtarı cihaz loguna basılıyor.** `AIService.swift:314` endpoint'i
   `?key=\(apiKey)` ile kuruyor, `:319` `print` ediyor. Release'de de basılıyor
   (repoda 5 `#if DEBUG` var, hiçbiri log sarmıyor). → **döndürülmeli**

### Çocuk güvenliği — ürün kritik
3. **Güvenlik doğrulama hattı tamamen ölü.** 8 validator da yazılmış, `StoryEngineContainer`
   hiç inşa edilmiyor → hiçbiri erişilebilir değil. Canlı Gemini çağrısı `safetySettings`
   göndermiyor; canlı fal.ai çağrısı `enable_safety_checker` göndermiyor.
   **Çocuğa giden içeriğin önünde şu an hiçbir kontrol yok.**
4. **İlke 5 + İlke 9 ihlali üretimde.** `FalAIImageGenerator.swift:21` her görsele
   `"3d pixar style render, cute, vibrant colors, 8k"` ekliyor. `AIService.swift:99/:828`
   çocuğun görünüşünü **her sayfada bir dil modeline** yazdırıyor. `CharacterProfile`
   bu yola hiç girmiyor. → D1 ile `createCustomStory` gidince kendiliğinden kapanır.
5. **`ComposedStory.isClean` üretimde hiç çağrılmıyor** — 10 test dosyasında assert
   ediliyor, sıfır üretim tüketicisi. Yerine konmamış `{{discovery.name}}` okuyucuya
   gidebiliyor. Düzeltmesi bridge'de tek guard.
6. **Firebase silme yolu yok.** Yüklenen görsel hikâye/profil silinince de kalıyor.
   `PRIVACY_POLICY.md` 30 günlük otomatik silme yazıyor; bunu yapan kod yok.
   (Hafifletici: `createCustomStory` bugün çocuk fotoğrafı değil,
   `MPAvatarRenderer` harf avatarı gönderiyor; `ImagePicker` yalnızca erişilemez test
   ekranlarında. Yani boru hattı **canlı kullanıcı verisi olmadan** temizlenebilir.)
7. **`deleteProfile` o çocuğun hikâyelerini silmiyor** — `Story.childProfileID` var,
   cascade hiç yazılmamış.
8. **`StoryGenerationManager.swift:347` ve `:444`** — `print("🎬 Child: \(childName), Age: \(age)")`.
   Ad ve yaş doğrudan loga. `:347` canlı yolda. ProfileManager'ın 20 `print()`'inin
   tamamından ağır (onların hiçbiri ad/yaş basmıyor).
9. **441 `print()`** (app 430 + paket 11), `os.Logger` 0. Sınıflandırma:
   P0 anahtar sızdıran 3 · P1 çocuk verisi 33 · P2 türetilmiş 44 · P3 operasyonel 156 · güvenli 205.
   Dosya:satır listesi `_Privacy_Architecture.md` içinde, Grup 2 iş emri olarak sıralı.

### Mimari
10. **Yaş hikâye üretimine hiç girmiyor.** `OfflineStoryIntent` yalnızca
    `childName: String` taşıyor. `BlueprintSelector` yaşa göre filtrelemiyor.
    Uygulama 5-7/8-10/11-12 sunuyor, korpusta **yalnızca 3-4 ve 5-6 var**.
    Ölçüldü: `suits(age: 9)` → **0 fikir**.
11. **Çocuğun kimliği bugün bir `String`.** Canlı akışta `CharacterProfile` hiç yaratılmıyor.
    `ProfileCharacterSource` → `StoryEngineContainer` → tüketici yok. Silinmemeli;
    D4 için gereken her parça burada, çalışır ve test edilmiş.
12. **`CharacterVersionID` ve `CharacterAsset.id` taze UUID** — aynı girdiden üretilen iki
    `CharacterVersion` eşit değil. D4 migration'ı sürümleri **kopyalamalı, yeniden inşa
    etmemeli**; aksi hâlde çocuğun görsel kimliği kalıcı kayar.
    **Zamanlama:** bugün pinli kitap yok → risk bugün sıfır, köprü canlanınca yüksek.
13. **`FileStores` üç yerde sessiz:** `save` Documents erişilemezse sessizce "başarılı";
    `load`/`loadAll` çözümlenemeyen dosyayı atlıyor. Hikâye için kabul edilebilir,
    **karakter için değil** — `nil` "karakter yok" diye okunur ve yeni versiyon basılır.
14. **Hiçbir yerde `FileProtection` yok.** Üç yazma noktası da çıplak `write(to:)`.
15. **`stories.undecodable.*` yedekleri sınırsız, hiç temizlenmiyor.**
16. **`migrateOldStoriesIfNeeded()` (SGM:939)** 4 MB üstünde `UserDefaults["stories"]`'i
    **yedeksiz siliyor**. D4'ten önce kapatılmalı.
17. **`TestPlan.xctestplan` yalnızca `MagicPaperTests`'i içeriyor** — paketin 761 testi
    Xcode/CI'da hiç koşmuyor. `AgeBandCoverageTests` ise `swift test` altında koşmuyor.
    İki suite birbirini görmüyor.
18. **Merkezi yükleme ve hata yüzeyi yok.** `errorMessage` üç ekranda bağımsız çiziliyor.
19. **54 `MPIcon` çağrısı 17 ayrı boyut kullanıyor.** `MP.G` ölçeği eklendi, çağrılar taşınmadı.

---

## 8. Grup 2 önkoşulları

**Başlamadan önce yapılması gerekenler:**

1. **Ç2 kararı (seed drift).** `UserDefaults["stories"]` blob'unun üretilmiş metni mi
   yoksa yalnızca seed'i mi sakladığı doğrulanmalı. Metni saklıyorsa drift kullanıcıyı
   etkilemez; seed'i saklıyorsa mevcut kitaplar değişir. **D4 bundan önce başlamamalı.**
2. **38 testin sıfırlanması.** Kırmızı ağaç üzerine D1/D2/D4 ameliyatı yapılırsa
   hata atfı imkânsızlaşır. Sahip: story-engine (bayat pin + motor açığı) + content-library (Ç4).
3. **§5 karar:** üç silinmiş dosya kalsın mı, geri mi alınsın.
4. **Anahtar döndürme** (§7.1, §7.2) — kod işi değil, kullanıcı işi.
5. **`TestPlan.xctestplan`** paket target'larını içermeli, yoksa entegrasyon
   doğrulaması yarım kalır.
6. **`.build` izolasyonu** — her agent `--scratch-path` ile ayrı dizin.

**Grup 2 kapsamı ve sahiplik (çakışmasız):**

| Agent | Alan | Bağımlılık |
|---|---|---|
| story-engine | `StoryGenerationManager.swift` **tek sahip**, D1 adım 1-5 | önkoşul 2 |
| character-system | `CharacterEngine/` + `ProfileManager` devri | — |
| parent-ux | onboarding, home, akış | — |
| reader | `Screens/StoryReader/` | — |
| library-memory | D4 persistence, `StoryGenerationManager` **D1'den sonra devralır** | önkoşul 1, D1 |
| monetization | entitlement soyutlaması (`isPremium` 19/10 dosya) | — |

**D1 tek adımda yapılamaz.** `createCustomStory` kaldırılırsa illüstrasyonlu masal
üretme tamamen kaybolur; yerine geçecek özellik (`MPAppState:79-85`'te niyet olarak
yazılı) henüz yok. Dalga 0 (bugün güvenli: ölü kod silme, `isClean` guard, test planı,
UI dikişi) Dalga 1'den (illüstrasyon ikamesine bağlı) ayrılmalı.

**MPStreak: RETAINED.** Kaldırma işi yok. İkinci dalgada sahiplik: **parent-ux**
(durum, tetikleyici, kopya) ve **reader** (okuma süresi defteri, günlük bütçe,
`ReaderTimeUpLeaf`). Okuma süresi tarafı oyunlaştırma değil, ebeveyn kontrolü.
Açık işler: H1 (tek satır), H3 (`StoryReadingSessionCompleted` semantiği),
H2 (profil kapsamı — D4 ile birlikte). Detay: `docs/MagicPaper_Streak_System.md`.
