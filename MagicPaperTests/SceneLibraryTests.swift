import XCTest
import StoryEngine
@testable import MagicPaper

/// Sahne kütüphanesinin bütünlüğü: manifest, eylem sözleşmesi, içerik onayı
/// ve MVP kapsaması (B2, plan §1, §3.2.1, §9.1).
final class SceneLibraryTests: XCTestCase {

    private var library: SceneLibrary {
        get throws {
            try XCTUnwrap(SceneLibrary.load(from: .main),
                          "scene_library.json uygulama paketinde yok ya da çözülemiyor")
        }
    }

    private var kit: AvatarKit {
        get throws {
            try XCTUnwrap(AvatarKit.load(from: .main),
                          "avatar_kit.json uygulama paketinde yok ya da çözülemiyor")
        }
    }

    // MARK: - Manifest

    func testSceneIDsAreUnique() throws {
        let ids = try library.scenes.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryVersionNumberIsUniqueWithinItsScene() throws {
        for scene in try library.scenes {
            let numbers = scene.versions.map(\.version)
            XCTAssertEqual(numbers.count, Set(numbers).count, scene.id)
            XCTAssertFalse(numbers.isEmpty, "\(scene.id): sürümü yok")
        }
    }

    func testLifecyclesAreKnown() throws {
        for scene in try library.scenes {
            for v in scene.versions {
                XCTAssertTrue(ContentLifecycle.all.contains(v.lifecycle), "\(scene.id) v\(v.version): \(v.lifecycle)")
            }
        }
    }

    /// Anchor'lar kadraj kesridir; piksel asla saklanmaz.
    func testAnchorsAndBandsStayInsideTheFrame() throws {
        func check(_ a: SceneLibrary.Anchor, _ label: String) {
            for value in [a.x, a.y, a.scale] {
                XCTAssertTrue((0...1).contains(value), "\(label): \(value)")
            }
            XCTAssertGreaterThan(a.scale, 0, label)
            XCTAssertTrue(["left", "right"].contains(a.facing), "\(label): \(a.facing)")
        }
        for scene in try library.scenes {
            for v in scene.versions {
                check(v.characterAnchor, "\(scene.id) karakter")
                if let c = v.companionAnchor { check(c, "\(scene.id) yol arkadaşı") }
                if let b = v.quietBand {
                    XCTAssertTrue(b.x >= 0 && b.y >= 0 && b.x + b.width <= 1 && b.y + b.height <= 1, scene.id)
                }
                if let p = v.placeholderArt {
                    XCTAssertTrue((0...1).contains(p.horizon), scene.id)
                }
            }
        }
    }

    /// Arka plan en arkada ve zorunlu; avatar her sahnede; katman rolleri bilinen.
    func testLayersAreOrderedAndKnown() throws {
        for scene in try library.scenes {
            for v in scene.versions {
                let roles = v.layers.map(\.role)
                XCTAssertEqual(roles.first, SceneLayerRole.background, scene.id)
                XCTAssertEqual(roles.filter { $0 == SceneLayerRole.avatar }.count, 1, scene.id)
                XCTAssertLessThanOrEqual(roles.filter { $0 == SceneLayerRole.companion }.count, 1, scene.id)
                for role in roles {
                    XCTAssertTrue(SceneLayerRole.all.contains(role), "\(scene.id): \(role)")
                }
                // Yol arkadaşının yeri varsa katmanda da yeri olmalı, ve tersi.
                XCTAssertEqual(v.companionAnchor != nil, roles.contains(SceneLayerRole.companion), scene.id)
            }
        }
    }

    /// Yer tutucu sürüm varlık adına değil yer tutucu çizime dayanır; gerçek
    /// sürüm arka plan varlığını adıyla taşır ve `Scenes/` ad alanındadır.
    func testPlaceholderAndRealVersionsDeclareTheirArt() throws {
        for scene in try library.scenes {
            for v in scene.versions {
                if v.placeholder {
                    XCTAssertNotNil(v.placeholderArt, "\(scene.id) v\(v.version): yer tutucu çizimi yok")
                } else {
                    let bg = v.layers.first { $0.role == SceneLayerRole.background }?.asset
                    XCTAssertNotNil(bg, "\(scene.id) v\(v.version): arka plan varlığı yok")
                }
                for layer in v.layers {
                    if let asset = layer.asset {
                        XCTAssertTrue(asset.hasPrefix("Scenes/"), "\(scene.id): \(asset)")
                    }
                }
            }
        }
    }

    func testPlaceholderMotifsExistInTheBundle() throws {
        for scene in try library.scenes {
            for v in scene.versions {
                for motif in v.placeholderArt?.motifs ?? [] {
                    XCTAssertTrue(StoryArtKit.bundleHasAsset(motif), "\(scene.id): \(motif) yok")
                }
            }
        }
    }

    // MARK: - İçerik onayı (§9.1)

    /// Gerçek bir varlık, onaylayanı ve tarihi yazılmadan onaylı sayılmaz.
    func testRealApprovedVersionsNameTheirApprover() throws {
        for scene in try library.scenes {
            for v in scene.versions where !v.placeholder && v.lifecycle == ContentLifecycle.approved {
                XCTAssertFalse((v.approvedBy ?? "").isEmpty, "\(scene.id) v\(v.version): approvedBy yok")
                XCTAssertFalse((v.approvedAt ?? "").isEmpty, "\(scene.id) v\(v.version): approvedAt yok")
            }
        }
    }

    // MARK: - Eylem sözleşmesi (§3.2.1)

    func testEveryPoseTheLibraryNamesExistsInTheKit() throws {
        let poses = Set(try kit.poses.map(\.id))
        let lib = try library
        for (beat, pose) in lib.direction.beatPoses {
            XCTAssertTrue(poses.contains(pose), "beat \(beat) → \(pose)")
        }
        for (role, pose) in lib.direction.rolePoses {
            XCTAssertTrue(poses.contains(pose), "rol \(role) → \(pose)")
        }
        XCTAssertTrue(poses.contains(lib.direction.fallbackPose))
        for scene in lib.scenes {
            for pose in scene.allowedPoses {
                XCTAssertTrue(poses.contains(pose), "\(scene.id): \(pose)")
            }
            XCTAssertTrue(scene.allowedPoses.contains(scene.defaultPose), "\(scene.id): defaultPose izinli değil")
            for v in scene.versions {
                if let p = v.companionAnchor?.pose { XCTAssertFalse(p.isEmpty, scene.id) }
            }
        }
    }

    /// Daha özel bir eşleşme hiçbir zaman yenilikle ya da ağırlıkla geçilmesin:
    /// en küçük özgüllük basamağı (10) azami cezadan ve ağırlık aralığından büyük.
    func testSpecificityOutranksNoveltyAndWeight() throws {
        let lib = try library
        let weights = lib.scenes.map(\.weight)
        let spread = (weights.max() ?? 0) - (weights.min() ?? 0)
        XCTAssertLessThan(lib.cooldown.penalty + spread, 10)
        XCTAssertGreaterThanOrEqual(lib.cooldown.penalty, 0)
    }

    func testCanvasIsFourByThree() throws {
        let canvas = try library.canvas
        XCTAssertEqual(canvas.aspectRatio, 4.0 / 3.0, accuracy: 0.005)
        XCTAssertEqual(Double(canvas.minWidth) / Double(canvas.minHeight), 4.0 / 3.0, accuracy: 0.005)
    }

    // MARK: - İçerik kütüphanesiyle tutarlılık

    func testSettingIDsAndTagsExistInTheContentCatalog() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let ids = Set(catalog.settings.map(\.id.rawValue))
        let tags = Set(catalog.settings.flatMap { $0.tags.map(\.rawValue) })
        for scene in try library.scenes {
            for id in scene.settingIDs { XCTAssertTrue(ids.contains(id), "\(scene.id): \(id)") }
            for tag in scene.settingTags { XCTAssertTrue(tags.contains(tag), "\(scene.id): \(tag)") }
        }
    }

    /// Yol arkadaşıyla tanışma 3. sayfada; 1. ve 2. sayfanın rollerindeki
    /// sahneler yol arkadaşı yeri taşımamalı (plan §1.4).
    func testScenesBeforeTheCompanionMeetingHaveNoCompanion() throws {
        for scene in try library.scenes where !Set(scene.roles).isDisjoint(with: ["hook", "discovery"]) {
            for v in scene.versions {
                XCTAssertNil(v.companionAnchor, "\(scene.id): yol arkadaşı tanışmadan önce resimde")
            }
        }
    }

    // MARK: - MVP kapsaması (ölçülmüş)

    /// Macera, 5-6 yaş: görsel yuvası alan her sayfa bir sahne bulur ve ana
    /// beat'inin `beatPoses`'ta açık bir karşılığı vardır. Matris, plan §1'deki
    /// ölçümün küçültülmüş tekrarı — tahmin değil, motorun kendi çıktısı.
    func testEveryMVPAdventureStoryIsFullyIllustrated() throws {
        let lib = try library
        let catalog = try ContentCatalogLoader().load().catalog
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        let selector = BlueprintSelector()
        let picker = SceneSelector(library: lib)

        var stories = 0
        var gaps = Set<String>()
        var unmappedBeats = Set<String>()

        let ideas: [CatalogStoryIdea?] = [nil] + selector.storyIdeas(catalog: catalog, mode: .adventure, ageBand: band).map { Optional($0) }
        for idea in ideas {
            let companions = selector.companionCandidates(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "", storyIdeaID: idea?.id, seed: "candidates",
                                           mode: .adventure, ageBand: band),
                idea: idea)
            for companion in [nil] + companions.map({ Optional($0) }) {
                for s in 0..<15 {
                    let intent = OfflineStoryIntent(childName: "Ada", storyIdeaID: idea?.id,
                                                    companionID: companion?.id, seed: "b2-\(s)",
                                                    mode: .adventure, ageBand: band)
                    guard let composed = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent) else { continue }
                    stories += 1
                    let input = IllustratedBookBinder.selectorInput(from: composed, mode: .adventure,
                                                                    ageBand: band, recentSceneIDs: [])
                    let selection = picker.select(input)
                    for gap in selection.gaps { gaps.insert("\(gap.settingID)·\(gap.role)") }
                    XCTAssertEqual(selection.plates.count, 4, composed.blueprintID.rawValue)
                    for page in picker.illustratedPages(input.pages, ageBand: input.ageBand) {
                        if let beat = page.beats.first, lib.direction.beatPoses[beat] == nil {
                            unmappedBeats.insert(beat)
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(stories, 100, "ölçüm anlamlı olacak kadar masal üretmedi")
        XCTAssertTrue(gaps.isEmpty, "kapsama boşlukları: \(gaps.sorted())")
        XCTAssertTrue(unmappedBeats.isEmpty, "beatPoses karşılığı olmayan beat'ler: \(unmappedBeats.sorted())")
    }
}
