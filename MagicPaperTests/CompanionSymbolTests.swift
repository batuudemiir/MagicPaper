import XCTest
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

    /// Through the seam the screen uses, so this checks what a parent can
    /// actually be shown, whichever source is behind it.
    private func companions() -> [CompanionChoice] {
        StoryChoiceSources.current.companionChoices(forIdeaID: nil, mode: nil, age: nil)
    }

    func testThereAreCompanionsToCheck() {
        XCTAssertGreaterThanOrEqual(companions().count, 4)
    }

    /// No two selectable companions are drawn the same.
    func testEverySelectableCompanionHasItsOwnPicture() {
        var byType: [String: [String]] = [:]
        for companion in companions() {
            byType[CompanionStep.symbol(forType: companion.kind), default: []]
                .append("\(companion.name) (\(companion.kind))")
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
            .filter { CompanionStep.symbol(forType: $0.kind) == "pawprint" }
            .map(\.kind)
        XCTAssertLessThanOrEqual(
            onPaw.count, 1,
            "More than one companion fell through to the paw: \(onPaw.sorted()). "
            + "Give each a symbol in CompanionStep.symbol(forType:).")
    }
}
