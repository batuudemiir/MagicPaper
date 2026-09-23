import Foundation

/// Everything the Story Engine is permitted to know about who a character is.
///
/// Immutable. Produced by the Character Engine, pinned into a story by version,
/// and never widened by anything downstream.
public struct CharacterIdentity: Codable, Sendable, Hashable {
    public let ageYears: Int
    public let pronouns: Pronouns
    public let descriptors: [CharacterDescriptor]
    public let identitySeed: UInt64
    /// Safety exclusions that must never appear in text or illustration.
    public let doNotDepict: [String]

    public init(ageYears: Int, pronouns: Pronouns, descriptors: [CharacterDescriptor], identitySeed: UInt64, doNotDepict: [String] = []) {
        self.ageYears = ageYears
        self.pronouns = pronouns
        self.descriptors = descriptors
        self.identitySeed = identitySeed
        self.doNotDepict = doNotDepict
    }

    /// Tolerates a record written before a list existed.
    ///
    /// The synthesized decoder demands every key, and `FileBackedStore` turns a
    /// decode failure into `nil` — which downstream reads as "no character
    /// yet", not as an error. Re-minting an identity is the one failure mode
    /// this package exists to prevent, so an absent list decodes as empty.
    ///
    /// `identitySeed` is deliberately excluded: it is what makes the same child
    /// render the same way twice, and there is no honest default for it.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ageYears = try container.decode(Int.self, forKey: .ageYears)
        pronouns = try container.decode(Pronouns.self, forKey: .pronouns)
        descriptors = try container.decodeIfPresent([CharacterDescriptor].self, forKey: .descriptors) ?? []
        identitySeed = try container.decode(UInt64.self, forKey: .identitySeed)
        doNotDepict = try container.decodeIfPresent([String].self, forKey: .doNotDepict) ?? []
    }

    public func descriptors(in category: DescriptorCategory) -> [CharacterDescriptor] {
        descriptors.filter { $0.category == category }
    }

    /// The exact phrases this identity authorizes, per category. Anything a
    /// generation step says about appearance has to be in here.
    public var authorizedPhrases: [DescriptorCategory: Set<String>] {
        var result: [DescriptorCategory: Set<String>] = [:]
        for descriptor in descriptors {
            result[descriptor.category, default: []].insert(descriptor.normalizedValue)
        }
        return result
    }
}
