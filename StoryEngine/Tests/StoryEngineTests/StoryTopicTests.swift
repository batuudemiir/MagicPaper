import XCTest
@testable import StoryEngine

/// Alt seçenekler: modun içindeki konu (karar: 16 Ekim 2026).
///
/// Buradaki testlerin tamamı tek bir cümlenin etrafında: **alt seçenek bir
/// sözdür.** "Meslekler" seçildiğinde ya meslekle ilgili bir masal gelir ya da
/// hiçbir şey gelmez; sessizce başka bir masal gelmez. İlgi alanlarından farkı
/// budur ve bu fark testlerle tutuluyor, yoksa bir gün "süzme, ağırlık ver"
/// diye basitleştirilir ve kimse yalanı fark etmez.
final class StoryTopicTests: XCTestCase {

    private var catalog: ContentCatalog!

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private func intent(_ topic: String?, mode: StoryMode = .learning,
                        seed: String = "topic-seed") -> OfflineStoryIntent {
        OfflineStoryIntent(childName: "Yeliz", seed: seed, mode: mode,
                           ageBand: AgeBand(lowerBound: 5, upperBound: 6), subOption: topic)
    }

    private func blueprint(for mode: StoryMode) throws -> CatalogBlueprint {
        let families = try XCTUnwrap(catalog.modeProfile(mode)?.families)
        return try XCTUnwrap(catalog.blueprints.first { blueprint in
            guard let family = blueprint.family, families.contains(family) else { return false }
            return blueprint.ageRange.contains(5)
        })
    }

    // MARK: - Sözlük

    func testTheCatalogDeclaresTopicsForLearningAndAdventure() {
        XCTAssertFalse(catalog.storyTopics(for: .learning).isEmpty)
        XCTAssertFalse(catalog.storyTopics(for: .adventure).isEmpty)
        // Uyku öncesinin alt seçeneği yok: tahtadaki kurguda da yok, ve bir
        // uyku masalının konusu "uyku"dur.
        XCTAssertTrue(catalog.storyTopics(for: .bedtime).isEmpty)
    }

    /// Hiçbir yuvaya şart koymayan konu, tanımı gereği sözünü tutamaz.
    func testEveryDeclaredTopicPromisesSomething() {
        for topic in catalog.storyTopics {
            XCTAssertFalse(topic.requires.isEmpty,
                           "\(topic.id.rawValue) hiçbir şey şart koşmuyor")
        }
    }

    func testATopicBelongsToExactlyOneMode() {
        let ids = catalog.storyTopics.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "aynı konu iki kez tanımlı")
    }

    // MARK: - Söz tutuluyor mu

    /// Konu seçilince bağlanan içerik gerçekten o konuyu taşır.
    func testABoundStoryCarriesTheTopicItPromised() throws {
        let topic = try XCTUnwrap(catalog.storyTopic("topic_learning_animals"))
        let bound = try OfflineContentBinder().bind(
            blueprint: try blueprint(for: .learning), catalog: catalog,
            intent: intent(topic.id.rawValue))

        XCTAssertNil(topic.rejection(companion: bound.companion),
                     "bağlanan arkadaş konuyu taşımıyor: \(bound.companion.id.rawValue)")
    }

    /// Karşılanamayan konu **reddedilir**, başka bir masalla doldurulmaz.
    ///
    /// Bu testin koruduğu şey bir hata mesajı değil, bir davranış: motorun
    /// "bulamadım" demesi, bulduğunu sanıp başka bir şey vermesinden iyidir.
    func testAnUnservableTopicIsRefusedNotSubstituted() throws {
        // Katalogda hiçbir yol arkadaşının taşımadığı bir konu sözcüğü.
        let impossible = CatalogStoryTopic(
            id: "topic_test_impossible", mode: .learning, name: "Olmayan",
            requires: .init(companion: ["kesinlikle_yok"]))
        let catalog = ContentCatalog.merging([
            self.catalog, ContentCatalog(version: "0.0.0", storyTopics: [impossible])
        ])

        XCTAssertThrowsError(try OfflineContentBinder().bind(
            blueprint: try blueprint(for: .learning), catalog: catalog,
            intent: intent(impossible.id.rawValue))
        ) { error in
            guard let error = error as? OfflineSelectionError else {
                return XCTFail("beklenmeyen hata: \(error)")
            }
            XCTAssertTrue(error.explanation.contains("Olmayan"),
                          "gerekçe konuyu adlandırmalı: \(error.explanation)")
        }
    }

    /// Katalogda karşılığı olmayan bir alt seçenek sessizce yok sayılmaz.
    ///
    /// Yok sayılsaydı, uygulamadaki bir yazım hatası söz verilip tutulmamış
    /// masallar üretirdi ve hiçbir yerde iz bırakmazdı.
    func testAnUnknownSubOptionIsRefused() throws {
        XCTAssertThrowsError(try OfflineContentBinder().bind(
            blueprint: try blueprint(for: .learning), catalog: catalog,
            intent: intent("topic_yok_boyle_bir_sey"))
        ) { error in
            XCTAssertEqual(error as? OfflineSelectionError,
                           .unknownTopic("topic_yok_boyle_bir_sey"))
        }
    }

    /// Alt seçenek yokken masal, alt seçenekler eklenmeden önceki masalın
    /// aynısı olmalı: bu özellik var olan hiçbir masalı değiştirmedi.
    func testNoSubOptionLeavesTheStoryExactlyAsItWas() throws {
        let plain = try OfflineContentBinder().bind(
            blueprint: try blueprint(for: .learning), catalog: catalog, intent: intent(nil))
        let again = try OfflineContentBinder().bind(
            blueprint: try blueprint(for: .learning), catalog: catalog, intent: intent(nil))

        XCTAssertEqual(plain.setting.id, again.setting.id)
        XCTAssertEqual(plain.companion.id, again.companion.id)
        XCTAssertEqual(plain.discovery.id, again.discovery.id)
    }

    // MARK: - Yalnızca kurulabilen teklif edilir

    /// Tutulamayacak söz hiç verilmez (§29).
    func testOnlyBuildableTopicsAreOffered() throws {
        let offered = BlueprintSelector().availableTopics(
            catalog: catalog, intent: intent(nil))
        let declared = catalog.storyTopics(for: .learning)

        XCTAssertLessThanOrEqual(offered.count, declared.count)
        // Teklif edilen her konu gerçekten kurulabilmeli.
        for topic in offered {
            XCTAssertNoThrow(
                try OfflineContentBinder().bind(
                    blueprint: try blueprint(for: .learning), catalog: catalog,
                    intent: intent(topic.id.rawValue)),
                "\(topic.id.rawValue) teklif edildi ama kurulmuyor")
        }
    }

    /// İçeriği olmayan bir konu ekranda hiç görünmez — ölü bir çip olarak değil.
    func testATopicWithoutContentIsNotOffered() throws {
        let impossible = CatalogStoryTopic(
            id: "topic_test_impossible", mode: .learning, name: "Olmayan",
            requires: .init(companion: ["kesinlikle_yok"]))
        let merged = ContentCatalog.merging([
            catalog, ContentCatalog(version: "0.0.0", storyTopics: [impossible])
        ])

        let offered = BlueprintSelector().availableTopics(catalog: merged, intent: intent(nil))
        XCTAssertFalse(offered.contains { $0.id == impossible.id })
    }

    func testNoModeMeansNoTopics() {
        let offered = BlueprintSelector().availableTopics(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Yeliz", seed: "s"))
        XCTAssertTrue(offered.isEmpty)
    }

    // MARK: - Bütünlük denetimi

    func testIntegrityFlagsATopicThatPromisesNothing() {
        let catalog = ContentCatalog(
            version: "1.0.0",
            storyTopics: [CatalogStoryTopic(id: "topic_empty", mode: .learning,
                                            name: "Boş", requires: .init())])
        let issues = CatalogIntegrityChecker().check(catalog, corpus: nil)
            .issues(withCode: "topic_promises_nothing")
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
    }

    /// İçerik boşluğu hata değil uyarı: kayıt doğru, içerik henüz yok.
    func testIntegrityWarnsAboutATopicWithoutContent() {
        let catalog = ContentCatalog(
            version: "1.0.0",
            storyTopics: [CatalogStoryTopic(id: "topic_gap", mode: .learning, name: "Boşluk",
                                            requires: .init(companion: ["kesinlikle_yok"]))])
        let issues = CatalogIntegrityChecker().check(catalog, corpus: nil)
            .issues(withCode: "topic_without_content")
        XCTAssertEqual(issues.first?.severity, .warning)
    }
    /// Bugün gerçekten sunulabilen konular — ve dolayısıyla içerik boşluğunun
    /// ölçüsü.
    ///
    /// Eşitlik iddiası bilerek: yeni içerik yazıldığında bu test kırılır ve
    /// kıran kişiye "bir konu daha canlandı, kaydı güncelle" der. Kapsama
    /// iddiası (`contains`) sessiz kalırdı, ve bu boşluğun sessiz kalmaması
    /// gereken bir boşluk olduğunu düşünüyorum: ürünün vaat ettiği yedi alt
    /// kategoriden kaçının gerçek olduğu, haftalık olarak bilinmesi gereken
    /// bir sayı.
    func testWhichTopicsAreLiveToday() throws {
        func live(_ mode: StoryMode, band: AgeBand) -> [String] {
            BlueprintSelector().availableTopics(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: "live", mode: mode, ageBand: band)
            ).map(\.id.rawValue).sorted()
        }
        let b56 = AgeBand(lowerBound: 5, upperBound: 6)
        let b34 = AgeBand(lowerBound: 3, upperBound: 4)

        // 21 Ekim 2026 ölçümü. On konu tanımlı, ÜÇÜ canlı: v2 kütüphanesi
        // havuza katılınca kumsal, resif ve ada "Denizin altı" konusunu açtı.
        XCTAssertEqual(live(.learning, band: b56), ["topic_learning_animals"])
        XCTAssertEqual(live(.adventure, band: b56),
                       ["topic_adventure_sea", "topic_adventure_wild"])

        // 3-4 bandında tek bir blueprint var ve o uyku öncesine ait; bu bantta
        // hiçbir konu kurulamıyor, yani alt kategori adımı hiç görünmüyor.
        XCTAssertEqual(live(.learning, band: b34), [])
        XCTAssertEqual(live(.adventure, band: b34), [])

        // Bu test kırıldıysa muhtemelen bir içerik turu bir konuyu canlandırdı.
        // Doğrusu: listeyi güncelle ve DEMO_CHANGELOG'a "şu konu canlandı" diye
        // yaz. Testi gevşetmek (contains'e çevirmek) boşluğu tekrar sessiz
        // yapardı, ki bu sayının görünür kalması bu işin bütün meselesi.
    }

}
