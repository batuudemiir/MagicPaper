import XCTest
import StoryEngine
@testable import MagicPaper

/// Bantları dürüstleştirme (C turu, 21 Ekim 2026).
///
/// Buraya kadarki davranış sessiz bir yanlıştı: 9 yaşındaki bir çocuk için
/// masal istendiğinde `servedBand` en yakın bandı (5-6) seçiyor, log'a bir
/// uyarı yazıyor ve o masalı 9 yaşındakinin adıyla yazıyordu. Ebeveyn bunu
/// göremez; yalnızca masalın beklediğinden basit olduğunu hisseder.
///
/// Bu testlerin koruduğu iki şey var ve ikincisi daha önemli: desteklenen
/// bantlar **içerikten** türüyor (elle yazılmış bir "3-6" kuralı yok), ve
/// kayıtlı bir profilin yaşına hiçbir koşulda dokunulmuyor.
@MainActor
final class SupportedAgeTests: XCTestCase {

    private let profilesKey = "user_profiles"
    private let currentKey = "current_profile_id"

    private let band34 = AgeBand(lowerBound: 3, upperBound: 4)
    private let band56 = AgeBand(lowerBound: 5, upperBound: 6)
    private let band78 = AgeBand(lowerBound: 7, upperBound: 8)

    // MARK: - Desteklenen bant içerikten gelir

    /// Bugünün katalogu: 3-4 ve 5-6. Liste açık yazılı, çünkü büyümesi bir
    /// ürün olayıdır: 7-8 için ilk masal yazıldığı gün bu test kırmızıya döner
    /// ve kıran kişi tam olarak doğru soruyu sorar.
    func testTodaysContentIsAuthoredForThreeToSix() {
        XCTAssertEqual(OfflineStoryService.shared.authoredBands(), [band34, band56])
        XCTAssertEqual(StoryChoiceSources.current.authoredBands(), [band34, band56])
    }

    /// Yeni profil ekranı yalnızca masalı yazılmış bantları sunar.
    func testTheAgeChipsOfferOnlyAuthoredBands() {
        let offered = MPAgeRange.authored(StoryChoiceSources.current.authoredBands())
        XCTAssertEqual(offered.map(\.title), ["3-4 yaş", "5-6 yaş"])
    }

    /// Katalog okunamadığında ebeveyne yanlış bilgi verilmez: dört chip de
    /// durur ve akış masal yazmayı dener. Hata içerikte değil yüklemede.
    func testAnUnreadableCatalogDoesNotShrinkTheChipsOrBlockTheFlow() {
        XCTAssertEqual(MPAgeRange.authored([]), MPAgeRange.allCases)
        XCTAssertTrue(StoryCreationSteps.supportsAge(9, authored: []))
    }

    // MARK: - Kayıtlı profil değişmez

    /// 9 yaşındaki bir çocuk desteklenmiyor, ama yaşı hâlâ 9 ve bandı hâlâ
    /// 9-10 olarak okunuyor: desteklememek, başka bir yaşmış gibi davranmak
    /// değil.
    func testAnUnsupportedChildStillReadsAsItsOwnAge() {
        XCTAssertFalse(StoryCreationSteps.supportsAge(9, authored: [band34, band56]))
        XCTAssertEqual(MPAgeRange.from(age: 9), .r910)
        XCTAssertEqual(AgeBandResolver.band(forAge: 9), AgeBand(lowerBound: 9, upperBound: 10))
    }

    /// Akışın desteklenmeyen dalından geçmek diskteki yaşı değiştirmemeli.
    ///
    /// En önemli test: "düzeltme" niyetiyle yazılmış tek satır, ebeveynin
    /// kendi girdiği bilgiyi haberi olmadan değiştirir.
    func testWalkingTheUnsupportedBranchLeavesTheStoredAgeAlone() throws {
        let manager = ProfileManager.shared
        let savedProfiles = manager.profiles
        let savedCurrent = manager.currentProfile
        let savedData = UserDefaults.standard.data(forKey: profilesKey)
        let savedCurrentID = UserDefaults.standard.string(forKey: currentKey)
        let big = UserProfile(name: "Test Dokuz", age: 9)
        let small = UserProfile(name: "Test Beş", age: 5)
        defer {
            manager.profiles = savedProfiles
            manager.currentProfile = savedCurrent
            UserDefaults.standard.set(savedData, forKey: profilesKey)
            UserDefaults.standard.set(savedCurrentID, forKey: currentKey)
        }
        manager.profiles = savedProfiles + [big, small]
        manager.currentProfile = big

        let authored = StoryChoiceSources.current.authoredBands()
        XCTAssertFalse(StoryCreationSteps.supportsAge(big.age, authored: authored))
        // Akışın bu daldaki bütün kararları, yan etkisiz olmalı.
        _ = StoryCreationSteps.supportedAlternatives(
            to: big.id, among: manager.profiles, authored: authored)
        _ = OfflineStoryService.shared.authoredBands()

        XCTAssertEqual(manager.profiles.first { $0.id == big.id }?.age, 9)
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            let stored = try JSONDecoder().decode([UserProfile].self, from: data)
            if let written = stored.first(where: { $0.id == big.id }) {
                XCTAssertEqual(written.age, 9, "kayıtlı yaş değişmiş")
            }
        }
    }

    // MARK: - "Başka bir çocuk seç"

    /// Teklif yalnızca gerçekten masal yazılabilecek bir kardeş varken.
    func testPickingAnotherChildIsOfferedOnlyWhenOneIsSupported() {
        let big = UserProfile(name: "Dokuz", age: 9)
        let other = UserProfile(name: "Sekiz", age: 8)
        let small = UserProfile(name: "Beş", age: 5)
        let authored = [band34, band56]

        XCTAssertEqual(
            StoryCreationSteps.supportedAlternatives(to: big.id, among: [big, small], authored: authored)
                .map(\.name),
            ["Beş"])
        XCTAssertTrue(
            StoryCreationSteps.supportedAlternatives(to: big.id, among: [big, other], authored: authored)
                .isEmpty,
            "iki çocuk da desteklenmiyorsa teklif edilecek bir şey yok")
        XCTAssertTrue(
            StoryCreationSteps.supportedAlternatives(to: small.id, among: [small], authored: authored)
                .isEmpty,
            "çocuğun kendisi alternatif değil")
    }

    // MARK: - Desteklenen çocuk etkilenmez

    /// 3-6 bandındaki akış bu turda hiç değişmedi: masal yazılıyor.
    func testASupportedChildStillGetsAStory() throws {
        for age in [4, 6] {
            XCTAssertTrue(StoryCreationSteps.supportsAge(age, authored: [band34, band56]))
            XCTAssertFalse(StoryChoiceSources.current.availableModes(forAge: age).isEmpty,
                           "\(age) yaş için mod kalmamış")
            let result = try OfflineStoryService.shared.compose(
                childName: "Ada", ideaID: nil, companionID: nil,
                mode: nil, age: age, seed: "c-turu-\(age)")
            XCTAssertTrue(result.story.isClean)
        }
    }

    /// Desteklenen bir bantta sessiz bant düşürmesi tetiklenmiyor: istenen
    /// bant ne ise o sunuluyor.
    func testASupportedBandIsNeverQuietlyDowngraded() {
        for age in [3, 4, 5, 6] {
            XCTAssertEqual(OfflineStoryService.shared.servedBand(forAge: age),
                           AgeBandResolver.band(forAge: age))
        }
        // 7-8 hâlâ düşüyor, ve bu bilinçli: ana sayfa vitrini gibi bir şey
        // göstermek zorunda olan yüzeyler için duruyor. Yaratma akışı bu yola
        // artık girmiyor (`supportsAge` yukarıda).
        XCTAssertNotEqual(OfflineStoryService.shared.servedBand(forAge: 8), band78)
    }
}
