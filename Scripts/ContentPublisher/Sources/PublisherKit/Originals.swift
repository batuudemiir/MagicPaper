import Foundation

/// Kapağın akıştaki yeri ve özeti. İmza akışın tamamını kapsadığı için
/// özet de imzalıdır: özeti tutmayan kapak yayımlanan kapak değildir.
public struct CoverReference: Codable, Equatable {
    public let path: String
    public let sha256: String

    public init(path: String, sha256: String) {
        self.path = path
        self.sha256 = sha256
    }
}

/// Bir MagicPaper Original masalı: `Content/Originals/<drafts|published>/<slug>/tale.json`.
/// Uygulamanın `FeedOriginal`'ı ile aynı alanlar. İkisini birlikte değiştirin.
public struct OriginalFile: Codable, Equatable {
    public let id: String
    public let slug: String
    public let title: String
    /// `bedtime` | `learning` | `adventure`
    public let mode: String
    public let ageMin: Int
    public let ageMax: Int
    public let minutes: Int
    public let summary: String
    public let characters: [String]
    public let pages: [String]
    public let publishDate: String
    /// Kaynak dosyada yok; yayıncı akışa yazarken doldurur.
    public var cover: CoverReference?

    public static let modes: Set<String> = ["bedtime", "learning", "adventure"]
    public static let maxCoverBytes = 1_500_000
    public static let minPages = 3

    public var words: Int { pages.reduce(0) { $0 + Self.wordCount($1) } }

    static func wordCount(_ text: String) -> Int { text.split(whereSeparator: \.isWhitespace).count }

    /// Sayfa başına kelime aralığı (`Content/Classics/WRITING_BRIEF.md`).
    public var wordsPerPage: ClosedRange<Int> { ageMin <= 4 ? 25...45 : 40...80 }

    /// CLAUDE.md "Dil": masal yazılır, üretilmez; hız ve yapay zeka anlatılmaz.
    static let bannedPattern = "[Üü]ret|[Oo]luştur|saniyeler içinde|anında|[Yy]apay zeka"

    /// Yazara Türkçe, her sorun ayrı satır. Boşsa masal yayımlanabilir.
    public func problems(folder: String, characters known: Set<String>, cover: Data?) -> [String] {
        var problems: [String] = []
        if UUID(uuidString: id) == nil { problems.append("id bir UUID değil") }
        if slug.range(of: #"^[a-z0-9]+(-[a-z0-9]+)*$"#, options: .regularExpression) == nil {
            problems.append("slug yalnız küçük harf, rakam ve tire olmalı: \(slug)")
        }
        if slug != folder { problems.append("slug (\(slug)) klasör adıyla (\(folder)) aynı değil") }
        for (name, text) in [("title", title), ("summary", summary)]
        where text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("\(name) boş")
        }
        if !Self.modes.contains(mode) { problems.append("bilinmeyen mod: \(mode)") }
        if !(3...10).contains(ageMin) || !(3...10).contains(ageMax) || ageMin > ageMax {
            problems.append("yaş aralığı 3-10 içinde ve küçükten büyüğe olmalı: \(ageMin)-\(ageMax)")
        }
        if !StoryFile.isDay(publishDate) { problems.append("publishDate yyyy-MM-dd değil: \(publishDate)") }

        if pages.count < Self.minPages { problems.append("en az \(Self.minPages) sayfa olmalı, \(pages.count) var") }
        for (index, page) in pages.enumerated() {
            let count = Self.wordCount(page)
            if !wordsPerPage.contains(count) {
                problems.append("\(index + 1). sayfa \(count) kelime (\(wordsPerPage.lowerBound)-\(wordsPerPage.upperBound) olmalı)")
            }
            if page.components(separatedBy: "\n\n").count > 3 {
                problems.append("\(index + 1). sayfada 3'ten fazla paragraf var")
            }
        }
        let expected = Int((Double(words) / 40).rounded(.up))
        if minutes != expected { problems.append("minutes \(minutes), kelime sayısına göre \(expected) olmalı") }

        if characters.isEmpty { problems.append("characters boş") }
        for name in characters where !known.contains(name) {
            problems.append("WORLD.md'de olmayan karakter: \(name)")
        }

        let text = ([title, summary] + pages).joined(separator: "\n")
        if text.contains("\u{2014}") { problems.append("uzun tire (—) var") }
        if text.contains("{{") { problems.append("doldurulmamış yer tutucu var") }
        if let match = text.range(of: Self.bannedPattern, options: .regularExpression) {
            problems.append("dil kuralı: \"\(text[match])\" geçiyor (CLAUDE.md Dil)")
        }
        if text.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) { problems.append("emoji var") }

        if let cover {
            if cover.count > Self.maxCoverBytes { problems.append("kapak \(cover.count / 1024) KB, en çok 1500 KB") }
            if !cover.starts(with: [0xFF, 0xD8]) { problems.append("kapak JPEG değil") }
        } else {
            problems.append("kapak yok (cover.jpg)")
        }
        return problems
    }
}

/// `Content/Originals/WORLD.md`: markanın kanonu. Karakterler "## Karakterler"
/// altında birer "### Ad" başlığıdır; doğrulama adları buradan okur.
public enum WorldBook {
    public static func characters(in text: String) -> Set<String> {
        var inside = false
        var names: Set<String> = []
        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("## ") {
                inside = line.trimmingCharacters(in: .whitespaces) == "## Karakterler"
                continue
            }
            if inside, line.hasPrefix("### ") {
                names.insert(String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces))
            }
        }
        return names
    }
}
