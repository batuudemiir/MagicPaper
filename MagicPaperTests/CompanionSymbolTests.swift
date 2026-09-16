import XCTest
import StoryEngine
@testable import MagicPaper

/// The companion screen's whole job is choosing between three characters, and a
/// five-year-old chooses by the picture.
///
/// Four of the five shipped companions used to share one paw print. The screen
/// still worked, still looked well made, and offered three copies of the same
/// picture — a defect no test could see because nothing was wrong with any
/// individual card. The same shape as the story covers: distinct content
/// collapsing into one drawing somewhere between the catalog and the screen.
@MainActor
final class CompanionSymbolTests: XCTestCase {

    private func companions() -> [CatalogCompanion] {
        OfflineStoryService.shared.companionCandidates(forIdeaID: nil)
    }

    func testThereAreCompanionsToCheck() {
        XCTAssertGreaterThanOrEqual(companions().count, 4)
    }

    /// No two selectable companions are drawn the same.
    func testEverySelectableCompanionHasItsOwnPicture() {
        var byType: [String: [String]] = [:]
        for companion in companions() {
            byType[CompanionStep.symbol(forType: companion.type), default: []]
                .append("\(companion.name) (\(companion.type))")
        }
        let shared = byType.filter { $0.value.count > 1 }
        XCTAssertTrue(
            shared.isEmpty,
            "Companions sharing one symbol — the choice screen shows the same picture "
            + "more than once:\n"
            + shared.map { "  \($0.key): \($0.value.joined(separator: ", "))" }
                .sorted().joined(separator: "\n"))
    }

    /// The fallback is allowed to exist and is not allowed to be the answer for
    /// more than one animal at a time. This fails when the roster grows into a
    /// type the symbol set has nothing for *and* something else is already
    /// there — the moment the fallback stops being a fallback.
    func testTheFallbackIsNeverCarryingTwoAnimals() {
        let onPaw = companions()
            .filter { CompanionStep.symbol(forType: $0.type) == "pawprint" }
            .map(\.type)
        XCTAssertLessThanOrEqual(
            onPaw.count, 1,
            "More than one companion fell through to the paw: \(onPaw.sorted()). "
            + "Give each a symbol in CompanionStep.symbol(forType:).")
    }
}
