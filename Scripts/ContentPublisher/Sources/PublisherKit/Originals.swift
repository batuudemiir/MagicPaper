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
    static let bannedPattern = #"\b(anında|saniyeler içinde)\b|\b[Üü]ret|\b[Oo]luştur|[Yy]apay zeka"#

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
        if text.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation || $0.value == 0xFE0F }) { problems.append("emoji var") }

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
                inside = line.trimmingCharacters(in: .whitespacesAndNewlines) == "## Karakterler"
                continue
            }
            if inside, line.hasPrefix("### ") {
                names.insert(String(line.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return names
    }
}

/// Yayımlanmış ya da onay bekleyen bir masal, kapağıyla.
public struct OriginalEntry {
    public let tale: OriginalFile
    public let cover: Data
}

/// `Content/Originals` üzerindeki işler. Ajan yalnız `check` çalıştırır;
/// `approve` ve yayın Batuhan'ındır.
public enum OriginalLibrary {

    static func knownCharacters(repo: Repo) -> Set<String>? {
        guard let text = try? String(contentsOf: repo.world, encoding: .utf8) else { return nil }
        return WorldBook.characters(in: text)
    }

    /// Bir klasördeki masalın sorunları; boşsa geçer.
    static func problems(in folder: URL, known: Set<String>?) -> [String] {
        guard let known else { return ["WORLD.md yok: önce dünya kitabı (Content/Originals/README.md)"] }
        let tale: OriginalFile
        do {
            tale = try JSONDecoder().decode(OriginalFile.self, from: Data(contentsOf: folder.appendingPathComponent("tale.json")))
        } catch {
            return ["tale.json okunamadı: \(error)"]
        }
        let cover = try? Data(contentsOf: folder.appendingPathComponent("cover.jpg"))
        return tale.problems(folder: folder.lastPathComponent, characters: known, cover: cover)
    }

    static func isValidSlug(_ slug: String) -> Bool {
        slug.range(of: #"^[a-z0-9]+(-[a-z0-9]+)*$"#, options: .regularExpression) != nil
    }

    /// `drafts/<slug>`'ı denetler.
    public static func check(slug: String, repo: Repo) -> [String] {
        guard isValidSlug(slug) else { return ["geçersiz slug: \(slug)"] }
        return problems(in: repo.originalDrafts.appendingPathComponent(slug), known: knownCharacters(repo: repo))
    }

    /// Tüm taslakların sorunları, klasör adıyla.
    public static func checkAllDrafts(repo: Repo) -> [String] {
        let known = knownCharacters(repo: repo)
        return folders(in: repo.originalDrafts).flatMap { folder in
            problems(in: folder, known: known).map { "\(folder.lastPathComponent): \($0)" }
        }
    }

    /// Yayımlanmış masalların hepsi, denetlenmiş. Biri bile bozuksa hiçbiri.
    public static func loadPublished(repo: Repo) throws -> [OriginalEntry] {
        let known = knownCharacters(repo: repo)
        var entries: [OriginalEntry] = []
        var problems: [String] = []
        for folder in folders(in: repo.originalsPublished) {
            let found = Self.problems(in: folder, known: known)
            guard found.isEmpty,
                  let tale = try? JSONDecoder().decode(OriginalFile.self, from: Data(contentsOf: folder.appendingPathComponent("tale.json"))),
                  let cover = try? Data(contentsOf: folder.appendingPathComponent("cover.jpg")) else {
                problems += found.map { "\(folder.lastPathComponent): \($0)" }
                continue
            }
            entries.append(OriginalEntry(tale: tale, cover: cover))
        }
        var ids: Set<String> = []
        for entry in entries where !ids.insert(entry.tale.id.uppercased()).inserted {
            problems.append("\(entry.tale.slug): id başka bir Original ile aynı")
        }
        guard problems.isEmpty else { throw PublishError.invalid(problems) }
        return entries
    }

    /// `drafts/<slug>` → `published/<slug>`: önce kopyalanır, yalnız `tale.json` ve `cover.jpg`.
    /// `review.md` taşınmaz; git geçmişinde kalır.
    public static func approve(slug: String, repo: Repo, log: (String) -> Void = { print($0) }) throws {
        guard isValidSlug(slug) else { throw PublishError.message("geçersiz slug: \(slug)") }
        let draft = repo.originalDrafts.appendingPathComponent(slug)
        let found = check(slug: slug, repo: repo)
        guard found.isEmpty else { throw PublishError.invalid(found) }
        let target = repo.originalsPublished.appendingPathComponent(slug)
        guard !FileManager.default.fileExists(atPath: target.path) else {
            throw PublishError.message("published/\(slug) zaten var.")
        }
        let tale = try JSONDecoder().decode(OriginalFile.self, from: Data(contentsOf: draft.appendingPathComponent("tale.json")))
        let published = try loadPublished(repo: repo)
        if published.contains(where: { $0.tale.id.uppercased() == tale.id.uppercased() }) {
            throw PublishError.message("\(slug): id yayımlanmış bir Original ile aynı.")
        }
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        do {
            for name in ["tale.json", "cover.jpg"] {
                try FileManager.default.copyItem(at: draft.appendingPathComponent(name), to: target.appendingPathComponent(name))
            }
        } catch {
            try? FileManager.default.removeItem(at: target)
            throw error
        }
        try FileManager.default.removeItem(at: draft)
        log("Onaylandı: \(tale.title) (published/\(slug)). Yayın: `content-publisher publish --deploy`.")
    }

    static func folders(in directory: URL) -> [URL] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.sorted().map { directory.appendingPathComponent($0) }.filter {
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }
}
