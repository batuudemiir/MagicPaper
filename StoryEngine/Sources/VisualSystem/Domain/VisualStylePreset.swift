import Foundation
import EngineFoundation

/// The top of the design-system chain: one named look, pointing at the
/// illustration style, palette, type and layouts that make it up.
///
/// A story template names this and nothing else, so changing what
/// "magic_paper_v1" means is a data edit in one place.
public struct VisualStylePreset: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let displayName: String
    public let illustrationStyleID: String
    public let palettePresetID: String
    public let typographyPresetID: String
    public let defaultCompositionRuleID: String
    public let compositionRuleIDs: [String]
    public let layoutRuleIDs: [String]
    /// Applied on top of the illustration style's own forbidden clauses.
    public let globalNegativeClauses: [String]

    public init(
        id: String,
        version: SemanticVersion,
        displayName: String,
        illustrationStyleID: String,
        palettePresetID: String,
        typographyPresetID: String,
        defaultCompositionRuleID: String,
        compositionRuleIDs: [String],
        layoutRuleIDs: [String],
        globalNegativeClauses: [String] = []
    ) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.illustrationStyleID = illustrationStyleID
        self.palettePresetID = palettePresetID
        self.typographyPresetID = typographyPresetID
        self.defaultCompositionRuleID = defaultCompositionRuleID
        self.compositionRuleIDs = compositionRuleIDs
        self.layoutRuleIDs = layoutRuleIDs
        self.globalNegativeClauses = globalNegativeClauses
    }
}

/// A style preset with every reference followed. Pinned into a story so the
/// exact look it was generated with can always be reconstructed.
public struct ResolvedVisualStyle: Codable, Sendable, Hashable {
    public let preset: VisualStylePreset
    public let illustrationStyle: IllustrationStyle
    public let palette: PalettePreset
    public let typography: TypographyPreset
    public let compositionRules: [ImageCompositionRule]
    public let layoutRules: [PageLayoutRule]

    public init(
        preset: VisualStylePreset,
        illustrationStyle: IllustrationStyle,
        palette: PalettePreset,
        typography: TypographyPreset,
        compositionRules: [ImageCompositionRule],
        layoutRules: [PageLayoutRule]
    ) {
        self.preset = preset
        self.illustrationStyle = illustrationStyle
        self.palette = palette
        self.typography = typography
        self.compositionRules = compositionRules
        self.layoutRules = layoutRules
    }

    public func compositionRule(id: String) -> ImageCompositionRule? {
        compositionRules.first { $0.id == id }
    }

    public var defaultCompositionRule: ImageCompositionRule? {
        compositionRule(id: preset.defaultCompositionRuleID)
    }

    /// The rule governing a page, most specific first. Ties break on the order
    /// the preset lists them, so the data file stays the tie-breaker.
    public func layoutRule(for context: LayoutContext) -> PageLayoutRule? {
        layoutRules
            .enumerated()
            .filter { $0.element.appliesTo.matches(context) }
            .max { lhs, rhs in
                let left = (lhs.element.appliesTo.specificity, -lhs.offset)
                let right = (rhs.element.appliesTo.specificity, -rhs.offset)
                return left < right
            }?
            .element
    }

    /// Every version in the chain, for pinning and for fingerprints.
    public var versionPins: [String] {
        [
            "preset:\(preset.id)@\(preset.version)",
            "illustration:\(illustrationStyle.id)@\(illustrationStyle.version)",
            "palette:\(palette.id)@\(palette.version)",
            "typography:\(typography.id)@\(typography.version)"
        ]
    }
}
