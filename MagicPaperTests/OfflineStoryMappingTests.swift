import XCTest
import StoryEngine
@testable import MagicPaper

/// Step 4: what the engine composed becomes what the app reads.
///
/// This is the seam that fixes B1 — a text story used to be created, saved, and
/// then never reach the Reader — so most of what follows is about the story
/// arriving complete, identified, and rebuildable.
@MainActor
final class OfflineStoryMappingTests: XCTestCase {

    private let service = OfflineStoryService.shared

    private func profile(_ name: String = "Yeliz") -> UserProfile {
        UserProfile(name: name, age: 6, profileType: .child)
    }

    private func compose(
        ideaID: String? = nil,
        companionID: String? = nil,
        seed: String = "test-seed",
        child: UserProfile? = nil
    ) throws -> MagicPaper.Story {
        let profile = child ?? self.profile()
        let composed = try service.compose(
            childName: profile.name, ideaID: ideaID, companionID: companionID, seed: seed)
        return OfflineStoryMapper.appStory(
            from: composed.story,
            childName: profile.name,
            childProfileID: profile.id,
            storyIdeaID: ideaID,
            catalogVersion: composed.catalogVersion
        )
    }

    // MARK: - Content is reachable from the app bundle

    /// The engine's resources ship inside the package bundle. If this fails in
    /// the app but passes in the package, the resources did not make it into
    /// the `.app` — which is a packaging failure, not a logic one.
    func testTheCatalogLoadsFromInsideTheApp() {
        XCTAssertFalse(service.storyIdeas(forAge: 6).isEmpty,
                       "No story ideas reachable from the app bundle.")
    }

    func testIdeasAreOfferedForTheTargetAge() {
        XCTAssertEqual(service.storyIdeas(forAge: 6).count, 3)
        XCTAssertEqual(service.storyIdeas(forAge: 5).count, 3)
    }

    func testCompanionCandidatesAreOfferedForEachIdea() {
        for idea in service.storyIdeas(forAge: 6) {
            XCTAssertFalse(
                service.companionCandidates(forIdeaID: idea.id.rawValue).isEmpty,
                "\(idea.id.rawValue) offers no companions.")
        }
    }

    func testSurpriseStillOffersCompanions() {
        XCTAssertFalse(service.companionCandidates(forIdeaID: nil).isEmpty)
    }

    // MARK: - The mapped story

    func testAComposedStoryBecomesACompleteAppStory() throws {
        let story = try compose(ideaID: "idea_mysterious_signal_001")
        XCTAssertEqual(story.pages.count, 8)
        XCTAssertEqual(story.status, .completed, "An offline story is finished when it exists.")
        XCTAssertEqual(story.language, .turkish)
        XCTAssertFalse(story.title.isEmpty)
        XCTAssertNil(story.currentProgress)
    }

    func testNoPageCarriesAnUnresolvedPlaceholder() throws {
        for seed in ["a", "b", "c", "d", "e"] {
            let story = try compose(seed: seed)
            XCTAssertFalse(story.title.contains("{{"), story.title)
            for page in story.pages {
                XCTAssertFalse(page.text.isEmpty)
                XCTAssertFalse(page.text.contains("{{"), page.text)
            }
        }
    }

    func testTheStoryIsBoundToTheChildByID() throws {
        let yeliz = profile("Yeliz")
        let story = try compose(child: yeliz)
        XCTAssertEqual(story.childProfileID, yeliz.id)
        XCTAssertTrue(story.belongs(to: yeliz))
        XCTAssertFalse(story.belongs(to: profile("Demir")))
    }

    // MARK: - Provenance

    func testTheStoryRecordsEverythingThatDeterminedIt() throws {
        let story = try compose(ideaID: "idea_follow_the_traces_001", seed: "fixed-1")
        let origin = try XCTUnwrap(story.origin)

        XCTAssertEqual(origin.seed, "fixed-1")
        XCTAssertEqual(origin.storyIdeaID, "idea_follow_the_traces_001")
        XCTAssertFalse(origin.blueprintID.isEmpty)
        XCTAssertFalse(origin.settingID.isEmpty)
        XCTAssertFalse(origin.companionID.isEmpty)
        XCTAssertFalse(origin.discoveryID.isEmpty)
        XCTAssertFalse(origin.fingerprint.isEmpty)
        XCTAssertFalse(origin.catalogVersion.isEmpty)
    }

    /// §28: analytics must be answerable from ids, never from display strings.
    func testProvenanceIsIDsNotCopy() throws {
        let origin = try XCTUnwrap(try compose(ideaID: "idea_someone_needs_us_001").origin)
        XCTAssertTrue(origin.storyIdeaID?.hasPrefix("idea_") ?? false)
        XCTAssertFalse(origin.storyIdeaID?.contains(" ") ?? true)
    }

    func testSurpriseRecordsThatNoIdeaWasChosen() throws {
        XCTAssertNil(try XCTUnwrap(try compose(ideaID: nil).origin).storyIdeaID)
    }

    /// B5. The old path used `UInt64.random` and stored it nowhere, so no story
    /// could ever be rebuilt.
    func testTheSameSeedRebuildsTheSameStory() throws {
        let first = try compose(ideaID: "idea_mysterious_signal_001", seed: "repeat-me")
        let second = try compose(ideaID: "idea_mysterious_signal_001", seed: "repeat-me")

        XCTAssertEqual(first.origin?.fingerprint, second.origin?.fingerprint)
        XCTAssertEqual(first.title, second.title)
        XCTAssertEqual(first.pages.map(\.text), second.pages.map(\.text))
        XCTAssertNotEqual(first.id, second.id, "Each build is still its own story.")
    }

    func testDifferentSeedsGiveDifferentStories() throws {
        let texts = try ["s1", "s2", "s3", "s4", "s5", "s6"].map {
            try compose(ideaID: "idea_follow_the_traces_001", seed: $0).pages.map(\.text).joined()
        }
        XCTAssertGreaterThan(Set(texts).count, 1)
    }

    /// A story saved today must be rebuildable from what was stored with it.
    func testAStoryCanBeRebuiltFromItsOwnOrigin() throws {
        let original = try compose(ideaID: "idea_someone_needs_us_001", seed: "origin-test")
        let origin = try XCTUnwrap(original.origin)

        let rebuilt = try compose(ideaID: origin.storyIdeaID, seed: origin.seed)
        XCTAssertEqual(rebuilt.origin?.fingerprint, origin.fingerprint)
        XCTAssertEqual(rebuilt.pages.map(\.text), original.pages.map(\.text))
    }

    // MARK: - The chosen companion is actually used

    /// B3: the old flow mapped every choice onto `companion_fox_001`.
    func testTheChosenCompanionIsTheOneInTheStory() throws {
        for candidate in service.companionCandidates(forIdeaID: "idea_follow_the_traces_001") {
            let story = try compose(
                ideaID: "idea_follow_the_traces_001",
                companionID: candidate.id.rawValue,
                seed: "companion-test")
            XCTAssertEqual(story.origin?.companionID, candidate.id.rawValue)
            XCTAssertTrue(
                story.pages.contains { $0.text.contains(candidate.name) },
                "\(candidate.name) was selected but never appears in the text.")
        }
    }

    // MARK: - Persistence

    func testAMappedStoryRoundTripsThroughJSON() throws {
        let story = try compose(ideaID: "idea_mysterious_signal_001", seed: "codable")
        let decoded = try JSONDecoder().decode(
            MagicPaper.Story.self, from: try JSONEncoder().encode(story))

        XCTAssertEqual(decoded.origin, story.origin)
        XCTAssertEqual(decoded.childProfileID, story.childProfileID)
        XCTAssertEqual(decoded.pages.map(\.text), story.pages.map(\.text))
    }

    // MARK: - Failure

    /// §29: the user sees one sentence; the log gets the full account. What must
    /// never happen is the old behaviour — a `print` and a wizard that sits
    /// there (B2).
    func testAnImpossibleRequestFailsWithSomethingWorthLogging() {
        XCTAssertThrowsError(
            try service.compose(childName: "Yeliz", ideaID: "idea_does_not_exist", companionID: nil)
        ) { error in
            guard let failure = error as? OfflineStoryService.Failure else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertFalse(failure.detail.isEmpty, "A failure with nothing to log is B2 again.")
            XCTAssertTrue(failure.detail.contains("idea_does_not_exist"), failure.detail)
        }
    }

    func testAskingForACompanionTheIdeaCannotUseIsRefusedNotSubstituted() throws {
        // The fox knows the area, which the absence blueprint forbids; if the
        // engine silently swapped it, this would pass with a different animal.
        let ideaID = "idea_follow_the_traces_001"
        let candidates = service.companionCandidates(forIdeaID: ideaID).map(\.id.rawValue)
        guard !candidates.contains("companion_fox_pilot_001") else {
            throw XCTSkip("The fox is admissible here; nothing to assert.")
        }
        XCTAssertThrowsError(
            try service.compose(
                childName: "Yeliz", ideaID: ideaID, companionID: "companion_fox_pilot_001")
        )
    }
}
