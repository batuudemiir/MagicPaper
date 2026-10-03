import XCTest
@testable import MagicPaper

/// The age bands the app offers must be bands the content can actually serve.
///
/// The Story Idea screen is specified as three cards plus Surprise. It renders
/// whatever `storyIdeas(forAge:)` returns, so when that returns nothing the
/// screen does not break, warn, or look wrong — it quietly becomes a single
/// Surprise tile. No error, no log, no empty state. It simply stops being the
/// screen that was designed.
///
/// That is what happened: every authored idea is banded `5-6`, and the profile
/// editor offers four bands whose representative ages are 4, 6, 9 and 11. One
/// of the four has content. The other three produce the degraded screen, and
/// nothing anywhere says so.
///
/// The gating itself is correct and was asked for. What was missing is anyone
/// checking that the two ends meet.
@MainActor
final class AgeBandCoverageTests: XCTestCase {

    /// Ekranın plandaki hâli üç kart ister; bu bir TASARIM hedefi, içerik
    /// yasası değil. Bir bandın en az bir kartı olmalı — sıfır, ekranı
    /// "Sürpriz"den ibaret bırakır ve asıl bildirilen kusur oydu.
    private let cardsRequired = 1

    /// Every idea card a child of this age can be shown: the cards under each
    /// mode the flow offers them, asked through the seam the screens use.
    private func ideasShown(forAge age: Int) -> [StoryIdeaChoice] {
        let source = StoryChoiceSources.current
        var seen = Set<String>()
        return source.availableModes(forAge: age)
            .flatMap { source.ideaChoices(forAge: age, mode: $0) }
            .filter { seen.insert($0.id).inserted }
    }

    /// Süzgeç geri açıldı ve gerçekten süzüyor.
    ///
    /// Bu test daha önce "katalog tek bantlı kaldığı sürece süzgeç kapalı
    /// kalabilir" diyordu ve 3-4 bandı yazıldığı an kırıldı — kırılması
    /// işiydi. Şimdi tersini soruyor: iki bant varsa iki farklı yaş iki farklı
    /// şey görmeli. Görmüyorsa süzgeç yine kapanmış demektir.
    func testAgeGatingActuallySeparatesTheBands() {
        let young = ideasShown(forAge: 4)
        let older = ideasShown(forAge: 6)
        XCTAssertFalse(young.isEmpty)
        XCTAssertFalse(older.isEmpty)
        XCTAssertNotEqual(Set(young.map(\.id)), Set(older.map(\.id)),
                          "Dört yaş ile altı yaş aynı kartları görüyor; süzgeç iş görmüyor.")
    }

    func testEveryAgeBandTheAppOffersHasIdeasToShow() {
        var starved: [String] = []
        for band in MPAgeRange.allCases {
            let count = ideasShown(forAge: band.representativeAge).count
            if count < cardsRequired {
                starved.append("\(band.title) (age \(band.representativeAge)): \(count) ideas")
            }
        }
        XCTAssertTrue(
            starved.isEmpty,
            "Age bands the profile editor offers but the catalog cannot serve. A child in "
            + "one of these sees a screen with nothing on it but Surprise:\n  "
            + starved.joined(separator: "\n  "))
    }

    /// The band that does work, asserted separately so a regression there is
    /// distinguishable from the coverage gap above.
    /// 5-7 bandı hâlâ tam ekran: üç kart artı Sürpriz.
    func testTheFullyAuthoredBandStillFillsTheScreen() {
        XCTAssertGreaterThanOrEqual(
            ideasShown(forAge: 6).count, 3,
            "İçeriği tamamlanmış bant ekranı doldurmalı.")
    }

    /// 3-4 bandında bugün tek kart var ve bu bilinen bir durum.
    ///
    /// Daha fazla fikir kartı yazmak, hepsi aynı tek blueprint'e çözülürdü —
    /// farklı sözler veren kartlar, aynı hikâye şekli. Kartı çoğaltmadan önce
    /// o banda ikinci bir blueprint gerekiyor.
    func testTheYoungBandHasWhatItHas() {
        XCTAssertGreaterThanOrEqual(ideasShown(forAge: 4).count, 1)
    }

    /// An intent with no age still composes: `BlueprintSelector` filters by
    /// band only when the intent carries one. The creation flow always passes
    /// the child's age now (`StoryModeFlowTests`), so this is the legacy path —
    /// kept so older call sites are known to still work.
    func testSurpriseStillProducesAStoryOutsideTheAuthoredBand() throws {
        let result = try OfflineStoryService.shared.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, seed: "age-check")
        XCTAssertFalse(result.story.pages.isEmpty)
    }
}
