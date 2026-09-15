import Foundation
import StoryEngine

/// Deletes the files the engine caused to exist.
///
/// The engine only ever holds locators; this is what turns one into an actual
/// removal. Locators the app stores locally are deleted from
/// `Documents/Stories`; anything that looks like a remote URL is reported as
/// unhandled rather than silently treated as gone, because a photo still
/// sitting in cloud storage after a family asked for deletion is exactly the
/// failure this contract exists to make visible.
struct FileAssetDeleter: AssetDeleting {
    private let fileManager: FileManagerService
    private let remoteDeleter: RemoteAssetDeleting?

    init(fileManager: FileManagerService = .shared, remoteDeleter: RemoteAssetDeleting? = nil) {
        self.fileManager = fileManager
        self.remoteDeleter = remoteDeleter
    }

    func deleteAsset(locator: String) async throws {
        if locator.hasPrefix("http://") || locator.hasPrefix("https://") || locator.hasPrefix("gs://") {
            guard let remoteDeleter else {
                throw DeletionUnsupported.remoteAssetHasNoDeleter(locator)
            }
            try await remoteDeleter.deleteRemoteAsset(at: locator)
            return
        }

        guard let directory = fileManager.getStoriesDirectoryURL() else {
            throw DeletionUnsupported.storageUnavailable
        }
        let url = directory.appendingPathComponent(locator)
        // Already gone counts as deleted: a retried deletion must converge.
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    enum DeletionUnsupported: Error {
        /// Firebase or another remote store owns this file. Wiring that up is
        /// a bridge concern and is deliberately not guessed at here.
        case remoteAssetHasNoDeleter(String)
        case storageUnavailable
    }
}

/// Deleting something the app uploaded to a remote store.
///
/// Left unimplemented in V1: the engine defines the contract, and whoever wires
/// Firebase decides how a stored object is removed.
protocol RemoteAssetDeleting: Sendable {
    func deleteRemoteAsset(at locator: String) async throws
}
