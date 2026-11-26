import Foundation
import StoryEngine

/// Internal callers must supply both a repository and an exact source.
/// There is intentionally no production singleton or bundled pilot lookup.
struct P56InternalService {
    static let productionEnabled = false
    let store: P56SnapshotStore

    func prepare(payload: Data, expectedSHA256: String) throws -> P56SourceReference {
        try store.save(payload: payload, expectedSHA256: expectedSHA256)
    }

    func compose(_ request: P56Request, source: P56SourceReference) throws -> P56ComposedStory {
        let package = try store.load(source)
        return try P56StoryComposer(package: package).compose(request)
    }
}
