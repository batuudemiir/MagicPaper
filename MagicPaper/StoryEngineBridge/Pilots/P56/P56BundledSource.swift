import Foundation
import StoryEngine

/// The P56 payload that ships with the app (B2, beş arkadaş B hattı).
///
/// The bytes are a verbatim copy of `Content/Pilots/five-friends-56-runtime-v1/payload.json`
/// and must hash to `P56PinnedSource.sha256`. Loading archives them in the
/// P56 snapshot store and returns the verified reference. A missing or altered
/// payload is an error: the caller (B3) then writes with the legacy engine and
/// records why; nothing substitutes current content for this source.
struct P56BundledSource {
    enum SourceError: Error, Equatable { case missingResource }

    /// The shipped package. When C2 v2 lands, Codex's pinned package version
    /// replaces this constant; v1 stays readable from the archive.
    static let packageVersion = "five-friends-56-runtime-v1"
    static let resourceName = packageVersion + ".p56payload"

    static var defaultStoreDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("P56Sources", isDirectory: true)
    }

    static func bundledBytes(in bundle: Bundle = .main) throws -> Data {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw SourceError.missingResource
        }
        return try Data(contentsOf: url)
    }

    private let bytes: () throws -> Data
    private let store: P56SnapshotStore

    init(bytes: @escaping () throws -> Data = { try P56BundledSource.bundledBytes() },
         store: P56SnapshotStore = P56SnapshotStore(root: P56BundledSource.defaultStoreDirectory)) {
        self.bytes = bytes
        self.store = store
    }

    func load() throws -> P56SourceReference {
        try store.save(payload: bytes(), expectedSHA256: P56PinnedSource.sha256)
    }

    /// The pinned bytes verified and decoded once, without touching the
    /// archive: what a decision needs. (B7: arşive yazıp yeniden okumak 3,3 MB'ı
    /// üç kez çözüyordu.) The loader checks the pin itself.
    func loadPackage() throws -> (P56SourceReference, P56Package) {
        let package = try P56PackageLoader.load(payload: bytes(), expectedSHA256: P56PinnedSource.sha256)
        return (package.sourceReference, package)
    }
}
