import XCTest
@testable import CharacterEngine

final class DescriptorLexiconTests: XCTestCase {
    private let english = DescriptorLexicon.builtIn(languageCode: "en")
    private let turkish = DescriptorLexicon.builtIn(languageCode: "tr")

    func testBuiltInLexiconsLoadFromResources() {
        XCTAssertFalse(english.phrases.isEmpty, "English lexicon should ship with the package")
        XCTAssertFalse(turkish.phrases.isEmpty, "Turkish lexicon should ship with the package")
        XCTAssertEqual(english.languageCode, "en")
    }

    func testUnknownLanguageFallsBackToEnglish() {
        XCTAssertEqual(DescriptorLexicon.builtIn(languageCode: "ja").languageCode, "en")
        XCTAssertEqual(DescriptorLexicon.builtIn(languageCode: "en-GB").languageCode, "en")
    }

    func testAuthorizedPhraseIsNotFlagged() {
        let identity = CharacterFixtures.identity()
        let violations = english.violations(in: "Deniz shook their curly black hair.", authorizedBy: identity)
        XCTAssertTrue(violations.isEmpty, "The identity authorizes exactly this phrase")
    }

    func testNarrowerPhraseInsideAnAuthorizedOneIsAllowed() {
        let identity = CharacterFixtures.identity()
        let violations = english.violations(in: "Her black hair caught the light.", authorizedBy: identity)
        XCTAssertTrue(violations.isEmpty, "'black hair' is contained by the authorized 'curly black hair'")
    }

    func testInventedAttributeIsFlagged() {
        let identity = CharacterFixtures.identity()
        let violations = english.violations(in: "Deniz pushed back their blonde hair and blinked blue eyes.", authorizedBy: identity)

        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(Set(violations.map(\.phrase)), ["blonde hair", "blue eyes"])
        XCTAssertEqual(violations.first(where: { $0.phrase == "blue eyes" })?.category, .eyes)
        XCTAssertEqual(violations.first(where: { $0.phrase == "blue eyes" })?.authorized, ["brown eyes"])
    }

    func testWiderPhraseThanAuthorizedIsFlagged() {
        let identity = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "black hair")
        ])
        let violations = english.violations(in: "Deniz had curly black hair.", authorizedBy: identity)

        XCTAssertEqual(violations.map(\.phrase), ["curly black hair"], "'curly' was invented")
    }

    func testUnconstrainedCategoryIsStillFlagged() {
        // The identity says nothing about clothing, so the model may not either.
        let identity = CharacterFixtures.identity()
        let violations = english.violations(in: "She wore a yellow raincoat.", authorizedBy: identity)

        XCTAssertEqual(violations.map(\.category), [.clothingDefault])
        XCTAssertEqual(violations.first?.authorized, [])
    }

    func testWordBoundariesPreventSubstringFalsePositives() {
        let identity = CharacterFixtures.identity(descriptors: [])
        XCTAssertTrue(
            english.violations(in: "The chair was brown.", authorizedBy: identity).isEmpty,
            "'hair' must not match inside 'chair'"
        )
        XCTAssertTrue(
            english.violations(in: "A brown bear waved.", authorizedBy: identity).isEmpty,
            "A bare colour word is not an appearance claim"
        )
    }

    func testTurkishDiacriticsAreMatched() {
        let identity = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "siyah saç")
        ])

        XCTAssertTrue(turkish.violations(in: "Deniz'in siyah saçı vardı.", authorizedBy: identity).isEmpty)

        let violations = turkish.violations(in: "Deniz'in sarı saçı rüzgarda uçuştu.", authorizedBy: identity)
        XCTAssertEqual(violations.map(\.phrase), ["sari sac"], "Comparison folds Turkish diacritics")
    }

    func testCaseIsIgnored() {
        let identity = CharacterFixtures.identity()
        let violations = english.violations(in: "BLUE EYES stared back.", authorizedBy: identity)
        XCTAssertEqual(violations.map(\.phrase), ["blue eyes"])
    }

    func testViolationsAreDeduplicatedAndOrdered() {
        let identity = CharacterFixtures.identity(descriptors: [])
        let text = "blue eyes, blue eyes again, and blonde hair"
        let violations = english.violations(in: text, authorizedBy: identity)

        XCTAssertEqual(violations.map(\.phrase), ["blue eyes", "blonde hair"].sorted { lhs, rhs in
            // eyes sorts before hair by category
            lhs == "blue eyes"
        })
        XCTAssertEqual(violations.count, 2, "Repeated claims collapse to one violation")
    }

    func testTurkishSuffixedAuthorizedPhraseStaysAuthorized() {
        let identity = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "kıvırcık siyah saç"),
            CharacterDescriptor(category: .eyes, value: "kahverengi gözler")
        ])
        let text = "Deniz'in kıvırcık siyah saçları ve kahverengi gözleriyle güldü."
        XCTAssertTrue(
            turkish.violations(in: text, authorizedBy: identity).isEmpty,
            "Inflected forms of an authorized phrase must not be flagged"
        )
    }

    func testTurkishDottedAndDotlessIAreComparable() {
        // "SARI" case-folds to "sari" while "sarı" keeps its dotless i; without
        // explicit mapping these two spellings of one word would never match.
        XCTAssertEqual(DescriptorNormalization.normalize("SARI SAÇ"), DescriptorNormalization.normalize("sarı saç"))
        XCTAssertEqual(DescriptorNormalization.normalize("İnce"), "ince")
    }

    func testUppercaseTurkishClaimIsStillFlagged() {
        let identity = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "siyah saç")
        ])
        XCTAssertEqual(
            turkish.violations(in: "SARI SAÇ rüzgarda uçuştu.", authorizedBy: identity).map(\.phrase),
            ["sari sac"]
        )
    }

    func testEnglishDoesNotAllowSuffixAttachment() {
        XCTAssertFalse(english.allowsSuffixAttachment)
        XCTAssertTrue(turkish.allowsSuffixAttachment)
    }

    func testEmptyTextProducesNoViolations() {
        XCTAssertTrue(english.violations(in: "   ", authorizedBy: CharacterFixtures.identity()).isEmpty)
    }
}
