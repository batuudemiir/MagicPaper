import Foundation

// MARK: - Masal ailem

/// What a Masal ailem character is to the child.
///
/// A closed set on purpose: the relation decides which lines may carry the
/// character, and a line written for a little sister does not read right for a
/// cat. There is no gender here and never will be (karar: 3 Ekim 2026) — the
/// lines are written so they do not need one.
public enum FamilyRelationKind: String, Codable, Sendable, Hashable, CaseIterable {
    case sibling
    case friend
    case animal
    case imaginary
}

/// An animal kind a Masal ailem pet can be, as content declares it.
///
/// A fixed list rather than free text (karar: 4 Ekim 2026), so every kind has
/// grammar someone has checked: "köpek" softens to "köpeğe", and its owned form
/// "köpeği" is written here instead of being guessed.
public struct CatalogFamilyAnimalKind: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// The kind as a common noun — "kedi", "köpek".
    public let name: String
    /// Third-person possessive — "kedisi", "köpeği". Templates write
    /// `{{child.name}}'in {{family.possessive}}`; the stem already ends in a
    /// possessive, so a case on it takes the buffer -n- ("kedisini").
    public let possessive: String
    /// Regular softening does not apply ("kuş" is one syllable anyway; a
    /// loanword like "hamster" keeps its consonant).
    public let blocksSoftening: Bool

    public init(id: ContentID, name: String, possessive: String, blocksSoftening: Bool = false) {
        self.id = id
        self.name = name
        self.possessive = possessive
        self.blocksSoftening = blocksSoftening
    }

    private enum CodingKeys: String, CodingKey { case id, name, possessive, blocksSoftening }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        possessive = try container.decode(String.self, forKey: .possessive)
        blocksSoftening = try container.decodeIfPresent(Bool.self, forKey: .blocksSoftening) ?? false
    }
}

/// The child's own recurring character, as one story receives it.
///
/// The name is the parent's words. It goes into the story text and nowhere
/// else: not into an error, not into a log, not into `description`. Every
/// diagnostic this engine produces names the relation instead.
public struct FamilyCast: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public let name: String
    public let relation: FamilyRelationKind
    /// Required for `.animal`, ignored otherwise.
    public let animalKind: CatalogFamilyAnimalKind?

    public init(name: String, relation: FamilyRelationKind, animalKind: CatalogFamilyAnimalKind? = nil) {
        self.name = name
        self.relation = relation
        self.animalKind = relation == .animal ? animalKind : nil
    }

    public var description: String { "FamilyCast(\(relation.rawValue))" }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["relation": relation, "animalKind": animalKind?.id as Any])
    }
}
