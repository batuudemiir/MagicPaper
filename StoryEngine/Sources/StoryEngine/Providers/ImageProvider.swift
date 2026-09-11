import Foundation
import VisualSystem

/// An illustration request.
///
/// The instruction is a `VisualConstraintSet` and nothing else: there is no
/// free-text prompt parameter, because there is no path in this engine from
/// arbitrary text to an image model.
public struct ImageGenerationRequest: Sendable, Hashable {
    public let constraints: VisualConstraintSet
    /// Identifies this logical illustration. A retry after a lost response
    /// carries the same identity, which is what stops a family being billed
    /// twice for one picture.
    public let identity: ProviderRequestIdentity

    public init(constraints: VisualConstraintSet, identity: ProviderRequestIdentity) {
        self.constraints = constraints
        self.identity = identity
    }

    public var idempotencyKey: String { identity.idempotencyKey }
}

public struct ImageGenerationResponse: Sendable, Hashable {
    public let imageRef: ImageRef
    public let usage: AIUsage

    public init(imageRef: ImageRef, usage: AIUsage) {
        self.imageRef = imageRef
        self.usage = usage
    }
}

/// The image-model boundary.
///
/// An adapter is responsible for turning the constraint set into its vendor's
/// parameters, for downloading and storing the result, and for returning a
/// locator its own app can resolve. The engine never touches bytes.
public protocol ImageProvider: Sendable {
    func generateImage(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse
}
