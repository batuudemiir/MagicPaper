import XCTest
@testable import MagicPaper

/// Kendi sesin (FAZ 18): kayıtların cihazda tutulması, aileye gönderilmesi,
/// eşitlenmesi ve silinmesi; okuyucunun hangi sesi çalacağı.
@MainActor
final class VoiceRecordingStoreTests: XCTestCase {

    private var root: URL!
    private let story = UUID()

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory.appendingPathComponent("VoiceTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    private func tempAudio(_ bytes: String = "ses") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rec-\(UUID().uuidString).m4a")
        try Data(bytes.utf8).write(to: url)
        return url
    }

    private func makeStore(remote: FakeVoiceRemote? = FakeVoiceRemote(), folder: String? = "families/f1/voice") -> VoiceRecordingStore {
        VoiceRecordingStore(root: root, remote: remote, folder: { folder })
    }

    func testASavedPageIsKeptOnTheDeviceAndUploadedToTheFamilysFolder() async throws {
        let remote = FakeVoiceRemote()
        let store = makeStore(remote: remote)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 2, seconds: 12.5, by: "u1")

        XCTAssertTrue(store.isRecorded(story, page: 2))
        XCTAssertNotNil(store.localFile(story, page: 2))
        XCTAssertEqual(store.recordings(for: story)?.pages["2"], 12.5)
        await store.flush()
        let uploads = await remote.uploads
        XCTAssertEqual(uploads, ["families/f1/voice/\(story.uuidString)/2.m4a"])
        XCTAssertFalse(store.hasPendingWork)
    }

    func testWithoutAnAccountTheRecordingWaitsOnTheDevice() async throws {
        let remote = FakeVoiceRemote()
        let store = makeStore(remote: remote, folder: nil)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        await store.flush()
        let uploads = await remote.uploads
        XCTAssertTrue(uploads.isEmpty)
        XCTAssertTrue(store.hasPendingWork)
    }

    func testAFailedUploadIsRetriedLater() async throws {
        let remote = FakeVoiceRemote()
        await remote.setFailing(true)
        let store = makeStore(remote: remote)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        await store.flush()
        XCTAssertTrue(store.hasPendingWork)
        await remote.setFailing(false)
        await store.flush()
        XCTAssertFalse(store.hasPendingWork)
    }

    func testTheIndexSurvivesARestart() throws {
        let first = makeStore()
        try first.save(recordingAt: try tempAudio(), storyID: story, page: 1, seconds: 4)
        let second = makeStore()
        XCTAssertTrue(second.isRecorded(story, page: 1))
        XCTAssertEqual(second.recordedStoryCount, 1)
    }

    func testDeletingAStoryRemovesItsFilesHereAndThere() async throws {
        let remote = FakeVoiceRemote()
        let store = makeStore(remote: remote)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 1, seconds: 3)
        await store.flush()
        let file = store.fileURL(story, page: 0)

        store.deleteRecordings(for: story)
        await store.flush()

        XCTAssertFalse(store.hasRecording(story))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let deletes = await remote.deletes
        XCTAssertEqual(Set(deletes), ["families/f1/voice/\(story.uuidString)/0.m4a",
                                      "families/f1/voice/\(story.uuidString)/1.m4a"])
    }

    func testWithdrawingConsentDeletesOnlyThatAdultsPages() throws {
        let store = makeStore()
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3, by: "anne")
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 1, seconds: 3, by: "baba")
        store.deleteAll(recordedBy: "anne")
        XCTAssertFalse(store.isRecorded(story, page: 0))
        XCTAssertTrue(store.isRecorded(story, page: 1))
    }

    func testARecordingFromAnotherDeviceArrivesAndIsDownloadedWhenRead() async throws {
        let remote = FakeVoiceRemote()
        let store = makeStore(remote: remote)
        store.applySynced(VoiceRecordingSet(pages: ["0": 5, "3": 6]), for: story)
        XCTAssertTrue(store.isRecorded(story, page: 3))
        XCTAssertNil(store.localFile(story, page: 3), "not here yet")

        await store.prefetch(story)

        XCTAssertNotNil(store.localFile(story, page: 3))
        let downloads = await remote.downloads
        XCTAssertEqual(Set(downloads), ["families/f1/voice/\(story.uuidString)/0.m4a",
                                        "families/f1/voice/\(story.uuidString)/3.m4a"])
    }

    func testARemoteDeletionRemovesTheLocalFile() throws {
        let store = makeStore()
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        let file = store.fileURL(story, page: 0)
        store.applySynced(nil, for: story)
        XCTAssertFalse(store.hasRecording(story))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testAPageRerecordedElsewhereIsFetchedAgain() throws {
        let store = makeStore()
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        store.applySynced(VoiceRecordingSet(pages: ["0": 4.2]), for: story)
        XCTAssertNil(store.localFile(story, page: 0), "the old take is not the family's take any more")
    }

    func testTheSyncedRecordCarriesNoAudio() throws {
        let store = makeStore()
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3, by: "u1")
        let payload = try SyncCoding.encode(try XCTUnwrap(store.syncPayloads.first).set)
        XCTAssertEqual(payload, #"{"by":{"0":"u1"},"pages":{"0":3}}"#)
    }

    func testEraseLocalLeavesTheFamilysCopyAlone() async throws {
        let remote = FakeVoiceRemote()
        let store = makeStore(remote: remote)
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)
        await store.flush()
        store.eraseLocal()
        XCTAssertFalse(store.hasRecording(story))
        let deletes = await remote.deletes
        XCTAssertTrue(deletes.isEmpty)
    }

    // MARK: - Kim okusun?

    func testTheNarratorReadsWhereThereIsNoRecording() throws {
        let key = FamilyFeatureAccess.key(.voiceRecording)
        let before = UserDefaults.standard.object(forKey: key)
        FamilyFeatureAccess.setDeveloperFlag(.voiceRecording, true)
        defer { UserDefaults.standard.set(before, forKey: key) }
        let settings = MPSettingsStore.shared
        let wasFamily = settings.familyVoice
        defer { settings.familyVoice = wasFamily }

        let store = makeStore()
        try store.save(recordingAt: try tempAudio(), storyID: story, page: 0, seconds: 3)

        settings.familyVoice = true
        XCTAssertNotNil(MPNarration.recording(story, page: 0, store: store, settings: settings))
        XCTAssertNil(MPNarration.recording(story, page: 1, store: store, settings: settings), "page 1 has no recording")
        XCTAssertTrue(MPNarration.isAvailable(for: story, store: store))

        settings.familyVoice = false
        XCTAssertNil(MPNarration.recording(story, page: 0, store: store, settings: settings), "the parent chose the narrator")
    }

    func testTheSleepSessionKeepsEachPagesPlaceInTheStory() {
        var s = ReaderFixtures.textStory(pages: 3)
        s.pages[1].text = "   "
        let session = MPSleepSession(story: s)
        XCTAssertEqual(session.pages.count, 2)
        XCTAssertEqual(session.pageIndexes, [0, 2])
        XCTAssertEqual(session.storyID, s.id)
    }
}

actor FakeVoiceRemote: VoiceRemote {
    private(set) var uploads: [String] = []
    private(set) var downloads: [String] = []
    private(set) var deletes: [String] = []
    private var failing = false

    func setFailing(_ value: Bool) { failing = value }

    func upload(file: URL, to path: String) async throws {
        if failing { throw AccountError.offline }
        uploads.append(path)
    }

    func download(path: String, to file: URL) async throws {
        if failing { throw AccountError.offline }
        downloads.append(path)
        try Data("ses".utf8).write(to: file)
    }

    func delete(path: String) async throws {
        if failing { throw AccountError.offline }
        deletes.append(path)
    }
}
