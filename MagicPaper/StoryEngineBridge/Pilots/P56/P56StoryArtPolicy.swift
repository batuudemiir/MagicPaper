import CryptoKit
import Foundation

/// Separately reviewed app artwork. Immutable engine auto annotations and
/// `artApproved` flags never authorize an asset; only these pinned rules do.
struct P56StoryArtPolicy: Decodable {
    static let packagePin = "five-friends-56-runtime-v4"
    static let payloadPin = "c06a5dfc3f586eae5d837926cab915be6b22480c20e11e02c9ea7fd5894990d6"
    // Updated with the exact resource bytes by the resource author.
    static let resourceSHA256 = "904a4261664962743661b76e12c10069304f061b1294b059e9fc336072612329"

    struct Asset: Decodable {
        let assetID: String
        let fileName: String
        let digest: String
        let subjectID: String
        let subjectState: [String]
        let altText: String
        let revision: Int
        let styleRevision: String
    }

    struct Page: Decodable {
        let number: Int
        let beat: String
        let settingID: String
        let templateID: String
        let templateSHA256: String
        let templateText: String
        let parentSourceID: String
        let parentSHA256: String
        let parentPointer: String
    }

    struct Book: Decodable {
        let bookID: String
        let companionID: String
        let mode: String
        let structureID: String
        let discoveryID: String
        let worldID: String
        let pages: [Page]
    }

    struct Rule: Decodable {
        let bookID: String
        let pageNumber: Int
        let assetID: String
        let priority: Int
    }

    let schemaVersion: Int
    let bindingPolicyVersion: Int
    let packageVersion: String
    let payloadSHA256: String
    let engineBehaviorID: String
    let reviewID: String
    let assets: [Asset]
    let books: [Book]
    let rules: [Rule]

    static let bundled: Self? = {
        guard let file = Bundle.main.url(forResource: "p56-story-art-v4", withExtension: "json"),
              let data = try? Data(contentsOf: file) else { return nil }
        return load(data: data, expectedSHA256: resourceSHA256)
    }()

    static func load(data: Data, expectedSHA256: String) -> Self? {
        guard isDigest(expectedSHA256), digest(data) == expectedSHA256,
              let policy = try? JSONDecoder().decode(Self.self, from: data),
              policy.isValid else { return nil }
        return policy
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func isDigest(_ value: String) -> Bool {
        value.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil
    }

    var isValid: Bool {
        guard schemaVersion == 1, bindingPolicyVersion == 4,
              packageVersion == Self.packagePin, payloadSHA256 == Self.payloadPin,
              engineBehaviorID == "offline-p56-v1", !reviewID.isEmpty,
              !assets.isEmpty, !books.isEmpty, !rules.isEmpty,
              Set(assets.map(\.assetID)).count == assets.count,
              Set(assets.map(\.fileName)).count == assets.count,
              Set(books.map(\.bookID)).count == books.count,
              assets.allSatisfy(Self.validAsset), books.allSatisfy(Self.validBook) else { return false }
        let bookIndex = Dictionary(uniqueKeysWithValues: books.map { ($0.bookID, $0) })
        let ids = Set(assets.map(\.assetID))
        let ruleKeys = rules.map { "\($0.bookID)|\($0.pageNumber)|\($0.assetID)" }
        return Set(ruleKeys).count == rules.count && rules.allSatisfy {
            ids.contains($0.assetID) && (1...8).contains($0.pageNumber)
                && $0.priority >= 0 && bookIndex[$0.bookID] != nil
        }
    }

    private static func validAsset(_ asset: Asset) -> Bool {
        asset.assetID.hasPrefix("v4_") && asset.fileName.hasPrefix("v4_")
            && asset.fileName.hasSuffix(".mpart") && StorySpotAssetResolver.isSafeFileName(asset.fileName)
            && isDigest(asset.digest) && asset.revision > 0
            && asset.styleRevision == "magicpaper-gouache-v4-1"
            && !asset.subjectID.isEmpty && !asset.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !asset.subjectState.isEmpty && asset.subjectState.allSatisfy { !$0.isEmpty }
    }

    private static func validBook(_ book: Book) -> Bool {
        guard !book.bookID.isEmpty, !book.companionID.isEmpty,
              ["bedtime", "learning", "adventure"].contains(book.mode),
              !book.structureID.isEmpty, !book.discoveryID.isEmpty, !book.worldID.isEmpty,
              book.pages.map(\.number) == Array(1...8),
              Set(book.pages.map(\.templateID)).count == 8 else { return false }
        return book.pages.allSatisfy {
            !$0.beat.isEmpty && !$0.settingID.isEmpty && $0.templateID.hasPrefix("p56_runtime_p56_v4_")
                && isDigest($0.templateSHA256) && digest(Data($0.templateText.utf8)) == $0.templateSHA256
                && !$0.parentSourceID.isEmpty && isDigest($0.parentSHA256) && !$0.parentPointer.isEmpty
        }
    }
}
