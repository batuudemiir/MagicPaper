# MagicPaper Kids — Story System V2 Master Plan

**Status:** plan only. No implementation code was written or changed for this document.
**Date:** 2026-09-15

This consolidates and **verifies** the five audit documents already in the repo
(`ARCHITECTURE_AUDIT.md`, `CONTENT_AUDIT.md`, `STORY_ENGINE_AUDIT.md`,
`STORY_CREATION_UX_SPEC.md`, `CONTENT_SCHEMA_V2.md`) and adds what they left
open. Those documents are good and are **not** superseded — read them for detail.
This one records what I re-verified, what I corrected, the architecture decision
they stopped short of making, and the execution plan.

---

## 0. Corrections to the existing audits

Three claims in the prior documents are wrong or incomplete. They matter.

| Prior claim | Verified reality |
|---|---|
| `ARCHITECTURE_AUDIT.md`: "`swift test` currently fails due to a resource-bundle code-signing error … This must be repaired" | **Not a code defect.** The package is healthy: **413 tests, 0 failures** across all four targets. The failure only occurs when building into `.build` *inside* `~/Desktop`, which carries `com.apple.macl` / `com.apple.provenance` xattrs that break `codesign` on the `.xctest` bundle. Fix is one command: `xattr -cr StoryEngine`, or build with `--scratch-path` outside Desktop. Nothing to repair in the engine. |
| My own first inference this session: "resource lookup must fail because the pbxproj uses `PBXGroup`, so the subdirectory lookup returns nil" | **Half right, and the half that matters is wrong.** The subdirectory lookup does fail, but `Bundle.allBundles` *includes* `Bundle.main`, so the loader's second, flat lookup (`StoryGenerationManager.swift:1239`) finds the flattened resource. The catalog almost certainly **does** load. I withdrew this as a root cause. |
| `STORY_ENGINE_AUDIT.md` implies the reported `noBlueprintsFound` may still be reachable | It is **not**. `noBlueprintsFound` is declared at `StoryGenerationManager.swift:1216` and **thrown nowhere in the app target**. Full RCA in §6. |

**Unverified, and I am flagging it rather than asserting it:** I could not complete an
app build to inspect the real `.app` bundle layout — `xcodebuild` stalled ~10 minutes
fetching `swift-protobuf` and `interop-ios-for-google-sdks` and I killed it. Network
to SPM appears blocked in this environment. The bundle-flattening claim below is a
**high-confidence inference** from `project.pbxproj` (`isa = PBXGroup`, not a folder
reference) plus well-established Xcode behaviour — not an observed result. It should
be confirmed by the first test written in Phase 1.

---

## 1. Current architecture summary

Three story systems coexist. Only one reaches a user.

| # | System | Location | Status |
|---|---|---|---|
| 1 | **Legacy cloud path** | `StoryGenerationManager.createCustomStory` → Firebase upload → Gemini (`AIService`) → fal.ai per page | **Live.** The "Görselli masal" button. |
| 2 | **Embedded offline prototype** | `TestOfflineTemplateStoryProvider`, inline at `StoryGenerationManager.swift:1167-1400` | **Live but broken UX.** The "Metin masalı oluştur" button. |
| 3 | **StoryEngine SwiftPM package** | `MagicPaper/StoryEngine/` — 4 targets, 97 source files, 413 passing tests | **Completely unwired.** Not referenced by `MagicPaper.xcodeproj` at all. |

**The app compiles 59 of 72 Swift files.** 13 are on disk but absent from the
Sources build phase — including all 7 `StoryEngineBridge/*.swift` files, which
`import StoryEngine` and therefore *could not* compile even if added, because the
local package is not a project dependency (`grep -c "XCLocalSwiftPackageReference"
project.pbxproj` → **0**).

Only `DesignSystem/`, `Screens/`, `Helpers/` are synchronized folder groups.
`Views/`, `Services/`, `Models/`, `StoryEngineBridge/` require explicit membership —
which is why files can sit on disk looking alive and never build.

Navigation is a hand-rolled router (`MPAppState`) with five `.fullScreenCover`s on
`ContentView`. There is **no `NavigationStack` anywhere**. Sheets are drawn as an
overlay layer, not `.sheet` (`ContentView.swift:89-110`), deliberately.

---

## 2. Existing Story Engine summary

The package is genuinely good and is the right foundation — but it is shaped for
**LLM generation**, which is not what MVP needs.

`StoryOrchestrator` runs 13 stages, of which `planStory`, `draftNarrative`,
`refinePages`, `generateImages` and half of `validate` all call a provider over the
network. Its machinery — job checkpointing, resume, retry/backoff, budget
reservation, concurrency limiting, idempotency keys, provenance — exists because
those calls are **slow, billable and failure-prone**.

Offline template generation is none of those things. It is a local, deterministic
function that completes in milliseconds. Running it through `StoryOrchestrator`
would add twelve job stages of pure overhead and a resumable-job record for work
that cannot fail halfway.

**What offline should reuse from the package (substantial):**

- Domain: `Story`, `StoryPage`, `StoryScene`, `StoryCharacter`, `StoryValidationResult`
- `StoryValidator` + `StructuralValidator`, `RepetitionValidator`, `AgeAppropriatenessValidator`
- `ChildSafetyPolicy` + `ChildSafetyGate` (§32 is already built)
- `StableHash` → story fingerprints (§18 is already built)
- `GenerationProvenance`
- `FileStoryRepository` / `StoryDataLifecycle` (durable, atomic, per-record)
- `CharacterEngine` entirely — versioned child identity
- `VisualSystem` — for later visual metadata only

**What offline needs that does not exist:** the catalog, compatibility, scoring,
narrative state, variant selection, novelty, and title composition.

---

## 3. Current resource summary

| Thing | Reality |
|---|---|
| v1 offline blueprints | 12 files, `StoryEngine/.../templates/offline/`. Text baked into the blueprint. **288 Turkish variants** — genuinely good prose. |
| v1 page roles | **33 distinct role names across 12 files.** Only `hook` is universal. No shared vocabulary. |
| v1 `safetyMetadata` | **12 mutually incompatible shapes.** `containsViolence` / `hasViolence` / `violence`; `contentRating` is `"safe"` in 5 files and `"G"` in 2. |
| v2 catalog | 1 file. 12 blueprints, 16 settings, 15 companions, 20 objects, 20 events, 15 challenges, 10 endings, 52 templates (156 variants). |
| v2 blueprints | **All 12 are `adventure/courage/5-6/8p`.** Genre diversity collapsed 5 → 1 vs v1. |
| v2 safety metadata | **Zero.** Regression from v1. |
| v2 `resolutions` | **Empty array** while every other collection is populated. |
| v2 `visualScene` | **147 of 156 are filler** — literally `"{{child.name}} hook sahnesi."` |
| v2 text quality | Heavy duplication — one sentence appears **8×**, another 6×, another 6×. |
| Referential integrity | **Broken.** 7 orphan setting tags referenced by companions (`ocean`, `city`, `house`, `night`, `park`, `pond`, `rain`). `companion_dolphin_001` wants `ocean`; no setting is tagged `ocean`. |
| Theme vocabulary | **Broken.** `calm`, `good_night`, `trying_again`, `helping_others` have components but **no templates**. |
| Unreachable content | 10 templates (`celebration`, `bedtime_transition`) — no blueprint declares those roles. |
| Duplication | `shared_content_library_v2.json` is **byte-identical in two places** (sha256 `0d5f510c…`), no sync mechanism. |
| `templates/adventure_01.json` | **0 bytes**, and it is a member of the Resources build phase. |
| Placeholders | 8 distinct tokens. `{{child.pronoun}}` / `{{child.possessive}}` appear only in v1 — the exact English-centric construction §21 forbids. |

**Net:** v1 has the good prose and bad structure. v2 has the good structure and bad
prose. Neither is shippable as-is. See §9.

---

## 4. Current UX summary

The wizard is **four** technical steps, not three creative ones:
`MPStepDots(total: 4, labels: ["Kim", "Tür", "Konu", "Dünya"])` — `StoryWizardView.swift:219`.

Step 1 exposes 7 genre tiles, step 2 exposes 6 "direction" tiles, step 3 exposes 7
world chips **plus** 6 companion chips on the same screen. That is the
"choose 10 settings and 8 story parameters" feel §50 explicitly rejects.

**What already exists and should be reused rather than rebuilt:**

- `MPChoiceTile` (`MPSurfaces.swift:197`) — *is* the choice card. `.row` and `.column`
  layouts, built-in selected check-mark and lock badge. Documented as
  "Sihirbazın cevap kontrolü — tek dokunuş, tek cevap."
- `MPStepDots` (`MPNavigation.swift:131`) — retarget `total: 4` → `3`.
- `MPCard`, `MPPressableCard`, `MPButton`, `MPChip`, `MPBadge`, `MPEmptyState`,
  `MPAvatar`, `MPSectionHeader`, `MPProgressRing`, `MPToast`.
- Full token system: `MP.C` semantic colours, `MP.F` (Baloo 2 / Nunito),
  `MP.S` spacing, `MP.R` radii, `MP.E` hard-edge depth, `MP.M` motion with
  `MP.M.gated()` already honouring Reduce Motion.

**What is missing:** a reusable grid. `LazyVGrid` appears exactly once in the app.
The wizard's `MPWrapRow` / `MPFlowLayout` are trapped inside
`StoryWizardView.swift:562-632` and should be promoted to `DesignSystem/`.

**The visual language needs no redesign.** §4 is already satisfied by the existing
system. V2 is a *flow* change, not a *look* change.

---

## 5. Known bugs

| # | Bug | Evidence | Severity |
|---|---|---|---|
| B1 | **Text stories never open the reader.** `createOfflineTextStory` sets `pendingStoryID` then calls `dismiss()` directly; `StoryGeneratingView.onFinished` never fires. | `StoryWizardView.swift:545-549` | **High** — the feature visibly does nothing |
| B2 | **Generation failure is silent.** On error it `print`s and sets `isGenerating = false`, leaving a dead wizard with no message. This is the source of the `"Offline story generation failed:"` line reported. | `StoryWizardView.swift:551-555` | **High** |
| B3 | **Place and companion choices are ignored.** Every non-surprise world maps to `"setting_forest_001"`, every non-surprise companion to `"companion_fox_001"`. | `StoryWizardView.swift:532-533` | **High** — violates DoD §47 |
| B4 | **Genre/theme matching compares Turkish UI labels to English content keys** — `"Macera"` vs `"adventure"`. Always falls through to "all blueprints". | `StoryWizardView.swift:530` vs catalog | **High** |
| B5 | **Determinism is fake.** `seed: UInt64.random(in:)` at the call site; page/story IDs are fresh `UUID()`. §37's contract cannot hold. | `StoryGenerationManager.swift:1358` | **High** |
| B6 | **Hard-coded developer absolute path** as resource fallback. Cannot exist on a device. | `StoryGenerationManager.swift:1247` | **High** |
| B7 | **Force-unwrapped `randomElement()!`** — traps instead of erroring if the pool is empty. | `StoryGenerationManager.swift:1286` | Medium |
| B8 | **Every filter falls back to the unfiltered pool** when empty — the exact antipattern §14/§23 forbids. Incompatible combinations are produced silently. | `StoryGenerationManager.swift:1274-1284` | **High** |
| B9 | `theme: .jungle` hard-coded into every offline `Story` regardless of actual content. | `StoryGenerationManager.swift:1334` | Medium |
| B10 | Title is hard-coded `"\(childName) ve \(companion.name)"`. §31 title patterns unused. | `StoryGenerationManager.swift:1313` | Medium |
| B11 | `preset.world` from Home world tiles is silently dropped. | `StoryWizardView.swift:187-191` | Medium |
| B12 | `MPStoryLength` / `MPStoryTone` fully specified but dead; `.orta` / `.neseli` hard-coded. | `StoryWizardView.swift:504-505` | Low |
| B13 | **Three Fal.ai services share one hard-coded API key in source**, committed to git. | `FalAIImageGenerator.swift:14`, `FalImageService.swift:10`, `FalImageGenerator.swift:8` | **Security** |
| B14 | 0-byte `adventure_01.json` shipped as a build resource. | pbxproj `2D025C83…` | Low |
| B15 | Dead code: `TextOnlyStory` (referenced by nothing), `HomeView_OLD_BACKUP.swift` (duplicate `HomeView` symbol), `patch.swift`, `FalImageGenerator`, orphaned `TextStory` subsystem, stray Xcode archive folder inside `Views/`. | §6 of UX audit | Low |

The console noise reported in §23 (UserDefaults story loading, RevenueCat
transaction metadata, sheet presentation warnings) is benign and unrelated to
generation. B1/B2 are what a user actually experiences.

---

## 6. Root cause analysis — `noBlueprintsFound`

**Conclusion: the reported error cannot be produced by the current app, and the
real latent failure is a different one.**

Method — I traced every path rather than assuming:

1. **Where is it thrown?** `grep -rn "noBlueprintsFound" MagicPaper/` returns exactly
   two hits: the enum case (`:1216`) and its `errorDescription` (`:1223`).
   **It is thrown nowhere in the app target.**
2. **Where *is* it thrown?** In four loose scratch files at the repo root —
   `run_test_now.swift:161,166,208`, `update_engine.swift:161`, `test_runner.swift:246`,
   `local_test.swift`. These are standalone scripts with their own loaders and
   *strict* filtering, not in any build target.
3. **Could the app throw it via an older build?** Possibly, but irrelevant to the
   fix: the current code path cannot reach it.
4. **What would the current code actually do if the catalog were missing?**
   Throw `missingSharedLibrary` ("shared_content_library_v2.json bulunamadı").
5. **What if the catalog loaded but were empty?** `candidates` stays empty through
   every "fall back to previous pool" branch, and `unreadCandidates.randomElement()!`
   **traps** — a crash, not an error.
6. **Does the catalog load?** Almost certainly yes. The pbxproj uses `isa = PBXGroup`
   for `templates/offline/v2`, so Xcode flattens the resource to the bundle root; the
   nested lookup at `:1234` fails, but the **flat fallback at `:1239` succeeds**
   because `Bundle.allBundles` contains `Bundle.main`. *(Inference — see §0.)*

**So the error the user saw came from running one of the root-level scratch scripts,
not from the app.** What the app *does* do is worse in a quieter way: because every
filter falls back (B8) and the UI labels never match the content keys (B4), the
"offline story" is a random blueprint with a random setting and a random companion
that ignore all three of the user's choices — and then it never opens (B1) and says
nothing (B2).

**The fix is not to make `noBlueprintsFound` throwable.** It is:
- typed, structured `CatalogDiagnostics` recording discovery → decode → each filter's
  count *and rejection reason* → final candidate count;
- an explicit `noCompatibleContent(diagnostics:)` error instead of silent fallback;
- deleting the dev-path fallback and proving bundle discovery with a test;
- removing the root-level scratch scripts so they cannot mislead again.

---

## 7. Proposed V2 architecture

**Decision: add an offline provider as a peer inside the existing package. Do not
route offline generation through `StoryOrchestrator`, and do not build a second engine.**

```
                      StoryIntent  (product-level: profile, place, companion, discovery, seed)
                            │
                  ┌─────────┴─────────┐
                  │  StoryProvider    │   ← NEW protocol (generation strategy)
                  └─────────┬─────────┘
          ┌─────────────────┼──────────────────┐
          ▼                 ▼                  ▼
 OfflineTemplate      CloudAIStory       OnDeviceAIStory
   StoryProvider        Provider           Provider
   (MVP, local)      (wraps existing      (future)
                     StoryOrchestrator)
          │                 │                  │
          └─────────────────┴──────────────────┘
                            ▼
        SHARED: Story · StoryValidator · ChildSafetyGate ·
        StableHash fingerprint · GenerationProvenance ·
        FileStoryRepository · StoryDataLifecycle · CharacterEngine
```

`StoryAIProvider` (existing) is a **model** port — text in, text out.
`StoryProvider` (new) is a **strategy** port — intent in, story out. They sit at
different levels and both are needed. This is exactly the shape §7 asks for.

**Why not run offline through the orchestrator:** it has no billable calls (no
budget), no network (no retry/backoff), and completes in milliseconds (no
checkpoint/resume). Twelve job stages would be overhead with no benefit. This is
the §46 "do not over-engineer" line, drawn deliberately.

Offline pipeline (§15), all deterministic, all in-package:

```
StoryIntent
 → validate intent + child safety input gate
 → load catalog (cached, validated at load)
 → resolve surprise selections (seeded)
 → compatibility intersection → candidate pool  [typed empty error, never fallback]
 → score blueprints (compatibility + affinity + novelty + seeded tiebreak)
 → select blueprint
 → resolve components (setting, companion, discovery, event, challenge, ending)
 → initialise NarrativeState
 → per page: filter variants by role + state + compatibility → select → apply transitions
 → personalise (name, Turkish suffixes)
 → compose title from blueprint titlePatterns
 → validate: placeholders, roles, state reachability, age, safety, repetition
 → fingerprint (StableHash over composition)
 → persist StoryComposition + Story
```

---

## 8. Proposed blueprint model

A blueprint is a **narrative skeleton with constraints**, never a story (§9).

```swift
struct Blueprint {
    let id: ContentID
    let catalogVersion: String
    let worldKeys: [String]          // opaque; engine never switches on them
    let themeKeys: [String]
    let ageRange: AgeBand
    let pageCount: Int               // 8 for MVP
    let pagePlan: [PageSlot]
    let requirements: ContentRequirements   // which component kinds must resolve
    let compatibility: CompatibilityRules   // tag intersections, not free text
    let titlePatterns: [TitlePattern]       // §31
    let safety: SafetyMetadata              // ONE shape, unlike v1's twelve
    let novelty: NoveltyWeights
}

struct PageSlot {
    let pageNumber: Int
    let role: PageRole
    let requiredState: [StateCondition]
    let stateChanges: [StateChange]
    let allowedTemplateTags: [String]
    let visualIntent: String?        // metadata only; text never depends on it
}
```

`PageRole` is a **closed enum**, standardising on the eight the brief names and
that the five best v1 files and all twelve v2 blueprints already use:

`hook · discovery · companion · problem · attempt · challenge · resolution · emotionalEnding`

The other 25 v1 role names collapse into these. Nothing new to invent.

**Narrative state (§12)** stays deliberately small — a typed bag, not a state machine:

```swift
struct NarrativeState {
    var locationID, companionID, discoveryID: ContentID?
    var problemDetected, attemptMade, challengeResolved, returnedHome: Bool
    var companionMood: CompanionMood   // .afraid / .calm / .brave
}
```

Enough for coherence, nothing more. A variant declares what it requires and what
it changes; the selector only offers variants whose requirements the current state
satisfies. That single rule is what stops page 7 resolving a challenge page 6
never raised.

---

## 9. Proposed content model

One versioned, **package-owned** catalog. The app never reads it directly.

```
ContentCatalog (schemaVersion, catalogVersion, locale)
├── blueprints[]
├── settings[]      ← user-facing "place"
├── companions[]    ← user-facing "companion"
├── discoveries[]   ← user-facing "secret"; binds object and/or event internally
├── events[]        ← engine-selected
├── challenges[]    ← engine-selected
├── endings[]       ← engine-selected
└── templates[]     ← role-scoped variant pools
```

Every record carries `id`, localized display, `ageRange`, `tags`, `compatibility`,
`safety`, `novelty`. **Cross-references are IDs validated at load** — the current
orphan-tag problem (companions wanting a setting tagged `ocean` that does not exist)
becomes a load-time error, not a silent random substitution.

**Content strategy — this is the part that decides whether V2 feels good:**

v1 has the prose (288 real Turkish variants with sensory texture). v2 has the
structure (decoupled, reusable, tagged). The plan is to **keep v2's schema and
harvest v1's writing into it** — not to pick one and delete the other:

1. Keep both source files. Delete nothing (§22).
2. Promote the five `adventure_courage_*` files — they already use the correct
   eight roles, already have Turkish `visualScene`, and already populate
   `stateRequirements`/`stateChanges` in two of them.
3. De-couple their prose: strip hard-coded species ("yavru ejderha", "baykuş",
   "ahtapot") and re-slot to `{{companion.name}}` / `{{companion.type}}`. The
   audit found these hardcoded *in the same sentence* as the slot that was
   supposed to parameterise them.
4. Replace the 147 filler `visualScene` fields; they are metadata-only for MVP but
   must not ship as `"{{child.name}} hook sahnesi."`
5. Eliminate the 8×/6×/6× duplicated v2 sentences.
6. Drop `{{child.pronoun}}` / `{{child.possessive}}` entirely (§21).
7. One `SafetyMetadata` shape, applied to every record.

**Phase-1 target (§39):** one world — Adventure / Courage-Discovery, age 5-6, 8
pages. 10-15 *structurally distinct* blueprints, 15+ settings, 15+ companions,
20+ objects, 15+ challenges, 10+ endings. Quality-gated, not count-gated (§42).

**Combinatorics (§40):** the QA report must state theoretical, compatible, and
*non-duplicate* combinations separately. No "millions of stories" claim.

---

## 10. Proposed story creation UX

`STORY_CREATION_UX_SPEC.md` is already right and I am adopting it. Recommendation
on the §26 question: **Flow C wording on Flow A structure.**

```
Home → "Yeni Bir Masal"
  → (child picker only if >1 profile)
  → 1. "Nereye gidelim?"        4 places    + Bana sürpriz yap
  → 2. "Yanımızda kim olsun?"   4 companions + Bana sürpriz yap
  → 3. "Bugün neyi keşfedelim?" 4 secrets   + Bana sürpriz yap
  → "Sayfaları sihirle hazırlıyoruz…"
  → Cover reveal → Reader
```

Flow C's child-led phrasing costs nothing over Flow A and is the one that can
become a parent-child ritual (§27). Structurally identical, so this is a copy
decision, not an architecture decision.

Reuse `MPChoiceTile` in `.column` layout, `MPStepDots(total: 3)`, existing tokens.
Promote `MPWrapRow`/`MPFlowLayout` out of `StoryWizardView.swift` into
`DesignSystem/`. No new visual language.

---

## 11. Data flow

```
SwiftUI (StoryCreationDraft — opaque ContentIDs, never Turkish labels)
   │  no engine vocabulary crosses this line
   ▼
StoryIntent { childProfileID, ageYears, locale, placeID?, companionID?,
              discoveryID?, seed, catalogVersion }        ← persisted
   ▼
OfflineTemplateStoryProvider  (in package, deterministic, offline)
   ▼
StoryComposition { blueprintID, componentIDs, variantIDs, seed, fingerprint }
   ▼
Story (+ GenerationProvenance)  → FileStoryRepository (Documents/StoryEngine)
   ▼
StoryEngineMapper → MagicPaper.Story  → existing Reader / Library  (unchanged)
```

The UI submits IDs and receives display-ready cards. It never sees a blueprint,
role, state or compatibility rule.

---

## 12. Agent work breakdown

Phase A (audit) is **done** — this document plus the five existing ones.

Implementation agents run **sequentially** where they touch the engine, and may
overlap only where file ownership is disjoint. No two agents edit the same file.

| Agent | Owns (exclusive) | Depends on |
|---|---|---|
| **I1 — Build wiring** | `MagicPaper.xcodeproj`, `StoryEngine/Package.swift` | — |
| **I2 — Catalog schema + loader** | `StoryEngine/Sources/StoryEngine/Content/**` (new dir), catalog JSON | I1 |
| **I3 — Selection engine** | `.../Offline/{Compatibility,Scorer,NarrativeState,VariantSelector}.swift` | I2 |
| **I4 — Assembly + Turkish** | `.../Offline/{Personalizer,TitleComposer}.swift`, `TurkishSuffixResolver.swift` | I3 |
| **I5 — Validation + novelty** | `.../Offline/{OfflineValidators,NoveltyStore,Fingerprint}.swift` | I3 |
| **I6 — Bridge + persistence** | `MagicPaper/StoryEngineBridge/**` | I1, I4, I5 |
| **I7 — UI** | `Screens/StoryCreation*/**`, `DesignSystem/MPFlowLayout.swift` | I6 |
| **I8 — Content authoring** | catalog JSON only | I2 |
| **I9 — Cleanup** | dead files, root scripts, key rotation | last |

I3/I4/I5 all sit under `.../Offline/` — they must run **in sequence**, not in
parallel, despite disjoint filenames, because they share the provider's seam.

---

## 13. File-by-file change plan

| # | Change | Files | Risk |
|---|---|---|---|
| 1 | Add local package + bridge to the Xcode target; add a unit-test target (there is none). | `MagicPaper.xcodeproj/project.pbxproj` | **High** — pbxproj edits; do in Xcode UI, verify build before proceeding |
| 2 | Prove resource discovery from a real app bundle. Delete the dev-path fallback. | new `CatalogBundleTests.swift` | Low |
| 3 | Make `templates/offline/v2` a **folder reference**, or move the catalog into the package and delete the app duplicate. One source of truth. | pbxproj, resource dirs | Medium |
| 4 | Catalog domain + strict decoder + `CatalogDiagnostics` + reference-integrity validation at load. | `StoryEngine/.../Content/*` (new) | Medium |
| 5 | `StoryProvider` protocol + `StoryIntent`. | `StoryEngine/.../Providers/StoryProvider.swift` (new) | Low |
| 6 | `OfflineTemplateStoryProvider` + compatibility + scoring + state + variants. Typed empty errors; **no fallback-to-unfiltered**; no force unwraps. | `StoryEngine/.../Offline/*` (new) | **High** |
| 7 | Extract `TurkishSuffixResolver` from `StoryGenerationManager.swift:1379+` into the package **unchanged**, with tests. It is real, working Turkish work. | move + `TurkishSuffixTests.swift` | Low |
| 8 | Title composition from `titlePatterns`; Turkish apostrophe correctness. | `TitleComposer.swift` (new) | Medium |
| 9 | Fingerprint + per-profile `NoveltyStore` with documented cooldown weights (§17 — no undocumented magic numbers). | `Fingerprint.swift`, `NoveltyStore.swift` (new) | Medium |
| 10 | Bridge: wire container, map `StoryIntent` → provider → `MagicPaper.Story`. Fix B1/B2. | `StoryEngineBridge/*`, `StoryWizardView.swift` | **High** |
| 11 | Replace 4-step wizard with 3-choice flow; preparation screen; cover reveal. | new `Screens/StoryCreation/*`, retire wizard steps 1-3 | Medium |
| 12 | Retire `TestOfflineTemplateStoryProvider` **only after** 10-11 ship green. | `StoryGenerationManager.swift` (delete lines 1167-1400) | Medium |
| 13 | Content authoring pass per §9. | catalog JSON | Medium |
| 14 | Cleanup: delete root scratch scripts, `patch.swift`, `HomeView_OLD_BACKUP.swift`, `TextOnlyStory.swift`, 0-byte `adventure_01.json`, stray archive folder. **Rotate the fal.ai key** (B13). | various | Low (key rotation: urgent) |

**Explicitly preserved, not touched:** the legacy cloud illustrated path, the
Reader, the Library, `UserProfile`, subscription/paywall, daily stories, the design
system tokens.

---

## 14. Migration strategy

**Dual-read, no destructive migration.**

1. Legacy `UserDefaults["stories"]` stays readable. Never bulk-delete. Note the
   existing `migrateOldStoriesIfNeeded()` *already deletes the whole key above 4 MB*
   (`StoryGenerationManager.swift:910`) — that behaviour should be removed as part
   of this work; it is data loss.
2. New offline stories are canonical as engine records under `Documents/StoryEngine/`,
   mapped into `MagicPaper.Story` for the Reader through `StoryEngineMapper`.
3. Library shows both, sorted by date. Library filtering currently keys on **child
   name**, which breaks on rename/collision — switch to profile ID.
4. Import legacy records only later, explicitly, with backup.
5. Remove the app's duplicate catalog only after bundle tests pass in CI.

---

## 15. Testing strategy

There is **no test target in the app today**. One must be created (change #1).

**Package tests (extend the existing 413):**

- Resource discovery from a real bundle; decode; version; reference integrity
- Catalog diagnostics counts at every filter stage
- Compatibility: intersection correctness, and that an empty pool raises a **typed
  error with reasons** rather than falling back
- Blueprint scoring: affinity, novelty penalty, cooldown, seeded tiebreak
- **Determinism contract:** same intent + same seed → identical story *and identical
  fingerprint*; different seed → different valid story
- All 8 roles present, in order; narrative state reachable and resolved
- Placeholder resolution → zero unresolved; **no `{{child.pronoun}}` anywhere**
- Turkish: suffix correctness across vowel classes, apostrophes in titles
- Safety metadata present on every record; unsafe content blocked
- Novelty: immediate duplicate fingerprint rejected
- Persistence: save → relaunch → reopen without regeneration
- Golden fixtures for the deterministic chain (the package already has this pattern)

**App tests (new target):** three-choice flow reaches generation; each of the three
choices provably appears in the saved story (kills B3); Surprise at each stage;
multiple profiles; offline with no network; cover → reader; failure shows a
family-readable message (kills B2).

**Regression contract (§38):** child 5-6 + adventure/courage + 8 pages + seed 12345
→ resources discovered, catalog decoded, ≥1 candidate, exactly 1 blueprint selected,
8 ordered roles, 0 unresolved placeholders, validation PASS, fingerprint stable,
persist + reopen PASS.

---

## 16. Risk register

| Risk | Likelihood | Control |
|---|---|---|
| pbxproj edit breaks the project | Medium | Do it in Xcode UI, not by hand; commit before and verify build immediately |
| SPM deps unreachable (as seen this session) | Medium | Vendor/cache deps; CI must not depend on live checkout |
| Offline provider becomes a second engine | Medium | Enforce shared domain/validation/persistence; review that nothing is duplicated |
| Content quality is the real bottleneck | **High** | Phase 1 is content-bound, not code-bound. Budget editorial time; native Turkish review is non-negotiable |
| Rewriting v1 content loses its good prose | Medium | Harvest, don't regenerate. Keep originals for audit |
| Determinism quietly breaks (fresh `UUID()`s) | High | Inject an ID generator; golden fixtures catch drift |
| Scope creep beyond MVP | **High** | §20 freeze list is explicit. One world, one age band, 8 pages, text only |
| fal.ai key in git history | **Certain** | Rotate now; move to `Secrets.xcconfig`; assume compromised |
| Photo policy conflict (see below) | — | **Needs a product decision before the visual phase** |

---

## 17. Definition of done

**Product (§47):** a parent picks a saved child, taps "Yeni bir masal", makes three
choices (or Surprise), and gets a coherent 8-page Turkish story that visibly
contains all three choices, has a natural title, opens from a cover, reopens after
relaunch, requires no network, and never shows a technical term.

**Technical (§48):** resources discoverable and strictly decoded with diagnostics;
no silent zero-result filtering; no generation logic in views; no hardcoded story
text in Swift; no absolute paths; engine unit-testable without UI; persisted stories
reopen without regeneration; failures are family-readable.

**Content (§49):** one production-quality world demonstrating reusable blueprints,
components, compatibility, roles, variants, state, personalization, safety,
native Turkish, and novelty — with honest combinatorics.

---

## Open decisions — I need your call on these

**D1 — Child photo. This is a direct conflict between your brief and the shipped app.**

Your §1 says *"A parent creates a child profile and uploads the child's photo"* and
§8 says *"Do NOT ask the user to upload the photo again."* But the app deliberately
removed photos and **promises users it does not store them**, in visible UI copy:

> `ProfileCreationView.swift:127` — *"MagicPaper çocuk fotoğrafı istemez ve saklamaz
> — sadece bir isim ve avatar rengi."*

`UserProfile.imageFileName` still exists and `ProfileManager` can save one, but
`createProfile` is called without an image (`ProfileCreationView.swift:136`). The
illustrated path currently renders a **letter avatar** instead of a photo. Given
Kids Category / COPPA positioning this looks like a deliberate compliance choice,
not an oversight — so I will not quietly reverse it.

MVP is text-only, so this does not block Phase 1. It must be decided before the
visual layer.

**D2 — Content base.** My recommendation is v2 schema + harvested v1 prose (§9).
The alternative is authoring fresh content against the new schema and keeping both
existing sets read-only. The first is faster and preserves real Turkish writing;
the second gives a cleaner corpus but costs more editorial time.

**D3 — Sequencing reality.** Change #1 (Xcode wiring) is the highest-risk item and
everything depends on it. I would rather do that one change alone, verify the app
still builds and runs, and stop — before any engine work starts.
