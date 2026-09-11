import XCTest
import EngineFoundation
@testable import StoryEngine

final class TemplateResolutionTests: XCTestCase {
    private let clock = FixedClock()

    private func resolver(_ templates: [StoryTemplate]) -> TemplateResolver {
        TemplateResolver(repository: StaticTemplateRepository(templates), clock: clock)
    }

    func testBuiltInTemplatesLoadFromResources() {
        XCTAssertFalse(BuiltInTemplates.all.isEmpty, "Templates should ship as package resources")
        XCTAssertNotNil(BuiltInTemplates.template(id: "adventure_01"))
    }

    func testResolvesShippedTemplateAndPinsEveryVersion() async throws {
        let resolved = try await resolver(BuiltInTemplates.all).resolve(for: StoryFixtures.request())

        XCTAssertEqual(resolved.template.id, "adventure_01")
        XCTAssertEqual(resolved.ref.templateVersion, resolved.template.version)
        XCTAssertEqual(resolved.ref.narrativeVersion, resolved.template.narrative.version)
        XCTAssertEqual(resolved.ref.visualStyleID, "magic_paper_v1")
        XCTAssertTrue(resolved.ref.visualStylePins.contains("illustration:storybook_painted_v1@1.0.0"))
        XCTAssertEqual(resolved.ref.resolvedAt, clock.now())
    }

    func testUnknownTemplateThrowsNamingTheID() async {
        do {
            _ = try await resolver([]).resolve(for: StoryFixtures.request(templateID: "ghost"))
            XCTFail("Expected templateNotFound")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .templateNotFound("ghost"))
        }
    }

    func testNewestVersionWinsWhenUnpinned() async throws {
        let old = StoryFixtures.template(version: SemanticVersion(1, 0, 0))
        let new = StoryFixtures.template(version: SemanticVersion(1, 4, 2))
        let resolved = try await resolver([old, new]).resolve(for: StoryFixtures.request(templateID: "test_template"))

        XCTAssertEqual(resolved.template.version, SemanticVersion(1, 4, 2))
    }

    func testExactPinSelectsThatVersion() async throws {
        let old = StoryFixtures.template(version: SemanticVersion(1, 0, 0))
        let new = StoryFixtures.template(version: SemanticVersion(2, 0, 0))
        let request = StoryFixtures.request(templateID: "test_template", requirement: .exact(SemanticVersion(1, 0, 0)))

        let version = try await resolver([old, new]).resolve(for: request).template.version
        XCTAssertEqual(version, SemanticVersion(1, 0, 0))
    }

    func testExactPinOnAMissingVersionThrows() async {
        let templates = [StoryFixtures.template(version: SemanticVersion(1, 0, 0))]
        let requirement = VersionRequirement.exact(SemanticVersion(9, 9, 9))
        let request = StoryFixtures.request(templateID: "test_template", requirement: requirement)

        do {
            _ = try await resolver(templates).resolve(for: request)
            XCTFail("Expected noCompatibleTemplate")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .noCompatibleTemplate(id: "test_template", requirement: requirement))
        }
    }

    func testCompatibleRequirementStaysWithinMajor() async throws {
        let v1 = StoryFixtures.template(version: SemanticVersion(1, 5, 0))
        let v2 = StoryFixtures.template(version: SemanticVersion(2, 0, 0))
        let request = StoryFixtures.request(templateID: "test_template", requirement: .compatible(SemanticVersion(1, 0, 0)))

        let version = try await resolver([v1, v2]).resolve(for: request).template.version
        XCTAssertEqual(version, SemanticVersion(1, 5, 0))
    }

    func testCompatibleRequirementRejectsOlderThanFloor() async {
        let templates = [StoryFixtures.template(version: SemanticVersion(1, 1, 0))]
        let request = StoryFixtures.request(templateID: "test_template", requirement: .compatible(SemanticVersion(1, 4, 0)))

        do {
            _ = try await resolver(templates).resolve(for: request)
            XCTFail("Expected noCompatibleTemplate")
        } catch {
            guard case .noCompatibleTemplate = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testUnsupportedLanguageIsReportedAsSuch() async {
        let templates = [StoryFixtures.template(languages: ["en"])]
        do {
            _ = try await resolver(templates).resolve(for: StoryFixtures.request(templateID: "test_template", languageCode: "tr"))
            XCTFail("Expected unsupportedLanguage")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .unsupportedLanguage("tr"))
        }
    }

    func testUnsupportedAgeIsReportedAsSuch() async {
        let templates = [StoryFixtures.template(ageRange: 8...12)]
        do {
            _ = try await resolver(templates).resolve(for: StoryFixtures.request(templateID: "test_template", ageYears: 4))
            XCTFail("Expected unsupportedAgeBand")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .unsupportedAgeBand(age: 4))
        }
    }

    func testThemeKeysFilterCandidates() async throws {
        let spaceOnly = StoryFixtures.template(id: "themed", themeKeys: ["space"])
        let resolverUnderTest = resolver([spaceOnly])

        let matched = try await resolverUnderTest.resolve(for: StoryFixtures.request(templateID: "themed", themeKey: "space"))
        XCTAssertEqual(matched.template.id, "themed")

        do {
            _ = try await resolverUnderTest.resolve(for: StoryFixtures.request(templateID: "themed", themeKey: "jungle"))
            XCTFail("Expected a theme rejection")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .templateNotFound("themed#jungle"))
        }
    }

    func testEmptyThemeKeysMeanAnyTheme() async throws {
        // The engine must not own a theme vocabulary; a template with no keys
        // accepts whatever the caller invented.
        let anyTheme = StoryFixtures.template(themeKeys: [])
        let resolved = try await resolver([anyTheme])
            .resolve(for: StoryFixtures.request(templateID: "test_template", themeKey: "dinosaurs-in-space"))
        XCTAssertEqual(resolved.template.id, "test_template")
    }

    func testTemplateWithNoBeatsIsRejected() async {
        let empty = StoryFixtures.template(beats: [])
        do {
            _ = try await resolver([empty]).resolve(for: StoryFixtures.request(templateID: "test_template"))
            XCTFail("Expected templateHasNoBeats")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .templateHasNoBeats("test_template"))
        }
    }

    func testMissingVisualStyleSurfacesAsAVisualError() async {
        let broken = StoryTemplate(
            id: "broken", version: SemanticVersion(1), displayName: "Broken", themeKeys: [],
            narrative: NarrativeTemplate(version: SemanticVersion(1), beats: StoryFixtures.defaultBeats),
            visualStyleID: "no_such_style",
            sceneRules: SceneRules(maximumScenes: 4),
            validationRules: ValidationRules(ageBands: []),
            constraints: TemplateConstraints(supportedPageCounts: 3...10, supportedAgeRange: 3...12, supportedLanguageCodes: ["en"])
        )
        do {
            _ = try await resolver([broken]).resolve(for: StoryFixtures.request(templateID: "broken"))
            XCTFail("Expected a visual error")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .visual(.stylePresetNotFound("no_such_style")))
        }
    }

    func testShippedTemplateJSONDecodesCompletely() throws {
        let template = StoryFixtures.adventureTemplate

        XCTAssertEqual(template.schemaVersion, StoryTemplate.currentSchemaVersion)
        XCTAssertEqual(template.narrative.beats.count, 10)
        XCTAssertEqual(template.narrative.beats(role: .opening).count, 2)
        XCTAssertEqual(template.narrative.beats(role: .closing).count, 2)
        XCTAssertFalse(template.narrative.repeatableMiddleBeats.isEmpty)
        XCTAssertNotNil(template.narrative.promptSlot(NarrativeTemplate.appearanceLockdownSlot),
                        "Every template must carry the appearance lockdown instruction")
        XCTAssertEqual(template.constraints.supportedPageCounts, 5...16)
        XCTAssertEqual(template.sceneRules.visualPolicy, .singleAssetPerScene)
        XCTAssertNotNil(template.validationRules.ageBand(for: 6))
    }
}
