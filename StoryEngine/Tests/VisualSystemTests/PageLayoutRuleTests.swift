import XCTest
import EngineFoundation
@testable import VisualSystem

final class PageLayoutRuleTests: XCTestCase {

    // MARK: - Predicates

    func testAlwaysPredicateMatchesEverything() {
        XCTAssertTrue(LayoutPredicate.always.matches(LayoutContext(pageIndex: 3, pageCount: 8, beatRole: "middle")))
    }

    func testPositionPredicates() {
        let first = LayoutPredicate(positions: [.first])
        XCTAssertTrue(first.matches(LayoutContext(pageIndex: 0, pageCount: 5, beatRole: "opening")))
        XCTAssertFalse(first.matches(LayoutContext(pageIndex: 1, pageCount: 5, beatRole: "opening")))

        let last = LayoutPredicate(positions: [.last])
        XCTAssertTrue(last.matches(LayoutContext(pageIndex: 4, pageCount: 5, beatRole: "closing")))

        let interior = LayoutPredicate(positions: [.interior])
        XCTAssertFalse(interior.matches(LayoutContext(pageIndex: 0, pageCount: 5, beatRole: "x")))
        XCTAssertTrue(interior.matches(LayoutContext(pageIndex: 2, pageCount: 5, beatRole: "x")))
        XCTAssertFalse(interior.matches(LayoutContext(pageIndex: 4, pageCount: 5, beatRole: "x")))
    }

    func testMultiplePositionsAreOred() {
        let predicate = LayoutPredicate(positions: [.odd, .interior])
        // Page 3 of 8 is odd and interior.
        XCTAssertTrue(predicate.matches(LayoutContext(pageIndex: 3, pageCount: 8, beatRole: "x")))
        // Page 2 is even but still interior, so the OR still matches.
        XCTAssertTrue(predicate.matches(LayoutContext(pageIndex: 2, pageCount: 8, beatRole: "x")))
        // Page 0 is even and not interior.
        XCTAssertFalse(predicate.matches(LayoutContext(pageIndex: 0, pageCount: 8, beatRole: "x")))
    }

    func testBeatRoleAndPositionAreAnded() {
        let predicate = LayoutPredicate(beatRoles: ["closing"], positions: [.last])
        XCTAssertTrue(predicate.matches(LayoutContext(pageIndex: 6, pageCount: 7, beatRole: "closing")))
        XCTAssertFalse(predicate.matches(LayoutContext(pageIndex: 6, pageCount: 7, beatRole: "middle")))
        XCTAssertFalse(predicate.matches(LayoutContext(pageIndex: 5, pageCount: 7, beatRole: "closing")))
    }

    func testExplicitIndexPredicate() {
        let predicate = LayoutPredicate(pageIndices: [2, 4])
        XCTAssertTrue(predicate.matches(LayoutContext(pageIndex: 4, pageCount: 9, beatRole: "x")))
        XCTAssertFalse(predicate.matches(LayoutContext(pageIndex: 3, pageCount: 9, beatRole: "x")))
    }

    func testSpecificityRanking() {
        XCTAssertLessThan(LayoutPredicate.always.specificity, LayoutPredicate(positions: [.first]).specificity)
        XCTAssertLessThan(
            LayoutPredicate(positions: [.first]).specificity,
            LayoutPredicate(beatRoles: ["opening"], positions: [.first]).specificity
        )
        XCTAssertLessThan(
            LayoutPredicate(beatRoles: ["opening"], positions: [.first]).specificity,
            LayoutPredicate(beatRoles: ["opening"], positions: [.first], pageIndices: [0]).specificity
        )
    }

    // MARK: - Selection against the shipped catalog

    func testFirstPageGetsTheOpeningSpread() throws {
        let style = try VisualFixtures.resolvedStyle()
        let rule = try XCTUnwrap(style.layoutRule(for: LayoutContext(pageIndex: 0, pageCount: 7, beatRole: "opening")))

        XCTAssertEqual(rule.id, "layout_opening_spread")
        XCTAssertEqual(rule.layout, .spread)
        XCTAssertEqual(rule.compositionRuleID, "full_bleed_establishing")
    }

    func testLastPageGetsTheQuietClosing() throws {
        let style = try VisualFixtures.resolvedStyle()
        let rule = try XCTUnwrap(style.layoutRule(for: LayoutContext(pageIndex: 6, pageCount: 7, beatRole: "closing")))
        XCTAssertEqual(rule.id, "layout_closing_quiet")
    }

    func testInteriorPagesAlternateComposition() throws {
        let style = try VisualFixtures.resolvedStyle()
        let odd = try XCTUnwrap(style.layoutRule(for: LayoutContext(pageIndex: 3, pageCount: 7, beatRole: "middle")))
        let even = try XCTUnwrap(style.layoutRule(for: LayoutContext(pageIndex: 2, pageCount: 7, beatRole: "middle")))

        XCTAssertEqual(odd.compositionRuleID, "character_left_text_right")
        XCTAssertEqual(even.compositionRuleID, "character_left_text_right",
                       "The shipped mirror rule matches odd OR interior, so both interior pages take it")
        XCTAssertNotEqual(odd.id, "layout_default_interior")
    }

    func testEveryPageOfEveryReasonableLengthResolvesARule() throws {
        let style = try VisualFixtures.resolvedStyle()
        for pageCount in 3...16 {
            for index in 0..<pageCount {
                let context = LayoutContext(pageIndex: index, pageCount: pageCount, beatRole: "middle")
                XCTAssertNotNil(style.layoutRule(for: context),
                                "No layout rule for page \(index) of \(pageCount)")
            }
        }
    }

    func testSelectionIsDeterministic() throws {
        let style = try VisualFixtures.resolvedStyle()
        let context = LayoutContext(pageIndex: 3, pageCount: 7, beatRole: "middle")
        let ids = (0..<20).map { _ in style.layoutRule(for: context)?.id }
        XCTAssertEqual(Set(ids).count, 1)
    }

    func testTieBreaksOnCatalogOrder() {
        let a = rule(id: "a", predicate: LayoutPredicate(positions: [.first]))
        let b = rule(id: "b", predicate: LayoutPredicate(positions: [.first]))
        let style = ResolvedVisualStyle(
            preset: VisualStylePreset(
                id: "p", version: SemanticVersion(1), displayName: "p",
                illustrationStyleID: "i", palettePresetID: "pal", typographyPresetID: "t",
                defaultCompositionRuleID: "c", compositionRuleIDs: ["c"], layoutRuleIDs: ["a", "b"]
            ),
            illustrationStyle: IllustrationStyle(id: "i", version: SemanticVersion(1), displayName: "i", mediumClauses: [], lightingClauses: []),
            palette: PalettePreset(id: "pal", version: SemanticVersion(1), displayName: "p", paletteClauses: []),
            typography: TypographyPreset(id: "t", version: SemanticVersion(1), fontRole: "body", pointSize: 18, lineHeightMultiple: 1.4),
            compositionRules: [],
            layoutRules: [a, b]
        )
        XCTAssertEqual(style.layoutRule(for: LayoutContext(pageIndex: 0, pageCount: 4, beatRole: "x"))?.id, "a",
                       "Earlier in the preset's list wins a tie")
    }

    // MARK: - Layout facts

    func testTextOnlyLayoutNeedsNoImage() {
        XCTAssertFalse(PageLayout.textOnly.requiresImage)
        for layout in PageLayout.allCases where layout != .textOnly {
            XCTAssertTrue(layout.requiresImage, "\(layout) should need an illustration")
        }
    }

    func testTypographyLineCeilingsCoverEveryLayout() throws {
        let style = try VisualFixtures.resolvedStyle()
        for layout in PageLayout.allCases {
            XCTAssertNotNil(style.typography.maximumLines(for: layout), "No line ceiling for \(layout)")
        }
    }

    private func rule(id: String, predicate: LayoutPredicate) -> PageLayoutRule {
        PageLayoutRule(
            id: id, version: SemanticVersion(1), layout: .imageTopTextBottom,
            appliesTo: predicate, compositionRuleID: "c", typographyPresetID: "t", textWordBudget: 10...20
        )
    }
}
