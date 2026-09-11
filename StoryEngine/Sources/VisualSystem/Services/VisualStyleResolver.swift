import Foundation
import EngineFoundation

/// Follows a style preset's references and hands back the whole chain.
///
/// Resolution is strict: a dangling id is an error naming the id, never a
/// silent substitution. Getting a different look than the template asked for
/// is worse than failing loudly.
public struct VisualStyleResolver: Sendable {
    private let catalog: VisualCatalog

    public init(catalog: VisualCatalog = .builtIn) {
        self.catalog = catalog
    }

    public func stylePreset(id: String, requirement: VersionRequirement = .latest) throws -> VisualStylePreset {
        let candidates = catalog.stylePresets
            .filter { $0.id == id && requirement.isSatisfied(by: $0.version) }
            .sorted { $0.version < $1.version }
        guard let best = candidates.last else { throw VisualSystemError.stylePresetNotFound(id) }
        return best
    }

    public func resolve(styleID: String, requirement: VersionRequirement = .latest) throws -> ResolvedVisualStyle {
        let preset = try stylePreset(id: styleID, requirement: requirement)

        guard let illustration = newest(catalog.illustrationStyles, id: preset.illustrationStyleID) else {
            throw VisualSystemError.illustrationStyleNotFound(preset.illustrationStyleID)
        }
        guard let palette = newest(catalog.palettes, id: preset.palettePresetID) else {
            throw VisualSystemError.paletteNotFound(preset.palettePresetID)
        }
        guard let typography = newest(catalog.typographyPresets, id: preset.typographyPresetID) else {
            throw VisualSystemError.typographyNotFound(preset.typographyPresetID)
        }

        var compositionRules: [ImageCompositionRule] = []
        for id in preset.compositionRuleIDs {
            guard let rule = newest(catalog.compositionRules, id: id) else {
                throw VisualSystemError.compositionRuleNotFound(id)
            }
            compositionRules.append(rule)
        }
        guard compositionRules.contains(where: { $0.id == preset.defaultCompositionRuleID }) else {
            throw VisualSystemError.compositionRuleNotFound(preset.defaultCompositionRuleID)
        }

        var layoutRules: [PageLayoutRule] = []
        for id in preset.layoutRuleIDs {
            guard let rule = newest(catalog.layoutRules, id: id) else {
                throw VisualSystemError.layoutRuleNotFound(id)
            }
            layoutRules.append(rule)
        }

        return ResolvedVisualStyle(
            preset: preset,
            illustrationStyle: illustration,
            palette: palette,
            typography: typography,
            compositionRules: compositionRules,
            layoutRules: layoutRules
        )
    }

    private func newest<T: Identifiable>(_ items: [T], id: String) -> T? where T.ID == String {
        items.filter { $0.id == id }.max { lhs, rhs in
            version(of: lhs) < version(of: rhs)
        }
    }

    private func version<T>(of item: T) -> SemanticVersion {
        switch item {
        case let value as IllustrationStyle: return value.version
        case let value as PalettePreset: return value.version
        case let value as TypographyPreset: return value.version
        case let value as ImageCompositionRule: return value.version
        case let value as PageLayoutRule: return value.version
        case let value as VisualStylePreset: return value.version
        default: return SemanticVersion(0)
        }
    }
}
