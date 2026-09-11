import Foundation
@testable import StoryEngine

/// Records what the engine asked to have deleted, and can refuse on demand.
///
/// An actor rather than a locked class: it is only ever touched from async
/// code, and `NSLock` in an async context is an error under the Swift 6
/// language mode.
actor RecordingAssetDeleter: AssetDeleting {
    private(set) var deleted: [String] = []
    private let unreachable: Set<String>

    init(unreachable: Set<String> = []) { self.unreachable = unreachable }

    func deleteAsset(locator: String) async throws {
        guard !unreachable.contains(locator) else {
            throw StoryEngineError.providerFailed(
                operation: .imageGeneration, errorClass: .transient, message: "storage unreachable"
            )
        }
        deleted.append(locator)
    }
}
