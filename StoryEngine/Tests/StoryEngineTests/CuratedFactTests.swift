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

    /// Olgu bildiren bir satırı taşıyan katalog, JSON'dan kurulur: hem
    /// `CatalogVariant` hem `CatalogTemplate` alanları `let`, ve üretim koduna
    /// yalnızca test için kurucu eklemek yanlış yönde bir borç olurdu.
    private func catalogWith(_ facts: [CatalogFact], lineFacts: [[String]]) throws -> ContentCatalog {
        let variants = lineFacts.enumerated().map { index, ids in
            let list = ids.map { "\"\($0)\"" }.joined(separator: ", ")
            return """
            {"id": "v\(index)", "text": "{{child.name}} baktı.",
             "requiredSlots": ["child.name"], "facts": [\(list)]}
            """
        }
        let json = """
        {"id": "t_probe", "role": "hook", "variants": [\(variants.joined(separator: ","))]}
        """
        let template = try JSONDecoder().decode(CatalogTemplate.self, from: Data(json.utf8))
        return ContentCatalog(version: "test", templates: [template], facts: facts)
    }

    // MARK: - Yayınlanan sekiz olgu

    /// Sekizi de onaylı, 5-6 için yazılmış, ve kaynağı tam.
    ///
    /// Kaynak alanları boş geçilemiyor (decoder hata veriyor), ama "var" ile
    /// "anlamlı" ayrı şeyler: bu test adresin gerçekten bir adres, tarihin
    /// gerçekten bir tarih olduğuna bakıyor.
    func testEveryShippedFactIsApprovedAndSourced() throws {
        XCTAssertEqual(catalog.facts.count, 8)
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        for fact in catalog.facts {
            XCTAssertTrue(fact.isApproved, fact.id.rawValue)
            XCTAssertEqual(fact.bands, [band], "\(fact.id.rawValue): olgular yalnızca 5-6'ya yazılabilir")
            XCTAssertTrue(fact.sourceURL.hasPrefix("https://"), fact.id.rawValue)
            XCTAssertFalse(fact.sourceName.trimmingCharacters(in: .whitespaces).isEmpty, fact.id.rawValue)
            XCTAssertNotNil(ISO8601DateFormatter.date(fromDay: fact.verifiedOn),
                            "\(fact.id.rawValue): doğrulama tarihi bir tarih değil (\(fact.verifiedOn))")
            XCTAssertFalse(fact.statement.hasSuffix(":"), fact.id.rawValue)
        }
    }

    /// Hepsi NASA Space Place'ten, ve bu kayıtlı: provenans bir turda
    /// sessizce genişlemesin.
    func testEveryShippedFactComesFromTheRecordedSource() {
        XCTAssertEqual(Set(catalog.facts.map { URL(string: $0.sourceURL)?.host }), ["spaceplace.nasa.gov"])
    }

    /// Bugün hiçbir satır olgu bildirmiyor, ve bu bilinçli: taşıyıcı önce,
    /// prozası sonra. Bu test o sıranın kaza olmadığını söylüyor.
    func testNoLineCarriesAFactYet() {
        let carrying = catalog.templates.flatMap(\.variants).filter { !$0.facts.isEmpty }
        XCTAssertTrue(carrying.isEmpty,
                      "satırlar olgu taşımaya başladıysa bu testin yerini kapsama ölçümü almalı: "
                      + "\(carrying.map(\.id.rawValue))")
    }

    // MARK: - Üç kural

    func testADeclaredFactMustExist() throws {
        let broken = try catalogWith([], lineFacts: [["fact_missing"]])
        let codes = CatalogIntegrityChecker().check(broken).issues.map(\.code)
        XCTAssertTrue(codes.contains("unknown_fact"), "\(codes)")
    }

    /// Onaysız olgu bildirmek hata: kaynağında doğrulanmamış bilgi, tutulamayan
    /// bir sözden kötüdür.
    func testAnUnapprovedFactCannotBeCarried() throws {
        for review in [CatalogFact.Review.draft, .sourceUnverified] {
            let broken = try catalogWith(
                [fact("fact_x", review: review)], lineFacts: [["fact_x"]])
            let report = CatalogIntegrityChecker().check(broken)
            XCTAssertTrue(report.issues.map(\.code).contains("unapproved_fact"), review.rawValue)
            XCTAssertEqual(report.issues(withCode: "unapproved_fact").first?.severity, .error)
        }
    }

    /// Bir satır en çok bir olgu taşır — ürün kararı, 23 Ekim 2026.
    ///
    /// MagicPaper önce bir çocuk yayıncılığı deneyimi: olgu, çocuğun fark
    /// ettiği şeydir, kitabın öğrettiği şey değil. İki olgu taşıyan sayfa bir
    /// ders sayfasıdır, kahramanı olan bir ders.
    func testALineCarriesAtMostOneFact() throws {
        let two = try catalogWith(
            [fact("fact_a"), fact("fact_b")], lineFacts: [["fact_a", "fact_b"]])
        let report = CatalogIntegrityChecker().check(two)
        XCTAssertTrue(report.issues.map(\.code).contains("line_carries_two_facts"))
        XCTAssertEqual(report.issues(withCode: "line_carries_two_facts").first?.severity, .error)

        let one = try catalogWith([fact("fact_a")], lineFacts: [["fact_a"]])
        XCTAssertTrue(CatalogIntegrityChecker().check(one).issues
            .filter { $0.code.hasSuffix("_fact") || $0.code == "line_carries_two_facts" }.isEmpty)
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
