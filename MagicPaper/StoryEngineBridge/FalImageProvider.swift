import Foundation
import UIKit
import StoryEngine
import VisualSystem

/// fal.ai, behind the engine's `ImageProvider` port.
///
/// Turns a `VisualConstraintSet` into the vendor's parameters, downloads the
/// result, and stores it through the app's existing `FileManagerService` so
/// illustrations land exactly where the rest of the app already looks for them.
/// The engine only ever sees the returned filename.
struct FalImageProvider: ImageProvider {
    private let apiKey: String
    private let endpoint: String
    private let session: URLSession
    private let fileManager: FileManagerService
    private let costPerImageUSD: Double

    init?(
        apiKey: String? = nil,
        endpoint: String = "https://fal.run/fal-ai/gemini-25-flash-image/edit",
        session: URLSession = .shared,
        fileManager: FileManagerService = .shared,
        costPerImageUSD: Double = 0.04
    ) {
        guard let resolved = apiKey ?? Self.resolveAPIKey(), !resolved.isEmpty else { return nil }
        self.apiKey = resolved
        self.endpoint = endpoint
        self.session = session
        self.fileManager = fileManager
        self.costPerImageUSD = costPerImageUSD
    }

    /// Reads the key from configuration rather than from source.
    ///
    /// The legacy `FalAIImageGenerator` no longer carries its own copy of the
    /// key; both paths now read `APIKeys.fal`, so there is one place to rotate.
    static func resolveAPIKey() -> String? { APIKeys.fal }

    func generateImage(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        let constraints = request.constraints
        guard let url = URL(string: endpoint) else {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration, errorClass: .permanent, message: "Malformed fal.ai URL"
            )
        }

        var parameters: [String: Any] = [
            "prompt": constraints.positivePrompt,
            "negative_prompt": constraints.negativePrompt,
            // The engine derives seeds deterministically, so the same page
            // redraws identically unless a reroll was explicitly asked for.
            "seed": Int(truncatingIfNeeded: constraints.seed),
            "aspect_ratio": Self.aspectRatioParameter(constraints.aspectRatio)
        ]
        if !constraints.referenceLocators.isEmpty {
            parameters["image_urls"] = constraints.referenceLocators
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(request.idempotencyKey, forHTTPHeaderField: "X-Request-Id")
        urlRequest.timeoutInterval = 180
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let started = Date()
        let (data, response) = try await perform(urlRequest)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration,
                errorClass: Self.classify(statusCode: code),
                message: "HTTP \(code): \(String(data: data, encoding: .utf8)?.prefix(300) ?? "")"
            )
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let images = json["images"] as? [[String: Any]],
            let remote = images.first?["url"] as? String
        else {
            throw StoryEngineError.malformedProviderResponse(
                operation: .imageGeneration, detail: "No image URL in fal.ai response"
            )
        }

        let locator = try await downloadAndStore(remote: remote, idempotencyKey: request.idempotencyKey)
        let stored = fileManager.loadImage(fileName: locator)

        return ImageGenerationResponse(
            imageRef: ImageRef(
                locator: locator,
                width: stored.map { Int($0.size.width) },
                height: stored.map { Int($0.size.height) },
                createdAt: Date()
            ),
            usage: AIUsage(
                provider: "fal.ai",
                model: "gemini-25-flash-image-edit",
                operation: .imageGeneration,
                imageCount: 1,
                estimatedCostUSD: costPerImageUSD,
                latency: Date().timeIntervalSince(started),
                requestID: request.idempotencyKey,
                recordedAt: Date()
            )
        )
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration,
                errorClass: Self.classify(transportError: error),
                message: error.localizedDescription
            )
        }
    }

    /// Stores the image where the app already keeps illustrations, and hands
    /// back the filename the rest of the app resolves.
    private func downloadAndStore(remote: String, idempotencyKey: String) async throws -> String {
        guard let url = URL(string: remote) else {
            throw StoryEngineError.malformedProviderResponse(
                operation: .imageGeneration, detail: "Unusable image URL"
            )
        }

        let data: Data
        do {
            let (downloaded, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw StoryEngineError.providerFailed(
                    operation: .imageGeneration,
                    errorClass: Self.classify(statusCode: http.statusCode),
                    message: "Image download returned HTTP \(http.statusCode)"
                )
            }
            data = downloaded
        } catch let error as StoryEngineError {
            throw error
        } catch {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration,
                errorClass: Self.classify(transportError: error),
                message: "Image download failed: \(error.localizedDescription)"
            )
        }

        let fileName = "se-\(idempotencyKey).jpg"
        guard let saved = fileManager.saveImage(data: data, fileName: fileName) else {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration, errorClass: .transient, message: "Could not write image to disk"
            )
        }
        return saved
    }

    static func aspectRatioParameter(_ ratio: AspectRatio) -> String {
        switch ratio {
        case .square: return "1:1"
        case .portrait: return "3:4"
        case .landscape: return "4:3"
        case .wideLandscape: return "16:9"
        }
    }

    static func classify(statusCode: Int) -> ErrorClass {
        switch statusCode {
        case 429: return .rateLimited
        case 500...599: return .transient
        case 408: return .transient
        default: return .permanent
        }
    }

    static func classify(transportError: Error) -> ErrorClass {
        guard let urlError = transportError as? URLError else { return .transient }
        switch urlError.code {
        case .cancelled: return .cancelled
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .transient
        case .badURL, .unsupportedURL: return .permanent
        default: return .transient
        }
    }
}
