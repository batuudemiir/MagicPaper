import XCTest
@testable import StoryEngine

/// `CompanionNature` (22 Ekim 2026): prozanın "bu bir hayvan mı, insan mı"
/// diye sorabildiği eksen.
///
/// Neden var: bir satır beden varsayabiliyor ve bunu söyleyemiyordu. Bedtime
/// `bt_td_03` yastıktan havalanan bir tüy anlatıyor; havuzdaki herkes tüylü ya
/// da kanatlı olduğu sürece sorun yok. "Meslekler ve günlük yaşam" konusu bir
/// fırıncıyı havuza soktuğu gün aynı satır fırıncıya da teklif edilir ve kitap
/// tüy döken bir fırıncı anlatır. Ne satır ne kayıt yanlış; yalnızca ikisi
/// birlikte, yani hiçbir testin göremediği kusur sınıfı.
final class CompanionNatureTests: XCTestCase {

    private var catalog: ContentCatalog!

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    // MARK: - Kayıt

    /// Alanı yazmayan bir kayıt hayvan okunur, ama "yazmadı" ile "hayvan dedi"
    /// ayrı durur: bütünlük denetimi birincisini uyarıyor, ikincisini değil.
    func testAnUndeclaredRecordReadsAsAnAnimalButStaysDistinguishable() throws {
        let json = #"{"id": "companion_x", "name": "X", "type": "tilki"}"#
        let decoded = try JSONDecoder().decode(CatalogCompanion.self, from: Data(json.utf8))
        XCTAssertNil(decoded.declaredNature)
        XCTAssertEqual(decoded.nature, .animal)

        let declared = #"{"id": "companion_y", "name": "Y", "type": "fırıncı", "nature": "person"}"#
        let person = try JSONDecoder().decode(CatalogCompanion.self, from: Data(declared.utf8))
        XCTAssertEqual(person.declaredNature, .person)
        XCTAssertEqual(person.nature, .person)
    }

    /// Yayınlanan havuzun tamamı ne olduğunu söylüyor, ve doğrusunu söylüyor.
    func testEveryShippedCompanionDeclaresWhatItIs() {
        let silent = catalog.companions.filter { $0.declaredNature == nil }
        XCTAssertTrue(silent.isEmpty,
                      "ne olduğunu söylemeyen kayıt: \(silent.map(\.id.rawValue).sorted())")
        XCTAssertEqual(
            Set(catalog.companions.filter { $0.nature == .fantastic }.map(\.type)),
            ["ejderha", "robot"],
            "masal yaratıkları değişti; etiket bir vaattir, gözden geçirilmeli")
        XCTAssertTrue(catalog.companions.contains { $0.nature == .animal })
    }

    /// Alan eklenmesi eski kayıtların çözülmesini bozmadı: şema büyüdü, geriye
    /// dönük uyumluluk durdu.
    func testTheFieldSurvivesARoundTrip() throws {
        let original = try XCTUnwrap(catalog.companions.first { $0.nature == .fantastic })
        let again = try JSONDecoder().decode(
            CatalogCompanion.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(again.declaredNature, original.declaredNature)
        XCTAssertEqual(again, original)
    }

    /// Bütünlük denetimi sessiz kaydı görüyor, ve `error` değil `warning`:
    /// varsayılan okuma kataloğu çalışır tutuyor, eski bir paketi reddetmek
    /// bu kusurdan büyük olurdu.
    func testAnUndeclaredRecordIsWarnedAboutAndNotRejected() throws {
        let json = #"{"id": "companion_silent_001", "name": "Sessiz", "type": "fırıncı"}"#
        let silent = try JSONDecoder().decode(CatalogCompanion.self, from: Data(json.utf8))
        // Yalnızca yol arkadaşı listesi değişen bir katalog: denetim bu
        // kontrolü başka hiçbir kayda bakmadan yapıyor.
        let report = CatalogIntegrityChecker().check(
            ContentCatalog(version: catalog.version, companions: [silent]))
        let issues = report.issues(withCode: "companion_nature_undeclared")
        XCTAssertEqual(issues.map(\.recordID?.rawValue), ["companion_silent_001"])
        XCTAssertEqual(issues.first?.severity, .warning)
    }

    // MARK: - Proza

    /// Bildirilmemiş bir satır herkese uygun: mevcut korpusun tamamı
    /// etkilenmeden çalışmaya devam ediyor.
    func testALineThatSaysNothingSuitsEveryone() {
        let quiet = catalog.templates.flatMap(\.variants).filter { $0.natureRequire.isEmpty }
        XCTAssertFalse(quiet.isEmpty)
        for nature in CompanionNature.allCases {
            XCTAssertTrue(quiet.allSatisfy { $0.suits(nature: nature) })
        }
    }

    /// Tüy satırı artık kendi varsayımını söylüyor, ve insana teklif edilmiyor.
    func testTheFeatherLineIsNowOfferedOnlyToAnAnimal() throws {
        let feather = try XCTUnwrap(
            catalog.templates.flatMap(\.variants).first { $0.id.rawValue == "bt_td_03" },
            "bedtime tend korpusu değişmiş olabilir")
        XCTAssertEqual(feather.natureRequire, [.animal])
        XCTAssertTrue(feather.suits(nature: .animal))
        XCTAssertFalse(feather.suits(nature: .person))
        XCTAssertFalse(feather.suits(nature: .fantastic))
    }

    /// Süzgeç `fits` içinde DEĞİL, ve bu kasıtlı: `fits` havuz baskısı altında
    /// gevşiyor (`narrow`), bu süzgecin bütün amacı ise baskıya dayanmak.
    /// Tüy döken bir fırıncı "biraz tutarsız bir sayfa" değil, başka birinin
    /// sayfasıdır.
    func testNatureIsNotPartOfTheRelaxableFitCheck() throws {
        let feather = try XCTUnwrap(
            catalog.templates.flatMap(\.variants).first { $0.id.rawValue == "bt_td_03" })
        let setting = try XCTUnwrap(catalog.settings.first { $0.traits.contains(.isRestingPlace) })
        let person = try JSONDecoder().decode(
            CatalogCompanion.self,
            from: Data(#"{"id": "c_p", "name": "Ela", "type": "fırıncı", "nature": "person"}"#.utf8))
        let discovery = try XCTUnwrap(catalog.objects.first)

        XCTAssertTrue(feather.fits(setting: setting, discovery: discovery, companion: person),
                      "fits yalnızca gevşeyebilir kısıtları bakıyor")
        XCTAssertFalse(feather.suits(nature: person.nature))
    }

    /// Bugünkü havuzla hiçbir masal bu yüzden kurulamaz hâle gelmedi: bütün
    /// yol arkadaşları hayvan ya da masal yaratığı, ve tüy satırının yanında
    /// aynı beat'te bildirimsiz satırlar var.
    func testTodaysPoolStillComposesEveryBedtimeStory() throws {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        var composed = 0
        for seed in (1...20).map({ "nature-\($0)" }) {
            if (try? OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Ada", seed: seed, mode: .bedtime,
                                           ageBand: band))) != nil {
                composed += 1
            }
        }
        XCTAssertEqual(composed, 20, "tüy satırının bildirimi uyku masallarını kırdı")
    }
}

/// İlgi kapsaması yalnızca bir çocuğun gerçekten alabileceği şekilleri sayar
/// (22 Ekim 2026).
///
/// Kuralın hikâyesi: ölçüldüğünde 3-4 bandının bütün ilgi kapsaması tek bir
/// blueprint'ten geliyordu — `blueprint_charge_tending_age3_001`, 21 Ekim'de
/// uyku öncesi kendi arkına taşınınca hiçbir moda bağlanamaz hâle gelen üç
/// blueprint'ten biri. Yani ebeveyne gösterilen dört çipin üçü, hiçbir çocuğa
/// ulaşmayan bir blueprint yüzünden gösteriliyordu.
///
/// Aynı gün `charge` ailesi "Yeni şeyler öğrenelim"e eklendi (karar: Batuhan)
/// ve o blueprint ulaşılabilir oldu, yani kapsama artık meşru. Kural yine de
/// gerekli ve bu yüzden kurgu bir katalogla sınanıyor: canlı katalogda örnek
/// kalmaması kuralın gereksizleştiği anlamına gelmez, yalnızca bugün ihlal
/// olmadığı anlamına gelir.
final class InterestReachabilityTests: XCTestCase {

    private var catalog: ContentCatalog!
    private let selector = BlueprintSelector()

    override func setUpWithError() throws {
        catalog = try ContentCatalogLoader().load().catalog
    }

    /// Hiçbir modun kabul etmediği blueprint kapsamaya sayılmaz.
    ///
    /// Kurgu katalogla sınanıyor: canlı katalogda bugün ulaşılamayan blueprint
    /// yok (`charge` öğrenelime eklendi), ama kural bir modun ailesini
    /// değiştiren her turda yeniden geçerli olacak.
    func testCoverageCountsOnlyWhatAModeAdmits() throws {
        let reachable = try XCTUnwrap(catalog.blueprints.first {
            $0.isBeatAuthored && $0.family == .charge
                && $0.ageRange == AgeBand(lowerBound: 3, upperBound: 4)
        })
        // Aynı katalog, tek fark: hiçbir mod artık charge kabul etmiyor.
        let withoutCharge = ContentCatalog(
            version: catalog.version, settings: catalog.settings,
            companions: catalog.companions, objects: catalog.objects,
            templates: catalog.templates, blueprints: catalog.blueprints,
            storyModes: catalog.storyModes.map {
                StoryModeProfile(mode: $0.mode,
                                 families: $0.families.filter { $0 != .charge },
                                 arcs: $0.arcs)
            },
            interests: catalog.interests)

        let band = AgeBand(lowerBound: 3, upperBound: 4)
        XCTAssertTrue(catalog.storyModes.contains { $0.admits(reachable) },
                      "canlı katalogda charge bir moda bağlı olmalı")
        XCTAssertFalse(withoutCharge.storyModes.contains { $0.admits(reachable) })

        let before = selector.interestCoverage(catalog: catalog)[band] ?? []
        let after = selector.interestCoverage(catalog: withoutCharge)[band] ?? []
        XCTAssertTrue(after.isStrictSubset(of: before),
                      "ulaşılamayan blueprint hâlâ kapsamaya sayılıyor: "
                      + "\(after.map(\.rawValue).sorted())")
    }

    /// Ebeveyne sunulan liste, her bantta gerçekten tutulabilen sözlerden
    /// oluşuyor.
    ///
    /// 22 Ekim: `charge` öğrenelime eklenince 3-4 bandı bir çocuğun gerçekten
    /// alabildiği ikinci bir şekle kavuştu (`lookingAfter`) ve liste beş
    /// kelimeye çıktı. FAZ 12 eşiği (dört) **meşru biçimde** aşıldı, yani ilgi
    /// ekranları artık görünüyor — iki tur önce aynı sayı ulaşılamayan bir
    /// blueprint yüzünden görünmüştü, bu kez değil.
    func testTheOfferedListIsWhatEveryBandCanActuallyKeep() {
        XCTAssertEqual(selector.availableInterests(catalog: catalog).map(\.id.rawValue),
                       ["animals", "sea", "magic", "nature", "treasure"])
    }

    /// Mod tanımı olmayan bir katalogda süzgeç uygulanmaz: "hiçbir mod kabul
    /// etmiyor" o durumda doğru okuma değil, yalnızca eksik veri.
    func testACatalogWithoutModesIsNotTreatedAsUnreachable() {
        let withoutModes = ContentCatalog(
            version: catalog.version, settings: catalog.settings,
            companions: catalog.companions, objects: catalog.objects,
            templates: catalog.templates, blueprints: catalog.blueprints,
            interests: catalog.interests)
        let coverage = selector.interestCoverage(catalog: withoutModes)
        let band = AgeBand(lowerBound: 3, upperBound: 4)
        XCTAssertTrue((coverage[band] ?? []).count > 1,
                      "mod tanımı yokken süzgeç uygulanmamalı")
    }
}
