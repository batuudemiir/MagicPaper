import Foundation

/// Stable identifier for a character across every story they appear in.
public struct CharacterID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID) { self.rawValue = rawValue }
    public init() { self.rawValue = UUID() }
    public var description: String { rawValue.uuidString }

    public init(from decoder: Decoder) throws {
        self.rawValue = try decoder.singleValueContainer().decode(UUID.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Identifier for one immutable snapshot of a character's identity.
///
/// Stories pin this, not `CharacterID`: a child's character can be re-derived
/// from a newer photo without retroactively changing books already generated.
public struct CharacterVersionID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID) { self.rawValue = rawValue }
    public init() { self.rawValue = UUID() }
    public var description: String { rawValue.uuidString }

    public init(from decoder: Decoder) throws {
        self.rawValue = try decoder.singleValueContainer().decode(UUID.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
