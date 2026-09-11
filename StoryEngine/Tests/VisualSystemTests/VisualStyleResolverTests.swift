import XCTest
import EngineFoundation
@testable import VisualSystem

final class VisualStyleResolverTests: XCTestCase {
    private let resolver = VisualStyleResolver()

    func testBuiltInCatalogLoads() {
        XCTAssertFalse(VisualCatalog.builtIn.stylePresets.isEmpty, "Catalog resource should ship with the package")
    }

    func testResolvesTheWholeChain() throws {
        let style = try resolver.resolve(styleID: "magic_paper_v1")

        XCTAssertEqual(style.preset.id, "magic_paper_v1")
        XCTAssertEqual(style.illustrationStyle.id, "storybook_painted_v1")
        XCTAssertEqual(style.palette.id, "paper_warm")
        XCTAssertEqual(style.typography.id, "mp_body_v1")
        XCTAssertEqual(style.compositionRules.count, 5)
        XCTAssertEqual(style.layoutRules.count, 4)
        XCTAssertNotNil(style.defaultCompositionRule)
    }

    func testUnknownStyleThrowsNamingTheID() {
        XCTAssertThrowsError(try resolver.resolve(styleID: "nope_v9")) { error in
            XCTAssertEqual(error as? VisualSystemError, .stylePresetNotFound("nope_v9"))
        }
    }

    func testDanglingIllustrationReferenceThrows() {
        let catalog = VisualCatalog(
            stylePresets: [preset(illustrationStyleID: "missing_style")],
            illustrationStyles: [],
            palettes: [palette()],
            typographyPresets: [typography()],
            compositionRules: [composition()],
            layoutRules: []
        )
        XCTAssertThrowsError(try VisualStyleResolver(catalog: catalog).resolve(styleID: "test_preset")) { error in
            XCTAssertEqual(error as? VisualSystemError, .illustrationStyleNotFound("missing_style"))
        }
    }

    func testDefaultCompositionMustBeListed() {
        let catalog = VisualCatalog(
            stylePresets: [preset(defaultCompositionRuleID: "not_listed", compositionRuleIDs: ["comp_a"])],
            illustrationStyles: [illustration()],
            palettes: [palette()],
            typographyPresets: [typography()],
            compositionRules: [composition()],
            layoutRules: []
        )
        XCTAssertThrowsError(try VisualStyleResolver(catalog: catalog).resolve(styleID: "test_preset")) { error in
            XCTAssertEqual(error as? VisualSystemError, .compositionRuleNotFound("not_listed"))
        }
    }

    func testNewestVersionWinsWhenUnpinned() throws {
        let catalog = VisualCatalog(
            stylePresets: [preset(version: SemanticVersion(1, 0, 0)), preset(version: SemanticVersion(1, 4, 0))],
            illustrationStyles: [illustration()],
            palettes: [palette()],
            typographyPresets: [typography()],
            compositionRules: [composition()],
            layoutRules: []
        )
        let resolved = try VisualStyleResolver(catalog: catalog).resolve(styleID: "test_preset")
        XCTAssertEqual(resolved.preset.version, SemanticVersion(1, 4, 0))
    }

    func testExactPinSelectsOlderVersion() throws {
        let catalog = VisualCatalog(
            stylePresets: [preset(version: SemanticVersion(1, 0, 0)), preset(version: SemanticVersion(2, 0, 0))],
            illustrationStyles: [illustration()],
            palettes: [palette()],
            typographyPresets: [typography()],
            compositionRules: [composition()],
            layoutRules: []
        )
        let resolved = try VisualStyleResolver(catalog: catalog)
            .resolve(styleID: "test_preset", requirement: .exact(SemanticVersion(1, 0, 0)))
        XCTAssertEqual(resolved.preset.version, SemanticVersion(1, 0, 0))
    }

    func testCompatibleRequirementStaysInsideMajor() {
        let catalog = VisualCatalog(
            stylePresets: [preset(version: SemanticVersion(2, 0, 0))],
            illustrationStyles: [illustration()],
            palettes: [palette()],
            typographyPresets: [typography()],
            compositionRules: [composition()],
            layoutRules: []
        )
        XCTAssertThrowsError(
            try VisualStyleResolver(catalog: catalog)
                .resolve(styleID: "test_preset", requirement: .compatible(SemanticVersion(1, 0, 0)))
        )
    }

    func testVersionPinsDescribeTheWholeChain() throws {
        let pins = try VisualFixtures.resolvedStyle().versionPins
        XCTAssertEqual(pins, [
            "preset:magic_paper_v1@1.0.0",
            "illustration:storybook_painted_v1@1.0.0",
            "palette:paper_warm@1.0.0",
            "typography:mp_body_v1@1.0.0"
        ])
    }

    // MARK: - Builders

    private func preset(
        version: SemanticVersion = SemanticVersion(1, 0, 0),
        illustrationStyleID: String = "illu_a",
        defaultCompositionRuleID: String = "comp_a",
        compositionRuleIDs: [String] = ["comp_a"]
    ) -> VisualStylePreset {
        VisualStylePreset(
            id: "test_preset",
            version: version,
            displayName: "Test",
            illustrationStyleID: illustrationStyleID,
            palettePresetID: "pal_a",
            typographyPresetID: "type_a",
            defaultCompositionRuleID: defaultCompositionRuleID,
            compositionRuleIDs: compositionRuleIDs,
            layoutRuleIDs: []
        )
    }

    private func illustration() -> IllustrationStyle {
        IllustrationStyle(id: "illu_a", version: SemanticVersion(1, 0, 0), displayName: "A", mediumClauses: ["m"], lightingClauses: ["l"])
    }
    private func palette() -> PalettePreset {
        PalettePreset(id: "pal_a", version: SemanticVersion(1, 0, 0), displayName: "P", paletteClauses: ["p"])
    }
    private func typography() -> TypographyPreset {
        TypographyPreset(id: "type_a", version: SemanticVersion(1, 0, 0), fontRole: "body", pointSize: 18, lineHeightMultiple: 1.4)
    }
    private func composition() -> ImageCompositionRule {
        ImageCompositionRule(
            id: "comp_a", version: SemanticVersion(1, 0, 0), displayName: "C",
            subjectAnchor: .center, textSafeArea: .none, cameraDistance: .medium, aspectRatio: .landscape
        )
    }
}
