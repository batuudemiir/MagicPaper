import Foundation
import StoryEngine

/// Historical lookup never consults current-selection policy or substitutes an
/// equal-semver catalog. Saved pages need no resolver; only rewriting does.
struct HistoricalCatalogResolver {
    /// A restore can use this app's exact shipped bytes without selecting the
    /// current remote package or writing a new story first.
    static func forThisBuild(store: CatalogSnapshotStore = .shared) -> Self {
        Self(store: store, bundledPayload: shippedPayload)
    }

    private static let shippedPayload: Data? = {
        let sources = ContentPackage.bundledSources()
        guard let loaded = try? ContentCatalogLoader().load() else { return nil }
        let names = sources.libraries.map(\.name) + sources.beats.map(\.name)
        guard names.count == Set(names).count, Set(names) == Set(loaded.report.mergedSources) else { return nil }
        return try? ContentPackage.build(version: loaded.catalog.version,
                                        libraries: sources.libraries, beats: sources.beats)
    }()

    enum Resolution {
        case exact(ContentCatalogLoader.Result, ContentSourceReference)
        case verifiedLegacy(ContentCatalogLoader.Result, ContentSourceReference)
        case missing
        case ambiguous
        case unsupported
        case corrupt
    }

    let store: CatalogSnapshotStore
    let bundledPayload: Data?
    let compatibility: LegacyCatalogCompatibility

    init(store: CatalogSnapshotStore = .shared, bundledPayload: Data? = nil,
         compatibility: LegacyCatalogCompatibility = .empty) {
        self.store = store
        self.bundledPayload = bundledPayload
        self.compatibility = compatibility
    }

    func resolve(metadata: ContentSourceMetadata) -> Resolution {
        switch metadata.status {
        case .unsupported: return .unsupported
        case .malformed: return .corrupt
        case .known:
            guard let reference = metadata.reference else { return .corrupt }
            return resolve(reference: reference)
        }
    }

    func resolve(reference: ContentSourceReference) -> Resolution {
        guard reference.isSupported else { return .unsupported }
        do { return .exact(try store.load(reference), reference) }
        catch CatalogSnapshotStore.StoreError.missing {
            guard let bundledPayload, CatalogSnapshotStore.digest(bundledPayload) == reference.payloadSHA256 else {
                return .missing
            }
            do { return .exact(try store.validate(payload: bundledPayload, reference: reference), reference) }
            catch { return .corrupt }
        } catch { return .corrupt }
    }

    func resolveLegacy(catalogVersion: String) -> Resolution {
        let candidates = compatibility.candidates(catalogVersion: catalogVersion)
        guard !candidates.isEmpty else { return .missing }
        guard candidates.count == 1 else { return .ambiguous }
        let reference = candidates[0]
        guard reference.catalogVersion == catalogVersion else { return .corrupt }
        switch resolve(reference: reference) {
        case .exact(let result, let exact): return .verifiedLegacy(result, exact)
        case .verifiedLegacy: return .corrupt
        case .missing: return .missing
        case .ambiguous: return .ambiguous
        case .unsupported: return .unsupported
        case .corrupt: return .corrupt
        }
    }
}
