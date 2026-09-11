import Foundation
@testable import StoryEngine

/// An image validator the test scripts. Records every context it was handed, so
/// a test can check the validator was given the real source of truth rather
/// than a summary of it.
final class FakeImageValidationProvider: ImageValidationProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var scripted: [ImageValidationResult]
    private var fallback: ImageValidationResult?
    private var thrownError: Error?
    private(set) var contexts: [ImageValidationContext] = []
    private(set) var images: [ImageRef] = []

    init(
        scripted: [ImageValidationResult] = [],
        fallback: ImageValidationResult? = .passed,
        throwing: Error? = nil
    ) {
        self.scripted = scripted
        self.fallback = fallback
        self.thrownError = throwing
    }

    var callCount: Int { lock.lock(); defer { lock.unlock() }; return contexts.count }

    func validate(image: ImageRef, context: ImageValidationContext) async throws -> ImageValidationResult {
        lock.lock()
        contexts.append(context)
        images.append(image)
        let error = thrownError
        let result: ImageValidationResult?
        if !scripted.isEmpty {
            result = scripted.removeFirst()
        } else {
            result = fallback
        }
        lock.unlock()

        if let error { throw error }
        guard let result else {
            throw StoryEngineError.providerFailed(
                operation: .imageValidation, errorClass: .permanent, message: "no scripted result"
            )
        }
        return result
    }

    static let unsafe = ImageValidationResult.failed(observations: [
        ImageValidationObservation(
            finding: .dangerousOrInappropriateContent,
            confidence: 0.95,
            detail: "a sharp object near the child"
        )
    ])

    static let driftedCharacter = ImageValidationResult.failed(observations: [
        ImageValidationObservation(finding: .characterAppearanceDrift, confidence: 0.8, detail: "hair colour differs")
    ])

    static let watermarked = ImageValidationResult.failed(observations: [
        ImageValidationObservation(finding: .textOrWatermarkInImage, confidence: 0.9, detail: "stock watermark")
    ])

    static let cannotTell = ImageValidationResult.uncertain(reason: "image too small to assess", observations: [])
}
