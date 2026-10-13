# p_spread_end_hook

**Status:** ready_for_decision · **Target:** `writing_guidance` · claim `c_spread_end_hook` (LOW, 3/5 works)

> In 3 of 5 books a spread ends on an unfinished line or a direct question answered on the next spread ('But Mama says...', 'But where is Mud?', 'Hmm. But how?').

- Current: page-end lines are not specified
- Suggested: Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

In 3 of 5 books a spread ends on an unfinished line or a direct question answered on the next spread ('But Mama says...', 'But where is Mud?', 'Hmm. But how?'). Evidence: 3 of 5 works, small sample, confidence LOW. Proposal for `writing_guidance`: Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.

Evidence: `c_spread_end_hook`, `w_amahle_wants_to_help_nsibande`, `w_mud_waterkeyn`, `w_catch_that_cat_pirie`

**privacy-safety** · concern · 2026-10-08 08:07

Generally fine, but two conditions. Bedtime: page-turn hooks are an engagement device; in bedtime mode they work against wind-down and must not appear in the last third, and never on the final page. Series: hooks must stay inside the story; no cross-story or episode-end cliffhangers ('come back tomorrow to find out'), which CLAUDE.md calm UX rules out and FAZ 13 already forbids at episode ends. Questions must be about story, not suspense about danger ('But where is Mud?' fine; 'But what was in the dark?' not).

Evidence: `c_spread_end_hook`, `CLAUDE.md`, `docs/MagicPaper_Faz_Plani_Ekim.md`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`

**story-engine** · concern · 2026-10-08 08:07

Feasible as content guidance, with two engine frictions. Page variants are composed independently from pools, so 'But where is X?' on page n only works if page n+1's pool always answers it, which means pairing variants across beats (today the corpus has no cross-page variant links). Second, CalmEnding forbids '?' and 'acaba' only at story/episode ends, so mid-story questions are allowed, but bedtime mode should keep them off the last two pages. Suggest a content-library prototype inside a single beat pair before any engine change.

Evidence: `StoryEngine/Tools/validate_beat_corpus.py`, `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`

**content-library** · support · 2026-10-08 08:08

Support for adventure and learning, with a constraint. Pages are drawn independently, so a page-end question must not promise a detail the next variant may not deliver; that is exactly the light/sound cross-page contradiction PROSE_PRODUCTION_GUIDE records. Writable safely as generic hooks ('Ama nasıl?') plus an answersHook opening on every variant of the following beat. Bedtime: only pages 2-4 and soft; never on the last two pages, and 'acaba'/'?' endings are already banned for episode ends by CalmEnding.

Evidence: `../PROSE_PRODUCTION_GUIDE.md`, `StoryEngine/Sources/StoryEngine/Offline/Series/CalmEnding.swift`, `StoryEngine/Tools/validate_beat_corpus.py`

**content-library** · prototype · 2026-10-08 08:08

Prototype: Research/BookIntelligence/sandbox/p_spread_end_hook.md (adventure page 4 -> 5, two writable routes, per-mode limits, cost estimate).

Evidence: `Research/BookIntelligence/sandbox/p_spread_end_hook.md`

**book-research** · answer ↩ story-engine-1 · 2026-10-08 15:11

Agree the composer cannot guarantee a specific answer on the next page. The generic-hook route ('Ama nasıl?' + an answersHook opening on every variant of the following beat) avoids cross-beat linking entirely. I accept safety's limits: within-story only, not on the last page or episode ends, not in bedtime, never about danger or the unknown.

Evidence: `Research/BookIntelligence/sandbox/p_spread_end_hook.md`, `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`

## Engine impact (story-engine)

- Fields: beat variant pairing (new), CalmEnding
- Files: StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift, StoryEngine/Tools/validate_beat_corpus.py
- Tests: a page-end question variant is only selectable when the next page's chosen variant answers it
- Owner: story-engine · cost M · reversible: yes
- Needs cross-beat variant linking, which the composer lacks. Start as content-library sandbox prototype; engine work only if adopted.

## Prototype (content-library)

`Research/BookIntelligence/sandbox/p_spread_end_hook.md` — Adventure page 4 ends on 'Ama ... nasıl?' answered after the turn; two writable routes (generic hook + answersHook openings, or fixed beat pairs); bedtime limits

## Safety (privacy-safety)

**concerns** — Conditions: within-story only, never on the last page or episode ends; excluded from bedtime mode (or confined to its first half); hook questions not about danger or the unknown; page emotion stays within ceiling 2 and the parent's ContentSafety level.

## Recommendation (book-research)

**adopt_guidance** — As writing guidance only, via the generic-hook route (no engine change): adventure and learning, mid-story, never bedtime / last page / episode end, never danger questions. Specific question-answer pairs wait until the corpus supports cross-beat linking.

## Decision (human)

Waiting. `book-agent exchange decide p_spread_end_hook --verdict approved|rejected|parked --note "…"`
