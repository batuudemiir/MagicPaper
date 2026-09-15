# I2-R — Catalog Revision to the Blueprint Architecture

**Date:** 2026-09-15
**Trigger:** `BLUEPRINT_ARCHITECTURE.md` (Phase 2) was written at 09:08 while I2 was
being built, and contradicts the schema I2 modelled. You approved it as the target and
directed that the pre-beat catalog stay loadable until replacements exist.
**Result:** ✅ Complete. **522 package tests, 0 failures** (487 before). App builds.

---

## What conflicted, and how each was resolved

| Architecture says | I2 had | Resolution |
|---|---|---|
| §3.4 Templates declare **beats**, not roles; role must not drive text selection | `CatalogTemplate.role` drove everything | Added `realizesBeat: StoryBeat?`. Role retained for layout/visual intent only |
| §3.2 A closed **28-beat** vocabulary with requires/produces | No beat concept at all | `StoryBeat` — 28 cases, each declaring `requires`/`produces` |
| §4 State is **derived**, never authored | `StateFact` parsed authored `"key=value"` into a string bag | `NarrativeStateKey` (10 booleans) + `DerivedNarrativeState`, computed from beats. Authored state removed from page slots |
| §4.3 Unmet precondition = **build failure** | Nothing checked it | `BeatSequenceValidator`; violations are **fatal** at load |
| §5 Blueprint carries family + mechanism triple; no authored state | Genre/theme strings, authored state | `NarrativeFamily` with curiosity/conflict/resolution mechanisms; `BlueprintPageSlot` now carries `beat`, `supportingBeat`, `emotion` |
| §7 Emotional arc with intensity ceiling | Nothing | `EmotionalState` (29 states, 4 intensity bands) + ceiling/landing/sustained-tension rules |
| §7.4 Pacing rules | Nothing | Implemented, including the Family VI `duration` exemption |

**Kept from I2 unchanged** — the loader was the hard part and it survives intact:
`ContentCatalogLoader`, `CatalogLoadReport`, `CatalogLoadError`, the integrity-checker
framework, repositories, `ContentID`/`ContentTag`, `AgeBand`, `ContentSlot`, and
`PageRole` (which §15 says to adopt as-is).

---

## The migration bridge

You chose "keep loadable until replacements exist". That required supporting both shapes
at once:

- `beat`, `supportingBeat`, `emotion`, `family` and `realizesBeat` are **optional**, so
  the current catalog decodes.
- Blueprints decode from either `pages` (beat-bearing) or `pageRoles` (pre-beat).
- The gap is **measured, not hidden**: `blueprint_without_beats`,
  `template_without_beat`, `blueprint_without_family`.
- Beat rules only apply to blueprints that *are* beat-authored — and there they are
  **fatal**, so authored content cannot ship incoherent.

Current catalog status: `usable: true`, 0 fatal, 23 error, 268 warning.

| Code | Severity | Count |
|---|---|---|
| `orphan_setting_tag` | error | 17 |
| `theme_without_templates` | error | 4 |
| `template_without_beat` | error | 1 *(covers all 52)* |
| `blueprint_without_beats` | error | 1 *(covers all 12)* |
| `unused_declared_slot` | warning | 135 |
| `undeclared_slot` | warning | 106 |
| `no_title_patterns` / `blueprint_without_family` | warning | 12 each |
| `unreachable_template` / `empty_collection` | warning | 2 / 1 |

Nothing in the shipped catalog is selectable under the beat model — correctly, since
none of it has beats. The offline path keeps working on the legacy provider meanwhile.

---

## Verification of the architecture itself

The document states all six reference arcs "were machine-checked against the beat table
and these rules". **That check now runs in CI.** All six families are transcribed
verbatim as fixtures and validated:

- ✅ every beat's preconditions met in order, for all six arcs
- ✅ every arc reaches `resolved`
- ✅ every arc stays within intensity ceiling 2 and lands settled or positive
- ✅ no arc holds intensity-2 tension for three consecutive pages
- ✅ all fifteen family pairs differ on all three mechanisms
- ✅ ten state keys, each produced *and* consumed by at least one beat
- ✅ exactly seven beats produce `solutionKnown`, and `commit` is the only disjunctive requirement

Also verified negatively — the validator rejects what it exists to prevent: resolving a
conflict never raised, unearned resolution, never resolving, resolving before page 7,
late anomaly, new work on the final page, a frightening page, an unsettled ending, and
three consecutive tense pages.

**The Family VI exemption is proved to be load-bearing:** the `charge` arc passes with
`conflictMechanism: .duration` and *fails* `obstacle_too_late` without it.

---

## One correction to the architecture

`§6` gives Family IV's signature as `persist → restore`. Treating the second half as the
resolution beat is wrong for that family: `restore` produces `resolved`, while `persist`
is what produces `solutionKnown`. `restore` is also shared with Family III — so keying
the diversity gate on it would make Families III and IV look alike, which is precisely
what the gate must not do.

I added `NarrativeFamily.resolutionBeat` (the mechanism beat) alongside `signatureBeats`
(as documented). They coincide in five families and diverge only in Absence. A test pins
that all six resolution beats are distinct.

This surfaced as a test failure, not by inspection — the same argument §7.4 makes for
running these checks in CI.

---

## Files

**New:** `NarrativeStateModel.swift`, `StoryBeat.swift`, `EmotionalArc.swift`,
`BeatSequenceValidator.swift`
**Revised:** `CatalogTemplate.swift`, `CatalogBlueprint.swift`, `CatalogIntegrity.swift`
**Unchanged:** `ContentCatalogLoader.swift`, `ContentCatalog.swift`, `ContentPrimitives.swift`,
`CatalogRecords.swift`, `NarrativeStateExpression.swift` *(`StateFact` retained only for
decoding legacy event/challenge fields; it no longer feeds narrative state)*

**Tests added:** `BeatVocabularyTests` (19), `BeatSequenceValidatorTests` (10),
`CatalogBeatMigrationTests` (6).

---

## Known issues

| # | Issue | For |
|---|---|---|
| R1 | Nothing in the shipped catalog has beats — no blueprint is selectable under the new model | Phase 3 pilots |
| R2 | `StateFact` still decodes legacy `requiredState`/`stateChanges` on events/challenges but feeds nothing. Dead weight until those records are re-authored | I8 |
| R3 | 17 orphan setting tags, 4 uncovered themes (unchanged from I2) | I8 |
| R4 | `requiredSlots` unreliable — 241 mismatches; derive slots from text | I3 |
| R5 | **Turkish suffix resolver blocker** — §16 flags that it lacks the cases `T2_achievement`/`T3_secret` need and *silently emits ungrammatical output rather than failing*. §16 says this gates Phase 3 | Before pilot titles |
| R6 | fal.ai API key still hard-coded in three files, in git history | **Urgent** |

---

## Ready for I3?

**Yes, with one caveat.** I3 (compatibility, scoring, variant selection) now has the
right foundation: a beat vocabulary, derived state, a validator, and families with
mechanism triples.

The caveat is R1: **I3 can be built but cannot be exercised end-to-end on real content**
until at least one Phase 3 pilot blueprint exists. The migration tests include a working
beat-authored pilot as a fixture, so I3 can be developed and tested against that.

Sequencing question worth your call: I3 (selection engine) and Phase 3 (pilot authoring)
are now mutually unblocking — I3 has no content to select, and pilots have no engine to
run in. Either order works; authoring one pilot first would let I3 be validated against
real content rather than a fixture.

**Stopping here. I3 not started.**
