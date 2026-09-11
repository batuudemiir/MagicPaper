import XCTest
import EngineFoundation
@testable import StoryEngine

final class IdempotencyTests: XCTestCase {
    private let storyID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000001")!
    private let otherStoryID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000002")!

    // MARK: - Keys are a function of the work

    func testIdenticalLogicalRequestsProduceIdenticalKeys() throws {
        let (story, request, template) = try StoryFixtures.completeStory()

        XCTAssertEqual(
            IdempotencyKeyFactory.outline(storyID: storyID, templateRef: template.ref, requestID: request.id),
            IdempotencyKeyFactory.outline(storyID: storyID, templateRef: template.ref, requestID: request.id)
        )
        let page = story.pages[1]
        XCTAssertEqual(
            IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: nil),
            IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: nil)
        )
        let asset = try XCTUnwrap(story.scenes.first?.visualAssets.first)
        XCTAssertEqual(
            IdempotencyKeyFactory.image(storyID: storyID, asset: asset),
            IdempotencyKeyFactory.image(storyID: storyID, asset: asset)
        )
    }

    func testKeysAreStableAcrossProcesses() throws {
        // Pinned literal. If this changes, every in-flight retry in the wild
        // stops recognising its own earlier request and may pay twice.
        let identity = ProviderRequestIdentity(operation: .outline, components: ["story:fixed", "template:t@1.0.0"])
        XCTAssertEqual(identity.idempotencyKey, "outline-35148edba213bd28")
    }

    func testTheKeyNamesItsOperation() {
        let identity = ProviderRequestIdentity(operation: .imageGeneration, components: ["a"])
        XCTAssertTrue(identity.idempotencyKey.hasPrefix("imageGeneration-"),
                      "A support log should say what the request was")
    }

    func testDifferentStoriesNeverShareAKey() throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        XCTAssertNotEqual(
            IdempotencyKeyFactory.outline(storyID: storyID, templateRef: template.ref, requestID: request.id),
            IdempotencyKeyFactory.outline(storyID: otherStoryID, templateRef: template.ref, requestID: request.id)
        )
        _ = story
    }

    // MARK: - Material change means new work

    func testANewPageRevisionIsNewWork() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        var page = story.pages[1]
        let before = IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: nil)
        page.textRevision += 1

        XCTAssertNotEqual(before, IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: nil))
    }

    func testADifferentInstructionIsNewWork() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let page = story.pages[1]
        XCTAssertNotEqual(
            IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: nil),
            IdempotencyKeyFactory.pageRefinement(storyID: storyID, page: page, instruction: "make it gentler")
        )
    }

    func testAChangedFingerprintIsNewWork() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        var asset = try XCTUnwrap(story.scenes.first?.visualAssets.first)
        let before = IdempotencyKeyFactory.image(storyID: storyID, asset: asset)
        asset.fingerprint = "0000000000000000"

        XCTAssertNotEqual(before, IdempotencyKeyFactory.image(storyID: storyID, asset: asset))
    }

    func testAForcedRerollIsNewWork() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        var asset = try XCTUnwrap(story.scenes.first?.visualAssets.first)
        let before = IdempotencyKeyFactory.image(storyID: storyID, asset: asset)
        // `forceNewSeed` bumps the revision, which is what makes the reroll a
        // different logical request rather than a cache hit.
        asset.revision += 1

        XCTAssertNotEqual(before, IdempotencyKeyFactory.image(storyID: storyID, asset: asset))
    }

    func testARePlannedOutlineIsNewDraftWork() throws {
        let (story, _, template) = try StoryFixtures.completeStory()
        let outline = try XCTUnwrap(story.outline)
        let before = IdempotencyKeyFactory.narrativeDraft(storyID: storyID, outline: outline, templateRef: template.ref)

        var beats = outline.beats
        beats[0] = OutlineBeat(
            id: beats[0].id, templateBeatID: beats[0].templateBeatID, role: beats[0].role,
            ordinal: beats[0].ordinal, summary: "Something entirely different happens.",
            settingKey: beats[0].settingKey, timeOfDayKey: beats[0].timeOfDayKey,
            moodKey: beats[0].moodKey, castNames: beats[0].castNames
        )
        let changed = StoryOutline(title: outline.title, logline: outline.logline, beats: beats)

        XCTAssertNotEqual(
            before,
            IdempotencyKeyFactory.narrativeDraft(storyID: storyID, outline: changed, templateRef: template.ref)
        )
    }

    func testRevalidatingUnchangedContentIsTheSameQuestion() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let a = IdempotencyKeyFactory.semanticValidation(
            storyID: story.id, validatorID: ValidatorID.narrativeConsistency, contentHash: story.contentHash
        )
        let edited = try story.applying(
            [.replacePageText(pageID: story.pages[0].id, title: nil, text: "Different words entirely.")],
            at: StoryFixtures.referenceDate
        )
        let b = IdempotencyKeyFactory.semanticValidation(
            storyID: story.id, validatorID: ValidatorID.narrativeConsistency, contentHash: edited.contentHash
        )
        XCTAssertNotEqual(a, b, "Changed content is a new question")
    }

    // MARK: - Retries keep their key

    func testARetryReusesTheKeyOfTheAttemptItRepeats() async throws {
        let harness = OrchestratorHarness.make(
            pageCount: 7,
            script: [.outline: [.transient, .success(ScriptedResponses.outline(beatIDs: Array(repeating: "b", count: 7)))]]
        )
        _ = try await harness.orchestrator.generate(harness.request())

        let outlineRequests = harness.aiProvider.requests(for: .outline)
        XCTAssertEqual(outlineRequests.count, 2, "One failure, one retry")
        XCTAssertEqual(outlineRequests[0].identity, outlineRequests[1].identity,
                       "A retry is the same logical call; a provider must be able to recognise it")
    }

    // MARK: - Deduplication

    func testACachedResultIsReusedInsteadOfRebought() async throws {
        let cache = ProviderResultCache()
        let provider = FakeStoryAIProvider(fallback: { _ in .success(#"{"value":1}"#) })
        let budget = GenerationBudgetManager(budget: .standard)
        let service = StoryAIService(
            provider: provider, budget: budget, policy: RetryPolicy(maximumAttempts: 1),
            clock: FixedClock(autoAdvance: 1), idGenerator: SequentialIDGenerator(startingAt: 8_000),
            cache: cache
        )

        struct Shape: Codable, Sendable { let value: Int }
        let request = AICompletionRequest(
            operation: .outline, modelTier: .fast, systemInstructions: ["s"], userInstructions: ["u"],
            languageCode: "en",
            identity: ProviderRequestIdentity(operation: .outline, components: ["fixed"])
        )

        _ = try await service.complete(request, stage: .planStory, estimate: UsageEstimate(operation: .outline), decoding: Shape.self)
        _ = try await service.complete(request, stage: .planStory, estimate: UsageEstimate(operation: .outline), decoding: Shape.self)

        XCTAssertEqual(provider.callCount, 1, "The second identical request must not reach the provider")
        let hits = await cache.hitCount
        XCTAssertEqual(hits, 1)

        let ledger = await budget.currentLedger
        XCTAssertEqual(ledger.languageModelCallCount, 1, "And must not be billed twice")
    }

    func testADifferentKeyIsNotDeduplicated() async throws {
        let cache = ProviderResultCache()
        let provider = FakeStoryAIProvider(fallback: { _ in .success(#"{"value":1}"#) })
        let service = StoryAIService(
            provider: provider, budget: GenerationBudgetManager(budget: .standard),
            policy: RetryPolicy(maximumAttempts: 1), clock: FixedClock(autoAdvance: 1),
            idGenerator: SequentialIDGenerator(startingAt: 8_100), cache: cache
        )

        struct Shape: Codable, Sendable { let value: Int }
        func request(_ component: String) -> AICompletionRequest {
            AICompletionRequest(
                operation: .outline, modelTier: .fast, systemInstructions: ["s"], userInstructions: ["u"],
                languageCode: "en",
                identity: ProviderRequestIdentity(operation: .outline, components: [component])
            )
        }

        _ = try await service.complete(request("a"), stage: .planStory, estimate: UsageEstimate(operation: .outline), decoding: Shape.self)
        _ = try await service.complete(request("b"), stage: .planStory, estimate: UsageEstimate(operation: .outline), decoding: Shape.self)

        XCTAssertEqual(provider.callCount, 2)
        let hits = await cache.hitCount
        XCTAssertEqual(hits, 0)
    }

    func testALostResponseDoesNotCauseADoubleCharge() async throws {
        // The case this whole mechanism exists for: the image was produced, the
        // response never arrived, and the retry must not buy a second one.
        let cache = ProviderResultCache()
        let provider = FakeImageProvider()
        let budget = GenerationBudgetManager(budget: .standard)
        let service = ImageGenerationService(
            provider: provider, budget: budget, policy: RetryPolicy(maximumAttempts: 1),
            clock: FixedClock(autoAdvance: 1), idGenerator: SequentialIDGenerator(startingAt: 8_200),
            cache: cache
        )

        let (story, _, _) = try StoryFixtures.completeStory()
        var asset = try XCTUnwrap(story.scenes.first?.visualAssets.first)
        asset.state = .notRequested
        asset.imageRef = nil
        let constraints = try XCTUnwrap(asset.promptSnapshot)

        _ = try await service.generate(asset: asset, constraints: constraints, storyID: story.id)
        _ = try await service.generate(asset: asset, constraints: constraints, storyID: story.id)

        XCTAssertEqual(provider.callCount, 1, "One picture, one charge")
        let ledger = await budget.currentLedger
        XCTAssertEqual(ledger.imageCallCount, 1)
        XCTAssertEqual(ledger.totalImagesProduced, 1)
    }

    func testIdentityRoundTrips() throws {
        let identity = ProviderRequestIdentity(operation: .imageValidation, components: ["a", "b"])
        let decoded = try JSONDecoder().decode(ProviderRequestIdentity.self, from: JSONEncoder().encode(identity))
        XCTAssertEqual(decoded, identity)
    }
}
