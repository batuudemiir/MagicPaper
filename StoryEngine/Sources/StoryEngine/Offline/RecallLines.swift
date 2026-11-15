import Foundation

// MARK: - Catalog record

/// How well the child knows what this story brings back (E3).
public enum RecallTier: String, Codable, Sendable, Hashable, CaseIterable {
    /// The companion was in one earlier story.
    case metOnce
    /// The companion was in two or three.
    case friends
    /// The companion was in four or more.
    case oldFriends
    /// No companion to remember, but the child has been to this place.
    case placeAgain

    /// The tier for a companion met in `stories` earlier stories.
    public static func forCompanion(storyCount: Int) -> RecallTier? {
        switch storyCount {
        case ..<1: return nil
        case 1: return .metOnce
        case 2...3: return .friends
        default: return .oldFriends
        }
    }

    public var isCompanionTier: Bool { self != .placeAgain }
}

/// Where a companion line says the two first met, if it says so at all.
public enum RecallFirstMet: String, Codable, Sendable, Hashable, CaseIterable {
    /// The same place as this story: "burada".
    case here
    /// Another place, named through `{{recall.place.name}}`.
    case elsewhere
}

/// One recall sentence, authored in `recall_lines_v1.json`.
///
/// ```json
/// { "id": "recall_old_friends_here_01", "tier": "oldFriends", "firstMet": "here",
///   "ageBand": "3-4", "text": "{{child.name}} ile {{companion.name}} …",
///   "editorialNote": "taslak, Batuhan okuyacak" }
/// ```
///
/// `firstMet` is nil for a line that does not say where they met; such a line
/// serves either case. `ageBand` nil serves every band; a band that has lines
/// of its own uses only those.
public struct CatalogRecallLine: Decodable, Sendable, Hashable {
    public let id: ContentID
    public let tier: RecallTier
    public let firstMet: RecallFirstMet?
    public let ageBand: AgeBand?
    public let text: String
    /// Who has read the line and what is open about it. Never shown.
    public let editorialNote: String?

    public init(
        id: ContentID, tier: RecallTier, firstMet: RecallFirstMet? = nil,
        ageBand: AgeBand? = nil, text: String, editorialNote: String? = nil
    ) {
        self.id = id
        self.tier = tier
        self.firstMet = firstMet
        self.ageBand = ageBand
        self.text = text
        self.editorialNote = editorialNote
    }

    /// The slots a recall line may use. `recall.place.name` only in a line
    /// whose `firstMet` is `elsewhere`, which must use it.
    public static let allowedSlots: Set<String> = [
        "child.name", "companion.name", "companion.type", "setting.name", RecallComposer.placeSlot
    ]
}

// MARK: - What the app passes

/// What the child met before (E3). Ids and counts only: what those stories
/// said, and who they were for, never reach the engine.
public struct RecallHistory: Sendable, Hashable {
    public struct Companion: Sendable, Hashable {
        /// Finished standalone stories this companion was in.
        public let storyCount: Int
        /// Where the child met it first.
        public let firstSettingID: ContentID

        public init(storyCount: Int, firstSettingID: ContentID) {
            self.storyCount = storyCount
            self.firstSettingID = firstSettingID
        }
    }

    public let companions: [ContentID: Companion]
    public let visitedSettings: Set<ContentID>

    public init(companions: [ContentID: Companion] = [:], visitedSettings: Set<ContentID> = []) {
        self.companions = companions
        self.visitedSettings = visitedSettings
    }

    public var isEmpty: Bool { companions.isEmpty && visitedSettings.isEmpty }
}

// MARK: - Choosing and writing the line

/// Picks and renders the recall sentence once the story's content is bound.
///
/// Decided after binding because a surprise story's companion and place are
/// not known before. The order is the one the app used (Faz 10): the
/// companion first, a friendship being the stronger tie, then the place.
enum RecallComposer {
    static let placeSlot = "recall.place.name"

    /// What this story can recall: the tier and, for a companion, where they
    /// first met. Nil when nothing in it is familiar.
    struct Cue {
        let tier: RecallTier
        let firstMet: RecallFirstMet?
        let firstSetting: CatalogSetting?
    }

    static func cue(history: RecallHistory, content: BoundContent, catalog: ContentCatalog) -> Cue? {
        if let met = history.companions[content.companion.id],
           let tier = RecallTier.forCompanion(storyCount: met.storyCount) {
            if met.firstSettingID == content.setting.id {
                return Cue(tier: tier, firstMet: .here, firstSetting: content.setting)
            }
            return Cue(tier: tier, firstMet: .elsewhere, firstSetting: catalog.setting(met.firstSettingID))
        }
        if history.visitedSettings.contains(content.setting.id) {
            return Cue(tier: .placeAgain, firstMet: nil, firstSetting: nil)
        }
        return nil
    }

    /// The lines that can serve this cue in this band, in the order the
    /// integrity check counts them.
    ///
    /// A line that names where they met must match the cue; one that does not
    /// say serves either. An `elsewhere` cue whose first place the catalog no
    /// longer has takes only lines that do not name it. A band with lines of
    /// its own uses only those; otherwise the bandless lines serve.
    static func pool(for cue: Cue, band: AgeBand?, in lines: [CatalogRecallLine]) -> [CatalogRecallLine] {
        let fitting = lines.filter { line in
            guard line.tier == cue.tier else { return false }
            guard let said = line.firstMet else { return true }
            guard said == cue.firstMet else { return false }
            return said == .here || cue.firstSetting != nil
        }
        let own = fitting.filter { $0.ageBand != nil && $0.ageBand == band }
        return own.isEmpty ? fitting.filter { $0.ageBand == nil } : own
    }

    /// The rendered line, or nil. Nil whenever anything is off: no cue, no
    /// line for it, or a line that did not render clean. A recall that cannot
    /// be written is dropped; the story never is.
    ///
    /// Cooling: a line used in the child's recent stories (`recent`, the same
    /// window prose lines cool in) is left out while another serves, and the
    /// rest are ordered by `SelectionScoring.variantWeight` from the story
    /// seed, so the same history gives the same line.
    static func line(
        history: RecallHistory,
        content: BoundContent,
        catalog: ContentCatalog,
        band: AgeBand?,
        slots: [String: TurkishTextRenderer.Slot],
        recent: [Set<ContentID>],
        seed: String
    ) -> (id: ContentID, text: String)? {
        guard let cue = cue(history: history, content: content, catalog: catalog) else { return nil }
        let pool = pool(for: cue, band: band, in: catalog.recallLines)
        guard !pool.isEmpty else { return nil }

        let window = recent.prefix(SelectionScoring.cooldownWindow)
        let fresh = pool.filter { line in !window.contains { $0.contains(line.id) } }
        let choices = fresh.isEmpty ? pool : fresh
        let weights = choices.map { SelectionScoring.variantWeight(id: $0.id, recent: recent) }
        let ordered = SelectionScoring.ordered(choices, weights: weights, id: \.id, seed: seed, salt: "recall")
        guard let chosen = ordered.first else { return nil }

        var table = slots
        if cue.firstMet == .elsewhere, let place = cue.firstSetting {
            table[placeSlot] = .init(
                place.name, isProperNoun: place.isProperNoun,
                hasPossessiveEnding: place.hasPossessiveEnding, blocksSoftening: place.blocksSoftening)
        }
        let rendered = TurkishTextRenderer.render(chosen.text, slots: table)
        guard rendered.isClean else { return nil }
        return (chosen.id, rendered.text)
    }
}

extension ComposedPage {
    /// This page with the recall line added as its own paragraph at the end.
    func appendingRecall(id: ContentID, text line: String) -> ComposedPage {
        ComposedPage(
            pageNumber: pageNumber, role: role, beats: beats, emotion: emotion,
            text: text + "\n\n" + line, visualScene: visualScene,
            variantIDs: variantIDs + [id], missingSlots: missingSlots,
            unrecognisedSuffixes: unrecognisedSuffixes, words: words, refrain: refrain)
    }
}
