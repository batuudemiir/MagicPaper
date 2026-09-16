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
            intent: intent,
            idea: selector.storyIdea(catalog: catalog, intent: intent)
        )
    }

    public func compose(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea? = nil
    ) throws -> ComposedStory {
        guard blueprint.isBeatAuthored else {
            throw OfflineSelectionError.blueprintNotBeatAuthored(id: blueprint.id)
        }

        let content = try binder.bind(
            blueprint: blueprint, catalog: catalog, intent: intent, idea: idea)
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
        var carried: [Int: (beats: [StoryBeat], role: PageRole, emotion: EmotionalState?)] = [:]
        for step in try Self.plan(blueprint) {
            carried[step.pageNumber] = (step.beats, step.role, step.emotion)
        }

        var currentPage = 0
        var sentences: [String] = []
        var scenes: [String] = []
        var variantIDs: [ContentID] = []
        var missing: [String] = []
        var unrecognised: [String] = []

        func flush() {
            guard currentPage != 0, let page = carried[currentPage] else { return }
            pages.append(ComposedPage(
                pageNumber: currentPage,
                role: page.role,
                beats: page.beats,
                emotion: page.emotion,
                text: sentences.joined(separator: " "),
                visualScene: scenes.joined(separator: "; "),
                variantIDs: variantIDs,
                missingSlots: missing,
                unrecognisedSuffixes: unrecognised
            ))
            sentences = []; scenes = []; variantIDs = []; missing = []; unrecognised = []
        }

        for step in try Self.plan(blueprint) {
            if step.pageNumber != currentPage {
                flush()
                currentPage = step.pageNumber
            }
            let candidates = catalog.templates.filter {
                $0.realizesBeat == step.beat && !$0.variants.isEmpty
            }
            guard !candidates.isEmpty else {
                throw OfflineSelectionError.noTemplate(beat: step.beat, page: step.pageNumber)
            }
            let template = DeterministicPicker.pick(from: candidates, seed: storySeed, salt: step.salt)

            let variant = try Self.chooseVariant(
                from: template.variants,
                realizing: step.beat,
                wanting: step.wanted,
                after: step.previous,
                closing: step.closing,
                state: step.state,
                onPage: step.pageNumber,
                content: content,
                register: blueprint.family?.beliefRegister,
                conflict: blueprint.family?.conflict,
                seed: storySeed,
                salt: step.salt + ".v"
            )

            let rendered = TurkishTextRenderer.render(variant.text, slots: slots)
            sentences.append(rendered.text)
            if !variant.visualScene.isEmpty { scenes.append(variant.visualScene) }
            variantIDs.append(variant.id)
            missing += rendered.missingSlots
            unrecognised += rendered.unrecognisedSuffixes
        }
        flush()

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

    /// One beat to be written, with everything the choice depends on.
    ///
    /// `previous`, `closing` and `state` are three different questions about
    /// what has already happened and it is easy to answer one with another:
    /// on a page pairing `self_recognize` with `warm_close`, the beat
    /// immediately before the closing line is the one beside it on the same
    /// page, while the resolution it refers back to is two beats earlier.
    struct PlanStep {
        let pageNumber: Int
        let role: PageRole
        let emotion: EmotionalState?
        /// Every beat on this page, for the record the page carries.
        let beats: [StoryBeat]
        let beat: StoryBeat
        let wanted: VariantLengthClass
        let previous: StoryBeat?
        let closing: StoryBeat?
        let state: DerivedNarrativeState
        let salt: String
    }

    /// The blueprint's page plan flattened into the order beats are written,
    /// with the accumulated context each one sees.
    ///
    /// Pure, and shared: the composer walks it to write the book and the supply
    /// tests walk it to measure pools. Keeping one copy is the same rule the
    /// rest of this merge kept arriving at — a second implementation of a walk
    /// is free to disagree with the first, and a test that disagrees with the
    /// code it checks reports defects that are not there.
    static func plan(_ blueprint: CatalogBlueprint) throws -> [PlanStep] {
        var steps: [PlanStep] = []
        var previous: StoryBeat?
        var closing: StoryBeat?
        var state = DerivedNarrativeState()

        for slot in blueprint.pagePlan.sorted(by: { $0.pageNumber < $1.pageNumber }) {
            guard let beat = slot.beat else {
                throw OfflineSelectionError.blueprintNotBeatAuthored(id: blueprint.id)
            }
            // A supporting beat is a second sentence on the same page, not a
            // second page — that is what lets page 4 both name the reluctance
            // and decide anyway. A page carrying two beats needs two short
            // lines; a page carrying one needs a full one.
            let ordered = [beat] + (slot.supportingBeat.map { [$0] } ?? [])
            let wanted: VariantLengthClass = ordered.count > 1 ? .paired : .solo

            for (offset, current) in ordered.enumerated() {
                steps.append(PlanStep(
                    pageNumber: slot.pageNumber, role: slot.role, emotion: slot.emotion,
                    beats: ordered, beat: current, wanted: wanted,
                    previous: previous, closing: closing, state: state,
                    salt: "p\(slot.pageNumber).\(offset).\(current.rawValue)"))
                previous = current
                if current == .succeed || current == .restore { closing = current }
                state.produce(current.produces)
            }
        }
        return steps
    }

    /// Picks a line for one beat.
    ///
    /// Some narrowings degrade and some do not, and which is which is the whole
    /// design. A corpus is always partly authored, so a filter that empties the
    /// pool must not turn "nobody has written a short version yet" into "this
    /// story cannot be told" — those preferences are dropped rather than
    /// enforced. But a filter whose violation **contradicts another page** is
    /// different in kind: relaxing it does not make a weaker book, it makes an
    /// incoherent one, and the author wants to be told instead. Selection stays
    /// deterministic either way.
    static func chooseVariant(
        from variants: [CatalogVariant],
        realizing beat: StoryBeat,
        wanting length: VariantLengthClass,
        after previous: StoryBeat?,
        closing: StoryBeat? = nil,
        state: DerivedNarrativeState = DerivedNarrativeState(),
        onPage page: Int,
        content: BoundContent,
        register: VariantRegister?,
        conflict: ConflictMechanism? = nil,
        seed: String,
        salt: String
    ) throws -> CatalogVariant {
        let pool = try self.pool(
            from: variants, realizing: beat, wanting: length, after: previous,
            closing: closing, state: state, onPage: page, content: content,
            register: register, conflict: conflict)
        return DeterministicPicker.pick(from: pool, seed: seed, salt: salt)
    }

    /// Every line that could serve this page for this binding.
    ///
    /// Split out from the choice so a test can ask how *many* there were.
    /// Declared filters compose, and each one partitions: `meet_companion`
    /// offers sixteen variants but four cast roles times two length classes is
    /// eight cells, and a story is bound to one cell before a single variant is
    /// eligible. A cell of one means every book of that binding gets the same
    /// page — which was true on page 3 of a shipped blueprint while the beat's
    /// headline count read sixteen.
    ///
    /// Counting a beat's variants cannot see that, and neither can a check that
    /// a length class merely *exists* for a beat. Only the pool the composer
    /// actually ends up with can, so that pool is what this returns — the real
    /// one, not a second implementation of the same filters that would be free
    /// to drift away from it.
    static func pool(
        from variants: [CatalogVariant],
        realizing beat: StoryBeat,
        wanting length: VariantLengthClass,
        after previous: StoryBeat?,
        closing: StoryBeat? = nil,
        state: DerivedNarrativeState = DerivedNarrativeState(),
        onPage page: Int,
        content: BoundContent,
        register: VariantRegister?,
        conflict: ConflictMechanism? = nil
    ) throws -> [CatalogVariant] {
        func narrow(_ pool: [CatalogVariant], _ keep: (CatalogVariant) -> Bool) -> [CatalogVariant] {
            let kept = pool.filter(keep)
            return kept.isEmpty ? pool : kept
        }

        // 0. The part the companion is playing. **Does not degrade.**
        //
        //    A line written for a guide, given to a companion cast as the one
        //    who needs care, does not read as a slightly-off line: it describes
        //    a different character than the rest of the book does. This is the
        //    same class as narrowing 3 below, and the reason the cast is
        //    resolved once per story rather than per page.
        let byRole = variants.filter { $0.suits(role: content.castRole) }
        guard !byRole.isEmpty else {
            throw OfflineSelectionError.noVariantForRole(
                role: content.castRole, beat: beat, page: page)
        }

        // 0b. The shape the conflict actually has. **Does not degrade.**
        //
        //     An obstacle that stands in the way is the wrong shape for a
        //     conflict made of time: nothing is blocking the child, the
        //     difficulty is that it is not finished yet. A line of the wrong
        //     shape does not read as a weaker obstacle, it reads as a different
        //     story's obstacle.
        let byConflict = byRole.filter { $0.suits(conflict: conflict) }
        guard !byConflict.isEmpty else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a \(conflict?.rawValue ?? "unstated")-shaped conflict",
                beat: beat, page: page)
        }

        // 0c. What the line assumes is already true. **Does not degrade.**
        let byState = byConflict.filter { variant in
            variant.afterState.allSatisfy(state.contains)
        }
        guard !byState.isEmpty else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "state the story has not reached", beat: beat, page: page)
        }

        // 0d. How the story ended, for a line that refers back to it.
        //     **Does not degrade**, and deliberately asks a different question
        //     from narrowing 3 below: on a page pairing `self_recognize` with
        //     `warm_close`, the beat immediately before the closing line is the
        //     one beside it, while what it refers back to is the resolution two
        //     beats earlier.
        let byClosing = byState.filter { variant in
            guard !variant.afterClosing.isEmpty else { return true }
            guard let closing else { return false }
            return variant.afterClosing.contains(closing)
        }
        guard !byClosing.isEmpty else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a story that ended in '\(closing?.rawValue ?? "nothing")'",
                beat: beat, page: page)
        }

        var pool = byClosing
        // 1. Content the line assumes must actually be there — including what
        //    the companion can do, so a line about gliding down is offered only
        //    to something that flies. Degrades: a glowing egg is wrong and a
        //    reader forgives it once.
        pool = narrow(pool) {
            $0.fits(
                setting: content.setting,
                discovery: content.discovery,
                companion: content.companion)
        }
        // 2. The right length for a shared or unshared page. Degrades: the page
        //    runs long or short, which is cosmetic.
        pool = narrow(pool) { $0.lengthClass == nil || $0.lengthClass == length }
        // 2b. How firmly the line is voiced, where the corpus says it matters.
        //     Degrades only in the sense that an unauthored register cannot be
        //     honoured; a line that declares one is never given to a family that
        //     needs the other while an alternative exists.
        if let register {
            pool = narrow(pool) { $0.register == nil || $0.register == register }
        }

        // 3. A line written to follow a particular beat. **Does not degrade.**
        //
        //    Dropping this one is different in kind from dropping the other
        //    two. A page whose closing line refers to overcoming something,
        //    placed after a beat that overcame nothing, does not read as a
        //    weaker page — it contradicts the six pages before it. That is the
        //    defect that put "Ve Yeliz karşıya geçti" at the end of a story
        //    about misreading the evidence, and quietly re-permitting it under
        //    pool pressure would undo the fix.
        //
        //    An empty pool here is an authoring gap, and the author wants to be
        //    told about it.
        let byOrder = pool.filter { variant in
            guard !variant.afterBeat.isEmpty else { return true }
            guard let previous else { return false }
            return variant.afterBeat.contains(previous)
        }
        guard !byOrder.isEmpty else {
            throw OfflineSelectionError.noVariantAfter(beat: previous, page: page)
        }
        return byOrder
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
