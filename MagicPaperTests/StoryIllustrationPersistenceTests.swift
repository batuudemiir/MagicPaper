import XCTest
@testable import MagicPaper

/// Görselli kitabın anlık görüntüsü kütüphaneye zarar vermeden saklanır ve
/// geri okunur (B2, plan §4).
///
/// Masallar `UserDefaults["stories"]`'te tek bir `[Story]` dizisi olarak
/// çözülür. Buradaki her test aynı riskin bir yüzü: yeni alanlardaki tek bir
/// hata bir çocuğun bütün rafını düşürmemeli.
final class StoryIllustrationPersistenceTests: XCTestCase {

    // MARK: - Fixture'lar

    /// B2'den önce düz `JSONEncoder` ile yazılmış bir kütüphane (tarihler 2001
    /// referanslı saniye). `illustration` ve `scene` anahtarları yok.
    private let legacyLibrary = """
    [
      {
        "id": "6F9619FF-8B86-D011-B42D-00C04FC964FF",
        "title": "Eski Masal",
        "childName": "Yeliz",
        "theme": "custom",
        "language": "tr",
        "status": "completed",
        "pages": [
          { "id": "7F9619FF-8B86-D011-B42D-00C04FC964FF", "title": "", "text": "Bir varmış.", "imagePrompt": "child at the edge" },
          { "id": "8F9619FF-8B86-D011-B42D-00C04FC964FF", "title": "", "text": "Bir yokmuş.", "imagePrompt": "child looking up" }
        ],
        "createdAt": 780000000,
        "lastReadPage": 1
      },
      {
        "id": "9F9619FF-8B86-D011-B42D-00C04FC964FF",
        "title": "Kimliksiz Masal",
        "childName": "Demir",
        "theme": "fantasy",
        "language": "tr",
        "status": "completed",
        "pages": [],
        "createdAt": 770000000
      }
    ]
    """

    private func avatar() -> AvatarSpec {
        AvatarSpec(skinTone: "skin_brown", hairStyle: "hair_curly", hairColor: "haircolor_black",
                   outfit: "outfit_green", accessory: "acc_glasses")
    }

    private func illustratedStory() -> Story {
        var story = Story(title: "Görselli", childName: "Ada", childProfileID: UUID(),
                          theme: .custom, language: .turkish, status: .completed)
        story.pages = (1...3).map { StoryPage(title: "", text: "Sayfa \($0)", imagePrompt: "scene \($0)") }
        story.pages[0].scene = ScenePlate(sceneID: "scene_forest_hook_01", sceneVersion: 1,
                                          pose: "lookingUp", facing: "right", companionID: nil)
        story.pages[2].scene = ScenePlate(sceneID: "scene_forest_problem_01", sceneVersion: 1,
                                          pose: "standing", facing: "right", companionID: "companion_fox_pilot_001")
        story.illustration = StoryIllustration(
            avatar: avatar(), avatarKitVersion: "1.0.0", avatarArtVersion: 1, sceneLibraryVersion: "1.0.0",
            gaps: [CoverageGapRecord(pageNumber: 2, role: "discovery",
                                     settingID: "setting_whispering_forest_001", settingTags: ["forest", "nature"])])
        return story
    }

    // MARK: - Eski kütüphane

    /// B2 öncesi masallar `illustration == nil`, her sayfada `scene == nil` ile çözülür.
    func testALibraryWrittenBeforeB2StillDecodes() throws {
        let stories = try JSONDecoder().decode([Story].self, from: Data(legacyLibrary.utf8))
        XCTAssertEqual(stories.count, 2)
        XCTAssertEqual(stories[0].title, "Eski Masal")
        XCTAssertEqual(stories[0].lastReadPage, 1)
        XCTAssertNil(stories[0].illustration)
        XCTAssertTrue(stories[0].pages.allSatisfy { $0.scene == nil })
        XCTAssertNil(stories[1].illustration)
    }

    // MARK: - Round-trip

    func testAnIllustratedStorySurvivesARoundTrip() throws {
        let story = illustratedStory()
        let decoded = try JSONDecoder().decode(Story.self, from: JSONEncoder().encode(story))

        // `Story ==` yalnızca kimliğe bakar; alanlar tek tek karşılaştırılır.
        XCTAssertEqual(decoded.illustration, story.illustration)
        XCTAssertEqual(decoded.pages.map(\.scene), story.pages.map(\.scene))
        XCTAssertEqual(decoded.illustration?.avatar, avatar())
        XCTAssertTrue(decoded.illustration?.isUsable ?? false)
    }

    /// D4 dosya deposu `Story`'yi `Codable` ile yazar; yeni alanlar onunla taşınır.
    @MainActor
    func testTheFileStoreCarriesTheSnapshot() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("B2Snapshot-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = try LibraryFileStore(root: root)
        let story = illustratedStory()
        _ = try store.writeStory(story)

        let read = store.readAllStories()
        XCTAssertTrue(read.failures.isEmpty)
        let back = try XCTUnwrap(read.stories.first { $0.id == story.id })
        XCTAssertEqual(back.illustration, story.illustration)
        XCTAssertEqual(back.pages.map(\.scene), story.pages.map(\.scene))
    }

    // MARK: - Bozuk anlık görüntü kütüphaneyi düşürmez

    func testACorruptSnapshotDoesNotTakeTheLibraryWithIt() throws {
        var array = try JSONSerialization.jsonObject(with: Data(legacyLibrary.utf8)) as! [[String: Any]]
        // Birinci masal: tamamen yanlış tipte bir anlık görüntü ve bozuk bir plate.
        array[0]["illustration"] = "bu bir nesne değil"
        var pages = array[0]["pages"] as! [[String: Any]]
        pages[0]["scene"] = ["sceneVersion": "iki", "pose": 7] as [String: Any]
        array[0]["pages"] = pages
        // İkinci masal: bu sürümün tanımadığı bir şema ve eksik avatar.
        array[1]["illustration"] = ["schemaVersion": 99, "gaps": "yanlış"] as [String: Any]

        let data = try JSONSerialization.data(withJSONObject: array)
        let stories = try JSONDecoder().decode([Story].self, from: data)

        XCTAssertEqual(stories.count, 2, "kütüphane çözülmeye devam etmeli")
        XCTAssertEqual(stories[0].illustration?.isUsable, false)
        XCTAssertEqual(stories[0].pages[0].scene?.sceneID, "", "bozuk plate boş kimliğe düşer → metin sayfası")
        XCTAssertEqual(stories[1].illustration?.isUsable, false)
        XCTAssertEqual(stories[1].illustration?.gaps, [])
    }

    // MARK: - Sürüm sabitleme (plan §4.2)

    private func scene(versions: [(Int, String, Bool)]) throws -> SceneLibrary.Scene {
        let doc: [String: Any] = [
            "id": "s", "settingIDs": [], "settingTags": [], "modes": [], "roles": ["hook"], "beats": [],
            "emotions": [], "allowedPoses": ["standing"], "defaultPose": "standing", "altTextTR": "",
            "weight": 1,
            "versions": versions.map { n, lifecycle, placeholder in
                [
                    "version": n, "lifecycle": lifecycle, "placeholder": placeholder,
                    "layers": [["role": "background"], ["role": "avatar"]],
                    "characterAnchor": ["x": 0.5, "y": 0.9, "scale": 0.5, "facing": "right"] as [String: Any]
                ] as [String: Any]
            }
        ]
        return try JSONDecoder().decode(SceneLibrary.Scene.self,
                                        from: JSONSerialization.data(withJSONObject: doc))
    }

    /// 2026'da çizilen kitap, sahne 2027'de yeniden çizilse de 2026 sanatıyla açılır.
    func testABookOpensWithTheVersionItWasMadeWith() throws {
        let s = try scene(versions: [(1, "deprecated", false), (2, "approved", false)])
        XCTAssertEqual(s.renderable(pinned: 1)?.version, 1)
        XCTAssertEqual(s.renderable(pinned: 2)?.version, 2)
    }

    /// Yer tutucu sabitlenmez: gerçek sanat gelince eski kitap yükselir.
    func testAPlaceholderBookUpgradesToRealArt() throws {
        let s = try scene(versions: [(1, "approved", true), (2, "approved", false)])
        XCTAssertEqual(s.renderable(pinned: 1)?.version, 2)
    }

    /// Emekliye ayrılmış ya da artık bulunmayan sürüm en yeni onaylıya düşer;
    /// hiç onaylı sürüm yoksa sayfa metin sayfası olur.
    func testARetiredOrMissingVersionFallsToTheNewestApproved() throws {
        let s = try scene(versions: [(1, "retired", false), (3, "approved", false)])
        XCTAssertEqual(s.renderable(pinned: 1)?.version, 3)
        XCTAssertEqual(s.renderable(pinned: 2)?.version, 3)

        let none = try scene(versions: [(1, "retired", false), (2, "review", false)])
        XCTAssertNil(none.renderable(pinned: 1))
    }
}
