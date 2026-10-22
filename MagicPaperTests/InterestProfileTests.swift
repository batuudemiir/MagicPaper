import XCTest
import StoryEngine
@testable import MagicPaper

/// İlgi alanları profilde (FAZ 12): eski profiller açılıyor, seçim saklanıyor,
/// gizlenen bir kelime düzenlemede kaybolmuyor, ve hiçbiri log'a düşmüyor.
@MainActor
final class InterestProfileTests: XCTestCase {

    private let profilesKey = "user_profiles"
    private let currentKey = "current_profile_id"

    private let animals = InterestChoice(id: "animals", name: "Hayvanlar", symbol: "pawprint")
    private let nature = InterestChoice(id: "nature", name: "Doğa", symbol: "leaf")
    private let space = InterestChoice(id: "space", name: "Uzay", symbol: nil)
    private let sea = InterestChoice(id: "sea", name: "Deniz", symbol: nil)
    private var choices: [InterestChoice] { [animals, nature, space, sea] }

    // MARK: - Geriye dönük çözme

    /// A profile list saved before FAZ 12 — no `interests` key — must load.
    /// `loadProfiles` decodes with `try?`: a failure here empties the app.
    func testAProfileSavedBeforeFaz12StillLoads() throws {
        let json = """
        [
          { "id": "6F2C1B8E-3D7A-4C55-9F3E-2B1A0C9D8E7F", "name": "Elif", "age": 5,
            "profileType": "child", "createdAt": 780000000 },
          { "id": "0A1B2C3D-4E5F-4A6B-8C7D-9E0F1A2B3C4D", "name": "Can", "age": 8,
            "profileType": "child", "imageFileName": "profile_x.jpg", "createdAt": 780000100 }
        ]
        """
        let profiles = try JSONDecoder().decode([UserProfile].self, from: Data(json.utf8))
        XCTAssertEqual(profiles.map(\.name), ["Elif", "Can"])
        XCTAssertEqual(profiles.map(\.interests), [[], []])
        XCTAssertEqual(profiles[1].imageFileName, "profile_x.jpg")
    }

    func testInterestsSurviveARoundTrip() throws {
        let profile = UserProfile(name: "Ada", age: 6, interests: ["animals", "sea"])
        let decoded = try JSONDecoder().decode(UserProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(decoded.interests, ["animals", "sea"])
        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, "Ada")
    }

    // MARK: - Kurallar

    func testOnlyOfferedInterestsAreShownInCatalogOrder() {
        let shown = ChildInterests.offered(["sea", "dinosaurs", "animals"], from: [animals, nature, sea])
        XCTAssertEqual(shown, ["animals", "sea"])
    }

    /// The catalog stopped offering "dinosaurs": it is not shown, and an edit
    /// that never saw it must not delete it.
    func testAnEditKeepsWhatTheScreenDidNotShow() {
        let merged = ChildInterests.merging(
            stored: ["dinosaurs", "animals"], edited: ["nature"], choices: [animals, nature])
        XCTAssertEqual(merged, ["nature", "dinosaurs"])
    }

    func testAtMostThreeAreKept() {
        XCTAssertEqual(ChildInterests.maxSelection, 3)
        XCTAssertTrue(ChildInterests.canAdd("sea", to: ["animals", "nature"]))
        XCTAssertFalse(ChildInterests.canAdd("sea", to: ["animals", "nature", "space"]))
        XCTAssertTrue(ChildInterests.canAdd("space", to: ["animals", "nature", "space"]), "removing is always allowed")
        let merged = ChildInterests.merging(
            stored: [], edited: ["animals", "nature", "space", "sea"], choices: choices)
        XCTAssertEqual(merged, ["animals", "nature", "space"])
    }

    /// Karar (4 Ekim 2026): dörtten az sunulan kelimeyle ekranlar gizli.
    func testTheScreensNeedAtLeastFourOfferedWords() {
        XCTAssertEqual(ChildInterests.minimumOfferedToShow, 4)
        XCTAssertFalse(ChildInterests.isShown([]))
        XCTAssertFalse(ChildInterests.isShown([animals, nature, space]))
        XCTAssertTrue(ChildInterests.isShown(choices))
    }

    /// Ekranlar gizli, ve saklanan bir kelime hâlâ motora ulaşıyor.
    ///
    /// 21 Ekim'de bu test bir tur "ekranlar açıldı" diye yazıldı: A turunda
    /// sunulan kelime 2'den 4'e çıkmış görünüyordu ve FAZ 12 eşiği aşılmıştı.
    /// 22 Ekim'de ölçülünce sebebin içerik olmadığı çıktı: 3-4 bandının
    /// kapsaması hiçbir moda bağlanamayan bir blueprint üzerinden sayılıyordu
    /// (`InterestReachabilityTests`). Kapsama o blueprint'i saymayı bıraktığı
    /// an sunulan kelime bire düştü, yani eşik hiç meşru biçimde aşılmamış.
    ///
    /// Yani doğru hâli bu: ekranlar gizli. Eşik, katalog dörtten az kelimeyi
    /// her bantta onurlandırabiliyorsa soru sormamak için var — tutamayacağın
    /// bir söz vermemek için.
    ///
    /// Değişmeyen taraf: gizlemek unutmak değil. Eşiğin altında kalan bir
    /// kelime bile motora ulaşmaya devam eder.
    func testTodaysCatalogHidesTheScreensButKeepsWeighing() throws {
        let offered = OfflineStoryService.shared.interestChoices()
        XCTAssertFalse(ChildInterests.isShown(offered),
                       "katalog \(offered.count) kelime sunuyor, eşik \(ChildInterests.minimumOfferedToShow)")
        XCTAssertEqual(ChildInterests.offered(["animals"], from: offered), ["animals"])
    }

    func testNoneIsAValidAnswer() {
        XCTAssertEqual(ChildInterests.merging(stored: ["animals"], edited: [], choices: choices), [])
    }

    // MARK: - Saklama

    func testInterestsAreStoredPerChildAndLeaveWithTheProfile() throws {
        let manager = ProfileManager.shared
        let savedProfiles = manager.profiles
        let savedCurrent = manager.currentProfile
        let savedData = UserDefaults.standard.data(forKey: profilesKey)
        let savedCurrentID = UserDefaults.standard.string(forKey: currentKey)
        let first = UserProfile(name: "Test Bir", age: 6)
        let second = UserProfile(name: "Test İki", age: 4)
        defer {
            manager.profiles = savedProfiles
            manager.currentProfile = savedCurrent
            UserDefaults.standard.set(savedData, forKey: profilesKey)
            UserDefaults.standard.set(savedCurrentID, forKey: currentKey)
        }
        manager.profiles = savedProfiles + [first, second]

        manager.setInterests(["animals", "nature", "animals"], for: first.id)
        manager.setInterests(["sea"], for: second.id)

        let stored = try JSONDecoder().decode(
            [UserProfile].self, from: XCTUnwrap(UserDefaults.standard.data(forKey: profilesKey)))
        XCTAssertEqual(stored.first { $0.id == first.id }?.interests, ["animals", "nature"], "duplicates dropped")
        XCTAssertEqual(stored.first { $0.id == second.id }?.interests, ["sea"])

        if case .failure = manager.deleteProfile(first) { return XCTFail("deleteProfile refused") }
        let after = try JSONDecoder().decode(
            [UserProfile].self, from: XCTUnwrap(UserDefaults.standard.data(forKey: profilesKey)))
        XCTAssertNil(after.first { $0.id == first.id })
        XCTAssertEqual(after.first { $0.id == second.id }?.interests, ["sea"])
    }

    // MARK: - Gizlilik

    /// A profile printed whole — `"\(profile)"` in some future log line —
    /// carries neither the child's name nor what they like.
    func testAProfileNeverPrintsItsNameOrInterests() {
        let profile = UserProfile(name: "Gizliad", age: 6, interests: ["dinosaurs"])
        var dumped = ""
        dump(profile, to: &dumped)
        for text in [String(describing: profile), String(reflecting: profile), "\(profile)", dumped] {
            XCTAssertFalse(text.contains("Gizliad"), text)
            XCTAssertFalse(text.contains("dinosaurs"), text)
        }
        XCTAssertTrue(Mirror(reflecting: profile).children.allSatisfy { $0.label == "profileType" })
    }

    // MARK: - Köprü

    /// Katalogdaki her bantta **gerçekten** ulaşılabilen kelimeler.
    ///
    /// Liste burada açık yazılı, çünkü bu kelimeler ebeveyne gösterilen
    /// sözlerin tamamı: sessizce büyümesi ya da küçülmesi bir ürün kararıdır,
    /// bir yan etki değil. Bugün tek kelime, çünkü 3-4 bandında bir çocuğun
    /// gerçekten alabildiği tek masal şekli var ve o yalnızca hayvanlara
    /// ulaşıyor. 3-4 için macera ya da öğrenme yazıldığı gün liste büyür.
    func testTheServiceOffersWhatReachesEveryBand() {
        let offered = OfflineStoryService.shared.interestChoices()
        XCTAssertEqual(offered.map(\.id), ["animals"])
        XCTAssertEqual(offered.map(\.name), ["Hayvanlar"])
        XCTAssertTrue(StoryChoiceSources.current.interestChoices() == offered)
    }

    /// Interests and history reach the engine and still produce a clean story;
    /// a word the catalog does not offer is dropped, not an error.
    func testComposingWithInterestsAndHistoryWorks() throws {
        let origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "bp_charge_tending_001",
            settingID: "setting_whispering_forest_001", companionID: "companion_fox_pilot_001",
            discoveryID: "object_wilting_seedling_001", fingerprint: "f", catalogVersion: "v",
            worldID: nil, modeID: nil, selectionStrategy: nil, ageBand: nil, subOptionID: nil)
        let result = try OfflineStoryService.shared.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .adventure, age: 6,
            interests: ["animals", "dinosaurs"], recent: [origin])
        XCTAssertTrue(result.story.isClean)
    }

    /// No interests and no history build exactly the book they built before.
    func testNoInterestsAndNoHistoryRebuildTheSameStory() throws {
        let service = OfflineStoryService.shared
        let plain = try service.compose(childName: "Yeliz", ideaID: nil, companionID: nil,
                                        mode: .learning, age: 6, seed: "faz12-app")
        let explicit = try service.compose(childName: "Yeliz", ideaID: nil, companionID: nil,
                                           mode: .learning, age: 6, seed: "faz12-app",
                                           interests: [], recent: [])
        XCTAssertEqual(plain.story.fingerprint, explicit.story.fingerprint)
    }
}
