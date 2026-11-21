import CryptoKit
import EngineFoundation
import Foundation
import ImageIO
import StoryEngine

/// Exact publishing attestations, independent of automatic visual labels.
struct WholeBookArtPolicy: Decodable {
    struct Entry: Decodable {
        let asset: StorySpotCatalog.Asset
        let view: String
        let subjectRole: String
        let canonicalFingerprint: String
    }
    struct Rule: Decodable {
        let blueprintID: String
        let pageNumber: Int
        let role: String
        let beats: [String]
        let orderedParts: [PageSourcePart]
        let assetID: String
        let requiredSubjectID: String
        let requiredPresence: String
        let requiredStates: [String]
    }
    let schemaVersion: Int
    let bindingPolicyVersion: Int
    let reviewID: String
    let catalogVersion: String
    let blueprintIDs: [String]
    let assets: [Entry]
    let rules: [Rule]
    static let manifestDigest = "a9262bfc7c38f5d7464fa62fee62ef2e1b6fc3c9665f0bbe1af043205d018952"
    static let pilotBlueprintIDs: Set<String> = [
        "blueprint_threshold_crossing_001", "bp_threshold_joining_002",
        "blueprint_absence_looking_001", "bp_absence_retracing_002",
        "bp_threshold_together_003", "bp_absence_asking_003"
    ]
    static let bundled: Self? = {
        guard let url = Bundle.main.url(forResource: "whole-book-art-v3", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return load(data: data, validateFile: validatesBundledImage)
    }()

    static func load(data: Data, validateFile: (String, String) -> Bool) -> Self? {
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == manifestDigest, let policy = try? JSONDecoder().decode(Self.self, from: data),
              policy.schemaVersion == 1, policy.bindingPolicyVersion == 3,
              policy.reviewID == "manual-whole-book-pilot-2026-11-21", policy.catalogVersion == "2.1.0",
              Set(policy.blueprintIDs) == pilotBlueprintIDs, policy.blueprintIDs.count == 6,
              !policy.assets.isEmpty, !policy.rules.isEmpty,
              Set(policy.assets.map { $0.asset.assetID }).count == policy.assets.count,
              policy.assets.allSatisfy({ ["discovery", "companion"].contains($0.subjectRole)
                  && !$0.view.isEmpty && validFingerprint($0.canonicalFingerprint) }),
              let encoded = try? JSONEncoder().encode(policy.assets.map(\.asset)),
              let assets = try? JSONSerialization.jsonObject(with: encoded),
              let catalog = try? JSONSerialization.data(withJSONObject:
                  ["schemaVersion": 1, "assets": assets, "rules": []]),
              StorySpotCatalog.load(data: catalog, validateFile: validateFile) != nil,
              policy.rules.allSatisfy({ policy.validRule($0) }) else { return nil }
        return policy
    }

    private func validRule(_ rule: Rule) -> Bool {
        guard Self.pilotBlueprintIDs.contains(rule.blueprintID), (1...8).contains(rule.pageNumber),
              !rule.role.isEmpty, !rule.beats.isEmpty, !rule.orderedParts.isEmpty,
              let entry = assets.first(where: { $0.asset.assetID == rule.assetID }),
              rule.requiredSubjectID == entry.asset.subjectID, rule.requiredPresence == "present",
              rule.orderedParts.allSatisfy({ $0.kind != .refrain && $0.contexts.isEmpty
                  && Self.validFingerprint($0.sourceTextDigest) }) else { return false }
        return rule.orderedParts.flatMap { $0.visual ?? [] }.contains {
            $0.subject.rawValue == entry.subjectRole && $0.subjectID == rule.requiredSubjectID
                && $0.presence.rawValue == rule.requiredPresence && $0.states == rule.requiredStates
        }
    }

    func matches(_ rule: Rule, blueprintID: String, pageNumber: Int, role: String,
                 beats: [String], parts: [PageSourcePart], variantIDs: [String],
                 subjectID: String, canonicalFingerprint: String) -> Bool {
        guard let entry = assets.first(where: { $0.asset.assetID == rule.assetID }) else { return false }
        return rule.blueprintID == blueprintID && rule.pageNumber == pageNumber
            && rule.role == role && rule.beats == beats && rule.orderedParts == parts
            && parts.map(\.sourceID) == variantIDs && entry.asset.subjectID == subjectID
            && rule.requiredSubjectID == subjectID && entry.canonicalFingerprint == canonicalFingerprint
    }

    static func companionFingerprint(_ companion: CatalogCompanion) -> String {
        let traits = companion.traits.map(\.rawValue).sorted()
        let habitat = companion.habitat.map(\.rawValue).sorted()
        let values = ["whole-book-companion-identity-v1", companion.id.rawValue, companion.name,
            companion.type, companion.personality, companion.description, companion.visualDescription,
            String(traits.count)] + traits + [String(habitat.count)] + habitat
            + [companion.declaredNature?.rawValue ?? "<nil>"]
        return StableHash.fingerprint(values.map { "\($0.utf8.count):\($0)" })
    }

    private static func validFingerprint(_ value: String) -> Bool {
        value.range(of: "^[a-f0-9]{16}$", options: .regularExpression) != nil
    }

    private static func validatesBundledImage(file: String, digest: String) -> Bool {
        guard let url = StorySpotAssetResolver.validatedURL(fileName: file, digest: digest),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil), CGImageSourceGetCount(source) == 1,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width > 0, image.height > 0, max(image.width, image.height) <= 4096 else { return false }
        return true
    }
}
