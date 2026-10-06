import XCTest
@testable import StoryEngine

/// İlgi alanı sözlüğü (FAZ 12): sözlük katalogda tanımlı, içerik ona göre
/// etiketli, ve ekranda yalnızca her içerikli bantta bir masala ulaşan
/// kelime gösteriliyor.
final class InterestCatalogTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private let b34 = AgeBand(lowerBound: 3, upperBound: 4)
    private let b56 = AgeBand(lowerBound: 5, upperBound: 6)

    // MARK: - Vocabulary

    func testTheVocabularyIsCatalogData() throws {
        let catalog = try catalog()
        XCTAssertEqual(catalog.interests.map(\.id.rawValue), [
            "animals", "space", "dinosaurs", "princesses", "cars", "sea",
            "music", "magic", "nature", "robots", "sports", "pirates"
        ])
        XCTAssertEqual(catalog.interest("sea")?.name, "Deniz")
        XCTAssertEqual(catalog.interest("nature")?.name, "Doğa")
        XCTAssertTrue(catalog.interests.allSatisfy { $0.symbol != nil })
    }

    func testInterestIdsAreCaseInsensitive() {
        XCTAssertEqual(InterestTag("Sea"), InterestTag("sea"))
    }

    /// A catalog written before FAZ 12 has no `interests` anywhere and still
    /// decodes: no vocabulary, no record tagged.
    func testACatalogWithoutInterestsStillDecodes() throws {
        let json = """
        {
          "version": "1.0.0",
          "settings": [{ "id": "setting_a", "name": "A", "tags": ["forest"] }],
          "companions": [{ "id": "companion_a", "name": "B" }],
          "objects": [{ "id": "object_a", "name": "C" }]
        }
        """
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        XCTAssertTrue(catalog.interests.isEmpty)
        XCTAssertTrue(catalog.settings[0].interests.isEmpty)
        XCTAssertTrue(catalog.companions[0].interests.isEmpty)
        XCTAssertTrue(catalog.objects[0].interests.isEmpty)
    }

    /// Interests ride beside `tags`, never inside them: setting tags pick the
    /// cover world, and an interest must not change a cover.
    func testTaggingAnInterestLeavesContentTagsAlone() throws {
        let catalog = try catalog()
        let sea = try XCTUnwrap(catalog.setting("setting_coral_sea_001"))
        let tagged = try InterestFixtures.tagging(sea, with: ["sea"])
        XCTAssertEqual(tagged.interests, ["sea"])
        XCTAssertEqual(tagged.tags, sea.tags)
        XCTAssertEqual(tagged.traits, sea.traits)
    }

    // MARK: - The authored tagging (content decision, FAZ12_ILGI_ETIKETLERI.md)

    /// Bugünkü katalogla hangi kelime hangi banda ulaşıyor. İçerik kararıdır ve
    /// bilerek sabitlenir: içerik eklendiğinde kırmızıya döner ve güncellenir.
    func testTheShippedInterestMatrix() throws {
        let catalog = try catalog()
        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)
        XCTAssertEqual(coverage[b34], ["animals", "nature"])
        XCTAssertEqual(coverage[b56], ["animals", "nature"])
        XCTAssertEqual(BlueprintSelector().availableInterests(catalog: catalog).map(\.name),
                       ["Hayvanlar", "Doğa"])
    }

    /// The sea is authored but reaches no story: the coral sea, the dolphin
    /// and the shell bind to no shipped blueprint. Listed for the content
    /// pipeline, not hidden.
    func testTheSeaIsTaggedButUnreachable() throws {
        let catalog = try catalog()
        XCTAssertEqual(catalog.setting("setting_coral_sea_001")?.interests, ["sea"])
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let sea = report.issues(withCode: "interest_unreachable_in_band").filter { $0.message.contains("'sea'") }
        XCTAssertEqual(sea.count, 1)
        XCTAssertTrue(sea[0].message.contains("3-4") && sea[0].message.contains("5-6"), sea[0].message)
    }

    // MARK: - Integrity

    func testAnUndefinedInterestIsAnError() throws {
        let catalog = try catalog()
        let fox = try XCTUnwrap(catalog.companion("companion_fox_pilot_001"))
        let broken = InterestFixtures.rebuilding(
            catalog, companions: catalog.companions.map {
                $0.id == fox.id ? (try! InterestFixtures.tagging($0, with: ["volcanoes"])) : $0
            })
        let report = CatalogIntegrityChecker().check(broken)
        let issues = report.issues(withCode: "unknown_interest")
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(issues.first?.recordID, fox.id)
    }

    func testADuplicateInterestIsAnError() throws {
        let catalog = try catalog()
        let doubled = InterestFixtures.rebuilding(
            catalog, interests: catalog.interests + [CatalogInterest(id: "sea", name: "Okyanus")])
        let issues = CatalogIntegrityChecker().check(doubled).issues(withCode: "duplicate_interest")
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(doubled.interest("sea")?.name, "Deniz", "the first definition wins")
    }

    /// Bir bantta masala ulaşmayan kelime uyarıdır, hata değil: ekranda
    /// gösterilmez, içerik hattına gider.
    func testAnUnreachableInterestIsAWarning() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let unreachable = report.issues(withCode: "interest_unreachable_in_band")
        XCTAssertFalse(unreachable.isEmpty)
        XCTAssertTrue(unreachable.allSatisfy { $0.severity == .warning })
        XCTAssertTrue(report.issues(withCode: "unknown_interest").isEmpty)
        XCTAssertTrue(report.issues(withCode: "duplicate_interest").isEmpty)
        // Bantlar içerikli olanlarla sınırlı; 7-8 ve 9-10 ayrıca sayılmaz.
        let messages = unreachable.map(\.message).joined(separator: "\n")
        XCTAssertFalse(messages.contains("7-8") || messages.contains("9-10"), messages)
    }

    // MARK: - Coverage

    /// Coverage asks the binder, so a tag on content no story can use reaches
    /// nothing. The coral sea, the dolphin and the shell are such content today:
    /// every blueprint needs something the sea does not offer (somewhere to
    /// conceal, traces, a threshold, something tended), so the sea reaches no
    /// band at all — a finding for the content pipeline, not an engine rule.
    func testCoverageFollowsWhatCanActuallyBeBuilt() throws {
        let catalog = try InterestFixtures.testTagging(in: try catalog())
        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)

        XCTAssertEqual(coverage[b56], ["pirates", "animals"])
        XCTAssertEqual(coverage[b34], ["animals"], "the torn map serves no 3-4 shape")
        XCTAssertEqual(coverage[AgeBand(lowerBound: 7, upperBound: 8)], [])

        let offered = BlueprintSelector().availableInterests(catalog: catalog).map(\.id)
        XCTAssertEqual(offered, ["animals"], "pirates misses 3-4 and the sea misses both")
    }

    func testABlueprintTagCountsOnlyInItsOwnBand() throws {
        let catalog = try InterestFixtures.retagging(
            try catalog(), ["blueprint_charge_tending_age3_001": ["nature"]])
        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)
        XCTAssertEqual(coverage[b34], ["nature"])
        XCTAssertEqual(coverage[b56], [])
    }

    func testNothingIsOfferedWithoutContent() {
        let empty = ContentCatalog(version: "0", interests: [CatalogInterest(id: "sea", name: "Deniz")])
        XCTAssertTrue(BlueprintSelector().availableInterests(catalog: empty).isEmpty)
    }
}

/// Builders for catalogs with interest tags. `ContentCatalog` and its records
/// are decode-only by design, so tagging goes through a JSON round trip.
enum InterestFixtures {
    static func tagging<Record: Codable>(_ record: Record, with interests: [String]) throws -> Record {
        let data = try JSONEncoder().encode(record)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["interests"] = interests
        return try JSONDecoder().decode(Record.self, from: JSONSerialization.data(withJSONObject: object))
    }

    static func rebuilding(
        _ catalog: ContentCatalog,
        settings: [CatalogSetting]? = nil,
        companions: [CatalogCompanion]? = nil,
        objects: [CatalogObject]? = nil,
        blueprints: [CatalogBlueprint]? = nil,
        interests: [CatalogInterest]? = nil
    ) -> ContentCatalog {
        ContentCatalog(
            version: catalog.version,
            settings: settings ?? catalog.settings,
            companions: companions ?? catalog.companions,
            objects: objects ?? catalog.objects,
            events: catalog.events,
            challenges: catalog.challenges,
            endings: catalog.endings,
            templates: catalog.templates,
            blueprints: blueprints ?? catalog.blueprints,
            storyIdeas: catalog.storyIdeas,
            storyModes: catalog.storyModes,
            familyMoments: catalog.familyMoments,
            familyAnimalKinds: catalog.familyAnimalKinds,
            interests: interests ?? catalog.interests,
            declaredResolutionCount: catalog.declaredResolutionCount
        )
    }

    /// The shipped catalog with a small, test-owned tagging, independent of the
    /// authored one so engine tests do not move when content does: the sea on
    /// the coral sea, the dolphin and the shell; pirates on the torn map;
    /// animals on the hedgehog.
    static func testTagging(in catalog: ContentCatalog) throws -> ContentCatalog {
        try retagging(catalog, [
            "setting_coral_sea_001": ["sea"],
            "companion_dolphin_pilot_001": ["sea"],
            "object_shell_pilot_001": ["sea"],
            "object_torn_map_001": ["pirates"],
            "companion_hedgehog_pilot_001": ["animals"]
        ])
    }

    /// Every record's interests replaced by `tags` (untagged when absent).
    static func retagging(_ catalog: ContentCatalog, _ tags: [String: [String]]) throws -> ContentCatalog {
        func tag<R: Codable & InterestTagged>(_ r: R) throws -> R {
            try tagging(r, with: tags[r.id.rawValue] ?? [])
        }
        return rebuilding(
            catalog,
            settings: try catalog.settings.map(tag),
            companions: try catalog.companions.map(tag),
            objects: try catalog.objects.map(tag),
            blueprints: try catalog.blueprints.map(tag))
    }
}
