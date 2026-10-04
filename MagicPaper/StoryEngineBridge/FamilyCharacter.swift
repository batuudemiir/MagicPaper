import Foundation
import StoryEngine

/// Masal ailem ilişki türü (FAZ 11). Cinsiyet yok, olmayacak (karar: 3 Ekim 2026).
///
/// Hayvan türü sabit listeden gelir (`familyAnimalKinds`, katalogda): serbest
/// metin yok, çünkü türün ek çekimi önceden doğrulanmış olmalı.
enum FamilyRelation: Hashable, Sendable {
    case sibling
    case friend
    case animal(kindID: String)
    case imaginary

    /// Kayıtta ve motorda kullanılan ad. Hiçbir zaman karakterin adı değil.
    var kind: FamilyRelationKind {
        switch self {
        case .sibling: return .sibling
        case .friend: return .friend
        case .animal: return .animal
        case .imaginary: return .imaginary
        }
    }

    var animalKindID: String? {
        if case .animal(let kindID) = self { return kindID }
        return nil
    }
}

/// Çocuğun tekrar eden karakteri: kardeşi, arkadaşı, evcil hayvanı, hayali arkadaşı.
///
/// Ad ebeveynin yazdığıdır ve yalnızca masal metnine girer. `description`,
/// `debugDescription` ve `Mirror` adı göstermez: yanlışlıkla
/// `logger.debug("\(character)")` yazılsa bile log'a ad düşmez.
///
/// Masala kopyalanan şey adın o günkü hâlidir; karakter sonradan yeniden
/// adlandırılır ya da silinirse kayıtlı masallar değişmez.
struct FamilyCharacter: Identifiable, Equatable, Sendable {
    let id: UUID
    let childID: UUID
    var name: String
    var relation: FamilyRelation
    let createdAt: Date
    var schemaVersion: Int

    static let maxPerChild = 8
    static let currentSchemaVersion = 1

    init(
        id: UUID = UUID(),
        childID: UUID,
        name: String,
        relation: FamilyRelation,
        createdAt: Date = Date(),
        schemaVersion: Int = FamilyCharacter.currentSchemaVersion
    ) {
        self.id = id
        self.childID = childID
        self.name = name
        self.relation = relation
        // Whole seconds: the store writes ISO 8601 without fractions, and a
        // character that reads back different from the one just saved would
        // make "is this the same character?" depend on whether it was reloaded.
        self.createdAt = Date(timeIntervalSince1970: createdAt.timeIntervalSince1970.rounded(.down))
        self.schemaVersion = schemaVersion
    }
}

extension FamilyCharacter: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, childID, name, relation, animalKind, createdAt, schemaVersion
    }

    /// Bilinmeyen ilişki türü: daha yeni bir sürümün yazdığı kayıt. Depo bu
    /// kaydı atlar, dosyanın geri kalanını okur.
    struct UnknownRelation: Error {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        childID = try container.decode(UUID.self, forKey: .childID)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        let raw = try container.decode(String.self, forKey: .relation)
        switch FamilyRelationKind(rawValue: raw) {
        case .sibling: relation = .sibling
        case .friend: relation = .friend
        case .imaginary: relation = .imaginary
        case .animal:
            guard let kind = try container.decodeIfPresent(String.self, forKey: .animalKind) else {
                throw UnknownRelation()
            }
            relation = .animal(kindID: kind)
        case nil:
            throw UnknownRelation()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(childID, forKey: .childID)
        try container.encode(name, forKey: .name)
        try container.encode(relation.kind.rawValue, forKey: .relation)
        try container.encodeIfPresent(relation.animalKindID, forKey: .animalKind)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(schemaVersion, forKey: .schemaVersion)
    }
}

extension FamilyCharacter: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    var description: String { "FamilyCharacter(\(relation.kind.rawValue))" }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["id": id, "relation": relation.kind.rawValue])
    }
}
