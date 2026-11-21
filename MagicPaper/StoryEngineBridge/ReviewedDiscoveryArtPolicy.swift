import CryptoKit
import Foundation
import ImageIO
import StoryEngine

/// Publishing attestation for exact reviewed sources, independent of automatic engine labels.
/// Authorizes bounded isolated discoveries; it does not authorize scenes.
struct ReviewedDiscoveryArtPolicy {
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
    struct Entry: Decodable {
        let canonicalDiscoveryFingerprint: String
        let asset: StorySpotCatalog.Asset
    }
    struct Authorization {
        let asset: StorySpotCatalog.Asset
        let proof: String
        let beats: [StoryBeat]
    }
    private struct Manifest: Decodable {
        let schemaVersion: Int
        let bindingPolicyVersion: Int
        let reviewID: String
        let catalogVersion: String
        let canonicalDiscoveryFingerprint: String?
        let asset: StorySpotCatalog.Asset?
        let entries: [Entry]?
        let sources: [Source]
        let recalls: [Recall]
        let pairedSources: [Source]?
        let pairedBlueprintIDs: [String]?
    }
    let schemaVersion: Int
    let bindingPolicyVersion: Int
    let reviewID: String
    let catalogVersion: String
    let entries: [Entry]
    let sources: [Source]
    let recalls: [Recall]
    let pairedSources: [Source]
    let pairedBlueprintIDs: [String]

    private struct Edition {
        let reviewID: String
        let entryCount: Int
        let sourceCount: Int
        let supportCount: Int
        let blueprintCount: Int
    }
    private static let editions: [String: Edition] = [
        "5a39b3e776a6a0c7cdd70c7f8eb03743a242a58a1fd5045f94e1bee1763d8af4":
            Edition(reviewID: "manual-isolated-bell-2026-11-20", entryCount: 1,
                    sourceCount: 5, supportCount: 0, blueprintCount: 0),
        "28b285072990b172843f39c88d7b4275472a36b49d38ff0dc40b8877f6771f4c":
            Edition(reviewID: "manual-isolated-discoveries-2026-11-21", entryCount: 11,
                    sourceCount: 5, supportCount: 0, blueprintCount: 0),
        "7ff4a60b417fa71f560354b80344af5a5112e0ed1bb019feea9e98ff481cd91d":
            Edition(reviewID: "manual-isolated-discoveries-wave2-2026-11-21", entryCount: 14,
                    sourceCount: 20, supportCount: 4, blueprintCount: 3),
        "c065eb4b4a1c400c00b5225b4e6aadce77630040116713e0e5e45f70895ac897":
            Edition(reviewID: "manual-isolated-discoveries-wave3-2026-11-21", entryCount: 20,
                    sourceCount: 20, supportCount: 4, blueprintCount: 3)
    ]

    static let bundled: Self? = {
        guard let url = Bundle.main.url(forResource: "reviewed-discovery-art-wave3-v2", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return load(data: data, validateFile: validatesBundledImage)
    }()

    static func load(data: Data, validateFile: (String, String) -> Bool) -> Self? {
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard let edition = editions[digest],
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data),
              manifest.schemaVersion == 1, manifest.bindingPolicyVersion == 2,
              manifest.reviewID == edition.reviewID,
              manifest.catalogVersion == "2.1.0" else { return nil }
        let legacy = edition.entryCount == 1
        let entries: [Entry]
        if legacy, let asset = manifest.asset, let fingerprint = manifest.canonicalDiscoveryFingerprint {
            entries = [Entry(canonicalDiscoveryFingerprint: fingerprint, asset: asset)]
        } else {
            guard !legacy, manifest.asset == nil, manifest.canonicalDiscoveryFingerprint == nil,
                  let expanded = manifest.entries, expanded.count == edition.entryCount else { return nil }
            entries = expanded
        }
        let policy = Self(schemaVersion: manifest.schemaVersion, bindingPolicyVersion: manifest.bindingPolicyVersion,
            reviewID: manifest.reviewID, catalogVersion: manifest.catalogVersion,
            entries: entries, sources: manifest.sources, recalls: manifest.recalls,
            pairedSources: manifest.pairedSources ?? [], pairedBlueprintIDs: manifest.pairedBlueprintIDs ?? [])
        return policy.validated(edition: edition, validateFile: validateFile) ? policy : nil
    }

    private func validated(edition: Edition, validateFile: (String, String) -> Bool) -> Bool {
        guard Set(entries.map { $0.asset.subjectID }).count == entries.count,
              Set(entries.map { $0.asset.fileName }).count == entries.count,
              Set(entries.map(\.canonicalDiscoveryFingerprint)).count == entries.count,
              entries.allSatisfy({ Self.validDigest($0.canonicalDiscoveryFingerprint) }),
              Set(sources.map { $0.templateID + ":" + $0.sourceID }).count == sources.count,
              sources.count == edition.sourceCount, recalls.count == 38,
              Set(recalls.map(\.sourceID)).count == recalls.count,
              sources.allSatisfy({ $0.decision == "discovery_present" && Self.validDigest($0.sourceTextDigest) }),
              pairedSources.count == edition.supportCount,
              pairedBlueprintIDs.count == edition.blueprintCount,
              Set(pairedSources.map { $0.templateID + ":" + $0.sourceID }).count == pairedSources.count,
              pairedSources.allSatisfy({ $0.templateID == "corpus_3-4_meet_companion"
                  && $0.decision == "no_discovery_contradiction" && Self.validDigest($0.sourceTextDigest) }),
              recalls.allSatisfy({ $0.decision == "no_discovery_contradiction" && Self.validDigest($0.sourceTextDigest) }),
              let assetData = try? JSONEncoder().encode(entries.map(\.asset)),
              let assetJSON = try? JSONSerialization.jsonObject(with: assetData),
              let catalogData = try? JSONSerialization.data(withJSONObject:
                ["schemaVersion": 1, "assets": assetJSON, "rules": []]),
              StorySpotCatalog.load(data: catalogData, validateFile: validateFile) != nil else { return false }
        return true
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
        authorization(parts: parts, variantIDs: variantIDs, discovery: discovery)?.proof
    }

    func authorization(parts: [PageSourcePart], variantIDs: [String], discovery: CatalogObject,
                       blueprintID: String? = nil, pageNumber: Int? = nil, companionID: String? = nil) -> Authorization? {
        guard (1...2).contains(parts.count), parts.map(\.sourceID) == variantIDs,
              let entry = entries.first(where: { $0.asset.subjectID == discovery.id.rawValue }),
              AuthoredSourceFingerprint.make(sources: [], discovery: discovery) == entry.canonicalDiscoveryFingerprint,
              let first = parts.first, first.kind == .beatLine, first.beat == .noticeAnomaly,
              first.contexts.isEmpty,
              sources.contains(where: { $0.sourceID == first.sourceID && $0.templateID == first.templateID
                  && $0.sourceTextDigest == first.sourceTextDigest }),
              let visual = first.visual,
              visual.filter({ $0.subject == .discovery }).count == 1,
              visual.contains(where: { $0.subject == .discovery && $0.subjectID == entry.asset.subjectID && $0.presence == .present })
        else { return nil }
        let paired = first.templateID == "corpus_3-4_notice_anomaly"
        if paired {
            guard let blueprintID, pairedBlueprintIDs.contains(blueprintID), pageNumber == 1,
                  let companionID, !companionID.isEmpty, parts.count == 2,
                  validCompanion(parts[1], companionID: companionID) else { return nil }
        } else if parts.count == 2 {
            let recall = parts[1]
            guard recall.kind == .recall, recall.templateID == nil, recall.beat == nil,
                  recall.contexts.isEmpty, recall.visual == nil, recall.visualReview == nil,
                  recalls.contains(where: { $0.sourceID == recall.sourceID && $0.sourceTextDigest == recall.sourceTextDigest })
            else { return nil }
        }
        // Manual source attestations intentionally assert presence, not auto "examined" state.
        let proofReviewID = entry.asset.subjectID == "object_bell_001" ? "manual-isolated-bell-2026-11-20" : reviewID
        let proof = PageSourcePart.digest(([proofReviewID, entry.canonicalDiscoveryFingerprint]
            + parts.flatMap { [$0.kind.rawValue, $0.sourceID, $0.templateID ?? "", $0.sourceTextDigest] }).joined(separator: "\u{1f}"))
        return Authorization(asset: entry.asset, proof: proof, beats: paired ? [.noticeAnomaly, .meetCompanion] : [.noticeAnomaly])
    }
    private func validCompanion(_ part: PageSourcePart, companionID: String) -> Bool {
        guard part.kind == .beatLine, part.beat == .meetCompanion, part.contexts.isEmpty,
              pairedSources.contains(where: { $0.sourceID == part.sourceID && $0.templateID == part.templateID
                  && $0.sourceTextDigest == part.sourceTextDigest }),
              let visual = part.visual, visual.count == 1, let mention = visual.first else { return false }
        return mention.subject == .companion && mention.subjectID == companionID
            && mention.presence == .present && mention.states == ["greeting"]
    }

}
