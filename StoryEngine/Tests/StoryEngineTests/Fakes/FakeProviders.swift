import Foundation
@testable import StoryEngine

/// What a scripted provider should do for one call.
enum ScriptedResult: Sendable {
    case success(String)
    case failure(ErrorClass, String)

    static let transient = ScriptedResult.failure(.transient, "temporary upstream failure")
    static let permanent = ScriptedResult.failure(.permanent, "request rejected")
    static let rateLimited = ScriptedResult.failure(.rateLimited, "slow down")
}

/// A language-model provider that returns whatever the test tells it to, and
/// remembers everything it was asked.
final class FakeStoryAIProvider: StoryAIProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var scriptByOperation: [AIOperation: [ScriptedResult]]
    private var fallback: (@Sendable (AICompletionRequest) -> ScriptedResult)?
    private(set) var requests: [AICompletionRequest] = []
    var usageTemplate: AIUsage

    init(
        script: [AIOperation: [ScriptedResult]] = [:],
        fallback: (@Sendable (AICompletionRequest) -> ScriptedResult)? = nil,
        usage: AIUsage = AIUsage(
            provider: "fake",
            model: "fake-1",
            operation: .outline,
            inputTokens: 100,
            outputTokens: 200,
            estimatedCostUSD: 0.01,
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    ) {
        self.scriptByOperation = script
        self.fallback = fallback
        self.usageTemplate = usage
    }

    var callCount: Int { lock.lock(); defer { lock.unlock() }; return requests.count }

    func callCount(for operation: AIOperation) -> Int {
        lock.lock(); defer { lock.unlock() }
        return requests.filter { $0.operation == operation }.count
    }

    func requests(for operation: AIOperation) -> [AICompletionRequest] {
        lock.lock(); defer { lock.unlock() }
        return requests.filter { $0.operation == operation }
    }

    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        lock.lock()
        requests.append(request)
        let scripted: ScriptedResult
        if var queue = scriptByOperation[request.operation], !queue.isEmpty {
            scripted = queue.removeFirst()
            scriptByOperation[request.operation] = queue
        } else if let fallback {
            scripted = fallback(request)
        } else {
            scripted = .failure(.permanent, "no scripted response for \(request.operation.rawValue)")
        }
        let usage = AIUsage(
            provider: usageTemplate.provider,
            model: usageTemplate.model,
            operation: request.operation,
            inputTokens: usageTemplate.inputTokens,
            outputTokens: usageTemplate.outputTokens,
            estimatedCostUSD: usageTemplate.estimatedCostUSD,
            latency: usageTemplate.latency,
            requestID: request.idempotencyKey,
            recordedAt: usageTemplate.recordedAt
        )
        lock.unlock()

        switch scripted {
        case .success(let text):
            return AICompletionResponse(text: text, usage: usage)
        case .failure(let errorClass, let message):
            throw StoryEngineError.providerFailed(operation: request.operation, errorClass: errorClass, message: message)
        }
    }
}

/// An image provider that counts calls. Most scene-reuse assertions come down
/// to "how many times was this called", so the counter is the point.
final class FakeImageProvider: ImageProvider, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var requests: [ImageGenerationRequest] = []
    private var failures: [ErrorClass]
    var costPerImage: Double

    init(failures: [ErrorClass] = [], costPerImage: Double = 0.04) {
        self.failures = failures
        self.costPerImage = costPerImage
    }

    var callCount: Int { lock.lock(); defer { lock.unlock() }; return requests.count }

    var seeds: [UInt64] {
        lock.lock(); defer { lock.unlock() }
        return requests.map { $0.constraints.seed }
    }

    func generateImage(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        lock.lock()
        requests.append(request)
        let failure = failures.isEmpty ? nil : failures.removeFirst()
        let index = requests.count
        lock.unlock()

        if let failure {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration,
                errorClass: failure,
                message: "image generation failed"
            )
        }

        return ImageGenerationResponse(
            imageRef: ImageRef(
                locator: "image-\(index).png",
                width: 1024,
                height: 768,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            usage: AIUsage(
                provider: "fake-image",
                model: "fake-image-1",
                operation: .imageGeneration,
                imageCount: 1,
                estimatedCostUSD: costPerImage,
                requestID: request.idempotencyKey,
                recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )
    }
}
