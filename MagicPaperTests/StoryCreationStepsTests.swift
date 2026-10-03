import XCTest
import StoryEngine
@testable import MagicPaper

/// Yaratma akışının görünümden çıkarılmış kararları (FAZ 10).
final class StoryCreationStepsTests: XCTestCase {

    // MARK: - Fikir adımı (K7)

    func testTheIdeaStepNeedsTheFlagAndIdeas() {
        XCTAssertFalse(StoryCreationSteps.showsIdeaStep(hasIdeas: true, flag: false))
        XCTAssertFalse(StoryCreationSteps.showsIdeaStep(hasIdeas: false, flag: true))
        XCTAssertTrue(StoryCreationSteps.showsIdeaStep(hasIdeas: true, flag: true))
    }

    func testStepLabelsFollowTheFlag() {
        XCTAssertEqual(StoryCreationSteps.stepLabels(ideaStep: false), ["Masal", "Kimler"])
        XCTAssertEqual(StoryCreationSteps.stepLabels(ideaStep: true), ["Masal", "Fikir", "Kimler"])
    }

    // MARK: - Sürpriz (K6)

    func testSurpriseNeedsAtLeastTwoModes() {
        XCTAssertFalse(StoryCreationSteps.showsSurprise(availableModes: []))
        XCTAssertFalse(StoryCreationSteps.showsSurprise(availableModes: [.bedtime]))
        XCTAssertTrue(StoryCreationSteps.showsSurprise(availableModes: [.bedtime, .learning]))
    }

    // MARK: - Sıra (K5)

    func testScreenOrderIsBedtimeLearningAdventure() {
        XCTAssertEqual(StoryMode.displayOrder, [.bedtime, .learning, .adventure])
        XCTAssertEqual(Set(StoryMode.displayOrder), Set(StoryMode.allCases))
    }

    func testOnlyAvailableModesAreShownInScreenOrder() {
        XCTAssertEqual(StoryCreationSteps.shownModes([.learning, .adventure, .bedtime]),
                       [.bedtime, .learning, .adventure])
        XCTAssertEqual(StoryCreationSteps.shownModes([.adventure, .bedtime]), [.bedtime, .adventure])
        XCTAssertEqual(StoryCreationSteps.shownModes([]), [])
    }

    // MARK: - Ana sayfadan açılış (K8)

    func testAModeChosenOnHomeOpensAtWhoComesAlong() {
        let all = StoryMode.allCases
        XCTAssertEqual(StoryCreationSteps.openingPhase(preset: .bedtime, available: all), .companion(.bedtime))
        XCTAssertEqual(StoryCreationSteps.openingPhase(preset: nil, available: all), .mode)
    }

    /// Kurulamayan bir preset sessizce geçirilmez; akış modlardan açılır.
    func testAPresetThatCannotBeBuiltOpensAtTheModes() {
        XCTAssertEqual(StoryCreationSteps.openingPhase(preset: .learning, available: [.bedtime]), .mode)
    }

    /// Ana sayfadan preset ile gelindiğinde fikir adımı bayrak açıkken de
    /// atlanır: kart "Masalda kimler olsun?" adımına söz veriyor.
    func testAPresetSkipsTheIdeaStepEvenWithTheFlagOn() {
        XCTAssertEqual(StoryCreationSteps.openingPhase(preset: .learning, available: [.learning]),
                       .companion(.learning))
    }

    // MARK: - Mod adları

    func testModeTitles() {
        XCTAssertEqual(StoryMode.bedtime.title, "Uyku öncesi")
        XCTAssertEqual(StoryMode.learning.title, "Yeni şeyler öğrenelim")
        XCTAssertEqual(StoryMode.adventure.title, "Maceraya çıkalım")
    }
}
