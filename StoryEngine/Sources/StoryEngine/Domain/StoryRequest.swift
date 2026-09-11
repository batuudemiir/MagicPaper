import Foundation
import EngineFoundation
import CharacterEngine

/// How image seeds are chosen.
public enum SeedPolicy: Codable, Sendable, Hashable {
    /// Derived from the story, the scene and the character's identity seed.
    /// Same inputs always produce the same picture, which is what makes
    /// "regenerate this page" meaningfully different from "reroll it".
    case deterministic
    /// Derived the same way, but salted, so a reroll differs reproducibly.
    case salted(UInt64)

    public var salt: UInt64 {
        switch self {
        case .deterministic: return 0
        case .salted(let value): return value
        }
    }
}

/// Everything a caller asks for. Immutable; the job and story reference it.
///
/// Note what is absent: no theme enum, no page structure, no style prose, and
/// no way to describe the child. Those come from the template, the design
/// system and the Character Engine respectively.
public struct StoryRequest: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let cast: CastBinding
    public let templateID: String
    public let templateRequirement: VersionRequirement
    /// Matched against a template's `themeKeys`. Opaque to the engine.
    public let themeKey: String
    public let languageCode: String
    public let ageYears: Int
    public let requestedPageCount: Int
    /// One of the template's `toneKeys`, or nil for its default.
    public let toneKey: String?
    public let budget: GenerationBudget
    public let seedPolicy: SeedPolicy
    public let createdAt: Date
    public let schemaVersion: Int

    public static let currentSchemaVersion = 1

    public init(
        id: UUID = UUID(),
        cast: CastBinding,
        templateID: String,
        templateRequirement: VersionRequirement = .latest,
        themeKey: String,
        languageCode: String,
        ageYears: Int,
        requestedPageCount: Int,
        toneKey: String? = nil,
        budget: GenerationBudget = .standard,
        seedPolicy: SeedPolicy = .deterministic,
        createdAt: Date,
        schemaVersion: Int = StoryRequest.currentSchemaVersion
    ) {
        self.id = id
        self.cast = cast
        self.templateID = templateID
        self.templateRequirement = templateRequirement
        self.themeKey = themeKey
        self.languageCode = languageCode
        self.ageYears = ageYears
        self.requestedPageCount = requestedPageCount
        self.toneKey = toneKey
        self.budget = budget
        self.seedPolicy = seedPolicy
        self.createdAt = createdAt
        self.schemaVersion = schemaVersion
    }
}
