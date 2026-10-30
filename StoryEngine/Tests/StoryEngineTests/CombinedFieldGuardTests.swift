import XCTest
@testable import StoryEngine

/// Elle yazılmış alan listeleri (30 Ekim 2026).
///
/// Bu kod tabanı aynı kusuru **üç kez** buldu: bir tipe alan eklendi, o tipi
/// elle yeniden kuran bir fonksiyonun listesine eklenmedi, ve alan sessizce
/// düştü. `ContentCatalogLoader.assemble` iki kez (`storyTopics`, `facts` —
/// ikincisini `testAssemblyDropsNoCatalogField` yakaladı), sonra
/// `ContentExclusions.combined(with:)` bir kez: 28 Ekim'de eklenen `nature`
/// burada taşınmıyordu, yani bir fikirle birleşen blueprint "arkadaşı insan
/// olmaz" şartını tam birleştirmenin olduğu yerde kaybediyordu.
///
/// Nöbetçi `Mirror` ile çalışıyor, yani alan listesini **bilmiyor**: her alanın
/// birleştirmeden sağ çıktığını alan adına bakmadan doğruluyor. Dördüncü alan
/// eklendiğinde listeye eklenmesi gerekmiyor; eklenmezse bu test kırmızıya
/// döner ve yerini söyler.
final class CombinedFieldGuardTests: XCTestCase {

    /// Her dışlama alanı birleşmeden sağ çıkıyor.
    ///
    /// Yöntem: iki tarafı DOLU kur, birleştir, ve birleşmiş sonuçta her alanın
    /// boş olmadığını denetle. Bir alan listede yoksa varsayılanıyla —
    /// yani boş — gelir ve test onu görür.
    func testCombiningExclusionsDropsNoField() {
        let left = ContentExclusions(
            setting: [.canConceal], companion: [.canFly],
            discovery: [.impliesNeed], nature: [.person])
        let right = ContentExclusions(
            setting: [.isHazardous], companion: [.isLiteralMinded],
            discovery: [.isFragmentary], nature: [.fantastic])
        let combined = left.combined(with: right)

        for child in Mirror(reflecting: combined).children {
            guard let label = child.label else { continue }
            let count = (child.value as? any Collection)?.count ?? 0
            XCTAssertEqual(count, 2,
                           "'\(label)' birleşmede düştü ya da yarısı kayboldu "
                           + "(iki tarafta birer değer vardı, sonuçta \(count))")
        }
    }

    /// Her şart alanı birleşmeden sağ çıkıyor.
    ///
    /// Şartlar dışlamalardan farklı birleşiyor — "bunlardan biri" eksenleri
    /// KESİŞİYOR, birleşmiyor — o yüzden burada iki taraf aynı değeri veriyor
    /// ve sonuçta o değerin kaldığına bakılıyor. Alan taşınmazsa boş kalır.
    func testCombiningRequirementsDropsNoField() {
        let same = ContentRequirements(
            setting: [.canConceal], companion: [.canFly], discovery: [.isVisible],
            casting: [.guide], thresholdKind: [.social], nature: [.person])
        let combined = same.combined(with: same)

        for child in Mirror(reflecting: combined).children {
            guard let label = child.label else { continue }
            if let traits = child.value as? any Collection {
                XCTAssertFalse(traits.isEmpty, "'\(label)' birleşmede düştü")
            } else if let requirement = child.value as? TraitRequirement<SettingTrait> {
                XCTAssertFalse(requirement.isEmpty, "'\(label)' birleşmede düştü")
            }
        }
        // Mirror üç ayrı `TraitRequirement` tipini tek dalda tutamıyor, o yüzden
        // üçü açıkça: birleşme hiçbirini boşaltmıyor.
        XCTAssertFalse(combined.setting.isEmpty)
        XCTAssertFalse(combined.companion.isEmpty)
        XCTAssertFalse(combined.discovery.isEmpty)
        XCTAssertEqual(combined.casting, [.guide])
        XCTAssertEqual(combined.thresholdKind, [.social])
        XCTAssertEqual(combined.nature, [.person])
    }

    /// Boş taraf "fikrim yok" demek, "hiçbiri" demek değil: bir fikir
    /// bildirmediği ekseni boşaltmıyor.
    func testAnEmptySideYieldsRatherThanEmptying() {
        let blueprint = ContentRequirements(casting: [.guide, .reassuring], nature: [.person])
        let silentIdea = ContentRequirements()
        XCTAssertEqual(blueprint.combined(with: silentIdea).nature, [.person])
        XCTAssertEqual(silentIdea.combined(with: blueprint).nature, [.person])
        XCTAssertEqual(blueprint.combined(with: silentIdea).casting, [.guide, .reassuring])
    }
}
