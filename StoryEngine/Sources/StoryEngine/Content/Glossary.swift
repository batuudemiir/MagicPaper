import Foundation

/// One word a story can teach, with what it means (FAZ 17, "Yeni kelimeler").
///
/// Authored data: a line names the entry it teaches (`CatalogVariant.words`)
/// and the reader highlights the word where the line puts it. Nothing guesses
/// which words are new to a child; an author decided this one is worth a
/// sentence of explanation for this band.
public struct CatalogGlossaryEntry: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// The word as a child would look it up, e.g. "fener".
    public let term: String
    /// Beginnings the word takes in running text, lowercased. Turkish adds
    /// suffixes, so "fener" is found in "fenerini" and highlighted to the end
    /// of that word. Defaults to the term; a stem that changes when inflected
    /// ("ağaç" → "ağacı") lists both.
    public let forms: [String]
    /// One sentence a five-year-old can follow, e.g. "Karanlıkta yolu
    /// aydınlatan, elde taşınan küçük ışık."
    public let meaning: String
    /// Bands the meaning is written for. Empty means every band.
    public let bands: [AgeBand]

    private enum CodingKeys: String, CodingKey { case id, term, forms, meaning, bands }

    public init(id: ContentID, term: String, forms: [String] = [], meaning: String, bands: [AgeBand] = []) {
        self.id = id
        self.term = term
        self.forms = forms.isEmpty ? [term] : forms
        self.meaning = meaning
        self.bands = bands
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        term = try container.decode(String.self, forKey: .term)
        let declared = try container.decodeIfPresent([String].self, forKey: .forms) ?? []
        forms = declared.isEmpty ? [term] : declared
        meaning = try container.decode(String.self, forKey: .meaning)
        bands = try container.decodeIfPresent([AgeBand].self, forKey: .bands) ?? []
    }

    public func suits(band: AgeBand?) -> Bool {
        guard let band, !bands.isEmpty else { return true }
        return bands.contains(band)
    }
}

/// A taught word as it landed on a composed page.
///
/// Offsets count `Character`s in the page text, the unit a reader can index
/// an `AttributedString` by without caring how the text is encoded.
public struct PageWord: Sendable, Hashable, Codable {
    public let glossaryID: ContentID
    public let term: String
    public let meaning: String
    /// Where the word starts in `ComposedPage.text`.
    public let start: Int
    /// How many characters it spans, suffixes included.
    public let length: Int

    public init(glossaryID: ContentID, term: String, meaning: String, start: Int, length: Int) {
        self.glossaryID = glossaryID
        self.term = term
        self.meaning = meaning
        self.start = start
        self.length = length
    }
}

enum GlossaryMatcher {
    private static let locale = Locale(identifier: "tr_TR")

    /// Where an entry's word sits in one rendered sentence, as a character
    /// offset and length within that sentence. The first match at the start
    /// of a word wins; the match runs on to the end of that word so the
    /// suffix is highlighted with it. Nil when the sentence does not hold it,
    /// which the integrity check reports for the authored text.
    static func locate(_ entry: CatalogGlossaryEntry, in sentence: String) -> (start: Int, length: Int)? {
        let characters = Array(sentence)
        let folded = characters.map { String($0).lowercased(with: locale) }
        // Longest form first, so "ağacı" is preferred over "ağaç" when both fit.
        let forms = entry.forms
            .map { Array($0.lowercased(with: locale)).map(String.init) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
        for start in characters.indices {
            if start > 0, characters[start - 1].isLetter { continue }
            for form in forms where start + form.count <= characters.count {
                guard Array(folded[start..<(start + form.count)]) == form else { continue }
                var end = start + form.count
                while end < characters.count, characters[end].isLetter { end += 1 }
                return (start, end - start)
            }
        }
        return nil
    }
}
