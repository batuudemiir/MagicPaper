import Foundation

/// Ebeveynin kitap karakteri için seçtiği parçalar.
///
/// Bir karakter modeli değil, bir **seçim**: yalnızca `avatar_kit.json`'daki
/// parça kimlikleri. Görünüşün anlamı CharacterEngine'in kapalı sözlüğündedir
/// ve `AvatarKit.descriptors(for:)` ile oraya eşlenir. Paralel bir kimlik
/// tanımı kurulmaz (İlke 5).
///
/// Alanlar bilerek `String`. Bu değer masalın içine kopyalanır
/// (`StoryIllustration.avatar`) ve masallar tek bir `[Story]` dizisi olarak
/// çözülür; tanınmayan bir enum değeri bütün kütüphaneyi düşürebilirdi.
/// Tanınmayan bir parça kimliği ise yalnızca o grubun varsayılanına düşer
/// (`AvatarKit.resolved(_:)`).
///
/// Çocuğun adı burada yok. Bu değer log'a, `print`'e girmez.
struct AvatarSpec: Codable, Equatable, Sendable {
    /// Bu şemanın sürümü. Alan eklendikçe artar; çözücü eski sürümleri okur.
    var schemaVersion: Int
    var skinTone: String
    var hairStyle: String
    var hairColor: String
    /// Kıyafet kimliği, renk değil: bugün `outfit_blue`, yarın
    /// `outfit_yellow_raincoat`. Şema değişmeden yeni biçimler girebilsin diye.
    var outfit: String
    /// `nil` = aksesuar yok.
    var accessory: String?

    static let currentSchemaVersion = 1

    init(skinTone: String, hairStyle: String, hairColor: String,
         outfit: String, accessory: String? = nil) {
        self.schemaVersion = Self.currentSchemaVersion
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.outfit = outfit
        self.accessory = accessory
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, skinTone, hairStyle, hairColor, outfit, accessory
    }

    /// Hiçbir alan eksikliğinde atmaz: eksik parça boş kimlik olur ve
    /// `AvatarKit.resolved` onu grubun varsayılanına çevirir. Kayıtlı bir
    /// masalın anlık görüntüsü, kit değişse de okunabilir kalmalı.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = (try? c.decode(Int.self, forKey: .schemaVersion)) ?? Self.currentSchemaVersion
        skinTone  = (try? c.decode(String.self, forKey: .skinTone))  ?? ""
        hairStyle = (try? c.decode(String.self, forKey: .hairStyle)) ?? ""
        hairColor = (try? c.decode(String.self, forKey: .hairColor)) ?? ""
        outfit    = (try? c.decode(String.self, forKey: .outfit))    ?? ""
        accessory = try? c.decodeIfPresent(String.self, forKey: .accessory)
    }

    /// Grup adı → seçilen parça. Kit ve testler grupları adla gezer.
    func part(in group: AvatarKit.Group) -> String? {
        switch group {
        case .skinTone:  return skinTone
        case .hairStyle: return hairStyle
        case .hairColor: return hairColor
        case .outfit:    return outfit
        case .accessory: return accessory
        }
    }
}
