# MagicPaper Original Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Masallar sekmesinde "MagicPaper Original" rafı; masallar ve kapakları imzalı uzaktan akışla güncellemesiz gelir, bir ajan haftada iki masal yazıp onaya koyar.

**Architecture:** Mevcut imzalı akış (`feed.json`, FAZ 15) bir `originals` dizisi taşır; her kayıt sayfalı metin ve kapağın yolu + SHA-256'sı. Yayıncı (`Scripts/ContentPublisher`) masalları `Content/Originals/published/`'tan okur, kapakları `hosting/public/content/originals/`'a koyar. Uygulama kapakları indirir, özetini doğrular, masalları `ClassicTale`'e çevirip `ClassicsLibrary`'nin raflarına katar. Ajan yalnızca `Content/Originals/drafts/`'a yazar; onay ve yayın Batuhan'ın komutlarıdır.

**Tech Stack:** Swift 5.9 (SwiftPM PublisherKit, SwiftUI iOS app), XCTest, Python 3 stdlib (kapak aracı), Gemini görsel API, Claude Code ajanı + yerel zamanlanmış görev.

**Spec:** `docs/superpowers/specs/2026-11-12-magicpaper-original-design.md`

---

## Çalışma kuralları (bu plan için)

- **Testler yalnızca plan sonunda bir kez çalışır** (Batuhan tercihi, `test-yalniz-plan-sonunda`). Görevler testleri önce yazar, sonra kodu; çalıştırma Görev 14'te. Ara adımlarda kod okuyarak doğrulanır.
- Checkout paylaşımlı: başka oturumların commit edilmemiş dosyaları var (`classics_catalog.json`, `covers.json`, yeni klasik masallar). **Her commit yalnızca o görevin dosyalarını açık yol vererek ekler.** `git add -A` ya da `git add .` yok. Commit'ten hemen önce `git branch --show-current` → `main`.
- Commit mesajlarının sonu:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  ```
- Uzun tire (—) yok: kodda, yorumda, belgede.
- Uygulama klasörleri Xcode'da senkron grup (`Screens`, `StoryEngineBridge`, `MagicPaperTests`): yeni dosya bu klasörlere konunca projeye kendiliğinden girer, `project.pbxproj` düzenlenmez.

## Dosya haritası

| Dosya | Sorumluluk |
|---|---|
| `Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift` (yeni) | `OriginalFile`, `CoverReference`, kurallar, `WorldBook`, `OriginalLibrary` (check, approve, loadPublished) |
| `Scripts/ContentPublisher/Sources/PublisherKit/Feed.swift` | `FeedFile.originals` |
| `Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift` | `Repo` yolları; `publishFeed` Original'leri ve kapakları yazar |
| `Scripts/ContentPublisher/Sources/content-publisher/main.swift` | `originals check`, `originals approve`; `verify` kapakları da denetler |
| `Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift` (yeni) | Yayıncı testleri |
| `MagicPaper/StoryEngineBridge/RemoteContent/ContentFeed.swift` | `FeedOriginal`, `ContentFeed.originals` |
| `MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentStore.swift` | Kapak dosyaları (`Originals/<slug>.jpg`) |
| `MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentService.swift` | Kapak indirme + doğrulama, `@Published originals` |
| `MagicPaper/Screens/Gunluk/Model/OriginalTales.swift` (yeni) | `FeedOriginal.classicTale`, `OriginalCovers` (dosyadan kapak) |
| `MagicPaper/Screens/Gunluk/Model/ClassicTale.swift` | `ClassicShelf.orijinal`, `creditLine` |
| `MagicPaper/Screens/Gunluk/Model/ClassicsCatalog.swift` | `items(in:)` yeni rafı tanır |
| `MagicPaper/Screens/Gunluk/Model/ClassicsLibrary.swift` | Original'leri raflara katar, `tale(_:)` |
| `MagicPaper/Screens/Gunluk/GunlukComponents.swift` | `ClassicCoverImage` dosyadan kapak |
| `MagicPaper/Screens/Gunluk/GunlukView.swift` | Original bölümü, `.tale` rotası `library.tale` |
| `MagicPaper/Views/LibraryView.swift` | Klasik aramaları `ClassicsLibrary.shared.tale` |
| `MagicPaperTests/RemoteContentTests.swift` | Akış ve kapak testleri |
| `MagicPaperTests/OriginalTalesTests.swift` (yeni) | Çeviri ve kütüphane testleri |
| `Tools/originals_cover.py`, `Tools/test_originals_cover.py` (yeni) | Kapak çizdirme aracı ve testi |
| `Content/Originals/README.md`, `drafts/.gitkeep`, `published/.gitkeep` (yeni) | İş akışı |
| `.claude/agents/original-writer.md` (yeni) | Ajan |
| `docs/REMOTE_CONTENT.md` | Original yayını bölümü |

---

### Task 1: Yayıncı modeli ve kuralları

**Files:**
- Create: `Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift`
- Create: `Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift`

- [ ] **Step 1: Testleri yaz**

`Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift`:

```swift
import XCTest
import CryptoKit
@testable import PublisherKit

final class OriginalsTests: XCTestCase {

    private var temp: URL!
    private let realRepo = try! Repo.find(from: URL(fileURLWithPath: #filePath))
    static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0]) + Data(repeating: 7, count: 64)
    static let world = """
    # Fener Kasabası

    ## Karakterler

    ### Lale
    Deniz feneri bekçisinin kızı.

    ### Pırpır
    Kanadı yamalı bir martı.

    ## Kapak stili
    Guaj, kâğıt dokusu.
    """

    override func setUpWithError() throws {
        temp = FileManager.default.temporaryDirectory.appendingPathComponent("OriginalsTests-\(UUID())")
        let repo = Repo(root: temp)
        try FileManager.default.createDirectory(at: repo.stories, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repo.originalDrafts, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repo.originalsPublished, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: temp.appendingPathComponent("StoryEngine"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: temp.appendingPathComponent("MagicPaper/StoryEngineBridge/RemoteContent"), withIntermediateDirectories: true)
        try Data().write(to: temp.appendingPathComponent("StoryEngine/Package.swift"))
        try Data(Self.world.utf8).write(to: repo.world)
        for name in try FileManager.default.contentsOfDirectory(atPath: realRepo.stories.path) {
            try FileManager.default.copyItem(at: realRepo.stories.appendingPathComponent(name),
                                             to: repo.stories.appendingPathComponent(name))
        }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temp)
    }

    // MARK: - Helpers

    static func page(_ words: Int) -> String { Array(repeating: "Lale", count: words).joined(separator: " ") }

    /// 3 sayfa × 45 kelime = 135 kelime → 4 dk. 5-7 yaş: sayfa 40-80.
    static func tale(_ slug: String = "fener-masali", id: String = UUID().uuidString,
                     _ edit: (inout [String: Any]) -> Void = { _ in }) throws -> OriginalFile {
        var object: [String: Any] = [
            "id": id, "slug": slug, "title": "Fenerin Sesi", "mode": "bedtime",
            "ageMin": 5, "ageMax": 7, "minutes": 4, "summary": "Lale feneri yakar.",
            "characters": ["Lale", "Pırpır"], "pages": [page(45), page(45), page(45)],
            "publishDate": "2026-11-17",
        ]
        edit(&object)
        return try JSONDecoder().decode(OriginalFile.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func writeDraft(_ tale: OriginalFile, cover: Data? = OriginalsTests.jpeg, review: Bool = true) throws {
        let folder = Repo(root: temp).originalDrafts.appendingPathComponent(tale.slug)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(tale).write(to: folder.appendingPathComponent("tale.json"))
        if let cover { try cover.write(to: folder.appendingPathComponent("cover.jpg")) }
        if review { try Data("# İnceleme\n".utf8).write(to: folder.appendingPathComponent("review.md")) }
    }

    private let known: Set<String> = ["Lale", "Pırpır"]

    // MARK: - Rules

    func testAValidTaleHasNoProblems() throws {
        XCTAssertEqual(try Self.tale().problems(folder: "fener-masali", characters: known, cover: Self.jpeg), [])
    }

    func testEachBrokenRuleIsNamed() throws {
        func problems(_ edit: (inout [String: Any]) -> Void, cover: Data? = OriginalsTests.jpeg) throws -> [String] {
            try Self.tale(edit).problems(folder: "fener-masali", characters: known, cover: cover)
        }
        XCTAssertFalse(try problems { $0["id"] = "1" }.isEmpty)
        XCTAssertFalse(try problems { $0["mode"] = "spooky" }.isEmpty)
        XCTAssertFalse(try problems { $0["ageMin"] = 8; $0["ageMax"] = 6 }.isEmpty)
        XCTAssertFalse(try problems { $0["ageMax"] = 12 }.isEmpty)
        XCTAssertFalse(try problems { $0["characters"] = ["Lale", "Ejderha"] }.isEmpty)
        XCTAssertFalse(try problems { $0["minutes"] = 9 }.isEmpty)
        XCTAssertFalse(try problems { $0["pages"] = [Self.page(45), Self.page(45), Self.page(10)] }.isEmpty)
        XCTAssertFalse(try problems { $0["pages"] = [Self.page(45), Self.page(45)] }.isEmpty)
        XCTAssertFalse(try problems { $0["summary"] = "Lale — feneri yakar." }.isEmpty)
        XCTAssertFalse(try problems { $0["summary"] = "Yapay zeka ile yazıldı." }.isEmpty)
        XCTAssertFalse(try problems { $0["summary"] = "Lale feneri yakar 🌙" }.isEmpty)
        XCTAssertFalse(try problems { $0["publishDate"] = "17.11.2026" }.isEmpty)
        XCTAssertFalse(try problems({ _ in }, cover: nil).isEmpty)
        XCTAssertFalse(try problems({ _ in }, cover: Data("PNG".utf8)).isEmpty)
        XCTAssertFalse(try Self.tale().problems(folder: "baska-klasor", characters: known, cover: Self.jpeg).isEmpty)
    }

    func testThreeToFourBandHasShorterPages() throws {
        let short = try Self.tale { $0["ageMin"] = 3; $0["ageMax"] = 4; $0["minutes"] = 3
            $0["pages"] = [Self.page(30), Self.page(30), Self.page(30)] }
        XCTAssertEqual(short.problems(folder: "fener-masali", characters: known, cover: Self.jpeg), [])
        let long = try Self.tale { $0["ageMin"] = 3; $0["ageMax"] = 4 }
        XCTAssertFalse(long.problems(folder: "fener-masali", characters: known, cover: Self.jpeg).isEmpty)
    }

    func testWorldBookReadsCharacterHeadingsOnly() {
        XCTAssertEqual(WorldBook.characters(in: Self.world), ["Lale", "Pırpır"])
        XCTAssertEqual(WorldBook.characters(in: "# Boş\n"), [])
    }
}
```

- [ ] **Step 2: Modeli ve kuralları yaz**

`Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift`:

```swift
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
```

`Repo` yolları Task 2'de; testler derlenmek için Task 2'yi bekler.

- [ ] **Step 3: Kod okuyarak kontrol**

`problems` her test satırındaki düzenlemeye en az bir sorun döndürüyor mu, geçerli masal (3 × 45 kelime, 135 kelime → `ceil(135/40) = 4`) boş mu: satır satır izle. `StoryFile.isDay` `internal static`, aynı modülde: erişilebilir.

- [ ] **Step 4: Commit**

```bash
git add Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift
git commit -m "MagicPaper Original: yayıncı modeli ve kuralları

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Kontrol, onay ve yayımlanmış masalları okuma

**Files:**
- Modify: `Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift` (struct `Repo`)
- Modify: `Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift` (sona ekle)
- Modify: `Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift` (sınıfın sonuna ekle)

- [ ] **Step 1: Testleri ekle**

`OriginalsTests` sınıfının kapanışından önce:

```swift
    // MARK: - Library

    func testCheckReportsADraftsProblems() throws {
        try writeDraft(try Self.tale { $0["characters"] = ["Ejderha"] })
        let problems = OriginalLibrary.check(slug: "fener-masali", repo: Repo(root: temp))
        XCTAssertTrue(problems.contains { $0.contains("Ejderha") })
    }

    func testCheckWithoutAWorldBookFails() throws {
        try FileManager.default.removeItem(at: Repo(root: temp).world)
        try writeDraft(try Self.tale())
        XCTAssertFalse(OriginalLibrary.check(slug: "fener-masali", repo: Repo(root: temp)).isEmpty)
    }

    func testApproveMovesTaleAndCoverButNotTheReview() throws {
        let repo = Repo(root: temp)
        try writeDraft(try Self.tale())
        try OriginalLibrary.approve(slug: "fener-masali", repo: repo)

        let published = repo.originalsPublished.appendingPathComponent("fener-masali")
        XCTAssertTrue(FileManager.default.fileExists(atPath: published.appendingPathComponent("tale.json").path))
        XCTAssertEqual(try Data(contentsOf: published.appendingPathComponent("cover.jpg")), Self.jpeg)
        XCTAssertFalse(FileManager.default.fileExists(atPath: published.appendingPathComponent("review.md").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: repo.originalDrafts.appendingPathComponent("fener-masali").path))
    }

    func testApproveRefusesABrokenDraftAndLeavesItInPlace() throws {
        let repo = Repo(root: temp)
        try writeDraft(try Self.tale(), cover: nil)
        XCTAssertThrowsError(try OriginalLibrary.approve(slug: "fener-masali", repo: repo))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: repo.originalDrafts.appendingPathComponent("fener-masali/tale.json").path))
    }

    func testApproveRefusesAnIDThatIsAlreadyPublished() throws {
        let repo = Repo(root: temp)
        let id = UUID().uuidString
        try writeDraft(try Self.tale("birinci", id: id))
        try OriginalLibrary.approve(slug: "birinci", repo: repo)
        try writeDraft(try Self.tale("ikinci", id: id))
        XCTAssertThrowsError(try OriginalLibrary.approve(slug: "ikinci", repo: repo))
    }

    func testNothingPublishedLoadsAsEmpty() throws {
        try FileManager.default.removeItem(at: Repo(root: temp).originalsPublished)
        XCTAssertEqual(try OriginalLibrary.loadPublished(repo: Repo(root: temp)).count, 0)
    }
```

- [ ] **Step 2: `Repo` yollarını ekle**

`Publisher.swift`, `struct Repo` içinde `public var stories: URL { … }` satırının altına:

```swift
    /// MagicPaper Original (spec 2026-11-12).
    public var originals: URL { root.appendingPathComponent("Content/Originals") }
    public var world: URL { originals.appendingPathComponent("WORLD.md") }
    public var originalDrafts: URL { originals.appendingPathComponent("drafts") }
    public var originalsPublished: URL { originals.appendingPathComponent("published") }
```

ve `public var signature: URL { … }` satırının altına:

```swift
    public var hostedOriginals: URL { content.appendingPathComponent("originals") }
```

- [ ] **Step 3: `OriginalLibrary`'yi yaz**

`Originals.swift` sonuna:

```swift
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

    /// `drafts/<slug>`'ı denetler.
    public static func check(slug: String, repo: Repo) -> [String] {
        problems(in: repo.originalDrafts.appendingPathComponent(slug), known: knownCharacters(repo: repo))
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

    /// `drafts/<slug>` → `published/<slug>`: yalnız `tale.json` ve `cover.jpg`.
    /// `review.md` taşınmaz; git geçmişinde kalır.
    public static func approve(slug: String, repo: Repo, log: (String) -> Void = { print($0) }) throws {
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
        for name in ["tale.json", "cover.jpg"] {
            try FileManager.default.moveItem(at: draft.appendingPathComponent(name), to: target.appendingPathComponent(name))
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
```

- [ ] **Step 4: Kod okuyarak kontrol**

`approve` önce `check` (kapak yoksa fırlatır, taslak yerinde kalır), sonra aynı id kontrolü (ikinci taslak `ikinci` slug'ıyla geçer ama id çakışır → fırlatır). `.gitkeep` dosya olduğu için `folders` onu atlar.

- [ ] **Step 5: Commit**

```bash
git add Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift
git commit -m "MagicPaper Original: taslak denetimi ve onay

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Akış Original'leri ve kapakları taşır

**Files:**
- Modify: `Scripts/ContentPublisher/Sources/PublisherKit/Feed.swift` (`FeedFile`)
- Modify: `Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift` (`publishFeed`)
- Modify: `Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift`

- [ ] **Step 1: Testleri ekle**

```swift
    // MARK: - Feed

    private func publish() throws -> (feed: FeedFile, data: Data, signer: Signer) {
        let signer = Signer(key: Curve25519.Signing.PrivateKey())
        let publisher = Publisher(repo: Repo(root: temp))
        let feed = try publisher.publishFeed(signer: signer, package: .none, today: "2026-11-20", first: true)
        return (feed, try Data(contentsOf: Repo(root: temp).feed), signer)
    }

    func testAFeedWithoutOriginalsHasNoOriginalsKey() throws {
        let (_, data, _) = try publish()
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(object["originals"], "Original yokken akış baytları eskisiyle aynı kalmalı")
    }

    func testPublishedOriginalsGoIntoTheSignedFeedWithTheirCoverDigest() throws {
        let repo = Repo(root: temp)
        try writeDraft(try Self.tale())
        try OriginalLibrary.approve(slug: "fener-masali", repo: repo)

        let (feed, data, signer) = try publish()

        XCTAssertEqual(feed.originals?.map(\.slug), ["fener-masali"])
        let cover = try XCTUnwrap(feed.originals?.first?.cover)
        XCTAssertEqual(cover.path, "originals/fener-masali.jpg")
        XCTAssertEqual(cover.sha256, Digest.sha256(Self.jpeg))
        XCTAssertEqual(try Data(contentsOf: repo.content.appendingPathComponent(cover.path)), Self.jpeg)
        XCTAssertTrue(Signer.verify(try Data(contentsOf: repo.signature), for: data, publicKey: signer.publicKeyBase64))
    }

    func testACoverThatLeftTheFeedIsRemovedFromHosting() throws {
        let repo = Repo(root: temp)
        try FileManager.default.createDirectory(at: repo.hostedOriginals, withIntermediateDirectories: true)
        let stale = repo.hostedOriginals.appendingPathComponent("eski.jpg")
        try Self.jpeg.write(to: stale)
        _ = try publish()
        XCTAssertFalse(FileManager.default.fileExists(atPath: stale.path))
    }
```

- [ ] **Step 2: `FeedFile`'a alan ekle**

`Feed.swift`, `FeedFile` içinde `public var catalogPackage: PackageReference?` satırının altına:

```swift
    /// MagicPaper Original masalları. Yokken `nil`: anahtar hiç yazılmaz ve
    /// Original'siz bir akışın baytları önceki sürümün yazdığıyla aynı kalır.
    public var originals: [OriginalFile]?
```

ve init'i şununla değiştir:

```swift
    public init(feedVersion: Int, publishedAt: String, stories: [StoryFile], catalogPackage: PackageReference?,
                originals: [OriginalFile]? = nil) {
        self.feedVersion = feedVersion
        self.publishedAt = publishedAt
        self.stories = stories
        self.catalogPackage = catalogPackage
        self.originals = originals
    }
```

(Sentezlenen `Encodable` isteğe bağlı alanı `encodeIfPresent` ile yazar: `nil` iken anahtar yok.)

- [ ] **Step 3: `publishFeed` Original'leri yazsın**

`Publisher.swift`, `publishFeed` içinde `let feed = FeedFile(…)` satırını şununla değiştir:

```swift
        let originals = try publishOriginalCovers()
        let feed = FeedFile(feedVersion: (previous?.feedVersion ?? 0) + 1, publishedAt: today,
                            stories: stories, catalogPackage: package,
                            originals: originals.isEmpty ? nil : originals)
```

ve log satırını şununla:

```swift
        log("Akış \(feed.feedVersion) yazıldı: \(stories.count) masal (\(future) ileri tarihli), "
            + "\(originals.count) Original, paket \(package?.version ?? "yok").")
```

`packageReference(path:)` fonksiyonunun üstüne ekle:

```swift
    /// Yayımlanmış Original'lerin kapaklarını `content/originals/`'a yazar,
    /// akıştan çıkanları siler. Akışa girecek kayıtları kapak özetiyle döndürür.
    func publishOriginalCovers() throws -> [OriginalFile] {
        let entries = try OriginalLibrary.loadPublished(repo: repo)
        let folder = repo.hostedOriginals
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let keep = Set(entries.map { "\($0.tale.slug).jpg" })
        for name in (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [] where !keep.contains(name) {
            try FileManager.default.removeItem(at: folder.appendingPathComponent(name))
        }
        return try entries.map { entry in
            let path = "originals/\(entry.tale.slug).jpg"
            try entry.cover.write(to: repo.content.appendingPathComponent(path), options: .atomic)
            var tale = entry.tale
            tale.cover = CoverReference(path: path, sha256: Digest.sha256(entry.cover))
            return tale
        }
    }
```

- [ ] **Step 4: Kod okuyarak kontrol**

`PublisherKitTests` içindeki mevcut akış testleri `FeedFile(feedVersion:publishedAt:stories:catalogPackage:)` çağırıyorsa varsayılan parametre sayesinde değişmeden derlenir. `writeFallback` Original taşımaz (yedekte kapak yok): bilerek.

- [ ] **Step 5: Commit**

```bash
git add Scripts/ContentPublisher/Sources/PublisherKit/Feed.swift Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift Scripts/ContentPublisher/Tests/PublisherKitTests/OriginalsTests.swift
git commit -m "MagicPaper Original: akış masalları ve kapak özetlerini taşır

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Komut satırı

**Files:**
- Modify: `Scripts/ContentPublisher/Sources/content-publisher/main.swift`

- [ ] **Step 1: Kullanım metnine ekle**

`usage` içinde `fallback` satırının üstüne:

```
  originals check [<slug>]   Taslağı (ya da hepsini) denetler: kurallar, karakterler, dil, kapak.
  originals approve <slug>   Denetler, drafts/<slug> → published/<slug>. Yayın için ardından publish.
```

- [ ] **Step 2: Komutları ekle**

`case "fallback":` satırının üstüne:

```swift
    case "originals":
        guard let sub = arguments.first else { throw PublishError.message("originals check|approve") }
        arguments.removeFirst()
        switch sub {
        case "check":
            let problems = arguments.first.map { OriginalLibrary.check(slug: $0, repo: repo) }
                ?? OriginalLibrary.checkAllDrafts(repo: repo)
            guard problems.isEmpty else { throw PublishError.invalid(problems) }
            print("Denetim temiz.")
        case "approve":
            guard let slug = arguments.first else { throw PublishError.message("originals approve <slug>") }
            try OriginalLibrary.approve(slug: slug, repo: repo)
        default:
            throw PublishError.message("originals check|approve")
        }
```

- [ ] **Step 3: `verify` kapakları da denetlesin**

`case "verify":` içinde `print("Akış …")` satırının üstüne:

```swift
        for original in decoded.originals ?? [] {
            guard let cover = original.cover,
                  let data = try? Data(contentsOf: repo.content.appendingPathComponent(cover.path)),
                  Digest.sha256(data) == cover.sha256 else {
                throw PublishError.message("Original kapağı uyuşmuyor: \(original.slug)")
            }
        }
```

ve `print` satırına `\(decoded.originals?.count ?? 0) Original, ` ekle.

- [ ] **Step 4: Commit**

```bash
git add Scripts/ContentPublisher/Sources/content-publisher/main.swift
git commit -m "content-publisher: originals check ve approve

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Uygulama akış modeli

**Files:**
- Modify: `MagicPaper/StoryEngineBridge/RemoteContent/ContentFeed.swift`
- Modify: `MagicPaperTests/RemoteContentTests.swift`

- [ ] **Step 1: Test yardımcısını genişlet ve testleri yaz**

`RemoteContentTests.swift`, `TestPublisher` içinde `feedData`'yı şununla değiştir:

```swift
    static func feedData(version: Int, stories: [FeedStory], package: CatalogPackageRef? = nil,
                         schema: Int = ContentFeed.supportedSchemaVersion, originals: [FeedOriginal] = []) -> Data {
        let feed = ContentFeed(schemaVersion: schema, feedVersion: version, publishedAt: "2026-10-06",
                               stories: stories, catalogPackage: package, originals: originals)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(feed)
    }

    static let cover = Data([0xFF, 0xD8, 0xFF, 0xE0]) + Data(repeating: 3, count: 32)

    static func original(_ slug: String, cover: Data = TestPublisher.cover, day: String = "2026-10-01",
                         mode: String = "bedtime", id: UUID = UUID()) -> FeedOriginal {
        let digest = SHA256.hash(data: cover).map { String(format: "%02x", $0) }.joined()
        return FeedOriginal(id: id, slug: slug, title: "Fenerin Sesi", mode: mode, ageMin: 5, ageMax: 7,
                            minutes: 4, summary: "Lale feneri yakar.", characters: ["Lale"],
                            pages: ["Bir.", "İki.", "Üç."], publishDate: day,
                            cover: .init(path: "originals/\(slug).jpg", sha256: digest))
    }
```

`RemoteContentTests` sınıfının sonuna:

```swift
    // MARK: - MagicPaper Original

    func testAFeedWithoutOriginalsStillReads() throws {
        let json = #"{"schemaVersion":1,"feedVersion":3,"publishedAt":"2026-10-06","stories":[]}"#
        XCTAssertEqual(try JSONDecoder().decode(ContentFeed.self, from: Data(json.utf8)).originals, [])
    }

    func testAMalformedOriginalIsDroppedNotTheFeed() throws {
        let good = TestPublisher.original("fener")
        var object = try JSONSerialization.jsonObject(
            with: TestPublisher.feedData(version: 1, stories: [], originals: [good])) as! [String: Any]
        var originals = object["originals"] as! [[String: Any]]
        var bad = originals[0]
        bad["slug"] = "../kacak"
        bad["id"] = UUID().uuidString
        originals.append(bad)
        object["originals"] = originals
        let feed = try JSONDecoder().decode(ContentFeed.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(feed.originals.map(\.slug), ["fener"])
    }

    func testOriginalCoversAreDownloadedAndVerified() async {
        let original = TestPublisher.original("fener")
        serve(TestPublisher.feedData(version: 1, stories: [], originals: [original]))
        StubContentProtocol.responses["/content/originals/fener.jpg"] = (200, TestPublisher.cover)
        let content = service()

        await content.refresh()

        XCTAssertEqual(content.originals.map(\.slug), ["fener"])
        XCTAssertEqual(store.originalCover(slug: "fener"), TestPublisher.cover)
    }

    func testAnOriginalWhoseCoverDoesNotMatchStaysHidden() async {
        serve(TestPublisher.feedData(version: 1, stories: [], originals: [TestPublisher.original("fener")]))
        StubContentProtocol.responses["/content/originals/fener.jpg"] = (200, Data([0xFF, 0xD8, 0x00]))
        let content = service()

        await content.refresh()

        XCTAssertEqual(content.originals, [])
        XCTAssertNil(store.originalCover(slug: "fener"))
    }

    func testAnOriginalLeavingTheFeedTakesItsCoverAlong() async {
        serve(TestPublisher.feedData(version: 1, stories: [], originals: [TestPublisher.original("fener")]))
        StubContentProtocol.responses["/content/originals/fener.jpg"] = (200, TestPublisher.cover)
        let content = service()
        await content.refresh()

        serve(TestPublisher.feedData(version: 2, stories: []))
        await content.refresh()

        XCTAssertEqual(content.originals, [])
        XCTAssertNil(store.originalCover(slug: "fener"))
    }

    func testStoredCoversServeOfflineFromTheNextLaunch() async {
        serve(TestPublisher.feedData(version: 1, stories: [], originals: [TestPublisher.original("fener")]))
        StubContentProtocol.responses["/content/originals/fener.jpg"] = (200, TestPublisher.cover)
        await service().refresh()

        StubContentProtocol.responses = [:]
        XCTAssertEqual(service().originals.map(\.slug), ["fener"])
    }
```

- [ ] **Step 2: `FeedOriginal` ve `ContentFeed.originals`**

`ContentFeed.swift`, `ContentFeed` içinde `let flags: [String: Bool]?` altına:

```swift
    /// MagicPaper Original masalları (spec 2026-11-12). Eski akışlarda yok: boş.
    let originals: [FeedOriginal]
```

`CodingKeys`'e `originals` ekle:

```swift
    enum CodingKeys: String, CodingKey {
        case schemaVersion, feedVersion, publishedAt, stories, catalogPackage, flags, originals
    }
```

Memberwise init'e son parametre `originals: [FeedOriginal] = []` ve gövdesine `self.originals = originals`.

`init(from:)` sonuna:

```swift
        // Bozuk bir Original akışı düşürmez; aynı id ya da slug ikinci kez gelmez.
        let decoded = ((try? container.decodeIfPresent([Lossy<FeedOriginal>].self, forKey: .originals)) ?? nil)?
            .compactMap(\.value).filter(\.isWellFormed) ?? []
        var ids: Set<UUID> = []
        var slugs: Set<String> = []
        originals = decoded.filter { ids.insert($0.id).inserted && slugs.insert($0.slug).inserted }
```

`FeedStory`'nin üstüne:

```swift
/// Bir MagicPaper Original masalı. Yayıncının `OriginalFile`'ı ile aynı
/// alanlar; ikisini birlikte değiştirin. Metin akışta, kapak yanında:
/// `cover.path`'teki dosya `cover.sha256`'ya uymuyorsa masal gösterilmez.
struct FeedOriginal: Codable, Equatable {
    struct Cover: Codable, Equatable {
        let path: String
        let sha256: String
    }

    let id: UUID
    let slug: String
    let title: String
    /// `bedtime` | `learning` | `adventure`. Bilinmeyen mod masalı düşürmez.
    let mode: String
    let ageMin: Int
    let ageMax: Int
    let minutes: Int
    let summary: String
    let characters: [String]
    let pages: [String]
    /// `yyyy-MM-dd`; o günden önce gösterilmez.
    let publishDate: String
    let cover: Cover

    /// Yayıncının yazdığı biçim: slug güvenli, kapak `originals/<slug>.jpg`.
    var isWellFormed: Bool {
        slug.range(of: #"^[a-z0-9]+(-[a-z0-9]+)*$"#, options: .regularExpression) != nil
            && cover.path == "originals/\(slug).jpg"
            && cover.sha256.count == 64 && cover.sha256.allSatisfy { $0.isHexDigit && !$0.isUppercase }
            && publishDate.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"#, options: .regularExpression) != nil
            && !pages.isEmpty && ageMin <= ageMax
    }

    func matches(_ data: Data) -> Bool {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() == cover.sha256
    }
}
```

- [ ] **Step 3: Kod okuyarak kontrol**

`verified(_:signature:key:)` değişmez. `Lossy` aynı dosyada `private`: erişilebilir. Testteki `"../kacak"` slug'ı regex'e uymaz, düşer.

- [ ] **Step 4: Commit**

```bash
git add MagicPaper/StoryEngineBridge/RemoteContent/ContentFeed.swift MagicPaperTests/RemoteContentTests.swift
git commit -m "Uzaktan içerik: akış MagicPaper Original masallarını okur

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Kapakları indir, doğrula, sakla

**Files:**
- Modify: `MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentStore.swift`
- Modify: `MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentService.swift`

(Testler Task 5'te yazıldı.)

- [ ] **Step 1: Store'a kapak dosyaları**

`RemoteContentStore.swift`, `// MARK: Files` satırının üstüne:

```swift
    // MARK: Original covers

    /// `Originals/<slug>.jpg`. Akışın imzalı özetine göre denetlenir; burada
    /// yalnız okunur ve yazılır.
    private var originalsDirectory: URL { directory.appendingPathComponent("Originals", isDirectory: true) }

    func originalCoverURL(slug: String) -> URL { originalsDirectory.appendingPathComponent("\(slug).jpg") }

    func originalCover(slug: String) -> Data? { try? Data(contentsOf: originalCoverURL(slug: slug)) }

    func saveOriginalCover(_ data: Data, slug: String) throws {
        try ensureDirectory()
        try FileManager.default.createDirectory(at: originalsDirectory, withIntermediateDirectories: true)
        try data.write(to: originalCoverURL(slug: slug), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    /// Akışta artık olmayan masalların kapakları gider.
    func removeOriginalCovers(keeping slugs: Set<String>) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: originalsDirectory.path)) ?? []
        for name in names where !slugs.contains(String(name.dropLast(".jpg".count))) || !name.hasSuffix(".jpg") {
            try? FileManager.default.removeItem(at: originalsDirectory.appendingPathComponent(name))
        }
    }
```

`write(_:_:)`'ı klasör kurulumunu paylaşacak şekilde böl:

```swift
    private func ensureDirectory() throws {
        let manager = FileManager.default
        guard !manager.fileExists(atPath: directory.path) else { return }
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        var folder = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
    }

    private func write(_ data: Data, _ name: String) throws {
        try ensureDirectory()
        try data.write(to: url(name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
```

- [ ] **Step 2: Service kapakları eşitlesin**

`RemoteContentService.swift`:

`static let maxPackageBytes` altına:

```swift
    static let maxCoverBytes = 2 * 1024 * 1024
```

`@Published private(set) var feed` altına:

```swift
    /// Kapağı cihazda olan ve imzalı özete uyan MagicPaper Original masalları.
    @Published private(set) var originals: [FeedOriginal] = []
```

`init` içinde `if let key = config?.key { feed = store.feed(key: key) }` satırını şununla değiştir:

```swift
        if let key = config?.key { feed = store.feed(key: key) }
        originals = Self.verifiedOriginals(feed?.originals ?? [], store: store)
```

`run()` içinde `await syncPackage(…)` satırının altına:

```swift
        await syncOriginalCovers((feed ?? stored)?.originals ?? [], config: config)
```

`/// A failure in a few words` yorumunun üstüne:

```swift
    nonisolated static func verifiedOriginals(_ list: [FeedOriginal], store: RemoteContentStore) -> [FeedOriginal] {
        list.filter { original in store.originalCover(slug: original.slug).map(original.matches) ?? false }
    }

    /// Akıştaki her Original'in kapağı: yoksa ya da özeti tutmuyorsa indirilir.
    /// Özeti tutmayan indirme saklanmaz; masal gizli kalır, sonraki çalışmada
    /// yeniden denenir.
    private func syncOriginalCovers(_ list: [FeedOriginal], config: RemoteContentConfig) async {
        store.removeOriginalCovers(keeping: Set(list.map(\.slug)))
        for original in list {
            if let local = store.originalCover(slug: original.slug), original.matches(local) { continue }
            do {
                let data = try await download(config.contentRoot.appendingPathComponent(original.cover.path),
                                              limit: Self.maxCoverBytes)
                guard original.matches(data) else {
                    logger.notice("Original kapağı özete uymadı: \(original.slug, privacy: .public)")
                    continue
                }
                try store.saveOriginalCover(data, slug: original.slug)
            } catch {
                logger.notice("Original kapağı indirilemedi: \(Self.brief(error), privacy: .public)")
            }
        }
        originals = Self.verifiedOriginals(list, store: store)
    }
```

- [ ] **Step 3: Kod okuyarak kontrol**

Özeti tutmayan kapak önceden diskte yoksa `originalCover` nil kalır (Task 5 testi). Akıştan çıkan slug `removeOriginalCovers` ile silinir. `brief` `private static`, aynı tipte: erişilebilir. Slug loglanıyor: çocuk verisi değil, yayımlanmış içerik adı.

- [ ] **Step 4: Commit**

```bash
git add MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentStore.swift MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentService.swift
git commit -m "Uzaktan içerik: Original kapakları indirilir, özetle doğrulanır

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Raf ve masal çevirisi

**Files:**
- Create: `MagicPaper/Screens/Gunluk/Model/OriginalTales.swift`
- Modify: `MagicPaper/Screens/Gunluk/Model/ClassicTale.swift`
- Modify: `MagicPaper/Screens/Gunluk/Model/ClassicsCatalog.swift:88-89`
- Create: `MagicPaperTests/OriginalTalesTests.swift`

- [ ] **Step 1: Testleri yaz**

`MagicPaperTests/OriginalTalesTests.swift`:

```swift
import XCTest
@testable import MagicPaper

/// MagicPaper Original (spec 2026-11-12): akış masalının klasiğe çevrilmesi
/// ve Masallar rafları.
@MainActor
final class OriginalTalesTests: XCTestCase {

    private func library(_ originals: [FeedOriginal], today: String = "2026-11-20") -> ClassicsLibrary {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: today)!
        let suite = "OriginalTalesTests-\(UUID().uuidString)"
        return ClassicsLibrary(catalog: ClassicsCatalog(file: ClassicsCatalogTests.file),
                               defaults: UserDefaults(suiteName: suite)!, now: { date },
                               currentAge: { nil }, dailyStories: { [] }, remoteOriginals: { originals })
    }

    func testABedtimeOriginalSitsOnTheOriginalAndBedtimeShelves() {
        let tale = TestPublisher.original("fener", mode: "bedtime").classicTale
        XCTAssertEqual(tale.origin, .orijinal)
        XCTAssertEqual(tale.shelves, [.orijinal, .uyku])
        XCTAssertEqual(tale.shortMeta, "Original · 4 dk")
        XCTAssertEqual(tale.soft.pages, ["Bir.", "İki.", "Üç."])
        XCTAssertFalse(tale.creditLine.contains("uyarlaması"))
        XCTAssertEqual(TestPublisher.original("orman", mode: "adventure").classicTale.shelves, [.orijinal])
    }

    func testTheCoverNameCarriesSlugAndDigest() {
        let original = TestPublisher.original("fener")
        XCTAssertEqual(OriginalCovers.slug(in: original.classicTale.cover), "fener")
        XCTAssertNil(OriginalCovers.slug(in: "classic-rapunzel"))
    }

    func testTheOriginalShelfHoldsOnlyOriginalsNewestFirst() {
        let old = TestPublisher.original("eski", day: "2026-11-01")
        let new = TestPublisher.original("yeni", day: "2026-11-15")
        let titles = library([old, new]).items(in: .orijinal).map(\.id)
        XCTAssertEqual(titles, [new.id, old.id])
    }

    func testAnOriginalIsNotShownBeforeItsDay() {
        XCTAssertTrue(library([TestPublisher.original("yarin", day: "2026-11-21")]).items(in: .orijinal).isEmpty)
    }

    func testBedtimeOriginalsJoinTheBedtimeShelf() {
        let original = TestPublisher.original("fener", mode: "bedtime")
        XCTAssertTrue(library([original]).items(in: .uyku).contains { $0.id == original.id })
        XCTAssertFalse(library([original]).items(in: .klasikler).contains { $0.id == original.id })
    }

    func testAnOriginalOpensByID() {
        let original = TestPublisher.original("fener")
        XCTAssertEqual(library([original]).tale(original.id)?.title, "Fenerin Sesi")
    }

    func testTheBundledCatalogMayNotWriteTheOriginalShelf() {
        XCTAssertTrue(ClassicShelf.orijinal.isDerived)
        XCTAssertEqual(ClassicsCatalog(file: ClassicsCatalogTests.file).items(in: .orijinal), [])
    }
}
```

- [ ] **Step 2: `ClassicShelf.orijinal` ve `creditLine`**

`ClassicTale.swift`:

```swift
enum ClassicShelf: String, Codable, CaseIterable, Identifiable {
    case orijinal, klasikler, anadolu, fabllar, seriler, uyku, besDakika, hayvanlar, sesli
```

`title` switch'ine `case .orijinal: return "MagicPaper Original"`, `subtitle` switch'ine `case .orijinal: return "Yalnızca burada okunan masallar"`.

`isDerived`:

```swift
    /// Bu raflar kataloğa yazılmaz; masalın başka alanlarından çıkarılır.
    /// "Seriler" seri olmaktan, "5 dakikalık" süreden, "MagicPaper Original"
    /// uzaktan akıştan. "Sesli" için henüz seslendirilmiş masal yok, bu
    /// yüzden hep boş ve gizli.
    var isDerived: Bool { self == .seriler || self == .besDakika || self == .sesli || self == .orijinal }
```

`ClassicTale.creditLine`:

```swift
    /// Detay ekranının en altındaki satır. Original uyarlama değildir.
    var creditLine: String {
        origin == .orijinal ? "\(attribution) \(coverCredit)" : "\(attribution) \(coverCredit) MagicPaper uyarlaması."
    }
```

- [ ] **Step 3: Katalog yeni rafı tanısın**

`ClassicsCatalog.swift`, `items(in:age:)` içinde:

```swift
        case .sesli, .orijinal:
            onShelf = []
```

(`case .sesli:` satırının yerine.) Sonra derleyicinin göstereceği başka `switch` var mı diye: `grep -rn "case .sesli" MagicPaper --include='*.swift'`; her birine `.orijinal` eklenir.

- [ ] **Step 4: Çeviri ve kapak çözücü**

`MagicPaper/Screens/Gunluk/Model/OriginalTales.swift`:

```swift
import UIKit

// MARK: - MagicPaper Original (spec 2026-11-12)
//
// Uzaktan akışın kendi masalları Masallar'da klasiklerin okuyucusuyla okunur.
// Kişiselleştirilmez; her çocuk aynı metni okur.

extension FeedOriginal {
    /// Masalın klasik biçimi. Kapak adı `original:<slug>:<özetin başı>`:
    /// kapak değişince ad da değişir, eski görsel önbellekte kalmaz.
    var classicTale: ClassicTale {
        ClassicTale(
            id: id, slug: slug, title: title, origin: .orijinal, byline: "Original",
            ageMin: ageMin, ageMax: ageMax, minutes: minutes, summary: summary,
            shelves: mode == "bedtime" ? [.orijinal, .uyku] : [.orijinal],
            cover: OriginalCovers.name(slug: slug, sha256: cover.sha256), coverFocus: .center,
            attribution: "MagicPaper Original.", coverCredit: "Kapak: MagicPaper.",
            soft: ClassicText(pages: pages), classic: nil, seriesID: nil, episode: nil)
    }
}

/// Original kapakları asset kataloğunda değil, cihazda
/// (`RemoteContentStore.originalCoverURL`).
enum OriginalCovers {
    static let prefix = "original:"
    private static let cache = NSCache<NSString, UIImage>()

    static func name(slug: String, sha256: String) -> String { "\(prefix)\(slug):\(sha256.prefix(12))" }

    static func slug(in name: String) -> String? {
        guard name.hasPrefix(prefix) else { return nil }
        return name.dropFirst(prefix.count).split(separator: ":").first.map(String.init)
    }

    static func image(named name: String, store: RemoteContentStore = RemoteContentStore()) -> UIImage? {
        guard let slug = slug(in: name) else { return nil }
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let image = UIImage(contentsOfFile: store.originalCoverURL(slug: slug).path) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add MagicPaper/Screens/Gunluk/Model/OriginalTales.swift MagicPaper/Screens/Gunluk/Model/ClassicTale.swift MagicPaper/Screens/Gunluk/Model/ClassicsCatalog.swift MagicPaperTests/OriginalTalesTests.swift
git commit -m "Masallar: MagicPaper Original rafı ve masal çevirisi

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Kütüphane Original'leri raflara katar

**Files:**
- Modify: `MagicPaper/Screens/Gunluk/Model/ClassicsLibrary.swift`
- Modify: `MagicPaper/Screens/Gunluk/GunlukView.swift:99`
- Modify: `MagicPaper/Views/LibraryView.swift:330,349`

(Testler Task 7'de.)

- [ ] **Step 1: Kaynağı ekle**

`ClassicsLibrary`:

`private let dailyStories: () -> [DailyStory]` altına:

```swift
    private let remoteOriginals: () -> [FeedOriginal]
```

`init` imzasına son parametre `remoteOriginals: (() -> [FeedOriginal])? = nil`, gövdeye `self.dailyStories = …` altına:

```swift
        self.remoteOriginals = remoteOriginals ?? { RemoteContentService.shared.originals }
        if remoteOriginals == nil {
            // Kapaklar inince raflar yenilensin.
            RemoteContentService.shared.$originals
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
        }
```

- [ ] **Step 2: Raflar ve arama**

`// MARK: - Raflar` altındaki `items(in:ageBand:)`'ı şununla değiştir:

```swift
    func items(in shelf: ClassicShelf?, ageBand: MPAgeRange? = nil) -> [ClassicItem] {
        let items = catalog.items(in: shelf) + originalItems(in: shelf)
        guard let ageBand else { return items }
        return items.filter { $0.ageMin <= ageBand.band.upperBound && $0.ageMax >= ageBand.band.lowerBound }
    }

    /// MagicPaper Original: günü gelmiş, kapağı cihazda olan masallar, en yeni önce.
    var originalTales: [ClassicTale] {
        let today = TodaysStoryPicker.day(now(), calendar: calendar)
        return remoteOriginals().filter { $0.publishDate <= today }
            .sorted { $0.publishDate > $1.publishDate }
            .map(\.classicTale)
    }

    private func originalItems(in shelf: ClassicShelf?) -> [ClassicItem] {
        let tales = originalTales
        switch shelf {
        case nil: return tales.map(ClassicItem.tale)
        case .besDakika?: return tales.filter { $0.minutes <= 5 }.map(ClassicItem.tale)
        case let written?: return tales.filter { $0.shelves.contains(written) }.map(ClassicItem.tale)
        }
    }

    /// Katalogdaki ya da Original masal.
    func tale(_ id: UUID) -> ClassicTale? {
        catalog.tale(id) ?? originalTales.first { $0.id == id }
    }
```

`continueReading` içinde `if let tale = catalog.tale(id) {` → `if let tale = tale(id) {`.

- [ ] **Step 3: Çağıranlar**

- `GunlukView.swift` `destination`: `if let tale = library.catalog.tale(id) {` → `if let tale = library.tale(id) {`.
- `LibraryView.swift:330`: `ClassicsLibrary.shared.catalog.tale(item.id)` → `ClassicsLibrary.shared.tale(item.id)`.
- `LibraryView.swift:349` civarı: satırı oku; `catalog.tale(id)` yerel bir `catalog` değişkeninden geliyorsa `ClassicsLibrary.shared.tale(id)` ile değiştir (fonksiyon `@MainActor` bağlamında; değilse dokunma ve Görev 14 raporuna yaz).
- `MPCollection.swift:41` bilerek değişmez: koleksiyon klasiklerin kendi sayımı.

- [ ] **Step 4: Kod okuyarak kontrol**

`GunlukCategoriesView` `library.items(in:)` kullanıyor: Original rafı boş değilse Kategoriler'de kendiliğinden görünür. `bedtimeSection` `library.items(in: .uyku)` okuyor: uyku Original'leri gece bölgesine kendiliğinden girer. Arama (`catalog.search`) Original'leri bulmaz: bilerek, kapsam dışı.

- [ ] **Step 5: Commit**

```bash
git add MagicPaper/Screens/Gunluk/Model/ClassicsLibrary.swift MagicPaper/Screens/Gunluk/GunlukView.swift MagicPaper/Views/LibraryView.swift
git commit -m "Masallar: Original masallar raflarda ve okuyucuda

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Ekran

**Files:**
- Modify: `MagicPaper/Screens/Gunluk/GunlukComponents.swift:24`
- Modify: `MagicPaper/Screens/Gunluk/GunlukView.swift` (bölümler)

- [ ] **Step 1: Kapak dosyadan da okunsun**

`ClassicCoverImage.body`:

```swift
            if let image = UIImage(named: asset) ?? OriginalCovers.image(named: asset) {
```

Üstteki doc yorumuna bir satır: `/// Original kapakları cihazdaki dosyadan gelir (`OriginalCovers`).`

- [ ] **Step 2: Bölüm**

`GunlukView`, vitrinin altındaki `VStack(alignment: .leading, spacing: MPSpacing.xxxl)` içinde `shelfDoors`'un üstüne:

```swift
                            // MagicPaper Original: vitrinin hemen altı; boşsa hiç çizilmez.
                            shelfSection(.orijinal, width: 128, height: 176)
```

`shelfSection` `GunlukSection` (`MPSectionHeader`) + "Tümü ›" (`.shelf(.orijinal)`) + `ClassicShelfCard` kullanıyor: yeni bileşen yok. Ragi eklenmez (ekranda zaten var).

- [ ] **Step 3: Tasarım yasası grep'i (değişen dosyalar)**

```bash
grep -n -e "Color(hex:" -e "\.shadow(" -e "fixedSize:" MagicPaper/Screens/Gunluk/GunlukView.swift MagicPaper/Screens/Gunluk/GunlukComponents.swift MagicPaper/Screens/Gunluk/Model/OriginalTales.swift
grep -nE "\.padding\((\.[a-z]+, )?[0-9]" MagicPaper/Screens/Gunluk/GunlukView.swift MagicPaper/Screens/Gunluk/Model/OriginalTales.swift
grep -nE "\"[^\"]*([Üü]ret|[Oo]luştur|saniyeler içinde|anında|[Yy]apay zeka)[^\"]*\"" MagicPaper/Screens/Gunluk/Model/OriginalTales.swift MagicPaper/Screens/Gunluk/Model/ClassicTale.swift
```

Beklenen: bu işin eklediği satırlardan isabet yok (önceden var olan isabetler `git blame` ile ayrılır).

- [ ] **Step 4: Commit**

```bash
git add MagicPaper/Screens/Gunluk/GunlukComponents.swift MagicPaper/Screens/Gunluk/GunlukView.swift
git commit -m "Masallar: MagicPaper Original bölümü

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Kapak aracı

**Files:**
- Create: `Tools/originals_cover.py`
- Create: `Tools/test_originals_cover.py`

- [ ] **Step 1: Testi yaz**

`Tools/test_originals_cover.py`:

```python
"""Original kapak aracı testleri (spec 2026-11-12). Ağ yok, yalnız stdlib.

    python3 Tools/test_originals_cover.py
"""

import base64
import pathlib
import tempfile
import unittest

import originals_cover as c

WORLD = """# Fener Kasabası

## Karakterler

### Lale
Kızıl örgülü saç.

## Kapak stili
Gouache, warm paper texture, soft dusk light.

## Ton
Sakin.
"""

REVIEW = """# Fenerin Sesi

## Kapak sahnesi
Lale climbs the lighthouse stairs holding a small lantern.

## Notlar
"""


class SectionTests(unittest.TestCase):
    def test_reads_only_its_own_section(self):
        self.assertEqual(c.section(WORLD, "Kapak stili"), "Gouache, warm paper texture, soft dusk light.")
        self.assertEqual(c.section(REVIEW, "Kapak sahnesi"), "Lale climbs the lighthouse stairs holding a small lantern.")
        self.assertEqual(c.section(REVIEW, "Notlar"), "")
        self.assertEqual(c.section(WORLD, "Yok"), "")


class PromptTests(unittest.TestCase):
    def test_prompt_has_style_scene_and_rules(self):
        prompt = c.build_prompt("Gouache.", "Lale on the stairs.")
        self.assertIn("Gouache.", prompt)
        self.assertIn("Lale on the stairs.", prompt)
        self.assertIn("no text", prompt)

    def test_missing_parts_are_named(self):
        with self.assertRaises(ValueError):
            c.build_prompt("", "Sahne")
        with self.assertRaises(ValueError):
            c.build_prompt("Stil", "")

    def test_request_asks_for_a_portrait_image(self):
        body = c.request_body("p")
        self.assertEqual(body["generationConfig"]["imageConfig"]["aspectRatio"], "3:4")
        self.assertEqual(body["generationConfig"]["responseModalities"], ["IMAGE"])


class ResponseTests(unittest.TestCase):
    def test_first_inline_image_is_returned(self):
        raw = b"\x89PNG..."
        response = {"candidates": [{"content": {"parts": [
            {"text": "işte"}, {"inlineData": {"mimeType": "image/png", "data": base64.b64encode(raw).decode()}}]}}]}
        self.assertEqual(c.image_bytes(response), raw)

    def test_no_image_raises(self):
        with self.assertRaises(RuntimeError):
            c.image_bytes({"candidates": []})


class KeyTests(unittest.TestCase):
    def test_key_comes_from_secrets_when_env_is_empty(self):
        with tempfile.TemporaryDirectory() as root:
            pathlib.Path(root, "Secrets.xcconfig").write_text("OTHER = x\nGEMINI_API_KEY = abc123\n", encoding="utf-8")
            self.assertEqual(c.api_key(pathlib.Path(root), env={}), "abc123")
            self.assertEqual(c.api_key(pathlib.Path(root), env={"GEMINI_API_KEY": "env"}), "env")
            self.assertIsNone(c.api_key(pathlib.Path(root, "yok"), env={}))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Aracı yaz**

`Tools/originals_cover.py`:

```python
"""MagicPaper Original kapağı (spec 2026-11-12, docs/superpowers/specs).

    python3 Tools/originals_cover.py <slug>

WORLD.md'nin "## Kapak stili" bölümü + drafts/<slug>/review.md'nin
"## Kapak sahnesi" bölümü → Gemini görsel → drafts/<slug>/cover.jpg
(uzun kenar en çok 1500 px, JPEG). Anahtar: GEMINI_API_KEY ortamı ya da
Secrets.xcconfig. İstekte çocuk verisi yok: yalnız dünyanın karakterleri ve
sahne. Model: MP_COVER_MODEL (varsayılan gemini-2.5-flash-image).
"""

import base64
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORIGINALS = ROOT / "Content" / "Originals"
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def section(text, title):
    """`## <title>` başlığının altındaki metin, bir sonraki `## `'e kadar."""
    out, inside = [], False
    for line in text.splitlines():
        if line.startswith("## "):
            if inside:
                break
            inside = line.strip() == f"## {title}"
            continue
        if inside:
            out.append(line)
    return "\n".join(out).strip()


def api_key(root=ROOT, env=None):
    env = os.environ if env is None else env
    if env.get("GEMINI_API_KEY"):
        return env["GEMINI_API_KEY"]
    path = pathlib.Path(root) / "Secrets.xcconfig"
    if not path.exists():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\s*GEMINI_API_KEY\s*=\s*(\S+)", line)
        if match:
            return match.group(1)
    return None


def build_prompt(style, scene):
    if not style.strip():
        raise ValueError("WORLD.md'de '## Kapak stili' bölümü boş ya da yok")
    if not scene.strip():
        raise ValueError("review.md'de '## Kapak sahnesi' bölümü boş ya da yok")
    return (
        "Illustrated cover for a premium children's picture book, portrait.\n\n"
        f"Style:\n{style}\n\n"
        f"Scene:\n{scene}\n\n"
        "Rules: no text, no letters, no logos, no photorealism, no neon, no glossy 3D, "
        "no frightening imagery. Keep the top third calm for a title."
    )


def request_body(prompt):
    return {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "3:4"}},
    }


def image_bytes(response):
    for candidate in response.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            data = part.get("inlineData") or part.get("inline_data")
            if data and data.get("data"):
                return base64.b64decode(data["data"])
    raise RuntimeError("Yanıtta görsel yok (güvenlik filtresi ya da model hatası)")


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    slug = argv[1]
    draft = ORIGINALS / "drafts" / slug
    world = (ORIGINALS / "WORLD.md").read_text(encoding="utf-8")
    review = (draft / "review.md").read_text(encoding="utf-8")
    prompt = build_prompt(section(world, "Kapak stili"), section(review, "Kapak sahnesi"))
    key = api_key()
    if not key:
        print("HATA: GEMINI_API_KEY yok (ortam ya da Secrets.xcconfig)", file=sys.stderr)
        return 1
    model = os.environ.get("MP_COVER_MODEL", "gemini-2.5-flash-image")
    request = urllib.request.Request(
        ENDPOINT.format(model=model), data=json.dumps(request_body(prompt)).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": key}, method="POST")
    with urllib.request.urlopen(request, timeout=180) as response:
        image = image_bytes(json.load(response))
    with tempfile.TemporaryDirectory() as temp:
        raw = pathlib.Path(temp) / "raw.png"
        raw.write_bytes(image)
        cover = draft / "cover.jpg"
        subprocess.run(["sips", "-Z", "1500", "-s", "format", "jpeg", "-s", "formatOptions", "80",
                        str(raw), "--out", str(cover)], check=True, capture_output=True)
    print(f"Kapak yazıldı: {cover} ({cover.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

- [ ] **Step 3: Commit**

```bash
git add Tools/originals_cover.py Tools/test_originals_cover.py
git commit -m "Original kapak aracı (Gemini görsel)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: İçerik klasörü ve iş akışı belgesi

**Files:**
- Create: `Content/Originals/README.md`
- Create: `Content/Originals/drafts/.gitkeep`, `Content/Originals/published/.gitkeep`
- Modify: `docs/REMOTE_CONTENT.md` (tablo + yeni bölüm)

- [ ] **Step 1: README**

`Content/Originals/README.md`:

````markdown
# MagicPaper Original

Masallar sekmesindeki "MagicPaper Original" rafının kaynağı. Tasarım:
`docs/superpowers/specs/2026-11-12-magicpaper-original-design.md`.

## Klasörler

| Yer | Ne |
|---|---|
| `WORLD.md` | Dünya kitabı: mekân, karakterler (`## Karakterler` altında her biri `### Ad`), ton, `## Kapak stili`. Ajan her turda önce bunu okur |
| `world-proposals.md` | Yalnız ilk tur: ajanın üç dünya önerisi |
| `drafts/<slug>/` | Onay bekleyen masal: `tale.json`, `cover.jpg`, `review.md` |
| `published/<slug>/` | Onaylanmış masal: `tale.json`, `cover.jpg` |

## Batuhan'ın işi

1. Bildirim gelince `drafts/<slug>/review.md`'yi ve `tale.json`'u okuyun, `cover.jpg`'ye bakın.
2. Beğendiyseniz:
   ```bash
   cd Scripts/ContentPublisher
   swift run content-publisher originals approve <slug>
   swift run content-publisher publish --deploy
   ```
   Ardından `Content/Originals/published/<slug>` ve `hosting/public/content/` değişikliklerini commit'leyin.
3. Beğenmediyseniz `review.md`'nin en altındaki `## Notlar`'a yazın. Ajan sonraki turda önce onu düzeltir.
4. Hiç istemiyorsanız klasörü silin.

Denetim her zaman: `swift run content-publisher originals check [<slug>]`.

## Yayından önce bir kez

Uzaktan içerik bugün kapalı: `Info.plist`'te `MPContentSigningKey` boş. Original rafı ancak
`docs/REMOTE_CONTENT.md` "İlk kurulum" adımları yapılıp anahtarlı bir sürüm yayımlanınca görünür.
````

- [ ] **Step 2: `.gitkeep` dosyaları**

```bash
mkdir -p Content/Originals/drafts Content/Originals/published
touch Content/Originals/drafts/.gitkeep Content/Originals/published/.gitkeep
```

- [ ] **Step 3: `docs/REMOTE_CONTENT.md`**

"Ne nerede" tablosuna iki satır:

```
| MagicPaper Original masalları (bir masal = bir klasör) | `Content/Originals/published/<slug>/` (`Content/Originals/README.md`) |
| Original kapakları (yayımlanan) | `hosting/public/content/originals/<slug>.jpg`, özeti `feed.json` içinde |
```

"## Katalog paketi yayımlamak" başlığının üstüne:

````markdown
## MagicPaper Original yayımlamak

1. `swift run content-publisher originals approve <slug>` (önce denetler, sonra `drafts/` → `published/`).
2. `swift run content-publisher publish --deploy`: akış `originals` dizisini, her kaydın kapak yolu ve
   SHA-256'sıyla taşır; kapaklar `content/originals/`'a yazılır, akıştan çıkanlar silinir.
3. `Content/Originals/published/`, `hosting/public/content/feed.json`, `.sig` ve `originals/`'ı commit'leyin.

Uygulama kapağı indirir ve imzalı özetle karşılaştırır; tutmayan kapağın masalı o cihazda görünmez.
Original yokken akışta `originals` anahtarı hiç yazılmaz. Eski uygulamalar anahtarı yok sayar;
`schemaVersion` artmaz.
````

- [ ] **Step 4: Commit**

```bash
git add Content/Originals/README.md Content/Originals/drafts/.gitkeep Content/Originals/published/.gitkeep docs/REMOTE_CONTENT.md
git commit -m "MagicPaper Original: içerik klasörü ve yayın belgesi

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Ajan

**Files:**
- Create: `.claude/agents/original-writer.md` (MagicPaper reposunun kökünde; zamanlanmış görev buradan çalışır)

- [ ] **Step 1: `.gitignore` kontrolü**

```bash
git check-ignore -v .claude/agents/original-writer.md || echo "izlenebilir"
```

Beklenen: `izlenebilir`.

- [ ] **Step 2: Ajanı yaz**

`.claude/agents/original-writer.md`:

````markdown
---
name: original-writer
description: MagicPaper Original masal yazarı. Haftada iki kez zamanlanmış görevle çalışır; ortak dünyada bir masal yazar, kapağını çizdirir ve onaya koyar. Yalnız Content/Originals/drafts/ ve world-proposals.md'ye yazar; asla onaylamaz ya da yayımlamaz.
tools: Read, Write, Edit, Bash, Grep, Glob
---

Sen MagicPaper'ın kendi masallarını yazan ajansın. Marka: "MagicPaper Original". Okur 3-10 yaş çocuk,
sesli okuyan bir ebeveyn. Ürün bir çocuk yayınevi gibi hissettirmeli: sıcak, şiirsel, sakin.

## Sınırlar

- Yazabileceğin yerler: `Content/Originals/drafts/`, `Content/Originals/world-proposals.md`,
  `design-handoff/reference/DEMO_CHANGELOG.md` (yalnız kendi kaydın).
- Asla: `Content/Originals/published/`'a ya da `WORLD.md`'ye yazmak, `originals approve` ya da `publish`
  çalıştırmak, push etmek, uygulama kodunu, klasikleri ya da motoru değiştirmek.
- Kişiselleştirme yok, gerçek bir çocuğun adı yok. Ragi bu dünyanın karakteri değil.

## Tur

1. **Durum.** `git branch --show-current` `main` değilse dur: günlüğe sebebi yaz, bildirim gönder, bitir.
2. **Dünya.** `Content/Originals/WORLD.md` yoksa ilk tur:
   - `world-proposals.md` zaten varsa yeni öneri yazma; "Dünya seçimi bekleniyor" bildirimi gönder, bitir.
   - Yoksa üç dünya öner. Her biri: ad, bir paragraf atmosfer, 4-6 karakter (ad, tür, kapakta değişmeyecek
     görünüş ayrıntıları, konuşma biçimi, sevdiği ve korktuğu şey), üç modun bu dünyada nasıl duyulduğu,
     İngilizce yazılmış bir `Kapak stili` paragrafı (teknik, palet, ışık, kadraj) ve örnek bir ilk sayfa.
     Seçilen öneri Batuhan'ın onayıyla `WORLD.md`'ye şu başlıklarla dönüşecek: `## Mekân`, `## Karakterler`
     (her biri `### Ad`), `## Ton`, `## Kapak stili`. Önerileri de bu iskeletle yaz.
   - Bildirim: "MagicPaper Original: üç dünya önerisi hazır". Bitir.
3. **Notlu taslak.** `drafts/*/review.md` içinde `## Notlar` bölümü dolu bir taslak varsa yeni masal yazma:
   notlara göre metni ya da kapağı düzelt, `## Notlar`'ın altına "Düzeltildi (<tarih>): <ne değişti>" ekle,
   denetimden geçir (adım 6), 8-9'a geç.
4. **Yığın sınırı.** Notsuz onay bekleyen taslak sayısı 3 ya da fazlaysa yeni masal yazma; bildirim:
   "Onay bekleyen 3 Original masal var" ve bitir.
5. **Yaz.** Önce `WORLD.md`'yi, `published/*/tale.json`'u ve `drafts/*/tale.json`'u oku.
   - Mod: son dört masalda en az kullanılan (`bedtime`, `learning`, `adventure`).
   - Yaş bandı: son dört masalda en az kullanılan (3-4, 5-6, 7-8, 9-10); `ageMin`-`ageMax` bu bant.
   - Konu: son sekiz masalda geçmeyen. Karakterler: son iki masalın ana karakteri ana karakter olmaz.
   - Uyku masalı yavaşlayarak, sessizlikle biter. Öğrenme masalı tek bir gerçek bilgiyi doğru verir.
     Macera masalı tehlike değil merak taşır.
   - Kurallar: `Content/Classics/WRITING_BRIEF.md` "Dil ve ton" ve "Güvenlik" bölümleri. Sayfa 40-80 kelime
     (3-4 bandında 25-45), en az 3 sayfa, sayfada en çok 3 paragraf (`\n\n`). `minutes` = toplam kelime / 40,
     yukarı yuvarla. Uzun tire yok, emoji yok. "üret", "oluştur", "yapay zeka", "anında",
     "saniyeler içinde" hiç geçmez.
   - `drafts/<slug>/tale.json`: `id` (`uuidgen`), `slug` (küçük harf, tire, Türkçe karakter yok),
     `title`, `mode`, `ageMin`, `ageMax`, `minutes`, `summary` (tek cümle), `characters` (WORLD.md'deki
     adlar), `pages`, `publishDate` (bugünden sonraki ilk pazartesi ya da perşembe, `yyyy-MM-dd`).
   - `drafts/<slug>/review.md`:
     ```
     # <Başlık>

     - Mod, yaş, süre, karakterler
     - Neden bu seçim (mod, bant, konu)

     ## Öz denetim
     <yüksek sesle okuma notları, `originals check` sonucu>

     ## Kapak sahnesi
     <İngilizce, 2-4 cümle: kim, nerede, ne yapıyor; karakterlerin WORLD.md'deki sabit görünüşü>

     ## Notlar
     ```
6. **Denetim.** Metni yüksek sesle okuyormuş gibi bir kez baştan sona oku, takılan cümleyi düzelt. Sonra:
   ```bash
   cd Scripts/ContentPublisher && swift run content-publisher originals check <slug>
   ```
   Kapak dışındaki her sorunu düzelt; üç denemede geçmezse sorunları `## Öz denetim`'e yaz.
7. **Kapak.** `python3 Tools/originals_cover.py <slug>`. Sonra `cover.jpg`'ye bak (Read). Karakterin
   görünüşü ya da stil WORLD.md'yi tutmuyorsa sahneyi netleştirip en çok iki kez daha çizdir. Yine olmazsa
   `## Öz denetim`'e yaz. Hata alırsan (anahtar yok, ağ) masal kapaksız kalır, sebebi yazılır.
   Ardından `originals check <slug>` yeniden.
8. **Günlük ve commit.** `design-handoff/reference/DEMO_CHANGELOG.md` "## Değişiklik günlüğü" altına en üste:
   `### <tarih> · main, commit bu kayıtla · MagicPaper Original: <başlık> onaya kondu` ve maddeler
   (mod, yaş, denetim sonucu, kapak durumu, dosyalar). Commit:
   ```bash
   git add Content/Originals/drafts/<slug>          # ilk turda: git add Content/Originals/world-proposals.md
   git diff -- design-handoff/reference/DEMO_CHANGELOG.md
   ```
   Kaydı yazmadan önce `git diff` ile günlük dosyasına bak. Yazmadan önce temizse kaydından sonra
   `git add design-handoff/reference/DEMO_CHANGELOG.md`. Başka bir oturumun commit edilmemiş değişikliği
   varsa dosyayı ekleme (etkileşimli `git add -p` burada çalışmaz); kaydı yine yaz ve `review.md`'ye
   "Günlük kaydı commit edilmedi" ekle.
   `git commit -m "MagicPaper Original: <başlık> onaya kondu"` + son satır
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push yok.
9. **Bildirim.**
   ```bash
   osascript -e 'display notification "<başlık>" with title "MagicPaper Original onay bekliyor"'
   ```
````

- [ ] **Step 3: Commit**

```bash
git add .claude/agents/original-writer.md
git commit -m "MagicPaper Original: original-writer ajanı

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Zamanlanmış görev

**Files:** yok (yerel görev, `scheduled-tasks` MCP).

- [ ] **Step 1: Şemayı yükle**

`ToolSearch` → `select:mcp__scheduled-tasks__create_scheduled_task,mcp__scheduled-tasks__list_scheduled_tasks`.

- [ ] **Step 2: Görevi kur**

- Zaman: pazartesi ve perşembe 09:00, Europe/Istanbul (cron `0 9 * * 1,4`).
- Çalışma klasörü: `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper`.
- İstem: `original-writer ajanıyla bir tur çalıştır (.claude/agents/original-writer.md). Bitince ne yaptığını iki cümleyle yaz.`
- Ad: `MagicPaper Original yazımı`.

Şemada istenen başka bir alan (izin modu gibi) varsa ajanın Bash (`swift run`, `python3`, `git`, `osascript`) ve dosya yazma ihtiyacına göre doldur; emin olunamayanı Batuhan'a sor.

- [ ] **Step 3: Doğrula**

`list_scheduled_tasks` görevi bir sonraki çalışma zamanıyla göstermeli. Görev bilgisi Görev 14 raporuna yazılır.

---

### Task 14: Doğrulama, günlük ve teslim

- [ ] **Step 1: Yayıncı testleri**

```bash
cd Scripts/ContentPublisher && swift test 2>&1 | tail -20
```

Beklenen: `OriginalsTests` dahil hepsi geçer. Kalan hatalar varsa `systematic-debugging` ile çöz.

- [ ] **Step 2: Kapak aracı testi**

```bash
python3 Tools/test_originals_cover.py
```

Beklenen: `OK`.

- [ ] **Step 3: Uygulama testleri (bir kez)**

```bash
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MagicPaperTests 2>&1 | grep -E "Executed|error:|failed" | tail -20
```

Beklenen: `Executed N tests, with 0 failures`. (Komut bitince kapanmayabilir; sonuç `Executed` satırında.)

- [ ] **Step 4: Simülatörde rafı gör**

Yerel bir akışla (gerçek `hosting/`'a dokunmadan):

```bash
T=$(mktemp -d) && mkdir -p $T/StoryEngine $T/Content/Originals/published/deneme $T/MagicPaper/StoryEngineBridge/RemoteContent
touch $T/StoryEngine/Package.swift && cp -R Content/DailyFeed $T/Content/
```

- `$T/Content/Originals/WORLD.md`: `## Karakterler` altında `### Lale`.
- `$T/Content/Originals/published/deneme/tale.json`: kurallara uyan bir masal (`characters: ["Lale"]`, `publishDate` bugünden önce), `cover.jpg`: herhangi bir JPEG (`sips -s format jpeg <bir png> --out …`).
- Test anahtarı ve yayın:
  ```bash
  cd Scripts/ContentPublisher
  swift run content-publisher keygen --key $T/key && swift run content-publisher publish --repo $T --key $T/key --first --package none
  python3 -m http.server 8765 -d $T/hosting/public
  ```
  (sunucu arka planda)
- Uygulamayı DEBUG argümanlarıyla aç: `-mp.debug.contentBaseURL http://127.0.0.1:8765/content -mp.debug.contentSigningKey <keygen'in yazdığı açık anahtar>`.
- Ekran görüntüleri: Masallar sekmesi (Original bölümü vitrinin altında), raf ekranı, detay, okuyucu ilk sayfa. Açık + koyu, en büyük Dynamic Type, iPhone SE + Pro Max.
- Bitince sunucuyu durdur, `$T`'yi sil.

- [ ] **Step 5: Tasarım yasası grep'leri**

CLAUDE.md "Doğrulama" bölümündeki altı grep, bu planın değiştirdiği dosyalarla sınırlanarak. Bu işin eklediği satırlarda isabet yok.

- [ ] **Step 6: Günlük kaydı**

`design-handoff/reference/DEMO_CHANGELOG.md` en üste: `### 2026-11-<gün> · main@<commit> · MagicPaper Original: raf, akış ve ajan`. Maddeler: ne değişti (yayıncı, uygulama, araç, ajan, zamanlanmış görev), bilerek değişmeyen (arama, koleksiyon, vitrine koyma, Info.plist anahtarı), test sonuçları (sayılarla), simülatörde görülenler, dosyalar, Batuhan'ın adımları (dünya seçimi, imza anahtarı ve ilk kurulum).

- [ ] **Step 7: Commit**

```bash
git add design-handoff/reference/DEMO_CHANGELOG.md
git commit -m "Günlük: MagicPaper Original

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Push yok; Batuhan isterse.

- [ ] **Step 8: Ajanın ilk turu (isteğe bağlı, Batuhan'a sorulur)**

Zamanlanmış görevi beklemeden bir kez elle: original-writer ile tur → `world-proposals.md`. Batuhan dünyayı seçince `WORLD.md` yazılır (Batuhan onayıyla, ajan değil bu oturum).
