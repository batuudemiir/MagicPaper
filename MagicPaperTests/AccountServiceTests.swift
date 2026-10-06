import XCTest
import StoryEngine
@testable import MagicPaper

/// Hesap, ebeveyn onayı, hesap silme ve okuma olaylarının gönderimi (FAZ 16).
///
/// Kabul: hesap silme sonrası sunucuda veri yok (silme sırası burada; boş
/// sunucu kural testinde ve emülatörde). Olaylar ancak ebeveyn metni
/// gördükten sonra ve hesap kimliği olmadan gider.
@MainActor
final class AccountServiceTests: XCTestCase {

    private var queueFolder = ""
    private var ledgerFolder = ""
    private var defaults: UserDefaults!
    private var suiteName = ""
    private let istanbul = TimeZone(identifier: "Europe/Istanbul")!

    override func setUp() {
        super.setUp()
        queueFolder = "AccountEvents-\(UUID().uuidString)"
        ledgerFolder = "AccountLedger-\(UUID().uuidString)"
        suiteName = "AccountServiceTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        ReadingEventQueue(subdirectory: queueFolder).eraseAll()
        SyncLedgerStore(subdirectory: ledgerFolder).erase()
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private var queue: ReadingEventQueue { ReadingEventQueue(subdirectory: queueFolder) }

    private struct Harness {
        let service: AccountService
        let auth: FakeAccountAuth
        let remote: FakeFamilyRemote
        let sink: FakeEventSink
        let local: FakeFamilyLocal
        let erased: () -> [Bool]
    }

    private func harness(remote: FakeFamilyRemote = FakeFamilyRemote(), sharing: Bool = true) -> Harness {
        let auth = FakeAccountAuth()
        let sink = FakeEventSink()
        var erasures: [Bool] = []
        let local = FakeFamilyLocal()
        let sync = FamilySyncService(local: local, ledgerStore: SyncLedgerStore(subdirectory: ledgerFolder))
        let service = AccountService(
            auth: auth, sync: sync,
            consentStore: ParentConsentStore(defaults: defaults),
            makeRemote: { _ in remote },
            eventSink: sink,
            eventQueue: queue,
            shareUsageData: { sharing },
            setShareUsageData: { _ in },
            eraseLocal: { erasures.append($0) })
        addTeardownBlock { @MainActor in sync.stop() }
        return Harness(service: service, auth: auth, remote: remote, sink: sink, local: local, erased: { erasures })
    }

    private func event(finished: Bool = true) throws -> ReadingEvent {
        var story = ReaderFixtures.textStory(pages: 6)
        story.origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "bp", settingID: "set", companionID: "comp",
            discoveryID: "disc", fingerprint: "f", catalogVersion: "v", worldID: nil,
            modeID: "bedtime", selectionStrategy: "direct", ageBand: "5-6", subOptionID: nil)
        return try XCTUnwrap(ReadingEvent(story: story, pageReached: 5, finished: finished, reread: false,
                                          companionKind: "tavşan", at: Date(), in: istanbul))
    }

    // MARK: - Gate

    func testTheOpeningOrder() {
        var i = AppGate.Inputs(onboardingDone: false, signedIn: false, deferredSignIn: false,
                               consentCurrent: false, restoreSettled: false, hasProfiles: false,
                               hasCurrentProfile: false)
        XCTAssertEqual(AppGate.resolve(i), .intro)
        i.onboardingDone = true
        XCTAssertEqual(AppGate.resolve(i), .signIn)
        i.signedIn = true
        XCTAssertEqual(AppGate.resolve(i), .consent)
        i.consentCurrent = true
        XCTAssertEqual(AppGate.resolve(i), .restoring, "a new device waits for the account's children")
        i.restoreSettled = true
        XCTAssertEqual(AppGate.resolve(i), .createProfile)
        i.hasProfiles = true
        XCTAssertEqual(AppGate.resolve(i), .selectProfile)
        i.hasCurrentProfile = true
        XCTAssertEqual(AppGate.resolve(i), .app)
    }

    func testAnInstalledAppMeetsSignInAndConsentOnce() {
        let existing = AppGate.Inputs(onboardingDone: true, signedIn: false, deferredSignIn: false,
                                      consentCurrent: false, restoreSettled: false, hasProfiles: true,
                                      hasCurrentProfile: true)
        XCTAssertEqual(AppGate.resolve(existing), .signIn)
        var signedIn = existing
        signedIn.signedIn = true
        XCTAssertEqual(AppGate.resolve(signedIn), .consent)
        signedIn.consentCurrent = true
        XCTAssertEqual(AppGate.resolve(signedIn), .app, "its own children need no restore")
    }

    func testOnlyADeviceWithChildrenMayWaitForAConnection() {
        var offline = AppGate.Inputs(onboardingDone: true, signedIn: false, deferredSignIn: true,
                                     consentCurrent: false, restoreSettled: false, hasProfiles: true,
                                     hasCurrentProfile: true)
        XCTAssertEqual(AppGate.resolve(offline), .app)
        offline.hasProfiles = false
        offline.hasCurrentProfile = false
        XCTAssertEqual(AppGate.resolve(offline), .signIn)
    }

    // MARK: - Consent

    func testANewConsentTextAsksAgain() {
        let store = ParentConsentStore(defaults: defaults)
        store.save(ConsentRecord(version: "2026-01-01", acceptedAt: Date(), shareUsageData: true),
                   for: "u", recordedRemotely: true)
        XCTAssertNil(store.current(for: "u"))
        XCTAssertNotNil(store.current(for: "u", version: "2026-01-01"))
        XCTAssertNil(store.current(for: "someone-else", version: "2026-01-01"))
    }

    func testAcceptingRecordsTheConsentOnTheAccount() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        XCTAssertNil(h.service.consent)
        await h.service.acceptConsent(shareUsageData: false)
        XCTAssertEqual(h.service.consent?.version, ParentConsentText.version)
        let onServer = try await h.remote.consent(version: ParentConsentText.version)
        XCTAssertEqual(onServer?.shareUsageData, false)
        XCTAssertNil(ParentConsentStore(defaults: defaults).pendingRemote(for: "parent-1"))
    }

    func testConsentGivenOnAnotherDeviceIsNotAskedAgain() async throws {
        let remote = FakeFamilyRemote()
        await remote.seedConsent(ConsentRecord(version: ParentConsentText.version, acceptedAt: Date(),
                                               shareUsageData: true))
        let h = harness(remote: remote)
        try await h.service.signIn(with: .google)
        XCTAssertNotNil(h.service.consent)
    }

    /// Karar (6 Ekim 2026): what was read before the parent saw the text is
    /// never sent.
    func testEventsFromBeforeTheNoticeAreDropped() async throws {
        queue.append(try event(), for: UUID())
        queue.append(try event(finished: false), for: UUID())
        let h = harness()
        try await h.service.signIn(with: .apple)
        await h.service.acceptConsent(shareUsageData: true)
        let sent = await h.sink.sent
        XCTAssertEqual(queue.count, 0)
        XCTAssertTrue(sent.isEmpty)
    }

    // MARK: - Reading events

    func testTheWireHasNoStoryID() throws {
        let wire = ReadingEventWire(try event())
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(wire)) as? [String: Any]
        XCTAssertEqual(Set((json ?? [:]).keys), [
            "schemaVersion", "mode", "blueprintID", "contentIDs", "companionKind", "ageBand",
            "pageReached", "pageCount", "finished", "reread", "day",
        ])
        XCTAssertNil(wire.fields["storyID"])
        XCTAssertNil(wire.fields["familyRelation"], "an absent value is left out, not null")
        XCTAssertEqual(Set(wire.fields.keys), Set((json ?? [:]).keys))
    }

    func testEventsGoOnlyWithSharingConsentAndAnAccount() async throws {
        let sink = FakeEventSink()
        let uploader = ReadingEventUploader(queue: queue, sink: sink)
        queue.append(try event(), for: UUID())
        for conditions in [
            ReadingEventUploader.Conditions(sharingOn: false, consentGiven: true, signedIn: true),
            ReadingEventUploader.Conditions(sharingOn: true, consentGiven: false, signedIn: true),
            ReadingEventUploader.Conditions(sharingOn: true, consentGiven: true, signedIn: false),
        ] {
            let sent = await uploader.flush(when: conditions)
            XCTAssertEqual(sent, 0)
        }
        XCTAssertEqual(queue.count, 1)
        let sent = await uploader.flush(when: .init(sharingOn: true, consentGiven: true, signedIn: true))
        XCTAssertEqual(sent, 1)
        XCTAssertEqual(queue.count, 0)
    }

    func testAFailedSendKeepsTheEvents() async throws {
        let sink = FakeEventSink(fails: true)
        queue.append(try event(), for: UUID())
        let sent = await ReadingEventUploader(queue: queue, sink: sink)
            .flush(when: .init(sharingOn: true, consentGiven: true, signedIn: true))
        XCTAssertEqual(sent, 0)
        XCTAssertEqual(queue.count, 1)
    }

    func testEventsGoInBatches() async throws {
        let sink = FakeEventSink()
        let child = UUID()
        let one = try event()
        for _ in 0..<(ReadingEventUploader.batchSize + 5) { queue.append(one, for: child) }
        let sent = await ReadingEventUploader(queue: queue, sink: sink)
            .flush(when: .init(sharingOn: true, consentGiven: true, signedIn: true))
        XCTAssertEqual(sent, ReadingEventUploader.batchSize + 5)
        let batches = await sink.batches
        XCTAssertEqual(batches, [ReadingEventUploader.batchSize, 5])
    }

    // MARK: - Delete

    func testDeletingTheAccountDeletesServerThenSignInThenDevice() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        await h.service.acceptConsent(shareUsageData: true)
        await h.remote.seed(RemoteSyncRecord(key: SyncKey(collection: .stories, id: "s1"), payload: "{}",
                                             updatedAt: 1, serverUpdatedAt: Date()))
        var steps: [AccountService.DeletionStep] = []
        try await h.service.deleteAccount { steps.append($0) }

        XCTAssertEqual(steps, [.reauthenticating, .deletingData, .deletingAccount, .erasingDevice])
        XCTAssertEqual(h.auth.calls, ["signIn", "reauthenticate", "deleteUser"])
        let empty = await h.remote.isEmpty
        XCTAssertTrue(empty, "nothing of the family is left on the server")
        XCTAssertEqual(h.erased(), [false], "the device is erased back to the first screen")
        XCTAssertNil(h.service.account)
        XCTAssertNil(h.service.consent)
    }

    func testAFailedServerDeletionTouchesNothingElse() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        await h.service.acceptConsent(shareUsageData: true)
        await h.remote.setOffline(true)
        do {
            try await h.service.deleteAccount()
            XCTFail("expected a failure")
        } catch {}
        XCTAssertFalse(h.auth.calls.contains("deleteUser"))
        XCTAssertTrue(h.erased().isEmpty)
        XCTAssertNotNil(h.service.account)
    }

    func testCancellingTheFreshSignInDeletesNothing() async throws {
        let h = harness()
        try await h.service.signIn(with: .apple)
        h.auth.reauthenticationError = .cancelled
        do {
            try await h.service.deleteAccount()
            XCTFail("expected a cancellation")
        } catch {
            XCTAssertEqual(error as? AccountError, .cancelled)
        }
        let deleted = await h.remote.deletedEverything
        XCTAssertFalse(deleted)
        XCTAssertTrue(h.erased().isEmpty)
    }

    // MARK: - Sign out

    func testSigningOutKeepsOnboardingAndErasesTheDevice() async throws {
        let h = harness()
        try await h.service.signIn(with: .google)
        await h.service.acceptConsent(shareUsageData: true)
        try await h.service.signOut()
        XCTAssertEqual(h.erased(), [true])
        XCTAssertNil(h.service.account)
        XCTAssertTrue(h.auth.calls.contains("signOut"))
    }

    func testSigningOutWithUnsentChangesIsRefused() async throws {
        let h = harness()
        try await h.service.signIn(with: .google)
        await h.service.acceptConsent(shareUsageData: true)
        await h.remote.setOffline(true)
        h.local.records[SyncKey(collection: .stories, id: "unsent")] = "{}"
        do {
            try await h.service.signOut()
            XCTFail("expected a refusal")
        } catch {
            XCTAssertEqual(error as? AccountError, .unsentChanges)
        }
        XCTAssertTrue(h.erased().isEmpty, "no story is lost")
        XCTAssertNotNil(h.service.account)
    }
}

// MARK: - Fakes

@MainActor
final class FakeAccountAuth: AccountAuth {
    var current: ParentAccount?
    var googleAvailable = true
    var calls: [String] = []
    var reauthenticationError: AccountError?

    func signIn(with provider: SignInProvider) async throws -> ParentAccount {
        calls.append("signIn")
        let account = ParentAccount(uid: "parent-1", provider: provider)
        current = account
        return account
    }

    func reauthenticateForDeletion() async throws {
        if let reauthenticationError { throw reauthenticationError }
        calls.append("reauthenticate")
    }

    func deleteUser() async throws {
        calls.append("deleteUser")
        current = nil
    }

    func signOut() throws {
        calls.append("signOut")
        current = nil
    }
}

actor FakeEventSink: ReadingEventSink {
    private(set) var sent: [ReadingEventWire] = []
    private(set) var batches: [Int] = []
    let fails: Bool

    init(fails: Bool = false) { self.fails = fails }

    func send(_ events: [ReadingEventWire]) async throws {
        if fails { throw AccountError.offline }
        sent += events
        batches.append(events.count)
    }
}
