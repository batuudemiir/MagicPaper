import CryptoKit
import Foundation
import ImageIO
import StoryEngine

/// Publishing attestation for exact reviewed sources, independent of automatic engine labels.
/// This first slice authorizes an isolated bell only; it does not authorize a scene.
struct ReviewedDiscoveryArtPolicy: Decodable {
    struct Source: Decodable {
        let sourceID: String
        let templateID: String
        let sourceTextDigest: String
        let decision: String
    }
    struct Recall: Decodable {
        let sourceID: String
        let sourceTextDigest: String
        let decision: String
    }
    let schemaVersion: Int
    let bindingPolicyVersion: Int
    let reviewID: String
    let catalogVersion: String
    let canonicalDiscoveryFingerprint: String
    let asset: StorySpotCatalog.Asset
    let sources: [Source]
    let recalls: [Recall]

    static let bundled: Self? = {
        guard let url = Bundle.main.url(forResource: "reviewed-discovery-art-v2", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return load(data: data, validateFile: validatesBundledImage)
    }()

    static func load(data: Data, validateFile: (String, String) -> Bool) -> Self? {
        guard SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined()
                == "5a39b3e776a6a0c7cdd70c7f8eb03743a242a58a1fd5045f94e1bee1763d8af4",
              let policy = try? JSONDecoder().decode(Self.self, from: data),
              policy.schemaVersion == 1, policy.bindingPolicyVersion == 2,
              policy.reviewID == "manual-isolated-bell-2026-11-20", policy.catalogVersion == "2.1.0",
              policy.asset.assetID == "spot.silver-bell", policy.asset.subjectID == "object_bell_001",
              policy.asset.subjectState == ["small", "silver", "intact"],
              policy.canonicalDiscoveryFingerprint == "056b272623315690",
              Set(policy.sources.map(\.sourceID)) == Set(["na_neutral_01", "na_neutral_02", "na_any_01", "na_any_02", "na_any_03"]),
              policy.sources.count == 5, policy.recalls.count == 38,
              Set(policy.recalls.map(\.sourceID)).count == policy.recalls.count,
              policy.sources.allSatisfy({ $0.templateID == "corpus_5-6_notice_anomaly"
                  && $0.decision == "discovery_present" && validDigest($0.sourceTextDigest) }),
              policy.recalls.allSatisfy({ $0.decision == "no_discovery_contradiction" && validDigest($0.sourceTextDigest) }),
              let assetData = try? JSONEncoder().encode(policy.asset),
              let assetJSON = try? JSONSerialization.jsonObject(with: assetData),
              let catalogData = try? JSONSerialization.data(withJSONObject:
                ["schemaVersion": 1, "assets": [assetJSON], "rules": []]),
              StorySpotCatalog.load(data: catalogData, validateFile: validateFile) != nil else { return nil }
        return policy
    }

    private static func validatesBundledImage(file: String, digest: String) -> Bool {
        guard let url = StorySpotAssetResolver.validatedURL(fileName: file, digest: digest),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              CGImageSourceGetCount(source) == 1,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width > 0, image.height > 0,
              max(image.width, image.height) <= 4096 else { return false }
        return true
    }

    private static func validDigest(_ value: String) -> Bool {
        value.range(of: "^[a-f0-9]{16}$", options: .regularExpression) != nil
    }

    func proof(parts: [PageSourcePart], variantIDs: [String], discovery: CatalogObject) -> String? {
        guard (1...2).contains(parts.count), parts.map(\.sourceID) == variantIDs,
              discovery.id.rawValue == asset.subjectID,
              AuthoredSourceFingerprint.make(sources: [], discovery: discovery) == canonicalDiscoveryFingerprint,
              let first = parts.first, first.kind == .beatLine, first.beat == .noticeAnomaly,
              first.contexts.isEmpty,
              sources.contains(where: { $0.sourceID == first.sourceID && $0.templateID == first.templateID
                  && $0.sourceTextDigest == first.sourceTextDigest }),
              let visual = first.visual,
              visual.filter({ $0.subject == .discovery }).count == 1,
              visual.contains(where: { $0.subject == .discovery && $0.subjectID == asset.subjectID && $0.presence == .present })
        else { return nil }
        if parts.count == 2 {
            let recall = parts[1]
            guard recall.kind == .recall, recall.templateID == nil, recall.beat == nil,
                  recall.contexts.isEmpty, recall.visual == nil, recall.visualReview == nil,
                  recalls.contains(where: { $0.sourceID == recall.sourceID && $0.sourceTextDigest == recall.sourceTextDigest })
            else { return nil }
        }
        // Manual source attestations intentionally assert presence, not auto "examined" state.
        return PageSourcePart.digest(([reviewID, canonicalDiscoveryFingerprint]
            + parts.flatMap { [$0.kind.rawValue, $0.sourceID, $0.templateID ?? "", $0.sourceTextDigest] }).joined(separator: "\u{1f}"))
    }
}
