import XCTest
import StoryEngine
@testable import MagicPaper

/// Yaratma akışının görünümden çıkarılmış kararları (FAZ 10).
final class StoryCreationStepsTests: XCTestCase {

    // MARK: - Fikir adımı kaldırıldı (21 Ekim 2026)

    /// Akış en fazla üç adımdır ve "Fikir" artık onlardan biri değil.
    ///
    /// Adım bayrağın arkasında uyuyordu; bir cihazda bayrak açık kaldığı için
    /// üründen çıkmış sayılan ekran telefonda görünüyordu. Kapalı bir özellik,
    /// silinmiş bir özellik değildir.
    func testThereIsNoIdeaStep() {
        for child in [true, false] {
            XCTAssertFalse(StoryCreationSteps.stepLabels(childStep: child).contains("Fikir"))
        }
    }

    // MARK: - Çocuk ve konu adımları (16 Ekim 2026)

    /// Tek çocuklu evde "hangi çocuk?" cevabı belli bir sorudur.
    func testTheChildStepNeedsMoreThanOneChild() {
        XCTAssertFalse(StoryCreationSteps.showsChildStep(profileCount: 0))
        XCTAssertFalse(StoryCreationSteps.showsChildStep(profileCount: 1))
        XCTAssertTrue(StoryCreationSteps.showsChildStep(profileCount: 2))
    }

    /// Konu ayrı bir adım değil: mod adımının içinde beliriyor, bu yüzden
    /// adım noktalarına bir nokta eklemiyor.
    func testStepLabelsGrowWithTheStepsActuallyShown() {
        XCTAssertEqual(StoryCreationSteps.stepLabels(), ["Masal", "Kimler"])
        XCTAssertEqual(StoryCreationSteps.stepLabels(childStep: true),
                       ["Çocuk", "Masal", "Kimler"])
    }

    /// Sıra ekrandaki sırayla aynı olmalı: "Konu" moddan sonra, "Kimler" en
    /// sonda. Akış adım numarasını bu listeden okuyor.
    func testTheLastStepIsAlwaysTheCast() {
        for child in [true, false] {
            let labels = StoryCreationSteps.stepLabels(childStep: child)
            XCTAssertEqual(labels.last, "Kimler")
            XCTAssertEqual(labels.first, child ? "Çocuk" : "Masal")
        }
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
