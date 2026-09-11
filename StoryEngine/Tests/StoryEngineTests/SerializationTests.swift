import XCTest
import CharacterEngine
import EngineFoundation
import VisualSystem
@testable import StoryEngine

final class SerializationTests: XCTestCase {

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #filePath, line: UInt = #line) throws {
        let decoded = try decoder().decode(T.self, from: encoder().encode(value))
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    // MARK: - Domain roots

    func testStoryRequestRoundTrips() throws {
        try roundTrip(StoryFixtures.request())
        try roundTrip(StoryFixtures.request(requirement: .exact(SemanticVersion(1, 2, 0))))
        try roundTrip(StoryFixtures.request(seedPolicy: .salted(4_242)))
    }

    func testStoryTemplateRoundTrips() throws {
        try roundTrip(StoryFixtures.adventureTemplate)
        try roundTrip(StoryFixtures.template())
    }

    func testACompleteStoryRoundTrips() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        try roundTrip(story)
    }

    func testAPublishedStoryRoundTripsIncludingItsStamp() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        try roundTrip(published)

        let decoded = try decoder().decode(Story.self, from: encoder().encode(published))
        XCTAssertTrue(decoded.publication.isPublished)
        XCTAssertEqual(decoded.publication.contentHash, published.publication.contentHash)
        XCTAssertEqual(decoded.contentHash, published.contentHash, "The hash must survive a save and reload")
    }

    func testOutlineDraftPagesAndScenesRoundTripIndividually() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        try roundTrip(try XCTUnwrap(story.outline))
        try roundTrip(try XCTUnwrap(story.draft))
        try roundTrip(story.pages)
        try roundTrip(story.scenes)
        try roundTrip(story.characters)
    }

    func testValidationResultRoundTripsWithEveryOutcome() throws {
        let result = StoryValidationResult(
            reports: [
                ValidatorReport(validatorID: "a", outcome: .ran, issues: [
                    ValidationIssue(validatorID: "a", code: "x", severity: .error, scope: .story, message: "m")
                ]),
                ValidatorReport(validatorID: "b", outcome: .skipped(reason: "budget exhausted"), issues: []),
                ValidatorReport(validatorID: "c", outcome: .failed(reason: "boom"), issues: [])
            ],
            validatedAt: StoryFixtures.referenceDate
        )
        try roundTrip(result)

        let decoded = try decoder().decode(StoryValidationResult.self, from: encoder().encode(result))
        XCTAssertEqual(decoded.skippedValidatorIDs, ["b"], "A skipped check must not read back as a passed one")
    }

    func testEveryValidationScopeRoundTrips() throws {
        let id = UUID()
        try roundTrip([ValidationScope.story, .page(id), .scene(id), .visualAsset(id)])
    }

    func testUsageLedgerRoundTrips() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        var ledger = story.usage
        ledger.record(AIUsage(provider: "p", model: "m", operation: .outline, inputTokens: 5, estimatedCostUSD: 0.01, recordedAt: StoryFixtures.referenceDate))
        try roundTrip(ledger)
    }

    func testVisualConstraintSetRoundTripsWithItsFingerprint() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let constraints = try XCTUnwrap(story.scenes.first?.visualAssets.first?.promptSnapshot)
        try roundTrip(constraints)

        let decoded = try decoder().decode(VisualConstraintSet.self, from: encoder().encode(constraints))
        XCTAssertEqual(decoded.fingerprint, constraints.fingerprint, "Fingerprints must survive persistence")
    }

    // MARK: - Schema versions

    func testSchemaVersionsArePersisted() throws {
        let (story, request, _) = try StoryFixtures.completeStory()

        let storyObject = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoder().encode(story)) as? [String: Any])
        XCTAssertEqual(storyObject["schemaVersion"] as? Int, Story.currentSchemaVersion)

        let requestObject = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoder().encode(request)) as? [String: Any])
        XCTAssertEqual(requestObject["schemaVersion"] as? Int, StoryRequest.currentSchemaVersion)
    }

    func testUnknownFieldsAreTolerated() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        var object = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoder().encode(story)) as? [String: Any])
        object["somethingAddedInAFutureVersion"] = ["nested": true]

        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertNoThrow(try decoder().decode(Story.self, from: data))
    }

    // MARK: - Jobs and resumption

    func testJobRoundTripsWithItsAttemptHistory() throws {
        var job = StoryGenerationJob(
            id: UUID(), storyID: UUID(), requestID: UUID(), createdAt: StoryFixtures.referenceDate
        )
        job = job.starting(.planStory, at: StoryFixtures.referenceDate)
        job = job.recording(
            StoryGenerationAttempt(
                id: UUID(), stage: .planStory, attemptNumber: 1,
                startedAt: StoryFixtures.referenceDate, finishedAt: StoryFixtures.referenceDate.addingTimeInterval(2),
                outcome: .failure(errorClass: .transient, message: "flaky"),
                usage: AIUsage(provider: "p", model: "m", operation: .outline, recordedAt: StoryFixtures.referenceDate)
            ),
            at: StoryFixtures.referenceDate
        )
        job = job.completing(.planStory, at: StoryFixtures.referenceDate)

        try roundTrip(job)
    }

    func testACheckpointSurvivesPersistenceAndResumesIdentically() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.narrativeDraft: [.permanent]])
        let queued = try await harness.orchestrator.startJob(for: harness.request())
        _ = try? await harness.orchestrator.run(jobID: queued.id)

        let stored = try await XCTUnwrapAsync(await harness.jobStore.job(id: queued.id))
        let reloaded = try decoder().decode(StoryGenerationJob.self, from: encoder().encode(stored))

        XCTAssertEqual(reloaded.checkpoint, stored.checkpoint)
        XCTAssertEqual(reloaded.completedStages, stored.completedStages)
        XCTAssertEqual(reloaded.allAttempts.count, stored.allAttempts.count)
        XCTAssertEqual(reloaded.usage.totalCostUSD, stored.usage.totalCostUSD, accuracy: 0.000_1)
        XCTAssertEqual(reloaded, stored)
    }

    func testAReloadedStoryStillRegeneratesTheSamePicture() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        let reloaded = try decoder().decode(Story.self, from: encoder().encode(story))
        let asset = try XCTUnwrap(reloaded.scenes.first?.visualAssets.first)
        let original = try XCTUnwrap(story.scenes.first?.visualAssets.first)

        XCTAssertEqual(asset.fingerprint, original.fingerprint)
        XCTAssertEqual(asset.promptSnapshot?.seed, original.promptSnapshot?.seed,
                       "A story reopened tomorrow must not decide its illustrations are stale")
    }

    func testJobStageOrderIsStable() {
        // Persisted checkpoints are stage names; reordering the enum would make
        // every stored job resume in the wrong place.
        XCTAssertEqual(
            JobStage.allCases.map(\.rawValue),
            ["resolveTemplate", "resolveCast", "planStory", "planScenes", "planPages",
             "draftNarrative", "segmentPages", "refinePages", "planVisuals",
             "generateImages", "validateImages", "validate", "assemble"]
        )
    }

    func testAllEnumRawValuesAreStable() {
        XCTAssertEqual(JobState.allCases.map(\.rawValue), ["queued", "running", "paused", "cancelled", "failed", "completed"])
        XCTAssertEqual(StageStatus.allCases.map(\.rawValue), ["pending", "running", "completed", "failed", "skipped"])
        XCTAssertEqual(ErrorClass.allCases.map(\.rawValue), ["transient", "rateLimited", "permanent", "cancelled"])
        XCTAssertEqual(BeatRole.allCases.map(\.rawValue), ["opening", "middle", "closing"])
        XCTAssertEqual(VisualAssetState.allCases.map(\.rawValue), ["notRequested", "pending", "ready", "failed"])
        XCTAssertEqual(SceneVisualPolicy.allCases.map(\.rawValue), ["singleAssetPerScene", "assetPerVariant"])
    }

    // MARK: - Templates as data

    func testAHandWrittenTemplateNeedsOnlyItsEssentials() throws {
        // Everything with a sensible default is optional, so a new kind of
        // story is a short file rather than a full transcription.
        let minimal = """
        {
          "id": "minimal_01",
          "version": "1.0.0",
          "narrative": {
            "version": "1.0.0",
            "beats": [
              { "id": "start", "role": "opening", "settingKey": "home" },
              { "id": "middle", "role": "middle", "settingKey": "away", "repeatable": true },
              { "id": "end", "role": "closing", "settingKey": "home" }
            ]
          },
          "visualStyleID": "magic_paper_v1",
          "sceneRules": { "maximumScenes": 5 },
          "validationRules": {
            "ageBands": [
              { "minimumAge": 3, "maximumAge": 9, "minimumWordsPerPage": 20,
                "maximumWordsPerPage": 90, "maximumSentenceWords": 14 }
            ]
          },
          "constraints": {
            "minimumPages": 3, "maximumPages": 8,
            "minimumAge": 3, "maximumAge": 9,
            "supportedLanguageCodes": ["en"]
          }
        }
        """

        let template = try decoder().decode(StoryTemplate.self, from: Data(minimal.utf8))

        XCTAssertEqual(template.id, "minimal_01")
        XCTAssertEqual(template.displayName, "minimal_01", "Falls back to the id")
        XCTAssertEqual(template.schemaVersion, StoryTemplate.currentSchemaVersion)
        XCTAssertTrue(template.themeKeys.isEmpty, "No keys means any theme")
        XCTAssertEqual(template.visualStyleRequirement, .latest)
        XCTAssertEqual(template.sceneRules.visualPolicy, .singleAssetPerScene)
        XCTAssertEqual(template.sceneRules.changeTriggers, [.setting, .timeOfDay, .cast])
        XCTAssertEqual(template.generationPolicy.maximumAttemptsPerStage, 3)
        XCTAssertEqual(template.validationRules.enabledValidators, ValidatorID.allDeterministic)

        try roundTrip(template)
    }

    func testTheShippedTemplateSurvivesAFullRoundTrip() throws {
        let original = StoryFixtures.adventureTemplate
        let decoded = try decoder().decode(StoryTemplate.self, from: encoder().encode(original))

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.narrative.beats.count, original.narrative.beats.count)
    }
}
