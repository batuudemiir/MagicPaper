// MPTypography.swift
// İki aile: Baloo 2 başlıkta, Nunito geri kalan her yerde (`docs/MARKA.md`). Fontlar
// `DesignSystem/Fonts` içinde, Info.plist `UIAppFonts` listesinde. Baloo 2 dosyası
// satır kutusu düzeltilmiş Latin kopyasıdır (`Tools/make_baloo_latin.py`).
// Boyutlar `relativeTo:` ile Dynamic Type'la büyür.

import SwiftUI

enum MPTextStyle: CaseIterable {
    case display, largeTitle, title1, title2, title3, navTitle, headline, cardTitle
    /// Günlük (FAZ 20): sola yaslı sayfa başlığı 34 ve illüstrasyon üstü masal adı 38.
    case pageTitle, heroTitle
    case button, body, bodyStrong, callout, footnote, caption, eyebrow, tabLabel, story, storyLarge

    /// Sekiz rol: kapak, sayfa, bölüm, kart, gövde, ikincil, dipnot, düğme.
    /// Eski adlar rollerine iner; dokunulan ekranda rol adına taşınır (Faz 2).
    var size: CGFloat {
        switch self {
        case .heroTitle, .pageTitle, .display: 34
        case .largeTitle, .title1, .title2: 28
        case .title3, .navTitle, .headline: 21
        case .cardTitle, .bodyStrong, .button, .body: 17
        case .callout: 15
        case .footnote, .caption, .eyebrow: 13
        case .tabLabel: 12
        case .story: 19
        case .storyLarge: 26
        }
    }

    var weight: Font.Weight {
        switch self {
        case .heroTitle, .pageTitle, .display, .largeTitle, .title1, .title2: .bold
        case .title3, .navTitle, .headline: .semibold
        case .cardTitle, .bodyStrong, .button, .tabLabel, .storyLarge: .bold
        case .body, .callout: .regular
        case .footnote, .caption, .eyebrow, .story: .semibold
        }
    }

    /// Başlık rolleri Baloo 2, geri kalanı Nunito.
    var family: String {
        switch self {
        case .heroTitle, .pageTitle, .display, .largeTitle, .title1, .title2, .title3, .navTitle, .headline: "Baloo 2"
        default: "Nunito"
        }
    }

    /// Multiplier of the font size (CSS line-height). Converted to SwiftUI lineSpacing in `mpText`.
    var lineHeight: CGFloat {
        switch self {
        case .body, .bodyStrong, .footnote: 1.4
        case .callout, .caption: 1.35
        case .story, .storyLarge: 1.7
        case .cardTitle: 1.25
        case .button, .tabLabel: 1.0
        default: 1.2
        }
    }

    var tracking: CGFloat {
        self == .eyebrow ? size * 0.06 : 0
    }
    var isUppercase: Bool { self == .eyebrow }

    var relativeTo: Font.TextStyle {
        switch self {
        // Büyük yazıda küçük stiller daha çok büyür: bölüm başlığı `.headline`'a bağlı
        // olsa en büyük boyutta sayfa başlığını geçerdi.
        case .display, .pageTitle, .heroTitle: .largeTitle
        case .largeTitle, .title1, .title2: .title
        case .title3, .navTitle, .headline: .title2
        case .cardTitle: .headline
        case .button, .body, .bodyStrong: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption, .eyebrow, .tabLabel: .caption
        case .story, .storyLarge: .body
        }
    }

    var font: Font { .custom(family, size: size, relativeTo: relativeTo).weight(weight) }
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
