import XCTest
import CharacterEngine
@testable import StoryEngine

final class DataLifecycleTests: XCTestCase {

    private func makeLifecycle(
        stories: [Story] = [],
        characters: [CharacterProfile] = [],
        deleter: RecordingAssetDeleter? = RecordingAssetDeleter()
    ) -> (StoryDataLifecycleService, InMemoryStoryRepository, InMemoryJobStore, InMemoryCharacterStore) {
        let storyRepository = InMemoryStoryRepository(stories)
        let jobStore = InMemoryJobStore()
        let characterStore = InMemoryCharacterStore(characters)
        let service = StoryDataLifecycleService(
            storyRepository: storyRepository,
            jobStore: jobStore,
            characterStore: characterStore,
            assetDeleter: deleter
        )
        return (service, storyRepository, jobStore, characterStore)
    }

    // MARK: - Stories

    func testDeletingAStoryRemovesItsRecordAndItsIllustrations() async throws {
        let (story, request, _) = try StoryFixtures.completeStory()
        let deleter = RecordingAssetDeleter()
        let (service, repository, jobStore, _) = makeLifecycle(stories: [story], deleter: deleter)
        try await jobStore.saveRequest(request)

        let report = try await service.deleteStoryReporting(story.id)

        let remaining = try await repository.story(id: story.id)
        XCTAssertNil(remaining)
        XCTAssertTrue(report.logicalRecords.contains("story:\(story.id.uuidString)"))

        let expectedImages = story.scenes.flatMap(\.visualAssets).compactMap { $0.imageRef?.locator }
        let deleted = await deleter.deleted
        XCTAssertEqual(Set(deleted), Set(expectedImages))
        XCTAssertFalse(expectedImages.isEmpty, "This fixture should own illustrations")
    }

    func testDeletingAStoryKeepsTheFamilysOwnPhoto() async throws {
        // The reference photo belongs to the child's profile, not to one book.
        // Deleting a story must not take the family's picture with it.
        let (story, _, _) = try StoryFixtures.completeStory()
        let deleter = RecordingAssetDeleter()
        let (service, _, _, _) = makeLifecycle(stories: [story], deleter: deleter)

        let report = try await service.deleteStoryReporting(story.id)

        XCTAssertTrue(report.externalAssetLocators.contains("deniz-master.jpg"))
        let deleted = await deleter.deleted
        XCTAssertFalse(deleted.contains("deniz-master.jpg"))
    }

    func testDeletingAStoryRemovesItsResumableJob() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.narrativeDraft: [.permanent]])
        let queued = try await harness.orchestrator.startJob(for: harness.request())
        _ = try? await harness.orchestrator.run(jobID: queued.id)

        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: queued.storyID))
        let service = StoryDataLifecycleService(
            storyRepository: harness.storyRepository, jobStore: harness.jobStore
        )

        try await service.deleteStory(story.id)

        let jobs = try await harness.jobStore.resumableJobs()
        XCTAssertTrue(jobs.isEmpty, "A checkpoint that would rebuild a deleted story must go with it")
        let request = try await harness.jobStore.request(id: story.requestID)
        XCTAssertNil(request)
    }

    func testDeletingAStoryReportsAssetsItCouldNotRemove() async throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let doomed = try XCTUnwrap(story.scenes.first?.visualAssets.first?.imageRef?.locator)
        let deleter = RecordingAssetDeleter(unreachable: [doomed])
        let (service, repository, _, _) = makeLifecycle(stories: [story], deleter: deleter)

        let report = try await service.deleteStoryReporting(story.id)

        XCTAssertEqual(report.failedAssetLocators, [doomed])
        let remaining = try await repository.story(id: story.id)
        XCTAssertNil(remaining, "One unreachable file must not leave the deletion half-done")
    }

    func testWithNoDeleterAssetsAreReportedAsExternalNotAsRemoved() async throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let (service, _, _, _) = makeLifecycle(stories: [story], deleter: nil)

        let report = try await service.deleteStoryReporting(story.id)

        XCTAssertTrue(report.deletedAssetLocators.isEmpty)
        XCTAssertFalse(report.externalAssetLocators.isEmpty, "Nothing removed them, so nothing should claim they are gone")
    }

    // MARK: - Characters

    func testDeletingACharacterStopsFutureGenerationResolvingIt() async throws {
        let profile = CharacterFixtureBuilder.profile()
        let (service, _, _, characterStore) = makeLifecycle(characters: [profile])

        try await service.deleteCharacter(profile.id)

        let resolver = CharacterResolver(store: characterStore)
        do {
            _ = try await resolver.resolveCast(for: CastBinding(protagonist: profile.id))
            XCTFail("Expected profileNotFound")
        } catch {
            XCTAssertEqual(error as? CharacterEngineError, .profileNotFound(profile.id))
        }
    }

    func testDeletingACharacterRemovesEveryVersionsReferenceImages() async throws {
        let first = CharacterFixtureBuilder.version(number: 1, locator: "photo-v1.jpg")
        let second = CharacterFixtureBuilder.version(number: 2, locator: "photo-v2.jpg")
        let profile = CharacterFixtureBuilder.profile(versions: [first, second])
        let deleter = RecordingAssetDeleter()
        let (service, _, _, _) = makeLifecycle(characters: [profile], deleter: deleter)

        let report = try await service.deleteCharacterReporting(profile.id)

        let deleted = await deleter.deleted
        XCTAssertEqual(Set(deleted), ["photo-v1.jpg", "photo-v2.jpg"],
                       "An older photo is still a photo of a child")
        XCTAssertTrue(report.logicalRecords.contains("character:\(profile.id)"))
    }

    func testDeletingACharacterLeavesAlreadyGeneratedBooksReadable() async throws {
        // Stories keep their own copy of the identity they were drawn with, so
        // removing the character must not corrupt a book a child already owns.
        let (story, _, _) = try StoryFixtures.completeStory()
        let profile = CharacterFixtureBuilder.profile()
        let (service, repository, _, _) = makeLifecycle(stories: [story], characters: [profile])

        try await service.deleteCharacter(profile.id)

        let survivor = try await XCTUnwrapAsync(await repository.story(id: story.id))
        XCTAssertFalse(survivor.characters.isEmpty)
        XCTAssertEqual(survivor.protagonist?.displayName, "Deniz")
    }

    // MARK: - Jobs

    func testDeletingAJobRemovesItsCheckpoint() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7, script: [.narrativeDraft: [.permanent]])
        let queued = try await harness.orchestrator.startJob(for: harness.request())
        _ = try? await harness.orchestrator.run(jobID: queued.id)

        let service = StoryDataLifecycleService(storyRepository: harness.storyRepository, jobStore: harness.jobStore)
        try await service.deleteGenerationJob(queued.id)

        let job = try await harness.jobStore.job(id: queued.id)
        XCTAssertNil(job)
    }

    func testDeletingAJobLeavesItsStoryIntact() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())

        let service = StoryDataLifecycleService(storyRepository: harness.storyRepository, jobStore: harness.jobStore)
        try await service.deleteGenerationJob(job.id)

        let story = try await harness.storyRepository.story(id: job.storyID)
        XCTAssertNotNil(story, "Deleting the receipt should not delete the book")
    }

    // MARK: - Idempotence

    func testDeletingAStoryTwiceIsSafe() async throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let (service, _, _, _) = makeLifecycle(stories: [story])

        let first = try await service.deleteStoryReporting(story.id)
        let second = try await service.deleteStoryReporting(story.id)

        XCTAssertFalse(first.wasAlreadyAbsent)
        XCTAssertTrue(second.wasAlreadyAbsent, "A retried deletion should converge, not fail")
        XCTAssertTrue(second.isEmpty)
    }

    func testDeletingSomethingThatNeverExistedIsSafe() async throws {
        let (service, _, _, _) = makeLifecycle()

        let story = try await service.deleteStoryReporting(UUID())
        let character = try await service.deleteCharacterReporting(CharacterID())
        let job = try await service.deleteGenerationJobReporting(UUID())

        XCTAssertTrue(story.wasAlreadyAbsent)
        XCTAssertTrue(character.wasAlreadyAbsent)
        XCTAssertTrue(job.wasAlreadyAbsent)
    }

    func testDeletionDistinguishesItsThreeKindsOfRemoval() async throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let (service, _, _, _) = makeLifecycle(stories: [story])

        let report = try await service.deleteStoryReporting(story.id)

        // Engine records, files the engine had removed, and files it only
        // knows about — blurring these would hide a child's photo still
        // sitting in cloud storage after a deletion.
        XCTAssertFalse(report.logicalRecords.isEmpty)
        XCTAssertFalse(report.deletedAssetLocators.isEmpty)
        XCTAssertFalse(report.externalAssetLocators.isEmpty)
    }

    func testTheOrchestratorExposesTheLifecycleContract() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())

        let lifecycle: StoryDataLifecycle = await harness.orchestrator.lifecycle
        try await lifecycle.deleteStory(job.storyID)

        let story = try await harness.storyRepository.story(id: job.storyID)
        XCTAssertNil(story)
    }
}

/// Character profiles for lifecycle tests.
enum CharacterFixtureBuilder {
    static func version(number: Int, locator: String) -> CharacterVersion {
        CharacterVersion(
            versionNumber: number,
            createdAt: StoryFixtures.referenceDate,
            identity: CharacterIdentity(ageYears: 6, pronouns: .theyThem, descriptors: [], identitySeed: 1),
            styleProfile: CharacterStyleProfile(illustrationStyleID: "storybook_painted_v1", palettePresetID: "paper_warm"),
            assetSet: CharacterAssetSet(
                masterReference: CharacterAsset(role: .master, locator: locator, createdAt: StoryFixtures.referenceDate),
                identitySeed: 1,
                stylePresetID: "magic_paper_v1"
            ),
            provenance: .authoredByParent
        )
    }

    static func profile(versions: [CharacterVersion]? = nil) -> CharacterProfile {
        let resolved = versions ?? [version(number: 1, locator: "photo-v1.jpg")]
        return CharacterProfile(
            ownerProfileID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            displayName: "Deniz",
            versions: resolved,
            activeVersionID: resolved[resolved.count - 1].id,
            createdAt: StoryFixtures.referenceDate
        )
    }
}
