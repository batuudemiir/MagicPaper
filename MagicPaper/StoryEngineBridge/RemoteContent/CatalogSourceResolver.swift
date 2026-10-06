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

    static func forThisLaunch() -> CatalogSourceResolver {
        CatalogSourceResolver(store: RemoteContentStore(), key: RemoteContentConfig.current()?.key)
    }

    struct Resolved {
        let result: ContentCatalogLoader.Result
        let fromPackage: Bool
    }

    func resolve() throws -> Resolved {
        let bundled = try loader.load()
        guard let key else { return Resolved(result: bundled, fromPackage: false) }

        store.promoteStaged()
        guard let package = store.activePackage else { return Resolved(result: bundled, fromPackage: false) }

        guard let reference = store.feed(key: key)?.catalogPackage, reference.matches(package) else {
            logger.notice("İçerik paketi akışla eşleşmiyor; paketle gelen katalog kullanılıyor")
            store.removeActive()
            return Resolved(result: bundled, fromPackage: false)
        }
        guard let loaded = try? loader.load(package: package) else {
            logger.error("🛑 İçerik paketi \(reference.version, privacy: .public) yüklenemedi")
            store.removeActive()
            return Resolved(result: bundled, fromPackage: false)
        }
        let verdict = RemoteCatalogPolicy.evaluate(package: loaded, bundled: bundled)
        guard verdict == .accept else {
            logger.notice("İçerik paketi \(reference.version, privacy: .public) kullanılmıyor: \(String(describing: verdict), privacy: .public)")
            store.removeActive()
            return Resolved(result: bundled, fromPackage: false)
        }
        logger.info("İçerik paketi \(reference.version, privacy: .public) kullanılıyor")
        return Resolved(result: loaded, fromPackage: true)
    }
}
