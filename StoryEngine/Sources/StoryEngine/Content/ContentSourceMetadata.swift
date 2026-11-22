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
