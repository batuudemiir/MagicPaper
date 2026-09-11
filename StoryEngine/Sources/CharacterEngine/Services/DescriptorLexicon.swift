import Foundation

/// An appearance claim found in generated content that the character's identity
/// does not authorize.
public struct LexiconViolation: Sendable, Hashable {
    public let category: DescriptorCategory
    /// The phrase as it appears in the lexicon (normalized form).
    public let phrase: String
    /// What the identity actually authorizes for this category, if anything.
    public let authorized: [String]

    public init(category: DescriptorCategory, phrase: String, authorized: [String]) {
        self.category = category
        self.phrase = phrase
        self.authorized = authorized
    }
}

/// A vocabulary of appearance phrases, per category, in one language.
///
/// Phrase-based rather than word-based on purpose. Matching the bare word
/// "brown" would flag "a brown bear"; matching "brown hair" flags only a claim
/// about the child. That precision is what makes this usable as a hard gate
/// instead of a noisy warning.
public struct DescriptorLexicon: Codable, Sendable {
    public let languageCode: String
    public let phrases: [DescriptorCategory: [String]]
    /// Whether this language glues case/possessive endings onto the words the
    /// lexicon lists. Turkish does — "sarı saç" shows up as "sarı saçı",
    /// "saçları", "saçıyla" — so matching has to tolerate a trailing suffix.
    public let allowsSuffixAttachment: Bool

    /// How many trailing letters may be treated as an inflection. Turkish
    /// suffix chains on a noun are comfortably inside this. Being generous
    /// here risks an occasional false positive, which is the right direction
    /// for a gate whose job is to catch invented appearance claims.
    static let maximumSuffixLength = 6

    public init(languageCode: String, phrases: [DescriptorCategory: [String]], allowsSuffixAttachment: Bool = false) {
        self.languageCode = languageCode
        self.phrases = phrases
        self.allowsSuffixAttachment = allowsSuffixAttachment
    }

    // Dictionaries keyed by an enum do not encode as JSON objects, so the wire
    // format uses an explicit array and the nicer shape is kept for callers.
    private enum CodingKeys: String, CodingKey { case languageCode, entries, allowsSuffixAttachment }
    private struct Entry: Codable { let category: DescriptorCategory; let phrases: [String] }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        allowsSuffixAttachment = try container.decodeIfPresent(Bool.self, forKey: .allowsSuffixAttachment) ?? false
        let entries = try container.decode([Entry].self, forKey: .entries)
        phrases = Dictionary(uniqueKeysWithValues: entries.map { ($0.category, $0.phrases) })
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(allowsSuffixAttachment, forKey: .allowsSuffixAttachment)
        let entries = phrases
            .map { Entry(category: $0.key, phrases: $0.value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
        try container.encode(entries, forKey: .entries)
    }

    /// Every appearance claim in `text` that `identity` does not authorize.
    ///
    /// A found phrase counts as authorized when an authorized phrase for the
    /// same category contains it — "black hair" is fine for a child whose
    /// identity says "curly black hair", while "curly black hair" is not fine
    /// for a child whose identity only says "black hair".
    public func violations(in text: String, authorizedBy identity: CharacterIdentity) -> [LexiconViolation] {
        let haystack = DescriptorNormalization.normalize(text)
        guard !haystack.isEmpty else { return [] }
        let authorizedByCategory = identity.authorizedPhrases
        var found: [LexiconViolation] = []
        var seen: Set<String> = []

        for (category, categoryPhrases) in phrases {
            let authorized = authorizedByCategory[category] ?? []
            for phrase in categoryPhrases {
                let normalizedPhrase = DescriptorNormalization.normalize(phrase)
                guard !normalizedPhrase.isEmpty else { continue }
                guard Self.contains(phrase: normalizedPhrase, in: haystack, allowingSuffix: allowsSuffixAttachment) else { continue }
                guard !authorized.contains(where: { $0.contains(normalizedPhrase) }) else { continue }

                let key = "\(category.rawValue)|\(normalizedPhrase)"
                guard seen.insert(key).inserted else { continue }
                found.append(
                    LexiconViolation(
                        category: category,
                        phrase: normalizedPhrase,
                        authorized: authorized.sorted()
                    )
                )
            }
        }

        return found.sorted { ($0.category.rawValue, $0.phrase) < ($1.category.rawValue, $1.phrase) }
    }

    /// Whole-phrase containment, so "hairy" never matches "hair".
    ///
    /// With `allowingSuffix`, a bounded run of trailing letters is accepted so
    /// agglutinative languages still match their own inflected forms.
    ///
    /// Public because the story validators need exactly this matching for
    /// banned phrases and safety exclusions — two different notions of
    /// "does this text contain that phrase" would eventually disagree.
    public static func contains(phrase: String, in haystack: String, allowingSuffix: Bool = false) -> Bool {
        guard let regex = PhraseRegexCache.shared.regex(for: phrase, allowingSuffix: allowingSuffix) else { return false }
        let range = NSRange(haystack.startIndex..<haystack.endIndex, in: haystack)
        return regex.firstMatch(in: haystack, range: range) != nil
    }
}

/// Compiled patterns, kept between calls.
///
/// A validation pass matches every lexicon phrase against every page and every
/// image prompt — a few hundred phrases times a dozen texts. Recompiling the
/// same patterns each time dominated the runtime of a validation pass.
final class PhraseRegexCache: @unchecked Sendable {
    static let shared = PhraseRegexCache()

    private let lock = NSLock()
    private var cache: [String: NSRegularExpression] = [:]

    func regex(for phrase: String, allowingSuffix: Bool) -> NSRegularExpression? {
        let key = "\(allowingSuffix ? "s" : "-")|\(phrase)"
        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let trailing = allowingSuffix
            ? "\\p{L}{0,\(DescriptorLexicon.maximumSuffixLength)}(?![\\p{L}\\p{N}])"
            : "(?![\\p{L}\\p{N}])"
        let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: phrase) + trailing
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        lock.lock()
        cache[key] = regex
        lock.unlock()
        return regex
    }
}

// MARK: - Built-in vocabularies

extension DescriptorLexicon {
    private struct Bundled: Codable { let lexicons: [DescriptorLexicon] }

    /// Lexicons shipped with the package, keyed by language code.
    public static let builtIn: [String: DescriptorLexicon] = {
        guard
            let url = Bundle.module.url(forResource: "lexicons", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let bundled = try? JSONDecoder().decode(Bundled.self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: bundled.lexicons.map { ($0.languageCode, $0) })
    }()

    /// Lexicon for a language, falling back to English so an unsupported
    /// locale still gets a gate rather than none.
    public static func builtIn(languageCode: String) -> DescriptorLexicon {
        let primary = String(languageCode.prefix(2)).lowercased()
        return builtIn[primary] ?? builtIn["en"] ?? DescriptorLexicon(languageCode: primary, phrases: [:])
    }
}
