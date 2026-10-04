import XCTest
@testable import StoryEngine

/// Masal ailem (FAZ 11): the child's own recurring character in the story.
///
/// The acceptance criterion is the first test: every relation, in every band
/// the product offers, is carried naturally by the shipped catalog — the name
/// is on the opening page and on the closing page, and nothing is left
/// unfilled. The rest guard the two ways this goes wrong quietly: a relation
/// with no line being swapped for another story instead of reported, and a
/// story without a family character changing because family lines exist.
final class FamilyCastTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private static let childName = "Yeliz"

    /// One example character per relation. The names are chosen to exercise
    /// the grammar: a vowel-final name, a consonant-final one, a rounded one.
    private func cast(_ relation: FamilyRelationKind, in catalog: ContentCatalog) -> FamilyCast {
        switch relation {
        case .sibling: return FamilyCast(name: "Ela", relation: .sibling)
        case .friend: return FamilyCast(name: "Deniz", relation: .friend)
        case .animal:
            return FamilyCast(name: "Pamuk", relation: .animal,
                              animalKind: catalog.familyAnimalKind("family_animal_cat"))
        case .imaginary: return FamilyCast(name: "Bulut", relation: .imaginary)
        }
    }

    /// The band a profile of this band is written for, as the app serves it.
    private func served(_ band: AgeBand, in catalog: ContentCatalog) -> AgeBand? {
        let available = Set(catalog.blueprints.filter(\.isBeatAuthored).map(\.ageRange))
        return AgeBandResolver.servedBand(for: band, available: available)
    }

    // MARK: - Acceptance

    func testEveryRelationIsCarriedInEveryBand() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()

        for band in AgeBandResolver.bands {
            let servedBand = try XCTUnwrap(served(band, in: catalog), "\(band)")
            let modes = BlueprintSelector().availableModes(catalog: catalog, ageBand: servedBand)
            XCTAssertFalse(modes.isEmpty, "\(band)")

            for relation in FamilyRelationKind.allCases {
                let family = cast(relation, in: catalog)
                var built = 0
                for mode in modes {
                    for seed in ["a", "b", "c"] {
                        let intent = OfflineStoryIntent(
                            childName: Self.childName, seed: "family-\(seed)",
                            mode: mode, ageBand: servedBand, family: family)
                        guard let story = try? composer.compose(catalog: catalog, intent: intent) else {
                            continue
                        }
                        built += 1
                        XCTAssertTrue(story.isClean, "\(band) \(relation) \(mode): \(story.pages.map(\.text))")
                        let first = try XCTUnwrap(story.pages.first).text
                        let last = try XCTUnwrap(story.pages.last).text
                        XCTAssertTrue(first.contains(family.name), "\(band) \(relation) \(mode) opening: \(first)")
                        XCTAssertTrue(last.contains(family.name), "\(band) \(relation) \(mode) closing: \(last)")
                        // Only the moments carry the character.
                        for page in story.pages.dropFirst().dropLast() {
                            XCTAssertFalse(page.text.contains("{{"), page.text)
                        }
                    }
                }
                XCTAssertGreaterThan(built, 0, "no \(relation) story in \(band) (served \(servedBand))")
            }
        }
    }

    /// Stronger than the acceptance criterion, and the list FAZ 11 hands to the
    /// content pipeline: every shipped blueprint carries every relation. When a
    /// blueprint gains a family moment nobody wrote lines for, this names it.
    func testEveryShippedBlueprintCarriesEveryRelation() throws {
        let coverage = BlueprintSelector().familyCoverage(catalog: try catalog())
        XCTAssertFalse(coverage.isEmpty)
        let gaps = coverage.filter { !$0.value.isEmpty }
            .map { "\($0.key.rawValue): " + $0.value.map { "\($0.key.rawValue)@\($0.value.rawValue)" }.sorted().joined(separator: ", ") }
            .sorted()
        XCTAssertEqual(gaps, [], gaps.joined(separator: "\n"))
    }

    func testTheAnimalKindIsInflectedAsACommonNoun() throws {
        let catalog = try catalog()
        let dog = try XCTUnwrap(catalog.familyAnimalKind("family_animal_dog"))
        let slots = OfflineStoryComposer.slots(
            childName: Self.childName,
            content: try anyBinding(in: catalog),
            family: FamilyCast(name: "Karabaş", relation: .animal, animalKind: dog))
        let rendered = TurkishTextRenderer.render(
            "{{family.possessive}} {{family.name}}'a, {{family.kind}}'e, {{family.possessive}}'i", slots: slots)
        XCTAssertTrue(rendered.isClean, "\(rendered)")
        XCTAssertEqual(rendered.text, "Köpeği Karabaş'a, köpeğe, köpeğini")
    }

    /// A companion with the family character's name is never bound beside it.
    func testACompanionNeverSharesTheFamilyCharactersName() throws {
        let catalog = try catalog()
        let companionName = try XCTUnwrap(catalog.companions.first { $0.name == "Pamuk" }).name
        let family = FamilyCast(name: "pamuk", relation: .sibling)
        for seed in 0..<12 {
            let intent = OfflineStoryIntent(
                childName: Self.childName, seed: "clash-\(seed)",
                ageBand: AgeBand(lowerBound: 5, upperBound: 6), family: family)
            guard let story = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent) else { continue }
            XCTAssertNotEqual(story.content.companion.name, companionName, "seed \(seed)")
        }
    }

    /// "da/de" written after a slot cannot follow the name: the same line
    /// gives "Ela da" and "Bulut de". Family lines never do it.
    func testNoFamilyLineWritesTheConjunctionAfterASlot() throws {
        let pattern = try NSRegularExpression(pattern: "\\}\\}(?:'[a-zçğıöşü]+)? (?:da|de|ta|te)\\b")
        for variant in try catalog().templates.flatMap(\.variants) where variant.isFamilyLine {
            let range = NSRange(variant.text.startIndex..., in: variant.text)
            XCTAssertNil(pattern.firstMatch(in: variant.text, range: range), "\(variant.id): \(variant.text)")
        }
    }

    /// The child opens the story (karar: 4 Ekim 2026): a family opening names
    /// the child in its first sentence; "Kardeşi Ela uyuyordu." is never the
    /// first sentence of a book.
    func testEveryFamilyOpeningNamesTheChildInItsFirstSentence() throws {
        let catalog = try catalog()
        for template in catalog.templates where template.realizesBeat == .noticeAnomaly {
            for variant in template.variants where variant.isFamilyLine {
                // Sentence ends are punctuation followed by a space; a bare "."
                // would split inside the `{{child.name}}` token itself.
                let end = variant.text.range(of: #"[.!?…]\s"#, options: .regularExpression)
                let first = end.map { String(variant.text[..<$0.lowerBound]) } ?? variant.text
                XCTAssertTrue(first.contains("{{child.name}}"), "\(variant.id): \(variant.text)")
            }
        }
    }

    // MARK: - No silent substitution

    /// A relation with no line is ruled out by name, not swapped for a story
    /// without the character.
    func testARelationWithNoLineIsReportedNotSubstituted() throws {
        let full = try catalog()
        let stripped = ContentCatalog(
            version: full.version,
            settings: full.settings, companions: full.companions, objects: full.objects,
            events: full.events, challenges: full.challenges, endings: full.endings,
            templates: full.templates.map { template in
                CatalogTemplate(
                    id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                    compatibleThemes: template.compatibleThemes,
                    variants: template.variants.filter { !$0.familyRelations.contains(.imaginary) },
                    ageBand: template.ageBand)
            },
            blueprints: full.blueprints, storyIdeas: full.storyIdeas, storyModes: full.storyModes,
            familyMoments: full.familyMoments, familyAnimalKinds: full.familyAnimalKinds)

        let family = FamilyCast(name: "Bulutçuk", relation: .imaginary)
        let intent = OfflineStoryIntent(
            childName: Self.childName, seed: "gap", mode: .bedtime,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6), family: family)

        XCTAssertThrowsError(try OfflineStoryComposer().compose(catalog: stripped, intent: intent)) { error in
            guard case OfflineSelectionError.noBlueprintForChoices(let reasons) = error else {
                return XCTFail("expected noBlueprintForChoices, got \(error)")
            }
            XCTAssertTrue(reasons.contains { $0.contains("no 'imaginary' line for 'notice_anomaly'") }, "\(reasons)")
            // The parent's words stay out of diagnostics.
            XCTAssertFalse((error as? OfflineSelectionError)?.explanation.contains(family.name) ?? true)
            XCTAssertFalse(String(describing: error).contains(family.name))
        }
        XCTAssertFalse(BlueprintSelector().availableFamilyRelations(
            catalog: stripped, mode: .bedtime, ageBand: AgeBand(lowerBound: 5, upperBound: 6)
        ).contains(.imaginary))
    }

    func testAnAnimalWithoutAKindIsRefused() throws {
        let intent = OfflineStoryIntent(
            childName: Self.childName, seed: "kind", mode: .bedtime,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6),
            family: FamilyCast(name: "Pamuk", relation: .animal))
        XCTAssertThrowsError(try OfflineStoryComposer().compose(catalog: try catalog(), intent: intent))
    }

    func testTheFamilyErrorNamesTheRelationNotTheName() {
        let error = OfflineSelectionError.noVariantForFamily(relation: .sibling, beat: .warmClose, page: 8)
        XCTAssertTrue(error.explanation.contains("sibling"))
        XCTAssertEqual(String(describing: FamilyCast(name: "Ela", relation: .sibling)), "FamilyCast(sibling)")
        var dumped = ""
        dump(FamilyCast(name: "Ela", relation: .sibling), to: &dumped)
        XCTAssertFalse(dumped.contains("Ela"), dumped)
    }

    // MARK: - Stories without a family character do not move

    /// The pinned determinism test covers one intent; this covers every band
    /// and mode. With no family character, no family line is ever chosen.
    func testAStoryWithoutAFamilyCharacterNeverUsesAFamilyLine() throws {
        let catalog = try catalog()
        let familyLineIDs = Set(catalog.templates.flatMap(\.variants).filter(\.isFamilyLine).map(\.id))
        XCTAssertEqual(familyLineIDs.count, 36)
        for band in [AgeBand(lowerBound: 3, upperBound: 4), AgeBand(lowerBound: 5, upperBound: 6)] {
            for mode in BlueprintSelector().availableModes(catalog: catalog, ageBand: band) {
                for seed in 0..<6 {
                    let intent = OfflineStoryIntent(
                        childName: Self.childName, seed: "plain-\(seed)", mode: mode, ageBand: band)
                    guard let story = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent) else {
                        continue
                    }
                    let used = Set(story.pages.flatMap(\.variantIDs))
                    XCTAssertTrue(used.isDisjoint(with: familyLineIDs), "\(band) \(mode) \(seed)")
                }
            }
        }
    }

    func testTheFamilyCharacterChangesTheFingerprintOnlyWhenPresent() throws {
        let catalog = try catalog()
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let plain = OfflineStoryIntent(childName: Self.childName, seed: "fp", mode: .bedtime, ageBand: band)
        let a = try OfflineStoryComposer().compose(catalog: catalog, intent: plain)
        let b = try OfflineStoryComposer().compose(catalog: catalog, intent: plain)
        XCTAssertEqual(a.fingerprint, b.fingerprint)
        let withFamily = OfflineStoryIntent(
            childName: Self.childName, seed: "fp", mode: .bedtime, ageBand: band,
            family: FamilyCast(name: "Ela", relation: .sibling))
        let c = try OfflineStoryComposer().compose(catalog: catalog, intent: withFamily)
        XCTAssertNotEqual(a.fingerprint, c.fingerprint)
        let d = try OfflineStoryComposer().compose(catalog: catalog, intent: withFamily)
        XCTAssertEqual(c.pages.map(\.text), d.pages.map(\.text), "same inputs, same book")
    }

    // MARK: - Integrity

    func testTheShippedCatalogHasNoFamilyErrors() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        for code in ["family_slot_without_relation", "family_relation_without_slot",
                     "family_kind_outside_animal", "family_line_outside_moment"] {
            XCTAssertEqual(report.issues(withCode: code).map(\.message), [], code)
        }
        // 7-8 and 9-10 have no content of their own; they are not reported here.
        XCTAssertEqual(report.issues(withCode: "family_relation_unavailable_in_band").map(\.message), [])
    }

    func testNoFamilyLineSaysHayaliVarlik() throws {
        for variant in try catalog().templates.flatMap(\.variants) where variant.isFamilyLine {
            XCTAssertFalse(variant.text.lowercased(with: Locale(identifier: "tr_TR")).contains("hayali varlı"),
                           variant.id.rawValue)
        }
    }

    // MARK: - Helpers

    private func anyBinding(in catalog: ContentCatalog) throws -> BoundContent {
        let intent = OfflineStoryIntent(childName: Self.childName, seed: "bind",
                                        ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        return try OfflineStoryComposer().compose(catalog: catalog, intent: intent).content
    }
}
