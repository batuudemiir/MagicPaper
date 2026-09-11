import Foundation

/// How this character should be rendered — the character's half of the visual
/// contract. Points at VisualSystem presets by id rather than carrying style
/// prose, so the design system stays the single source of truth.
public struct CharacterStyleProfile: Codable, Sendable, Hashable {
    public let illustrationStyleID: String
    public let palettePresetID: String
    public let renderingNotes: [String]
    public let negativeTraits: [String]

    public init(illustrationStyleID: String, palettePresetID: String, renderingNotes: [String] = [], negativeTraits: [String] = []) {
        self.illustrationStyleID = illustrationStyleID
        self.palettePresetID = palettePresetID
        self.renderingNotes = renderingNotes
        self.negativeTraits = negativeTraits
    }
}
