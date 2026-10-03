# FAZ 10 — Mod seti ve oluşturma akışı: uygulama planı

**3 Ekim 2026**, `docs/`'a taşındı 4 Ekim 2026 (FAZ 9 main'e birleşti). Kaynak: `MagicPaper_Faz_Plani_Ekim.md` FAZ 10.

**Uygulama durumu (4 Ekim 2026, dal `faz-10`):**
- A, B, C uygulandı.
- D (eski sihirbazın kaldırılması) FAZ 9'da yapıldı (`a895f3f`). FAZ 10'da kalan `MPStoryLength`/`MPStoryTone` da silindi.
- FAZ 9'dan devir (madde 7): `MPBridge.swift` başındaki "Gemini/Fal.ai hattı" yorumu güncellendi.
- Ana sayfadaki dünya şeridini FAZ 9 zaten kaldırmıştı. Mod kartları aynı yere, "Kaldığın yer" kartının altına geldi.

**Kapanış (4 Ekim 2026): FAZ 10 ✅.** Kapanış notu, tasarım yasası borcu ve koyu tema açık sorusu
`MagicPaper_Faz_Plani_Ekim.md`'de (FAZ 10 bölümü ve belgenin sonu).

Bütün kararlar kapandı (3 Ekim, Batuhan): K1-K9. Özeti §13'te.

---

## 0. Bağlam ve başlama koşulu

FAZ 10, yaratma akışını 3 Ekim kararlarına oturtuyor:
- `growth` yerine `learning`,
- sürprizle yalnızca tek seferlik masal,
- `StoryIdeaStep` bayrak arkasında,
- uzunluk yaş bandından, ton moddan,
- eylem rengi #6A47B8,
- dünya seçiminin kalkması.

Plan FAZ 9 (temizlik) sürerken yazıldı. Retired/, Gemini/AIService metin yolu ve FAZ 9'un sileceği eski `Views/`
dosyalarının hiçbirine **dayanmıyor**. `StoryWizardView` FAZ 9'dan sağ çıkarsa FAZ 10'un sonunda kaldırılır (§10).

**Başlama koşulu:** FAZ 9 bitmiş ve `StoryGenerationManager.swift` serbest bırakılmış olmalı (tek sahipli dosya).
`STORY_MODE.md`'yi FAZ 9 da güncelliyor. FAZ 10 onu FAZ 9'un bıraktığı hâlin üstüne günceller.

---

## 1. Kod incelemesinin bulguları (3 Ekim 2026)

| Konu | Bugünkü durum |
|---|---|
| `StoryMode` | `StoryEngine/.../Offline/StoryMode.swift`: `String` ham değerli enum (`growth / adventure / bedtime`), sentezlenmiş `Codable` |
| Kayıtta mod | `Story.origin.modeID: String?` (`Models/Story.swift:103`). `StoryMode(rawValue:)` ile okunuyor: `StoryDetailModel.swift:11` (`mpMode`; raf filtresi de bunu kullanıyor) ve `StoryGenerationManager.swift:1340` (`recentModes`). `StoryArtKit.swift:96` ham string ile eşliyor |
| Katalog | Tek dosya `pilot_library_v1.json`; `storyModes[0].mode = "growth"`. 15 blueprint var |
| Bütünlük | `CatalogIntegrity.checkStoryModes` modun **herhangi bir** bantta ulaşılabilir olup olmadığına bakıyor. Bant bazlı denetim yok |
| Bant | `AgeBandResolver` zaten 3-4/5-6/7-8/9-10. `servedBand` global çalışıyor: içeriği olan en yakın bant, eşitlikte küçüğü |
| Uzunluk | `AgeBand.pageCount` **kodda** (`ContentPrimitives.swift`): 3-4→6, 5-6→8, 7-8→8, 9-10→10. `checkAgeFit` uyuşmazlığı yalnızca uyarı sayıyor |
| Ton | Motorda ton kavramı yok. Mod yalnızca bir aile kümesi seçiyor (`bedtime` → `charge`) |
| Akış | `StoryCreationFlow`: mod → (fikir) → arkadaş. Uzunluk ya da ton seçimi **yok** |
| Eski sihirbaz | `StoryWizardView` iki yerden açılıyor: `HomeView` dünya şeridi (`illustratedPath`, `startWizard(world:)`) ve `ParentChildrenView` "Favori dünyalar". Kendi içinde sabit `MPStoryLength.orta` / `MPStoryTone.neseli` kullanıyor |
| Yaş seçici | `MPAgeRange` zaten 4 bant (3-10). Eskiden kaydedilmiş 11/12 yaş 9-10'a oturuyor |
| Sürpriz | `StoryOrigin.selectionStrategy` zaten kaydediliyor |
| Renk | `MP.C.brand* = Palette.gul*` (#C1436B). `MP.C.brand` 41 yerde kullanılıyor. 5 bileşen `Palette.gul*`'u doğrudan okuyor (`MPControls` ×3, `MPNavigation`, `ParentOverviewView`); bu bugünkü bir yasa ihlali |

---

## 2. `growth` → `learning`: kaydedilmiş masallar

**Etki.** Diskte `origin.modeID = "growth"` olan masallar var. Yalnızca vakanın adı değişirse `StoryMode(rawValue: "growth")`
`nil` döner. Masal yine açılır, çünkü `modeID` bir String. Ama şunlar sessizce bozulur:
- mod etiketi ve raf filtresi kaybolur,
- sürpriz geçmişi bu masalları saymaz,
- Faz 13 (seri) ve Faz 14 (kullanımdan öğrenme) yanlış veri okur.

**Çözüm.** Veri yeniden yazılmaz, değişiklik geri alınabilir:
1. **Motor:** `case learning` (ham değeri `"learning"`). Eski adlar tek bir tabloda: `StoryMode.legacyAliases = ["growth": .learning]`. Yeni `public init?(storedID:)` önce ham değere, sonra eski ada bakar. Özel `init(from:)` (Decodable) aynı yolu kullanır.
2. **Uygulama:** `StoryOrigin.mode: StoryMode? { modeID.flatMap(StoryMode.init(storedID:)) }`. `mpMode`, `recentModes` ve `StoryArtKit` bunu okur. `StoryMode(rawValue:)` ile `modeID` okuyan başka yer kalmaz.
3. **Yazma:** Yeni masallar `"learning"` yazar (`OfflineStoryMapper` zaten `mode?.rawValue` kullanıyor). Eski kayıtlar diskte `"growth"` olarak kalır. Toplu göç yapılmaz.
4. **Katalog:** `storyModes` içinde `"mode": "learning"` yazılır, `editorialNote` yeni adla güncellenir.

**Geriye dönük çözme testi** (ilk yazılacak test, önce kırmızı olmalı): `StoryModeFlowTests.testAStorySavedAsGrowthOpensAsLearning`
- Mevcut `testAStorySavedBeforeModesStillDecodes` kalıbı kullanılır: masal üret, JSON'a çevir, `origin.modeID = "growth"` yaz, geri çöz.
- Doğrulananlar:
  - `mpMode == .learning`;
  - içinde hem `"growth"` hem `"learning"` olan bir rafta tek bir `.learning` filtresi çıkar;
  - `recentModes` `"growth"`'u `.learning` sayar;
  - sayfa metni ve `blueprintID` değişmez.
- Motor tarafında: `StoryModeTests.testLegacyGrowthDecodesAsLearning`.
- `StoryDetailModelTests` ve `StoryArtKitTests` içindeki `"growth"` fikstürleri eski veri olarak kalır. Beklentileri `.learning`'e çevrilir.

---

## 3. Hangi mod hangi bantta blueprint'e ulaşıyor (bugünkü katalog)

Ailelerin alt yaşı: `unexplained` ve `misreading` en az 5. `appeal`, `threshold`, `absence` ve `charge` 3.

| Profil bandı | Sunulan bant | Sayfa | Yeni şeyler öğrenelim | Maceraya çıkalım | Uyku öncesi | "Bana sürpriz yap" (K6) |
|---|---|---|---|---|---|---|
| 3-4 | 3-4 | 6 | ✗ 0 | ✗ 0 | ✓ 1 (`charge`) | **gizli** (tek mod) |
| 5-6 | 5-6 | 8 | ✓ 8 (unexplained 3, appeal 3, misreading 2) | ✓ 4 (threshold 2, absence 2) | ✓ 2 | görünür |
| 7-8 | 5-6 (geçici) | 8 | ✓ 8 | ✓ 4 | ✓ 2 | görünür |
| 9-10 | 5-6 (geçici) | 8 (bant tanımı 10) | ✓ 8 | ✓ 4 | ✓ 2 | görünür |

**İçerik hattına gidecek eksikler:**
- 3-4 bandına bir `appeal` blueprint'i (Yeni şeyler öğrenelim).
- 3-4 bandına bir `threshold` ya da `absence` blueprint'i (Maceraya çıkalım).
- Gerçek bir uyku arkı.
- 7-8 ve 9-10 içeriği.

Bu matris `ModeBandCoverageTests` ile sabitlenir. İçerik geldiğinde test bilerek güncellenir.

---

## 4. Bant bazlı bütünlük: "mod düşer, hata vermez"

- **`BlueprintSelector.modeCoverage(catalog:) -> [AgeBand: [StoryMode]]`:** her `AgeBandResolver.bands` için o bandın kendi blueprint'lerine bakar.
- **`CatalogIntegrity.checkStoryModes`:**
  - İçeriği olan bir bantta mod blueprint'e ulaşamıyorsa `warning` / `mode_unavailable_in_band`.
  - İçeriği hiç olmayan bant için bant başına tek bir `warning` / `band_without_content`.
  - `mode_unservable` (mod hiçbir bantta yok) `error` olarak kalır.
- **Akış:** `availableModes(forAge:)` kurulamayan modu zaten göstermiyor; bu değişmez. Kullanılamayan modun kartı ne akışta ne ana sayfada görünür (K6).

---

## 5. Sürpriz yalnızca tek seferlik masal üretir

Davranış zaten doğru. FAZ 10 sözleşmeyi sabitler:
- Yeni test `testASurpriseStoryRecordsItsStrategy`.
- `StoryOrigin` doc yorumuna Faz 13 notu: seri yalnızca `selectionStrategy == "direct"` olan masaldan açılır.

**K6 kuralı:** "Bana sürpriz yap" kartı, o bantta en az iki mod kullanılabiliyorsa görünür; tek mod varsa gizlenir.
Kural görünümde değil, `StoryCreationSteps.showsSurprise(availableModes:)` içinde durur ve test edilir.
Not: `StoryModeStep`'te tek mod kalınca ekranda bir kart olur. Bu doğru davranış, boş ekran değil.

---

## 6. `StoryIdeaStep` bayrağa, `subOption` alanı

**Bayrak (K7).** Yeni `MagicPaper/StoryEngineBridge/StoryIdeaStepAccess.swift`, `IllustratedBookAccess` kalıbını izler.
`developerFlagKey = "mp_dev_storyIdeaStep"`. Varsayılan her build'de **kapalı**: DEBUG'da da. Release'te `isEnabled()` hep `false` döner.
Açma yolu: `Views/SettingsView.swift` içindeki DEBUG'a özel "Geliştirici" bölümüne, görselli kitap anahtarının yanına bir anahtar eklenir.
Bu bölüm Release'te görünmez, yani yayınlanan uygulamada fikir adımı açılamaz.

**Akış kararı görünümden çıkar.** Yeni `Screens/StoryCreation/StoryCreationSteps.swift` üç kararı tutar:
- `showsIdeaStep(ideas:flag:)`,
- `showsSurprise(availableModes:)`,
- `stepLabels(ideaStep:)`.

Sonuçları:
- Bayrak kapalıyken adım noktaları ikidir: "Masal", "Kimler". `chosenIdeaID` hep `nil` kalır ve motor fikri kendisi seçer.
- `StoryIdeaStep.swift` silinmez, dosyaya dokunulmaz.

**`subOption`.**
- `OfflineStoryIntent.subOption: String? = nil`. Seçici ve composer bu alanı okumaz.
- Uygulama tarafı (K3): `StoryOrigin.subOptionID: String?`, boş alan olarak açılır. `OfflineStoryService.compose(subOption:)` ve `StoryGenerationManager.createStory(subOption:)` değeri geçirir; akış `nil` verir.
- Testler:
  - aynı tohumla `nil` ve `"x"` aynı `fingerprint`'i verir;
  - bu alanı içermeyen eski bir origin `subOptionID == nil` ile çözülür (`testAStorySavedBeforeSubOptionsDecodesWithNil`);
  - yeni masalda `subOptionID == nil`.

---

## 7. Uzunluk yaş bandından, ton moddan

- **Uzunluk:**
  - Kaynak `AgeBand.pageCount` (K2: kodda, `maxSentenceWords`'ün yanında kalır; kataloğa taşınmaz). Uygulanan sayfa sayısı sunulan bandın blueprint'inden gelir.
  - `page_count_off_band` uyarısı `error`'a yükselir. Bugünkü katalog bunu 15/15 sağlıyor.
- **Ton (K4):** Ayrı ton alanı açılmaz. Ton modun anlatı ailelerinden gelir. Bu, `STORY_MODE.md`'ye ve `StoryModeProfile` doc yorumuna açıkça yazılır.
- **Akışta seçim:** `StoryCreationFlow`'da uzunluk ya da ton seçimi yok; eklenmez. `MPStoryLength`/`MPStoryTone` yalnızca eski sihirbazda kullanılıyor ve §10'da onunla birlikte gider. `Capability.swift:44`'teki doc yorumu güncellenir.
- **11-12 yaş:** Davranış zaten doğru. Yalnızca `testElevenAndTwelveAreServedAsNineToTen` testi eklenir.

---

## 8. Mod sunumu

- **Başlıklar:** "Uyku öncesi", "Yeni şeyler öğrenelim", "Maceraya çıkalım".
- **`learning`:** ikonu `sparkles`, aksanı `MP.C.brand`.
- **`CompanionStep` başlığı:** "Masalda kimler olsun?"
- **Sıra (K5):** `StoryMode` enum sırası sabit kalır (`learning, adventure, bedtime`); sürprizin eşitlik bozması ona bağlı.
  Ekran ve ana sayfa sırası sunum katmanında ayrı tanımlanır: Uyku öncesi, Yeni şeyler öğrenelim, Maceraya çıkalım.
  Tek kaynak: `StoryMode.displayOrder` (sunum uzantısında). Akış ve ana sayfa kartları bunu kullanır; test sırayı sabitler.

---

## 9. Ana sayfa: dünya şeridi yerine mod kartları (K8)

- **`HomeView.illustratedPath` kalkar.** Yerine `modeCards` gelir:
  - `StoryChoiceSources.current.availableModes(forAge:)` ile yalnızca kullanılabilen modlar gösterilir;
  - kart `MPChoiceTile` ile çizilir (başlık, `symbol`, `accent`);
  - Türkçe `accessibilityLabel` taşır.
- **Kart yeni akışın ikinci adımını açar.**
  - `MPAppState.startStoryCreation(mode: StoryMode? = nil)`: `creationPreset` ayarlanır, `showStoryCreation = true` olur.
  - `StoryCreationFlow` açılışta preset varsa `chosenMode = preset`, `strategy = .direct` kurar ve doğrudan `.companion`'dan başlar ("Masalda kimler olsun?").
  - Bu akışta "geri" mod ekranına döner. Preset tek kullanımlıktır, akış kapanınca sıfırlanır.
- **Hero kartı ve (+) düğmesi:** Bugünkü gibi birinci adımı açar. Ana sayfada sürpriz kartı yok; sürpriz akışın birinci adımında, K6 kuralıyla.
- **`ParentChildrenView`:** "Favori dünyalar" bölümü (`favoriteWorlds`, `topWorlds`) kalkar. Dünya kavramı kalktığı için yerine şimdilik bir şey konmaz.
  **FAZ 12 notu:** Bu boşluğa çocuğun "İlgi alanları" düzenleme bölümü gelecek. FAZ 10 yer tutucu bırakmaz, FAZ 12 bölümü bu konuma ekler.
- **Kalan kapak işleri:** Masalların kapak/dünya görseli (`mpWorld`, `worldID`, `StoryArtKit`) kapak sanatı olarak kalır. Bu bir seçim değil, değişmez.
- **Yan etki (kabul edildi):** Görselli masal yolunun uygulamadaki tek girişi bu şeritti. Şerit kalkınca girişi de kalkar. Görsel servisler (`FalImageProvider`, `FirebaseImageUploader`, `VisualSystem`) FAZ 9 madde 6'daki gibi bayrak arkasında, izole kalır. B2 görselli kitap (`IllustratedBookAccess`, `MPSheets`) ayrı bir yol ve etkilenmez. Görselli masal ertelendi; bayrak arkasında kalması yeterli.

---

## 10. Eski sihirbazın kaldırılması (FAZ 10 sonu, envanter onayıyla)

FAZ 9 `StoryWizardView`'ı silmediyse FAZ 10'un son adımı budur. Önce envanter çıkar, Batuhan onaylar, sonra silinir.
Envanterde her kalem için şunlar yazılır: pbxproj/senkron klasör, referans, test.

| Aday | Not |
|---|---|
| `Screens/StoryWizardView.swift` | Sihirbazın kendisi. Yalnızca onun kullandığı yardımcılar envanterde tek tek doğrulanır |
| `MPAppState`: `MPWizardPreset`, `showWizard`, `wizardPreset`, `startWizard(world:)` | |
| `ContentView.swift:70-72` | `fullScreenCover(isPresented: $app.showWizard)` |
| `DesignSystem/MPBridge.swift`: `MPStoryLength`, `MPStoryTone` | Yalnızca sihirbaz kullanıyor |
| `Services/Entitlements/Capability.swift:44` | `MPStoryLength`'e atıf yapan doc yorumu |

**Kabul:** `grep -rn "StoryWizardView\|startWizard\|showWizard\|MPWizardPreset" MagicPaper/MagicPaper` boş döner.

---

## 11. Eylem rengi (K1: İrem'in canvas'ı, degrade yok)

### İrem için özet: altı mor ton

Kontrast WCAG 2.x oranı. "Kâğıt" uygulamanın zemini (`kagit100`, #FDF6EE).

| Ton | Hex | Kaynak | Kullanım | Kontrast |
|---|---|---|---|---|
| Ana | #6A47B8 | canvas | eylem rengi: buton dolgusu, seçili adım, mod aksanı | beyaz metin 6.55 · kâğıtta 6.11 |
| Basılı / koyu | #5C3A8F | canvas | basılı buton, link, açık mor zemin üstünde metin ve ikon | beyazda 8.55 · açık mor zeminde 7.44 |
| En koyu | #3A2458 | canvas | butonun sert alt kenarı (`mpEdge`) | beyazda 13.35 |
| Hover | #7653C2 | türetildi, onaylı | basılmadan önceki hâl (bugün kullanılmıyor) | beyaz metin 5.55 |
| Açık zemin | #F2EDFA | türetildi, onaylı | yumuşak buton ve rozet zemini | üstünde #5C3A8F 7.44 · #6A47B8 5.70 |
| Açık kenar | #DCD0F1 | türetildi, onaylı | açık yüzeylerin süs kenarı | metin taşımaz · kâğıtta 1.37 |

Lavanta (#8F6BD6, canvas) bu altıya dahil değil. Yalnızca odak halkası ve tamamlanmış adım noktalarında kullanılır.
Kâğıtta kontrastı 3.74: metin olmayan öğe için yeterli (≥ 3:1), metin ve ikon için yetersiz (< 4.5). Canvas'taki buton degradesi alınmadı; butonlar düz renk.

### Ayrıntı

**Canvas'tan alınanlar** (`MP.Palette.mor*`, kontrastlar WCAG 2.x göreli parlaklıkla hesaplandı):

| Token | Hex | Kaynak | Beyaz | `kagit100` (uygulama zemini) |
|---|---|---|---|---|
| `mor500` ana | #6A47B8 | canvas | 6.55 | 6.11 |
| `mor600` basılı/koyu | #5C3A8F | canvas | 8.55 | 7.97 |
| `mor900` en koyu | #3A2458 | canvas | 13.35 | 12.45 |
| `morLavanta` | #8F6BD6 | canvas | 4.01 | 3.74 |

**Türetilenler** (canvas'ta karşılığı yok, 3 Ekim'de onaylandı):

| Token | Hex | Kullanım | Kontrast |
|---|---|---|---|
| `mor400` | #7653C2 | `brandHover` (bugün kullanılmıyor; token korunsun diye) | beyaz metin 5.55 |
| `mor50` | #F2EDFA | `brandSoft` (yumuşak zemin) | üstünde `mor600` metin 7.44, `mor500` 5.70 |
| `mor100` | #DCD0F1 | `brandSoftEdge` (yumuşak yüzeyin süs kenarı) | metin taşımaz; `kagit100`'e karşı 1.37, bilgi taşımadığı için 3:1 gerekmez |

**`MP.C` eşlemesi:**
- **Ana tonlar:** `brand → mor500`, `brandPress → mor600`, `brandEdge → mor900`, `brandHover → mor400`, `brandSoft → mor50`, `textOnBrand = kagit0`.
- **Metin:** `textLink → mor600`. Yeni `brandInk → mor600`, yumuşak zemin üstündeki metin ve ikon için (7.44).
- **Yalnızca metin dışı öğe (lavanta):**
  - `focusRing → morLavanta` (metin dışı öğe, 3.74 ≥ 3:1);
  - yeni `brandTrack → morLavanta`, tamamlanmış adım noktaları için (3.74 ≥ 3:1). Adım ayrıca etiketle de bildiriliyor.
- **Gölge:** `MP.Sh.brand` rengi `mor500`.

**Kurallar:**
- `morLavanta` **yalnızca** `focusRing` ve `brandTrack` üzerinden okunur. Beyaz ya da kâğıt zemin üstünde metin veya ikon olarak kullanılmaz. Bu kural design-system belgesine yazılır.
- Degrade yok. Butonlar düz `brand` dolgusu ve `mpEdge(brandEdge)` ile çizilir; canvas'taki buton degradesi alınmaz.
- Doğrudan `Palette.gul*` okuyan 5 bileşen `MP.C`'ye geçer:
  - `MPControls.swift:65,92,218` → `brandInk` / `brandSoftEdge`;
  - `MPNavigation.swift:214` → `brandTrack`;
  - `ParentOverviewView.swift:154` → `brandSoftEdge`.
- `gul*` paletten silinmez. Dünya ve avatar aksanları onu okumaya devam eder.
- `docs/MagicPaper_Design_System.md` renk bölümü güncellenir. Kontrast tablosu oraya da girer.

---

## 12. Değişecek dosyalar ve sahipler

**Sıra:** A → B ve C (paralel, ortak dosya yok) → D (sihirbazın kaldırılması) → reviewer.

### A — content-library (motor + katalog)
| Dosya | Değişiklik |
|---|---|
| `StoryEngine/Sources/StoryEngine/Offline/StoryMode.swift` | `learning`, `legacyAliases`, `init?(storedID:)`, `init(from:)` |
| `.../Offline/OfflineSelection.swift` | `OfflineStoryIntent.subOption` |
| `.../Offline/BlueprintSelector.swift` | `modeCoverage(catalog:)` |
| `.../Content/CatalogIntegrity.swift` | bant döngüsü; `page_count_off_band` → error |
| `.../Resources/blueprints/pilot_library_v1.json` | `storyModes`: `learning` |
| `StoryEngine/Tests/StoryEngineTests/StoryModeTests.swift` | `.learning`, eski ad testleri |
| **yeni** `StoryEngine/Tests/StoryEngineTests/ModeBandCoverageTests.swift` | §3 matrisi, uyarı/hata ayrımı, `subOption` tohum testi |

### B — builder (model + köprü; `StoryGenerationManager` bu pakette tek sahipli)
| Dosya | Değişiklik |
|---|---|
| `MagicPaper/Models/Story.swift` | `StoryOrigin.mode`, `subOptionID`, Faz 13 notu |
| `MagicPaper/Screens/StoryDetail/StoryDetailModel.swift` | `mpMode` → `origin?.mode` |
| `MagicPaper/Screens/ArtKit/StoryArtKit.swift` | kit eşlemesi `origin?.mode?.rawValue` ile |
| `MagicPaper/Services/StoryGenerationManager.swift` | `recentModes`, `createStory(subOption:)`; en küçük değişiklik |
| `MagicPaper/StoryEngineBridge/OfflineStoryService.swift`, `OfflineStoryMapper.swift`, `StoryChoiceSource.swift` | `subOption` geçişi |
| **yeni** `MagicPaper/StoryEngineBridge/StoryIdeaStepAccess.swift` | bayrak |
| `MagicPaperTests/StoryModeFlowTests.swift` | §2, §5, §7 testleri; bant×mod üretim testi |
| `MagicPaperTests/StoryDetailModelTests.swift`, `StoryArtKitTests.swift`, `AgeBandCoverageTests.swift` | eski fikstürler, 3-4 sürprizi |

### C — design-system (token + ekranlar; `StoryCreationFlow` ve `HomeView` bu pakette tek sahipli)
| Dosya | Değişiklik |
|---|---|
| `MagicPaper/DesignSystem/MPTheme.swift` | `mor*`, `MP.C` eşlemesi, `brandInk` / `brandSoftEdge` / `brandTrack` |
| `MagicPaper/DesignSystem/MPControls.swift`, `MPNavigation.swift`, `Screens/Parent/ParentOverviewView.swift` | `Palette.gul*` → `MP.C` |
| `MagicPaper/Screens/StoryCreation/StoryModeStep.swift` | başlıklar, K6 sürpriz görünürlüğü |
| `MagicPaper/Screens/StoryCreation/StoryCreationFlow.swift` | bayrak, preset mod ile ikinci adımdan açılış, adım noktaları |
| `MagicPaper/Screens/StoryCreation/CompanionStep.swift` | "Masalda kimler olsun?" |
| **yeni** `MagicPaper/Screens/StoryCreation/StoryCreationSteps.swift` + `MagicPaperTests/StoryCreationStepsTests.swift` | adım, sürpriz ve etiket kararları |
| `MagicPaper/Screens/MPAppState.swift` | `startStoryCreation(mode:)`, `creationPreset` |
| `MagicPaper/Views/HomeView.swift` | dünya şeridi → mod kartları |
| `MagicPaper/Screens/Parent/ParentChildrenView.swift` | "Favori dünyalar" kalkar (FAZ 12 notu, §9) |
| `MagicPaper/Views/SettingsView.swift` | DEBUG "Geliştirici" bölümüne fikir adımı anahtarı (K7) |

### D — builder (FAZ 10 sonu, envanter onayından sonra)
§10'daki silmeler. `MPAppState` ve `ContentView`'a yalnızca bu adımda dokunulur. C'nin `MPAppState` değişikliği bu adımdan önce birleşmiş olmalı.

### Belgeler
- `docs/STORY_MODE.md` (mod adları, matris, eski ad tablosu, bayrak; tonun mod ailelerinden geldiği — K4)
- `docs/MagicPaper_Design_System.md`
- `MagicPaper_Faz_Plani_Ekim.md` (FAZ 10 ✅)
- içerik hattı listesi (§3 eksikleri)
- bu plan, `docs/`'a taşınır

### reviewer
Şunlar kontrol edilir:
- kayıt uyumluluğu,
- log'da çocuk verisi olmaması,
- `StoryGenerationManager` diff'inin küçük kalması,
- tasarım yasası grep'leri,
- sihirbaza giden yol kalmaması.

---

## 13. Kararlar (hepsi kapandı, 3 Ekim 2026)

| # | Karar |
|---|---|
| K1 | İrem'in canvas'ı: #6A47B8 / #5C3A8F / #3A2458. Türetilen #7653C2, #F2EDFA, #DCD0F1 onaylandı. Degrade yok. Lavanta yalnızca odak halkası ve adım noktaları |
| K2 | Sayfa sayısı kodda (`AgeBand.pageCount`), kelime bütçesinin yanında kalır |
| K3 | `StoryOrigin.subOptionID` boş alan olarak açılır; eski kayıtlar `nil` ile çözülür (test) |
| K4 | Ton alanı yok; ton mod ailelerinden gelir, `STORY_MODE.md`'ye yazılır |
| K5 | Kod sırası sabit; ekran sırası Uyku öncesi, Yeni şeyler öğrenelim, Maceraya çıkalım |
| K6 | Bantta ≥ 2 mod varsa "Bana sürpriz yap" görünür, tek mod varsa gizlenir; kullanılamayan modun kartı görünmez |
| K7 | Fikir adımı her build'de kapalı; yalnızca Ayarlar > Geliştirici (DEBUG) bölümünden açılır |
| K8 | Dünya şeridi yerine ana sayfada mod kartları, her biri ikinci adımı açar. Eski sihirbaz FAZ 10 sonunda envanter onayıyla silinir. Görselli masal girişinin kalkması kabul; görselli masal bayrak arkasında |
| K9 | A paketi FAZ 9 kabul edilince başlar; B, C, D FAZ 9 merge edildikten sonra |

**Başka fazlara notlar**
- FAZ 12: `ParentChildrenView`'da "Favori dünyalar"ın boşalttığı yere çocuğun "İlgi alanları" düzenleme bölümü gelir.
- İçerik hattı: §3'teki eksikler.

---

## 14. Doğrulama

1. `testAStorySavedAsGrowthOpensAsLearning` önce kırmızı, A + B ile yeşil.
2. Paket testleri scratch-path ile çalışır; hata sayısı ≤ 18.
3. Uygulama testleri ≥ 248 geçer; yeni testler de geçer.
4. **Elle, eski masal:** FAZ 10 öncesi build ile `growth` masalı olan bir simülatöre yeni build kurulur. Masal açılır ve rafta "Yeni şeyler öğrenelim" altında görünür.
5. **Elle, akış:**
   - 3-4 profilde yalnızca "Uyku öncesi" var ve sürpriz kartı yok.
   - 5-6, 7-8 ve 9-10'da üç mod ve sürpriz var.
   - Fikir adımı görünmüyor; iki adım noktası var.
   - Ana sayfada mod kartları var ve her biri "Masalda kimler olsun?" ekranını açıyor; "geri" mod ekranına dönüyor.
   - Dünya şeridi ve "Favori dünyalar" yok.
6. Sihirbaz grep'i (§10) boş; CLAUDE.md'deki 5 tasarım yasası grep'i değişen dosyalarda boş; `morLavanta` yalnızca `MPTheme.swift`'te geçiyor.
7. Ekran görüntüleri: mod ekranı, arkadaş ekranı, ana sayfa, paywall, ebeveyn özeti, çocuklar ekranı. Her biri açık + koyu, en büyük Dynamic Type, iPhone SE + Pro Max.
