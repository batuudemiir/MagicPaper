import Foundation
import CryptoKit
import StoryEngine

/// Immutable, content-addressed full packages. There is no mutable index to
/// corrupt and no dependency on the remote candidate/active cache lifecycle.
struct CatalogSnapshotStore {
    enum StoreError: Error { case missing, corrupt, unsupported }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CatalogHistory", isDirectory: true)
    }
    static var shared: CatalogSnapshotStore { CatalogSnapshotStore() }

    let root: URL
    var loader: ContentCatalogLoader
    /// Injectable atomic writer permits disk-full/interruption tests.
    var writeAtomically: (Data, URL) throws -> Void

    init(root: URL = Self.defaultDirectory, loader: ContentCatalogLoader = ContentCatalogLoader(),
         writeAtomically: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) {
        self.root = root
        self.loader = loader
        self.writeAtomically = writeAtomically
    }

    /// Caller must have established trust from bundled bytes or a verified
    /// signed feed. This API computes identity; it never trusts an incoming SHA.
    func saveVerified(payload: Data) throws -> ContentSourceReference {
        try validateSourceSet(payload)
        let loaded = try loader.load(package: payload)
        let reference = try ContentSourceReference(catalogVersion: loaded.catalog.version,
                                                  payloadSHA256: Self.digest(payload))
        let destination = url(for: reference)
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try load(reference)
            return reference
        }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try writeAtomically(payload, destination)
        _ = try load(reference)
        return reference
    }

    func load(_ reference: ContentSourceReference) throws -> ContentCatalogLoader.Result {
        guard reference.isSupported else { throw StoreError.unsupported }
        let path = url(for: reference)
        guard FileManager.default.fileExists(atPath: path.path) else { throw StoreError.missing }
        let payload = try Data(contentsOf: path)
        return try validate(payload: payload, reference: reference)
    }

    func load(reference: ContentSourceReference) throws -> ContentCatalogLoader.Result { try load(reference) }

    func validate(payload: Data, reference: ContentSourceReference) throws -> ContentCatalogLoader.Result {
        guard reference.isSupported else { throw StoreError.unsupported }
        guard Self.digest(payload) == reference.payloadSHA256 else { throw StoreError.corrupt }
        try validateSourceSet(payload)
        let loaded = try loader.load(package: payload)
        guard loaded.catalog.version == reference.catalogVersion else { throw StoreError.corrupt }
        return loaded
    }

    func eraseAll() throws {
        if FileManager.default.fileExists(atPath: root.path) { try FileManager.default.removeItem(at: root) }
    }

    static func digest(_ payload: Data) -> String {
        SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    private func url(for reference: ContentSourceReference) -> URL {
        root.appendingPathComponent(reference.payloadSHA256 + ".mpcatalog")
    }

    private func validateSourceSet(_ payload: Data) throws {
        guard let document = try JSONSerialization.jsonObject(with: payload) as? [String: Any],
              let libraries = document["libraries"] as? [[String: Any]],
              let beats = document["beats"] as? [[String: Any]], !beats.isEmpty else { throw StoreError.corrupt }
        let libraryNames = libraries.compactMap { $0["name"] as? String }
        let beatNames = beats.compactMap { $0["name"] as? String }
        let allowed = ([ContentCatalogLoader.resourceName] + ContentCatalogLoader.additionalResourceNames).map { $0 + ".json" }
        guard libraryNames.count == libraries.count, beatNames.count == beats.count,
              libraryNames.first == allowed.first,
              libraryNames == allowed.filter({ libraryNames.contains($0) }),
              Set(libraryNames).count == libraryNames.count, Set(beatNames).count == beatNames.count,
              beatNames.allSatisfy({ $0.hasPrefix("beat_") && $0.hasSuffix(".json") && !$0.contains("/") }) else {
            throw StoreError.corrupt
        }
    }
}
