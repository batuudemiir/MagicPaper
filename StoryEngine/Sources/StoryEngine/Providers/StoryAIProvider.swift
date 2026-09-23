import Foundation

/// A prompt, as the engine hands it over.
///
/// Split into parts rather than one blob so an adapter can map them onto
/// whatever its vendor prefers — system/user turns, a single string, or a
/// structured-output request.
public struct AICompletionRequest: Sendable, Hashable {
    public let operation: AIOperation
    public let modelTier: ModelTier
    public let systemInstructions: [String]
    public let userInstructions: [String]
    /// JSON the response must conform to, described for the model. Adapters
    /// with native structured output should use it as a schema.
    public let responseSchemaDescription: String?
    public let languageCode: String
    public let maximumOutputTokens: Int?
    public let temperature: Double?
    /// Identifies this logical call. Retries of the same work carry the same
    /// identity, so an adapter can deduplicate rather than bill twice.
    public let identity: ProviderRequestIdentity

    public init(
        operation: AIOperation,
        modelTier: ModelTier,
        systemInstructions: [String],
        userInstructions: [String],
        responseSchemaDescription: String? = nil,
        languageCode: String,
        maximumOutputTokens: Int? = nil,
        temperature: Double? = nil,
        identity: ProviderRequestIdentity
    ) {
        self.operation = operation
        self.modelTier = modelTier
        self.systemInstructions = systemInstructions
        self.userInstructions = userInstructions
        self.responseSchemaDescription = responseSchemaDescription
        self.languageCode = languageCode
        self.maximumOutputTokens = maximumOutputTokens
        self.temperature = temperature
        self.identity = identity
    }

    public var idempotencyKey: String { identity.idempotencyKey }

    public var systemPrompt: String { systemInstructions.joined(separator: "\n\n") }
    public var userPrompt: String { userInstructions.joined(separator: "\n\n") }
}

public struct AICompletionResponse: Sendable, Hashable {
    public let text: String
    public let usage: AIUsage

    public init(text: String, usage: AIUsage) {
        self.text = text
        self.usage = usage
    }
}

/// The language-model boundary.
///
/// One method, deliberately. Everything the engine wants from an LLM is
/// "instructions in, text out, with the cost attached" — which is what keeps
/// swapping Gemini for something else an adapter change rather than an engine
/// change.
///
/// **This is not the story-production boundary, and the names invite that
/// mistake.** D1 describes `StoryProvider` with `OfflineTemplateAIProvider`,
/// `OnDeviceAIProvider` and `RemoteAIProvider` under it — a seam over *how a
/// book gets made*. This protocol is a seam over *how a sentence gets
/// generated*, and the offline path never crosses it: `OfflineStoryComposer`
/// writes from an authored corpus and asks no model anything. Implementing
/// "OfflineTemplateAIProvider" as a `StoryAIProvider` would mean wrapping a
/// deterministic composer in a completion API it has no use for.
///
/// The D1 seam belongs one level up, in the app bridge, where the views
/// currently name `OfflineStoryService` directly. See
/// `docs/MagicPaper_Story_Engine_Plan.md` §5.5 (Dalga 0.4) for its shape.
///
/// Adapters must classify their failures as `StoryEngineError.providerFailed`
/// with an `ErrorClass`; the retry policy has no other way to tell a timeout
/// from a refusal.
public protocol StoryAIProvider: Sendable {
    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse
}
