import XCTest
import StoryEngine
@testable import MagicPaper

/// Görselli kitabın akışa bağlanması (B2, Faz 4): bayrak, avatar deposu,
/// masal üretimine ek olma, anlık görüntü, cooldown ve kurulum ekranının modeli.
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
    private func composed(seed: String = "b2-demo-002") throws -> ComposedStory {
        let catalog = try ContentCatalogLoader().load().catalog
        return try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: profile.name, seed: seed, mode: .adventure,
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
            let c = try composed(seed: seed)
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

    // MARK: - Kurulum ekranının modeli

    func testTheSetupModelStartsFromAPreviewAndSavesOnlyOnSave() async throws {
        let model = BookCharacterModel(profileID: profile.id, store: store)
        await model.load()
        XCTAssertFalse(model.hasSaved)
        XCTAssertEqual(model.spec, AvatarKit.bundled?.previewDefault)

        model.select(.skinTone, "skin_brown")
        model.select(.accessory, "acc_beanie")
        let unsaved = await store.avatar(for: profile.id)
        XCTAssertNil(unsaved, "seçim kaydedilmeden hiçbir yere yazılmamalı")

        let saved = await model.save()
        XCTAssertTrue(saved)
        XCTAssertTrue(model.hasSaved)
        let stored = await store.avatar(for: profile.id)
        XCTAssertEqual(stored?.skinTone, "skin_brown")
        XCTAssertEqual(stored?.accessory, "acc_beanie")

        model.select(.accessory, nil)
        XCTAssertNil(model.spec.accessory, "aksesuar 'yok' seçilebilmeli")

        await model.remove()
        XCTAssertFalse(model.hasSaved)
        let removed = await store.avatar(for: profile.id)
        XCTAssertNil(removed)
    }

    func testTheSetupModelReopensWithTheSavedAvatar() async throws {
        try await store.save(avatarB, for: profile.id)
        let model = BookCharacterModel(profileID: profile.id, store: store)
        await model.load()
        XCTAssertTrue(model.hasSaved)
        XCTAssertEqual(model.spec, kitResolved(avatarB))
        XCTAssertTrue(model.spokenSummary.contains("kızıl"))
    }
}
