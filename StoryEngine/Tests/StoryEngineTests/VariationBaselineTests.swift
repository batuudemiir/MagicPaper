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
        (.bedtime, AgeBand(lowerBound: 3, upperBound: 4))
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
            notBelow(report.settings, before.settings, "mekân")
            notBelow(report.companions, before.companions, "arkadaş")
            notBelow(report.casts, before.casts, "kadro")

            XCTAssertLessThanOrEqual(
                report.repeatedSentenceRate, before.repeatedSentenceRate + 0.001,
                "\(where_): tekrar eden cümle oranı arttı "
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
    /// Bu test bugün **kırmızı başlıyor** ve bu kasıtlı: 21 Ekim'de uyku arkı
    /// eklenirken üç blueprint sessizce ulaşılamaz oldu. Testin işi onları
    /// görünür tutmak; düzeltildiklerinde ya da bilerek emekliye ayrıldıklarında
    /// yeşile döner.
    func testNoBlueprintIsStrandedWithoutAMode() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let stranded = report.issues(withCode: "blueprint_serves_no_mode")
        XCTAssertTrue(
            stranded.isEmpty,
            "Hiçbir moda bağlanamayan blueprint:\n"
            + stranded.map { "  " + $0.message }.joined(separator: "\n"))
    }

}
