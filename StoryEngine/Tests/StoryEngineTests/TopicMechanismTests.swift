import XCTest
@testable import StoryEngine

/// Konunun kabul ölçütü (B turu, 22 Ekim 2026).
///
/// Planın kuralı: bir konu, kurulabildiği her bantta **en az üç yapısal olarak
/// farklı olay örgüsü mekanizması** olmadan teklif edilmez. Aynı blueprint'i
/// farklı hayvan ya da mekânla çalıştırmak bu koşulu karşılamaz.
///
/// Kural neden mekanizmada: A turu havuzu iki katına çıkardı, mekanizma sayısı
/// hiç değişmedi (8/4/1/1), ve çocuğun aldığı masal **şekli** de değişmedi.
/// Blueprint ya da nesne saymak bu farkı göremiyor; mekanizma sayıyor.
final class TopicMechanismTests: XCTestCase {

    private var catalog: ContentCatalog!
    private let selector = BlueprintSelector()
    private let binder = OfflineContentBinder()

    private static let bands = [AgeBand(lowerBound: 3, upperBound: 4),
                                AgeBand(lowerBound: 5, upperBound: 6)]

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private func intent(_ mode: StoryMode, _ band: AgeBand, topic: String? = nil) -> OfflineStoryIntent {
        OfflineStoryIntent(childName: "Ada", seed: "kriter", mode: mode,
                           ageBand: band, subOption: topic)
    }

    /// Bu konunun bu bantta gerçekten kurabildiği mekanizmalar.
    private func mechanisms(of topic: CatalogStoryTopic, _ mode: StoryMode, _ band: AgeBand) -> Set<String> {
        let probe = intent(mode, band, topic: topic.id.rawValue)
        let (candidates, _) = selector.admissible(catalog: catalog, intent: probe)
        var found = Set<String>()
        for blueprint in candidates
        where (try? binder.bind(blueprint: blueprint, catalog: catalog, intent: probe)) != nil {
            found.insert(blueprint.mechanism ?? blueprint.id.rawValue)
        }
        return found
    }

    private func offeredTopics(_ mode: StoryMode, _ band: AgeBand) -> [CatalogStoryTopic] {
        selector.availableTopics(catalog: catalog, intent: intent(mode, band))
    }

    // MARK: - Ölçütün kendisi

    /// Teklif edilen her konu, teklif edildiği bantta ölçütü karşılıyor.
    ///
    /// B turunun geri kalanını otomatik olarak bu kurala bağlayan test: yeni
    /// bir konu ince kaldığı hâlde canlıya alınırsa burada kırmızı döner.
    func testEveryOfferedTopicMeetsTheMechanismFloor() {
        var checked = 0
        for band in Self.bands {
            for mode in StoryMode.allCases {
                for topic in offeredTopics(mode, band) {
                    let found = mechanisms(of: topic, mode, band)
                    checked += 1
                    XCTAssertGreaterThanOrEqual(
                        found.count, CatalogStoryTopic.minimumMechanisms,
                        "\(mode.rawValue) \(band) '\(topic.id.rawValue)' yalnızca "
                        + "\(found.count) mekanizma kurabiliyor: \(found.sorted()). "
                        + "İnce bir konu, aynı masalın dekoru değişmiş hâlidir.")
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "hiç konu teklif edilmiyor: ölçüm bir şey sınamadı")
    }

    /// Ölçütü karşılamayan bir konu teklif edilmiyor, ama katalogdan da
    /// silinmiyor: üçüncü mekanizma yazıldığı gün kendiliğinden geri gelsin.
    ///
    /// Bugünün örneği "Denizin altı": iki mekanizma (IV-1, IV-2). Kayıt burada
    /// duruyor ki eksiklik görünür olsun; sayı üçe çıktığında bu test
    /// kırmızıya döner ve kıran kişi konuyu canlı listeye alır.
    func testAThinTopicIsDefinedButNotOffered() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let sea = try XCTUnwrap(
            catalog.storyTopics.first { $0.id.rawValue == "topic_adventure_sea" },
            "konu katalogdan silinmiş olabilir")
        let found = mechanisms(of: sea, .adventure, band)
        XCTAssertEqual(found.count, 2, "Denizin altı artık \(found.sorted()) kuruyor; "
                       + "üçe çıktıysa konu canlı listeye alınmalı")
        XCTAssertFalse(offeredTopics(.adventure, band).contains(sea))
    }

    // MARK: - Hazine avı

    /// Konu 5-6'da canlı ve ölçütü **aşıyor**: dört mekanizma.
    ///
    /// Tek bir yeni blueprint yazılmadan: `absence` ailesi (IV-1 persistence,
    /// IV-2 retracing) konuyu doğrudan taşıyor, `threshold` ailesi de (II-1,
    /// II-2) hazine izini kendi engeliyle anlatabiliyor. Plan bunu "en ucuz
    /// yeni konu" diye tahmin etmişti; ölçüm doğruladı.
    func testTreasureIsOfferedAtFiveSixWithFourMechanisms() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let treasure = try XCTUnwrap(
            catalog.storyTopics.first { $0.id.rawValue == "topic_adventure_treasure" })
        XCTAssertTrue(offeredTopics(.adventure, band).contains(treasure))
        XCTAssertEqual(mechanisms(of: treasure, .adventure, band).count, 4)
    }

    /// Söz tutuluyor: konu seçildiğinde kurulan her masalın keşfi `treasure`
    /// taşıyor, ve hiçbir seed boşa düşmüyor.
    ///
    /// Alt kategori bir süzgeç (katı söz) olduğu için asıl sınav bu: çip
    /// görünüyor olması yetmez, arkasındaki masalın gerçekten o konuda olması
    /// gerekir.
    func testEveryTreasureStoryActuallyCarriesTreasure() {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        var mechanisms = Set<String>()
        var failures: [String] = []

        for index in 1...50 {
            let intent = OfflineStoryIntent(
                childName: "Ada", seed: "hazine-\(index)", mode: .adventure,
                ageBand: band, subOption: "topic_adventure_treasure")
            guard let story = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent) else {
                failures.append("hazine-\(index)")
                continue
            }
            XCTAssertTrue(
                story.content.discovery.interests.contains("treasure"),
                "seed hazine-\(index): keşif '\(story.content.discovery.id.rawValue)' "
                + "hazine taşımıyor, söz tutulmadı")
            if let mechanism = catalog.blueprints.first(where: { $0.id == story.blueprintID })?.mechanism {
                mechanisms.insert(mechanism)
            }
        }
        XCTAssertTrue(failures.isEmpty, "masal kurulamayan seed'ler: \(failures)")
        XCTAssertGreaterThanOrEqual(mechanisms.count, CatalogStoryTopic.minimumMechanisms,
                                    "50 seed yalnızca \(mechanisms.sorted()) üretti")
    }

    /// 3-4'te teklif edilmiyor, ve sebebi konu değil: o bantta macera modunun
    /// hiç içeriği yok. Konu bantta içerik yazıldığı gün kendiliğinden görünür.
    func testTreasureIsNotOfferedAtThreeFourBecauseAdventureIsEmptyThere() {
        let band = AgeBand(lowerBound: 3, upperBound: 4)
        XCTAssertTrue(offeredTopics(.adventure, band).isEmpty)
        let (candidates, _) = selector.admissible(catalog: catalog, intent: intent(.adventure, band))
        XCTAssertTrue(candidates.isEmpty,
                      "3-4 macera artık blueprint buluyor: konu kapısı yeniden ölçülmeli")
    }
}
