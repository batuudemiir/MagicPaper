# I1 — Build & Project Wiring — Implementation Report

**Date:** 2026-09-15
**Scope:** I1 only. No catalog models, no `StoryProvider`, no offline engine, no new UI,
no content migration, no cleanup, no removal of the legacy offline provider.
**Result:** ✅ Complete. App builds, launches, and runs. Repository is ready for I2.

---

## Headline finding: the app did not compile before this task

Before any change, the baseline build **failed**:

```
StoryGenerationManager.swift:1302:65: error: missing argument for parameter 'preferredId' in call
** BUILD FAILED **
```

`getCompatible(from:preferredId:extract:)` has no default for `preferredId`, and the
objects call omitted it. This is inside the embedded `TestOfflineTemplateStoryProvider`
block and is unrelated to the engine work.

**This reframes the original bug report.** A `noBlueprintsFound` runtime error could not
have come from a current build of this app, because there was no current build. It
corroborates the root-cause analysis in `STORY_SYSTEM_V2_PLAN.md` §6: that string is
thrown only by the loose scratch scripts at the repo root, never by the app target.

Running the baseline *first* is what made this attributable. Had I wired and built in one
step, this failure would have looked like mine.

---

## Files changed

| File | Change | Why |
|---|---|---|
| `MagicPaper.xcodeproj/project.pbxproj` | **+32 lines, −0** | Wire local package + bridge |
| `MagicPaper/Services/StoryGenerationManager.swift` | **1 line** | Repair pre-existing build break |
| `StoryEngineBridge/FileStores.swift` | conformances, access, `Story` qualification | Make bridge compile |
| `StoryEngineBridge/StoryEngineContainer.swift` | `Error` conformance, access, doc fix | Make bridge compile |
| `StoryEngineBridge/FalImageProvider.swift` | `import VisualSystem`, access | Make bridge compile |
| `StoryEngineBridge/StoryEngineMapper.swift` | access | Make bridge compile |
| `StoryEngineBridge/ProfileCharacterSource.swift` | access | Make bridge compile |
| `StoryEngineBridge/FileAssetDeleter.swift` | access | Make bridge compile |
| `StoryEngineBridge/GeminiStoryAIProvider.swift` | access | Make bridge compile |

Nothing else in the app was touched. Verified by modification time: no file outside
`StoryEngineBridge/`, `StoryGenerationManager.swift` and `project.pbxproj` changed.

A pre-edit backup of `project.pbxproj` is at
`…/scratchpad/backup/project.pbxproj.I1-before` (sha1 `99b53b93…`).

---

## Project wiring changes

All additive — **32 lines inserted, 0 removed**, confirmed by diff against the backup.

| # | Addition | Purpose |
|---|---|---|
| 1 | `XCLocalSwiftPackageReference` → `relativePath = StoryEngine` | Declares the local package |
| 2 | Entry in project `packageReferences` | Registers it in the package graph |
| 3 | 3 × `XCSwiftPackageProductDependency` (`StoryEngine`, `CharacterEngine`, `VisualSystem`) | The products the bridge imports |
| 4 | 3 × entries in target `packageProductDependencies` | Attaches them to the app target |
| 5 | 3 × `PBXBuildFile` + 3 × entries in the Frameworks phase | Links them |
| 6 | `PBXFileSystemSynchronizedRootGroup` for `StoryEngineBridge` | Compiles the bridge |
| 7 | Entry in target `fileSystemSynchronizedGroups` | Attaches the folder to the target |
| 8 | Entry in the `MagicPaper` navigator group | Makes it visible in Xcode |

### Why a synchronized folder group

The project already uses `PBXFileSystemSynchronizedRootGroup` for `DesignSystem/`,
`Screens/` and `Helpers/`. Mirroring that pattern means:

- one object instead of 14 (7 `PBXFileReference` + 7 `PBXBuildFile`),
- new bridge files in I2+ are picked up **automatically**, with no further pbxproj edits —
  which matters because explicit membership is exactly how 13 files ended up on disk but
  never compiled (see below).

### Method

Because this session is non-interactive I could not use the Xcode UI, so the edit was
applied by a script anchored on nine exact existing strings, each asserted. It was
**dry-run on a copy first** (all 9 anchors matched, +32/−0), then applied, then validated
with `plutil -lint` (OK) and `xcodebuild -list` (project readable).

---

## Why each bridge change was necessary

The bridge had **never been type-checked** — it was not in any target and the package was
not a dependency, so it could not compile even in principle. Wiring it exposed four
categories of real breakage:

1. **3 missing protocol conformances.** `JobStore` gained `delete(jobID:)` /
   `deleteRequest(id:)` and `CharacterStore` gained `delete(id:)` during the earlier
   production-hardening work, *after* the bridge was written. `FileJobStore` and
   `FileCharacterStore` no longer satisfied their protocols. Added, delegating to the
   existing `FileBackedStore.delete`.

2. **64 `public` modifiers.** The bridge lives *inside* the app module and touches
   `Story`, `UserProfile` and `FileManagerService` — all `internal`. A `public`
   declaration may not expose an internal type, so each was a compile error. Stripped;
   within one module `public` grants nothing.

3. **`UnavailableReason` did not conform to `Error`.** It is used as the failure type of
   `Result<StoryEngineContainer, UnavailableReason>`, which requires it.

4. **Two module-boundary bugs that only a real compile could reveal:**
   - `FalImageProvider` used `AspectRatio` (a `VisualSystem` type) without importing
     `VisualSystem`.
   - `FileStoryRepository` declared `func story(id:) -> Story?`. Inside the app module
     unqualified `Story` resolves to **`MagicPaper.Story`**, not `StoryEngine.Story`, so
     it silently failed to satisfy `StoryRepository`. Now qualified as
     `StoryEngine.Story`, with a comment recording why.

Point 4 is worth carrying into I2: the app and the engine both define `Story`,
`StoryPage` and `StoryStatus`. Any bridge code touching those **must qualify them**.

---

## Build result

| Stage | Result |
|---|---|
| Baseline, before any change | ❌ **BUILD FAILED** — 1 pre-existing error |
| Baseline, after 1-line repair | ✅ **BUILD SUCCEEDED**, 0 errors |
| Wired (package + bridge) | ✅ **BUILD SUCCEEDED**, 0 errors |

Configuration: `xcodebuild -scheme MagicPaper -sdk iphonesimulator -configuration Debug`,
Xcode 27.0, iOS deployment target 17.6, Swift 5.0.

All four engine targets now compile into the app: `EngineFoundation`, `CharacterEngine`,
`VisualSystem`, `StoryEngine`.

### Bundle verification — resolves an open question from the plan

`STORY_SYSTEM_V2_PLAN.md` §0 flagged the resource-flattening claim as an unverified
inference. **It is now confirmed empirically** from the built `.app`:

```
<APP>/shared_content_library_v2.json                        ← flattened to bundle ROOT
<APP>/StoryEngine_StoryEngine.bundle/shared_content_library_v2.json
<APP>/StoryEngine_CharacterEngine.bundle
<APP>/StoryEngine_VisualSystem.bundle
```

Two consequences:

1. The app resource **is** flattened to the bundle root, so
   `Bundle.main.url(forResource:withExtension:subdirectory:"templates/offline/v2")`
   cannot succeed. Only the loader's flat fallback works. Confirms plan §6.
2. The catalog is now in the app bundle **twice** — once flat, once inside the package
   resource bundle. Harmless today, but it is exactly the "one source of truth" problem
   I2 must resolve.

---

## Test result

| Suite | Result |
|---|---|
| `VisualSystemTests` | 51 passed, 0 failures |
| `StoryEngineTests` | 303 passed, 0 failures |
| `EngineFoundationTests` | 17 passed, 0 failures |
| `CharacterEngineTests` | 42 passed, 0 failures |
| **Total** | **413 passed, 0 failures** |

**App tests: none exist.** The project has exactly one target and no test target, so there
were no app tests to run.

### Note on the "package tests are broken" claim

`ARCHITECTURE_AUDIT.md` reported `swift test` failing with a resource-fork/codesign error.
That is **not a code defect**. The package directory carries `com.apple.macl` and
`com.apple.provenance` xattrs because it lives under `~/Desktop`, which breaks `codesign`
on the `.xctest` bundle when building into the default `.build`. Either fixes it:

```bash
xattr -cr StoryEngine
```

or build to a path outside `~/Desktop` via `--scratch-path`. The engine itself is healthy.

---

## Launch verification

Installed and launched on **iPhone 17 Pro (iOS 27.0)** simulator.

- Process started (PID 87696) and remained alive past 10 s.
- No crash report generated.
- Onboarding screen rendered correctly: warm paper ground, Baloo 2 display type, brand
  rose, hard-edge button depth, page dots, Turkish copy.

Existing functionality is intact — the app behaves exactly as before. Linking the engine
changed nothing at runtime, which is the intended outcome: **the engine is wired but
still unused.** No app code calls `StoryEngineContainer`.

---

## Known issues

| # | Issue | Severity | Owner |
|---|---|---|---|
| K1 | **13 files on disk were never compiled** (explicit membership, silently omitted): `HomeView_OLD_BACKUP.swift`, `patch.swift`, `FalImageGenerator.swift`, `LocalizationManager_Extended.swift`, `TextStoryLibraryView.swift`, `TextStoryViewerView.swift`, and the 7 bridge files. Only the bridge is now fixed. | Medium | I9 |
| K2 | **Catalog duplicated in the app bundle** (flat + package resource bundle). | Medium | I2 |
| K3 | **`m.xcodeproj` is an empty shell** with no `project.pbxproj`. It breaks `xcodebuild` auto-discovery, forcing `-project` on every invocation. | Low | I9 |
| K4 | **`templates/adventure_01.json` is 0 bytes** and ships as a build resource. | Low | I9 |
| K5 | **fal.ai API key hard-coded in three source files**, committed to git. Assume compromised; rotate. | **Security** | Urgent |
| K6 | Bridge files are compiled but **unreferenced**, so they are dead weight until I6. Deliberate. | Informational | I6 |
| K7 | `FileManagerService` is not `Sendable`; the compiler notes this where the bridge captures it. A warning under Swift 5, an **error under Swift 6**. | Low | I6 |
| K8 | A clean SPM resolve clones the full `protocolbuffers/protobuf` repo (a `swift-protobuf` submodule) and takes many minutes. Builds here reuse the existing DerivedData. CI must cache this. | Medium | CI |

---

## App test target — assessed and deliberately deferred

I1 listed this as *"create/prepare the app test target **if required**"*. I did not add it.

**Reasoning:** it is not required to verify I1 — there are no app tests to run, and every
I1 acceptance criterion is met without it. Adding one is a second high-risk mutation of a
project file that currently works, and D3's explicit intent was to make one change,
verify, and stop. Having already had to make four unplanned repairs to get the bridge
compiling, I did not want to spend the verified-good state on an optional change.

**Recommendation:** make it the first task of I2, where it has an immediate consumer — the
catalog bundle-discovery test that must prove resources load from a real app bundle.

If you would rather it were done now, say so and I will do it as an isolated change.

---

## Is the repository ready for I2?

**Yes.**

- ✅ App builds (0 errors) and launches; existing behaviour unchanged.
- ✅ Local `StoryEngine` package is a genuine project dependency; all four targets compile
  into the app.
- ✅ `StoryEngineBridge` compiles as a synchronized group; future files need no pbxproj edits.
- ✅ Engine package healthy: 413 tests, 0 failures.
- ✅ Package resource bundles ship correctly into the `.app`.
- ✅ Project file validates (`plutil`, `xcodebuild -list`); additive change only, backup retained.

**Carry into I2:**

1. Add the app test target first.
2. Resolve the duplicate catalog (K2) — one package-owned source of truth.
3. Qualify `StoryEngine.Story` / `StoryEngine.StoryPage` / `StoryEngine.StoryStatus`
   everywhere the bridge touches them; the app module shadows all three.
4. Delete the hard-coded developer path in `StoryGenerationManager.swift:1247` once the
   catalog loads from the package bundle.

**Stopping here as instructed. I2–I9 not started.**
