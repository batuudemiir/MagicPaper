# p_companion_mirrors_feeling

**Status:** decided · **Target:** `writing_guidance` · claim `c_companion_mirrors_feeling` (LOW, 3/23 works)

> In 3 of 23 books a toy or animal companion is drawn mirroring the protagonist's feeling while saying nothing in the text; in the other 20 there is no companion or it does not mirror (Khumo's and Monu's teddies, Fifi's Teddy stay neutral).

- Current: catalog companions speak and act in text
- Suggested: Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

In 3 of 5 books a toy or animal companion is drawn mirroring the protagonist's feeling (Jojo the monkey, Teddy, the dog) while saying nothing in the text. Evidence: 3 of 5 works, small sample, confidence LOW. Proposal for `writing_guidance`: Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.

Evidence: `c_companion_mirrors_feeling`, `w_brave_bora_gicovi`, `w_amahle_wants_to_help_nsibande`, `w_catch_that_cat_pirie`

**privacy-safety** · concern · 2026-10-08 08:07

Mostly low risk, but it targets companion illustration briefs, and illustrated stories are not live (cloud path behind CloudIllustrationAccess). A silently mirrored feeling is unvalidated: the text-side intensity ceiling cannot see a picture, so a companion drawn crying or terrified could exceed the page's EmotionalState with no check. Any brief must bind the companion's drawn emotion to the page's EmotionalState and ceiling, and go through the image safety gate (imagePolicy blocking). Not testable on children until the illustration pipeline and its validation exist.

Evidence: `c_companion_mirrors_feeling`, `MagicPaper/StoryEngineBridge/CloudIllustrationAccess.swift`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`, `StoryEngine/Sources/StoryEngine/Domain/ChildSafetyPolicy.swift`

**story-engine** · question · 2026-10-08 08:07

Text stories are the only live path (no LLM, illustration behind CloudIllustrationAccess), so a silent picture-only companion has no carrier in the text engine today. Engine-side the only hook would be an illustration-requirement field on the page plan (companion emotion = page emotion), which is cheap but belongs to illustration-system. Question to book-research: did the mirroring companion also have a text role elsewhere in those books, or was it silent throughout?

Evidence: `StoryEngine/Sources/StoryEngine/Content/CatalogBlueprint.swift`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`

**content-library** · support · 2026-10-08 08:08

Support. It extends a rule content already follows: beat_hesitate.json requires the child's reluctance to be shown physically, never named; today the companion often talks the tension away on the same page. A text-only form works now (a short 'mirror' line: the companion stops too, then relaxes when the child acts), and keeps the resolution the child's. Watch body assumptions (the roster includes a robot, per beat_meet_companion.json) and companion-name + 'da/de' harmony. The illustration-brief half waits for illustrated stories.

Evidence: `StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_hesitate.json`, `StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_meet_companion.json`, `StoryEngine/Tools/validate_beat_corpus.py`

**content-library** · prototype · 2026-10-08 08:08

Prototype: Research/BookIntelligence/sandbox/p_companion_mirrors_feeling.md (hesitate + resolution pages, body-safe generic forms, mode fit).

Evidence: `Research/BookIntelligence/sandbox/p_companion_mirrors_feeling.md`

**book-research** · answer ↩ story-engine-1 · 2026-10-08 15:11

To story-engine's question: in Brave Bora the monkey is named in the text but never speaks; in Amahle the teddy is named once ('read to Teddy') and never speaks; in Catch That Cat the dog is never in the text at all. So the companion's text role was minimal or nil — the mirroring was carried by the pictures. Content-library's text form (a short 'mirror' line where the companion stops and relaxes with the child, without talking the tension away) translates that to text-only stories.

Evidence: `w_brave_bora_gicovi`, `w_amahle_wants_to_help_nsibande`, `w_catch_that_cat_pirie`, `Research/BookIntelligence/sandbox/p_companion_mirrors_feeling.md`

## Prototype (content-library)

`Research/BookIntelligence/sandbox/p_companion_mirrors_feeling.md` — Text form of a silent mirroring companion on hesitate/succeed pages; short 'mirror' length class, body-assumption safe forms

## Safety (privacy-safety)

**concerns** — Conditions: (1) only once illustrated stories are live behind their own flag; (2) companion's drawn emotion bound to the page EmotionalState, never above the ceiling (2) and never above the parent's ContentSafety level; (3) passes the blocking image/illustration validation; (4) no child photo or likeness data used to create mirrored expressions.

## Recommendation (book-research)

**adopt_guidance** — Text form only, as writing guidance: a short silent 'mirror' line for the companion on hesitate/succeed pages, so the child, not the companion, resolves the tension. The illustration half is parked until illustrated stories are live and the image safety gate binds companion emotion to the page ceiling.

## Decision (human)

**approved** — Yalnızca metin hali, yazım rehberine (2026-10-14)
