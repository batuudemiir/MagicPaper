import XCTest
@testable import StoryEngine

/// FAZ 13: a liked story continues as four more episodes.
///
/// The first story is composed the way the app composes it; the series is
/// planned from what that story bound, as the app plans it from the origin.
final class SeriesPlannerTests: XCTestCase {

    private static let age3 = AgeBand(lowerBound: 3, upperBound: 4)
    private static let age5 = AgeBand(lowerBound: 5, upperBound: 6)

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func sister(_ catalog: ContentCatalog) -> FamilyCast {
        FamilyCast(name: "Ela", relation: .sibling)
    }

    /// The first story, as `createStory` would write it.
    ///
    /// A bedtime first story is the kind saved before the bedtime arc (21 Ekim
    /// 2026): a charge story in a garden or a forest, continued with standard
    /// episodes. A story that opened in a bedroom continues with bedtime-arc
    /// episodes (`testABedtimeArcStoryContinuesInItsBedroom`).
    private func firstStory(
        mode: StoryMode, band: AgeBand, seed: String, family: FamilyCast? = nil,
        catalog: ContentCatalog
    ) throws -> ComposedStory {
        let intent = OfflineStoryIntent(
            childName: "Yeliz", seed: seed, mode: mode, ageBand: band, family: family)
        guard mode == .bedtime else {
            return try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
        }
        let saved = catalog.blueprints.filter {
            $0.isBeatAuthored && $0.family == .charge && $0.arc == .standard && $0.ageRange == band
        }
        let blueprint = try XCTUnwrap(saved.isEmpty ? nil : saved[DeterministicPicker.index(
            count: saved.count, seed: seed, salt: "saved-bedtime")])
        return try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent)
    }

    private func anchor(_ story: ComposedStory) -> SeriesAnchor {
        SeriesAnchor(
            settingID: story.content.setting.id,
            companionID: story.content.companion.id,
            keepsakeID: story.content.discovery.id)
    }

    private func plan(
        mode: StoryMode, band: AgeBand, seed: String, family: FamilyCast? = nil,
        catalog: ContentCatalog
    ) throws -> SeriesPlanner.Result {
        let first = try firstStory(mode: mode, band: band, seed: seed, family: family, catalog: catalog)
        return try SeriesPlanner().plan(
            anchor: anchor(first), mode: mode, band: band, family: family,
            familyCharacterID: family == nil ? nil : "family-1", childName: "Yeliz",
            seed: SeriesPlanner.seed(storySeed: first.seed, fingerprint: first.fingerprint),
            catalog: catalog)
    }

    /// Every mode a band can write a first story in **and continue**, with a
    /// few seeds.
    ///
    /// Devam edilebilirlik süzgeci 22 Ekim 2026'da eklendi. O gün `charge`
    /// "Yeni şeyler öğrenelim"e eklenince öğrenelim 3-4'te açıldı, ama o
    /// kesit için yazılmış devam blueprint'i yok: tarama her modu gezdiği için
    /// on test birden, sınadıkları şeyle ilgisiz bir sebepten kırmızıya düştü.
    ///
    /// Uygulama bu boşluktan etkilenmiyor — "Devam ettir" düğmesi
    /// `SeriesPlanner.isAvailable` ile kapılı, yani o masalda hiç görünmüyor.
    /// Boşluğun kendisi `testWhichSectionsHaveNoSeriesYet` ile kayıtlı.
    private func canContinue(_ mode: StoryMode, _ band: AgeBand, _ catalog: ContentCatalog) -> Bool {
        guard let first = try? firstStory(mode: mode, band: band, seed: "s1", catalog: catalog)
        else { return false }
        return SeriesPlanner.isAvailable(
            settingID: first.content.setting.id, mode: mode, band: band, catalog: catalog)
    }

    private func cases(_ catalog: ContentCatalog) -> [(StoryMode, AgeBand, String)] {
        let selector = BlueprintSelector()
        return [Self.age3, Self.age5].flatMap { band in
            selector.availableModes(catalog: catalog, ageBand: band)
                .filter { canContinue($0, band, catalog) }
                .flatMap { mode in ["s1", "s2", "s3", "s4", "s5"].map { (mode, band, $0) } }
        }
    }

    /// Hangi kesitlerde seri henüz yok.
    ///
    /// Eşitlik iddiası bilerek: devam içeriği yazıldığında bu test kırılır ve
    /// kıran kişiye "bir kesit daha devam edebiliyor, kaydı güncelle" der.
    func testWhichSectionsHaveNoSeriesYet() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        var without: [String] = []
        for band in [Self.age3, Self.age5] {
            for mode in selector.availableModes(catalog: catalog, ageBand: band)
            where !canContinue(mode, band, catalog) {
                without.append("\(mode.rawValue) \(band)")
            }
        }
        // 22 Ekim 2026: öğrenelim 3-4 aynı gün açıldı, devam içeriği yok.
        XCTAssertEqual(without.sorted(), ["learning 3-4"])
    }

    // MARK: - Determinism

    func testTheSameStoryAndSeedPlanTheSameSeries() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            let a = try plan(mode: mode, band: band, seed: seed, catalog: catalog)
            let b = try plan(mode: mode, band: band, seed: seed, catalog: catalog)
            XCTAssertEqual(a.plan, b.plan, "\(mode) \(band) \(seed)")
            XCTAssertEqual(a.episodes.map(\.fingerprint), b.episodes.map(\.fingerprint))
            XCTAssertEqual(a.episodes.flatMap { $0.pages.map(\.text) },
                           b.episodes.flatMap { $0.pages.map(\.text) })
        }
    }

    func testAPlanRoundTripsAndComposesTheSameText() throws {
        let catalog = try catalog()
        let result = try plan(mode: .learning, band: Self.age5, seed: "s1", family: sister(catalog), catalog: catalog)
        let decoded = try JSONDecoder().decode(SeriesPlan.self, from: JSONEncoder().encode(result.plan))
        XCTAssertEqual(decoded, result.plan)
        let again = try SeriesPlanner().compose(
            decoded, childName: "Yeliz", family: sister(catalog), catalog: catalog)
        XCTAssertEqual(again.map { $0.pages.map(\.text) }, result.episodes.map { $0.pages.map(\.text) })
    }

    func testDifferentStoriesContinueDifferently() throws {
        let catalog = try catalog()
        let plans = try ["s1", "s2", "s3", "s4", "s5"].map {
            try plan(mode: .learning, band: Self.age5, seed: $0, catalog: catalog).plan
        }
        XCTAssertGreaterThan(Set(plans.map(\.episodes)).count, 1)
    }

    // MARK: - Shape

    func testEverySeriesHasFourEpisodesInOnePlaceWithOneFriend() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            let result = try plan(mode: mode, band: band, seed: seed, catalog: catalog)
            XCTAssertEqual(result.plan.episodes.map(\.number), [2, 3, 4, 5])
            XCTAssertEqual(result.episodes.count, 4)
            for story in result.episodes {
                XCTAssertEqual(story.content.setting.id, result.plan.anchor.settingID)
                XCTAssertEqual(story.content.companion.id, result.plan.anchor.companionID)
                XCTAssertNotEqual(story.content.discovery.id, result.plan.anchor.keepsakeID,
                                  "the keepsake is remembered, never found again")
                XCTAssertEqual(story.pages.count, band.pageCount)
                XCTAssertTrue(story.isClean, "\(story.blueprintID): \(story.pages.map(\.missingSlots))")
            }
            let discoveries = result.plan.episodes.map(\.discoveryID)
            for (a, b) in zip(discoveries, discoveries.dropFirst()) {
                XCTAssertNotEqual(a, b, "the same discovery two episodes in a row")
            }
        }
    }

    /// Episodes of one series do not read alike. The same blueprint returns
    /// every other episode, so its pages are where a repeat would show.
    func testEpisodesOfOneSeriesDoNotRepeatEachOther() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            let episodes = try plan(mode: mode, band: band, seed: seed, catalog: catalog).episodes
            for (a, b) in [(0, 2), (1, 3)] {
                let shared = zip(episodes[a].pages, episodes[b].pages).filter { $0.text == $1.text }
                XCTAssertTrue(shared.isEmpty, "\(mode) \(band) \(seed): episodes \(a + 2) and \(b + 2) share "
                              + shared.map { "page \($0.0.pageNumber)" }.joined(separator: ", "))
            }
        }
    }

    /// A discovery comes back only when this place cannot give four new
    /// ones: then the search allowing none must have failed.
    func testADiscoveryComesBackOnlyWhenItMust() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            let result = try plan(mode: mode, band: band, seed: seed, catalog: catalog)
            let found = result.plan.episodes.map(\.discoveryID)
            guard Set(found).count < found.count else { continue }
            // Repeats happened: no four distinct discoveries can fill this
            // series' blueprints in this place.
            let setting = try XCTUnwrap(catalog.setting(result.plan.anchor.settingID))
            let candidates = catalog.objects.filter {
                $0.id != result.plan.anchor.keepsakeID && !$0.traits.isEmpty
                    && ($0.habitat.isEmpty || !$0.habitat.isDisjoint(with: setting.habitat))
                    && $0.explainedBy.isDisjoint(with: setting.traits)
            }
            // Each episode's options; is there a choice of four different ones?
            let options: [[ContentID]] = result.plan.episodes.map { episode in
                let blueprint = catalog.series.continuation(episode.blueprintID)!
                return candidates.filter { object in
                    blueprint.requires.discovery.isSatisfied(by: object.traits)
                        && blueprint.forbids.discovery.isDisjoint(with: object.traits)
                }.map(\.id)
            }
            func distinct(_ index: Int, _ taken: Set<ContentID>) -> Bool {
                guard index < options.count else { return true }
                return options[index].contains { !taken.contains($0) && distinct(index + 1, taken.union([$0])) }
            }
            XCTAssertFalse(distinct(0, []),
                           "\(mode) \(band) \(seed) repeated a discovery it did not have to: \(found.map(\.rawValue))")
        }
    }

    func testTwoMechanismsAlternate() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            let ids = try plan(mode: mode, band: band, seed: seed, catalog: catalog).plan.episodes.map(\.blueprintID)
            XCTAssertEqual(ids[0], ids[2], "\(mode) \(band)")
            XCTAssertEqual(ids[1], ids[3], "\(mode) \(band)")
            XCTAssertNotEqual(ids[0], ids[1], "\(mode) \(band): A-B-A-B")
        }
    }

    func testEveryEpisodeOpensByComingBack() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            for story in try plan(mode: mode, band: band, seed: seed, catalog: catalog).episodes {
                XCTAssertEqual(story.pages.first?.beats.first, .revisit)
            }
        }
    }

    func testOnlyContinuationsWriteEpisodesAndOnlyEpisodesSeeThem() throws {
        let catalog = try catalog()
        XCTAssertFalse(catalog.series.continuations.isEmpty)
        let continuationIDs = Set(catalog.series.continuations.map(\.id))
        XCTAssertTrue(continuationIDs.isDisjoint(with: catalog.blueprints.map(\.id)))
        XCTAssertTrue(catalog.blueprints.allSatisfy { $0.continuation == nil })
        let seriesTemplateIDs = Set(catalog.series.templates.map(\.id))
        XCTAssertTrue(seriesTemplateIDs.isDisjoint(with: catalog.templates.map(\.id)))
        // A standalone story is written only from standalone lines.
        let seriesVariants = Set(catalog.series.templates.flatMap(\.variants).map(\.id))
        for (mode, band, seed) in cases(catalog) {
            let story = try firstStory(mode: mode, band: band, seed: seed, catalog: catalog)
            XCTAssertFalse(continuationIDs.contains(story.blueprintID))
            XCTAssertTrue(seriesVariants.isDisjoint(with: story.pages.flatMap(\.variantIDs)))
        }
    }

    // MARK: - Masal ailem

    func testTheFamilyCharacterOpensAndClosesEveryEpisode() throws {
        let catalog = try catalog()
        for band in [Self.age3, Self.age5] {
            let mode = try XCTUnwrap(BlueprintSelector()
                .availableModes(catalog: catalog, ageBand: band)
                .first { canContinue($0, band, catalog) })
            let result = try plan(mode: mode, band: band, seed: "fam", family: sister(catalog), catalog: catalog)
            XCTAssertEqual(result.plan.family?.relation, .sibling)
            for story in result.episodes {
                XCTAssertTrue(story.pages.first?.text.contains("Ela") == true, story.pages.first?.text ?? "")
                XCTAssertTrue(story.pages.last?.text.contains("Ela") == true, story.pages.last?.text ?? "")
            }
        }
    }

    func testAPlanComposesWithoutItsFamilyCharacter() throws {
        let catalog = try catalog()
        for band in [Self.age3, Self.age5] {
            let mode = try XCTUnwrap(BlueprintSelector()
                .availableModes(catalog: catalog, ageBand: band)
                .first { canContinue($0, band, catalog) })
            let result = try plan(mode: mode, band: band, seed: "fam", family: sister(catalog), catalog: catalog)
            let without = result.plan.withoutFamily()
            XCTAssertNil(without.family)
            for story in try SeriesPlanner().compose(
                without, childName: "Yeliz", family: sister(catalog), catalog: catalog) {
                XCTAssertFalse(story.pages.contains { $0.text.contains("Ela") },
                               "a plan without its character must not write the name")
                XCTAssertTrue(story.isClean)
            }
        }
    }

    func testThePlanNeverHoldsTheFamilyName() throws {
        let catalog = try catalog()
        let result = try plan(mode: .learning, band: Self.age5, seed: "fam", family: sister(catalog), catalog: catalog)
        let json = String(decoding: try JSONEncoder().encode(result.plan), as: UTF8.self)
        XCTAssertFalse(json.contains("Ela"))
        XCTAssertFalse(json.contains("Yeliz"))
    }

    // MARK: - Calm ending

    func testEveryEpisodeEndsCalmly() throws {
        let catalog = try catalog()
        for (mode, band, seed) in cases(catalog) {
            for family in [nil, sister(catalog)] {
                for story in try plan(mode: mode, band: band, seed: seed, family: family, catalog: catalog).episodes {
                    let last = try XCTUnwrap(story.pages.last)
                    XCTAssertEqual(CalmEnding.violations(in: last.text), [], last.text)
                }
            }
        }
    }

    func testTheCalmRule() {
        XCTAssertFalse(CalmEnding.isCalm("Ne olduğunu kim bilebilirdi?"))
        XCTAssertFalse(CalmEnding.isCalm("Yarın yine buluşacaklardı."))
        XCTAssertFalse(CalmEnding.isCalm("Yarına kadar bekleyecekti."))
        XCTAssertFalse(CalmEnding.isCalm("Acaba neydi o ses."))
        XCTAssertFalse(CalmEnding.isCalm("Birdenbire bir ışık yandı."))
        XCTAssertFalse(CalmEnding.isCalm("Sonra ne olacak, bilmiyordu."))
        XCTAssertTrue(CalmEnding.isCalm("Yorgundu ama mutluydu."), "'ama' is allowed")
        XCTAssertTrue(CalmEnding.isCalm("Güzel bir gündü."))
    }

    /// FAZ 11 #11 ("Yarın yine buluşacaklardı.") is a standalone closing; it
    /// never closes an episode.
    func testNoEpisodeEverClosesOnTomorrow() throws {
        let catalog = try catalog()
        let friend = FamilyCast(name: "Deniz", relation: .friend)
        for (mode, band, seed) in cases(catalog) {
            for story in try plan(mode: mode, band: band, seed: seed, family: friend, catalog: catalog).episodes {
                XCTAssertFalse(story.pages.last!.text.contains("Yarın"))
            }
        }
    }

    func testEverySeriesClosingLineIsCalm() throws {
        for template in try catalog().series.templates where template.realizesBeat == .warmClose {
            for variant in template.variants {
                XCTAssertTrue(CalmEnding.isCalm(variant.text), "\(variant.id): \(variant.text)")
            }
        }
    }

    // MARK: - Failure

    func testAModeWithoutContinuationsSaysSo() throws {
        let catalog = try catalog()
        let first = try firstStory(mode: .bedtime, band: Self.age3, seed: "s1", catalog: catalog)
        XCTAssertThrowsError(try SeriesPlanner().plan(
            anchor: anchor(first), mode: .learning, band: Self.age3, family: nil,
            familyCharacterID: nil, childName: "Yeliz", seed: "x", catalog: catalog)) { error in
            XCTAssertEqual(error as? SeriesPlanningError,
                           .noContinuation(mode: .learning, band: Self.age3, episode: 2))
        }
    }

    func testAnUnknownAnchorIsReportedNotSubstituted() throws {
        let catalog = try catalog()
        let anchor = SeriesAnchor(
            settingID: ContentID("setting_whispering_forest_001"),
            companionID: ContentID("companion_fox_pilot_001"),
            keepsakeID: ContentID("object_gone"))
        XCTAssertThrowsError(try SeriesPlanner().plan(
            anchor: anchor, mode: .learning, band: Self.age5, family: nil,
            familyCharacterID: nil, childName: "Yeliz", seed: "x", catalog: catalog)) { error in
            XCTAssertEqual(error as? SeriesPlanningError, .unknownContent(ContentID("object_gone")))
        }
    }

    // MARK: - Catalog

    func testTheSeriesLayerLoadsClean() throws {
        let loaded = try ContentCatalogLoader().load()
        let report = try XCTUnwrap(loaded.report.integrity)
        let continuations = Set(loaded.catalog.series.continuations.map(\.id))
        let seriesCodes: Set<String> = [
            "revisit_in_standalone", "continuation_without_modes", "continuation_episode_out_of_range",
            "continuation_without_revisit", "series_beat_without_templates", "keepsake_name_missing"]
        let found: [CatalogIssue] = report.issues.filter { issue in
            seriesCodes.contains(issue.code) || issue.recordID.map(continuations.contains) == true
        }
        XCTAssertEqual(found.map(\.message), [])
    }

    func testRevisitOnlyOpensABook() {
        let slots = [
            BeatSlot(pageNumber: 1, role: .hook, beat: .noticeAnomaly),
            BeatSlot(pageNumber: 2, role: .companion, beat: .revisit)
        ]
        let codes = BeatSequenceValidator().validate(slots).issues.map(\.code)
        XCTAssertTrue(codes.contains("revisit_out_of_place"))
    }

    func testAnObjectWrittenBeforeFaz13StillDecodes() throws {
        let json = #"{"id": "object_x", "name": "bir şey"}"#
        let object = try JSONDecoder().decode(CatalogObject.self, from: Data(json.utf8))
        XCTAssertNil(object.keepsakeName)
        XCTAssertEqual(OfflineStoryComposer.keepsakeSlot(object).value, "bir şey")
    }

    func testAContinuationSpecDefaultsToEveryEpisode() throws {
        let spec = try JSONDecoder().decode(ContinuationSpec.self, from: Data(#"{"modes": ["growth"]}"#.utf8))
        XCTAssertEqual(spec.modes, [.learning], "old mode names resolve")
        XCTAssertEqual(spec.episodes, [2, 3, 4, 5])
    }

    // MARK: - Draft

    /// Writes the review draft (`FAZ13_SERI_TASLAK.md`) from the engine's own
    /// output, so the draft is exactly what a family would read. Runs only when
    /// `SERIES_DRAFT_OUT` names a file.
    func testWriteTheReviewDraft() throws {
        guard let path = ProcessInfo.processInfo.environment["SERIES_DRAFT_OUT"] else {
            throw XCTSkip("set SERIES_DRAFT_OUT to write the draft")
        }
        let catalog = try catalog()
        var out = ""
        func book(_ title: String, _ story: ComposedStory) {
            out += "#### \(title) — \(story.title)\n\n"
            out += "_\(story.blueprintID.rawValue) · keşif: \(story.content.discovery.name)_\n\n"
            for page in story.pages { out += "\(page.pageNumber). \(page.text)\n\n" }
        }
        let runs: [(String, StoryMode, AgeBand, FamilyCast?)] = [
            ("3-4 · Uyku öncesi · Masal ailem yok", .bedtime, Self.age3, nil),
            ("5-6 · Yeni şeyler öğrenelim · kardeşi Ela", .learning, Self.age5, sister(catalog))
        ]
        for (heading, mode, band, family) in runs {
            let seed = "taslak"
            let first = try firstStory(mode: mode, band: band, seed: seed, family: family, catalog: catalog)
            let result = try plan(mode: mode, band: band, seed: seed, family: family, catalog: catalog)
            out += "### \(heading)\n\n"
            out += "Yer: \(first.content.setting.name) · Yol arkadaşı: \(first.content.companion.name) · "
                + "Hatıra: \(first.content.discovery.keepsakeName ?? first.content.discovery.name)\n\n"
            book("1. bölüm (ilk masal)", first)
            for (planned, story) in zip(result.plan.episodes, result.episodes) {
                book("\(planned.number). bölüm", story)
            }
        }
        try out.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Bedtime arc

    /// A story that opened in a bedroom (uyku arkı) continues there: every
    /// episode is a bedtime-arc continuation in the same room with the same
    /// friend, reads only bedtime lines, and closes calmly in that room.
    func testABedtimeArcStoryContinuesInItsBedroom() throws {
        let catalog = try catalog()
        let bedtimeLines = Set((catalog.templates + catalog.series.templates)
            .filter { $0.arc == .bedtime }.flatMap(\.variants).map(\.id))
        for band in [Self.age3, Self.age5] {
            for seed in ["uyku", "s1", "s2", "s3", "s4"] {
                for family in [nil, sister(catalog)] {
                    let story = try OfflineStoryComposer().compose(
                        catalog: catalog,
                        intent: OfflineStoryIntent(
                            childName: "Yeliz", seed: seed, mode: .bedtime, ageBand: band, family: family))
                    XCTAssertEqual(catalog.blueprint(story.blueprintID)?.arc, .bedtime)
                    XCTAssertTrue(SeriesPlanner.isAvailable(
                        settingID: story.content.setting.id, mode: .bedtime, band: band, catalog: catalog))
                    let result = try SeriesPlanner().plan(
                        anchor: anchor(story), mode: .bedtime, band: band, family: family,
                        familyCharacterID: family == nil ? nil : "family-1", childName: "Yeliz",
                        seed: SeriesPlanner.seed(storySeed: story.seed, fingerprint: story.fingerprint),
                        catalog: catalog)
                    let label = "\(band) \(seed) \(family == nil ? "-" : "aile")"

                    let ids = result.plan.episodes.map(\.blueprintID)
                    XCTAssertEqual(ids.count, 4, label)
                    XCTAssertTrue(ids.allSatisfy { catalog.series.continuation($0)?.arc == .bedtime }, label)
                    XCTAssertEqual(ids[0], ids[2], label)
                    XCTAssertEqual(ids[1], ids[3], label)
                    XCTAssertNotEqual(ids[0], ids[1], "\(label): A-B-A-B")

                    let discoveries = result.plan.episodes.map(\.discoveryID)
                    XCTAssertFalse(discoveries.contains(result.plan.anchor.keepsakeID), label)
                    for (a, b) in zip(discoveries, discoveries.dropFirst()) {
                        XCTAssertNotEqual(a, b, "\(label): the same discovery two episodes in a row")
                    }

                    let room = story.content.setting
                    for episode in result.episodes {
                        XCTAssertEqual(episode.content.setting.id, room.id, label)
                        XCTAssertEqual(episode.content.companion.id, story.content.companion.id, label)
                        XCTAssertEqual(episode.pages.count, band.pageCount, label)
                        XCTAssertEqual(episode.pages.first?.beats.first, .revisit, label)
                        XCTAssertTrue(episode.isClean, "\(label) \(episode.blueprintID)")
                        let used = Set(episode.pages.flatMap(\.variantIDs))
                        XCTAssertTrue(used.isSubset(of: bedtimeLines), "\(label): \(used.subtracting(bedtimeLines))")
                        let last = try XCTUnwrap(episode.pages.last)
                        XCTAssertTrue(last.text.contains(room.name), "\(label): \(last.text)")
                        XCTAssertTrue(CalmEnding.isCalm(last.text), "\(label): \(last.text)")
                    }
                    // The same mechanism comes back every other episode; its
                    // pages are where a repeat would show.
                    if family == nil {
                        for (a, b) in [(0, 2), (1, 3)] {
                            let shared = zip(result.episodes[a].pages, result.episodes[b].pages)
                                .filter { $0.text == $1.text }.map(\.0.pageNumber)
                            XCTAssertEqual(shared, [], "\(label): episodes \(a + 2) and \(b + 2)")
                        }
                    }
                    // Composing again from the plan alone gives the same text.
                    let again = try SeriesPlanner().compose(
                        result.plan, childName: "Yeliz", family: family, catalog: catalog)
                    XCTAssertEqual(again.map { $0.pages.map(\.text) }, result.episodes.map { $0.pages.map(\.text) }, label)
                }
            }
            // A bedtime story saved before the arc still continues, with
            // standard episodes in its garden or forest.
            let saved = try firstStory(mode: .bedtime, band: band, seed: "uyku", catalog: catalog)
            XCTAssertTrue(SeriesPlanner.isAvailable(
                settingID: saved.content.setting.id, mode: .bedtime, band: band, catalog: catalog))
            let continued = try plan(mode: .bedtime, band: band, seed: "uyku", catalog: catalog)
            XCTAssertTrue(continued.plan.episodes.allSatisfy {
                catalog.series.continuation($0.blueprintID)?.arc == .standard
            })
        }
    }
}
