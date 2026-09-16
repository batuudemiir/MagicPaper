import XCTest
import StoryEngine
@testable import MagicPaper

/// The age bands the app offers must be bands the content can actually serve.
///
/// The Story Idea screen is specified as three cards plus Surprise. It renders
/// whatever `storyIdeas(forAge:)` returns, so when that returns nothing the
/// screen does not break, warn, or look wrong — it quietly becomes a single
/// Surprise tile. No error, no log, no empty state. It simply stops being the
/// screen that was designed.
///
/// That is what happened: every authored idea is banded `5-6`, and the profile
/// editor offers four bands whose representative ages are 4, 6, 9 and 11. One
/// of the four has content. The other three produce the degraded screen, and
/// nothing anywhere says so.
///
/// The gating itself is correct and was asked for. What was missing is anyone
/// checking that the two ends meet.
@MainActor
final class AgeBandCoverageTests: XCTestCase {

    /// What the Story Idea screen needs before it is the screen in the plan.
    private let cardsRequired = 3

    /// Why age gating is currently off, as a test rather than a comment.
    ///
    /// It is off because every authored idea sits in one band, so gating could
    /// only ever subtract. The moment a second band is authored that stops being
    /// true and gating should come back — and this fails then, which is the
    /// whole point: the decision to re-enable it is not something anyone has to
    /// remember to revisit.
    func testAgeGatingStaysOffOnlyWhileTheCatalogIsSingleBanded() throws {
        let bands = Set(OfflineStoryService.shared.storyIdeas(forAge: 6).map(\.ageRange))
        XCTAssertEqual(
            bands.count, 1,
            "The catalog now offers ideas in more than one age band (\(bands.map(\.description).sorted())). "
            + "Re-enable the age filter in OfflineStoryService.storyIdeas(forAge:) — it was "
            + "disabled only because gating a single-banded catalog could subtract and never add.")
    }

    func testEveryAgeBandTheAppOffersHasIdeasToShow() {
        var starved: [String] = []
        for band in MPAgeRange.allCases {
            let count = OfflineStoryService.shared
                .storyIdeas(forAge: band.representativeAge).count
            if count < cardsRequired {
                starved.append("\(band.title) (age \(band.representativeAge)): \(count) ideas")
            }
        }
        XCTAssertTrue(
            starved.isEmpty,
            "Age bands the profile editor offers but the catalog cannot serve. A child in "
            + "one of these sees a screen with nothing on it but Surprise:\n  "
            + starved.joined(separator: "\n  "))
    }

    /// The band that does work, asserted separately so a regression there is
    /// distinguishable from the coverage gap above.
    func testTheAuthoredBandShowsAFullScreen() {
        XCTAssertGreaterThanOrEqual(
            OfflineStoryService.shared.storyIdeas(forAge: 6).count, cardsRequired,
            "The one age band with authored content must fill the screen.")
    }

    /// Surprise does not age-gate — `BlueprintSelector` never filters by age —
    /// so a child outside the authored band still gets a story, written for a
    /// five-year-old. Recorded here because it is the reason the gap is silent
    /// rather than a crash: nothing downstream fails, the prose is just aimed
    /// at the wrong child.
    func testSurpriseStillProducesAStoryOutsideTheAuthoredBand() throws {
        let result = try OfflineStoryService.shared.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, seed: "age-check")
        XCTAssertFalse(result.story.pages.isEmpty)
    }
}
