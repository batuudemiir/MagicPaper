import Foundation
import CryptoKit
import StoryEngine

/// Explicitly injected internal source archive. Never reads the production
/// catalog or stores a child's rendered pages, name or appearance.
struct P56SnapshotStore {
    enum StoreError: Error { case missing, corrupt, unsupported }

    let root: URL
    var writeAtomically: (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }

    func save(payload: Data, expectedSHA256: String) throws -> P56SourceReference {
        guard Self.digest(payload) == expectedSHA256 else { throw StoreError.corrupt }
        let package = try P56PackageLoader.load(payload: payload, expectedSHA256: expectedSHA256)
        let reference = package.sourceReference
        let destination = try url(for: reference)
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try load(reference)
            return reference
        }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try writeAtomically(payload, destination)
        _ = try load(reference)
        return reference
    }

    func load(_ reference: P56SourceReference) throws -> P56Package {
        let location = try url(for: reference)
        guard FileManager.default.fileExists(atPath: location.path) else { throw StoreError.missing }
        let bytes = try Data(contentsOf: location)
        guard Self.digest(bytes) == reference.payloadSHA256 else { throw StoreError.corrupt }
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: reference.payloadSHA256)
        guard package.sourceReference == reference else { throw StoreError.corrupt }
        return package
    }

    private func url(for reference: P56SourceReference) throws -> URL {
        guard reference.schemaVersion == 1,
              ["five-friends-56-runtime-v1", "five-friends-56-runtime-v2"].contains(reference.packageVersion),
              reference.engineBehaviorID == "offline-p56-v1" else { throw StoreError.unsupported }
        let digest = reference.payloadSHA256
        guard digest.utf8.count == 64,
              digest.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
            throw StoreError.corrupt
        }
        return root.appendingPathComponent(digest + ".p56catalog")
    }

    private static func digest(_ bytes: Data) -> String {
        SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
}
