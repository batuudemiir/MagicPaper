import Foundation

/// The only route from the engine to a language model.
///
/// Owns three things no caller should have to repeat: the budget check that
/// happens *before* the call, the retry loop, and turning whatever the model
/// said into a typed value. Planners and writers describe what they want; this
/// decides whether it is affordable and whether a failure is worth another go.
public struct StoryAIService: Sendable {
    private let provider: StoryAIProvider
    private let budget: GenerationBudgetManager
    private let policy: RetryPolicy
    private let clock: Clock
    private let idGenerator: IDGenerator
    private let cache: ProviderResultCache?
    private let limiter: GenerationConcurrencyLimiter?

    public init(
        provider: StoryAIProvider,
        budget: GenerationBudgetManager,
        policy: RetryPolicy,
        clock: Clock,
        idGenerator: IDGenerator = RandomIDGenerator(),
        cache: ProviderResultCache? = nil,
        limiter: GenerationConcurrencyLimiter? = nil
    ) {
        self.provider = provider
        self.budget = budget
        self.policy = policy
        self.clock = clock
        self.idGenerator = idGenerator
        self.cache = cache
        self.limiter = limiter
    }

    public struct Result<Value: Sendable>: Sendable {
        public let value: Value
        public let attempts: [StoryGenerationAttempt]
        public let rawText: String
    }

    /// Runs a completion and decodes the JSON it produced.
    public func complete<Value: Decodable & Sendable>(
        _ request: AICompletionRequest,
        stage: JobStage,
        estimate: UsageEstimate,
        decoding: Value.Type
    ) async throws -> Result<Value> {
        let outcome = try await RetryRunner(policy: policy, clock: clock, idGenerator: idGenerator)
            .run(stage: stage) { () -> ((Value, String), AIUsage?) in
                // Reserved per attempt: a retry costs real money too, and a
                // budget that only counts the first try is not a budget.
                let reservation = try await budget.reserve(estimate)
                do {
                    let response = try await send(request)
                    if !response.wasCached {
                        await budget.commit(reservation, usage: response.value.usage)
                    } else {
                        await budget.release(reservation)
                    }
                    let decoded = try Self.decode(Value.self, from: response.value.text, operation: request.operation)
                    return ((decoded, response.value.text), response.wasCached ? nil : response.value.usage)
                } catch let error as StoryEngineError {
                    if case .malformedProviderResponse = error {
                        // The call happened and was paid for; only the parse failed.
                        throw error
                    }
                    await budget.release(reservation)
                    throw error
                } catch {
                    await budget.release(reservation)
                    throw error
                }
            }

        return Result(value: outcome.value.0, attempts: outcome.attempts, rawText: outcome.value.1)
    }

    /// Runs a completion and returns the text as-is.
    public func completeText(
        _ request: AICompletionRequest,
        stage: JobStage,
        estimate: UsageEstimate
    ) async throws -> Result<String> {
        let outcome = try await RetryRunner(policy: policy, clock: clock, idGenerator: idGenerator)
            .run(stage: stage) { () -> (String, AIUsage?) in
                let reservation = try await budget.reserve(estimate)
                do {
                    let response = try await send(request)
                    if !response.wasCached {
                        await budget.commit(reservation, usage: response.value.usage)
                    } else {
                        await budget.release(reservation)
                    }
                    return (response.value.text, response.wasCached ? nil : response.value.usage)
                } catch {
                    await budget.release(reservation)
                    throw error
                }
            }
        return Result(value: outcome.value, attempts: outcome.attempts, rawText: outcome.value)
    }

    /// Sends the request, or returns what the same logical request already
    /// produced.
    ///
    /// The reuse case that matters is a retry after a lost response: the model
    /// answered, the reply never arrived, and paying again would be pure waste.
    private func send(_ request: AICompletionRequest) async throws -> (value: AICompletionResponse, wasCached: Bool) {
        if let cache, let cached = await cache.completion(for: request.identity) {
            return (cached, true)
        }
        let response: AICompletionResponse
        if let limiter {
            response = try await limiter.withSlot(.aiRequest) { try await provider.complete(request) }
        } else {
            response = try await provider.complete(request)
        }
        await cache?.store(response, for: request.identity)
        return (response, false)
    }

    public func canAfford(_ estimate: UsageEstimate) async -> Bool {
        await budget.canAfford(estimate)
    }

    public var ledger: UsageLedger {
        get async { await budget.currentLedger }
    }

    // MARK: - Parsing

    /// Pulls JSON out of whatever the model wrapped it in.
    ///
    /// Models fence their output, apologise before it, and add a sentence
    /// afterwards. Being lenient here is worth it; being lenient about the
    /// *shape* is not, so the decode itself stays strict.
    static func decode<Value: Decodable>(_ type: Value.Type, from text: String, operation: AIOperation) throws -> Value {
        let json = extractJSON(from: text)
        guard let data = json.data(using: .utf8), !json.isEmpty else {
            throw StoryEngineError.malformedProviderResponse(operation: operation, detail: "no JSON found in response")
        }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            throw StoryEngineError.malformedProviderResponse(
                operation: operation,
                detail: String(describing: error)
            )
        }
    }

    static func extractJSON(from text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let fenceStart = trimmed.range(of: "```") {
            let afterFence = trimmed[fenceStart.upperBound...]
            let body = afterFence.hasPrefix("json")
                ? afterFence.dropFirst("json".count)
                : afterFence
            if let fenceEnd = body.range(of: "```") {
                trimmed = String(body[..<fenceEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                trimmed = String(body).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let objectStart = trimmed.firstIndex(of: "{")
        let arrayStart = trimmed.firstIndex(of: "[")
        let start: String.Index?
        let terminator: Character
        switch (objectStart, arrayStart) {
        case let (object?, array?):
            if object < array { start = object; terminator = "}" } else { start = array; terminator = "]" }
        case let (object?, nil): start = object; terminator = "}"
        case let (nil, array?): start = array; terminator = "]"
        default: return ""
        }

        guard let start, let end = trimmed.lastIndex(of: terminator), start <= end else { return "" }
        return String(trimmed[start...end])
    }
}
