import XCTest
import CharacterEngine
@testable import StoryEngine

final class OrchestratorTests: XCTestCase {

    // MARK: - Happy path

    func testFullGenerationCompletesEveryStage() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())

        XCTAssertEqual(job.state, .completed)
        XCTAssertNil(job.checkpoint, "Nothing left outstanding")
        for stage in JobStage.allCases {
            XCTAssertTrue(
                [.completed, .skipped].contains(job.status(of: stage)),
                "\(stage.rawValue) ended as \(job.status(of: stage).rawValue)"
            )
        }
        XCTAssertEqual(job.progressFraction, 1.0, accuracy: 0.001)
    }

    func testGeneratedStoryIsComplete() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertEqual(story.pages.count, 7)
        XCTAssertFalse(story.title.isEmpty)
        XCTAssertNotNil(story.outline)
        XCTAssertNotNil(story.draft)
        XCTAssertFalse(story.characters.isEmpty)
        XCTAssertFalse(story.scenes.isEmpty)
        XCTAssertTrue(story.pages.allSatisfy(\.hasText))
        XCTAssertTrue(story.pages.filter(\.requiresImage).allSatisfy { $0.visualAssetID != nil })
        XCTAssertEqual(story.status, .ready, "Validation issues: \(story.validation?.errors.map(\.code) ?? [])")
    }

    func testFewerImagesAreBoughtThanThereArePages() async throws {
        let harness = OrchestratorHarness.make(pageCount: 9)
        let job = try await harness.orchestrator.generate(harness.request(pageCount: 9))
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertLessThan(harness.imageProvider.callCount, story.pages.count)
        XCTAssertEqual(harness.imageProvider.callCount, story.scenes.count)
    }

    func testEveryProviderCallIsRecordedWithItsCost() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertEqual(
            story.usage.languageModelCallCount + story.usage.imageCallCount,
            harness.aiProvider.callCount + harness.imageProvider.callCount
        )
        XCTAssertGreaterThan(story.usage.totalCostUSD, 0)
        XCTAssertGreaterThan(story.usage.totalTokens, 0)
        XCTAssertEqual(job.usage.imageCallCount, harness.imageProvider.callCount)
    }

    func testTheWholeBookIsWrittenInOneDraftCall() async throws {
        let harness = OrchestratorHarness.make(pageCount: 11)
        _ = try await harness.orchestrator.generate(harness.request(pageCount: 11))

        XCTAssertEqual(harness.aiProvider.callCount(for: .outline), 1)
        XCTAssertEqual(harness.aiProvider.callCount(for: .narrativeDraft), 1,
                       "Pacing is decided once, for the book as a whole")
        XCTAssertEqual(harness.aiProvider.callCount(for: .pageRefinement), 11, "Polish is per page")
    }

    func testRefinementCanBeTurnedOffByTheTemplate() async throws {
        let template = StoryFixtures.template(
            beats: StoryFixtures.adventureTemplate.narrative.beats,
            generationPolicy: GenerationPolicy(pageRefinementEnabled: false, semanticValidationEnabled: false),
            pageRange: 5...16
        )
        let harness = OrchestratorHarness.make(pageCount: 7, templates: [template])
        let request = StoryFixtures.request(templateID: template.id, pageCount: 7)

        let job = try await harness.orchestrator.generate(request)

        XCTAssertEqual(job.status(of: .refinePages), .skipped)
        XCTAssertEqual(harness.aiProvider.callCount(for: .pageRefinement), 0)
        XCTAssertEqual(job.state, .completed)
    }

    // MARK: - Failure and retry

    func testATransientFailureIsRetriedWithinTheStage() async throws {
        let harness = OrchestratorHarness.make(
            pageCount: 7,
            script: [.outline: [.transient, .success(ScriptedResponses.outline(beatIDs: Array(repeating: "b", count: 7)))]]
        )
        let job = try await harness.orchestrator.generate(harness.request())

        XCTAssertEqual(job.state, .completed)
        XCTAssertEqual(job.stageState(.planStory)?.attempts.count, 2)
    }

    func testAPermanentFailureFailsTheJobAtThatStage() async {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.outline: [.permanent]])

        do {
            _ = try await harness.orchestrator.generate(harness.request())
            XCTFail("Expected the job to fail")
        } catch {
            guard case .retriesExhausted(let stage, _, _) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(stage, .planStory)
        }
    }

    func testRetryResumesFromTheFailedStageOnly() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.outline: [.permanent]])
        let request = harness.request()
        let queued = try await harness.orchestrator.startJob(for: request)

        _ = try? await harness.orchestrator.run(jobID: queued.id)
        let failed = try await XCTUnwrapAsync(await harness.orchestrator.job(id: queued.id))
        XCTAssertEqual(failed.state, .failed)
        XCTAssertEqual(failed.failedStage, .planStory)
        let castAttemptsBefore = failed.stageState(.resolveCast)?.attempts.count ?? 0

        let recovered = try await harness.orchestrator.retry(jobID: queued.id)

        XCTAssertEqual(recovered.state, .completed)
        XCTAssertEqual(recovered.stageState(.resolveCast)?.attempts.count, castAttemptsBefore,
                       "A completed stage is not run again")
        XCTAssertEqual(harness.aiProvider.callCount(for: .outline), 2, "One failed call, one successful retry")
    }

    func testAFailedImageDoesNotAbandonTheBook() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, imageFailures: [.permanent])
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertEqual(job.state, .completed, "The rest of the book still generated")
        XCTAssertTrue(story.scenes.flatMap(\.visualAssets).contains { $0.state == .failed })
        XCTAssertEqual(story.status, .failed, "But it is not publishable with a missing picture")
        XCTAssertTrue(story.validation?.errors.contains { $0.code == "image_not_ready" } == true)
    }

    // MARK: - Resume

    func testAnInterruptedJobResumesFromItsCheckpoint() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.narrativeDraft: [.permanent]])
        let request = harness.request()
        let queued = try await harness.orchestrator.startJob(for: request)
        _ = try? await harness.orchestrator.run(jobID: queued.id)

        let interrupted = try await XCTUnwrapAsync(await harness.orchestrator.job(id: queued.id))
        XCTAssertEqual(interrupted.checkpoint, .draftNarrative)
        XCTAssertTrue(interrupted.completedStages.contains(.planStory))
        let outlineCallsBefore = harness.aiProvider.callCount(for: .outline)

        let resumed = try await harness.orchestrator.retry(jobID: queued.id)

        XCTAssertEqual(resumed.state, .completed)
        XCTAssertEqual(harness.aiProvider.callCount(for: .outline), outlineCallsBefore,
                       "Resuming must not pay for work already done")
    }

    func testResumeRejectsACompletedJob() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())

        do {
            _ = try await harness.orchestrator.resume(jobID: job.id)
            XCTFail("Expected notResumable")
        } catch {
            guard case .notResumable(_, let state) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(state, .completed)
        }
    }

    func testResumeRejectsACancelledJob() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let queued = try await harness.orchestrator.startJob(for: harness.request())
        try await harness.orchestrator.cancel(jobID: queued.id)

        do {
            _ = try await harness.orchestrator.resume(jobID: queued.id)
            XCTFail("Expected notResumable")
        } catch {
            guard case .notResumable(_, let state) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(state, .cancelled)
        }
    }

    func testCheckpointIsPersistedAfterEveryStage() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())

        let saves = await harness.jobStore.saveCount
        XCTAssertGreaterThanOrEqual(saves, JobStage.allCases.count,
                                    "A dying process must never lose more than one stage")
        let stored = try await harness.jobStore.job(id: job.id)
        XCTAssertNotNil(stored)
    }

    // MARK: - Cancel

    func testCancellingAQueuedJobStopsItAndKeepsTheCheckpoint() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let queued = try await harness.orchestrator.startJob(for: harness.request())

        try await harness.orchestrator.cancel(jobID: queued.id)
        let cancelled = try await XCTUnwrapAsync(await harness.orchestrator.job(id: queued.id))

        XCTAssertEqual(cancelled.state, .cancelled)
        XCTAssertNotNil(cancelled.checkpoint, "The work done so far is still recorded")
    }

    func testRunningACancelledJobStopsBeforeSpendingAnything() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let queued = try await harness.orchestrator.startJob(for: harness.request())
        try await harness.orchestrator.cancel(jobID: queued.id)

        do {
            _ = try await harness.orchestrator.run(jobID: queued.id)
            XCTFail("Expected cancellation")
        } catch {
            guard case .cancelled = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
        }
        XCTAssertEqual(harness.aiProvider.callCount, 0)
        XCTAssertEqual(harness.imageProvider.callCount, 0)
    }

    func testCancellingAnUnknownJobThrows() async {
        let harness = OrchestratorHarness.make()
        let ghost = UUID()
        do {
            try await harness.orchestrator.cancel(jobID: ghost)
            XCTFail("Expected jobNotFound")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .jobNotFound(ghost))
        }
    }

    // MARK: - Budget

    func testAnExhaustedBudgetStopsGenerationRatherThanOverspending() async {
        let tiny = GenerationBudget(maximumLanguageModelCalls: 1, maximumImageCalls: 0, maximumTokens: 5_000, maximumCostUSD: 0.05)
        let harness = OrchestratorHarness.make(pageCount: 7)

        do {
            _ = try await harness.orchestrator.generate(harness.request(budget: tiny))
            XCTFail("Expected the job to fail on budget")
        } catch {
            // Either the draft or a later stage runs out; what matters is that
            // it stopped, and stopped before the image provider was touched.
            XCTAssertLessThanOrEqual(harness.aiProvider.callCount, 2)
            XCTAssertEqual(harness.imageProvider.callCount, 0)
        }
    }

    // MARK: - Character binding

    func testAMissingCharacterFailsAtCastResolution() async {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let failing = StoryEngineDependencies(
            aiProvider: harness.aiProvider,
            imageProvider: harness.imageProvider,
            characterEngine: StubCharacterEngine(cast: StoryFixtures.cast(), error: .emptyCast),
            templateRepository: BuiltInTemplates.repository,
            storyRepository: harness.storyRepository,
            jobStore: harness.jobStore,
            clock: harness.clock,
            idGenerator: SequentialIDGenerator(startingAt: 5_000)
        )
        let orchestrator = StoryOrchestrator(dependencies: failing)

        do {
            _ = try await orchestrator.generate(harness.request())
            XCTFail("Expected a character error")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .character(.emptyCast))
        }
    }

    func testAnUnknownTemplateFailsBeforeAnyRecordsAreCreated() async {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let request = StoryFixtures.request(templateID: "ghost")

        do {
            _ = try await harness.orchestrator.generate(request)
            XCTFail("Expected templateNotFound")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .templateNotFound("ghost"))
        }
        let stories = try? await harness.storyRepository.allStories()
        XCTAssertEqual(stories?.count, 0, "Nothing half-created is left behind")
    }
}

/// `XCTUnwrap` does not accept an async autoclosure.
func XCTUnwrapAsync<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) throws -> T {
    try XCTUnwrap(value, file: file, line: line)
}
