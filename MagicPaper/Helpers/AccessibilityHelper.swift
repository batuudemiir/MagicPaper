import SwiftUI

/// Helper for Dynamic Type and accessibility features
struct AccessibilityHelper {
    
    // MARK: - Dynamic Type Sizes
    
    /// Returns scaled font size based on user's accessibility settings
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return .system(size: size, weight: weight, design: design)
    }
    
    /// Returns scaled font with maximum size limit
    static func scaledFont(size: CGFloat, maxSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = min(size, maxSize)
        return .system(size: scaledSize, weight: weight)
    }
    
    // MARK: - Text Styles (Dynamic Type Compatible)
    
    /// Large title for hero sections
    static var largeTitle: Font {
        .system(.largeTitle, design: .default, weight: .bold)
    }
    
    /// Title for section headers
    static var title: Font {
        .system(.title, design: .default, weight: .bold)
    }
    
    /// Title 2 for subsections
    static var title2: Font {
        .system(.title2, design: .default, weight: .bold)
    }
    
    /// Title 3 for card headers
    static var title3: Font {
        .system(.title3, design: .default, weight: .semibold)
    }
    
    /// Headline for important text
    static var headline: Font {
        .system(.headline, design: .default)
    }
    
    /// Subheadline for secondary text
    static var subheadline: Font {
        .system(.subheadline, design: .default)
    }
    
    /// Body text for main content
    static var body: Font {
        .system(.body, design: .default)
    }
    
    /// Callout for emphasized body text
    static var callout: Font {
        .system(.callout, design: .default)
    }
    
    /// Footnote for supplementary text
    static var footnote: Font {
        .system(.footnote, design: .default)
    }
    
    /// Caption for labels and small text
    static var caption: Font {
        .system(.caption, design: .default)
    }
    
    /// Caption 2 for very small text
    static var caption2: Font {
        .system(.caption2, design: .default)
    }
    
    // MARK: - Story Reading Styles
    
    /// Story title in viewer
    static var storyTitle: Font {
        .system(.title, design: .rounded, weight: .bold)
    }
    
    /// Story body text in viewer
    static var storyBody: Font {
        .system(.body, design: .rounded)
    }
    
    /// Story page title
    static var storyPageTitle: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }
    
    // MARK: - Button Styles
    
    /// Primary button text
    static var buttonPrimary: Font {
        .system(.body, design: .default, weight: .semibold)
    }
    
    /// Secondary button text
    static var buttonSecondary: Font {
        .system(.callout, design: .default, weight: .medium)
    }
    
    // MARK: - Accessibility Helpers
    
    /// Check if user has enabled larger text sizes
    static var isAccessibilitySize: Bool {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        return contentSize.isAccessibilityCategory
    }
    
    /// Get current content size category
    static var contentSizeCategory: ContentSizeCategory {
        let uiCategory = UIApplication.shared.preferredContentSizeCategory
        return ContentSizeCategory(uiCategory) ?? .large
    }
    
    /// Returns appropriate line spacing for current text size
    static func lineSpacing(for font: Font) -> CGFloat {
        if isAccessibilitySize {
            return 8
        } else {
            return 4
        }
    }
    
    /// Returns appropriate padding for current text size
    static func dynamicPadding(base: CGFloat) -> CGFloat {
        if isAccessibilitySize {
            return base * 1.5
        } else {
            return base
        }
    }
    
    // MARK: - VoiceOver Support
    
    /// Creates accessibility label for story card
    static func storyCardLabel(title: String, childName: String, theme: String, pageCount: Int) -> String {
        return "\(title). Hikaye kahramanı: \(childName). Tema: \(theme). \(pageCount) sayfa."
    }
    
    /// Creates accessibility hint for interactive elements
    static func actionHint(_ action: String) -> String {
        return "\(action) için çift dokunun"
    }
    
    /// Creates accessibility value for progress indicators
    static func progressValue(current: Int, total: Int) -> String {
        return "\(current) / \(total)"
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Applies dynamic type scaling to the view
    func dynamicTypeSize(_ range: DynamicTypeSize...) -> some View {
        self.dynamicTypeSize(range.isEmpty ? .large ... .accessibility3 : range[0] ... range[1])
    }
    
    /// Adds accessibility label and hint
    func accessible(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Makes view accessible as a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self.accessible(label: label, hint: hint, traits: .isButton)
    }
    
    /// Makes view accessible as a header
    func accessibleHeader(label: String) -> some View {
        self.accessible(label: label, traits: .isHeader)
    }
    
    /// Combines multiple accessibility elements
    func accessibilityElement(label: String, value: String? = nil, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Text Style Modifiers

extension Text {
    /// Applies story title style with dynamic type
    func storyTitleStyle() -> some View {
        self
            .font(AccessibilityHelper.storyTitle)
            .lineSpacing(AccessibilityHelper.lineSpacing(for: AccessibilityHelper.storyTitle))
    }
    
    /// Applies story body style with dynamic type
    func storyBodyStyle() -> some View {
        self
            .font(AccessibilityHelper.storyBody)
            .lineSpacing(AccessibilityHelper.lineSpacing(for: AccessibilityHelper.storyBody))
    }
    
    /// Applies primary button style with dynamic type
    func primaryButtonStyle() -> some View {
        self
            .font(AccessibilityHelper.buttonPrimary)
    }
    
    /// Applies secondary button style with dynamic type
    func secondaryButtonStyle() -> some View {
        self
            .font(AccessibilityHelper.buttonSecondary)
    }
}
