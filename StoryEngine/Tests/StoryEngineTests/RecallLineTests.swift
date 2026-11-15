import XCTest
@testable import StoryEngine

/// E3: the recall sentence is written by the engine, after the content is
/// bound, from catalog lines (`recall_lines_v1.json`), through the same
/// renderer and the same `isClean` gate as every other line.
final class RecallLineTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func intent(_ seed: String = "recall-seed-001", recall: RecallHistory? = nil) -> OfflineStoryIntent {
        OfflineStoryIntent(childName: "Yeliz", seed: seed, mode: .adventure,
                           ageBand: AgeBand(lowerBound: 5, upperBound: 6), recall: recall)
    }

    private func compose(_ intent: OfflineStoryIntent, in catalog: ContentCatalog) throws -> ComposedStory {
        try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
    }

    private func line(_ id: ContentID?, in catalog: ContentCatalog) throws -> CatalogRecallLine {
        let id = try XCTUnwrap(id, "No recall line was written.")
        return try XCTUnwrap(catalog.recallLines.first { $0.id == id })
    }

    // MARK: - No cue, no change

    /// Without a history, and with one that names nothing in this story, the
    /// book is the book it was before E3: same text, same lines, same
    /// fingerprint. The pinned literals in `OfflineDeterminismTests` hold the
    /// same promise across processes; they pass no history.
    func testWithoutACueTheBookIsBitForBitTheSame() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let empty = try compose(intent(recall: RecallHistory()), in: catalog)
        let unrelated = try compose(intent(recall: RecallHistory(
            companions: [ContentID("companion_not_in_this_story"): .init(storyCount: 5, firstSettingID: "nowhere")],
            visitedSettings: [ContentID("setting_not_in_this_story")])), in: catalog)

        for other in [empty, unrelated] {
            XCTAssertNil(other.recallLineID)
            XCTAssertEqual(other.fingerprint, plain.fingerprint)
            XCTAssertEqual(other.pages.map(\.text), plain.pages.map(\.text))
            XCTAssertEqual(other.pages.map(\.variantIDs), plain.pages.map(\.variantIDs))
            XCTAssertEqual(other.title, plain.title)
        }
        XCTAssertNil(plain.recallLineID)
    }

    // MARK: - Tiers

    private func companionHistory(_ count: Int, firstSetting: ContentID, for story: ComposedStory) -> RecallHistory {
        RecallHistory(
            companions: [story.content.companion.id: .init(storyCount: count, firstSettingID: firstSetting)],
            visitedSettings: [firstSetting])
    }

    func testEachCompanionTierWritesALineOfThatTier() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let here = plain.content.setting.id

        for (count, tier) in [(1, RecallTier.metOnce), (2, .friends), (3, .friends), (4, .oldFriends), (9, .oldFriends)] {
            let story = try compose(intent(recall: companionHistory(count, firstSetting: here, for: plain)), in: catalog)
            let chosen = try line(story.recallLineID, in: catalog)
            XCTAssertEqual(chosen.tier, tier, "\(count) masal")
            XCTAssertNotEqual(chosen.firstMet, .elsewhere, "Aynı yerde tanıştılar; 'başka yer' satırı seçilmemeli.")
        }
    }

    func testMeetingElsewhereNamesThatPlace() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let other = try XCTUnwrap(catalog.settings.first { $0.id != plain.content.setting.id })

        let story = try compose(intent(recall: companionHistory(4, firstSetting: other.id, for: plain)), in: catalog)
        let chosen = try line(story.recallLineID, in: catalog)
        XCTAssertEqual(chosen.tier, .oldFriends)
        XCTAssertNotEqual(chosen.firstMet, .here)
        if chosen.firstMet == .elsewhere {
            XCTAssertTrue(story.pages[0].text.contains(other.name), story.pages[0].text)
        }
    }

    func testAPlaceVisitedBeforeWritesAPlaceLine() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let story = try compose(intent(recall: RecallHistory(visitedSettings: [plain.content.setting.id])), in: catalog)
        XCTAssertEqual(try line(story.recallLineID, in: catalog).tier, .placeAgain)
    }

    // MARK: - Where it goes

    /// Page 1, its own paragraph, clean, its id last among the page's lines.
    /// Every other page is untouched, and the fingerprint now carries it.
    func testTheLineClosesPageOneAndPassesTheCleanGate() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let story = try compose(intent(recall: companionHistory(1, firstSetting: plain.content.setting.id, for: plain)), in: catalog)
        let id = try XCTUnwrap(story.recallLineID)

        XCTAssertTrue(story.isClean)
        XCTAssertTrue(story.pages[0].text.hasPrefix(plain.pages[0].text + "\n\n"))
        XCTAssertFalse(story.pages[0].text.contains("{{"))
        XCTAssertEqual(story.pages[0].variantIDs, plain.pages[0].variantIDs + [id])
        XCTAssertEqual(story.pages.dropFirst().map(\.text), plain.pages.dropFirst().map(\.text))
        XCTAssertNotEqual(story.fingerprint, plain.fingerprint)
        XCTAssertEqual(story.seed, plain.seed)
    }

    func testTheSameHistoryWritesTheSameLine() throws {
        let catalog = try catalog()
        let plain = try compose(intent(), in: catalog)
        let history = companionHistory(2, firstSetting: plain.content.setting.id, for: plain)
        let first = try compose(intent(recall: history), in: catalog)
        let again = try compose(intent(recall: history), in: catalog)
        XCTAssertEqual(first.recallLineID, again.recallLineID)
        XCTAssertEqual(first.pages[0].text, again.pages[0].text)
    }

    // MARK: - Choosing the line

    private func boundContent() throws -> (ContentCatalog, ComposedStory) {
        let catalog = try catalog()
        return (catalog, try compose(intent(), in: catalog))
    }

    /// A line used in the child's recent stories is not used again while
    /// another serves.
    func testARecentLineIsNotWrittenAgain() throws {
        let (catalog, plain) = try boundContent()
        let history = companionHistory(2, firstSetting: plain.content.setting.id, for: plain)
        let slots = OfflineStoryComposer.slots(childName: "Yeliz", content: plain.content)
        func pick(_ recent: [Set<ContentID>]) -> ContentID? {
            RecallComposer.line(history: history, content: plain.content, catalog: catalog,
                                band: AgeBand(lowerBound: 5, upperBound: 6), slots: slots,
                                recent: recent, seed: "cool")?.id
        }
        let first = try XCTUnwrap(pick([]))
        let second = try XCTUnwrap(pick([[first]]))
        XCTAssertNotEqual(second, first)
        let third = try XCTUnwrap(pick([[second], [], [first]]))
        XCTAssertFalse([first, second].contains(third), "Pencere içindeki satırlar soğumalı.")
    }

    /// A line that cannot be filled drops the recall, never the story.
    func testALineThatCannotBeFilledDropsTheRecall() throws {
        let (catalog, plain) = try boundContent()
        let broken = ContentCatalog(version: "test", settings: catalog.settings, recallLines: [
            CatalogRecallLine(id: "recall_broken", tier: .placeAgain, text: "{{family.name}} burayı tanıdı.")
        ])
        let picked = RecallComposer.line(
            history: RecallHistory(visitedSettings: [plain.content.setting.id]),
            content: plain.content, catalog: broken, band: nil,
            slots: OfflineStoryComposer.slots(childName: "Yeliz", content: plain.content),
            recent: [], seed: "s")
        XCTAssertNil(picked)
    }

    /// The child's name is required: an empty one leaves the slot unfilled
    /// and the recall is dropped, as `StoryMemory` did.
    func testAnEmptyChildNameDropsTheRecall() throws {
        let (catalog, plain) = try boundContent()
        let picked = RecallComposer.line(
            history: RecallHistory(visitedSettings: [plain.content.setting.id]),
            content: plain.content, catalog: catalog, band: AgeBand(lowerBound: 5, upperBound: 6),
            slots: OfflineStoryComposer.slots(childName: "", content: plain.content),
            recent: [], seed: "s")
        XCTAssertNil(picked)
    }

    /// A first place the catalog no longer has: only lines that do not name it.
    func testAnUnknownFirstPlaceUsesOnlyLinesThatDoNotNameIt() throws {
        let (catalog, plain) = try boundContent()
        let history = companionHistory(1, firstSetting: "setting_removed_from_catalog", for: plain)
        let cue = try XCTUnwrap(RecallComposer.cue(history: history, content: plain.content, catalog: catalog))
        XCTAssertEqual(cue.firstMet, .elsewhere)
        let pool = RecallComposer.pool(for: cue, band: AgeBand(lowerBound: 5, upperBound: 6), in: catalog.recallLines)
        XCTAssertFalse(pool.isEmpty)
        XCTAssertTrue(pool.allSatisfy { $0.firstMet == nil })
    }

    /// The 3-4 band has short lines of its own and uses only those.
    func testTheYoungestBandUsesItsOwnLines() throws {
        let (catalog, plain) = try boundContent()
        let cue = try XCTUnwrap(RecallComposer.cue(
            history: RecallHistory(visitedSettings: [plain.content.setting.id]),
            content: plain.content, catalog: catalog))
        let young = RecallComposer.pool(for: cue, band: AgeBand(lowerBound: 3, upperBound: 4), in: catalog.recallLines)
        XCTAssertGreaterThanOrEqual(young.count, 4)
        XCTAssertTrue(young.allSatisfy { $0.ageBand == AgeBand(lowerBound: 3, upperBound: 4) })
        let older = RecallComposer.pool(for: cue, band: AgeBand(lowerBound: 7, upperBound: 8), in: catalog.recallLines)
        XCTAssertTrue(older.allSatisfy { $0.ageBand == nil })
    }

    // MARK: - Catalog

    func testTheShippedRecallLinesPassTheirChecks() throws {
        let catalog = try catalog()
        XCTAssertFalse(catalog.recallLines.isEmpty, "recall_lines_v1.json yüklenmedi.")
        let issues = CatalogIntegrityChecker().checkRecallLines(catalog)
        XCTAssertTrue(issues.isEmpty, issues.map(\.message).joined(separator: "\n"))
        for tier in RecallTier.allCases {
            XCTAssertGreaterThanOrEqual(catalog.recallLines.filter { $0.tier == tier && $0.ageBand == nil }.count, 4,
                                        "\(tier.rawValue) için en az dört çeşit.")
        }
    }

    func testTheShippedLinesKeepTheLanguageRules() throws {
        let banned = ["—", "hemen", "anında", "üret", "oluştur", "yapay zeka", " sen ", " seni ", " sana "]
        for line in try catalog().recallLines {
            for word in banned {
                XCTAssertFalse(line.text.lowercased(with: Locale(identifier: "tr_TR")).contains(word.lowercased()),
                               "\(line.id): '\(word)'")
            }
        }
    }

    func testTheCheckerReportsBrokenLines() {
        let catalog = ContentCatalog(version: "test", recallLines: [
            CatalogRecallLine(id: "a", tier: .placeAgain, text: "{{discovery.name}} burada."),
            CatalogRecallLine(id: "b", tier: .metOnce, firstMet: .elsewhere, text: "{{child.name}} tanıdı."),
            CatalogRecallLine(id: "c", tier: .friends, firstMet: .here, text: "{{recall.place.name}}'da."),
            CatalogRecallLine(id: "c", tier: .placeAgain, firstMet: .here, text: "{{child.name}}."),
        ])
        let codes = Set(CatalogIntegrityChecker().checkRecallLines(catalog).map(\.code))
        XCTAssertTrue(codes.isSuperset(of: [
            "recall_unknown_slot", "recall_place_slot", "duplicate_id", "recall_place_first_met", "recall_tier_gap"
        ]), "\(codes)")
    }

    func testACatalogWithoutRecallLinesHasNothingToCheck() {
        XCTAssertTrue(CatalogIntegrityChecker().checkRecallLines(ContentCatalog(version: "old")).isEmpty)
    }
}
