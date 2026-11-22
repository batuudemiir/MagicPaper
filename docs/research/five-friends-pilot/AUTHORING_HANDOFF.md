# P56 authored source handoff — 22 November 2026

**Status:** authored internal corpus, independent review and engine integration pending.

Package: [five-friends-56-v1](../../../Content/Pilots/five-friends-56-v1/README.md). Entry point: [manifest](../../../Content/Pilots/five-friends-56-v1/manifest.json).

Delivered: nine reusable causal structures; thirty allowed character/structure books, eight full pages each; 240 actual page sources with ordered trace and sentence segment source IDs. All books use synthetic Deniz, age 5–6. Bedtime uses a distinct new forest-edge room; learning/adventure use exact `setting_whispering_forest_001`. Canonical companion IDs are preserved; no legacy content is migrated or mutated.

## Structural differences

| Shape | Mechanism | Child's necessary action | Character adaptation |
|---|---|---|---|
| U1 | Familiar sound ritual | Chooses known sounds, then stops attending | Fox waits, owl listens on perch, bear rests on broad floor bed |
| U2 | Comfort choice and space | Prepares according to preference and leaves room | Hedgehog needs tassel-free surface; visiting cat chooses flat cushion; bear chooses thin cloth on broad floor bed |
| U3 | One memory then release | Selects one small moment and closes telling | Fox/gentle pause, hedgehog/shared small steps, owl/observed light, visiting cat/curled tail |
| L1 | Two observations and causal test | Compares contact with coincident sound and rechecks | Fox reports proximity, owl reports gap closure, cat reports absence of pre-contact sound |
| L2 | Combine viewpoints | Walks around and joins two partial views | Low hedgehog view, low perched owl view, bear stepping back to leave the child a view |
| L3 | Wait and reobserve | Keeps a fixed viewpoint and compares one drop | Fox shares waiting, hedgehog watches comfortably, cat keeps paws at stone, bear keeps paws away |
| A1 | Self-paced threshold | Chooses small steps and crosses on own feet | Fox waits; hedgehog takes own smaller steps; cat slows without racing |
| A2 | Sequence plus complementary contribution | Orders two light marker pieces | Fox/bear hold an explicit edge; owl supplies an explicit second observation, without invented hands |
| A3 | Retrace own observation | Recognizes personally remembered root and retrieves cloth | Hedgehog follows pace; owl makes one explicit short flight; cat slows and looks back; bear leaves child physical access |

These are three mechanisms per mode; within a shape some source pages are shared editorial functions. Thirty books must not be reported as thirty independent mechanisms. Pilot sentence sources are currently concrete fixtures, not a production combinatorial slot library.

## Temporal and art handoff

Every book page has full text, previous/next page index, source pointer/digest, full repeated context, present/remembered/intended subjects, action actor/evidence, anatomy/scale constraints and explicit false art approval. U3 keeps recalled daytime objects out of the room; A3 p2 root is remembered, p5 root is visible, p6 cloth is recovered in the child's hand, p7–8 cloth is in pocket. Negative actions are not illustration requests.

`pilot56_discovery_*` identifies new authoring semantic groups, not existing `DiscoveryObject` records. Existing assets cannot be bound by these IDs without a separately reviewed adapter and art rule. No asset reuse or new art approval is implied. Scene object subdivision and runtime `PageProvenance` mapping remain follow-up work.

## Final verification handoff

Per repository instruction, no tests/builds were run during authoring. Root should run this check in the final verification pass:

```sh
python3 Content/Pilots/five-friends-56-v1/validate_authoring.py
```

It checks cardinalities, exact pairs/cells, hashes, complete source pointers, sentence partition, filled text, bedtime room closure and forbidden approval flags. Its word-count warnings reference the historical 144–304 range and do not prove current engine age acceptance. It does not validate prose quality, causal logic, real `StoryBeat` transitions, personalization/inflection, safety, seeds or art coverage.

Before runtime acceptance: independent review of all thirty books; valid beat/state compiler mapping; exact age/sentence budgets and paraphrase refinement; source snapshot integration; supported-context guards; 1,500 first-attempt trials with failures in denominator; full art coverage report; explicit product release decision. No release inference follows from successful offline integrity checks.
