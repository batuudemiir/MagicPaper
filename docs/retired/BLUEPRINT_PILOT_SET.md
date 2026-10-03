# MagicPaper Kids — Pilot Blueprint Set (Phase 3)

**Date:** 2026-09-15
**Status:** **Superseded by `BLUEPRINT_CATALOG_V2.md` (Phase 5).** Kept as the record of what the pilots were and how they failed, because the failures drove the architecture. Three of the nine instantiations below violate their own blueprints; Phase 4 §3 and the catalog's §1 explain which and why. Read the catalog for current rules.

Three pilots for review. No JSON authored — per the brief, resources follow catalog approval.
**Input:** `BLUEPRINT_AUDIT.md` (Phase 1), `BLUEPRINT_ARCHITECTURE.md` (Phase 2). Families and discovery-kind approved. Suffix resolver fixed and tested (see §0).

---

## 0. Prerequisite closed

The Phase 2 blocker is resolved. `TurkishGrammar`, `TurkishSuffixRequest` and `TurkishTextRenderer` now live in the engine (`StoryEngine/Sources/StoryEngine/Services/TurkishGrammar.swift`) with 36 tests, all passing; the full engine suite is green (546 tests across four targets, 0 failures); the iOS app builds against them.

What changed, in terms that matter to authoring:

- **Suffix spellings are now requests for a case, not literal text.** An author writing `{{setting.name}}'nde` gets the correct locative for whatever word arrives — `Fısıldayan Orman'da`, `Gizli Bahçe'de`, `Bulut Krallığı'nda`. Mis-authored suffixes self-correct rather than shipping.
- **Common nouns no longer take an apostrophe.** `{{companion.type}}'ye` renders `tilkiye`, not `tilki'ye`.
- **Possessive stems are declared, not guessed.** Four settings (`Bulut Krallığı`, `Yıldız İstasyonu`, `Ay Yüzeyi`, `Mercan Resifi`) carry `possessiveStem: true`. This was the real reason the corpus held both correct and incorrect `'nde` spellings — the original author generalised from the subset where it happened to be right.
- **Defects are reported, not swallowed.** A missing slot or a non-case suffix now fails generation with a named diagnostic. `{{child.favoriteColor}}`, which appears 16× in V1 and is undeclared at runtime, is caught rather than silently producing a hole.
- **The relative `-ki` is supported** — `Ormandaki`, `Fısıldayan Orman'daki`, `Bulut Krallığı'ndaki` — built on top of the locative so it inherits the d/t assimilation, the possessive buffer and apostrophe placement. This was a gap in my Phase 2 design: I specified `T2_achievement` as *{Child}+GEN {Setting}+LOC {Noun}*, but the shape the V1 titles actually use ("Yeliz'in Ormandaki Büyük Keşfi") needs locative **+ -ki**, which plain locative cannot produce. It is modelled as a separate `TurkishSuffixRequest` rather than a sixth case, correctly: the result is an adjective and cannot take a further case ending.

Pilots below are authored against this behaviour, so title families (§7 of each pilot) are safe to write.

**One correction to Phase 2.** Family II's declared emotional arc opened `ease → curiosity`. Authoring page 1 against it produced a flat hook — a page whose job is to catch attention cannot have *ease* as its dominant register. The arc is revised to open `curiosity → wonder`. Still unique against the other five sequences; re-checked.

---

## 1. The pilot set

| | Pilot A | Pilot B | Pilot C |
|---|---|---|---|
| **ID** | `bp_threshold_crossing_001` | `bp_unexplained_signal_001` | `bp_appeal_reunion_001` |
| **Family** | II — The Threshold | I — The Unexplained | III — The Appeal |
| **Conflict locus** | **Internal** | **Cognitive** | **Relational** |
| **Resolves by** | incremental courage | insight | cooperation |
| **The child's act** | doing the thing they feared | working something out | contributing what only they can |

Chosen for maximum separation: these are the three furthest-apart families in the library (beat distances 6, 6, 7). If the architecture holds here, the intra-family cases in Phase 5 are the harder test, not the easier one.

They also cover the three things Phase 1 found the existing corpus could not do at all: give the fear to the child, let the child deduce, and make cooperation two-sided.

---

# PILOT A — `bp_threshold_crossing_001`

## A.1 Identity

**Family:** II — The Threshold
**Premise (semantic, no nouns):** *A child wants to reach something on the far side of a barrier they are afraid to cross. The barrier never changes. The child does.*

| Mechanism | Value |
|---|---|
| Curiosity | `barrierWithSomethingBeyond` — the pull is what's on the other side |
| Conflict | `internal` — nothing external prevents the crossing |
| Resolution | `incrementalCourage` — a smaller version first, then the whole thing |

## A.2 Why this blueprint exists

Phase 1's sharpest finding was that the existing "courage" stories give the fear to the **companion**. The fox is afraid of the dark; the child is a bystander to someone else's feeling. That is not a courage story — it is a reassurance story with the child cast as the adult.

This blueprint inverts it, and the inversion is the entire design. Three constraints follow from it and are non-negotiable:

1. **The barrier must be something the child could physically do at any moment.** A swaying bridge, a dark entrance, cold water, a high step. If an external force blocks the way, the conflict stops being internal and the blueprint becomes something else.
2. **The companion must be unable to solve it.** Not unwilling — unable. Hence the exclusions in §A.5. A companion that can carry the child across deletes the premise while the story still generates, which is exactly the silent failure mode Phase 1 documented.
3. **The resolution must be incremental, not sudden.** One step on the bridge. A hand in the water. Three paces in. This is how children actually build courage, and it is the one thing this structure can teach that a "then they were brave" ending cannot.

The emotional risk is real and specific: a story about a child's fear can shame the child reading it. The editorial constraints in §A.8 exist for that reason and are tighter than any other pilot's.

## A.3 Emotional arc

`curiosity → wonder → hesitation → unease → determination → effort → relief → pride`

Intensity: 1, 1, 2, 2, 1, 2, 0, 0 — ceiling 2, longest run at 2 is pages 3–4. That held breath *is* this family's identity, so it sits deliberately at the limit rather than below it.

## A.4 Page architecture

### PAGE 1 — `hook` · beat `notice_anomaly`
**Narrative purpose:** The child notices something on the far side of a barrier. The barrier is visible but not yet the subject.
**Emotional purpose:** Curiosity. The pull, before the problem.
**State in:** — **State out:** `anomalyKnown`
**Visual:** `full_bleed_establishing` — wide, the barrier crossing the frame, the something beyond it small and bright.
**Editorial:** Lead with what is wanted, not with what is in the way. The reader should want to cross before they learn there is a reason not to.

### PAGE 2 — `discovery` · beat `approach`
**Narrative purpose:** The child comes close. The barrier becomes concrete and physical — it sways, it is dark, it is cold.
**Emotional purpose:** Wonder edged with the first awareness of scale.
**State in:** `anomalyKnown` **State out:** —
**Visual:** `centered_portrait` — the child at the near edge, the barrier filling the foreground.
**Editorial:** Name one physical property the reader can feel. Not "it was scary" — a sound, a movement, a temperature.

### PAGE 3 — `companion` · beat `meet_companion`
**Narrative purpose:** The companion arrives with its own reason to be here — it lives beyond, it crosses often, it is waiting for someone. It does not exist to comfort.
**Emotional purpose:** Hesitation surfaces in the child's body before it is spoken.
**State in:** — **State out:** `companionPresent`
**Visual:** `character_left_text_right`
**Editorial:** The companion is calm about the crossing without being dismissive of it. It must never say a version of "there's nothing to be afraid of."

### PAGE 4 — `problem` · beat `hesitate`
**Narrative purpose:** The child stops. The reluctance is named plainly and owned by the child.
**Emotional purpose:** Unease — the peak, and it is small and honest.
**State in:** — **State out:** `hesitationNamed`, `obstacleNamed`
**Visual:** `character_right_text_left` — the child still, the companion near, neither moving.
**Editorial:** The child says it, or the narration says it for them, in one plain sentence. No shame, no apology, no one urging. **The companion waits and does not persuade.** This page is the blueprint; getting it wrong loses the whole thing.

### PAGE 5 — `attempt` · beat `small_step`
**Narrative purpose:** The child does a reduced version of the crossing. One step. A hand in. A look round the corner.
**Emotional purpose:** Determination — quiet, not triumphant.
**State in:** `hesitationNamed` **State out:** `attemptMade`
**Visual:** `character_right_text_left` — close on the point of contact: a foot, a hand.
**Editorial:** The small step must be genuinely small and must **succeed**. Nothing goes wrong here. The discovery of page 6 depends on this having held.

### PAGE 6 — `challenge` · beat `find_own_courage`
**Narrative purpose:** The child registers that the small step held, and goes.
**Emotional purpose:** Effort — the real exertion of the book.
**State in:** `hesitationNamed` ∧ `attemptMade` **State out:** `solutionKnown`
**Visual:** `full_bleed_establishing` — mid-crossing, both edges visible.
**Editorial:** The realisation is the child's and is *about themselves*, not about the barrier. The barrier has not become safer. The companion may be alongside; it may not pull, lift, or lead.

### PAGE 7 — `resolution` · beat `succeed`
**Narrative purpose:** The child reaches the far side and the thing that drew them there.
**Emotional purpose:** Relief, then the thing itself.
**State in:** `solutionKnown` **State out:** `resolved`
**Visual:** `centered_portrait`
**Editorial:** Give the discovery one real sentence. It has been the engine for six pages and must not be a throwaway.

### PAGE 8 — `emotionalEnding` · beats `self_recognize` + `warm_close`
**Narrative purpose:** The child notices they are someone who can do this.
**Emotional purpose:** Pride — quiet, internal, unwitnessed by anyone but the companion.
**State in:** `resolved` **State out:** —
**Visual:** `quiet_closing`
**Editorial:** The recognition is internal, not praise from the companion. **No one tells the child they were brave.** The child notices it. That distinction is the difference between a story about approval and a story about self-knowledge.

## A.5 Content requirements

```
requires:
  setting:    [hasThreshold] ∧ ([hasDistance] ∨ [canConceal])
  companion:  [canReassure]
  discovery:  [isBeautiful] ∨ [emitsSignal] ∨ [isUnexplained]
forbids:
  companion:  [canCarry]
  discovery:  [impliesNeed]
```

**On `forbids: companion [canCarry]`.** The rule is not "the companion cannot cross" — a turtle swimming the river while the child hesitates on the bank is a *better* page, not a broken one. The rule is that the companion cannot cross **for** the child. A bear that could carry them over deletes the premise silently.

`canFly` is deliberately **not** forbidden outright: an owl that flies across and waits on the far side is fine, because flight does not transfer. Exclusions must name the capability that dissolves the conflict, not the species that suggests it — this is where the previous system's ID-based compatibility could not reach.

**On `forbids: discovery [impliesNeed]`.** If the thing beyond needs help, the child's motive stops being desire and becomes duty — the story drifts into Family III and the internal conflict loses its point. A blueprint's exclusions are how it keeps its identity under content substitution.

## A.6 Narrative state

`anomalyKnown` → p1 · `companionPresent` → p3 · `hesitationNamed`, `obstacleNamed` → p4 · `attemptMade` → p5 · `solutionKnown` → p6 · `resolved` → p7.

Machine-checked against the beat table: every precondition satisfied in order, `resolved` reached at page 7. Note that `obstacleNamed` is produced by `hesitate` itself — in this family the hesitation *is* the obstacle, which is what distinguishes it structurally from every other pilot.

## A.7 Title families

`T4_act`, `T5_journey`, `T1_pairing`.

| Family | Shape | Example |
|---|---|---|
| `T4_act` | *{Adverbial} {Infinitive}* | "Cesaretle Karşıya Geçmek" |
| `T5_journey` | *{Setting}+DAT {Adjective} Yolculuk* | "Eski Taş Köprü'ye Cesur Yolculuk" |
| `T1_pairing` | *{Child} ve {DiscoveryPhrase}* | "Yeliz ve Köprünün Ardındaki Işık" |

`T4_act` is this blueprint's signature: it names an *action*, which is what the book is about. It would be wrong on Pilot B, where nothing is crossed.

`T2_achievement` and `T3_secret` are excluded — both frame the story as a discovery, and this story's subject is the crossing.

## A.8 Safety

`childSafety: .strict` · `intensityCeiling: 2`
**Forbidden outcomes:** `childAtFault`, `characterHarmed`, `deusExMachina`, `companionLost`

Blueprint-specific emotional constraints, tighter than the family default:

- The child's hesitation is **never** mocked, sighed at, or framed as a flaw.
- The companion **never** urges, counts down, or expresses impatience.
- No character says the child was brave. The child notices it (page 8).
- The barrier is never made safe by an outside force. If it stops being frightening, the courage was not earned.
- No consequence for hesitating — no missed chance, nothing lost by waiting.

## A.9 Distinctness

**vs Pilot B:** B's obstacle is *not understanding*; A's is *not daring*. B's child works something out; A's child does something. Mechanism distance 3, beat distance 6.
**vs Pilot C:** C's need belongs to someone else and resolves through joint action; A's belongs to the child and resolves alone — the companion is present and deliberately idle at the decisive moment. Mechanism distance 3, beat distance 6.

The reader-facing difference: **A is the only pilot where nothing external changes.** Remove every noun and A is still the one where the world stays exactly as it was and the child is different at the end.

## A.10 Instantiation

**① Eski Taş Köprü + Cesur (köpek, loyal and brave) + a glowing light beyond**
The bridge sways. Cesur crosses easily and waits, tail going, not calling. The child names it: *I don't want to*. One foot on the first plank — it holds. Then the rest. The light is a lantern someone left. Walking home, the child keeps thinking about the first plank.

**② Kristal Mağara + Dikenli (kirpi, careful) + a sound from inside**
The entrance is dark and the sound comes from deep in. Dikenli is careful too, which makes it a companion rather than a contrast. The child puts a hand round the corner of the entrance — nothing happens. Then goes in. The sound is water on crystal. *Different story: the fear is of the dark, not of falling; the small step is a hand, not a foot; the companion shares the caution instead of modelling calm.*

**③ Şırıl Şırıl Nehir + Yavaş (kaplumbağa, patient) + something bright on the far bank**
The water is cold and moving. Yavaş swims it without effort — and the child stays. One ankle in. Then across. *Different again: here the companion's ease is the source of the sting, which page 4 must handle without the child feeling lesser.*

**Fails compatibility, correctly:** Güneşli Çayır (no `hasThreshold`) — there is nothing to cross, and the blueprint is unselectable rather than generating a crossing-free crossing story. Böğürtlen the bear (`canCarry`) — excluded, because the premise would quietly evaporate.

---

# PILOT B — `bp_unexplained_signal_001`

## B.1 Identity

**Family:** I — The Unexplained
**Premise:** *A child meets something they cannot explain, gathers what it does, forms an idea about why, and finds that acting on the idea is what makes it make sense.*

| Mechanism | Value |
|---|---|
| Curiosity | `unexplainedPhenomenon` |
| Conflict | `cognitive` — the thing is not understood |
| Resolution | `insight` — one step of reasoning, earned from shown evidence |

## B.2 Why this blueprint exists

This is a deduction story, and the pleasure is the **click**. Two design rules follow, both developmental:

1. **One inferential step, not a chain.** A 5–6-year-old can hold *this, therefore that*. They cannot hold *this, therefore that, therefore the other*. Every multi-step mystery at this age collapses into the adult explaining at the end — which is the failure mode this blueprint is built to avoid.
2. **The evidence must be on the page before the conclusion.** Pages 2 and 5 show; page 6 concludes. This is what lets the listening child get there a beat before the character does — the single greatest pleasure available in a picture book, and unreachable if the clue is withheld.

The companion carries `hasLocalKnowledge` and supplies exactly **one fact** — never the answer. Phase 1's agency rule is sharpest here: the owl may say *that light only comes after rain*; the child must be the one who says *then it's showing where the water went*. The moment the companion draws the conclusion, this blueprint has failed even though the text still reads fine.

## B.3 Emotional arc

`ease → curiosity → wonder → puzzlement → determination → insight → satisfaction → warmth`

Intensity: 0, 1, 1, 1, 1, 0, 0, 0 — the calmest pilot. There is no tension here, only a question, which is why it can open at `ease` where Pilot A cannot.

## B.4 Page architecture

### PAGE 1 — `hook` · beat `notice_anomaly`
**Narrative purpose:** Something is happening that does not fit the place.
**Emotional purpose:** Ease broken by a small wrongness.
**State out:** `anomalyKnown`
**Visual:** `full_bleed_establishing`
**Editorial:** Make it strange, not alarming. The reader should lean in, not brace.

### PAGE 2 — `discovery` · beat `examine`
**Narrative purpose:** The child observes specifics. **This is the evidence page.**
**Emotional purpose:** Curiosity becoming attention.
**State in:** `anomalyKnown` **State out:** —
**Visual:** `centered_portrait` — close, the detail legible in the illustration.
**Editorial:** Give **two** concrete observations, one of which matters later. Not "it was strange" — *when*, *how often*, *which direction*, *only where*. The reader is being handed the clue.

### PAGE 3 — `companion` · beats `meet_companion` + `companion_offers`
**Narrative purpose:** The companion arrives knowing the place, and states one fact about it.
**Emotional purpose:** Wonder — the fact makes the thing bigger, not smaller.
**State out:** `companionPresent`
**Visual:** `character_left_text_right`
**Editorial:** **One fact. Flat. No interpretation.** The companion does not speculate, guess, or lead. A literal-minded companion is ideal here, not a liability.

### PAGE 4 — `problem` · beats `form_belief` + `commit`
**Narrative purpose:** The child puts the observation and the fact together into an idea, and decides to test it.
**Emotional purpose:** Puzzlement resolving into a plan.
**State in:** `anomalyKnown` **State out:** `beliefFormed`, `committed`
**Visual:** `character_right_text_left`
**Editorial:** The idea is voiced as a **question or a maybe**, never a certainty — "Maybe it's…". This keeps page 6 available and models how thinking actually sounds.

### PAGE 5 — `attempt` · beats `first_attempt` + `obstacle_raises`
**Narrative purpose:** Testing the idea half-works. A specific complication appears — **and the complication is the second clue.**
**Emotional purpose:** Determination meeting friction.
**State in:** `committed` **State out:** `attemptMade`, `obstacleNamed`
**Visual:** `character_right_text_left`
**Editorial:** The complication must be concrete and must **contain** the answer. This is the page that makes page 6 earned rather than announced.

### PAGE 6 — `challenge` · beat `insight`
**Narrative purpose:** The child sees what the complication means. The click.
**Emotional purpose:** Insight.
**State in:** `obstacleNamed` **State out:** `solutionKnown`
**Visual:** `full_bleed_establishing` — the scene reframed, as if seen properly for the first time.
**Editorial:** The realisation names something the reader has already been shown. **Nothing new may be introduced on this page.** If the child needs a fact that has not appeared, the deduction is a trick.

### PAGE 7 — `resolution` · beat `succeed`
**Narrative purpose:** Acting on the insight works, and the phenomenon makes sense.
**State in:** `solutionKnown` **State out:** `resolved`
**Visual:** `centered_portrait`
**Editorial:** Explain it once, in the child's words, simply. Do not re-explain.

### PAGE 8 — `emotionalEnding` · beats `warm_close` + `carry_forward`
**Narrative purpose:** The child takes something away — an object, a habit of looking, a plan to come back.
**Emotional purpose:** Satisfaction settling into warmth.
**State in:** `resolved`
**Visual:** `quiet_closing`
**Editorial:** The takeaway should be *noticing*, not the object. The thing to carry forward is the looking.

## B.5 Content requirements

```
requires:
  setting:    [canConceal] ∨ [showsTraces]
  companion:  [hasLocalKnowledge]
  discovery:  [isUnexplained] ∧ ([emitsSignal] ∨ [isFragmentary])
forbids:
  discovery:  [impliesNeed]
  companion:  [isSmallAndVulnerable]
```

**On `forbids: discovery [impliesNeed]`** — the same boundary Pilot A draws, from the other side. If the unexplained thing turns out to need help, the story stops being about understanding and becomes an Appeal. Family I's subject is the question itself.

**On `forbids: companion [isSmallAndVulnerable]`** — a companion that needs looking after pulls attention onto care and away from thinking. It also tempts the author toward a rescue on page 7.

## B.6 Narrative state

`anomalyKnown` → p1 · `companionPresent` → p3 · `beliefFormed`, `committed` → p4 · `attemptMade`, `obstacleNamed` → p5 · `solutionKnown` → p6 · `resolved` → p7. Machine-checked.

Note `beliefFormed` is produced but never consumed in this pilot — `insight` requires only `obstacleNamed`. That is correct and deliberate: `beliefFormed` is what Family V consumes (via `belief_fails`). Its presence here marks where a Family V sibling would diverge, and costs nothing.

## B.7 Title families

`T3_secret`, `T2_achievement`, `T1_pairing`.

| Family | Example |
|---|---|
| `T3_secret` | "Yeliz ve Parlayan Işığın Sırrı" |
| `T2_achievement` | "Yeliz'in Ormandaki Büyük Keşfi" |
| `T1_pairing` | "Yeliz ve Fısıldayan Ormandaki Işık" |

Both `T2` and `T3` depend on the genitive and locative the resolver previously could not produce — they are directly enabled by §0 and would have shipped broken a week ago.

`T4_act` is excluded: nothing is *done* here in the sense `T4` implies.

## B.8 Safety

`childSafety: .strict` · `intensityCeiling: 1` — deliberately below the family ceiling. This story has no tension to manage.
**Forbidden outcomes:** `deusExMachina`, `problemUnresolved`, `childAtFault`

Blueprint-specific:
- The explanation must be **true within the story's world** and complete. A partial explanation reads as an adult deflecting.
- No magic as explanation. If the answer is "it was magic", nothing was deduced.
- The companion may not reach the conclusion, restate it, or confirm it before the child.

## B.9 Distinctness

**vs Pilot A:** cognitive vs internal conflict; nothing here is feared and nothing is crossed. Beat distance 6.
**vs Pilot C:** no one needs anything in B. The companion is a source of information, not of need. Beat distance 7 — the furthest pair in the set.

Reader-facing: **B is the only pilot where the child's decisive act is a thought.**

## B.10 Instantiation

**① Fısıldayan Orman + Bilge (baykuş, wise) + a glowing light**
The light appears between the trees, always in the same place. Bilge notes that it only shows after rain. The child thinks maybe it is the water. They dig at the spot and find not water but the wet stones the light is bouncing off — and the second clue is that it only glows when the sun is low. The child sees it: the stones are catching the last light. They come back at dusk on purpose.

**② Ay Yüzeyi + Zip (robot, logical and baffled) + a blinking light**
The light blinks in a pattern. Zip states, flatly, that nothing on this side of the moon makes light. The child counts the blinks — three, then a gap. Following them means going where they get dimmer, not brighter. That is the clue: they are not a signal *to* anyone, they are a reflection *of* something. The pattern is a shadow crossing. *Structurally identical, unrecognisable as the same story: the reasoning is counting, the setting does the work of strangeness, Zip's literal-mindedness is the perfect delivery for an unadorned fact.*

**③ Gizli Bahçe + Pırıltı (ateşböceği, helpful) + a flower that opens and closes**
It opens in the afternoon and shuts by the time the child leaves. Pırıltı mentions it only ever flies there when the flower is open. The child tries visiting earlier — shut. Then notices it opens when the shadow of the wall has moved past. The flower is following the sun. *Note: `Pırıltı` is a possessive-stem word (`ateşböceği`) and needs the buffer; this instantiation exists partly to keep that case exercised in review.*

**Fails compatibility, correctly:** a discovery-kind with `impliesNeed` (an injured bird) — recruits Family III instead. A companion without `hasLocalKnowledge` — page 3 has no fact to offer and the deduction has only one leg.

---

# PILOT C — `bp_appeal_reunion_001`

## C.1 Identity

**Family:** III — The Appeal
**Premise:** *Someone small needs to get back to where they belong and cannot manage it alone. What closes the distance is the one thing the child can do and they cannot.*

| Mechanism | Value |
|---|---|
| Curiosity | `anotherStatedNeed` |
| Conflict | `relational` |
| Resolution | `cooperation` — two contributions, both necessary |

## C.2 Why this blueprint exists

Helping stories fail in two predictable ways, and both are visible in the existing corpus.

**Failure one: the child as taxi.** The companion needs to get somewhere, the child carries it, the end. There is no story, because there was never a difficulty — only a distance.

**Failure two: the companion as protagonist.** Phase 1 found this shipping today — the fox is lost, the fox is frightened, the fox asks; the child watches. The book is about the fox with the child's name on the cover.

The structural fix is a single rule, and it is what this blueprint is for:

> **The obstacle must be one the companion's own traits cannot solve, and the solution must require something the companion lacks and the child has.**

Reach. Height. Hands. Steadiness. A voice loud enough. That makes `cooperative_effort` honest — two contributions, both necessary — rather than decorative. A bird that could simply fly home is not in trouble; a bird that can fly but cannot lift the branch off its nest is.

This is the hardest of the three pilots to author well, which is why it is in the pilot set rather than Phase 5.

## C.3 Emotional arc

`ease → curiosity → sympathy → concern → determination → effort → relief → warmth`

Intensity: 0, 1, 1, 2, 1, 2, 0, 0. `concern` at page 4 is the peak and is *about someone else* — the safest kind of tension available at this age, because the reader is never the one at risk.

## C.4 Page architecture

### PAGE 1 — `hook` · beat `notice_anomaly`
**Narrative purpose:** The child notices a sign that something is wrong — a sound, a scatter, a small voice.
**Emotional purpose:** Ease interrupted.
**State out:** `anomalyKnown`
**Visual:** `full_bleed_establishing`
**Editorial:** The sign, not the sufferer. Meeting them on page 3 is the point of page 3.

### PAGE 2 — `discovery` · beat `approach`
**Narrative purpose:** The child follows it and finds the situation.
**Emotional purpose:** Curiosity tipping toward concern.
**State in:** `anomalyKnown`
**Visual:** `centered_portrait`
**Editorial:** Show the situation before the need is voiced. The reader should work out that something is wrong a moment before being told.

### PAGE 3 — `companion` · beats `meet_companion` + `receive_appeal`
**Narrative purpose:** The companion is met and states what it needs, in its own words.
**Emotional purpose:** Sympathy.
**State out:** `companionPresent`, `needKnown`
**Visual:** `character_left_text_right`
**Editorial:** The companion asks **plainly and once**. No pleading, no distress, no tears. It is a small problem stated by someone small, which is what keeps it safe.

### PAGE 4 — `problem` · beats `commit` + `obstacle_raises`
**Narrative purpose:** The child agrees to help, and the specific difficulty appears.
**Emotional purpose:** Concern — the peak.
**State in:** `needKnown` **State out:** `committed`, `obstacleNamed`
**Visual:** `character_right_text_left`
**Editorial:** **The obstacle must be one the companion cannot solve with what it has.** Name it concretely. This page carries the whole blueprint; a vague obstacle here produces a vague cooperation on page 6.

### PAGE 5 — `attempt` · beat `first_attempt`
**Narrative purpose:** The obvious try. It does not quite work — and how it fails shows what is missing.
**Emotional purpose:** Determination.
**State in:** `committed` **State out:** `attemptMade`
**Visual:** `character_right_text_left`
**Editorial:** Fail informatively, not discouragingly. Nobody is at fault. The failure names the missing piece.

### PAGE 6 — `challenge` · beat `cooperative_effort`
**Narrative purpose:** They combine what each can do. **Both contributions are necessary and both are visible.**
**Emotional purpose:** Effort, shared.
**State in:** `companionPresent` ∧ `obstacleNamed` **State out:** `solutionKnown`
**Visual:** `full_bleed_establishing`
**Editorial:** State both parts in the same breath: *the companion did X while the child did Y*. If either could have managed alone, rewrite the obstacle on page 4 — not this page.

### PAGE 7 — `resolution` · beat `restore`
**Narrative purpose:** The companion gets back where it belongs. The reunion, not the victory.
**Emotional purpose:** Relief.
**State in:** `solutionKnown` ∧ `needKnown` **State out:** `resolved`
**Visual:** `centered_portrait`
**Editorial:** Let the arrival land. `restore` is a different note from `succeed` — quieter, and about someone else's relief rather than the child's achievement.

### PAGE 8 — `emotionalEnding` · beat `warm_close`
**Narrative purpose:** The friendship, briefly, and the way home.
**Emotional purpose:** Warmth.
**State in:** `resolved`
**Visual:** `quiet_closing`
**Editorial:** No reward, no gift, no thanks that reads as payment. The warmth is the point; a prize would cheapen it.

## C.5 Content requirements

```
requires:
  setting:    [hasDistance]
  companion:  [isSmallAndVulnerable] ∧ ([canFly] ∨ [hasLocalKnowledge] ∨ [isPatient])
  discovery:  [impliesNeed] ∨ [impliesPresence]
forbids:
  companion:  [canCarry]
constraint:
  the obstacle named on page 4 must not be soluble by the companion's declared traits
```

That last line is a **per-blueprint authoring constraint**, not a trait filter — it cannot be expressed as a set intersection, and it is the rule the whole blueprint rests on. It is checked at editorial review and stated in `editorialGuidance` so a human sees it. Phase 6 should test it by instantiating against every compatible companion and asking, for each: *could this animal have done it alone?*

The companion needs the vulnerability **and** a capability — that second clause is what makes cooperation possible. A companion with no capability produces a rescue, not a partnership.

## C.6 Narrative state

`anomalyKnown` → p1 · `companionPresent`, `needKnown` → p3 · `committed`, `obstacleNamed` → p4 · `attemptMade` → p5 · `solutionKnown` → p6 · `resolved` → p7. Machine-checked.

`restore` is the only closing beat requiring both `solutionKnown` **and** `needKnown`, which is precisely what makes it unavailable to Pilots A and B — neither produces `needKnown`. The state model enforces the distinction rather than relying on the author to observe it.

## C.7 Title families

`T1_pairing`, `T5_journey`.

| Family | Example |
|---|---|
| `T1_pairing` | "Yeliz ve Yolunu Kaybeden Fındık" |
| `T5_journey` | "Güneşli Çayır'a Uzun Yolculuk" |

`T2_achievement` and `T3_secret` are excluded — both centre the child's discovery, and this story's subject is someone else's return. `T4_act` is excluded as too triumphal for a `restore` ending.

## C.8 Safety

`childSafety: .strict` · `intensityCeiling: 2`
**Forbidden outcomes:** `companionLost`, `characterHarmed`, `characterAbandoned`, `problemUnresolved`, `childAtFault`

Blueprint-specific — this is the pilot where emotional safety needs the most care, because the tension is someone's distress:

- The companion is **never in danger**, only inconvenienced. Separated, stuck, out of reach — never at risk.
- Nothing is lost permanently. No injury, no bereavement, no home destroyed.
- Whoever the companion returns to is **present and fine** throughout. The reader must never wonder whether they are all right.
- The child is never responsible for the problem, and never fails the companion.
- No gratitude framed as debt.

## C.9 Distinctness

**vs Pilot A:** the need is external and the resolution is joint; A's is internal and solitary. Beat distance 6.
**vs Pilot B:** B has no need in it at all — the companion informs rather than asks; B's page 7 is `succeed`, C's is `restore`. Beat distance 7.

Reader-facing: **C is the only pilot whose ending belongs to someone other than the child.**

## C.10 Instantiation

**① Güneşli Çayır + Fındık (sincap, energetic) + scattered nuts**
Nuts scattered across the path. Fındık has knocked its store from a branch too high to climb back to with full paws. It can climb; it cannot carry and climb at once. The child can reach the low fork but not the store. They try throwing — nuts everywhere. Then: the child passes them up one at a time while Fındık climbs and stows. *Both necessary: the child's reach, the squirrel's climb.*

**② Gizli Bahçe + Pırıltı (ateşböceği, helpful) + a fading glow**
Pırıltı's light is dimming and it needs to be back among the others before dark, but it cannot fly far and the wall is long. It knows the way; it has no distance. The child tries carrying it in cupped hands — too fast, the light gutters in the wind. Then: the child walks the long way round, slowly, out of the wind, while Pırıltı calls the direction from the cupped hands. *The child's legs, the firefly's knowledge.*

**③ Karlı Vadi + Yonca (tavşan, gentle but timid) + tracks in the snow**
Tracks leading the wrong way. Yonca has come down the slope and cannot get back up — the snow gives under it, being light is the whole problem. It knows which notch in the ridge is home. The child tries lifting it up — the bank crumbles. Then: the child packs a flat path with their boots and Yonca hops it, calling which way at each turn. *The child's weight, the rabbit's certainty. The trait that makes it vulnerable is the trait that makes it stuck — the cleanest version of the page-4 rule in the set.*

**Fails compatibility, correctly:** Böğürtlen the bear — not `isSmallAndVulnerable`, and `canCarry`. Kıvılcım the dragon — has neither the vulnerability nor the scale for it. A `hasDistance`-less setting (Kristal Mağara alone) — there is no "back" to return to.

---

## 4. Cross-pilot review

### 4.1 The diversity gate

| Pair | Mechanism | Arc unique | Beat distance | Verdict |
|---|---|---|---|---|
| A ↔ B | 3 of 3 | yes | 6 | **Pass** |
| A ↔ C | 3 of 3 | yes | 6 | **Pass** |
| B ↔ C | 3 of 3 | yes | 7 | **Pass** |

All three clear the ≥2 mechanism / unique arc / ≥3 beat thresholds with margin.

### 4.2 The nouns-removed test

The brief's §25, applied honestly. Strip every name:

- **A** — a child wants something across a barrier, is afraid, does a small version, then the whole thing, and is different at the end. Nothing external changed.
- **B** — a child sees something that does not fit, collects two facts, puts them together, and is right. Nothing was feared and nothing was crossed.
- **C** — someone small cannot get home, the obvious help fails, and two different abilities together do what neither could. The ending belongs to them, not the child.

Three different stories. This is the test the five existing `adventure_courage_*` blueprints fail — four of them reduce to *the child had a good idea*.

### 4.3 What the set proves

- Same page role, genuinely different pages: page 4 is `hesitate` / `form_belief`+`commit` / `commit`+`obstacle_raises`. Page 7 is `succeed` / `succeed` / `restore`.
- Exclusions carry identity: A forbids `canCarry`, B forbids `impliesNeed`, C forbids `canCarry` for a different reason. Each exclusion, removed, would let the blueprint generate a coherent story that is no longer *that* blueprint — the silent failure Phase 1 documented.
- Child agency holds under substitution: nine instantiations, and in every one the decisive act is the child's.
- The discovery-kind does real work: `isBeautiful`/`emitsSignal` pulls A, `isUnexplained`+`emitsSignal` pulls B, `impliesNeed` pulls C. The third user choice selects the shape of the story, as designed.

### 4.4 What it does not yet prove

Stated plainly, because these are Phase 4's job and should not be claimed here:

- **Intra-family distinctness is untested.** All three pilots are from different families, where separation is guaranteed by construction. The real question — can Family I hold three blueprints that feel different? — is unanswered.
- **No prose exists.** These are architectures. Whether `insight` can be written in 18–38 Turkish words for a 5-year-old, repeatedly and without formula, is unproven. The V1 corpus suggests yes and also shows the risk: four of five files open that page with the same sentence.
- **Template supply is unestimated.** Each beat needs enough variants that two books from one blueprint do not rhyme. How many is a Phase 4 measurement.
- **The page-4 constraint in Pilot C is editorial, not machine-checkable.** It is the weakest enforcement point in the set and the most likely place for quality to slip at volume.

### 4.5 Recommended Phase 4 matrix

Per pilot, instantiate against: forest+fox+light · mountain+owl+footprints · garden+hedgehog+sound · sea+dolphin+shell · forest+rabbit+map — recording for each whether it (a) passes compatibility, (b) produces a coherent arc, (c) reads as a different story from the same blueprint's other instantiations.

Combinations that *should* fail are as informative as those that pass: `mountain+owl+footprints` ought to be rejected by Pilot B (footprints are `impliesPresence`, not `isUnexplained`) and accepted by a Family IV or V blueprint. If it passes everything, the traits are too loose.

---

## 5. Open items for review

1. **Pilot B's `intensityCeiling: 1`** is below the age band's permitted 2. I set it deliberately — a deduction story with tension is a different story — but it means the library will not have uniform intensity, and a parent choosing "Adventure" may get a notably calmer book. Worth a product decision.
2. **Family II's arc revision** (§0) changes a Phase 2 artefact. Flagged rather than silently applied.
3. **Pilot C's page-4 constraint** needs a home. Options: `editorialGuidance` prose (weakest), a new `authoringConstraints` field carrying a closed enum the QA suite can enumerate (better), or a Phase 6 review checklist item (adequate). I lean to the second and will propose it in the catalog unless directed otherwise.
4. **`beliefFormed` is produced but unconsumed in Pilot B** (§B.6). Harmless and intentional — it marks the Family V divergence point — but if it is still unconsumed after Phase 5, it should be dropped from Family I's beats rather than left as decoration.
