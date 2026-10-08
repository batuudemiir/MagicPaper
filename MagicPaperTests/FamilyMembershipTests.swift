import XCTest
@testable import MagicPaper

/// Aile üyeleri (FAZ 18): hangi aile eşitlenir, roller, davet, ayrılma, silme.
/// Sunucudaki yetkiler `firebase/tests/family.test.mjs`'te.
@MainActor
final class FamilyMembershipTests: XCTestCase {

    private var ledgerFolder = ""
    private var defaults: UserDefaults!
    private var suiteName = ""

    override func setUp() {
        super.setUp()
        ledgerFolder = "FamilyLedger-\(UUID().uuidString)"
        suiteName = "FamilyMembershipTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        SyncLedgerStore(subdirectory: ledgerFolder).erase()
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private struct Harness {
        let service: AccountService
        let directory: FakeFamilyDirectory
        /// Aile kimliğine göre sunucular: kurucunun ve katılınan ailenin.
        let remotes: [String: FakeFamilyRemote]
        let local: FakeFamilyLocal
        let erased: () -> [Bool]
    }

    /// `FakeAccountAuth` her zaman "parent-1" olarak giriş yapar.
    private func harness(directory: FakeFamilyDirectory = FakeFamilyDirectory()) -> Harness {
        let remotes = ["parent-1": FakeFamilyRemote(), "founder": FakeFamilyRemote()]
        var erasures: [Bool] = []
        let local = FakeFamilyLocal()
        let sync = FamilySyncService(local: local, ledgerStore: SyncLedgerStore(subdirectory: ledgerFolder))
        let service = AccountService(
            auth: FakeAccountAuth(), sync: sync,
            consentStore: ParentConsentStore(defaults: defaults),
            makeRemote: { remotes[$0] ?? FakeFamilyRemote() },
            eventSink: FakeEventSink(),
            eventQueue: ReadingEventQueue(subdirectory: "FamilyEvents-\(UUID().uuidString)"),
            shareUsageData: { false },
            setShareUsageData: { _ in },
            eraseLocal: { erasures.append($0) },
            directory: directory,
            membershipCache: FamilyMembershipCache(defaults: defaults))
        addTeardownBlock { @MainActor in sync.stop() }
        return Harness(service: service, directory: directory, remotes: remotes, local: local, erased: { erasures })
    }

    private func familyConsent() -> ConsentRecord {
        ConsentRecord(version: ParentConsentText.version, acceptedAt: Date(), shareUsageData: false)
    }

    // MARK: - Davet kodu

    func testInviteCodesUseOnlyUnambiguousCharacters() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let code = FamilyInviteCode.make(using: &generator)
            XCTAssertEqual(code.count, 8)
            XCTAssertFalse(code.contains { "IO01".contains($0) })
            XCTAssertEqual(FamilyInviteCode.normalize(code), code)
        }
    }

    func testATypedCodeIsCleanedUp() {
        XCTAssertEqual(FamilyInviteCode.normalize(" abcd-efgh "), "ABCDEFGH")
        XCTAssertNil(FamilyInviteCode.normalize("ABCDEFG"), "too short")
        XCTAssertNil(FamilyInviteCode.normalize("ABCDEFG0"), "0 is not in the alphabet")
    }

    func testInviteLinksAreRead() {
        XCTAssertEqual(FamilyInviteCode.from(url: URL(string: "magicpaper://invite/abcdefgh")!), "ABCDEFGH")
        XCTAssertEqual(FamilyInviteCode.from(url: URL(string: "https://magicpaper-393a7.web.app/i/ABCDEFGH")!), "ABCDEFGH")
        XCTAssertNil(FamilyInviteCode.from(url: URL(string: "https://magicpaper-393a7.web.app/s/ABCDEFGH")!))
        XCTAssertNil(FamilyInviteCode.from(url: URL(string: "com.googleusercontent.apps.x:/oauth")!))
    }

    func testTheInviteMessageCarriesTheCodeButNoChildData() {
        let text = FamilyInviteCode.message(code: "ABCDEFGH", inviterName: "Batu")
        XCTAssertTrue(text.contains("ABCDEFGH"))
        XCTAssertTrue(text.hasPrefix("Batu "))
    }

    // MARK: - Hangi aile

    func testAnAccountThatJoinedNoFamilyFoundsItsOwn() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        XCTAssertEqual(h.service.familyID, "parent-1")
        XCTAssertEqual(h.service.role, .admin)
        XCTAssertTrue(h.service.canWriteFamily)
    }

    func testAMemberSyncsTheFoundersFamilyAndAdoptsItsConsent() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .parent), for: "parent-1")
        let h = harness(directory: directory)
        try await h.remotes["founder"]!.recordConsent(familyConsent())

        try await h.service.signIn(with: .google)

        XCTAssertEqual(h.service.familyID, "founder")
        XCTAssertEqual(h.service.role, .parent)
        XCTAssertNotNil(h.service.consent, "the family's consent stands for its members")
        XCTAssertFalse(h.service.sync.readOnly)
    }

    func testAReaderSyncsReadOnlyAndCannotWrite() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .reader), for: "parent-1")
        let h = harness(directory: directory)
        try await h.remotes["founder"]!.recordConsent(familyConsent())

        try await h.service.signIn(with: .apple)

        XCTAssertTrue(h.service.sync.readOnly)
        XCTAssertFalse(h.service.canWriteFamily)
        XCTAssertFalse(h.service.isFounder)
    }

    func testAMemberNeverRecordsTheFamilysConsent() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .parent), for: "parent-1")
        let h = harness(directory: directory)
        try await h.service.signIn(with: .apple)
        await h.service.acceptConsent(shareUsageData: false)
        let onServer = try await h.remotes["founder"]!.consent(version: ParentConsentText.version)
        XCTAssertNil(onServer, "only the founder writes the family's consent")
    }

    func testOfflineTheDevicesCopyOfTheMembershipStands() async throws {
        FamilyMembershipCache(defaults: defaults).save(FamilyMembership(familyID: "founder", role: .reader), for: "parent-1")
        let directory = FakeFamilyDirectory()
        await directory.setOffline(true)
        let h = harness(directory: directory)
        try await h.service.signIn(with: .apple)
        XCTAssertEqual(h.service.familyID, "founder")
        XCTAssertEqual(h.service.role, .reader)
    }

    // MARK: - Katıl, ayrıl

    func testJoiningDeletesTheAccountsOwnFamilyFirst() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        await h.service.acceptConsent(shareUsageData: false)
        try await h.remotes["founder"]!.recordConsent(familyConsent())
        let invite = FamilyInvite(code: "ABCDEFGH", familyID: "founder", role: .parent, inviterName: "Batu",
                                  expiresAt: Date().addingTimeInterval(3600))

        try await h.service.joinFamily(invite, displayName: "Murat")

        let ownDeleted = await h.remotes["parent-1"]!.deletedEverything
        XCTAssertTrue(ownDeleted)
        let log = await h.directory.log
        XCTAssertEqual(log, ["dissolve parent-1", "accept ABCDEFGH parent-1 Murat"])
        XCTAssertEqual(h.erased(), [true], "the device's copy of the old family goes; onboarding stays")
        XCTAssertEqual(h.service.familyID, "founder")
        XCTAssertNotNil(h.service.consent)
    }

    func testAnExpiredInviteIsRefusedBeforeAnythingIsDeleted() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        let invite = FamilyInvite(code: "ABCDEFGH", familyID: "founder", role: .parent, inviterName: "Batu",
                                  expiresAt: Date().addingTimeInterval(-1))
        do {
            try await h.service.joinFamily(invite, displayName: "Murat")
            XCTFail("expected a refusal")
        } catch {}
        let ownDeleted = await h.remotes["parent-1"]!.deletedEverything
        XCTAssertFalse(ownDeleted)
        XCTAssertTrue(h.erased().isEmpty)
    }

    func testLeavingRemovesTheMemberAndTheFamilysCopy() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .parent), for: "parent-1")
        let h = harness(directory: directory)
        try await h.remotes["founder"]!.recordConsent(familyConsent())
        try await h.service.signIn(with: .apple)

        try await h.service.leaveFamily()

        let log = await directory.log
        XCTAssertEqual(log, ["remove parent-1 founder"])
        XCTAssertEqual(h.erased(), [true])
        XCTAssertEqual(h.service.familyID, "parent-1")
        XCTAssertNil(h.service.consent, "its own family has no consent yet")
    }

    func testTheFounderCannotLeave() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        do {
            try await h.service.leaveFamily()
            XCTFail("expected a refusal")
        } catch {}
    }

    func testRemovedFromTheFamilyTheDeviceLetsGoOfItsData() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .parent), for: "parent-1")
        let h = harness(directory: directory)
        try await h.remotes["founder"]!.recordConsent(familyConsent())
        try await h.service.signIn(with: .apple)
        XCTAssertNotNil(h.service.consent)

        await directory.setMembership(nil, for: "parent-1")
        await h.service.refreshMembership()

        XCTAssertEqual(h.service.familyID, "parent-1")
        XCTAssertEqual(h.erased(), [true])
    }

    // MARK: - Silme

    func testTheFoundersDeletionDissolvesTheFamily() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        try await h.service.deleteAccount()
        let log = await h.directory.log
        XCTAssertEqual(log, ["dissolve parent-1"])
        let deleted = await h.remotes["parent-1"]!.deletedEverything
        XCTAssertTrue(deleted)
    }

    func testAMembersDeletionLeavesTheFamilysData() async throws {
        let directory = FakeFamilyDirectory()
        await directory.setMembership(FamilyMembership(familyID: "founder", role: .reader), for: "parent-1")
        let h = harness(directory: directory)
        try await h.service.signIn(with: .apple)
        try await h.service.deleteAccount()
        let log = await directory.log
        XCTAssertEqual(log, ["remove parent-1 founder"])
        let founderDeleted = await h.remotes["founder"]!.deletedEverything
        XCTAssertFalse(founderDeleted)
        XCTAssertNil(h.service.account)
    }

    // MARK: - Sadece okuma eşitlemesi

    func testAReadOnlySyncPullsButNeverPushes() async throws {
        let remote = FakeFamilyRemote()
        let key = SyncKey(collection: .stories, id: "s1")
        await remote.seed(RemoteSyncRecord(key: key, payload: "{\"t\":1}", updatedAt: 1, serverUpdatedAt: Date()))
        let local = FakeFamilyLocal()
        local.records[SyncKey(collection: .progress, id: "s1")] = "{\"lastReadPage\":3}"
        let sync = FamilySyncService(local: local, ledgerStore: SyncLedgerStore(subdirectory: ledgerFolder))
        addTeardownBlock { @MainActor in sync.stop() }

        sync.start(uid: "founder", remote: remote, readOnly: true)
        let ok = await sync.syncNow()

        XCTAssertTrue(ok)
        XCTAssertEqual(local.records[key], "{\"t\":1}", "the family's story arrives")
        let pushed = await remote.document(SyncKey(collection: .progress, id: "s1"))
        XCTAssertNil(pushed, "a reader's progress stays on the device")
        XCTAssertFalse(sync.hasUnsentChanges, "nothing is waiting to be sent: nothing ever will be")
    }
}

// MARK: - Fakes

actor FakeFamilyDirectory: FamilyDirectory {
    private var memberships: [String: FamilyMembership] = [:]
    private var offline = false
    private(set) var log: [String] = []

    func setMembership(_ membership: FamilyMembership?, for uid: String) { memberships[uid] = membership }
    func setOffline(_ value: Bool) { offline = value }

    func membership(for uid: String) async throws -> FamilyMembership? {
        if offline { throw AccountError.offline }
        return memberships[uid]
    }
    func members(of familyID: String) async throws -> [FamilyMember] { [] }
    func ensureFounder(familyID: String, displayName: String) async throws {}
    func createInvite(familyID: String, role: FamilyRole, inviterName: String, now: Date) async throws -> FamilyInvite {
        FamilyInvite(code: "ABCDEFGH", familyID: familyID, role: role, inviterName: inviterName,
                     expiresAt: now.addingTimeInterval(FamilyInviteCode.lifetime))
    }
    func invites(of familyID: String) async throws -> [FamilyInvite] { [] }
    func invite(code: String) async throws -> FamilyInvite? { nil }
    func deleteInvite(code: String) async throws {}
    func accept(_ invite: FamilyInvite, uid: String, displayName: String) async throws {
        log.append("accept \(invite.code) \(uid) \(displayName)")
        memberships[uid] = FamilyMembership(familyID: invite.familyID, role: invite.role)
    }
    func setRole(_ role: FamilyRole, for uid: String, in familyID: String) async throws {}
    func remove(uid: String, from familyID: String) async throws {
        log.append("remove \(uid) \(familyID)")
        memberships[uid] = nil
    }
    func dissolve(familyID: String) async throws { log.append("dissolve \(familyID)") }
}
