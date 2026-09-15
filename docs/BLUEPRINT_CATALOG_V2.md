# MagicPaper Kids — Blueprint Catalog V2 (Phase 5)

**Date:** 2026-09-15
**Status:** 14 blueprints, gate-verified. Content requirements use the Phase 4 capability/role vocabulary as approved.
**Scope:** Adventure · age 5–6 · 8 pages · Turkish.

**Gate results — computed, not asserted:**

| Check | Result |
|---|---|
| Reachability (every beat's preconditions met in order) | **14/14** |
| Liveness (no page produces state nothing later reads) | **14/14** |
| Pacing (anomaly by p2, resolve at p7, closing-only p8) | **14/14** |
| Intensity ceiling ≤ 2, max 2 consecutive, lands warm | **14/14** |
| Diversity gate across all 91 pairs | **0 violations** |
| Distinct resolution mechanisms | **14 of 14** |

---

## 1. What changed since Phase 3, and why

Phase 4's computed compatibility review and an independent adversarial QA pass together found nine defects serious enough to change the design. Expanding to 14 without fixing them would have multiplied each by five. All are resolved below; three remain open in §6.

| # | Defect | Resolution |
|---|---|---|
| 1 | Trait vocabulary conflated *what a character is* with *what it is doing* | Capability/role split (approved) |
| 2 | **Liveness was unenforced** — Pilot A's companion page, and page 5 of B and C, produced state nothing read. The engine would generate identical stories with those pages deleted | New validator Rule 2; four beat preconditions tightened. Caught two more inert family arcs (V, VI) on re-run |
| 3 | **No habitat axis** — nothing prevented a squirrel on a coral reef or a seashell in a snowy valley. Phase 1's own complaint, reproduced by its replacement | `habitat` added to settings, companions, discoveries |
| 4 | **`isUnexplained` is context-dependent** — a "mysterious" glowing light in a cave whose description says it is full of glowing stones | `explainedBy` on discoveries; a setting that trivially explains a discovery cannot host it |
| 5 | **Arc-uniqueness gate blocked Phase 5 by construction** — requiring wholly unused arcs meant only one blueprint per family could carry its family's signature | Gate relaxed to *arc separation ≥ 2 positions* |
| 6 | **Family II modelled unsafe behaviour** — incremental courage at water, height and dark enclosed spaces, with no adult present, is a rehearsal of overriding correct self-protective fear | §2.2: hazardous thresholds forbidden outright |
| 7 | Pilot B's worked examples needed 3-step inference against its own 1-step rule | §2.1 page contract rewritten |
| 8 | Pilot C's "child as taxi" failure was defeated only by ad-hoc authoring excuses | §2.3: the thing restored is never the companion's body |
| 9 | `ateşböceği` needed a possessive-stem flag and had none | Fixed in content; test added |

`hasDistance` was also **removed** as a trait: measured on 12 of 16 settings, it was a requirement satisfied by three-quarters of the library.

---

## 2. Cross-cutting rules by family

These bind every blueprint in the family and exist because QA found each failure mode already present in the pilots.

### 2.1 Family I — one inferential step, enforced structurally

A 5–6-year-old holds *this, therefore that*. Not *this, therefore that, therefore the other*. All three Phase 3 worked examples violated this while the blueprint claimed it.

**Page contract, binding:**
- **p2 supplies exactly ONE observation.** Not two.
- **p3 supplies exactly ONE fact, and it must be ordinary.** If the companion's fact is the surprising half, the reader credits the companion with the discovery regardless of who speaks the conclusion.
- **p5 is a failed application of the idea — never a third clue.**
- **p6 combines p2 and p3 and nothing else.** Any input not already on the page is a trick.

The child's observation carries the distinctiveness; the companion's fact is mundane. That ordering is what keeps the deduction the child's.

### 2.2 Family II — the threshold must be daunting, never dangerous

**Forbidden threshold kinds: `water`, `height`. Forbidden setting trait: `isHazardous`.**

A story in which a child feels afraid of fast water, takes a small step in, crosses, and is proud, is a story that rehearses overriding the exact hesitation that keeps small children safe. No emotional-safety rule catches this, because it is not about how the child feels.

**Permitted thresholds:** `opening` (a doorway, a hedge tunnel, a dim room), `span` (a bridge with sides, stepping stones in shallow still water), `social` (going first, being looked at, joining a group already playing).

`social` is the most valuable and the most under-used. A child who dreads going first is in exactly the Threshold structure with no physical hazard anywhere, and it is the version most 5-year-olds will recognise.

**On narrative pressure.** Phase 3's Pilot A forbade every source of pressure — no urging, no cost to waiting, nothing external changing — leaving four pages of a child not moving. Family II blueprints must supply **one gentle, non-coercive reason the crossing matters now**: the thing beyond is time-limited (it only happens at dusk), or someone is waiting without calling. Never a countdown, never a person urging.

**Turkish register, p4.** The reluctance is shown, not named. `Korkuyorum` makes fear the child's label for themselves; `İstemiyorum` reads as sulking and invites correction; `Çekiniyorum` is above register. The writable form is physical: *"Ayakları durdu."* / *"Bir adım geri gitti."* This also removes the shame risk that the naming rule was trying to manage.

### 2.3 Family III — the companion's body is never the cargo

Every companion this family admits is small enough for a five-year-old to pick up, so "just carry it" is always available and must be destroyed by invented excuse. All three Phase 3 examples did exactly that — including one that negated `canFly`, the very capability it had selected on.

**Binding rule: what must be restored is never the companion itself.** It is the companion's stored food, its nest, its way back for *next* time, something it dropped, something it must deliver. Carrying then solves nothing, and the obstacle needs no excuse.

**Cooperation must not collapse to *child = body, companion = directions*.** Two of three Phase 3 examples had the companion shouting which way while the child did the labour — satisfying the letter of the agency rule and inverting its spirit. In the resolving beat **the child's contribution must include a choice or an idea**, not only effort.

### 2.4 Family VI — release is not loss

`bp_charge_release_002` ends with the child letting go of something they cared for. This is only safe if the departure is **the good outcome, visibly** — the creature is well, it is going where it belongs, and the child chose the moment. No lingering, no last look, no ambiguity about whether it survives. The final emotional state is `calm`, not `warmth`, deliberately: the note is settledness, not consolation.

---

## 3. The catalog

Each entry: mechanisms · beat sequence · emotional arc · what it requires and forbids · title families · what makes it distinct from its nearest sibling.

Shared by all: `childSafety: .strict` · age band 5–6 · 8 pages · 18–38 words/page · max 14-word sentences · **max one level of subordination per sentence** (new — the word band constrains length but not syntax, and Turkish participial subordination is short in words and late in comprehension).

---

### FAMILY I — THE UNEXPLAINED · *cognitive conflict*

#### I-1 · `bp_unexplained_signal_001`
**insight** — two facts combine into one realisation.
`notice_anomaly · examine · meet+offers · form_belief+commit · first_attempt+obstacle_raises · insight · succeed · warm+carry_forward`
*ease → curiosity → wonder → puzzlement → determination → insight → satisfaction → warmth*

```
requires  setting   canConceal ∨ showsTraces
          companion cast as guide
          discovery isUnexplained ∧ (emitsSignal ∨ isFragmentary)
forbids   discovery impliesNeed;  setting explains the discovery (explainedBy)
          companion cast as needsCare
```
**Titles:** `T3_secret`, `T2_achievement`, `T1_pairing`
**Distinct from I-2:** I-1's answer is *worked out*; I-2's is *waited for*. Beat distance 5.

#### I-2 · `bp_unexplained_moment_002`
**patientObservation** — it only happens at one moment; the child has to be there for it.
`notice_anomaly · approach · meet+offers · commit · first_attempt · patient_wait · succeed · warm+self_recognize`
*ease → curiosity → wonder → determination → puzzlement → patience → delight → warmth*

```
requires  setting   isOpen ∨ hasWeather
          companion cast as guide
          discovery isUnexplained ∧ emitsSignal
forbids   discovery impliesNeed, isFragmentary
```
**Titles:** `T2_achievement`, `T1_pairing`
**Note:** the only Family I blueprint with no `form_belief` — the child never theorises, only attends. That is what makes waiting the mechanism rather than a delay.

#### I-3 · `bp_unexplained_askingout_003`
**seekingKnowledge** — nobody here knows; understanding requires going to find who does.
`notice_anomaly · examine · meet_companion · commit+obstacle_raises · first_attempt · ask_for_help · succeed · warm_close`
*ease → curiosity → puzzlement → determination → doubt → insight → satisfaction → warmth*

```
requires  setting   canConceal ∨ isTended
          companion cast as hesitant ∨ guide   (may openly not know)
          discovery isUnexplained ∧ isFragmentary
forbids   discovery impliesNeed
```
**Titles:** `T3_secret`, `T1_pairing`
**Distinct:** the only Family I blueprint where the companion's *not* knowing is the point — asking is a skill, and this is the blueprint that models it.

---

### FAMILY II — THE THRESHOLD · *internal conflict*
*Subject to §2.2 in full: no `water`, no `height`, no `isHazardous`.*

#### II-1 · `bp_threshold_crossing_001`
**incrementalCourage** — a smaller version first, then the whole thing.
`notice_anomaly · approach · meet_companion · hesitate · small_step · find_own_courage · succeed · self_recognize+warm`
*curiosity → wonder → hesitation → unease → determination → effort → relief → pride*

```
requires  setting   hasThreshold ∧ thresholdKind ∈ {opening, span, social}
          companion cast as hesitant ∨ reassuring
          discovery isBeautiful ∨ emitsSignal ∨ isUnexplained
forbids   companion canCarry, canFly, canSwim   (see below)
          setting   isHazardous;  discovery impliesNeed
```
**On forbidding `canFly`/`canSwim`:** Phase 3 permitted flight on the reasoning that it does not transfer to the child. QA was right that this is an adult abstraction. What a five-year-old sees is a friend who could obviously get across and doesn't help — and since this blueprint also forbids urging, the result reads as indifference. **The companion must be subject to the same barrier.** This resolves the contradiction with Architecture §8.3, which forbade both.

**Titles:** `T4_act`, `T5_journey`, `T1_pairing`

#### II-2 · `bp_threshold_joining_002`
**askingToJoin** — the barrier is being seen, and the way through is asking.
`notice_anomaly · examine · meet+offers · hesitate · prepare · ask_for_help · succeed · warm+carry_forward`
*curiosity → unease → hesitation → determination → doubt → effort → relief → pride*

```
requires  setting   isOpen ∨ isTended        (somewhere with others already in it)
          setting   thresholdKind = social
          companion cast as hesitant ∨ reassuring
          discovery isBeautiful ∨ emitsSignal ∨ impliesPresence
forbids   setting   isHazardous
```
**Reworked during Phase 6.** As first written (`preparation`, a physical threshold) this was the weakest blueprint in the catalog on every computed measure: beat distance 4 and arc separation 2 from II-1 — both exactly at threshold — and **only four eligible companions**, the narrowest in the library. Cutting it was the obvious move and the wrong one: it would have left Family II with a single blueprint, so every courage story in the product would share one shape.

Rebuilding it on the `social` threshold instead fixed all three problems at once. There is no physical barrier, so the `canFly`/`canSwim`/`canCarry` exclusions that squeeze II-1's cast do not apply — **the companion pool went from 4 to 11**. Distance from II-1 rose to beat 5 / arc 3.

It is also the better story. A child who wants to join a game already in progress and cannot make themselves walk over is in exactly the Threshold structure, with no hazard anywhere, and it is the version most five-year-olds will recognise from their own week. The resolution — asking — is a real skill at this age, and `ask_for_help` makes the child the one who acts while keeping the act social rather than physical.

**Distinct from II-1:** II-1's barrier is a place and the child crosses it alone; II-2's barrier is other people and the child resolves it by speaking. Beat distance 5, arc separation 3.

---

### FAMILY III — THE APPEAL · *relational conflict*
*Subject to §2.3: the companion's body is never the cargo.*

#### III-1 · `bp_appeal_reunion_001`
**cooperation** — two abilities, both necessary.
`notice_anomaly · approach · meet+receive_appeal · commit+obstacle_raises · first_attempt · cooperative_effort · restore · warm_close`
*ease → curiosity → sympathy → concern → determination → effort → relief → warmth*

```
requires  setting   hasThreshold ∨ canConceal
          companion cast as needsCare; capability hasLocalKnowledge ∨ isQuick ∨ isPatient
          discovery impliesNeed ∨ impliesPresence
forbids   companion canCarry
constraint  the obstacle must not be soluble by the companion's own capabilities,
            and must not be soluble by the child carrying the companion (§2.3)
```
**Titles:** `T1_pairing`, `T5_journey`

#### III-2 · `bp_appeal_speakingup_002`
**advocacy** — the child's contribution is to speak for someone who cannot.
`notice_anomaly · examine · meet_companion · take_charge+obstacle_raises · first_attempt · speak_for · restore · warm+carry_forward`
*ease → curiosity → sympathy → determination → doubt → effort → relief → pride*

```
requires  setting   isTended ∨ isOpen        (somewhere with others in it)
          companion cast as needsCare; capability isSmall
forbids   companion canCarry
editorial the companion does not voice its need — the child works out what is
          wrong. This is a casting instruction, not a capability filter:
          knowing the place and being able to say what hurts are different
          things, and conflating them cut this blueprint to two companions.
```
**Distinct:** the only blueprint in the catalog where the need is **never voiced** — `take_charge` replaces `receive_appeal`, because the companion cannot ask. The child works out what is wrong and says it on someone else's behalf. Beat distance 5 from III-1.

#### III-3 · `bp_appeal_sharing_003`
**givingSomethingUp** — the child solves it by giving up something of their own.
`notice_anomaly · examine · meet+receive_appeal · commit+obstacle_raises · tend · give_up_something · restore · warm+self_recognize`
*ease → curiosity → sympathy → concern → tenderness → effort → relief → pride*

```
requires  setting   isTended ∨ canConceal
          companion cast as needsCare; capability isSmall
          discovery impliesNeed
forbids   companion canCarry
safety    what is given up must be replaceable and freely given. No coerced
          sacrifice, no adult praising the child for going without.
```
**Distinct:** page 5 is `tend`, not `first_attempt` — the child cares for the companion before discovering that care alone is not enough. Beat distance 4 from III-1, 5 from III-2.

---

### FAMILY IV — THE ABSENCE · *uncertainty*

#### IV-1 · `bp_absence_search_001`
**persistence** — keep looking, methodically, after the first try fails.
`notice_anomaly · examine · meet+receive_appeal · commit+obstacle_raises · first_attempt · persist · restore · warm+carry_forward`
*ease → wonder → concern → determination → doubt → patience → relief → tenderness*

```
requires  setting   showsTraces ∨ canConceal
          companion cast as needsCare ∨ guide
          discovery impliesPresence ∧ isFragmentary
forbids   companion canFly     (searching from above ends the search)
```
**Titles:** `T2_achievement`, `T5_journey`
**This is the home for footprints** — the discovery-kind Phase 4 found orphaned by all three pilots.

#### IV-2 · `bp_absence_retracing_002`
**retracing** — the answer is behind you, not ahead.
`notice_anomaly · examine · meet+offers · commit+obstacle_raises · first_attempt · retrace · succeed · warm+self_recognize`
*ease → wonder → concern → determination → doubt → insight → relief → satisfaction*

```
requires  setting   showsTraces
          companion cast as guide
          discovery impliesPresence
forbids   discovery impliesNeed    (this is a puzzle, not a rescue)
```
**Distinct:** IV-1 searches *forward* and resolves by not giving up; IV-2 turns *around* and resolves by re-reading what was already passed. Different lesson, different page 6, beat distance 5.

---

### FAMILY V — THE MISREADING · *perceptual conflict*

#### V-1 · `bp_misreading_truth_001`
**revelation** — what the child was certain of turns out to be something else, and better.
`notice_anomaly · examine+form_belief · meet+offers · belief_fails+commit · first_attempt · reveal_truth · succeed · warm_close`
*curiosity → certainty → surprise → puzzlement → doubt → insight → delight → warmth*

```
requires  setting   canConceal ∨ showsTraces
          companion cast as guide
          discovery impliesPresence ∧ (isFragmentary ∨ isUnexplained)
forbids   discovery impliesNeed
safety    the mistaken belief must never be frightening, and the child is never
          foolish for holding it. The truth is warmer than the assumption.
```
**Titles:** `T3_secret`, `T1_pairing`
**The only arc that opens at `certainty`** — the misreading has to be established confidently before it can be gently overturned. That shape is what a reader feels as a different kind of story.

#### V-2 · `bp_misreading_twosides_002`
**perspectiveShift** — two of them each hold half the truth.
`notice_anomaly · approach+form_belief · meet+receive_appeal · belief_fails+commit · first_attempt · exchange_views · restore · warm+self_recognize`
*curiosity → certainty → surprise → concern → doubt → insight → relief → warmth*

```
requires  setting   isOpen ∨ isTended
          companion cast as needsCare ∨ hesitant
          discovery impliesPresence ∧ impliesNeed
forbids   companion isLiteralMinded   (needs a point of view to differ from)
safety    neither party is at fault and neither is corrected. Both were right
          about what they could see.
```
**Distinct:** V-1's misreading is about a *thing*; V-2's is between two *people*, and resolves by `restore` rather than `succeed`. Beat distance 5.

---

### FAMILY VI — THE CHARGE · *duration*

#### VI-1 · `bp_charge_tending_001`
**patience** — nothing blocks the child; it simply takes time and returning.
`notice_anomaly · examine · meet_companion · take_charge · tend · patient_wait · restore · self_recognize+warm`
*ease → surprise → tenderness → duty → effort → patience → pride → calm*

```
requires  setting   isTended ∨ canConceal
          companion cast as needsCare; capability isSmall
          discovery isFragile ∧ impliesNeed
forbids   companion canCarry
```
**The only blueprint that produces no `obstacleNamed`** — its conflict is duration, not difficulty, so the §7.4 pacing rule requiring an obstacle by page 5 does not apply. That exception was found by the checker failing, not by review.

#### VI-2 · `bp_charge_release_002`
**release** — the child cares for something, then lets it go.
`notice_anomaly · approach · meet+offers · take_charge · tend · let_go · restore · warm+carry_forward`
*ease → surprise → tenderness → duty → patience → effort → tenderness → calm*

```
requires  setting   isOpen ∨ isTended
          companion cast as needsCare; capability isSmall
          discovery isFragile ∧ impliesNeed
forbids   companion canCarry
safety    §2.4 in full. The departure is visibly the good outcome, the creature
          is well, and the child chooses the moment.
```
**Titles:** `T4_act`, `T1_pairing`
**Distinct:** VI-1 resolves by *keeping on*; VI-2 by *stopping*. The hardest blueprint in the catalog to write well and the one most worth having.

---

## 4. Coverage

Coverage was computed, not assumed — my first draft of this section claimed universal coverage and was wrong on two counts. The specific Phase 4 gaps:

| Phase 4 orphan | Now served by |
|---|---|
| Mountain + Owl + **Footprints** | IV-1 `persistence`, IV-2 `retracing` |
| **Kıvılcım** the dragon (unusable by all three pilots) | I-3 `seekingKnowledge`, V-2 `perspectiveShift` |
| Garden + Hedgehog + Sound | II-1, I-3 |
| **`isFragile` / `impliesNeed`** discoveries | III-3, VI-1, VI-2 |

The dragon lands in I-3 and V-2 rather than Family VI, which is where I first claimed it and was wrong: VI forbids `canCarry` and the dragon has it. Its actual homes are better ones — the eager, clumsy dragon who *does not know* (I-3) and who *has understood something wrongly* (V-2) use its personality rather than merely tolerating its size.

**Verified companion coverage** (computed over all 14 blueprints):

| | Result |
|---|---|
| Companions usable by no blueprint | **0 of 15** |
| Companions usable by only one blueprint | **0 of 15** — none can produce the same book forever |
| Blueprints with fewer than 3 eligible companions | **0 of 14** |
| Fewest eligible companions for any blueprint | **5** (II-1) |
| Most | 15 (I-3) · mean 9.0 |

Four clauses were corrected to reach this. `Yavaş` the turtle was unusable entirely — cast only as `reassuring`, while both Family II blueprints forbid `canSwim`; adding `guide` (a slow companion that knows the way is a guide) fixes it honestly. I-2 required a patient *companion* when the patience is the child's. II-2 cast only `reassuring`, leaving exactly one eligible companion. III-2 and VI-1 forbade `hasLocalKnowledge` to mean "cannot explain itself", conflating knowing with speaking.

**Bidirectional integrity is now a load-time check.** Phase 4's §8.4 asked only *does every blueprint have content?* It never asked *does every selectable content item have a blueprint?* — which is how the dragon became unusable while every check passed. Both directions are now required, and a companion reachable by only one blueprint is a warning, because a child who always picks the dragon would otherwise get the same book forever while novelty tracking reported success.

---

## 5. Honest combinatorics

Per Phase 1 §6.5, record counts are never the headline.

| Metric | Phase 1 | Now |
|---|---|---|
| Narratively distinct arcs | 1 | **14** |
| Distinct resolution mechanisms | 2 (across 5 blueprints) | **14 of 14** |
| Blueprints passing the diversity gate | 0 of 17 | **14 of 14**, 0 violations across 91 pairs |
| Unreachable content | 41% | 0% by construction (bidirectional check) |
| Pages that are structurally inert | 5 across 3 pilots | **0** |
| User choices observable in final text | 0 of 3 | 3 of 3 by requirement |

**No claim is made about story counts.** Multiplying blueprints by settings by companions produces a number that means nothing until templates exist, which they do not.

---

## 6. Still open

Stated plainly rather than deferred silently.

1. **No prose exists.** Fourteen architectures, zero Turkish words. Whether `insight` can be written in 18–38 words for a five-year-old, fourteen different ways, without formula, is the real remaining risk — and Phase 1 showed four of five V1 files opening that page identically.
2. **Template supply is unmeasured.** How many variants per beat before two books from one blueprint rhyme. This is Phase 6's first measurement and may force the catalog *down*, not up.
3. **The Family III page-4 constraint is still partly editorial.** §2.3 makes the taxi problem structural, but "the obstacle must not be soluble by the companion's own capabilities" still needs a human. It is now *partly* checkable: if the obstacle declares which capability it defeats, the selector can verify the companion lacks it. Recommended for Phase 6.
4. ~~II-1 vs II-2 is the closest pair~~ — **resolved in Phase 6** by rebuilding II-2 on a social threshold (beat 5, arc 3). The closest pair is now cross-family: I-2 `moment` vs IV-2 `retracing` at beat 3.
5. ~~Family II's `social` threshold is untested.~~ **Resolved** — it is now the basis of II-2.
6. **Product decision, unresolved since Phase 3:** Family III and V-2 end with `restore` — the ending belongs to someone other than the child. For a personalised book with the child's name on the cover this is deliberate and defensible, but it is the closest thing in the catalog to Phase 1's complaint that *the book is about the fox*. Five of fourteen blueprints end this way. Worth a decision before prose.
