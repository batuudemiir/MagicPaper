// MPTypography.swift
// Nunito is the only family. Add assets/fonts/Nunito-Variable.ttf and Nunito-Italic-Variable.ttf
// to the app target and list them under "Fonts provided by application" (UIAppFonts) in Info.plist.
// Sizes scale with Dynamic Type through `relativeTo:`.

import SwiftUI

enum MPTextStyle: CaseIterable {
    case display, largeTitle, title1, title2, title3, navTitle, headline, cardTitle
    /// Günlük (FAZ 20): sola yaslı sayfa başlığı 34 ve illüstrasyon üstü masal adı 38.
    case pageTitle, heroTitle
    case button, body, bodyStrong, callout, footnote, caption, eyebrow, tabLabel, story, storyLarge

    var size: CGFloat {
        switch self {
        case .heroTitle: 38
        case .pageTitle: 34
        case .display: 30
        case .largeTitle: 28
        case .title1: 26
        case .title2: 24
        case .title3: 22
        case .navTitle: 21
        case .headline: 19
        case .cardTitle: 17
        case .button: 16
        case .body, .bodyStrong: 15
        case .callout: 14
        case .footnote: 13
        case .caption, .eyebrow, .tabLabel: 12
        case .story: 19
        case .storyLarge: 26
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .largeTitle, .title1, .title2, .title3, .headline, .cardTitle, .eyebrow, .pageTitle, .heroTitle: .black
        case .navTitle, .button, .bodyStrong, .callout, .caption: .heavy
        case .footnote, .tabLabel, .storyLarge: .bold
        case .body, .story: .semibold
        }
    }

    /// Multiplier of the font size (CSS line-height). Converted to SwiftUI lineSpacing in `mpText`.
    var lineHeight: CGFloat {
        switch self {
        case .pageTitle, .heroTitle: 1.05
        case .display, .largeTitle, .title1, .title2: 1.15
        case .title3, .navTitle, .eyebrow: 1.2
        case .headline, .cardTitle: 1.25
        case .button, .tabLabel: 1.0
        case .body: 1.5
        case .bodyStrong, .footnote: 1.4
        case .callout, .caption: 1.35
        case .story, .storyLarge: 1.7
        }
    }

    var tracking: CGFloat {
        switch self {
        case .eyebrow: size * 0.06
        case .pageTitle, .heroTitle: size * -0.02
        default: 0
        }
    }
    var isUppercase: Bool { self == .eyebrow }

    var relativeTo: Font.TextStyle {
        switch self {
        case .display, .largeTitle, .pageTitle, .heroTitle: .largeTitle
        case .title1, .title2: .title
        case .title3, .navTitle: .title2
        case .headline, .cardTitle: .headline
        case .button, .body, .bodyStrong: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption, .eyebrow, .tabLabel: .caption
        case .story, .storyLarge: .body
        }
    }

    var font: Font { .custom("Nunito", size: size, relativeTo: relativeTo).weight(weight) }
}

extension Font {
    static func mp(_ style: MPTextStyle) -> Font { style.font }
    /// Ebeveyn kapısının çarpma sorusu (40 pt, ölçekli).
    static let mpNumeral = Font.custom("Nunito", size: 40, relativeTo: .largeTitle).weight(.black)
    /// Haftanın seçkisi sıra numarası (128 pt, süs; `accessibilityHidden`).
    static let mpRankNumeral = Font.custom("Nunito", size: 128, relativeTo: .largeTitle).weight(.black)
    /// Harf madalyonu: daireye göre ölçeklenir.
    static func mpInitial(size: CGFloat) -> Font { .custom("Nunito", size: size, relativeTo: .body).weight(.black) }
}

private struct MPTextModifier: ViewModifier {
    let style: MPTextStyle
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(max(0, style.size * (style.lineHeight - 1.2)))
            .textCase(style.isUppercase ? .uppercase : nil)
            // Türkçe büyük harf: "yeni" → "YENİ", "sesli" → "SESLİ".
            .environment(\.locale, Locale(identifier: "tr_TR"))
    }
}

extension View {
    /// Applies a MagicPaper text style: `Text("Masal bitti!").mpText(.display)`.
    func mpText(_ style: MPTextStyle) -> some View { modifier(MPTextModifier(style: style)) }
}
