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
            pages: pages.map { page(from: $0, packageVersion: composed.sourceReference.packageVersion) },
            origin: StoryOrigin(
                seed: String(composed.seed),
                storyIdeaID: nil,
                blueprintID: composed.structureID,
                settingID: pages.first?.settingID ?? "",
                companionID: composed.companion.id,
                discoveryID: composed.discoveryID,
                fingerprint: fingerprint(ofRenderedDigests: pages.map(\.provenance.renderedSHA256)),
                catalogVersion: composed.sourceReference.packageVersion,
                contentSource: ContentSourceMetadata(p56: composed.sourceReference),
                worldID: MP.World(rawValue: composed.worldID)?.rawValue,
                modeID: StoryMode(rawValue: composed.mode.rawValue)?.rawValue,
                selectionStrategy: strategy?.rawValue,
                ageBand: AgeBandResolver.band(forAge: composed.age).description,
                p56BookID: composed.bookID
            )
        )
        story.currentProgress = nil
        return story
    }

    /// One page as the app keeps it: the composed text and the page's full P56
    /// source chain (Codex isteği, 25 Kasım), no art.
    static func page(from page: P56ComposedPage, packageVersion: String) -> MagicPaper.StoryPage {
        var stored = MagicPaper.StoryPage(id: UUID(), title: "", text: page.text, imagePrompt: "")
        let trace = page.provenance
        stored.provenance = StoryPageProvenance(p56: .init(
            packageVersion: packageVersion, templateID: trace.templateID, templateSHA256: trace.templateSHA256,
            parentSourceID: trace.parentSourceID, parentSHA256: trace.parentSHA256,
            parentPointer: trace.parentPointer, renderedSHA256: trace.renderedSHA256, order: trace.order))
        return stored
    }

    /// Stable over the rendered text: the pages' rendered digests, in order.
    /// A content fingerprint, not the source identity: two books with the same
    /// text from different sources share it; `contentSource` and the page
    /// chains tell them apart.
    static func fingerprint(ofRenderedDigests digests: [String]) -> String {
        SHA256.hash(data: Data(digests.joined(separator: "|").utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
