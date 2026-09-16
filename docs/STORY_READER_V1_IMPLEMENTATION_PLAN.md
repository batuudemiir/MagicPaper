# Story Reader V1 — Implementation Plan

**Date:** 2026-09-15
**Status:** Plan only. No implementation code written.
**Scope:** replace the generic paged text screen with a book: native page curl,
typeset pages, paper surface, quiet chrome.
**Method:** every claim about the current code is cited to a file and line and
was read, not inferred.

---

## 0. The one-sentence problem

`Views/StoryViewerView.swift` is a `VStack` with a progress bar, a 170×170
rounded thumbnail, centred text and three chevron buttons. It displays a story
correctly and feels like a settings screen. Nothing about it is wrong; nothing
about it is a book.

---

## 1. Current reader architecture, as it actually is

### 1.1 The path a story takes to the screen

```
LibraryView.swift:58  /  HomeView.swift:175
        ↓  app.sheet = .storyActions(story.id)
ContentView.swift:103 resolves the id back to a Story
        ↓
MPSheets.swift:96-97   app.sheet = nil ; app.readerStory = story
        ↓
ContentView.swift:49   .fullScreenCover(item: $app.readerStory)
        ↓
StoryViewerView(story:)
```

Creation reaches it differently — `StoryCreationFlow.swift:108-113`, the cover's
`onOpen`:

```swift
app.readerStory = story
dismiss()
```

and the old wizard differently again — `StoryWizardView.swift:90-94` dismisses
*first*, then assigns. Three entry points, three orderings.

### 1.2 What exists

| Concern | Location | Shape |
|---|---|---|
| Route | `Screens/MPAppState.swift:83` | `@Published var readerStory: Story?` — no enum case, no `.reader` route |
| Presentation | `ContentView.swift:49-51` | one `.fullScreenCover(item:)` among seven siblings |
| Dismiss | `StoryViewerView.swift:70`, `:181` | `@Environment(\.dismiss)`; **nothing anywhere sets `readerStory = nil`** |
| Model | `Models/Story.swift:4-58`, `:130-151` | `Story` / `StoryPage`, Codable value types |
| Truth | `Services/StoryGenerationManager.swift:9-16` | `@MainActor ObservableObject`, `.shared`, `@Published var stories` |
| Progress | `StoryGenerationManager.swift:998-1007` | `lastReadPage: Int?`, whole-array JSON → `UserDefaults["stories"]`, **per page turn** |
| Completion | `MPStoryExtras.swift:19-22` | derived `mpProgress`; no stored flag |
| Paging | `StoryViewerView.swift:210-243` | hand-rolled opacity + 14pt offset, `DispatchQueue.asyncAfter`, tap-only |
| Images | `FileManagerService.swift:64-81` | sync disk read + full decode, **called from `body`**, zero cache |
| Chrome | `StoryViewerView.swift:66-104`, `:185-205` | always-visible top bar, progress bar, 3-button footer |

### 1.3 The five defects this work has to fix, not merely paper over

**D1 — the page turn is not a page turn.** `StoryViewerView.swift:210-243`: two
hardcoded `withAnimation(.easeOut(duration: 0.13))` calls around a
`DispatchQueue.main.asyncAfter(deadline: .now() + 0.13)`. It is the only motion
in the reader that bypasses `MP.M.gated(...)`, so **Reduce Motion does not
disable it**. There is no `DragGesture` anywhere in the reader: turning is
tap-only, so the page never follows a finger.

**D2 — no re-entrancy guard.** `goNext()` (`:212-215`) and `goPrev()` (`:217-220`)
bound the index but neither checks `turning`. Taps inside the 0.13 s window
re-enter `turn(...)` and schedule overlapping `asyncAfter` blocks. §25 ("fast
repeated swipes", "interrupted page curl") is currently unmet.

**D3 — images are decoded synchronously on the main thread, inside `body`.**
`StoryViewerView.swift:148-168` calls `FileManagerService.shared.loadImage`
directly from a `@ViewBuilder`. `loadImage` (`FileManagerService.swift:64-81`)
does `Data(contentsOf:)` + `UIImage(data:)` with no cache and no downsampling —
a full-resolution decode to draw at 170×170 pt. This re-runs on *every* body
invalidation, which includes every page turn, because `saveProgress()` publishes
`StoryGenerationManager.stories` on each turn. Under a page curl, which
snapshots views mid-gesture, this is the single largest performance risk.

**D4 — progress is written from a stale value.** `StoryViewerView.swift:7` is
`let story: Story`, a value captured at presentation. So in `saveProgress()`
(`:251-255`) `story.lastReadPage` is always the value from when the reader
opened, and `max(previous, page)` only guards against regressing below the
*opening* page, not below the furthest page reached this session. Separately,
each turn re-encodes the entire `[Story]` array to `UserDefaults`
(`StoryGenerationManager.swift:883-895`) — the manager itself warns above 1 MB
at `:889`.

**D5 — a one-page story can never be completed.** `MPStoryExtras.swift:19-22`:

```swift
guard pages.count > 1, let last = lastReadPage else { return 0 }
```

A single-page story returns `0` forever, so `MPSheets.swift:91` offers it as
"Oku" permanently and §16's ending state would never be reached. §25 lists
"story with 1 page" explicitly.

### 1.4 What is not there at all

Verified by grep over all 243 `.swift` files:

- `UIPageViewController` — **0 hits**
- `UIViewRepresentable`, `PageTabViewStyle`, `.tabViewStyle`, `pageCurl` — **0 hits**
- `UIViewControllerRepresentable` — 2 hits, neither paging: `Helpers/ImagePicker.swift:8`, `Helpers/ShareSheet.swift:7`
- `NSCache` — **0 hits**
- paper texture / grain / noise / parchment — **0 hits** outside AI prompt strings in `AIService.swift`
- a haptics system — **see §3.1**
- Dynamic Type in the design system — **see §3.2**

---

## 2. Target architecture

```
ContentView / StoryCreationFlow
        ↓  presents
StoryReaderView                    SwiftUI · owns reader state, chrome, a11y metadata
        ↓
StoryReaderContainer               UIViewControllerRepresentable
        ↓
UIPageViewController(.pageCurl)    UIKit · owns the gesture and the turn
        ↓  dataSource / delegate
StoryPageHostController            UIHostingController<StoryPageView> · one per leaf
        ↓
StoryPageView                      SwiftUI · the typeset page
```

Ownership, stated once so it is not re-litigated per file:

| SwiftUI owns | UIKit owns |
|---|---|
| presentation and dismissal | the page-turn gesture |
| `StoryReaderModel` (current index, chrome visibility, completion) | `dataSource` before/after resolution |
| chrome overlay, ending leaf content | transition callbacks (`didFinishAnimating`) |
| accessibility metadata and reading order | nothing else |
| the `Story` → `ReaderStory` mapping | |

The container is a **thin bridge**. It does not decide what a page contains, does
not persist, does not animate anything itself. All state flows through
`StoryReaderModel`; the coordinator only translates UIKit callbacks into model
calls and reads the model for `viewControllerBefore/After`.

### 2.1 Why native page curl, and what it costs

§2 of the brief mandates it and it is correct: `UIPageViewController` with
`transitionStyle = .pageCurl` gives an interruptible, finger-tracking curl with
real lighting, and Apple maintains it. Five consequences must be designed for,
not discovered:

1. **Pages must be opaque, edge to edge.** The curl reveals the *back* of the
   leaf. A page with a transparent background curls to show whatever is behind
   the page controller, which reads as a bug. `StoryPageView` therefore paints
   the paper surface itself, full-bleed, ignoring safe areas. This is why §7's
   "do not treat the page as a rounded app card" is also a technical
   requirement, not only a taste one.

2. **`transitionStyle` is set at `init` and cannot change.** Switching to a
   simpler transition for Reduce Motion means **rebuilding the controller**. The
   representable is keyed on the effective style so SwiftUI recreates it.

3. **`UIPageViewController` installs its own tap recognizers.** They turn pages
   on tap. §10 needs tap to toggle chrome instead. The coordinator walks
   `pageViewController.gestureRecognizers` and disables every
   `UITapGestureRecognizer`, leaving the pan. The tap-to-toggle gesture then
   lives in SwiftUI on the overlay layer.

4. **VoiceOver does not curl.** With `.scroll` the three-finger scroll works for
   free; with `.pageCurl` it does not. The container view implements
   `accessibilityScroll(_:)` → `model.next()` / `model.previous()`, which works
   under either style and is what §18's "accessible page navigation" means.

5. **`setViewControllers` during an in-flight interactive transition is the
   classic `UIPageViewController` crash.** Guarded in §7.3.

### 2.2 Where the files go — this is decided by the project file

`MagicPaper.xcodeproj/project.pbxproj:6` is `objectVersion = 70` and the project
is **mixed**:

| Directory | Mechanism (`project.pbxproj`) | New file needs a pbxproj edit? |
|---|---|---|
| `MagicPaper/Screens/**` | `PBXFileSystemSynchronizedRootGroup` (`:106`) | **No** |
| `MagicPaper/DesignSystem/**` | synchronized (`:105`) | **No** |
| `MagicPaper/Helpers/**` | synchronized (`:107`) | **No** |
| `MagicPaper/StoryEngineBridge/**` | synchronized (`:104`) | **No** |
| `MagicPaperTests/**` | synchronized (`:108`) | **No** |
| `MagicPaper/Views/**` | explicit `PBXGroup` (`:207-225`) | **Yes** |
| `MagicPaper/Models/**` | explicit (`:227-236`) | **Yes** |
| `MagicPaper/Services/**` | explicit (`:238-259`) | **Yes** |

**Every new reader file goes in `MagicPaper/Screens/StoryReader/`.** The whole
feature then builds with zero `project.pbxproj` edits. The old reader lives in
`Views/` (explicit, listed four times) — retiring it is the one place the
project file is touched, and removing entries is far safer than adding them.

---

## 3. Two gaps in the brief's assumptions

### 3.1 §20 assumes a haptics system. There isn't one.

A full grep for `haptic|Haptic|ImpactFeedbackGenerator|NotificationFeedbackGenerator|sensoryFeedback`
over `MagicPaper/MagicPaper/` returns **five** hits, all raw and ad hoc:

- `Helpers/PremiumComponents.swift:199` — `UIImpactFeedbackGenerator(style: .medium)` inline in a button action
- `Views/HomeView_OLD_BACKUP.swift:365, 491, 503, 593` — same pattern, in a file **not in the Xcode target**

No `MPHaptics` type. No public API. No settings key (`MPSettingsStore` keys are
`mp_readAloud`, `mp_readSize`, `mp_childMode`, `mp_reminder`,
`mp_approveBeforeShow`, `mp_screenLimit`, `mp_approvedStoryIDs`,
`mp_settingsSeeded`). No gating of any kind. `MPPressStyle` produces no haptic.

**So §20's instruction — "use the existing system, do not call raw
`UIImpactFeedbackGenerator`" — cannot be followed as written.** The plan builds
the small system §20 presumes (§4, `MPHaptics.swift`) rather than adding a sixth
raw call site. This is in scope because the alternative is to violate §20 either
way.

### 3.2 §18 requires Dynamic Type. The design system cannot currently do it.

Every `MP.F` token is a fixed-size custom font — `MPTheme.swift:252-277`:

```swift
static func read(_ size: CGFloat) -> Font { .custom(body, size: size).weight(.semibold) }
```

`.custom(_:size:)`, never `.custom(_:size:relativeTo:)`. Grep for `relativeTo`
across the design system returns nothing. **No text in the app scales with the
system content size.** The reader's only sizing is the manual `MP.ReadSize` chip
control (17 / 19 / 22 / 26 pt, `MPTheme.swift:280-293`).

`Helpers/AccessibilityHelper.swift` does contain real Dynamic Type helpers, but
they are `.system(...)`-based, do not use MP tokens, and are used by nothing in
the current reader.

**Making the reader honour Dynamic Type is therefore a design-system change, not
a reader change.** Kept deliberately narrow — §4 adds one additive token,
`MP.F.readScaled(_:)`, used only by the reader. Every other screen is untouched.
Widening Dynamic Type across the app is a separate piece of work and this plan
does not start it.

---

## 4. Files

### 4.1 New — `MagicPaper/Screens/StoryReader/` (synchronized, no pbxproj edit)

| File | ~LOC | Responsibility |
|---|---|---|
| `ReaderStory.swift` | 90 | `ReaderStory` / `ReaderLeaf` display model + `init(from: Story)`. The §5 boundary. |
| `StoryReaderModel.swift` | 130 | All paging logic, UI-free, `@MainActor ObservableObject`. **This is what the unit tests drive.** |
| `StoryReaderView.swift` | 220 | SwiftUI shell: paper, container, chrome overlay, ending leaf, a11y, lifecycle. |
| `StoryReaderContainer.swift` | 200 | `UIViewControllerRepresentable` + `Coordinator`. |
| `StoryPageHostController.swift` | 70 | `UIHostingController<StoryPageView>` carrying its leaf index. |
| `StoryPageView.swift` | 180 | The typeset page: paper, spine, illustration, text, folio. |
| `StoryEndingLeaf.swift` | 90 | "Hikâyenin sonu" + two quiet actions. |
| `ReaderChrome.swift` | 130 | Close, title, `3 / 8`, settings entry, favourite, read-aloud. |
| `ReaderImageLoader.swift` | 120 | `actor` + `NSCache`, downsampling, off-main decode. Fixes D3. |
| `ReaderPaper.swift` | 90 | Paper surface, static grain, spine shading. Tokens only. |

### 4.2 New — `MagicPaper/DesignSystem/` (synchronized, no pbxproj edit)

| File | ~LOC | Responsibility |
|---|---|---|
| `MPHaptics.swift` | 70 | The system §20 assumes. `pageTurn()`, `light()`, `success()`, gated. |

### 4.3 New — `MagicPaperTests/` (synchronized, no pbxproj edit)

| File | ~LOC | Covers |
|---|---|---|
| `StoryReaderModelTests.swift` | 260 | §26 items 1–11, 18, 20 |
| `ReaderStoryMappingTests.swift` | 120 | §26 items 9–11, 20 |
| `ReaderProgressTests.swift` | 140 | §26 items 8, 14; D4, D5 |

### 4.4 Modified

| File | Change | pbxproj? |
|---|---|---|
| `DesignSystem/MPTheme.swift` | add `MP.F.readScaled(_:)`; add `MP.ReadTheme.paper` and `.spine` | No |
| `Screens/MPStoryExtras.swift` | fix `mpProgress` for 1-page stories (D5); add `isFinished` | No |
| `Screens/MPSettingsStore.swift` | add `haptics: Bool` (`mp_haptics`, default true) | No |
| `Screens/MPSheets.swift` | `ReaderSettingsSheet` gains the haptics row | No |
| `Screens/StoryCreation/StoryCreationFlow.swift` | add `.reading(Story)` phase for the §13 transition | No |
| `Screens/MPAppState.swift` | nothing structural; `readerStory` stays the route | No |
| `ContentView.swift` | present `StoryReaderView` instead of `StoryViewerView` | **Yes** (see below) |
| `Services/StoryGenerationManager.swift` | add `markCompleted(storyId:)`; keep `updateLastReadPage` | No (edit, not add) |
| `Views/StoryViewerView.swift` | **delete** | **Yes** — 4 references |

### 4.5 The one project-file edit

`Views/StoryViewerView.swift` appears four times in `project.pbxproj`: a
`PBXFileReference`, a `PBXBuildFile`, a child of the `Views` group (`:207-225`),
and a Sources entry (`:427`). Deleting the file means removing those four lines.

`Views/HomeView_OLD_BACKUP.swift:63` also constructs `StoryViewerView(story:)`,
but that file has **zero** pbxproj references and is not compiled, so it does not
block the deletion.

**Alternative if you would rather not touch the project file at all:** leave
`StoryViewerView.swift` on disk, empty its body, and have it wrap
`StoryReaderView`. It costs a dead 5-line file. I recommend the deletion —
removing pbxproj entries is mechanical and reversible, and a shim that exists
only to avoid a four-line edit will outlive its reason.

---

## 5. Data boundary and page model

### 5.1 `ReaderStory` — satisfying §5 without a second model

§5 says the reader must not know about Blueprint, ContentCatalog, StoryIntent,
compatibility rules or content IDs. The app's `Story` *nearly* qualifies — but
`Models/Story.swift:32` carries `origin: StoryOrigin?`, and `StoryOrigin`
(`:62-79`) is `blueprintID`, `settingID`, `companionID`, `discoveryID`,
`fingerprint`, `catalogVersion`. That is exactly the vocabulary §5 forbids,
sitting one property access away from the reader.

So the reader consumes a display model built at the presentation boundary:

```swift
struct ReaderStory {
    let id: UUID
    let title: String
    let childName: String
    let accent: Color
    let symbol: String
    let leaves: [ReaderLeaf]      // story pages + one ending leaf
    var pageCount: Int            // story pages only, for "3 / 8"
}

enum ReaderLeaf: Identifiable {
    case page(ReaderPage)
    case ending
}

struct ReaderPage {
    let index: Int                // 0-based, within story pages
    let title: String             // usually "" — offline engine authors none
    let text: String
    let imageRef: String?         // resolved from imageFileName / imageUrl
    let accessibilityDescription: String?
}
```

**This is not a second Story model and not a second persistence system.** It is a
projection built in `init(from: Story)`, held only while the reader is on
screen, never encoded, never stored. `Story` remains the single persisted type
and `StoryGenerationManager.stories` remains the single source of truth.

### 5.2 The page model, as it really is

`Models/Story.swift:130-151`:

```swift
struct StoryPage: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var text: String
    var imagePrompt: String
    var imageFileName: String?
    var imageUrl: String?
}
```

Six fields. §6 says invent nothing beyond them, and nothing is invented.

**`visualScene` already reaches the app, as `imagePrompt`.**
`StoryEngineBridge/OfflineStoryMapper.swift:50-62`:

```swift
MagicPaper.StoryPage(
    id: UUID(),
    title: "",                    // offline engine authors no per-page title
    text: page.text,
    imagePrompt: page.visualScene // authored visual intent, not a prompt yet
)
```

Three consequences the reader must respect:

- **`title` is empty for every offline story.** `StoryPageView` must never
  reserve vertical space for a heading that will not arrive. Render the title
  only when non-empty; the layout closes up when it is not.
- **Offline stories have `imageFileName == nil` and `imageUrl == nil`.** They are
  always text-only. The text-only page is the *common* case in the shipping
  flow, not the degraded one, and gets the better typography for it.
- **`imagePrompt` is English and is not an image description.** Sample values
  from `StoryEngine/Resources/blueprints/pilot_library_v1.json:767`: *"child
  pausing mid-step at the edge of the place, something faint further in"*. It
  reads like an alt text and **must not be used as one** — it would make
  VoiceOver read English stage directions into a Turkish story. `ReaderPage`
  therefore sets `accessibilityDescription = nil` when no image exists, and
  where an image does exist labels it in Turkish from the story's own terms
  (§9.3). Flagging this because using `imagePrompt` as the a11y label is the
  obvious-looking move and is wrong.

The illustrated path (`StoryEngineMapper.swift:39-52`) sets `imageFileName` and
`imageUrl` to the **same** locator string. `ReaderPage.imageRef` resolves
`imageFileName ?? imageUrl` — note the order is **reversed** from the current
reader (`StoryViewerView.swift:152` tries `imageUrl` first and hands it to a
*filename*-based loader, which silently yields `nil` for any genuine remote URL).

### 5.3 The ending leaf is a real leaf

§16 wants a quiet ending that does not dismiss. Rather than an overlay, the
ending is **the last leaf in the page controller** — index `pageCount`. You
reach it by turning the final page, which is what the closing leaf of a book is.

It gives three things for free: the gesture that ends the story is the same
gesture that told the story; completion becomes unambiguous (reaching the leaf
marks the story finished); and there is no "the reader dismissed itself while my
child was still looking at the picture".

An empty story (`pages.isEmpty`) yields a reader with exactly one leaf — the
ending. No crash, no blank page. §25's "invalid story data".

---

## 6. Visual design

### 6.1 Paper

The design system has no texture and, per `MPBridge.swift:185`, is explicit that
it does not want one:

> `/// Tüm ekranların zemini düz sıcak kağıt rengidir — gradyan yok, sistem rengi yok.`

Depth in this system is `mpEdge` — a hard 3–4 pt bottom edge, never a blur
(`MPTheme.swift:335-340, 376-386`). The reader honours that and adds exactly one
thing the rest of the app does not need: a **spine**.

| Element | Value | Token |
|---|---|---|
| Paper, light | `#FDF6EE` | `MP.Palette.kagit100` — the same colour `MPStoryPDF.swift:29` already prints on |
| Paper, sepia | `#F7EFDE` | existing `ReadTheme.sepia.background` |
| Paper, night | `#121D34` | `MP.Palette.gece700` |
| Ink | `#2B1D24` | `MP.C.textTitle` / `ReadTheme.foreground` |
| Body ink | `#4A3640` | `MP.C.textBody` / `ReadTheme.body` |
| Folio | `#6E5964` | `MP.C.textMuted` / `ReadTheme.muted` |
| Spine | `kagit300` @ 0.10 → clear, 14 pt from the leading edge | new `ReadTheme.spine` |

Note `MP.ReadTheme.light.background` is currently `kagit0` — **pure white**
(`MPTheme.swift:158`). White is not paper. Rather than change `background` and
alter `DailyStoryReaderView` (`DailyStoriesView.swift:147`) as a side effect, the
plan **adds** `MP.ReadTheme.paper` returning `kagit100 / #F7EFDE / gece700`. The
reader reads `.paper`; every existing consumer of `.background` is untouched.
Additive, no blast radius.

**Texture (§7 "if technically safe"):** one static, 64×64 tileable grain
generated once into a cached `UIImage` at first reader launch, drawn at **0.035**
opacity, never animated, dropped entirely when Reduce Transparency is on. It is
generated once per process, not per page and not per frame — §19's "avoid
constantly animated paper textures" is the reason it is static, and the page
curl snapshots views, so a moving texture would tear during a turn anyway.

If it does not survive the §12 product test on device, it is deleted. Flat warm
paper plus the spine plus the curl's own lighting is already most of the effect.

### 6.2 Page composition

Full-bleed, ignoring safe areas — required by the curl (§2.1) and wanted by §7.

```
┌─────────────────────────────┐
│ ░ spine, 14pt               │  ← leading edge only
│                             │
│      ILLUSTRATION           │  45–55% of usable height
│      (absent on text pages) │
│                             │
│   ─── 32pt gutter ───       │
│                             │
│   Yeliz, ağacın arkasından  │  30–40%
│   gelen küçük ışığı gördü.  │
│                             │
│   "Bu da ne?" diye          │
│   fısıldadı.                │
│                             │
│                             │
│            3 / 8            │  ← folio, only when chrome is visible
└─────────────────────────────┘
```

- **Outer gutter 32 pt** (`MP.S.x7`). `MPStoryPDF.swift:18-19` prints A5 at 40/420
  ≈ 9.5%; on a 393 pt iPhone that is ~37 pt. 32 is the nearest token and reads
  correctly at every size. The current reader's `.padding(.horizontal, 30)`
  (`StoryViewerView.swift:132`) is an untokened literal.
- **Text is leading-aligned, not centred.** `StoryViewerView.swift:126` centres
  it. Centred prose is a poster; a children's book sets ragged-right. This is
  §14's "typeset, not placed inside a UI text card".
- **Paragraph spacing.** Engine text arrives with `\n\n` between paragraphs and
  `lineSpacing` alone does not distinguish them. `StoryPageView` splits on blank
  lines and lays paragraphs in a `VStack(spacing: size * 0.55)`, so dialogue
  separates as a paragraph (§15) without bubbles or a second type style.
- **Ratios are a target, not a constraint.** The illustration is
  `height * 0.5`, clamped to `[0.34, 0.55]`, and yields to text first as
  Dynamic Type grows — §8 says these are design targets and §14 says never
  sacrifice readability.
- **Text-only pages get the better setting**, because they are the common case:
  no reserved image area, text optically centred in the upper-middle with more
  leading, capped at a **62-character measure** so a large iPhone does not print
  20-word lines.
- **No illustration frame.** The current 170×170 rounded rect
  (`StoryViewerView.swift:156-157`) is a thumbnail in a list. The illustration
  sits on the paper with the text, sharing its gutters, with `MP.R.sm` corners at
  most — §12's "illustration feels integrated with the typography".

### 6.3 Typography

| Element | Token |
|---|---|
| Story text | `MP.F.readScaled(app.readSize.points)` — new, `relativeTo: .body` |
| Line spacing | `app.readSize.lineSpacing` (= `points * 0.72`, line-height 1.72) |
| Page title, when non-empty | `MP.F.displaySM()` (Baloo 2, 21, bold) |
| Folio `3 / 8` | `MP.F.caption()` |
| Ending headline | `MP.F.displayMD()` + `mpTightTracking(26)` |

The new token, additive, next to the existing `MP.F.read`:

```swift
/// Masal metni, sistem yazı boyutuna duyarlı. Okuyucu bunu kullanır.
static func readScaled(_ size: CGFloat) -> Font {
    .custom(body, size: size, relativeTo: .body).weight(.semibold)
}
```

`MP.F.read` stays exactly as it is for every existing caller. The reader clamps
at `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` — the same ceiling
`AccessibilityHelper.swift` already assumes — so `MP.ReadSize.cokBuyuk` (26 pt)
at AX5 cannot produce three words per page.

### 6.4 Chrome (§9–§11)

Visible on open, auto-hides after **3 s**, single tap toggles. When hidden: paper
and story only.

**Visible:**

| Position | Element |
|---|---|
| Top leading | Close — `MPIconButton(symbol: "xmark", label: "Kapat")` |
| Top trailing | Favourite (`MPFavorites`), read-aloud (`MPSpeech`), reading settings (`ReaderSettingsSheet`) |
| Bottom centre | `3 / 8` — `MP.F.caption()`, `ReadTheme.muted` |

Removed from the current reader: the full-width progress bar
(`StoryViewerView.swift:106-121`) and the three 54 pt chevron buttons
(`:185-205`). §11 forbids a prominent page control and §9 forbids persistent
large buttons; the folio and the curl replace both.

Kept, because they are existing shipped product behaviour and §21 says not to
invent audio but not to remove it: favourites, `MPSpeech` read-aloud, and
`ReaderSettingsSheet` (theme / size / read-aloud, `MPSheets.swift:157-200`) —
all reachable only while chrome is visible.

Chrome fades with `MP.M.gated(MP.M.easeOut)`, so Reduce Motion gets an instant
swap for free. It never translates or scales — §12.

### 6.5 Cover → reader (§13)

Today the cover sets `app.readerStory` and dismisses its own `fullScreenCover`
(`StoryCreationFlow.swift:108-113`) while `ContentView.swift:49` presents a
second one. Two full-screen presentations cross-fading over each other cannot be
made to feel like a book opening, no matter what is animated inside them.

**Fix: the reader becomes a phase of the creation flow.** `Phase` gains
`case reading(Story)`; `onOpen` sets `phase = .reading(story)` instead of
touching `app.readerStory`. Cover and page 1 are then in one view tree and a
real transition is possible. Closing the reader from this path dismisses the
whole flow back to Home.

The library path is unchanged: `MPSheets.swift:97` → `app.readerStory` →
`ContentView.swift:49` presents `StoryReaderView` directly, with no cover. That
is correct — a book you already own opens at your page, it does not re-introduce
itself.

The transition, in full, over `MP.M.page` (0.52 s — **defined at
`MPTheme.swift:350` and currently used nowhere in the app**):

1. The paper plane is continuous. Cover and page 1 share the same surface via
   `matchedGeometryEffect`; the paper never fades, flashes or moves.
2. The cover's card contents (symbol, title, avatar line) fade out over 0.18 s.
3. Page 1's text rises 8 pt and fades in over 0.26 s, 0.10 s later.
4. Chrome appears last, at 0.42 s, then auto-hides on its own 3 s timer.

No zoom, no confetti, no flash. Under Reduce Motion the whole sequence collapses
to an instant swap because every step is gated. §13's "book opening" is carried
by continuity of the paper, which is the thing a real book does when it opens.

---

## 7. Page controller mechanics

### 7.1 Construction

```swift
UIPageViewController(
    transitionStyle: effectiveStyle,       // .pageCurl, or .scroll under Reduce Motion
    navigationOrientation: .horizontal,
    options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
)
```

- `isDoubleSided = false` — the reverse of a leaf is rendered automatically.
- `view.backgroundColor` = the resolved paper colour, so the gap behind a
  mid-curl leaf is paper and not black.
- `dataSource` and `delegate` = the `Coordinator`.
- In `makeUIViewController`, every `UITapGestureRecognizer` in
  `pageViewController.gestureRecognizers` is disabled (§2.1 item 3).
- `.id(effectiveStyle)` on the representable in SwiftUI, so a Reduce Motion
  change rebuilds rather than mutating an immutable property.

### 7.2 Data source

```swift
func pageViewController(_ pvc: UIPageViewController,
                        viewControllerBefore vc: UIViewController) -> UIViewController?
```

Both directions read the index off `StoryPageHostController.leafIndex` and
return `nil` at the bounds — which is how §25's "first page cannot go backward"
and "last page cannot go forward" are expressed to UIKit. No force unwraps: the
cast is `guard let host = vc as? StoryPageHostController else { return nil }`.

Hosts are built on demand in `host(at:)` and not retained beyond what
`UIPageViewController` itself keeps (current ± 1). §19: an 8-page story holds at
most three hosting controllers.

### 7.3 Turn completion, and the crash this prevents

```swift
func pageViewController(_ pvc: UIPageViewController,
                        didFinishAnimating finished: Bool,
                        previousViewControllers: [UIViewController],
                        transitionCompleted completed: Bool)
```

Only when `completed` is true does the model advance. An abandoned curl — the
child drags half a page and lets go — leaves the model where it was. This is the
callback that makes the haptic fire once, at the moment the page lands, and not
during the drag (§20).

A `isTransitioning` flag on the coordinator is set in
`willTransitionTo` and cleared in `didFinishAnimating`. Programmatic
`setViewControllers` is refused while it is set — calling it mid-interactive-
transition is the classic `UIPageViewController` crash, and §25 asks for exactly
this ("fast repeated swipes", "interrupted page curl", "reader dismissed during
transition"). The coordinator holds the model `weak` and drops any completion
that arrives after teardown.

### 7.4 Reduce Motion

`UIAccessibility.isReduceMotionEnabled` → `.scroll` instead of `.pageCurl`.
Navigation, boundaries, callbacks, folio and completion are identical; only the
visual changes. §18's "simpler page transition while preserving logical
navigation", met by construction rather than by a parallel code path.

Read via `@Environment(\.accessibilityReduceMotion)` in the view, **not**
`MP.M.reduceMotion` — the latter is a static `UIAccessibility` read
(`MPBridge.swift:199`) that does not invalidate the view when the setting
changes mid-session. `MP.M.gated(...)` remains correct for the chrome, where a
one-launch delay in picking up the change is harmless.

---

## 8. Persistence (§17)

**No new persistence layer.** `StoryGenerationManager` stays the single source of
truth and `UserDefaults["stories"]` stays the single store.

Three targeted changes:

**Write on settle, not on every frame.** The model accumulates
`furthestPageReached` in memory and calls `updateLastReadPage` on: a completed
turn (via `didFinishAnimating`, already debounced by the gesture), reader
dismissal, and `scenePhase` → `.background` (§25's "app backgrounding during a
page turn"). Today each turn re-encodes the whole `[Story]` array
(`StoryGenerationManager.swift:883-895`, which warns above 1 MB at `:889`); with
an interruptible curl that pressure only grows.

**Fix the stale read (D4).** The model owns `furthestPageReached`, seeded once
from `story.lastReadPage`. `StoryViewerView.swift:253` re-reads a captured value
that can never change, so progress currently regresses to the opening page if
you page backwards and leave.

**Fix completion (D5).** `MPStoryExtras.swift:19-22` returns `0` for any story
with `pages.count <= 1`. Replace with a form that treats a single-page story as
complete once its only page is read, and add:

```swift
var isFinished: Bool { mpProgress >= 1 }
```

so `MPSheets.swift:91` ("Okumaya devam et" vs "Oku"), `LibraryView.swift:55` and
`HomeView.swift:172` all agree on what finished means, and §31's "completed
stories remain completed" holds for a 1-page story.

Opening rule: `StoryReaderView` starts at `min(max(lastReadPage ?? 0, 0), pageCount - 1)`
— clamped, so corrupt or out-of-range stored data opens at a valid page instead
of crashing (§25's "invalid page indexes"). Reaching the ending leaf does **not**
advance `lastReadPage` past the last real page; the ending is a leaf, not
progress.

`MPStreak.markReadToday()` / `addReadingTime` and `MPFavorites` keep their
current call pattern (`StoryViewerView.swift:52-62`), moved into the new view's
lifecycle unchanged.

---

## 9. Accessibility (§18)

### 9.1 Reading order

Each leaf is an accessibility container; VoiceOver traverses:

```
illustration (only when one exists)
   → story text
   → folio "3 / 8"
   → chrome (close, favourite, read aloud, settings)
```

`StoryPageView` groups the paragraphs into **one** element with the full page
text, so VoiceOver reads the page as continuous prose rather than as four
fragments — §18's "continuous reading". `.accessibilityTextContentType(.narrative)`
marks it as prose, and the container carries
`.accessibilityLabel("Sayfa \(index + 1), \(pageCount) sayfanın")`.

### 9.2 Navigation without the gesture

The curl is a pan, and VoiceOver consumes pans. Two mechanisms:

- `accessibilityScroll(_:)` on the container view → `model.next()` /
  `model.previous()`, so the standard three-finger page gesture works under
  `.pageCurl`, which it otherwise would not (§2.1 item 4).
- `.accessibilityAction(named: "Sonraki sayfa")` and `"Önceki sayfa"` on the
  page, so the rotor offers them explicitly. These are the same two entry points
  the programmatic navigation tests drive, so §26 item 7 and §18 are covered by
  one code path.

`UIAccessibility.post(notification: .pageScrolled, argument: "3 / 8")` on each
completed turn announces position without stealing focus from the text.

### 9.3 Image labels

When a page has an image, its label is built in Turkish from the story's own
terms — `"\(story.title), sayfa \(n) çizimi"` — not from `imagePrompt`, which is
English authored stage direction (§5.2). When there is no image, no element and
no announcement: a text-only page has nothing visual to describe and inventing
one is noise.

### 9.4 Dynamic Type

Per §3.2 and §6.3: `MP.F.readScaled`, capped at `accessibility3`, illustration
yields height to text as sizes grow. The reader is the first screen in the app
that responds to the system text size at all.

---

## 10. Performance (§19)

| Risk | Mitigation |
|---|---|
| **D3 — sync decode in `body`** | `ReaderImageLoader`: `actor` + `NSCache<NSString, UIImage>`, `CGImageSourceCreateThumbnailAtIndex` downsampling to the target pixel size, `preparingForDisplay()`, decode off-main. `StoryPageView` shows the paper (not a spinner) until the image resolves. |
| Whole-array JSON per turn | Write on settle only (§8). |
| Host controller churn | Built on demand, only current ± 1 retained by `UIPageViewController`. |
| Body invalidation on every turn | `StoryPageView` takes a `ReaderPage` value, not the `Story` or the manager, so a `StoryGenerationManager` publish does not re-render pages. |
| Texture cost | 64×64 tile, generated once per process, cached, never animated, dropped under Reduce Transparency. |
| Text-only stories | Never touch the loader, never allocate an image view — the light path is the common path. |

Target: an 8-page text story holds three hosting controllers and zero images. An
illustrated 8-page story holds at most three decoded downsampled bitmaps.

---

## 11. Haptics (§20)

New `DesignSystem/MPHaptics.swift`, because §3.1 — there is nothing to reuse.

```swift
@MainActor
enum MPHaptics {
    static func pageTurn()   // .light impact, intensity 0.45
    static func light()
    static func success()
}
```

- Fires **once**, in `didFinishAnimating` when `transitionCompleted == true`
  (§7.3). Never during the drag, never per frame.
- Gated on a new `MPSettingsStore.haptics` (`mp_haptics`, default `true`),
  surfaced as a row in `ReaderSettingsSheet` next to the existing read-aloud
  toggle.
- Generators are `prepare()`d on reader appear and released on disappear.
- Not gated on Reduce Motion: a haptic is not motion, and suppressing it there
  would remove feedback from users who may rely on it. It is gated on the
  explicit user setting, which is the honest control.
- Migrating `PremiumComponents.swift:199` to `MPHaptics.light()` is a one-line
  cleanup, listed as optional.

---

## 12. Test plan (§26)

`MagicPaperTests/` is a synchronized group, XCTest, `@testable import MagicPaper`,
matching `StoryPersistenceTests.swift` and `OfflineStoryMappingTests.swift`.

**The design decision that makes this testable:** all paging logic lives in
`StoryReaderModel`, which has no SwiftUI and no UIKit. Items 1–8, 18 and 20 are
plain unit tests over a value type, not UI tests fighting an animation.

| # | §26 item | Where | How |
|---|---|---|---|
| 1 | opens first page | `StoryReaderModelTests` | fresh story → `currentIndex == 0` |
| 2 | page count matches | `StoryReaderModelTests` | `leaves.count == pages.count + 1` (ending) |
| 3 | next page | `StoryReaderModelTests` | `next()` → index 1 |
| 4 | previous page | `StoryReaderModelTests` | `next(); previous()` → 0 |
| 5 | first-page boundary | `StoryReaderModelTests` | `previous()` at 0 is a no-op, returns `false` |
| 6 | last-page boundary | `StoryReaderModelTests` | past the ending leaf is a no-op |
| 7 | programmatic navigation | `StoryReaderModelTests` | `go(to:)` valid, and clamps −1 / 99 |
| 8 | current page state | `ReaderProgressTests` | `furthestPageReached` monotonic across back-and-forth |
| 9 | text-only story | `ReaderStoryMappingTests` | all `imageRef == nil`, no a11y image element |
| 10 | illustrated story | `ReaderStoryMappingTests` | `imageRef` resolves `imageFileName` **before** `imageUrl` |
| 11 | missing optional image | `ReaderStoryMappingTests` | mixed story: some pages with, some without |
| 12 | cover → reader | `StoryReaderModelTests` | `.reading(story)` phase seeds index 0 |
| 13 | reader → library | manual / UI test | dismissal returns to the library tab |
| 14 | persisted story reopens | `ReaderProgressTests` | `lastReadPage = 4` → opens at 4; **1-page story completes** (D5) |
| 15 | Dynamic Type | manual on device | AX1 / AX3 / AX5 at all four `MP.ReadSize` values |
| 16 | VoiceOver semantics | `StoryReaderModelTests` + manual | a11y actions drive the same API; order verified on device |
| 17 | Reduce Motion | `StoryReaderModelTests` | `.scroll` selected; navigation identical under both styles |
| 18 | rapid navigation | `StoryReaderModelTests` | 50 alternating calls, no over/underflow, guard holds |
| 19 | dismissal during transition | manual + Instruments | coordinator's weak model, late callback dropped |
| 20 | invalid story data | `ReaderStoryMappingTests` | 0 pages → ending leaf only; `lastReadPage = 99` clamps; empty text renders |

Items 15, 19 and part of 13/16 are honest manual checks. Asserting a page-curl
frame or VoiceOver focus order in XCTest produces tests that pass while the
experience is broken; §28 says to judge this as a book, and on-device is where
that judgement is made.

### 12.1 The UI test (§27) — needs a new target

There is **no UI test target**. `project.pbxproj` has exactly two
`PBXNativeTarget`s: `MagicPaper` (`:291`) and `MagicPaperTests` (`:323`,
`product-type.bundle.unit-test`). No `product-type.bundle.ui-testing` anywhere,
no `MagicPaperUITests` directory.

So §27 requires **adding a target** — a larger `project.pbxproj` change than the
four-line deletion in §4.5, plus a `TestPlan.xctestplan` entry.

Scenario, once the target exists:

```
launch with -MPUITestSeedStory  (seeds a deterministic 8-page story, no generation)
open Library → tap the story → "Oku"
assert page 1
swipe → assert page 2
… swipe to page 8
swipe once more → assert the ending leaf ("Hikâyenin sonu")
tap "Kitaplığıma dön" → assert Library
reopen the same story
assert the reader opens and no generation ran (assert the seeded story id is unchanged)
```

The seed hook is a launch argument read at startup, not a test-only code path in
the reader — the reader stays identical under test and in production.

**Recommendation:** treat §27 as a second, separately-approved step. It is a
project-file change of a different order from everything else here, and the unit
suite plus a device pass covers the §31 criteria without it. Say the word and I
will fold it into step 5 instead.

---

## 13. Implementation order

| Step | Work | Verification |
|---|---|---|
| 1 | `ReaderStory`, `StoryReaderModel`, `MPHaptics`, `MP.F.readScaled`, `ReadTheme.paper/.spine`, `mpProgress` fix | Unit tests green; app still builds on the old reader |
| 2 | `StoryReaderContainer` + `StoryPageHostController` + a placeholder page | Curl turns, follows the finger, boundaries hold, no crash on rapid swipes |
| 3 | `StoryPageView`, `ReaderPaper`, `ReaderImageLoader` | Text-only and illustrated pages; Instruments shows no main-thread decode |
| 4 | `ReaderChrome`, `StoryEndingLeaf`, tap-to-toggle, persistence wiring | Progress survives a relaunch; ending is calm; folio correct |
| 5 | Swap `ContentView.swift:49`; `.reading` phase in `StoryCreationFlow`; delete `StoryViewerView.swift` + 4 pbxproj lines | All three entry points reach the new reader; library and home intact |
| 6 | Accessibility pass: VoiceOver, Dynamic Type, Reduce Motion on device | §18 in full |
| 7 | §28 product test on device | The judgement that actually decides whether this is done |

Steps 1–4 leave the app shipping the old reader, so none of them can break the
product mid-flight. Step 5 is the switch.

Per §30, one agent implements — the reader files are too coupled for parallel
edits — and a separate accessibility/QA pass follows at step 6.

---

## 14. Risks

| Risk | Likelihood | Response |
|---|---|---|
| `UIHostingController` inside `.pageCurl` renders a transparent or clipped back face | Medium | Opaque full-bleed paper on every host's `view.backgroundColor`; verified at step 2 before any real page content exists |
| Disabling the built-in tap recognizers also breaks the pan | Low | Filter on `UITapGestureRecognizer` only; fallback is a SwiftUI tap on a transparent overlay above the container |
| Safe-area handling fights the curl at the notch and home indicator | Medium | Page ignores safe areas; text and folio inset by safe area **inside** the page |
| Static grain reads as dirt on an OLED display | Medium | Ship it behind one constant; delete at step 7 if the device test does not justify it |
| Large `UserDefaults["stories"]` blob makes even settle-time writes visible | Low | Already warned at `StoryGenerationManager.swift:889`; if it shows, that is a separate persistence change, not a reader one |
| `UIPageViewController` state restoration on backgrounding mid-curl | Low | `scenePhase` → save; the reader reopens at the saved page rather than mid-transition |
| No UI test target (§27) | Certain | §12.1 — decide whether to add one |

---

## 15. Definition of done (§31), mapped

| Criterion | Met by |
|---|---|
| native page curl | §7.1 |
| turns follow the finger | `UIPageViewController` interactive pan, §7 |
| pages feel like real book pages | §6.1, §6.2 — full bleed, paper, spine, no card |
| premium visual hierarchy | §6.2, §6.3 |
| highly readable text | §6.3 — 1.72 leading, 62-char measure, leading-aligned |
| controls disappear | §6.4 — 3 s auto-hide, tap toggles |
| cover → page 1 | §6.5 — `.reading` phase, continuous paper |
| text-only **and** illustrated | §5.2 — one architecture, illustration optional |
| independent of engine internals | §5.1 — `ReaderStory`, no `StoryOrigin` reaches the reader |
| VoiceOver | §9 |
| Dynamic Type | §3.2, §6.3 |
| Reduce Motion | §7.4 |
| no crashes on rapid paging | §7.3 |
| persistence works | §8 |
| Library / Home / navigation intact | §4.4 — only `ContentView.swift:49` changes |
| design system respected | tokens throughout; two additive tokens, one new system §3.1 |

---

## 16. Open questions

1. **§27's UI test target** — add it in this work, or approve it separately?
   (§12.1. My recommendation: separately.)
2. **Paper texture** — ship the static grain, or flat paper plus spine plus the
   curl's own lighting? (§6.1. I lean flat, and would add grain only if the
   device test says the page looks thin.)
3. **Retiring the old reader** — delete `Views/StoryViewerView.swift` with four
   pbxproj lines, or leave a shim? (§4.5. My recommendation: delete.)
4. **`DailyStoryReaderView`** (`DailyStoriesView.swift:137-231`) reads a
   `DailyStory` with a flat `content: String` and no pages. Out of scope here —
   but it will now look markedly older than the story reader. Worth a follow-up.
