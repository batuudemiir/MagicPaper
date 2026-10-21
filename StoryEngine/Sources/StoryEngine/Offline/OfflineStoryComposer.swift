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
    /// Words this page teaches (FAZ 17), where they sit in `text`. Empty for
    /// a page whose lines teach none, which is every page before FAZ 17.
    public let words: [PageWord]
    /// The declared refrain this page ends with, as it appears at the end of
    /// `text`. Nil on every page of a blueprint without one.
    public var refrain: String? = nil
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

/// What composing a series episode needs beyond an ordinary intent (FAZ 13).
public struct EpisodeContext: Sendable, Hashable {
    /// 2…5. The first story is episode 1 and is never composed again.
    public let number: Int
    /// What the first story found, remembered in every later episode.
    public let keepsake: CatalogObject
    /// Lines the earlier episodes already used. A preference, not a rule:
    /// where every line of a page has been used, one is used again.
    public let avoiding: Set<ContentID>

    public init(number: Int, keepsake: CatalogObject, avoiding: Set<ContentID> = []) {
        self.number = number
        self.keepsake = keepsake
        self.avoiding = avoiding
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
        let idea = try selector.storyIdea(catalog: catalog, intent: intent)
        let candidates = try selector.ranked(catalog: catalog, intent: intent)

        // Tried in order rather than picked once. A blueprint is admitted by
        // checking each axis on its own, and the axes are coupled: one can
        // accept the chosen companion and accept some setting while accepting
        // no setting that companion could be in. The child's choice is the
        // fixed point here — the shape is what should give way.
        //
        // The failure kept is the **first**, not the last. The first candidate
        // is the one the idea's affinity actually chose, so its reason is the
        // one that explains what the child asked for; the last is whatever
        // remote blueprint the walk happened to end on.
        var failure: Error?
        for blueprint in candidates {
            do {
                return try compose(
                    blueprint: blueprint, catalog: catalog, intent: intent, idea: idea)
            } catch {
                if failure == nil { failure = error }
                continue
            }
        }
        throw failure ?? OfflineSelectionError.noBlueprints
    }

    public func compose(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea? = nil
    ) throws -> ComposedStory {
        try compose(blueprint: blueprint, catalog: catalog, intent: intent, idea: idea, episode: nil)
    }

    /// One episode of a series (FAZ 13): a continuation blueprint, the first
    /// story's place and companion pinned in `intent`, and the keepsake that
    /// story found. Lines come from the series layer where it has them, and
    /// the last page must close calmly (`CalmEnding`).
    public func composeEpisode(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        episode: EpisodeContext
    ) throws -> ComposedStory {
        guard blueprint.continuation != nil else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a continuation blueprint", beat: .revisit, page: 1)
        }
        return try compose(blueprint: blueprint, catalog: catalog, intent: intent, idea: nil, episode: episode)
    }

    private func compose(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea?,
        episode: EpisodeContext?
    ) throws -> ComposedStory {
        guard blueprint.isBeatAuthored else {
            throw OfflineSelectionError.blueprintNotBeatAuthored(id: blueprint.id)
        }

        let content = try binder.bind(
            blueprint: blueprint, catalog: catalog, intent: intent, idea: idea)
        var slots = Self.slots(childName: intent.childName, content: content, family: intent.family)
        if let episode { slots["keepsake.name"] = Self.keepsakeSlot(episode.keepsake) }
        let familyMoments = episode == nil ? catalog.familyMoments : catalog.series.familyMoments
        let lastPage = blueprint.pagePlan.map(\.pageNumber).max() ?? 0
        // A series episode and a bedtime story both close without a hook: the
        // first promised it (FAZ 13), the second is read to a child falling
        // asleep (privacy-safety koşul 4, 21 Ekim 2026).
        let closesCalmly = episode != nil || blueprint.arc == .bedtime

        // Variant choice is keyed on the whole story, not on the seed alone.
        // Keyed on the seed alone, two stories built from the same seed but
        // different content picked the same sentence for every shared beat —
        // so a fox story and a dolphin story came out near-identical. Every
        // input that identifies the story is folded in, which keeps a
        // regenerate reproducible (same inputs, same book) while letting two
        // different books diverge.
        // The family character joins the key only when there is one, so every
        // story without one keeps the seed — and the book — it had before.
        let storySeed = StableHash.fingerprint([
            intent.seed, intent.childName, blueprint.id.rawValue,
            content.setting.id.rawValue, content.companion.id.rawValue,
            content.discovery.id.rawValue
        ] + Self.familyKey(intent.family) + Self.episodeKey(episode))

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
        var words: [PageWord] = []
        var pageLength = 0

        func flush() {
            guard currentPage != 0, let page = carried[currentPage] else { return }
            // A declared refrain closes its page, after the beat's own lines,
            // so the listener hears the story first and then the line to join.
            let refrain = blueprint.refrain?.text(onPage: currentPage)
            if let refrain { sentences.append(refrain) }
            pages.append(ComposedPage(
                pageNumber: currentPage,
                role: page.role,
                beats: page.beats,
                emotion: page.emotion,
                text: sentences.joined(separator: " "),
                visualScene: scenes.joined(separator: "; "),
                variantIDs: variantIDs,
                missingSlots: missing,
                unrecognisedSuffixes: unrecognised,
                words: words,
                refrain: refrain
            ))
            sentences = []; scenes = []; variantIDs = []; missing = []; unrecognised = []
            words = []; pageLength = 0
        }

        for step in try Self.plan(blueprint) {
            if step.pageNumber != currentPage {
                flush()
                currentPage = step.pageNumber
            }
            let candidates = Self.templates(
                for: step.beat, in: catalog, blueprint: blueprint, series: episode != nil)
            guard !candidates.isEmpty else {
                throw OfflineSelectionError.noTemplate(beat: step.beat, page: step.pageNumber)
            }
            // On a family moment only a template that has a line for this
            // relation can serve; picking among all of them would let the seed
            // land on one that cannot, and the page would fail for no reason.
            let familyMoment = intent.family != nil && familyMoments.contains(step.beat)
            let serving = familyMoment
                ? candidates.filter { Self.hasFamilyLine($0, for: intent.family?.relation) }
                : candidates
            let familyPool = serving.isEmpty ? candidates : serving
            // A template with no line the parent allows cannot serve this page
            // (FAZ 17). Filtered only when a setting is given, so a story
            // without one picks among exactly the templates it always did.
            let templatePool: [CatalogTemplate]
            if let safety = intent.safety {
                templatePool = familyPool.filter { template in
                    template.variants.contains { safety.admits(topics: $0.topics) }
                }
                guard !templatePool.isEmpty else {
                    throw OfflineSelectionError.noVariantSatisfying(
                        constraint: "a line clear of the topics the parent avoids",
                        beat: step.beat, page: step.pageNumber)
                }
            } else {
                templatePool = familyPool
            }
            let template = episode == nil
                ? DeterministicPicker.pick(from: templatePool, seed: storySeed, salt: step.salt)
                : templatePool[DeterministicPicker.mixedIndex(
                    count: templatePool.count, seed: storySeed, salt: step.salt)]

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
                family: intent.family?.relation,
                familyMoment: familyMoment,
                calmEnding: closesCalmly && step.pageNumber == lastPage,
                safety: intent.safety,
                episode: episode,
                seed: storySeed,
                salt: step.salt + ".v"
            )

            let rendered = TurkishTextRenderer.render(variant.text, slots: slots)
            // Sentences are joined with one space; offsets count from the
            // start of the page text the reader will show.
            let sentenceStart = sentences.isEmpty ? 0 : pageLength + 1
            words += Self.words(
                of: variant, in: rendered.text, at: sentenceStart,
                catalog: catalog, band: blueprint.ageRange)
            pageLength = sentenceStart + rendered.text.count
            sentences.append(rendered.text)
            if !variant.visualScene.isEmpty { scenes.append(variant.visualScene) }
            variantIDs.append(variant.id)
            missing += rendered.missingSlots
            unrecognised += rendered.unrecognisedSuffixes
        }
        flush()

        // The lines were filtered, and the page is checked again as rendered:
        // a slot value is the one thing the filter could not see.
        if closesCalmly, let last = pages.last, !CalmEnding.isCalm(last.text) {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a calm episode ending", beat: last.beats.last ?? .warmClose,
                page: last.pageNumber)
        }

        let title = titles.compose(
            blueprint: blueprint, slots: slots, seed: storySeed, avoiding: intent.recentTitles)

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
                + Self.familyKey(intent.family)
                + Self.episodeKey(episode)
                + pages.flatMap { $0.variantIDs.map(\.rawValue) }
            )
        )
    }

    /// Bu beat'i bu blueprint için yazabilecek şablonlar.
    ///
    /// Tek yerde, çünkü iki yerde olduğunda ayrıştı: arz testleri şablon
    /// seçimini kendileri yeniden türetiyordu ve yaş bandı süzgecini
    /// öğrenmediler. Sonuç, 5-6 masalı için 3-4 şablonunun seçilmesi ve
    /// "bu rol için satır yok" diye bir hata — kuralın değil, kuralın
    /// kopyasının hatası.
    static func templates(
        for beat: StoryBeat,
        in catalog: ContentCatalog,
        blueprint: CatalogBlueprint,
        series: Bool = false
    ) -> [CatalogTemplate] {
        // The arc is matched exactly, never relaxed: a bedtime line opens in
        // bed and a standard one in a garden, and neither is a weaker version
        // of the other (`NarrativeArc`).
        func serving(_ templates: [CatalogTemplate]) -> [CatalogTemplate] {
            templates.filter {
                $0.realizesBeat == beat && !$0.variants.isEmpty
                    && $0.suits(band: blueprint.ageRange)
                    && $0.arc == blueprint.arc
            }
        }
        // An episode prefers the lines written for episodes: the standalone
        // ones were written for a first meeting, and a book the child has
        // heard four times already should not open the same way again. Where
        // the series layer has nothing for a beat yet, the standalone lines
        // serve. A standalone story never sees the series layer.
        if series {
            let written = serving(catalog.series.templates)
            if !written.isEmpty { return written }
        }
        return serving(catalog.templates)
    }

    /// Whether a template has any line for this Masal ailem relation.
    static func hasFamilyLine(_ template: CatalogTemplate, for relation: FamilyRelationKind?) -> Bool {
        guard let relation else { return false }
        return template.variants.contains { $0.isFamilyLine && $0.suits(family: relation) }
    }

    /// The first family moment in this blueprint that has no line for the
    /// relation, or nil when every one does.
    ///
    /// A pre-check, not the whole rule: the pool still applies the role,
    /// conflict and ordering filters when the page is written. It exists so a
    /// blueprint that plainly cannot carry the character is ruled out with a
    /// reason, instead of being tried and failing behind the selector's back.
    static func familyGap(
        in blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        relation: FamilyRelationKind
    ) -> StoryBeat? {
        guard let steps = try? plan(blueprint) else { return nil }
        for step in steps where catalog.familyMoments.contains(step.beat) {
            let lines = templates(for: step.beat, in: catalog, blueprint: blueprint)
            if !lines.contains(where: { hasFamilyLine($0, for: relation) }) { return step.beat }
        }
        return nil
    }

    /// The first beat in this blueprint where every line touches a topic the
    /// parent avoids, or nil when each beat keeps one (FAZ 17).
    ///
    /// A pre-check like `familyGap`: the pool still applies its other filters
    /// when the page is written, and a blueprint that fails there is passed
    /// over for the next one.
    static func safetyGap(
        in blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        safety: ContentSafety
    ) -> StoryBeat? {
        guard let steps = try? plan(blueprint) else { return nil }
        for step in steps {
            let lines = templates(for: step.beat, in: catalog, blueprint: blueprint)
                .flatMap(\.variants)
                .filter { !$0.isFamilyLine }
            if !lines.isEmpty, !lines.contains(where: { safety.admits(topics: $0.topics) }) {
                return step.beat
            }
        }
        return nil
    }

    /// The glossary words a line teaches, located in its rendered sentence.
    /// A word the sentence does not hold, or one not written for this band,
    /// is left out; the integrity check reports the first for the author.
    static func words(
        of variant: CatalogVariant,
        in sentence: String,
        at offset: Int,
        catalog: ContentCatalog,
        band: AgeBand
    ) -> [PageWord] {
        variant.words.compactMap { id in
            guard let entry = catalog.glossaryEntry(id), entry.suits(band: band),
                  let found = GlossaryMatcher.locate(entry, in: sentence) else { return nil }
            return PageWord(
                glossaryID: entry.id, term: entry.term, meaning: entry.meaning,
                start: offset + found.start, length: found.length)
        }
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
        family: FamilyRelationKind? = nil,
        familyMoment: Bool = false,
        calmEnding: Bool = false,
        safety: ContentSafety? = nil,
        episode: EpisodeContext? = nil,
        seed: String,
        salt: String
    ) throws -> CatalogVariant {
        let pool = try self.pool(
            from: variants, realizing: beat, wanting: length, after: previous,
            closing: closing, state: state, onPage: page, content: content,
            register: register, conflict: conflict,
            family: family, familyMoment: familyMoment, calmEnding: calmEnding,
            safety: safety)
        guard let episode else {
            return DeterministicPicker.pick(from: pool, seed: seed, salt: salt)
        }
        // An episode prefers a line the series has not used yet: the child
        // hears these books in a row, and the second "Bak," dedi is noticed.
        let fresh = pool.filter { !episode.avoiding.contains($0.id) }
        let choices = fresh.isEmpty ? pool : fresh
        return choices[DeterministicPicker.mixedIndex(count: choices.count, seed: seed, salt: salt)]
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
        conflict: ConflictMechanism? = nil,
        family: FamilyRelationKind? = nil,
        familyMoment: Bool = false,
        calmEnding: Bool = false,
        safety: ContentSafety? = nil
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
        // 0f. What the parent asked stories to avoid (FAZ 17). **Does not
        //     degrade**, and comes first: a line about being alone in the dark
        //     is not a weaker line for a child whose parent ruled that out, it
        //     is the one thing the setting promised would not be read.
        let allowed = safety.map { safety in
            variants.filter { safety.admits(topics: $0.topics) }
        } ?? variants
        guard !allowed.isEmpty else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a line clear of the topics the parent avoids", beat: beat, page: page)
        }

        let byRole = allowed.filter { $0.suits(role: content.castRole) }
        guard !byRole.isEmpty else {
            throw OfflineSelectionError.noVariantForRole(
                role: content.castRole, beat: beat, page: page)
        }

        // 0a. The Masal ailem character. **Does not degrade**, in either
        //     direction. On a family moment the character must be there: a
        //     story that opens with the child's sister and never mentions her
        //     again is the defect, not a weaker page. Everywhere else family
        //     lines stay out, and with no character they are out entirely —
        //     which is what keeps every story written before FAZ 11 the same.
        let byFamily: [CatalogVariant]
        if familyMoment, let family {
            byFamily = byRole.filter { $0.isFamilyLine && $0.suits(family: family) }
            guard !byFamily.isEmpty else {
                throw OfflineSelectionError.noVariantForFamily(
                    relation: family, beat: beat, page: page)
            }
        } else {
            byFamily = byRole.filter { !$0.isFamilyLine }
            guard !byFamily.isEmpty else {
                throw OfflineSelectionError.noVariantForRole(
                    role: content.castRole, beat: beat, page: page)
            }
        }

        // 0b. The shape the conflict actually has. **Does not degrade.**
        //
        //     An obstacle that stands in the way is the wrong shape for a
        //     conflict made of time: nothing is blocking the child, the
        //     difficulty is that it is not finished yet. A line of the wrong
        //     shape does not read as a weaker obstacle, it reads as a different
        //     story's obstacle.
        let byConflict = byFamily.filter { $0.suits(conflict: conflict) }
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

        // 0e. The last page of a series episode closes. **Does not degrade.**
        //     A line that leaves a question open is not a weaker ending, it is
        //     the hook the series promised not to use (FAZ 13, `CalmEnding`).
        let byCalm = calmEnding ? byClosing.filter { CalmEnding.isCalm($0.text) } : byClosing
        guard !byCalm.isEmpty else {
            throw OfflineSelectionError.noVariantSatisfying(
                constraint: "a calm episode ending", beat: beat, page: page)
        }

        var pool = byCalm
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
    static func slots(
        childName: String,
        content: BoundContent,
        family: FamilyCast? = nil
    ) -> [String: TurkishTextRenderer.Slot] {
        var table: [String: TurkishTextRenderer.Slot] = [
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
        if let family {
            // The parent typed it, so it is a name: "Ela'ya", never "elaya".
            table["family.name"] = .init(family.name, isProperNoun: true)
            if let kind = family.animalKind {
                // A kind is a common noun and softens: "köpeğe".
                table["family.kind"] = .init(
                    kind.name, isProperNoun: false, blocksSoftening: kind.blocksSoftening)
                // Its owned form already ends in a possessive: "kedisini".
                table["family.possessive"] = .init(
                    kind.possessive, isProperNoun: false, hasPossessiveEnding: true)
            }
        }
        return table
    }

    /// The keepsake as a remembered thing: its own register when authored,
    /// the prose name otherwise, with the object's grammar either way.
    static func keepsakeSlot(_ object: CatalogObject) -> TurkishTextRenderer.Slot {
        .init(
            object.keepsakeName ?? object.name,
            isProperNoun: object.isProperNoun,
            hasPossessiveEnding: object.hasPossessiveEnding,
            blocksSoftening: object.blocksSoftening)
    }

    /// What an episode adds to a seed or fingerprint. Empty for a standalone
    /// story, so nothing written before FAZ 13 changes.
    static func episodeKey(_ episode: EpisodeContext?) -> [String] {
        guard let episode else { return [] }
        return ["episode", String(episode.number), episode.keepsake.id.rawValue]
    }

    /// What the family character adds to a seed or fingerprint. Empty without
    /// one, so nothing that existed before FAZ 11 changes.
    static func familyKey(_ family: FamilyCast?) -> [String] {
        guard let family else { return [] }
        return ["family", family.relation.rawValue, family.name,
                family.animalKind?.id.rawValue ?? ""]
    }
}
