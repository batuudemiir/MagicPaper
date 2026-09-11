import Foundation
import EngineFoundation

/// The deterministic identity of one *logical* provider operation.
///
/// The failure this exists to prevent is expensive and silent: a provider
/// generates an image, the response is lost to a timeout, the engine sees a
/// failure and retries, and the family is billed twice for one picture. A retry
/// of the same logical operation must therefore carry the same key, so an
/// adapter (or the engine's own result cache) can recognise it as the same work.
///
/// The key is a hash of what makes the operation what it is. Two requests that
/// would produce the same artefact share a key; anything that would produce a
/// different artefact — a new revision, a changed fingerprint, a forced reroll —
/// gets a new one.
public struct ProviderRequestIdentity: Codable, Sendable, Hashable, CustomStringConvertible {
    public let idempotencyKey: String

    public init(idempotencyKey: String) {
        self.idempotencyKey = idempotencyKey
    }

    public var description: String { idempotencyKey }

    /// Builds a key from the parts of a logical operation.
    ///
    /// The hash is an implementation detail; what the engine guarantees is that
    /// identical components produce an identical key, on any device, in any
    /// process. The readable prefix is there so provider logs and support
    /// tickets are navigable.
    public init(operation: AIOperation, components: [String]) {
        let digest = StableHash.fingerprint([operation.rawValue] + components)
        self.idempotencyKey = "\(operation.rawValue)-\(digest)"
    }
}

/// Builds the identity for every billable operation the engine performs.
///
/// One place, so that "what makes this request different from that one" is a
/// single readable answer rather than a string literal scattered across five
/// services.
public enum IdempotencyKeyFactory {

    public static func outline(storyID: UUID, templateRef: TemplateRef, requestID: UUID, attemptSalt: Int = 0) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .outline,
            components: [
                "story:\(storyID.uuidString)",
                "request:\(requestID.uuidString)",
                "template:\(templateRef.templateID)@\(templateRef.templateVersion)",
                "narrative:\(templateRef.narrativeVersion)",
                "salt:\(attemptSalt)"
            ]
        )
    }

    public static func narrativeDraft(storyID: UUID, outline: StoryOutline, templateRef: TemplateRef, attemptSalt: Int = 0) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .narrativeDraft,
            components: [
                "story:\(storyID.uuidString)",
                "template:\(templateRef.templateID)@\(templateRef.templateVersion)",
                // The outline is the draft's input, so a re-planned outline is
                // genuinely different work and must not reuse a cached draft.
                "outline:\(outlineDigest(outline))",
                "salt:\(attemptSalt)"
            ]
        )
    }

    public static func pageRefinement(storyID: UUID, page: StoryPage, instruction: String?) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .pageRefinement,
            components: [
                "story:\(storyID.uuidString)",
                "page:\(page.id.uuidString)",
                // The revision counter is what makes "regenerate this page
                // again" different work rather than a cache hit.
                "revision:\(page.textRevision)",
                "instruction:\(instruction ?? "-")"
            ]
        )
    }

    public static func image(storyID: UUID, asset: VisualAsset) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .imageGeneration,
            components: [
                "story:\(storyID.uuidString)",
                "asset:\(asset.id.uuidString)",
                "revision:\(asset.revision)",
                // The fingerprint already folds in identity, style, scene and
                // seed, so any material change to the picture changes the key.
                "fingerprint:\(asset.fingerprint)"
            ]
        )
    }

    public static func semanticValidation(storyID: UUID, validatorID: String, contentHash: String) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .semanticValidation,
            components: [
                "story:\(storyID.uuidString)",
                "validator:\(validatorID)",
                // Re-validating unchanged content is the same question.
                "content:\(contentHash)"
            ]
        )
    }

    public static func imageValidation(storyID: UUID, assetID: UUID, imageLocator: String, revision: Int) -> ProviderRequestIdentity {
        ProviderRequestIdentity(
            operation: .imageValidation,
            components: [
                "story:\(storyID.uuidString)",
                "asset:\(assetID.uuidString)",
                "image:\(imageLocator)",
                "revision:\(revision)"
            ]
        )
    }

    static func outlineDigest(_ outline: StoryOutline) -> String {
        StableHash.fingerprint(
            [outline.title, outline.logline]
                + outline.beats.sorted { $0.ordinal < $1.ordinal }.map {
                    "\($0.ordinal):\($0.templateBeatID):\($0.summary):\($0.settingKey):\($0.timeOfDayKey):\($0.moodKey)"
                }
        )
    }
}

/// Remembers what a provider already produced for a logical operation.
///
/// The engine cannot assume a provider deduplicates on its own — most do not.
/// This is the fallback: a result recorded here is returned instead of paying
/// for the same work twice, which matters most on a retry that follows a lost
/// response rather than a real failure.
///
/// In-memory and per-run by design. Persisting it would mean reasoning about
/// staleness and eviction, which V1 does not need: the case that costs money is
/// a retry seconds after the original call.
public actor ProviderResultCache {
    private var completions: [String: AICompletionResponse] = [:]
    private var images: [String: ImageGenerationResponse] = [:]
    public private(set) var hitCount = 0

    public init() {}

    public func completion(for identity: ProviderRequestIdentity) -> AICompletionResponse? {
        guard let cached = completions[identity.idempotencyKey] else { return nil }
        hitCount += 1
        return cached
    }

    public func store(_ response: AICompletionResponse, for identity: ProviderRequestIdentity) {
        completions[identity.idempotencyKey] = response
    }

    public func image(for identity: ProviderRequestIdentity) -> ImageGenerationResponse? {
        guard let cached = images[identity.idempotencyKey] else { return nil }
        hitCount += 1
        return cached
    }

    public func store(_ response: ImageGenerationResponse, for identity: ProviderRequestIdentity) {
        images[identity.idempotencyKey] = response
    }

    public func reset() {
        completions.removeAll()
        images.removeAll()
        hitCount = 0
    }
}
