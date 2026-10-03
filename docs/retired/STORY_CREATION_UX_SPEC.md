# Magic Paper Kids — Story Creation V2 MVP Spec

## Product promise

**Üç küçük seçim. Kocaman bir masal.**

A parent and child make a tiny ritual together. They choose where to go, who joins them, and what magical thing they discover. Magic Paper quietly chooses story structure, pacing, challenge, ending, and visual treatment.

The UI must never say or ask for: template, blueprint, genre, narrative state, page count, challenge, ending, content ID, or compatibility rule.

## Scope and non-goals

MVP makes one newly generated story for one saved child profile. It preserves the app’s warm paper surface, large rounded cards, soft shadows, illustrated/icon-led choices, and generous touch targets. It replaces the current four-step V1 choice vocabulary with three creative choices; it does not redesign the reader, billing policy, profile editing, or content-authoring tools.

## Parent/child flow

```text
Home / “Yeni Bir Masal”
  → Choose child (only if more than one, otherwise preselected)
  → 1. Place
  → 2. Companion
  → 3. Secret / discovery
  → “Magic Paper hazırlanıyor”
  → Cover reveal
  → Reader
```

Every choice screen presents four visible, compatible cards plus a distinct **Bana sürpriz yap** card. Selecting a card advances immediately; Back preserves the previous choice. Surprise chooses only that stage’s value, not the child profile or unrelated account settings.

### 0. Child (conditional)

- If exactly one child profile is available, show their avatar/name in the top bar and skip this screen.
- With multiple profiles, ask “Bu masal kimin için?” and show large profile cards plus “Yeni profil ekle.”
- Never ask for age or a photo during story creation; use the saved profile. If a photo is absent, generation remains supported with a non-photo character treatment; do not invent physical traits.

### 1. Place — “Nereye gidelim?”

Four content-driven place cards such as Orman, Bulutların Üstü, Deniz Altı, and Gizli Bahçe. Each has an illustration/icon and one short sensory line, e.g. “Yaprakların arasında fısıltılar var.” This is a choice of imaginative setting, not a genre.

### 2. Companion — “Yanımızda kim olsun?”

Show four companions compatible with the selected place and the child’s age. Example cards: Tilki, Baykuş, Minik Ejderha, Kaplumbağa. The choice is friendly and affirmative; no locked options or technical explanation. If a previously valid choice becomes unavailable only after a back-navigation change, retain it until the parent selects a replacement and explain gently only if needed: “Bu yolculuk için yeni bir dost seçelim.”

### 3. Secret / discovery — “Bugün neyi keşfedelim?”

Show four discoveries compatible with the first two choices: Parlayan bir ışık, Kaybolmuş bir harita, Şarkı söyleyen taşlar, Küçük bir dilek. This is the final explicit choice. The button becomes “Masalımızı hazırla”; a compact recap uses child, place, companion, and discovery in natural language.

## Preparation and reveal

Tapping the final CTA creates and persists the request before costly work begins. The preparation screen is a calm, cancellable status surface—not a fake percentage or technical spinner:

- Headline: “Sayfaları sihirle hazırlıyoruz…”
- Support line changes by meaningful stage: “Hikâyenin yolunu çiziyoruz”, “Masalın sayfalarını yazıyoruz”, “Resimleri hazırlıyoruz”, “Kitabı bağlıyoruz.”
- A paper/ink animation may be used, but it must respect Reduce Motion.
- Cancel asks for confirmation only after generation has started; cancellation retains the incomplete book/job for safe resume or deletion.
- Failure says what the family can do (“Tekrar deneyelim” / “Daha sonra devam et”) and never exposes internal template or provider errors.

When successful, reveal the cover first: “`[Child]` ve `[discovery]`” (engine-authored localized title may replace this). Then offer one clear action: “Masalı oku.” A quiet secondary action may be “Kütüphaneye ekle.”

## Surprise Me behavior

Surprise chooses from the same age-, safety-, locale-, and compatibility-filtered catalog as an explicit choice. It must be reproducible for a stored request (persist resulting opaque IDs and seed), but it must feel delightfully spontaneous. A Surprise choice can be used at any of the three screens. On the final screen, “Hepsini bana sürpriz yap” is optional only if it is visibly equivalent to selecting Surprise at all remaining stages.

## UI state model

`StoryCreationDraft` is ephemeral UI state; `StoryIntent` is persisted with the generation request. Both use stable catalog IDs, never localized display text.

| Field | Owner | Persisted | Notes |
| --- | --- | --- | --- |
| `childProfileID` | profile selection | yes | Existing `UserProfile.id`; maps to engine character ID. |
| `placeID` | place card | yes | Resolved result when Surprise is chosen. |
| `companionID` | companion card | yes | Resolved result when Surprise is chosen. |
| `discoveryID` | discovery card | yes | Resolved result when Surprise is chosen. |
| `catalogVersion` | catalog resolver | yes | Lets a finished book reproduce its selections. |
| `selectionSeed` | intent resolver | yes | Used for deterministic internal selection. |
| template/blueprint/beat/ending | engine only | engine provenance | Not a UI field. |

The resolver receives `StoryIntent` and returns a validated internal generation plan. It may choose template, blueprint, object/event/challenge, tone, page count, and ending. It must report a product-level `noAvailableStory` only after validating the current catalog; the UI then offers a safe fallback such as “Bana sürpriz yap” or asks to choose another place, never a raw error.

## Content and localization rules

- Catalog records contain stable IDs, Turkish/English display content, artwork/icon references, age ranges, compatibility tags, and safety metadata.
- The UI gets pre-filtered card models from a catalog service. It does not perform equality checks on Turkish labels.
- Content authors can add places, companions, and discoveries without changing SwiftUI screens. The engine may have many more internal variants than the four cards shown.
- Four cards is the default. If fewer than four compatible choices exist, fill with safe Surprise/curated fallback choices; do not show an empty grid.
- All strings are localized and titles/summaries handle Turkish suffixes in the content/assembly layer, not by view concatenation.

## Acceptance criteria

1. A typical user reaches generation in three selections (or fewer when a child is already active).
2. Each selected place, companion, and discovery visibly influences the saved story; no option silently maps to a fixed forest or fox.
3. No technical engine vocabulary appears in the shipping flow or user-facing errors.
4. Every saved request can resume/retry after relaunch and retains its child identity and resolved selections.
5. The app remains usable offline until a provider-dependent stage; the catalog and request validation do not depend on a hard-coded developer file path.
6. The flow respects existing subscription gating, parental settings, Dynamic Type, VoiceOver labels, Reduce Motion, and large touch targets.
