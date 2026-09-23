import SwiftUI

// MARK: - Cover Color Tokens

/// The 9 colors of the MagicPaper generative cover palette.
///
/// These are artwork colors, not UI colors. They live here instead of
/// `MP.Palette` to avoid coupling the generative cover system to global
/// UI theming. Each color is warm, muted, and paper-inspired.
enum MagicPaperCoverColor: String, Codable, CaseIterable {
    case paperCream
    case warmIvory
    case dustyBlue
    case mutedSage
    case softOchre
    case warmBrown
    case palePeach
    case mutedTerracotta
    case softLavender

    /// The resolved SwiftUI color.
    var color: Color {
        switch self {
        case .paperCream:       return Color(hex: 0xF5EEE3)
        case .warmIvory:        return Color(hex: 0xF8F3E8)
        case .dustyBlue:        return Color(hex: 0x9EAFB5)
        case .mutedSage:        return Color(hex: 0xA9B49F)
        case .softOchre:        return Color(hex: 0xD3B274)
        case .warmBrown:        return Color(hex: 0x8D7560)
        case .palePeach:        return Color(hex: 0xE5BDAA)
        case .mutedTerracotta:  return Color(hex: 0xB9826D)
        case .softLavender:     return Color(hex: 0xB5A9BC)
        }
    }

    /// Colors eligible as cover background — only paper tones.
    static var backgroundColors: [MagicPaperCoverColor] {
        [.paperCream, .warmIvory]
    }

    /// Whether this color is light enough to serve as a background.
    var isBackgroundEligible: Bool {
        Self.backgroundColors.contains(self)
    }
}

// MARK: - Curated Palette Identifiers

/// Each curated palette guarantees visual harmony.
///
/// Arbitrary color combinations are never used. Every cover draws from
/// one of these palettes, ensuring the library always looks cohesive.
enum CoverPaletteID: String, Codable, CaseIterable {
    case quietMorning   // paperCream + dustyBlue, mutedSage + softOchre
    case warmGarden     // warmIvory + mutedSage, palePeach + warmBrown
    case storybookSky   // paperCream + dustyBlue, softLavender + softOchre
    case autumnPaper    // warmIvory + softOchre, mutedTerracotta + mutedSage
    case softEvening    // warmIvory + dustyBlue, softLavender + warmBrown
    case peachGarden    // palePeach bg + mutedSage, warmIvory + warmBrown
}

// MARK: - Curated Palette

/// A resolved palette with background, primary tiles, and optional accent.
///
/// Every palette guarantees 3–5 distinct colors. The background is always
/// a paper tone; primaries and accent provide the visual character.
struct CoverPalette {
    let id: CoverPaletteID
    let background: MagicPaperCoverColor
    let primary: [MagicPaperCoverColor]
    let accent: MagicPaperCoverColor?

    /// All unique colors used by this palette.
    var allColors: [MagicPaperCoverColor] {
        var colors: [MagicPaperCoverColor] = [background] + primary
        if let accent { colors.append(accent) }
        return colors
    }

    /// The colors available for tiles (excludes background).
    var tileColors: [MagicPaperCoverColor] {
        var colors = primary
        if let accent { colors.append(accent) }
        return colors
    }

    /// Number of distinct colors.
    var colorCount: Int { allColors.count }

    // MARK: - Factory

    static func palette(for id: CoverPaletteID) -> CoverPalette {
        switch id {
        case .quietMorning:
            return CoverPalette(
                id: .quietMorning,
                background: .paperCream,
                primary: [.dustyBlue, .mutedSage],
                accent: .softOchre
            )
        case .warmGarden:
            return CoverPalette(
                id: .warmGarden,
                background: .warmIvory,
                primary: [.mutedSage, .palePeach],
                accent: .warmBrown
            )
        case .storybookSky:
            return CoverPalette(
                id: .storybookSky,
                background: .paperCream,
                primary: [.dustyBlue, .softLavender],
                accent: .softOchre
            )
        case .autumnPaper:
            return CoverPalette(
                id: .autumnPaper,
                background: .warmIvory,
                primary: [.softOchre, .mutedTerracotta],
                accent: .mutedSage
            )
        case .softEvening:
            return CoverPalette(
                id: .softEvening,
                background: .warmIvory,
                primary: [.dustyBlue, .softLavender],
                accent: .warmBrown
            )
        case .peachGarden:
            return CoverPalette(
                id: .peachGarden,
                background: .palePeach,
                primary: [.mutedSage, .warmIvory],
                accent: .warmBrown
            )
        }
    }
}
