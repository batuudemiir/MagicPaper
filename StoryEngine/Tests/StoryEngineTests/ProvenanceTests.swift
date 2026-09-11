import XCTest
import EngineFoundation
@testable import StoryEngine

final class ProvenanceTests: XCTestCase {

    private func generated(pageCount: Int = 7) async throws -> (OrchestratorHarness, Story) {
        let harness = OrchestratorHarness.make(pageCount: pageCount)
        let job = try await harness.orchestrator.generate(harness.request(pageCount: pageCount))
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))
        return (harness, story)
    }

    // MARK: - It is recorded at all

    func testAGeneratedStoryCarriesProvenance() async throws {
        let (_, story) = try await generated()
        let provenance = try XCTUnwrap(story.provenance)

        XCTAssertEqual(provenance.engineVersion, EngineVersion.current)
        XCTAssertEqual(provenance.promptCompilerVersion, EngineVersion.promptCompiler)
        XCTAssertEqual(provenance.templateVersion, story.templateRef.templateVersion)
    }

    func testProviderAndModelComeFromWhatWasActuallyCalled() async throws {
        let (_, story) = try await generated()
        let provenance = try XCTUnwrap(story.provenance)

        XCTAssertEqual(provenance.textProvider, "fake")
        XCTAssertEqual(provenance.textModel, "fake-1")
        XCTAssertEqual(provenance.imageProvider, "fake-image")
        XCTAssertEqual(provenance.imageModel, "fake-image-1")
    }

    func testTheSeedIsCapturedWhenGenerationWasDeterministic() async throws {
        let (_, story) = try await generated()
        let provenance = try XCTUnwrap(story.provenance)
        let firstAssetSeed = story.scenes
            .sorted { $0.index < $1.index }
            .flatMap(\.visualAssets)
            .compactMap { $0.promptSnapshot?.seed }
            .first

        XCTAssertNotNil(provenance.seed)
        XCTAssertEqual(provenance.seed, firstAssetSeed, "The recorded seed must be one the book was actually drawn with")
    }

    func testNoSeedIsClaimedWhenGenerationWasNotDeterministic() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let request = StoryFixtures.request(pageCount: 7, seedPolicy: .salted(4_242))
        let job = try await harness.orchestrator.generate(request)
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertNil(try XCTUnwrap(story.provenance).seed,
                     "Recording a seed would imply a reproducibility the policy does not offer")
    }

    func testGeneratedAtIsTheEnginesClockNotTheWallClock() async throws {
        let (harness, story) = try await generated()
        let provenance = try XCTUnwrap(story.provenance)
        let now = harness.clock.now()

        XCTAssertLessThanOrEqual(provenance.generatedAt, now)
        XCTAssertGreaterThanOrEqual(provenance.generatedAt, StoryFixtures.referenceDate)
    }

    // MARK: - Regeneration

    func testRegeneratingAPageWritesFreshProvenance() async throws {
        let (harness, story) = try await generated()
        let before = try XCTUnwrap(story.provenance)
        harness.clock.advance(by: 3_600)

        let updated = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: story.pages[2].id)
        let after = try XCTUnwrap(updated.provenance)

        XCTAssertGreaterThan(after.generatedAt, before.generatedAt,
                             "Provenance must describe the book as it stands, not as it was first made")
        XCTAssertEqual(after.templateVersion, before.templateVersion)
    }

    func testRegeneratingAnImageWritesFreshProvenance() async throws {
        let (harness, story) = try await generated()
        let before = try XCTUnwrap(story.provenance)
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })
        harness.clock.advance(by: 3_600)

        let result = try await harness.orchestrator.regeneratePageImage(
            storyID: story.id, pageID: target.id, forceNewSeed: true
        )
        let after = try XCTUnwrap(result.story.provenance)

        XCTAssertGreaterThan(after.generatedAt, before.generatedAt)
        XCTAssertEqual(after.imageProvider, "fake-image")
    }

    func testProvenanceMayBeRewrittenOnAPublishedStory() async throws {
        // Regeneration is permitted after publication, so the record that
        // explains the book has to be allowed to keep up with it.
        let (published, _, _) = try await StoryFixtures.publishedStory()
        let updated = try published.applying(
            StoryMutation(
                .setProvenance(
                    GenerationProvenance(templateVersion: SemanticVersion(9, 9, 9), generatedAt: StoryFixtures.referenceDate)
                ),
                origin: .explicitRegeneration
            ),
            at: StoryFixtures.referenceDate
        )
        XCTAssertEqual(updated.provenance?.templateVersion, SemanticVersion(9, 9, 9))
    }

    func testOrdinaryWritesStillCannotTouchAPublishedStory() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        XCTAssertThrowsError(
            try published.applying(
                StoryMutation(
                    .setProvenance(
                        GenerationProvenance(templateVersion: SemanticVersion(1), generatedAt: StoryFixtures.referenceDate)
                    )
                ),
                at: StoryFixtures.referenceDate
            )
        )
    }

    // MARK: - Persistence

    func testProvenanceSurvivesSerialization() async throws {
        let (_, story) = try await generated()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(Story.self, from: encoder.encode(story))
        XCTAssertEqual(decoded.provenance, story.provenance)
    }

    func testProvenanceRoundTripsOnItsOwn() throws {
        let provenance = GenerationProvenance(
            templateVersion: SemanticVersion(2, 1, 0),
            textProvider: "google", textModel: "gemini-2.5-pro",
            imageProvider: "fal.ai", imageModel: "flux-1",
            seed: 12_345, generatedAt: StoryFixtures.referenceDate
        )
        let decoded = try JSONDecoder().decode(GenerationProvenance.self, from: JSONEncoder().encode(provenance))
        XCTAssertEqual(decoded, provenance)
    }

    func testDerivationIgnoresValidationCallsWhenNamingTheTextModel() {
        // An image-validation call is the last thing in the ledger, but it is
        // not what wrote the story; naming it would send a support
        // investigation to the wrong model.
        var ledger = UsageLedger()
        ledger.record(AIUsage(provider: "google", model: "gemini-2.5-pro", operation: .narrativeDraft, recordedAt: StoryFixtures.referenceDate))
        ledger.record(AIUsage(provider: "fal.ai", model: "flux-1", operation: .imageGeneration, imageCount: 1, recordedAt: StoryFixtures.referenceDate))
        ledger.record(AIUsage(provider: "vision", model: "vision-1", operation: .imageValidation, recordedAt: StoryFixtures.referenceDate))

        let provenance = GenerationProvenance.derive(
            templateVersion: SemanticVersion(1), ledger: ledger, seed: 7, generatedAt: StoryFixtures.referenceDate
        )

        XCTAssertEqual(provenance.textModel, "gemini-2.5-pro")
        XCTAssertEqual(provenance.imageModel, "flux-1")
    }

    func testDerivationFromAnEmptyLedgerRecordsNothingRatherThanGuessing() {
        let provenance = GenerationProvenance.derive(
            templateVersion: SemanticVersion(1), ledger: UsageLedger(), seed: nil, generatedAt: StoryFixtures.referenceDate
        )
        XCTAssertNil(provenance.textProvider)
        XCTAssertNil(provenance.imageModel)
        XCTAssertEqual(provenance.engineVersion, EngineVersion.current)
    }
}
