import XCTest
@testable import MagicPaper

/// E1: the file store becomes the library's live copy.
///
/// The measure is the one the plan sets: a child's stories are never lost.
/// Every test runs against a temporary directory and a scratch
/// `UserDefaults`, never the simulator's real library.
@MainActor
final class LibraryCutoverTests: XCTestCase {

    // MARK: - Fixtures

    private var root: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var clock = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LibraryCutoverTests-\(UUID().uuidString)", isDirectory: true)
        suiteName = "LibraryCutoverTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        clock = Date(timeIntervalSince1970: 1_700_000_000)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        // Tests that lock a file or a folder unlock it themselves; this makes
        // sure a failed assertion cannot leave the temp tree undeletable.
        if let items = FileManager.default.enumerator(atPath: root.path) {
            for case let item as String in items {
                try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: root.appendingPathComponent(item).path)
            }
        }
        try? FileManager.default.removeItem(at: root)
        try super.tearDownWithError()
    }

    private func makeStore() throws -> LibraryFileStore {
        try LibraryFileStore(root: root)
    }

    /// A new launch: a fresh store (no digests in memory) and a fresh
    /// migration that reads the marker back.
    private func launch(cutoverEnabled: Bool = true) throws -> LibraryMigration {
        let migration = LibraryMigration(
            defaults: defaults, store: try makeStore(), now: { [unowned self] in self.clock },
            cutoverEnabled: cutoverEnabled
        )
        migration.run()
        return migration
    }

    /// Two launches with the gate open: pending → verified → diskAuthoritative.
    @discardableResult
    private func cutOver(
        _ stories: [Story], favorites: Set<String> = []
    ) throws -> LibraryMigration {
        try seedLegacy(stories: stories, favorites: favorites)
        _ = try launch()
        let migration = try launch()
        XCTAssertEqual(migration.state.phase, .diskAuthoritative)
        return migration
    }

    private func story(_ title: String, id: UUID = UUID(), createdAt: Date? = nil) -> Story {
        var story = Story(
            id: id, title: title, childName: "Yeliz", childProfileID: UUID(),
            theme: .fantasy, language: .turkish, status: .completed
        )
        story.pages = (1...2).map { StoryPage(title: "\(title) \($0)", text: "\(title), \($0). sayfa", imagePrompt: "p\($0)") }
        story.lastReadPage = 1
        story.lastReadAt = Date(timeIntervalSince1970: 1_700_000_000.25)
        if let createdAt { story.createdAt = createdAt }
        return story
    }

    private func seedLegacy(stories: [Story], favorites: Set<String> = []) throws {
        defaults.set(try JSONEncoder().encode(stories), forKey: LibraryMigration.LegacyKeys.stories)
        if !favorites.isEmpty {
            defaults.set(Array(favorites), forKey: LibraryFileStore.FlagList.favorites.legacyKey)
        }
    }

    private var legacyBlob: Data? { defaults.data(forKey: LibraryMigration.LegacyKeys.stories) }

    /// JSON'u yapısıyla karşılaştırır. `JSONEncoder` sözlük anahtarlarının
    /// sırasını sabitlemez (Swift'in `Dictionary` hash tohumu her süreçte
    /// değişir), bu yüzden aynı değer iki kodlamada farklı baytlar verebilir:
    /// CI'da "967 bytes ≠ 967 bytes". Aynı içerik, aynı nesne ağacı demektir.
    private func assertSameJSON(_ written: Data?, _ expected: Data,
                                file: StaticString = #filePath, line: UInt = #line) throws {
        let written = try XCTUnwrap(written, "Eski blob yazılmadı.", file: file, line: line)
        let a = try JSONSerialization.jsonObject(with: written) as? NSObject
        let b = try JSONSerialization.jsonObject(with: expected) as? NSObject
        XCTAssertEqual(a, b, file: file, line: line)
    }

    private func storyFile(_ id: UUID) -> URL {
        root.appendingPathComponent("Stories/\(id.uuidString).json")
    }

    private func damagedFolder() -> URL {
        root.appendingPathComponent(LibraryFileStore.Kind.damagedStories.rawValue, isDirectory: true)
    }

    // MARK: - Transition

    func testAVerifiedLibraryCutsOverOnTheNextLaunch() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])

        let first = try launch()
        XCTAssertEqual(first.state.phase, .verified, "Kesişim, doğrulamayla aynı açılışta olmamalı.")
        XCTAssertNil(first.state.cutoverAt)

        clock = clock.addingTimeInterval(3600)
        let second = try launch()
        XCTAssertEqual(second.state.phase, .diskAuthoritative)
        XCTAssertEqual(second.state.cutoverAt, clock)
        XCTAssertEqual(LibraryShelf(defaults: defaults, migration: second).mode, .disk)
    }

    func testTheCutoverMarkerSurvivesANewInstance() throws {
        try cutOver([story("Deniz Feneri")])
        let reopened = LibraryMigration(defaults: defaults, store: try makeStore())
        XCTAssertEqual(reopened.state.phase, .diskAuthoritative)
        XCTAssertEqual(reopened.state.cutoverAt, clock)
    }

    func testNoCutoverWhileTheGateIsClosed() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])
        _ = try launch(cutoverEnabled: false)
        let migration = try launch(cutoverEnabled: false)

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertEqual(LibraryShelf(defaults: defaults, migration: migration).mode, .legacy)
    }

    /// A file the sync cannot delete or overwrite (not named after a story)
    /// fails the final verification; the legacy path carries on unchanged.
    func testCutoverWaitsWhileADiskFileCannotBeRead() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])
        _ = try launch()
        try Data("yarım".utf8).write(to: root.appendingPathComponent("Stories/kirik.json"))
        let before = legacyBlob

        let migration = try launch()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertNotNil(migration.state.lastFailure)
        XCTAssertEqual(legacyBlob, before)
        XCTAssertEqual(LibraryShelf(defaults: defaults, migration: migration).mode, .legacy)
    }

    /// The last legacy write before the cutover launch reaches disk.
    func testTheFinalSyncCarriesTheLastLegacyWriteAcross() throws {
        let first = story("Bir")
        try seedLegacy(stories: [first])
        _ = try launch()

        let late = story("Geç gelen")
        try seedLegacy(stories: [first, late])
        let migration = try launch()

        XCTAssertEqual(migration.state.phase, .diskAuthoritative)
        XCTAssertEqual(migration.store.storyIDsOnDisk(), [first.id, late.id])
    }

    // MARK: - The marker

    func testAMarkerWrittenBeforeE1StillDecodes() throws {
        let json = #"{"schemaVersion":1,"phase":"verified","verifiedAt":700000000,"quarantinedFiles":[]}"#
        defaults.set(Data(json.utf8), forKey: LibraryMigration.State.key)

        let state = LibraryMigration.storedState(in: defaults)
        XCTAssertEqual(state.phase, .verified)
        XCTAssertNil(state.cutoverAt)
        XCTAssertEqual(state.verifiedAt, Date(timeIntervalSinceReferenceDate: 700_000_000))
    }

    /// A phase from a newer build must not read as `.pending`: that would copy
    /// the frozen legacy blob over the live files.
    func testAnUnknownPhaseNeverFallsBackToPending() throws {
        var live = story("Deniz Feneri")
        try seedLegacy(stories: [live])
        live.lastReadPage = 5
        let store = try makeStore()
        try store.writeStory(live)
        let json = #"{"schemaVersion":2,"phase":"cloudAuthoritative"}"#
        defaults.set(Data(json.utf8), forKey: LibraryMigration.State.key)

        let migration = try launch()

        XCTAssertEqual(migration.state.phase, .diskAuthoritative)
        XCTAssertEqual(try makeStore().readStory(id: live.id)?.lastReadPage, 5, "Donmuş yedek canlı dosyanın üstüne yazıldı.")
    }

    /// Unreadable marker, story files on disk: disk is read, the legacy blob
    /// is frozen and, with no cutover date, never retired.
    func testAnUnreadableMarkerWithStoryFilesOnDiskReadsFromDisk() throws {
        let legacyOnly = story("Yalnızca eski yığında")
        let onDisk = story("Diskteki")
        try seedLegacy(stories: [legacyOnly])
        try makeStore().writeStory(onDisk)
        defaults.set(Data("çöp".utf8), forKey: LibraryMigration.State.key)
        let blob = legacyBlob

        let migration = try launch()
        XCTAssertEqual(migration.state.phase, .diskAuthoritative)
        XCTAssertNil(migration.state.cutoverAt)

        let shelf = LibraryShelf(defaults: defaults, migration: migration)
        XCTAssertEqual(shelf.mode, .disk)
        var stories = shelf.load()
        XCTAssertEqual(stories.map(\.id), [onDisk.id])
        stories[0].lastReadPage = 2
        shelf.save(stories)
        XCTAssertEqual(legacyBlob, blob, "Kesişim işareti okunamazken eski yığına yazıldı.")

        // Without a cutover date nothing is ever retired.
        clock = clock.addingTimeInterval(LibraryMigration.graceInterval * 10)
        _ = try launch()
        XCTAssertEqual(legacyBlob, blob)
    }

    /// Unreadable marker, no story file on disk, legacy blob present: the
    /// blob is the only copy, so the legacy path is taken and the migration
    /// starts again. The shelf is the child's, not the sample stories.
    func testAnUnreadableMarkerWithAnEmptyDiskReturnsToTheLegacyPath() throws {
        let stories = [story("Bir"), story("İki")]
        try seedLegacy(stories: stories)
        defaults.set(Data("çöp".utf8), forKey: LibraryMigration.State.key)
        let blob = legacyBlob

        let fresh = LibraryMigration(defaults: defaults, store: try makeStore(), now: { [unowned self] in self.clock })
        XCTAssertEqual(fresh.state.phase, .pending)

        let migration = try launch()
        XCTAssertEqual(migration.state.phase, .verified)
        let shelf = LibraryShelf(defaults: defaults, migration: migration)
        XCTAssertEqual(shelf.mode, .legacy)

        let manager = StoryGenerationManager(library: shelf, notifications: NotificationCenter())
        XCTAssertEqual(manager.stories.map(\.id), stories.map(\.id), "Raf örnek masallarla doldu.")
        XCTAssertEqual(legacyBlob, blob)
    }

    /// Unreadable marker and no store this launch: read-only, frozen copy.
    func testAnUnreadableMarkerWithoutAStoreShowsTheFrozenCopy() throws {
        let stories = [story("Bir")]
        try seedLegacy(stories: stories)
        defaults.set(Data("çöp".utf8), forKey: LibraryMigration.State.key)
        let blob = legacyBlob

        let shelf = LibraryShelf(defaults: defaults, migration: nil)
        XCTAssertEqual(shelf.mode, .readOnly)
        XCTAssertEqual(shelf.load().map(\.id), stories.map(\.id))
        shelf.save([])
        XCTAssertEqual(legacyBlob, blob)
    }

    // MARK: - Reading after cutover

    func testAfterCutoverTheShelfReadsFromDiskNewestFirst() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let t1 = Date(timeIntervalSince1970: 2_000)
        let tieB = story("B", id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B0")!, createdAt: t0)
        let tieA = story("A", id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A0")!, createdAt: t0)
        let newest = story("Yeni", createdAt: t1)
        try cutOver([tieB, newest, tieA])

        let shelf = LibraryShelf(defaults: defaults, migration: try launch())
        XCTAssertEqual(shelf.load().map(\.id), [newest.id, tieA.id, tieB.id])
    }

    func testAfterCutoverTheFrozenLegacyBlobIsNotRead() throws {
        let kept = story("Diskteki")
        try cutOver([kept])
        try seedLegacy(stories: [kept, story("Yalnızca eski yığında")])

        let shelf = LibraryShelf(defaults: defaults, migration: try launch())
        XCTAssertEqual(shelf.load().map(\.id), [kept.id])
    }

    // MARK: - Writing

    /// Before cutover the blob is written exactly as `saveStories()` always
    /// wrote it, and the shadow follows.
    func testBeforeCutoverTheShelfWritesTheLegacyBlobAsBefore() throws {
        let first = story("Bir")
        try seedLegacy(stories: [first])
        let migration = try launch()
        let shelf = LibraryShelf(defaults: defaults, migration: migration)
        XCTAssertEqual(shelf.mode, .legacy)

        let next = [story("İki"), first]
        shelf.save(next)

        try assertSameJSON(legacyBlob, try JSONEncoder().encode(next))
        XCTAssertEqual(migration.store.storyIDsOnDisk(), Set(next.map(\.id)))
        XCTAssertTrue(shelf.lastWrittenStoryIDs.isEmpty)
    }

    func testAfterCutoverSavingLeavesTheLegacyBlobUntouched() throws {
        let first = story("Bir")
        try cutOver([first])
        let before = legacyBlob
        let shelf = LibraryShelf(defaults: defaults, migration: try launch())

        var stories = shelf.load()
        stories[0].lastReadPage = 2
        stories.insert(story("Yeni"), at: 0)
        shelf.save(stories)
        shelf.flush()

        XCTAssertEqual(legacyBlob, before, "Kesişimden sonra eski yığına yazıldı.")
    }

    /// One story's progress changes: one file is written. The change keeps
    /// the record's length and sits deep in its JSON, the case a
    /// `Data.hashValue` digest (length + first 80 bytes) missed.
    func testAfterCutoverOneChangedStoryWritesOneFile() throws {
        let shelfStories = [story("Bir"), story("İki"), story("Üç")]
        try cutOver(shelfStories)
        let shelf = LibraryShelf(defaults: defaults, migration: try launch())

        var stories = shelf.load()
        shelf.save(stories)
        XCTAssertEqual(shelf.lastWrittenStoryIDs, [], "Değişmeyen raf yeniden yazıldı.")

        let changed = stories[1].id
        stories[1].lastReadPage = 2
        shelf.save(stories)

        XCTAssertEqual(shelf.lastWrittenStoryIDs, [changed])
        XCTAssertEqual(try makeStore().readStory(id: changed)?.lastReadPage, 2)
    }

    func testAfterCutoverDeletingAStoryRemovesOnlyItsFile() throws {
        let kept = story("Kalan")
        let gone = story("Silinen")
        let migration = try cutOver([kept, gone])
        let shelf = LibraryShelf(defaults: defaults, migration: try launch())

        shelf.save(shelf.load().filter { $0.id != gone.id })

        XCTAssertEqual(migration.store.storyIDsOnDisk(), [kept.id])
    }

    /// The manager's own path: a page turn after cutover writes one file and
    /// leaves `UserDefaults["stories"]` as it was.
    func testTheManagerWritesOneFileForAPageTurnAfterCutover() throws {
        let stories = [story("Bir"), story("İki")]
        try cutOver(stories)
        let before = legacyBlob
        let shelf = LibraryShelf(defaults: defaults, migration: try launch())

        let manager = StoryGenerationManager(library: shelf, notifications: NotificationCenter())
        XCTAssertEqual(Set(manager.stories.map(\.id)), Set(stories.map(\.id)))
        manager.updateLastReadPage(storyId: stories[0].id, page: 2)

        XCTAssertEqual(shelf.lastWrittenStoryIDs, [stories[0].id])
        XCTAssertEqual(legacyBlob, before)
        XCTAssertEqual(try makeStore().readStory(id: stories[0].id)?.lastReadPage, 2)
    }

    // MARK: - Damaged files

    func testADamagedFileIsSetAsideAndTheRestOfTheShelfOpens() throws {
        let good = [story("Bir"), story("İki")]
        try cutOver(good)
        let damagedID = UUID()
        let damagedBytes = Data("{\"title\": yarım".utf8)
        try damagedBytes.write(to: storyFile(damagedID))

        let migration = try launch()
        let shelf = LibraryShelf(defaults: defaults, migration: migration)
        let loaded = shelf.load()

        XCTAssertEqual(Set(loaded.map(\.id)), Set(good.map(\.id)), "Bozuk dosya rafı düşürdü.")
        XCTAssertFalse(FileManager.default.fileExists(atPath: storyFile(damagedID).path))
        let setAside = migration.store.damagedStoryFileNames()
        XCTAssertEqual(setAside.count, 1)
        XCTAssertTrue(setAside[0].hasPrefix(damagedID.uuidString))
        XCTAssertEqual(try Data(contentsOf: damagedFolder().appendingPathComponent(setAside[0])), damagedBytes)
        XCTAssertEqual(migration.state.quarantinedFiles, setAside)

        // Saves and later launches leave it alone.
        shelf.save(loaded)
        _ = try launch()
        XCTAssertEqual(try Data(contentsOf: damagedFolder().appendingPathComponent(setAside[0])), damagedBytes)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storyFile(damagedID).path))
    }

    /// When the file cannot be moved it stays where it is: hidden, never
    /// written over, never deleted.
    func testADamagedFileThatCannotBeMovedIsNeitherWrittenNorDeleted() throws {
        let good = story("Bir")
        try cutOver([good])
        let damagedID = UUID()
        let damagedBytes = Data("yarım".utf8)
        try damagedBytes.write(to: storyFile(damagedID))
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: damagedFolder().path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: damagedFolder().path) }

        let shelf = LibraryShelf(defaults: defaults, migration: try launch())
        let loaded = shelf.load()
        XCTAssertEqual(loaded.map(\.id), [good.id])

        shelf.save(loaded)
        shelf.save([])

        XCTAssertEqual(try Data(contentsOf: storyFile(damagedID)), damagedBytes)
    }

    func testRetirementWaitsWhileADamagedStoryIsSetAside() throws {
        try cutOver([story("Bir")])
        try Data("yarım".utf8).write(to: storyFile(UUID()))
        _ = LibraryShelf(defaults: defaults, migration: try launch()).load()

        clock = clock.addingTimeInterval(LibraryMigration.graceInterval + 1)
        let migration = try launch()

        XCTAssertEqual(migration.state.phase, .diskAuthoritative)
        XCTAssertNotNil(legacyBlob, "Bozuk masalın sağlam kopyası olabilecek yedek silindi.")
    }

    // MARK: - Retirement after cutover

    /// Not compared with the frozen blob: a story deleted after cutover would
    /// fail that comparison for ever.
    func testRetirementDoesNotCompareAgainstTheFrozenCopy() throws {
        let kept = story("Kalan")
        let gone = story("Silinen")
        try cutOver([kept, gone])
        let shelf = LibraryShelf(defaults: defaults, migration: try launch())
        shelf.save(shelf.load().filter { $0.id != gone.id })

        clock = clock.addingTimeInterval(LibraryMigration.graceInterval + 1)
        let migration = try launch()

        XCTAssertEqual(migration.state.phase, .legacyRetired)
        XCTAssertNil(legacyBlob)
        XCTAssertEqual(migration.store.storyIDsOnDisk(), [kept.id])
        XCTAssertEqual(LibraryShelf(defaults: defaults, migration: migration).mode, .disk)
    }

    /// The legacy-era sync deletes disk files the blob does not list. After
    /// cutover it must not run at all.
    func testTheLegacySyncNeverRunsAfterCutover() throws {
        let stories = [story("Bir"), story("İki")]
        let migration = try cutOver(stories)

        XCTAssertFalse(migration.reconcile())
        XCTAssertFalse(migration.reconcile(stories: []))
        XCTAssertEqual(migration.store.storyIDsOnDisk(), Set(stories.map(\.id)))
    }

    // MARK: - A locked device

    /// An unreadable file (what a locked device returns for a
    /// `.completeUnlessOpen` file) is not damage: it stays in place, is not
    /// touched by saves, and joins the shelf once it reads.
    func testAnUnreadableFileStaysPutAndJoinsTheShelfWhenItReads() throws {
        let open = story("Açık")
        let locked = story("Kilitli")
        try cutOver([open, locked])
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: storyFile(locked.id).path)

        let migration = try launch()
        let shelf = LibraryShelf(defaults: defaults, migration: migration)
        let loaded = shelf.load()
        XCTAssertEqual(loaded.map(\.id), [open.id])

        shelf.save(loaded)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storyFile(locked.id).path))
        XCTAssertTrue(migration.store.damagedStoryFileNames().isEmpty)

        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: storyFile(locked.id).path)
        XCTAssertEqual(shelf.recoverUnreadable().map(\.id), [locked.id])
        XCTAssertEqual(shelf.recoverUnreadable().map(\.id), [])
    }

    // MARK: - No store this launch

    func testWithoutAStoreAfterCutoverTheFrozenCopyIsShownAndNothingIsSaved() throws {
        let stories = [story("Bir"), story("İki")]
        try cutOver(stories, favorites: [stories[0].id.uuidString])
        let blob = legacyBlob
        let marker = defaults.data(forKey: LibraryMigration.State.key)

        let shelf = LibraryShelf(defaults: defaults, migration: nil)
        XCTAssertEqual(shelf.mode, .readOnly)
        XCTAssertEqual(shelf.load().map(\.id), stories.map(\.id))

        shelf.save([])
        shelf.saveFavorites([])
        XCTAssertEqual(legacyBlob, blob)
        XCTAssertEqual(defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey), [stories[0].id.uuidString])
        XCTAssertEqual(defaults.data(forKey: LibraryMigration.State.key), marker, "Evre değişti.")
    }

    func testWithoutAStoreBeforeCutoverTheLegacyPathContinues() throws {
        let first = story("Bir")
        try seedLegacy(stories: [first])

        let shelf = LibraryShelf(defaults: defaults, migration: nil)
        XCTAssertEqual(shelf.mode, .legacy)
        XCTAssertEqual(shelf.load().map(\.id), [first.id])

        let next = [story("İki"), first]
        shelf.save(next)
        try assertSameJSON(legacyBlob, try JSONEncoder().encode(next))
    }

    // MARK: - Favourites

    func testBeforeCutoverFavoritesStayInUserDefaults() throws {
        let first = story("Bir")
        try seedLegacy(stories: [first])
        let favorites = MPFavorites(library: LibraryShelf(defaults: defaults, migration: try launch()))

        favorites.toggle(first.id)

        XCTAssertEqual(defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey), [first.id.uuidString])
    }

    func testAfterCutoverFavoritesAreReadAndWrittenThroughTheStore() throws {
        let first = story("Bir")
        let second = story("İki")
        try cutOver([first, second], favorites: [first.id.uuidString])
        let migration = try launch()
        let favorites = MPFavorites(library: LibraryShelf(defaults: defaults, migration: migration))
        XCTAssertTrue(favorites.contains(first.id))

        XCTAssertTrue(favorites.toggle(second.id))

        XCTAssertEqual(try migration.store.readFlagList(.favorites), [first.id.uuidString, second.id.uuidString])
        XCTAssertEqual(
            defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey), [first.id.uuidString],
            "Kesişimden sonra eski favori anahtarına yazıldı."
        )
    }
}
