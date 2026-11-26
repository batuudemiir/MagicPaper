# İki dalga için hazırlık ve sözleşme önerisi

26 Kasım2026. Bu plan runtime uygulaması değildir. Sıra: **v3 pin geçişinin tamamlanması → Dalga1 → Dalga2**. Kullanıcı 9+9 iskeleti ve 90+90 metni onayladı; burada kalan engine/app veri sözleşmesi netleştirilir. Üretim ve art kapalıdır; eski kaynak baytları değişmez.

## Ön koşulun güncel durumu

Onay dosyası artık mevcut; motor pin geçişi024b8a5ile tamamlandı (27Release/0hata). Claude uygulama worktree'sinde başka commit edilmemiş değişiklikler var; root bunlara dokunmaz. Okunan SnapshotStore henüz yalnız v1/v2 kabul ediyor ve aktif bundle v2. Uygulama v3 bundle/guard ve bayrak açık-kapalı mostProtective yazma-kaydetme-açma kanıtını vermeden Dalga1/2 runtime koduna geçilmez. Motor pininin değişmesi bu app kapısının geçtiği anlamına gelmez.

## Claude ile karşılıklı kabul için önerilen noktalar

1. Mevcut P56Request initializer ve compose imzasını koru; yeni typed history overload/adapter tercih et. Geçmiş yalnız caller'dan gelen public bookID dizisidir, oldest→newest. Child-scope app'te; engine saklamaz/loglamaz. Duplicate için son görülme sırası geçerli; bilinmeyen veya mevcut scope dışında kimlikler seçim kapsamını genişletmez.
2. Önce yaş/mod/arkadaş/yapı ve gerçek ContentSafety ile admissible havuz; sonra geçmiş dışlama. Okunmamış varsa aynı seeded tek seçim. Hepsi okunmuşsa kabul edilenler arasındaki en eski son-okunan tek kitap açılır; yasak kitap geri gelemez. Tie deterministik source sırası; boş geçmiş eski seçimle aynı.
3. V1/v2/v3 eski çağrıların davranışı korunur. Yeni 180/270 kitap paketleri ayrı versiyon/codec ve gerekiyorsa ayrı behavior kimliği taşır. Tarihsel yükleyicilerin90/9/oda kısıtını gevşetmek yok. Yeni sözleşme yorumları eski kaynağa uygulanmaz.
4. App bugün P56 composed.bookID'yi origin'de saklamıyor. Gelecek history girdisi için bookID+sourceReference'a bağlı yeni optional persistence alanı app sahibince önerilmeli; paylaşılan Story.swift için koordinasyon gerekir. Eski kimliği seed/metinden tahmin etmek yok. Exact arşiv ve tam kaynak izinden benzersiz eşleme mümkünse yalnız kanıtlı kimlik alınır; kayıp kaynakta eski sayfalar korunur.
5. N1500 on/off: her15hücrede100ilkdeneme, aynıseedmanifest, caller geçmişi yalnız başarılı çıktılardan günceller. A0:100alternating okumada aynı çocuk/mod/seed programı; kimlik tekrarı ve tam renderedtext tekrarı ayrı, fail paydada, retry0. Güvenlikli ve politikasız kollar birbirine karıştırılmaz. 180/270 toplam, policy sonrası aday sayısı garantisi değildir.

Aşağıdaki uzman planındaki initializer önerisi taslaktır; frozen mevcut imzayı değiştirmeden additive overload seçeneği önceliklidir. Mekân kimlikleri ve behavior/schema seçimi de karşı kabul edilmeden kaynak sözleşmesi sayılmaz.

---

# P56 waves contract implementation plan

Goal — After the separate v3 pin prerequisite is accepted, provide deterministic, audited 180-book then 270-book internal packages with caller-owned reading history and authentic child agency.

Why — Story quality, personalization, illustration consistency, privacy and low operating cost. No new product surface or remote generation.

Layer decision — Contracts, filtering, typed causal validation and package acceptance belong in StoryEngine/Pilots/P56. Caller supplies history through the existing bridge service; engine must not persist it. Character identity remains the existing opaque CharacterEngine reference. No UI work.

## Evidence and blockers

Inspected motor worktree `/Users/batudemir/.codex/worktrees/magicpaper-bes-arkadas-codex-motor`, AGENTS.md and PROJE_HAFIZASI P56 entries. No repo edits or test execution.

* Approved pin specification is now present at bes-arkadas-metin-v3/v3-pin-gecisi-is-tanimi.md. Batuhan approved v3 SHA855870c8462f167b4031058897c2ddfc8c5f513802ad057758c86e3ff5316c3c; root is implementing motor pin and historical v2 separation. Corrected v3 has630/630fixture and1500/1500sample success; old budget failures are closed. Application transition remains a separate Claude-owned prerequisite.
* dalga2/codex-is-tanimi.md explicitly requires separate `../v3-pin-gecisi-is-tanimi.md`, then dalga1, then dalga2. The prerequisite document has been obtained and records explicit approval. Motor readiness is not evidence that the Claude-owned bundle, SnapshotStore and simulator transition has completed; no wave implementation bypasses that delivery gate.
* `P56V3PackageLoader.swift` is frozen to schema 2, 90 books/9 structures, one `five-friends-56-voice-v3` corpus, 30 structure-companion pairs, event01/02/03, 15 cells of 6. It cannot ingest either wave directly.
* `P56PackageLoader.validateBook`, lines 93–94, requires old forest-edge room for all bedtime and legacy forest setting otherwise. New settings require a separately dispatched extended validator; relaxing historical acceptance changes old behavior.
* Wave structures use draft schema names and contain setting/obstacle/solution prose; P56Structure requires blueprintID and typed P56Beat. Wave books contain `structure`, `event:e1/e2/e3`, string pages, optional/sample/sourceBookID; runtime P56Book instead requires structureID, mode, companion/world/discovery IDs, authored bytes/hash and P56TemplatePage objects with semantics, art, lineage, typed beat and causal evidence. SourceBookID is not sufficient provenance.
* P56StructureValidator knows only U1–3/L1–3/A1–3. Its factPaths derive events from page number, requires all previous facts, and mark resolution from beat membership. That is not proof of the new mechanisms. Current source-span checks prove quotation/attribution, not that a quotation establishes an arbitrary asserted fact.
* Existing request has no recentBookIDs. Support applies mode/companion/forcedStructure and ContentSafety before composer makes one seeded draw. composeFixture currently checks the same candidates; history must not accidentally disable fixture audits.
* C3 has exactly darkness/alone/fear/weather/heights. Physical safeguards such as no climbing or animal contact need separate editorial/source-span evidence; do not invent new ContentSafety topics silently.

## Deliverable 0: prerequisite only

A separate v3-pin-transition plan/implementation/verification report must define accepted bytes, source metadata codec and bridge compatibility, exact pin movement, failed-v3 correction provenance and historical snapshot retention. No wave work before its acceptance. Keep productionEnabled=false, artApproved=false. An old book ID reused across voice versions is not global identity: exact source reference remains necessary.

## Deliverable 1: dalga1 (180 books, 18 structures, 12 per cell)

1. **Freeze inputs and publish contract decisions.** Targets: proposed `Content/Pilots/five-friends-56-wave1/` authoring manifest and `docs/research/five-friends-p56-runtime/wave1/CONTRACT.md`. Record original input file SHA256, JSON pointers for each title/page, sample approvals and editor ownership. Preserve accepted v3 source bytes and source evidence; append a distinct 90-book wave1 corpus. Acceptance: 90 old + 90 new; 60 allowed structure-companion pairs, three events each; all 15 cells have 12. No v1/v2/v3 bytes rewritten.

2. **Add caller-owned recent-book policy.** Targets: P56StoryComposer.swift, P56Support.swift; focused new P56RecentSelection.swift; bridge P56InternalService only if callers need adapter documentation. Proposed compatible initializer parameter `recentBookIDs: [String] = []`, ordered oldest → newest, scoped by caller child. Repeated IDs normalize using their latest occurrence. Ignore unknown/out-of-source/out-of-filter IDs. Establish base scope and ContentSafety first. If any admissible unread candidates exist, apply the existing mix(seed) draw to their ID-sorted list. If exhausted, choose the least-recently-read admissible candidate (oldest latest occurrence), without readmitting safety-rejected books. Update history only after an actual successful read, caller side. Empty history preserves the existing draw byte for byte; no engine persistence, retry or implicit history cap. Expose base support independently from history so audit fixtures remain inspectable. Acceptance: deterministic same source/request/history result; exhaustion cannot produce unsupported; filtered books never reenter. This exact order, duplicate and exhaustion policy is a proposed API contract requiring explicit editorial/Claude alignment, not already defined in input JSON.

3. **Add 9 typed structure contracts incrementally.** Targets: P56StructureValidator.swift additive enums and explicit new validator dispatch; proposed P56Wave1StructureContracts.swift and P56WaveCausalValidator.swift. Preserve historical sequences/factPaths and historical compiled traces. Add pageMoves exactly as supplied; new facts must name mechanism-specific conditions rather than `childSolution` for all mechanisms. Each contract defines allowed actors, dependency edges, resolution fact, evidence quote/span/source hash and semantic predicates. Child agency must be established by a child action evidence span, not page index, name in a prior page, or generic narrator approval.

| Structure | Required causal facts and checks |
|---|---|
| U4 | rain heard → child slows ordinary breathing → child voluntarily releases counting; no breath holding, sleep/health promise |
| U5 | multiple plans → child chooses one specific plan → child leaves others until morning |
| U6 | visible light inventory → child orders changes → child retains exactly one night light; extinguished/remaining states agree |
| L4 | prediction before test → distinct observed object outcomes → child compares those outcomes; trial3 cannot be fabricated as known at trial2 |
| L5 | first feature and membership → different second feature → child regroups same objects; preserve identity/count |
| L6 | comparable lengths + explicit repeated unit → friend/child differing counts → child explains unit difference → consistent-unit recheck |
| A4 | shoe-level muddy obstacle → child chooses safe materials and step spacing → constructed route → child traverses it |
| A5 | single-person viewpoint → child proposes turn order → waits → takes turn → shares access; distant nest remains untouched |
| A6 | recalled landmarks → child draws ordered map → follows first landmark → verifies map against scene → reaches goal |

Acceptance: removing prerequisite evidence, swapping child/friend ownership or inventing an absent result fails even when pageMoves remain valid. Old enum raw values and JSON decoding remain unchanged.

4. **Extend settings without aliases.** Targets: proposed wave settings manifest/extended package validator; do not modify historical setting checks. Proposed canonical IDs: `pilot56_setting_attic_room_v1`, `pilot56_setting_treehouse_room_v1`; keep `pilot56_setting_forest_edge_room_v1` for the original room. Setting names are labels, not identity. Existing named outdoor places also need a documented inventory/mapping rather than reducing every place to the forest ID. A5 has event-dependent locations, so validate per event/page rather than structure-only location. Acceptance: approved mapping table, actual room represented in art handoff, original room unchanged. IDs are proposals needing shared content/art contract alignment.

5. **Build separate extended package.** Targets: proposed `Content/Pilots/five-friends-56-runtime-wave1/build_runtime_package.py`, payload/manifest, new P56WavePackageLoader.swift, minimal explicit dispatch in P56PackageLoader.swift. Prefer schema2-compatible additive corpus layout only if all new fields fit; otherwise a separate schema3/version discriminator. Decide exact packageVersion/engineBehaviorID before publishing. Reuse digest, personalization, source binding and C3 validators; reuse old validateBook only where its old settings/causal assumptions hold, via extracted neutral checks with unchanged historical assertions. New loader accepts exactly its explicit version/counts/corpus digests/allowed pair matrix. Historical loaders retain rejection behavior. Source metadata recognition and P56SnapshotStore exact loading must be extended together if new version recognition is required.

6. **Produce source-bound reviews and verify once when plan is accepted.** Targets: new wave research source/causal/safety/art files, StoryEngineTests/P56Wave1PackageTests.swift and P56RecentSelectionTests.swift, relevant MagicPaperTests/P56SnapshotTests.swift. All 1,440 pages and 180 titles need source lineage; new corpus has 720 pages. Reuse v3 reviews only for identical original source hashes. Export per-page temporal subjects, actions, state changes, setting, causal quote, canonical character reference, runtimeArt=null and assetRuleApproval=false. Report editorial faults by book/page/quote/proposal; Claude changes prose. No text repairs in packaging.

## Deliverable 2: dalga2 (270 books, 27 structures, 18 per cell)

After wave1 acceptance, append a separate 90-book wave2 corpus. Proposed new P56Wave2StructureContracts.swift and explicit second extended package version; reuse wave-neutral loader checks. Coverage: 90 allowed pairs × 3 events = 270, 15 cells ×18, 2,160 pages. Wave1 package and all earlier bytes remain frozen. Same source/safety/art review gates and diagnostics.

| Structure | Required causal facts and checks |
|---|---|
| U7 | toy inventory → child selects storage places/order → child retains one toy; crayons event cannot be misclassified as literal sleeping living actors |
| U8 | fidgety body → child releases explicit body part → child decides sequence complete; species anatomy kept canonical, no health/sleep guarantee |
| U9 | explicitly imagined place → child chooses place/details → voluntarily fades image; imagined stream must not become physical room scenery |
| L7 | ground-observed shadows across changed orientation → child compares positions → opposite-light relation; never gaze at sun |
| L8 | unknown track sample → requested known friend print → compare dimensions/digits/direction/count → matching inference; only companion/bird origins |
| L9 | tilted stick on below-knee log → child adjusts positions/counterweights → observed balance → recheck; no climbing |
| A7 | object inaccessible → child selects reach tool → trial → changes tool based on trial → recovers without entering shrubs |
| A8 | bulky load → child partitions → matches parts to canonical friend anatomy → shares carrying → arrival; no heavy-load inference |
| A9 | creature destination/obstacle → child chooses material → builds route → waits → creature crosses itself; no contact or forced movement |

Wave2 pageMoves `noticed`, `trial_1`, `result`, `return`, `closing` are generic labels and must not map directly to generic fact establishment. Contract is keyed by structure and event with mechanism-specific fact requirements. `first_piece` is reused in A8 but cannot inherit the A2 placement semantics.

New proposed IDs: `pilot56_setting_stream_edge_v1` (L8 physical scene), `pilot56_setting_fern_edge_v1` (A7 physical scene). U9 imagined stream is a subject/location reference with imagined presence, not automatic physical stream setting. Attic/treehouse retain wave1 identities.

## Meaningful verification gates

* Historical regression: exact payload bytes/digests; historical loaders still accept/reject same cases; same empty-history requests produce same book/text/transitions/source references for v1/v2/v3. Round-trip old snapshots and explicit old refs; corrupt/missing exact source never falls back to current package.
* Every authored book forced through real TextMetrics for ages5/6 and İrem/Çağrı/Öykü/Ege/Ali/Gül/Deniz, all8pages:18–38 words, ≤14 sentence words. Do not infer from Python lint. Validate calm ending and all typed causal/safety/source gates. Report source failure separately from diagnostic-only decoding.
* Selection tests: absent/empty history, all unread, one unseen, all exhausted, duplicates, unknown IDs, mixed cells, nil mode/companion, forced structure, safety-restricted pool, all safety rejected; no extra draw/retry; oldest recent candidate wins only within admissible scope.
* N1500: equal reproducible 100 seeds ×15cells for v3/wave1/wave2; report loader success, composition failures by kind, retries, unique IDs/full-text digests, per-cell coverage and first exact recurrence. Run history off/on with fixed protocol and same schedule; state ages/names/seeds/history order/cap explicitly. Do not use aggregate uniqueness as child-visible novelty.
* 100 alternating readings per synthetic child: publish exact alternating mode/companion schedule; append only successfully read IDs; compare off/on using same seeds and schedule, in addition to 100 consecutive readings of each cell. Report recurrence distance in cell visits and global reads, exact book/text repeats versus mechanism/event repeats. With unlimited scoped history, each cell must enumerate its 12/18 admissible books before repeating, then least recent returns; do not promise zero repeats over100 when inventory is finite.
* Mutation tests retain valid page order but replace resolution quote with neutral sentence, swap actor, omit required observation/tool change, change remembered/imagined object to present, alter source/hash, substitute stale C3 review or cross-corpus evidence. Each must fail for the relevant reason.

Risks — Shared validator/composer/loader/source metadata edits can affect historical behavior; isolate dispatch and preserve fixture snapshots. Authoring claims and approved examples do not equal runtime validation. Broad history changes behavior when explicitly supplied; new behavior identity/version needs a contract decision if exact source replay is intended to include selection behavior. Canonical setting and anatomy disagreements require content/art owners. Physical safety beyond five C3 topics stays explicit editorial evidence. No production activation implied.

Dependencies — Exact accepted v3 source, approved pin specification and completed application transition, 30 wave input JSON files and structure contracts, existing P56 safety vocabulary, metadata codec, snapshot store, source digests, authored event mapping e1→event01/e2→event02/e3→event03, frozen companion identities. No engine history persistence or new migration for existing story JSON; new persisted composed traces/settings/source versions require additive codec recognition and old-fixture round-trip tests. Do not reinterpret old snapshots.

Cost note — Entirely local, deterministic. No AI/network calls. Authoring reviews are offline release artifacts. Existing derived packages can be cached by exact payload hash.



Scope/conflicts — This planning agent owns only `/private/tmp/p56-waves-contract-plan.md`; no code/tests/commits. Builder must coordinate shared P56StructureValidator, P56StoryComposer, P56Support, loader dispatch, SourceMetadata and changelog with current owners. Repository completion requires changelog entry, but none added by this read-only task.
