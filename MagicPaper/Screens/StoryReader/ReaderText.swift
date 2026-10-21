import Foundation
import NaturalLanguage

/// Masal metninin sayfada nasıl dizileceği (21 Ekim 2026).
///
/// Erken okuma kitaplarındaki gibi: 3-6 yaşta her cümle kendi satırında
/// ("nefes satırları"), 7-10 yaşta kısa paragraflar ve sesli okurken cümle
/// takibi. Bant masalın yazıldığı yaştan gelir (`Story.ageBand`); bandı
/// olmayan eski masal paragraf düzeninde açılır.
enum ReaderTextLayout: Equatable {
    case breath
    case paragraphs

    init(ageBand: String?) {
        // "5-6" → alt sınır 5. Okunamayan bant paragraf düzenine düşer.
        let lower = ageBand?.split(separator: "-").first.flatMap { Int($0) }
        self = (lower ?? 7) <= 6 ? .breath : .paragraphs
    }
}

/// Sesli okumada o an okunan cümle: hangi paragrafta ve paragrafın içinde
/// hangi UTF-16 aralığında.
struct ReadAlongMark: Equatable {
    let paragraph: Int
    let start: Int
    let end: Int
}

/// Metnin ölçülen, test edilebilir parçaları. Görünüm burada karar vermez;
/// yalnızca bu cevapları boyar.
enum ReaderText {

    private static let locale = Locale(identifier: "tr_TR")

    // MARK: - Cümleler

    /// Paragrafın cümleleri, UTF-16 aralıkları olarak. Boşluklar cümleye
    /// dahil edilmez.
    static func sentenceRanges(in paragraph: String) -> [Range<Int>] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = paragraph
        tokenizer.setLanguage(.turkish)
        var out: [Range<Int>] = []
        tokenizer.enumerateTokens(in: paragraph.startIndex..<paragraph.endIndex) { range, _ in
            var r = range
            while r.lowerBound < r.upperBound, paragraph[paragraph.index(before: r.upperBound)].isWhitespace {
                r = r.lowerBound..<paragraph.index(before: r.upperBound)
            }
            let ns = NSRange(r, in: paragraph)
            guard ns.length > 0 else { return true }
            // Küçük harfle başlayan parça önceki cümlenin devamıdır:
            // "“Gerçekten mi?” dedi Deniz." tek satır kalır.
            if let last = out.last, paragraph[r].first?.isLowercase == true {
                out[out.count - 1] = last.lowerBound..<(ns.location + ns.length)
            } else {
                out.append(ns.location..<(ns.location + ns.length))
            }
            return true
        }
        return out.isEmpty && !paragraph.isEmpty ? [0..<(paragraph as NSString).length] : out
    }

    /// Nefes satırları: her paragrafın cümleleri ayrı satır.
    static func breathLines(of paragraphs: [String]) -> [[String]] {
        paragraphs.map { paragraph in
            let ns = paragraph as NSString
            return sentenceRanges(in: paragraph).map { ns.substring(with: NSRange(location: $0.lowerBound, length: $0.count)) }
        }
    }

    // MARK: - Sesli okuma

    /// Okunan karakterin (`MPSpeech`, sayfa metninin `"\n\n"` ile birleşmiş
    /// hâlinde UTF-16 konumu) düştüğü cümle. Konum metnin dışındaysa `nil`.
    static func readAlongMark(paragraphs: [String], spokenLocation: Int) -> ReadAlongMark? {
        var offset = 0
        for (i, paragraph) in paragraphs.enumerated() {
            let length = (paragraph as NSString).length
            if spokenLocation >= offset && spokenLocation < offset + length {
                let local = spokenLocation - offset
                let sentence = sentenceRanges(in: paragraph).first { $0.contains(local) }
                    ?? (local..<min(length, local + 1))
                return ReadAlongMark(paragraph: i, start: sentence.lowerBound, end: sentence.upperBound)
            }
            offset += length + 2   // "\n\n"
        }
        return nil
    }

    /// Paragraf bir konuşmayla mı başlıyor (tırnak ya da konuşma çizgisi).
    static func isDialogue(_ paragraph: String) -> Bool {
        guard let first = paragraph.trimmingCharacters(in: .whitespaces).first else { return false }
        return ["\"", "\u{201C}", "\u{00AB}", "\u{2014}", "\u{2013}", "-"].contains(first)
    }

    // MARK: - Çocuğun adı

    /// Çocuğun adının paragraftaki geçişleri. Ad bir kelimenin parçasıysa
    /// sayılmaz ("Can" "Canavar"da işaretlenmez); kesme işaretli ek
    /// ("Deniz'in") adın dışında kalır.
    static func nameRanges(of name: String, in text: String) -> [Range<String.Index>] {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return [] }
        var out: [Range<String.Index>] = []
        var searchStart = text.startIndex
        while let r = text.range(of: name, options: [.caseInsensitive], range: searchStart..<text.endIndex, locale: locale) {
            let before = r.lowerBound > text.startIndex ? text[text.index(before: r.lowerBound)] : " "
            let after = r.upperBound < text.endIndex ? text[r.upperBound] : " "
            if !before.isLetter && !after.isLetter { out.append(r) }
            searchStart = r.upperBound
        }
        return out
    }

    // MARK: - Ses kelimeleri

    /// Masallarda geçen yansıma sesler. Türkçede çoğu ikilenir ("pıt pıt",
    /// "şırıl şırıl"); her biri ayrı ayrı işaretlenir. Listede olmayan kelime
    /// sıradan metin kalır: yanlış bir kelimeyi süslemektense birini
    /// kaçırmak iyidir.
    static let soundWords: Set<String> = [
        "pıt", "pıtır", "tık", "tıkır", "tak", "şırıl", "mırıl", "fısıl", "hışır", "çıt",
        "pat", "güm", "küt", "şap", "şıp", "vızır", "vız", "fış", "fıs", "cik", "cik-cik",
        "cıvıl", "hav", "miyav", "mö", "mee", "vak", "üü", "uu", "horul", "gıcır", "lıkır",
        "fokur", "zıp", "hop", "vın", "pır", "çat", "şakır", "takır", "şırak", "dıt", "bip",
        "çiş", "hapşu", "hoşt", "vınn", "pof", "puf", "şlap", "zınk", "tırıl", "kıpır",
    ]

    /// Paragraftaki ses kelimelerinin aralıkları.
    static func soundRanges(in text: String) -> [Range<String.Index>] {
        var out: [Range<String.Index>] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { word, range, _, _ in
            guard let word else { return }
            if soundWords.contains(word.lowercased(with: locale)) { out.append(range) }
        }
        return out
    }
}
