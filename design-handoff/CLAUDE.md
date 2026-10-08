# MagicPaper Kids · design handoff for Claude Code

This package is the complete design spec for the MagicPaper Kids iOS app (SwiftUI, iOS 17+): design system, 45 prototype screens with 15 extra state screenshots, navigation map, brand and mascot assets, and the story engine contract with 2,427 test vectors. Your job is to implement the real app so it matches these screens exactly.

## Source of truth, in this order

1. `screens/*.png`: what it must look like (390 × 844 pt, rendered @2x).
2. `reference/html/<Screen>.dc.html`: exact values. Inline styles hold the precise colors, paddings, radii and font sizes when a screenshot is ambiguous.
3. `design-system/tokens.json` and `ios/DesignSystem/*.swift`: the tokens and components to build with.
4. `docs/SCREENS.md`: per-screen route, presentation, purpose, data, interactions and the exact on-screen copy.
5. `docs/NAVIGATION.md`: every tap target and where it leads (from the prototype's real links).
6. `docs/ENGINE.md` and `engine/`: story request, response, errors and backend behaviour.

When these disagree, the higher item wins. Flag the conflict in your summary instead of guessing silently.

## Package map

```
CLAUDE.md                     this file
README.md                     Turkish overview for the team
docs/
  DESIGN_SYSTEM.md            principles, tokens, components, presentation, accessibility
  BRAND_AND_MASCOT.md         logo, app icon, 14 mascot assets and where each one goes
  SCREENS.md                  45 screens, one section each, with screenshot and copy
  NAVIGATION.md               mermaid flow + link table
  ICONS.md                    Lucide → SF Symbols mapping used in the prototype
  ENGINE.md                   story engine flow, age bands, error → screen table
  IMPLEMENTATION_PLAN.md      phased checklist, one ticket per screen
design-system/tokens.json     colors, type, spacing, radius, shadow, size, motion
ios/
  Assets.xcassets/Colors      80 colorsets (namespaced: Color("Colors/brandPurple"))
  Assets.xcassets/Brand       20 imagesets (namespaced: Image("Brand/mascotHappy"))
  DesignSystem/               MPColor, MPTypography, MPLayout + Components/*
  Models/StoryEngineModels.swift
  Navigation/Route.swift      route enums + deep links (magicpaper://)
assets/brand, assets/fonts, assets/icons/lucide
screens/                      01–45 PNGs, state-*.png, index.json (machine-readable list)
engine/                       catalog.json, schemas, prompts, fixtures, reference engine (node)
reference/html, reference/DEMO_CHANGELOG.md
```

## Hard rules

- **Copy:** Turkish, use the exact strings in `docs/SCREENS.md`. Second person ("sen"). Never use the em dash (—) in UI copy, comments or docs; use a comma, colon or a new sentence.
- **One primary button per screen** (`MPButton(kind: .primary)`).
- **Mascot:** at most one per screen, one feeling, never in the parent area. Use the mapping in `BRAND_AND_MASCOT.md`.
- **Child safety:** no purchases, external links, settings or sharing reachable from the kid area without passing the parent gate (`EbeveynKapisi`). Paywall opens only from the parent side or behind the gate.
- **No hard-coded colors or fonts** in screens. Use `MPColor`, `MPWorldTone`, `ReaderTheme`, `.mpText(_:)`, `MPSpacing`, `MPRadius`, `.mpShadow(_:)`.
- **Kid vs parent styling:** kid = `background.kid` cream, 56 pt touch targets, `MPCard(area: .kid)`; parent = `background.parent` gray, 44 pt, system-like grouped lists, `MPCard(area: .parent)`.
- **World list, ages, lengths, tones** come from `engine/catalog.json` (served by backend later), not from hard-coded arrays in views.
- **iOS 17 minimum.** Do not use iOS 18 only APIs such as `Group(subviews:)` or the new `Tab` syntax inside `TabView`.

## Conventions

- Fonts: add `assets/fonts/Nunito-Variable.ttf` and `Nunito-Italic-Variable.ttf` to the target and to `UIAppFonts`. Family name is `Nunito`.
- Assets: copy `ios/Assets.xcassets/Colors` and `Brand` folders into the app catalog keeping "Provides Namespace".
- Icons: SF Symbols per `docs/ICONS.md`. The Lucide SVGs in `assets/icons/lucide` are only for reference or custom symbols.
- Light appearance: set `UIUserInterfaceStyle = Light`; dark looks exist only in the reader Night theme and Sleep mode.
- One SwiftUI file per screen under `Features/<Area>/<ScreenName>View.swift`, named after the prototype file (`AnaSayfa` → `HomeView` is fine, keep a comment with the prototype name and number).
- Every screen gets `#Preview`s for each state in `screens/state-*.png`.

## Important caveat

All Swift in `ios/` was written **without a compiler** (no Xcode was available when the package was produced). Treat it as a careful reference implementation: add it to the project first, build, and fix any compile errors before building screens on top. Keep APIs and token names stable when fixing.

Mascot PNGs are 1x only (cropped from the brand kit). Leave the asset names as they are; higher resolution exports will be dropped in later.

## How to work through it

Follow `docs/IMPLEMENTATION_PLAN.md` phase by phase. For each screen:

1. Open its section in `docs/SCREENS.md` and its PNG(s).
2. Build it from design-system components only; if a needed component is missing, add it to `ios/DesignSystem/Components` rather than styling inline.
3. Wire every interaction listed under "Gezinme".
4. Add previews for all states, compare against the PNG at the same size, fix differences.
5. Tick the box in the plan.

## Acceptance checklist (per screen)

- [ ] Layout, colors, radii, spacing and copy match the PNG at 390 × 844.
- [ ] All tap targets from `NAVIGATION.md` work.
- [ ] All states shown in `state-*` images can be produced from previews.
- [ ] Dynamic Type up to XL without clipping; VoiceOver labels present.
- [ ] No hard-coded color, font or magic spacing values.
- [ ] Kid screens: nothing purchasable or external without the parent gate.
