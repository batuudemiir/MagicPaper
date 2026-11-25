import XCTest
import StoryEngine
@testable import MagicPaper

/// Görselli kitabın akışa bağlanması (B2, Faz 4): bayrak, avatar deposu,
/// masal üretimine ek olma, anlık görüntü, cooldown ve kahramandan türetilen
/// kitap karakteri (E4).
@MainActor
final class IllustratedBookFlowTests: XCTestCase {

    // MARK: - Fixture'lar

    private var subdirectory: String!
    private var store: AvatarStore!

    override func setUp() async throws {
        try await super.setUp()
        subdirectory = "AvatarsTest-\(UUID().uuidString)"
        store = AvatarStore(subdirectory: subdirectory)
    }

    override func tearDown() async throws {
        AvatarStore.eraseAll(subdirectory: subdirectory)
        try await super.tearDown()
    }

    private let profile = UserProfile(id: UUID(), name: "Ada", age: 6, profileType: .child)

    private let avatarA = AvatarSpec(skinTone: "skin_dark", hairStyle: "hair_curly",
                                     hairColor: "haircolor_black", outfit: "outfit_green", accessory: "acc_glasses")
    private let avatarB = AvatarSpec(skinTone: "skin_light", hairStyle: "hair_ponytail",
                                     hairColor: "haircolor_red", outfit: "outfit_yellow")

    /// Gerçek motorla, sabit seed'le bir macera masalı.
    ///
    /// Seed 21 Ekim 2026'da `b2-demo-001`'den buna taşındı. Sebep testte değil
    /// içerikte: havuz diriltilince (A turu) aynı seed artık **kaleyi**
    /// seçiyor, B2 sahne kütüphanesinin ise yalnızca orman, çayır ve bahçe
    /// çizimleri var (Faz 1; Faz 2 onay bekliyor). Yani eski seed'le kitap
    /// sahnesiz kalıyor ve bu bir kapsama boşluğu, bir regresyon değil.
    ///
    /// Bu seed ormana düşüyor, böylece "avatar varsa kural A sayfaları sahne
    /// alır" iddiası yine gerçekten sınanıyor. Boşluğun kendisi
    /// `testMostAdventureSettingsHaveNoSceneYet` ile ayrıca kayıtlı.
    ///
    /// 25 Kasım 2026: havuz yine büyüdü ve aynı seed bu kez çarşıya
    /// (`setting_arched_bazaar_001`, çizimi yok) düştü. Seed'i ikinci kez
    /// taşımak yerine varsayılan masalın mekânı ormana sabitlendi: iddia "çizimi
    /// olan mekânda kural A sayfaları sahne alır", seed'in hangi mekâna düştüğü
    /// değil. Seed taraması yapan testler (`forest: false`) eskisi gibi serbest.
    private func composed(seed: String = "b2-demo-002", forest: Bool = true) throws -> ComposedStory {
        let catalog = try ContentCatalogLoader().load().catalog
        return try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: profile.name,
                                       settingID: forest ? ContentID("setting_forest_001") : nil,
                                       seed: seed, mode: .adventure,
                                       ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
    }

    private func mapped(_ composed: ComposedStory) -> MagicPaper.Story {
        OfflineStoryMapper.appStory(from: composed, childName: profile.name, childProfileID: profile.id,
                                    storyIdeaID: nil, catalogVersion: "test", mode: .adventure)
    }

    private func illustrate(_ story: MagicPaper.Story, _ composed: ComposedStory, enabled: Bool = true,
                            existing: [MagicPaper.Story] = []) async -> MagicPaper.Story {
        await IllustratedBookBinder.illustrateIfEnabled(
            story, composed: composed, profile: profile, mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6), existing: existing,
            isEnabled: enabled, avatars: store)
    }

    private func json(_ story: MagicPaper.Story) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(story)
    }

    private func realSpotFixture() throws -> (ComposedStory, MagicPaper.Story) {
        let catalog = try ContentCatalogLoader().load().catalog
        let spots = try XCTUnwrap(StorySpotCatalog.bundled)
        let rule = try XCTUnwrap(spots.rules.first { $0.assetID == "spot.torn-map" })
        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == rule.blueprintID })
        for index in 0..<160 {
            let intent = OfflineStoryIntent(childName: profile.name,
                settingID: ContentID("setting_forest_001"), discoveryID: ContentID("object_torn_map_001"),
                seed: "spot-b2-\(index)")
            guard let composed = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent) else { continue }
            let story = OfflineStoryMapper.appStory(from: composed, childName: profile.name,
                childProfileID: profile.id, storyIdeaID: nil, catalogVersion: catalog.version, mode: .adventure)
            if story.pages[0].art?.isBundledSpot == true { return (composed, story) }
        }
        throw NSError(domain: "StorySpotFixture", code: 1)
    }

    func testBoundSpotSurvivesDisabledB2AndNoAvatarAndEnabledSceneWins() async throws {
        let (composed, story) = try realSpotFixture()
        let disabled = await illustrate(story, composed, enabled: false)
        XCTAssertEqual(disabled.pages[0].art, story.pages[0].art)
        XCTAssertNil(disabled.pages[0].scene)
        let noAvatar = await illustrate(story, composed)
        XCTAssertEqual(noAvatar.pages[0].art, story.pages[0].art)
        XCTAssertNil(noAvatar.pages[0].scene)
        try await store.save(avatarA, for: profile.id)
        let enabled = await illustrate(story, composed)
        XCTAssertNotNil(enabled.pages[0].scene)
        XCTAssertEqual(enabled.pages[0].art, story.pages[0].art)
        XCTAssertEqual(ReaderStory(from: enabled).leaves.compactMap(\.page).first?.composition, .scene)
    }

    // MARK: - Masal üretimine ek

    /// Bayrak kapalıyken masal bayt bayt aynıdır.
    func testWithTheFlagOffTheStoryIsUntouched() async throws {
        try await store.save(avatarA, for: profile.id)
        let c = try composed()
        let story = mapped(c)
        let out = await illustrate(story, c, enabled: false)
        XCTAssertEqual(try json(out), try json(story))
    }

    /// Kayıtlı avatar yoksa masal bayt bayt aynıdır: uygulama ebeveyn adına
    /// bir görünüş seçmez.
    func testWithoutASavedAvatarTheStoryIsUntouched() async throws {
        let c = try composed()
        let story = mapped(c)
        let out = await illustrate(story, c)
        XCTAssertEqual(try json(out), try json(story))
        XCTAssertNil(out.illustration)
    }

    func testWithASavedAvatarTheRuleAPagesGetScenes() async throws {
        try await store.save(avatarA, for: profile.id)
        let c = try composed()
        let out = await illustrate(mapped(c), c)

        let illustrated = out.pages.enumerated().filter { $0.element.scene != nil }.map { $0.offset + 1 }
        XCTAssertEqual(illustrated, [1, 2, 4, 7])
        XCTAssertEqual(out.illustration?.avatar, avatarA)
        XCTAssertEqual(out.illustration?.gaps, [])
        // Metin değişmez: sahne eklemek metne dokunmaz.
        XCTAssertEqual(out.pages.map(\.text), mapped(c).pages.map(\.text))
        // Yol arkadaşı yalnızca tanışmadan sonra, türüyle birlikte.
        XCTAssertNil(out.pages[0].scene?.companionID)
        XCTAssertNotNil(out.pages[3].scene?.companionKind)
    }

    /// Bugün macera masallarının çoğu sahnesiz kalıyor — bu kayıt onu
    /// görünür tutuyor.
    ///
    /// A turunda havuz 8 mekândan 15'e çıktı; B2 kütüphanesinde ise üç zemin
    /// var (orman, çayır, bahçe). Sonuç: kale, köy, mağara, kar vadisi, köprü,
    /// kumsal ve dağda geçen kitap metin kitabı olarak kalıyor.
    ///
    /// Test bu oranı **korumuyor**, çünkü havuzun büyümesi doğru yönde bir
    /// hareket ve her yeni mekân çizim gelene kadar oranı düşürür. Yalnızca
    /// görselli yolun tümden ölmediğini sınıyor ve rakamı loga yazıyor; çizim
    /// kapsamını büyütmek B2 Faz 2'nin işi.
    func testMostAdventureSettingsHaveNoSceneYet() async throws {
        try await store.save(avatarA, for: profile.id)
        var withScenes = 0
        var bare: [String] = []
        for index in 1...40 {
            let seed = "b2-demo-\(String(format: "%03d", index))"
            let c = try composed(seed: seed, forest: false)
            let out = await illustrate(mapped(c), c)
            if out.pages.contains(where: { $0.scene != nil }) {
                withScenes += 1
            } else {
                bare.append(c.content.setting.id.rawValue)
            }
        }
        print("B2 kapsama: 40 macera seed'inin \(withScenes)'i sahne aldı. "
              + "Çizimi olmayan mekânlar: \(Set(bare).sorted().joined(separator: ", "))")
        XCTAssertGreaterThan(withScenes, 0, "hiçbir macera masalı sahne almıyor: görselli yol tümden kapalı")
    }

    /// Aynı seed her seferinde aynı sahneleri verir.
    func testTheSameSeedGivesTheSameScenes() async throws {
        try await store.save(avatarA, for: profile.id)
        let first = await illustrate(mapped(try composed()), try composed())
        let second = await illustrate(mapped(try composed()), try composed())
        XCTAssertEqual(first.pages.map(\.scene), second.pages.map(\.scene))
    }

    // MARK: - Anlık görüntü

    /// Avatar sonradan değişse de eski kitap eski görünüşü korur.
    func testChangingTheAvatarLaterDoesNotChangeAnOldBook() async throws {
        try await store.save(avatarA, for: profile.id)
        let c = try composed()
        let oldBook = await illustrate(mapped(c), c)

        try await store.save(avatarB, for: profile.id)
        let newBook = await illustrate(mapped(c), c)

        XCTAssertEqual(oldBook.illustration?.avatar, avatarA)
        XCTAssertEqual(newBook.illustration?.avatar, kitResolved(avatarB))
        // Eski kitap kaydedilip geri okunduğunda da eski görünüş.
        let reread = try JSONDecoder().decode(MagicPaper.Story.self, from: try json(oldBook))
        XCTAssertEqual(reread.illustration?.avatar, avatarA)
    }

    private func kitResolved(_ spec: AvatarSpec) -> AvatarSpec {
        AvatarKit.bundled?.resolved(spec) ?? spec
    }

    // MARK: - Cooldown

    func testRecentScenesComeOnlyFromThisChildsIllustratedBooks() async throws {
        try await store.save(avatarA, for: profile.id)
        let c = try composed()
        let mine = await illustrate(mapped(c), c)

        var someoneElses = mine
        someoneElses.childProfileID = UUID()
        let plain = mapped(c)

        let recent = IllustratedBookBinder.recentSceneIDs(in: [plain, someoneElses, mine], for: profile, window: 5)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(Set(recent[0]), Set(mine.pages.compactMap { $0.scene?.sceneID }))
    }

    // MARK: - Avatar deposu

    func testTheStoreSavesLoadsAndDeletes() async throws {
        let id = UUID()
        let none = await store.avatar(for: id)
        XCTAssertNil(none)
        try await store.save(avatarA, for: id)
        let loaded = await store.avatar(for: id)
        XCTAssertEqual(loaded, avatarA)
        await store.delete(for: id)
        let deleted = await store.avatar(for: id)
        XCTAssertNil(deleted)
    }

    func testEraseAllRemovesEveryAvatar() async throws {
        try await store.save(avatarA, for: UUID())
        let id = UUID()
        try await store.save(avatarB, for: id)
        AvatarStore.eraseAll(subdirectory: subdirectory)
        let after = await AvatarStore(subdirectory: subdirectory).avatar(for: id)
        XCTAssertNil(after)
    }

    // MARK: - Bayrak

    func testTheFlagIsADeveloperSettingThatDefaultsOnInDebug() throws {
        let name = "IllustratedBookAccessTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        #if DEBUG
        XCTAssertTrue(IllustratedBookAccess.isEnabled(defaults: defaults))
        IllustratedBookAccess.setDeveloperFlag(false, defaults: defaults)
        XCTAssertFalse(IllustratedBookAccess.isEnabled(defaults: defaults))
        #else
        XCTAssertFalse(IllustratedBookAccess.isEnabled(defaults: defaults))
        #endif
    }

    // MARK: - Tek kahraman kimliği (E4)

    /// Kahraman varsa kitap ondan çizilir; eski kayıtlı karakter kullanılmaz.
    func testAHeroIsDrawnFromTheHeroLook() async throws {
        let suite = "HeroBookTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let heroes = HeroLookStore(defaults: defaults)
        let look = HeroLook(skin: 5, hair: .braids, hairColor: 4, topColor: 1)
        heroes.save(look, for: profile.id)
        try await store.save(avatarB, for: profile.id)

        let c = try composed()
        let out = await IllustratedBookBinder.illustrateIfEnabled(
            mapped(c), composed: c, profile: profile, mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6), existing: [],
            isEnabled: true, avatars: store, heroes: heroes)
        XCTAssertEqual(out.illustration?.avatar, HeroBookCharacter.spec(for: look, kit: .bundled))
        XCTAssertEqual(out.illustration?.avatar.skinTone, "skin_dark")
        XCTAssertEqual(out.illustration?.avatar.hairStyle, "hair_braided")
    }

    /// Hayvan kahramanda kitap metin kalır, eski kayıtlı karakter olsa bile.
    func testAnAnimalHeroWritesATextBook() async throws {
        let suite = "HeroBookTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let heroes = HeroLookStore(defaults: defaults)
        heroes.save(HeroLook(kind: .fox, fur: 0), for: profile.id)
        try await store.save(avatarA, for: profile.id)

        let c = try composed()
        let story = mapped(c)
        let out = await IllustratedBookBinder.illustrateIfEnabled(
            story, composed: c, profile: profile, mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6), existing: [],
            isEnabled: true, avatars: store, heroes: heroes)
        XCTAssertNil(out.illustration)
        XCTAssertEqual(try json(out), try json(story))
    }
}
