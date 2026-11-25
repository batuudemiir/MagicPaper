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

    /// 26 Kasım 2026: çocuğu büyüğüne de yönlendirmez; ücretli bir şeyi
    /// çocuğa istetmek, çocuğa doğrudan satış çağrısı sayılabilir.
    func testTheLockedCopyDoesNotSendTheChildToAGrownUp() {
        for capability in Capability.allCases {
            let copy = MPLockedCopy(capability)
            for text in [copy.ragi, copy.title, copy.message] {
                let lower = text.lowercased(with: Locale(identifier: "tr_TR"))
                for word in ["büyük", "göster", "iste", "söyle"] {
                    XCTAssertFalse(lower.contains(word), "\(capability.rawValue): \(word) in \(text)")
                }
            }
        }
    }

    func testLockedInterestKeepsOnlyTheLatestForAWeek() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "LockedInterestTests"))
        defer { defaults.removePersistentDomain(forName: "LockedInterestTests") }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertNil(MPLockedInterest.latest(now: now, defaults: defaults))

        MPLockedInterest.record(.classicLibrary, childName: "İrem", now: now, defaults: defaults)
        MPLockedInterest.record(.seriesStories, childName: "İrem", now: now, defaults: defaults)
        let entry = try XCTUnwrap(MPLockedInterest.latest(now: now, defaults: defaults))
        XCTAssertEqual(entry.capability, .seriesStories)
        XCTAssertEqual(MPLockedInterest.sentence(for: entry), "İrem, masalın devamını açmak istedi.")

        XCTAssertNil(MPLockedInterest.latest(now: now.addingTimeInterval(MPLockedInterest.maxAge + 1), defaults: defaults))
        MPLockedInterest.clear(defaults: defaults)
        XCTAssertNil(MPLockedInterest.latest(now: now, defaults: defaults))
    }

    func testLockedInterestWithoutANameStaysGrammatical() {
        let entry = MPLockedInterest.Entry(capability: .pdfBook, childName: nil, date: Date())
        XCTAssertEqual(MPLockedInterest.sentence(for: entry), "Çocuk, masallarından kitap yapmak istedi.")
    }

    /// Günün masalı yazıldıysa yarına bakılır, saate değil.
    func testTheDailyLimitLooksToTomorrow() {
        XCTAssertTrue(MPLockedCopy(.unlimitedTextStories).message.hasPrefix("Yarın"))
    }
}
