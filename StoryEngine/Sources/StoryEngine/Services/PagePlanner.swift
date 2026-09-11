import Foundation
import VisualSystem

/// Builds page skeletons: which beat, which scene, which layout, how many
/// words. No prose, no AI, no randomness.
///
/// Layout is a deterministic function of the page's position and beat role,
/// resolved through the design system's rules. Two identical requests produce
/// byte-identical page structures, which is what lets a resumed job pick up
/// without re-planning.
public struct PagePlanner: Sendable {
    private let idGenerator: IDGenerator

    public init(idGenerator: IDGenerator = RandomIDGenerator()) {
        self.idGenerator = idGenerator
    }

    public func planPages(
        outline: StoryOutline,
        template: ResolvedTemplate,
        sceneIDByBeatID: [UUID: UUID]
    ) throws -> [StoryPage] {
        let beats = outline.beats.sorted { $0.ordinal < $1.ordinal }
        let pageCount = beats.count

        return try beats.enumerated().map { index, beat in
            let context = LayoutContext(
                pageIndex: index,
                pageCount: pageCount,
                beatRole: beat.role.rawValue
            )
            guard let rule = template.visualStyle.layoutRule(for: context) else {
                throw StoryEngineError.visual(
                    .noLayoutRuleMatches(pageIndex: index, beatRole: beat.role.rawValue)
                )
            }
            guard let sceneID = sceneIDByBeatID[beat.id] else {
                throw StoryEngineError.sceneNotFound(beat.id)
            }

            // A beat may ask for a particular shot; otherwise the layout rule decides.
            let compositionRuleID = beat.compositionRuleID ?? rule.compositionRuleID

            return StoryPage(
                id: idGenerator.next(),
                index: index,
                outlineBeatID: beat.id,
                templateBeatID: beat.templateBeatID,
                beatRole: beat.role,
                sceneID: sceneID,
                layout: rule.layout,
                layoutRuleID: rule.id,
                compositionRuleID: compositionRuleID,
                typographyPresetID: rule.typographyPresetID,
                minimumWords: rule.textWordBudget.lowerBound,
                maximumWords: rule.textWordBudget.upperBound,
                title: beat.summary.isEmpty ? "" : Self.deriveTitle(from: beat)
            )
        }
    }

    /// Page titles come from the outline, not from a second model call.
    private static func deriveTitle(from beat: OutlineBeat) -> String {
        let firstSentence = TextMetrics.sentences(beat.summary).first ?? beat.summary
        let words = TextMetrics.words(firstSentence)
        guard words.count > 6 else { return firstSentence }
        return words.prefix(6).joined(separator: " ")
    }
}
