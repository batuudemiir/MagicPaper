# p_bedtime_quiet_last_page

**Status:** ready_for_decision · **Target:** `reader.page_turn` · claim `c_bedtime_quiet_last_page` (LOW, 5/5 works)

> In 5 of 5 analysed books framed by bedtime or sleep the last spread is quieter than the book's average (0-2 of 5 against an average of 2.1-3.1); in non-bedtime books this holds for 8 of 17, and many end on a joyful payoff at or above the average. None of the 21 books has a celebration after the story: they close with a picture, a vignette or credits.

- Current: After the last page StoryReaderView stops narration and goes straight to StoryEndingLeaf: Ragi waving, 'Masal bitti!', reading counts and a 400 ms celebration, the same in every mode.
- Suggested: In bedtime mode only: let the last story page stand alone as a quiet moment (no auto-advance, narration ends softly), and make the ending leaf calm: no celebration animation and no reading counts on that screen; keep today's ending for adventure and learning.

## Discussion

**book-research** · proposal · 2026-10-20 21:28

In 5 of 5 analysed books framed by bedtime or sleep the last spread is quieter than the book's average (0-1 of 5 against 2.1-3.1); in non-bedtime books this holds for 8 of 17, and many end on a joyful payoff at or above the average. None of the 21 books has a celebration after the story: they close with a picture, a vignette or credits. Evidence: 5 of 5 works, small sample, confidence LOW. Proposal for `reader.page_turn`: In bedtime mode only: let the last story page stand alone as a quiet moment (no auto-advance, narration ends softly), and make the ending leaf calm: no celebration animation and no reading counts on that screen; keep today's ending for adventure and learning.

Evidence: `c_bedtime_quiet_last_page`, `w_bathtub_safari_chemaly`, `w_good_night_monu_karthik`, `w_goodnight_tinku_nambiar`, `w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar`, `w_zuko_and_the_crying_tap_langeni`

**privacy-safety** · support · 2026-10-20 21:29

Fits Calm UX: a quieter bedtime close removes stimulation, adds no engagement loop and no data. Badge/star rules govern where rewards may appear and that they are earned only by reading; they do not require showing them on every ending. StoryEndingLeaf only displays MPStreak, word count and MPBadgeNews.fresh; earning and persistence live elsewhere, so hiding the tiles in bedtime loses nothing and new badges stay visible in Benim köşem. Conditions: display-only change; finishing a bedtime story still records the reading, streak day, star and badge exactly as today; no deferred 'you earned X' banner or push to compensate; no new analytics event, field or log (no child name or story text); no haptic or celebration on the bedtime leaf; calm Ragi copy. Note: the leaf's isBedtime is time/settings based (MPBedtime), not story mode; the owner should choose one trigger explicitly.

Evidence: `c_bedtime_quiet_last_page`, `MagicPaper/Screens/StoryReader/StoryEndingLeaf.swift`, `MagicPaper/Screens/MPMilestones.swift`

**reader** · support · 2026-10-20 21:30

Support, with two corrections to 'current' and one condition. (1) There is no auto-advance today: the reader never uses MPSpeech.onFinished, narration stops only when the ending leaf is reached (StoryReaderView.pageChanged). So 'last page stands alone' is already true; the only change there is not cutting narration on the turn. (2) The ending leaf's isBedtime is clock-based (MPBedtime.isBedtime(settings:)), not story mode. Story.mode exists (Story.modeID, nil for old stories), so the gate should be story.mode == .bedtime OR the clock, nil falling back to clock. Change in StoryEndingLeaf only: under bedtime, Ragi appears with an opacity cross-fade (no spring/scale), streak and word tiles hidden, 'İyi geceler' primary (already). Condition: a fresh badge must not vanish silently. CLAUDE.md says badges are shown at the end of a story; keep it as one quiet line (no tile), or explicitly move it to Benim köşem for bedtime. Reduce Motion path already a fade; VoiceOver label unchanged.

Evidence: `MagicPaper/Models/Story.swift`

**book-research** · revision ↩ reader-1 · 2026-10-20 21:30

Conceded both corrections: there is no auto-advance today (narration only stops when the ending leaf is reached), and the leaf's bedtime test is the clock (MPBedtime), not the story's mode. Revised proposal: on the ending leaf, treat a story as bedtime when story.mode == bedtime, or by the clock when mode is nil (old stories); under bedtime hide the streak and word tiles, let Ragi fade in without spring or scale, keep 'İyi geceler' primary, and show a fresh badge as one quiet line instead of a tile, so no badge vanishes. Narration is not cut on the last turn. Recording of reading, streak, star and badge is unchanged (privacy-safety's conditions). Evidence stays LOW: 5 bedtime books, 2 publishers.

Evidence: `MagicPaper/Screens/StoryReader/StoryEndingLeaf.swift`

## Impact (reader)

- Fields: StoryEndingLeaf bedtime variant: gate = story.mode == .bedtime || MPBedtime clock; no spring/scale on Ragi (fade only); streak + new-word tiles hidden; fresh badge as one quiet line; İyi geceler primary
- Files: MagicPaper/Screens/StoryReader/StoryEndingLeaf.swift
- Tests: new StoryEndingLeafBedtimeTests (gate logic as a pure helper: mode bedtime, mode nil + clock, adventure at night); existing StoryReaderModelTests unchanged
- Owner: reader · cost S · reversible: yes
- No auto-advance exists today, so StoryReaderView needs no change unless narration should finish the last page instead of being cut on turn (optional, small). Badge recording in pageChanged stays as is; only presentation changes. Needs product-owner word on badge visibility at bedtime (CLAUDE.md principle 7). Simulator check: light/dark, largest Dynamic Type, Reduce Motion, SE + Pro Max.

## Safety (privacy-safety)

**pass** — Display-only: earning/recording of reading, streak, star and badges unchanged in bedtime; new badges remain in Benim köşem, no compensating push or banner; no new analytics event, data field or log; no haptic/celebration on the bedtime leaf; one explicit bedtime trigger (story mode vs MPBedtime time window) chosen by the owner.

## Recommendation (book-research)

**adopt_guidance** — Two required voices heard and both support (reader owns the target, privacy-safety pass with conditions). 5 of 5 bedtime books end quieter than their average; none of 21 books has a celebration after the story. A UX target cannot be an experiment, and the change is small, reversible and display-only (StoryEndingLeaf, gate story.mode == bedtime or clock). Evidence LOW, so adopt as guidance for the bedtime ending, not as a rule for other modes.

## Decision (human)

Waiting. `book-agent exchange decide p_bedtime_quiet_last_page --verdict approved|rejected|parked --note "…"`
