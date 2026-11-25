import Foundation
import CryptoKit
import StoryEngine

/// A P56 story as the app keeps it (B1, beş arkadaş B hattı).
///
/// The book is stored as written: its pages are the composed pages, its source
/// is the exact P56 payload reference. Nothing here makes a P56 story look like
/// a legacy one: the source stays `.unsupported` for the historical catalog, so
/// it is never rewritten or continued from a current catalog.
///
/// Page-level P56 provenance is not copied onto the pages; the book is
/// reconstructable from `origin` (source, structure, companion, seed).
/// The pages carry no art: P56 artwork is not approved (K-E).
enum P56StoryMapper {
    static func story(
        from composed: P56ComposedStory,
        childProfileID: UUID,
        strategy: StorySelectionStrategy?
    ) -> MagicPaper.Story {
        let pages = composed.pages.sorted { $0.number < $1.number }
        var story = MagicPaper.Story(
            title: composed.title,
            childName: composed.childName,
            childProfileID: childProfileID,
            theme: .custom,
            language: .turkish,
            status: .completed,
            pages: pages.map { MagicPaper.StoryPage(id: UUID(), title: "", text: $0.text, imagePrompt: "") },
            origin: StoryOrigin(
                seed: String(composed.seed),
                storyIdeaID: nil,
                blueprintID: composed.structureID,
                settingID: pages.first?.settingID ?? "",
                companionID: composed.companion.id,
                discoveryID: composed.discoveryID,
                fingerprint: fingerprint(of: pages),
                catalogVersion: composed.sourceReference.packageVersion,
                contentSource: ContentSourceMetadata(p56: composed.sourceReference),
                worldID: MP.World(rawValue: composed.worldID)?.rawValue,
                modeID: StoryMode(rawValue: composed.mode.rawValue)?.rawValue,
                selectionStrategy: strategy?.rawValue,
                ageBand: AgeBandResolver.band(forAge: composed.age).description
            )
        )
        story.currentProgress = nil
        return story
    }

    /// Stable over the rendered text: the pages' rendered digests, in order.
    static func fingerprint(of pages: [P56ComposedPage]) -> String {
        let joined = pages.map(\.provenance.renderedSHA256).joined(separator: "|")
        return SHA256.hash(data: Data(joined.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
