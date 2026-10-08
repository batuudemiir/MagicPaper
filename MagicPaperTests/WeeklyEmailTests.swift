import XCTest
@testable import MagicPaper

/// Haftalık özet (FAZ 18): ayar satırının ne söylediği. Gönderim ve metin
/// `firebase/functions/test/functions.test.mjs`'te.
final class WeeklyEmailTests: XCTestCase {
    func testOnlyTheFounderWithAVerifiedEmailCanTurnItOn() {
        XCTAssertEqual(WeeklyEmailCopy.subtitle(enabled: false, email: "a@b.c", isFounder: false),
                       "Ailenin kurucusu açabilir")
        XCTAssertEqual(WeeklyEmailCopy.subtitle(enabled: false, email: nil, isFounder: true),
                       "Hesabında doğrulanmış e-posta yok")
        XCTAssertEqual(WeeklyEmailCopy.subtitle(enabled: true, email: "a@b.c", isFounder: true),
                       "Pazar sabahları · a@b.c")
    }

    @MainActor
    func testTheTestAuthHasNoEmail() {
        XCTAssertNil(FakeAccountAuth().verifiedEmail)
    }
}
