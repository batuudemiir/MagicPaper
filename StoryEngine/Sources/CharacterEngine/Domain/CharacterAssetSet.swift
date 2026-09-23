import Foundation

/// Which reference an image request should lean on.
public enum CharacterAssetRole: String, Codable, Sendable, CaseIterable, Hashable {
    case master
    case fullBody
    case face
    case expression
}

/// Expressions we may eventually keep a dedicated reference for.
public enum CharacterExpression: String, Codable, Sendable, CaseIterable, Hashable {
    case neutral
    case happy
    case surprised
    case sad
    case brave
    case sleepy
}

/// A single stored reference image. The engine only ever handles the locator —
/// bytes stay with whatever storage the host app uses.
public struct CharacterAsset: Codable, Sendable, Hashable {
    public let id: UUID
    public let role: CharacterAssetRole
    /// Remote URL or app-local filename; opaque to the engine.
    public let locator: String
    public let createdAt: Date
    public let checksum: String?

    public init(id: UUID = UUID(), role: CharacterAssetRole, locator: String, createdAt: Date, checksum: String? = nil) {
        self.id = id
        self.role = role
        self.locator = locator
        self.createdAt = createdAt
        self.checksum = checksum
    }
}

/// The reference images that carry a character's visual identity.
///
/// V1 fills `masterReference` only — that is the photo the app already uploads.
/// The other slots exist now so that adding full-body sheets, face crops and
/// expression sheets later is a data change, not a migration. Every consumer
/// must tolerate `nil` in them.
public struct CharacterAssetSet: Codable, Sendable, Hashable {
    public let masterReference: CharacterAsset?
    public let fullBodyReference: CharacterAsset?
    public let faceReference: CharacterAsset?
    public let expressionReferences: [CharacterExpression: CharacterAsset]
    public let identitySeed: UInt64
    public let stylePresetID: String

    public init(
        masterReference: CharacterAsset? = nil,
        fullBodyReference: CharacterAsset? = nil,
        faceReference: CharacterAsset? = nil,
        expressionReferences: [CharacterExpression: CharacterAsset] = [:],
        identitySeed: UInt64,
        stylePresetID: String
    ) {
        self.masterReference = masterReference
        self.fullBodyReference = fullBodyReference
        self.faceReference = faceReference
        self.expressionReferences = expressionReferences
        self.identitySeed = identitySeed
        self.stylePresetID = stylePresetID
    }

    /// The reference slots beyond `masterReference` are already Optional, so
    /// only the expression map needs help: V1 never writes one, and a record
    /// without it must not fail to decode. See `CharacterIdentity.init(from:)`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        masterReference = try container.decodeIfPresent(CharacterAsset.self, forKey: .masterReference)
        fullBodyReference = try container.decodeIfPresent(CharacterAsset.self, forKey: .fullBodyReference)
        faceReference = try container.decodeIfPresent(CharacterAsset.self, forKey: .faceReference)
        expressionReferences = try container.decodeIfPresent(
            [CharacterExpression: CharacterAsset].self,
            forKey: .expressionReferences
        ) ?? [:]
        identitySeed = try container.decode(UInt64.self, forKey: .identitySeed)
        stylePresetID = try container.decode(String.self, forKey: .stylePresetID)
    }

    /// V1 bar: a master reference is enough to illustrate a book.
    public var isUsable: Bool { masterReference != nil }

    /// Every slot filled. Nothing requires this yet.
    public var isComplete: Bool {
        masterReference != nil && fullBodyReference != nil && faceReference != nil && !expressionReferences.isEmpty
    }

    /// Best available reference for a requested role, degrading toward the
    /// master rather than returning nothing.
    public func reference(preferring role: CharacterAssetRole, expression: CharacterExpression? = nil) -> CharacterAsset? {
        switch role {
        case .master:
            return masterReference
        case .fullBody:
            return fullBodyReference ?? masterReference
        case .face:
            return faceReference ?? masterReference
        case .expression:
            if let expression, let asset = expressionReferences[expression] { return asset }
            return faceReference ?? masterReference
        }
    }

    /// References an image request should attach, most specific first, de-duplicated.
    public func referenceChain(preferring role: CharacterAssetRole, expression: CharacterExpression? = nil) -> [CharacterAsset] {
        var chain: [CharacterAsset] = []
        if let primary = reference(preferring: role, expression: expression) { chain.append(primary) }
        if let master = masterReference, !chain.contains(where: { $0.id == master.id }) { chain.append(master) }
        return chain
    }
}
