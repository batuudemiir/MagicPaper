import XCTest
@testable import MagicPaper

/// FAZ 20 · Günlük: kaldığın yer, anlatım seçimi, okuyucuya giden masal, sekmeler.
@MainActor
final class ClassicProgressTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suite: String!
    private var child = UUID()
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        super.setUp()
        suite = "ClassicProgressTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func makeStore() -> ClassicProgressStore {
        ClassicProgressStore(defaults: defaults, childID: { [unowned self] in self.child },
                             now: { [unowned self] in self.clock })
    }

    func testProgressIsSavedAndReadBack() {
        let id = UUID()
        let store = makeStore()
        store.markOpened(id, pageCount: 8, narration: .soft)
        store.saveProgress(id, page: 3)
        let again = makeStore()
        XCTAssertEqual(again.entry(id)?.page, 3)
        XCTAssertEqual(again.entry(id)?.fraction ?? 0, 0.5, accuracy: 0.001)
        XCTAssertFalse(again.entry(id)?.isFinished ?? true)
    }

    func testReachingTheLastPageFinishes() {
        let id = UUID()
        let store = makeStore()
        store.markOpened(id, pageCount: 4, narration: .soft)
        store.saveProgress(id, page: 9)
        XCTAssertEqual(store.entry(id)?.page, 3)
        XCTAssertTrue(store.finishedIDs.contains(id))
        XCTAssertTrue(store.inProgress().isEmpty)
    }

    func testContinueReadingIsNewestFirstAndSkipsUnstarted() {
        let a = UUID(), b = UUID(), c = UUID()
        let store = makeStore()
        store.markOpened(a, pageCount: 6, narration: .soft); store.saveProgress(a, page: 2)
        clock += 60
        store.markOpened(b, pageCount: 6, narration: .soft); store.saveProgress(b, page: 1)
        clock += 60
        store.markOpened(c, pageCount: 6, narration: .soft)
        XCTAssertEqual(store.inProgress().map(\.id), [b, a])
    }

    func testChangingNarrationStartsOver() {
        let id = UUID()
        let store = makeStore()
        store.markOpened(id, pageCount: 6, narration: .soft)
        store.saveProgress(id, page: 4)
        store.setNarration(.classic, for: id)
        XCTAssertEqual(store.narration(for: id), .classic)
        XCTAssertEqual(store.entry(id)?.page, 0)
    }

    func testEachChildHasItsOwnBook() {
        let id = UUID()
        let store = makeStore()
        store.markOpened(id, pageCount: 6, narration: .soft)
        store.saveProgress(id, page: 2)
        child = UUID()
        XCTAssertNil(store.entry(id))
    }

    // MARK: - Okuyucu

    func testReaderStoryCarriesPagesCoverAndSavedPage() {
        let tale = ClassicsCatalogTests.tale(1, "Rapunzel", classic: true)
        let story = ClassicReading.story(for: tale, narration: .classic, childID: child, childName: "İrem", savedPage: 1)
        XCTAssertEqual(story.id, tale.id)
        XCTAssertEqual(story.pages.map(\.text), ["Bir.", "İki.", "Üç."])
        XCTAssertEqual(story.lastReadPage, 1)
        XCTAssertNil(story.origin, "Günlük masalları motor masalı değil")
        XCTAssertEqual(story.childProfileID, child)
    }

    // MARK: - Sekmeler

    func testTabsRoundTrip() {
        for tab in MPTab.allCases {
            XCTAssertEqual(MPTab(tab.kidTab), tab)
        }
        XCTAssertEqual(MPTab.allCases.map(\.label), ["Ana sayfa", "Günlük", "Kitaplık", "Köşem"])
    }

    func testKidCornerIsATab() {
        let app = MPAppState()
        app.showKidCorner = true
        XCTAssertEqual(app.tab, .corner)
        app.showKidCorner = false
        XCTAssertEqual(app.tab, .home)
        app.tab = .gunluk
        app.showKidCorner = false
        XCTAssertEqual(app.tab, .gunluk, "köşe kapalıyken başka sekmeye dokunmaz")
    }
}
