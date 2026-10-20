# MagicPaper Story Design Insights

Research → analysis → insight → **human review** → product rule → implementation.

<!-- bookintel:generated:start -->
Every entry names the engine field or content gate it would affect. The research agent can only write `proposed`; review, acceptance and implementation are separate, human-owned steps.

## Reviewed

### c_bedtime_closes_circle

- **Finding:** In 4 of 6 analysed books framed by bedtime or sleep, the last page returns to the opening place (the bed or bedroom, or the same mother and moon) at low intensity (0-2 of 5) after a peak earlier in the book (Good Night, Monu; Bathtub Safari; Zuko and the crying tap; Goodnight, Tinku!); Bohlale's adventure ends on a high payoff (4 of 5) and Kottavi Raja ends calm but in a different place (the whole city asleep), after a late second peak.
- **Evidence:** 4 of 6 works (small sample), confidence **LOW**, counterexamples: w_bohlales_adventure_ambrosano, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `beat_sequences` · current: bedtime mode shares beat sequences with the other modes; m004 already keeps hooks out of its last third · suggested: For bedtime blueprints only: place the emotional peak no later than about two thirds through, and let the final page return to the opening setting (bed, room, window) at the lowest intensity of the story.
- **Note:** Hypothesis from 4 books; bedtime-specific, does not apply to adventure or learning modes.

### c_length_twelve_spreads

- **Finding:** Outside Book Dash, whose format fixes 12 spreads, 1 of 5 analysed books runs 12 pages (Chicken and Millipede, African Storybook); the others run 11 (Goodnight, Tinku!), 13 (Good Night, Monu), 15 (Bohlale's adventure) and 17 (Kottavi Raja). The 12-spread pattern is not shown beyond one publisher.
- **Evidence:** 1 of 5 works (small sample), confidence **LOW**, counterexamples: w_bohlales_adventure_ambrosano, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `validator.BANDS` · current: 8 pages × 18-38 words (144-304 words) · suggested: Similar total length, but these books spend it on ~12 page turns of ~10-20 words. Worth testing shorter pages and more turns once the corpus is larger.
- **Note:** One publisher, one country. Do not act on this before ≥10 books from ≥2 sources agree.

### c_peak_in_last_third

- **Finding:** The emotional peak falls in the last third in 16 of 24 analysed books; in 8 the first peak comes at or before the midpoint (plateaus, or bedtime books that peak mid-way and wind down).
- **Evidence:** 16 of 24 works (corpus), confidence **LOW**, counterexamples: w_bathtub_safari_chemaly, w_chicken_and_millipede_asara, w_come_back_cat_rijsdijk, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_khumos_big_trip_sedibe, w_unexpected_adventure_jooste
- **Target:** `beat_sequences` · current: 8-beat arcs · suggested: Check where MagicPaper arcs place their most intense page; compare after the corpus grows.
- **Note:** Emotion intensity is an analyst judgment per page.

### c_picture_only_information

- **Finding:** In 23 of 24 analysed books at least one spread carries story information only in the picture; 3 are wordless and in 4 more the turning point is carried by wordless spreads. The level-3 Kottavi Raja tells everything in its text.
- **Evidence:** 23 of 24 works (corpus), confidence **LOW**, counterexamples: w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `writing_guidance` · current: text carries the whole story · suggested: Hypothesis for illustrated stories: leave one fact per story to the picture; not applicable to text-only stories.
- **Note:** —

### c_sentence_length

- **Finding:** Mean sentence length is between 3 and 10 words in all 21 analysed books with text; the longest sentence stays at or under 14 words in 12 of 21 (the others reach 15-21, and 38 in the level-3 Kottavi Raja).
- **Evidence:** 12 of 21 works (corpus), confidence **LOW**, counterexamples: w_ann_nem_oh_nee_finds_adventure_griffiths, w_bohlales_adventure_ambrosano, w_brave_bora_gicovi, w_foxy_joxy_plays_a_trick_esmail, w_ga_mohana_the_hill_of_wonders_itumeleng, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `validator.MAX_SENTENCE_WORDS` · current: 14 · suggested: No change suggested: the pilot sits around the current cap.
- **Note:** —

## Accepted

### c_companion_mirrors_feeling

- **Finding:** In 3 of 23 books a toy or animal companion is drawn mirroring the protagonist's feeling while saying nothing in the text; in the other 20 there is no companion or it does not mirror (Khumo's and Monu's teddies, Fifi's Teddy stay neutral).
- **Evidence:** 3 of 23 works (corpus), confidence **LOW**, counterexamples: w_amo_and_the_missing_mielies_phala, w_ann_nem_oh_nee_finds_adventure_griffiths, w_bathtub_safari_chemaly, w_best_friends_louw, w_bohlales_adventure_ambrosano, w_chicken_and_millipede_asara, w_come_back_cat_rijsdijk, w_come_stay_with_me_siege, w_feathered_friends_ange, w_fifi_and_teddy_letsapa, w_foxy_joxy_plays_a_trick_esmail, w_ga_mohana_the_hill_of_wonders_itumeleng, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_khumos_big_trip_sedibe, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_mud_waterkeyn, w_unexpected_adventure_jooste, w_zuko_and_the_crying_tap_langeni
- **Target:** `writing_guidance` · current: catalog companions speak and act in text · suggested: Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.
- **Note:** Companions as emotional amplifiers, not protagonists.

### c_repeated_line

- **Finding:** A line returns on 2 or more spreads in 11 of 21 books with text (e.g. 'Come back, cat!', 'Good night, Monu.', Amo's call to the mielies, Tinku's friendship question and answer on five spreads); the other 10 repeat a structure, a sound pattern or a speaker tag instead of a line.
- **Evidence:** 11 of 21 works (corpus), confidence **LOW**, counterexamples: w_ann_nem_oh_nee_finds_adventure_griffiths, w_bathtub_safari_chemaly, w_brave_bora_gicovi, w_chicken_and_millipede_asara, w_come_stay_with_me_siege, w_feathered_friends_ange, w_fifi_and_teddy_letsapa, w_foxy_joxy_plays_a_trick_esmail, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `writing_guidance` · current: repetition is measured as a defect to avoid (PROSE_PRODUCTION_GUIDE.md) · suggested: Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.
- **Note:** —

### c_spread_end_hook

- **Finding:** In 16 of 21 books with text a spread ends on an unfinished line or a direct question answered on the next spread (e.g. 'And then…', 'Cat?', 'What's wrong?', a count broken off mid-way); Goodnight, Tinku! instead carries the reader on by a repeating pattern, and Kottavi Raja by a list of remedies.
- **Evidence:** 16 of 21 works (corpus), confidence **MEDIUM**, counterexamples: w_brave_bora_gicovi, w_chicken_and_millipede_asara, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `writing_guidance` · current: page-end lines are not specified · suggested: Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.
- **Note:** —

## Declined

### c_adult_enables_resolution

- **Finding:** In 5 of 12 books with a problem an adult makes the resolution possible (a tickle, an injection, a 'yes', a repairer called, a mother's instruction); in 7 the child or a peer resolves it.
- **Evidence:** 6 of 14 works (corpus), confidence **LOW**, counterexamples: w_best_friends_louw, w_bohlales_adventure_ambrosano, w_catch_that_cat_pirie, w_come_back_cat_rijsdijk, w_feathered_friends_ange, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_mud_waterkeyn
- **Target:** `writing_guidance` · current: MagicPaper beats favour the child acting (take_charge, find_own_courage) · suggested: No change; record that adult-enabled endings are common in this population, and track agency as the corpus grows.
- **Note:** —

### c_fear_named_and_supported

- **Finding:** Fear is a subject in 3 of 16 books with three different handlings: Brave Bora names it and a parent supports him; Bohlale names it herself and defuses it by looking again; Good Night, Monu shows it only in pictures and the child settles it alone.
- **Evidence:** 1 of 3 works (small sample), confidence **HYPOTHESIS**, counterexamples: w_bohlales_adventure_ambrosano, w_good_night_monu_karthik
- **Target:** `EmotionalState.intensity` · current: fear, panic, grief, despair (intensity 3) never permitted at age 5-6 · suggested: Open question, not a recommendation: whether named fear followed by adult support could be allowed mid-story. One book cannot answer it.
- **Note:** —
<!-- bookintel:generated:end -->
