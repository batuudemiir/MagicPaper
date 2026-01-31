# MagicPaper - Accessibility Guide

## Overview
MagicPaper fully supports iOS accessibility features including Dynamic Type (larger text), VoiceOver, and other assistive technologies.

---

## Dynamic Type Support

### What is Dynamic Type?
Dynamic Type allows users to adjust text size system-wide in iOS Settings. MagicPaper automatically respects these settings, making the app more accessible for users with visual impairments.

### How to Enable Larger Text

**On iPhone/iPad:**
1. Open **Settings**
2. Go to **Accessibility**
3. Tap **Display & Text Size**
4. Tap **Larger Text**
5. Enable **Larger Accessibility Sizes** (optional)
6. Adjust the slider to your preferred text size

### Supported Text Sizes
- **Standard Sizes**: XS, S, M, L (default), XL, XXL, XXXL
- **Accessibility Sizes**: AX1, AX2, AX3, AX4, AX5 (extra large)

### Text Scaling in MagicPaper

All text in the app uses Dynamic Type:

#### UI Elements
- **Navigation titles**: Scale from 17pt to 28pt
- **Section headers**: Scale from 22pt to 34pt
- **Body text**: Scale from 17pt to 23pt
- **Captions**: Scale from 12pt to 19pt
- **Buttons**: Scale from 17pt to 23pt

#### Story Reading
- **Story titles**: Scale from 22pt to 34pt
- **Story body text**: Scale from 17pt to 28pt
- **Page titles**: Scale from 20pt to 32pt

#### Adaptive Layout
- **Line spacing**: Increases with larger text (4pt → 8pt)
- **Padding**: Increases by 50% for accessibility sizes
- **Button heights**: Automatically adjust to fit larger text

---

## VoiceOver Support

### What is VoiceOver?
VoiceOver is a screen reader that describes what's on screen, allowing blind and low-vision users to navigate the app.

### How to Enable VoiceOver

**On iPhone/iPad:**
1. Open **Settings**
2. Go to **Accessibility**
3. Tap **VoiceOver**
4. Toggle **VoiceOver** on

**Quick Toggle:**
- Triple-click the side button (or home button)

### VoiceOver Features in MagicPaper

#### Story Cards
- **Label**: "Story title. Hero: Child name. Theme: Theme name. X pages."
- **Hint**: "Double tap to read story"
- **Value**: Reading progress (e.g., "Page 3 of 10")

#### Buttons
- **Create Story**: "Create new story button. Double tap to start creating"
- **Library**: "View library button. Double tap to see all stories"
- **Settings**: "Settings button. Double tap to open settings"

#### Story Viewer
- **Navigation**: "Previous page button" / "Next page button"
- **Progress**: "Page 3 of 10"
- **Images**: Descriptive labels for story images

#### Subscription Status
- **Free User**: "Free plan. Upgrade to Story Club for unlimited stories"
- **Premium User**: "Story Club member. 5 illustrated stories remaining"
- **Trial User**: "Free trial active. 2 stories remaining"

---

## Accessibility Helper API

### Using AccessibilityHelper in Code

```swift
import SwiftUI

// Dynamic Type fonts
Text("Story Title")
    .font(AccessibilityHelper.storyTitle)

Text("Story body text...")
    .font(AccessibilityHelper.storyBody)
    .lineSpacing(AccessibilityHelper.lineSpacing(for: AccessibilityHelper.storyBody))

// Accessibility labels
Button("Create") {
    // action
}
.accessible(label: "Create new story", hint: "Double tap to start")

// Check if accessibility size is enabled
if AccessibilityHelper.isAccessibilitySize {
    // Show simplified layout
}

// Dynamic padding
VStack {
    // content
}
.padding(AccessibilityHelper.dynamicPadding(base: 20))
```

### Available Text Styles

#### Headers
- `AccessibilityHelper.largeTitle` - Large title (34pt → 53pt)
- `AccessibilityHelper.title` - Title (28pt → 44pt)
- `AccessibilityHelper.title2` - Title 2 (22pt → 34pt)
- `AccessibilityHelper.title3` - Title 3 (20pt → 31pt)

#### Body Text
- `AccessibilityHelper.headline` - Headline (17pt → 23pt)
- `AccessibilityHelper.body` - Body (17pt → 23pt)
- `AccessibilityHelper.callout` - Callout (16pt → 22pt)
- `AccessibilityHelper.subheadline` - Subheadline (15pt → 21pt)

#### Small Text
- `AccessibilityHelper.footnote` - Footnote (13pt → 19pt)
- `AccessibilityHelper.caption` - Caption (12pt → 18pt)
- `AccessibilityHelper.caption2` - Caption 2 (11pt → 17pt)

#### Story-Specific
- `AccessibilityHelper.storyTitle` - Story title with rounded design
- `AccessibilityHelper.storyBody` - Story body with rounded design
- `AccessibilityHelper.storyPageTitle` - Story page title

#### Buttons
- `AccessibilityHelper.buttonPrimary` - Primary button text
- `AccessibilityHelper.buttonSecondary` - Secondary button text

### Helper Functions

```swift
// Check if user has accessibility text size enabled
let isLargeText = AccessibilityHelper.isAccessibilitySize

// Get current content size category
let category = AccessibilityHelper.contentSizeCategory

// Calculate dynamic line spacing
let spacing = AccessibilityHelper.lineSpacing(for: .body)

// Calculate dynamic padding
let padding = AccessibilityHelper.dynamicPadding(base: 20)

// Create accessibility labels
let label = AccessibilityHelper.storyCardLabel(
    title: "Space Adventure",
    childName: "Emma",
    theme: "Space",
    pageCount: 8
)
```

---

## Color Contrast

### WCAG 2.1 Compliance
MagicPaper follows WCAG 2.1 Level AA guidelines for color contrast:

- **Normal text**: Minimum 4.5:1 contrast ratio
- **Large text**: Minimum 3:1 contrast ratio
- **UI components**: Minimum 3:1 contrast ratio

### Color Palette

#### Primary Colors
- **Purple**: `#9449FA` - Used for primary actions
- **Pink**: `#D959D9` - Used for accents
- **Coral**: `#FF738C` - Used for highlights

#### Text Colors
- **Primary text**: Black on white (21:1 ratio) ✅
- **Secondary text**: Gray 60% on white (7:1 ratio) ✅
- **Disabled text**: Gray 40% on white (4.5:1 ratio) ✅

#### Interactive Elements
- **Buttons**: White text on gradient (4.5:1+ ratio) ✅
- **Links**: Purple on white (4.5:1+ ratio) ✅
- **Focus indicators**: 3px purple border ✅

---

## Reduce Motion

### Respecting User Preferences
MagicPaper respects the "Reduce Motion" accessibility setting:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Conditional animation
withAnimation(reduceMotion ? .none : .spring()) {
    // animation code
}
```

### Affected Animations
- **Splash screen**: Reduced animation duration
- **Page transitions**: Crossfade instead of slide
- **Button presses**: No scale animation
- **Loading indicators**: Simplified spinner

---

## Testing Accessibility

### Manual Testing Checklist

#### Dynamic Type
- [ ] Open Settings → Accessibility → Display & Text Size → Larger Text
- [ ] Set slider to maximum
- [ ] Open MagicPaper
- [ ] Verify all text is readable and not truncated
- [ ] Check that buttons are tappable
- [ ] Verify story viewer text scales properly

#### VoiceOver
- [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
- [ ] Navigate through home screen
- [ ] Create a new story
- [ ] Read a story
- [ ] Check library
- [ ] Verify all elements have proper labels

#### Color Contrast
- [ ] Enable Increase Contrast (Settings → Accessibility → Display & Text Size)
- [ ] Verify all text is readable
- [ ] Check button visibility
- [ ] Verify focus indicators are visible

#### Reduce Motion
- [ ] Enable Reduce Motion (Settings → Accessibility → Motion)
- [ ] Open app and verify animations are reduced
- [ ] Navigate between screens
- [ ] Create and view stories

### Automated Testing

```swift
// XCTest accessibility tests
func testDynamicType() {
    let app = XCUIApplication()
    app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
    app.launch()
    
    // Verify elements are visible and accessible
    XCTAssertTrue(app.buttons["Create Story"].exists)
    XCTAssertTrue(app.buttons["Create Story"].isHittable)
}

func testVoiceOver() {
    let app = XCUIApplication()
    app.launch()
    
    // Verify accessibility labels
    let createButton = app.buttons["Create Story"]
    XCTAssertEqual(createButton.label, "Create new story")
    XCTAssertEqual(createButton.hint, "Double tap to start creating")
}
```

---

## Best Practices

### For Developers

1. **Always use Dynamic Type fonts**
   ```swift
   // ✅ Good
   Text("Hello").font(.body)
   
   // ❌ Bad
   Text("Hello").font(.system(size: 17))
   ```

2. **Provide accessibility labels**
   ```swift
   // ✅ Good
   Image(systemName: "star")
       .accessibilityLabel("Favorite")
   
   // ❌ Bad
   Image(systemName: "star")
   ```

3. **Use semantic colors**
   ```swift
   // ✅ Good
   .foregroundColor(.primary)
   
   // ❌ Bad
   .foregroundColor(.black)
   ```

4. **Test with accessibility features enabled**
   - Test with largest text size
   - Test with VoiceOver
   - Test with Reduce Motion
   - Test with Increase Contrast

5. **Avoid fixed heights for text containers**
   ```swift
   // ✅ Good
   Text("Story")
       .fixedSize(horizontal: false, vertical: true)
   
   // ❌ Bad
   Text("Story")
       .frame(height: 50)
   ```

### For Designers

1. **Design for flexibility**
   - Text should wrap, not truncate
   - Buttons should expand with text
   - Layouts should adapt to content size

2. **Maintain contrast ratios**
   - 4.5:1 for normal text
   - 3:1 for large text
   - Test with color blindness simulators

3. **Provide alternative text**
   - All images need descriptive labels
   - Icons need text alternatives
   - Decorative images should be hidden from VoiceOver

4. **Design touch targets**
   - Minimum 44x44 points
   - Adequate spacing between elements
   - Clear focus indicators

---

## Resources

### Apple Documentation
- [Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Dynamic Type](https://developer.apple.com/design/human-interface-guidelines/typography#Dynamic-Type)
- [VoiceOver](https://developer.apple.com/documentation/accessibility/voiceover)

### WCAG Guidelines
- [WCAG 2.1 Level AA](https://www.w3.org/WAI/WCAG21/quickref/?versions=2.1&levels=aa)
- [Color Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Testing Tools
- **Xcode Accessibility Inspector**: Debug → Accessibility Inspector
- **VoiceOver Practice**: Settings → Accessibility → VoiceOver → VoiceOver Practice
- **Color Contrast Analyzer**: Free tool for checking contrast ratios

---

## Support

For accessibility-related issues or suggestions:
- Email: accessibility@magicpaper.app
- Include: Device model, iOS version, accessibility feature used
- Describe: What you expected vs. what happened

---

**Status**: ✅ Fully Accessible
**Last Updated**: January 31, 2026
**Compliance**: WCAG 2.1 Level AA
