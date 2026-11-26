import Foundation

/// Lossless JSON envelope: unsupported or malformed source metadata survives sync
/// and persistence without making an otherwise readable saved book disappear.
public struct ContentSourceMetadata: Codable, Hashable, Sendable {
    public enum Status: Hashable, Sendable { case known, unsupported, malformed }
    private let raw: JSONValue

    public init(known reference: ContentSourceReference) {
        raw = .object([
            "schemaVersion": .number(Decimal(reference.schemaVersion)),
            "catalogVersion": .string(reference.catalogVersion),
            "packageSchemaVersion": .number(Decimal(reference.packageSchemaVersion)),
            "payloadSHA256": .string(reference.payloadSHA256),
            "engineBehaviorID": .string(reference.engineBehaviorID)
        ])
    }

    public init(p56 reference: P56SourceReference) {
        raw = .object([
            "schemaVersion": .number(Decimal(reference.schemaVersion)),
            "packageVersion": .string(reference.packageVersion),
            "payloadSHA256": .string(reference.payloadSHA256),
            "engineBehaviorID": .string(reference.engineBehaviorID)
        ])
    }

    public var p56Reference: P56SourceReference? {
        guard case .object(let fields) = raw,
              case .number(1)? = fields["schemaVersion"],
              case .string(let version)? = fields["packageVersion"],
              ["five-friends-56-runtime-v1", "five-friends-56-runtime-v2"].contains(version),
              case .string(P56Engine.behaviorID)? = fields["engineBehaviorID"],
              case .string(let digest)? = fields["payloadSHA256"], Self.isDigest(digest) else { return nil }
        return P56SourceReference(packageVersion: version, payloadSHA256: digest)
    }

    private static func isDigest(_ value: String) -> Bool {
        value.utf8.count == 64 && value.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }

    private var p56Status: Status? {
        guard case .object(let fields) = raw else { return nil }
        let behavior: String
        if case .string(let value)? = fields["engineBehaviorID"] { behavior = value } else { behavior = "" }
        let isP56Behavior = behavior.hasPrefix("offline-p56-")
        let isP56Package: Bool
        if case .string(let value)? = fields["packageVersion"] {
            isP56Package = value.hasPrefix("five-friends-56-runtime-")
                && fields["catalogVersion"] == nil && fields["packageSchemaVersion"] == nil
        } else { isP56Package = false }
        guard isP56Behavior || isP56Package else { return nil }
        if isP56Behavior && behavior != P56Engine.behaviorID { return .unsupported }
        guard case .number(1)? = fields["schemaVersion"],
              case .string(let package)? = fields["packageVersion"], !package.isEmpty,
              case .string(let digest)? = fields["payloadSHA256"], Self.isDigest(digest),
              case .string(P56Engine.behaviorID)? = fields["engineBehaviorID"] else { return .malformed }
        return .unsupported
    }

    public init(_ reference: ContentSourceReference) { self.init(known: reference) }

    private var decodedReference: ContentSourceReference? {
        guard let data = try? JSONEncoder().encode(raw) else { return nil }
        return try? JSONDecoder().decode(ContentSourceReference.self, from: data)
    }

    public var status: Status {
        if case .object(let fields) = raw, case .number(let schema)? = fields["schemaVersion"],
           schema != Decimal(ContentSourceReference.currentSchemaVersion) {
            return .unsupported
        }
        if let status = p56Status { return status }
        guard let reference = decodedReference else { return .malformed }
        return reference.isSupported ? .known : .unsupported
    }

    public var reference: ContentSourceReference? {
        guard let reference = decodedReference, reference.isSupported else { return nil }
        return reference
    }

    public init(from decoder: Decoder) throws { raw = try JSONValue(from: decoder) }
    public func encode(to encoder: Encoder) throws { try raw.encode(to: encoder) }
}

private indirect enum JSONValue: Codable, Hashable, Sendable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Decimal), bool(Bool), null

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let item = try? value.decode(Bool.self) { self = .bool(item) }
        else if let item = try? value.decode(String.self) { self = .string(item) }
        else if let item = try? value.decode(Decimal.self) { self = .number(item) }
        else if let item = try? value.decode([String: JSONValue].self) { self = .object(item) }
        else { self = .array(try value.decode([JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .object(let item): try value.encode(item)
        case .array(let item): try value.encode(item)
        case .string(let item): try value.encode(item)
        case .number(let item): try value.encode(item)
        case .bool(let item): try value.encode(item)
        case .null: try value.encodeNil()
        }
    }
}
