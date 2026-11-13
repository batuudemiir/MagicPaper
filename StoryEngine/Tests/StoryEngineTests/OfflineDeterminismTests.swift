import XCTest
@testable import StoryEngine

/// Determinism of the **live** path, pinned rather than merely self-consistent.
///
/// `OfflineCompositionTests.testSameIntentProducesTheSameBook` composes twice and
/// compares. That cannot fail for the reason we actually fear. Swift seeds
/// `Hashable` once per process, so `Set` and `Dictionary` iterate in a stable
/// order *within* a run and a different one on the next launch — two calls in one
/// test therefore agree even when the code is order-dependent. The defect it is
/// blind to is exactly the one that matters: a parent reopens the app tomorrow,
/// the story rebuilds from its stored seed, and comes back a different book.
///
/// So the assertions here are **literals**. A literal was produced by some
/// earlier process; matching it today is evidence about processes, which no
/// same-run comparison can give. A diff is not automatically a bug — content
/// changes move these legitimately — but it is always a decision, and re-pinning
/// belongs in a commit that says why the output moved.
final class OfflineDeterminismTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// The intent every pinned expectation below is written against.
    private let pinnedIntent = OfflineStoryIntent(
        childName: "Yeliz", seed: "pinned-seed-001")

    // MARK: - The stored-seed guarantee

    /// One seed, one book — including on a machine that has never run this seed.
    ///
    /// This is the promise `OfflineStoryService.compose` makes when it returns
    /// its seed for storage: "supply one to rebuild an existing story exactly".
    /// Every value here is part of that promise, so they are pinned together
    /// rather than as a single fingerprint — when this breaks, the failure
    /// should say *which* decision moved, not just that something did.
    func testAStoredSeedRebuildsTheSameBookInAFreshProcess() throws {
        let story = try OfflineStoryComposer().compose(
            catalog: catalog(), intent: pinnedIntent)

        // Re-pinned 2026-10-23: 3-4 bandının ikinci mekanizması
        // (`bp_charge_release_age3_001`) havuza girdi ve bu seed ona düştü.
        // Seed kaymasının kullanıcıya etkisi yok — saklanan masallar üretilmiş
        // metni tutuyor (K1) — ama bu testin işi tam olarak kaymayı söylemek.
        // Yeniden sabitlendi 30 Ekim 2026: havuza üç meslek blueprint'i girdi
        // ve sıralama değişti. Bu kez masal BANT da değiştirdi — 3-4'ün
        // `lettingGo`'sundan 5-6'nın `cooperation`'ına geçti — çünkü bu niyet
        // bant bildirmiyor ve bütün bantlar aday.
        // Yeniden sabitlendi 11 Kasım 2026 (Faz 10): uyku arkına üç ve 7-8
        // bandına altı blueprint girdi. Bu niyet bant bildirmediği için bütün
        // bantlar aday; havuz büyüdü, seed 5-6'nın `unexplained` şekline düştü.
        // Saklanan masallar metinlerini tuttuğu için çocuğu etkilemez (K1).
        // Yeniden sabitlendi 13 Kasım 2026: 9-10 bandının altı blueprint'i ve
        // kütüphanenin üç yeni kaydı (Cıvıl, müzik kutusu, kâğıt fener) havuza
        // girdi; seed 5-6'nın `absence` şekline düştü. Çocuğu etkilemez (K1).
        XCTAssertEqual(story.blueprintID.rawValue, "blueprint_absence_looking_001",
                       "The shape this seed resolves to moved.")
        // Re-pinned 2026-09-18 after D3 made Schema 2 canonical. The seed itself
        // did not move; the catalog it resolves against did — the five pilot
        // blueprints were merged up to the catalog's arcs, which changed their
        // requires/forbids and so changed which records are admissible.
        //
        // Re-pinning is safe for existing readers and this was verified, not
        // assumed: stored stories persist their generated prose
        // (`Story.pages[].text`), `StoryOrigin` has no reader anywhere in the
        // app, and `compose` is called only on the creation path. So a book
        // already in a child's library is not rebuilt from its seed and cannot
        // change under it. See docs/MagicPaper_Wave0_Stabilization.md §1.
        // Yeniden sabitlendi 23 Ekim 2026 (üçüncü kez): 3-4 bandının ikinci
        // mekanizması havuza girdi ve bu seed ona düştü, yani masal artık
        // 3-4 bandında. Bağlanan içerik de onunla değişti.
        // Yeniden sabitlendi 29 Ekim 2026 (dördüncü kez): üç insan yol arkadaşı
        // ve Pazar Yeri havuza girdi. Şekil aynı kaldı (3-4'ün `lettingGo`'su),
        // ona bağlanan içerik kaydı. İnsanların kendisi bu masala GİRMİYOR —
        // 3-4 havuzunda sıraları değiştirmeleri yeterli oldu.
        // 13 Kasım 2026: şekille birlikte bağlanan mekân ve arkadaş da değişti.
        XCTAssertEqual(story.content.setting.id.rawValue, "setting_whispering_forest_001")
        XCTAssertEqual(story.content.companion.id.rawValue, "companion_frog_001")
        XCTAssertEqual(story.content.discovery.id.rawValue, "object_torn_map_001")
        // Yeniden sabitlendi 21 Ekim 2026 (ikinci kez, havuz diriltmesi): v2
        // kütüphanesindeki 44 kayıt etiketlenip havuza katılınca bu seed
        // orman + tavşan yerine mağara + robot bağladı. Determinizm bozulmadı
        // — aynı seed aynı kitabı veriyor — değişen havuzun kendisi. Kaydedilmiş
        // masallar metinlerini sakladığı için çocuk bundan etkilenmiyor.
        //
        // Re-pinned 2026-10-21: title patterns became mode-specific and mostly
        // name-free (4-6 per blueprint). The old "Kayıp {{discovery.title}}"
        // made "Kayıp Yırtık Harita" here. Stored stories keep their title.
        //
        // Re-pinned 2026-10-23: masal 3-4'ün `lettingGo` şekline düştüğü için
        // başlık da onun kalıplarından geliyor.
        //
        // Yeniden sabitlendi 30 Ekim 2026: şekil değiştiği için kalıp kümesi de
        // değişti; başlık artık `appeal` ailesinin kalıplarından.
        // 13 Kasım 2026: başlık artık `absence` ailesinin kalıplarından.
        XCTAssertEqual(story.title, "Yeliz ve Zıpzıp Arıyor")

        // The lines themselves, which is what a child would notice changing.
        // On satır: 5-6 masalı sekiz sayfa ve iki sayfası destek beat'i
        // taşıyor. 30 Ekim'e kadar bu liste sekiz satırlıktı çünkü seed 3-4'e
        // düşüyordu; bant değişti, satır sayısı onunla değişti.
        XCTAssertEqual(
            story.pages.flatMap { $0.variantIDs.map(\.rawValue) },
            // 13 Kasım 2026: `absence` şekli on bir satır taşıyor.
            ["na_neutral_05", "ex_s_trace_02", "mc_care_04", "ra_p_01", "cm_p_05", "ob_gen_02",
             "fa_s_05", "ps_s_04", "rs_any_03", "wc_p_succeed_02", "cf_p_08"],
            "A different sentence was selected for at least one beat.")

        XCTAssertEqual(story.fingerprint, "1d80933ff9a54cd5")
    }

    /// The fingerprint is what a "has this story changed?" check would compare,
    /// so it has to be a function of the inputs and of nothing else — not of the
    /// process, and not of the clock.
    func testTheFingerprintIsAFunctionOfTheInputsAlone() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()

        let again = try composer.compose(catalog: catalog, intent: pinnedIntent)
        XCTAssertEqual(again.fingerprint, "1d80933ff9a54cd5")

        // A different child is a different book even on the same seed, which is
        // what stops two children sharing one cached story.
        let other = try composer.compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Demir", seed: "pinned-seed-001"))
        XCTAssertNotEqual(other.fingerprint, again.fingerprint)
    }

    /// Seeded selection is pinned at the primitive, so a failure here localises
    /// the cause to the picker rather than to the corpus above it.
    func testTheSeededPickerIsPinned() {
        let items = ["a", "b", "c", "d", "e", "f", "g"]
        XCTAssertEqual(DeterministicPicker.pick(from: items, seed: "s", salt: "setting"), "b")
        XCTAssertEqual(DeterministicPicker.pick(from: items, seed: "s", salt: "companion"), "g")
        XCTAssertEqual(DeterministicPicker.index(count: 7, seed: "s", salt: "setting"), 1)

        // A one-element pool never consults the hash, so an empty or single
        // candidate list cannot be a source of drift.
        XCTAssertEqual(DeterministicPicker.index(count: 1, seed: "anything", salt: "x"), 0)
        XCTAssertEqual(DeterministicPicker.index(count: 0, seed: "anything", salt: "x"), 0)
    }

    // MARK: - What the ordering defences actually cover

    /// Blueprint choice survives the catalog being reordered — `ranked` sorts by
    /// id before it rotates, on purpose.
    func testBlueprintChoiceIsIndependentOfBlueprintOrderInTheCatalog() throws {
        let original = try catalog()
        let reversed = Self.rebuilding(original, blueprints: original.blueprints.reversed())

        let selector = BlueprintSelector()
        let a = try selector.ranked(catalog: original, intent: pinnedIntent).map(\.id)
        let b = try selector.ranked(catalog: reversed, intent: pinnedIntent).map(\.id)
        XCTAssertEqual(a, b, "Blueprint ranking followed catalog order instead of id order.")
    }

    /// **The content axes do not have that defence, and this records it.**
    ///
    /// `OfflineContentBinder.choose` and `orderedCandidates` build `admissible`
    /// in catalog array order and then index into it with a seeded offset. The
    /// offset depends on the *count*; which record sits at that offset depends
    /// on the *order*. So moving a setting up the JSON file — an edit an author
    /// would consider cosmetic — silently repoints every stored seed at
    /// different content, and a family's saved story rebuilds as another story.
    ///
    /// This test asserts the current, order-sensitive behaviour so the hazard is
    /// executable rather than a paragraph nobody reads. It is deliberately not a
    /// fix: making the axes sort by id the way blueprints already do would change
    /// what every existing seed resolves to, and that is a content decision, not
    /// a refactor. When it is taken, this test is the one to invert.
    func testContentSelectionStillFollowsCatalogOrder() throws {
        let original = try catalog()
        let reordered = Self.rebuilding(original, settings: original.settings.reversed())

        let composer = OfflineStoryComposer()
        let a = try composer.compose(catalog: original, intent: pinnedIntent)
        let b = try composer.compose(catalog: reordered, intent: pinnedIntent)

        XCTAssertNotEqual(
            a.content.setting.id, b.content.setting.id,
            "Content selection has become order-independent. That is the desired "
            + "end state, but it also means every previously stored seed now "
            + "rebuilds a different story — re-pin the goldens deliberately and "
            + "invert this assertion.")
    }

    // MARK: - Age

    /// Surprise Me has no age input at all, and this is where that shows.
    ///
    /// `OfflineStoryIntent` carries a name and a seed. It does not carry an age,
    /// and `BlueprintSelector` never filters by one — age reaches the engine only
    /// through the idea card the child picked, and Surprise picks no card. A
    /// nine-year-old therefore gets a book banded 5-6: correct Turkish, correct
    /// structure, aimed at the wrong child, and nothing anywhere reports it.
    ///
    /// `AgeBandCoverageTests` says this too, but it lives in the Xcode app target
    /// and `swift test` never runs it, so the engine's own suite was silent about
    /// its own gap.
    func testSurpriseHasNoAgeInputAndLandsInTheAuthoredBand() throws {
        let catalog = try catalog()
        let story = try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Yeliz", seed: "age-check"))

        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id == story.blueprintID })
        // 23 Ekim 2026: korpus büyüdü ve bu seed 3-4'e düştü. Testin kendi
        // notu bu günü öngörüyordu ("if the corpus grew, this is good news"),
        // bu yüzden iddia tek bir banda değil **yazılmış bir banda** bağlandı.
        // Korunan şey asıl söz: yaş motora girmiyor, yani çocuğun hangi bandı
        // aldığı hâlâ seed'in tesadüfü — ve rakamı sabitlemek o gerçeği
        // gizlerdi.
        let authored = Set(catalog.blueprints.filter(\.isBeatAuthored).map(\.ageRange))
        XCTAssertTrue(
            authored.contains(blueprint.ageRange),
            "Surprise, içerik yazılmamış bir banda düştü: \(blueprint.ageRange)")
        XCTAssertGreaterThan(
            authored.count, 1,
            "Tek yazılmış bant kaldıysa bu test bir şey sınamıyor demektir")
    }

    /// The bands the profile editor offers against the bands the corpus serves.
    ///
    /// Recorded here in engine terms so the gap is visible to `swift test`. The
    /// two upper bands have no content whatsoever; the app papers over that with
    /// a nearest-band fallback that ships 5-6 prose to an eleven-year-old.
    func testTheAuthoredBandsAreStillOnlyThreeToFourAndFiveToSix() throws {
        let catalog = try catalog()
        let banded = Set(catalog.blueprints.map(\.ageRange.description))
        // Faz 10 (11 Kasım 2026): 7-8 yazıldı. 13 Kasım 2026: 9-10 da; dört
        // bandın hepsi blueprint taşıyor.
        XCTAssertEqual(banded, ["3-4", "5-6", "7-8", "9-10"],
                       "Authored bands moved; AgeBandCoverageTests and the "
                       + "nearest-band fallback in OfflineStoryService both "
                       + "assume this set.")

        // Faz 10: 8 yaşın kendi fikirleri var. 13 Kasım 2026: 9 ve 10 yaşın da.
        // En yakın banda düşme kodu duruyor ama hiçbir yaş için çalışmıyor
        // (`AgeBandResolver.servedBand` notu); yalnızca bant dışı yaşlar kaldı.
        for age in [11, 12] {
            XCTAssertTrue(
                catalog.storyIdeas.filter { $0.suits(age: age) }.isEmpty,
                "Age \(age) now has authored ideas — remove the nearest-band "
                + "fallback rather than leaving two mechanisms for one problem.")
        }
    }

    // MARK: - Helpers

    /// A copy of a catalog with one collection replaced.
    ///
    /// `ContentCatalog` is decode-only by design, so a test that wants to
    /// perturb record order has to go through the memberwise initialiser.
    private static func rebuilding(
        _ catalog: ContentCatalog,
        settings: [CatalogSetting]? = nil,
        blueprints: [CatalogBlueprint]? = nil
    ) -> ContentCatalog {
        ContentCatalog(
            version: catalog.version,
            settings: settings ?? catalog.settings,
            companions: catalog.companions,
            objects: catalog.objects,
            events: catalog.events,
            challenges: catalog.challenges,
            endings: catalog.endings,
            templates: catalog.templates,
            blueprints: blueprints ?? catalog.blueprints,
            storyIdeas: catalog.storyIdeas,
            declaredResolutionCount: catalog.declaredResolutionCount
        )
    }
}
