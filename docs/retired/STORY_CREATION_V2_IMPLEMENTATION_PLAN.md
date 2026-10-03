# Story Creation V2 — Implementation Plan

**Date:** 2026-09-15
**Status:** Plan only. No implementation code written.
**Scope:** replace the four-step wizard with Story Idea → Companion → Story.
**Method:** every claim below is cited to a file and line, and was read rather than inferred.

---

## 1. The current flow, as it actually is

`Screens/StoryWizardView.swift` (655 lines) presented full-screen from
`ContentView.swift:43`, driven by `MPAppState.showWizard`.

Four steps, `MPStepDots(total: 4, labels: ["Kim", "Tür", "Konu", "Dünya"])`
(`StoryWizardView.swift:218`):

| Step | Asks | State |
|---|---|---|
| 0 | Which child | `childID: UUID?` |
| 1 | Story type — 7 options, `V1StoryType` | `storyType` |
| 2 | Direction — 6 options, `V1StoryDirection` | `storyDirection` |
| 3 | World (7) **and** companion (6) on one screen | `storyWorld`, `storyCompanion` |

Then a **fifth implicit decision** in the footer: two buttons, *"Görselli masal"*
and *"Metin masalı oluştur"* (`StoryWizardView.swift:441-462`).

So the real count is six decisions, not four.

### 1.1 The six bugs, located

Five of the seven bugs in §30 of the brief are visible in this file. They are not
inferred — these are the lines.

**B3 — place and companion choices are ignored.** `StoryWizardView.swift:531-532`:

```swift
let settingId = (storyWorld == .surpriz) ? nil : "setting_forest_001" // simplistic mapping for V1
let companionId = (storyCompanion == .surpriz) ? nil : "companion_fox_001"
```

Every non-surprise choice collapses to forest + fox. The user picks "Denizin
altında" and "Baykuş" and receives a forest and a fox. The seven world tiles and
six companion chips are decorative.

**B5 — determinism is not guaranteed.** `StoryGenerationManager.swift:1383`:
`seed: UInt64.random(in: 0...UInt64.max)`, generated per call and stored nowhere.
The same intent cannot be reproduced, and a crash mid-generation loses the story.

**B2 — generation failure is silent.** `StoryWizardView.swift:549-554`: the catch
prints to the console and sets `isGenerating = false`, returning the user to the
wizard with no message and no retry.

**B1 — the text story does not reach the Reader.** The reader opens from
`ContentView.swift:46`, `fullScreenCover(item: $app.readerStory)`. The visual
path sets it (`StoryWizardView.swift:44`, via `StoryGeneratingView.onFinished`).
`createOfflineTextStory` sets `pendingStoryID` and calls `dismiss()`
(`StoryWizardView.swift:543-547`) — it never assigns `app.readerStory`. The story
is created, saved, and then nothing happens.

**B4 — Turkish labels as identity.** `V1StoryType`, `V1StoryWorld`,
`V1StoryCompanion` are `String` enums whose `rawValue` is Turkish display text
("Macera", "Ormanda", "Tilki"), and those strings are what cross into generation
as `genre` and `theme` (`StoryWizardView.swift:529-530`).

**B10 — title patterns.** The legacy provider composes titles itself; the
engine's `TitleComposer` (added this session) is not reached, because nothing in
the app calls the new engine at all — see §1.3.

### 1.2 Two more defects found during this audit, not in §30

**The Home preset is ignored.** `MPAppState.startWizard(world:)` sets
`startStep: 2` when a world tile is tapped (`MPAppState.swift:93`), but
`applyPreset` carries a comment admitting the world is dropped
(`StoryWizardView.swift:190`): *"In V1, preset.world isn't directly mapped"*. So
tapping a world on Home skips two steps and then asks for the world again.

**Stories are keyed to a child by name.** `Story.childName: String`
(`Models/Story.swift:7`), and the wizard counts a child's stories with
`stories.filter { $0.childName == profile.name }`
(`StoryWizardView.swift:303`). Renaming a child orphans their library; two
children with the same name share one. §28 of the brief ("stable IDs, never UI
strings") requires fixing this.

### 1.3 The engine is not connected

`StoryEngineContainer` is referenced nowhere outside the bridge folder. The only
app-side import of the package is `StoryGenerationManager.swift:4`, which uses
`TurkishTextRenderer` alone. Text stories are produced by
`TestOfflineTemplateStoryProvider`, embedded in `StoryGenerationManager.swift`
(~lines 1167–1400), reading the flat app-bundle copy of the V1 catalog.

**This is the central fact of this plan.** The Blueprint engine built over the
previous increments — selector, binder, composer, title composer, validator — has
never run in the app. Story Creation V2 is the work that connects it.

---

## 2. Target flow

```
HOME  "Yeni bir masal"
  ↓
STORY IDEA     3 ideas + "Bana sürpriz yap"
  ↓
COMPANION      3 companions + "Bana sürpriz yap"   (derived from the idea)
  ↓
PREPARATION    short narrative transition, no spinner
  ↓
COVER          title · child · world              [ Hikâyeyi Başlat ]
  ↓
READER
```

Two decisions. Child selection moves **out** of the flow: the app already has a
current profile (`ProfileManager.shared.currentProfile`), and asking again on
every story is the step with the least product value. If no profile is selected,
the flow opens on the existing profile selector instead of adding a step.

Removed entirely: story type, direction, world, companion-as-chip, page count,
tone, and the text/visual fork (§20, §21, §22).

---

## 3. The Story Idea model

A Story Idea is **not** a preset and not marketing copy. It is a named bundle of
*constraints plus affinity* — which is the same shape the engine already uses for
blueprint requirements, so it composes with what exists rather than sitting
beside it.

```swift
public struct CatalogStoryIdea: Decodable, Sendable, Identifiable {
    public let id: ContentID                 // "idea_mysterious_signal_001"
    public let display: String               // "Gizemli bir ışığın peşine düşelim"
    public let supportingText: String        // one short sentence
    public let illustration: String          // SF Symbol / asset name
    public let ageRange: AgeBand

    /// Narrows what the engine may bind. Same type as a blueprint's, so the
    /// two intersect rather than fight: an idea about a signal constrains the
    /// discovery, and says nothing about the setting.
    public let requires: ContentRequirements
    public let forbids: ContentExclusions

    /// Affinity, not a pin. §12: an idea must be able to reach several
    /// narrative structures or it is a preset wearing a different name.
    public let preferredFamilies: [NarrativeFamily]

    public let weights: SelectionWeights      // novelty/cooldown, already modelled
}
```

Authored as data in the package bundle, never as Swift literals (§32). It lives
next to the pilot library, in the same file, so one load gets everything.

### 3.1 Why this shape

`requires`/`forbids` are the types added in D1 (`TraitRequirement` with
disjunction). "A mysterious light" is `discovery: allOf [isUnexplained], anyOf
[[emitsSignal, isBeautiful]]` — expressible only because disjunction landed. The
same idea then reaches Family I *and* Family II, which is exactly §6's
requirement that a card be a narrative promise rather than a fixed story.

### 3.2 The three MVP ideas

Derived from the five families and five discoveries that actually exist, not
invented:

| id | Copy | Constrains | Reaches |
|---|---|---|---|
| `idea_mysterious_signal_001` | "Gizemli bir ışığın peşine düşelim" | discovery `isUnexplained` | Unexplained, Threshold |
| `idea_someone_needs_us_001` | "Yardıma ihtiyacı olan birini bulalım" | discovery `impliesNeed` | Appeal |
| `idea_follow_the_traces_001` | "Geride kalan izleri takip edelim" | discovery `impliesPresence` | Absence, Misreading |

Three ideas, five families, no idea bound to one blueprint. Final Turkish copy to
be reviewed against brand voice before authoring.

---

## 4. Engine integration

### 4.1 `OfflineStoryIntent` changes

Today (`Offline/OfflineSelection.swift`):

```swift
OfflineStoryIntent(childName:, settingID:, companionID:, discoveryID:, seed:)
```

Needed:

```swift
OfflineStoryIntent(
    childProfileID: UUID,       // NEW — stable identity, replaces name-keying
    childName: String,          // still needed: it is a slot value
    ageYears: Int,              // NEW — age gating
    locale: String,             // NEW — "tr"
    storyIdeaID: ContentID?,    // NEW — nil means Surprise
    companionID: ContentID?,    // nil means Surprise
    settingID: ContentID?,      // engine-chosen in V2; kept for regeneration
    discoveryID: ContentID?,    // engine-chosen in V2; kept for regeneration
    seed: String,
    catalogVersion: String      // NEW — pins reproducibility to a catalog
)
```

`settingID`/`discoveryID` stay in the type but are no longer supplied by the UI.
They are what a *regeneration* pins, which is how "the same story again" stays
reproducible even if content is added later.

### 4.2 Selection with an idea

`BlueprintSelector.admissible(catalog:intent:)` already computes candidates and
per-blueprint rejection reasons. The change is to intersect the idea's
constraints before scoring:

```
storyIdea.requires ∩ blueprint.requires   →  candidate blueprints
        + storyIdea.preferredFamilies     →  affinity bonus, not a filter
        + novelty / cooldown              →  (I3 proper, later)
        + seeded tiebreak                 →  selected blueprint
```

Affinity is a **score**, never a filter (§12). A blueprint outside
`preferredFamilies` may still be selected if it is the only compatible one — the
alternative is an empty pool, which is the failure this architecture exists to
prevent.

### 4.3 Companion candidates (§8, §9)

After the idea is chosen and before the companion screen renders:

1. compute the blueprints the idea can reach;
2. take the union of companions admissible for at least one of them, using
   `TraitMatch.admits` with that blueprint's `requires.companion` / `forbids.companion`;
3. rank by affinity to the idea's preferred families, then seeded;
4. show the top three, plus Surprise.

This is why the companion is a story role and not decoration: a literal-minded
rabbit is absent from a Misreading story's candidates because the blueprint
forbids it, and an owl is absent from a Threshold story because it can fly across
the barrier the child must cross. That behaviour already exists and is tested
(`MatrixCoverageTests`); this step surfaces it in the UI.

### 4.4 Surprise (§15, §16)

- **Surprise at step 1** — `storyIdeaID = nil`: the engine picks an idea, then
  proceeds normally. The user still sees a companion screen, derived from the
  chosen idea.
- **Surprise at step 2** — `companionID = nil`, idea preserved. The engine picks
  the best-scoring companion for the already-chosen idea. The narrative intent is
  *not* reset (§16 is explicit).

Both are the existing `nil`-means-engine-chooses path in `OfflineContentBinder`,
so this needs no new mechanism.

### 4.5 The blocking dependency: the catalog loader

`ContentCatalogLoader` locates exactly one resource, `shared_content_library_v2.json`
— the V1 catalog, which has **no beats and no traits**, so nothing in it is
selectable under the beat model. The five beat-authored blueprints live in
`pilot_library_v1.json`, loaded directly by tests via `Bundle.module`.

**Story Creation V2 cannot ship until the loader reads the pilot library.** This
is delta D8 in `SCHEMA_MERGE_PLAN.md` (multi-file corpus loader). It is the one
hard prerequisite, and it is engine work, not UI work.

---

## 5. Affected files

### Must change

| File | Change |
|---|---|
| `Screens/StoryWizardView.swift` | **Replaced.** New `StoryCreationFlow` container + `StoryIdeaStep`, `CompanionStep` |
| *(new)* `Screens/StoryCreation/…` | The four screens. New folder — `Screens/` is a synchronized group, so no pbxproj edit |
| `Screens/StoryGeneratingView.swift` | Repurposed as the preparation transition, or replaced; its stages are driven by `StoryStatus` from the *visual* pipeline and do not apply |
| `Screens/MPAppState.swift` | `MPWizardPreset` retired; new routing state for the flow |
| `ContentView.swift:43` | Presents the new flow |
| `Services/StoryGenerationManager.swift` | New entry point taking a `StoryIntent`; old `createOfflineTextStory` retired **after** verification |
| `StoryEngineBridge/` | New file mapping `ComposedStory` → `MagicPaper.Story`; the existing `StoryEngineMapper` maps the *AI pipeline's* `StoryEngine.Story`, which is a different type |
| `StoryEngine/.../Content/` | `CatalogStoryIdea`; `ContentCatalog.storyIdeas` |
| `StoryEngine/.../Offline/` | `StoryIdeaSelector`; `OfflineStoryIntent` fields; affinity in `BlueprintSelector` |
| `StoryEngine/.../Content/ContentCatalogLoader.swift` | Load the pilot library (D8) |
| `Resources/blueprints/pilot_library_v1.json` | Three authored Story Ideas |

### Probably change

`Views/HomeView.swift` (entry point wording only), `Views/LibraryView.swift` and
`Models/Story.swift` (child id vs name, §6 below).

### Do not touch (§39)

Home layout, Library layout, Profile, Reader, `StoryViewerView`, the visual/AI
pipeline, `FalImageProvider`, subscription and paywall logic, daily stories.

---

## 6. State migration and deletions

**Delete with the wizard:** `V1StoryType`, `V1StoryDirection`, `V1StoryWorld`,
`V1StoryCompanion` (all four enums are declared in `StoryWizardView.swift` and
used nowhere else — verified), and `MPWizardPreset`.

**Verify before deleting** — these are referenced outside the wizard and must be
checked one at a time, per §31:

- `MPStoryLength` / `MPStoryTone` (`DesignSystem/MPBridge.swift:46,89`) — the
  wizard hardcodes `.orta` / `.neseli` rather than asking, so the *wizard* does
  not need them, but `createCustomStory` still takes them. Keep until the visual
  path is addressed; it is out of scope here.
- `Story.theme: StoryTheme` — a **required** field on the app's story model
  (`Models/Story.swift:7`). V2 must still supply one. Map from the selected
  blueprint's family to the nearest `StoryTheme` in the bridge, and never surface
  it in the UI.
- `MP.World` — used by Home tiles and `StoryGeneratingView`. Keep.

**`childName` → `childProfileID`:** additive and staged. Add
`childProfileID: UUID?` to `Story`, write both fields on creation, switch Library
and counts to read the id with a name fallback, and only then stop writing the
name. Existing stories decode with `childProfileID == nil` and keep working —
dual-read, no destructive migration, consistent with the master plan §14.

---

## 7. Navigation and persistence

**Navigation.** The reader opens from `fullScreenCover(item: $app.readerStory)`
(`ContentView.swift:46`). The new flow must set `app.readerStory` on
*"Hikâyeyi Başlat"*, which is the direct fix for B1. The cover screen is new and
sits between preparation and reader.

**Persistence.** Stories remain in `StoryGenerationManager.stories` +
`saveStories()`. Two additions:

- persist the **seed**, `storyIdeaID`, `companionID`, `blueprintID` and
  `fingerprint` on the story, so §38's "re-running with the same seed produces
  the same result" is checkable against a stored story rather than only within
  one process;
- keep the existing `read_history_*` blueprint cooldown key
  (`StoryGenerationManager.swift:1369`) — it is the only novelty mechanism that
  exists today, and the new flow should feed it.

**Not touched:** the legacy `UserDefaults["stories"]` bulk-delete above 4 MB
(`StoryGenerationManager.swift:910`) is data loss and should be removed, but it
is a separate change with its own risk.

---

## 8. UI: reuse, not reinvention

Everything §24 lists exists and was read. `MPChoiceTile`
(`DesignSystem/MPSurfaces.swift:197`) takes `title`, `description`, `symbol`,
`accent`, `isSelected`, `isLocked`, `layout: .row | .column` — it is already the
Story Idea card, in `.column` layout at a larger size. Also present: `MPCard`,
`MPPressableCard`, `MPButton`, `MPChip`, `MPBadge`, `MPStepDots`, `MPStoryCard`,
`MPAvatar`, `MPSectionHeader`, `MPEmptyState`, and the `MP.C/S/F/M/R/E` tokens
with `mpScreenBackground()` / `mpGutter()`.

| Screen | Built from |
|---|---|
| Story Idea | `MPChoiceTile(layout: .column)` ×3 + a Surprise tile; `MPStepDots(total: 2)` |
| Companion | `MPChoiceTile(layout: .column)` ×3 + Surprise |
| Preparation | `MPCard(tone: .paper)` with staged text; no spinner (§19) |
| Cover | `MPStoryCard` or `MPCard` + `MPAvatar` + `MPButton` |

**The one genuine gap:** nothing renders an illustrated, cover-like card. The
minimum addition is a `MPStoryIdeaCard` wrapping `MPPressableCard` — not a new
design language, a new arrangement of existing tokens.

---

## 9. Error handling (§29)

One user-facing message, one retry, full detail to the log:

> "Hikâyemizi hazırlarken küçük bir sorun oldu. Bir kez daha deneyelim."

`OfflineSelectionError` already carries a structured `.explanation` naming every
rejected candidate and why. That string goes to the log and **never** to the
screen. `noBlueprintsFound`, decode errors and compatibility failures stay
internal — which is the whole point of having typed errors with reasons.

---

## 10. Testing

**Engine (package, XCTest):** Story Idea decoding and stable ids; an idea reaches
more than one family; idea ∩ blueprint requirement intersection; companion
candidates for each idea are non-empty and exclude forbidden traits; Surprise at
step 1 and at step 2 (intent preserved); `StoryIntent` construction; the same
seed produces an identical fingerprint and prose; a different child produces a
different one; an impossible combination throws with reasons.

**§38 integration test**, end to end in the package with a stub catalog:
idea `idea_mysterious_signal_001` + a fox + seed `12345` → intent carries both
ids; a compatible blueprint is found and selected; the story is 8 pages; the
companion appears in the text; no `{{` remains; validation passes; re-running is
byte-identical.

**App-level:** there is still no test target (I1 §K1). Creating one is a prerequisite
for testing navigation, persistence and retry, and should be the first task of
implementation — not deferred again.

---

## 11. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | **The loader does not read the pilot library.** Nothing selectable ships today | D8 first. Hard blocker; do it before any UI |
| R2 | **Content is thin** — 5 settings, 5 companions, 5 discoveries. Three ideas over that pool will repeat quickly | Ship anyway; note that novelty needs I3 and more content. Do not widen the ideas to hide it |
| R3 | **A parallel session owns the content layer** — 14 blueprints and a v3 corpus in flight. This plan is written against the 5-blueprint library | Agree the schema (`SCHEMA_MERGE_PLAN.md` D1–D4) before authoring ideas, or the ideas get re-authored |
| R4 | `Story.theme` is required and taxonomic. Supplying it from a family mapping is a quiet coupling | Map in the bridge, in one function, with a comment; never surface it |
| R5 | Deleting the wizard removes the **visual** story entry point too | §22 says visual enrichment becomes a separate action on an existing story. That action does not exist yet — either keep a temporary entry or accept that visual stories are unreachable during the transition. **Needs your decision** |
| R6 | No app test target, so navigation and persistence changes are unverified by CI | Create it first |
| R7 | The child-selection step is being removed | Verify `currentProfile` is always set by the time Home can start a story |

---

## 12. Sequence

1. **D8** — loader reads the pilot library. *Blocking.*
2. App test target.
3. `CatalogStoryIdea` + three authored ideas + engine-side selection and affinity, with tests.
4. `ComposedStory` → `MagicPaper.Story` bridge, with the seed and ids persisted.
5. The four screens, against the existing design system.
6. Wire `app.readerStory`; retire `createOfflineTextStory`; delete the wizard and its four enums.
7. `childProfileID` migration, dual-read.

Steps 1–4 are engine and bridge work with no UI. Step 5 is the first step that
changes what the user sees, and by then the thing behind it already works.

---

## 13. Open questions

1. **R5 — the visual story path.** Removing the fork leaves no way to create an
   illustrated story until "turn this into a picture book" exists. Keep a
   temporary entry, or accept the gap?
2. **Child selection.** Confirm it moves out of the flow and relies on
   `currentProfile`.
3. **Story Idea copy.** The three above are structural placeholders; final
   Turkish wording should be reviewed against brand voice.
4. **Sequencing against the parallel session** (R3).

**No implementation code has been written. Awaiting approval.**
