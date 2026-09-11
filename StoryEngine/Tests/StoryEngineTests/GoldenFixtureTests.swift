import XCTest
import CharacterEngine
import EngineFoundation
import VisualSystem
@testable import StoryEngine

/// A snapshot of everything the engine decides without asking a model.
///
/// The unit tests say each deterministic stage is correct in isolation. This
/// says the whole deterministic chain still produces what it produced before —
/// which is the thing a refactor quietly changes. A diff here is not
/// necessarily a bug, but it is always a decision: regenerate the fixture on
/// purpose and say in the commit why the behaviour moved.
struct GoldenFixture: Codable, Equatable {
    struct Beat: Codable, Equatable {
        let ordinal: Int
        let templateBeatID: String
        let role: String
        let settingKey: String
        let timeOfDayKey: String
        let moodKey: String
    }

    struct Page: Codable, Equatable {
        let index: Int
        let templateBeatID: String
        let beatRole: String
        let layout: String
        let layoutRuleID: String
        let compositionRuleID: String
        let typographyPresetID: String
        let minimumWords: Int
        let maximumWords: Int
        let sceneIndex: Int
        /// Word count, not the prose itself: the words come from a model and
        /// are not expected to be byte-identical.
        let segmentedWordCount: Int
    }

    struct Scene: Codable, Equatable {
        let index: Int
        let settingKey: String
        let timeOfDayKey: String
        let moodKey: String
        let castNames: [String]
        let signatureFingerprint: String
        let pageIndices: [Int]
        let assetFingerprints: [String]
        let assetSeeds: [UInt64]
    }

    struct Constraints: Codable, Equatable {
        let sceneIndex: Int
        let aspectRatio: String
        let identityClauses: [String]
        let compositionClauses: [String]
        let negativeClauseCount: Int
        let provenance: [String]
    }

    let name: String
    let templateID: String
    let templateVersion: String
    let requestedPageCount: Int
    let effectivePageCount: Int
    let beats: [Beat]
    let pages: [Page]
    let scenes: [Scene]
    let constraints: [Constraints]
}

final class GoldenFixtureTests: XCTestCase {

    /// Set to true, run once, set back to false. Do not leave it on.
    private let regenerateFixtures = false

    // MARK: - The cases

    func testSingleCharacterStory() throws {
        try assertMatchesGolden(name: "adventure_child_01", pageCount: 7)
    }

    func testMultiCharacterStory() throws {
        let cast = StoryFixtures.cast(
            StoryFixtures.resolvedCharacter(name: "Deniz"),
            supporting: [StoryFixtures.resolvedCharacter(name: "Pamuk", role: .companion, identitySeed: 11)]
        )
        try assertMatchesGolden(name: "two_character_01", pageCount: 9, cast: cast)
    }

    func testShortStory() throws {
        try assertMatchesGolden(name: "bedtime_child_01", pageCount: 5)
    }

    func testMaximumSupportedPageCount() throws {
        try assertMatchesGolden(name: "adventure_max_pages_01", pageCount: 16)
    }

    func testSceneReuseShape() throws {
        // Every beat in one place: the whole book should collapse to one scene
        // and therefore one illustration.
        let template = StoryFixtures.template(
            id: "one_room",
            beats: [
                StoryFixtures.beat(id: "a", role: .opening, setting: "attic"),
                StoryFixtures.beat(id: "b", role: .middle, repeatable: true, setting: "attic"),
                StoryFixtures.beat(id: "c", role: .closing, setting: "attic")
            ],
            pageRange: 3...8
        )
        try assertMatchesGolden(name: "scene_reuse_01", pageCount: 6, template: template)
    }

    func testPartialTextRegenerationLeavesTheRestUntouched() throws {
        let planned = try plan(pageCount: 7)
        let before = try fixture(name: "regeneration_01", planned: planned, pageCount: 7)

        // A regenerated page changes its own words and nothing structural.
        var pages = planned.pages
        pages[2].text = "Completely different words on this page entirely, and a few more besides."
        pages[2].textRevision += 1

        let after = try fixture(
            name: "regeneration_01",
            planned: StoryFixtures.PlannedStory(
                template: planned.template, outline: planned.outline,
                scenes: planned.scenes, pages: pages, characters: planned.characters
            ),
            pageCount: 7
        )

        XCTAssertEqual(after.scenes, before.scenes, "Rewriting a page must not move a scene")
        XCTAssertEqual(after.constraints, before.constraints, "Nor change any illustration")
        XCTAssertEqual(
            after.pages.filter { $0.index != 2 },
            before.pages.filter { $0.index != 2 },
            "Nor disturb its neighbours"
        )
        XCTAssertNotEqual(after.pages[2].segmentedWordCount, before.pages[2].segmentedWordCount)

        try assertMatches(golden: before, name: "regeneration_01")
    }

    func testImageRegenerationChangesOnlyTheSeedOfOneAsset() throws {
        let planned = try plan(pageCount: 7)
        let scenes = try planAssets(planned)
        let original = try XCTUnwrap(scenes.first?.visualAssets.first)

        let rerolled = try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 6_000)).recompile(
            asset: original,
            scene: scenes[0],
            characters: planned.characters,
            template: planned.template,
            storyID: Self.storyID,
            seedPolicy: .deterministic,
            forceNewSeed: true
        )

        XCTAssertNotEqual(rerolled.promptSnapshot?.seed, original.promptSnapshot?.seed)
        XCTAssertNotEqual(rerolled.fingerprint, original.fingerprint)
        XCTAssertEqual(
            rerolled.promptSnapshot?.identityClauses, original.promptSnapshot?.identityClauses,
            "A reroll must not change who the child is"
        )
        XCTAssertEqual(rerolled.promptSnapshot?.compositionClauses, original.promptSnapshot?.compositionClauses)
        XCTAssertEqual(rerolled.revision, original.revision + 1)

        // Other scenes are untouched.
        for scene in scenes.dropFirst() {
            for asset in scene.visualAssets {
                XCTAssertNotEqual(asset.fingerprint, rerolled.fingerprint)
            }
        }
    }

    func testSafetyRejectionShape() throws {
        // A request the product refuses. The rejection has to be deterministic
        // too, or a banned theme could slip through on a retry.
        let gate = ChildSafetyGate(policy: .strict)
        let request = StoryFixtures.request(themeKey: "how to kill a dragon")

        let first = gate.checkInput(request: request, template: StoryFixtures.adventureTemplate)
        let second = gate.checkInput(request: request, template: StoryFixtures.adventureTemplate)

        XCTAssertEqual(first.map(\.code), second.map(\.code))
        XCTAssertEqual(first.map(\.code), ["unsafe_input"])
        XCTAssertEqual(first.map(\.severity), [.error])
        XCTAssertTrue(gate.shouldRefuseInput(first))
    }

    // MARK: - Building and comparing

    static let storyID = UUID(uuidString: "F0F0F0F0-0000-0000-0000-000000000001")!

    private func plan(
        pageCount: Int,
        template: StoryTemplate? = nil,
        cast: ResolvedCast? = nil
    ) throws -> StoryFixtures.PlannedStory {
        try StoryFixtures.plannedStory(
            template: template,
            pageCount: pageCount,
            characters: StoryFixtures.storyCharacters(cast ?? StoryFixtures.cast()),
            // Fixed generator, so ids are identical between runs.
            ids: SequentialIDGenerator(startingAt: 1)
        )
    }

    private func planAssets(_ planned: StoryFixtures.PlannedStory) throws -> [StoryScene] {
        try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 5_000)).planAssets(
            scenes: planned.scenes,
            pages: planned.pages,
            characters: planned.characters,
            template: planned.template,
            storyID: Self.storyID,
            seedPolicy: .deterministic
        )
    }

    /// Runs the deterministic chain and captures what it decided.
    private func fixture(
        name: String,
        planned: StoryFixtures.PlannedStory,
        pageCount: Int
    ) throws -> GoldenFixture {
        let scenes = try planAssets(planned)
        let sceneIndexByID = Dictionary(uniqueKeysWithValues: scenes.map { ($0.id, $0.index) })
        let pages = VisualPlanner().assigning(
            pages: planned.pages, to: scenes,
            policy: planned.template.template.sceneRules.visualPolicy
        )

        let beatPlan = try BeatPlanner().plan(
            template: planned.template.template, requestedPageCount: pageCount
        )

        return GoldenFixture(
            name: name,
            templateID: planned.template.template.id,
            templateVersion: planned.template.template.version.description,
            requestedPageCount: pageCount,
            effectivePageCount: beatPlan.effectivePageCount,
            beats: planned.outline.beats.sorted { $0.ordinal < $1.ordinal }.map {
                GoldenFixture.Beat(
                    ordinal: $0.ordinal, templateBeatID: $0.templateBeatID, role: $0.role.rawValue,
                    settingKey: $0.settingKey, timeOfDayKey: $0.timeOfDayKey, moodKey: $0.moodKey
                )
            },
            pages: pages.sorted { $0.index < $1.index }.map {
                GoldenFixture.Page(
                    index: $0.index, templateBeatID: $0.templateBeatID, beatRole: $0.beatRole.rawValue,
                    layout: $0.layout.rawValue, layoutRuleID: $0.layoutRuleID,
                    compositionRuleID: $0.compositionRuleID, typographyPresetID: $0.typographyPresetID,
                    minimumWords: $0.minimumWords, maximumWords: $0.maximumWords,
                    sceneIndex: sceneIndexByID[$0.sceneID] ?? -1,
                    segmentedWordCount: $0.wordCount
                )
            },
            scenes: scenes.map { scene in
                GoldenFixture.Scene(
                    index: scene.index,
                    settingKey: scene.signature.settingKey,
                    timeOfDayKey: scene.signature.timeOfDayKey,
                    moodKey: scene.signature.moodKey,
                    castNames: scene.signature.castNames,
                    signatureFingerprint: scene.fingerprint,
                    pageIndices: pages.filter { $0.sceneID == scene.id }.map(\.index).sorted(),
                    assetFingerprints: scene.visualAssets.map(\.fingerprint),
                    assetSeeds: scene.visualAssets.compactMap { $0.promptSnapshot?.seed }
                )
            },
            constraints: scenes.compactMap { scene in
                guard let snapshot = scene.visualAssets.first?.promptSnapshot else { return nil }
                return GoldenFixture.Constraints(
                    sceneIndex: scene.index,
                    aspectRatio: snapshot.aspectRatio.rawValue,
                    identityClauses: snapshot.identityClauses,
                    compositionClauses: snapshot.compositionClauses,
                    negativeClauseCount: snapshot.negativeClauses.count,
                    provenance: snapshot.provenance
                )
            }
        )
    }

    private func assertMatchesGolden(
        name: String,
        pageCount: Int,
        template: StoryTemplate? = nil,
        cast: ResolvedCast? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let planned = try plan(pageCount: pageCount, template: template, cast: cast)
        let produced = try fixture(name: name, planned: planned, pageCount: pageCount)
        try assertMatches(golden: produced, name: name, file: file, line: line)
    }

    private func assertMatches(
        golden produced: GoldenFixture,
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(produced)
        let url = Self.fixturesDirectory.appendingPathComponent("\(name).json")

        guard !regenerateFixtures else {
            try FileManager.default.createDirectory(at: Self.fixturesDirectory, withIntermediateDirectories: true)
            try data.write(to: url)
            XCTFail("Fixtures were regenerated. Set regenerateFixtures back to false and review the diff.", file: file, line: line)
            return
        }

        guard let stored = try? Data(contentsOf: url) else {
            XCTFail(
                "No golden fixture at \(url.lastPathComponent). Set regenerateFixtures = true, run once, review the diff.",
                file: file, line: line
            )
            return
        }

        let expected = try JSONDecoder().decode(GoldenFixture.self, from: stored)
        guard produced != expected else { return }

        XCTFail(
            """
            Deterministic engine behaviour changed for '\(name)'.

            If this was intentional, set regenerateFixtures = true, run once, set it back, \
            and explain in the commit why the behaviour moved.

            \(Self.describeDifference(expected: expected, produced: produced))
            """,
            file: file, line: line
        )
    }

    /// Names what moved, rather than dumping two large JSON blobs.
    private static func describeDifference(expected: GoldenFixture, produced: GoldenFixture) -> String {
        var lines: [String] = []
        if expected.effectivePageCount != produced.effectivePageCount {
            lines.append("page count: \(expected.effectivePageCount) → \(produced.effectivePageCount)")
        }
        if expected.beats != produced.beats {
            lines.append("beats: \(expected.beats.map(\.templateBeatID)) → \(produced.beats.map(\.templateBeatID))")
        }
        for (old, new) in zip(expected.pages, produced.pages) where old != new {
            lines.append("page \(old.index): layout \(old.layout)/\(old.layoutRuleID) → \(new.layout)/\(new.layoutRuleID), scene \(old.sceneIndex) → \(new.sceneIndex), words \(old.segmentedWordCount) → \(new.segmentedWordCount)")
        }
        if expected.scenes.count != produced.scenes.count {
            lines.append("scene count: \(expected.scenes.count) → \(produced.scenes.count)")
        }
        for (old, new) in zip(expected.scenes, produced.scenes) where old != new {
            lines.append("scene \(old.index): pages \(old.pageIndices) → \(new.pageIndices), fingerprints \(old.assetFingerprints) → \(new.assetFingerprints)")
        }
        for (old, new) in zip(expected.constraints, produced.constraints) where old != new {
            lines.append("constraints for scene \(old.sceneIndex): identity \(old.identityClauses) → \(new.identityClauses)")
        }
        return lines.isEmpty ? "(difference is in a field not summarised here)" : lines.joined(separator: "\n")
    }

    private static var fixturesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }
}
