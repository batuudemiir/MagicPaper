# Schema Merge Plan — v3 corpus ⟷ pilot library

**Date:** 2026-09-15
**Snapshot:** 20:12. Both sides quiescent — the corpus session's last write was 18:20,
the engine session's 18:29.
**Question this answers:** two sessions produced overlapping content schemas. Which
survives, and what has to change in the engine to adopt it.

**Answer in one line:** they are not competing schemas, they are two layers. Take the
corpus session's *design* and the engine session's *runtime*, and the merge is ten
named deltas, of which two are blocking.

---

## 1. What exists on each side

| | Corpus session | Engine session |
|---|---|---|
| Design docs | Phases 3–6: pilot set, compatibility review (2,400 combinations computed), **14-blueprint catalog, gate-verified**, QA report (600-trial reading simulation) | this plan |
| Blueprints | 14 — on paper, no JSON | 5 — JSON, decoding, validated |
| Prose corpus | 6 beat files, **84 variants** (12–16 per beat) | 23 templates, **69 variants** (3 per beat) |
| Content records | traits assigned in the review model (in a scratchpad) | 5 settings / 5 companions / 5 discoveries, shipped and decoding |
| Runtime | none — the corpus is read only by its own test | loader, `BlueprintSelector`, `OfflineContentBinder`, `OfflineStoryComposer`, `TitleComposer` |
| Validator | rules specified, run in the authoring model | `BeatSequenceValidator` — 13 rules in CI |

The corpus session's six beats (`notice_anomaly`, `examine`, `meet_companion`, `commit`,
`first_attempt`, `warm_close`) are a **strict subset** of the engine session's 23. No beat
is lost in either direction; for those six their variants are four to five times denser.

---

## 2. Who wins what

| Layer | Winner | Why |
|---|---|---|
| Runtime and Swift types | **engine** | The other side has none. This is not a judgement of quality |
| Blueprint schema (the decoding shape) | **engine** | Same reason |
| The blueprint *set* — how many, which, what binds them | **corpus** | 14 gate-verified against 91 pairs, QA'd, with cross-cutting family rules. The engine's 5 were authored to cover a matrix, which is a weaker reason |
| Content-requirement vocabulary | **corpus** | Capability/role split, disjunction, habitat, `thresholdKind`, `explainedBy` — every one of these fixes something the engine's trait model gets wrong |
| Prose corpus (those 6 beats) | **corpus** | Denser, and gated structurally rather than by careful writing |
| Prose corpus (the other 17 beats) | **engine** | Only side that has any. Scaffolding until they are re-authored |
| Validator | **merge** | Engine has the harness; corpus found a rule it is missing (liveness) |

---

## 3. Three defects the corpus session found that are present in the engine

Verified by running the engine, not inferred from the documents.

**3.1 — No habitat axis.** The engine will put a dolphin in a forest. Run at 20:05:

```
Fısıldayan Orman + Köpük (yunus) + parlak bir deniz kabuğu
"Deniz Kabuğunun Sırrı"
p3: Yalnız değilmiş. Az ötede, Köpük adlı bir yunus onu izliyordu.
```

`BlueprintSelector` and `OfflineContentBinder` match narrative traits only. `setting.tags`
and `companion.compatibleSettingTags` exist on the records and **nothing reads them**.
This is Phase 1's original complaint, reproduced by its replacement — exactly as their
review says.

**3.2 — Family II carries no safety exclusion.** Their §2.2 forbids `water` and `height`
thresholds outright: a story where a child overrides fear of fast water, crosses, and is
proud rehearses overriding the hesitation that keeps small children safe. The engine's
`blueprint_threshold_crossing_001` forbids `canFly`/`canCarry` on the companion and
**nothing at all on the setting**. It is not reachable today — no shipped setting carries
both `hasThreshold` and `hasWater` — so the engine is safe by accident, not by rule.

**3.3 — Requirements cannot express disjunction.** `ContentRequirements` is a conjunction
of trait sets. **13 of their 14 blueprints** use `∨` (`canConceal ∨ showsTraces`,
`isUnexplained ∧ (emitsSignal ∨ isFragmentary)`). Without this, thirteen of fourteen
cannot be expressed at all.

A note on 3.3: the engine session already hit this and worked around it, by giving the
torn map an `isUnexplained` trait so a conjunction would do. That workaround was correct
in itself — it also resolved a genuine inconsistency, see §6 — but it was reaching for
disjunction and not finding it.

---

## 3b. Status — 2026-09-16

| Delta | State | Note |
|---|---|---|
| D1 disjunction | **done** | `TraitRequirement.anyOf`; bare arrays still decode |
| D2 capability/role | **done** | `CompanionRole`, cast resolved once per story and carried on the binding |
| D3 new axes | **done** | habitat, `ThresholdKind`, `isHazardous`, `explainedBy`; `hasDistance` retired |
| D4 naming | **done, by them** | the corpus already writes `discovery.name`; no file carries `produces`/`requires` |
| D5 variant gating | **done** | `castRoles`, `capabilityRequire/Forbid`, `settingTraits`, `discoveryTraits`, `register` |
| D6 lengthClass | **done** | per-beat bands parsed from `lengthClasses`, never assumed |
| D7 `move` | **decoded, unused** | the diversity scorer that would read it does not exist yet |
| D8 multi-file loader | **done** | 33 beat files; an unreadable one is **fatal**, not skipped |
| D9 liveness | **done** | severity-graded; two principled exemptions |
| D10 port the 14 | **open** | the last one, and the only one that is content rather than schema |

**One disagreement, recorded rather than resolved silently.** D3 retires `hasDistance`;
their F5 keeps it inside `hasDistance ∨ hasThreshold`. F5 is right that the real
requirement is *separation* and right that the trait as used was vacuous — but a trait
held by 12 of 16, placed in a disjunction with one held by most of the rest, constrains
less than it did, not more. Separation is a relation between a companion and where it
belongs; modelling it as a property of the place was the original error, and a disjunction
inherits it. Retired here; if the port needs it, that is the evidence and it comes back.

**Two runtime cautions learned the expensive way, both about trusting a green run.**
A test bundle embeds its own copy of the resource bundle and it can go stale, so a suite
can pass against content it never loaded — the pinned record counts in
`CatalogLoadingTests` exist to catch exactly that and have now caught it twice. And with
two sessions authoring at once, content can change *during* a run: a whole class of
apparent budget failures turned out to be files rewritten 23 seconds into the run. Both
sides now verify the bundle's file count and checksum the corpus either side of a suite.

---

## 4. The deltas

Ordered. **D1 and D8 are blocking**: until both land, the 14 blueprints can neither be
expressed nor verified.

### Phase A — schema (Swift types)

| # | Delta | Touches |
|---|---|---|
| **D1** | **Disjunction in `ContentRequirements`.** Add `anyOf: [Set<Trait>]` alongside the existing conjunction: admissible ⟺ `allOf ⊆ offered` ∧ `∀g ∈ anyOf: g ∩ offered ≠ ∅` ∧ `offered ∩ forbidden = ∅`. Blocks 13 of 14 | `ContentTraits.swift`, `CatalogBlueprint.swift` |
| **D2** | **Split `CompanionTrait`.** Their defect #1: the vocabulary conflates what a character *is* with what it is *doing*. Two enums — **cast role** (`guide`, `needsCare`, `hesitant`, `reassuring`) and **capability** (`canFly`, `canCarry`, `canSwim`, `isSmall`, `isQuick`, `isPatient`, `hasLocalKnowledge`, `isLiteralMinded`). The engine's current enum mixes all three kinds | `ContentTraits.swift`, `CatalogRecords.swift` |
| **D3** | **New axes.** `habitat` on settings, companions and discoveries (fixes 3.1); `thresholdKind ∈ {opening, span, social}` and `isHazardous` on settings (fixes 3.2); `explainedBy` on discoveries — a setting that trivially explains a discovery cannot host it. **Remove `hasDistance`**: measured on 12 of 16 settings, it is a requirement three-quarters of the library satisfies, so it filters nothing | `ContentTraits.swift`, `CatalogRecords.swift` |
| **D4** | **Naming.** Their `discovery.phrase` ⟷ the engine's `discovery.name`. Pick one; keep the engine's separate `discovery.title`, which they do not have and which titles need (`"Yeliz ve Kayıp Yırtık Harita"`, not `"…Kayıp yırtık bir harita"`). Drop the corpus files' file-level `produces`/`requires`: `StoryBeat` already declares both, and two copies will drift | corpus files, `OfflineStoryComposer.swift` |

### Phase B — runtime

| # | Delta | Touches |
|---|---|---|
| **D5** | **Variant-level gating** — `settingTraits`, `discoveryTraits`, `castRoles`, `capabilityRequire`, `capabilityForbid` on `CatalogVariant`, filtered at selection. This is the structural version of what the engine session did by hand: writing every variant to assume nothing. Their `arrives_from_above` simply requires `canFly`; the engine's fix was to delete flight from the prose entirely, which is weaker and loses the good sentence | `CatalogTemplate.swift`, `OfflineStoryComposer.swift` |
| **D6** | **`lengthClass` (`solo` / `paired`).** A variant is either a whole page or one half of a page shared with a supporting beat. The engine concatenates both beats blindly, which is what produced *"Ama … Ama …"* on page 4 and pages of uneven length. Their `commit` file is 10 paired / 2 solo because page 4 is shared in 8 of 9 blueprints — the corpus is written knowing this. **The single most valuable idea on their side** | `CatalogTemplate.swift`, `OfflineStoryComposer.swift` |
| **D7** | **`move`** — a named narrative move per variant (`sound_before_sight`, `body_notices_first`). The diversity key §12 needs and the engine has no equivalent of; its 3-variant templates repeat visibly | `CatalogTemplate.swift`, future scorer |
| **D8** | **Multi-file corpus loader.** One file per beat, merged into one `ContentCatalog`. Today `ContentCatalogLoader` reads exactly one document | `ContentCatalogLoader.swift`, `ContentCatalog.swift` |

### Phase C — validator

| # | Delta | Touches |
|---|---|---|
| **D9** | **Liveness rule.** No page may produce narrative state that nothing later reads. Their defect #2 — *"the engine would generate identical stories with those pages deleted"* — caught an inert companion page in their own Pilot A and two more inert family arcs on re-run. The engine's validator has 13 rules and not this one. Blocking, with D1: without it the 14 cannot be verified once ported | `BeatSequenceValidator.swift` |

### Phase D — content

| # | Delta | Touches |
|---|---|---|
| **D10** | Port the 14 blueprints to JSON; adopt the 6 v3 beat files; keep the engine's other 17 beats as scaffolding until re-authored. **The engine's 5 blueprints are superseded** — their 14 are better argued and gate-verified. Content records gain the D3 axes | `pilot_library_v1.json` → catalog, `v3/` |

---

## 5. Sequence

**D1 + D9 first.** Both are small and both are gates: without disjunction thirteen of the
fourteen cannot be written down, and without liveness there is no way to confirm they
still pass once they are. Then D2–D4, then B, then D10 last — porting content against a
schema still in motion is the expensive order.

A caution on D10: the 14 were gate-verified **in the authoring model, not in this
engine**. Porting them is also the first real test of whether the two validators agree.
Expect disagreements, and treat each as a finding rather than as a porting error — the
Family IV `resolutionBeat` correction in I2-R and the footprints/map trait clash in §6
both surfaced exactly this way.

---

## 6. One inconsistency already found and resolved

`BLUEPRINT_ARCHITECTURE.md` §8.2 gives footprints and the torn map **identical traits**
(`impliesPresence`, `isFragmentary`) and then assigns them different family sets — IV, V
for one and I, IV, V for the other. Recruitment *is* trait intersection, so that cannot
hold.

Resolved in the engine by giving the map `isUnexplained`: a map has to be *read*,
footprints do not. §8.2's table then holds exactly, and a test now pins that no two
discoveries share a trait set. **This should be carried back into the architecture
document**, and checked against the 14-blueprint catalog, which was written before the
fix.

---

## 7. Process

The two sessions were writing into one package concurrently. At 18:28 a test run failed
against `beat_warm_close.json` — written 13 seconds before its decoder was updated. It
was transient and resolved itself, and nothing was lost, but it was luck: the split
happened to be clean, with the corpus session in `Resources/templates/v3/` and `docs/`
and the engine session in `Sources/` and `Tests/`.

**That luck ends here.** Every delta in §4 is the corpus session's schema landing in the
engine session's Swift types. From D1 onward both sides want the same files.

Pick one before starting:

- **Serialise** — the corpus session stops, the engine session applies D1–D9, then
  authoring resumes against the new schema. Simplest, and the schema work is the smaller
  half.
- **Split by layer** — `Sources/` and `Tests/` belong to one owner, `Resources/` and
  `docs/` to the other, with the schema frozen in writing before either proceeds. Works
  only if D1–D4 are agreed up front, because they define the file format the corpus is
  authored into.

Everything is committed, so either choice is recoverable.

---

## 8. What this plan does not decide

- **Whether 14 is the right number.** Taken on their QA's authority, not re-verified here.
- **Whether the other 17 beats get the v3 treatment.** 12–16 variants × 17 beats is a
  large authoring job; the engine's 3-variant scaffolding works but repeats.
- **Habitat vocabulary contents.** D3 says settings, companions and discoveries need the
  axis; which habitats exist is a content decision.
- **fal.ai key rotation.** Unrelated and still outstanding: the key is in git history from
  `c435ebc`, and removing it from the working tree did not remove it from there.
