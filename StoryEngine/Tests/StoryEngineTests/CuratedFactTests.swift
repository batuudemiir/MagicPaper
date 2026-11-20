import XCTest
@testable import StoryEngine

/// Küratörlü olgular (B-ön 2, karar 23 Ekim 2026).
///
/// Bu testlerin koruduğu şey bir sayı değil bir duruş: bir çocuk kitabına
/// giren gerçek bilgi, kimsenin hatırlamasına bırakılmaz. Üç kural da
/// `error` seviyesinde, yani uzak bir paket (FAZ 15) onları ihlal ederse
/// `RemoteCatalogPolicy` paketi reddeder.
final class CuratedFactTests: XCTestCase {

    private var catalog: ContentCatalog!

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    private func fact(
        _ id: ContentID, review: CatalogFact.Review = .approved
    ) -> CatalogFact {
        CatalogFact(id: id, statement: "Bir şey.", bands: [AgeBand(lowerBound: 5, upperBound: 6)],
                    sourceName: "Kaynak", sourceURL: "https://example.test/x",
                    verifiedOn: "2026-10-23", review: review)
    }

    /// Keşfi verilen olguya bağlayan katalog. JSON'dan kuruluyor çünkü
    /// `CatalogObject` alanları `let` ve üretim koduna yalnızca test için
    /// kurucu eklemek yanlış yönde bir borç olurdu.
    private func catalogWith(_ facts: [CatalogFact], discoveryFact: String?) throws -> ContentCatalog {
        let link = discoveryFact.map { ", \"factID\": \"\($0)\"" } ?? ""
        let json = """
        {"id": "object_probe", "name": "bir şey", "traits": ["isVisible"]\(link)}
        """
        let object = try JSONDecoder().decode(CatalogObject.self, from: Data(json.utf8))
        return ContentCatalog(version: "test", objects: [object], facts: facts)
    }

    // MARK: - Yayınlanan sekiz olgu

    /// Hepsi onaylı, bandı kayıtlı (iki NASA olgusu 5-10, gerisi 5-6), ve dayanağına uygun.
    ///
    /// "Dayanağına uygun" 30 Ekim'de iki kola ayrıldı (karar: karma kaynak).
    /// Kaynak alanları `sourced` olguda boş geçilemiyor (decoder hata veriyor),
    /// ama "var" ile "anlamlı" ayrı şeyler: bu test adresin gerçekten bir
    /// adres, tarihin gerçekten bir tarih olduğuna bakıyor. `editorial` olguda
    /// kaynağın **bulunmaması** denetleniyor — yanlış etiketlenmiş bir kaydı
    /// kaynaksız göstermek, kaynaksızlığın yayılma yolu.
    func testEveryShippedFactIsApprovedAndMatchesItsBasis() throws {
        // Beş: iki bilim olgusu (NASA) + üç meslek olgusu (editoryal, onay:
        // Batuhan, 30 Ekim). İnceleme dosyasında daha fazla onaylı bilim olgusu
        // var ama katalog yalnızca bir çocuğa ULAŞABİLENİ taşıyor: konusu
        // havuzda olmayan olguyu katalogda tutmak ölü içeriktir.
        // Sporlar (19 Kasım 2026): beden öğretmeninin editoryal olgusu altıncı.
        XCTAssertEqual(catalog.facts.count, 6)
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        // H2 (18 Kasım 2026, karar: Batuhan): iki NASA olgusu 7-8 ve 9-10'a
        // da açıldı (mevcut kaydın değişmesi, sıra kuralının istisnası).
        // Meslek olguları yalnızca 5-6'da kalıyor.
        // H2b (19 Kasım 2026): meslek olguları da 7-10'a açıldı; artık beşi de 5-10.
        let widened: Set<String> = ["fact_sun_is_a_star", "fact_shooting_star_is_not_a_star",
                                    "fact_baker_rests_the_dough", "fact_postman_sorts_by_street",
                                    "fact_teacher_writes_the_order", "fact_coach_shows_slowly"]
        let upper = [band, AgeBand(lowerBound: 7, upperBound: 8), AgeBand(lowerBound: 9, upperBound: 10)]
        for fact in catalog.facts {
            XCTAssertTrue(fact.isApproved, fact.id.rawValue)
            let expected = widened.contains(fact.id.rawValue) ? upper : [band]
            XCTAssertEqual(fact.bands, expected, "\(fact.id.rawValue): olgunun bantları değişti")
            XCTAssertNotNil(ISO8601DateFormatter.date(fromDay: fact.verifiedOn),
                            "\(fact.id.rawValue): doğrulama tarihi bir tarih değil (\(fact.verifiedOn))")
            XCTAssertFalse(fact.statement.hasSuffix(":"), fact.id.rawValue)
            switch fact.basis {
            case .sourced:
                XCTAssertTrue(fact.sourceURL?.hasPrefix("https://") ?? false, fact.id.rawValue)
                XCTAssertFalse(fact.sourceName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true,
                               fact.id.rawValue)
            case .editorial:
                XCTAssertNil(fact.sourceName, "\(fact.id.rawValue): editoryal olgu kaynak taşımaz")
                XCTAssertNil(fact.sourceURL, "\(fact.id.rawValue): editoryal olgu kaynak taşımaz")
                // Sayı bir iddiadır ve dayanak ister; denetim kuralı da bu.
                XCTAssertFalse(fact.statement.contains(where: \.isNumber),
                               "\(fact.id.rawValue): editoryal olgu sayı taşıyor")
            }
        }
    }

    /// Kaynaklı olguların hepsi NASA Space Place'ten, ve bu kayıtlı: provenans
    /// bir turda sessizce genişlemesin. Editoryal olgular bu soruya girmiyor —
    /// onların provenansı bizim onayımız.
    func testEverySourcedFactComesFromTheRecordedSource() {
        let hosts = Set(catalog.facts
            .filter { $0.basis == .sourced }
            .map { $0.sourceURL.flatMap(URL.init(string:))?.host })
        XCTAssertEqual(hosts, ["spaceplace.nasa.gov"])
        XCTAssertEqual(catalog.facts.filter { $0.basis == .editorial }.count, 4,
                       "dört meslek olgusu editoryal (dördüncüsü beden öğretmeni, Sporlar, 19 Kasım 2026: \"tümünü yap\"); beşincisi eklenirse kararı yazılmalı")
    }

    /// Her olgu bir keşfe bağlı olmalı, yoksa hiçbir masala eşlik etmez.
    ///
    /// Bağlanmayan olgu `warning` (olguyu yazıp keşfini sonra bağlamak meşru
    /// bir sıra), ama yayınlanan katalogda hiç olmamalı: yazılmış, kaynaklanmış
    /// ve hiçbir çocuğa ulaşmayan olgu, A turunda temizlenen ölü içeriğin
    /// aynısıdır.
    func testEveryShippedFactReachesADiscovery() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let orphans = report.issues(withCode: "fact_reaches_no_record")
        XCTAssertTrue(orphans.isEmpty,
                      "hiçbir keşfe bağlanmamış olgu:\n"
                      + orphans.map { "  " + $0.message }.joined(separator: "\n"))
    }

    /// Bir masalın en çok bir olgusu var, ve bunun ayrı bir denetime ihtiyacı
    /// yok: masalın bir keşfi var, keşfin de en çok bir olgusu.
    ///
    /// Ürün kararı (23 Ekim 2026) buydu ve ilk tasarımda satır başına
    /// sayılıyordu — iki satırın iki ayrı olgu taşımasını engellemiyordu.
    /// Olgu keşfe bağlandığında kural yapıya gömülü hâle geldi.
    func testAStoryCarriesAtMostOneFact() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        for index in 1...20 {
            let story = try XCTUnwrap(try? OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Ada", seed: "tek-\(index)",
                                           mode: .learning, ageBand: band)))
            let facts = [story.content.discovery.factID].compactMap { $0 }
            XCTAssertLessThanOrEqual(facts.count, 1)
        }
    }

    // MARK: - Üç kural

    func testADeclaredFactMustExist() throws {
        let broken = try catalogWith([], discoveryFact: "fact_missing")
        let codes = CatalogIntegrityChecker().check(broken).issues.map(\.code)
        XCTAssertTrue(codes.contains("unknown_fact"), "\(codes)")
    }

    /// Onaysız olgu bildirmek hata: kaynağında doğrulanmamış bilgi, tutulamayan
    /// bir sözden kötüdür.
    func testAnUnapprovedFactCannotBeCarried() throws {
        for review in [CatalogFact.Review.draft, .sourceUnverified] {
            let broken = try catalogWith(
                [fact("fact_x", review: review)], discoveryFact: "fact_x")
            let report = CatalogIntegrityChecker().check(broken)
            XCTAssertTrue(report.issues.map(\.code).contains("unapproved_fact"), review.rawValue)
            XCTAssertEqual(report.issues(withCode: "unapproved_fact").first?.severity, .error)
        }
    }

    /// Onaylı bir olguya bağlı bir keşif hiçbir uyarı üretmiyor.
    func testAnApprovedFactOnADiscoveryIsClean() throws {
        let fine = try catalogWith([fact("fact_a")], discoveryFact: "fact_a")
        let codes = CatalogIntegrityChecker().check(fine).issues
            .filter { $0.code.contains("fact") }.map(\.code)
        XCTAssertTrue(codes.isEmpty, "\(codes)")
    }

    /// Kaynaksız olgu decode edilemiyor. Sözlükten ayrıldığı yer burası: bir
    /// kelimenin eksik alanı için makul varsayılan vardır, bir olgunun kaynağı
    /// için yoktur.
    func testAFactWithoutASourceDoesNotDecode() {
        let json = #"{"id": "f", "statement": "Bir şey.", "review": "approved"}"#
        XCTAssertThrowsError(try JSONDecoder().decode(CatalogFact.self, from: Data(json.utf8)))
    }

    /// Yayınlanan katalog bu üç kuraldan hiçbirini ihlal etmiyor.
    func testTheShippedCatalogHasNoFactFaults() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let faults = report.issues.filter {
            ["unknown_fact", "unapproved_fact", "line_carries_two_facts", "duplicate_fact"].contains($0.code)
        }
        XCTAssertTrue(faults.isEmpty, faults.map(\.message).joined(separator: "\n"))
    }
}

private extension ISO8601DateFormatter {
    static func date(fromDay text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: text)
    }
}
