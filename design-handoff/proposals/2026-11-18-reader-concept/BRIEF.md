# Reader concept · 18 November 2026

Status: proposed design for visual review; no application implementation authorized. Audience: child and accompanying adult while reading; settings use the calm adult register. Scope: two interior page compositions and existing reading settings. Cover, onboarding, home, completion rewards and character trials are outside this proposal.

## Recommendation

Make the reader feel like a small illustrated book with room to breathe. Alternate a scene-led page with a quiet continuation page where the picture is a small narrative afterthought. White is the default paper. Purple belongs to selected controls and the child's name; lilac, turquoise and coral belong principally to matte gouache artwork. Never add stars, atmospheric particles, floating stickers or decorative fantasy scenery around the text.

Compared approaches: full scene on every page makes the story visually repetitive and crowds larger text; text-only pages preserve reading but lose the illustration rhythm the user liked. Recommend scene/spot alternation when content supports it, without mechanically forcing every second page to be illustrated.

## Layout

**A · Scene page.** Root `ReaderPaper`, upper scene, text below, overlaid `ReaderChrome`. Full-width artwork without a card, radius or shadow. Keep the artwork's focal character below the safe-area controls. In the visual prototype aim for roughly two fifths of the usable portrait page, rather than today's image-led half-page. This is a composition target, not a new global spacing token. Retain scene aspect-ratio information and show enough of the image to preserve the storytelling action. Text starts after `MP.S.x6`, with `StoryPageView.gutter` (`MP.S.x7`) on both sides. Short page title only when supplied by story data; never repeat the book title. Left-aligned text and a free right edge. White remains visibly dominant below the artwork. Retain the existing quiet paper-to-scene transition provisionally; compare its curve in the visual review before changing it.

**B · Quiet continuation.** Same paper and gutters. Top text clears `MP.S.navBarHeight`; do not vertically center a single sentence in the entire screen. Put a modest, unframed transparent spot illustration after the text, within the reading column, with `MP.S.x6` separation. Centre its footprint horizontally; leave substantial untouched paper around it. It depicts one action-bearing object or character detail from this exact page. Do not reuse an unrelated watering-can or decorative asset merely to fill space. It must not push text out of view. When space is tight, reduce its footprint or omit it. A missing spot produces an intentional text-only page. This is a **proposed new composition**: current `page.hasIllustration` routes art above text; it does not distinguish scene and spot.

**Chrome.** Preserve the current permanent close circle at upper leading edge. Favorite and Aa remain one small upper trailing group, with no header bar or repeated book title. Preserve automatic withdrawal of secondary controls, existing timing, and tap-to-reveal. Close never fades. Visible bottom controls remain previous / page position plus speech / next, one quiet `mpGlassSurface`; do not add another floating speech pill. Keep the lower strip visually subordinate to the page, with available content space reserved so it cannot cover the last line or spot. Hidden state retains the existing folio and fine progress line. Recommend reviewing the visual density of the progress line in the mockup, but retain page seeking and adjustable accessibility behavior. Do not remove functionality to obtain a cleaner screenshot.

## Views, state and ownership

- Reuse `StoryPageView`, `ReaderPaper`, `ReaderChrome`, `ReaderSettingsSheet`, `MPSegmented`, MP sheet and button components. Do not invent a second reader framework.
- Proposed `ReaderPageComposition` presentation value: scene / spot / text. Illustration metadata owns art role and focal safe area; reader model or a presentation resolver owns composition choice and fallback. SwiftUI only renders that choice. Existing content remains valid and defaults to its current composition.
- `StoryPageView` keeps page, theme, size, spacing, easy-reading, age layout, child name, folio, accent and symbol inputs. Any future spot input must carry semantic alternative text and source identity.
- `ReaderChrome` keeps its existing favorite, speech, position and callback contract. No business logic moves into it. `StoryReaderModel` retains page position, and `MPSpeech`/`MPSpokenPosition` retain playback and highlighting.
- Settings continue to bind to `MPAppState` and `MPSettingsStore`; proposed layout changes do not reset a parent's chosen settings.

## Typography and tokens

Story body exclusively `MP.F.read(MP.ReadSize.points)`: existing choices 17 / 19 / 22 / 26. Preserve age default: up to 6 → very large, 7–8 → large, older → normal, unless chosen already. Preserve `.breath` for ages 3–6 and paragraphs for older ages. Breath lines retain the current one-size-up rule and at least `.rahat` spacing. Paragraph line spacing remains `points × MP.ReadSpacing.factor` (normal 0.72, rahat 0.9, genis 1.1); do not substitute CSS line-height values as SwiftUI `lineSpacing`.

Page heading `MP.F.displaySM()` only; UI labels use existing `.footnote`, `.body`, `.section`, `.cardTitle` roles. Preserve Nunito for easy reading, Turkish ligature protection and current sound-word treatment. Name emphasis stays semantic, not a gradient or highlighted pill.

Colors come from `MP.ReadTheme.paper`, `.foreground`, `.muted`, `.highlight`, `.readAlong`; app settings use `MP.C`/existing MPColor bridge. Default `.light`, optional `.cream`, `.sepia`, `.dusk`, `.night` remain. **Proposed mapping change:** Gündüz should resolve to the existing white paper token after approval; its current reader-day asset is warm, so white in the prototype is a proposal, not a faithful rendering of today's token. No new palette, radius, font, spacing token or SPM dependency requested. Approved social art direction is a style reference for this proposal, not approval to replace current in-app illustration presets. Production art must reference the approved `VisualSystem` preset once confirmed.

## Settings

Keep the existing system half sheet, expandable by dragging, titled “Okuma ayarları”, with one bottom “Okumaya dön” action. Recommended order: **Yazı**, **Kâğıt**, **Daha fazla**. Text size is the most likely mid-reading adjustment; show current size name beside the existing four-stop slider. Keep Normal / Rahat / Geniş and Kolay okuma. Show a short live text sample using the actual chosen size/spacing when the page behind is obscured; this is a proposed addition and must use localized sample copy, never a fabricated story passage.

Paper keeps all five labeled swatches, selected border and selected trait. Texture and automatic night remain with paper. Existing voice/speed/haptic settings remain under Daha fazla. Do not add font family choices, theme subscriptions, an audio dashboard or another reader-mode chooser; “Kim okusun?” already lives on the cover. Apply adjustments immediately and preserve current page/reading position. The settings sheet is an opaque app surface, not more translucent glass.

## States and edge cases

Normal reading has no loading chrome or shimmer. Reserve the artwork slot while its image loads; text stays readable. An unavailable scene falls back to text with a stable layout for this visit; never insert random replacement art. A missing spot disappears. For a truly empty/corrupt page, offer a small localized explanation and accessible next/close path, without a second mascot scene.

Long legacy text and accessibility text sizes must remain scrollable; never shrink the font to fit. Short text must not bounce. Proposed composition resolver prioritizes text: reduce scene height, then use text-first layout; spot is optional. Keep the same folio despite visual overflow; changing font must not silently change story progress or completion. At the last page retain the current completion route; propose a plain forward/book-ending symbol instead of checkered flag only after approval, since this is existing behavior. No automatic page advance is newly introduced.

Speech preserves current age-specific word/sentence highlighting; avoid dimming earlier prose so far that rereading becomes difficult. Page turns, seeking and modal opening must follow existing speech interruption/resume policy. Verify that policy before implementation rather than inventing it in a view. Word actions remain available; revealing controls must not consume a vocabulary-word activation.

## Adaptive and accessibility

iPhone portrait is the primary composition. Small phones and landscape prioritize readable text over image acreage; allow vertical overflow. Existing iPad landscape image-left/text-right spread remains, with a maximum reading measure; a spot occupies modest space rather than being scaled to fill the left leaf. Accessibility sizes use one readable column as today. Do not impose a fixed-height scene or settings preview at large Dynamic Type.

Preserve `MP.S.tapMin` (48) minimum controls and existing `MPSize.minTouchHero` (64) page navigation, exceeding the 44pt baseline. VoiceOver: page position once, narrative as continuous text, image description only if informative, named word actions, labeled previous/next/close, adjustable page seeking. Selected themes announce selection, not color alone. VoiceOver focus and interaction keep secondary controls available; no timeout while focused, seeking or sheet interaction. Ensure hidden controls are absent from accessibility navigation. Read-aloud button announces play/pause state through `MPSpeech`, without conflating VoiceOver narration with story speech.

Every new or touched label must go through `LocalizationManager`; current reader files contain Turkish literals, which are integration debt rather than examples to copy. Turkish/English labels wrap in settings rather than shrink. Page counts use localized formatting. Do not abbreviate essential speech controls into unexplained icons when space is tight.

## Interaction and motion

Preserve existing page-curl container and explicit next/previous buttons. Tap on noninteractive paper reveals/hides chrome; do not make a central text tap advance pages. Swipe/curl is supplementary, never the only route. Preserve `MP.M.gated(MP.M.easeOut)` for secondary chrome and current Reduced Motion alternate page transition. No parallax, image breathing, sparkle or celebratory motion during reading. Use existing `MPHaptics` behavior; no new haptic for every word, image appearance or seek step. Respect bedtime and reduced-motion settings.

## Evidence, conflicts and handoff

Read: `AGENTS.md`; reader-related search results in `docs/PROJE_HAFIZASI.md`; `StoryPageView.swift`, `ReaderChrome.swift`, `ReaderText.swift`, `ReaderPaper.swift`, `StoryCover.swift`; relevant portions of `StoryReaderView.swift`, `Screens/MPSheets.swift`, and `DesignSystem/MPTheme.swift`; `marketing/social/brand/ART_DIRECTION.md`; earlier `magicpaper-reader.html` scene/spot reference structure. No app builds, tests or simulator runs: this is a proposed design only.

Conflicts requiring explicit review: scene/spot role is absent from current page layout; smaller scene target changes current composition; settings reordering/live sample are proposed; permanent X and large navigation targets must survive simplification. Character-comparison trials remain unapproved and are not canonical art. No illustration-engine or character-identity change is implied.

Owned change: this BRIEF.md only. Parent agent owns the interactive visual review and requested changelog entry; no shared changelog edits or commits made here. Approval of the visual direction must precede application changes.
