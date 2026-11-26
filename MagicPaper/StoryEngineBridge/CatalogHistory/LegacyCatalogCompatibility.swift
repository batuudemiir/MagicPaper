import StoryEngine

/// Only independently verified historical mappings belong here. Catalog semver,
/// seed and a recomposed fingerprint do not establish historical source identity.
/// The initial release has no verified historical mappings: legacy stays missing.
struct LegacyCatalogCompatibility {
    static let empty = LegacyCatalogCompatibility(verifiedMappings: [:])
    let verifiedMappings: [String: [ContentSourceReference]]

    func candidates(catalogVersion: String) -> [ContentSourceReference] {
        Array(Set(verifiedMappings[catalogVersion, default: []])).sorted {
            $0.payloadSHA256 < $1.payloadSHA256
        }
    }
}
