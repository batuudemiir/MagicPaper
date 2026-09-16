import XCTest
@testable import StoryEngine

/// D1 — disjunction in content requirements.
///
/// A flat `Set` says only "all of these". Thirteen of the fourteen blueprints
/// in `BLUEPRINT_CATALOG_V2.md` need "all of these **and** one of those"
/// (`isUnexplained ∧ (emitsSignal ∨ isFragmentary)`), so without this they
/// cannot be written down at all.
final class TraitRequirementTests: XCTestCase {

    // MARK: - Semantics

    func testConjunctionAloneBehavesAsBefore() {
        let requirement: TraitRequirement<SettingTrait> = [.hasThreshold, .canConceal]
        XCTAssertTrue(requirement.isSatisfied(by: [.hasThreshold, .canConceal, .isOpen]))
        XCTAssertFalse(requirement.isSatisfied(by: [.hasThreshold]))
    }

    func testAChoiceIsMetByAnyOneMember() {
        let requirement = TraitRequirement<SettingTrait>(anyOf: [[.canConceal, .showsTraces]])
        XCTAssertTrue(requirement.isSatisfied(by: [.canConceal]))
        XCTAssertTrue(requirement.isSatisfied(by: [.showsTraces]))
        XCTAssertTrue(requirement.isSatisfied(by: [.canConceal, .showsTraces]))
        XCTAssertFalse(requirement.isSatisfied(by: [.isOpen, .hasWater]))
    }

    /// The shape the catalog actually asks for.
    func testHardRequirementAndChoiceTogether() {
        let requirement = TraitRequirement<DiscoveryTrait>(
            allOf: [.isUnexplained], anyOf: [[.emitsSignal, .isFragmentary]])
        XCTAssertTrue(requirement.isSatisfied(by: [.isUnexplained, .emitsSignal]))
        XCTAssertTrue(requirement.isSatisfied(by: [.isUnexplained, .isFragmentary]))
        XCTAssertFalse(requirement.isSatisfied(by: [.emitsSignal, .isFragmentary]),
                       "The hard requirement is not optional.")
        XCTAssertFalse(requirement.isSatisfied(by: [.isUnexplained, .isBeautiful]),
                       "The choice is not optional either.")
    }

    /// Two groups are two independent choices, not one pooled alternative.
    func testTwoGroupsMustEachBeMet() {
        let requirement = TraitRequirement<CompanionTrait>(
            anyOf: [[.canFly, .canSwim], [.isPatient, .isPlayful]])
        XCTAssertTrue(requirement.isSatisfied(by: [.canFly, .isPatient]))
        XCTAssertFalse(requirement.isSatisfied(by: [.canFly, .canSwim]),
                       "Both members of one group does not satisfy the other group.")
    }

    /// An empty group can never be satisfied, and an author who wrote one meant
    /// to write nothing — silently making a blueprint unselectable is the worse
    /// reading.
    func testAnEmptyChoiceGroupIsDropped() {
        let requirement = TraitRequirement<SettingTrait>(allOf: [.isOpen], anyOf: [Set<SettingTrait>()])
        XCTAssertTrue(requirement.anyOf.isEmpty)
        XCTAssertTrue(requirement.isSatisfied(by: [.isOpen]))
    }

    func testEmptyRequirementAdmitsAnything() {
        let requirement: TraitRequirement<SettingTrait> = []
        XCTAssertTrue(requirement.isEmpty)
        XCTAssertTrue(requirement.isSatisfied(by: []))
    }

    // MARK: - Diagnostics

    func testAnUnmetChoiceIsReportedAsAChoice() {
        let requirement = TraitRequirement<DiscoveryTrait>(
            allOf: [.isUnexplained], anyOf: [[.emitsSignal, .isFragmentary]])
        let reasons = requirement.unmet(in: [.isBeautiful])
        XCTAssertEqual(reasons.count, 2)
        XCTAssertTrue(reasons.contains("isUnexplained"))
        XCTAssertTrue(reasons.contains { $0.hasPrefix("one of ") && $0.contains("emitsSignal") },
                      "A choice must not be reported as a list of missing traits: \(reasons)")
    }

    func testRejectionNamesBothWhatIsMissingAndWhatIsForbidden() {
        let reason = TraitMatch.rejection(
            offered: [.canFly, .isPatient],
            required: TraitRequirement<CompanionTrait>(allOf: [.hasLocalKnowledge]),
            forbidden: [.canFly])
        XCTAssertEqual(reason, "lacks hasLocalKnowledge; offers forbidden canFly")
    }

    // MARK: - Decoding

    /// The corpus is authored as bare arrays. Adopting disjunction must not
    /// require rewriting content that never needed it.
    func testABareArrayStillDecodesAsConjunction() throws {
        let requirement = try JSONDecoder().decode(
            TraitRequirement<SettingTrait>.self, from: Data("[\"hasThreshold\"]".utf8))
        XCTAssertEqual(requirement.allOf, [.hasThreshold])
        XCTAssertTrue(requirement.anyOf.isEmpty)
    }

    func testTheObjectFormDecodesChoices() throws {
        let json = #"{"allOf":["isUnexplained"],"anyOf":[["emitsSignal","isFragmentary"]]}"#
        let requirement = try JSONDecoder().decode(
            TraitRequirement<DiscoveryTrait>.self, from: Data(json.utf8))
        XCTAssertEqual(requirement.allOf, [.isUnexplained])
        XCTAssertEqual(requirement.anyOf, [[.emitsSignal, .isFragmentary]])
    }

    func testBothFormsRoundTrip() throws {
        for requirement: TraitRequirement<SettingTrait> in [
            [.hasThreshold],
            TraitRequirement(allOf: [.isOpen], anyOf: [[.canConceal, .showsTraces]]),
            TraitRequirement(allOf: [], anyOf: [])
        ] {
            let data = try JSONEncoder().encode(requirement)
            XCTAssertEqual(try JSONDecoder().decode(TraitRequirement<SettingTrait>.self, from: data),
                           requirement)
        }
    }

    /// Requirements and exclusions are different shapes on purpose: forbidding
    /// "a or b" either forbids both or forbids nothing in particular.
    func testExclusionsAreFlatSets() throws {
        let json = #"{"companion":["canFly","canCarry"]}"#
        let exclusions = try JSONDecoder().decode(ContentExclusions.self, from: Data(json.utf8))
        XCTAssertEqual(exclusions.companion, [.canFly, .canCarry])
    }

    // MARK: - In the shipped library

    func testTheLibraryUsesAChoiceAndItSelects() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "pilot_library_v1", withExtension: "json"))
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
        let unexplained = try XCTUnwrap(catalog.blueprints.first { $0.family == .unexplained })

        XCTAssertFalse(unexplained.requires.setting.anyOf.isEmpty,
                       "The library should exercise disjunction, not just support it.")

        // canConceal ∨ showsTraces — a place that can hold a thing back, or show
        // that it passed. The sea offers neither.
        let admitted = catalog.settings.filter {
            TraitMatch.admits(offered: $0.traits,
                              required: unexplained.requires.setting,
                              forbidden: unexplained.forbids.setting)
        }.map(\.id.rawValue).sorted()
        XCTAssertTrue(admitted.contains("setting_whispering_forest_001"), "\(admitted)")
        XCTAssertTrue(admitted.contains("setting_cloud_mountain_001"), "showsTraces arm: \(admitted)")
        XCTAssertFalse(admitted.contains("setting_coral_sea_001"), "\(admitted)")
    }
}
