import Foundation
import EngineFoundation

/// Everything the design system ships, as data.
public struct VisualCatalog: Codable, Sendable, Hashable {
    public let stylePresets: [VisualStylePreset]
    public let illustrationStyles: [IllustrationStyle]
    public let palettes: [PalettePreset]
    public let typographyPresets: [TypographyPreset]
    public let compositionRules: [ImageCompositionRule]
    public let layoutRules: [PageLayoutRule]

    public init(
        stylePresets: [VisualStylePreset] = [],
        illustrationStyles: [IllustrationStyle] = [],
        palettes: [PalettePreset] = [],
        typographyPresets: [TypographyPreset] = [],
        compositionRules: [ImageCompositionRule] = [],
        layoutRules: [PageLayoutRule] = []
    ) {
        self.stylePresets = stylePresets
        self.illustrationStyles = illustrationStyles
        self.palettes = palettes
        self.typographyPresets = typographyPresets
        self.compositionRules = compositionRules
        self.layoutRules = layoutRules
    }

    public func merging(_ other: VisualCatalog) -> VisualCatalog {
        VisualCatalog(
            stylePresets: stylePresets + other.stylePresets,
            illustrationStyles: illustrationStyles + other.illustrationStyles,
            palettes: palettes + other.palettes,
            typographyPresets: typographyPresets + other.typographyPresets,
            compositionRules: compositionRules + other.compositionRules,
            layoutRules: layoutRules + other.layoutRules
        )
    }
}

extension VisualCatalog {
    /// The catalog bundled with the package. Empty rather than fatal if the
    /// resource is missing, so a packaging mistake surfaces as a resolver
    /// error naming the id, not a crash at launch.
    public static let builtIn: VisualCatalog = {
        guard
            let url = Bundle.module.url(forResource: "visual_catalog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(VisualCatalog.self, from: data)
        else { return VisualCatalog() }
        return catalog
    }()
}
