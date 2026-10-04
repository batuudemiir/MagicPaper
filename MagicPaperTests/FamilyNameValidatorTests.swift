import XCTest
@testable import MagicPaper

/// Masal ailem adının kuralları (FAZ 11). Adı masalda ek alır ("Ela'ya"),
/// bu yüzden çekilemeyen her şey reddedilir ve geri kalan Türkçe kurala göre
/// büyük harfle yazılır.
final class FamilyNameValidatorTests: XCTestCase {

    private func check(_ raw: String, child: String = "Yeliz", existing: [String] = [])
        -> Result<String, FamilyNameValidator.Rejection> {
        FamilyNameValidator.validate(raw, childName: child, existing: existing)
    }

    func testNormalisation() {
        XCTAssertEqual(try check("irem").get(), "İrem")
        XCTAssertEqual(try check("ELA").get(), "Ela")
        XCTAssertEqual(try check("ılgaz").get(), "Ilgaz")
        XCTAssertEqual(try check("  ali   can ").get(), "Ali Can")
        XCTAssertEqual(try check("ayşe-nur").get(), "Ayşe-Nur")
        XCTAssertEqual(try check("Kemâl").get(), "Kemâl")
    }

    func testRejections() {
        XCTAssertEqual(check("   "), .failure(.empty))
        XCTAssertEqual(check("A"), .failure(.tooShort))
        XCTAssertEqual(check("Abcdefghijklmnopqrstu"), .failure(.tooLong))
        XCTAssertEqual(check("Ali Can Ela Su"), .failure(.tooManyWords))
        XCTAssertEqual(check("Ela2"), .failure(.invalidCharacters))
        XCTAssertEqual(check("Ela 🙂"), .failure(.invalidCharacters))
        XCTAssertEqual(check("🐶"), .failure(.invalidCharacters))
        XCTAssertEqual(check("O'Neil"), .failure(.invalidCharacters))
        XCTAssertEqual(check("O’Neil"), .failure(.invalidCharacters))
        XCTAssertEqual(check("-Ela"), .failure(.invalidCharacters))
        XCTAssertEqual(check("Ela!"), .failure(.invalidCharacters))
        XCTAssertEqual(check("Mrv"), .failure(.noVowel))
    }

    func testTheChildsOwnNameIsRefused() {
        XCTAssertEqual(check("yeliz", child: "Yeliz"), .failure(.sameAsChild))
        XCTAssertEqual(check("İpek", child: "ipek"), .failure(.sameAsChild))
    }

    func testADuplicateIsRefusedWithTurkishCaseFolding() {
        XCTAssertEqual(check("ela", existing: ["Ela"]), .failure(.duplicate))
        XCTAssertEqual(check("IŞIK", existing: ["Işık"]), .failure(.duplicate))
        // "Işık" and "İşık" are different names in Turkish.
        XCTAssertEqual(try check("İşık", existing: ["Işık"]).get(), "İşık")
    }
}
