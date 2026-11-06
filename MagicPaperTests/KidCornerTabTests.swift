import XCTest
@testable import MagicPaper

/// 12 · Benim köşem: sekmenin avatarından açılan sayfa (karar 7 Kasım 2026).
@MainActor
final class KidCornerTabTests: XCTestCase {

    func testEveryTabSurvivesTheKidTabBarRoundTrip() {
        for tab in MPTab.allCases {
            XCTAssertEqual(MPTab(tab.kidTab), tab)
        }
    }

    func testTheAvatarPushesTheCornerOnTheOpenTab() {
        let app = MPAppState()
        app.tab = .library
        app.openKidCorner()
        XCTAssertEqual(app.tab, .library)
        XCTAssertEqual(app.kidPaths[.library], [.corner])
    }

    /// Profil Köşem'de seçilir: seçince Köşem kapanmaz, eski çocuğun sayfaları kapanır.
    func testChangingChildKeepsTheCornerAndClosesTheChildsPages() {
        let app = MPAppState()
        app.openKidCorner()
        app.openKidPage(.newWords(UUID()))
        app.tab = .gunluk
        app.openKidCorner()
        app.openKidPage(.series(UUID()))
        app.closePagesOfPreviousChild()
        XCTAssertEqual(app.kidPaths[.home], [.corner])
        XCTAssertEqual(app.masallarPath, [.kid(.corner)])
    }

    /// Ebeveyn odası çocuğun üstüne açılır: kapanınca çocuk bıraktığı yerdedir.
    func testLeavingTheParentRoomReturnsTheChildToWhereItWas() {
        let app = MPAppState()
        let route = MPKidRoute.newWords(UUID())
        app.openKidCorner()
        app.openKidPage(route)
        app.requestParentMode()
        XCTAssertTrue(app.showGate)
        app.unlockParent()
        XCTAssertFalse(app.showGate)
        XCTAssertTrue(app.isParentMode)
        app.enterChildMode()
        XCTAssertFalse(app.isParentMode)
        XCTAssertEqual(app.tab, .home)
        XCTAssertEqual(app.kidPaths[.home], [.corner, route])
    }

    /// Köşem'deki "Büyükler için" ve "Ekle" yalnızca kapıyı açar; ebeveyn alanına geçmez.
    func testTheCornerReachesTheParentAreaOnlyThroughTheGate() {
        let app = MPAppState()
        app.openKidCorner()
        app.requestParentMode()
        XCTAssertTrue(app.showGate)
        XCTAssertFalse(app.isParentMode)
        XCTAssertEqual(app.kidPaths[.home], [.corner])
    }

    /// Widget ve Siri bağlantıları Köşem açıkken de Ana sayfaya döner.
    func testASurfaceLinkFromTheCornerLandsOnHome() {
        let app = MPAppState()
        app.openKidCorner()
        app.sheet = .profilePicker
        app.open(.series, childID: nil)
        XCTAssertEqual(app.tab, .home)
        XCTAssertNil(app.sheet)
    }

    // MARK: - Sekme yığınları (7 Kasım 2026)

    func testAKidPageIsPushedOnTheOpenTabAndBackPopsIt() {
        let app = MPAppState()
        app.openKidCorner()
        let route = MPKidRoute.newWords(UUID())
        app.openKidPage(route)
        XCTAssertEqual(app.kidPaths[.home], [.corner, route])
        XCTAssertNil(app.sheet)
        app.closeKidPage()
        XCTAssertEqual(app.kidPaths[.home], [.corner])
    }

    func testEachTabKeepsItsOwnPathAcrossTabChanges() {
        let app = MPAppState()
        let route = MPKidRoute.series(UUID())
        app.tab = .library
        app.openKidPage(route)
        app.tab = .home
        XCTAssertEqual(app.kidPaths[.home] ?? [], [])
        app.tab = .library
        XCTAssertEqual(app.kidPaths[.library], [route])
    }

    func testReselectingATabReturnsItToItsRoot() {
        let app = MPAppState()
        app.openKidCorner()
        app.openKidPage(.familyCharacters(UUID()))
        app.reselectTab()
        XCTAssertEqual(app.kidPaths[.home], [])
    }

    func testTheSamePageIsNotPushedTwice() {
        let app = MPAppState()
        let route = MPKidRoute.newWords(UUID())
        app.openKidCorner()
        app.openKidPage(route)
        app.openKidPage(route)
        XCTAssertEqual(app.kidPaths[.home], [.corner, route])
    }

    /// Masallar'ın yığını çocuk sayfalarını `GunlukRoute.kid` içinde taşır.
    func testAKidPageOpenedFromMasallarStaysOnMasallar() {
        let app = MPAppState()
        let route = MPKidRoute.series(UUID())
        app.tab = .gunluk
        app.openKidPage(route)
        XCTAssertEqual(app.tab, .gunluk)
        XCTAssertEqual(app.masallarPath, [.kid(route)])
        app.closeKidPage()
        XCTAssertEqual(app.masallarPath, [])
    }

    func testCharacterPagesArePushedOnTheParentStackAndCloseTheSheet() {
        let app = MPAppState()
        app.requestParentMode()
        app.unlockParent()
        let id = UUID()
        app.sheet = .profileEdit(id)
        app.openKidPage(.familyCharacters(id))
        XCTAssertEqual(app.parentRoute, .familyCharacters(id))
        XCTAssertNil(app.sheet)
        XCTAssertTrue(app.kidPaths.isEmpty)
        app.closeKidPage()
        XCTAssertNil(app.parentRoute)
    }

    /// "Profili düzenle" eski hatasına dönmesin: yeni profil akışını açmaz.
    func testEditingAProfileOpensItsFormNotTheNewProfileFlow() {
        let app = MPAppState()
        app.requestParentMode()
        app.unlockParent()
        let id = UUID()
        app.sheet = .profileEdit(id)
        app.openProfileEdit(id)
        XCTAssertEqual(app.parentRoute, .profileEdit(id))
        XCTAssertNil(app.sheet)
        XCTAssertFalse(app.showProfileAdd)
    }

    func testEditingKeepsTheExactAgeWhileTheBandStaysTheSame() {
        let profile = UserProfile(name: "İrem", age: 6)
        XCTAssertEqual(profile.ageAfterEdit(to: profile.mpAgeRange), 6)
        let other = MPAgeRange.allCases.first { $0 != profile.mpAgeRange }!
        XCTAssertEqual(profile.ageAfterEdit(to: other), other.representativeAge)
        XCTAssertEqual(MPAgeRange.from(age: profile.ageAfterEdit(to: other)), other)
    }

    /// Seçilmiş renk korunur; seçilmemişse addan türeyen, ekranda görünen renk.
    func testEditingStartsFromTheColorTheAvatarAlreadyShows() {
        let profile = UserProfile(name: "İrem")
        let key = "mp_avatarColor_\(profile.id.uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        XCTAssertTrue(MP.C.avatarAccents.indices.contains(profile.mpColorIndex))
        UserProfile.storeColorIndex(2, for: profile.id)
        XCTAssertEqual(profile.mpColorIndex, 2)
    }

    /// Sheet kapanırken açılan modal yutulur: sıradaki iş kapanış bitince çalışır.
    func testWorkAfterASheetWaitsForItsDismissal() {
        let app = MPAppState()
        app.sheet = .profilePicker
        app.closeSheet { app.showProfileAdd = true }
        XCTAssertNil(app.sheet)
        XCTAssertFalse(app.showProfileAdd)
        app.runAfterSheet()
        XCTAssertTrue(app.showProfileAdd)
        // Yalnızca bir kez çalışır.
        app.showProfileAdd = false
        app.runAfterSheet()
        XCTAssertFalse(app.showProfileAdd)
    }

    func testReturningToChildModeClosesAnyOpenSheet() {
        let app = MPAppState()
        app.requestParentMode()
        app.unlockParent()
        app.sheet = .signOut
        app.enterChildMode()
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
