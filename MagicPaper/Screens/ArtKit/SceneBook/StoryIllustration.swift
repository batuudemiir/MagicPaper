import Foundation

/// Görselli bir masalın kitapla birlikte saklanan anlık görüntüsü.
///
/// Masal kaydedildiği an avatarın hâli ve sahne seçimleri buraya **kopyalanır**.
/// Ebeveyn avatarı sonradan değiştirse de eski kitap eski görünüşle açılır —
/// CharacterEngine'deki sürüm pinlemenin aynısı (`MagicPaper_Character_System.md`
/// §4.4, §10.2).
///
/// Çözücü **hiçbir koşulda atmaz.** Masallar `UserDefaults["stories"]`'te tek
/// bir `[Story]` dizisi olarak çözülür; buradaki bir hata bir çocuğun bütün
/// rafını düşürürdü. Bozuk ya da okunamayan bir anlık görüntü `isUsable == false`
/// olur ve kitap metin kitabı olarak açılır.
struct StoryIllustration: Codable, Equatable {
    var schemaVersion: Int
    var avatar: AvatarSpec
    var avatarKitVersion: String
    /// Avatar sanatının sürümü (`AvatarKit.artVersion`).
    var avatarArtVersion: Int
    var sceneLibraryVersion: String
    /// Sahne bulunamayan görsel yuvaları. Geliştirici galerisi ve testler için.
    var gaps: [CoverageGapRecord]

    static let currentSchemaVersion = 1

    init(avatar: AvatarSpec, avatarKitVersion: String, avatarArtVersion: Int,
         sceneLibraryVersion: String, gaps: [CoverageGapRecord] = []) {
        self.schemaVersion = Self.currentSchemaVersion
        self.avatar = avatar
        self.avatarKitVersion = avatarKitVersion
        self.avatarArtVersion = avatarArtVersion
        self.sceneLibraryVersion = sceneLibraryVersion
        self.gaps = gaps
    }

    /// Okunabildi ve bu sürümün anladığı bir şema mı.
    var isUsable: Bool {
        schemaVersion >= 1 && schemaVersion <= Self.currentSchemaVersion && !avatar.skinTone.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, avatar, avatarKitVersion, avatarArtVersion, sceneLibraryVersion, gaps
    }

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = .unreadable
            return
        }
        schemaVersion       = (try? c.decode(Int.self, forKey: .schemaVersion)) ?? 0
        avatar              = (try? c.decode(AvatarSpec.self, forKey: .avatar))
                              ?? Self.unreadable.avatar
        avatarKitVersion    = (try? c.decode(String.self, forKey: .avatarKitVersion)) ?? ""
        avatarArtVersion    = (try? c.decode(Int.self, forKey: .avatarArtVersion)) ?? 1
        sceneLibraryVersion = (try? c.decode(String.self, forKey: .sceneLibraryVersion)) ?? ""
        gaps                = (try? c.decode([CoverageGapRecord].self, forKey: .gaps)) ?? []
    }

    /// Okunamayan anlık görüntünün yerine geçen değer. `isUsable == false`.
    static let unreadable: StoryIllustration = {
        var value = StoryIllustration(
            avatar: AvatarSpec(skinTone: "", hairStyle: "", hairColor: "", outfit: ""),
            avatarKitVersion: "", avatarArtVersion: 1, sceneLibraryVersion: "")
        value.schemaVersion = 0
        return value
    }()
}

/// Bir sayfanın sahnesi — kimlik ve sürüm. Piksel ve anchor değil: onlar
/// çizim anında manifestten, sabitlenen sürümden okunur (plan §4.2).
struct ScenePlate: Codable, Equatable {
    var sceneID: String
    var sceneVersion: Int
    /// `AvatarKit` poz kimliği. Tanınmazsa sahnenin `defaultPose`'u çizilir.
    var pose: String
    /// `left` | `right`.
    var facing: String
    /// Yol arkadaşı sahnede mi. Tanışmadan önceki sayfalarda `nil`.
    var companionID: String?
    /// Yol arkadaşının türü, katalogdaki `type` (`tilki`, `kirpi` …). Seçim
    /// anında kopyalanır: okuyucu içerik kataloğuna bağımlı olmadan doğru
    /// hayvanı çizer.
    var companionKind: String?

    private enum CodingKeys: String, CodingKey {
        case sceneID, sceneVersion, pose, facing, companionID, companionKind
    }

    init(sceneID: String, sceneVersion: Int, pose: String, facing: String,
         companionID: String?, companionKind: String? = nil) {
        self.sceneID = sceneID
        self.sceneVersion = sceneVersion
        self.pose = pose
        self.facing = facing
        self.companionID = companionID
        self.companionKind = companionKind
    }

    /// Atmaz: eksik alan boş kimlik olur, sahne bulunamaz, sayfa metin sayfası
    /// çizilir. Kütüphane çözülmeye devam eder.
    init(from decoder: Decoder) throws {
        let c = try? decoder.container(keyedBy: CodingKeys.self)
        sceneID      = (try? c?.decode(String.self, forKey: .sceneID)) ?? ""
        sceneVersion = (try? c?.decode(Int.self, forKey: .sceneVersion)) ?? 0
        pose         = (try? c?.decode(String.self, forKey: .pose)) ?? ""
        facing       = (try? c?.decode(String.self, forKey: .facing)) ?? "right"
        companionID  = (try? c?.decodeIfPresent(String.self, forKey: .companionID)) ?? nil
        companionKind = (try? c?.decodeIfPresent(String.self, forKey: .companionKind)) ?? nil
    }
}

/// Sahne bulunamayan bir görsel yuvası. Yalnızca kimlikler — çocuğun adı ya da
/// metin asla.
struct CoverageGapRecord: Codable, Equatable, Hashable {
    var pageNumber: Int
    var role: String
    var settingID: String
    var settingTags: [String]
}
