import XCTest
import CharacterEngine
import VisualSystem
@testable import StoryEngine

final class PartialRegenerationTests: XCTestCase {

    /// Runs a full generation, then hands back the harness and the finished story.
    private func generated(pageCount: Int = 7) async throws -> (OrchestratorHarness, Story) {
        let harness = OrchestratorHarness.make(pageCount: pageCount)
        let job = try await harness.orchestrator.generate(harness.request(pageCount: pageCount))
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))
        return (harness, story)
    }

    // MARK: - Page text

    func testRegeneratingPageTextTouchesOnlyThatPage() async throws {
        let (harness, story) = try await generated()
        let target = story.pages[2]
        let othersBefore = story.pages.filter { $0.id != target.id }

        let updated = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: target.id)
        let page = try XCTUnwrap(updated.page(id: target.id))

        XCTAssertEqual(page.textRevision, target.textRevision + 1)
        for original in othersBefore {
            let after = try XCTUnwrap(updated.page(id: original.id))
            XCTAssertEqual(after.text, original.text, "Page \(original.index) must not change")
            XCTAssertEqual(after.textRevision, original.textRevision)
        }
    }

    func testRegeneratingPageTextIsGivenTheBooksVoice() async throws {
        let (harness, story) = try await generated()
        let target = story.pages[3]
        _ = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: target.id)

        let prompt = try XCTUnwrap(harness.aiProvider.requests(for: .pageRefinement).last).userPrompt
        let voice = try XCTUnwrap(story.draft?.voiceProfile)

        XCTAssertTrue(prompt.contains(voice.narratorRegister), "The established voice must travel with the request")
        XCTAssertTrue(prompt.contains("THE PAGE BEFORE"), "Neighbouring pages keep the seam invisible")
        XCTAssertTrue(prompt.contains("THE PAGE AFTER"))
    }

    func testAParentsInstructionReachesTheModel() async throws {
        let (harness, story) = try await generated()
        _ = try await harness.orchestrator.regeneratePageText(
            storyID: story.id, pageID: story.pages[1].id, instruction: "make it gentler"
        )

        let prompt = try XCTUnwrap(harness.aiProvider.requests(for: .pageRefinement).last).userPrompt
        XCTAssertTrue(prompt.contains("make it gentler"))
    }

    func testRegeneratingTextDoesNotRedrawAnything() async throws {
        let (harness, story) = try await generated()
        let imagesBefore = harness.imageProvider.callCount

        _ = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: story.pages[2].id)

        XCTAssertEqual(harness.imageProvider.callCount, imagesBefore, "Rewriting a page must not re-buy illustrations")
    }

    func testUnknownPageThrows() async throws {
        let (harness, story) = try await generated()
        let ghost = UUID()
        do {
            _ = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: ghost)
            XCTFail("Expected pageNotFound")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .pageNotFound(ghost))
        }
    }

    // MARK: - Page image

    func testRegeneratingAPageImageWithNewSeedRedrawsExactlyOneAsset() async throws {
        let (harness, story) = try await generated()
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })
        let before = harness.imageProvider.callCount

        let result = try await harness.orchestrator.regeneratePageImage(
            storyID: story.id, pageID: target.id, forceNewSeed: true
        )

        XCTAssertEqual(harness.imageProvider.callCount, before + 1)
        XCTAssertTrue(result.story.visualAsset(forPage: target.id)?.isReady == true)
    }

    func testRedrawingWithUnchangedInputsCostsNothing() async throws {
        // Without a new seed the request is identical in every respect, so it
        // is the same logical operation and reuses what was already produced.
        // Charging for a second identical picture would be pure waste.
        let (harness, story) = try await generated()
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })
        let before = harness.imageProvider.callCount

        let result = try await harness.orchestrator.regeneratePageImage(
            storyID: story.id, pageID: target.id, forceNewSeed: false
        )

        XCTAssertEqual(harness.imageProvider.callCount, before, "No second charge for identical work")
        XCTAssertTrue(result.story.visualAsset(forPage: target.id)?.isReady == true, "And the page still has its picture")
    }

    func testRegeneratingAPageImageReportsEveryPageItChanges() async throws {
        let (harness, story) = try await generated(pageCount: 9)
        // Pick an illustration that more than one page actually shows.
        let assetID = try XCTUnwrap(
            Set(story.pages.compactMap(\.visualAssetID))
                .first { story.pages(sharing: $0).count > 1 }
        )
        let shared = story.pages(sharing: assetID)
        XCTAssertGreaterThan(shared.count, 1)

        let result = try await harness.orchestrator.regeneratePageImage(storyID: story.id, pageID: shared[0].id)

        XCTAssertEqual(Set(result.affectedPageIDs), Set(shared.map(\.id)),
                       "A parent redrawing one page must be told which others change with it")
    }

    func testWithoutForceNewSeedTheSeedIsUnchanged() async throws {
        let (harness, story) = try await generated()
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })
        let originalSeed = try XCTUnwrap(story.visualAsset(forPage: target.id)?.promptSnapshot?.seed)

        let result = try await harness.orchestrator.regeneratePageImage(
            storyID: story.id, pageID: target.id, forceNewSeed: false
        )

        XCTAssertEqual(result.story.visualAsset(forPage: target.id)?.promptSnapshot?.seed, originalSeed,
                       "Same inputs, same picture")
        XCTAssertEqual(result.story.visualAsset(forPage: target.id)?.revision, 0, "And no reroll was recorded")
    }

    func testForceNewSeedAsksForADifferentPicture() async throws {
        let (harness, story) = try await generated()
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })
        let originalSeed = try XCTUnwrap(story.visualAsset(forPage: target.id)?.promptSnapshot?.seed)

        let result = try await harness.orchestrator.regeneratePageImage(storyID: story.id, pageID: target.id, forceNewSeed: true)

        XCTAssertNotEqual(harness.imageProvider.seeds.last, originalSeed)
        XCTAssertEqual(result.story.visualAsset(forPage: target.id)?.revision, 1)
    }

    func testForcingANewSeedTwiceKeepsMoving() async throws {
        let (harness, story) = try await generated()
        let target = try XCTUnwrap(story.pages.first { $0.visualAssetID != nil })

        _ = try await harness.orchestrator.regeneratePageImage(storyID: story.id, pageID: target.id, forceNewSeed: true)
        _ = try await harness.orchestrator.regeneratePageImage(storyID: story.id, pageID: target.id, forceNewSeed: true)

        let seeds = harness.imageProvider.seeds.suffix(2)
        XCTAssertEqual(Set(seeds).count, 2, "Each reroll must land somewhere new")
    }

    // MARK: - Scene

    func testRegeneratingASceneRedrawsEveryPictureItOwns() async throws {
        let (harness, story) = try await generated(pageCount: 9)
        let scene = try XCTUnwrap(story.scenes.first { !$0.visualAssets.isEmpty })
        let before = harness.imageProvider.callCount

        let result = try await harness.orchestrator.regenerateScene(
            storyID: story.id, sceneID: scene.id, forceNewSeed: true
        )

        XCTAssertEqual(harness.imageProvider.callCount, before + scene.visualAssets.count)
        XCTAssertEqual(Set(result.affectedPageIDs), Set(scene.pageIDs))
    }

    func testRegeneratingASceneLeavesOtherScenesAlone() async throws {
        let (harness, story) = try await generated(pageCount: 9)
        let scene = try XCTUnwrap(story.scenes.first { !$0.visualAssets.isEmpty })
        let others = story.scenes.filter { $0.id != scene.id }

        let result = try await harness.orchestrator.regenerateScene(
            storyID: story.id, sceneID: scene.id, forceNewSeed: true
        )

        for original in others {
            let after = try XCTUnwrap(result.story.scene(id: original.id))
            XCTAssertEqual(after.visualAssets.map(\.imageRef), original.visualAssets.map(\.imageRef))
        }
    }

    func testUnknownSceneThrows() async throws {
        let (harness, story) = try await generated()
        let ghost = UUID()
        do {
            _ = try await harness.orchestrator.regenerateScene(storyID: story.id, sceneID: ghost)
            XCTFail("Expected sceneNotFound")
        } catch {
            XCTAssertEqual(error as? StoryEngineError, .sceneNotFound(ghost))
        }
    }

    // MARK: - Publication immutability

    func testAPublishedStoryRejectsOrdinaryWrites() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        XCTAssertTrue(published.publication.isPublished)

        XCTAssertThrowsError(
            try published.applying(StoryMutation(.setTitle("A new title")), at: StoryFixtures.referenceDate)
        ) { error in
            XCTAssertEqual(error as? StoryEngineError, .storyIsPublished(published.id))
        }
    }

    func testEvenAnExplicitOriginCannotRewriteStructure() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()

        // Regeneration is for text and pictures, not for replacing the book.
        XCTAssertThrowsError(
            try published.applying(
                StoryMutation(.setPages([]), origin: .explicitRegeneration),
                at: StoryFixtures.referenceDate
            )
        ) { error in
            XCTAssertEqual(error as? StoryEngineError, .storyIsPublished(published.id))
        }
    }

    func testExplicitRegenerationIsAllowedOnAPublishedStory() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        let page = published.pages[1]

        let updated = try published.applying(
            StoryMutation(
                .replacePageText(pageID: page.id, title: nil, text: "A gentler version of this page."),
                origin: .explicitRegeneration
            ),
            at: StoryFixtures.referenceDate
        )

        XCTAssertEqual(updated.page(id: page.id)?.text, "A gentler version of this page.")
        XCTAssertEqual(updated.page(id: page.id)?.textRevision, page.textRevision + 1)
        XCTAssertTrue(updated.publication.isPublished, "It stays published")
    }

    func testRegenerationChangesTheContentHash() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        let stamped = try XCTUnwrap(published.publication.contentHash)

        let updated = try published.applying(
            StoryMutation(
                .replacePageText(pageID: published.pages[0].id, title: nil, text: "Different words entirely."),
                origin: .explicitRegeneration
            ),
            at: StoryFixtures.referenceDate
        )

        XCTAssertNotEqual(updated.contentHash, stamped,
                          "The stamped hash now shows the book has moved on since publication")
    }

    func testPublishingStampsAMatchingContentHash() async throws {
        let (published, _, _) = try await StoryFixtures.publishedStory()
        XCTAssertEqual(published.publication.contentHash, published.contentHash)
    }

    func testAnUnpublishedStoryAcceptsOrdinaryWrites() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        let updated = try story.applying([.setTitle("Renamed")], at: StoryFixtures.referenceDate)
        XCTAssertEqual(updated.title, "Renamed")
    }

    func testRegeneratingThroughTheOrchestratorWorksOnAPublishedBook() async throws {
        let (harness, story) = try await generated()
        _ = try await harness.orchestrator.publish(storyID: story.id)

        // Generation already refined this page once, so the revision counter
        // is not starting from zero.
        let revisionBefore = story.pages[2].textRevision
        let updated = try await harness.orchestrator.regeneratePageText(storyID: story.id, pageID: story.pages[2].id)

        XCTAssertTrue(updated.publication.isPublished)
        XCTAssertEqual(updated.page(id: story.pages[2].id)?.textRevision, revisionBefore + 1)
    }
}
