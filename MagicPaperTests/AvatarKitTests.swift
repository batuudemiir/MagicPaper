import XCTest
import CharacterEngine
@testable import MagicPaper

/// Kitap karakterinin parça kataloğu ve CharacterEngine köprüsü (B2, plan §6).
final class AvatarKitTests: XCTestCase {

    private var kit: AvatarKit {
        get throws {
            try XCTUnwrap(AvatarKit.load(from: .main),
                          "avatar_kit.json uygulama paketinde yok ya da çözülemiyor")
        }
    }

    // MARK: - Manifest

    func testEveryGroupHasSelectableOptions() throws {
        let kit = try kit
        for group in AvatarKit.Group.allCases {
            XCTAssertFalse(kit.selectableOptions(group).isEmpty, group.rawValue)
        }
    }

    func testOptionIDsAreUniqueAcrossTheKit() throws {
        let ids = try AvatarKit.Group.allCases.flatMap { try kit.options($0).map(\.id) }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testLifecyclesAreKnown() throws {
        let kit = try kit
        for group in AvatarKit.Group.allCases {
            for option in kit.options(group) {
                XCTAssertTrue(ContentLifecycle.all.contains(option.lifecycle), option.id)
            }
        }
        for pose in kit.poses {
            XCTAssertTrue(ContentLifecycle.all.contains(pose.lifecycle), pose.id)
        }
    }

    /// Renkli gruplarda her seçenek bir token adı taşır; hex asla.
    func testColouredGroupsNameATokenNotAHex() throws {
        let kit = try kit
        for group in [AvatarKit.Group.skinTone, .hairColor, .outfit] {
            for option in kit.options(group) {
                let token = try XCTUnwrap(option.colorToken, option.id)
                XCTAssertFalse(token.contains("#") || token.lowercased().hasPrefix("0x"), option.id)
            }
        }
    }

    /// Etiketler biçim adıdır; hiçbir seçenek bir cinsiyete bağlanmaz.
    func testLabelsAreNotGendered() throws {
        let kit = try kit
        let gendered = ["kız", "erkek", "oğlan", "kadın", "bay", "bayan"]
        for group in AvatarKit.Group.allCases {
            for option in kit.options(group) {
                let words = option.label.lowercased().split(separator: " ").map(String.init)
                for word in words {
                    XCTAssertFalse(gendered.contains(word), "\(option.id): \(option.label)")
                }
            }
        }
    }

    func testThePlannedPosesExist() throws {
        let ids = Set(try kit.poses.map(\.id))
        for pose in ["standing", "walking", "reaching", "lookingUp", "pointing", "celebrating", "sitting", "sleeping"] {
            XCTAssertTrue(ids.contains(pose), pose)
        }
    }

    func testLayerOrderIsBackToFront() throws {
        XCTAssertEqual(try kit.layerOrder, ["hairBack", "body", "outfit", "face", "hairFront", "accessory"])
    }

    func testCanvasIsSmallerThanASceneAndFeetAreInside() throws {
        let canvas = try kit.canvas
        XCTAssertEqual(canvas.width, 512)
        XCTAssertEqual(canvas.height, 768)
        XCTAssertTrue((0...1).contains(canvas.footX))
        XCTAssertTrue((0...1).contains(canvas.footY))
    }

    func testDefaultsPointAtRealOptions() throws {
        let kit = try kit
        for (group, id) in kit.defaults {
            let g = try XCTUnwrap(AvatarKit.Group(rawValue: group), group)
            XCTAssertNotNil(kit.option(g, id: id), "\(group): \(id)")
        }
        for group in [AvatarKit.Group.skinTone, .hairStyle, .hairColor, .outfit] {
            XCTAssertNotNil(kit.defaults[group.rawValue], "\(group.rawValue) varsayılanı yok")
        }
    }

    /// Örnekler gerçek parçalara oturur ve çeşitliliği gösterir: ten, saç ve
    /// kıyafet her örnekte farklı.
    func testSamplesAreValidAndDistinct() throws {
        let kit = try kit
        XCTAssertEqual(kit.samples.count, 3)
        for sample in kit.samples {
            XCTAssertEqual(kit.resolved(sample.spec.avatar), sample.spec.avatar,
                           "\(sample.id) kitte olmayan bir parça kullanıyor")
        }
        for keyPath in [\AvatarKit.SampleSpec.skinTone, \.hairColor, \.outfit] {
            let values = kit.samples.map { $0.spec[keyPath: keyPath] }
            XCTAssertEqual(Set(values).count, values.count)
        }
    }

    // MARK: - CharacterEngine köprüsü

    /// Görünüşün anlamı paralel bir modelde değil, CharacterEngine'in kapalı
    /// sözlüğünde: her descriptor değeri kendi dilinin sözlüğünde bulunur.
    func testEveryDescriptorIsInTheLexicon() throws {
        let kit = try kit
        let en = DescriptorLexicon.builtIn(languageCode: "en")
        let tr = DescriptorLexicon.builtIn(languageCode: "tr")
        for group in AvatarKit.Group.allCases {
            for option in kit.options(group) {
                let d = try XCTUnwrap(option.descriptor, "\(option.id): descriptor yok")
                let category = try XCTUnwrap(DescriptorCategory(rawValue: d.category), "\(option.id): \(d.category)")
                XCTAssertTrue(en.phrases[category, default: []].contains(d.en), "\(option.id): en '\(d.en)' sözlükte yok")
                XCTAssertTrue(tr.phrases[category, default: []].contains(d.tr), "\(option.id): tr '\(d.tr)' sözlükte yok")
            }
        }
    }

    func testDescriptorsAreParentProvidedAndCoverEveryChosenPart() throws {
        let kit = try kit
        let spec = AvatarSpec(skinTone: "skin_dark", hairStyle: "hair_curly", hairColor: "haircolor_black",
                              outfit: "outfit_green", accessory: "acc_glasses")
        let en = kit.descriptors(for: spec)
        XCTAssertEqual(en.count, 5)
        XCTAssertTrue(en.allSatisfy { $0.source == .parentProvided })
        XCTAssertEqual(Set(en.map(\.value)),
                       ["dark skin", "curly hair", "black hair", "green t-shirt", "glasses"])
        XCTAssertTrue(en.contains { $0.category == .distinguishingFeature && $0.value == "glasses" },
                      "gözlük sözlükte distinguishingFeature")

        let tr = kit.descriptors(for: spec, language: "tr")
        XCTAssertEqual(Set(tr.map(\.value)),
                       ["koyu ten", "kıvırcık saç", "siyah saç", "yeşil tişört", "gözlük"])
    }

    // MARK: - Çözümleme

    /// Kitten kalkmış bir parça grubun varsayılanına düşer; rastgele bir
    /// parçaya asla. Tanınmayan aksesuar "yok" olur.
    func testUnknownPartsFallBackToTheGroupDefault() throws {
        let kit = try kit
        let spec = AvatarSpec(skinTone: "skin_gone", hairStyle: "hair_gone", hairColor: "haircolor_red",
                              outfit: "outfit_gone", accessory: "acc_gone")
        let r = kit.resolved(spec)
        XCTAssertEqual(r.skinTone, kit.defaults["skinTone"])
        XCTAssertEqual(r.hairStyle, kit.defaults["hairStyle"])
        XCTAssertEqual(r.hairColor, "haircolor_red")
        XCTAssertEqual(r.outfit, kit.defaults["outfit"])
        XCTAssertNil(r.accessory)
        XCTAssertEqual(kit.resolved(spec), r, "çözümleme deterministik olmalı")
    }

    func testAnAvatarWithMissingFieldsStillDecodes() throws {
        let json = #"{"skinTone":"skin_light"}"#.data(using: .utf8)!
        let spec = try JSONDecoder().decode(AvatarSpec.self, from: json)
        XCTAssertEqual(spec.skinTone, "skin_light")
        XCTAssertEqual(spec.outfit, "")
        XCTAssertNil(spec.accessory)
    }
}
