import Foundation

/// Versioning shared by character snapshots, visual presets and story templates.
///
/// Ordinary semver ordering, with the compatibility rule the resolvers rely on:
/// same major means a document can stand in for another.
public struct SemanticVersion: Codable, Sendable, Hashable, Comparable, CustomStringConvertible, LosslessStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init?(_ description: String) {
        let parts = description.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard (1...3).contains(parts.count) else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard let value = Int(part), value >= 0 else { return nil }
            numbers.append(value)
        }
        self.major = numbers[0]
        self.minor = numbers.count > 1 ? numbers[1] : 0
        self.patch = numbers.count > 2 ? numbers[2] : 0
    }

    public var description: String { "\(major).\(minor).\(patch)" }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }

    /// `other` can stand in for `self` when the major matches and it is at
    /// least as new.
    public func isCompatible(with other: SemanticVersion) -> Bool {
        major == other.major && other >= self
    }

    // Stored as "1.2.0" so hand-written JSON stays readable.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let parsed = SemanticVersion(raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "'\(raw)' is not a semantic version")
            )
        }
        self = parsed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// How a caller asks for a version of a versioned document.
public enum VersionRequirement: Codable, Sendable, Hashable {
    /// Newest available, whatever the major.
    case latest
    /// Exactly this version, or an error.
    case exact(SemanticVersion)
    /// Newest version sharing this major and at least this new.
    case compatible(SemanticVersion)

    public func isSatisfied(by version: SemanticVersion) -> Bool {
        switch self {
        case .latest: return true
        case .exact(let pinned): return version == pinned
        case .compatible(let floor): return floor.isCompatible(with: version)
        }
    }

    // Hand-written as "latest", {"exact":"1.2.0"} or {"compatible":"1.2.0"}.
    // The synthesized form ({"exact":{"_0":"1.2.0"}}) is not something anyone
    // should have to type into a template file.
    private enum CodingKeys: String, CodingKey { case exact, compatible }

    public init(from decoder: Decoder) throws {
        if let raw = try? decoder.singleValueContainer().decode(String.self) {
            guard raw == "latest" else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Unknown version requirement '\(raw)'")
                )
            }
            self = .latest
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let version = try container.decodeIfPresent(SemanticVersion.self, forKey: .exact) {
            self = .exact(version)
        } else if let version = try container.decodeIfPresent(SemanticVersion.self, forKey: .compatible) {
            self = .compatible(version)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Version requirement needs 'exact' or 'compatible'")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .latest:
            var container = encoder.singleValueContainer()
            try container.encode("latest")
        case .exact(let version):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(version, forKey: .exact)
        case .compatible(let version):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(version, forKey: .compatible)
        }
    }
}
