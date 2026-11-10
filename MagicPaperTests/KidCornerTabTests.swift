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
        app.router.sheet = .interests(UUID())
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
        app.router.parentRoute = .profileHub(id)
        app.router.sheet = .interests(id)
        app.router.openKidPage(.familyCharacters(id))
        XCTAssertEqual(app.router.parentPath, [.profileHub(id), .familyCharacters(id)])
        XCTAssertNil(app.router.sheet)
        XCTAssertTrue(app.router.kidPaths.isEmpty)
        app.router.closeKidPage()
        XCTAssertEqual(app.router.parentRoute, .profileHub(id))
    }

    /// "Profili düzenle" eski hatasına dönmesin: yeni profil akışını açmaz.
    func testEditingAProfileOpensItsFormNotTheNewProfileFlow() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        let id = UUID()
        app.router.parentRoute = .profileHub(id)
        app.router.openProfileEdit(id)
        XCTAssertEqual(app.router.parentPath, [.profileHub(id), .profileEdit(id)])
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
        app.router.sheet = .interests(UUID())
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

/// Faz 7: tek kapı ve çok seviyeli ebeveyn yığını.
@MainActor
final class SingleGateTests: XCTestCase {

    func testGatedWorkRunsAfterTheGateWithoutOpeningTheRoom() {
        let app = MPAppState()
        var ran = false
        app.router.requestGate { ran = true }
        XCTAssertTrue(app.router.showGate)
        app.router.gateSucceeded()
        XCTAssertFalse(app.router.showGate)
        XCTAssertFalse(app.router.isParentMode)
        XCTAssertFalse(ran, "İş kapı ekranı kapanınca çalışır")
        app.router.gateDismissed()
        XCTAssertTrue(ran)
    }

    func testCancelledGateForgetsTheWork() {
        let app = MPAppState()
        var ran = false
        app.router.requestGate { ran = true }
        app.router.showGate = false
        app.router.gateDismissed()
        XCTAssertFalse(ran)
        app.router.requestParentMode()
        app.router.gateSucceeded()
        XCTAssertTrue(app.router.isParentMode, "Bekleyen iş yoksa oda açılır")
    }

    func testInsideTheRoomGatedWorkRunsDirectly() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        var ran = false
        app.router.requestGate { ran = true }
        XCTAssertTrue(ran)
        XCTAssertFalse(app.router.showGate)
    }

    func testLeavingTheRoomClearsTheWholeParentStack() {
        let app = MPAppState()
        app.router.requestParentMode()
        app.router.unlockParent()
        let id = UUID()
        app.router.parentRoute = .profileHub(id)
        app.router.parentRoute = .profileEdit(id)
        app.router.enterChildMode()
        XCTAssertTrue(app.router.parentPath.isEmpty)
    }

    func testSwitchingParentTabsClearsTheStack() {
        let app = MPAppState()
        app.router.parentRoute = .bookExport
        app.router.parentTab = .settings
        XCTAssertTrue(app.router.parentPath.isEmpty)
    }
}

/// Faz 7: masal sonu sözü ve Özet cümlesi.
final class PageStructureCopyTests: XCTestCase {

    func testClassicEndingWithoutANameStaysGrammatical() {
        XCTAssertEqual(StoryEndingCopy.bravo(""), "Bravo!")
        XCTAssertEqual(StoryEndingCopy.bravo("İrem"), "Bravo, İrem!")
        XCTAssertEqual(StoryEndingCopy.goodNight(" "), "İyi geceler.")
    }

    func testOverviewSentence() {
        XCTAssertEqual(ParentInsight.sentence(stories: 0, minutes: 0, streak: 0), "Bu hafta henüz masal okunmadı.")
        XCTAssertEqual(ParentInsight.sentence(stories: 4, minutes: 38, streak: 3), "Bu hafta 4 masal, 38 dakika, 3 akşam üst üste.")
        XCTAssertEqual(ParentInsight.sentence(stories: 1, minutes: 0, streak: 1), "Bu hafta 1 masal.")
    }

    func testOverviewWeekStartsOnMonday() throws {
        // 12 Kasım 2026 Perşembe; hafta 9 Kasım Pazartesi başlar.
        let thursday = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 12)))
        let week = try XCTUnwrap(ParentInsight.weekInterval(containing: thursday))
        XCTAssertEqual(Calendar(identifier: .gregorian).component(.weekday, from: week.start), 2)
    }
}
