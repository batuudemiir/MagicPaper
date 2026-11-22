import Foundation
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "CatalogSource")

/// Which catalog the engine reads this launch: the bundle, or a downloaded
/// package (FAZ 15).
///
/// The bundle always loads first; it is the answer whenever anything about a
/// package is in doubt. A package is used only when all of these hold, checked
/// again on every launch, not trusted from when it was downloaded:
/// - the stored feed's signature still verifies with this build's key,
/// - that feed still names a package, and the bytes hash to its digest,
/// - it loads through the bundle's own merge and integrity check,
/// - `RemoteCatalogPolicy` accepts it against *this* build's bundle — so an
///   app update carrying the same or newer content retires it.
///
/// A package that fails is deleted, so it is not weighed again next launch.
struct CatalogSourceResolver {
    let store: RemoteContentStore
    let key: ContentSigningKey?
    var loader = ContentCatalogLoader()
    var history = CatalogSnapshotStore.shared

    static func forThisLaunch() -> CatalogSourceResolver {
        CatalogSourceResolver(store: RemoteContentStore(), key: RemoteContentConfig.current()?.key)
    }

    struct Resolved {
        let result: ContentCatalogLoader.Result
        let fromPackage: Bool
        let contentSource: ContentSourceMetadata
    }

    func resolve() throws -> Resolved {
        let bundled = try loader.load()
        let sources = ContentPackage.bundledSources()
        let names = sources.libraries.map(\.name) + sources.beats.map(\.name)
        guard names.count == Set(names).count,
              Set(names) == Set(bundled.report.mergedSources),
              Set(sources.libraries.map(\.name)) == Set(
                ([ContentCatalogLoader.resourceName] + ContentCatalogLoader.additionalResourceNames).map { $0 + ".json" }) else {
            throw CatalogSnapshotStore.StoreError.corrupt
        }
        let bundledPayload = try ContentPackage.build(version: bundled.catalog.version,
                                                       libraries: sources.libraries, beats: sources.beats)
        let bundledReference = try history.saveVerified(payload: bundledPayload)
        let fallback = Resolved(result: bundled, fromPackage: false,
                                contentSource: ContentSourceMetadata(bundledReference))
        guard let key else { return fallback }

        store.promoteStaged()
        guard let package = store.activePackage else { return fallback }

        guard let reference = store.feed(key: key)?.catalogPackage, reference.matches(package) else {
            logger.notice("İçerik paketi akışla eşleşmiyor; paketle gelen katalog kullanılıyor")
            store.removeActive()
            return fallback
        }
        guard let loaded = try? loader.load(package: package) else {
            logger.error("🛑 İçerik paketi \(reference.version, privacy: .public) yüklenemedi")
            store.removeActive()
            return fallback
        }
        let verdict = RemoteCatalogPolicy.evaluate(package: loaded, bundled: bundled)
        guard verdict == .accept else {
            logger.notice("İçerik paketi \(reference.version, privacy: .public) kullanılmıyor: \(String(describing: verdict), privacy: .public)")
            store.removeActive()
            return fallback
        }
        logger.info("İçerik paketi \(reference.version, privacy: .public) kullanılıyor")
        let archivedReference = try history.saveVerified(payload: package)
        return Resolved(result: loaded, fromPackage: true,
                        contentSource: ContentSourceMetadata(archivedReference))
    }
}
