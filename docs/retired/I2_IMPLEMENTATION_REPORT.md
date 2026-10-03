# I2 — Catalog Schema, Loader & Diagnostics — Implementation Report

**Date:** 2026-09-15
**Scope:** I2 only — content catalog domain models, strict loader, bundle discovery,
and integrity diagnostics. **No** `StoryProvider`, no selection/scoring, no narrative
assembly, no UI, no content rewriting, no cleanup, no removal of the legacy provider.
**Result:** ✅ Complete. 487 package tests pass (up from 413). App still builds.

---

## What was built

Nine new files under `StoryEngine/Sources/StoryEngine/Content/` — all package-owned,
Foundation-only, no UIKit, no network.

| File | Contains |
|---|---|
| `ContentPrimitives.swift` | `ContentID`, `ContentTag`, `AgeBand`, `PageRole`, `SelectionWeights` |
| `NarrativeStateExpression.swift` | `StateFact` (parses `"key=value"`), `NarrativeState` |
| `CatalogRecords.swift` | `CatalogSetting`, `CatalogCompanion`, `CatalogObject`, `CatalogEvent`, `CatalogChallenge`, `CatalogEnding` |
| `CatalogBlueprint.swift` | `CatalogBlueprint`, `BlueprintPageSlot` |
| `CatalogTemplate.swift` | `CatalogTemplate`, `CatalogVariant`, `ContentSlot` |
| `ContentCatalog.swift` | Root aggregate, lookups, vocabularies, fingerprint |
| `CatalogIntegrity.swift` | `CatalogIntegrityChecker`, `CatalogIssue`, `CatalogIntegrityReport` |
| `ContentCatalogLoader.swift` | Loader, `CatalogLoadReport`, `CatalogLoadError`, repositories |

Tests: `CatalogLoadingTests.swift` (20), `ContentPrimitiveTests.swift` (54).

---

## Design decisions worth knowing

**`ContentID` and `ContentTag` are distinct types.** The catalog links companions to
settings *by tag*, not by id. Conflating the two is precisely how the shipped catalog
ended up with `compatibleSettings: ["ocean"]` against a reef tagged `water` — a
reference that looks valid and silently never matches. Two types make that mix-up
unrepresentable.

**`PageRole` is a closed enum, and unknown roles fail to decode.** Every page must have
a narrative purpose; silently dropping an unrecognised role is how eight pages become
eight variations of one paragraph. It carries ten cases: the eight-beat MVP arc plus
`celebration` and `bedtimeTransition`, which exist as real authored templates. The
integrity check reports those two as unreachable rather than discarding the content.

**`ContentCatalog` is `Decodable` only, not `Codable`.** The catalog is authored — by
hand or by the development-time Content Creator — and never written by the runtime.
Declaring `Encodable` would imply a round trip the engine does not have and could not
honour for collections it does not model.

**Integrity issues are graded, not binary.** `fatal` blocks loading; `error` and
`warning` are reported and carried. This matters: the shipped catalog has 21 real
referential errors. Making those fatal would leave the engine unusable until the content
is rewritten; ignoring them is how a dolphin ends up in a forest. So the loader succeeds,
the report is explicit, and I8 fixes the content.

**No absolute-path fallback.** The prototype's loader falls back to
`/Users/batudemir/Desktop/…`, which is why it works on one Mac and cannot work on a
device. The new loader searches `Bundle.module` first, then other bundles, and records
every location it tried. If it fails, the error names them.

---

## Diagnostics: making "no blueprints" explainable

The original bug report was an unexplainable `noBlueprintsFound`. Nothing recorded
whether the resource was even found. Two structured records now close that gap:

- **`CatalogLoadReport`** — where the catalog came from (`packageBundle` / `otherBundle`
  / `memory` / `notFound(searched:)`), whether it decoded, the decode error if not, and
  the integrity report. `.summary` is one readable line.
- **`CatalogIntegrityReport`** — every issue with severity, code, offending record id and
  a plain-language message, plus record counts.

`CatalogLoadError` distinguishes `resourceNotFound(searched:)`, `unreadable`,
`undecodable` and `unusable(report:)` — four different failures that were previously one
opaque message.

Selection-funnel diagnostics (how a candidate pool becomes empty) belong to I3, not here.

---

## What the checker says about the catalog we ship

Run against the real bundled catalog:

```
Catalog loaded from shared_content_library_v2.json
12 blueprints, 52 templates — 0 fatal, 21 error, 256 warning
blueprints=12 challenges=15 companions=15 endings=10 events=20
objects=20 resolutions=0 settings=16 templates=52 variants=156
```

| Code | Severity | Count |
|---|---|---|
| `orphan_setting_tag` | error | **17** |
| `theme_without_templates` | error | **4** |
| `unused_declared_slot` | warning | 135 |
| `undeclared_slot` | warning | 106 |
| `no_title_patterns` | warning | 12 |
| `unreachable_template` | warning | 2 |
| `empty_collection` | warning | 1 |

**This independently reproduces `CONTENT_AUDIT.md` from code rather than by inspection**,
and adds a finding the audit did not have:

> **`requiredSlots` is unreliable and cannot be used for compatibility.**
> Across 156 variants there are 135 declared-but-unused slots and 106 used-but-undeclared
> ones. For example every `template_discovery_0_*` variant uses `{{companion.name}}`
> without declaring it. I3 must derive slots from the text, not from the declaration;
> I8 must resync them.

The 17 orphan tags are concrete: `ocean`, `night`, `city`, `house`, `park`, `pond`,
`rain`, `road`, `desert` are expected by companions/events/challenges but no setting
declares them. `companion_dolphin_001` can never legitimately match any setting.

The 4 uncovered themes — `calm`, `good_night`, `helping_others`, `trying_again` — have
components but no template can write them.

Nothing is fatal: every role the 12 blueprints ask for has templates, so the catalog can
still produce stories.

---

## Build and test results

| Check | Result |
|---|---|
| Package build | ✅ 0 errors |
| Package tests | ✅ **487 passed, 0 failures** (413 before I2, +74 new) |
| App build with I2 code | ✅ `BUILD SUCCEEDED`, 0 errors |

Per-suite: `StoryEngineTests` 377, `VisualSystemTests` 51, `CharacterEngineTests` 42,
`EngineFoundationTests` 17.

Test coverage added: bundle discovery and search order; package-bundle sourcing; record
counts; eight-beat arc on every blueprint; fingerprint stability; missing/malformed/empty
catalog handling; repository caching; every integrity rule (orphan tags, uncovered
themes, duplicate ids, page-count mismatch, variantless templates, slot mismatches,
unreachable templates); `AgeBand`, `ContentTag`, `PageRole`, `ContentSlot` and
`NarrativeState` semantics.

**Per your instruction, I wrote package-level unit tests only and no app-level tests.**

---

## Not done, deliberately

- **The duplicate catalog remains.** `shared_content_library_v2.json` still exists both
  as a flat app resource and inside `StoryEngine_StoryEngine.bundle`. Removing the app
  copy would break the legacy `TestOfflineTemplateStoryProvider`, which you asked me not
  to touch. The new loader reads the **package** copy; the legacy provider keeps reading
  the flat one. They are byte-identical today. This resolves when the legacy provider is
  retired (plan step #12).
- **The hard-coded developer path in `StoryGenerationManager.swift:1247` is untouched**,
  for the same reason. The new loader has no such fallback.
- No content was edited. V1 and V2 content are both preserved intact (D2).

---

## Known issues carried forward

| # | Issue | For |
|---|---|---|
| J1 | `requiredSlots` unusable as compatibility metadata (241 mismatches) | I3 derives from text; I8 resyncs |
| J2 | 17 orphan setting tags — some companions can never match a setting | I8 |
| J3 | 4 themes with content but no templates | I8 |
| J4 | No blueprint has title patterns; titles must be composed generically | I4 |
| J5 | `resolutions` declared but empty and unmodelled — counted, not typed | I8 defines it or drops it |
| J6 | Catalog duplicated in the app bundle | plan step #12 |
| J7 | fal.ai API key still hard-coded in three files, in git history | **Urgent, unchanged** |

---

## Ready for I3?

**Yes.** I3 (compatibility, blueprint scoring, narrative state, variant selection) has
what it needs:

- a typed, validated catalog with real lookups and vocabularies;
- `NarrativeState` and `StateFact` already modelled, with the catalog's `requiredState` /
  `stateChanges` / `stateRequirements` parsed;
- `SelectionWeights` (cooldown/novelty) carried on settings, companions and objects;
- a diagnostics pattern to extend with the selection funnel.

Two things I3 must respect, both learned here:

1. Derive slots from variant **text**, never from `requiredSlots`.
2. Compatibility is a **tag intersection** against `catalog.settingTagVocabulary` — and
   17 records currently cannot match anything. I3 must surface that as a typed empty-pool
   error with reasons, never fall back to an unfiltered pool.

**Stopping here. I3–I9 not started.**
