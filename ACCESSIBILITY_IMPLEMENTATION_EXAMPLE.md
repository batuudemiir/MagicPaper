# Accessibility Implementation Examples

## Quick Reference for Using Dynamic Type in MagicPaper

### Basic Text with Dynamic Type

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack(spacing: 16) {
            // ✅ GOOD: Uses Dynamic Type
            Text("Story Title")
                .font(.title)
            
            Text("Story description goes here...")
                .font(.body)
            
            // ✅ BETTER: Uses AccessibilityHelper
            Text("Story Title")
                .font(AccessibilityHelper.title)
            
            Text("Story description goes here...")
                .font(AccessibilityHelper.body)
                .lineSpacing(AccessibilityHelper.lineSpacing(for: AccessibilityHelper.body))
        }
    }
}
```

### Story Viewer with Accessibility

```swift
struct StoryPageView: View {
    let page: StoryPage
    let childName: String
    
    var body: some View {
        VStack(spacing: AccessibilityHelper.dynamicPadding(base: 20)) {
            // Story title with Dynamic Type
            Text(page.title)
                .font(AccessibilityHelper.storyPageTitle)
                .accessibilityAddTraits(.isHeader)
            
            // Story body with name highlighting
            Text(highlightName(in: page.text, name: childName))
                .font(AccessibilityHelper.storyBody)
                .lineSpacing(AccessibilityHelper.lineSpacing(for: AccessibilityHelper.storyBody))
                .multilineTextAlignment(.center)
        }
        .padding(AccessibilityHelper.dynamicPadding(base: 20))
    }
    
    private func highlightName(in text: String, name: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = attributedString.range(of: name, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .orange
            attributedString[range].font = AccessibilityHelper.isAccessibilitySize ? 
                .system(size: 26, weight: .bold) : 
                .system(size: 19, weight: .bold)
        }
        
        return attributedString
    }
}
```

### Buttons with Accessibility

```swift
struct CreateStoryButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Create Story")
                    .font(AccessibilityHelper.buttonPrimary)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AccessibilityHelper.dynamicPadding(base: 16))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple)
            )
        }
        .accessibilityLabel("Create new story")
        .accessibilityHint("Double tap to start creating a personalized story")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Story Card with VoiceOver

```swift
struct StoryCard: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover image
            if let coverImage = story.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: DeviceHelper.isIPad ? 180 : 120)
                    .clipped()
                    .accessibilityLabel("Story cover image for \(story.title)")
            }
            
            // Title
            Text(story.title)
                .font(AccessibilityHelper.title3)
                .lineLimit(2)
            
            // Metadata
            HStack {
                Text(story.theme.emoji)
                Text(story.theme.displayName)
                    .font(AccessibilityHelper.caption)
                    .foregroundColor(.secondary)
            }
            
            // Page count
            Text("\(story.pages.count) pages")
                .font(AccessibilityHelper.caption2)
                .foregroundColor(.secondary)
        }
        .padding(AccessibilityHelper.dynamicPadding(base: 12))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        // Combine all info for VoiceOver
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityHelper.storyCardLabel(
            title: story.title,
            childName: story.childName,
            theme: story.theme.displayName,
            pageCount: story.pages.count
        ))
        .accessibilityHint("Double tap to read this story")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Adaptive Layout for Accessibility Sizes

```swift
struct SubscriptionCard: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(spacing: AccessibilityHelper.dynamicPadding(base: 16)) {
            if AccessibilityHelper.isAccessibilitySize {
                // Simplified layout for large text
                VStack(alignment: .leading, spacing: 12) {
                    statusIcon
                    statusText
                    actionButton
                }
            } else {
                // Standard layout
                HStack(spacing: 12) {
                    statusIcon
                    statusText
                    Spacer()
                    actionButton
                }
            }
        }
        .padding(AccessibilityHelper.dynamicPadding(base: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 56, height: 56)
            
            Text(subscriptionManager.isPremium ? "👑" : "✨")
                .font(.system(size: 28))
        }
        .accessibilityHidden(true) // Decorative
    }
    
    private var statusText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subscriptionManager.isPremium ? "Premium Member" : "Free Plan")
                .font(AccessibilityHelper.subheadline)
                .fontWeight(.bold)
            
            Text(subscriptionManager.isPremium ? 
                 "\(subscriptionManager.remainingImageStories) stories remaining" : 
                 "Upgrade for unlimited stories")
                .font(AccessibilityHelper.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var actionButton: some View {
        Button(action: {}) {
            Text(subscriptionManager.isPremium ? "Manage" : "Upgrade")
                .font(AccessibilityHelper.buttonSecondary)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.purple)
                )
        }
        .accessibilityLabel(subscriptionManager.isPremium ? 
                           "Manage subscription" : 
                           "Upgrade to premium")
    }
}
```

### Settings with Dynamic Type

```swift
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
                
                // Title
                Text(title)
                    .font(AccessibilityHelper.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Value
                if let value = value {
                    Text(value)
                        .font(AccessibilityHelper.callout)
                        .foregroundColor(.secondary)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AccessibilityHelper.dynamicPadding(base: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(value != nil ? "\(title), \(value!)" : title)
        .accessibilityHint("Double tap to change")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Progress Indicator with Accessibility

```swift
struct StoryProgress: View {
    let currentPage: Int
    let totalPages: Int
    let theme: StoryTheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Visual progress bar
            ProgressView(value: Double(currentPage), total: Double(totalPages))
                .progressViewStyle(LinearProgressViewStyle(tint: theme.color))
                .scaleEffect(y: DeviceHelper.isIPad ? 1.5 : 1.0)
            
            // Text indicator
            Text("Page \(currentPage) of \(totalPages)")
                .font(AccessibilityHelper.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Story progress")
        .accessibilityValue(AccessibilityHelper.progressValue(
            current: currentPage,
            total: totalPages
        ))
    }
}
```

### Conditional Animation with Reduce Motion

```swift
struct AnimatedButton: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            Text("Create Story")
                .font(AccessibilityHelper.buttonPrimary)
                .foregroundColor(.white)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            if reduceMotion {
                // No animation
                isPressed = pressing
            } else {
                // Animated
                withAnimation(.spring(response: 0.3)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}
```

## Testing Your Implementation

### Test with Maximum Text Size

1. Open Settings app
2. Go to Accessibility → Display & Text Size → Larger Text
3. Enable "Larger Accessibility Sizes"
4. Drag slider to maximum (AX5)
5. Open MagicPaper
6. Verify:
   - All text is readable
   - No text is truncated
   - Buttons are tappable
   - Layouts don't overlap

### Test with VoiceOver

1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate through your view
3. Verify:
   - All elements have descriptive labels
   - Hints explain what will happen
   - Values are announced correctly
   - Navigation is logical

### Test with Reduce Motion

1. Enable Reduce Motion (Settings → Accessibility → Motion → Reduce Motion)
2. Navigate through your view
3. Verify:
   - Animations are simplified or removed
   - Transitions are instant or crossfade
   - No motion sickness triggers

## Common Mistakes to Avoid

### ❌ Fixed Font Sizes
```swift
// Bad
Text("Title").font(.system(size: 24))
```

### ✅ Dynamic Type
```swift
// Good
Text("Title").font(.title)
// or
Text("Title").font(AccessibilityHelper.title)
```

### ❌ Fixed Heights for Text
```swift
// Bad
Text("Story text...").frame(height: 100)
```

### ✅ Flexible Heights
```swift
// Good
Text("Story text...")
    .fixedSize(horizontal: false, vertical: true)
```

### ❌ Missing Accessibility Labels
```swift
// Bad
Image(systemName: "star")
```

### ✅ Descriptive Labels
```swift
// Good
Image(systemName: "star")
    .accessibilityLabel("Favorite")
```

### ❌ Ignoring Reduce Motion
```swift
// Bad
withAnimation(.spring()) {
    // always animates
}
```

### ✅ Respecting Reduce Motion
```swift
// Good
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? .none : .spring()) {
    // conditional animation
}
```

## Resources

- **AccessibilityHelper.swift**: `/MagicPaper/Helpers/AccessibilityHelper.swift`
- **DeviceHelper.swift**: `/MagicPaper/Helpers/DeviceHelper.swift`
- **Full Guide**: `ACCESSIBILITY_GUIDE.md`
- **Apple Docs**: [Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

---

**Remember**: Accessibility is not optional. It makes your app usable by everyone, including users with disabilities, older users, and users in challenging environments.
