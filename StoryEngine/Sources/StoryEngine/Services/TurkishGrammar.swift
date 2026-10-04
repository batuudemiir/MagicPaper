import Foundation

// MARK: - Case

/// The Turkish grammatical cases story text needs.
///
/// Templates are authored with a suffix *spelling* after a slot
/// (`{{setting.name}}'nde`). Spellings are unreliable — the author has to guess
/// the stem's vowel harmony and buffer consonants before knowing which setting
/// will be substituted, and cannot. So a spelling is only ever read as a
/// *request for a case*; the correct surface form is computed here from the
/// word that actually arrives.
///
/// That inversion is the whole point: `'nde`, `'nda`, `'da`, `'de`, `'ta` and
/// `'te` all mean "locative", and a mis-authored one is corrected rather than
/// passed through.
public enum TurkishCase: String, Codable, Sendable, Hashable, CaseIterable {
    /// -in / -ın / -un / -ün — "Yeliz'in"
    case genitive
    /// -e / -a — "Yeliz'e"
    case dative
    /// -i / -ı / -u / -ü — "Yeliz'i"
    case accusative
    /// -de / -da / -te / -ta — "Yeliz'de"
    case locative
    /// -den / -dan / -ten / -tan — "Yeliz'den"
    case ablative

    /// Every spelling an author might reasonably write for this case,
    /// including the buffered forms that are only correct after a
    /// possessive stem.
    static let spellings: [String: TurkishCase] = {
        var map: [String: TurkishCase] = [:]
        func add(_ forms: [String], _ value: TurkishCase) {
            for form in forms { map[form] = value }
        }
        add(["in", "ın", "un", "ün", "nin", "nın", "nun", "nün"], .genitive)
        add(["e", "a", "ye", "ya", "ne", "na"], .dative)
        add(["i", "ı", "u", "ü", "yi", "yı", "yu", "yü", "ni", "nı", "nu", "nü"], .accusative)
        add(["de", "da", "te", "ta", "nde", "nda", "nte", "nta"], .locative)
        add(["den", "dan", "ten", "tan", "nden", "ndan", "nten", "ntan"], .ablative)
        return map
    }()

    /// Reads a requested suffix spelling as a case. Returns nil for anything
    /// that is not a case ending — a copula like `'ydi`, or a typo — so the
    /// caller can report it instead of emitting it verbatim.
    public static func parse(suffixSpelling: String) -> TurkishCase? {
        spellings[normalise(suffixSpelling)]
    }

    /// Strips either apostrophe and lowercases with Turkish rules, so that a
    /// template written `'DA` or `\u{2019}da` reads the same as `'da`.
    /// Turkish casing matters: `I` lowercases to `ı`, not `i`.
    static func normalise(_ spelling: String) -> String {
        spelling
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .lowercased(with: Locale(identifier: "tr_TR"))
    }
}

// MARK: - Suffix request

/// What a suffix spelling in a template is *asking for*.
///
/// Not every ending a template writes is a case. `-ki` is a derivational
/// suffix: it turns a locative into an adjective ("orman" → "ormandaki
/// ışık", *the light in the forest*). Title family `T2_achievement`
/// — *{Child}+GEN {Setting}+LOC+ki {AchievementNoun}* — is built on it, so it
/// has to be expressible; but folding it into `TurkishCase` would be a lie,
/// since the result is no longer a case form and cannot take another one.
public enum TurkishSuffixRequest: Sendable, Hashable {
    /// One of the five case endings.
    case grammaticalCase(TurkishCase)

    /// Locative + the relative `-ki` — "Fısıldayan Orman'daki",
    /// "ormandaki", "Bulut Krallığı'ndaki".
    case locativeRelative

    /// Reads a spelling as a request. Returns nil for anything that is neither
    /// a case ending nor a recognised derivation, so the caller reports it
    /// instead of emitting it verbatim.
    public static func parse(suffixSpelling: String) -> TurkishSuffixRequest? {
        let cleaned = TurkishCase.normalise(suffixSpelling)
        if locativeRelativeSpellings.contains(cleaned) { return .locativeRelative }
        if let value = TurkishCase.spellings[cleaned] { return .grammaticalCase(value) }
        return nil
    }

    /// Every spelling an author might write for locative + `-ki`, including the
    /// buffered forms that only a possessive stem takes.
    ///
    /// `-ki` itself is invariant here. It is one of the few Turkish suffixes
    /// that resists vowel harmony, and in this position the question cannot
    /// even arise: the vowel it follows is the locative's, which is only ever
    /// `a` or `e`. (The harmonised `-kü` exists — "dünkü", "bugünkü" — but only
    /// after a rounded stem vowel, which no locative ending produces.)
    static let locativeRelativeSpellings: Set<String> = [
        "daki", "deki", "taki", "teki",
        "ndaki", "ndeki", "ntaki", "nteki"
    ]
}

// MARK: - Noun

/// A word to be inflected, plus the two things about it that cannot be
/// inferred from its spelling.
public struct TurkishNoun: Sendable, Hashable {
    public let text: String

    /// Proper nouns take an apostrophe before a case ending — "Yeliz'in",
    /// "Fısıldayan Orman'da". Common nouns do not — "tilkiye", "köpeğe".
    ///
    /// The previous implementation emitted an apostrophe unconditionally,
    /// which produced "tilki'ye" wherever a companion *type* was inflected.
    public let isProperNoun: Bool

    /// True when the word already ends in a third-person possessive suffix:
    /// "Bulut Krallığı", "Yıldız İstasyonu", "Ay Yüzeyi", "Mercan Resifi".
    /// Those take a buffer **-n-** before every case ending
    /// ("Bulut Krallığı'nda"), where a plain noun does not
    /// ("Fısıldayan Orman'da").
    ///
    /// This genuinely cannot be inferred: "Karlı Vadi" and "Ay Yüzeyi" both end
    /// in -i and inflect differently. Content must declare it. Four of the
    /// sixteen shipped settings need it, which is why the corpus contains both
    /// correct and incorrect `'nde` spellings — the author generalised from the
    /// subset that happened to be right.
    public let hasPossessiveEnding: Bool

    /// Blocks regular final-consonant softening. Set for loanwords that keep
    /// their hard consonant ("robot" → "robotu", never "robodu") and for
    /// single-syllable words that resist it ("at" → "atı").
    public let blocksSoftening: Bool

    public init(
        _ text: String,
        isProperNoun: Bool,
        hasPossessiveEnding: Bool = false,
        blocksSoftening: Bool = false
    ) {
        self.text = text
        self.isProperNoun = isProperNoun
        self.hasPossessiveEnding = hasPossessiveEnding
        self.blocksSoftening = blocksSoftening
    }
}

// MARK: - Grammar

/// Turkish morphology for the slots story templates actually inflect.
///
/// Scope is deliberate: the five case endings, vowel harmony, buffer
/// consonants, the d/t assimilation and regular final-consonant softening.
/// Not a general morphological analyser.
public enum TurkishGrammar {

    // Uppercase matters here and was wrong before: `I` is the capital of `ı`
    // (back), and `İ` is the capital of `i` (front). The previous table listed
    // `I` as front-unrounded, which flipped harmony for any name typed or
    // stored uppercase.
    // `â`, `î` and `û` (circumflex) appear in names typed by parents — "Kemâl",
    // "Nihâl" — and they mark exactly the palatal sound that takes a front
    // suffix. Left out of the table, they were not vowels at all, so the
    // harmony came from whatever vowel stood before them.
    private static let frontUnrounded: Set<Character> = ["e", "i", "E", "İ", "â", "Â", "î", "Î"]
    private static let frontRounded: Set<Character> = ["ö", "ü", "Ö", "Ü", "û", "Û"]
    private static let backUnrounded: Set<Character> = ["a", "ı", "A", "I"]
    private static let backRounded: Set<Character> = ["o", "u", "O", "U"]

    static let vowels: Set<Character> = frontUnrounded
        .union(frontRounded).union(backUnrounded).union(backRounded)

    /// "fıstıkçı şahap" — the voiceless consonants that turn a following
    /// d into t.
    private static let voiceless: Set<Character> = [
        "p", "ç", "t", "k", "f", "s", "ş", "h",
        "P", "Ç", "T", "K", "F", "S", "Ş", "H"
    ]

    /// Regular final-consonant softening before a vowel-initial suffix.
    private static let softened: [Character: Character] = [
        "p": "b", "ç": "c", "t": "d", "k": "ğ",
        "P": "B", "Ç": "C", "T": "D", "K": "Ğ"
    ]

    private static func lastVowel(of text: String) -> Character? {
        text.reversed().first { vowels.contains($0) }
    }

    /// Names whose last syllable is written with a back vowel but said with a
    /// palatal *l*, so they take front suffixes: "Kemal'e", "Hilal'i".
    ///
    /// Spelling cannot reveal this — "Kemal'e" and "Kartal'a" end alike — so
    /// it is a list, and a short one on purpose: a name goes on it only when
    /// the front form is the standard one. Adding a doubtful name would make a
    /// correct story wrong for every child who has it.
    static let frontHarmonyNames: Set<String> = [
        "kemal", "celal", "cemal", "hilal", "bilal", "nihal", "iclal"
    ]

    /// The vowel suffix harmony follows for this noun.
    private static func harmonyVowel(of noun: TurkishNoun) -> Character {
        if noun.isProperNoun,
           let lastWord = noun.text.split(separator: " ").last,
           frontHarmonyNames.contains(lastWord.lowercased(with: Locale(identifier: "tr_TR"))) {
            return "e"
        }
        return lastVowel(of: noun.text) ?? "a"
    }

    private static func endsWithVowel(_ text: String) -> Bool {
        guard let last = text.last else { return false }
        return vowels.contains(last)
    }

    /// The four-way harmonic vowel (i / ı / u / ü) for genitive and accusative.
    private static func closeVowel(isFront: Bool, isRounded: Bool) -> String {
        switch (isFront, isRounded) {
        case (true, false): return "i"
        case (true, true): return "ü"
        case (false, false): return "ı"
        case (false, true): return "u"
        }
    }

    /// The two-way harmonic vowel (e / a) for dative, locative and ablative.
    private static func openVowel(isFront: Bool) -> String { isFront ? "e" : "a" }

    /// Applies regular softening when the rule holds: a multi-syllable common
    /// noun ending in p/ç/t/k after a vowel, taking a vowel-initial suffix.
    private static func applySoftening(to stem: String, noun: TurkishNoun) -> String {
        guard !noun.isProperNoun, !noun.blocksSoftening else { return stem }
        guard let last = stem.last, let replacement = softened[last] else { return stem }
        // Single-syllable words generally resist softening ("at" → "atı").
        guard stem.filter({ vowels.contains($0) }).count >= 2 else { return stem }
        // The consonant must follow a vowel ("kitap"), not another consonant.
        let beforeLast = stem.dropLast().last
        guard let beforeLast, vowels.contains(beforeLast) else { return stem }
        return stem.dropLast() + String(replacement)
    }

    /// Inflects a noun into a case.
    ///
    /// Assembly order is `stem + apostrophe + buffer + ending`, which is what
    /// puts the apostrophe in the right place for a possessive stem:
    /// "Bulut Krallığı" + locative → "Bulut Krallığı'nda".
    public static func inflect(_ noun: TurkishNoun, into grammaticalCase: TurkishCase) -> String {
        let stem = noun.text
        guard !stem.isEmpty else { return "" }

        let finalVowel = harmonyVowel(of: noun)
        let isFront = frontUnrounded.contains(finalVowel) || frontRounded.contains(finalVowel)
        let isRounded = frontRounded.contains(finalVowel) || backRounded.contains(finalVowel)
        let vowelFinal = endsWithVowel(stem)

        // A stem already carrying a third-person possessive takes -n- before
        // every case ending. Otherwise only the vowel-initial cases need a
        // buffer, and which one depends on the case.
        let buffer: String
        if noun.hasPossessiveEnding {
            buffer = "n"
        } else {
            switch grammaticalCase {
            case .genitive: buffer = vowelFinal ? "n" : ""
            case .dative, .accusative: buffer = vowelFinal ? "y" : ""
            case .locative, .ablative: buffer = ""
            }
        }

        // Softening only applies when the ending actually lands on the final
        // consonant — i.e. a vowel-initial case with no buffer in between.
        let takesVowelInitialEnding: Bool
        switch grammaticalCase {
        case .genitive, .dative, .accusative: takesVowelInitialEnding = true
        case .locative, .ablative: takesVowelInitialEnding = false
        }
        let body = (takesVowelInitialEnding && buffer.isEmpty)
            ? applySoftening(to: stem, noun: noun)
            : stem

        let ending: String
        switch grammaticalCase {
        case .genitive:
            ending = closeVowel(isFront: isFront, isRounded: isRounded) + "n"
        case .dative:
            ending = openVowel(isFront: isFront)
        case .accusative:
            ending = closeVowel(isFront: isFront, isRounded: isRounded)
        case .locative, .ablative:
            // The consonant the ending assimilates to is whatever now precedes
            // it — the buffer if there is one, else the stem's final letter.
            let preceding = buffer.last ?? body.last ?? "a"
            let d = voiceless.contains(preceding) ? "t" : "d"
            let vowel = openVowel(isFront: isFront)
            ending = grammaticalCase == .locative ? d + vowel : d + vowel + "n"
        }

        return body + (noun.isProperNoun ? "'" : "") + buffer + ending
    }

    /// Realises a suffix request on a noun.
    ///
    /// The relative form is built *on top of* the locative rather than beside
    /// it, so it inherits everything the locative already gets right: the
    /// d/t assimilation, the possessive buffer, and the apostrophe placement
    /// that keeps a proper noun readable — "Bulut Krallığı'ndaki", not
    /// "Bulut Krallığıdaki'".
    public static func apply(_ noun: TurkishNoun, _ request: TurkishSuffixRequest) -> String {
        switch request {
        case .grammaticalCase(let value):
            return inflect(noun, into: value)
        case .locativeRelative:
            return inflect(noun, into: .locative) + "ki"
        }
    }
}

// MARK: - Template rendering

/// Renders `{{slot}}` tokens, with optional case suffixes, into Turkish text.
///
/// Replaces the previous `TurkishSuffixResolver`, which had three defects this
/// type is built to make impossible:
///
/// 1. Unknown suffixes were emitted verbatim, so `{{setting.name}}'nde`
///    silently produced "Fısıldayan Orman'nde". Here an unrecognised suffix is
///    *reported*, and a recognised one is recomputed from the actual word.
/// 2. Every inflection got an apostrophe, including common nouns.
/// 3. A missing slot substituted the empty string, quietly deleting the
///    subject of the sentence. Here it is reported.
public enum TurkishTextRenderer {

    /// One substitutable value plus its grammar.
    public struct Slot: Sendable, Hashable {
        public let value: String
        public let isProperNoun: Bool
        public let hasPossessiveEnding: Bool
        public let blocksSoftening: Bool

        public init(
            _ value: String,
            isProperNoun: Bool,
            hasPossessiveEnding: Bool = false,
            blocksSoftening: Bool = false
        ) {
            self.value = value
            self.isProperNoun = isProperNoun
            self.hasPossessiveEnding = hasPossessiveEnding
            self.blocksSoftening = blocksSoftening
        }

        var noun: TurkishNoun {
            TurkishNoun(
                value,
                isProperNoun: isProperNoun,
                hasPossessiveEnding: hasPossessiveEnding,
                blocksSoftening: blocksSoftening
            )
        }
    }

    /// What rendering produced, and everything that went wrong while producing
    /// it. Callers decide whether a defect blocks publication; the renderer
    /// never decides that silently.
    public struct Result: Sendable, Hashable {
        public let text: String
        /// Tokens with no matching slot. The text keeps the raw `{{token}}`
        /// so the failure is visible rather than a hole in the sentence.
        public let missingSlots: [String]
        /// Suffixes that are not case endings. Emitted verbatim after the
        /// value, and reported.
        public let unrecognisedSuffixes: [String]

        public var isClean: Bool { missingSlots.isEmpty && unrecognisedSuffixes.isEmpty }
    }

    // A token, optionally followed by an apostrophe and a suffix. Both the
    // ASCII apostrophe and the typographic one are accepted, because both
    // occur in the authored corpus.
    private static let pattern = "\\{\\{([^}]+)\\}\\}(?:['\u{2019}]([a-zA-ZçğıöşüÇĞİÖŞÜ]+))?"

    /// Punctuation after which the next word begins a sentence.
    private static let sentenceEnders: Set<Character> = [".", "!", "?", ":", "\u{2026}"]

    /// Characters that may sit between the punctuation and the word — an
    /// opening quote does not start a new sentence by itself.
    private static let transparentBeforeWord: Set<Character> = [
        " ", "\n", "\t", "\"", "\u{201C}", "\u{00AB}", "(", "\u{2014}", "-"
    ]

    /// Whether what has been emitted so far leaves the cursor at the start of a
    /// sentence.
    ///
    /// Needed because a slot's value carries the casing of the *content record*,
    /// which is correct in the middle of a sentence and wrong at the beginning:
    /// a discovery named "titrek bir ışık" is a common noun phrase, so
    /// "…ulaştı. titrek bir ışığı gördü" is what a naive substitution produces.
    static func isAtSentenceStart(_ output: String) -> Bool {
        var index = output.endIndex
        while index > output.startIndex {
            let previous = output.index(before: index)
            let character = output[previous]
            if transparentBeforeWord.contains(character) { index = previous; continue }
            return sentenceEnders.contains(character)
        }
        return true
    }

    /// Turkish-locale capitalisation of the first letter only.
    ///
    /// The locale is not optional here: the capital of `i` is `İ`, so
    /// "ince bir ses" must become "İnce bir ses" and never "Ince bir ses".
    static func capitalisingFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased(with: Locale(identifier: "tr_TR")) + text.dropFirst()
    }

    public static func render(_ template: String, slots: [String: Slot]) -> Result {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return Result(text: template, missingSlots: [], unrecognisedSuffixes: [])
        }

        let source = template as NSString
        let matches = regex.matches(
            in: template,
            range: NSRange(location: 0, length: source.length)
        )

        var output = ""
        var missing: [String] = []
        var unrecognised: [String] = []
        var cursor = 0

        // Single forward pass. The previous implementation re-ran the regex
        // over its own output after every replacement, so a substituted value
        // that happened to contain "{{" would be re-substituted.
        for match in matches {
            let whole = match.range(at: 0)
            output += source.substring(with: NSRange(location: cursor, length: whole.location - cursor))
            cursor = whole.location + whole.length

            let key = source.substring(with: match.range(at: 1))
            let suffixRange = match.range(at: 2)
            let suffix = suffixRange.location == NSNotFound
                ? nil
                : source.substring(with: suffixRange)

            guard let slot = slots[key], !slot.value.isEmpty else {
                missing.append(key)
                output += source.substring(with: whole)   // keep it visible
                continue
            }

            let substitution: String
            if let suffix {
                if let request = TurkishSuffixRequest.parse(suffixSpelling: suffix) {
                    substitution = TurkishGrammar.apply(slot.noun, request)
                } else {
                    unrecognised.append(suffix)
                    substitution = slot.value + "'" + suffix
                }
            } else {
                substitution = slot.value
            }

            output += isAtSentenceStart(output)
                ? capitalisingFirstLetter(substitution)
                : substitution
        }

        output += source.substring(from: cursor)
        return Result(text: output, missingSlots: missing, unrecognisedSuffixes: unrecognised)
    }
}
