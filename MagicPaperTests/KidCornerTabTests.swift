import XCTest
@testable import MagicPaper

/// 12 · Profil sekmesi (karar 7 Kasım 2026).
@MainActor
final class KidCornerTabTests: XCTestCase {

    func testEveryTabSurvivesTheKidTabBarRoundTrip() {
        for tab in MPTab.allCases {
            XCTAssertEqual(MPTab(tab.kidTab), tab)
        }
    }

    func testOpeningTheProfileSelectsItsTab() {
        let app = MPAppState()
        app.router.tab = .library
        app.router.openKidCorner()
        XCTAssertEqual(app.router.tab, .corner)
    }

    /// Çocuk değişince onun sayfaları kapanır; açık klasik herkesindir, kalır.
    func testChangingChildClosesTheChildsPages() {
        let app = MPAppState()
        app.router.openKidCorner()
        app.router.openKidPage(.newWords(UUID()))
        app.router.tab = .gunluk
        app.router.masallarPath = [.search]
        app.router.openKidPage(.series(UUID()))
        app.router.closePagesOfPreviousChild()
        XCTAssertEqual(app.router.kidPaths[.corner] ?? [], [])
        XCTAssertEqual(app.router.masallarPath, [.search])
    }

    /// Ebeveyn odası çocuğun üstüne açılır: kapanınca çocuk bıraktığı yerdedir.
    func testLeavingTheParentRoomReturnsTheChildToWhereItWas() {
        let app = MPAppState()
        let route = MPKidRoute.newWords(UUID())
        app.router.openKidCorner()
        app.router.openKidPage(route)
        app.router.requestParentMode()
        XCTAssertTrue(app.router.showGate)
        app.router.unlockParent()
        XCTAssertFalse(app.router.showGate)
        XCTAssertTrue(app.router.isParentMode)
        app.router.enterChildMode()
        XCTAssertFalse(app.router.isParentMode)
        XCTAssertEqual(app.router.tab, .corner)
        XCTAssertEqual(app.router.kidPaths[.corner], [route])
    }

    /// Profil'deki "Büyükler için" ve "Ekle" yalnızca kapıyı açar; ebeveyn alanına geçmez.
    func testTheProfileReachesTheParentAreaOnlyThroughTheGate() {
        let app = MPAppState()
        app.router.openKidCorner()
        app.router.requestParentMode()
        XCTAssertTrue(app.router.showGate)
        XCTAssertFalse(app.router.isParentMode)
        XCTAssertEqual(app.router.tab, .corner)
    }

    /// Widget ve Siri bağlantıları Köşem açıkken de Ana sayfaya döner.
    func testASurfaceLinkFromTheCornerLandsOnHome() {
        let app = MPAppState()
        app.router.openKidCorner()
        app.router.sheet = .profilePicker
        app.open(.series, childID: nil)
        XCTAssertEqual(app.router.tab, .home)
        XCTAssertNil(app.router.sheet)
    }

    // MARK: - Sekme yığınları (7 Kasım 2026)

    func testAKidPageIsPushedOnTheOpenTabAndBackPopsIt() {
        let app = MPAppState()
        app.router.openKidCorner()
        let route = MPKidRoute.newWords(UUID())
        app.router.openKidPage(route)
        XCTAssertEqual(app.router.kidPaths[.corner], [route])
        XCTAssertNil(app.router.sheet)
        app.router.closeKidPage()
        XCTAssertEqual(app.router.kidPaths[.corner], [])
    }

    func testEachTabKeepsItsOwnPathAcrossTabChanges() {
        let app = MPAppState()
        let route = MPKidRoute.series(UUID())
        app.router.tab = .library
        app.router.openKidPage(route)
        app.router.tab = .home
        XCTAssertEqual(app.router.kidPaths[.home] ?? [], [])
        app.router.tab = .library
        XCTAssertEqual(app.router.kidPaths[.library], [route])
    }

    func testReselectingATabReturnsItToItsRoot() {
        let app = MPAppState()
        app.router.openKidCorner()
        app.router.openKidPage(.familyCharacters(UUID()))
        app.router.reselectTab()
        XCTAssertEqual(app.router.kidPaths[.corner], [])
    }

    func testTheSamePageIsNotPushedTwice() {
        let app = MPAppState()
        let route = MPKidRoute.newWords(UUID())
        app.router.openKidCorner()
        app.router.openKidPage(route)
        app.router.openKidPage(route)
        XCTAssertEqual(app.router.kidPaths[.corner], [route])
    }

    /// Masallar'ın yığını çocuk sayfalarını `GunlukRoute.kid` içinde taşır.
    func testAKidPageOpenedFromMasallarStaysOnMasallar() {
        let app = MPAppState()
        let route = MPKidRoute.series(UUID())
        app.router.tab = .gunluk
        app.router.openKidPage(route)
        XCTAssertEqual(app.router.tab, .gunluk)
        XCTAssertEqual(app.router.masallarPath, [.kid(route)])
        app.router.closeKidPage()
        XCTAssertEqual(app.router.masallarPath, [])
    }

    func testCharacterPagesArePushedOnTheParentStackAndCloseTheSheet() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        let id = UUID()
        app.router.sheet = .profileEdit(id)
        app.router.openKidPage(.familyCharacters(id))
        XCTAssertEqual(app.router.parentRoute, .familyCharacters(id))
        XCTAssertNil(app.router.sheet)
        XCTAssertTrue(app.router.kidPaths.isEmpty)
        app.router.closeKidPage()
        XCTAssertNil(app.router.parentRoute)
    }

    /// "Profili düzenle" eski hatasına dönmesin: yeni profil akışını açmaz.
    func testEditingAProfileOpensItsFormNotTheNewProfileFlow() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        let id = UUID()
        app.router.sheet = .profileEdit(id)
        app.router.openProfileEdit(id)
        XCTAssertEqual(app.router.parentRoute, .profileEdit(id))
        XCTAssertNil(app.router.sheet)
        XCTAssertFalse(app.router.showProfileAdd)
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
        app.router.sheet = .profilePicker
        app.router.closeSheet { app.router.showProfileAdd = true }
        XCTAssertNil(app.router.sheet)
        XCTAssertFalse(app.router.showProfileAdd)
        app.router.runAfterSheet()
        XCTAssertTrue(app.router.showProfileAdd)
        // Yalnızca bir kez çalışır.
        app.router.showProfileAdd = false
        app.router.runAfterSheet()
        XCTAssertFalse(app.router.showProfileAdd)
    }

    func testReturningToChildModeClosesAnyOpenSheet() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        app.router.sheet = .signOut
        app.router.enterChildMode()
        XCTAssertNil(app.router.sheet)
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
        app.router.openKidCorner()
        app.router.requestProfileAdd()
        XCTAssertTrue(app.router.showGate)
        XCTAssertFalse(app.router.showProfileAdd)
        app.router.unlockParent()
        app.router.gateDismissed()
        XCTAssertTrue(app.router.isParentMode)
        XCTAssertTrue(app.router.showProfileAdd)
    }

    func testCancellingTheGateForgetsThePendingProfileAdd() {
        let app = MPAppState()
        app.router.requestProfileAdd()
        app.router.showGate = false
        app.router.gateDismissed()
        XCTAssertFalse(app.router.showProfileAdd)
        // Sonraki sıradan kilit açılışı profil eklemeyi açmaz.
        app.router.requestParentMode()
        app.router.unlockParent()
        app.router.gateDismissed()
        XCTAssertFalse(app.router.showProfileAdd)
    }

    func testInTheParentAreaAddingAProfileSkipsTheGate() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        app.router.gateDismissed()
        app.router.requestProfileAdd()
        XCTAssertTrue(app.router.showProfileAdd)
    }
}
