import XCTest
@testable import MagicPaper

/// The first app-level tests.
///
/// There was no test target until now (I1 §K1), which is why the profile and
/// story-identity changes had to be verified by driving the simulator by hand.
/// These cover the part that is pure logic and was previously unverifiable:
/// which stories belong to which child.
final class StoryPersistenceTests: XCTestCase {

    private func profile(_ name: String, id: UUID = UUID()) -> UserProfile {
        UserProfile(id: id, name: name, age: 6, profileType: .child)
    }

    private func story(
        _ title: String,
        childName: String,
        childProfileID: UUID? = nil
    ) -> Story {
        Story(
            title: title,
            childName: childName,
            childProfileID: childProfileID,
            theme: .fantasy,
            language: .turkish
        )
    }

    // MARK: - Identity

    func testAStoryBelongsToTheProfileItWasCreatedFor() {
        let yeliz = profile("Yeliz")
        XCTAssertTrue(story("A", childName: "Yeliz", childProfileID: yeliz.id).belongs(to: yeliz))
    }

    func testAStoryDoesNotBelongToADifferentProfile() {
        let yeliz = profile("Yeliz")
        let demir = profile("Demir")
        XCTAssertFalse(story("A", childName: "Yeliz", childProfileID: yeliz.id).belongs(to: demir))
    }

    /// The defect this replaced: identity was the name, so renaming a child
    /// orphaned their whole library.
    func testRenamingAChildDoesNotOrphanTheirStories() {
        let id = UUID()
        let before = profile("Yeliz", id: id)
        let story = story("A", childName: "Yeliz", childProfileID: id)

        var renamed = before
        renamed.name = "Yelİz Nur"

        XCTAssertTrue(story.belongs(to: renamed), "The story followed the name instead of the child.")
    }

    /// And its mirror: two children with the same name used to share one
    /// library.
    func testTwoChildrenWithTheSameNameDoNotShareStories() {
        let first = profile("Deniz")
        let second = profile("Deniz")
        XCTAssertNotEqual(first.id, second.id)

        let hers = story("A", childName: "Deniz", childProfileID: first.id)
        XCTAssertTrue(hers.belongs(to: first))
        XCTAssertFalse(hers.belongs(to: second))
    }

    // MARK: - Legacy rows

    /// Stories saved before the id existed decode with `nil` and must keep
    /// working, matched by name.
    func testALegacyStoryWithoutAnIDStillMatchesByName() {
        let yeliz = profile("Yeliz")
        let legacy = story("A", childName: "Yeliz", childProfileID: nil)
        XCTAssertTrue(legacy.belongs(to: yeliz))
    }

    func testALegacyStoryDoesNotMatchADifferentName() {
        let demir = profile("Demir")
        XCTAssertFalse(story("A", childName: "Yeliz", childProfileID: nil).belongs(to: demir))
    }

    /// The leak: two filters admitted any story with an empty name, so one
    /// nameless story appeared in every child's library.
    func testANamelessLegacyStoryBelongsToNobody() {
        XCTAssertFalse(story("A", childName: "", childProfileID: nil).belongs(to: profile("Yeliz")))
        XCTAssertFalse(story("A", childName: "", childProfileID: nil).belongs(to: profile("Demir")))
    }

    /// Once a story carries an id, the name is display only and must not
    /// override it.
    func testTheIDWinsOverAMatchingName() {
        let yeliz = profile("Yeliz")
        let other = UUID()
        let mislabelled = story("A", childName: "Yeliz", childProfileID: other)
        XCTAssertFalse(mislabelled.belongs(to: yeliz))
    }

    func testNoStoryBelongsToNoProfile() {
        let none: UserProfile? = nil
        XCTAssertFalse(story("A", childName: "Yeliz", childProfileID: UUID()).belongs(to: none))
    }

    // MARK: - Round trip

    /// `Story` is persisted as JSON in UserDefaults. A story written before the
    /// id field existed must still decode.
    func testALegacyEncodedStoryDecodesWithoutAnID() throws {
        let json = """
        {"id":"\(UUID().uuidString)","title":"Eski Masal","childName":"Yeliz",
         "theme":"fantasy","language":"tr","status":"completed","pages":[],
         "createdAt":0}
        """
        let decoded = try JSONDecoder().decode(Story.self, from: Data(json.utf8))
        XCTAssertNil(decoded.childProfileID)
        XCTAssertEqual(decoded.childName, "Yeliz")
    }

    func testAStoryRoundTripsThroughJSONKeepingItsProfileID() throws {
        let id = UUID()
        let original = story("Masal", childName: "Yeliz", childProfileID: id)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Story.self, from: data)
        XCTAssertEqual(decoded.childProfileID, id)
    }
}

// MARK: - Deletion ownership

/// Deleting a child deletes their stories — and only theirs. These pin the
/// stricter rule `isSolelyOwned(by:among:)` uses, because a wrong answer here
/// is unrecoverable.
extension StoryPersistenceTests {

    func testDeletingAChildTakesTheirIdentifiedStories() {
        let yeliz = profile("Yeliz")
        let demir = profile("Demir")
        let own = story("A", childName: "Yeliz", childProfileID: yeliz.id)
        XCTAssertTrue(own.isSolelyOwned(by: yeliz, among: [yeliz, demir]))
    }

    func testDeletingAChildLeavesTheirSiblingsStories() {
        let yeliz = profile("Yeliz")
        let demir = profile("Demir")
        let siblings = story("A", childName: "Demir", childProfileID: demir.id)
        XCTAssertFalse(siblings.isSolelyOwned(by: yeliz, among: [yeliz, demir]))
    }

    /// An identified story is the child's even if a sibling shares the name.
    func testAnIdentifiedStoryIsOwnedEvenWhenANameIsShared() {
        let first = profile("Deniz")
        let second = profile("Deniz")
        let own = story("A", childName: "Deniz", childProfileID: first.id)
        XCTAssertTrue(own.isSolelyOwned(by: first, among: [first, second]))
        XCTAssertFalse(own.isSolelyOwned(by: second, among: [first, second]))
    }

    func testALegacyStoryGoesWithTheOnlyChildOfThatName() {
        let yeliz = profile("Yeliz")
        let demir = profile("Demir")
        let legacy = story("A", childName: "Yeliz")
        XCTAssertTrue(legacy.isSolelyOwned(by: yeliz, among: [yeliz, demir]))
    }

    /// Two children named alike: a pre-id story could be either's, so neither
    /// deletion may take it.
    func testALegacyStoryIsKeptWhenTheNameIsShared() {
        let first = profile("Deniz")
        let second = profile("Deniz")
        let legacy = story("A", childName: "Deniz")
        XCTAssertFalse(legacy.isSolelyOwned(by: first, among: [first, second]))
        XCTAssertFalse(legacy.isSolelyOwned(by: second, among: [first, second]))
    }

    func testAStoryWithNoNameIsNeverTaken() {
        let yeliz = profile("Yeliz")
        let nameless = story("A", childName: "")
        XCTAssertFalse(nameless.isSolelyOwned(by: yeliz, among: [yeliz]))
    }
}
