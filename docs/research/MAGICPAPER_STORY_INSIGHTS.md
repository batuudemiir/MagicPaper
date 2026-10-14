# MagicPaper Story Design Insights

Research → analysis → insight → **human review** → product rule → implementation.

<!-- bookintel:generated:start -->
Every entry names the engine field or content gate it would affect. The research agent can only write `proposed`; review, acceptance and implementation are separate, human-owned steps.

## Proposed

### c_adult_enables_resolution

- **Finding:** In 3 of 6 books an adult makes the resolution possible (a tickle, a distracted injection, a 'yes'); in the other 3 the child or a peer resolves it (a plan and a catch; leaving Mud in the bath; a classmate's invitation to help).
- **Evidence:** 3 of 6 works (small sample), confidence **LOW**, counterexamples: w_catch_that_cat_pirie, w_mud_waterkeyn, w_best_friends_louw
- **Target:** `writing_guidance` · current: MagicPaper beats favour the child acting (take_charge, find_own_courage) · suggested: No change; record that adult-enabled endings are common in this population, and track agency as the corpus grows.
- **Note:** —

### c_companion_mirrors_feeling

- **Finding:** In 3 of 7 books a toy or animal companion is drawn mirroring the protagonist's feeling while saying nothing in the text; the other 4 have no such silent companion.
- **Evidence:** 3 of 7 works (small sample), confidence **LOW**, counterexamples: w_grumpy_cloud_ditlhareng, w_mud_waterkeyn, w_best_friends_louw, w_unexpected_adventure_jooste
- **Target:** `writing_guidance` · current: catalog companions speak and act in text · suggested: Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.
- **Note:** Companions as emotional amplifiers, not protagonists.

### c_fear_named_and_supported

- **Finding:** Fear is the subject of 1 of 5 books (Brave Bora): it is named on page 2, called okay by a parent, rehearsed on a toy, and peaks at intensity 4 just before the solution.
- **Evidence:** 1 of 1 works (one book), confidence **HYPOTHESIS**
- **Target:** `EmotionalState.intensity` · current: fear, panic, grief, despair (intensity 3) never permitted at age 5-6 · suggested: Open question, not a recommendation: whether named fear followed by adult support could be allowed mid-story. One book cannot answer it.
- **Note:** —

### c_length_twelve_spreads

- **Finding:** All 7 analysed contemporary picture books run 12 spreads; the 6 with text have 136-220 words in total (median 154), about 13 words per spread.
- **Evidence:** 7 of 7 works (small sample), confidence **LOW**
- **Target:** `validator.BANDS` · current: 8 pages × 18-38 words (144-304 words) · suggested: Similar total length, but these books spend it on ~12 page turns of ~10-20 words. Worth testing shorter pages and more turns once the corpus is larger.
- **Note:** One publisher, one country. Do not act on this before ≥10 books from ≥2 sources agree.

### c_peak_in_last_third

- **Finding:** The emotional peak falls in the last third of the book in 5 of 7 analysed books; Grumpy Cloud and An Unexpected Adventure reach their first peak at the midpoint and plateau.
- **Evidence:** 5 of 7 works (small sample), confidence **LOW**, counterexamples: w_grumpy_cloud_ditlhareng, w_unexpected_adventure_jooste
- **Target:** `beat_sequences` · current: 8-beat arcs · suggested: Check where MagicPaper arcs place their most intense page; compare after the corpus grows.
- **Note:** Emotion intensity is an analyst judgment per page.

### c_picture_only_information

- **Finding:** In all 7 analysed books at least one spread carries story information only in the picture (who caused the mess, what is hiding, who is now left out); one book is wordless.
- **Evidence:** 7 of 7 works (small sample), confidence **LOW**
- **Target:** `writing_guidance` · current: text carries the whole story · suggested: Hypothesis for illustrated stories: leave one fact per story to the picture; not applicable to text-only stories.
- **Note:** —

### c_repeated_line

- **Finding:** A line returns on 2 or more spreads in 4 of 6 books with text ('It's not me, Mama. It's Mud!', 'Catch that cat!', 'No, Amahle, you are too young.', a polite refusal in Best Friends); the other 2 repeat a failed-attempt structure instead of a line.
- **Evidence:** 4 of 6 works (small sample), confidence **LOW**, counterexamples: w_grumpy_cloud_ditlhareng, w_brave_bora_gicovi
- **Target:** `writing_guidance` · current: repetition is measured as a defect to avoid (PROSE_PRODUCTION_GUIDE.md) · suggested: Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.
- **Note:** —

### c_sentence_length

- **Finding:** Mean sentence length is 3-11 words in the 6 analysed books with text; the longest sentence stays at or under 14 words in 4 of 6 (the other two reach 18 and 21).
- **Evidence:** 4 of 6 works (small sample), confidence **LOW**, counterexamples: w_brave_bora_gicovi, w_grumpy_cloud_ditlhareng
- **Target:** `validator.MAX_SENTENCE_WORDS` · current: 14 · suggested: No change suggested: the pilot sits around the current cap.
- **Note:** —

### c_spread_end_hook

- **Finding:** In 4 of 6 books with text a spread ends on an unfinished line or a direct question answered on the next spread ('But Mama says...', 'But where is Mud?', 'Hmm. But how?', an invitation to play together).
- **Evidence:** 4 of 6 works (small sample), confidence **LOW**, counterexamples: w_grumpy_cloud_ditlhareng, w_brave_bora_gicovi
- **Target:** `writing_guidance` · current: page-end lines are not specified · suggested: Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.
- **Note:** —
<!-- bookintel:generated:end -->
