import Foundation

/// Word and sentence counting used by the segmenter and the validators.
///
/// Centralised so a page's budget is measured exactly the way the validator
/// later checks it — otherwise a page can be segmented "in budget" and then
/// fail validation for being out of it.
public enum TextMetrics {
    public static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }

    public static func wordCount(_ text: String) -> Int { words(text).count }

    private static let terminators: Set<Character> = [".", "!", "?", "\u{2026}"]
    private static let closers: Set<Character> = ["\"", "\u{201D}", "'", "\u{2019}", ")", "]", "\u{00BB}"]

    /// Splits into sentences, keeping punctuation attached.
    ///
    /// Dialogue is the reason this is not a one-line split. In a picture book,
    /// `"Stop!" said Deniz.` is one sentence, not two — so after a terminator
    /// and any closing quotes, a following lowercase word means the sentence is
    /// still going. Getting this wrong would let the segmenter cut a page
    /// between a line of speech and its attribution.
    public static func sentences(_ text: String) -> [String] {
        let characters = Array(text)
        var result: [String] = []
        var current = ""
        var index = 0

        while index < characters.count {
            let character = characters[index]
            current.append(character)
            index += 1

            guard terminators.contains(character) else { continue }

            // Absorb runs of terminators and any closing quotes or brackets.
            while index < characters.count,
                  terminators.contains(characters[index]) || closers.contains(characters[index]) {
                current.append(characters[index])
                index += 1
            }

            // A lowercase word after the punctuation is a speech attribution,
            // so the sentence has not ended.
            var lookahead = index
            while lookahead < characters.count, characters[lookahead].isWhitespace { lookahead += 1 }
            if lookahead < characters.count, characters[lookahead].isLowercase { continue }

            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(trimmed) }
            current = ""
        }

        let trailing = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trailing.isEmpty { result.append(trailing) }
        return result
    }

    public static func longestSentenceWordCount(_ text: String) -> Int {
        sentences(text).map { wordCount($0) }.max() ?? 0
    }

    /// Lowercased n-grams, used for repetition detection.
    public static func nGrams(_ text: String, size: Int) -> [String] {
        guard size > 0 else { return [] }
        let tokens = words(text).map { $0.lowercased() }
        guard tokens.count >= size else { return [] }
        return (0...(tokens.count - size)).map { tokens[$0..<($0 + size)].joined(separator: " ") }
    }

    public static func firstWord(ofSentence sentence: String) -> String? {
        words(sentence).first?.lowercased()
    }
}
