import Foundation

/// Additive authored reading semantics. Unknown data remains readable and inert.
struct StoryPageReading: Codable, Equatable {
    let schemaVersion: Int
    let role: String
    let refrain: String?

    init(role: String, refrain: String? = nil, schemaVersion: Int = 1) {
        self.schemaVersion = schemaVersion
        self.role = role
        self.refrain = refrain
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, role, refrain }

    init(from decoder: Decoder) throws {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = values?.contains(.schemaVersion) == true
            ? ((try? values?.decode(Int.self, forKey: .schemaVersion)) ?? 0) : 1
        role = (try? values?.decode(String.self, forKey: .role)) ?? ""
        refrain = try? values?.decode(String.self, forKey: .refrain)
    }
}
