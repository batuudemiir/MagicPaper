# p_repeated_line

**Status:** decided · **Target:** `writing_guidance` · claim `c_repeated_line` (LOW, 11/21 works)

> A line returns on 2 or more spreads in 11 of 21 books with text (e.g. 'Come back, cat!', 'Good night, Monu.', Amo's call to the mielies, Tinku's friendship question and answer on five spreads); the other 10 repeat a structure, a sound pattern or a speaker tag instead of a line.

- Current: repetition is measured as a defect to avoid (PROSE_PRODUCTION_GUIDE.md)
- Suggested: Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

A line returns on 2 or more spreads in 3 of 5 books ('It's not me, Mama. It's Mud!', 'Catch that cat!', 'No, Amahle, you are too young.'); the other 2 repeat a failed-attempt structure instead of a line. Evidence: 3 of 5 works, small sample, confidence LOW. Proposal for `writing_guidance`: Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.

Evidence: `c_repeated_line`, `w_mud_waterkeyn`, `w_catch_that_cat_pirie`, `w_amahle_wants_to_help_nsibande`

**privacy-safety** · support · 2026-10-08 08:07

Low safety risk and a good fit for calm bedtime reading. Content conditions: a refrain must not be a prohibition or shaming line said to the child character by an adult ('you are too young') or a blame line repeated as the hook, since repetition is what the child imitates and internalises; prefer joinable, positive or neutral lines. Refrains still pass banned_phrase and ceiling checks. Evaluation via completion/reread aggregates needs no new data.

Evidence: `c_repeated_line`, `StoryEngine/Sources/StoryEngine/Domain/ChildSafetyPolicy.swift`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`

**story-engine** · concern · 2026-10-08 08:07

The conflict is harder than 'guidance': RepetitionValidator flags any 5-gram repeated across pages (maximumRepeatedNGrams defaults to 0), and validate_beat_corpus.py fails the corpus on shared 5-grams (check_collisions) and reused rhetorical moves (check_moves). A refrain is by definition a repeated n-gram, so every refrain story would be flagged. Feasible path: a declared refrain slot on the blueprint (one line, fixed pages, one changed final use) that both validators whitelist explicitly, so accidental repetition stays a defect. This is the most promising proposal for read-aloud at 3-6, but 3/5 books does not justify loosening a gate globally.

Evidence: `StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift`, `StoryEngine/Sources/StoryEngine/Domain/StoryTemplate.swift`, `StoryEngine/Tools/validate_beat_corpus.py`

**content-library** · support · 2026-10-08 08:08

Content supports. Today a deliberate refrain is impossible: the corpus gate and the engine both treat any shared 5-gram in a book as a defect (check_collisions; DeterministicValidators). Writable without touching beat pools: a refrain is a separate per-blueprint line family (base x3 + changed ending x1), slot-free so no vowel-harmony risk, exempted from the collision check by tag. Cost is small (~40-60 short lines for 19 blueprints); the real cost is the engine/validator exemption, which is story-engine's call. Best fit is bedtime: the changed last refrain can carry the calm landing.

Evidence: `StoryEngine/Tools/validate_beat_corpus.py`, `StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift`, `../PROSE_PRODUCTION_GUIDE.md`

**content-library** · prototype · 2026-10-08 08:08

Prototype: Research/BookIntelligence/sandbox/p_repeated_line.md (bedtime, 5-6, BEFORE/AFTER with a refrain on pages 2/4/6 and a changed page-8 line; page band impact and mode table).

Evidence: `Research/BookIntelligence/sandbox/p_repeated_line.md`

**book-research** · revision · 2026-10-08 15:11

Accepting all three voices: (1) never loosen the 5-gram gate globally — only a declared refrain on the blueprint that both validators subtract (story-engine-1); (2) refrains must be joinable, positive or neutral — never prohibition, blame or shaming lines; note that one of my own examples ('No, Amahle, you are too young.') is exactly such a prohibition line and would fail this rule (privacy-safety-1); (3) bedtime is the best first fit, with the changed final refrain carrying the calm landing (content-library prototype).

Evidence: `Research/BookIntelligence/sandbox/p_repeated_line.md`, `StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift`

## Impact (story-engine)

- Fields: StoryTemplate.maximumRepeatedNGrams, RepetitionValidator, validate_beat_corpus.check_collisions, validate_beat_corpus.check_moves, CatalogBlueprint.refrain(new)
- Files: StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift, StoryEngine/Sources/StoryEngine/Domain/StoryTemplate.swift, StoryEngine/Sources/StoryEngine/Content/CatalogBlueprint.swift, StoryEngine/Sources/StoryEngine/Content/CatalogIntegrity.swift, StoryEngine/Tools/validate_beat_corpus.py, StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift
- Tests: RepetitionValidator: declared refrain allowed, undeclared repeat still flagged; composer places refrain on declared pages only; final-use variant differs; corpus validator whitelists refrain n-grams only
- Owner: story-engine · cost M · reversible: yes
- Do not raise maximumRepeatedNGrams. Add an optional, declared refrain on a blueprint (text, pages, final variant) that the validators subtract before counting n-grams. Experiment: one or two refrain-carrying sibling blueprints in 3-4 / 5-6 bedtime, weighted via aggregateWeight and measured by BlueprintOutcome rereads (the signal UsageLearner already weights highest). Blueprints without the field behave exactly as today.

## Prototype (content-library)

`Research/BookIntelligence/sandbox/p_repeated_line.md` — Bedtime refrain: one 5-word line on pages 2/4/6, changed once on page 8 as the calm landing; refrain as a per-blueprint line family exempt from the 5-gram check

## Safety (privacy-safety)

**pass** — Pass as flagged experiment or guidance. Refrains must pass existing validators, must not be blame, shaming or prohibition lines aimed at the child, and must not name a Masal ailem relative in a negative role.

## Recommendation (book-research)

**experiment** — Strongest proposal: 3 of 5 books, all three agents in favour, safety pass, M cost, fully reversible. Build a declared-refrain field (validators subtract it; accidental repeats stay defects) and 1-2 refrain sibling blueprints for bedtime 3-4/5-6. They can be built and validated offline now; they reach children only after your approval AND privacy-safety's loop conditions (consented, aggregated usage via FAZ 16).

## Decision (human)

**approved** — Deney onaylandı (2026-10-14)
