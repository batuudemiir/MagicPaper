import Foundation
import StoryEngine

/// 21 · Masal yazılıyor: what the preparation screen says, in what order and
/// for how long (`docs/MASAL_ATOLYESI_PLANI.md`).
///
/// The offline engine builds a story in milliseconds. The screen shows the work
/// it really did instead of hiding it: who is in the story, how the mode shaped
/// it, the real first sentence, the safety reading. Every line is built from
/// facts about *this* story; nothing here claims work the engine did not do.
///
/// Pure on purpose: the view only plays the steps.
enum StoryPreparationScript {

    enum Beat: Equatable {
        case openBook, cast, ageFit, modeTouch, writing, reread, bind
    }

    struct Step: Equatable {
        let beat: Beat
        /// The calm status line under the notebook.
        let line: String
        /// How long the step stays before the next one, in seconds. The last
        /// step (`bind`) stays: it holds the cover and "Masalı oku".
        let hold: Double
    }

    /// How much of the ritual a story gets: the whole of it at first, less
    /// once the family knows it (karar 16 Ekim 2026).
    enum Tier: Equatable {
        /// The child's first story: ~15 s, no skip (karar 16 Ekim 2026).
        case full
        /// The 2nd and 3rd: ~10 s.
        case standard
        /// From the 4th on: ~6 s, the age line folds away.
        case short
    }

    /// Seconds per beat for `.full`. The other tiers scale or drop from it.
    private static let fullHolds: [Beat: Double] = [
        .openBook: 2.0, .cast: 2.8, .ageFit: 2.0, .modeTouch: 2.2, .writing: 3.8, .reread: 2.2
    ]
    private static let shortHolds: [Beat: Double] = [
        .openBook: 0.8, .cast: 1.4, .modeTouch: 1.1, .writing: 1.9, .reread: 0.9
    ]
    private static let standardScale = 0.67
    /// Uyku saatinde her şey biraz daha yavaş.
    static let bedtimeScale = 1.2

    /// The first sentence is cut at a word, never inside one.
    static let firstSentenceLimit = 110

    static func tier(for facts: PreparationFacts) -> Tier {
        if facts.isFirstRun || facts.storyOrdinal <= 1 { return .full }
        return facts.storyOrdinal <= 3 ? .standard : .short
    }

    static func steps(for facts: PreparationFacts) -> [Step] {
        let tier = tier(for: facts)
        let scale = facts.isBedtime ? bedtimeScale : 1

        var beats: [Beat] = [.openBook, .cast]
        if tier != .short { beats.append(.ageFit) }
        if modeLine(facts) != nil { beats.append(.modeTouch) }
        beats += [.writing, .reread, .bind]

        return beats.map { beat in
            Step(beat: beat, line: line(for: beat, facts: facts),
                 hold: hold(for: beat, tier: tier) * scale)
        }
    }

    /// When "Hemen aç" appears, counted from the screen opening. The first
    /// story is never skippable: it is the moment the ritual is learnt.
    static func skipDelay(for facts: PreparationFacts) -> Double? {
        switch tier(for: facts) {
        case .full: nil
        case .standard: 2
        case .short: 1
        }
    }

    /// The whole run until the cover, in seconds.
    static func totalDuration(for facts: PreparationFacts) -> Double {
        steps(for: facts).reduce(0) { $0 + $1.hold }
    }

    private static func hold(for beat: Beat, tier: Tier) -> Double {
        switch tier {
        case .full: fullHolds[beat] ?? 0
        case .standard: (fullHolds[beat] ?? 0) * standardScale
        case .short: shortHolds[beat] ?? 0
        }
    }

    // MARK: - Lines

    private static func line(for beat: Beat, facts: PreparationFacts) -> String {
        let owner = SeriesCopy.genitive(facts.childName)
        switch beat {
        case .openBook:
            return "Ragi, \(owner) masal defterini açıyor."
        case .cast:
            let names = castNames(facts)
            return names.count == 1
                ? "Masalın kahramanı \(facts.childName)."
                : "Masalda \(listed(names)) var."
        case .ageFit:
            // Yaş sayısı yazılmaz: sunulan bant istenenden farklı olabilir.
            return "\(owner) yaşına göre kelimeler seçiliyor."
        case .modeTouch:
            return modeLine(facts) ?? ""
        case .writing:
            return "Sayfalar yazılıyor · \(facts.pageCount) sayfa"
        case .reread:
            return "Ragi masalı bir kez daha okuyor."
        case .bind:
            return facts.storyOrdinal <= 1
                ? "\(owner) ilk masalı hazır."
                : "\(owner) \(facts.storyOrdinal). masalı hazır."
        }
    }

    // MARK: - Notebook

    /// A mark a step leaves in the notebook, so the page fills as the story
    /// is made instead of the screen standing still for fifteen seconds.
    struct Note: Equatable {
        /// `MPIcon` name.
        let icon: String
        let text: String
    }

    /// "Ela'nın masal defteri", the notebook's running head.
    static func notebookTitle(_ facts: PreparationFacts) -> String {
        "\(SeriesCopy.genitive(facts.childName)) masal defteri"
    }

    /// "No. 3": the story's place in the child's shelf.
    static func shelfNumber(_ facts: PreparationFacts) -> String {
        "No. \(max(facts.storyOrdinal, 1))"
    }

    /// The note a step leaves; nil for steps whose trace is the page itself
    /// (the cast tags, the inked sentence, the cover).
    static func note(for beat: Beat, facts: PreparationFacts) -> Note? {
        switch beat {
        case .ageFit:
            return Note(icon: "textformat.size", text: "Yaşına uygun kelimeler")
        case .modeTouch:
            switch facts.mode {
            case .bedtime: return Note(icon: "moon", text: "Yumuşak bir son")
            case .learning: return Note(icon: "sparkles", text: facts.hasNewWord ? "Yeni bir kelime" : "Bir keşif")
            case .adventure: return Note(icon: "map", text: "Bir macera yolu")
            case nil: return nil
            }
        case .reread:
            return Note(icon: "checkmark.shield", text: "Ragi okudu")
        case .openBook, .cast, .writing, .bind:
            return nil
        }
    }

    /// Only for modes the story actually has; older stories carry none.
    private static func modeLine(_ facts: PreparationFacts) -> String? {
        switch facts.mode {
        case .bedtime: "Uyku için yumuşak bir son yazılıyor."
        case .learning: facts.hasNewWord ? "Masala yeni bir kelime saklanıyor." : "Masala bir keşif saklanıyor."
        case .adventure: "Macera için bir yol çiziliyor."
        case nil: nil
        }
    }

    /// The child first, then the companion ("tilki Tarçın"), then Masal ailem.
    static func castNames(_ facts: PreparationFacts) -> [String] {
        var names = [facts.childName]
        if let companion = facts.companion {
            names.append(companion.kind.isEmpty ? companion.name : "\(companion.kind) \(companion.name)")
        }
        if let family = facts.familyName, !family.isEmpty { names.append(family) }
        return names
    }

    /// "Ela", "Ela ve Mia", "Ela, tilki Tarçın ve Mia".
    static func listed(_ names: [String]) -> String {
        guard let last = names.last else { return "" }
        guard names.count > 1 else { return last }
        return names.dropLast().joined(separator: ", ") + " ve " + last
    }

    /// The story's first sentence, as it will be read. Cut at a word with "…"
    /// when it runs long.
    static func firstSentence(of text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var sentence = trimmed
        if let end = trimmed.firstIndex(where: { ".!?".contains($0) }) {
            sentence = String(trimmed[...end])
        }
        guard sentence.count > firstSentenceLimit else { return sentence }
        let head = sentence.prefix(firstSentenceLimit)
        let cut = head.lastIndex(of: " ").map { head[..<$0] } ?? head
        return cut.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces)) + "…"
    }
}

/// What the preparation screen knows about the story it is showing. Gathered
/// outside the view from the built story, the catalog and the library.
struct PreparationFacts: Equatable {
    struct Companion: Equatable {
        let name: String
        /// Catalog type, "tilki". May be empty.
        let kind: String
    }

    let childName: String
    let companion: Companion?
    /// Masal ailem character, as the parent named it.
    let familyName: String?
    let mode: StoryMode?
    let hasNewWord: Bool
    let firstSentence: String
    let pageCount: Int
    /// This child's how-manyth story, counting this one.
    let storyOrdinal: Int
    let isFirstRun: Bool
    let isBedtime: Bool
}

extension PreparationFacts {
    /// Facts from a story just built. `companion` and `familyName` are looked
    /// up by the caller (catalog, Masal ailem); `ordinal` from the library.
    init(story: Story, childName: String, companion: Companion?, familyName: String?,
         ordinal: Int, isFirstRun: Bool, isBedtime: Bool) {
        self.init(
            childName: childName,
            companion: companion,
            familyName: familyName,
            mode: story.origin?.mode,
            hasNewWord: story.pages.contains { !($0.words ?? []).isEmpty },
            firstSentence: StoryPreparationScript.firstSentence(of: story.pages.first?.text ?? ""),
            pageCount: story.pages.count,
            storyOrdinal: max(ordinal, 1),
            isFirstRun: isFirstRun,
            isBedtime: isBedtime
        )
    }
}
