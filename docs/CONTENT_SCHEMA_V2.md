# MagicPaper Kids — Content Schema V2 Proposal

## Decision

Use one versioned, package-owned JSON catalog decoded by public `StoryEngine` Codable models. It is the runtime input to an offline template provider; the Content Creator validates and writes this file during development only. The app UI consumes opaque choice-card models and never reads the catalog directly.

The first shipping library remains deliberately narrow: Turkish `tr`, age 5–6, Adventure / Courage–Discovery, 8 pages. Existing V2 material is migrated, not deleted.

## Catalog shape

```text
ContentCatalogV2
  manifest: { schemaVersion, catalogVersion, supportedLocales, defaultLocale }
  blueprints[]
  settings[]             // parent/child-facing places
  companions[]           // parent/child-facing companions
  discoveries[]          // object and/or discovery event; parent/child-facing
  events[]               // engine-selected
  challenges[]           // engine-selected
  endings[]              // engine-selected
  templates[]            // role variants
```

Every record has a stable `id`, `localized`, `ageRange`, `tags`, `selection`, `safety`, and `provenance`-safe content version. Cross-record references use IDs only and are validated on load.

## Key records

### Blueprint

`id`, `worldKeys`, `themeKeys`, `ageRange`, `pageCount`, `pagePlan`, `requirements`, `compatibility`, `titlePatterns`, `safety`, `novelty`.

`pagePlan` fixes the V2 MVP roles: `hook`, `discovery`, `companion`, `problem`, `attempt`, `challenge`, `resolution`, `emotionalEnding`. Each page declares required state, state changes, allowed template IDs/tags, and visual intent. Blueprint requirements constrain setting, companion, discovery, event, challenge, and ending IDs/tags.

### User-selectable components

`Setting`, `Companion`, and `Discovery` provide localized short label, optional child-facing line, icon/illustration key, age range, tags, and compatibility rules. A discovery may bind an object and/or event through opaque engine IDs; it is not a technical category in the UI.

### Engine-selected components

`Event`, `Challenge`, and `Ending` add localized semantic fragments, compatibility constraints, state requirements/changes, safety rating, and novelty/cooldown weight. Endings must require a resolved state and declare a warm resolution policy.

### Template variants

A variant declares `id`, page `role`, localized text and visual scene templates, declared required/optional slots, state requirements/changes, compatibility tags, safety metadata, and optional continuity tags. Variant text is authored in native Turkish; no pronoun or English possessive tokens are permitted.

## Compatibility and state

Compatibility is an intersection, never a fallback to arbitrary content:

```text
age + locale + safety
  → place + companion + discovery
  → compatible blueprint
  → event + challenge + ending
  → state-compatible role variant per page
```

Use a small typed state bag: `locationID`, `companionID`, `discoveryID`, `problemDetected`, `attemptMade`, `challengeResolved`, and `returnedHome`. A page can only use variants whose state requirements are satisfied, then applies its declared transitions. The validator confirms all required page roles, state reachability, and a resolved ending.

## Selection, novelty, and provenance

Candidates are scored from documented weights: hard compatibility first, then explicit-choice affinity, recent-use penalties, and deterministic seeded tie-breaking. Store a `StoryComposition` with catalog/blueprint/component/variant IDs, selection seed, fingerprint, and validation report. The fingerprint is a stable hash of catalog version plus blueprint, all selected components, and ordered variants. Recent composition history is scoped to the child profile ID.

## Safety and visuals

All components require age band, severity/scariness metadata, and prohibited-content tags. The catalog loader rejects unsafe or incomplete records for the request. `visualScene` is optional story metadata and must retain a `VisualSystem` style/composition reference, but text generation remains fully offline and independent of image generation.

## Migration rules

1. Retain `StoryTemplate` for the existing AI provider; do not force V2 into it.
2. Move the canonical V2 JSON to `StoryEngine/Resources` and remove the app duplicate only after bundle tests pass.
3. Replace app-private `TestV2*` DTOs with package domain models and a `ContentCatalogRepository`.
4. Import legacy offline records only when their references, Turkish copy, state, and safety metadata validate; preserve originals for audit.
5. The Content Creator emits this catalog and a validation report; it is never linked into the iOS runtime.
