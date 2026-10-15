# p_fear_named_and_supported

**Status:** decided · **Target:** `EmotionalState.intensity` · claim `c_fear_named_and_supported` (HYPOTHESIS, 1/3 works)

> Fear is a subject in 3 of 16 books with three different handlings: Brave Bora names it and a parent supports him; Bohlale names it herself and defuses it by looking again; Good Night, Monu shows it only in pictures and the child settles it alone.

- Current: fear, panic, grief, despair (intensity 3) never permitted at age 5-6
- Suggested: Open question, not a recommendation: whether named fear followed by adult support could be allowed mid-story. One book cannot answer it.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

Fear is the subject of 1 of 5 books (Brave Bora): it is named on page 2, called okay by a parent, rehearsed on a toy, and peaks at intensity 4 just before the solution. Evidence: 1 of 1 works, one book, confidence HYPOTHESIS. Proposal for `EmotionalState.intensity`: Open question, not a recommendation: whether named fear followed by adult support could be allowed mid-story. One book cannot answer it.

Evidence: `c_fear_named_and_supported`, `w_brave_bora_gicovi`

**privacy-safety** · object · 2026-10-08 08:07

Object to any experiment here. Fear/panic are intensity 3 and the BeatSequenceValidator ceiling is 2 for every band; SafetyVocabulary documents that this ceiling keeps fear out of every band, and parents chose 'Sakin' or 'Biraz heyecan' on that promise. The source peaks at intensity 4, one book, HYPOTHESIS confidence. Running it as an A/B arm would mean deliberately exposing some children, possibly at bedtime, to frightening pages to measure completion, which completion/reread data cannot even evaluate (abandonment is not a fear signal). If ever revisited it needs child-development expert review, a new explicit parent-facing ContentSafety level, opt-in, and bedtime excluded, not an experiment.

Evidence: `c_fear_named_and_supported`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`, `StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift`, `StoryEngine/Sources/StoryEngine/Content/SafetyVocabulary.swift`, `docs/MagicPaper_Faz_Plani_Ekim.md`

**story-engine** · object · 2026-10-08 08:07

Factual correction: the engine scale is 0-3, so 'intensity 4' maps onto nothing here; Brave Bora's peak would be our intensity 3 (fear), which BeatSequenceValidator rejects with intensityCeiling=2 in every band, not only 5-6. A narrower version is already possible without touching the ceiling: intensity-2 states (unease, hesitation, concern) followed by an adult-reassurance beat, within the existing rule of at most two consecutive intensity-2 pages. Raising the ceiling on one book is not justified, and any ceiling change is a privacy-safety decision before it is an engine one.

Evidence: `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`, `StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift`

**content-library** · object · 2026-10-08 08:08

Content objects for now. beat_hesitate.json deliberately never names fear ('Korkuyorum' becomes the label the child carries out of the book) and EmotionalArc keeps fear/panic out of the band. One book cannot outweigh that editorial decision, and bedtime must never peak on fear. If revisited, it needs privacy-safety plus more works, and a learning-mode framing (a named feeling met by a supporting adult), not adventure peaks.

Evidence: `StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_hesitate.json`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`

**book-research** · revision · 2026-10-08 15:11

Conceded on both points. My 'intensity 4' was on the research scale (0-5) and should have been translated: it is engine intensity 3, which is blocked in every band. And one book cannot outweigh a documented parent-facing safety promise. The narrower version story-engine describes — named unease or hesitation (intensity 2) followed by an adult-reassurance beat — is already possible today. Lesson for the research side: every proposal must state its numbers on the engine's scales.

Evidence: `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`, `StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift`

## Impact (story-engine)

- Fields: EmotionalState.intensity, BeatSequenceValidator.intensityCeiling
- Files: StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift, StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift, StoryEngine/Sources/StoryEngine/Content/SafetyVocabulary.swift
- Tests: intensity_over_ceiling tests, consecutive intensity-2 run tests
- Owner: story-engine · cost S · reversible: yes
- Technically a one-line ceiling change, which is why it must not be done casually: it is a child-safety gate and needs privacy-safety sign-off. Engine recommends no change. A safe experiment exists without touching the gate: a blueprint that names unease/hesitation (intensity 2) and follows it with an adult-reassurance beat, within the two-consecutive-pages rule. Note research's 'intensity 4' is not on the engine's 0-3 scale.

## Safety (privacy-safety)

**block** — Must not reach children as an experiment. Raising the intensity ceiling or permitting fear/panic mid-story breaks the documented promise behind ContentSafety (fear kept out of every band). Re-entry only as a new proposal with expert review, an explicit opt-in parent safety level, bedtime excluded, and stronger evidence than one book; never as a randomized arm.

## Recommendation (book-research)

**decline** — Blocked by safety and objected to by engine and content. The ceiling stays. Re-entry only as a new proposal with expert review, an opt-in parent safety level and far more evidence. The intensity-2 'named unease + reassurance' form needs no decision; it already fits the rules.

## Decision (human)

**rejected** — Korku sınırı kalıyor (2026-10-14)
