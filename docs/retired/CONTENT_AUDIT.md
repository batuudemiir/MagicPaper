# Magic Paper Kids — Story Content Audit (V2 baseline)

Date: 2026-09-15. Scope: bundled JSON story resources, their active decoders/loaders, and the content implications for Story System V2. No production code or content was changed by this audit.

## Executive finding

The repository has two distinct data-driven story systems:

1. `StoryEngine` owns a mature, SwiftPM-bundled `StoryTemplate` schema used by the AI orchestration path.
2. The app has a separate, currently active *offline text-story* prototype which reads `shared_content_library_v2.json` with private `TestV2*` models.

The V2 JSON is syntactically valid and is copied into the iOS app target, but it is **not a `StoryTemplate` resource** and is therefore skipped by `BuiltInTemplates`. It is not decoded by a reusable StoryEngine content repository. The app-side V2 provider uses only blueprints, settings, companions, objects, and role templates; events, challenges, endings, and the empty resolutions collection are not used to build a story.

This is a sound starting inventory, not yet the production-quality content system described by the V2 brief.

## Resource inventory and bundling

| Resource family | Canonical location / owner | Observed consumer | Notes |
| --- | --- | --- | --- |
| Legacy structured template | `MagicPaper/StoryEngine/Sources/StoryEngine/Resources/templates/adventure_01.json` | `BuiltInTemplates` / `StoryOrchestrator` | Decodes into `StoryTemplate`; contains narrative, visual, safety, validation, and generation policy. |
| Legacy offline blueprints | `.../Resources/templates/offline/*.json` | No production loader found | 13 JSON files: 12 `blueprint` wrappers plus `shared_content_library.json`; these do not match `StoryTemplate` and are skipped by `BuiltInTemplates`. |
| V2 shared library | `MagicPaper/MagicPaper/templates/offline/v2/shared_content_library_v2.json` | `TestOfflineTemplateStoryProvider` | Explicitly in the iOS target Resources build phase. |
| V2 duplicate | `MagicPaper/StoryEngine/Sources/StoryEngine/Resources/templates/offline/v2/shared_content_library_v2.json` | No V2 package decoder | Byte-for-byte identical to the app copy (same SHA-1). SwiftPM also processes it in the StoryEngine resource bundle. |
| Visual catalog | `.../VisualSystem/Resources/visual_catalog.json` | `VisualCatalog` | Separate data model; loaded from `Bundle.module`. |
| Character lexicon | `.../CharacterEngine/Resources/lexicons.json` | `DescriptorLexicon` | Separate data model; loaded from `Bundle.module`. |

The Xcode project copies the app-side V2 file and `adventure_01.json`. `Package.swift` processes all StoryEngine resources. Thus V2 currently has two sources of truth and may be present in both the app bundle and the package bundle. Keeping both copies synchronized manually is a release risk.

`BuiltInTemplates` enumerates flat JSON resources and tries to decode either `{ "templates": [StoryTemplate] }` or an individual `StoryTemplate`. V2 has a different top-level shape, so it is silently ignored by that loader. The app provider instead searches `Bundle.main`, all bundles/frameworks, and finally a hard-coded developer-machine absolute path. That last fallback must not survive a production migration.

## V2 library schema and coverage

`shared_content_library_v2.json` declares version `2.0.0` and contains:

| Collection | Count | Typical fields | Runtime status |
| --- | ---: | --- | --- |
| settings | 16 | name, description, visual keywords, genre/theme compatibility, tags, novelty/cooldown weights | Selected; compatibility by theme only. |
| companions | 15 | type, personality, visual description, setting/theme compatibility, weights | Selected; compatibility by theme only. |
| objects | 20 | description, theme compatibility, tags, weights | Selected; compatibility by theme only. |
| events | 20 | required state, state changes, setting/theme compatibility | Not selected or applied. |
| challenges | 15 | state requirements/changes, setting/theme compatibility | Not selected or applied. |
| resolutions | 0 | — | Empty and unused. |
| endings | 10 | ending content/compatibility | Not selected or applied. |
| templates | 52 | role, compatible themes, 3 text/visual variants | Selected by role and theme. |
| blueprints | 12 | genre, theme, age range, page count, ordered page roles | Selected by genre, then soft age/page filtering and read history. |

All 12 blueprints are currently **`adventure` / `courage` / `5-6` / 8 pages** and use exactly this role sequence: `hook`, `discovery`, `companion`, `problem`, `attempt`, `challenge`, `resolution`, `emotional_ending`. The library advertises broader choices—settings cover `adventure`, `fantasy`, `ocean`, and `space`; metadata includes several additional themes—but those options have no matching blueprint. The provider falls back to all blueprints when genre has no match, so an unsupported selected genre silently produces an adventure/courage book.

Templates provide five three-variant templates for most active roles, six for `companion` and `problem`, plus five each for currently unused `celebration` and `bedtime_transition`. This is enough for a prototype, but variants are not meaningfully coupled to a selected blueprint, event, challenge, resolution, ending, companion setting, or narrative state.

## Placeholders, language, and prose quality

The V2 token vocabulary is limited to `{{child.name}}`, `{{setting.name}}`, `{{companion.name}}`, and `{{companion.type}}`. The resolver additionally supplies `child.age` and `object.name`, although neither currently appears in V2 templates. Placeholder substitution is followed by an unresolved-`{{` check, which is useful, but there is no schema-time declaration of required/optional slots or grammar morphology requirements.

The primary reader text is Turkish, while content IDs, genre/theme keys, role names, and many visual strings are English or mixed English/Turkish. A large portion of visual prompts are placeholders such as `{{child.name}} hook sahnesi.` rather than illustration-ready scene descriptions. This will not meet visual consistency or child-character depiction needs if image generation is later attached.

V2 contains no `language` field, localized content map, locale fallback policy, reading-level metadata, word-count target, title variants, or Turkish grammar constraints. The provider always creates the offline story with `.turkish`, regardless of the request language. The existing legacy resources also mix Turkish narrative text with English `visualScene` values, so this needs a deliberate library-wide localization policy rather than a one-off translation pass.

## Compatibility, narrative state, and deterministic behavior

The V2 data has promising compatibility/state fields (`compatibleSettings`, `compatibleThemes`, `requiredState`, `stateRequirements`, `stateChanges`) and novelty/cooldown weights. They are not implemented end-to-end:

- Selection checks only `compatibleThemes`; user-supplied setting/companion IDs bypass even that check.
- `compatibleGenres`, `compatibleSettings`, tags, novelty weight, cooldown weight, events, challenges, endings, and state transitions are ignored.
- Blueprint `theme` is used as fallback, but a user-provided theme can select templates incompatible with the blueprint because no full compatibility intersection is calculated.
- There is no typed narrative state, state transition validation, reachability check, or reference integrity validation.
- Read history records only blueprint IDs; with 12 same-shaped blueprints, novelty is shallow. Nothing records recent settings, companions, templates, events, challenges, objects, or endings.
- The local LCG can make per-request selection reproducible if a seed is retained, but the app supplies `UInt64.random` and does not persist the seed or selected content IDs in the generated `Story`.

This means a book can be rendered deterministically only accidentally; it cannot be reliably regenerated, audited, or explained from stored provenance.

## Page roles and content quality

The fixed 8-role arc is a sensible MVP narrative spine. However, page roles are just strings in V2 rather than a validated shared vocabulary. `celebration` and `bedtime_transition` templates have no V2 blueprint role, while `endings` is a separate unused collection. The V2 provider simply chooses one compatible role template per page; it never binds a page to a blueprint-specific beat or verifies that text, visual prompt, setting, companion, object, event, challenge, and ending agree.

Legacy offline blueprint files are richer at the page level: each variant can declare `requiredSlots`, `optionalSlots`, `stateRequirements`, and `stateChanges`, and some include safety metadata. They are nevertheless not part of the active app flow. The main `StoryTemplate` schema goes further still, including child safety, validation rules, generation policy, scene rules, and visual-style requirements. V2 should retain those strengths instead of creating a parallel, less expressive runtime schema.

## Visual and safety metadata

V2 settings/companions carry useful raw visual keywords/descriptions, but V2 has no illustration style ID, palette, layout/composition rule, character-consistency constraint, negative prompt/do-not-depict data, image-safety policy, or page-level visual composition metadata. It does not integrate with `VisualCatalog` or the child character asset system.

No V2 blueprint, role template, or top-level library has a child-safety policy, content rating, scariness scale, prohibited themes, conflict/resolution rules, or age-specific safety rule. Some legacy offline blueprints have inconsistent ad-hoc safety metadata; `adventure_01.json` has the strongest structured safety/validation metadata. Safety needs to be normalized and enforced before selection, not left as descriptive content.

## Tests and release validation

`jq empty` validates the checked-in content JSON. Existing StoryEngine tests cover legacy template loading/decoding, template resolution, safety policy, serialization, and related engine behavior. No automated test was found for V2 decoding, bundle lookup in the app target, V2 reference integrity, compatibility selection, placeholder completeness, locale completeness, narrative-state transitions, deterministic replay, or content safety.

## Recommended V2 migration order

1. Establish **one canonical V2 source** under StoryEngine resources (or a dedicated content package), and make the app bundle consume that resource through an injected repository. Remove the duplicate only as part of that change, after confirming archive bundle behavior.
2. Define versioned, public Codable V2 domain models in StoryEngine: library manifest, content IDs, localized strings, selection constraints, typed page roles, variant slots, safety metadata, visual metadata, and provenance. Decode strictly with actionable diagnostics; do not rely on ignored unknown fields.
3. Build a deterministic `ContentLibraryRepository` and selector. It should compute a complete compatibility intersection for the three user choices (place, companion, secret/discovery), age, locale, safety policy, blueprint, and state; seeded selection must persist every chosen ID and the seed in story provenance.
4. Make the 3-choice UX map to content IDs only. The engine, rather than the UI, should choose blueprint, object/event, challenge, resolution, ending, and variants. Preserve a real `Surprise Me` route that uses the same selector with no forced preference.
5. Replace generic visual scene placeholders with reviewed, localized, role-specific scene briefs and bind them to VisualSystem style/composition constraints and CharacterEngine identity/do-not-depict rules.
6. Add content QA tests: JSON/schema decode; unique IDs; all references resolve; every supported place/companion/secret combination has a safe path; role coverage by blueprint; slot resolution; locale/age completeness; state reachability; deterministic golden stories; forbidden-content/scariness checks; and bundle smoke tests.
7. Expand content only after the selector can validate it: current shipped V2 supports only 5–6-year-old, 8-page adventure/courage books despite broader catalog metadata. Add blueprints in balanced combinations rather than adding unselectable settings or templates.

## Implementation guardrails

- Keep the existing `StoryTemplate`/AI path working; introduce V2 behind a repository and provider boundary rather than replacing it wholesale.
- Do not retain the `Test*` provider/model names or developer-machine absolute-path fallback in a production system.
- Treat visual and child-safety constraints as required selection inputs and persisted provenance, not prompt text or optional content annotations.
- Content Creator output should validate this same V2 schema offline; the iOS runtime should only load/select/validate bundled content and should not depend on the creator or an LLM.
