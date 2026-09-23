import XCTest
@testable import MagicPaper

/// The migration that moves a child's library out of `UserDefaults`.
///
/// Written before the migration was allowed to run anywhere near a real device,
/// because the thing being moved is the only copy of stories a family cannot
/// make again. Every test here is a way the previous two attempts at this in
/// the codebase went wrong: a delete with no backup (`SGM:939`) and a backup
/// with no delete (`stories.undecodable.*`).
@MainActor
final class LibraryMigrationTests: XCTestCase {

    // MARK: - Fixtures

    private var root: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LibraryMigrationTests-\(UUID().uuidString)", isDirectory: true)
        suiteName = "LibraryMigrationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: root)
        try super.tearDownWithError()
    }

    private func makeStore() throws -> LibraryFileStore {
        try LibraryFileStore(root: root)
    }

    private func makeMigration(
        store: LibraryFileStore,
        now: @escaping () -> Date = Date.init,
        cutoverEnabled: Bool = false
    ) -> LibraryMigration {
        LibraryMigration(defaults: defaults, store: store, now: now, cutoverEnabled: cutoverEnabled)
    }

    private func story(_ title: String, pages: Int = 2) -> Story {
        var story = Story(
            title: title,
            childName: "Yeliz",
            childProfileID: UUID(),
            theme: .fantasy,
            language: .turkish,
            status: .completed
        )
        story.pages = (1...pages).map { index in
            StoryPage(
                title: "\(title) \(index)",
                text: "\(title) — \(index). sayfa",
                imagePrompt: "prompt \(index)"
            )
        }
        story.lastReadPage = 1
        story.lastReadAt = Date(timeIntervalSince1970: 1_700_000_000.123456)
        return story
    }

    private func seedLegacy(
        stories: [Story],
        favorites: Set<String> = [],
        approvals: Set<String> = []
    ) throws {
        // The legacy writer is a plain `JSONEncoder`; the fixture has to be
        // written exactly the way `saveStories()` writes it or the test proves
        // nothing about the real blob.
        defaults.set(try JSONEncoder().encode(stories), forKey: LibraryMigration.LegacyKeys.stories)
        if !favorites.isEmpty {
            defaults.set(Array(favorites), forKey: LibraryFileStore.FlagList.favorites.legacyKey)
        }
        if !approvals.isEmpty {
            defaults.set(Array(approvals), forKey: LibraryFileStore.FlagList.approvals.legacyKey)
        }
    }

    // MARK: - Empty state

    /// A brand-new install has no `stories` key at all. That is a library with
    /// nothing in it, not a failure, and the migration has to finish.
    func testAnEmptyLibraryMigratesAndIsMarkedVerified() throws {
        let store = try makeStore()
        let migration = makeMigration(store: store)

        migration.run()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertNil(migration.state.lastFailure)
        XCTAssertTrue(store.readAllStories().stories.isEmpty)
    }

    /// And it must not invent one. An empty migration that wrote a story would
    /// be indistinguishable from one that lost track of whose library it held.
    func testAnEmptyLibraryWritesNoStoryFiles() throws {
        let store = try makeStore()
        makeMigration(store: store).run()
        XCTAssertTrue(store.storyIDsOnDisk().isEmpty)
    }

    // MARK: - Populated state

    func testAPopulatedLibraryIsCopiedToDiskInFull() throws {
        let shelf = [story("Deniz Feneri"), story("Orman"), story("Gökyüzü", pages: 5)]
        try seedLegacy(stories: shelf, favorites: [shelf[0].id.uuidString], approvals: [shelf[1].id.uuidString])

        let store = try makeStore()
        let migration = makeMigration(store: store)
        migration.run()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertEqual(store.storyIDsOnDisk(), Set(shelf.map(\.id)))
        XCTAssertEqual(try store.readFlagList(.favorites), [shelf[0].id.uuidString])
        XCTAssertEqual(try store.readFlagList(.approvals), [shelf[1].id.uuidString])
    }

    /// `Story: Equatable` compares ids and nothing else, so "the story is on
    /// disk" is a much weaker claim than it looks. The prose is the product.
    func testTheCopyKeepsThePagesAndNotJustTheIdentity() throws {
        let original = story("Gökyüzü", pages: 5)
        try seedLegacy(stories: [original])

        let store = try makeStore()
        makeMigration(store: store).run()

        let restored = try XCTUnwrap(try store.readStory(id: original.id))
        XCTAssertEqual(restored.pages.count, 5)
        XCTAssertEqual(restored.pages.map(\.text), original.pages.map(\.text))
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.childProfileID, original.childProfileID)
        XCTAssertEqual(restored.lastReadPage, original.lastReadPage)
    }

    /// Sub-second precision survives. `lastReadAt` orders the home screen's
    /// "where you left off" card, and an ISO-8601 round trip would round it.
    func testTheCopyKeepsFullDatePrecision() throws {
        let original = story("Gökyüzü")
        try seedLegacy(stories: [original])

        let store = try makeStore()
        makeMigration(store: store).run()

        let restored = try XCTUnwrap(try store.readStory(id: original.id))
        XCTAssertEqual(
            try XCTUnwrap(restored.lastReadAt).timeIntervalSince1970,
            try XCTUnwrap(original.lastReadAt).timeIntervalSince1970,
            accuracy: 0.000001
        )
    }

    /// The whole point of the ordering. Nothing is removed at the write step.
    func testTheLegacyStoreIsUntouchedByAVerifiedMigration() throws {
        let shelf = [story("Deniz Feneri")]
        try seedLegacy(stories: shelf, favorites: ["x"], approvals: ["y"])
        let before = defaults.data(forKey: LibraryMigration.LegacyKeys.stories)

        makeMigration(store: try makeStore()).run()

        XCTAssertEqual(defaults.data(forKey: LibraryMigration.LegacyKeys.stories), before)
        XCTAssertEqual(defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey), ["x"])
        XCTAssertEqual(defaults.stringArray(forKey: LibraryFileStore.FlagList.approvals.legacyKey), ["y"])
    }

    // MARK: - Idempotence

    func testRunningTwiceChangesNothing() throws {
        let shelf = [story("Deniz Feneri"), story("Orman")]
        try seedLegacy(stories: shelf)

        let store = try makeStore()
        let first = makeMigration(store: store)
        first.run()
        let markedAt = first.state.verifiedAt

        let second = makeMigration(store: store)
        second.run()

        XCTAssertEqual(second.state.phase, .verified)
        XCTAssertEqual(second.state.verifiedAt, markedAt, "İkinci koşu işareti yeniden yazdı.")
        XCTAssertEqual(store.storyIDsOnDisk(), Set(shelf.map(\.id)))
    }

    /// A fresh process reads the marker back rather than starting over.
    func testTheMarkerSurvivesANewInstance() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])
        makeMigration(store: try makeStore()).run()

        let reopened = makeMigration(store: try makeStore())
        XCTAssertEqual(reopened.state.phase, .verified)
    }

    // MARK: - Interruption

    /// The write step carries no marker precisely so that a run killed halfway
    /// through is simply repeated. The second run must finish the job, not
    /// discover a half-moved library.
    func testAnInterruptedCopyIsCompletedByTheNextRun() throws {
        let shelf = [story("Bir"), story("İki"), story("Üç")]
        try seedLegacy(stories: shelf)

        // Simulate the crash: one story on disk, no marker.
        let store = try makeStore()
        try store.writeStory(shelf[0])
        XCTAssertNil(defaults.data(forKey: LibraryMigration.State.key))

        let migration = makeMigration(store: try makeStore())
        migration.run()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertEqual(store.storyIDsOnDisk(), Set(shelf.map(\.id)))
    }

    /// And a run interrupted before the marker leaves the legacy store whole,
    /// which is the property that makes repeating it safe.
    func testAnInterruptedCopyLeavesTheLegacyStoreIntact() throws {
        let shelf = [story("Bir"), story("İki")]
        try seedLegacy(stories: shelf)
        let before = defaults.data(forKey: LibraryMigration.LegacyKeys.stories)

        let store = try makeStore()
        try store.writeStory(shelf[0])

        XCTAssertEqual(defaults.data(forKey: LibraryMigration.LegacyKeys.stories), before)
    }

    // MARK: - Damaged records

    /// A blob that will not decode is not an empty library. Marking the
    /// migration done over it would turn a recoverable loss into a permanent
    /// one — the exact shape of the bug this replaces.
    func testAnUndecodableLegacyBlobStopsTheMigration() throws {
        defaults.set(Data("bu JSON değil".utf8), forKey: LibraryMigration.LegacyKeys.stories)

        let store = try makeStore()
        let migration = makeMigration(store: store)
        migration.run()

        XCTAssertEqual(migration.state.phase, .pending, "Bozuk kaynağın üzerine 'tamamlandı' yazıldı.")
        XCTAssertNotNil(migration.state.lastFailure)
        XCTAssertNotNil(defaults.data(forKey: LibraryMigration.LegacyKeys.stories), "Bozuk veri silindi.")
    }

    /// A damaged file on the target side must fail verification rather than be
    /// skipped. `readAllStories` drops it for the reader's sake; the migration
    /// is not a reader.
    func testADamagedFileOnDiskFailsVerification() throws {
        let shelf = [story("Deniz Feneri")]
        try seedLegacy(stories: shelf)

        let store = try makeStore()
        try Data("yarım".utf8).write(
            to: store.directory(.stories).appendingPathComponent("\(UUID().uuidString).json")
        )

        let migration = makeMigration(store: store)
        migration.run()

        XCTAssertEqual(migration.state.phase, .pending)
        XCTAssertFalse(migration.state.quarantinedFiles.isEmpty, "Bozuk dosya rapor edilmedi.")
    }

    /// The store reports what it skipped instead of skipping it silently.
    func testTheStoreNamesTheFilesItCouldNotRead() throws {
        let store = try makeStore()
        try store.writeStory(story("Sağlam"))
        try Data("yarım".utf8).write(
            to: store.directory(.stories).appendingPathComponent("\(UUID().uuidString).json")
        )

        let result = store.readAllStories()
        XCTAssertEqual(result.stories.count, 1)
        XCTAssertEqual(result.failures.count, 1)
    }

    /// `nil` must mean "never written" and nothing else. When it also means
    /// "damaged", the character store answers it by minting a fresh
    /// `CharacterVersionID` and the child's face changes for good.
    func testADamagedRecordThrowsRatherThanReadingAsAbsent() throws {
        let store = try makeStore()
        let id = UUID()
        XCTAssertNil(try store.readStory(id: id), "Hiç yazılmamış kayıt nil olmalı.")

        try Data("yarım".utf8).write(
            to: store.directory(.stories).appendingPathComponent("\(id.uuidString).json")
        )
        XCTAssertThrowsError(try store.readStory(id: id), "Bozuk kayıt 'yok' diye okundu.")
    }

    // MARK: - The oversized blob

    /// `SGM:939` deleted this outright. It now gets copied and kept.
    func testAnOversizedBlobIsCopiedAndTheKeyIsKept() throws {
        let blob = Data(repeating: 0x41, count: LibraryMigration.oversizedThreshold + 1)
        defaults.set(blob, forKey: LibraryMigration.LegacyKeys.stories)

        let store = try makeStore()
        let migration = makeMigration(store: store)
        migration.run()

        XCTAssertEqual(
            defaults.data(forKey: LibraryMigration.LegacyKeys.stories), blob,
            "Dört megabaytın üstündeki kütüphane yine yedeksiz silindi."
        )
        XCTAssertEqual(store.quarantinedFileNames().count, 1)
    }

    /// Once, not once per launch — otherwise the quarantine is the new
    /// unbounded backup.
    func testAnOversizedBlobIsNotCopiedAgainOnEveryLaunch() throws {
        let blob = Data(repeating: 0x41, count: LibraryMigration.oversizedThreshold + 1)
        defaults.set(blob, forKey: LibraryMigration.LegacyKeys.stories)

        let store = try makeStore()
        makeMigration(store: store).run()
        makeMigration(store: store).run()
        makeMigration(store: store).run()

        XCTAssertEqual(store.quarantinedFileNames().count, 1)
    }

    func testQuarantineIsPruned() throws {
        let store = try makeStore()
        for index in 0..<8 {
            try store.quarantine(Data("\(index)".utf8), named: "blob-\(index).json")
        }
        store.pruneQuarantine(keeping: 3)
        XCTAssertLessThanOrEqual(store.quarantinedFileNames().count, 3)
    }

    // MARK: - The grace window

    /// While reads still come from `UserDefaults`, the shadow has to follow
    /// deletions too. Settings' "delete all data" clears the legacy keys; if
    /// only additions were copied, a parent told their data was gone would
    /// still have their child's stories sitting on disk.
    func testErasingTheLegacyStoreErasesTheShadowOnTheNextRun() throws {
        let shelf = [story("Deniz Feneri"), story("Orman")]
        try seedLegacy(stories: shelf, favorites: [shelf[0].id.uuidString])

        let store = try makeStore()
        makeMigration(store: store).run()
        XCTAssertEqual(store.storyIDsOnDisk().count, 2)

        // What `SettingsView.clearAll()` does.
        for key in LibraryMigration.LegacyKeys.migrated {
            defaults.removeObject(forKey: key)
        }
        makeMigration(store: store).run()

        XCTAssertTrue(store.storyIDsOnDisk().isEmpty, "Silinen kütüphane diskte kaldı.")
        XCTAssertEqual(try store.readFlagList(.favorites), [])
    }

    func testDeletingOneStoryRemovesItsFileOnTheNextSync() throws {
        let shelf = [story("Kalan"), story("Silinen")]
        try seedLegacy(stories: shelf)

        let store = try makeStore()
        let migration = makeMigration(store: store)
        migration.run()

        try seedLegacy(stories: [shelf[0]])
        migration.reconcile()

        XCTAssertEqual(store.storyIDsOnDisk(), [shelf[0].id])
    }

    // MARK: - Retirement

    /// Step five is written now and gated, not written later. This is the test
    /// that it exists at all.
    func testTheLegacyStoreIsRetiredOnceTheGraceWindowHasPassed() throws {
        try seedLegacy(stories: [story("Deniz Feneri")], favorites: ["x"])

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var clock = start
        let store = try makeStore()
        let migration = makeMigration(store: store, now: { clock }, cutoverEnabled: true)
        migration.run()
        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertNotNil(defaults.data(forKey: LibraryMigration.LegacyKeys.stories))

        clock = start.addingTimeInterval(LibraryMigration.graceInterval + 1)
        migration.run()

        XCTAssertEqual(migration.state.phase, .legacyRetired)
        for key in LibraryMigration.LegacyKeys.migrated {
            XCTAssertNil(defaults.object(forKey: key), "'\(key)' emeklilikten sonra duruyor.")
        }
    }

    func testTheLegacyStoreSurvivesTheGraceWindow() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var clock = start
        let migration = makeMigration(store: try makeStore(), now: { clock }, cutoverEnabled: true)
        migration.run()

        clock = start.addingTimeInterval(LibraryMigration.graceInterval - 60)
        migration.run()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertNotNil(defaults.data(forKey: LibraryMigration.LegacyKeys.stories))
    }

    /// The gate itself. This wave ships with the read path still on
    /// `UserDefaults`, so retirement must not fire however much time passes.
    func testNothingIsRetiredWhileTheReadPathIsStillTheLegacyStore() throws {
        try seedLegacy(stories: [story("Deniz Feneri")])

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var clock = start
        let migration = makeMigration(store: try makeStore(), now: { clock }, cutoverEnabled: false)
        migration.run()

        clock = start.addingTimeInterval(LibraryMigration.graceInterval * 10)
        migration.run()

        XCTAssertEqual(migration.state.phase, .verified)
        XCTAssertNotNil(defaults.data(forKey: LibraryMigration.LegacyKeys.stories))
    }

    func testTheShippedBuildKeepsTheLegacyStore() {
        XCTAssertFalse(
            LibraryMigration.readPathIsAuthoritative,
            "Okuma yolu diske taşınmadan eski kopya emekliye ayrılamaz: "
            + "SettingsView.clearAll ve favori/onay yazıcıları henüz bu depoyu bilmiyor."
        )
    }

    /// Nothing is removed on the strength of a marker alone.
    func testRetirementIsRefusedIfTheShadowNoLongerMatches() throws {
        let shelf = [story("Deniz Feneri")]
        try seedLegacy(stories: shelf)

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var clock = start
        let store = try makeStore()
        let migration = makeMigration(store: store, now: { clock }, cutoverEnabled: true)
        migration.run()

        // A book appears in the legacy store that never reached disk, and the
        // sync is skipped: retirement must not delete the only copy of it.
        try seedLegacy(stories: shelf + [story("Sonradan")])
        clock = start.addingTimeInterval(LibraryMigration.graceInterval + 1)

        XCTAssertFalse(migration.retireLegacyIfDue())
        XCTAssertNotNil(defaults.data(forKey: LibraryMigration.LegacyKeys.stories))
    }

    // MARK: - Recovery backups

    /// `stories.undecodable.*` grew without limit and nothing ever read one.
    func testUndecodableBackupsAreCapped() {
        for offset in 0..<7 {
            defaults.set(
                Data("\(offset)".utf8),
                forKey: "\(StoryGenerationManager.undecodableBackupPrefix)\(1_700_000_000 + offset)"
            )
        }

        StoryGenerationManager.pruneUndecodableBackups(keeping: 3, in: defaults)

        let remaining = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(StoryGenerationManager.undecodableBackupPrefix) }
        XCTAssertEqual(remaining.count, 3)
        // The newest survive: the oldest is the one furthest from the fault,
        // but three whole libraries in `UserDefaults` is already the ceiling.
        XCTAssertTrue(remaining.contains("\(StoryGenerationManager.undecodableBackupPrefix)1700000006"))
        XCTAssertFalse(remaining.contains("\(StoryGenerationManager.undecodableBackupPrefix)1700000000"))
    }

    /// Timestamps are numbers. Sorted as strings, "999999999" outranks
    /// "1000000000" and the prune keeps the wrong three.
    func testBackupPruningComparesTimestampsAsNumbers() {
        let older = "\(StoryGenerationManager.undecodableBackupPrefix)999999999"
        let newer = "\(StoryGenerationManager.undecodableBackupPrefix)1000000000"
        defaults.set(Data(), forKey: older)
        defaults.set(Data(), forKey: newer)

        StoryGenerationManager.pruneUndecodableBackups(keeping: 1, in: defaults)

        XCTAssertNotNil(defaults.object(forKey: newer))
        XCTAssertNil(defaults.object(forKey: older))
    }

    // MARK: - Erasure

    func testEraseRemovesEverythingTheStoreHolds() throws {
        let store = try makeStore()
        try store.writeStory(story("Deniz Feneri"))
        try store.writeFlagList(["x"], as: .favorites)
        try store.quarantine(Data("y".utf8), named: "blob.json")

        try store.eraseEverything()

        XCTAssertTrue(store.storyIDsOnDisk().isEmpty)
        XCTAssertNil(try store.readFlagList(.favorites))
        XCTAssertTrue(store.quarantinedFileNames().isEmpty)
    }
}
