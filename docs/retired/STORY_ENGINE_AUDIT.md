# Story Engine / Persistence Audit — 2026-09-15

## Executive finding

The repository contains a well-factored, testable `StoryEngine` package, but the customer-facing story wizard does not call it. The active text-story path is a separate, app-target `TestOfflineTemplateStoryProvider`; the image-story path is the older `StoryGenerationManager` AI flow. This is a useful migration seam, but it is not yet one end-to-end Story Engine system.

## Current request-to-story paths

| Entry point | Request model / selection | Generator | Persistence | Reader |
| --- | --- | --- | --- | --- |
| `StoryWizardView` → **Görselli masal** | child + `MP.World`; V1 type/direction/companion are not passed | legacy `StoryGenerationManager.createCustomStory` | app `Story` JSON in `UserDefaults`; image files separately | `StoryViewerView` |
| `StoryWizardView` → **Metin masalı oluştur** | `TestOfflineStoryRequest` | `TestOfflineTemplateStoryProvider` in `StoryGenerationManager.swift` | same app `Story` JSON, plus blueprint IDs in `UserDefaults` | `StoryViewerView` |
| `StoryEngineContainer` | immutable `StoryEngine.StoryRequest` | `StoryOrchestrator` | one JSON record per engine story/job/request/profile under `Documents/StoryEngine` | no app/UI caller |

Evidence: `StoryEngineContainer` explicitly says “existing story creation still goes through `StoryGenerationManager`, untouched.” No app source calls `StoryEngineContainer.make`, `makeRequest`, or `orchestrator.generate`.

## StoryRequest and engine assessment

`StoryEngine.StoryRequest` is a sound runtime boundary: immutable, Codable, versioned, and sufficiently specific for reproducibility (`cast`, template/version requirement, opaque `themeKey`, language, age, page count, tone, budget, seed policy, creation date). The orchestrator resolves and pins a template before persisting the request, story, and resumable job. Its dependency injection, checkpoints, template resolution, safety gates, provenance, and test suite are good foundations for V2.

The gap is upstream: the product choices have no V2 domain model and no mapper to the engine request. `StoryEngineContainer.makeRequest` also defaults `templateID` to `adventure_01`; that template declares an empty `themeKeys` array (therefore accepts all themes), so it cannot itself enforce Place/Companion/Discovery compatibility.

## Exact `noBlueprintsFound` / empty-candidate analysis

The active V2 provider declares `TestOfflineGenerationError.noBlueprintsFound(String)` in `MagicPaper/MagicPaper/Services/StoryGenerationManager.swift`, but never throws it. Instead:

1. It filters `library.blueprints` by exact `request.genre`.
2. If empty, it silently falls back to every blueprint.
3. Age and page filters also silently retain the prior pool when they find no match.
4. It force-unwraps `unreadCandidates.randomElement(using: &rng)!`.

Therefore an actually empty `blueprints` array produces a runtime trap, not `noBlueprintsFound`. A “no blueprint” error observed from the root-level scripts (`local_test.swift`, `run_test_now.swift`, `update_engine.swift`, or `test_runner.swift`) comes from diagnostic/patch scripts, not the app-target active provider. Those scripts contain their own loaders and strict filtering, so their error is not proof that the app’s current provider hit the same condition.

The resource itself decodes as non-empty: 12 blueprints, all `{ genre: adventure, theme: courage, ageRange: 5-6, pageCount: 8 }`. The project also lists `shared_content_library_v2.json` in the app Resources build phase. The active loader first tries the subdirectory, then the flat bundle name, then a machine-specific development path; the second lookup should handle Xcode resource flattening. A missing/undecodable resource would currently yield `missingSharedLibrary` or a JSON decoding error, not `noBlueprintsFound`.

There are meaningful selection mismatches even when the library loads:

- The wizard passes Turkish display strings such as `"Macera"` and `"Biraz cesur olalım"`; V2 content uses `"adventure"` and `"courage"`. Genre therefore falls back to all blueprints, and theme compatibility falls back to arbitrary content.
- The wizard always requests `.orta`; V2 has only 8-page blueprints. Page filtering falls back to the 8-page set, so the apparent requested length is not honored.
- `settingId` is hard-coded to `setting_forest_001` for every non-surprise world; `companionId` is hard-coded to `companion_fox_001` for every non-surprise companion. Most visible place/companion choices do not affect the output.
- `events`, `challenges`, and `stateChanges` are decoded but unused. The V2 story uses setting, companion, object, page-role templates only.
- Blueprint read history is keyed by child ID, which is good, but can grow unbounded and is not transactionally coupled to story persistence.

## Persistence and identity audit

- App profile: `UserProfile` (name, age, optional local image filename) is a `UserDefaults` blob; profile photo is a Documents file. Its UUID is stable and is suitable as the ownership/character key.
- Legacy/app story: an app-specific `Story` list is serialized to `UserDefaults`; image data is stored separately. The manager itself warns at 1 MB and clears the entire `stories` key above 4 MB during a legacy migration. This is unsuitable as the long-term source of truth for a fully provenance-rich engine story.
- Engine records: `FileStoryRepository`, `FileJobStore`, and `FileCharacterStore` correctly use atomic JSON files below `Documents/StoryEngine/{Stories,Jobs,Requests,Characters}`. Decode failures are isolated per record, and jobs can resume.
- The stores are disjoint. There is no migration, shared library repository, or mapping from engine `Story` to app `Story` in the actual creation flow. A V2 adoption needs a single library-visible record strategy before switching readers.
- `ProfileCharacterSource` can create a versioned engine character from the existing profile UUID, but it has no caller. The current visual story route substitutes an initials avatar rather than using the saved profile photo.

## Recommended implementation order

1. Introduce a UI-owned `StoryIntent`/`StoryCreationDraft` with opaque IDs for place, companion, and discovery; do not expose engine template/blueprint concepts.
2. Add a content-catalog repository that validates the shipped V2 library at launch/build time and returns compatibility-filtered candidates with an explicit typed empty result.
3. Map intent deterministically to a real engine `StoryRequest` and resolve the template internally. Remove display-string matching, hard-coded forest/fox, and force unwraps.
4. Wire the wizard through `StoryEngineContainer`, `ensureCharacter`, and `StoryOrchestrator`; surface persisted job progress in the preparation screen.
5. Define a migration/adapter so the library and reader can show both legacy books and engine books while new generation writes only the durable engine representation.
6. Add integration tests covering every visible choice, Surprise Me, all supported ages, resource loading from an app bundle, empty compatibility pools, resume/retry, and profile-photo identity preservation.

No application code was changed for this audit.
