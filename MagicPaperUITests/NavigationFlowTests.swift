import XCTest

/// Faz 2 korkuluğu (`docs/STARTUP_PLANI.md`): gezinmenin ana yolları. Sekme, push ve
/// geri, masal yazmayı açıp kapatma, ebeveyn odasından dönüş.
@MainActor
final class NavigationFlowTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-mpDemo", "YES", "-mpDemoLibrary", "YES", "-mp_approveBeforeShow", "NO"] + arguments
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Ana sayfa"].waitForExistence(timeout: 15))
        return app
    }

    func testTabsSwitch() {
        let app = launch()
        for (tab, title) in [("Masallar", "Masallar"), ("Kitaplık", "Kitaplık"), ("Odam", "Odam")] {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), tab)
        }
    }

    /// Bir seviye derin sayfa itilir, "Geri" köke döner, çubuk görünür kalır.
    func testPushAndBackKeepTabBar() {
        let app = launch(["-mpStartTab", "corner"])
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Masal ailem")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        let back = app.buttons["Geri"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        back.tap()
        XCTAssertTrue(app.staticTexts["Kim okuyor?"].waitForExistence(timeout: 5))
    }

    /// Sekme değişince yığın kaybolmaz.
    func testPageSurvivesTabSwitch() {
        let app = launch(["-mpStartTab", "corner"])
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Masal ailem")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.buttons["Geri"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Kitaplık"].tap()
        XCTAssertFalse(app.buttons["Geri"].waitForExistence(timeout: 2))
        app.tabBars.buttons["Odam"].tap()
        XCTAssertTrue(app.buttons["Geri"].waitForExistence(timeout: 5))
    }

    func testCreateOpensAndCloses() {
        let app = launch()
        app.tabBars.buttons["Masal yaz"].tap()
        let close = app.buttons["Kapat"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        close.tap()
        XCTAssertTrue(app.tabBars.buttons["Ana sayfa"].waitForExistence(timeout: 5))
    }

    /// Çubuktan okumaya 3 dokunuş: Masal yaz, mod, Masalı yaz (`STARTUP_PLANI.md`).
    func testStoryIsThreeTapsAway() {
        let app = launch()
        app.tabBars.buttons["Masal yaz"].tap()
        let mode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Maceraya çıkalım")).firstMatch
        XCTAssertTrue(mode.waitForExistence(timeout: 10))
        mode.tap()
        let write = app.buttons["Masalı yaz"]
        XCTAssertTrue(write.waitForExistence(timeout: 5))
        write.tap()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 20), "Masal kendiliğinden açılmalı")
    }

    /// Sürpriz 2 dokunuş ve başka soru sormaz; "Masalı aç" beklemeden açar.
    func testSurpriseWritesWithoutMoreQuestions() {
        let app = launch()
        app.tabBars.buttons["Masal yaz"].tap()
        let surprise = app.buttons["Bana sürpriz yap"]
        XCTAssertTrue(surprise.waitForExistence(timeout: 10))
        surprise.tap()
        XCTAssertFalse(app.buttons["Masalı yaz"].exists)
        let skip = app.buttons["Masalı aç"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 5))
    }

    /// Kenara dokunmak sayfa çevirir; sürükleme küçük çocuğa zor (`STARTUP_PLANI.md`).
    func testEdgeTapTurnsThePage() {
        let app = launch()
        app.tabBars.buttons["Masal yaz"].tap()
        let surprise = app.buttons["Bana sürpriz yap"]
        XCTAssertTrue(surprise.waitForExistence(timeout: 10))
        surprise.tap()
        let skip = app.buttons["Masalı aç"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 5))
        let folio = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Sayfa ")).firstMatch
        XCTAssertTrue(folio.waitForExistence(timeout: 5))
        let before = folio.label
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let turned = NSPredicate(format: "label BEGINSWITH %@ AND label != %@", "Sayfa ", before)
        XCTAssertTrue(app.staticTexts.matching(turned).firstMatch.waitForExistence(timeout: 5))
    }

    /// "Çocuk modu" odayı kapatır, çocuk bıraktığı sekmede olur.
    func testLeavingParentRoomReturnsToKidTab() {
        let app = launch(["-mpStartTab", "library", "-mpStartParent", "YES"])
        let kid = app.buttons["Çocuk modu"]
        XCTAssertTrue(kid.waitForExistence(timeout: 15))
        kid.tap()
        XCTAssertTrue(app.staticTexts["Kitaplık"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Çocuk modu"].exists)
    }
}
