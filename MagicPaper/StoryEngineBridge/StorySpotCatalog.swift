import Foundation

/// The validated local publishing allowlist. File verification happens only at load.
struct StorySpotCatalog {
    struct Asset: Codable {
        let assetID: String
        let revision: Int
        let digest: String
        let styleRevision: String
        let fileName: String
        let status: String
        let subjectID: String
        let subjectState: [String]
        let altText: String
    }
    struct Rule: Codable {
        let bindingPolicyVersion: Int
        let catalogVersion: String
        let blueprintID: String
        let pageNumber: Int
        let role: String
        let beats: [String]
        let variantIDs: [String]
        let authoredSourceFingerprint: String
        let assetID: String
        let assetRevision: Int
        let settingIDs: [String]?
    }
    private struct Manifest: Decodable {
        let schemaVersion: Int
        let assets: [Asset]
        let rules: [Rule]
    }
    let assets: [Asset]
    let rules: [Rule]

    static let bundled: StorySpotCatalog? = {
        guard let url = Bundle.main.url(forResource: "story-art-v1", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return load(data: data) { file, digest in
            StorySpotAssetResolver.validatedURL(fileName: file, digest: digest) != nil
        }
    }()

    static func load(data: Data, validateFile: (String, String) -> Bool) -> StorySpotCatalog? {
        guard let manifest = try? JSONDecoder().decode(Manifest.self, from: data),
              manifest.schemaVersion == 1 else { return nil }
        var keys = Set<String>()
        for asset in manifest.assets {
            guard keys.insert("\(asset.assetID)/\(asset.revision)").inserted,
                  asset.revision > 0, asset.status == "approved", !asset.assetID.isEmpty,
                  !asset.styleRevision.isEmpty, !asset.subjectID.isEmpty,
                  !asset.subjectState.isEmpty, asset.subjectState.allSatisfy({ !$0.isEmpty }),
                  !asset.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  asset.digest.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil,
                  StorySpotAssetResolver.isSafeFileName(asset.fileName),
                  validateFile(asset.fileName, asset.digest) else { return nil }
        }
        guard manifest.rules.allSatisfy({ rule in
            rule.bindingPolicyVersion == 1 && rule.pageNumber == 1 && rule.role == "hook"
                && rule.beats == ["notice_anomaly"] && rule.variantIDs.count == 1
                && ["na_neutral_01", "na_neutral_02"].contains(rule.variantIDs[0])
                && !rule.catalogVersion.isEmpty && !rule.blueprintID.isEmpty
                && !rule.authoredSourceFingerprint.isEmpty
                && manifest.assets.contains { $0.assetID == rule.assetID && $0.revision == rule.assetRevision }
        }) else { return nil }
        return StorySpotCatalog(assets: manifest.assets, rules: manifest.rules)
    }
}
