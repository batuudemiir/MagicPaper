import Foundation
import StoryEngine

/// Turns what the offline engine composed into the story the app already reads.
///
/// Separate from `StoryEngineMapper`, which maps the *illustrated* pipeline's
/// `StoryEngine.Story`. These are different types with different lifetimes — one
/// is a job that progresses through planning, writing and illustrating, the
/// other is text that is finished the moment it exists — and collapsing them
/// into one mapper would mean inventing states that the offline path never has.
enum OfflineStoryMapper {

    /// Maps a composed story onto the app model.
    ///
    /// The result is `.completed` on arrival. There is no waiting state for an
    /// offline story: composition is synchronous and takes milliseconds, which
    /// is why the flow shows a short narrative transition rather than a spinner.
    static func appStory(
        from composed: ComposedStory,
        childName: String,
        childProfileID: UUID,
        storyIdeaID: String?,
        catalogVersion: String,
        mode: StoryMode? = nil,
        selectionStrategy: StorySelectionStrategy? = nil,
        ageBand: AgeBand? = nil,
        subOption: String? = nil
    ) -> MagicPaper.Story {
        var story = MagicPaper.Story(
            title: composed.title,
            childName: childName,
            childProfileID: childProfileID,
            theme: theme(for: composed.content.setting),
            language: .turkish,
            status: .completed,
            pages: composed.pages
                .sorted { $0.pageNumber < $1.pageNumber }
                .map(appPage(from:)),
            origin: StoryOrigin(
                seed: composed.seed,
                storyIdeaID: storyIdeaID,
                blueprintID: composed.blueprintID.rawValue,
                settingID: composed.content.setting.id.rawValue,
                companionID: composed.content.companion.id.rawValue,
                discoveryID: composed.content.discovery.id.rawValue,
                fingerprint: composed.fingerprint,
                catalogVersion: catalogVersion,
                worldID: MP.World.from(
                    settingTags: composed.content.setting.tags.map(\.rawValue))?.rawValue,
                modeID: mode?.rawValue,
                selectionStrategy: selectionStrategy?.rawValue,
                ageBand: ageBand?.description,
                subOptionID: subOption
            )
        )
        story.currentProgress = nil
        return story
    }

    static func appPage(from page: ComposedPage) -> MagicPaper.StoryPage {
        MagicPaper.StoryPage(
            id: UUID(),
            // The app model wants a per-page title; the offline engine does not
            // author one, and inventing a heading per page would put text on the
            // page that no author wrote. Empty, and the reader shows the body.
            title: "",
            text: page.text,
            // Not a prompt yet — this is the authored visual intent, which is
            // what a later illustration pass would build a prompt from.
            imagePrompt: page.visualScene
        )
    }

    /// The app's `StoryTheme` is a **world** taxonomy — Magical Kingdom, Space,
    /// Jungle, Superhero, Underwater — and the engine's narrative family is not
    /// one. Mapping family to theme would read plausibly and be wrong: a
    /// Threshold story is not a "Superhero" story, it is a story about a child
    /// who hesitates.
    ///
    /// So this maps from where the story is *set*, which is the axis the two
    /// vocabularies actually share, and returns `.custom` for everything else.
    /// `.custom` exists for exactly this and is not a failure.
    ///
    /// Nothing in the new flow shows the theme. It is mapped only because the
    /// app model requires the field — and it is lossy on purpose there, which
    /// is why the **cover** is no longer derived from it. Forest, garden,
    /// orchard and meadow all collapse to one theme here; four of the six
    /// shipped settings were therefore drawn with the same green tree, and a
    /// shelf of a child's stories looked like one story repeated.
    static func theme(for setting: CatalogSetting) -> StoryTheme {
        let tags = Set(setting.tags.map(\.rawValue))
        if !tags.isDisjoint(with: ["sea", "water", "ocean"]) { return .underwater }
        if !tags.isDisjoint(with: ["forest", "jungle", "garden"]) { return .jungle }
        if !tags.isDisjoint(with: ["space", "sky", "moon"]) { return .space }
        return .custom
    }
}
