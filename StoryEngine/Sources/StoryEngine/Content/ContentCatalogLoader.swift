import Foundation

/// Where a catalog came from, and what happened on the way in.
///
/// This exists because of a specific past failure: a "no blueprints" error that
/// nobody could explain, because nothing recorded whether the resource was even
/// found. Every stage is captured, so the answer is always in the record rather
/// than in a debugging session.
public struct CatalogLoadReport: Sendable {
    public enum Source: Sendable, Equatable {
        /// Found in the package's own resource bundle — the expected route.
        case packageBundle(String)
        /// Found in another bundle, searched as a fallback.
        case otherBundle(String)
        /// Supplied directly, e.g. by a test.
        case memory
        case notFound(searched: [String])

        public var isFound: Bool { if case .notFound = self { return false } else { return true } }
    }

    public let source: Source
    public let decoded: Bool
    public let decodeError: String?
    public let integrity: CatalogIntegrityReport?
    public let loadedAt: Date

    public init(
        source: Source,
        decoded: Bool,
        decodeError: String? = nil,
        integrity: CatalogIntegrityReport? = nil,
        loadedAt: Date
    ) {
        self.source = source
        self.decoded = decoded
        self.decodeError = decodeError
        self.integrity = integrity
        self.loadedAt = loadedAt
    }

    /// Readable summary for the development catalog screen and for logs.
    public var summary: String {
        switch source {
        case .notFound(let searched):
            return "Catalog NOT FOUND. Searched: \(searched.joined(separator: ", "))"
        case .packageBundle(let path), .otherBundle(let path):
            guard decoded else { return "Catalog found at \(path) but failed to decode: \(decodeError ?? "unknown")" }
            return "Catalog loaded from \(path) — \(integrity?.summary ?? "not checked")"
        case .memory:
            return "Catalog supplied in memory — \(integrity?.summary ?? "not checked")"
        }
    }
}

public enum CatalogLoadError: Error, Sendable, CustomStringConvertible {
    case resourceNotFound(searched: [String])
    case unreadable(path: String, underlying: String)
    case undecodable(path: String, underlying: String)
    case unusable(report: CatalogIntegrityReport)

    public var description: String {
        switch self {
        case .resourceNotFound(let searched):
            return "Story content could not be found. Searched: \(searched.joined(separator: ", "))"
        case .unreadable(let path, let underlying):
            return "Story content at \(path) could not be read: \(underlying)"
        case .undecodable(let path, let underlying):
            return "Story content at \(path) is not valid: \(underlying)"
        case .unusable(let report):
            return "Story content is unusable: "
                + report.fatals.map(\.message).joined(separator: "; ")
        }
    }
}

/// Reads the catalog and says exactly what it found.
///
/// The package's own bundle is the only expected source. Other bundles are
/// searched as a fallback purely so a host that embeds the JSON differently
/// still works — but there is deliberately **no absolute filesystem path**
/// fallback, because one of those is what currently makes the prototype work on
/// a developer's Mac and fail on a device.
public struct ContentCatalogLoader: Sendable {
    public static let resourceName = "shared_content_library_v2"
    public static let resourceExtension = "json"

    private let checker: CatalogIntegrityChecker
    private let clock: Clock

    public init(checker: CatalogIntegrityChecker = CatalogIntegrityChecker(), clock: Clock = SystemClock()) {
        self.checker = checker
        self.clock = clock
    }

    public struct Result: Sendable {
        public let catalog: ContentCatalog
        public let report: CatalogLoadReport
    }

    /// Loads the bundled catalog, or throws describing precisely what failed.
    public func load() throws -> Result {
        var searched: [String] = []

        guard let url = Self.locate(searched: &searched) else {
            throw CatalogLoadError.resourceNotFound(searched: searched)
        }

        let isPackageBundle = url.path.contains("StoryEngine_StoryEngine.bundle")
        let source: CatalogLoadReport.Source = isPackageBundle
            ? .packageBundle(url.lastPathComponent)
            : .otherBundle(url.path)

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CatalogLoadError.unreadable(path: url.path, underlying: String(describing: error))
        }

        return try decode(data, source: source, path: url.path)
    }

    /// Loads from data already in hand. Used by tests and by any host that
    /// ships the catalog another way.
    public func load(data: Data) throws -> Result {
        try decode(data, source: .memory, path: "<memory>")
    }

    private func decode(_ data: Data, source: CatalogLoadReport.Source, path: String) throws -> Result {
        let catalog: ContentCatalog
        do {
            catalog = try JSONDecoder().decode(ContentCatalog.self, from: data)
        } catch {
            throw CatalogLoadError.undecodable(path: path, underlying: String(describing: error))
        }

        let integrity = checker.check(catalog)
        let report = CatalogLoadReport(
            source: source, decoded: true, integrity: integrity, loadedAt: clock.now()
        )

        // Fatal means the catalog cannot produce a story at all. Errors and
        // warnings are content problems: they are reported and carried, not
        // thrown, so that bad content degrades visibly instead of blocking the
        // whole engine.
        guard integrity.isUsable else {
            throw CatalogLoadError.unusable(report: integrity)
        }

        return Result(catalog: catalog, report: report)
    }

    /// Bundle search order, recorded so a failure names everywhere it looked.
    static func locate(searched: inout [String]) -> URL? {
        searched.append("Bundle.module")
        if let url = Bundle.module.url(forResource: resourceName, withExtension: resourceExtension) {
            return url
        }

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            let label = bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent
            searched.append(label)
            if let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) {
                return url
            }
        }
        return nil
    }
}

/// Where the rest of the engine gets content from.
public protocol ContentCatalogRepository: Sendable {
    func catalog() throws -> ContentCatalog
    func loadReport() -> CatalogLoadReport?
}

/// The shipped catalog, decoded once and reused.
///
/// Loading is idempotent and cheap after the first call; the report is kept so a
/// development screen can show what happened without reloading.
public final class BundledContentCatalogRepository: ContentCatalogRepository, @unchecked Sendable {
    private let loader: ContentCatalogLoader
    private let lock = NSLock()
    private var cached: Result<ContentCatalogLoader.Result, Error>?

    public init(loader: ContentCatalogLoader = ContentCatalogLoader()) {
        self.loader = loader
    }

    public func catalog() throws -> ContentCatalog {
        try resolve().get().catalog
    }

    public func loadReport() -> CatalogLoadReport? {
        try? resolve().get().report
    }

    private func resolve() -> Result<ContentCatalogLoader.Result, Error> {
        lock.lock()
        defer { lock.unlock() }
        if let cached { return cached }
        let outcome = Result { try loader.load() }
        cached = outcome
        return outcome
    }
}

/// A catalog held in memory. For tests and previews.
public struct InMemoryContentCatalogRepository: ContentCatalogRepository {
    private let stored: ContentCatalog
    private let report: CatalogLoadReport?

    public init(_ catalog: ContentCatalog, report: CatalogLoadReport? = nil) {
        self.stored = catalog
        self.report = report
    }

    public func catalog() throws -> ContentCatalog { stored }
    public func loadReport() -> CatalogLoadReport? { report }
}
