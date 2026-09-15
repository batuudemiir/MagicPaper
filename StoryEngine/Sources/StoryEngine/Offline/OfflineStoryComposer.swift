import Foundation
import EngineFoundation

// MARK: - Output

/// One composed page: the prose, and everything needed to explain it.
public struct ComposedPage: Sendable, Hashable {
    public let pageNumber: Int
    public let role: PageRole
    public let beats: [StoryBeat]
    public let emotion: EmotionalState?
    public let text: String
    public let visualScene: String
    /// The variants this text came from, in order. Provenance, not decoration:
    /// when a page reads badly, this is what names the sentence to fix.
    public let variantIDs: [ContentID]
    /// Slots the text asked for and did not get. Non-empty means a defect.
    public let missingSlots: [String]
    /// Suffix spellings the Turkish renderer did not recognise.
    public let unrecognisedSuffixes: [String]
}

/// A finished offline draft — text only. No images, no persistence, no IDs the
/// app layer owns.
public struct ComposedStory: Sendable, Hashable {
    public let title: String
    public let pages: [ComposedPage]
    public let blueprintID: ContentID
    public let family: NarrativeFamily?
    public let content: BoundContent
    public let seed: String
    /// Stable over the inputs that determine the text, so two runs can be
    /// compared and a regenerate can be recognised as a no-op.
    public let fingerprint: String

    /// Whether every page rendered without a missing slot or an unknown suffix.
    public var isClean: Bool {
        pages.allSatisfy { $0.missingSlots.isEmpty && $0.unrecognisedSuffixes.isEmpty }
    }
}

// MARK: - Composer

/// Turns a blueprint plus bound content into Turkish prose.
///
/// The order matters and is the point of the architecture: a page's text is
/// chosen by the **beat** it has to realize, never by its role. One well-written
/// `hesitate` variant then serves every blueprint that hesitates.
public struct OfflineStoryComposer: Sendable {
    private let binder = OfflineContentBinder()
    private let titles = TitleComposer()
    private let selector = BlueprintSelector()

    public init() {}

    /// Compose without naming a blueprint: the three choices select the shape.
    /// This is the entry point the app uses; the blueprint-explicit overload
    /// exists for tests and for regenerating a story that already has one.
    public func compose(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> ComposedStory {
        try compose(
            blueprint: selector.select(catalog: catalog, intent: intent),
            catalog: catalog,
            intent: intent
        )
    }

    public func compose(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> ComposedStory {
        guard blueprint.isBeatAuthored else {
            throw OfflineSelectionError.blueprintNotBeatAuthored(id: blueprint.id)
        }

        let content = try binder.bind(blueprint: blueprint, catalog: catalog, intent: intent)
        let slots = Self.slots(childName: intent.childName, content: content)

        // Variant choice is keyed on the whole story, not on the seed alone.
        // Keyed on the seed alone, two stories built from the same seed but
        // different content picked the same sentence for every shared beat —
        // so a fox story and a dolphin story came out near-identical. Every
        // input that identifies the story is folded in, which keeps a
        // regenerate reproducible (same inputs, same book) while letting two
        // different books diverge.
        let storySeed = StableHash.fingerprint([
            intent.seed, intent.childName, blueprint.id.rawValue,
            content.setting.id.rawValue, content.companion.id.rawValue,
            content.discovery.id.rawValue
        ])

        var pages: [ComposedPage] = []
        for slot in blueprint.pagePlan.sorted(by: { $0.pageNumber < $1.pageNumber }) {
            guard let beat = slot.beat else {
                throw OfflineSelectionError.blueprintNotBeatAuthored(id: blueprint.id)
            }
            let ordered = [beat] + (slot.supportingBeat.map { [$0] } ?? [])

            var sentences: [String] = []
            var scenes: [String] = []
            var variantIDs: [ContentID] = []
            var missing: [String] = []
            var unrecognised: [String] = []

            // A supporting beat is a second sentence on the same page, not a
            // second page. That is what lets page 4 both name the reluctance
            // and decide anyway.
            for (offset, current) in ordered.enumerated() {
                let candidates = catalog.templates.filter {
                    $0.realizesBeat == current && !$0.variants.isEmpty
                }
                guard !candidates.isEmpty else {
                    throw OfflineSelectionError.noTemplate(beat: current, page: slot.pageNumber)
                }
                let salt = "p\(slot.pageNumber).\(offset).\(current.rawValue)"
                let template = DeterministicPicker.pick(from: candidates, seed: storySeed, salt: salt)
                let variant = DeterministicPicker.pick(
                    from: template.variants, seed: storySeed, salt: salt + ".v"
                )

                let rendered = TurkishTextRenderer.render(variant.text, slots: slots)
                sentences.append(rendered.text)
                if !variant.visualScene.isEmpty { scenes.append(variant.visualScene) }
                variantIDs.append(variant.id)
                missing += rendered.missingSlots
                unrecognised += rendered.unrecognisedSuffixes
            }

            pages.append(ComposedPage(
                pageNumber: slot.pageNumber,
                role: slot.role,
                beats: ordered,
                emotion: slot.emotion,
                text: sentences.joined(separator: " "),
                visualScene: scenes.joined(separator: "; "),
                variantIDs: variantIDs,
                missingSlots: missing,
                unrecognisedSuffixes: unrecognised
            ))
        }

        let title = titles.compose(blueprint: blueprint, slots: slots, seed: storySeed)

        return ComposedStory(
            title: title,
            pages: pages,
            blueprintID: blueprint.id,
            family: blueprint.family,
            content: content,
            seed: intent.seed,
            fingerprint: StableHash.fingerprint(
                [blueprint.id.rawValue, content.setting.id.rawValue,
                 content.companion.id.rawValue, content.discovery.id.rawValue,
                 intent.childName, intent.seed]
                + pages.flatMap { $0.variantIDs.map(\.rawValue) }
            )
        )
    }

    /// The slot table, built once per story.
    ///
    /// Each value carries its own grammar, declared by the content record —
    /// which is why "tilki" comes back as "tilkiye" and "Tarçın" as "Tarçın'a".
    static func slots(childName: String, content: BoundContent) -> [String: TurkishTextRenderer.Slot] {
        [
            "child.name": .init(childName, isProperNoun: true),
            "setting.name": .init(
                content.setting.name,
                isProperNoun: content.setting.isProperNoun,
                hasPossessiveEnding: content.setting.hasPossessiveEnding,
                blocksSoftening: content.setting.blocksSoftening
            ),
            "companion.name": .init(
                content.companion.name,
                isProperNoun: content.companion.isProperNoun,
                hasPossessiveEnding: content.companion.hasPossessiveEnding,
                blocksSoftening: content.companion.blocksSoftening
            ),
            // A companion *type* is a common noun: "tilkiye", never "tilki'ye".
            // Emitting an apostrophe here was a visible defect of the prototype.
            "companion.type": .init(content.companion.type, isProperNoun: false),
            // Two registers of the same thing: `name` reads inside a
            // sentence, `title` on a cover. Titles use the latter.
            "discovery.title": .init(
                content.discovery.titleName,
                isProperNoun: content.discovery.isProperNoun,
                hasPossessiveEnding: content.discovery.hasPossessiveEnding,
                blocksSoftening: content.discovery.blocksSoftening
            ),
            "discovery.name": .init(
                content.discovery.name,
                isProperNoun: content.discovery.isProperNoun,
                hasPossessiveEnding: content.discovery.hasPossessiveEnding,
                blocksSoftening: content.discovery.blocksSoftening
            )
        ]
    }
}
