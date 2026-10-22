import XCTest
@testable import StoryEngine

/// D2: proza satırlarının soğuması (22 Ekim 2026).
///
/// Buraya kadar soğuma yalnızca mekân, arkadaş ve nesne eksenlerinde
/// çalışıyordu; cümlenin kendisinde hiçbir hafıza yoktu. Ölçüm bedelini
/// gösterdi: aynı çocuğun elli masalında tekrar eden cümle oranı öğrenelim
/// 5-6'da %52, macerada %57. A turunda havuz iki katına çıktığında bu oran
/// neredeyse kıpırdamadı — mekân değişiyor, sayfanın cümlesi aynı yerden
/// seçiliyordu.
///
/// Ölçüm burada `VariationReport`'tan farklı ve farklı olmak zorunda: o,
/// birbirinden bağımsız seed'lerle çeşitliliği sayıyor (havuzun genişliği),
/// bu ise masalları **sırayla** kuruyor ve her masalın satırlarını sonrakine
/// geçmiş olarak veriyor (bir çocuğun arka arkaya okuduğu şey).
final class ProseCooldownTests: XCTestCase {

    private var catalog: ContentCatalog!

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private struct Run {
        var repeatedRate: Double
        var distinctLines: Int
        var stories: Int
    }

    /// Bir çocuğun arka arkaya okuduğu masallar. `carryHistory` kapalıyken
    /// geçmiş hiç verilmez, yani D2'den önceki davranış.
    private func sequence(mode: StoryMode, band: AgeBand, count: Int, carryHistory: Bool) -> Run {
        var recent: [RecentContent] = []
        var seenSentences = Set<String>()
        var seenLines = Set<ContentID>()
        var repeated = 0
        var total = 0
        var stories = 0

        for index in 1...count {
            let intent = OfflineStoryIntent(
                childName: "Ada", seed: "d2-\(index)", mode: mode, ageBand: band,
                recent: carryHistory ? recent : [])
            guard let story = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent) else { continue }
            stories += 1

            for page in story.pages {
                for sentence in VariationReport.sentences(of: page) {
                    total += 1
                    if !seenSentences.insert(sentence).inserted { repeated += 1 }
                }
                seenLines.formUnion(page.variantIDs)
            }
            // En yenisi önce, tıpkı uygulamanın verdiği sıra.
            recent.insert(RecentContent(
                blueprintID: story.blueprintID,
                settingID: story.content.setting.id,
                companionID: story.content.companion.id,
                discoveryID: story.content.discovery.id,
                variantIDs: Set(story.pages.flatMap(\.variantIDs))), at: 0)
        }
        return Run(repeatedRate: total == 0 ? 0 : Double(repeated) / Double(total),
                   distinctLines: seenLines.count, stories: stories)
    }

    // MARK: - İyileşme

    /// Geçmiş taşındığında tekrar eden cümle oranı düşüyor ve kullanılan farklı
    /// satır sayısı artıyor.
    ///
    /// Eşik sabit sayıya bağlı değil: iki ölçüm aynı turda alınıp karşılaştırılıyor,
    /// yani içerik büyüdükçe test kendiliğinden doğru kalır. İddia yön iddiası —
    /// "geçmiş işe yarıyor" — çünkü korunmak istenen şey bugünkü rakam değil
    /// mekanizmanın kendisi.
    func testCarryingHistoryLowersRepetition() {
        for (mode, band) in [(StoryMode.learning, AgeBand(lowerBound: 5, upperBound: 6)),
                             (StoryMode.adventure, AgeBand(lowerBound: 5, upperBound: 6))] {
            let without = sequence(mode: mode, band: band, count: 12, carryHistory: false)
            let with = sequence(mode: mode, band: band, count: 12, carryHistory: true)
            XCTAssertEqual(with.stories, without.stories, "\(mode.rawValue): masal sayısı değişmemeli")
            XCTAssertLessThan(
                with.repeatedRate, without.repeatedRate,
                "\(mode.rawValue) \(band): geçmiş tekrarı azaltmadı "
                + "(%\(Int(without.repeatedRate * 100)) → %\(Int(with.repeatedRate * 100)))")
            XCTAssertGreaterThan(
                with.distinctLines, without.distinctLines,
                "\(mode.rawValue) \(band): geçmiş daha fazla satır kullandırmadı "
                + "(\(without.distinctLines) → \(with.distinctLines))")
            print("D2 \(mode.rawValue) \(band): tekrar %\(Int(without.repeatedRate * 100))"
                  + " → %\(Int(with.repeatedRate * 100)), farklı satır "
                  + "\(without.distinctLines) → \(with.distinctLines)")
        }
    }

    // MARK: - Bozulmaması gerekenler

    /// Geçmişi olmayan bir niyet **bit bit** eskisi gibi masal kuruyor.
    ///
    /// D2'nin en önemli kısıtı bu: alan eklenmesi, bu alandan önce yazılmış
    /// hiçbir masalı değiştirmemeli. Aksi hâlde "aynı seed aynı kitap" sözü
    /// kırılır ve bütün fixture testleri sebepsiz kayar.
    ///
    /// İlk hâli yanlış yazılmıştı ve yalnızca şansla geçiyordu: karşılaştırma
    /// `recent: [RecentContent(settingID:)]` ile yapılıyordu, ama bir mekân
    /// kimliği FAZ 12'den beri mekân seçimini meşru biçimde soğutuyor —
    /// mekân değişince bağlanan içerik, dolayısıyla uygun satır havuzu da
    /// değişir. Yani test, D2'yi değil FAZ 12'yi sınıyordu. Doğru iddia: satır
    /// kimliği taşımayan bir geçmiş **satır seçimine** hiçbir şey eklemez, ve
    /// bu ancak içerik eksenleri sabit tutulduğunda görülebilir.
    func testAnIntentWithoutLineHistoryChoosesTheSameLines() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let axes = RecentContent(settingID: "setting_garden_001",
                                 companionID: "companion_fox_pilot_001")
        func build(_ recent: [RecentContent]) throws -> ComposedStory {
            try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Ada", seed: "d2-sabit", mode: .learning,
                                           ageBand: band, recent: recent))
        }
        // Aynı içerik ekseni geçmişi, tek fark satır kimliklerinin olmaması.
        let withoutLines = try build([axes])
        let alsoWithoutLines = try build([RecentContent(
            settingID: axes.settingID, companionID: axes.companionID, variantIDs: [])])
        XCTAssertEqual(withoutLines.pages.flatMap(\.variantIDs),
                       alsoWithoutLines.pages.flatMap(\.variantIDs))

        // Ve geçmiş hiç verilmediğinde de masal eskisi gibi kuruluyor.
        let none = try build([])
        let nilRecent = try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Ada", seed: "d2-sabit",
                                       mode: .learning, ageBand: band))
        XCTAssertEqual(none.pages.flatMap(\.variantIDs), nilRecent.pages.flatMap(\.variantIDs))
    }

    /// Determinizm korunuyor: aynı geçmiş, aynı seed, aynı kitap.
    func testTheSameHistoryGivesTheSameBook() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let history = [RecentContent(variantIDs: ["mc_guide_03", "na_01", "ex_02"])]
        func build() throws -> [ContentID] {
            try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Ada", seed: "d2-det", mode: .learning,
                                           ageBand: band, recent: history)
            ).pages.flatMap(\.variantIDs)
        }
        XCTAssertEqual(try build(), try build())
    }

    /// Soğuma süzgeç değil: üç varyantlı bir beat'te hepsi geçmişte olsa bile
    /// masal kurulabiliyor.
    func testEveryLineBeingColdStillBuildsAStory() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let everything = Set(catalog.templates.flatMap(\.variants).map(\.id))
        let story = try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Ada", seed: "d2-hepsi", mode: .learning,
                                       ageBand: band,
                                       recent: [RecentContent(variantIDs: everything)]))
        XCTAssertFalse(story.pages.isEmpty)
        XCTAssertTrue(story.isClean)
    }

    /// Soğuma eğrisi iki eksende aynı: "üç masal önce geçti" içerik kaydı için
    /// de proza satırı için de aynı ağırlığı veriyor.
    func testBothAxesShareOneCooldownCurve() {
        for ago in 0..<SelectionScoring.cooldownWindow {
            var recordHistory: [ContentID?] = Array(repeating: nil, count: ago)
            recordHistory.append("x")
            let record = SelectionScoring.weight(
                id: "x", matchesInterest: false, recent: recordHistory)

            var lineHistory: [Set<ContentID>] = Array(repeating: [], count: ago)
            lineHistory.append(["x"])
            let line = SelectionScoring.variantWeight(id: "x", recent: lineHistory)

            XCTAssertEqual(record, line, accuracy: 0.0001, "\(ago) masal önce")
        }
        XCTAssertEqual(SelectionScoring.variantWeight(id: "x", recent: []), 1)
    }
}
