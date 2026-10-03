# MagicPaper Kids — Cross-Compatibility Review (Phase 4)

**Date:** 2026-09-15
**Scope:** Stress-testing the three Phase 3 pilots against the shipped content inventory — 16 settings × 15 companions × 10 discovery-kinds = 2,400 combinations.
**Method:** Traits were assigned to every shipped content record, the pilots' stated rules were encoded, and the full cross-product was computed. Nothing in this report is asserted from inspection; every number is calculated. The model lives in the session scratchpad.

**Headline:** the pilots' *narrative* architecture survived. Their *compatibility* rules did not. Baseline coverage was 20.4% of the content space with **5 of 15 companions unusable by any pilot**, and three of my own nine published instantiations were rejected by their own blueprints. A vocabulary fix raises coverage to 46.0% and leaves one companion unusable, correctly.

---

## 1. The brief's five combinations

§28 of the brief specifies these as the reusability test.

| Combination | Baseline | After fixes (§4) |
|---|---|---|
| Forest + Fox + Light | B | **A, B** |
| Forest + Rabbit + Map | *none* | **C** |
| Mountain + Owl + Footprints | *none* | *orphan — needs Family IV/V* |
| Garden + Hedgehog + Sound | *none* | **A** |
| Sea + Dolphin + Shell | B | **B** |

**Three of five had no home at all.** That is a failing result for a set of blueprints claiming reusability, and it is the finding this phase exists to produce.

One of the three is *correctly* orphaned and should stay that way: footprints are `impliesPresence`, not `isUnexplained`, so they recruit Family IV (Absence) or V (Misreading), neither of which is built. A pilot set covering 3 of 6 families should leave gaps — but it should not leave gaps where a family it *does* cover is the obvious fit, which is what happened with the other two.

---

## 2. Coverage

| | Baseline | After fixes |
|---|---:|---:|
| Pilot A — Threshold | 105 combos · 3/15 companions | 280 · **8/15** |
| Pilot B — Unexplained | 198 combos · 6/15 companions | 330 · **10/15** |
| Pilot C — Appeal | 216 combos · 3/15 companions | 576 · **6/15** |
| **Union** | **489 / 2400 (20.4%)** | **1105 / 2400 (46.0%)** |
| Unusable companions | **5 of 15** | **1 of 15** |
| Unusable settings | 0 of 16 | 0 of 16 |

A blueprint that accepts 3 of 15 companions is not reusable — it is a story with three casting options. That was the state of two of the three pilots.

---

## 3. Findings

### F1 — CRITICAL · Five companions were unusable by any pilot

`Yonca` (timid rabbit), `Kıvılcım` (dragon), `Böğürtlen` (bear), `Pofuduk` (penguin), `Zıpzıp` (frog).

A third of the cast, dead. Most damning: **Yonca, the gentle-but-timid rabbit — arguably the single most natural companion in a 5–6 picture book — could not appear in any of the three stories.** Phase 1 criticised the old system for authoring fifteen differentiated personalities and then ignoring them. This set would have excluded five of them outright, which is a different failure with the same effect.

### F2 — CRITICAL · The trait vocabulary conflates intrinsic properties with castable roles

This is the architectural finding of the phase, and it is the root cause of F1, F3 and half of F4.

`isSmallAndVulnerable` is doing two incompatible jobs. Pilot C **requires** it ("someone small who cannot manage alone"). Pilot B **forbids** it ("a companion that needs looking after pulls attention away from thinking"). Both rationales are sound — but they are about different things:

- **small** is a physical property of the animal, true in every story;
- **needing care** is a part the animal is *playing in this story*.

`Pırıltı` the firefly is small in both. In my Pilot B instantiation it is a knowledgeable local guide; in my Pilot C instantiation it is the one who needs help. One trait cannot express that, so B excluded the firefly for a reason that is not true of it there — and my own published instantiation B③ violated the rule I had written two pages earlier.

**The fix is a vocabulary split:**

| | Declared by | Example | Blueprint uses it to |
|---|---|---|---|
| **Capabilities** | content, intrinsic | `canFly`, `canCarry`, `isSmall`, `isStrong`, `isQuick`, `isPatient`, `hasLocalKnowledge`, `isLiteralMinded` | **forbid** what would dissolve the conflict |
| **Castable roles** | content, as eligibility | `guide`, `needsCare`, `hesitant`, `reassuring` | **cast** the companion into a part |

A blueprint then says *I cast the companion as `needsCare`*, and content declares which parts each character can credibly play. The same firefly is a guide in one blueprint and a care-recipient in another — which is what a reusable content library is for.

This also resolves the tension Phase 1 identified without resolving: the fifteen personalities become *selection inputs* in a way the old `compatibleThemes` never could, because a personality maps naturally onto castable roles rather than onto themes.

### F3 — MAJOR · Pilot A's companion rule forced one emotional register

`companion [canReassure]` admitted four companions, one of which was then forbidden for `canCarry`. Three remained.

More importantly it was **narratively wrong**. The Threshold family has two equally valid companions: the steady one who is calm about the crossing, and the fellow-nervous one who is scared too and goes anyway. The second is arguably the better children's-book choice — and it is the one I wrote myself in instantiation A② ("Dikenli is careful too, which makes it a companion rather than a contrast") before excluding it by rule.

**Fix:** cast as `hesitant` **or** `reassuring`. The requirement is that the companion be *emotionally legible about the crossing*, not that it be soothing. Pilot A goes from 3 to 8 companions.

### F4 — MAJOR · Three of nine published instantiations violated their own blueprints

| | Combination | Status | Cause |
|---|---|---|---|
| A② | Kristal Mağara + Dikenli | rejected → **rule was wrong** | F3 — `canReassure` too narrow |
| B③ | Gizli Bahçe + Pırıltı | rejected → **rule was wrong** | F2 — trait conflation |
| C② | Gizli Bahçe + Pırıltı | rejected → **my test harness was wrong** | I labelled the discovery a "strange sound"; the pilot doc pairs it with a *fading glow* (`impliesNeed`), which passes |

Two genuine rule defects, one bookkeeping error on my side. All three would have gone unnoticed without computing the cross-product — I wrote both the rules and the instantiations and could not see the contradiction by reading.

That is the reusable lesson: **compatibility rules and worked examples must be checked against each other mechanically.** This belongs in CI, not in review.

### F5 — MAJOR · `hasDistance` does almost no work

Held by **12 of 16 settings**. A constraint satisfied by three-quarters of the library is not a constraint, and it was Pilot C's only setting requirement — so C's setting rule was effectively "any setting", while appearing to be selective.

The real requirement is **separation**: somewhere the companion belongs that it cannot currently reach. Distance creates that; so does a barrier. **Fix:** `hasDistance` ∨ `hasThreshold`, which is honest about the two ways separation arises. Pilot C reaches all 16 settings, and does so for a stated reason rather than by accident.

### F6 — MINOR · Trait distribution is lumpy at both ends

| Trait | Held by | Problem |
|---|---|---|
| `hasDistance` | 12/16 settings | too common to constrain (F5) |
| `hasLocalKnowledge` | 8/15 companions | borderline; acceptable |
| `isLiteralMinded` | 1/15 companions | only `Zip`; a rule referencing it selects one companion |

A useful rule of thumb for Phase 5: **a trait held by more than ~60% or by exactly one record is not carrying information.** Worth checking at content-load time and reporting, the same way the diversity gate reports.

### F7 — `Kıvılcım` the dragon remains unusable, and that is correct

Capabilities `canFly`, `canCarry`, `isStrong`. Pilot A forbids `canCarry` (a dragon that lifts the child across deletes the premise). Pilot C forbids it (a dragon that carries the lost creature home deletes the cooperation). Pilot B needs a `guide`, and an eager, clumsy dragon is not a knowledge source.

The dragon is not broken and the rules are not wrong. It belongs to **Family VI (The Charge)** — caring for something small — where its size and clumsiness are the subject rather than a shortcut.

Flagged anyway, because a dragon is a marquee companion for a children's app and cannot still be unusable after Phase 5. It is a concrete argument for which family to build next.

### F8 — Sameness: passes at the page level; the shape is audible

Pilot B across four accepted combinations:

| Combination | p2 evidence | p3 fact | p5 complication | p6 insight |
|---|---|---|---|---|
| Orman + Bilge + light | only after rain | owl knows the rain | digging finds no water | wet stones reflect low sun |
| Ay Yüzeyi + Zip + light | blinks 3-then-gap | nothing here makes light | they get *dimmer* when followed | a shadow crossing, not a signal |
| Mercan Resifi + Mavi + shell | glows in the current | dolphin knows its hours | ashore it stops | the water moving through it |
| Karlı Vadi + Cesur + sound | only at midday | valley warms then | silence when they arrive early | snow shifting as it thaws |

Every load-bearing page differs, and the *kind* of reasoning differs — optical, spatial, hydraulic, thermal. This is not noun-swapping, and it clears the bar the old corpus failed.

**But the shape is identical and a parent reading two in one week will hear it:** *noticed X · was told Y · tried and it half-worked · realised Z.* That is inherent to a family represented by a single blueprint. The answer is not to loosen Pilot B — it is Phase 5's 2–3 blueprints per family with genuinely different page-5/6 architectures (deduction vs. direct observation vs. having to ask). Loosening B would buy variety by giving up its identity, which is the §29 trap.

---

## 4. Recommended changes

Ordered by impact. All are vocabulary or rule changes; no pilot's narrative architecture changes.

1. **Split the companion vocabulary into capabilities and castable roles** (F2). Amends `BLUEPRINT_ARCHITECTURE.md` §8.1. Content declares which parts each character can play; blueprints cast rather than filter.
2. **Pilot A casts `hesitant` ∨ `reassuring`** (F3).
3. **Pilot B forbids the `needsCare` *casting*, not small companions** (F2).
4. **Pilot C requires separation — `hasDistance` ∨ `hasThreshold`** (F5).
5. **Enrich under-specified companions.** Four had only two traits; every animal here plainly affords more (`Yonca` knows the meadow, `Böğürtlen` knows the forest, `Pofuduk` waits, `Zıpzıp` knows the pond). **Minimum three capabilities and two castable roles per companion**, assigned by an editor who knows the characters.
6. **Add a trait-distribution check at content load** (F6): warn on any trait held by >60% or exactly one record.
7. **Add a CI check that every published instantiation satisfies its blueprint** (F4). This phase found two rule defects that way and would have shipped them otherwise.

Combined effect, computed: coverage 20.4% → **46.0%**, unusable companions 5 → **1**, unusable settings 0 → **0**, and 9 of 9 instantiations valid.

---

## 5. What Phase 4 did not test

- **Prose.** Still no Turkish text exists. Whether `insight` can be written in 18–38 words for a 5-year-old, repeatedly, without formula, is unproven — and Phase 1 showed the risk is real (four of five V1 files open that page identically).
- **Template supply.** How many variants per beat are needed before two books from one blueprint stop rhyming is unmeasured.
- **Intra-family distinctness.** All three pilots are from different families, where separation is guaranteed. The hard question is still open.
- **Pilot C's page-4 authoring constraint** (*the obstacle must not be soluble by the companion's own traits*) is still editorial. With the capability/role split it is now *partly* machine-checkable — the obstacle could declare which capability it defeats, and the selector could verify the companion lacks it. Worth designing in Phase 5.
- **The 54% of the content space with no blueprint.** Expected with 3 of 6 families, but Phase 5 must report this number per family rather than in aggregate.

---

## 6. Verdict

The three pilots pass the reusability test **after** the §4 changes, and fail it before them. The narrative architecture — beats, state, emotional arcs, the role/beat separation — held up under every test in this phase and needed no revision. What broke was the trait vocabulary, in a way that was invisible until computed: it could not distinguish what a character *is* from what a character is *doing in this story*.

That distinction is now the most important thing Phase 5 inherits.
