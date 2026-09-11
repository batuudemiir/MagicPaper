import Foundation
import VisualSystem

/// A page of the book.
///
/// Layout, composition and word budget are decided deterministically by
/// `PagePlanner` before any prose exists; text arrives later from the
/// segmenter, and the illustration is referenced, not owned — several pages may
/// point at the same `VisualAsset`.
public struct StoryPage: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let index: Int
    public let outlineBeatID: UUID
    public let templateBeatID: String
    public let beatRole: BeatRole
    public let sceneID: UUID
    /// The illustration this page shows. Shared with sibling pages when they
    /// sit in the same scene and want the same shot.
    public var visualAssetID: UUID?

    public let layout: PageLayout
    public let layoutRuleID: String
    public let compositionRuleID: String
    public let typographyPresetID: String
    public let minimumWords: Int
    public let maximumWords: Int

    public var title: String
    public var text: String
    public var textRevision: Int

    public init(
        id: UUID,
        index: Int,
        outlineBeatID: UUID,
        templateBeatID: String,
        beatRole: BeatRole,
        sceneID: UUID,
        visualAssetID: UUID? = nil,
        layout: PageLayout,
        layoutRuleID: String,
        compositionRuleID: String,
        typographyPresetID: String,
        minimumWords: Int,
        maximumWords: Int,
        title: String = "",
        text: String = "",
        textRevision: Int = 0
    ) {
        self.id = id
        self.index = index
        self.outlineBeatID = outlineBeatID
        self.templateBeatID = templateBeatID
        self.beatRole = beatRole
        self.sceneID = sceneID
        self.visualAssetID = visualAssetID
        self.layout = layout
        self.layoutRuleID = layoutRuleID
        self.compositionRuleID = compositionRuleID
        self.typographyPresetID = typographyPresetID
        self.minimumWords = minimumWords
        self.maximumWords = maximumWords
        self.title = title
        self.text = text
        self.textRevision = textRevision
    }

    public var wordBudget: ClosedRange<Int> { minimumWords...maximumWords }
    public var wordCount: Int { TextMetrics.wordCount(text) }
    public var requiresImage: Bool { layout.requiresImage }
    public var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
