import XCTest

/// Faz 0 korkuluğu (`docs/STARTUP_PLANI.md`): Apple'ın erişilebilirlik denetimi her
/// ana ekranda. Etiket eksiği, küçük dokunma alanı, kesilen yazı ve kontrast
/// sorunları burada yakalanır. Örnek veriyi `MPDebugLaunch` kurar (yalnızca DEBUG).
/// Denetim yalnızca o an ekranda görünen bölümü tarar.
///
/// Kontrast dışarıda: piksel ölçümü resim, cam çubuk ve kaydırma kenarında kararsız
/// (düz zemindeki başlık bir koşuda kalıp ötekinde geçti). Otomatik kontrast testi
/// henüz yok.
@MainActor
final class AccessibilityAuditTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-mpDemo", "YES", "-mpDemoLibrary", "YES"] + arguments
        app.launch()
        return app
    }

    /// Rapor yalnızca türü söyler; öğeyi de günlüğe yazar ki sorun bulunabilsin.
    private func audit(_ app: XCUIApplication,
                       types: XCUIAccessibilityAuditType = XCUIAccessibilityAuditType.all.subtracting(.contrast)) throws {
        try app.performAccessibilityAudit(for: types) { issue in
            let element = issue.element
            if Self.isKnownFalseAlarm(issue, element: element) { return true }
            print("AUDIT | \(self.name) | \(issue.compactDescription) | \(element?.label ?? "-") | \(element?.frame ?? .zero)")
            return false
        }
    }

    /// Burada elenen her tür için gerekçe var; yenisi eklenmeden önce gerçekten
    /// yanlış alarm olduğu ölçülür.
    private static func isKnownFalseAlarm(_ issue: XCUIAccessibilityAuditIssue, element: XCUIElement?) -> Bool {
        switch issue.auditType {
        case .hitRegion:
            // Sayfa noktaları ve adım göstergesi yalnızca bilgi verir, dokunulmaz.
            return element?.elementType == .other
        case .dynamicType, .textClipped:
            // `HomeStatLine`, sığmazsa alt alta düşen `ViewThatFits`; denetim bunu sezemiyor.
            // Arama kutusu sistemin `TextField`'ı.
            let label = element?.label ?? ""
            return label.hasSuffix("yıldız") || label.hasSuffix("üst üste") || label == "·"
                || element?.elementType == .textField
        default:
            return false
        }
    }

    private func auditKidTab(_ tab: String, types: XCUIAccessibilityAuditType = XCUIAccessibilityAuditType.all.subtracting(.contrast),
                             file: StaticString = #filePath, line: UInt = #line) throws {
        let app = launch(["-mpStartTab", tab])
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), file: file, line: line)
        try audit(app, types: types)
    }

    private func auditParentTab(_ tab: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let app = launch(["-mpStartParent", "YES", "-mpParentTab", tab])
        XCTAssertTrue(app.buttons["Çocuk modu"].waitForExistence(timeout: 15), file: file, line: line)
        try audit(app)
    }

    func testAuditHome() throws { try auditKidTab("home") }
    /// Başlık ve vitrin resim üstünde, yazıları bilerek `accessibility1` ile sınırlı.
    func testAuditMasallar() throws { try auditKidTab("gunluk", types: XCUIAccessibilityAuditType.all.subtracting([.contrast, .dynamicType])) }
    func testAuditLibrary() throws { try auditKidTab("library") }
    func testAuditProfile() throws { try auditKidTab("corner") }

    func testAuditParentOverview() throws { try auditParentTab("overview") }
    func testAuditParentSafety() throws { try auditParentTab("safety") }
    func testAuditParentSettings() throws { try auditParentTab("settings") }

    /// Ebeveyn odası açıkken arkadaki çocuk ekranı VoiceOver'a kapalı olmalı. Bugün
    /// `accessibilityHidden`, `isModal` ve `opacity` XCUITest ağacından düşürmüyor.
    /// Gerçek VoiceOver davranışı cihazda henüz denenmedi. Düzelince bu test hata
    /// verir: `XCTExpectFailure` satırını kaldır.
    func testParentRoomHidesKidScreen() {
        XCTExpectFailure("Ebeveyn odasında çocuk öğeleri erişilebilirlik ağacında duruyor")
        let app = launch(["-mpStartTab", "home", "-mpStartParent", "YES"])
        XCTAssertTrue(app.buttons["Çocuk modu"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Masal yaz"].exists)
        XCTAssertFalse(app.staticTexts["Maceraya çıkalım"].exists)
    }

    func testAuditCreateFlow() throws {
        let app = launch(["-mpStartTab", "home"])
        let create = app.tabBars.buttons["Masal yaz"]
        XCTAssertTrue(create.waitForExistence(timeout: 15))
        create.tap()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 10))
        try audit(app)
    }
}
