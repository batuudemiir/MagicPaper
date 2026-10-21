import Foundation

/// Composes a book title from the blueprint's authored patterns.
///
/// Titles used to be hard-coded strings in the prototype, so every story of a
/// given shape had the same name. A pattern is a template like any other and
/// goes through the same Turkish renderer, which is what makes
/// "Fısıldayan Orman'daki" and "Gece Bahçesi'ndeki" both come out right from one
/// authored line.
///
/// A rendered title is used only when it is also cover-ready (21 Ekim 2026):
/// short enough for the band's cover and free of a repeated word — "Kayıp
/// Kayıp Eldiven" is what a pattern and a discovery's own title can make
/// together, and neither is wrong alone. A title already in the child's
/// library is skipped while another pattern is clean; when every one is used,
/// today's choice stays.
public struct TitleComposer: Sendable {
    public init() {}

    /// Why a rendered title is not put on a cover.
    public enum Defect: String, Sendable, Hashable {
        /// Longer than `maxLength(for:)`.
        case tooLong
        /// The same word twice — "Kayıp Kayıp Eldiven", "Gece Bahçesi'nde Sessiz Gece".
        case repeatedWord
    }

    /// - Parameter avoiding: the child's existing titles. Compared folded
    ///   (`fold`), so case, spacing and the apostrophe's shape do not matter.
    ///   Not part of any seed: an empty set gives exactly the title it gave
    ///   before, and the same set gives the same title every time.
    public func compose(
        blueprint: CatalogBlueprint,
        slots: [String: TurkishTextRenderer.Slot],
        seed: String,
        avoiding: Set<String> = []
    ) -> String {
        let band = blueprint.ageRange

        // Prefer a pattern that renders cleanly. A blueprint may carry a
        // pattern whose slot the bound content does not supply; silently
        // shipping "{{object.name}}" as part of a title is worse than using the
        // next pattern.
        let ordered = Self.rotate(blueprint.titlePatterns, seed: seed, salt: blueprint.id.rawValue)
        let usable = ordered.compactMap { pattern -> String? in
            let rendered = TurkishTextRenderer.render(pattern, slots: slots)
            guard rendered.isClean, Self.defects(of: rendered.text, band: band).isEmpty else { return nil }
            return rendered.text
        }
        guard let today = usable.first else {
            return Self.fallback(slots: slots, band: band)
        }
        guard !avoiding.isEmpty else { return today }
        let used = Set(avoiding.map(Self.fold))
        return usable.first { !used.contains(Self.fold($0)) } ?? today
    }

    // MARK: - Cover-readiness

    /// The longest title a cover takes, in characters. The youngest band's
    /// cover is read aloud by a parent and looked at by the child, so it is
    /// shorter.
    public static func maxLength(for band: AgeBand?) -> Int {
        guard let band else { return 32 }
        return band.upperBound <= 4 ? 26 : 32
    }

    /// What keeps `title` off a cover; empty when nothing does.
    public static func defects(of title: String, band: AgeBand?) -> [Defect] {
        var found: [Defect] = []
        if title.count > maxLength(for: band) { found.append(.tooLong) }
        let words = coverWords(title)
        if Set(words).count != words.count { found.append(.repeatedWord) }
        return found
    }

    /// Whether a pattern opens with the child's name — the shape eleven of
    /// thirteen shipped patterns had, and the reason the titles all looked alike.
    public static func isNameLed(_ pattern: String) -> Bool {
        pattern.trimmingCharacters(in: .whitespaces).hasPrefix("{{child.name}}")
    }

    /// The form two titles are compared in: canonical Unicode, Turkish lower
    /// case (`I` → `ı`, `İ` → `i`), one kind of apostrophe, single spaces.
    /// Dotted and dotless i stay different letters.
    public static func fold(_ title: String) -> String {
        title.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .lowercased(with: turkish)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// The words of a title without their case endings: "Bahçesi'nde" and
    /// "Bahçesi" are one word for the repetition check.
    private static func coverWords(_ title: String) -> [String] {
        fold(title)
            .split(whereSeparator: { $0.isWhitespace })
            .map { word in
                let stem = word.split(separator: "'", maxSplits: 1).first.map(String.init) ?? String(word)
                return stem.trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { !$0.isEmpty }
    }

    private static let turkish = Locale(identifier: "tr_TR")

    // MARK: - Order

    /// Rotates rather than picks, so the fallback order is still deterministic
    /// and still varies between children.
    private static func rotate(_ patterns: [String], seed: String, salt: String) -> [String] {
        guard !patterns.isEmpty else { return [] }
        let start = DeterministicPicker.index(count: patterns.count, seed: seed, salt: salt + ".title")
        return Array(patterns[start...] + patterns[..<start])
    }

    /// Used only when no authored pattern can be rendered. Deliberately plain:
    /// a dull title is recoverable, a broken one is not. Goes through the
    /// renderer too, so the genitive follows the name ("Arda'nın").
    private static func fallback(slots: [String: TurkishTextRenderer.Slot], band: AgeBand) -> String {
        let child = slots["child.name"]?.value ?? ""
        if let setting = slots["setting.name"]?.value, !setting.isEmpty {
            let plain = TurkishTextRenderer.render("{{child.name}} ve {{setting.name}}", slots: slots)
            if plain.isClean, !defects(of: plain.text, band: band).contains(.repeatedWord) {
                return plain.text
            }
        }
        guard !child.isEmpty else { return "Bir Hikâye" }
        return TurkishTextRenderer.render("{{child.name}}'in Hikâyesi", slots: slots).text
    }
}
