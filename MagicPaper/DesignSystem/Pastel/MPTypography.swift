// MPTypography.swift
// İki aile: Baloo 2 başlıkta, Nunito geri kalan her yerde (`docs/MARKA.md`). Fontlar
// `DesignSystem/Fonts` içinde, Info.plist `UIAppFonts` listesinde. Baloo 2 dosyası
// satır kutusu düzeltilmiş Latin kopyasıdır (`Tools/make_baloo_latin.py`).
// Boyutlar `relativeTo:` ile Dynamic Type'la büyür.

import SwiftUI

enum MPTextStyle: CaseIterable {
    /// Sekiz rol (`docs/MARKA.md`) ve dipnotun büyük harfli çeşidi `eyebrow`.
    case cover, page, section, cardTitle, body, supporting, footnote, eyebrow, button

    var size: CGFloat {
        switch self {
        case .cover: 34
        case .page: 28
        case .section: 21
        case .cardTitle, .body, .button: 17
        case .supporting: 15
        case .footnote, .eyebrow: 13
        }
    }

    var weight: Font.Weight {
        switch self {
        case .cover, .page, .cardTitle, .button: .bold
        case .section, .footnote, .eyebrow: .semibold
        case .body, .supporting: .regular
        }
    }

    /// Başlık rolleri Baloo 2, geri kalanı Nunito.
    var family: String {
        switch self {
        case .cover, .page, .section: "Baloo 2"
        default: "Nunito"
        }
    }

    /// Multiplier of the font size (CSS line-height). Converted to SwiftUI lineSpacing in `mpText`.
    var lineHeight: CGFloat {
        switch self {
        case .body, .footnote: 1.4
        case .supporting: 1.35
        case .cardTitle: 1.25
        case .button: 1.0
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
        case .cover: .largeTitle
        case .page: .title
        case .section: .title2
        case .cardTitle: .headline
        case .button, .body: .body
        case .supporting: .callout
        case .footnote, .eyebrow: .footnote
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
