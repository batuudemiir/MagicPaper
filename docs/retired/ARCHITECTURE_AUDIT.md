# MagicPaper Kids — Architecture Audit (V2 starting point)

## Current architecture

The repository contains two largely independent story systems:

1. **Active iOS app path (legacy / cloud)** — `MagicPaper/MagicPaper` is a SwiftUI app with singleton managers. `MagicPaperApp` gates onboarding and profile selection, `ContentView` owns navigation, and `StoryWizardView` drives a four-step V1 choice flow. `StoryGenerationManager` creates the app-level `Story`, calls Firebase, Gemini (`AIService`), and fal.ai, and persists a `[Story]` JSON blob in `UserDefaults`.
2. **Unwired package path (engine)** — `MagicPaper/StoryEngine` is a well-separated Swift package: `EngineFoundation`, `CharacterEngine`, `VisualSystem`, and `StoryEngine`. It has vendor-neutral domain/services/protocols, deterministic hashing, template resolution, lifecycle services, and substantial unit tests. `MagicPaper/MagicPaper/StoryEngineBridge` supplies adapters, file stores, a Gemini adapter, a fal adapter, and an app-model mapper, but neither the local package nor bridge sources are linked by `MagicPaper.xcodeproj`.
3. **Prototype offline V2 path** — `StoryGenerationManager.swift` embeds `TestOfflineTemplateStoryProvider` and V2 DTOs. It loads a JSON catalog, applies simplified filters, resolves templates, then returns the old app `Story`. This is reachable only through the secondary “Metin masalı oluştur” button in `StoryWizardView`.

## UI and data flow

`MagicPaperApp` → onboarding/profile gate (`ProfileManager`) → `ContentView` (`MPAppState`) → Home / Library / Daily / Parent tabs. The center action opens `StoryWizardView`.

The current wizard asks **child → type → direction → world**, then accepts a companion internally but does not offer the requested explicit three-choice V2 ritual. Its primary action uses `createCustomStory` (remote image/story generation); its secondary action calls the embedded offline prototype. `StoryGeneratingView` then opens `StoryViewerView`; the reader and library consume only `MagicPaper.Models.Story`.

The existing profile model is `UserProfile` in `Services/ProfileManager.swift`: id, name, age, profile type, local image filename, and created date. This already provides child identity and age; V2 must reuse it rather than re-ask for either. Profiles are JSON in `UserDefaults`; photos are JPEGs in Documents.

## Persistence and targets

* App stories are one `UserDefaults["stories"]` blob, with page/cover images in Documents. The manager already warns above 1 MB; this is unsuitable for the richer engine story/provenance data.
* The bridge’s `FileStores.swift` correctly proposes one JSON record per engine story/request/job/character under `Documents/StoryEngine`, but it is inactive.
* The app target has no XCTest target. The only native test suite is `StoryEngine/Tests`.
* The app target includes `adventure_01.json` and `MagicPaper/MagicPaper/templates/offline/v2/shared_content_library_v2.json` as resources. The V2 file is byte-identical to the copy in the Swift package. The app resource is flattened at bundle root, while the prototype loader tries both nested and root lookup, so that particular lookup can work.
* `MagicPaper.xcodeproj` has Firebase and RevenueCat package dependencies only. It has no local `StoryEngine` package product, and the bridge folder is absent from source build phases. Consequently, the production app cannot use the packaged engine or its packaged resources today.

## Existing engine and content

The package `StoryRequest` is immutable and testable but template-centric: it requires `templateID`, `themeKey`, page count, age, language, and cast. It does **not** represent place/companion/secret, surprise flags, or an explicit deterministic seed. `TemplateResolver` resolves by a caller-specified template ID, then theme/language/age; it is not a blueprint candidate/scoring selector.

The package’s `StoryOrchestrator` is designed for AI text/image providers; its active container requires Gemini and fal credentials. It is structurally useful (dependency injection, validation, lifecycle, provenance), but it is not the requested offline template provider.

The V2 catalog has 12 blueprints, 16 settings, 15 companions, 20 objects, 20 events, 15 challenges, and 52 role templates. Blueprints currently repeat one `adventure/courage/5-6/8-page` shape and contain only id/genre/theme/age/page roles. Components have partial compatibility metadata, but the prototype only filters by `compatibleThemes`; it does not enforce setting/companion/object/challenge compatibility, state transitions, endings, requirements, novelty weights, or selected secret. The catalog is Turkish, although its schema/prototype types live in an app service named `Test…`.

## Confirmed risks / root causes

1. **Split, inactive architecture.** The app’s live production flow is cloud/legacy; the tested package and bridge cannot be reached by the target. Adding V2 features to the embedded prototype would create a third domain instead of evolving the engine.
2. **`noBlueprintsFound` cannot be diagnosed from the current active prototype.** The current `TestOfflineTemplateStoryProvider` defines that error but never throws it; it falls back from genre → all blueprints, and then selectively declines age/page filters when empty. A prior error necessarily came from another revision/path. The present device failure most likely manifests as `missingSharedLibrary` if packaging is wrong, because the hard-coded developer path is not available on device. Resource lookup needs explicit diagnostics/tests before changing filters.
3. **Current UI values do not match catalog vocabulary.** The offline call passes Turkish `V1StoryType.rawValue` (for example `Macera`) against catalog genre `adventure`, and Turkish direction text against keys such as `courage`; broad fallback masks this mismatch and can choose unrelated content. World and companion are hardcoded to `setting_forest_001` and `companion_fox_001` for every non-surprise choice.
4. **False determinism.** The prototype has an LCG but creates its request seed with `UInt64.random`; UUID page/story IDs are random too. It stores only blueprint IDs as history, not a generation fingerprint or selected component IDs.
5. **Two incompatible story models/stores.** Mapping engine output back to `MagicPaper.Story` preserves reader compatibility, but loses engine provenance/state unless the engine record remains canonical. Library filtering uses child name rather than profile ID, so renames/collisions are unsafe.
6. **Robustness gaps.** Offline failure is only printed and dismisses/halts without user-facing recovery. The ad-hoc decoder accepts only selected catalog fields, ignores endings/resolutions/state data, and treats any compatible list absence as a random fallback.
7. **Verification status.** `swift test --package-path MagicPaper/StoryEngine` currently fails before tests due to a resource-bundle code-signing error (“resource fork, Finder information, or similar detritus”), not a test assertion. This must be repaired/validated independently of V2 functional work.

## Recommended V2 boundaries

Keep `UserProfile`, the SwiftUI reader/library, and `MagicPaper.Story` as the UI compatibility surface initially. Make a single app-facing `StoryCreationRequest` at the bridge boundary (profile ID/name/age, selected place/companion/discovery IDs, language, seed, surprise flags). Keep it distinct from the package’s internal execution request only if the latter cannot be evolved compatibly.

Put catalog schema, decoding, diagnostics, compatibility filtering/scoring, stateful page variant selection, fingerprinting, and offline `StoryProvider` inside `StoryEngine`—not in views or `StoryGenerationManager`. The package should expose one offline provider for MVP and retain the existing protocol boundary for future cloud/on-device providers. The bridge should map profile → character and canonical engine story → existing reader model, while engine files remain the source of truth. Migrate library-facing records gradually, preserving legacy stories and their UserDefaults store read-only until successful import/mapping.

The V2 UI should replace the V1 technical choice taxonomy with exactly place → companion → secret/discovery, roughly four choices plus Surprise at each step. It should request only display-ready choices from a catalog facade and submit IDs; it must not know blueprint IDs, roles, or compatibility rules.

## Implementation order

1. Make the local Swift package and bridge target members; add a resource discovery/decoding catalog test and fix package test signing.
2. Consolidate the duplicate V2 catalog into a single package-owned source and make the app consume it through the package bundle.
3. Introduce/evolve V2 domain schema plus deterministic offline provider, candidate diagnostics, compatibility, state, variants, fingerprint, and validation tests.
4. Wire bridge persistence and mapping; migrate safely from existing app stories.
5. Replace the wizard with the three-choice UX and preparation/cover states; make failures actionable.
6. Retire the embedded `TestOfflineTemplateStoryProvider` only after the packaged provider is integrated and old cloud/illustrated flows remain explicitly supported.
