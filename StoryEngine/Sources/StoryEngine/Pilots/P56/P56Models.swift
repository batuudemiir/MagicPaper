import Foundation

public enum P56Error: Error, Equatable, Sendable {
    case unsupported(String)
    case unsupportedContexts([String])
    case integrity(String)
    case invalidStructure(String)
    case ageBudget(page: Int)
}

public enum P56Mode: String, Codable, CaseIterable, Sendable { case bedtime, learning, adventure }

public struct P56SourceReference: Codable, Hashable, Sendable {
    public let schemaVersion: Int
    public let packageVersion: String
    public let payloadSHA256: String
    public let engineBehaviorID: String
    public init(schemaVersion: Int = 1, packageVersion: String = "five-friends-56-runtime-v1",
                payloadSHA256: String, engineBehaviorID: String = "offline-p56-v1") {
        self.schemaVersion = schemaVersion
        self.packageVersion = packageVersion
        self.payloadSHA256 = payloadSHA256
        self.engineBehaviorID = engineBehaviorID
    }
}

/// Lossless semantic and art handoff values. The runtime does not reinterpret memories as present props.
public enum P56JSONValue: Codable, Hashable, Sendable {
    case object([String: P56JSONValue]), array([P56JSONValue]), string(String), number(Double), bool(Bool), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode([String: P56JSONValue].self) { self = .object(v) }
        else { self = .array(try c.decode([P56JSONValue].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    public subscript(key: String) -> P56JSONValue? {
        guard case .object(let values) = self else { return nil }; return values[key]
    }
    public var stringValue: String? { if case .string(let v) = self { return v }; return nil }
    public var arrayValue: [P56JSONValue]? { if case .array(let v) = self { return v }; return nil }
}

public struct P56RuntimeManifest: Codable, Sendable {
    public let schemaVersion: Int
    public let packageVersion: String
    public let engineBehaviorID: String
    public let payloadSHA256: String
    public let productionEnabled: Bool
    public let artApproved: Bool
}

public struct P56CompanionProfile: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let personality: String
    public let anatomy: String
    public let legacyRecordMutated: Bool
}

public struct P56Structure: Codable, Hashable, Sendable {
    public let blueprintID: String
    public let planLabel: String
    public let mode: P56Mode
    public let mechanismKey: String
    public let allowedCompanionIDs: [String]
    public let pageMoves: [P56Beat]
}

public enum P56EvidenceKind: String, Codable, Hashable, Sendable { case sourceStatement, observedAbsence }

public struct P56CausalEvidence: Codable, Hashable, Sendable {
    public let bookID: String
    public let pageNumber: Int
    public let actorID: String
    public let quote: String
    public let quoteSHA256: String
    public let attributionQuote: String
    public let attributionSourceID: String
    public let parentSourceID: String
    public let kind: P56EvidenceKind
}

public struct P56TemplatePage: Codable, Hashable, Sendable {
    public let number: Int
    public let beat: P56Beat
    public let actorIDs: [String]
    public let causalEvidence: P56CausalEvidence
    public let templateID: String
    public let templateText: String
    public let templateSHA256: String
    public let parentSourceID: String
    public let parentSHA256: String
    public let parentText: String
    public let parentPointer: String
    public let parentSourceIndex: Int
    public let semantics: P56JSONValue
    public let artHandoff: P56JSONValue
    public let intensity: Int
    public let settingID: String
}

public struct P56Book: Codable, Hashable, Sendable {
    public let id: String
    public let titleTemplate: String
    public let structureID: String
    public let mechanism: String
    public let mode: P56Mode
    public let companionID: String
    public let worldID: String
    public let discoveryID: String
    public let authoredBookSHA256: String
    public let authoredBookJSON: String
    public let pages: [P56TemplatePage]
}

public struct P56Package: Sendable {
    public let sourceReference: P56SourceReference
    public let books: [P56Book]
    public let structures: [P56Structure]
    public let companions: [P56CompanionProfile]
    public let settings: P56JSONValue
    public let worldID: String
}

struct P56Payload: Decodable {
    let schemaVersion: Int
    let packageVersion: String
    let engineBehaviorID: String
    let productionEnabled: Bool
    let artApproved: Bool
    let companions: [P56CompanionProfile]
    let settings: P56JSONValue
    let structures: [P56Structure]
    let books: [P56Book]
    let worldID: String
    let causalEvidenceJSON: String
    let causalEvidenceSHA256: String
    let authoredSourcesJSON: String
    let authoredSourcePayloadSHA256: String
}
