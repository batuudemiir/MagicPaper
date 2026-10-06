import XCTest
import CryptoKit
@testable import PublisherKit

final class PublisherKitTests: XCTestCase {

    private var temp: URL!
    private let realRepo = try! Repo.find(from: URL(fileURLWithPath: #filePath))

    override func setUpWithError() throws {
        temp = FileManager.default.temporaryDirectory.appendingPathComponent("PublisherKitTests-\(UUID())")
        let stories = temp.appendingPathComponent("Content/DailyFeed/stories")
        try FileManager.default.createDirectory(at: stories, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: temp.appendingPathComponent("StoryEngine"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: temp.appendingPathComponent("MagicPaper/StoryEngineBridge/RemoteContent"), withIntermediateDirectories: true)
        try Data().write(to: temp.appendingPathComponent("StoryEngine/Package.swift"))
        for name in try FileManager.default.contentsOfDirectory(atPath: realRepo.stories.path) {
            try FileManager.default.copyItem(at: realRepo.stories.appendingPathComponent(name),
                                             to: stories.appendingPathComponent(name))
        }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temp)
    }

    private func story(_ edit: (inout [String: Any]) -> Void) throws -> StoryFile {
        var object = try JSONSerialization.jsonObject(
            with: Data(contentsOf: realRepo.stories.appendingPathComponent("01.json"))) as! [String: Any]
        edit(&object)
        return try JSONDecoder().decode(StoryFile.self, from: JSONSerialization.data(withJSONObject: object))
    }

    // MARK: - Signing

    func testASignatureVerifiesWithThePublicKeyOnly() throws {
        let signer = Signer(key: Curve25519.Signing.PrivateKey())
        let data = Data("feed".utf8)
        let signature = try signer.signature(for: data)

        XCTAssertTrue(Signer.verify(signature, for: data, publicKey: signer.publicKeyBase64))
        XCTAssertFalse(Signer.verify(signature, for: Data("feeD".utf8), publicKey: signer.publicKeyBase64))
        XCTAssertFalse(Signer.verify(signature, for: data,
                                     publicKey: Signer(key: .init()).publicKeyBase64))
    }

    func testKeygenWritesAPrivateFileAndNeverOverwrites() throws {
        let path = temp.appendingPathComponent("keys/content-signing.key")
        let signer = try Signer.generate(at: path)

        let mode = try FileManager.default.attributesOfItem(atPath: path.path)[.posixPermissions] as? Int
        XCTAssertEqual(mode, 0o600)
        XCTAssertEqual(try Signer(contentsOf: path).publicKeyBase64, signer.publicKeyBase64)
        XCTAssertThrowsError(try Signer.generate(at: path))
    }

    // MARK: - Stories

    func testTheShippedStoriesAreValid() throws {
        XCTAssertEqual(try StoryLibrary.load(from: realRepo.stories).count, 12)
    }

    func testABrokenStoryIsNamed() throws {
        XCTAssertFalse(try story { $0["publishDate"] = "2026-13-40" }.problems().isEmpty)
        XCTAssertFalse(try story { $0["category"] = "spooky" }.problems().isEmpty)
        XCTAssertFalse(try story { $0["ageRange"] = "üç yaş" }.problems().isEmpty)
        XCTAssertFalse(try story { $0["content"] = "  " }.problems().isEmpty)
        XCTAssertFalse(try story { $0["id"] = "1" }.problems().isEmpty)
        XCTAssertTrue(try story { _ in }.problems().isEmpty)
    }

    func testDuplicateIDsAreRefused() throws {
        let repo = Repo(root: temp)
        try FileManager.default.copyItem(at: repo.stories.appendingPathComponent("01.json"),
                                         to: repo.stories.appendingPathComponent("99.json"))
        XCTAssertThrowsError(try StoryLibrary.load(from: repo.stories))
    }

    // MARK: - Feed

    func testEachPublishRaisesTheVersionAndSigns() throws {
        let signer = Signer(key: Curve25519.Signing.PrivateKey())
        var publisher = Publisher(repo: Repo(root: temp))
        publisher.log = { _ in }

        let first = try publisher.publishFeed(signer: signer, package: .none, today: "2026-10-06")
        let second = try publisher.publishFeed(signer: signer, package: .keep, today: "2026-10-07")

        XCTAssertEqual(first.feedVersion, 1)
        XCTAssertEqual(second.feedVersion, 2)
        XCTAssertNil(second.catalogPackage)
        let repo = Repo(root: temp)
        XCTAssertTrue(Signer.verify(try Data(contentsOf: repo.signature), for: try Data(contentsOf: repo.feed),
                                    publicKey: signer.publicKeyBase64))
    }

    func testAMissingPackageIsAnError() throws {
        var publisher = Publisher(repo: Repo(root: temp))
        publisher.log = { _ in }
        XCTAssertThrowsError(try publisher.publishFeed(signer: Signer(key: .init()), package: .version("9.9.9"),
                                                       today: "2026-10-06"))
    }

    /// The app's bundled copy is the publisher's output, not hand-kept.
    func testTheAppFallbackIsInStepWithTheStories() throws {
        let publisher = Publisher(repo: Repo(root: temp))
        try publisher.writeFallback()
        let written = try Data(contentsOf: Repo(root: temp).appFallback)
        XCTAssertEqual(written, try Data(contentsOf: realRepo.appFallback),
                       "Run `content-publisher fallback` after editing stories")
    }

    // MARK: - Package

    func testThePackageOfThisCheckoutPassesTheDeviceChecks() throws {
        let builder = PackageBuilder()
        let (version, data) = try builder.build()
        XCTAssertNoThrow(try builder.check(data, against: nil))
        // The same package again is not newer than itself.
        XCTAssertThrowsError(try builder.check(data, against: data))
        XCTAssertFalse(version.isEmpty)
    }

    func testValidatorOutputIsParsed() {
        let output = "header\n  - not an issue\nFAILED — 2 issue(s):\n  - one\n  - two\n"
        XCTAssertEqual(Publisher.validatorIssues(output), ["  - one", "  - two"])
        XCTAssertEqual(Publisher.validatorIssues("All checks passed\n"), [])
    }
}
