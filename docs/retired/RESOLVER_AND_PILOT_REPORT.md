# Turkish resolver completion + Pilot A (Family II)

**Date:** 2026-09-15
**Scope:** the §16 blocker, then one pilot blueprint. No selection engine, no
content migration, no UI, no changes to V1 content.
**Result:** ✅ Both done. **564 package tests, 0 failures.** App `BUILD SUCCEEDED`.

---

## Part 1 — The resolver

### What was actually missing

The resolver had already been substantially rebuilt: `TurkishGrammar.swift`
covers genitive, dative, accusative, locative and ablative with vowel harmony,
buffer consonants, d/t assimilation, proper-noun apostrophes and possessive
stems, under 29 passing tests. §16's description of it — *"does not implement
the cases that `T2_achievement` and `T3_secret` need, and silently emits
ungrammatical output rather than failing"* — was true when written and is now
true only in part.

I probed all five title families rather than assuming. Four rendered cleanly.
**One gap was real:**

```
T2 setting LOC+ki :: Yeliz'in Fısıldayan Orman'daki Büyük Keşfi
                  :: clean=false  unrecognised=["daki"]
```

`-daki` — locative plus the relative `-ki` — was unrecognised, and
`T2_achievement` is built on it. The second half of §16's charge no longer
applied: the renderer *reported* it rather than emitting silently, which is the
correct failure mode and is what made the gap findable in one probe.

### The fix

`-ki` is not a case. It is derivational: it turns a locative into an adjective
("orman" → "ormandaki ışık"). Folding it into `TurkishCase` would have been a
lie — the result is no longer a case form and cannot take another one. So the
parsed request is now its own type:

```swift
public enum TurkishSuffixRequest {
    case grammaticalCase(TurkishCase)
    case locativeRelative
}
```

and the relative form is built **on top of** the locative rather than beside it,
so it inherits everything the locative already gets right:

| Input | Output | Inherited behaviour |
|---|---|---|
| `orman` | `ormandaki` | vowel harmony |
| `kitap` | `kitaptaki` | voicing assimilation, softening correctly suppressed |
| `Fısıldayan Orman` (proper) | `Fısıldayan Orman'daki` | apostrophe before the ending, not after |
| `Bulut Krallığı` (possessive) | `Bulut Krallığı'ndaki` | the `-n-` buffer |

All eight authored spellings (`daki/deki/taki/teki` + the buffered `ndaki/…`)
map to the same request and are **recomputed from the word that arrives**, so a
mis-authored guess is corrected rather than passed through. `-ki` is emitted
invariant, which is correct here and not a shortcut: the vowel it follows is the
locative's, only ever `a` or `e`, so the harmonised `-kü` ("dünkü") is
unreachable from this position.

`-ninki` and a bare `-ki` are **not** accepted. They are real suffixes the
resolver does not model, and approximating them is precisely the defect this
type exists to prevent.

Also factored out: `TurkishCase.normalise`, so both parsers share one
apostrophe-stripping, Turkish-locale lowercasing step. Turkish casing matters —
`I` lowercases to `ı`, not `i` — and it is now pinned by test.

**17 new tests.** The four pre-existing cases are unaffected; `TurkishCase` and
its 29 tests are untouched.

### §9 is unblocked

> *"Title families cannot ship until the resolver covers `GEN`, `LOC`, `DAT`,
> `ACC` with correct buffer consonants and proper-noun detection."*

All four, plus `ABL` and now `LOC+ki`. All five title families render clean.

---

## Part 2 — Pilot A: Family II, The Threshold

`Sources/StoryEngine/Resources/blueprints/pilot_threshold_v1.json`

The first blueprint authored *by* the beat schema rather than *as* it. The six
reference arcs already in CI are transcriptions of the design document, checked
against rules the same document defines; a pilot is the first chance for the two
to disagree.

**Premise:** the child wants to reach something on the far side of a boundary,
and the boundary is not what stops them.

| Page | Role | Beat | Supporting | Emotion |
|---|---|---|---|---|
| 1 | hook | `notice_anomaly` | — | curiosity |
| 2 | discovery | `approach` | — | wonder |
| 3 | companion | `meet_companion` | `companion_offers` | warmth |
| 4 | problem | `hesitate` | `commit` | hesitation |
| 5 | attempt | `small_step` | — | effort |
| 6 | challenge | `find_own_courage` | — | determination |
| 7 | resolution | `succeed` | — | relief |
| 8 | emotional_ending | `self_recognize` | `warm_close` | pride |

It passes `BeatSequenceValidator` unaided: preconditions met in order,
`resolved` on page 7 exactly, obstacle named by page 5, closing beats only on
page 8, ceiling 2, settled landing, no three consecutive tense pages.

**It is a variant, not a copy.** It differs from the document's Family II
reference arc by two beats — the companion offers, and the child commits *before*
the hesitation is overcome rather than after. That ordering is the blueprint's
own reading of Family II: the child decides, and still has to find the courage.

### What the pilot needed that did not exist

§8's trait vocabulary. Without it a blueprint cannot say what it is, and §8.3 is
explicit that exclusions are where identity lives. Added as pure data — no
selection logic, which remains I3:

- `SettingTrait`, `CompanionTrait`, `DiscoveryTrait` (the closed vocabularies from §8.1)
- `ContentRequirements` / `ContentExclusions`
- `TraitMatch.admits` and `TraitMatch.rejection` — the latter returns *why*, never a bare no
- `CatalogBlueprint.requires` / `.forbids` / `.premise` / `.editorialName` /
  `.editorialGuidance`, all optional so the V1 catalog still decodes unchanged
- `CatalogBlueprint.contradictoryTraits` — requiring and forbidding the same
  trait is cheap to write and invisible at runtime; the pool is simply always empty

The pilot's identity:

```
requires:  setting   [hasThreshold]
           companion [canReassure]
           discovery [isUnexplained, emitsSignal]
forbids:   companion [canFly, canCarry]
```

### The exclusion does real work

Run against the Phase 4 matrix, and asserted in CI:

| Combination | Verdict | Why |
|---|---|---|
| forest + fox + light | ✅ admitted | |
| garden + hedgehog + sound | ✅ admitted | |
| mountain + owl + footprints | ❌ | the owl flies; footprints do not signal |
| sea + dolphin + shell | ❌ | no threshold; the dolphin carries; the shell is silent |
| forest + rabbit + map | ❌ | nothing reassures; the map does not signal |

Two of five, each rejection for a stated reason. This is the behaviour §8.4
requires in place of `if filtered.isEmpty { return items }`: a companion that can
carry the child across dissolves the premise without breaking anything — the
story still generates, it is just no longer this story.

### Titles

Three patterns, spanning `T1_pairing`, `T2_achievement` and `T5_journey`. Every
one renders clean against both kinds of setting name, which is why the resolver
had to be finished first — authoring these last week would have baked
`Orman'nde` into the corpus.

```
Yeliz ve Fısıldayan Orman'daki Işık          Demir ve Gece Bahçesi'ndeki Işık
Yeliz'in Fısıldayan Orman'daki Cesur Adımı   Demir'in Gece Bahçesi'ndeki Cesur Adımı
Fısıldayan Orman'a Cesur Yolculuk            Gece Bahçesi'ne Cesur Yolculuk
```

**18 new tests**, including the one that matters most for D2: the pilot is a
separate resource and is asserted **not** to have been merged into
`shared_content_library_v2.json`. V1 content is byte-unchanged.

---

## Verification

| Check | Result |
|---|---|
| Package build | ✅ 0 errors |
| Package tests | ✅ **564 passed, 0 failures** (+35 new) |
| App build | ✅ `BUILD SUCCEEDED` |
| Pilot ships into the `.app` | ✅ `StoryEngine_StoryEngine.bundle/pilot_threshold_v1.json` |

One thing worth recording about that last row: the pilot was **absent** from the
first app build. That was Xcode reusing a cached package resource bundle, not a
packaging defect — deleting the stale bundle and rebuilding produced it. It also
confirms again that `.process("Resources")` flattens subdirectories: the file
authored at `Resources/blueprints/…` ships at the bundle root, which the test
asserts by name so a change surfaces as a named failure.

---

## Known issues

| # | Issue | For |
|---|---|---|
| P1 | **No templates realize the pilot's beats.** It validates and is selectable in principle, but cannot yet be instantiated into prose. This is the authoring job §16 describes as "enough beat-tagged variants" | next |
| P2 | Title casing is not handled. The renderer preserves a slot's own casing, which is correct — but `T3_secret` against a lowercase object name yields *"Yeliz ve kayıp haritanın Sırrı"*. Title-casing belongs to the title composer | I4 |
| P3 | `-ninki` (genitive + relative) is unmodelled and reported. Fine today; revisit if a title family needs it | if needed |
| P4 | `TraitMatch` exists but nothing calls it — the selection engine is I3. The pilot's constraints are therefore proved by test, not yet enforced at load | I3 |
| P5 | fal.ai API key still hard-coded in three files, in git history | **Urgent** |

---

## Next

Pilot A is structurally complete and unexercised in prose. The two candidates:

1. **Author the pilot's variants** (P1) — makes one blueprint end-to-end real,
   and gives I3 genuine content to select rather than a fixture.
2. **Build I3** (selection, scoring, the empty-pool diagnostics) — makes the
   pilot's `requires`/`forbids` load-bearing rather than documentation.

They unblock each other; either order works. I lean (1), because a blueprint
that has never produced a sentence has not really been tested.

**Stopping here.** Pilots B and C not started; I3 not started.
