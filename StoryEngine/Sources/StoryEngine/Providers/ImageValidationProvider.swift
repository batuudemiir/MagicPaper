import Foundation
import CharacterEngine
import VisualSystem

/// What a validator is asked to check the image against.
///
/// Carries the source of truth rather than a description of it: the identity
/// the child actually has, the scene the page belongs to, and the exact
/// constraints the image was drawn from. A validator that had to re-derive any
/// of that could disagree with what was requested.
public struct ImageValidationContext: Codable, Sendable {
    public let characterIdentity: CharacterIdentity
    public let scene: StoryScene
    public let page: StoryPage
    public let visualConstraints: VisualConstraintSet
    public let expectedCastIDs: [CharacterID]

    public init(
        characterIdentity: CharacterIdentity,
        scene: StoryScene,
        page: StoryPage,
        visualConstraints: VisualConstraintSet,
        expectedCastIDs: [CharacterID]
    ) {
        self.characterIdentity = characterIdentity
        self.scene = scene
        self.page = page
        self.visualConstraints = visualConstraints
        self.expectedCastIDs = expectedCastIDs
    }
}

/// The kinds of problem an image validator may report.
///
/// A closed list, so a template can decide which of them block a book and a
/// support ticket can name one precisely. Not every provider will detect every
/// kind; `ImageValidationResult.uncertain` is how a provider says so.
public enum ImageValidationFinding: String, Codable, Sendable, Hashable, CaseIterable {
    case unexpectedCharacter
    case missingExpectedCharacter
    case characterAppearanceDrift
    case ageOrIdentityMismatch
    case dangerousOrInappropriateContent
    case textOrWatermarkInImage
    case renderingCorruption
    case sceneContextMismatch
    case compositionViolation
    case doNotDepictViolation

    /// Whether this finding is about a child's safety rather than a book's
    /// quality. Safety findings are the ones a policy should refuse to waive.
    public var isSafetyFinding: Bool {
        switch self {
        case .dangerousOrInappropriateContent, .doNotDepictViolation, .ageOrIdentityMismatch:
            return true
        case .unexpectedCharacter, .missingExpectedCharacter, .characterAppearanceDrift,
             .textOrWatermarkInImage, .renderingCorruption, .sceneContextMismatch, .compositionViolation:
            return false
        }
    }
}

public struct ImageValidationObservation: Codable, Sendable, Hashable {
    public let finding: ImageValidationFinding
    /// How sure the provider is, 0–1. Used only for reporting in V1.
    public let confidence: Double
    public let detail: String

    public init(finding: ImageValidationFinding, confidence: Double = 1.0, detail: String = "") {
        self.finding = finding
        self.confidence = min(max(confidence, 0), 1)
        self.detail = detail
    }
}

/// What came back from looking at the image.
///
/// Five cases, not two. The distinction that matters most is that
/// `providerUnavailable` and `uncertain` are their own outcomes: a check that
/// could not be performed must never be indistinguishable from one that passed,
/// because the difference is whether anyone has actually looked at the picture a
/// child is about to be shown.
public enum ImageValidationResult: Codable, Sendable, Hashable {
    case passed
    case failed(observations: [ImageValidationObservation])
    case uncertain(reason: String, observations: [ImageValidationObservation])
    case providerUnavailable(reason: String)
    case skipped(reason: String)

    public var observations: [ImageValidationObservation] {
        switch self {
        case .failed(let observations): return observations
        case .uncertain(_, let observations): return observations
        case .passed, .providerUnavailable, .skipped: return []
        }
    }

    public var isPassed: Bool { if case .passed = self { return true } else { return false } }
    public var isFailed: Bool { if case .failed = self { return true } else { return false } }
    public var isUncertain: Bool { if case .uncertain = self { return true } else { return false } }

    /// Whether the picture was actually looked at. `false` for both
    /// `providerUnavailable` and `skipped`.
    public var wasChecked: Bool {
        switch self {
        case .passed, .failed, .uncertain: return true
        case .providerUnavailable, .skipped: return false
        }
    }

    /// Short code used in validation issues and support logs.
    public var code: String {
        switch self {
        case .passed: return "image_validation_passed"
        case .failed: return "image_validation_failed"
        case .uncertain: return "image_validation_uncertain"
        case .providerUnavailable: return "image_validation_unavailable"
        case .skipped: return "image_validation_skipped"
        }
    }
}

/// Looks at an image that was produced and says whether it matches what was asked for.
///
/// Optional by design. Validating constraints and prompts, which the engine
/// already does, proves what was *requested*; only this proves something about
/// what came back. V1 defines the contract and expects a lightweight
/// implementation behind it — an honest `.uncertain` is a perfectly good answer
/// from a provider that cannot tell.
public protocol ImageValidationProvider: Sendable {
    func validate(image: ImageRef, context: ImageValidationContext) async throws -> ImageValidationResult
}

/// What the engine recorded about one image's validation.
public struct ImageValidationRecord: Codable, Sendable, Hashable {
    public let result: ImageValidationResult
    public let mode: ImageValidationMode
    public let provider: String?
    public let validatedAt: Date
    /// The image that was looked at. If the asset is redrawn, an older record
    /// no longer describes the current picture.
    public let imageLocator: String
    public let assetRevision: Int

    public init(
        result: ImageValidationResult,
        mode: ImageValidationMode,
        provider: String?,
        validatedAt: Date,
        imageLocator: String,
        assetRevision: Int
    ) {
        self.result = result
        self.mode = mode
        self.provider = provider
        self.validatedAt = validatedAt
        self.imageLocator = imageLocator
        self.assetRevision = assetRevision
    }

    /// Whether this record still describes the given asset's current image.
    public func describes(_ asset: VisualAsset) -> Bool {
        asset.revision == assetRevision && asset.imageRef?.locator == imageLocator
    }
}

/// How seriously the engine takes image validation.
public enum ImageValidationMode: String, Codable, Sendable, Hashable, CaseIterable {
    /// Do not look at the image at all. No provider call, no cost.
    case off
    /// Look, and report. Findings are warnings and do not hold up a book.
    case advisory
    /// Look, and insist. A failure or an unusable answer blocks publication.
    case required
}
