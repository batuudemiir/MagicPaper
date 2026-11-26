import Foundation
import EngineFoundation

/// Identity of complete source bytes and the engine behavior that interprets them.
/// SHA-256 is computed by the host; engine fingerprints are not source digests.
public struct ContentSourceReference: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1
    public static let legacyEngineBehaviorID = "offline-legacy-v1"
    public let schemaVersion: Int
    public let catalogVersion: String
    public let packageSchemaVersion: Int
    public let payloadSHA256: String
    public let engineBehaviorID: String

    public enum ValidationError: Error { case malformed }

    public var isSupported: Bool {
        schemaVersion == Self.currentSchemaVersion
            && packageSchemaVersion == ContentPackage.currentSchemaVersion
            && engineBehaviorID == Self.legacyEngineBehaviorID
    }

    public init(schemaVersion: Int = 1, catalogVersion: String, packageSchemaVersion: Int = 2,
                payloadSHA256: String, engineBehaviorID: String = "offline-legacy-v1") throws {
        guard schemaVersion > 0, packageSchemaVersion > 0, SemanticVersion(catalogVersion) != nil,
              payloadSHA256.utf8.count == 64,
              payloadSHA256.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              !engineBehaviorID.isEmpty else { throw ValidationError.malformed }
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.packageSchemaVersion = packageSchemaVersion
        self.payloadSHA256 = payloadSHA256
        self.engineBehaviorID = engineBehaviorID
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, catalogVersion, packageSchemaVersion, payloadSHA256, engineBehaviorID
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(schemaVersion: values.decode(Int.self, forKey: .schemaVersion),
                      catalogVersion: values.decode(String.self, forKey: .catalogVersion),
                      packageSchemaVersion: values.decode(Int.self, forKey: .packageSchemaVersion),
                      payloadSHA256: values.decode(String.self, forKey: .payloadSHA256),
                      engineBehaviorID: values.decode(String.self, forKey: .engineBehaviorID))
    }
}
