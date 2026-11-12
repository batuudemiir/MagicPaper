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
        let long = try Self.tale { $0["ageMin"] = 3; $0["ageMax"] = 4
            $0["pages"] = [Self.page(50), Self.page(50), Self.page(50)] }
        XCTAssertFalse(long.problems(folder: "fener-masali", characters: known, cover: Self.jpeg).isEmpty)
    }

    func testBannedWordsMatchWholeWordsOnly() throws {
        func problems(_ summary: String) throws -> [String] {
            try Self.tale { $0["summary"] = summary }.problems(folder: "fener-masali", characters: known, cover: Self.jpeg)
        }
        XCTAssertEqual(try problems("Lale kedinin yanında oturdu."), [])
        XCTAssertFalse(try problems("Masal anında hazır.").isEmpty)
    }

    func testWorldBookReadsCharacterHeadingsOnly() {
        XCTAssertEqual(WorldBook.characters(in: Self.world), ["Lale", "Pırpır"])
        XCTAssertEqual(WorldBook.characters(in: "# Boş\n"), [])
    }

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
}
