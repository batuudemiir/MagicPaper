import Foundation

/// One ready-written story, as authored in `Content/DailyFeed/stories/*.json`
/// and as the app's `FeedStory` reads it. Keep the two in step.
public struct StoryFile: Codable, Equatable {
    public let id: String
    public let publishDate: String
    public let title: String
    public let category: String
    public let ageRange: String
    public let readingTime: Int
    public let content: String
    public let moralLesson: String
    public let emoji: String

    /// `DailyStoryCategory` raw values the app knows. A story in an unknown
    /// category would be skipped by every installed app.
    public static let categories: Set<String> = ["bedtime", "morning", "educational", "values", "adventure", "nature"]

    /// What is wrong with this story, in words for the author.
    public func problems() -> [String] {
        var problems: [String] = []
        if UUID(uuidString: id) == nil { problems.append("id bir UUID değil") }
        if !Self.isDay(publishDate) { problems.append("publishDate yyyy-MM-dd değil: \(publishDate)") }
        if !Self.categories.contains(category) { problems.append("bilinmeyen kategori: \(category)") }
        if !Self.isAgeRange(ageRange) { problems.append("ageRange okunamıyor: \(ageRange) (örn. 3-6 ya da 10+)") }
        if !(1...30).contains(readingTime) { problems.append("readingTime 1-30 dakika olmalı") }
        for (name, text) in [("title", title), ("content", content), ("moralLesson", moralLesson), ("emoji", emoji)]
        where text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("\(name) boş")
        }
        if content.contains("{{") { problems.append("content'te doldurulmamış yer tutucu var") }
        return problems
    }

    static func isDay(_ text: String) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: text) else { return false }
        return formatter.string(from: date) == text
    }

    static func isAgeRange(_ text: String) -> Bool {
        if text.hasSuffix("+") { return Int(text.dropLast()) != nil }
        let parts = text.split(separator: "-").map { Int($0) }
        return parts.count == 2 && parts.allSatisfy { $0 != nil } && parts[0]! <= parts[1]!
    }
}

/// The catalog package a feed names. Mirrors the app's `CatalogPackageRef`.
public struct PackageReference: Codable, Equatable {
    public let version: String
    public let schemaVersion: Int
    public let path: String
    public let sha256: String
}

/// `feed.json`. Mirrors the app's `ContentFeed`.
public struct FeedFile: Codable, Equatable {
    public static let schemaVersion = 1

    public var schemaVersion: Int = FeedFile.schemaVersion
    public var feedVersion: Int
    public var publishedAt: String
    public var stories: [StoryFile]
    public var catalogPackage: PackageReference?

    public init(feedVersion: Int, publishedAt: String, stories: [StoryFile], catalogPackage: PackageReference?) {
        self.feedVersion = feedVersion
        self.publishedAt = publishedAt
        self.stories = stories
        self.catalogPackage = catalogPackage
    }

    /// The bytes that get signed. Stable for the same feed.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return try encoder.encode(self) + Data("\n".utf8)
    }
}

public enum StoryLibrary {
    /// Every story file, checked. Throws listing every problem at once.
    public static func load(from directory: URL) throws -> [StoryFile] {
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".json") }.sorted()
        var stories: [StoryFile] = []
        var problems: [String] = []
        for name in names {
            do {
                let story = try JSONDecoder().decode(StoryFile.self, from: Data(contentsOf: directory.appendingPathComponent(name)))
                problems += story.problems().map { "\(name): \($0)" }
                stories.append(story)
            } catch {
                problems.append("\(name): okunamadı — \(error)")
            }
        }
        var seen: [String: String] = [:]
        for (name, story) in zip(names, stories) {
            if let other = seen[story.id.uppercased()] { problems.append("\(name): id \(other) ile aynı") }
            seen[story.id.uppercased()] = name
        }
        if stories.isEmpty { problems.append("hiç masal yok") }
        guard problems.isEmpty else { throw PublishError.invalid(problems) }
        return stories
    }
}

public enum PublishError: Error, CustomStringConvertible {
    case invalid([String])
    case message(String)

    public var description: String {
        switch self {
        case .invalid(let problems): return "Doğrulanmadı:\n" + problems.map { "  - \($0)" }.joined(separator: "\n")
        case .message(let text): return text
        }
    }
}
