# MagicPaper Kids — Blueprint Architecture (Phase 2)

**Date:** 2026-09-15
**Status:** Design for review. No content authored, no code written.
**Input:** `retired/BLUEPRINT_AUDIT.md` (Phase 1). Six families and the discovery-kind model approved.
**Output of this phase:** the blueprint schema, beat vocabulary, state philosophy, compatibility semantics, emotional-arc rules, title architecture, and the diversity gate — everything Phase 3 needs to author pilots against.

---

## 0. What this architecture has to prevent

Phase 1 found one root cause and a set of symptoms. The design is judged by whether each symptom becomes **structurally impossible** rather than merely discouraged.

| Phase 1 finding | Structural prevention | Section |
|---|---|---|
| Blueprints carry no narrative information | Blueprint declares mechanisms, beats, arc; a blueprint without them fails to decode | §5 |
| Per-page random sampling has no memory | Page slots require *beats*; beats have preconditions; selection reads state | §3, §4 |
| `attempt` page contains no attempt | A sentence that realizes no beat cannot be selected for a beat slot | §3 |
| "Everything worked out" — unearned resolution | `succeed`/`restore` require `solutionKnown`, producible only by a caused action beat | §4.3 |
| 41% of content unreachable | State is *derived from beats*, not authored — unreachability cannot be expressed | §4 |
| Child is a bystander | Every beat that produces `solutionKnown` has the child as agent; enforced at authoring | §3.3 |
| Companion personality ignored | Companion traits are *selection inputs*, not decoration | §8 |
| Same sentence on 4 of 8 pages | Repetition validator (already built, already correct) runs on the offline path | §11 |
| Three user choices inert | Blueprint requires a discovery-kind by trait; selection binds all three or fails | §8 |
| Titles hardcoded | Blueprint declares title families; no runtime string concatenation | §9 |
| Five blueprints, two mechanisms | Diversity gate rejects at authoring time | §12 |

---

## 1. Design principles

**P1 — The blueprint is a contract, not a container.**
It states what must be true of a story, never what the story says. Every field is either a constraint the engine can check or a requirement the content must satisfy. If a field cannot be validated, it does not belong in the blueprint.

**P2 — Cross-page dependency is the story.**
A story is the dependency between its pages. Any layer sampled without context cannot hold one. Therefore page selection must read state, and state must be produced by earlier pages.

**P3 — Constraints create identity.**
A blueprint that permits everything is not a blueprint (§29 of the brief). Each blueprint *forbids* things, and what it forbids is most of what makes it recognisable.

**P4 — Derive rather than author.**
Every hand-authored field is a field that can drift out of sync. State is derived from beats. Compatibility is derived from trait intersection. Intensity is derived from the emotional arc. Authors write the story shape; the engine computes the bookkeeping.

**P5 — Reuse the engine that already exists.**
`ChildSafetyPolicy`, `ValidationRules`, `AgeBandRule`, `SemanticVersion`, `TemplateRef` and the composition-rule vocabulary are already correct and already shipped. The offline path bypassed them; that is the defect. This architecture adds no parallel safety or validation model.

---

## 2. The layer model

Five layers. Each answers exactly one question, and no layer may answer another's.

| Layer | Answers | Owns | Never contains |
|---|---|---|---|
| **Blueprint** | *What kind of transformation happens?* | mechanisms, beat sequence, arc, constraints, title families, safety ceiling | nouns, prose, IDs |
| **Content** | *Who, where, what?* | settings, companions, discovery-kinds, objects, events, endings — each with traits | narrative structure |
| **Template** | *How is this beat said?* | Turkish prose variants, each declaring the beat it realizes | story structure, selection logic |
| **Selection** | *Which of these, for this child, now?* | trait intersection, state gating, novelty, seed | content, prose |
| **Personalization** | *How does it become this child's?* | name, suffixation, age-band register | anything else |

The reader sees prose. The editor works in Blueprint and Template. The engineer works in Selection. **No layer needs to understand another's vocabulary** — which is the property the current system lacks, and why narrative meaning leaked into the template layer where it could not survive.

---

## 3. Page role vs. story beat

This is the central mechanism of the architecture, and the direct answer to the brief's §5 and to Phase 1 §3.

### 3.1 Role is the spine; beat is the variable

**Page role** is fixed for the MVP — the eight the brief names and the five best V1 files already use:

`hook · discovery · companion · problem · attempt · challenge · resolution · emotionalEnding`

A closed enum. It says what a page is *for*. It is not enough on its own — Phase 1 §1.3 showed all eight roles correctly named and none of them performed.

**Story beat** says what *happens*. It is also a closed enum (§3.2). A page slot binds one required beat plus an optional supporting beat.

The consequence, and the whole point:

> **The same role carries a different beat in every family.**

| Page 4 · role `problem` | Beat | What the page is |
|---|---|---|
| Family I — Unexplained | `form_belief` | the child works out what the thing might mean |
| Family II — Threshold | `hesitate` | the child stops; the reluctance is named |
| Family III — Appeal | `receive_appeal` | the need is stated aloud |
| Family V — Misreading | `belief_fails` | what the child assumed stops fitting |
| Family VI — Charge | `take_charge` | the child accepts responsibility |

Five genuinely different pages, one role. This is what the previous system could not express, and why twelve blueprints collapsed into one story.

### 3.2 Beat vocabulary

Twenty-eight beats, closed. Each declares what it requires and what it produces (§4). Authors compose; they never invent.

| Group | Beat | Requires | Produces |
|---|---|---|---|
| **Orientation** | `establish_ordinary` | — | — |
| | `notice_anomaly` | — | `anomalyKnown` |
| | `approach` | `anomalyKnown` | — |
| | `examine` | `anomalyKnown` | — |
| **Relational** | `meet_companion` | — | `companionPresent` |
| | `companion_offers` | `companionPresent` | — |
| | `receive_appeal` | `companionPresent` | `needKnown` |
| | `commit` | `anomalyKnown` ∨ `needKnown` | `committed` |
| **Belief** | `form_belief` | `anomalyKnown` | `beliefFormed` |
| | `belief_fails` | `beliefFormed` | `obstacleNamed` |
| | `reveal_truth` | `beliefFormed` | `solutionKnown` |
| **Effort** | `first_attempt` | `committed` | `attemptMade` |
| | `obstacle_raises` | `committed` | `obstacleNamed` |
| | `insight` | `beliefFormed` ∧ `attemptMade` ∧ `obstacleNamed` | `solutionKnown` |
| | `cooperative_effort` | `companionPresent` ∧ `obstacleNamed` ∧ `attemptMade` | `solutionKnown` |
| | `persist` | `attemptMade` ∧ `obstacleNamed` | `solutionKnown` |
| | `ask_for_help` | `companionPresent` ∧ `obstacleNamed` | `solutionKnown` |
| **Internal** | `hesitate` | — | `hesitationNamed`, `obstacleNamed` |
| | `small_step` | `hesitationNamed` ∧ `companionPresent` | `attemptMade` |
| | `find_own_courage` | `hesitationNamed` ∧ `attemptMade` ∧ `obstacleNamed` | `solutionKnown` |
| **Care** | `take_charge` | `anomalyKnown` | `committed`, `needKnown` |
| | `tend` | `committed` | `attemptMade` |
| | `patient_wait` | `attemptMade` | `solutionKnown` |
| **Closing** | `self_recognize` | `resolved` | — |
| | `succeed` | `solutionKnown` | `resolved` |
| | `restore` | `solutionKnown` ∧ `needKnown` | `resolved` |
| | `warm_close` | `resolved` | — |
| | `carry_forward` | `resolved` | — |

The vocabulary was derived by writing out all six family arcs and keeping only beats that at least one arc needs. `belief_fails` and `find_own_courage` exist because Families V and II could not be expressed without them. Nothing here is speculative.

### 3.3 The agency rule

Seven beats produce `solutionKnown`: `insight`, `cooperative_effort`, `persist`, `ask_for_help`, `find_own_courage`, `reveal_truth`, `patient_wait`.

> **In every one, the child is the grammatical and dramatic agent.** The companion may contribute knowledge or hands; it may never be the subject of the beat that resolves the story.

`cooperative_effort` and `ask_for_help` are the delicate ones — both involve the companion, and both are still the child's act: the child *joins*, the child *asks*. "The fox solved it" realizes no beat in this vocabulary and therefore cannot be written into a resolving slot. This is the structural form of the brief's §9.

### 3.4 Templates declare beats, not roles

A template variant currently declares `role`. It will declare **`realizesBeat`** instead. Consequences:

- One well-written `insight` variant serves every blueprint that uses `insight`, regardless of family. Prose reuse goes *up*, not down.
- A variant that realizes no beat is unselectable — the filler sentence has nowhere to live.
- A slot with no compatible variant is a **load-time error naming the beat**, not a silent fallback to "all templates" as the current `if validTemplates.isEmpty { validTemplates = roleTemplates }` does.

Role is retained on the page for layout and visual-intent purposes (§10), but it no longer drives text selection.

---

## 4. Narrative state — derived, not authored

### 4.1 The deviation, and why

The brief (§13) suggests authoring `requiredState` / `stateChanges` per page. **This architecture deliberately does not.** Phase 1 §1.6 showed exactly where that leads: 15 authored conditions, 8 with no producer, the one condition the prose depicted unproducible, and templates carrying no state fields at all — a state model disconnected at both ends and reporting nothing.

The failure was not the conditions chosen. It was that authors wrote requirements and productions **independently**, so nothing forced them to meet.

Instead: **state is a pure function of the beat sequence.** Authors write beats. The engine computes state from the table in §3.2. An unreachable precondition becomes unrepresentable rather than undetected.

### 4.2 The state keys

Ten booleans, every one produced by at least one beat and consumed by at least one beat:

`anomalyKnown · companionPresent · needKnown · committed · attemptMade · obstacleNamed · hesitationNamed · beliefFormed · solutionKnown · resolved`

Plus three content bindings fixed at selection, not by beats: `locationID`, `companionID`, `discoveryID`.

No counters, no enums, no numeric values, no branching. If a future story needs an eleventh key, that is a schema change with a review — not a content edit.

Note one deliberate simplification: there is no separate `courageGained`. Family II's resolution is `find_own_courage` producing the same `solutionKnown` as everyone else. The *distinctiveness lives in which beat produced it*, which is where the diversity test reads it (§12). Duplicating that distinction into the state model would add a key the engine cannot use.

### 4.3 The validation rules

**Rule 1 — reachability.** Run at content load:

```
state = ∅
for slot in blueprint.pages:
    for beat in slot.beats:
        assert beat.requires ⊆ state      // else: authoring error, named
        state ∪= beat.produces
assert "resolved" ∈ state                 // every story must resolve
```

This makes "page 7 resolves a conflict page 6 never raised" a **build failure**. It also makes the unearned resolution impossible: `succeed` requires `solutionKnown`, and every producer of `solutionKnown` is a caused action by the child. There is no path to a resolved story that does not pass through something the child did.

**Rule 2 — liveness.** Reachability alone is not enough, and Phase 4 proved it on the pilots themselves:

```
for key, page in produced:
    assert key ∈ consumed_by_some_later_beat   // else: that page is inert
```

Without this, a page can produce state nothing ever reads — meaning **the engine would generate an identical valid story with that page deleted**. Measured on the three Phase 3 pilots, which passed Rule 1 cleanly:

| Pilot | Dead state | Consequence |
|---|---|---|
| A | `companionPresent` (p3), `obstacleNamed` (p4) | the companion page is formally inert; so is half the problem page |
| B | `beliefFormed` (p4), `attemptMade` (p5) | the page the design calls "the second clue" has no downstream effect |
| C | `attemptMade` (p5) | the failed attempt is unreadable by the engine |

Principle **P2** — *cross-page dependency is the story* — was stated in Phase 2 and enforced by nothing. Rule 2 is what enforces it. A blueprint that trips it is not merely inefficient; it has a page that does not participate in its own story.

Fixing the pilots required tightening four beats so the earlier pages are actually load-bearing:

| Beat | Was | Now |
|---|---|---|
| `small_step` | `hesitationNamed` | `hesitationNamed` ∧ **`companionPresent`** |
| `find_own_courage` | `hesitationNamed` ∧ `attemptMade` | + **`obstacleNamed`** |
| `insight` | `obstacleNamed` | + **`beliefFormed`** ∧ **`attemptMade`** |
| `cooperative_effort` | `companionPresent` ∧ `obstacleNamed` | + **`attemptMade`** |

Each is narratively truer than what it replaced: the child takes the small step *because someone is there*; the insight arrives *after the idea has been tested and failed*; cooperation begins *after the solo attempt*.

---

## 5. The blueprint schema

Swift shown for precision; the shipped form is JSON decoded into this.

```swift
struct Blueprint: Codable, Identifiable {
    // Identity
    let id: ContentID
    let schemaVersion: Int
    let version: SemanticVersion
    let family: NarrativeFamily            // closed enum, §6
    let editorialName: String              // internal only, never shown

    // Narrative identity — the diversity test reads these three
    let curiosityMechanism: CuriosityMechanism   // what pulls
    let conflictMechanism: ConflictMechanism     // what resists
    let resolutionMechanism: ResolutionMechanism // what earns it
    let premise: String                    // one line, semantic, no nouns
    let distinctFrom: [DistinctionNote]    // vs. nearest siblings, §12

    // Structure
    let pages: [PageSlot]                  // exactly pageCount entries
    let emotionalArc: [EmotionalState]     // one per page, §7

    // Content requirements — traits, never IDs
    let requires: ContentRequirements       // §8
    let forbids: ContentExclusions          // §8 — P3: this is where identity lives

    // Surface
    let titleFamilies: [TitleFamilyID]      // §9
    let editorialGuidance: String?          // ≤ 2 sentences, for human authors only

    // Reused engine types — not redefined here
    let constraints: TemplateConstraints    // page count, age range, languages
    let childSafety: ChildSafetyPolicy      // defaults .strict
    let intensityCeiling: Int               // 0–3; 2 for age 5–6, §7.3
    let forbiddenOutcomes: [ForbiddenOutcome]
    let novelty: NoveltyWeights
}

struct PageSlot: Codable {
    let pageNumber: Int
    let role: PageRole                     // closed enum, the eight
    let beat: StoryBeat                    // required — §3.2
    let supportingBeat: StoryBeat?         // optional second beat
    let emotion: EmotionalState            // must equal emotionalArc[pageNumber-1]
    let visualIntent: VisualIntent         // §10, metadata only
}
```

What is **absent** and deliberately so: any content ID, any prose, any `stateRequirements` / `stateChanges` (derived, §4), any genre or theme string the engine switches on, any parallel safety or validation model (§11).

`editorialGuidance` is capped at two sentences and is the only free text. This is the brief's §32 line: *"Page 5 should contain an active attempt"* is guidance; *"Yeliz walked carefully toward the cave"* is content.

---

## 6. The six families, formalized

Approved in Phase 1. Formalized here as mechanism triples, which is what the diversity gate reads.

| Family | Curiosity mechanism | Conflict mechanism | Resolution mechanism | Signature beat |
|---|---|---|---|---|
| **I — The Unexplained** | `unexplainedPhenomenon` | `cognitive` (it isn't understood) | `insight` | `form_belief` → `insight` |
| **II — The Threshold** | `barrierWithSomethingBeyond` | `internal` (the child's own reluctance) | `incrementalCourage` | `hesitate` → `find_own_courage` |
| **III — The Appeal** | `anotherStatedNeed` | `relational` (someone else's difficulty) | `cooperation` | `receive_appeal` → `cooperative_effort` |
| **IV — The Absence** | `somethingMissing` | `uncertainty` (where, and will it be found) | `persistence` | `persist` → `restore` |
| **V — The Misreading** | `apparentEvidence` | `perceptual` (the child believes wrongly) | `revelation` | `belief_fails` → `reveal_truth` |
| **VI — The Charge** | `smallThingNeedingCare` | `duration` (nothing blocks; it simply takes time) | `patience` | `take_charge` → `patient_wait` |

Every mechanism value is unique to one family, so **all fifteen family pairs differ on all three axes**. Computed exhaustively rather than asserted.

This has a consequence worth stating plainly, because it determines what the diversity gate actually has to do: **between families the mechanism test is trivially satisfied and therefore does no work.** Structural separation between families is guaranteed by construction; the closest pair on beat sequence is III↔IV at a distance of 3 (they share `receive_appeal`, `commit`+`obstacle_raises`, `first_attempt` and `restore`, and diverge at pages 2, 6 and 8 — *cooperation* against *persistence*).

The real work of the gate is **within** a family, where blueprints share curiosity and conflict mechanism by definition and differ only on resolution — a mechanism distance of 1. §12 handles this explicitly; a gate that only measured mechanism distance would wrongly reject every intra-family blueprint.

**Reference arcs**, one per family, validated against the beat table. These are *examples proving expressibility*, not the pilots:

| Page | Role | **I** Unexplained | **II** Threshold | **III** Appeal | **IV** Absence | **V** Misreading | **VI** Charge |
|---|---|---|---|---|---|---|---|
| 1 | hook | `notice_anomaly` | `notice_anomaly` | `notice_anomaly` | `notice_anomaly` | `notice_anomaly` | `notice_anomaly` |
| 2 | discovery | `examine` | `approach` | `approach` | `examine` | `examine`+`form_belief` | `examine` |
| 3 | companion | `meet_companion`+`companion_offers` | `meet_companion` | `meet_companion`+`receive_appeal` | `meet_companion`+`receive_appeal` | `meet_companion` | `meet_companion` |
| 4 | problem | `form_belief`+`commit` | `hesitate` | `commit`+`obstacle_raises` | `commit`+`obstacle_raises` | `belief_fails`+`commit` | `take_charge` |
| 5 | attempt | `first_attempt`+`obstacle_raises` | `small_step` | `first_attempt` | `first_attempt` | `first_attempt` | `tend` |
| 6 | challenge | `insight` | `find_own_courage` | `cooperative_effort` | `persist` | `reveal_truth` | `patient_wait` |
| 7 | resolution | `succeed` | `succeed` | `restore` | `restore` | `succeed` | `restore` |
| 8 | ending | `warm_close`+`carry_forward` | `self_recognize`+`warm_close` | `warm_close` | `warm_close`+`carry_forward` | `warm_close` | `self_recognize`+`warm_close` |

Every column was machine-checked against §4.3 and passes. Page 1 is `notice_anomaly` in all six — that is the pacing rule (§7.4), not a lack of variety; the variety is in pages 4–7, which is where it is felt.

Within a family, blueprints differ by **resolution mechanism variant**. Family I can hold three: resolving by *observation* (the child notices the detail), by *deduction* (clues assemble), by *asking* (`ask_for_help` — understanding requires another's knowledge). Three different page-6 architectures, same family. 2–3 per family reaches 12–18 blueprints through structure rather than accumulation.

---

## 7. Emotional arc architecture

### 7.1 Vocabulary

Closed, with an intensity value used for the safety ceiling:

| Intensity 0 | Intensity 1 | Intensity 2 | Intensity 3 *(forbidden at 5–6)* |
|---|---|---|---|
| `ease`, `calm`, `warmth` | `curiosity`, `wonder`, `puzzlement`, `determination`, `surprise`, `tenderness`, `certainty`, `duty`, `sympathy` | `unease`, `hesitation`, `concern`, `doubt`, `effort`, `frustration`, `patience` | `fear`, `panic`, `grief`, `despair` |
| `joy`, `relief`, `pride`, `delight`, `insight`, `satisfaction` | | | |

### 7.2 Family signatures

Each family's arc is distinct as a *sequence*, not merely as a set:

| Family | p1 → p8 |
|---|---|
| **I** | ease → curiosity → wonder → puzzlement → determination → insight → satisfaction → warmth |
| **II** | ease → curiosity → hesitation → unease → determination → effort → relief → pride |
| **III** | ease → curiosity → sympathy → concern → determination → effort → relief → warmth |
| **IV** | ease → wonder → concern → determination → doubt → patience → relief → tenderness |
| **V** | curiosity → certainty → surprise → puzzlement → doubt → insight → delight → warmth |
| **VI** | ease → surprise → tenderness → duty → effort → patience → pride → calm |

Family V is the only arc that does not begin at `ease` — it begins at `curiosity` and reaches `certainty` by page 2, because the misreading has to be established confidently before it can be gently overturned. That difference in *shape* is what a reader feels as a different kind of story.

### 7.3 Emotional safety, as a computable rule

Three constraints, all checkable at load:

1. **Ceiling.** `max(intensity(arc)) ≤ intensityCeiling`. For age 5–6, `intensityCeiling = 2`. No intensity-3 state may appear, which is the structural form of the brief's §8 prohibitions.
2. **Landing.** The final state must be intensity 0 (`warmth`, `calm`) or a positive resolution state (`pride`, `joy`, `relief`, `tenderness`). No story may end above intensity 1.
3. **No sustained tension.** At most **two consecutive** pages at intensity 2. A 5–6-year-old can hold tension for two spreads; three is where a bedtime story stops being one.

All six signatures satisfy all three. Family II has its longest run at pages 3–4 (`hesitation`, `unease`) — two, at the limit, deliberately: that family's identity *is* the held breath.

### 7.4 Pacing rules

From the brief's §15, made checkable:

- `notice_anomaly` **must occur by page 2**. The story cannot spend three pages on setup.
- At most **one** page may carry `establish_ordinary`, and only page 1.
- `obstacleNamed` must be true by **page 5** — the difficulty must be concrete before the attempt that does not fully work. **Exception:** blueprints whose `conflictMechanism` is `duration` (Family VI) never produce `obstacleNamed`; nothing blocks the child, and inventing an obstacle to satisfy a pacing rule would destroy the only family whose tension is time rather than difficulty. The rule is therefore conditional on the mechanism, not universal.
- `resolved` must not be true before **page 7**, and must be true by page 7.
- Page 8 carries only closing beats.

All six reference arcs in §6 were machine-checked against the beat table and these rules: every one satisfies every beat precondition in order, reaches `resolved`, and lands within the intensity ceiling. The `duration` exception above was found by that check failing, not by inspection — which is the argument for running it in CI rather than trusting review.

---

## 8. Compatibility semantics

### 8.1 Traits, never IDs

Phase 1 found companions declaring `compatibleSettings: ["forest"]` against settings whose IDs are `setting_forest_001` — matching on tags, implicitly, unvalidated; and objects with no setting compatibility at all, so a seashell can be discovered in a snowy valley.

The blueprint declares **requirements**; content declares what it offers. No blueprint ever names a fox, a forest, or a light.

Phase 4 found the first version of this vocabulary broken in two ways. Both fixes are below.

#### Capabilities vs. castable roles

The original list conflated what a character **is** with what a character is **doing in this story**. `isSmallAndVulnerable` was required by one blueprint and forbidden by another, both with sound reasoning — because *small* is permanent and *needing care* is a part being played. The same firefly must be able to guide in one book and need help in the next.

| | Declared as | Vocabulary | Blueprints use it to |
|---|---|---|---|
| **Capabilities** | intrinsic, always true | `canFly` · `canCarry` · `canSwim` · `isSmall` · `isStrong` · `isQuick` · `isPatient` · `hasLocalKnowledge` · `isLiteralMinded` | **forbid** what would dissolve the conflict |
| **Castable roles** | eligibility to play a part | `guide` · `needsCare` · `hesitant` · `reassuring` | **cast** the companion |

A blueprint casts (`castAs: [hesitant, reassuring]`) and excludes (`capForbid: [canCarry]`). Content declares every part a character can credibly play. **Minimum three capabilities and two castable roles per companion**, assigned by an editor who knows the characters — Phase 4 found four companions with only two traits each, which made a third of the cast unusable.

#### Habitat and placement — the relational axis

Trait intersection over *unary* properties cannot express a relation between two content items, and three of the pilots' premises are relations. With unary traits alone, nothing prevents a squirrel on a coral reef, a seashell discovered in a snowy valley, or a "mysterious" glowing light in a cave whose own description says it is full of glowing stones. That last one is the sharpest: **`isUnexplained` is not a property of a thing, it is a property of a thing in a place.**

Two bounded relations close this. Neither turns the model into a general relational algebra:

- **`habitat`** — a small closed set (`land`, `water`, `air`, `snow`, `indoor`, `space`). A setting declares the habitats it *provides*; a companion and a discovery declare the habitats they can *occur in*. Selection requires a non-empty intersection. This restores the function the old `compatibleSettings` served and Phase 1 deleted without replacing.
- **`explainedBy`** — a discovery declares setting traits that would make it *ordinary*. A glowing light lists `isLuminous`; a setting that is itself luminous therefore cannot host it as a mystery. Footprints list `showsTraces` for the same reason — tracks in snow are the least mysterious tracks there are.

**Setting:** `canConceal` · `hasThreshold` · `hasHeight` · `hasWater` · `isEnclosed` · `isOpen` · `showsTraces` · `isTended` · `hasWeather` · `isLuminous` · `isHazardous` — plus `habitat` and `thresholdKind` (`opening` · `span` · `water` · `height` · `social`).

`hasDistance` is **removed**. Phase 4 measured it on 12 of 16 settings: a requirement satisfied by three-quarters of the library is not a requirement. Blueprints needing separation ask for `hasThreshold` or express it through the discovery instead.

**Discovery-kind:** `isUnexplained` · `emitsSignal` · `impliesPresence` · `impliesNeed` · `isFragmentary` · `isFragile` · `isBeautiful` — plus `habitat` and `explainedBy`.

### 8.2 The discovery-kind, as confirmed

The third user choice resolves to a **discovery-kind**, which internally binds an object and/or event. This is what makes family selection possible:

| User picks | Discovery-kind traits | Families it can recruit |
|---|---|---|
| A glowing light | `isUnexplained`, `emitsSignal` | I, II |
| Footprints | `impliesPresence`, `isFragmentary` | IV, V |
| A strange sound | `isUnexplained`, `emitsSignal`, `impliesNeed` | I, III |
| A torn map | `isFragmentary`, `impliesPresence` | I, IV, V |
| A small egg / injured bird | `isFragile`, `impliesNeed` | III, VI |

Modelled as a bare object, this choice carries no structural information and blueprint selection loses its most informative input — which is precisely what happened before. Modelled as a kind, **the child's most emotionally invested choice becomes the thing that selects the shape of their story.**

### 8.3 Exclusions are where identity lives (P3)

`forbids` is not an afterthought. Worked example — a Family II blueprint whose threshold is a height:

```
requires:  setting: [hasThreshold, hasHeight]
           companion: [canReassure]
           discovery: [isUnexplained]
forbids:   companion: [canFly, canCarry]
```

Without the exclusion, selecting an owl or a dragon lets the companion trivially carry the child across, and the blueprint's entire dramatic premise — *the child must cross this themselves* — silently evaporates. The story still generates. It is just no longer the story.

This is the brief's §28 in operational form: when a combination becomes nonsensical, the fix is a more precise constraint, not a rewritten blueprint. It is also the reason Phase 1 found the fifteen well-differentiated companion personalities being ignored — nothing in the system could express why a timid rabbit and a wise owl are not interchangeable.

### 8.4 Load-time integrity

At content load, for every blueprint: at least one setting, one companion and one discovery-kind must satisfy `requires` minus `forbids`. **A blueprint with an empty candidate set is a build failure**, not a runtime fallback. The current `if filtered.isEmpty { return items }` pattern — silently substituting arbitrary content when compatibility fails — is removed.

---

## 9. Title architecture

Phase 1: titles are `"\(childName) ve \(companionName)"`, forever, and V1's `titlePatterns` are never read.

Titles are built from **title families** — grammatical shapes, not string templates with swapped nouns (brief §20). Five, harvested from V1's real examples:

| ID | Shape | Example | Suits |
|---|---|---|---|
| `T1_pairing` | *{Child} ve {DiscoveryPhrase}* | Yeliz ve Ormandaki Gizemli Işık | I, III |
| `T2_achievement` | *{Child}+GEN {SettingLoc} {AchievementNoun}* | Yeliz'in Ormandaki Büyük Keşfi | I, IV |
| `T3_secret` | *{Child} ve {Thing}+GEN Sırrı* | Yeliz ve Kayıp Haritanın Sırrı | I, V |
| `T4_act` | *{AdverbialPhrase} {Infinitive}* | Cesaretle Yolu Aydınlatmak | II, VI |
| `T5_journey` | *{Setting}+DAT {Adjective} Yolculuk* | Kristal Odasına Cesur Yolculuk | II, IV |

A blueprint declares which families suit it — `T4_act` reads as a story about *doing something hard*, which is Family II's identity and would be wrong on Family V.

**Turkish requirement.** Each title family declares the **grammatical form required per slot** (`GEN`, `LOC`, `DAT`, or locative + relative `-ki`). This is not cosmetic: Phase 1 §7 found that `'nin` and `'nde` — the forms `T2` and `T3` depend on — were exactly what `TurkishSuffixResolver` did not implement, falling through to literal passthrough and producing *"Fısıldayan Orman'nde"*.

**Resolved in Phase 3.** `TurkishGrammar` now covers all five cases plus the relative `-ki` that `T2_achievement` actually needs ("Ormandaki"), with buffer consonants, d/t assimilation, declared proper-noun and possessive-stem handling, and reported rather than silent failures. 36 tests; full engine suite green; app builds. Title families are safe to author.

---

## 10. Visual intent

Metadata only. No image prompts in the blueprint (brief §33).

Each page slot carries a `visualIntent` drawn from the composition rules **already defined** in `visual_catalog.json` — the vocabulary exists and should not be reinvented:

`full_bleed_establishing` · `centered_portrait` · `character_left_text_right` · `character_right_text_left` · `quiet_closing`

Default mapping by role, overridable per blueprint:

| Role | Intent |
|---|---|
| hook | `full_bleed_establishing` |
| discovery | `centered_portrait` (the discovery held in frame) |
| companion | `character_left_text_right` |
| problem / attempt | `character_right_text_left` |
| challenge | `full_bleed_establishing` (the moment opens out) |
| resolution | `centered_portrait` |
| emotionalEnding | `quiet_closing` |

Text never depends on visual intent. A blueprint remains fully valid with the visual system switched off.

---

## 11. Safety and validation — reuse, do not reinvent

Phase 1 found **seven incompatible `safetyMetadata` shapes across twelve V1 files**, and none in V2.

`adventure_01.json` already carries the correct normalized shape. The blueprint reuses `ChildSafetyPolicy` verbatim — four gates, defaulting to `.strict`, so a blueprint that omits safety gets the safest behaviour. The seven ad-hoc shapes are mapped onto it and deleted.

The blueprint adds only what is genuinely narrative and not already covered:

- `intensityCeiling` (§7.3) — an emotional-arc property no existing type expresses
- `forbiddenOutcomes` — closed enum: `characterAbandoned`, `characterHarmed`, `problemUnresolved`, `childAtFault`, `companionLost`, `deusExMachina`
- `ForbiddenOutcome.deusExMachina` is already structurally impossible via §4.3; it is listed so the intent is reviewable by an editor who does not read the beat table.

**On validation — the most important finding of Phase 2.** `ValidationRules` already implements exactly the checks that would have caught the Phase 1 disaster, and they are already correct:

| Existing rule | Default | Effect on the current corpus |
|---|---|---|
| `maximumRepeatedNGrams` | `0` | The filler sentence repeated on 4 pages → **blocked** |
| `maximumSharedSentenceOpeners` | `2` | Four hook variants opening identically → **flagged** |
| `requireProtagonistMentionPerPage` | `true` | Pages without the child → **flagged** |

The repetition validator is implemented and works. **The offline path simply never calls it.** No new validation model is needed; the requirement is that the offline generation path runs `ValidationRules` like the AI path does.

One correction is needed, and it is a real one. `adventure_01.json`'s age band for 5–7 requires **40–130 words per page**. Measured: V1's best prose is **median 23 words** (range 13–32), V2's is 10.5. **Every existing variant fails the minimum.** That band was calibrated for AI-generated long-form pages, not for an illustrated picture book where the image carries half the load. For this product:

```
ageBand(5...6): minimumWordsPerPage 18, maximumWordsPerPage 38, maximumSentenceWords 14
```

Derived from the V1 median rather than chosen. Blueprints must not inherit `adventure_01.json`'s band.

---

## 12. The diversity gate

The Phase 1 rule, made into an authoring gate. A blueprint is **rejected** unless it passes all four against every already-approved blueprint:

1. **Mechanism separation.** Either the `(curiosity, conflict, resolution)` triple differs on **≥ 2 of 3** axes — the cross-family case — **or**, for two blueprints in the same family, the resolution mechanism differs **and** beat distance is **≥ 4**. The second clause exists because same-family blueprints share curiosity and conflict by definition (§6); without it the gate would reject every intra-family blueprint and force the library into exactly six stories.
2. **Arc separation ≥ 2.** The 8-state emotional sequence differs from every other blueprint's in at least two positions.
   Requiring the sequence to be *wholly unused* — the Phase 2 wording — is incompatible with §7.2's family signature arcs: it would let only one blueprint per family carry its own family's emotional identity, forcing every sibling to deviate from the thing that makes the family recognisable. Two positions is enough to forbid duplicates while leaving a family's shape intact.
3. **Beat distance ≥ 3.** The number of page slots whose **full beat set** (primary + supporting) differs. Comparing primary beats alone is too coarse — it misses a page that adds `obstacle_raises` beside an unchanged `first_attempt`, which materially changes what the page does.
4. **Authored distinction.** A `distinctFrom` note naming the two nearest siblings and what a reader would feel as different — prose, for the editor, reviewed by a human.

Tests 1–3 are machine-checkable and run in CI. Test 4 is the one that catches blueprints which game the metrics.

**Validation against the existing corpus** — the gate must reject what Phase 1 identified as weak and admit the legitimate reference arcs, or it is not a gate. Distances computed, not estimated:

| Comparison | Mech. | Arc | Beat | Verdict |
|---|---|---|---|---|
| V2 `blueprint_001` vs `_002` … `_012` | 0 | same | 0 | **Reject** — identical |
| V1 `cave_001` vs `bridge_002` | 0 | same | 0 | **Reject** — both resolve by insight |
| V1 `garden_004` vs `footprints_005` | 0 | same | 0 | **Reject** — both resolve by insight |
| V1 `cave_001` vs `map_003` | 1 | same | 1 | **Reject** — fails 3 of 4 |
| Family III ref. vs Family IV ref. *(closest pair)* | 3 | differs | 3 | **Pass** |
| Family II ref. vs Family V ref. | 3 | differs | 5 | **Pass** |
| Family I ref. vs Family III ref. *(furthest pair)* | 3 | differs | 7 | **Pass** |

The gate rejects all five existing `adventure_courage_*` blueprints and all twelve V2 records, and admits every family pair with margin. Across the fifteen family pairs, mechanism distance is 3 in all cases and beat distance ranges 3–7.

### 12.1 QA metrics

Per Phase 1 §6.5 — record counts are never reported. The Phase 6 report states:

| Metric | Today | Target |
|---|---|---|
| Narratively distinct arcs | 1 | ≥ 12 |
| Unique realised page sentences | 27 / 156 slots | ≥ 90% unique |
| Expected repeated sentences per book | ≈ 3.7 of 8 | 0 |
| Unreachable content share | 41% | 0% (load-time failure) |
| User choices observable in final text | 0 of 3 | 3 of 3 |
| Blueprints passing the §12 gate | 0 of 17 | 100% of shipped |

---

## 13. Engine-friendliness

The brief's §31 requires deterministic implementability. The full selection algorithm:

```
1. StoryIntent ← (childProfile, place, companion, discoveryKind, seed)
2. Candidate blueprints ← those whose requires/forbids admit all three choices,
                            whose constraints cover age and page count
3. Rank by novelty (unseen family first, then unseen blueprint), pick with seed
     — as built (FAZ 12): idea affinity groups first; within a group, a seeded
       weighted order (`SelectionScoring`): interest match ×3, content used in the
       last 4 stories cooled linearly. The binder orders settings, companions and
       discoveries the same way. Equal weights reproduce the old seeded rotation.
4. Bind content: setting, companion, discovery-kind, object, ending
     — by trait intersection; empty candidate set is impossible (§8.4)
5. For each page slot, in order:
     state ← accumulated state
     candidates ← templates where realizesBeat == slot.beat
                             ∧ requires ⊆ state
                             ∧ traits compatible with bound content
                             ∧ not used in this story
     pick with seed; apply beat.produces to state
6. Title ← pick a declared title family; resolve slots with case-correct suffixes
7. Validate with ValidationRules + ChildSafetyPolicy (§11)
8. Persist seed + every selected ID in provenance
```

Deterministic given `(intent, seed, catalogVersion)`. Step 8 is what makes a book reproducible, auditable and explainable — Phase 1 found the seed generated by `UInt64.random` and discarded.

Step 5's `not used in this story` clause is one line and eliminates the repeated-sentence defect at selection time, before validation ever sees it.

---

## 14. What this architecture deliberately does not do

Stated explicitly to prevent scope drift (brief §29):

- **No branching.** Linear, exactly eight pages for MVP. `pageCount` is in the schema so a 12-page book is a later content change, not a re-architecture.
- **No numeric or enumerated state.** Ten booleans.
- **No hand-authored state.** Derived (§4).
- **No parallel safety or validation model.** Reuse (§11).
- **No prose in blueprints** beyond two sentences of editorial guidance.
- **No genre/theme strings the engine switches on.** Families are structural; world keys stay opaque.
- **No LLM at runtime.** Selection is deterministic over bundled content.

---

## 15. Reuse map

| Existing asset | Disposition |
|---|---|
| `ChildSafetyPolicy`, `ValidationRules`, `AgeBandRule`, `TemplateConstraints` | **Reuse verbatim.** Re-band 5–6 word counts (§11). |
| `SemanticVersion`, `TemplateRef`, provenance pinning | **Reuse.** Extend `TemplateRef` with seed + selected IDs. |
| Repetition / structural / age validators | **Reuse.** Run them on the offline path — the missing step. |
| `visual_catalog.json` composition rules | **Reuse** as the `VisualIntent` vocabulary (§10). |
| The eight page roles | **Adopt** as the closed `PageRole` enum. |
| 288 V1 variants (esp. 120 from `adventure_courage_*`) | **Harvest** into beat-tagged templates; decouple hardcoded species/settings. |
| V1 `narrativePurpose` (40 pages) | **Convert** to beat assignments — it is the beat field in embryo. |
| V1 `titlePatterns` | **Harvest** into the five title families (§9). |
| 15 companions with personalities | **Retain**; map personality → traits (§8.1). |
| `TurkishSuffixResolver` vowel-harmony core | **Extend** to GEN/LOC/DAT/ACC + proper-noun detection. **Gates Phase 3.** |
| 12 V2 blueprint records | **Delete.** Zero information (Phase 1 §1.1). |
| Filler sentence + its 60 slots; 137 placeholder `visualScene` | **Delete.** |
| V1 role vocabularies 2 and 3 | **Delete.** Collapse into the eight. |
| 7 ad-hoc `safetyMetadata` shapes | **Delete.** Map onto `ChildSafetyPolicy`. |
| `{{child.pronoun}}`, `{{child.possessive}}`, `{{child.favoriteColor}}` | **Delete.** First two are English calques; the third is undeclared and would throw. |

---

## 16. Phase 3 entry conditions

Three pilots, one per family, chosen for maximum mechanism distance:

- **Pilot A — Family II (Threshold).** Internal conflict; the one thing the current corpus cannot do, since it gives the fear to the companion.
- **Pilot B — Family I (Unexplained).** Cognitive conflict, resolution by insight; the richest harvest target from V1.
- **Pilot C — Family III (Appeal).** Relational conflict, resolution by cooperation; proves `restore` and the child-agency rule under the hardest case.

Mutual distances — mechanism 3 in every pair (§6), beat distance A↔B = 6, A↔C = 6, B↔C = 7. These are the three furthest-separated families in the library, which is the right property for a pilot set: if the architecture holds here, the intra-family cases in Phase 5 are the harder test, not the easier one.

Each pilot must be authored with enough beat-tagged variants to be instantiated against the Phase 4 matrix (forest+fox+light, mountain+owl+footprints, garden+hedgehog+sound, ~~sea+dolphin+shell~~, forest+rabbit+map).

> **2026-10-01 — `sea+dolphin+shell` retired from the matrix** (product decision, Faz 7.1). No blueprint in the library fits it: an open sea offers no threshold, the dolphin carries, and the shell neither signals nor asks to be explained. The two nearest blueprints were one trait away and both would have been a narrative stretch; §8.3 forbids widening a blueprint to buy coverage, and a water-family blueprint was declined for now. The row stays in `MatrixCoverageTests` as `retiredSeaRow`, the library's standing impossible request, which must be refused with a reason. The coral sea, dolphin and shell content remain in the catalog.

**One blocker to resolve first.** The Turkish suffix resolver (§9, §15) does not implement the cases that `T2_achievement` and `T3_secret` need, and silently emits ungrammatical output rather than failing. Authoring title families against a resolver that cannot render them would bake the defect into the corpus. I recommend fixing the resolver — a contained, well-specified change — **before** Pilot titles are written, and I will flag it again rather than author around it.

Two smaller items I will decide during Phase 3 unless directed otherwise: whether `ending` content becomes a bindable component or is absorbed into the closing beats (I lean absorbed — Phase 1 found the 10 ending records never selected, and closing beats already carry the emotional landing); and whether `establish_ordinary` earns its place at all, given the pacing rule effectively forbids it after page 1.

---

## 17. Series episodes (FAZ 13, 6 October 2026)

A liked story continues as four more episodes. The architecture above holds for every episode; these are the additions.

- **A separate catalog layer.** Continuation blueprints live in `ContentCatalog.series.continuations`, episode-only lines in `series.templates` (`beat_series_*.json`, `series: true`). Nothing that picks or writes a standalone story can see either, so every saved seed still builds the same book. A `kind` field on ordinary blueprints was the first design; a separate list does the same without touching any code path a standalone story uses.
- **`continuation` block** on a blueprint: `modes` (which parent intents its series may belong to; the tone comes from here, not from `storyModes`) and `episodes` (2…5, default all). What carries over is not declared because it is not a choice: place, companion, Masal ailem character and keepsake always do; the discovery is always new.
- **`revisit`** — the 35th beat. The episode's opening: the child comes back to a known place and friend. Requires nothing, produces `companionPresent`. Only on page 1 (`revisit_out_of_place`), and never in a standalone blueprint (`revisit_in_standalone`). It is a family moment of the series layer (`series.familyMoments = [revisit, warm_close]`).
- **`{{keepsake.name}}`** — what the first story found, remembered. Rendered from `CatalogObject.keepsakeName` ("ince ses", "küçük yuva"), a third register beside the prose name and the title name; falls back to `name`.
- **Calm ending** (`CalmEnding`). The last page of an episode closes: no `?`, "yarın", "acaba", "birden", "sonra ne olacak". Enforced as a non-degrading pool filter on the last page, as a check on the rendered page, and as a validator gate on series closing lines. The rule replaces the `unresolvedThreads` idea in `MagicPaper_Persistence_Migration.md` §7: an episode never ends on a hook.
- **Picking.** Episodes use `DeterministicPicker.mixedIndex` (SplitMix-finished hash): the plain `index` reads FNV's poorly mixed low bits, and two episodes then picked the same line on every page one time in four. Standalone stories keep `index`. Each episode also prefers lines the earlier episodes have not used (a degrading preference).
- **Planning** (`SeriesPlanner`): continuations alternate A-B-A-B from a seeded start; discoveries are new in every episode and never the keepsake (a search that first forbids any repeat, then allows one, never twice in a row); every episode must compose both with and without the Masal ailem character.

## 18. Learning from reading (FAZ 14, 6 October 2026)

Selection weight gains one more factor, `usage`, after interests and cooldown. It never filters.

- **`UsageLearner`** turns the child's own reading (`StoryUsage`: blueprint, companion, mode, completions, abandoned) into a `UsageProfile`: a multiplier per narrative family and per companion. Re-read +1, finished once +¼, abandoned −1 when the mode counts it; `1 + sum / (stories + 2)`, clamped to 0.6…1.8 so it never outweighs an interest (×3). Nothing read means no keys, every multiplier exactly 1, and the seeded rotation is untouched — every pinned book stays the same book.
- **`storyModes[].success.abandonIsPenalty`** (default `true`). Bedtime sets it to `false`: a bedtime story left halfway usually means the child fell asleep.
- **`aggregateWeight`** on a blueprint (default 1, not written when 1; integrity error when not a positive number). A multiplier for what every child's reading says, to be published by the server from `BlueprintOutcome` rows (starts, completions, re-reads) with Thompson sampling after FAZ 16, delivered as a catalog package (FAZ 15). Nothing sets it yet.

