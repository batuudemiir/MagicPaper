# p_picture_only_information

**Status:** decided · **Target:** `writing_guidance` · claim `c_picture_only_information` (LOW, 7/7 works)

> In all 7 analysed books at least one spread carries story information only in the picture (who caused the mess, what is hiding, who is now left out); one book is wordless.

- Current: text carries the whole story
- Suggested: Hypothesis for illustrated stories: leave one fact per story to the picture; not applicable to text-only stories.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

In all 5 analysed books at least one spread carries story information only in the picture (who caused the mess, what is hiding, how the feeling grows). Evidence: 5 of 5 works, small sample, confidence LOW. Proposal for `writing_guidance`: Hypothesis for illustrated stories: leave one fact per story to the picture; not applicable to text-only stories.

Evidence: `c_picture_only_information`, `w_mud_waterkeyn`, `w_grumpy_cloud_ditlhareng`, `w_catch_that_cat_pirie`, `w_brave_bora_gicovi`, `w_amahle_wants_to_help_nsibande`

**privacy-safety** · concern · 2026-10-08 08:07

Not applicable to today's text-only stories, and safety-relevant when illustrations arrive: information carried only by the picture escapes the text validators (banned phrases, ceiling, safety topics). 'What is hiding' drawn but not written is exactly the kind of content a parent's avoided topics or 'Sakin' level cannot filter. Also, read-aloud (MPSpeech) and VoiceOver users lose picture-only facts, so a story must still be complete in text.

Evidence: `c_picture_only_information`, `MagicPaper/StoryEngineBridge/CloudIllustrationAccess.swift`, `StoryEngine/Sources/StoryEngine/Content/SafetyVocabulary.swift`, `StoryEngine/Sources/StoryEngine/Domain/ChildSafetyPolicy.swift`

**story-engine** · concern · 2026-10-08 08:07

For the live text-only product this is inapplicable and would break coherence: the engine validates that text carries the arc (page roles, continuity), and a withheld fact with no picture is a plot hole. It becomes relevant only if illustrated stories go live; then it needs a page-plan field marking which fact is picture-only plus a validator exemption, owned jointly with illustration-system. Park until then.

Evidence: `StoryEngine/Sources/StoryEngine/Content/ContentPrimitives.swift`, `StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift`

**content-library** · concern · 2026-10-08 08:08

Not applicable to today's content: stories are text-only, illustrated stories are not live, and read-aloud (MPSpeech) means text must carry the whole story. Leaving a fact to the picture would make the text story incomplete. Revisit only when illustrated stories ship, and then as a scene-brief field, not a text change. Suggest park.

Evidence: `docs/MagicPaper_Faz_Plani_Ekim.md`

**book-research** · answer ↩ story-engine-1 · 2026-10-08 15:11

Agreed with all three: text-only stories read aloud must be complete in text. Park until illustrated stories ship, then as a declared scene-spec field checked by the image safety gate.

## Safety (privacy-safety)

**concerns** — Conditions: only for illustrated stories once live; the picture-only fact must be declared in the scene spec so it is checked against EmotionalState ceiling, avoided SafetyTopics and the blocking image gate; never a frightening reveal (hidden creature, threat); story remains understandable from text for read-aloud and VoiceOver.

## Recommendation (book-research)

**park** — Inapplicable to live text-only stories; revisit when illustrated stories go live, as a scene-spec field under the image safety gate.

## Decision (human)

**parked** — Resimli masallar canlıya çıkınca (2026-10-14)
