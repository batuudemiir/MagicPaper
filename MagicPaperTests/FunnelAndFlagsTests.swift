import XCTest
@testable import MagicPaper

/// Faz 6: onaylı anonim huni ve uzaktan bayraklar.
final class FunnelAndFlagsTests: XCTestCase {

    private var defaults: UserDefaults!
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        defaults = UserDefaults(suiteName: "FunnelAndFlagsTests")
        defaults.removePersistentDomain(forName: "FunnelAndFlagsTests")
    }

    private func funnel() -> MPFunnel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return MPFunnel(defaults: defaults, now: { [unowned self] in self.clock }, calendar: calendar)
    }

    func testEachStepOnceWithCoarseValue() {
        funnel().appOpened()
        clock += 95
        funnel().record(.firstStory)
        funnel().record(.firstStory)
        let wires = funnel().pending
        XCTAssertEqual(wires.map(\.step), ["firstOpen", "firstStory"])
        XCTAssertEqual(wires[1].value, 120, "95 sn, 120 sn kovasına yuvarlanır")
        XCTAssertEqual(wires[1].days, 0)
    }

    func testWireCarriesNoIdentity() {
        funnel().appOpened()
        let keys = Set(funnel().pending[0].fields.keys)
        XCTAssertTrue(keys.isSubset(of: ["schemaVersion", "step", "days", "value"]))
    }

    func testFirstWeekCountsReadDaysOnce() {
        funnel().appOpened()
        funnel().storyFinished()
        clock += 86_400 * 2
        funnel().storyFinished()
        funnel().storyFinished()
        clock += 86_400 * 6
        funnel().appOpened()
        funnel().appOpened()
        let week = funnel().pending.filter { $0.step == "firstWeek" }
        XCTAssertEqual(week.count, 1)
        XCTAssertEqual(week.first?.value, 2)
    }

    func testFlushNeedsConsentAndClearsSent() async {
        funnel().appOpened()
        var sent: [MPFunnel.Wire] = []
        await funnel().flush(sharingOn: false, consentGiven: true, signedIn: true) { sent += $0 }
        XCTAssertTrue(sent.isEmpty)
        await funnel().flush(sharingOn: true, consentGiven: true, signedIn: true) { sent += $0 }
        XCTAssertEqual(sent.count, 1)
        XCTAssertTrue(funnel().pending.isEmpty)
    }

    func testFailedSendKeepsEvents() async {
        funnel().appOpened()
        struct Down: Error {}
        await funnel().flush(sharingOn: true, consentGiven: true, signedIn: true) { _ in throw Down() }
        XCTAssertEqual(funnel().pending.count, 1)
    }

    func testRemoteFlagsReadOnlyKnownNames() {
        XCTAssertFalse(MPRemoteFlags.value(.sleepMode, default: false, defaults: defaults))
        MPRemoteFlags.save(["sleepMode": true, "paywallEverywhere": true], defaults: defaults)
        XCTAssertTrue(MPRemoteFlags.value(.sleepMode, default: false, defaults: defaults))
        XCTAssertNil((defaults.dictionary(forKey: "mp_remoteFlags") as? [String: Bool])?["paywallEverywhere"])
        MPRemoteFlags.save(nil, defaults: defaults)
        XCTAssertFalse(MPRemoteFlags.value(.sleepMode, default: false, defaults: defaults))
    }

    func testFeedWithBrokenFlagsStillDecodes() throws {
        let json = #"{"schemaVersion":1,"feedVersion":3,"publishedAt":"2026-11-08","stories":[],"flags":{"sleepMode":"evet"}}"#
        let feed = try JSONDecoder().decode(ContentFeed.self, from: Data(json.utf8))
        XCTAssertNil(feed.flags)
        XCTAssertEqual(feed.feedVersion, 3)
    }
}
