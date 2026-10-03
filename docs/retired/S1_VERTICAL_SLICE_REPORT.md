# S1 — The vertical slice: Pilot A produces a real story

**Date:** 2026-09-15
**Scope:** the thin slice of I3 + I4 + I8 needed for one blueprint to produce
Turkish prose, plus the fal.ai key removal. No scoring, no novelty/cooldown, no
diversity gate, no persistence, no UI, no changes to V1 content.
**Result:** ✅ **584 package tests, 0 failures.** App `BUILD SUCCEEDED`.

---

## Part 1 — The fal.ai key

The key was hard-coded in three files: `FalImageService.swift`,
`FalImageGenerator.swift`, `FalAIImageGenerator.swift`.

**A correction, since retracted.** This report originally claimed the repository
was not under version control and that the "key is in git history" finding
(K5/J7/R6/P5) was therefore unverifiable. **That was wrong.** I ran
`git rev-parse` from `MagicPaperAPP/`, one level *above* the repository, which
is rooted at `MagicPaperAPP/MagicPaper/`. There are 40 commits.

The original audits were right: the key **is** in history. It was introduced in
`c435ebc Initial Commit` (2026-01-28); `141f67d` (2026-01-30) removed it from
some files but not from the three services, where it remained until today.
Rotation is genuinely urgent, and removing it from the working tree does not
remove it from history.

### What changed

The project already had the right mechanism and fal.ai simply never used it:
`Secrets.xcconfig` → build setting → `Info.plist`, which is how `GEMINI_API_KEY`
and `REVENUECAT_API_KEY` already worked.

- New `Helpers/APIKeys.swift` — one resolver, environment first then `Info.plist`.
- All three services now read `APIKeys.fal`.
- Both bridge providers (`FalImageProvider`, `GeminiStoryAIProvider`) had their
  own duplicate lookups; both now call the same resolver. One place to rotate.
- `FAL_API_KEY` added to `Secrets.xcconfig` and `Info.plist`.

It resolves an unset key to `nil` rather than to the literal `"$(FAL_API_KEY)"`.
Xcode leaves that placeholder in place when the setting is missing, and passing it
to a provider produces a 401 that reads like an expired credential rather than a
missing one.

`APIKeys.swift` went into `Helpers/`, not `Services/`, for a concrete reason:
`Helpers/` is a `PBXFileSystemSynchronizedRootGroup` and `Services/` uses explicit
membership. A new file in `Services/` compiles nowhere — which is exactly K1, the
thirteen files on disk that were never in any target. The first build failed with
`cannot find 'APIKeys' in scope` and proved it.

### What this does and does not fix

| | |
|---|---|
| ✅ Out of source — **0 occurrences** in the built binary (`strings`) | |
| ✅ One place to rotate, for both the legacy and engine paths | |
| ❌ **Still readable in the shipped app.** It sits in `Info.plist` inside the `.app`; anyone who unzips an IPA can read it. Inherent to this mechanism, and equally true of the two keys that already used it | |

**Treat the key as compromised and rotate it at fal.ai.** That is an account
action; I cannot do it. A client-side key for a paid image API is exposed by
construction — the durable fix is a server-side proxy, which is beyond this work.

---

## Part 2 — The vertical slice

### Why a slice instead of finishing I3

I2-R left R1 open: nothing in the catalog had beats, so no blueprint was
selectable. Pilot A then validated structurally but had never produced a
sentence. Building I3 in full would have meant testing a selection engine
against fixtures — the same gap, one layer up. The slice closes it by making one
blueprint work end to end and letting the rest be extended against real content.

### What was built

```
OfflineStoryIntent  →  OfflineContentBinder  →  OfflineStoryComposer  →  ComposedStory
   (3 choices + seed)     (trait intersection)     (beat → template → variant)
                                                    TitleComposer
```

| File | Contains |
|---|---|
| `Offline/OfflineSelection.swift` | `OfflineStoryIntent`, `OfflineSelectionError`, `BoundContent`, `OfflineContentBinder`, `DeterministicPicker` |
| `Offline/OfflineStoryComposer.swift` | `ComposedPage`, `ComposedStory`, `OfflineStoryComposer` |
| `Offline/TitleComposer.swift` | `TitleComposer` |
| `Content/ContentTraits.swift` *(from the pilot step)* | trait vocabularies, `TraitMatch` |

Content records gained two things they needed and lacked: `traits` (§8.1), and
the Turkish grammar flags the renderer says content must declare —
`isProperNoun`, `hasPossessiveEnding`, `blocksSoftening`. All optional, so V1
decodes unchanged. `hasPossessiveEnding` is the one that genuinely cannot be
inferred: "Karlı Vadi" and "Ay Yüzeyi" both end in *-i* and inflect differently.

### The content

`pilot_threshold_v1.json` is now a complete, self-contained package: the
blueprint, **11 templates / 33 variants** covering all 11 beats it needs, and
2 settings, 2 companions, 2 discoveries carrying traits.

**On harvesting V1 (D2).** The honest finding is that there was very little to
harvest. Of 52 templates, **49 are filler** — `template_companion_0` through
`_4` and `template_problem_0` through `_4` all contain the same sentence,
"{{child.name}} ve {{companion.name}} birlikte çok eğlendi", twice each. Three
templates are real authored prose. This is `CONTENT_AUDIT.md`'s conclusion
visible directly in the data, and it is why twelve blueprints produced one story.

The three real ones were harvested — the "Güneşli bir sabah…" opening and the
companion's arrival are kept close to verbatim. **One was rewritten, and it is
the important one:**

> V1 `template_problem_real_001`: *"Ama ilerideki yol çok karanlıktı.
> **{{companion.name}} bir adım daha atmaya korkuyordu.**"*

The fear belongs to the companion. That is precisely what
`BLUEPRINT_ARCHITECTURE.md` §16 names as the thing the corpus cannot do, and the
reason Family II was chosen as Pilot A. The sentence structure is kept; the
subject moved to the child:

> Pilot `hesitate`: *"Ama {{child.name}} olduğu yerde durdu. Bir adım daha atmak
> birden çok zor geldi."*

### It produces this

```
Yeliz'in Fısıldayan Orman'daki Cesur Adımı

1. Yeliz her zamanki yoluna gidiyordu ki bir şey onu durdurdu. Fısıldayan
   Orman'ın öte yanında titrek bir ışık vardı ve daha önce hiç orada yoktu.
2. Merakına engel olamadı. Yeliz yavaşça Fısıldayan Orman'a doğru yürüdü ve
   titrek bir ışığı daha yakından fark etti.
3. Yeliz etrafına bakınırken neşeli bir ses duydu. Minik tilki Tarçın zıplayarak
   yanına geldi. "Korkacak bir şey yok," dedi Tarçın. "Ben de seninle gelirim."
4. Yeliz'in ayakları ilerlemek istemedi. İçinde küçük bir çekingenlik vardı ve
   bunu saklamadı. "Tamam," dedi Yeliz kendi kendine. "Deneyeceğim."
5. Yeliz yavaşça bir adım ilerledi. Kalbi hızlı atıyordu ama geri dönmedi.
6. Bir şey değişmemişti; değişen Yeliz'in kendisiydi. İçindeki o çekingenlik
   yavaşça yerini başka bir şeye bıraktı.
7. Ve Yeliz karşıya geçti. Titrek bir ışık tam oradaydı, beklediği gibi.
8. Yeliz o gün kendisi hakkında yeni bir şey öğrendi. Durakladığında bile devam
   edebiliyordu. Tarçın yanında yürüyordu. Hava yavaşça kararıyordu ve her şey
   yerli yerindeydi.
```

Page 4 is `hesitate` + `commit` — the reluctance named, then the decision. Page 6
is interior: nothing outside the child changes. That is Family II, and it is the
page the old corpus could not write.

---

## Four defects the slice found

None of these was caught by any unit test, because each lives at a seam.

| # | Defect | Fix |
|---|---|---|
| 1 | **A page assumed a modality.** A discovery may be a light *or* a sound; three variants used *görebildi* / *gördü*, so the engine produced "ince bir sesi daha yakından **görebildi**" — it saw a sound | Rewrote to modality-neutral verbs. A test now asserts no page ever sees a sound |
| 2 | **Sentence-initial lowercase.** A common-noun discovery landing after a full stop stayed lowercase: "…öte yana ulaştı. **titrek bir ışık** tam oradaydı" | Renderer fix — general, not content-specific |
| 3 | **A past copula.** I authored "değişen {{child.name}}'di". `-di` is not a case; the renderer *reported* it rather than emitting it, which is the correct failure mode. Left unmodelled it would produce "Ahmet'di" where Turkish needs "Ahmet'ti" | Rewrote the sentence. Copula support logged as a known gap, not silently added |
| 4 | **Two adjacent beats both opened with "Ama."** `hesitate` and `commit` always share page 4 | Rewrote `commit` |

Defect 2 is the one worth keeping: it is the same class as the `T3_secret`
casing issue flagged as P2 last step, and the fix generalises. The renderer now
capitalises a substitution that begins a sentence, with Turkish rules — the
capital of `i` is `İ`, so "ince bir ses" becomes "**İ**nce bir ses" and never
"Ince". One existing test's expectation changed as a result, correctly: a token
at position 0 does start a sentence.

---

## What the tests pin

**`OfflineCompositionTests` (14)** — eight pages, no unsubstituted tokens; every
admissible content combination × 6 seeds renders with zero missing slots and zero
unknown suffixes; no page sees a sound; same intent → identical fingerprint and
prose; different seeds → different prose; a different child → a different
fingerprint; an explicit choice is honoured; a rejected request is **explained**
(`canCarry`) rather than substituted; an empty pool throws with per-candidate
reasons; a missing template is named by beat *and* page; page text always comes
from a template realizing that page's beat; supporting beats land on pages 3, 4
and 8 and nowhere else; titles come from authored patterns and vary; a
beat-less blueprint is refused rather than quietly repaired.

**`TurkishRelativeSuffixTests` (+5)** — sentence-initial capitalisation,
mid-sentence preservation, Turkish casing rules, capitalisation of the *inflected*
form, and that an opening quote does not itself end a sentence.

`§8.4` is honoured: **there is no fallback anywhere.** `if filtered.isEmpty {
return items }` has no counterpart in this code. Every empty pool is a typed
error carrying why each candidate was rejected.

---

## Verification

| Check | Result |
|---|---|
| Package build | ✅ 0 errors |
| Package tests | ✅ **584 passed, 0 failures** (564 before) |
| App build | ✅ `BUILD SUCCEEDED` |
| Key in built binary | ✅ 0 occurrences |
| V1 content unchanged | ⚠️ see below |

**On V1 content (D2).** Structurally unchanged: 12 blueprints with 0 beats, 52
templates with 0 `realizesBeat`, and the pilot id absent. Both copies of
`shared_content_library_v2.json` carry a modification time of today 18:13 — *to
the same minute*, in two different directories, while every other V1 resource
still dates from 09-12/09-13. I did not write either. They remain byte-identical
to each other (`e8251e1bacb214e1a21885032abda56e0146095a`), which makes a content
edit implausible; the likely explanation is an mtime-only touch from `~/Desktop`
sync, the same root cause as the `com.apple.macl` xattr problem found in I1.

I originally wrote that git could settle this and did not exist. Git exists —
and it cannot settle it either, for a different reason: **the catalog was never
tracked.** `StoryEngine/Sources/.../Resources/templates/` was untracked until it
was committed today, so there is no earlier revision to diff against. The sha
above is the baseline from here on.

---

## Known issues

| # | Issue | For |
|---|---|---|
| S1.1 | **Past copula unmodelled** (`'di` / `'dı` / `'du` / `'dü` / `'ti` / …). Reported, not emitted wrongly — but a common construction. Cheap to add: same harmony + d/t assimilation the locative already has | next resolver pass |
| S1.2 | **Two settings, two companions, two discoveries.** Enough to prove the loop, not enough for variety. Only 2 of the 5 Phase 4 matrix rows are admissible | content authoring |
| S1.3 | No scoring, novelty, cooldown or diversity gate — variant choice is a seeded pick from all candidates | I3 proper |
| S1.4 | Nothing persists. `ComposedStory` is returned, not stored, and nothing maps it to `MagicPaper.Story` | I6 |
| S1.5 | ~~Not under version control~~ — **wrong, see above.** The repo exists (40 commits) and the engine work is now committed. The real gap was that the catalog had never been tracked | resolved |
| S1.6 | fal.ai key is out of source but still readable in the shipped `.app`. **Rotate it** | you |
| S1.7 | 49 of 52 V1 templates are duplicate filler. They still ship and still decode | I8 |

---

## Next

Three candidates, in the order I would take them:

1. **Widen the content** (S1.2) — more settings/companions/discoveries with
   traits, so all five matrix rows work and the prose stops repeating. Cheap,
   and it is what makes the pilot feel like a product rather than a proof.
2. **I3 proper** — scoring, novelty, cooldown, the diversity gate. Now has real
   content to score.
3. **Pilots B and C** — Families I and III, against a loop that is known to work.

The V1-content question above keeps its "⚠️": the catalog is tracked from today
onward, but there is no earlier revision to prove today's mtime change was
harmless.

**Stopping here.**
