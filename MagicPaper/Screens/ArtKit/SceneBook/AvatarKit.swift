import Foundation
import CharacterEngine

/// Kitap karakterinin parça kataloğu.
///
/// İçerik `avatar_kit.json`'da durur, kodda değil: yeni bir saç biçimi, ten ya
/// da poz eklemek Swift değişikliği gerektirmez. `StoryArtKit` ile aynı desen:
/// manifest + `Assets.xcassets/Avatar/` ad alanı + varlık yoksa yer tutucu.
///
/// Etiketler biçim adıdır, cinsiyetsizdir ("Kıvırcık", "At kuyruğu"); hiçbir
/// seçenek bir cinsiyete bağlanmaz.
struct AvatarKit: Decodable, Equatable {
    let schemaVersion: Int
    let version: String
    /// Avatar sanatının sürümü. Masala kopyalanır (`StoryIllustration`), böylece
    /// avatar çizimleri yenilendiğinde eski kitap hangi sanatla çizildiğini bilir.
    let artVersion: Int
    let canvas: Canvas
    /// Arkadan öne çizim sırası. Her poz aynı sırayı kullanır.
    let layerOrder: [String]
    let poses: [Pose]
    /// Grup adı → seçenekler. Sözlük olarak çözülür ki tanınmayan bir grup
    /// kataloğu düşürmesin.
    let groups: [String: [Option]]
    /// Grubun varsayılan parçası: kitten kalkmış bir parça buna düşer.
    /// Ebeveyn adına seçim değildir — görselli kitap açık bir Kaydet ister.
    let defaults: [String: String]
    /// Geliştirici menüsündeki "Örnek avatar oluştur" için hazır kombinasyonlar.
    let samples: [Sample]

    /// Parça grupları. Kalıcı değil (JSON anahtarı olarak okunur), bu yüzden
    /// enum olabilir.
    enum Group: String, CaseIterable, Sendable {
        case skinTone, hairStyle, hairColor, outfit, accessory
    }

    struct Canvas: Decodable, Equatable {
        /// Avatar tuvali, piksel. Sahneden bağımsız ve küçük (512 × 768).
        let width: Int
        let height: Int
        /// Ayak noktası, tuval kesri (sol üstten).
        let footX: Double
        let footY: Double
    }

    struct Pose: Decodable, Equatable, Identifiable {
        let id: String
        let label: String
        let lifecycle: String
    }

    struct Option: Decodable, Equatable, Identifiable {
        let id: String
        /// Ebeveyne gösterilen Türkçe ad.
        let label: String
        /// Renk, `MP.C.avatarParts`'taki token adıyla. Hex yazılmaz.
        let colorToken: String?
        /// Kıyafetin biçimi (`tshirt`). Varlık adı rengi değil biçimi taşır:
        /// altı renk tek bir maske çizimini boyar. Yalnızca `outfit` grubunda.
        let shape: String?
        /// Görünüşün CharacterEngine karşılığı. Yoksa parça yalnızca görseldir.
        let descriptor: Descriptor?
        let lifecycle: String
        let placeholder: Bool
    }

    /// Bir parçanın anlamı, iki dilde.
    ///
    /// `en` görsel prompt'a olduğu gibi girer (`PromptConstraintCompiler`,
    /// B1); `tr` metin kapısının sözlüğüyle karşılaştırılır. İkisi de kendi
    /// sözlüğünde bulunmak zorunda — `AvatarKitTests` bunu doğrular.
    struct Descriptor: Decodable, Equatable {
        let category: String
        let en: String
        let tr: String
    }

    struct Sample: Decodable, Equatable, Identifiable {
        let id: String
        let label: String
        let spec: SampleSpec
    }

    struct SampleSpec: Decodable, Equatable {
        let skinTone: String
        let hairStyle: String
        let hairColor: String
        let outfit: String
        let accessory: String?

        var avatar: AvatarSpec {
            AvatarSpec(skinTone: skinTone, hairStyle: hairStyle,
                       hairColor: hairColor, outfit: outfit, accessory: accessory)
        }
    }

    // MARK: - Sorgular

    func options(_ group: Group) -> [Option] { groups[group.rawValue] ?? [] }

    /// Ebeveyne sunulabilecek seçenekler: yalnızca onaylı olanlar.
    func selectableOptions(_ group: Group) -> [Option] {
        options(group).filter { $0.lifecycle == ContentLifecycle.approved }
    }

    func option(_ group: Group, id: String?) -> Option? {
        guard let id else { return nil }
        return options(group).first { $0.id == id }
    }

    func pose(_ id: String) -> Pose? { poses.first { $0.id == id } }

    /// Kit'in bugün tanıdığı parçalara oturtulmuş avatar.
    ///
    /// Kaldırılmış ya da tanınmayan bir parça o grubun varsayılanına düşer;
    /// rastgele bir parçaya asla. Aksesuar opsiyonel olduğu için tanınmayan
    /// aksesuar "yok" olur — eklemek, uydurmaktır.
    func resolved(_ spec: AvatarSpec) -> AvatarSpec {
        func pick(_ group: Group, _ id: String) -> String {
            if option(group, id: id) != nil { return id }
            return defaults[group.rawValue] ?? options(group).first?.id ?? id
        }
        var out = spec
        out.skinTone  = pick(.skinTone, spec.skinTone)
        out.hairStyle = pick(.hairStyle, spec.hairStyle)
        out.hairColor = pick(.hairColor, spec.hairColor)
        out.outfit    = pick(.outfit, spec.outfit)
        out.accessory = option(.accessory, id: spec.accessory) == nil ? nil : spec.accessory
        return out
    }

    /// Kurulum ekranının başlangıç önizlemesi. Kaydedilmeden hiçbir kitapta
    /// kullanılmaz (plan §8.1).
    var previewDefault: AvatarSpec {
        AvatarSpec(skinTone: defaults[Group.skinTone.rawValue] ?? "",
                   hairStyle: defaults[Group.hairStyle.rawValue] ?? "",
                   hairColor: defaults[Group.hairColor.rawValue] ?? "",
                   outfit: defaults[Group.outfit.rawValue] ?? "",
                   accessory: nil)
    }

    // MARK: - CharacterEngine köprüsü

    /// Avatarın görünüşü, CharacterEngine'in kapalı sözlüğünde.
    ///
    /// B1'in köprüsü: `ProfileCharacterSource.makeProfile(parentProvidedDescriptors:)`
    /// bu listeyi alacak. Bu tur bağlanmaz. Kaynak her zaman `.parentProvided`:
    /// ebeveyn seçti, hiçbir şey yüzden çıkarılmadı.
    ///
    /// - Parameter language: `"en"` prompt dili (varsayılan), `"tr"` metin kapısı.
    func descriptors(for spec: AvatarSpec, language: String = "en") -> [CharacterDescriptor] {
        let r = resolved(spec)
        return Group.allCases.compactMap { group -> CharacterDescriptor? in
            guard let d = option(group, id: r.part(in: group))?.descriptor,
                  let category = DescriptorCategory(rawValue: d.category) else { return nil }
            return CharacterDescriptor(category: category,
                                       value: language == "tr" ? d.tr : d.en,
                                       source: .parentProvided)
        }
    }
}

/// İçerik varlıklarının yaşam döngüsü (plan §9.1). Avatar ve sahne aynı
/// sözlüğü kullanır. `String` sabitleri: manifestte bilinmeyen bir değer
/// kataloğu düşürmez, yalnızca seçilemez olur.
enum ContentLifecycle {
    static let draft = "draft"
    static let review = "review"
    static let approved = "approved"
    static let deprecated = "deprecated"
    static let retired = "retired"

    static let all: Set<String> = [draft, review, approved, deprecated, retired]
}

// MARK: - Katalog

extension AvatarKit {
    /// Uygulamanın gömülü kiti. Okunamazsa `nil`: görselli kitap kurulmaz,
    /// masal metin olarak çıkar — sessizce başka bir kite düşülmez.
    static let bundled: AvatarKit? = load(from: .main)

    static func load(from bundle: Bundle) -> AvatarKit? {
        guard let url = bundle.url(forResource: "avatar_kit", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AvatarKit.self, from: data)
    }
}

extension AvatarSpec {
    /// `AvatarKit.descriptors(for:)` kısayolu. Kit yoksa boş.
    func descriptors(in kit: AvatarKit? = .bundled, language: String = "en") -> [CharacterDescriptor] {
        kit?.descriptors(for: self, language: language) ?? []
    }
}
