# Beş arkadaş B hattı: P56'yı uygulamaya bağlama (Claude)

> **Ajanlar için:** REQUIRED SUB-SKILL: superpowers:executing-plans. Adımlar `- [ ]` ile izlenir. Proje kuralı: testler önce yazılır ama **ara adımda koşulmaz**; hepsi B7'de bir kez koşulur. "Testi koş, kırmızı gör" adımları bu yüzden yok.

**Amaç:** Bayrak açıkken ve istek P56'nın kapsamındayken "Masal yaz" masalı P56 ile yazsın, kaydetsin, "Masalda kimler olsun?" beşliyi göstersin; bayrak kapalıyken uygulama bugünküyle birebir aynı kalsın.

**Mimari:** Yeni küçük dosyalar `StoryEngineBridge/Pilots/P56/` ve `StoryEngineBridge/` altında; mevcut dosyalarda yalnız tek dallanma noktaları. P56 motoru ve içeriği Codex'te, bu hat yalnız tüketir.

**Teknoloji:** Swift, SwiftUI, XCTest (`MagicPaperTests`, Xcode'da senkron klasör: yeni dosya için pbxproj gerekmez), `StoryEngine` paketi.

**Dayandığı belge:** [ortak çalışma planı](2026-11-25-bes-arkadas-ortak-calisma-plani.md) Bölüm 3 (sözleşme) ve Bölüm 5 (B1–B6). Sözleşme iki tarafça kabul edildi: Codex `9865b81`, Claude `951f5ce`.

## Ön koşullar

- [ ] Codex `bes-arkadas/entegrasyon` dalını açtı ve commit'ini `docs/ortak/codex-durum.md`'ye yazdı.
- [ ] C4 entegrasyon dalına birleşti: `P56Support`, `P56Engine.behaviorID`, `P56PinnedSource.sha256`, `ContentSourceMetadata.init(p56:)` / `p56Reference`.
- [x] Worktree `~/MagicPaper-worktrees/claude-uygulama`, dal `codex/bes-arkadas/claude-uygulama` (taban `951f5ce`; `bes-arkadas` adı alt dal açmayı engellediği için `codex/` önekli adlar Batuhan onaylı). İkinci DerivedData açılmaz.

C4 gelmeden bu planın hiçbir görevi başlamaz: altısı da C4 tiplerini kullanıyor.

## Global kısıtlar

- `StoryRuntimeFlags.fiveFriendsPilot` yalnız `#if DEBUG` içinde `UserDefaults.standard.bool(forKey: "mpFiveFriendsPilot")` okur (launch: `-mpFiveFriendsPilot YES`); Release'te sabit `false`.
- P56 isteği bağlam simgeleri motorun kullandıklarıdır: `family`, `guest`, `recall`, `occasion`, `series`, `topic`.
- Arkadaş kimlikleri ve sırası: `companion_fox_pilot_001`, `companion_hedgehog_pilot_001`, `companion_owl_pilot_001`, `companion_city_cat_001`, `companion_bear_001`.
- Log'a ve tanı kaydına çocuğun adı, kimliği, metni girmez; yalnız `StoryRuntimeReason` kodu.
- Saklı P56 kaynağı hiçbir yolda eski katalogla yeniden yazılmaz; yeni istek için eski motoru seçmek serbest.
- Snapshot değişmezleri korunur: exact hash, her okumada doğrulama, bozuk ya da eksik kaynakta güncele geri düşmeme.
- Tasarım yasası (CLAUDE.md §9): yeni görünüm kodu yok; yalnız mevcut `MPCompanionPortrait` kullanılır.

## Dosya haritası

| Dosya | Durum | Sorumluluk |
|---|---|---|
| `MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryMapper.swift` | yeni | `P56ComposedStory` → `Story` |
| `MagicPaper/StoryEngineBridge/Pilots/P56/P56BundledSource.swift` | yeni | paketli payload → doğrulanmış `P56SourceReference` |
| `MagicPaper/StoryEngineBridge/Pilots/P56/five-friends-56-runtime-v1.p56payload.json` | yeni (C4 byte'ları, `cp`) | uygulamayla gelen payload |
| `MagicPaper/StoryEngineBridge/StoryRuntimeRouter.swift` | yeni | bayrak + destek → karar ve neden |
| `MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryWriter.swift` | yeni | bağlamdan P56 masalı yazıp kaydedilecek `Story` döndürme |
| `MagicPaper/StoryEngineBridge/FiveFriendsChoiceSource.swift` | yeni | `StoryChoiceSource` sarmalayıcısı; arkadaş listesini P56 yönünde değiştirir |
| `MagicPaper/Services/StoryGenerationManager.swift` | değişir | `createStory` içinde tek dal |
| `MagicPaper/StoryEngineBridge/StoryChoiceSource.swift` | değişir | `companionDisplayLimit` ve `current`'ın sarmalayıcıyı vermesi |
| `MagicPaper/Screens/StoryCreation/CompanionStep.swift` | değişir | `.prefix(Self.shown)` yerine kaynağın sınırı |
| `MagicPaper/StoryEngineBridge/StoryContextBuilder.swift` | değişir | `recallHistory` P56 masallarını atlar |

`StoryContextBuilder.swift` ortak planın sahiplik tablosunda yoktu; hatırlama girdisi burada kurulduğu için Claude hattına eklenir (`StoryMemory.swift` değişmez).

## Review Focus

1. **Güvenlik ayarı olan profil.** Her profilin güvenliği vardır: `UserProfile.effectiveSafety` ayarsızken `.mostProtective` döner, yani hiçbir zaman nil değildir. P56 C3'ten önce her `contentSafety != nil` isteğini reddeder; **C3'e kadar uygulamada hiçbir istek P56'ya gitmez.** Böyle bir profil bayrak açıkken bile eski motoru ve bugünkü arkadaş listesini görmeli, beşliyi değil. B3 ve B5 testleri.
2. **Masal ailem seçimi seçim ekranında değişince** liste eski yola dönmeli, seçili P56 arkadaşı listede yoksa seçim temizlenmeli. B5 testi; temizleme mevcut `onChange` davranışıyla zaten yapılıyor, test bunu sabitler.
3. **Uygulama Release'te** bayrak argümanı verilse bile açılmamalı. B3 testi `#if DEBUG` dışını derleme zamanında sabitler.
4. **P56 masalının kapağı.** `worldID` P56 dünya kimliğini `MP.World`'e eşleyemezse nil kalır ve varsayılan kapak çıkar; masal açılmalı, çökmemeli. B1 testi.
5. **Kaynağı kayıp P56 masalı** (`contentSource` senkronda silinmiş). Kayıtlı sayfalarla açılır; "Devam ettir" çıkmaz; hatırlamaya girmez. B6 testi.

---

### B1: P56 masalını `Story`'ye çevirme

**Dosyalar:** yeni `MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryMapper.swift`, test `MagicPaperTests/P56StoryMapperTests.swift`

**Arayüzler:**
- Kullanır: `P56ComposedStory`, `ContentSourceMetadata.init(p56:)`, `OfflineStoryMapper.storyWords` değil (P56 sözlük kelimesi taşımaz).
- Üretir: `enum P56StoryMapper { static func story(from composed: P56ComposedStory, childProfileID: UUID, strategy: StorySelectionStrategy?) -> Story; static func fingerprint(of: [P56ComposedPage]) -> String }`. Mod ve yaş bandı `composed`'dan türetilir (`StoryMode` ham değerleri `P56Mode` ile aynı).

- [x] **Test yaz.** (legacy JSON testi mevcut testlere bırakıldı) Fikstür: `Content/Pilots/five-friends-56-runtime-v1/payload.json` → `P56PackageLoader.load` → `P56StoryComposer(package:).compose(P56Request(childID: "test-child", name: "Deniz", age: 5, seed: 7, mode: .learning))` (`P56SnapshotTests`'teki yol çözümü).

```swift
func testMapsPagesAndOriginExactly() throws {
    let composed = try fixtureStory()
    let story = P56StoryMapper.story(from: composed, childProfileID: profileID, mode: .learning,
                                     strategy: nil, ageBand: AgeBandResolver.band(forAge: 5))
    XCTAssertEqual(story.pages.map(\.text), composed.pages.sorted { $0.number < $1.number }.map(\.text))
    XCTAssertEqual(story.pages.count, 8)
    XCTAssertTrue(story.pages.allSatisfy { $0.imagePrompt.isEmpty && $0.imageUrl == nil && $0.imageFileName == nil && $0.art == nil })
    XCTAssertEqual(story.status, .completed)
    let origin = try XCTUnwrap(story.origin)
    XCTAssertEqual(origin.contentSource?.p56Reference, composed.sourceReference)
    XCTAssertNil(origin.contentSource?.reference)
    XCTAssertEqual(origin.catalogVersion, "five-friends-56-runtime-v1")
    XCTAssertEqual(origin.blueprintID, composed.structureID)
    XCTAssertEqual(Set(composed.pages.map(\.settingID)).count, 1)
    XCTAssertEqual(origin.settingID, composed.pages[0].settingID)   // worldID değil (Codex düzeltmesi)
    XCTAssertEqual(origin.companionID, composed.companion.id)
    XCTAssertEqual(origin.discoveryID, composed.discoveryID)
    XCTAssertEqual(origin.seed, "7")
    XCTAssertEqual(origin.modeID, "learning")
    XCTAssertNil(origin.seriesID)
}
func testFingerprintIsStableAndSeedSensitive()   // aynı girdi iki kez → aynı; seed 8 → farklı
func testEncodeDecodeRoundTripKeepsP56Reference() // JSONEncoder/Decoder sonrası story == story, p56Reference aynı
// Legacy Story JSON korunumu: B1 Story.swift'e dokunmuyor; mevcut FrozenLegacyBooksTests ve LegacyCloudStoryDecodingTests B7'de koşar.
func testUnknownWorldLeavesCoverNil()             // origin.worldID == nil iken story oluşur, theme == .custom
```

- [x] **Uygula.** `title = composed.title`, `childName = composed.childName`, `theme = .custom`, `language = .turkish`, `status = .completed`. Sayfa: `StoryPage(id: UUID(), title: "", text: page.text, imagePrompt: "")` (alan isteğe bağlı değil; görsel niyeti yok), `provenance` nil (P56 izi `origin` + kaynak + seed ile yeniden kurulur). `fingerprint` = sayfaların `provenance.renderedSHA256` değerlerinin sırayla `|` ile birleşiminin SHA-256'sı. `settingID` = sayfaların ortak `settingID`'si (sekizi aynı; değilse ilk sayfanınki, test uyumu sabitler). `worldID = MP.World(rawValue: composed.worldID)?.rawValue`. `ageBand?.description`.
- [ ] **Commit:** `git add` iki dosya; `"B1: P56 masalını Story'ye çevir"`.

### B2: Paketli payload

**Dosyalar:** yeni `MagicPaper/StoryEngineBridge/Pilots/P56/P56BundledSource.swift`, payload kopyası, test `MagicPaperTests/P56BundledSourceTests.swift`

**Arayüzler:**
- Kullanır: `P56PinnedSource.sha256`, `P56SnapshotStore`.
- Üretir: `struct P56BundledSource { init(bundle: Bundle = .main, store: P56SnapshotStore); func load() throws -> P56SourceReference }`; `static let resourceName = "five-friends-56-runtime-v1"`, uzantı `p56payload.json`. Varsayılan store kökü `Application Support/P56Sources`.

- [x] **Payload'ı kopyala:** `cp Content/Pilots/five-friends-56-runtime-v1/payload.json MagicPaper/StoryEngineBridge/Pilots/P56/five-friends-56-runtime-v1.p56payload.json`. Yeniden yazma, biçimleme yok.
- [x] **Test yaz.** (6 test; bayt kaynağı enjekte edilebilir, sahte bundle yerine)

```swift
func testBundledBytesMatchPinnedAndContentCopy() // SHA(bundle bytes) == P56PinnedSource.sha256 == SHA(Content/... payload.json)
func testLoadReturnsVerifiedReference()          // ref.payloadSHA256 == P56PinnedSource.sha256, ref.engineBehaviorID == P56Engine.behaviorID
func testTamperedBundleThrows()                  // geçici bundle'da bir bayt değişmiş kopya → load() throws
func testMissingResourceThrows()                 // kaynağı olmayan bundle → load() throws
```

- [x] **Uygula.** Bayt oku, `store.save(payload:expectedSHA256: P56PinnedSource.sha256)` döndür. Kaynak adı paket sürümünden türetilir; C2 v2 kabul edilirse `P56SnapshotStore` ve paket adı v1 + v2'yi tanır, v1 tarihsel kaynak olarak okunabilir kalır. Hata türleri: `missingResource`, store hataları aynen.
- [ ] **Commit:** üç dosya; `"B2: P56 payload'ını uygulamayla paketle"`.

### B3: Yönlendirici

**Dosyalar:** yeni `MagicPaper/StoryEngineBridge/StoryRuntimeRouter.swift`, test `MagicPaperTests/StoryRuntimeRouterTests.swift`

**Arayüzler:**
- Kullanır: `P56Support.unsupportedReasons(for:package:)`, `P56BundledSource`.
- Üretir (ortak plan Bölüm 3, aynen): `StoryRuntimeRoute`, `StoryRuntimeReason`, `StoryRuntimeDecision`, `StoryRuntimeRequest`, `StoryRuntimeFlags`, ve:

```swift
final class StoryRuntimeRouter {   // kaynak bir kez yüklenip kilitle saklanır; struct değil
    func package(for reference: P56SourceReference) -> P56Package?   // B4 için
    init(isEnabled: Bool = StoryRuntimeFlags.fiveFriendsPilot,
         loadSource: @escaping () throws -> (P56SourceReference, P56Package))
    func decide(_ request: StoryRuntimeRequest) -> StoryRuntimeDecision
    /// Destek denetimi için anonim istek; çocuk verisi yok.
    static func p56Request(for request: StoryRuntimeRequest) -> P56Request
}
```

`p56Request`: `childID: "support-check"`, `name: "Deniz"`, `seed: 0`, `mode: P56Mode(rawValue: request.mode.rawValue)`, `companionID`, `contexts`: aile varsa `"family"`, `topicID` varsa `"topic"`, `occasion` varsa `"occasion"`; `contentSafety: request.safety`.

- [x] **Test yaz.** (14 test) Desteklenen temel istek: yaş 5, `.learning`, `companion_fox_pilot_001`, aile/konu/özel gün/güvenlik yok.

```swift
func testFlagOffAlwaysLegacy()          // isEnabled false → .legacy, reason .flagOff; loadSource hiç çağrılmaz
func testSupportedRequestRoutesToP56()  // → .p56(ref), reason nil
func testFamilyGoesLegacy()             // family dolu → .legacy, .unsupportedRequest
func testSafetyGoesLegacyUntilC3()      // safety: .mostProtective → .legacy, .unsupportedRequest
func testAge3GoesLegacy()               // age 3 → .legacy, .unsupportedAge
func testBrokenPayloadGoesLegacy()      // loadSource throws → .legacy, .payloadUnavailable
func testDecisionIsDeterministic()      // aynı istek iki kez → eşit karar
func testSupportRequestCarriesNoChildData() // p56Request(for:).childID == "support-check", name == "Deniz"
func testReleaseFlagIsOff()             // #if !DEBUG: XCTAssertFalse(StoryRuntimeFlags.fiveFriendsPilot)
```

`unsupportedAge` yalnız tek neden `"age"` olduğunda; başka nedenler de varsa `unsupportedRequest`.
- [x] **Uygula.** Varsayılan `loadSource`: `P56BundledSource().load()` + `P56SnapshotStore.load`. Kaynak bir kez yüklenip saklanır.
- [x] **Commit:** `"B3: eski motor / P56 yönlendiricisi"`.

### B4: Masal yazma yoluna bağlama

**Dosyalar:** yeni `MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryWriter.swift`; değişir `MagicPaper/Services/StoryGenerationManager.swift` (`createStory`, `service.compose(context, seed:)` çağrısından önce); test `MagicPaperTests/P56CompositionPathTests.swift`

**Arayüzler:**
- Kullanır: B1, B3, `P56InternalService`, `StoryContext`.
- Üretir: `struct P56StoryWriter { func write(context: StoryContext, source: P56SourceReference, seed: String?, ageBand: AgeBand?) throws -> Story }`; `static func seed(from: String?) -> UInt64` (rakamsa `UInt64(s)`, değilse FNV-1a 64; nil ise `UInt64.random`).
- `StoryGenerationManager` değişikliği: `StoryRuntimeRequest`'i `context` + `service.currentSafety` + `subOption` (konu) + `occasion`'dan kurar; karar `.p56` ise `P56StoryWriter.write` ile yazar, `IllustratedBookBinder`'ı atlar, aynı `stories.insert` / `saveStories` / `MPFunnel` yolunu kullanır. Writer hata atarsa karar `composeFailed` olur ve aynı `context` ile eski yol çalışır.

- [ ] **Test yaz.**

```swift
func testFlagOffOutputUnchanged()        // aynı seed ve bağlam: router kapalıyken üretilen Story metinleri ve origin, değişiklik öncesi yolun çıktısıyla eşit
func testP56RouteWritesAndSaves()        // router .p56 → dönen story.origin.contentSource?.p56Reference != nil, stories[0].id == story.id
func testWriterUsesRealChildForCompose() // P56 masalında childName == profil adı; destek kontrolündeki "Deniz" değil
func testComposeFailureFallsBackWithSameInputs() // writer throws → legacy masal; origin.companionID, modeID, subOptionID, familyCharacterID girdiyle aynı; başka arkadaşa çevrilmedi
func testFallbackReasonHasNoChildData()  // kaydedilen tanı yalnız "composeFailed"; ad ve id içermez
func testSeedBridgeIsDeterministic()     // seed(from: "123") == 123; seed(from: "abc") iki kez eşit
```

Router ve writer `StoryGenerationManager`'a init parametresiyle verilir (varsayılan: gerçekleri); testler sahte verir.
- [ ] **Uygula.** `StoryGenerationManager`'daki değişiklik yalnız dallanma ve bağımlılık enjeksiyonu; mevcut eski yol kodu yer değiştirmez.
- [ ] **Commit:** `"B4: P56'yı masal yazma yoluna bayrakla bağla"`.

### B5: "Masalda kimler olsun?"

**Dosyalar:** yeni `MagicPaper/StoryEngineBridge/FiveFriendsChoiceSource.swift`; değişir `StoryChoiceSource.swift` (protokole sınır, `current`), `Screens/StoryCreation/CompanionStep.swift` (satır 69–71); test `MagicPaperTests/CompanionStepChoicesTests.swift`

**Arayüzler:**
- Kullanır: B3, `P56Support.companionIDs`, `OfflineStoryService.companionKind(id:)`.
- Üretir:
  - `StoryChoiceSource`'a `func companionDisplayLimit(age: Int?, mode: StoryMode?, topicID: String?, family: FamilyCharacter?) -> Int`; protokol uzantısında varsayılan `3`.
  - `struct FiveFriendsChoiceSource: StoryChoiceSource { init(base: any StoryChoiceSource, router: StoryRuntimeRouter, safety: () -> ContentSafety?) }`: her şeyi `base`'e devreder. Yalnız `companionChoices(forIdeaID:mode:age:topicID:family:)` ve `companionDisplayLimit` için, karar `.p56` ise beşliyi kanonik sırayla döndürür (`drawable` süzgeci uygulanmaz, portreler ayırt edilebilir) ve sınır `5`'tir.
  - `StoryChoiceSources.current`: bayrak açıksa `FiveFriendsChoiceSource(base: OfflineStoryService.shared, …)`, değilse bugünkü gibi `OfflineStoryService.shared`.
  - `CompanionStep.candidates`: `.prefix(source.companionDisplayLimit(age: age, mode: mode, topicID: topicID, family: selectedFamily))`; `static let shown` silinir.

- [ ] **Test yaz.**

```swift
func testFlagOffListIsTodays()           // current, OfflineStoryService.shared ile aynı tür; sınır 3
func testP56ListsFiveInCanonicalOrder()  // ids == [fox, hedgehog, owl, city_cat, bear], sınır 5
func testFamilyRestoresLegacyList()      // family dolu → base'in listesi ve sınır 3
func testSafetySetRestoresLegacyList()   // safety .mostProtective → base'in listesi (C3 öncesi)
func testNamesComeFromPackage()          // choice.name ["Tarçın","Kestane","Yıldız","Simit","Böğürtlen"]
```

- [ ] **Uygula.**
- [ ] **Commit:** `"B5: P56 yönünde seçim ekranında beş arkadaş"`.

### B6: Seri ve hatırlama korumaları

**Dosyalar:** değişir `MagicPaper/StoryEngineBridge/StoryContextBuilder.swift` (`recallHistory`, satır ~118); test `MagicPaperTests/P56GuardTests.swift`

**Arayüzler:** Kullanır: B1, `ContentSourceMetadata.p56Reference`, `OfflineStoryService.seriesAvailable(from:)`.

- [ ] **Test yaz.**

```swift
func testP56StoryHasNoSeriesOffer()      // OfflineStoryService.shared.seriesAvailable(from: p56Story.origin!) == false
func testP56StoryNotInRecallHistory()    // yalnız bitmiş P56 masalı olan çocuk → recallHistory(of:) == nil
func testLegacyRecallUnchanged()         // bitmiş legacy masal + P56 masal → yalnız legacy arkadaş sayılır
func testHistoricalResolverRefusesP56()  // HistoricalCatalogResolver.resolve(metadata: .init(p56: ref)) == .unsupported; eski kataloğa düşmez
func testSourceLostP56StaysOutOfRecall() // contentSource nil, catalogVersion "five-friends-56-runtime-v1" → recall'a girmez, seriesAvailable false
```

- [ ] **Uygula.** `recallHistory`'deki süzgece: `origin.contentSource?.p56Reference == nil && origin.catalogVersion != "five-friends-56-runtime-v1"`. Seri tarafında kod değişmez; test mevcut davranışı sabitler.
- [ ] **Commit:** `"B6: P56 masalını seri ve hatırlamanın dışında tut"`.

### B7: Hat sonu doğrulaması (tek koşu)

- [ ] CLAUDE.md doğrulama grep'leri değişen dosyalarda boş.
- [ ] Uygulama testleri, mevcut scheme ve destinasyonla, tek DerivedData'da: yeni `P56*`, `StoryRuntimeRouterTests`, `CompanionStepChoicesTests` + etkilenen `P56SnapshotTests`, `OfflineStoryMappingTests`, `SeriesTests`, `StoryMemoryTests`, `CompanionSymbolTests`. Kırmızı varsa eski taban / yeni regresyon ayrımı yazılır.
- [ ] Simülatör (C3 güvenlik desteği entegrasyondaysa; değilse P56 yolu simülatörde görülemez ve bu açıkça yazılır): `-mpFiveFriendsPilot YES` ile 5 yaşında profil: beşli görünür, masal yazılır, açılır, kitaplıkta durur. Masal sonuna kadar okunur: masal sonu açılır, yıldız ve rozet bugünkü kurala göre sayılır. Bayraksız: ekran bugünküyle aynı. Açık/koyu, en büyük Dynamic Type, SE + Pro Max ekran görüntüsü.
- [ ] Changelog kaydı (kendi hunk'ım), `docs/ortak/claude-durum.md` kaydı, commit. Codex'in incelemesi sonrası entegrasyon dalına `--no-ff` birleştirme.

## Bu planın açık bıraktıkları

- P56 sayfa düzeyindeki kaynak izi `Story`'de sayfa sayfa tutulmuyor; `origin` (kaynak + kitap + seed) ile yeniden kurulabiliyor. Codex'e soruldu (`claude-durum.md`).
- Konu (`topic`) C3'e kadar P56'da desteksiz; konu seçilen her istek eski motora gider.
- Görsel yok (K-E: iç testte kabul).
