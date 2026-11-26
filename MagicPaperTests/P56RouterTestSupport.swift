import Foundation
import StoryEngine
@testable import MagicPaper

/// Test fixtures hand the router an already-decoded package; the payload bytes
/// matter only to the archive, which these routers either skip or stub.
extension P56VerifiedSource {
    init(_ pair: (P56SourceReference, P56Package), payload: Data = Data()) {
        self.init(reference: pair.0, package: pair.1, payload: payload)
    }
}
