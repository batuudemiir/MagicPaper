import XCTest
import StoryEngine
@testable import MagicPaper

/// Kullanımdan öğrenme, uygulama tarafı (FAZ 14).
///
/// Kabul: olay şemasında kişisel alan yok. Ve okuyucunun bir oturumu tam
/// olarak bir kayıt bırakır: çocuğun kendi okuma kaydı, paylaşım açıksa bir
/// anonim olay.
@MainActor
final class ReadingEventTests: XCTestCase {

    private var usageFolder = ""
    private var queueFolder = ""
    private let secretName = "Gizliad"
    private let istanbul = TimeZone(identifier: "Europe/Istanbul")!

    override func setUp() {
        super.setUp()
        usageFolder = "UsageTest-\(UUID().uuidString)"
        queueFolder = "EventTest-\(UUID().uuidString)"
    }

    override func tearDown() {
        StoryUsageStore(subdirectory: usageFolder).eraseAll()
        ReadingEventQueue(subdirectory: queueFolder).eraseAll()
        super.tearDown()
    }

    private var usageStore: StoryUsageStore { StoryUsageStore(subdirectory: usageFolder) }
    private var queue: ReadingEventQueue { ReadingEventQueue(subdirectory: queueFolder) }

    private func story(child: UUID = UUID(), mode: StoryMode = .adventure, pages: Int = 6,
                       relation: String? = "sibling", origin: Bool = true) -> MagicPaper.Story {
        var story = ReaderFixtures.textStory(pages: pages)
        story.childName = secretName
        story.childProfileID = child
        if origin {
            story.origin = StoryOrigin(
                seed: "seed-1", storyIdeaID: nil,
                blueprintID: "blueprint_threshold_x", settingID: "setting_x",
                companionID: "companion_x", discoveryID: "object_x",
                fingerprint: "f", catalogVersion: "v", worldID: nil,
                modeID: mode.rawValue, selectionStrategy: "direct", ageBand: "5-6",
                subOptionID: nil, familyCharacterID: "family-id-1", familyRelation: relation)
        }
        return story
    }

    private func recorder(_ story: MagicPaper.Story, sharing: Bool = true,
                          at date: String = "2026-10-06 21:40") -> ReadingSessionRecorder {
        ReadingSessionRecorder(
            story: story, usageStore: usageStore, queue: queue,
            isSharing: { sharing }, companionKind: { _ in "tavşan" },
            now: { TestClock.date(date, zone: self.istanbul) }, timeZone: { self.istanbul })
    }

    private let read = MPReadingSession(secondsRead: 120, pagesTurned: 5)

    // MARK: - Schema

    /// The keys are a contract with the server, and the whitelist is the
    /// privacy promise: anything added here is a decision.
    func testTheEventCarriesOnlyTheseKeys() throws {
        let event = try XCTUnwrap(ReadingEvent(
            story: story(), pageReached: 3, finished: false, reread: false,
            companionKind: "tavşan", at: Date(), in: istanbul))
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), [
            "schemaVersion", "storyID", "mode", "blueprintID", "contentIDs", "companionKind",
            "familyRelation", "ageBand", "pageReached", "pageCount", "finished", "reread", "day"])
        XCTAssertEqual(Set((object["contentIDs"] as? [String: Any] ?? [:]).keys),
                       ["setting", "companion", "discovery"])
    }

    func testNothingPersonalIsInTheEvent() throws {
        let child = UUID()
        let story = story(child: child)
        let event = try XCTUnwrap(ReadingEvent(
            story: story, pageReached: 3, finished: true, reread: false,
            companionKind: "tavşan", at: Date(), in: istanbul))
        let json = String(decoding: try JSONEncoder().encode(event), as: UTF8.self)
        for secret in [secretName, child.uuidString, "family-id-1", story.title] {
            XCTAssertFalse(json.contains(secret), "\(secret) leaked into the event")
        }
        // The relation, never the character.
        XCTAssertEqual(event.familyRelation, "sibling")

        var dumped = ""
        dump(event, to: &dumped)
        for text in [String(describing: event), String(reflecting: event), "\(event)", dumped] {
            XCTAssertFalse(text.contains(story.id.uuidString))
            XCTAssertFalse(text.contains(secretName))
        }
    }

    /// Rounded to the day, in the reader's own time zone.
    func testTheTimeIsADay() throws {
        let late = TestClock.date("2026-10-06 23:50", zone: istanbul)
        let event = try XCTUnwrap(ReadingEvent(
            story: story(), pageReached: 0, finished: false, reread: false,
            companionKind: nil, at: late, in: istanbul))
        XCTAssertEqual(event.day, "2026-10-06")
        XCTAssertEqual(ReadingEvent(
            story: story(), pageReached: 0, finished: false, reread: false,
            companionKind: nil, at: late, in: TimeZone(identifier: "UTC")!)?.day, "2026-10-06")
        XCTAssertEqual(ReadingEvent(
            story: story(), pageReached: 0, finished: false, reread: false,
            companionKind: nil, at: late, in: TimeZone(identifier: "Asia/Tokyo")!)?.day, "2026-10-07")
    }

    func testAStoryWithoutAnOriginMakesNoEvent() {
        XCTAssertNil(ReadingEvent(
            story: story(origin: false), pageReached: 0, finished: true, reread: false,
            companionKind: nil, at: Date(), in: istanbul))
    }

    // MARK: - Queue

    func testTheOutboundPayloadHasNoProfileID() throws {
        let child = UUID()
        recorder(story(child: child)).close(furthestPage: 2, session: read)
        XCTAssertEqual(queue.outbound().count, 1)
        let json = String(decoding: try JSONEncoder().encode(queue.outbound()), as: UTF8.self)
        XCTAssertFalse(json.contains(child.uuidString))
    }

    func testTheQueueIsBounded() throws {
        let event = try XCTUnwrap(ReadingEvent(
            story: story(), pageReached: 0, finished: false, reread: false,
            companionKind: nil, at: Date(), in: istanbul))
        let child = UUID()
        for _ in 0..<(ReadingEventQueue.capacity + 3) { queue.append(event, for: child) }
        XCTAssertEqual(queue.count, ReadingEventQueue.capacity)
    }

    func testAnUnreadableQueueIsSetAsideNotOverwritten() throws {
        let directory = try XCTUnwrap(StoryEngineStorage.directory(queueFolder))
        try Data("not json".utf8).write(to: directory.appendingPathComponent("queue.json"))
        recorder(story()).close(furthestPage: 2, session: read)
        XCTAssertEqual(queue.count, 1)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(names.contains { $0.hasPrefix("queue.unreadable-") })
    }

    // MARK: - Sessions

    func testAFinishedSessionIsRecordedOnce() throws {
        let child = UUID()
        let story = story(child: child)
        let session = recorder(story)
        session.reachedEnding()
        session.close(furthestPage: 5, session: read)
        session.close(furthestPage: 5, session: read)

        let stats = try XCTUnwrap(usageStore.stats(of: story.id, for: child))
        XCTAssertEqual(stats.sessions, 1)
        XCTAssertEqual(stats.completions, 1)
        XCTAssertFalse(stats.abandoned)
        let event = try XCTUnwrap(queue.outbound().first)
        XCTAssertEqual(queue.count, 1)
        XCTAssertTrue(event.finished)
        XCTAssertFalse(event.reread)
        XCTAssertEqual(event.pageReached, 5)
        XCTAssertEqual(event.pageCount, 6)
        XCTAssertEqual(event.companionKind, "tavşan")
        XCTAssertEqual(event.mode, "adventure")
        XCTAssertEqual(event.day, "2026-10-06")
    }

    /// Paging back and forth at the end is one reading; "Tekrar oku" and
    /// reaching the end again is a second.
    func testOnlyReadingAgainCountsASecondFinish() throws {
        let child = UUID()
        let story = story(child: child)
        let session = recorder(story)
        session.reachedEnding()
        session.reachedEnding()
        session.readAgain()
        session.reachedEnding()
        session.close(furthestPage: 5, session: read)
        XCTAssertEqual(usageStore.stats(of: story.id, for: child)?.completions, 2)
        XCTAssertEqual(queue.outbound().first?.reread, true)
    }

    func testFinishingAStoryFinishedBeforeIsAReread() throws {
        let child = UUID()
        let story = story(child: child)
        let first = recorder(story)
        first.reachedEnding()
        first.close(furthestPage: 5, session: read)
        let second = recorder(story, at: "2026-10-07 20:00")
        second.reachedEnding()
        second.close(furthestPage: 5, session: read)

        XCTAssertEqual(queue.outbound().map(\.reread), [false, true])
        XCTAssertEqual(queue.outbound().map(\.day), ["2026-10-06", "2026-10-07"])
        XCTAssertEqual(usageStore.stats(of: story.id, for: child)?.completions, 2)
    }

    func testLeavingBeforeTheEndIsAbandoning() throws {
        let child = UUID()
        let story = story(child: child)
        recorder(story).close(furthestPage: 2, session: read)
        let stats = try XCTUnwrap(usageStore.stats(of: story.id, for: child))
        XCTAssertTrue(stats.abandoned)
        XCTAssertEqual(queue.outbound().first?.finished, false)
        XCTAssertEqual(queue.outbound().first?.pageReached, 2)
    }

    /// Today's reading time ran out: the story was stopped, not left.
    func testABudgetStopIsNotAbandoning() throws {
        let child = UUID()
        let story = story(child: child)
        recorder(story).close(furthestPage: 2, session: read, interrupted: true)
        let stats = try XCTUnwrap(usageStore.stats(of: story.id, for: child))
        XCTAssertFalse(stats.abandoned)
        XCTAssertEqual(queue.outbound().first?.finished, false)
        // A later reading left by the child is abandoning again.
        recorder(story).close(furthestPage: 3, session: read)
        XCTAssertTrue(try XCTUnwrap(usageStore.stats(of: story.id, for: child)).abandoned)
    }

    /// An opening that was not a reading teaches nothing.
    func testAnAccidentalOpeningRecordsNothing() {
        let child = UUID()
        let story = story(child: child)
        recorder(story).close(furthestPage: 0, session: MPReadingSession(secondsRead: 3, pagesTurned: 0))
        XCTAssertNil(usageStore.stats(of: story.id, for: child))
        XCTAssertEqual(queue.count, 0)
    }

    /// Kapalı anahtar yalnızca gönderimi durdurur; çocuğun kendi kaydı sürer.
    func testWithSharingOffOnlyTheLocalRecordIsKept() {
        let child = UUID()
        let story = story(child: child)
        let session = recorder(story, sharing: false)
        session.reachedEnding()
        session.close(furthestPage: 5, session: read)
        XCTAssertEqual(usageStore.stats(of: story.id, for: child)?.completions, 1)
        XCTAssertEqual(queue.count, 0)
    }

    func testAStoryWithoutAnOriginOrAProfileIsNotRecorded() {
        let oldStory = story(origin: false)
        recorder(oldStory).close(furthestPage: 5, session: read)
        var orphan = story()
        orphan.childProfileID = nil
        recorder(orphan).close(furthestPage: 5, session: read)
        XCTAssertEqual(queue.count, 0)
    }

    /// The live store reads an absent key as on (karar: 6 Ekim 2026).
    func testTheSettingDefaultsToSharing() {
        let stored = UserDefaults.standard.object(forKey: "mp_shareUsageData") as? Bool
        XCTAssertEqual(MPSettingsStore.shared.shareUsageData, stored ?? true)
    }

    // MARK: - What the engine learns from

    func testUsageReachesTheEngineAsIdsAndOutcomes() throws {
        let child = UUID()
        let reread = story(child: child)
        let left = story(child: child, mode: .bedtime)
        let unread = story(child: child)
        let a = recorder(reread)
        a.reachedEnding(); a.readAgain(); a.reachedEnding()
        a.close(furthestPage: 5, session: read)
        recorder(left).close(furthestPage: 1, session: read)

        let usage = usageStore.usage(of: [reread, left, unread], for: child)
        XCTAssertEqual(usage.count, 2, "An unread story teaches nothing.")
        XCTAssertEqual(usage.map(\.completions).sorted(), [0, 2])
        let abandoned = try XCTUnwrap(usage.first { $0.abandoned })
        XCTAssertEqual(abandoned.mode, .bedtime)
        XCTAssertEqual(abandoned.blueprintID, "blueprint_threshold_x")
        XCTAssertEqual(abandoned.companionID, "companion_x")
    }

    func testOnlyTheLatestStoriesTeach() {
        let child = UUID()
        var stories: [MagicPaper.Story] = []
        for index in 0..<(StoryUsageStore.learningWindow + 5) {
            var story = story(child: child)
            story.createdAt = Date(timeIntervalSince1970: TimeInterval(index * 1000))
            stories.append(story)
            recorder(story).close(furthestPage: 1, session: read)
        }
        XCTAssertEqual(usageStore.usage(of: stories, for: child).count, StoryUsageStore.learningWindow)
    }

    // MARK: - Deleting

    func testDeletingAProfileTakesOnlyItsRecords() {
        let gone = UUID(), kept = UUID()
        let goneStory = story(child: gone), keptStory = story(child: kept)
        recorder(goneStory).close(furthestPage: 2, session: read)
        recorder(keptStory).close(furthestPage: 2, session: read)

        usageStore.delete(for: gone)
        queue.delete(for: gone)

        XCTAssertNil(usageStore.stats(of: goneStory.id, for: gone))
        XCTAssertNotNil(usageStore.stats(of: keptStory.id, for: kept))
        XCTAssertEqual(queue.outbound().map(\.storyID), [keptStory.id.uuidString])
    }

    func testDeletingAProfileAlsoRemovesASetAsideQueue() throws {
        let directory = try XCTUnwrap(StoryEngineStorage.directory(queueFolder))
        try Data("not json".utf8).write(to: directory.appendingPathComponent("queue.json"))
        recorder(story()).close(furthestPage: 2, session: read)
        queue.delete(for: UUID())
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertFalse(names.contains { $0.hasPrefix("queue.unreadable-") })
        XCTAssertEqual(queue.count, 1)
    }

    func testEraseAllEmptiesBoth() {
        let child = UUID()
        let story = story(child: child)
        recorder(story).close(furthestPage: 2, session: read)
        StoryUsageStore.eraseAll(subdirectory: usageFolder)
        ReadingEventQueue.eraseAll(subdirectory: queueFolder)
        XCTAssertNil(usageStore.stats(of: story.id, for: child))
        XCTAssertEqual(queue.count, 0)
    }

    /// The real cascade: `deleteProfile` reaches the live stores. Same
    /// save-and-restore as `FamilyCharacterDeletionTests`.
    func testDeleteProfileReachesTheLiveStores() throws {
        let manager = ProfileManager.shared
        let savedProfiles = manager.profiles
        let savedCurrent = manager.currentProfile
        let savedData = UserDefaults.standard.data(forKey: "user_profiles")
        let savedCurrentID = UserDefaults.standard.string(forKey: "current_profile_id")
        let leaving = UserProfile(name: secretName, age: 5, profileType: .child)
        let story = story(child: leaving.id)
        defer {
            StoryUsageStore().delete(for: leaving.id)
            ReadingEventQueue().delete(for: leaving.id)
            manager.profiles = savedProfiles
            manager.currentProfile = savedCurrent
            UserDefaults.standard.set(savedData, forKey: "user_profiles")
            UserDefaults.standard.set(savedCurrentID, forKey: "current_profile_id")
        }
        manager.profiles = savedProfiles + [leaving]

        ReadingSessionRecorder(story: story, isSharing: { true }, companionKind: { _ in nil })
            .close(furthestPage: 2, session: read)
        XCTAssertNotNil(StoryUsageStore().stats(of: story.id, for: leaving.id))
        XCTAssertTrue(ReadingEventQueue().outbound().contains { $0.storyID == story.id.uuidString })

        let result = manager.deleteProfile(leaving)
        if case .failure = result { return XCTFail("deleteProfile refused") }

        XCTAssertNil(StoryUsageStore().stats(of: story.id, for: leaving.id))
        XCTAssertFalse(ReadingEventQueue().outbound().contains { $0.storyID == story.id.uuidString })
    }
}
