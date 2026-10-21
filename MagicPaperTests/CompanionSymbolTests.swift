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

    /// Everything the catalog would offer if nothing filtered it.
    private func candidates() -> [CompanionChoice] {
        OfflineStoryService.shared
            .companionCandidates(forIdeaID: nil, mode: nil, age: nil)
            .map(CompanionChoice.init)
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

    /// The filter above is allowed to hide a companion for exactly one reason:
    /// its picture is already on the screen. A companion dropped for any other
    /// reason is content loss hiding behind a cosmetic rule, so this names the
    /// kind and fails.
    func testTheFilterHidesNothingButARepeatedPicture() {
        let offered = companions()
        let shownSymbols = Set(offered.map { CompanionStep.symbol(forType: $0.kind) })
        let offeredIDs = Set(offered.map(\.id))

        for hidden in candidates() where !offeredIDs.contains(hidden.id) {
            XCTAssertTrue(
                shownSymbols.contains(CompanionStep.symbol(forType: hidden.kind)),
                "\(hidden.name) (\(hidden.kind)) ekrandan düştü ama resmi başka "
                + "kimsede yok — bu bir tekrar süzmesi değil, içerik kaybı.")
        }
    }

    /// What the catalog currently cannot draw, so growth is visible instead of
    /// silent: a kind the symbol set has nothing for lands on the paw, and the
    /// filter then hides all but one of them. This test does not fail for that
    /// — it records it, and fails only if the paw is carrying companions the
    /// `symbol(forType:)` map could have named.
    func testTheFallbackCarriesOnlyUnnamedKinds() {
        let named: Set<String> = [
            "baykuş", "kuş", "yunus", "balık", "ejderha", "tavşan",
            "tilki", "köpek", "kedi", "ayı", "kaplumbağa", "kertenkele",
            "robot", "kelebek"
        ]
        let onPaw = candidates()
            .filter { CompanionStep.symbol(forType: $0.kind) == "pawprint" }
            .map(\.kind)
        XCTAssertTrue(
            onPaw.allSatisfy { !named.contains($0) },
            "Adı `symbol(forType:)`'ta olan bir tür patiye düşmüş: \(onPaw.sorted())")
        if !onPaw.isEmpty {
            print("Çizimi olmayan türler (ekranda en çok biri görünür): \(Set(onPaw).sorted())")
        }
    }
}
