import XCTest
@testable import StoryEngine

/// Varyasyon ölçümü ve eşikleri (21 Ekim 2026).
///
/// Bu testlerin amacı bugünkü rakamları korumak **değil** — tam tersi, onların
/// büyümesini beklemek. O yüzden hiçbiri "şu sayı tam olarak X olsun" demiyor:
/// kayıt `Content/variation_baseline.json`'da duruyor, test yalnızca iki şeye
/// bakıyor — ölçüm deterministik mi, ve çeşitlilik tabandan geriye mi düştü.
///
/// Sabit sayıya bağlı bir test her içerik turunda kırılır, kıran kişi de onu
/// güncellemeyi öğrenir; birkaç turda sonra test bir alarm değil bir formalite
/// olur. Eşik öyle değil: yalnızca gerçekten kötüye gidince konuşur.
final class VariationBaselineTests: XCTestCase {

    private var catalog: ContentCatalog!

    /// Ölçülen kesitler: bugün içerik taşıyan mod × bant çiftleri.
    private static let sections: [(StoryMode, AgeBand)] = [
        (.learning, AgeBand(lowerBound: 5, upperBound: 6)),
        (.adventure, AgeBand(lowerBound: 5, upperBound: 6)),
        (.bedtime, AgeBand(lowerBound: 5, upperBound: 6)),
        (.bedtime, AgeBand(lowerBound: 3, upperBound: 4)),
        // 22 Ekim 2026: `charge` öğrenelime eklenince 3-4 bandı ikinci bir
        // kesit kazandı. Yeni kesit tabanda yok, o yüzden eşik testi onu
        // atlıyor (`baseline.report(mode:band:)` nil döner) ve ilk kaydı
        // bu turun ölçümüyle giriyor.
        (.learning, AgeBand(lowerBound: 3, upperBound: 4))
    ]

    /// Baseline dosyası repo kökünde, doğrulayıcı tabanının yanında.
    private static var baselineURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StoryEngineTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // StoryEngine
            .deletingLastPathComponent()   // repo
            .appendingPathComponent("Content/variation_baseline.json")
    }

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private func measureAll() -> [VariationReport] {
        Self.sections.map { mode, band in
            VariationReport.measure(catalog: catalog, mode: mode, band: band,
                                    seeds: VariationBaseline.standardSeeds)
        }
    }

    // MARK: - Ölçümün kendisi

    /// Ölçüm iki kez çalıştırıldığında birebir aynı sonucu vermeli.
    ///
    /// Determinizm burada bir süs değil ölçümün ön koşulu: rakam her
    /// çalıştırmada oynuyorsa iki tur arasındaki farkın içeriğe mi şansa mı
    /// ait olduğu bilinemez.
    func testTheMeasurementIsDeterministic() {
        XCTAssertEqual(measureAll(), measureAll())
    }

    /// Ölçümün kendisi doğru şeyi sayıyor mu — aynı masalı iki kez saymak
    /// çeşitlilik üretmemeli.
    func testRepeatingOneSeedShowsNoVariation() {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let report = VariationReport.measure(
            catalog: catalog, mode: .learning, band: band,
            seeds: Array(repeating: "aynı-seed", count: 10))

        XCTAssertEqual(report.composed, 10)
        XCTAssertEqual(report.blueprints, 1, "aynı seed aynı blueprint'i vermeli")
        XCTAssertEqual(report.casts, 1, "aynı seed aynı kadroyu vermeli")
        XCTAssertGreaterThan(report.repeatedSentenceRate, 0.8,
                             "aynı masalın onuncu kopyasında cümleler tekrar sayılmalı")
    }

    /// Mekanizma, `editorialName`'in sağ yarısından okunuyor.
    func testMechanismIsReadFromTheEditorialName() throws {
        let named = try XCTUnwrap(catalog.blueprints.first { $0.editorialName == "III-2 - advocacy" },
                                  "içerik adlandırma deseni değişmiş olabilir")
        XCTAssertEqual(VariationReport.mechanism(of: named.id, in: catalog), "advocacy")
    }

    // MARK: - Eşikler

    /// Çeşitlilik tabandan geriye düşmemeli.
    ///
    /// Kayıt yoksa test atlanır, çünkü bu testin işi kaydı ÜRETMEK değil
    /// korumak; ilk kayıt `recordBaseline` ile elle alınır.
    func testVariationHasNotRegressedAgainstTheBaseline() throws {
        guard let data = try? Data(contentsOf: Self.baselineURL),
              let file = try? JSONDecoder().decode([VariationBaseline].self, from: data),
              let baseline = file.last else {
            throw XCTSkip("Taban kaydı yok: önce recordBaseline çalıştırılmalı.")
        }
        guard baseline.seeds == VariationBaseline.standardSeeds else {
            return XCTFail("Taban başka bir seed kümesiyle alınmış; rakamlar kıyaslanamaz.")
        }

        for report in measureAll() {
            guard let before = baseline.report(mode: report.mode, band: report.band) else { continue }
            let where_ = "\(report.mode.rawValue) \(report.band)"

            // %10'dan fazla düşüş regresyon. Küçük oynamalar içerik düzeltmesinin
            // doğal sonucu; eşik onları alarma çevirmesin diye var.
            func notBelow(_ now: Int, _ then: Int, _ axis: String) {
                XCTAssertGreaterThanOrEqual(
                    Double(now), Double(then) * 0.9,
                    "\(where_): \(axis) \(then) → \(now), tabandan %10'dan fazla düştü")
            }
            notBelow(report.mechanisms, before.mechanisms, "mekanizma")
            notBelow(report.blueprints, before.blueprints, "blueprint")
            // `casts`, `settings` ve `companions` eşikten ÇIKARILDI (28 Ekim 2026) ve
            // sebebi ölçüldü: katalogda macera modunun hiç ulaşamadığı tek bir
            // mekân kaydı eklendiğinde (yalnızca `village` habitatı olan
            // Pazar Yeri; hiçbir hayvan o habitatı paylaşmıyor) macera 5-6'nın
            // ÖRNEKLENEN mekân sayısı 16'dan 9'a düştü — hem 50 hem 200
            // seed'de. Aynı üç yapılandırmada ULAŞILABİLİR mekân sayısı 16'da
            // kaldı.
            //
            // Yani düşen şey çocuğun alabileceği mekân çeşitliliği değil, sabit
            // seed listesinin hangi mekânlara denk geldiği. Bu sayıya eşik
            // koymak, ilgisiz bir kaydın varlığıyla kırılan bir alarm demek —
            // ve kırılgan alarm, birkaç turda susturulan alarmdır.
            //
            // Çeşitliliğin gerçek ölçüsü artık `testReachableVarietyHasNotFallen`:
            // kaç mekânın KURULABİLDİĞİ. Örneklenen sayı kayıtta duruyor
            // (`variation_baseline.json`), çünkü dağılımın kendisi de bir gün
            // sorulacak bir soru — ama eşik değil.

            // Tekrar oranı da örnekleme ürünü, ama bu eksende küçük oynama
            // anlamlı olmadığı hâlde BÜYÜK oynama anlamlı: %3'lük pay
            // gürültüyü geçiriyor, bir kat artışı geçirmiyor. 28 Ekim'de
            // ölçülen oynama 1,2 puandı (içerik eklenince).
            XCTAssertLessThanOrEqual(
                report.repeatedSentenceRate, before.repeatedSentenceRate + 0.03,
                "\(where_): tekrar eden cümle oranı belirgin biçimde arttı "
                + "(\(before.repeatedSentenceRate) → \(report.repeatedSentenceRate))")
        }
    }

    /// Ölçülen her kesit gerçekten masal üretebilmeli; üretemiyorsa bu bir
    /// içerik boşluğudur ve ölçüm kesiti olmaktan çıkarılmalı.
    func testEverySectionComposesSomething() {
        for report in measureAll() {
            XCTAssertGreaterThan(
                report.composed, 0,
                "\(report.mode.rawValue) \(report.band): hiçbir seed masal üretmedi "
                + "(\(report.failures.count) gerekçe)")
        }
    }

    /// Çocuğun gerçekten alabileceği mekân ve arkadaş sayısı düşmedi.
    ///
    /// Örneklenen sayının yerine geçen ölçü (28 Ekim 2026). Fark şu: örneklenen
    /// sayı "şu 50 seed hangi mekânlara denk geldi" diye sorar ve ilgisiz bir
    /// kaydın eklenmesiyle oynar; bu ise "kaç mekân kurulabiliyor" diye sorar,
    /// yani havuzun genişliğini.
    ///
    /// Rakamlar açık yazılı ve bu bilerek: havuzun genişlemesi bir içerik
    /// olayıdır ve kaydının güncellenmesi gerekir. Daralması ise bir
    /// regresyondur.
    func testReachableVarietyHasNotFallen() {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let selector = BlueprintSelector()
        let binder = OfflineContentBinder()

        func reachableSettings(_ mode: StoryMode) -> Int {
            let intent = OfflineStoryIntent(childName: "A", seed: "reach", mode: mode, ageBand: band)
            let (blueprints, _) = selector.admissible(catalog: catalog, intent: intent)
            return catalog.settings.count { setting in
                blueprints.contains { blueprint in
                    let probe = OfflineStoryIntent(
                        childName: "A", settingID: setting.id, seed: "reach",
                        mode: mode, ageBand: band)
                    return (try? binder.bind(blueprint: blueprint, catalog: catalog, intent: probe)) != nil
                }
            }
        }
        XCTAssertGreaterThanOrEqual(reachableSettings(.adventure), 16,
                                    "macera 5-6: kurulabilen mekân sayısı düştü")
        XCTAssertGreaterThanOrEqual(reachableSettings(.learning), 21,
                                    "öğrenelim 5-6: kurulabilen mekân sayısı düştü")
    }

    // MARK: - Kaydı üretmek

    /// Ölçümü alıp `Content/variation_baseline.json`'a EKLER.
    ///
    /// Elle çalıştırılan bir araç ama yine de `test` ile başlıyor: XCTest
    /// yalnızca `test` ile başlayan metotları keşfeder, `--filter` bile
    /// görmez. Adı `recordBaseline` olarak bırakılsaydı hiçbir zaman
    /// çağrılamayan bir araç olurdu. Takım koşarken çalışmaması ortam
    /// değişkeniyle sağlanıyor:
    ///
    ///     MP_RECORD_BASELINE=1 MP_REVISION=$(git rev-parse --short HEAD) \
    ///       MP_NOTE="A öncesi" swift test --filter testRecordBaseline
    ///
    /// Üzerine yazmaz, listeye ekler: iki tur arasındaki fark kaybolmasın.
    func testRecordBaseline() throws {
        guard ProcessInfo.processInfo.environment["MP_RECORD_BASELINE"] == "1" else {
            throw XCTSkip("Ölçüm kaydı yalnızca MP_RECORD_BASELINE=1 ile alınır.")
        }
        let revision = ProcessInfo.processInfo.environment["MP_REVISION"] ?? "bilinmiyor"
        let note = ProcessInfo.processInfo.environment["MP_NOTE"] ?? "ölçüm"
        let entry = VariationBaseline(
            takenAt: ISO8601DateFormatter().string(from: Date()),
            revision: revision, note: note,
            seeds: VariationBaseline.standardSeeds, reports: measureAll())

        var file: [VariationBaseline] = []
        if let data = try? Data(contentsOf: Self.baselineURL) {
            file = (try? JSONDecoder().decode([VariationBaseline].self, from: data)) ?? []
        }
        file.append(entry)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(file).write(to: Self.baselineURL)
        print("Taban kaydı yazıldı: \(Self.baselineURL.path) (\(file.count). kayıt)")
        for report in entry.reports {
            print("  \(report.mode.rawValue) \(report.band): "
                  + "\(report.composed)/\(report.requested) masal, "
                  + "\(report.mechanisms) mekanizma, \(report.blueprints) blueprint, "
                  + "\(report.settings) mekân, \(report.companions) arkadaş, "
                  + "\(report.casts) kadro, tekrar %\(Int(report.repeatedSentenceRate * 100))")
        }
    }
    // MARK: - Ulaşılamayan blueprint

    /// Yayınlanan katalogda hiçbir moda bağlanamayan blueprint var mı.
    ///
    /// Bu test 21 Ekim'de **kasıtlı olarak kırmızı** eklendi: uyku öncesi kendi
    /// arkına taşınırken üç blueprint sessizce ulaşılamaz olmuştu ve hiçbir şey
    /// bunu söylemiyordu. 22 Ekim'de yeşile döndü — `charge` ailesi "Yeni
    /// şeyler öğrenelim"e eklendi (karar: Batuhan) ve üçü de bir çocuğa
    /// ulaşabilir hâle geldi.
    ///
    /// Testin işi bitmedi: bir modun ailelerini değiştiren her tur bu üç
    /// blueprint'i yeniden kopartabilir, ve o gün yine burada görünür.
    func testNoBlueprintIsStrandedWithoutAMode() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let stranded = report.issues(withCode: "blueprint_serves_no_mode")
        XCTAssertTrue(
            stranded.isEmpty,
            "Hiçbir moda bağlanamayan blueprint:\n"
            + stranded.map { "  " + $0.message }.joined(separator: "\n"))
    }

}

/// Nakaratsız tekrar oranı (23 Ekim 2026).
///
/// Kitap araştırma ajanının itirazıyla eklendi: ilan edilmiş bir nakarat
/// blueprint'in özelliği, o blueprint'in her masalı onu tasarım gereği
/// tekrarlar, ve sayılması motorun prozayı ne kadar çeşitlendirdiği hakkında
/// hiçbir şey söylemez. Ölçüldüğünde nakaratlı bir blueprint'te masallar arası
/// tekrarın 8'de 6'sı nakaratın kendisiydi.
final class RefrainAwareMeasurementTests: XCTestCase {

    private var catalog: ContentCatalog!

    /// Nakarat deneyinin kolu: yayında nakaratlı blueprint yok, bu yüzden ölçüyü
    /// sınamanın tek yolu deney kolunu havuza katmak.
    private var withRefrain: ContentCatalog!

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Content/Experiments/x_refrain_bedtime.json")
        let arm = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
        withRefrain = ContentCatalog(
            version: catalog.version, settings: catalog.settings, companions: catalog.companions,
            objects: catalog.objects, templates: catalog.templates + arm.templates,
            blueprints: catalog.blueprints + arm.blueprints,
            storyModes: catalog.storyModes, interests: catalog.interests,
            safetyTopics: catalog.safetyTopics, series: catalog.series)
    }

    /// Nakaratı olmayan katalogda iki ölçü birebir aynı: yeni ölçü eskisinin
    /// yerine geçmiyor, yanında duruyor.
    func testWithoutARefrainBothRatesAgree() {
        for (mode, band) in [(StoryMode.learning, AgeBand(lowerBound: 5, upperBound: 6)),
                             (.adventure, AgeBand(lowerBound: 5, upperBound: 6)),
                             (.bedtime, AgeBand(lowerBound: 3, upperBound: 4))] {
            let report = VariationReport.measure(
                catalog: catalog, mode: mode, band: band, seeds: VariationBaseline.standardSeeds)
            XCTAssertEqual(report.repeatedSentenceRate,
                           report.repeatedSentenceRateExcludingRefrains,
                           "\(mode.rawValue) \(band): yayında nakarat yok, oranlar ayrışmamalı")
        }
    }

    /// Nakaratlı bir blueprint ölçüldüğünde nakaratsız oran belirgin biçimde
    /// düşük: ölçü gerçekten nakaratı ayıklıyor.
    func testARefrainIsLeftOutOfTheSecondRate() {
        let band = AgeBand(lowerBound: 3, upperBound: 4)
        let seeds = (1...30).map { "rf-\($0)" }
        // Nakaratlı kol standart arklı charge: 23 Ekim'den beri öğrenelim onu
        // kabul ediyor.
        let report = VariationReport.measure(
            catalog: withRefrain, mode: .learning, band: band, seeds: seeds)
        XCTAssertGreaterThan(report.composed, 0)
        XCTAssertLessThan(report.repeatedSentenceRateExcludingRefrains,
                          report.repeatedSentenceRate,
                          "nakarat ayıklanmamış: \(report.repeatedSentenceRate) / "
                          + "\(report.repeatedSentenceRateExcludingRefrains)")
    }

    /// Nakarat cümleleri, sayfa cümleleriyle **aynı** biçimde ayrıştırılıyor.
    /// Ayrıştırma iki yerde ayrı yazılsaydı karşılaştırma hiç tutmazdı ve ölçü
    /// sessizce eskisinin kopyası olurdu.
    func testTheRefrainIsSplitTheSameWayAsAPage() throws {
        let blueprint = try XCTUnwrap(withRefrain.blueprints.first { $0.refrain != nil })
        let refrain = try XCTUnwrap(blueprint.refrain)
        let catalogWithRefrain = withRefrain!
        let story = try XCTUnwrap((1...30).lazy.compactMap { index in
            try? OfflineStoryComposer().compose(
                catalog: catalogWithRefrain,
                intent: OfflineStoryIntent(childName: "Ada", seed: "rf-\(index)",
                                           ageBand: blueprint.ageRange))
        }.first { $0.blueprintID == blueprint.id }, "nakaratlı masal kurulamadı")

        let sentences = Set(story.pages.flatMap(VariationReport.sentences(of:)))
        let found = VariationReport.refrainSentences(of: story, in: catalogWithRefrain)
        XCTAssertFalse(found.isEmpty)
        XCTAssertTrue(found.contains(where: sentences.contains),
                      "nakarat cümlesi sayfa cümleleriyle eşleşmiyor: \(found) / \(refrain.line)")
    }

    /// Bu alandan önce alınmış taban kayıtları çözülmeye devam ediyor.
    ///
    /// Sessiz felaket önleyici: çözülemeyen dosyayı `testRecordBaseline` boş
    /// liste sayıp üstüne yazıyor, yani turların karşılaştırma geçmişi kaybolur.
    func testABaselineRecordWithoutTheNewFieldStillDecodes() throws {
        let json = """
        {"band":"5-6","blueprints":8,"casts":45,"closings":9,"companions":15,"composed":50,
         "discoveries":12,"failures":[],"mechanisms":8,"mode":"learning","openings":11,
         "repeatedSentenceRate":0.52,"requested":50,"settings":15}
        """
        let report = try JSONDecoder().decode(VariationReport.self, from: Data(json.utf8))
        XCTAssertEqual(report.repeatedSentenceRate, 0.52)
        XCTAssertEqual(report.repeatedSentenceRateExcludingRefrains, 0.52,
                       "eski kayıtta nakarat yoktu, iki oran eşit sayılmalı")
    }
}
