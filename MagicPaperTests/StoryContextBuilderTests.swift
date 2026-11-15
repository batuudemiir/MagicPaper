import XCTest
import StoryEngine
@testable import MagicPaper

/// E2: the context a story is written from is gathered by one pure builder.
/// Behaviour does not change; the golden test rebuilds the old inline
/// calculation from `createStory` and asks for the same answer.
@MainActor
final class StoryContextBuilderTests: XCTestCase {

    private var usageSubdirectory: String!
    private var usageStore: StoryUsageStore!

    override func setUp() {
        super.setUp()
        usageSubdirectory = "StoryContextBuilderTests-\(UUID().uuidString)"
        usageStore = StoryUsageStore(subdirectory: usageSubdirectory)
    }

    override func tearDown() {
        StoryUsageStore.eraseAll(subdirectory: usageSubdirectory)
        super.tearDown()
    }

    // MARK: - Fixtures

    private let yeliz = UserProfile(name: "Yeliz", age: 6, profileType: .child, interests: ["animals", "space"])
    private let arda = UserProfile(name: "Arda", age: 8, profileType: .child)

    private func origin(_ tag: String, mode: StoryMode? = nil) -> StoryOrigin {
        var origin = StoryOrigin(seed: "s-\(tag)", blueprintID: "bp-\(tag)", settingID: "st-\(tag)",
                                 companionID: "c-\(tag)", discoveryID: "d-\(tag)",
                                 fingerprint: "f-\(tag)", catalogVersion: "v")
        origin.modeID = mode?.rawValue
        return origin
    }

    private func story(
        _ title: String, for profile: UserProfile?, legacyName: String? = nil,
        daysAgo: Double, origin: StoryOrigin? = nil
    ) -> MagicPaper.Story {
        var story = MagicPaper.Story(
            title: title, childName: profile?.name ?? legacyName ?? "",
            childProfileID: profile?.id, theme: .fantasy, language: .turkish, status: .completed)
        story.createdAt = Date(timeIntervalSince1970: 1_700_000_000 - daysAgo * 86_400)
        story.origin = origin
        return story
    }

    /// Two children, mixed dates, with and without origins, and one story
    /// from before profile ids that belongs to Yeliz by name.
    private func mixedLibrary() -> [MagicPaper.Story] {
        [
            story("Y-3", for: yeliz, daysAgo: 3, origin: origin("y3", mode: .bedtime)),
            story("A-1", for: arda, daysAgo: 1, origin: origin("a1", mode: .adventure)),
            story("Y-1", for: yeliz, daysAgo: 1, origin: origin("y1", mode: .learning)),
            story("Y-eski", for: nil, legacyName: "Yeliz", daysAgo: 10),
            story("Y-2", for: yeliz, daysAgo: 2),
            story("Y-5", for: yeliz, daysAgo: 5, origin: origin("y5", mode: .adventure)),
        ]
    }

    private func build(_ profile: UserProfile, _ library: [MagicPaper.Story],
                       mode: StoryMode? = .bedtime) -> StoryContext {
        StoryContextBuilder(usageStore: usageStore).build(
            for: profile, library: library, mode: mode, strategy: .direct,
            storyIdeaID: "idea", companionID: "comp", subOption: nil, family: nil)
    }

    // MARK: - Whose stories

    func testOnlyThisChildsStoriesEnterByIDAndOldOnesByName() {
        let context = build(yeliz, mixedLibrary())
        XCTAssertEqual(context.childStories.map(\.title), ["Y-3", "Y-1", "Y-eski", "Y-2", "Y-5"],
                       "Kitaplık sırası korunur; kardeşin masalı girmez.")
        XCTAssertEqual(build(arda, mixedLibrary()).childStories.map(\.title), ["A-1"])
    }

    // MARK: - Recent content

    func testRecentIsNewestFirstWindowedAndSkipsStoriesWithoutAnOrigin() {
        let context = build(yeliz, mixedLibrary())
        XCTAssertEqual(context.recent.map(\.seed), Array(["s-y1", "s-y3", "s-y5"].prefix(SelectionScoring.cooldownWindow)))

        let one = StoryContextBuilder.recentOrigins(of: mixedLibrary(), for: yeliz, limit: 1)
        XCTAssertEqual(one.map(\.seed), ["s-y1"])
    }

    func testRecentTitlesAreCappedAtTheTitleMemory() {
        let library = (0..<20).map { story("Masal \($0)", for: yeliz, daysAgo: Double($0)) }
        let context = build(yeliz, library)
        XCTAssertEqual(StoryGenerationManager.titleMemory, 12)
        XCTAssertEqual(context.recentTitles, Set((0..<12).map { "Masal \($0)" }))
    }

    func testRecentModesAreNewestFirst() {
        XCTAssertEqual(StoryContextBuilder.recentModes(of: mixedLibrary(), for: yeliz),
                       Array([StoryMode.learning, .bedtime, .adventure].prefix(StoryModeResolver.historyWindow)))
    }

    // MARK: - Profile

    func testInterestsAndProfileFieldsComeFromTheProfileAsTheyAre() {
        let context = build(yeliz, mixedLibrary())
        XCTAssertEqual(context.interests, ["animals", "space"])
        XCTAssertEqual(context.childName, "Yeliz")
        XCTAssertEqual(context.childProfileID, yeliz.id)
        XCTAssertEqual(context.age, 6)
        XCTAssertEqual(context.mode, .bedtime)
        XCTAssertEqual(context.strategy, .direct)
        XCTAssertEqual(context.storyIdeaID, "idea")
        XCTAssertEqual(context.companionID, "comp")
    }

    func testAnEmptyLibraryGivesAnEmptyContext() {
        let context = build(yeliz, [])
        XCTAssertTrue(context.childStories.isEmpty)
        XCTAssertTrue(context.recent.isEmpty)
        XCTAssertTrue(context.usage.isEmpty)
        XCTAssertTrue(context.recentTitles.isEmpty)
    }

    // MARK: - Privacy

    func testTheContextNeverPrintsTheChildOrTheText() {
        let context = build(yeliz, mixedLibrary())
        for text in [String(describing: context), String(reflecting: context), "\(context)"] {
            XCTAssertFalse(text.contains("Yeliz"))
            XCTAssertFalse(text.contains("animals"))
            XCTAssertFalse(text.contains("Y-1"))
        }
    }

    // MARK: - Golden: the old inline calculation

    /// `createStory` before E2, written out again here on purpose, field by
    /// field, against the same library and usage store.
    func testTheBuilderMatchesTheOldInlineCalculation() {
        let library = mixedLibrary()
        let read = library.first { $0.title == "Y-1" }!
        usageStore.recordSession(storyID: read.id, childID: yeliz.id, completions: 1, furthestPage: 3)

        let own = library.filter { $0.belongs(to: yeliz) }
        let oldRecent = Array(library
            .filter { $0.belongs(to: yeliz) }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap(\.origin)
            .prefix(SelectionScoring.cooldownWindow))
        let oldUsage = usageStore.usage(of: library.filter { $0.belongs(to: yeliz) }, for: yeliz.id)
        let oldTitles = Set(library
            .filter { $0.belongs(to: yeliz) }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(StoryGenerationManager.titleMemory)
            .map(\.title))

        let context = build(yeliz, library)

        XCTAssertEqual(context.childName, yeliz.name)
        XCTAssertEqual(context.age, yeliz.age)
        XCTAssertEqual(context.interests, yeliz.interests)
        XCTAssertEqual(context.recent, oldRecent)
        XCTAssertFalse(oldUsage.isEmpty, "Altın test kullanım verisini de karşılaştırmalı.")
        XCTAssertEqual(context.usage, oldUsage)
        XCTAssertEqual(context.recentTitles, oldTitles)
        // `Story ==` compares ids only; compare the ids and the text explicitly.
        XCTAssertEqual(context.childStories.map(\.id), own.map(\.id))
        XCTAssertEqual(context.childStories.map(\.title), own.map(\.title))
    }

    /// Same seed, same inputs: the context entry point and the old field by
    /// field call write the same book.
    func testComposingFromAContextWritesTheSameBookAsTheOldCall() throws {
        let service = OfflineStoryService.shared
        var context = build(yeliz, [], mode: .learning)
        context.storyIdeaID = nil
        context.companionID = nil

        let fromContext = try service.compose(context, seed: "e2-altin")
        let old = try service.compose(
            childName: yeliz.name, ideaID: nil, companionID: nil, mode: .learning, age: yeliz.age,
            seed: "e2-altin", subOption: nil, family: nil, interests: yeliz.interests,
            recent: [], usage: [], recentTitles: [])

        XCTAssertEqual(fromContext.story.fingerprint, old.story.fingerprint)
        XCTAssertEqual(fromContext.story.title, old.story.title)
        XCTAssertEqual(fromContext.seed, old.seed)
    }
}
