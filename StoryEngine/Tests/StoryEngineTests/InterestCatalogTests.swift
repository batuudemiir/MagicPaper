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
            "music", "magic", "nature", "robots", "sports", "pirates",
            // 16 Ekim 2026: alt kategoriler (`CatalogStoryTopic`) konu sözcüğü
            // olarak bu sözlüğü kullanıyor — ikinci bir taksonomi açmamak için.
            // İçeriği olmayan sözcük ebeveyne çip olarak da görünmez;
            // `interestCoverage` yalnızca ulaşılabilen sözcükleri sayar.
            "jobs", "science", "history", "country", "city", "sky",
            // 22 Ekim 2026: "Hazine avı" konusunun sözcüğü.
            "treasure"
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
        // 22 Ekim 2026: 3-4 satırı DÜŞTÜ, ve düşmesi bir düzeltme.
        //
        // 21 Ekim'de bu satır ["animals", "magic", "nature", "sea"] yazıyordu.
        // Ölçülünce dördünün de tek bir blueprint'ten geldiği çıktı:
        // `blueprint_charge_tending_age3_001`, uyku arkı eklenirken hiçbir
        // moda bağlanamaz hâle gelen üç blueprint'ten biri. Yani o bantta
        // hiçbir çocuğa ulaşmayan bir şekil üzerinden kapsama sayılıyordu.
        // `interestCoverage` artık yalnızca bir modun kabul ettiği
        // blueprint'leri sayıyor (`InterestReachabilityTests`), ve 3-4'te bir
        // çocuğun gerçekten alabildiği tek şekil yalnızca hayvanlara ulaşıyor.
        //
        // Sonucu: sunulan kelime dörtten bire düştü, FAZ 12 eşiği (dört)
        // aşılmıyor ve ilgi ekranları gizli — hiç meşru biçimde açılmamışlar.
        //
        // Aynı gün, ikinci değişiklik: `charge` ailesi "Yeni şeyler
        // öğrenelim"e eklendi (karar: Batuhan). O blueprint ulaşılabilir
        // oldu, 3-4 bandı bir çocuğun gerçekten alabildiği ikinci şekle
        // kavuştu, ve kapsama beş kelimeye çıktı — bu kez meşru. Sunulan
        // liste de dörtten beşe çıkınca FAZ 12 eşiği gerçekten aşıldı.
        XCTAssertEqual(coverage[b34], ["animals", "magic", "nature", "sea", "treasure"])
        XCTAssertEqual(coverage[b56],
                       ["animals", "magic", "music", "nature", "robots", "sea", "treasure"])
        XCTAssertEqual(BlueprintSelector().availableInterests(catalog: catalog).map(\.name),
                       ["Hayvanlar", "Deniz", "Sihir", "Doğa", "Hazine"])
    }

    /// Deniz iki bantta da ulaşılabilir (22 Ekim 2026, ikinci ölçüm).
    ///
    /// FAZ 12'den beri mercan denizi, yunus ve deniz kabuğu katalogda duruyor
    /// ama hiçbir masala giremiyordu: o masalları kuracak mekân/arkadaş/nesne
    /// üçlüsü tamamlanmıyordu. v2 kütüphanesi etiketlenip havuza katılınca
    /// (kumsal, resif, ada, penguen, kaplumbağa) deniz 5-6'da kuruldu.
    ///
    /// Bu iddia bir günde iki kez döndü, ve ikisinin de sebebi aynı blueprint:
    /// 21 Ekim'de deniz iki bantta da kurulu sayılıyordu, ama 3-4 ayağı hiçbir
    /// moda bağlanamayan `blueprint_charge_tending_age3_001` üzerinden
    /// sayılıyordu; kapsama onu saymayı bırakınca deniz o bantta kalmadı. Aynı
    /// gün `charge` öğrenelime eklenince (karar: Batuhan) aynı blueprint
    /// ulaşılabilir oldu ve deniz meşru biçimde geri geldi.
    ///
    /// Yani rakam baştaki gibi, dayanağı değil: ilki eksik bir kapsamaydı,
    /// bu bir çocuğun gerçekten alabildiği masal.
    ///
    /// Testin eski hâli bunun tersini sabitliyordu ve şöyle yazılmıştı:
    ///
    ///     XCTAssertEqual(sea.count, 1)
    ///     XCTAssertTrue(sea[0].message.contains(...))
    ///
    /// Önerme değişince `count` sıfıra düştü, ilk satır kırmızı yazdı, ikinci
    /// satır boş diziyi indeksleyip **bütün demeti çökertti** — o çalıştırmada
    /// bilinen 10 hatanın hiçbiri koşamadı. Önce doğrula sonra indeksle:
    /// kırılan bir test yalnızca kendi sonucunu bozmalı.
    func testTheSeaIsReachableInBothBands() throws {
        let catalog = try catalog()
        XCTAssertEqual(catalog.setting("setting_coral_sea_001")?.interests, ["sea"])

        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)
        XCTAssertTrue(coverage[b56]?.contains("sea") ?? false, "5-6 bandında deniz yok")
        XCTAssertTrue(coverage[b34]?.contains("sea") ?? false, "3-4 bandında deniz yok")

        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let sea = report.issues(withCode: "interest_unreachable_in_band")
            .filter { $0.message.contains("'sea'") }
        XCTAssertTrue(sea.isEmpty, "deniz yine ulaşılamaz: \(sea.map(\.message))")
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

    /// Kapsam bağlayıcıya sorar: hiçbir masalın kullanamadığı içerikteki etiket
    /// hiçbir yere ulaşmaz.
    ///
    /// Bu testin eski hâli denizi "ulaşılamaz içerik" örneği olarak
    /// kullanıyordu — mercan denizi, yunus ve deniz kabuğu hiçbir blueprint'e
    /// bağlanamıyordu, çünkü her blueprint denizin sunmadığı bir şey istiyordu
    /// (saklanacak yer, iz, eşik, bakılan bir şey). 21 Ekim 2026'da v2
    /// kütüphanesi etiketlenince kumsal, resif ve ada havuza girdi ve deniz iki
    /// bantta da kurulur oldu. Örnek değişti, kuralın kendisi değil: kapsam
    /// hâlâ kurulabilenle sınırlı, 7-8 hâlâ boş.
    func testCoverageFollowsWhatCanActuallyBeBuilt() throws {
        let catalog = try InterestFixtures.testTagging(in: try catalog())
        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)

        XCTAssertEqual(coverage[b56], ["pirates", "animals", "sea"])
        XCTAssertEqual(coverage[b34], ["animals", "sea"], "korsan haritası 3-4 yayına hizmet etmiyor")
        XCTAssertEqual(coverage[AgeBand(lowerBound: 7, upperBound: 8)], [],
                       "7-8 bandında hiç blueprint yok")

        let offered = BlueprintSelector().availableInterests(catalog: catalog).map(\.id)
        XCTAssertEqual(offered, ["animals", "sea"], "korsanlar 3-4'e ulaşmıyor")
    }

    /// Bir blueprint'in kendi etiketi yalnızca kendi bandına ulaşır.
    ///
    /// 22 Ekim 2026: vasıta blueprint değişti. Test
    /// `blueprint_charge_tending_age3_001` üzerinden yazılmıştı, ve o blueprint
    /// hiçbir moda bağlanamıyor — kapsama onu saymayı bıraktığı an test, test
    /// ettiği kuralla ilgisiz bir sebepten kırmızıya döndü. Kural doğru, vasıta
    /// yanlıştı: artık o bantta bir çocuğun gerçekten alabildiği şekil
    /// kullanılıyor.
    func testABlueprintTagCountsOnlyInItsOwnBand() throws {
        let catalog = try InterestFixtures.retagging(
            try catalog(), ["bp_bedtime_lullaby_age3_001": ["nature"]])
        let coverage = BlueprintSelector().interestCoverage(catalog: catalog)
        XCTAssertTrue(coverage[b34]?.contains("nature") ?? false)
        XCTAssertFalse(coverage[b56]?.contains("nature") ?? false)
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
