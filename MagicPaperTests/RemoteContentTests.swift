import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// Serves canned responses by path. No real network in tests.
final class StubContentProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: (status: Int, body: Data)] = [:]
    nonisolated(unsafe) static var requests: [URL] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.requests.append(url)
        guard let response = Self.responses[url.path] else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let http = HTTPURLResponse(url: url, statusCode: response.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubContentProtocol.self]
        return URLSession(configuration: configuration)
    }
}

/// The publisher's side, as a test plays it.
struct TestPublisher {
    let privateKey = Curve25519.Signing.PrivateKey()
    var publicKeyBase64: String { privateKey.publicKey.rawRepresentation.base64EncodedString() }

    func sign(_ data: Data) -> Data {
        Data(try! privateKey.signature(for: data).base64EncodedString().utf8)
    }

    static func story(_ title: String, day: String = "2026-10-01", age: String = "3-8",
                      category: DailyStoryCategory = .bedtime, id: UUID = UUID()) -> FeedStory {
        FeedStory(id: id, publishDate: day, title: title, category: category, ageRange: age, readingTime: 3,
                  content: "Bir zamanlar.", moralLesson: "Ders.", emoji: "⭐️")
    }

    static func feedData(version: Int, stories: [FeedStory], package: CatalogPackageRef? = nil,
                         schema: Int = ContentFeed.supportedSchemaVersion) -> Data {
        let feed = ContentFeed(schemaVersion: schema, feedVersion: version, publishedAt: "2026-10-06",
                               stories: stories, catalogPackage: package)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(feed)
    }

    static func reference(for package: Data, version: String = "2.0.1") -> CatalogPackageRef {
        let digest = SHA256.hash(data: package).map { String(format: "%02x", $0) }.joined()
        return CatalogPackageRef(version: version, schemaVersion: ContentPackage.currentSchemaVersion,
                                 path: "catalog/\(version).json", sha256: digest)
    }
}

/// Test packages built from the app's own bundled content.
enum TestPackages {
    static let bundled: ContentCatalogLoader.Result = try! ContentCatalogLoader().load()

    /// The bundled sources at version 2.0.1, optionally with a pilot blueprint broken.
    static func newer(breakWeight: Bool = false) -> Data {
        var sources = ContentPackage.bundledSources()
        func edit(_ index: Int, _ change: (inout [String: Any]) -> Void) {
            var object = try! JSONSerialization.jsonObject(with: sources.libraries[index].data) as! [String: Any]
            change(&object)
            sources.libraries[index] = .init(name: sources.libraries[index].name,
                                             data: try! JSONSerialization.data(withJSONObject: object))
        }
        edit(0) { $0["version"] = "2.0.1" }
        if breakWeight {
            edit(1) { pilot in
                var blueprints = pilot["blueprints"] as! [[String: Any]]
                blueprints[0]["aggregateWeight"] = -1
                pilot["blueprints"] = blueprints
            }
        }
        return try! ContentPackage.build(version: "2.0.1", libraries: sources.libraries, beats: sources.beats)
    }
}

@MainActor
final class RemoteContentTests: XCTestCase {

    private let publisher = TestPublisher()
    private var directory: URL!
    private var store: RemoteContentStore!
    private var defaults: UserDefaults!
    private var suite = ""
    private let root = "https://content.test/content/"

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("RemoteContentTests-\(UUID())")
        store = RemoteContentStore(directory: directory)
        suite = "RemoteContentTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        StubContentProtocol.responses = [:]
        StubContentProtocol.requests = []
    }

    override func tearDown() async throws {
        store.eraseAll()
        defaults.removePersistentDomain(forName: suite)
    }

    // MARK: - Helpers

    private var config: RemoteContentConfig { RemoteContentConfig.make(base: root, key: publisher.publicKeyBase64)! }

    private func service(now: @escaping () -> Date = Date.init) -> RemoteContentService {
        RemoteContentService(config: config, store: store, session: StubContentProtocol.session(),
                             defaults: defaults, now: now, bundledCatalog: { TestPackages.bundled })
    }

    private func serve(_ feed: Data, signature: Data? = nil) {
        StubContentProtocol.responses["/content/feed.json"] = (200, feed)
        StubContentProtocol.responses["/content/feed.json.sig"] = (200, signature ?? publisher.sign(feed))
    }

    private func serve(package: Data, at reference: CatalogPackageRef) {
        StubContentProtocol.responses["/content/" + reference.path] = (200, package)
    }

    private func resolver() -> CatalogSourceResolver {
        CatalogSourceResolver(store: store, key: config.key)
    }

    // MARK: - Configuration

    func testNoKeyMeansNoRemoteContent() async {
        XCTAssertNil(RemoteContentConfig.make(base: root, key: ""))
        XCTAssertNil(RemoteContentConfig.make(base: root, key: "not-a-key"))
        let disabled = RemoteContentService(config: nil, store: store, session: StubContentProtocol.session(),
                                            defaults: defaults, bundledCatalog: { nil })
        let outcome = await disabled.refresh()
        XCTAssertEqual(outcome, .disabled)
        XCTAssertTrue(StubContentProtocol.requests.isEmpty)
    }

    func testPlainHTTPIsRefused() {
        XCTAssertNil(RemoteContentConfig.make(base: "http://content.test/content", key: publisher.publicKeyBase64))
        XCTAssertNil(RemoteContentConfig.make(base: "https://content.test/content?u=1", key: publisher.publicKeyBase64))
        XCTAssertEqual(config.feedURL.absoluteString, "https://content.test/content/feed.json")
    }

    func testTheShippedInfoPlistHasNoKeyYet() {
        // Until the publisher's key is put in, the app takes no remote content.
        let key = Bundle.main.object(forInfoDictionaryKey: RemoteContentConfig.signingKeyKey) as? String
        XCTAssertNotNil(key, "Info.plist must declare the key, even empty")
    }

    // MARK: - Feed

    func testASignedFeedIsKept() async {
        serve(TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")]))
        let content = service()

        let outcome = await content.refresh()

        XCTAssertEqual(outcome, .updated(feedVersion: 1))
        XCTAssertEqual(content.feed?.stories.map(\.title), ["A"])
        XCTAssertEqual(store.feed(key: config.key)?.feedVersion, 1)
    }

    func testTheRequestsCarryNothingAboutTheFamily() async {
        serve(TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")]))
        await service().refresh()
        XCTAssertFalse(StubContentProtocol.requests.isEmpty)
        for url in StubContentProtocol.requests {
            XCTAssertNil(url.query, "\(url)")
        }
    }

    func testATamperedFeedIsRefused() async {
        let signed = TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")])
        let altered = TestPublisher.feedData(version: 1, stories: [TestPublisher.story("B")])
        serve(altered, signature: publisher.sign(signed))

        let outcome = await service().refresh()

        XCTAssertEqual(outcome, .failed)
        XCTAssertNil(store.feed(key: config.key))
    }

    func testAFeedSignedWithAnotherKeyIsRefused() async {
        let data = TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")])
        serve(data, signature: TestPublisher().sign(data))
        let outcome = await service().refresh()
        XCTAssertEqual(outcome, .failed)
    }

    func testANewerSchemaIsRefused() async {
        serve(TestPublisher.feedData(version: 1, stories: [], schema: ContentFeed.supportedSchemaVersion + 1))
        let outcome = await service().refresh()
        XCTAssertEqual(outcome, .failed)
    }

    func testAnOlderFeedIsNotReplayed() async {
        serve(TestPublisher.feedData(version: 5, stories: [TestPublisher.story("Yeni")]))
        let content = service()
        await content.refresh()

        serve(TestPublisher.feedData(version: 4, stories: [TestPublisher.story("Eski")]))
        let outcome = await content.refresh()

        XCTAssertEqual(outcome, .unchanged)
        XCTAssertEqual(store.feed(key: config.key)?.feedVersion, 5)
        XCTAssertEqual(content.feed?.stories.map(\.title), ["Yeni"])
    }

    func testOfflineTheLastFeedIsRead() async {
        serve(TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")]))
        await service().refresh()

        StubContentProtocol.responses = [:]
        let relaunched = service()
        let outcome = await relaunched.refresh()

        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(relaunched.feed?.stories.map(\.title), ["A"])
    }

    func testOneUnreadableStoryDoesNotTakeTheFeedDown() throws {
        var object = try JSONSerialization.jsonObject(
            with: TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A"), TestPublisher.story("B")])
        ) as! [String: Any]
        var stories = object["stories"] as! [[String: Any]]
        stories[1]["category"] = "a-category-from-the-future"
        object["stories"] = stories
        let data = try JSONSerialization.data(withJSONObject: object)

        let feed = try ContentFeed.verified(data, signature: publisher.sign(data), key: config.key)
        XCTAssertEqual(feed.stories.map(\.title), ["A"])
    }

    func testDuplicateStoriesAreRefused() {
        let id = UUID()
        let data = TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A", id: id),
                                                                TestPublisher.story("B", id: id)])
        XCTAssertThrowsError(try ContentFeed.verified(data, signature: publisher.sign(data), key: config.key))
    }

    func testAPackagePathOutsideTheCatalogFolderIsRefused() {
        for path in ["../secret.json", "https://elsewhere.test/x.json", "catalog/../x.json", "catalog/x.json?u=1"] {
            let reference = CatalogPackageRef(version: "2.0.1", schemaVersion: 1, path: path,
                                              sha256: String(repeating: "a", count: 64))
            let data = TestPublisher.feedData(version: 1, stories: [], package: reference)
            XCTAssertThrowsError(try ContentFeed.verified(data, signature: publisher.sign(data), key: config.key), path)
        }
    }

    func testForegroundRunsAreSpacedOut() async {
        serve(TestPublisher.feedData(version: 1, stories: [TestPublisher.story("A")]))
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let content = service(now: { now })

        let first = await content.refreshIfDue()
        XCTAssertEqual(first, .updated(feedVersion: 1))
        now += 10 * 60
        let soon = await content.refreshIfDue()
        XCTAssertEqual(soon, .skipped)
        now += RemoteContentService.minimumInterval
        let later = await content.refreshIfDue()
        XCTAssertEqual(later, .unchanged)
    }

    // MARK: - Catalog package

    func testANewerPackageIsStagedAndUsedFromTheNextLaunch() async throws {
        let package = TestPackages.newer()
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        serve(package: package, at: reference)

        await service().refresh()

        XCTAssertNotNil(store.stagedPackage)
        XCTAssertNil(store.activePackage, "Nothing changes under a running session")

        let resolved = try resolver().resolve()
        XCTAssertTrue(resolved.fromPackage)
        XCTAssertEqual(resolved.result.catalog.version, "2.0.1")
        XCTAssertEqual(resolved.result.report.source, .remotePackage("2.0.1"))
        XCTAssertNil(store.stagedPackage)
        XCTAssertNotNil(store.activePackage)
    }

    func testAPackageThatIsNotThePublishedOneIsNotStaged() async {
        let package = TestPackages.newer()
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        var altered = package
        altered.append(contentsOf: Data(" ".utf8))
        serve(package: altered, at: reference)

        await service().refresh()

        XCTAssertNil(store.stagedPackage)
        XCTAssertEqual(defaults.stringArray(forKey: RemoteContentService.rejectedPackagesKey), [reference.sha256])
    }

    func testABrokenPackageIsNotStaged() async throws {
        let package = TestPackages.newer(breakWeight: true)
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        serve(package: package, at: reference)

        await service().refresh()

        XCTAssertNil(store.stagedPackage)
        let resolved = try resolver().resolve()
        XCTAssertFalse(resolved.fromPackage)
        XCTAssertEqual(resolved.result.catalog.version, TestPackages.bundled.catalog.version)
    }

    func testARefusedPackageIsNotDownloadedAgain() async {
        let package = TestPackages.newer(breakWeight: true)
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        serve(package: package, at: reference)
        let content = service()
        await content.refresh()

        StubContentProtocol.requests = []
        await content.refresh()

        XCTAssertFalse(StubContentProtocol.requests.contains { $0.path.hasSuffix(reference.path) })
    }

    func testAPackageThatFailedToDownloadIsTriedAgain() async {
        let package = TestPackages.newer()
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        let content = service()
        await content.refresh()
        XCTAssertNil(store.stagedPackage)

        serve(package: package, at: reference)
        await content.refresh()
        XCTAssertNotNil(store.stagedPackage)
    }

    func testWithdrawingThePackageGivesTheBundleBack() async throws {
        let package = TestPackages.newer()
        let reference = TestPublisher.reference(for: package)
        serve(TestPublisher.feedData(version: 1, stories: [], package: reference))
        serve(package: package, at: reference)
        let content = service()
        await content.refresh()
        XCTAssertTrue(try resolver().resolve().fromPackage)

        serve(TestPublisher.feedData(version: 2, stories: [], package: nil))
        await content.refresh()

        XCTAssertNil(store.activePackage)
        XCTAssertFalse(try resolver().resolve().fromPackage)
    }

    func testAnActivePackageTheFeedDoesNotNameIsDropped() throws {
        let package = TestPackages.newer()
        let feed = TestPublisher.feedData(version: 1, stories: [],
                                          package: TestPublisher.reference(for: TestPackages.newer(breakWeight: true)))
        try store.saveFeed(feed, signature: publisher.sign(feed))
        try store.stage(package)

        let resolved = try resolver().resolve()

        XCTAssertFalse(resolved.fromPackage)
        XCTAssertNil(store.activePackage)
    }

    func testWithoutAKeyTheBundleServesEvenWithAPackageOnDisk() throws {
        let package = TestPackages.newer()
        let feed = TestPublisher.feedData(version: 1, stories: [], package: TestPublisher.reference(for: package))
        try store.saveFeed(feed, signature: publisher.sign(feed))
        try store.stage(package)

        let resolved = try CatalogSourceResolver(store: store, key: nil).resolve()
        XCTAssertFalse(resolved.fromPackage)
    }
}
