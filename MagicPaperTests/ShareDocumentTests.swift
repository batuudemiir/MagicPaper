import XCTest
@testable import MagicPaper

/// Aileyle paylaş (FAZ 18): bağlantıya yalnızca ad ve masal metni girer.
/// Sunucu aynı sınırı `firebase/tests/family.test.mjs`'te zorlar.
final class ShareDocumentTests: XCTestCase {

    private let expiry = Date(timeIntervalSince1970: 1_800_000_000)

    func testTheLinkCarriesOnlyTheNameAndTheText() throws {
        var story = ReaderFixtures.textStory(pages: 2, title: "Şehri Kurtaran Gün")
        story.origin = nil
        let document = ShareDocument(familyID: "f1", childName: "İrem", stories: [story], voice: false, expiresAt: expiry)

        XCTAssertEqual(Set(document.fields.keys), ["familyID", "childName", "stories", "voice"])
        let stories = try XCTUnwrap(document.fields["stories"] as? [[String: Any]])
        XCTAssertEqual(Set(stories[0].keys), ["title", "pages", "audio"])
        XCTAssertEqual(stories[0]["title"] as? String, "Şehri Kurtaran Gün")
        XCTAssertEqual((stories[0]["pages"] as? [String])?.count, 2)
        XCTAssertEqual(document.fields["voice"] as? Bool, false)
    }

    func testRecordedPagesAreSharedOnlyWhenVoiceIsChosen() {
        let story = ReaderFixtures.textStory(pages: 4)
        let silent = ShareDocument(familyID: "f1", childName: "Ada", stories: [story], voice: false, expiresAt: expiry,
                                   recordedPages: { _ in [0, 2] })
        XCTAssertEqual(silent.stories[0].audio, [])
        XCTAssertTrue(silent.audioKeys.isEmpty)

        let voiced = ShareDocument(familyID: "f1", childName: "Ada", stories: [story], voice: true, expiresAt: expiry,
                                   recordedPages: { _ in [0, 2, 9] })
        XCTAssertEqual(voiced.stories[0].audio, [0, 2], "a page the story does not have is dropped")
        XCTAssertEqual(voiced.audioKeys, ["0/0", "0/2"])
        XCTAssertTrue(voiced.voice)
    }

    func testVoiceWithNothingRecordedIsAPlainLink() {
        let document = ShareDocument(familyID: "f1", childName: "Ada", stories: [ReaderFixtures.textStory(pages: 2)],
                                     voice: true, expiresAt: expiry)
        XCTAssertFalse(document.voice)
    }

    func testLimitsMatchTheRules() {
        let many = (0..<25).map { _ in ReaderFixtures.textStory(pages: 1) }
        let document = ShareDocument(familyID: "f1", childName: String(repeating: "a", count: 60), stories: many,
                                     voice: false, expiresAt: expiry)
        XCTAssertEqual(document.stories.count, 20)
        XCTAssertEqual(document.childName.count, 40)
    }

    func testTokensAreLongUrlSafeAndDifferent() {
        let tokens = (0..<50).map { _ in FamilyShareLink.makeToken() }
        XCTAssertEqual(Set(tokens).count, 50)
        for token in tokens {
            XCTAssertEqual(token.count, 22)
            XCTAssertNil(token.range(of: "[^A-Za-z0-9_-]", options: .regularExpression))
        }
        XCTAssertEqual(FamilyShareLink.url("abc").absoluteString, "https://magicpaper-393a7.web.app/s/abc")
    }

    func testExpiryWording() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(FamilyCopy.expiry(now.addingTimeInterval(-1), now: now), "süresi doldu")
        XCTAssertEqual(FamilyCopy.expiry(now.addingTimeInterval(3 * 86_400), now: now), "3 gün kaldı")
    }
}
