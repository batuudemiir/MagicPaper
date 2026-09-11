import Foundation

/// The closed set of appearance facts the engine may state about a character.
///
/// Closed on purpose: anything the story or an illustration says about how a
/// child looks has to map to one of these, and has to have come from the
/// Character Engine. There is no "other" case, because "other" is where
/// invented details would hide.
public enum DescriptorCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case hair
    case eyes
    case skinTone
    case build
    case height
    case distinguishingFeature
    case clothingDefault
    case accessory
}

/// Where a descriptor came from. Photo-derived descriptors carry a confidence
/// the extraction port sets; parent-provided ones are authoritative.
public enum DescriptorSource: String, Codable, Sendable, Hashable {
    case photoDerived
    case parentProvided
    case defaulted
}

/// One controlled appearance fact, e.g. `.hair` / "curly black hair".
///
/// `value` is a short phrase, not free prose: it is matched against
/// `DescriptorLexicon` vocabulary, and it is what gets compiled into image
/// prompts verbatim.
public struct CharacterDescriptor: Codable, Sendable, Hashable {
    public let category: DescriptorCategory
    public let value: String
    public let confidence: Double
    public let source: DescriptorSource

    public init(category: DescriptorCategory, value: String, confidence: Double = 1.0, source: DescriptorSource = .parentProvided) {
        self.category = category
        self.value = value
        self.confidence = min(max(confidence, 0), 1)
        self.source = source
    }

    /// Lowercased, diacritic-folded form used for every comparison.
    public var normalizedValue: String { DescriptorNormalization.normalize(value) }
}

/// Shared normalization so the lexicon, the validators and the prompt compiler
/// all agree on what "the same phrase" means.
public enum DescriptorNormalization {
    /// Turkish's dotted/dotless i pair is not a diacritic, so folding leaves
    /// "ı" alone while case-folding turns "I" into "i" — which would make
    /// "SARI" and "sarı" normalize differently. Mapping the pair explicitly,
    /// before folding, keeps every form of a Turkish word comparable.
    private static let turkishDottedIPairs: [(String, String)] = [
        ("\u{0131}", "i"),  // ı  dotless small i
        ("\u{0130}", "i")   // İ  dotted capital I
    ]

    public static func normalize(_ text: String) -> String {
        var value = text
        for (source, replacement) in turkishDottedIPairs {
            value = value.replacingOccurrences(of: source, with: replacement)
        }
        return value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
