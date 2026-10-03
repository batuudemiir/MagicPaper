import Foundation
import StoryEngine

/// Gemini, behind the engine's `StoryAIProvider` port.
///
/// Deliberately standalone rather than a wrapper around `AIService`: that type
/// resolves its key with `fatalError` and exposes only one story-shaped call,
/// neither of which suits a provider the engine will retry. Nothing in
/// `AIService` is changed, and the two can run side by side.
///
/// The adapter's real job is error classification. `RetryPolicy` has no way to
/// tell a timeout from a refusal unless the adapter says which it was.
struct GeminiStoryAIProvider: StoryAIProvider {
    private let apiKey: String
    private let session: URLSession
    private let baseURL: String
    private let modelsByTier: [ModelTier: String]
    private let pricePerMillionInputTokens: [ModelTier: Double]
    private let pricePerMillionOutputTokens: [ModelTier: Double]

    /// Resolves the key the same way the rest of the app does, but reports a
    /// missing key as a provider error instead of killing the process.
    init?(
        apiKey: String? = nil,
        session: URLSession = .shared,
        baseURL: String = "https://generativelanguage.googleapis.com/v1beta/models",
        modelsByTier: [ModelTier: String] = [
            .fast: "gemini-2.5-flash",
            .balanced: "gemini-2.5-flash",
            .quality: "gemini-2.5-pro"
        ],
        pricePerMillionInputTokens: [ModelTier: Double] = [.fast: 0.30, .balanced: 0.30, .quality: 1.25],
        pricePerMillionOutputTokens: [ModelTier: Double] = [.fast: 2.50, .balanced: 2.50, .quality: 10.00]
    ) {
        guard let resolved = apiKey ?? Self.resolveAPIKey(), !resolved.isEmpty else { return nil }
        self.apiKey = resolved
        self.session = session
        self.baseURL = baseURL
        self.modelsByTier = modelsByTier
        self.pricePerMillionInputTokens = pricePerMillionInputTokens
        self.pricePerMillionOutputTokens = pricePerMillionOutputTokens
    }

    static func resolveAPIKey() -> String? { APIKeys.gemini }

    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        let model = modelsByTier[request.modelTier] ?? "gemini-2.5-flash"
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw StoryEngineError.providerFailed(
                operation: request.operation, errorClass: .permanent, message: "Malformed Gemini URL"
            )
        }

        var userText = request.userPrompt
        if let schema = request.responseSchemaDescription {
            userText += "\n\nReturn JSON only, matching this shape exactly:\n\(schema)"
        }

        var generationConfig: [String: Any] = ["responseMimeType": "application/json"]
        if let temperature = request.temperature { generationConfig["temperature"] = temperature }
        if let maximum = request.maximumOutputTokens { generationConfig["maxOutputTokens"] = maximum }

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": request.systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": userText]]]],
            "generationConfig": generationConfig
        ]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(request.idempotencyKey, forHTTPHeaderField: "X-Request-Id")
        urlRequest.timeoutInterval = 120
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let started = Date()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw StoryEngineError.providerFailed(
                operation: request.operation,
                errorClass: FalImageProvider.classify(transportError: error),
                message: error.localizedDescription
            )
        }

        guard let http = response as? HTTPURLResponse else {
            throw StoryEngineError.providerFailed(
                operation: request.operation, errorClass: .transient, message: "Non-HTTP response"
            )
        }
        guard (200...299).contains(http.statusCode) else {
            throw StoryEngineError.providerFailed(
                operation: request.operation,
                errorClass: FalImageProvider.classify(statusCode: http.statusCode),
                message: "HTTP \(http.statusCode): \(String(data: data, encoding: .utf8)?.prefix(300) ?? "")"
            )
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else {
            throw StoryEngineError.malformedProviderResponse(
                operation: request.operation, detail: "Unexpected Gemini response shape"
            )
        }

        let text = parts.compactMap { $0["text"] as? String }.joined()
        let metadata = json["usageMetadata"] as? [String: Any]
        let inputTokens = metadata?["promptTokenCount"] as? Int ?? 0
        let outputTokens = metadata?["candidatesTokenCount"] as? Int ?? 0

        return AICompletionResponse(
            text: text,
            usage: AIUsage(
                provider: "google",
                model: model,
                operation: request.operation,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                estimatedCostUSD: estimatedCost(tier: request.modelTier, input: inputTokens, output: outputTokens),
                latency: Date().timeIntervalSince(started),
                requestID: request.idempotencyKey,
                recordedAt: Date()
            )
        )
    }

    private func estimatedCost(tier: ModelTier, input: Int, output: Int) -> Double {
        let inputRate = pricePerMillionInputTokens[tier] ?? 0
        let outputRate = pricePerMillionOutputTokens[tier] ?? 0
        return (Double(input) / 1_000_000 * inputRate) + (Double(output) / 1_000_000 * outputRate)
    }
}
