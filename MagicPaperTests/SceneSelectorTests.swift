import XCTest
@testable import MagicPaper

/// `SceneSelector`: determinizm, tekrar yok, cooldown, kapsama boşluğu,
/// yalnızca onaylı, eylem sözleşmesi, yol arkadaşı (B2, plan §3.2).
final class SceneSelectorTests: XCTestCase {

    // MARK: - Fixture'lar

    /// 8 sayfalık macera arkı; yol arkadaşı 3. sayfada.
    private let arc: [SceneSelector.Page] = [
        .init(number: 1, role: "hook",             beats: ["notice_anomaly"],     emotion: "curiosity"),
        .init(number: 2, role: "discovery",        beats: ["approach"],           emotion: "wonder"),
        .init(number: 3, role: "companion",        beats: ["meet_companion"],     emotion: "hesitation"),
        .init(number: 4, role: "problem",          beats: ["hesitate"],           emotion: "unease"),
        .init(number: 5, role: "attempt",          beats: ["small_step"],         emotion: "determination"),
        .init(number: 6, role: "challenge",        beats: ["find_own_courage"],   emotion: "effort"),
        .init(number: 7, role: "resolution",       beats: ["succeed"],            emotion: "relief"),
        .init(number: 8, role: "emotional_ending", beats: ["self_recognize", "warm_close"], emotion: "pride"),
    ]

    private func input(seed: String = "s1", setting: String = "setting_a", tags: [String] = ["forest"],
                       mode: String? = "adventure", recent: [[String]] = [],
                       pages: [SceneSelector.Page]? = nil) -> SceneSelector.Input {
        .init(pages: pages ?? arc, settingID: setting, settingTags: tags, mode: mode, ageBand: "5-6",
              seed: seed, companionID: "companion_fox", recentSceneIDs: recent)
    }

    private struct S {
        var id: String
        var roles: [String]
        var beats: [String] = []
        var settingIDs: [String] = ["setting_a"]
        var tags: [String] = ["forest"]
        var modes: [String] = ["adventure"]
        var poses: [String] = ["standing", "walking", "reaching", "lookingUp", "pointing", "celebrating"]
        var defaultPose = "standing"
        var weight = 1.0
        var lifecycle = "approved"
        var companion = false
        var extraVersion: (Int, String)? = nil
    }

    private func library(_ scenes: [S], penalty: Double = 5, window: Int = 5) throws -> SceneLibrary {
        func version(_ n: Int, _ lifecycle: String, _ s: S) -> [String: Any] {
            var layers: [[String: Any]] = [["role": "background"], ["role": "avatar"]]
            if s.companion { layers.append(["role": "companion"]) }
            var v: [String: Any] = [
                "version": n, "lifecycle": lifecycle, "placeholder": true,
                "layers": layers,
                "characterAnchor": ["x": 0.4, "y": 0.88, "scale": 0.5, "facing": "right"] as [String: Any],
                "placeholderArt": ["horizon": 0.6, "tone": "forest", "motifs": [String]()] as [String: Any]
            ]
            if s.companion { v["companionAnchor"] = ["x": 0.7, "y": 0.88, "scale": 0.25, "facing": "left", "pose": "standing"] as [String: Any] }
            return v
        }
        let doc: [String: Any] = [
            "schemaVersion": 1, "version": "test",
            "canvas": ["aspect": "4:3", "minWidth": 2048, "minHeight": 1536] as [String: Any],
            "illustratedPages": [
                "5-6": [["hook"], ["discovery"], ["problem", "challenge"], ["resolution", "emotional_ending"]],
                "default": [["hook"], ["discovery"], ["problem", "challenge"], ["resolution", "emotional_ending"]]
            ],
            "direction": [
                "beatPoses": ["notice_anomaly": "lookingUp", "approach": "walking", "hesitate": "standing",
                              "succeed": "celebrating", "examine": "reaching"],
                "rolePoses": ["hook": "lookingUp", "discovery": "walking", "problem": "standing",
                              "resolution": "celebrating"],
                "fallbackPose": "standing"
            ] as [String: Any],
            "cooldown": ["window": window, "penalty": penalty] as [String: Any],
            "scenes": scenes.map { s -> [String: Any] in
                var versions = [version(1, s.lifecycle, s)]
                if case let (n, l)? = s.extraVersion { versions.append(version(n, l, s)) }
                return [
                    "id": s.id, "settingIDs": s.settingIDs, "settingTags": s.tags, "modes": s.modes,
                    "roles": s.roles, "beats": s.beats, "emotions": [], "timeOfDay": "day",
                    "allowedPoses": s.poses, "defaultPose": s.defaultPose, "altTextTR": "sahne",
                    "weight": s.weight, "versions": versions
                ]
            }
        ]
        let data = try JSONSerialization.data(withJSONObject: doc)
        return try JSONDecoder().decode(SceneLibrary.self, from: data)
    }

    private func fullSet() -> [S] {
        [S(id: "hook", roles: ["hook"]),
         S(id: "disc", roles: ["discovery"]),
         S(id: "prob", roles: ["problem"], companion: true),
         S(id: "res", roles: ["resolution"], companion: true)]
    }

    // MARK: - Görselli sayfa kuralı

    func testRuleAIllustratesPagesOneTwoFourSeven() throws {
        let selection = SceneSelector(library: try library(fullSet())).select(input())
        XCTAssertEqual(selection.plates.keys.sorted(), [1, 2, 4, 7])
        XCTAssertTrue(selection.gaps.isEmpty)
    }

    /// Yuva, listedeki rollerden masalda ilk bulunana verilir: `problem` yoksa
    /// `challenge` görsel alır.
    func testASlotFallsToItsNextRoleWhenTheFirstIsAbsent() throws {
        let pages = arc.filter { $0.role != "problem" }
        let lib = try library(fullSet() + [S(id: "chal", roles: ["challenge"])])
        let selection = SceneSelector(library: lib).select(input(pages: pages))
        XCTAssertEqual(selection.plates[6]?.sceneID, "chal")
    }

    // MARK: - Determinizm

    func testTheSameInputAlwaysGivesTheSamePlates() throws {
        let scenes = fullSet() + [S(id: "hook2", roles: ["hook"]), S(id: "disc2", roles: ["discovery"])]
        let selector = SceneSelector(library: try library(scenes))
        let first = selector.select(input(seed: "abc"))
        for _ in 0..<20 { XCTAssertEqual(selector.select(input(seed: "abc")), first) }
    }

    /// Eşitlikte sıra seed'den gelir: farklı seed'ler farklı ama her biri kararlı.
    func testTiesAreBrokenBySeedNotByChance() throws {
        let scenes = (1...6).map { S(id: "hook\($0)", roles: ["hook"]) }
        let selector = SceneSelector(library: try library(scenes))
        let picks = Set((0..<40).map { selector.select(input(seed: "seed-\($0)")).plates[1]?.sceneID ?? "" })
        XCTAssertGreaterThan(picks.count, 1, "seed eşitliği hiç bozmuyor")
        XCTAssertFalse(picks.contains(""))
    }

    /// Algoritma `EngineFoundation.StableHash` ile aynı; pakete taşındığında
    /// seçimler değişmesin. Değer `StableHashTests` ile aynı yoldan hesaplandı.
    func testStableHashIsFNV1aWithSeparators() {
        XCTAssertNotEqual(SceneSelector.stableHash(["ab", "c"]), SceneSelector.stableHash(["a", "bc"]))
        XCTAssertEqual(SceneSelector.stableHash(["x"]), SceneSelector.stableHash(["x"]))
    }

    // MARK: - Tekrar yok

    func testNoSceneAppearsTwiceInOneStory() throws {
        // Tek sahne birden çok rolü karşılıyor: ikinci yuva onu alamaz.
        let lib = try library([S(id: "any", roles: ["hook", "discovery", "problem", "resolution"])])
        let selection = SceneSelector(library: lib).select(input())
        XCTAssertEqual(selection.plates.count, 1)
        XCTAssertEqual(selection.gaps.count, 3)
        let ids = selection.plates.values.map(\.sceneID)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    // MARK: - Cooldown

    func testARecentlyUsedSceneIsPenalisedNotForbidden() throws {
        let lib = try library([S(id: "hookA", roles: ["hook"]), S(id: "hookB", roles: ["hook"])])
        let selector = SceneSelector(library: lib)

        // Hangisi seçilirse seçilsin, geçmişe girince öbürü kazanmalı.
        let fresh = try XCTUnwrap(selector.select(input()).plates[1]?.sceneID)
        let other = fresh == "hookA" ? "hookB" : "hookA"
        XCTAssertEqual(selector.select(input(recent: [[fresh]])).plates[1]?.sceneID, other)

        // Tek aday varsa ceza onu yasaklamaz.
        let single = SceneSelector(library: try library([S(id: "only", roles: ["hook"])]))
        XCTAssertEqual(single.select(input(recent: [["only"]])).plates[1]?.sceneID, "only")
    }

    func testThePenaltyFadesAcrossTheWindow() throws {
        let selector = SceneSelector(library: try library([S(id: "x", roles: ["hook"])], penalty: 5, window: 5))
        XCTAssertEqual(selector.cooldownPenalty("x", recent: [["x"]]), 5)
        XCTAssertEqual(selector.cooldownPenalty("x", recent: [[], [], [], [], ["x"]]), 1)
        XCTAssertEqual(selector.cooldownPenalty("x", recent: [[], [], [], [], [], ["x"]]), 0)
    }

    /// Cooldown özgüllüğü geçemez: geçmişte olsa bile beat'e özel sahne,
    /// yalnızca rol eşleşen sahneye yenilmez.
    func testCooldownNeverOutranksSpecificity() throws {
        let lib = try library([S(id: "specific", roles: ["hook"], beats: ["notice_anomaly"]),
                               S(id: "generic", roles: ["hook"])])
        let selection = SceneSelector(library: lib).select(input(recent: [["specific"]]))
        XCTAssertEqual(selection.plates[1]?.sceneID, "specific")
    }

    // MARK: - Kapsama boşluğu

    /// Uyan sahne yoksa sayfa metin sayfası kalır ve boşluk kaydı düşer;
    /// rastgele bir sahneye asla.
    func testNoMatchLeavesATextPageAndRecordsAGap() throws {
        let lib = try library([S(id: "hook", roles: ["hook"], settingIDs: ["setting_other"], tags: ["sea"])])
        let selection = SceneSelector(library: lib).select(input())
        XCTAssertTrue(selection.plates.isEmpty)
        XCTAssertEqual(selection.gaps.map(\.pageNumber), [1, 2, 4, 7])
        XCTAssertEqual(selection.gaps.first?.settingID, "setting_a")
        XCTAssertEqual(selection.gaps.first?.role, "hook")
    }

    func testAWrongModeIsNotAMatch() throws {
        let lib = try library([S(id: "hook", roles: ["hook"], modes: ["bedtime"])])
        XCTAssertNil(SceneSelector(library: lib).select(input()).plates[1])
    }

    /// Ayar kimliği eşleşmesi tag eşleşmesini geçer (Gece Bahçesi ≠ Meyve Bahçesi).
    func testSettingIDOutranksATagMatch() throws {
        let lib = try library([S(id: "byTag", roles: ["hook"], settingIDs: [], weight: 2),
                               S(id: "byID", roles: ["hook"])])
        XCTAssertEqual(SceneSelector(library: lib).select(input()).plates[1]?.sceneID, "byID")
    }

    // MARK: - Yalnızca onaylı

    func testOnlyApprovedVersionsAreChosen() throws {
        for lifecycle in ["draft", "review", "deprecated", "retired", "rejected"] {
            let lib = try library([S(id: "hook", roles: ["hook"], lifecycle: lifecycle)])
            XCTAssertNil(SceneSelector(library: lib).select(input()).plates[1], lifecycle)
        }
    }

    func testTheNewestApprovedVersionIsPinned() throws {
        let lib = try library([S(id: "hook", roles: ["hook"], extraVersion: (2, "approved")),
                               S(id: "disc", roles: ["discovery"], extraVersion: (2, "review"))])
        let selection = SceneSelector(library: lib).select(input())
        XCTAssertEqual(selection.plates[1]?.sceneVersion, 2)
        XCTAssertEqual(selection.plates[2]?.sceneVersion, 1, "onay bekleyen sürüm verilmemeli")
    }

    // MARK: - Eylem sözleşmesi

    func testPoseComesFromTheBeatThenTheRoleThenTheScene() throws {
        let lib = try library(fullSet())
        let selection = SceneSelector(library: lib).select(input())
        XCTAssertEqual(selection.plates[1]?.pose, "lookingUp")   // notice_anomaly
        XCTAssertEqual(selection.plates[2]?.pose, "walking")     // approach
        XCTAssertEqual(selection.plates[4]?.pose, "standing")    // hesitate
        XCTAssertEqual(selection.plates[7]?.pose, "celebrating") // succeed

        // Beat haritada yok → rolün pozu.
        var pages = arc
        pages[1] = .init(number: 2, role: "discovery", beats: ["unmapped"], emotion: nil)
        XCTAssertEqual(SceneSelector(library: lib).select(input(pages: pages)).plates[2]?.pose, "walking")

        // Sahne ne beat'in ne rolün pozuna izin veriyor → sahnenin varsayılanı.
        let narrow = try library([S(id: "hook", roles: ["hook"], poses: ["sitting"], defaultPose: "sitting")])
        XCTAssertEqual(SceneSelector(library: narrow).select(input()).plates[1]?.pose, "sitting")
    }

    func testProblemAndResolutionDoNotShareAPose() throws {
        let selection = SceneSelector(library: try library(fullSet())).select(input())
        XCTAssertNotEqual(selection.plates[4]?.pose, selection.plates[7]?.pose)
    }

    // MARK: - Yol arkadaşı

    /// Tanışma 3. sayfada: öncesinde yol arkadaşı resimde olamaz, sonrasında
    /// yalnızca sahne onun yerini tanımlıyorsa görünür.
    func testTheCompanionAppearsOnlyAfterTheyMeet() throws {
        var scenes = fullSet()
        scenes[0].companion = true   // hook sahnesi yer tanımlasa bile
        let selection = SceneSelector(library: try library(scenes)).select(input())
        XCTAssertNil(selection.plates[1]?.companionID)
        XCTAssertNil(selection.plates[2]?.companionID)
        XCTAssertEqual(selection.plates[4]?.companionID, "companion_fox")
        XCTAssertEqual(selection.plates[7]?.companionID, "companion_fox")
    }

    func testTheCompanionIsLeftOutWhenTheSceneHasNoPlaceForThem() throws {
        var scenes = fullSet()
        scenes[2].companion = false
        let selection = SceneSelector(library: try library(scenes)).select(input())
        XCTAssertNil(selection.plates[4]?.companionID)
    }

    // MARK: - Gömülü kütüphane

    /// Gerçek manifestle aynı masal her seferinde aynı sahneleri verir.
    func testTheBundledLibraryIsDeterministicForTheDemoSeed() throws {
        let lib = try XCTUnwrap(SceneLibrary.load(from: .main))
        let selector = SceneSelector(library: lib)
        let demo = input(seed: "b2-demo-001", setting: "setting_whispering_forest_001")
        let first = selector.select(demo)
        XCTAssertEqual(first.plates.count, 4)
        XCTAssertEqual(selector.select(demo), first)
    }
}
