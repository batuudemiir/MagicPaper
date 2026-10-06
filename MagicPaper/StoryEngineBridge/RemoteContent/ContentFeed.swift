import Foundation
import CryptoKit

/// The content feed (FAZ 15): Günün masalı, the educational stories, and which
/// catalog package the engine should use — changed without an app update.
///
/// Read only after its signature has been checked (`ContentFeed.verified`).
/// What is on disk is the signed bytes, never a re-encoding, so the signature
/// can be checked again on every launch.
struct ContentFeed: Codable, Equatable {
    /// The feed format this app reads. A feed in a newer format is refused
    /// whole, and the last one this app could read stays.
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    /// Rises with every publish. A feed that is not newer than the stored one
    /// is not taken — an old, validly signed feed cannot be replayed.
    let feedVersion: Int
    let publishedAt: String
    let stories: [FeedStory]
    /// `nil` takes any downloaded package out of use: the bundle serves again.
    let catalogPackage: CatalogPackageRef?

    enum CodingKeys: String, CodingKey {
        case schemaVersion, feedVersion, publishedAt, stories, catalogPackage
    }

    init(schemaVersion: Int = supportedSchemaVersion, feedVersion: Int, publishedAt: String,
         stories: [FeedStory], catalogPackage: CatalogPackageRef?) {
        self.schemaVersion = schemaVersion
        self.feedVersion = feedVersion
        self.publishedAt = publishedAt
        self.stories = stories
        self.catalogPackage = catalogPackage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        feedVersion = try container.decode(Int.self, forKey: .feedVersion)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        // One story this app cannot read — a category added later — is
        // skipped, not allowed to take the whole feed down with it.
        stories = try container.decode([Lossy<FeedStory>].self, forKey: .stories).compactMap(\.value)
        catalogPackage = try container.decodeIfPresent(CatalogPackageRef.self, forKey: .catalogPackage)
    }

    enum Rejection: Error, Equatable {
        case badSignature
        case unreadable
        case unsupportedSchema(Int)
        case duplicateStory
        case badPackageReference
    }

    /// The feed, if `signature` is the publisher's over exactly these bytes and
    /// the content is something this app can use.
    static func verified(_ data: Data, signature: Data, key: ContentSigningKey) throws -> ContentFeed {
        guard key.isValid(signature, for: data) else { throw Rejection.badSignature }
        let feed: ContentFeed
        do {
            feed = try JSONDecoder().decode(ContentFeed.self, from: data)
        } catch {
            throw Rejection.unreadable
        }
        guard feed.schemaVersion == supportedSchemaVersion else {
            throw Rejection.unsupportedSchema(feed.schemaVersion)
        }
        guard Set(feed.stories.map(\.id)).count == feed.stories.count else { throw Rejection.duplicateStory }
        if let package = feed.catalogPackage, !package.isWellFormed { throw Rejection.badPackageReference }
        return feed
    }
}

/// One ready-written story in the feed.
struct FeedStory: Codable, Equatable {
    let id: UUID
    /// `yyyy-MM-dd`, in the reader's own calendar day. A story is not shown
    /// before its day.
    let publishDate: String
    let title: String
    let category: DailyStoryCategory
    let ageRange: String
    let readingTime: Int
    let content: String
    let moralLesson: String
    let emoji: String

    func dailyStory(readOn date: Date?) -> DailyStory {
        DailyStory(id: id, title: title, category: category, ageRange: ageRange, readingTime: readingTime,
                   content: content, moralLesson: moralLesson, emoji: emoji,
                   isRead: date != nil, lastReadDate: date)
    }
}

/// Where the catalog package is and what it must hash to.
///
/// The digest is inside the signed feed, so the one signature covers the
/// package too: a package that does not hash to this is not the one published.
struct CatalogPackageRef: Codable, Equatable {
    let version: String
    let schemaVersion: Int
    /// Relative to the content root, under `catalog/`.
    let path: String
    /// Lowercase hex SHA-256 of the package bytes.
    let sha256: String

    var isWellFormed: Bool {
        path.hasPrefix("catalog/") && !path.contains("..") && !path.contains("://") && !path.contains("?")
            && sha256.count == 64 && sha256.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    func matches(_ data: Data) -> Bool {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() == sha256
    }
}

/// Decodes a value or nothing, so one bad element does not fail an array.
private struct Lossy<Value: Decodable>: Decodable {
    let value: Value?
    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

/// The publisher's public key. The private half never leaves the publisher's
/// machine (`Scripts/ContentPublisher keygen`).
struct ContentSigningKey {
    private let key: Curve25519.Signing.PublicKey

    init?(base64: String) {
        guard let raw = Data(base64Encoded: base64.trimmingCharacters(in: .whitespacesAndNewlines)),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw) else { return nil }
        self.key = key
    }

    init(_ key: Curve25519.Signing.PublicKey) {
        self.key = key
    }

    /// `signature` is the base64 text the publisher writes next to the feed.
    func isValid(_ signature: Data, for data: Data) -> Bool {
        guard let text = String(data: signature, encoding: .utf8),
              let raw = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return key.isValidSignature(raw, for: data)
    }
}
