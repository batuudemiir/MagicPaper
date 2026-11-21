import XCTest
@testable import MagicPaper

/// E7 (karar: Batuhan 19 Kasım 2026): çocuk alanındaki kilit penceresi sakin.
/// Sayı, geri sayım, fiyat ve satış dili yok; satış ebeveyn kapısının arkasında.
final class LockedCopyTests: XCTestCase {

    func testTheLockedCopyCarriesNoNumberCountdownOrSalesWord() {
        let banned = ["saat", "kaldı", "₺", "premium", "satın", "abone", "hemen", "anında", "üret", "oluştur"]
        for capability in Capability.allCases {
            let copy = MPLockedCopy(capability)
            for text in [copy.ragi, copy.title, copy.message] {
                XCTAssertNil(text.rangeOfCharacter(from: .decimalDigits), "\(capability.rawValue): \(text)")
                let lower = text.lowercased(with: Locale(identifier: "tr_TR"))
                for word in banned {
                    XCTAssertFalse(lower.contains(word), "\(capability.rawValue): \(word) in \(text)")
                }
            }
        }
    }

    /// Günün masalı yazıldıysa yarına bakılır, saate değil.
    func testTheDailyLimitLooksToTomorrow() {
        XCTAssertTrue(MPLockedCopy(.unlimitedTextStories).message.hasPrefix("Yarın"))
    }
}
