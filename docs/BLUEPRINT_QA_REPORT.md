# MagicPaper Kids — Blueprint QA Report (Phase 6)

**Date:** 2026-09-15
**Subject:** The 14-blueprint catalog in `BLUEPRINT_CATALOG_V2.md`.
**Method:** Every quantitative claim here is computed — beat/state traces, diversity distances, companion coverage, and a 600-trial reading simulation. Title quality is tested against the real `TurkishGrammar` in the engine, not evaluated on paper.

**Verdict: 14 of 14 approved**, one after a rework that QA forced. Two findings change production planning; four risks remain open and are named in §7.

---

## 1. Scoring rubric

Per the brief's §27, ten dimensions at 0–5. **Threshold for approval: ≥ 3 on every dimension and ≥ 35/50 overall.** A blueprint below threshold is reworked or cut — never approved to hit a count.

Six dimensions are computed; four are editorial judgement and marked as such.

| Dimension | How it is scored |
|---|---|
| Narrative distinctiveness | *computed* — beat distance to nearest neighbour |
| Reusability | *computed* — eligible companions of 15 |
| Emotional arc | *computed* — arc separation + shape |
| Content flexibility | *computed* — setting × discovery breadth |
| State coherence | *computed* — reachability + liveness + pacing |
| Pacing | *computed* — anomaly by p2, resolve p7, closing-only p8 |
| Child agency | editorial — who performs the resolving beat |
| Ending quality | editorial — earned, and belongs to the right person |
| Turkish quality | editorial — writability at 18–38 words, register risk |
| Age suitability | editorial — intensity, safety, developmental fit |

---

## 2. Headline finding: template supply

This was the question Phase 5 deferred, and the answer changes content planning.

### 2.1 The rhyme model

Two books from the same blueprint share page text at a rate of roughly `8 / V`, where V is variants per beat:

| V per beat | Expected shared pages of 8 | |
|---:|---:|---|
| 3 | 2.67 | **reproduces the shipped system** (Phase 1 measured ~3.7) |
| 5 | 1.60 | noticeable |
| 8 | 1.00 | acceptable |
| 12 | 0.67 | good |

### 2.2 Exposure is uneven, and flat allocation wastes a third of the budget

Three beats — `notice_anomaly`, `meet_companion`, `warm_close` — appear in **all 14 blueprints**. Twelve beats appear in exactly one. A reader meets the first group in every book and the second in one blueprint's worth. Allocating variants evenly therefore over-writes the rare beats and under-writes the common ones.

Simulated over a child's first 20 books, 600 trials:

| Policy | Corpus | Sentences seen 3+ times | Shared pages, consecutive books | Worst-case repeats |
|---|---:|---:|---:|---:|
| flat 3 | 99 | 22.7 | 1.50 | 9.9 |
| flat 8 | 264 | 17.2 | 0.57 | 5.7 |
| flat 12 | 396 | 11.5 | 0.38 | 4.7 |
| **tiered** | **262** | **10.0** | **0.34** | **4.3** |

**Tiered allocation beats flat-12 on every measure using 34% less content.** This is the single most actionable number in the phase.

### 2.3 Recommended allocation

| Beat exposure | Variants each | Beats |
|---|---:|---:|
| 14/14 blueprints | 16 | 3 |
| 7–9/14 | 12 | 6 |
| 4–6/14 | 8 | 5 |
| 2–3/14 | 6 | 7 |
| 1/14 | 5 | 12 |

**Total: 262 variants across 33 beats.**

For scale: V1 already contains **288 unique Turkish variants** at a comparable length (median 23 words). The corpus needed is roughly the size of the corpus that exists. That is a strong argument that harvesting V1 — rather than writing from zero — is viable, and it is the cheapest path to a shippable library.

**Caveat, stated plainly:** those 288 variants are welded to specific stories, and the harvest yield is unmeasured. A variant that says *"the fox was afraid of the dark passages"* realizes no beat in this vocabulary and cannot be re-slotted. Measuring actual yield is the first task of implementation, not a QA assertion.

---

## 3. Title architecture — tested against the real engine

Titles were hardcoded to `"{child} ve {companion}"` in the shipped app. This is the first end-to-end exercise of the five title families, run as Swift tests against `TurkishGrammar`.

**6 test cases, 0 failures.** Coverage:

- **`T2_achievement` across all eight setting shapes** — plain consonant-final, vowel-final, front and back harmony, and all four possessive-stem settings. *Yeliz'in Fısıldayan Orman'daki Büyük Keşfi* · *Yeliz'in Bulut Krallığı'ndaki Büyük Keşfi* · *Yeliz'in Gizli Bahçe'deki Büyük Keşfi*.
- **`T4_journey` dative** across the same shapes — *Kristal Mağara'ya*, *Yıldız İstasyonu'na*, *Eski Taş Köprü'ye*.
- **`T5` companion genitive** across all four vowel classes — *Kıpır'ın*, *Bilge'nin*, *Pofuduk'un*, *Zip'in*.
- **`T3` with a common-noun discovery phrase** — *kayıp haritanın*, correctly without an apostrophe.
- **Child-name genitive across nine names** including both capital I forms — *Irmak'ın* (back) and *İnci'nin* (front), the case the original resolver inverted.
- **All five families render clean** — no unresolved token, no unrecognised suffix.

Every expected string was correct on the first run. The title layer is the only part of the system currently proven end to end, because it is the only part where content, grammar and engine all exist.

---

## 4. Blueprint scores

Computed dimensions shown; editorial dimensions assessed against the family rules in catalog §2.

| Blueprint | Fam | Dist | Reuse | Arc | Flex | State | Pace | Agency | End | Turkish | Age | **Total** |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `unexplained_moment_002` | I | 4 | 5 | 5 | 5 | 5 | 5 | 4 | 4 | 4 | 5 | **46** |
| `unexplained_askingout_003` | I | 4 | 5 | 4 | 5 | 5 | 5 | 5 | 4 | 4 | 5 | **46** |
| `misreading_truth_001` | V | 4 | 5 | 4 | 4 | 5 | 5 | 5 | 5 | 4 | 5 | **46** |
| `unexplained_signal_001` | I | 4 | 5 | 4 | 4 | 5 | 5 | 5 | 4 | 3 | 5 | **44** |
| `absence_search_001` | IV | 4 | 5 | 4 | 5 | 5 | 5 | 5 | 4 | 4 | 5 | **46** |
| `absence_retracing_002` | IV | 3 | 5 | 4 | 4 | 5 | 5 | 5 | 4 | 4 | 5 | **44** |
| `threshold_joining_002` | II | 4 | 5 | 4 | 4 | 5 | 5 | 5 | 5 | 4 | 5 | **46** |
| `misreading_twosides_002` | V | 4 | 4 | 4 | 4 | 5 | 5 | 4 | 5 | 4 | 5 | **44** |
| `charge_release_002` | VI | 4 | 3 | 4 | 4 | 5 | 5 | 5 | 5 | 4 | 4 | **43** |
| `charge_tending_001` | VI | 3 | 3 | 4 | 4 | 5 | 5 | 5 | 5 | 4 | 5 | **43** |
| `appeal_reunion_001` | III | 3 | 3 | 3 | 4 | 5 | 5 | 4 | 4 | 4 | 5 | **40** |
| `appeal_sharing_003` | III | 3 | 3 | 3 | 4 | 5 | 5 | 5 | 5 | 4 | 4 | **41** |
| `appeal_speakingup_002` | III | 3 | 3 | 3 | 3 | 5 | 5 | 5 | 5 | 3 | 5 | **40** |
| `threshold_crossing_001` | II | 4 | 3 | 3 | 3 | 5 | 5 | 5 | 5 | 3 | 4 | **40** |

**All 14 clear the threshold** (≥3 everywhere, ≥35 total). Range 40–46; mean 43.5.

### 4.1 The rework QA forced

`bp_threshold_readying_002` scored **7/15 on computed dimensions — the weakest in the catalog by a clear margin**. Beat distance 4 and arc separation 2 from its only sibling, both exactly at threshold, and **four eligible companions**, the narrowest in the library.

Cutting it was the obvious move and would have been wrong: Family II would have dropped to one blueprint, making every courage story in the product share a single shape — precisely the sameness failure Phase 4 warned about for one-blueprint families.

Rebuilding it on the **`social` threshold** — the variant flagged as untested and most recognisable in catalog §2.2 — fixed all three problems simultaneously. With no physical barrier, the `canFly`/`canSwim`/`canCarry` exclusions do not apply, and **the companion pool went from 4 to 11**. Distance from II-1 rose to beat 5 / arc 3. It now scores 46.

It is also simply the better story: a child who wants to join a game already in progress and cannot make themselves walk over is in the Threshold structure with no hazard anywhere, and asking is a real five-year-old skill.

### 4.2 The weakest approved blueprints

**`threshold_crossing_001` (40)** — the narrowest cast in the catalog at 5 companions, because it must forbid `canCarry`, `canFly` and `canSwim` so the companion cannot bypass the barrier the child is facing. Its Turkish score is 3 because of the page-4 register problem: the reluctance must be shown physically (*"Ayakları durdu."*) rather than named, and that is a narrow band to write 16 different ways. **Watch item for prose.**

**The three Family III blueprints (40, 40, 41)** — all sit at beat distance 3 from a Family IV blueprint and arc separation 2 from each other. They pass, but Family III is the most crowded region of the catalog. If any two books ever read as the same story, it will be here.

---

## 5. Agency audit

The resolving beat of every blueprint, and who performs it:

| Beat | Blueprints | Child's act |
|---|---|---|
| `insight` | I-1 | works it out |
| `patient_wait` | I-2, VI-1 | chooses to wait and return |
| `ask_for_help` | I-3, II-2 | asks — an act, not a passivity |
| `find_own_courage` | II-1 | goes |
| `cooperative_effort` | III-1 | contributes the half only they have |
| `speak_for` | III-2 | says what the other cannot |
| `give_up_something` | III-3 | gives |
| `persist` / `retrace` | IV-1, IV-2 | keeps on / turns back |
| `reveal_truth` / `exchange_views` | V-1, V-2 | sees / listens and re-sees |
| `let_go` | VI-2 | releases |

**In all 14 the child is the agent.** No companion performs a resolving beat — which the beat table enforces rather than merely encouraging, since every producer of `solutionKnown` is a child action.

Two remain editorial rather than structural, both flagged in catalog §2:
- Family I's page 3 gives the companion a fact. The rule that the fact must be *ordinary* while the child's observation carries the distinctiveness is not machine-checkable.
- Family III's cooperation must include a choice or idea from the child, not only labour. Also editorial.

---

## 6. Safety audit

| Check | Result |
|---|---|
| Intensity ceiling ≤ 2 | 14/14 |
| Max 2 consecutive high-tension pages | 14/14 |
| Lands at intensity ≤ 1 | 14/14 |
| `childSafety: .strict` | 14/14 |
| Hazardous thresholds (water, height, `isHazardous`) | **0** — forbidden family-wide since Phase 5 |
| Companion in danger | 0 — Family III restricted to inconvenience |
| Permanent loss | 0 — Family VI's release is a departure, not a bereavement |
| Child blamed for the problem | 0 |

The one finding that needed a structural fix rather than a rule was Family II modelling risk-taking at water and height. It is now forbidden at the trait level, not the editorial level, because an editorial rule would not have caught it — the Phase 3 safety section was the tightest in the set and missed it entirely, since it reasoned about the child's feelings and never about what the child learns to do.

**Unresolved safety-adjacent item:** `charge_release_002` scores 4 on age suitability rather than 5. Letting go of something you cared for is developmentally valuable and emotionally real, but it is the only blueprint where a poorly written page 6 could read as loss. Catalog §2.4 constrains it tightly. It should be the last blueprint written and the first one user-tested.

---

## 7. Residual risks

Ordered by how much they could still cost.

1. **No prose exists.** Fourteen architectures, zero Turkish words. Every Turkish score above is a *writability estimate*, not a measurement. The catalog is a hypothesis until a beat has 16 variants that do not rhyme.
2. **V1 harvest yield is unmeasured.** §2.3 shows the corpus needed is about the size of the corpus that exists, which is encouraging and unproven. Variants with species and settings welded into the sentence cannot be re-slotted.
3. **Family III is crowded.** Three blueprints at beat distance 3 from Family IV and arc separation 2 from each other. First place to look for duplication once prose exists.
4. **`threshold_crossing_001`'s page 4 has a narrow writable band.** Showing reluctance physically, 16 different ways, without naming fear and without shame.
5. **Two agency rules are editorial, not enforced** (§5). At volume, editorial rules decay.
6. **The `restore` ending question is still open** — now 6 of 14 blueprints end with the resolution belonging to someone other than the child. Deliberate, defensible, and still a product decision nobody has made.

---

## 8. Definition of done for the next phase

Before any JSON ships:

- [ ] Measure actual V1 harvest yield per beat. If a common beat cannot reach 12 variants from harvest, it is written from scratch — budget for it.
- [ ] Write one beat to full tiered supply (16 variants of `notice_anomaly`) and check it against the existing repetition validator. That validator already enforces `maximumRepeatedNGrams: 0` and would have blocked the shipped corpus; it is the cheapest possible early warning.
- [ ] Re-band the age rules to 18–38 words (the shipped band demands 40–130 and **every existing variant fails it**).
- [ ] Add the subordination-depth rule — the word band constrains length but not syntax, and Turkish participial subordination is short in words and late in comprehension.
- [ ] Wire `ValidationRules` into the offline generation path. It exists, it is correct, and nothing calls it.
- [ ] Persist seed and every selected content ID in provenance, so a book can be reproduced and explained.
- [ ] Resolve the `restore` ending question (§7.6).

---

## Appendix — what QA actually ran

| Check | Scope | Result |
|---|---|---|
| Beat reachability | 14 blueprints × 8 pages | 14/14 |
| State liveness | 14 blueprints | 14/14 (found 5 inert pages in the Phase 3 pilots) |
| Pacing rules | 14 blueprints | 14/14 |
| Emotional arc intensity | 14 arcs | 14/14 |
| Diversity gate | 91 pairs | 0 violations |
| Companion coverage, both directions | 14 × 15 | 0 unusable, 0 single-blueprint, min 5, mean 9.0 |
| Reading simulation | 20 books × 600 trials × 4 policies | tiered allocation selected |
| Title rendering | 5 families × 8 settings, 5 companions, 9 child names | 6 tests, 0 failures |
| Engine regression | full package | 590 tests, 0 failures |
