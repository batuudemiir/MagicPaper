import Foundation
import VisualSystem

/// Binds the finished parts into a book, and owns the transition to published.
///
/// Publication lives here and only here: one place decides that a story is
/// finished, and it refuses unless validation actually passed. `Story.applying`
/// enforces the same rule a second time, so a caller cannot publish by
/// constructing the mutation themselves.
public struct BookAssembler: Sendable {
    private let visualPlanner: VisualPlanner
    private let scenePlanner: ScenePlanner
    private let clock: Clock

    public init(
        visualPlanner: VisualPlanner = VisualPlanner(),
        scenePlanner: ScenePlanner = ScenePlanner(),
        clock: Clock = SystemClock()
    ) {
        self.visualPlanner = visualPlanner
        self.scenePlanner = scenePlanner
        self.clock = clock
    }

    /// Final wiring: link pages into scenes, point pages at their illustration,
    /// and settle the story's status.
    public func assemble(story: Story, template: ResolvedTemplate) throws -> Story {
        let policy = template.template.sceneRules.visualPolicy
        let linkedScenes = scenePlanner.linking(pages: story.pages, to: story.scenes)
        let assignedPages = visualPlanner.assigning(pages: story.pages, to: linkedScenes, policy: policy)

        let everyImageReady = assignedPages
            .filter(\.requiresImage)
            .allSatisfy { page in
                guard let assetID = page.visualAssetID else { return false }
                return linkedScenes.compactMap { $0.asset(id: assetID) }.first?.isReady == true
            }

        return try story.applying(
            [
                .setScenes(linkedScenes),
                .setPages(assignedPages),
                .setStatus(everyImageReady ? .validating : .illustrating)
            ],
            at: clock.now()
        )
    }

    /// Freezes the book. Fails unless validation has run and passed.
    public func publish(story: Story) throws -> Story {
        guard let validation = story.validation else {
            throw StoryEngineError.validationFailed(["not_validated"])
        }
        guard validation.isValid else {
            throw StoryEngineError.validationFailed(validation.errors.map(\.code))
        }
        return try story.applying(
            StoryMutation(.publish(at: clock.now()), origin: .generation),
            at: clock.now()
        )
    }
}
