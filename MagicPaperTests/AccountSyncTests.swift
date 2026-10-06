import XCTest
import StoryEngine
@testable import MagicPaper

/// Hesap ve senkron, eşitleme kuralları (FAZ 16 §3).
///
/// Kabul: iki cihazda aynı hesapla kütüphane eşleşiyor; çevrimdışı yazılan
/// masal bağlantı gelince gidiyor. Çakışmada son yazan kazanır, masal metni
/// değişmez, silme iz olarak taşınır.
@MainActor
final class AccountSyncTests: XCTestCase {

    private let t0 = Date(timeIntervalSince1970: 1_759_780_000)
    private func key(_ c: SyncCollection, _ id: String) -> SyncKey { SyncKey(collection: c, id: id) }
    private func ms(_ date: Date) -> Int64 { SyncPlanner.milliseconds(date) }

    // MARK: - Planner

    func testANewLocalRecordIsSent() {
        let plan = SyncPlanner.plan(
            local: [LocalSyncRecord(key: key(.children, "c1"), payload: "{\"a\":1}")],
            remote: [], ledger: SyncLedger(ownerUID: "u"), now: t0)
        XCTAssertEqual(plan.push.map(\.key), [key(.children, "c1")])
        XCTAssertEqual(plan.push.first?.payload, "{\"a\":1}")
        XCTAssertTrue(plan.apply.isEmpty)
        XCTAssertEqual(plan.ledger[key(.children, "c1")]?.digest, SyncDigest.of("{\"a\":1}"))
    }

    func testANewRemoteRecordIsBroughtHere() {
        let remote = RemoteSyncRecord(key: key(.stories, "s1"), payload: "{}", updatedAt: 5, serverUpdatedAt: t0)
        let plan = SyncPlanner.plan(local: [], remote: [remote], ledger: SyncLedger(), now: t0)
        XCTAssertEqual(plan.apply, [remote])
        XCTAssertTrue(plan.push.isEmpty)
        XCTAssertEqual(plan.ledger.highWater["stories"], t0)
    }

    func testNothingChangedDoesNothing() {
        var ledger = SyncLedger()
        ledger[key(.children, "c1")] = .init(digest: SyncDigest.of("x"), updatedAt: 10)
        let plan = SyncPlanner.plan(
            local: [LocalSyncRecord(key: key(.children, "c1"), payload: "x")],
            remote: [], ledger: ledger, now: t0)
        XCTAssertTrue(plan.push.isEmpty)
        XCTAssertTrue(plan.apply.isEmpty)
    }

    func testALocalDeletionTravelsAsATombstone() {
        var ledger = SyncLedger()
        ledger[key(.children, "c1")] = .init(digest: SyncDigest.of("x"), updatedAt: 10)
        let plan = SyncPlanner.plan(local: [], remote: [], ledger: ledger, now: t0)
        XCTAssertEqual(plan.push.count, 1)
        XCTAssertNil(plan.push.first?.payload, "a tombstone carries no content")
        XCTAssertNil(plan.ledger[key(.children, "c1")]?.digest)
    }

    func testARemoteDeletionIsCarriedOutHere() {
        var ledger = SyncLedger()
        ledger[key(.stories, "s1")] = .init(digest: SyncDigest.present, updatedAt: 10)
        let tombstone = RemoteSyncRecord(key: key(.stories, "s1"), payload: nil, updatedAt: 20, serverUpdatedAt: t0)
        let plan = SyncPlanner.plan(
            local: [LocalSyncRecord(key: key(.stories, "s1"), payload: "{\"t\":1}")],
            remote: [tombstone], ledger: ledger, now: t0)
        XCTAssertEqual(plan.apply, [tombstone])
        XCTAssertTrue(plan.push.isEmpty)
    }

    func testTheLaterWriteWinsWhenBothChanged() {
        var ledger = SyncLedger()
        ledger[key(.children, "c1")] = .init(digest: SyncDigest.of("old"), updatedAt: 10)
        let local = LocalSyncRecord(key: key(.children, "c1"), payload: "mine", changedAt: t0)

        let newer = RemoteSyncRecord(key: key(.children, "c1"), payload: "theirs",
                                     updatedAt: ms(t0) + 1000, serverUpdatedAt: t0)
        let remoteWins = SyncPlanner.plan(local: [local], remote: [newer], ledger: ledger, now: t0)
        XCTAssertEqual(remoteWins.apply, [newer])
        XCTAssertTrue(remoteWins.push.isEmpty)

        let older = RemoteSyncRecord(key: key(.children, "c1"), payload: "theirs",
                                     updatedAt: ms(t0) - 1000, serverUpdatedAt: t0)
        let localWins = SyncPlanner.plan(local: [local], remote: [older], ledger: ledger, now: t0)
        XCTAssertTrue(localWins.apply.isEmpty)
        XCTAssertEqual(localWins.push.first?.payload, "mine")
    }

    func testAStoryIsNeverRewritten() {
        // Two devices hold the same story with different local details.
        var ledger = SyncLedger()
        ledger[key(.stories, "s1")] = .init(digest: SyncDigest.present, updatedAt: 10)
        let local = LocalSyncRecord(key: key(.stories, "s1"), payload: "{\"cover\":\"here\"}")
        let remote = RemoteSyncRecord(key: key(.stories, "s1"), payload: "{\"cover\":\"there\"}",
                                      updatedAt: 99, serverUpdatedAt: t0)
        let plan = SyncPlanner.plan(local: [local], remote: [remote], ledger: ledger, now: t0)
        XCTAssertTrue(plan.push.isEmpty)
        XCTAssertTrue(plan.apply.isEmpty)

        // A story already on the server is not re-sent because this copy differs.
        let fresh = SyncPlanner.plan(local: [local], remote: [remote], ledger: SyncLedger(), now: t0)
        XCTAssertTrue(fresh.push.isEmpty)
        XCTAssertTrue(fresh.apply.isEmpty)
    }

    func testAChangeMadeOfflineKeepsItsTime() {
        let record = LocalSyncRecord(key: key(.children, "c1"), payload: "offline edit")
        let noted = SyncPlanner.notePending(local: [record], in: SyncLedger(), now: t0)
        XCTAssertTrue(noted.hasUnsentChanges)
        let later = t0.addingTimeInterval(3600)
        let plan = SyncPlanner.plan(local: [record], remote: [], ledger: noted, now: later)
        XCTAssertEqual(plan.push.first?.updatedAt, ms(t0))
        XCTAssertFalse(plan.ledger.hasUnsentChanges)
    }

    func testChildrenAreAppliedFirst() {
        let remote = [
            RemoteSyncRecord(key: key(.progress, "s1"), payload: "{}", updatedAt: 1, serverUpdatedAt: t0),
            RemoteSyncRecord(key: key(.stories, "s1"), payload: "{}", updatedAt: 1, serverUpdatedAt: t0),
            RemoteSyncRecord(key: key(.children, "c1"), payload: "{}", updatedAt: 1, serverUpdatedAt: t0),
        ]
        let plan = SyncPlanner.plan(local: [], remote: remote, ledger: SyncLedger(), now: t0)
        XCTAssertEqual(plan.apply.map(\.key.collection), [.children, .stories, .progress])
    }

    // MARK: - What travels

    func testAProfilePhotoNeverTravels() throws {
        var profile = UserProfile(name: "Ada", age: 5, interests: ["animals"])
        profile.imageFileName = "profile_\(profile.id.uuidString).jpg"
        let payload = try FamilyRecordMapping.payload(for: profile, avatarColor: 3)
        XCTAssertFalse(payload.contains("imageFileName"))
        XCTAssertFalse(payload.contains(".jpg"))
        let child = try SyncCoding.decode(FamilyRecordMapping.SyncedChild.self, from: payload)
        XCTAssertEqual(child.avatarColor, 3, "the colour the parent picked travels with the child")
        let back = child.profile
        XCTAssertEqual(back.name, "Ada")
        XCTAssertEqual(back.interests, ["animals"])
        XCTAssertEqual(back.createdAt, profile.createdAt, "dates keep full precision")
    }

    func testAStoryTravelsWithoutItsReadingPosition() throws {
        var story = ReaderFixtures.textStory(pages: 4)
        story.lastReadPage = 2
        story.lastReadAt = t0
        story.coverImageFileName = "cover.png"
        let payload = try FamilyRecordMapping.payload(for: story)
        let back = try SyncCoding.decode(MagicPaper.Story.self, from: payload)
        XCTAssertNil(back.lastReadPage)
        XCTAssertNil(back.lastReadAt)
        XCTAssertNil(back.coverImageFileName)
        XCTAssertEqual(back.pages.map(\.text), story.pages.map(\.text))
        XCTAssertEqual(FamilyRecordMapping.progress(of: story), StoryProgress(lastReadPage: 2, lastReadAt: t0))
    }

    func testStarterBooksAndUnfinishedStoriesStayOnTheDevice() {
        var sample = ReaderFixtures.textStory(pages: 7)
        sample.origin = nil
        sample.pages[0].title = "Sihirli Başlangıç"
        sample.status = .completed
        XCTAssertFalse(FamilyRecordMapping.syncs(sample))

        var writing = ReaderFixtures.textStory(pages: 4)
        writing.status = .writingStory
        XCTAssertFalse(FamilyRecordMapping.syncs(writing))

        var done = ReaderFixtures.textStory(pages: 4)
        done.status = .completed
        XCTAssertTrue(FamilyRecordMapping.syncs(done))
    }

    // MARK: - Two devices, one account

    func testTwoDevicesOnOneAccountShareTheLibrary() async throws {
        let server = FakeFamilyRemote()
        let a = FakeFamilyLocal()
        let b = FakeFamilyLocal()
        let syncA = makeSync(a)
        let syncB = makeSync(b)
        defer { syncA.stop(); syncB.stop() }
        syncA.start(uid: "parent", remote: server)
        syncB.start(uid: "parent", remote: server)

        // A writes a child and a story; B receives them.
        a.records[key(.children, "c1")] = "{\"name\":\"Ada\"}"
        a.records[key(.stories, "s1")] = "{\"text\":\"Bir varmış\"}"
        await syncSucceeded(syncA)
        await syncSucceeded(syncB)
        XCTAssertEqual(b.records, a.records)
        XCTAssertTrue(syncB.restored)

        // B reads on; A sees where B left off.
        b.records[key(.progress, "s1")] = "{\"lastReadPage\":3}"
        await syncSucceeded(syncB)
        await syncSucceeded(syncA)
        XCTAssertEqual(a.records[key(.progress, "s1")], "{\"lastReadPage\":3}")

        // A deletes the story; it leaves B too, and the server keeps no text.
        a.records[key(.stories, "s1")] = nil
        a.records[key(.progress, "s1")] = nil
        await syncSucceeded(syncA)
        await syncSucceeded(syncB)
        XCTAssertNil(b.records[key(.stories, "s1")])
        let stored = await server.document(key(.stories, "s1"))
        XCTAssertNotNil(stored)
        XCTAssertNil(stored?.payload)
        XCTAssertEqual(a.records, b.records)
    }

    func testAStoryWrittenOfflineIsSentWhenTheConnectionReturns() async {
        let server = FakeFamilyRemote()
        let a = FakeFamilyLocal()
        let b = FakeFamilyLocal()
        let syncA = makeSync(a)
        let syncB = makeSync(b)
        defer { syncA.stop(); syncB.stop() }
        syncA.start(uid: "parent", remote: server)
        syncB.start(uid: "parent", remote: server)

        await server.setOffline(true)
        a.records[key(.stories, "offline")] = "{\"text\":\"Uçakta yazıldı\"}"
        let sent = await syncA.syncNow()
        XCTAssertFalse(sent)
        XCTAssertTrue(syncA.hasUnsentChanges, "the story waits on the device")
        XCTAssertEqual(a.records[key(.stories, "offline")], "{\"text\":\"Uçakta yazıldı\"}")

        await server.setOffline(false)
        await syncSucceeded(syncA)
        XCTAssertFalse(syncA.hasUnsentChanges)
        await syncSucceeded(syncB)
        XCTAssertEqual(b.records[key(.stories, "offline")], "{\"text\":\"Uçakta yazıldı\"}")
    }

    func testALedgerOfAnotherAccountIsNotUsed() async {
        let folder = "SyncTest-\(UUID().uuidString)"
        let ledgerStore = SyncLedgerStore(subdirectory: folder)
        defer { ledgerStore.erase() }
        var other = SyncLedger(ownerUID: "someone-else")
        other[key(.children, "c1")] = .init(digest: SyncDigest.of("x"), updatedAt: 1)
        other.restored = true
        ledgerStore.save(other)

        let sync = FamilySyncService(local: FakeFamilyLocal(), ledgerStore: ledgerStore)
        defer { sync.stop() }
        sync.start(uid: "parent", remote: FakeFamilyRemote())
        XCTAssertFalse(sync.restored)
        XCTAssertEqual(ledgerStore.load().ownerUID, "parent")
        XCTAssertTrue(ledgerStore.load().entries.isEmpty)
    }

    // MARK: - Helpers

    private var ledgerFolders: [String] = []

    override func tearDown() {
        ledgerFolders.forEach { SyncLedgerStore(subdirectory: $0).erase() }
        ledgerFolders = []
        super.tearDown()
    }

    private func makeSync(_ local: FakeFamilyLocal) -> FamilySyncService {
        let folder = "SyncTest-\(UUID().uuidString)"
        ledgerFolders.append(folder)
        var tick = 0.0
        return FamilySyncService(local: local, ledgerStore: SyncLedgerStore(subdirectory: folder), clock: {
            tick += 1
            return Date(timeIntervalSince1970: 1_759_780_000 + tick)
        })
    }

    private func syncSucceeded(_ sync: FamilySyncService, file: StaticString = #filePath, line: UInt = #line) async {
        let ok = await sync.syncNow()
        XCTAssertTrue(ok, "sync failed", file: file, line: line)
    }
}

// MARK: - Fakes

/// A device: records by key, as payload strings.
@MainActor
final class FakeFamilyLocal: FamilyLocalStore {
    var records: [SyncKey: String] = [:]

    func records() async -> [LocalSyncRecord] {
        records.map { LocalSyncRecord(key: $0.key, payload: $0.value) }
    }

    func apply(_ incoming: [RemoteSyncRecord]) async {
        for record in incoming { records[record.key] = record.payload }
    }
}

/// The account's server, with the rules' story rule.
actor FakeFamilyRemote: FamilyRemote {
    private var documents: [SyncKey: RemoteSyncRecord] = [:]
    private var consents: [String: ConsentRecord] = [:]
    private var clock = Date(timeIntervalSince1970: 1_759_780_000)
    private var offline = false
    private(set) var deletedEverything = false
    private(set) var log: [String] = []

    func setOffline(_ value: Bool) { offline = value }
    func document(_ key: SyncKey) -> RemoteSyncRecord? { documents[key] }
    var isEmpty: Bool { documents.isEmpty && consents.isEmpty }

    func seed(_ record: RemoteSyncRecord) { documents[record.key] = record }

    func pull(since highWater: [String: Date]) async throws -> [RemoteSyncRecord] {
        if offline { throw AccountError.offline }
        return documents.values.filter { record in
            guard let mark = highWater[record.key.collection.rawValue] else { return true }
            return (record.serverUpdatedAt ?? .distantPast) > mark
        }
    }

    func push(_ records: [RemoteSyncRecord]) async throws {
        if offline { throw AccountError.offline }
        for record in records {
            if record.key.collection == .stories, let existing = documents[record.key] {
                let allowed = record.deleted || (!existing.deleted && existing.payload == record.payload)
                if !allowed { throw AccountError.failed }
            }
            clock = clock.addingTimeInterval(1)
            documents[record.key] = RemoteSyncRecord(
                key: record.key, payload: record.payload, updatedAt: record.updatedAt, serverUpdatedAt: clock)
        }
    }

    func deleteEverything() async throws {
        if offline { throw AccountError.offline }
        log.append("deleteEverything")
        documents = [:]
        consents = [:]
        deletedEverything = true
    }

    func recordConsent(_ record: ConsentRecord) async throws {
        if offline { throw AccountError.offline }
        guard consents[record.version] == nil else { throw AccountError.failed }
        consents[record.version] = record
    }

    func consent(version: String) async throws -> ConsentRecord? {
        if offline { throw AccountError.offline }
        return consents[version]
    }

    func seedConsent(_ record: ConsentRecord) { consents[record.version] = record }
}
