import Foundation

/// How a series episode may end (FAZ 13): closed and calm.
///
/// Every episode is a whole story. Its last page leaves nothing open: no
/// question, no "tomorrow", no "suddenly", nothing that asks the child to come
/// back to find out. The next episode opens because a day passed, never
/// because this one stopped on a hook. The list is the product decision of
/// 6 October 2026, kept here as the one copy: the composer filters the last
/// page with it, the composed episode is checked against it, and
/// `validate_beat_corpus.py` holds the same list for the series lines.
///
/// "ama" is deliberately not on it: "yorgundu ama mutluydu" closes a day.
public enum CalmEnding {
    /// Words that, at the start of a word, open a door the page should close.
    /// Matched as prefixes so inflections ("yarına", "birdenbire") count too.
    public static let forbiddenWordPrefixes = ["yarın", "acaba", "birden"]
    /// Phrases matched anywhere in the text.
    public static let forbiddenPhrases = ["?", "sonra ne olacak"]

    /// What makes this text an open ending, empty when it closes.
    public static func violations(in text: String) -> [String] {
        let locale = Locale(identifier: "tr_TR")
        let lowered = text.lowercased(with: locale)
        var found = forbiddenPhrases.filter { lowered.contains($0) }
        let words = lowered.split { !$0.isLetter }.map(String.init)
        for prefix in forbiddenWordPrefixes where words.contains(where: { $0.hasPrefix(prefix) }) {
            found.append(prefix)
        }
        return found
    }

    public static func isCalm(_ text: String) -> Bool { violations(in: text).isEmpty }
}
