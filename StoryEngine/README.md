# Story Engine

The Magic Paper story engine: provider-agnostic, data-driven, and independent of
the app it serves. No UIKit, no SwiftUI, no vendor SDKs.

## Targets

| Target | What it owns |
|---|---|
| `EngineFoundation` | `SemanticVersion`, `VersionRequirement`, `StableHash` |
| `CharacterEngine` | Who a character is: profiles, versioned identities, asset sets, and the `DescriptorLexicon` that keeps appearance honest |
| `VisualSystem` | The design system as data: illustration styles, palettes, composition rules, page layouts, typography — compiled into the constraint set an image model receives |
| `StoryEngine` | Templates, planning, writing, scenes, validation, budgets, retries, the orchestrator |

`StoryEngine` depends on the other three. Nothing depends on `StoryEngine`.

## Two rules worth knowing before changing anything

**The engine cannot invent how a child looks.** `StoryCharacter` has no
memberwise initializer; the only one takes a `ResolvedCharacter` and is internal,
callable from `CharacterBinder` alone. Appearance reaches an image model through
`VisualConstraintSet`, compiled solely from `CharacterIdentity.descriptors`, and
never travels in a text prompt at all. `CharacterConsistencyValidator` then
checks the generated text and every image prompt against the lexicon, and an
unauthorized claim is an error that blocks publication.

**A scene is not an image.** A `StoryScene` is a visual context that owns zero or
more `VisualAsset`s, each with its own variant and fingerprint. Under the V1
`singleAssetPerScene` policy that is one picture per scene shared by several
pages; `assetPerVariant` gives a scene as many pictures as it needs. An asset is
only ever redrawn when its fingerprint changes.

## Pipeline

```
resolveTemplate → resolveCast → planStory → planScenes → planPages
  → draftNarrative → segmentPages → refinePages
  → planVisuals → generateImages → validate → assemble
```

Only `planStory`, `draftNarrative`, `refinePages`, `generateImages` and the
semantic half of `validate` cost money. Everything else is deterministic. The job
checkpoints after every stage, so a resumed generation never pays twice.

The book is drafted whole and then cut into pages, rather than written page by
page — that is what keeps the narrator's voice, the pacing and the emotional arc
consistent, and it is why single-page regeneration re-runs `PageRefiner` against
the draft's stored `voiceProfile`.

## Adding a kind of story

Write a JSON file in `Sources/StoryEngine/Resources/templates/`. A template is
narrative beats, layout, visual style, scene rules, generation policy and
validation rules, each independently versioned. Everything with a sensible
default may be omitted. There are no theme names anywhere in the engine.

## Production hardening

**Images are validated, not just requested.** Validating constraints proves what
was *asked for*; `ImageValidationProvider` is the contract for checking what came
back. Five outcomes, not two — `uncertain`, `providerUnavailable` and `skipped`
are distinct from `passed`, because "nobody looked" must never read as approval.
`GenerationPolicy.imageValidationMode` decides what that means: `.off` makes no
call, `.advisory` warns, `.required` blocks. A safety finding blocks under either
mode — advisory means "do not block on quality", never "ship anything".

**Every billable call has a deterministic identity.** A provider can generate an
image, lose the response to a timeout, and be retried — billing a family twice
for one picture. `ProviderRequestIdentity` makes a retry of the same logical work
carry the same key, and `ProviderResultCache` returns the recorded result rather
than paying again. Changing a revision, a fingerprint, or forcing a reroll all
produce a new key. A consequence worth knowing: `regeneratePageImage` without
`forceNewSeed` is the same logical request, so it reuses the existing picture and
costs nothing. Pass `forceNewSeed: true` to actually reroll.

**Child safety is one policy, not five opinions.** `ChildSafetyPolicy` gates
input, text, images and publication. The validators still do the work; what this
adds is a single place that decides what the product will publish. Unsafe input
is refused before a token is spent, and a safety-critical finding blocks
publication whatever severity its validator assigned.

**Deletion has boundaries.** `StoryDataLifecycle` separates logical records,
assets the engine removed, and external assets it only knows about — so a child's
photo still sitting in cloud storage after a deletion is visible rather than
assumed gone. Deleting a character cannot corrupt books already generated; every
deletion is idempotent.

**Concurrency is bounded.** `GenerationConcurrencyPolicy` caps stories, text
calls and image calls. FIFO, so one long book is not starved by newer work, and
capacity is released on success, failure and cancellation alike.

**Provenance is persisted.** `GenerationProvenance` records the engine version,
template version, prompt-compiler version, the provider and model actually used,
and the seed when generation was deterministic. Not shown to readers — it exists
so "the illustrations changed last week" is an answerable question.

## Tests

```bash
swift test
```

413 tests, no network. Providers, clock, ID generation and storage are all
injected, so every run is deterministic.

`Tests/StoryEngineTests/Fixtures/` holds golden snapshots of the deterministic
chain — beat plan, page skeletons, scene grouping, visual fingerprints, compiled
constraints. A failure there is not necessarily a bug, but it is always a
decision: set `regenerateFixtures = true` in `GoldenFixtureTests`, run once, set
it back, and say in the commit why the behaviour moved.
