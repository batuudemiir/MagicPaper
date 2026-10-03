# MagicPaper Kids — Story System V2 Implementation Plan

## Plan-mode decision

No production implementation has been changed in this planning phase. Proceed only after review of this plan and the four audit/spec documents. Flow A/C are equivalent in interaction; adopt the child-led wording of **Nereye gidelim? → Yanımızda kim olsun? → Bugün neyi keşfedelim?** as the MVP.

## Architecture and data flow

```text
SwiftUI draft (opaque place/companion/discovery IDs)
  → StoryIntent (profile ID, locale, seed, surprise resolution)
  → OfflineTemplateStoryProvider
  → catalog diagnostics → compatibility/scoring → generation plan
  → stateful variant assembly → validation/fingerprint/provenance
  → file-backed engine story + reader adapter → existing reader/library
```

Keep the cloud image route available as a separate optional visual upgrade. New text stories must not require Gemini, fal.ai, Firebase, or network access.

## File-by-file sequence

| # | Purpose | Likely files | Risk / acceptance |
| --- | --- | --- | --- |
| 1 | Make the package and bridge buildable in the app; fix resource-signing metadata and prove bundle discovery. | `MagicPaper.xcodeproj`, `StoryEngine/Package.swift`, resource folders | Medium. App and `swift test` build; catalog is found in production/test bundles. |
| 2 | Establish one canonical catalog and public V2 schema/repository. | `StoryEngine/Sources/StoryEngine/{Domain,Services,Resources}` | Medium. Strict decode, reference checks, diagnostics; no app duplicate source of truth. |
| 3 | Build deterministic offline provider and plan/provenance model. | new provider/selector/validator files, `StableHash.swift` | High. Same intent/seed yields same plan and fingerprint; typed empty-candidate errors replace force unwrap/fallback. |
| 4 | Add compatibility, state, title, placeholder, safety, and novelty validation. | selector/validator tests and V2 catalog | High. Selected three choices always appear; all 8 roles/state transitions validate. |
| 5 | Wire profile/character, durable stores, mapper, and dual-read migration. | `StoryEngineBridge/*`, app story/library models | High. New books reopen after relaunch; legacy books remain visible. |
| 6 | Replace V1 wizard choices with the three-step catalog-backed ritual, preparation, cover, and failures. | `Screens/StoryWizardView.swift`, `StoryGeneratingView.swift`, `MPAppState.swift` | Medium. Four cards + Surprise per step, accessibility preserved, no engine terms. |
| 7 | Retire the embedded prototype only after V2 is live; retain cloud visual creation behind its own entry. | `Services/StoryGenerationManager.swift` | Medium. No `Test*` models, display-string matching, absolute paths, or forest/fox mapping remain. |
| 8 | Curate first production-quality content world and validate it in CI. | canonical JSON plus Content Creator validator | Medium. 10–15 distinct structures over time; quality-gated Turkish/safety coverage. |

## Test strategy

Add package tests for bundle lookup, JSON decode/version/reference integrity, catalog diagnostic counts, request/choice matching, compatibility rejection reasons, deterministic replay, seed variation, score/cooldown behavior, all role sequences, state transitions, slots/Turkish titles, safety, fingerprint duplication, persistence/reopen, and deliberate invalid/missing catalog data. Add app integration/UI tests for active/multiple child profiles, all visible choices, Surprise at each stage, offline creation, cover→reader, retry/cancel, and legacy library migration.

The exact regression contract for current MVP is: child age 5–6 + `adventure/courage` + 8 pages + seed 12345 discovers resources, decodes content, selects one blueprint, produces eight ordered roles, resolves all slots, passes validation, creates a fingerprint, and persists/reopens.

## Migration strategy

Ship dual-read first: legacy `UserDefaults` stories continue through the current reader; V2 records are canonical in `Documents/StoryEngine` and adapt into reader-facing data. Do not bulk-delete or overwrite legacy stories. After successful production validation, remove the redundant V2 app resource and embedded prototype, then consider importing eligible legacy records only with explicit mapping and backup.

## Risks and controls

| Risk | Control |
| --- | --- |
| V2/catalog and active app drift | One package-owned catalog, bundle smoke tests, no label matching. |
| `noBlueprintsFound` returns without diagnosis | Structured `CatalogDiagnostics` captures discovery, decode, every filter count/reason, and final candidate count. |
| Duplicate or incoherent stories | Persist composition/history per profile; hard compatibility and fingerprint rejection. |
| Turkish grammar or unsafe copy | Native editorial review plus placeholder/title/safety QA tests. |
| Reader/library migration loss | Dual-read, atomic file records, no destructive migration. |
| Overbuilding | One world, one age band, fixed eight pages, one offline provider; defer AI/CMS/analytics. |
| Existing package test failure | Remove Finder/resource-fork metadata or otherwise correct packaging before treating functional test results as valid. |

## Definition of done

A saved child completes the three-choice flow (or Surprise), receives a coherent Turkish eight-page offline story containing the choices, opens it from the cover and library after relaunch, and never sees technical content terminology. Runtime content is discoverable/strictly decoded, generation is seeded and validated, immediate duplicates are avoided, failures are family-readable, and all tests above pass. The visual layer remains optional and does not affect offline text-story success.
