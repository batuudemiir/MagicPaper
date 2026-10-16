import XCTest
@testable import MagicPaper

/// 12 · Benim köşem alt barda "Köşem" sekmesi (karar 13 Ekim 2026).
@MainActor
final class KidCornerTabTests: XCTestCase {

    func testEveryTabSurvivesTheKidTabBarRoundTrip() {
        for tab in MPTab.allCases {
            XCTAssertEqual(MPTab(tab.kidTab), tab)
        }
        XCTAssertEqual(MPTab.corner.label, "Köşem")
    }

    func testOpeningTheCornerSelectsItsTab() {
        let app = MPAppState()
        app.openKidCorner()
        XCTAssertEqual(app.tab, .corner)
    }

    func testReturningFromTheParentAreaLandsOnHome() {
        let app = MPAppState()
        app.openKidCorner()
        app.requestParentMode()
        XCTAssertTrue(app.showGate)
        app.unlockParent()
        XCTAssertFalse(app.showGate)
        XCTAssertTrue(app.isParentMode)
        app.enterChildMode()
        XCTAssertFalse(app.isParentMode)
        XCTAssertEqual(app.tab, .home)
    }

    /// Köşem'deki kilit ve "Ekle" yalnızca kapıyı açar; ebeveyn alanına geçmez.
    func testTheCornerReachesTheParentAreaOnlyThroughTheGate() {
        let app = MPAppState()
        app.openKidCorner()
        app.requestParentMode()
        XCTAssertTrue(app.showGate)
        XCTAssertFalse(app.isParentMode)
        XCTAssertEqual(app.tab, .corner)
    }

    /// Widget ve Siri bağlantıları Köşem açıkken de Ana sayfaya döner.
    func testASurfaceLinkFromTheCornerLandsOnHome() {
        let app = MPAppState()
        app.openKidCorner()
        app.sheet = .newWords(UUID())
        app.open(.series, childID: nil)
        XCTAssertEqual(app.tab, .home)
        XCTAssertNil(app.sheet)
    }

    func testTheBadgeGridShowsEveryBadgeEarnedOnesFirst() {
        let earned: Set<MPMilestone> = [.sevenBedtime, .firstStory]
        let grid = MPMilestone.gridOrder(earned: earned)
        XCTAssertEqual(grid.count, MPMilestone.allCases.count)
        XCTAssertEqual(Set(grid), Set(MPMilestone.allCases))
        XCTAssertEqual(Array(grid.prefix(2)), [.firstStory, .sevenBedtime])
        XCTAssertFalse(grid.dropFirst(2).contains { earned.contains($0) })
    }

    func testWithNothingEarnedEveryBadgeIsLockedInListOrder() {
        XCTAssertEqual(MPMilestone.gridOrder(earned: []), MPMilestone.allCases)
    }

    /// "Ekle" kapıdan geçer; kapı açılınca ebeveyn özetinde kalmadan profil
    /// ekleme açılır (16 Ekim denetimi).
    func testAddingAProfileFromTheCornerOpensProfileCreationAfterTheGate() {
        let app = MPAppState()
        app.openKidCorner()
        app.requestProfileAdd()
        XCTAssertTrue(app.showGate)
        XCTAssertFalse(app.showProfileAdd)
        app.unlockParent()
        app.gateDismissed()
        XCTAssertTrue(app.isParentMode)
        XCTAssertTrue(app.showProfileAdd)
    }

    func testCancellingTheGateForgetsThePendingProfileAdd() {
        let app = MPAppState()
        app.requestProfileAdd()
        app.showGate = false
        app.gateDismissed()
        XCTAssertFalse(app.showProfileAdd)
        // Sonraki sıradan kilit açılışı profil eklemeyi açmaz.
        app.requestParentMode()
        app.unlockParent()
        app.gateDismissed()
        XCTAssertFalse(app.showProfileAdd)
    }

    func testInTheParentAreaAddingAProfileSkipsTheGate() {
        let app = MPAppState()
        app.requestParentMode()
        app.unlockParent()
        app.gateDismissed()
        app.requestProfileAdd()
        XCTAssertTrue(app.showProfileAdd)
    }
}
