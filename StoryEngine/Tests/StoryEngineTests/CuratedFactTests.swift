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

    /// Sekizi de onaylı, 5-6 için yazılmış, ve kaynağı tam.
    ///
    /// Kaynak alanları boş geçilemiyor (decoder hata veriyor), ama "var" ile
    /// "anlamlı" ayrı şeyler: bu test adresin gerçekten bir adres, tarihin
    /// gerçekten bir tarih olduğuna bakıyor.
    func testEveryShippedFactIsApprovedAndSourced() throws {
        // İkisi: inceleme dosyasında sekiz onaylı olgu var ama katalog yalnızca
        // bir çocuğa ULAŞABİLENİ taşıyor. Diğer altısının konusu havuzda yok
        // (Ay yok, Güneş yok, düşen bir şey yok) ve konusu olmayan olguyu
        // katalogda tutmak ölü içeriktir. Keşif yazıldığı gün bu sayı büyür.
        XCTAssertEqual(catalog.facts.count, 2)
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

    /// Her olgu bir keşfe bağlı olmalı, yoksa hiçbir masala eşlik etmez.
    ///
    /// Bağlanmayan olgu `warning` (olguyu yazıp keşfini sonra bağlamak meşru
    /// bir sıra), ama yayınlanan katalogda hiç olmamalı: yazılmış, kaynaklanmış
    /// ve hiçbir çocuğa ulaşmayan olgu, A turunda temizlenen ölü içeriğin
    /// aynısıdır.
    func testEveryShippedFactReachesADiscovery() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let orphans = report.issues(withCode: "fact_reaches_no_discovery")
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
