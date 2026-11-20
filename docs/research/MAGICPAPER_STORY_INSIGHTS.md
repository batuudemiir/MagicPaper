# MagicPaper Story Design Insights

Research → analysis → insight → **human review** → product rule → implementation.

<!-- bookintel:generated:start -->
Every entry names the engine field or content gate it would affect. The research agent can only write `proposed`; review, acceptance and implementation are separate, human-owned steps.

## Reviewed

### c_bedtime_closes_circle

- **Finding:** In 6 of 8 analysed books framed by bedtime or sleep, the last page returns to the opening place or image at low intensity (0-2 of 5) after a peak earlier in the book (Good Night, Monu; Bathtub Safari; Zuko and the crying tap; Goodnight, Tinku!; A House for Mouse; Clever Pig); Bohlale's adventure ends on a high payoff (4 of 5) and Kottavi Raja ends calm but in a different place, after a late second peak.
- **Evidence:** 7 of 9 works (small sample), confidence **LOW**, counterexamples: w_bohlales_adventure_ambrosano, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `beat_sequences` · current: bedtime mode shares beat sequences with the other modes; m004 already keeps hooks out of its last third · suggested: For bedtime blueprints only: place the emotional peak no later than about two thirds through, and let the final page return to the opening setting (bed, room, window) at the lowest intensity of the story.
- **Note:** Hypothesis from 4 books; bedtime-specific, does not apply to adventure or learning modes.

### c_length_twelve_spreads

- **Finding:** Outside Book Dash, whose format fixes 12 spreads, 1 of 8 analysed books runs 12 pages (Chicken and Millipede, African Storybook); the others run 11 (Goodnight, Tinku!; Get Down, Rocky!), 13 (Good Night, Monu), 14 (Sweet Dreams), 15 (Bohlale's adventure), 17 (Kottavi Raja) and 18 (The Lost Ball). The 12-spread pattern is not shown beyond one publisher.
- **Evidence:** 1 of 8 works (small sample), confidence **LOW**, counterexamples: w_bohlales_adventure_ambrosano, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_get_down_rocky_besant, w_the_lost_ball_mustafa, w_sweet_dreams_amaya
- **Target:** `validator.BANDS` · current: 8 pages × 18-38 words (144-304 words) · suggested: Similar total length, but these books spend it on ~12 page turns of ~10-20 words. Worth testing shorter pages and more turns once the corpus is larger.
- **Note:** One publisher, one country. Do not act on this before ≥10 books from ≥2 sources agree.

### c_peak_in_last_third

- **Finding:** The emotional peak (first page at the book's highest intensity) falls in the last third in 28 of 43 analysed books; in the other 15 the first peak comes earlier (mid-book reveals, plateaus, bedtime books that peak mid-way and wind down, or books whose last-third high only matches an earlier one).
- **Evidence:** 28 of 43 works (corpus), confidence **MEDIUM**, counterexamples: w_bathtub_safari_chemaly, w_chicken_and_millipede_asara, w_come_back_cat_rijsdijk, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_khumos_big_trip_sedibe, w_unexpected_adventure_jooste, w_clever_pig_koenig, w_who_ate_my_hat_shea, w_house_for_mouse_fry, w_trip_to_the_tap_mandoyi, w_i_can_do_it_mathe, w_alexs_super_medicine_rex, w_sweet_dreams_amaya
- **Target:** `beat_sequences` · current: 8-beat arcs · suggested: Check where MagicPaper arcs place their most intense page; compare after the corpus grows.
- **Note:** Emotion intensity is an analyst judgment per page.

### c_picture_only_information

- **Finding:** In 42 of 43 analysed books at least one spread carries story information only in the picture; 5 are wordless or have a wordless reveal spread and in several more the turning point, a rescue plan or the real cause is carried by the pictures alone. The level-3 Kottavi Raja tells everything in its text.
- **Evidence:** 42 of 43 works (corpus), confidence **MEDIUM**, counterexamples: w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar
- **Target:** `writing_guidance` · current: text carries the whole story · suggested: Hypothesis for illustrated stories: leave one fact per story to the picture; not applicable to text-only stories.
- **Note:** —

### c_sentence_length

- **Finding:** Mean sentence length is between 3 and 10 words in 38 of 39 analysed books with text (A Day Out, a 3-4 book of one-line cries, averages 2.4); the longest sentence stays at or under 14 words in 23 of 39 (the others reach 15-27, and 38 in the level-3 Kottavi Raja).
- **Evidence:** 23 of 39 works (corpus), confidence **LOW**, counterexamples: w_ann_nem_oh_nee_finds_adventure_griffiths, w_bohlales_adventure_ambrosano, w_brave_bora_gicovi, w_foxy_joxy_plays_a_trick_esmail, w_ga_mohana_the_hill_of_wonders_itumeleng, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_get_down_rocky_besant, w_dudus_hat_mcgregor, w_going_places_reeves, w_i_can_do_it_mathe, w_banzis_busy_bees_zazela, w_dance_khuzwayo_dance_nyirongo, w_alexs_super_medicine_rex
- **Target:** `validator.MAX_SENTENCE_WORDS` · current: 14 · suggested: No change suggested: the pilot sits around the current cap.
- **Note:** —

## Accepted

### c_bedtime_quiet_last_page

- **Finding:** In 7 of 7 analysed books framed by bedtime or sleep the last spread is quieter than the book's average (0-2 of 5); in non-bedtime books this holds for about half, and many end on a joyful payoff at or above the average. None of the analysed books has a celebration after the story: they close with a picture, a vignette or credits.
- **Evidence:** 8 of 8 works (small sample), confidence **LOW**
- **Target:** `reader.page_turn` · current: After the last page StoryReaderView stops narration and goes straight to StoryEndingLeaf: Ragi waving, 'Masal bitti!', reading counts and a 400 ms celebration, the same in every mode. · suggested: In bedtime mode only: let the last story page stand alone as a quiet moment (no auto-advance, narration ends softly), and make the ending leaf calm: no celebration animation and no reading counts on that screen; keep today's ending for adventure and learning.
- **Note:** Bedtime-specific; 5 bedtime books from 2 publishers.

### c_companion_mirrors_feeling

- **Finding:** In 6 of 42 books a toy or animal companion is drawn mirroring the protagonist's feeling while saying nothing in the text (a cat in The Lost Ball, a toy rhino in Dudu's Hat, a blue frog on every spread of Play with Me); in the other 36 there is no companion or it does not mirror.
- **Evidence:** 6 of 42 works (corpus), confidence **LOW**, counterexamples: w_amo_and_the_missing_mielies_phala, w_ann_nem_oh_nee_finds_adventure_griffiths, w_bathtub_safari_chemaly, w_best_friends_louw, w_bohlales_adventure_ambrosano, w_chicken_and_millipede_asara, w_come_back_cat_rijsdijk, w_come_stay_with_me_siege, w_feathered_friends_ange, w_fifi_and_teddy_letsapa, w_foxy_joxy_plays_a_trick_esmail, w_ga_mohana_the_hill_of_wonders_itumeleng, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_khumos_big_trip_sedibe, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_mud_waterkeyn, w_unexpected_adventure_jooste, w_zuko_and_the_crying_tap_langeni, w_get_down_rocky_besant, w_day_out_brain, w_who_ate_my_hat_shea, w_lets_go_looking_ngaba, w_clever_pig_koenig, w_house_for_mouse_fry, w_goldfish_genius_wilson, w_trip_to_the_tap_mandoyi, w_going_places_reeves, w_aaaaahhh_mmawe_mcgregor, w_can_we_eat_a_rainbow_drew, w_i_can_do_it_mathe, w_banzis_busy_bees_zazela, w_dance_khuzwayo_dance_nyirongo, w_alexs_super_medicine_rex, w_sweet_dreams_amaya
- **Target:** `writing_guidance` · current: catalog companions speak and act in text · suggested: Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.
- **Note:** Companions as emotional amplifiers, not protagonists.

### c_repeated_line

- **Finding:** A line returns on 2 or more spreads in 22 of 39 books with text (e.g. 'Come back, cat!', 'Good night, Monu.', the paired scream and 'don't be scared … it's just …' in AAAAAHHH!!!! Mmawe!, 'Sniff, sniff, sniff.' in Can We Eat a Rainbow?, 'I know, I'll …' in Alex's Super Medicine); the other 17 repeat a structure, a place or a callback but no line.
- **Evidence:** 22 of 39 works (corpus), confidence **LOW**, counterexamples: w_ann_nem_oh_nee_finds_adventure_griffiths, w_bathtub_safari_chemaly, w_brave_bora_gicovi, w_chicken_and_millipede_asara, w_come_stay_with_me_siege, w_feathered_friends_ange, w_fifi_and_teddy_letsapa, w_foxy_joxy_plays_a_trick_esmail, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_day_out_brain, w_lets_go_looking_ngaba, w_trip_to_the_tap_mandoyi, w_going_places_reeves, w_i_can_do_it_mathe, w_dance_khuzwayo_dance_nyirongo, w_sweet_dreams_amaya
- **Target:** `writing_guidance` · current: repetition is measured as a defect to avoid (PROSE_PRODUCTION_GUIDE.md) · suggested: Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.
- **Note:** —

### c_spread_end_hook

- **Finding:** In 31 of 39 books with text a spread ends on an unfinished line or a direct question answered on the next spread (e.g. 'And then…', 'Cat?', a sentence broken on 'BUT…' in I Can Do It!, a couplet whose rhyme arrives only after the turn in Sweet Dreams); the other 8 answer each spread within itself.
- **Evidence:** 31 of 39 works (corpus), confidence **MEDIUM**, counterexamples: w_brave_bora_gicovi, w_chicken_and_millipede_asara, w_goodnight_tinku_nambiar, w_grumpy_cloud_ditlhareng, w_kottavi_raja_and_his_sleepy_kingdom_sampathkumar, w_day_out_brain, w_who_ate_my_hat_shea, w_house_for_mouse_fry
- **Target:** `writing_guidance` · current: page-end lines are not specified · suggested: Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.
- **Note:** —

## Declined

### c_adult_enables_resolution

- **Finding:** In 10 of 29 books with a problem an adult makes the resolution possible (a tickle, an injection, a 'yes', a repairer called, a carpenter's ramp, a grandmother's new bucket, a garden replanted, a scare explained away); in 19 the child, a peer or an animal resolves it.
- **Evidence:** 10 of 29 works (corpus), confidence **LOW**, counterexamples: w_best_friends_louw, w_bohlales_adventure_ambrosano, w_catch_that_cat_pirie, w_come_back_cat_rijsdijk, w_feathered_friends_ange, w_good_night_monu_karthik, w_goodnight_tinku_nambiar, w_mud_waterkeyn, w_the_lost_ball_mustafa, w_day_out_brain, w_who_ate_my_hat_shea, w_dudus_hat_mcgregor, w_clever_pig_koenig, w_house_for_mouse_fry, w_goldfish_genius_wilson, w_i_can_do_it_mathe, w_play_with_me_seldon, w_dance_khuzwayo_dance_nyirongo, w_alexs_super_medicine_rex
- **Target:** `writing_guidance` · current: MagicPaper beats favour the child acting (take_charge, find_own_courage) · suggested: No change; record that adult-enabled endings are common in this population, and track agency as the corpus grows.
- **Note:** —

### c_fear_named_and_supported

- **Finding:** Fear is a subject in 5 of the analysed books with four different handlings: Brave Bora names it and a parent supports him; AAAAAHHH!!!! Mmawe! has an adult name each scare and reframe it as ordinary; Bohlale names it herself and defuses it by looking again; Dance, Khuzwayo, Dance! has the child name it and two friends support him; Good Night, Monu shows it only in pictures and the child settles it alone.
- **Evidence:** 2 of 5 works (small sample), confidence **HYPOTHESIS**, counterexamples: w_bohlales_adventure_ambrosano, w_good_night_monu_karthik, w_dance_khuzwayo_dance_nyirongo
- **Target:** `EmotionalState.intensity` · current: fear, panic, grief, despair (intensity 3) never permitted at age 5-6 · suggested: Open question, not a recommendation: whether named fear followed by adult support could be allowed mid-story. One book cannot answer it.
- **Note:** —
<!-- bookintel:generated:end -->
