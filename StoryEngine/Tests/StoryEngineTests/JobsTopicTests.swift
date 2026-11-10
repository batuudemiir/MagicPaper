import XCTest
@testable import StoryEngine

/// Konu olay örgüsünü de süzüyor (karar: 30 Ekim 2026, Batuhan).
///
/// Buradaki testlerin tamamı tek bir cümlenin etrafında: **"Meslekler" seçilen
/// masal meslek HAKKINDA olmalı, içinde bir yetişkin bulunan masal değil.**
///
/// Ölçüm bu ayrımın neden gerektiğini gösterdi: konu yalnızca kaydı süzerken
/// 30 masalın 30'unda öğretmen vardı ve 30'unda da masal başka bir şey
/// hakkındaydı. Kayıt süzgeci sözü tutmuyordu.
final class JobsTopicTests: XCTestCase {

    private var catalog: ContentCatalog!
    private let band = AgeBand(lowerBound: 5, upperBound: 6)

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private func intent(_ topic: String?, seed: String = "jobs-seed") -> OfflineStoryIntent {
        OfflineStoryIntent(childName: "Yeliz", seed: seed, mode: .learning,
                           ageBand: band, subOption: topic)
    }

    private var jobs: CatalogStoryTopic {
        catalog.storyTopic("topic_learning_jobs")!
    }

    // MARK: - Söz

    /// Konu olay örgüsünü şart koşuyor, yoksa yalnızca dekoru şart koşmuş olur.
    func testTheJobsTopicRequiresThePlotItself() {
        XCTAssertEqual(jobs.requires.plot, ["jobs"])
        XCTAssertEqual(jobs.requires.companion, ["jobs"])
    }

    /// Meslek hakkında olmayan bir şekil konu tarafından reddediliyor — ve bu
    /// red, kayıt bağlanmadan önce veriliyor.
    func testAShapeThatIsNotAboutWorkIsRejectedByTheTopic() throws {
        let other = try XCTUnwrap(catalog.blueprints.first {
            $0.ageRange == band && $0.interests.isEmpty
        })
        XCTAssertNotNil(jobs.rejection(blueprint: other),
                        "\(other.id.rawValue) meslek sözcüğü taşımıyor ama konu onu kabul ediyor")

        let aboutWork = try XCTUnwrap(catalog.blueprints.first { $0.interests.contains("jobs") })
        XCTAssertNil(jobs.rejection(blueprint: aboutWork))
    }

    /// Konu seçiliyken yalnızca meslek şekilleri kabul ediliyor.
    func testOnlyWorkShapesAreAdmissibleUnderTheTopic() {
        let (admitted, _) = BlueprintSelector().admissible(catalog: catalog, intent: intent("topic_learning_jobs"))
        XCTAssertFalse(admitted.isEmpty)
        for blueprint in admitted {
            XCTAssertTrue(blueprint.interests.contains("jobs"),
                          "\(blueprint.id.rawValue) meslek masalı değil ama konuya giriyor")
        }
    }

    // MARK: - Repertuar

    /// Konu kapısı üç mekanizma istiyor, ve meslek üçünü GERÇEKTEN kuruyor —
    /// aynı şeklin üç çekimi değil.
    func testWorkStoriesOfferThreeDistinctMechanisms() throws {
        let composer = OfflineStoryComposer()
        var mechanisms = Set<String>()
        var occupations = Set<String>()
        for i in 1...30 {
            let story = try composer.compose(catalog: catalog,
                                             intent: intent("topic_learning_jobs", seed: "jobs-\(i)"))
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id == story.blueprintID })
            mechanisms.insert(try XCTUnwrap(blueprint.mechanism))
            occupations.insert(try XCTUnwrap(story.content.companion.occupation?.rawValue))
        }
        XCTAssertGreaterThanOrEqual(mechanisms.count, CatalogStoryTopic.minimumMechanisms,
                                    "meslek konusu \(mechanisms.sorted()) ile kuruluyor")
        XCTAssertEqual(occupations.count, 3, "üç meslek de çıkmalı: \(occupations.sorted())")
    }

    /// Masalın arkadaşı her zaman bir insan, ve her zaman mesleği yazılı biri.
    func testEveryWorkStoryBindsAPersonWithAnOccupation() throws {
        let composer = OfflineStoryComposer()
        for i in 1...20 {
            let story = try composer.compose(catalog: catalog,
                                             intent: intent("topic_learning_jobs", seed: "who-\(i)"))
            XCTAssertEqual(story.content.companion.nature, .person)
            XCTAssertNotNil(story.content.companion.occupation, story.content.companion.id.rawValue)
        }
    }

    /// İnsan yalnızca meslek masallarında. Mesleği hiçbir şey yapmayan bir
    /// yetişkin, masala girmesi gereksiz bir yetişkindir.
    func testAPersonNeverAppearsOutsideAWorkStory() {
        for blueprint in catalog.blueprints where !blueprint.interests.contains("jobs") {
            XCTAssertTrue(blueprint.forbids.nature.contains(.person),
                          "\(blueprint.id.rawValue) meslek masalı değil ama insanı dışlamıyor")
        }
    }

    // MARK: - Zanaat prozası

    /// Zanaatı anan satır asla mesleksiz bir arkadaşa düşmüyor.
    func testACraftLineNeverReachesACompanionWithoutThatOccupation() {
        let occupations = Set(catalog.companions.compactMap(\.occupation))
        var craftLines = 0
        for template in catalog.templates {
            for variant in template.variants where !variant.occupationRequire.isEmpty {
                craftLines += 1
                XCTAssertTrue(variant.occupationRequire.isSubset(of: occupations),
                              "\(variant.id.rawValue) tanımsız meslek istiyor")
                XCTAssertFalse(variant.suits(occupation: nil),
                               "\(variant.id.rawValue) mesleksiz arkadaşa düşebiliyor")
                XCTAssertEqual(variant.natureRequire, [.person],
                               "\(variant.id.rawValue): zanaat satırı insana yazılır")
            }
        }
        XCTAssertGreaterThanOrEqual(craftLines, 36, "üç beat × üç meslek × dört satır")
    }

    /// Her meslek, her zanaat beat'inde kendi satırlarına sahip — yoksa o
    /// meslekle o şekil kurulamaz ve konu sessizce daralır.
    func testEveryOccupationHasLinesInEveryCraftBeat() throws {
        let occupations = Set(catalog.companions.compactMap(\.occupation))
        let craftTemplates = catalog.templates
            .filter { template in template.variants.contains { !$0.occupationRequire.isEmpty } }
        XCTAssertFalse(craftTemplates.isEmpty)
        for template in craftTemplates {
            for occupation in occupations {
                let pool = template.variants.filter { !$0.occupationRequire.isEmpty
                    && $0.suits(occupation: occupation) }
                XCTAssertGreaterThanOrEqual(pool.count, 4,
                    "\(template.realizesBeat?.rawValue ?? template.id.rawValue) / "
                    + "\(occupation.rawValue): havuz \(pool.count) satır, en az dört gerekiyor")
            }
        }
    }

    // MARK: - Olgu

    /// Meslek masalının olgusu zanaatın olgusu: olgu, blueprint'in neyle ilgili
    /// olduğunu bildirdiği kayıttan gelir.
    func testAWorkStoryCarriesTheCraftsFactNotTheDiscoverys() throws {
        let composer = OfflineStoryComposer()
        var seen = Set<String>()
        for i in 1...20 {
            let story = try composer.compose(catalog: catalog,
                                             intent: intent("topic_learning_jobs", seed: "fact-\(i)"))
            let fact = try XCTUnwrap(story.fact, "meslek masalı olgusuz kaldı")
            XCTAssertEqual(fact.id, story.content.companion.factID,
                           "olgu keşiften geldi, oysa masalın konusu meslek")
            XCTAssertEqual(fact.basis, .editorial)
            seen.insert(fact.id.rawValue)
        }
        XCTAssertEqual(seen.count, 3, "üç mesleğin üç olgusu da çıkmalı")
    }

    /// Hiçbir şey bildirmeyen yapısal blueprint'te olgu keşiften gelir — yani
    /// 23 Ekim'den beri olan davranış değişmedi.
    ///
    /// Önermesi ilk yazdığımda yanlıştı: "konu seçilmemiş" ile "yapısal şekil"
    /// aynı şey değil. Konu seçilmeden de meslek şekli gelebiliyor (meslek
    /// blueprint'leri öğrenelimin parçası), ve geldiğinde olgunun zanaattan
    /// gelmesi DOĞRU. Ölçülmesi gereken şey şeklin kendi bildirimi, niyetin
    /// konusu değil.
    func testAStructuralBlueprintStillTakesTheDiscoverysFact() throws {
        let composer = OfflineStoryComposer()
        var checked = 0
        for i in 1...30 {
            let story = try composer.compose(catalog: catalog, intent: intent(nil, seed: "plain-\(i)"))
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id == story.blueprintID })
            guard blueprint.interests.isEmpty else { continue }
            checked += 1
            XCTAssertEqual(story.fact?.id, story.content.discovery.factID,
                           "\(blueprint.id.rawValue) hiçbir şey bildirmiyor ama olgu keşiften gelmedi")
        }
        XCTAssertGreaterThan(checked, 0, "ölçülecek yapısal şekil çıkmadı")
    }

    /// Olgu PROZAYA girmiyor. Gerçek bir çocuk kitabı bilgiyi anlatının içine
    /// koymaz; koyarsa kahramanı olan bir ders sayfası olur.
    func testTheFactIsNeverWrittenIntoTheStory() throws {
        let composer = OfflineStoryComposer()
        for i in 1...20 {
            let story = try composer.compose(catalog: catalog,
                                             intent: intent("topic_learning_jobs", seed: "prose-\(i)"))
            guard let fact = story.fact else { continue }
            let head = fact.statement.split(separator: " ").prefix(4).joined(separator: " ")
            for page in story.pages {
                XCTAssertFalse(page.text.contains(head),
                               "olgu cümlesi sayfaya yazılmış: \(head)")
            }
        }
    }
}
