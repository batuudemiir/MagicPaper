import XCTest
@testable import StoryEngine

/// Kullanımdan öğrenme, cihaz tarafı (FAZ 14).
///
/// Kabul: yerel ağırlıklandırma belirleyici; Uyku öncesinde yarıda bırakmak
/// ceza değil. Ve en önemlisi: okuma geçmişi yokken her çarpan tam 1, yani
/// kitap FAZ 14 öncesinin kitabı.
final class UsageLearningTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private let b56 = AgeBand(lowerBound: 5, upperBound: 6)

    /// A shipped blueprint of this family, so the learner can look it up.
    private func blueprint(_ family: NarrativeFamily, in catalog: ContentCatalog) throws -> ContentID {
        try XCTUnwrap(catalog.blueprints.first { $0.family == family }?.id)
    }

    private func usage(
        _ blueprintID: ContentID,
        companion: ContentID? = nil,
        mode: StoryMode? = nil,
        completions: Int = 0,
        abandoned: Bool = false
    ) -> StoryUsage {
        StoryUsage(blueprintID: blueprintID, companionID: companion, mode: mode,
                   completions: completions, abandoned: abandoned)
    }

    // MARK: - Neutral

    func testNoReadingIsNeutral() throws {
        let profile = UsageLearner.profile(from: [], catalog: try catalog())
        XCTAssertEqual(profile, .neutral)
        XCTAssertEqual(profile.multiplier(family: .charge), 1)
        XCTAssertEqual(profile.multiplier(family: nil), 1)
        XCTAssertEqual(profile.multiplier(companion: "anything"), 1)
    }

    /// A story read once to the middle and not finished is not a signal in a
    /// mode that forgives it, and a story with no outcome at all is none either.
    func testStoriesWithoutAnOutcomeChangeNothing() throws {
        let catalog = try catalog()
        let charge = try blueprint(.charge, in: catalog)
        let profile = UsageLearner.profile(from: [
            usage(charge, companion: "companion_x", mode: .bedtime, abandoned: true),
            usage(charge, companion: "companion_x", mode: .adventure)
        ], catalog: catalog)
        XCTAssertEqual(profile, .neutral)
    }

    /// With no usage the live path is the old book, byte for byte.
    ///
    /// Parmak izi 30 Ekim 2026'da yeniden sabitlendi (dördüncü kez): üç meslek
    /// blueprint'i havuza girdi ve bu seed başka bir banda, başka bir şekle
    /// düştü. Testin koruduğu şey değişmedi — kullanım profili NÖTR iken
    /// kitabın kullanımdan önceki kitapla aynı olması.
    ///
    /// Parmak izi 29 Ekim 2026'da yeniden sabitlendi (üçüncü kez): üç insan
    /// arkadaş ve Pazar Yeri havuza girince bu seed başka bir mekân, arkadaş
    /// ve keşif bağladı. Bkz. `OfflineDeterminismTests`.
    ///
    /// Parmak izi 21 Ekim 2026'da yeniden sabitlendi: v2 kütüphanesi havuza
    /// katılınca bu seed başka bir mekân ve arkadaş bağladı. Testin koruduğu
    /// şey değişmedi — kullanım profili NÖTR iken kitabın, kullanımdan önceki
    /// kitapla aynı olması. Havuz değişince referans kitap da değişir.
    func testANeutralProfileKeepsThePinnedBook() throws {
        let intent = OfflineStoryIntent(childName: "Yeliz", seed: "pinned-seed-001", usage: .neutral)
        let story = try OfflineStoryComposer().compose(catalog: catalog(), intent: intent)
        XCTAssertEqual(story.fingerprint, "a7fd601ec0f44208")
    }

    func testANeutralUsageArgumentKeepsEveryWeight() {
        let id: ContentID = "a"
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: [], usage: 1), 1)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: true, recent: [id], usage: 1), 0.3, accuracy: 1e-9)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: true, recent: [], usage: 1.5), 4.5, accuracy: 1e-9)
    }

    // MARK: - Signals

    func testARereadRaisesItsFamilyAndCompanion() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let profile = UsageLearner.profile(from: [
            usage(threshold, companion: "companion_x", mode: .adventure, completions: 2)
        ], catalog: catalog)
        XCTAssertGreaterThan(profile.multiplier(family: .threshold), 1)
        XCTAssertGreaterThan(profile.multiplier(companion: "companion_x"), 1)
        XCTAssertEqual(profile.multiplier(family: .appeal), 1)
        XCTAssertEqual(profile.multiplier(companion: "companion_y"), 1)
    }

    func testARereadWeighsMoreThanOneReading() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let once = UsageLearner.profile(from: [usage(threshold, mode: .adventure, completions: 1)], catalog: catalog)
        let twice = UsageLearner.profile(from: [usage(threshold, mode: .adventure, completions: 2)], catalog: catalog)
        XCTAssertGreaterThan(once.multiplier(family: .threshold), 1)
        XCTAssertGreaterThan(twice.multiplier(family: .threshold), once.multiplier(family: .threshold))
    }

    func testAnAbandonedStoryLowersItsFamilyAndCompanion() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let profile = UsageLearner.profile(from: [
            usage(threshold, companion: "companion_x", mode: .adventure, abandoned: true)
        ], catalog: catalog)
        XCTAssertLessThan(profile.multiplier(family: .threshold), 1)
        XCTAssertLessThan(profile.multiplier(companion: "companion_x"), 1)
    }

    /// Uyku öncesinde yarıda bırakmak başarıdır: çocuk uyumuştur.
    func testAbandoningABedtimeStoryIsNotAPenalty() throws {
        let catalog = try catalog()
        XCTAssertEqual(catalog.modeProfile(.bedtime)?.success.abandonIsPenalty, false)
        XCTAssertEqual(catalog.modeProfile(.adventure)?.success.abandonIsPenalty, true)
        XCTAssertEqual(catalog.modeProfile(.learning)?.success.abandonIsPenalty, true)

        let charge = try blueprint(.charge, in: catalog)
        let asleep = (0..<5).map { _ in usage(charge, companion: "companion_x", mode: .bedtime, abandoned: true) }
        let profile = UsageLearner.profile(from: asleep, catalog: catalog)
        XCTAssertEqual(profile.multiplier(family: .charge), 1)
        XCTAssertEqual(profile.multiplier(companion: "companion_x"), 1)

        // The same story abandoned in a mode that counts it does lower it.
        let bored = UsageLearner.profile(
            from: [usage(charge, companion: "companion_x", mode: .adventure, abandoned: true)], catalog: catalog)
        XCTAssertLessThan(bored.multiplier(family: .charge), 1)
    }

    /// A story that was finished is not abandoned, whatever the last session did.
    func testAFinishedStoryIsNeverPenalised() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let profile = UsageLearner.profile(
            from: [usage(threshold, mode: .adventure, completions: 1, abandoned: true)], catalog: catalog)
        XCTAssertGreaterThan(profile.multiplier(family: .threshold), 1)
    }

    /// Learning nudges; it never overrides interests or cooldown.
    func testMultipliersAreBounded() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let loved = UsageLearner.profile(
            from: (0..<50).map { _ in usage(threshold, companion: "a", mode: .adventure, completions: 9) },
            catalog: catalog)
        let dropped = UsageLearner.profile(
            from: (0..<50).map { _ in usage(threshold, companion: "a", mode: .adventure, abandoned: true) },
            catalog: catalog)
        XCTAssertEqual(loved.multiplier(family: .threshold), UsageLearner.ceiling)
        XCTAssertEqual(dropped.multiplier(family: .threshold), UsageLearner.floor)
        XCTAssertLessThan(UsageLearner.ceiling, 1 + SelectionScoring.interestBoost)
    }

    /// An id the catalog does not know (an old story, a retired blueprint) still
    /// teaches its companion, and teaches no family.
    func testAnUnknownBlueprintTeachesOnlyItsCompanion() throws {
        let profile = UsageLearner.profile(
            from: [usage("blueprint_retired", companion: "companion_x", mode: .adventure, completions: 2)],
            catalog: try catalog())
        XCTAssertGreaterThan(profile.multiplier(companion: "companion_x"), 1)
        XCTAssertTrue(profile.families.isEmpty)
    }

    // MARK: - Determinism

    func testTheOrderOfStoriesDoesNotMatter() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let appeal = try blueprint(.appeal, in: catalog)
        let stories = [
            usage(threshold, companion: "a", mode: .adventure, completions: 2),
            usage(appeal, companion: "b", mode: .learning, abandoned: true),
            usage(threshold, companion: "b", mode: .adventure, completions: 1),
            usage(appeal, companion: "a", mode: .learning, completions: 3)
        ]
        let forward = UsageLearner.profile(from: stories, catalog: catalog)
        let backward = UsageLearner.profile(from: stories.reversed(), catalog: catalog)
        XCTAssertEqual(forward, backward)
        XCTAssertEqual(forward, UsageLearner.profile(from: stories, catalog: catalog))
    }

    /// Pinned literals, so a change in the formula is a decision, not an accident.
    func testPinnedMultipliers() throws {
        let catalog = try catalog()
        let threshold = try blueprint(.threshold, in: catalog)
        let profile = UsageLearner.profile(from: [
            usage(threshold, companion: "a", mode: .adventure, completions: 2),
            usage(threshold, companion: "a", mode: .adventure, abandoned: true),
            usage(threshold, companion: "b", mode: .adventure, completions: 1)
        ], catalog: catalog)
        // threshold: (1 - 1 + 0.25) / (3 + 2) = 0.05
        XCTAssertEqual(profile.multiplier(family: .threshold), 1.05, accuracy: 1e-12)
        // a: (1 - 1) / (2 + 2) = 0 → not stored, exactly 1
        XCTAssertEqual(profile.multiplier(companion: "a"), 1)
        // b: 0.25 / (1 + 2)
        XCTAssertEqual(profile.multiplier(companion: "b"), 1 + 0.25 / 3, accuracy: 1e-12)
    }

    // MARK: - Selection

    /// A family the child re-reads comes first more often across seeds, but not
    /// always: learning is a weight, never a filter.
    func testAReReadFamilyLeadsMoreOftenButNotAlways() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let candidates = try selector.ranked(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Can", seed: "probe", ageBand: b56))
        let families = Set(candidates.compactMap(\.family))
        XCTAssertGreaterThan(families.count, 1, "Needs more than one family to say anything.")
        let favourite = try XCTUnwrap(candidates.compactMap(\.family).sorted { $0.rawValue < $1.rawValue }.first)
        let loved = UsageProfile(families: [favourite: UsageLearner.ceiling], companions: [:])

        func leads(_ usage: UsageProfile) throws -> Int {
            try (0..<200).filter { index in
                let intent = OfflineStoryIntent(
                    childName: "Can", seed: "usage-\(index)", ageBand: b56, usage: usage)
                return try selector.ranked(catalog: catalog, intent: intent).first?.family == favourite
            }.count
        }
        let neutral = try leads(.neutral)
        let learned = try leads(loved)
        XCTAssertGreaterThan(learned, neutral)
        XCTAssertLessThan(learned, 200)
    }

    /// Sevilen arkadaş daha sık başa geçiyor — **bir eğilim olarak** (ölçüldü:
    /// 30 Ekim 2026).
    ///
    /// İlk hâli tek bir arkadaşla ölçüyordu: bir prob masalı kuruyor, onun
    /// arkadaşını tavan ağırlığa çıkarıyor, ve kesin artış bekliyordu.
    /// İstatistik bir eğilimi tek örnekle ölçmek demekti ve havuz değişince
    /// kırmızıya döndü — prob seed'inin verdiği arkadaş yunustu, 17 şeklin
    /// yalnızca 6'sına girebiliyor ve taban oranı 4/100, yani ölçülen şey
    /// mekanizma değil gürültüydü.
    ///
    /// Ölçüm (öğrenelim + macera havuzu, modsuz, 100 seed, erişim ≥ 6 olan
    /// bütün hayvanlar):
    ///
    ///     sincap     13 şekil    6 → 10  ✓     penguen    10 şekil    8 →  8  ✗
    ///     kirpi      13 şekil   11 → 10  ✗     ateşböceği 10 şekil    6 → 14  ✓
    ///     kurbağa    12 şekil    7 → 13  ✓     kedi        9 şekil    5 →  6  ✓
    ///     tavşan     12 şekil    9 → 17  ✓     ayı         7 şekil    5 →  4  ✗
    ///                                          kaplumbağa  7 şekil    4 →  7  ✓
    ///                                          yunus       6 şekil    4 →  2  ✗
    ///
    /// Yani mekanizma çalışıyor ve erişim arttıkça güçleniyor, ama tek tek her
    /// arkadaşta çalışmıyor: mekân ve habitat şartları kısıtlı bir arkadaş için
    /// ağırlıktan baskın. Bu bir kusur değil, bağlamanın sırası — arkadaş,
    /// mekân seçildikten sonra seçiliyor.
    ///
    /// Bu yüzden iddia toplamda ölçülüyor: ağırlık, geniş erişimli arkadaşların
    /// TOPLAM payını artırıyor. Tek bir çekilişe dayanan bir iddia, bir sonraki
    /// içerik turunda yine şansa kalır.
    func testALearnedCompanionLeadsMoreOftenButNotAlways() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        let binder = OfflineContentBinder()
        let shapes = catalog.blueprints.filter {
            $0.isBeatAuthored && $0.ageRange == b56 && $0.arc == .standard
        }

        /// Erişimi geniş arkadaşlar: ağırlığın görünebildiği yer.
        let broad = catalog.companions.filter { companion in
            shapes.filter { blueprint in
                (try? binder.bind(
                    blueprint: blueprint, catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Can", companionID: companion.id,
                                               seed: "reach", ageBand: b56),
                    idea: nil)) != nil
            }.count >= 9
        }
        XCTAssertGreaterThanOrEqual(broad.count, 5, "ölçüm için yeterli geniş erişimli arkadaş yok")

        func share(of companion: CatalogCompanion, usage: UsageProfile) -> Int {
            (0..<100).filter { index in
                (try? composer.compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Can", seed: "c-\(index)",
                                               ageBand: b56, usage: usage)))?
                    .content.companion.id == companion.id
            }.count
        }

        var neutralTotal = 0, learnedTotal = 0
        for companion in broad {
            neutralTotal += share(of: companion, usage: .neutral)
            let learned = share(of: companion, usage: UsageProfile(
                families: [:], companions: [companion.id: UsageLearner.ceiling]))
            learnedTotal += learned
            // Hiçbir arkadaş tavanda bile masalı ele geçirmiyor: öğrenme bir
            // ağırlık, bir kilit değil.
            XCTAssertLessThan(learned, 100, companion.id.rawValue)
        }
        XCTAssertGreaterThan(learnedTotal, neutralTotal,
                             "sevilen arkadaş toplamda daha sık başa geçmedi "
                             + "(\(neutralTotal) → \(learnedTotal))")
    }

    // MARK: - Catalog fields

    func testAModeWithoutASuccessRulePenalisesAbandoning() throws {
        let json = #"{"mode": "adventure", "families": ["threshold"]}"#
        let profile = try JSONDecoder().decode(StoryModeProfile.self, from: Data(json.utf8))
        XCTAssertTrue(profile.success.abandonIsPenalty)

        let bedtime = #"{"mode": "bedtime", "families": ["charge"], "success": {"abandonIsPenalty": false}}"#
        XCTAssertFalse(try JSONDecoder().decode(StoryModeProfile.self, from: Data(bedtime.utf8))
            .success.abandonIsPenalty)
    }

    func testABlueprintWithoutAnAggregateWeightIsNeutral() throws {
        let catalog = try catalog()
        XCTAssertTrue(catalog.blueprints.allSatisfy { $0.aggregateWeight == 1 })

        let original = try XCTUnwrap(catalog.blueprints.first)
        let data = try JSONEncoder().encode(original)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["aggregateWeight"], "A neutral weight is not written out.")

        var weighted = object
        weighted["aggregateWeight"] = 1.4
        let decoded = try JSONDecoder().decode(
            CatalogBlueprint.self, from: JSONSerialization.data(withJSONObject: weighted))
        XCTAssertEqual(decoded.aggregateWeight, 1.4)
        let again = try JSONDecoder().decode(CatalogBlueprint.self, from: JSONEncoder().encode(decoded))
        XCTAssertEqual(again.aggregateWeight, 1.4)
    }

    func testIntegrityRejectsANonPositiveAggregateWeight() throws {
        let catalog = try catalog()
        let original = try XCTUnwrap(catalog.blueprints.first)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object["aggregateWeight"] = 0
        let broken = try JSONDecoder().decode(
            CatalogBlueprint.self, from: JSONSerialization.data(withJSONObject: object))
        let rebuilt = InterestFixtures.rebuilding(
            catalog, blueprints: [broken] + catalog.blueprints.dropFirst())
        let report = CatalogIntegrityChecker().check(rebuilt)
        XCTAssertEqual(report.issues(withCode: "blueprint_aggregate_weight_invalid").map(\.severity), [.error])
        XCTAssertTrue(CatalogIntegrityChecker().check(catalog).issues(withCode: "blueprint_aggregate_weight_invalid").isEmpty)
    }

    /// A heavier aggregate weight leads more often, the hook Thompson sampling
    /// will use once the server has a table (FAZ 16 sonrası).
    func testAnAggregateWeightIsAWeight() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let probe = try selector.ranked(
            catalog: catalog, intent: OfflineStoryIntent(childName: "Can", seed: "probe", ageBand: b56))
        let target = try XCTUnwrap(probe.last)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(target)) as? [String: Any])
        object["aggregateWeight"] = 1.8
        let heavier = try JSONDecoder().decode(
            CatalogBlueprint.self, from: JSONSerialization.data(withJSONObject: object))
        let weighted = InterestFixtures.rebuilding(
            catalog, blueprints: catalog.blueprints.map { $0.id == target.id ? heavier : $0 })

        func leads(_ catalog: ContentCatalog) throws -> Int {
            try (0..<200).filter { index in
                try selector.ranked(
                    catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Can", seed: "agg-\(index)", ageBand: b56)
                ).first?.id == target.id
            }.count
        }
        XCTAssertGreaterThan(try leads(weighted), try leads(catalog))
    }

    // MARK: - Aggregate table row

    func testABlueprintOutcomeIsCountsOnly() throws {
        let row = BlueprintOutcome(blueprintID: "b", starts: 10, completions: 6, rereads: 2)
        let keys = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(row)) as? [String: Any]).keys
        XCTAssertEqual(Set(keys), ["blueprintID", "starts", "completions", "rereads"])
    }
}
