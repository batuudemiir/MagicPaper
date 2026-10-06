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
    /// Every document that went into this catalog, in precedence order.
    ///
    /// `source` names the first one, which is the required document; anything
    /// after it is optional content layered on top. Kept separate so the
    /// existing meaning of `source` does not change.
    public let mergedSources: [String]
    public let decoded: Bool
    public let decodeError: String?
    public let integrity: CatalogIntegrityReport?
    public let loadedAt: Date

    public init(
        source: Source,
        mergedSources: [String] = [],
        decoded: Bool,
        decodeError: String? = nil,
        integrity: CatalogIntegrityReport? = nil,
        loadedAt: Date
    ) {
        self.source = source
        self.mergedSources = mergedSources
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
            let documents = mergedSources.count > 1
                ? " (\(mergedSources.joined(separator: " + ")))"
                : ""
            return "Catalog loaded from \(path)\(documents) — \(integrity?.summary ?? "not checked")"
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
    /// The document that must be present. Absent, there is no catalog at all.
    public static let resourceName = "shared_content_library_v2"

    /// Documents layered on top when they are present, in precedence order.
    ///
    /// The pilot library holds the beat-authored blueprints and the content
    /// carrying traits. Without it nothing in the catalog is selectable under
    /// the beat model — the V1 document has no beats and no traits — so the app
    /// could load a catalog and still be unable to build a single story.
    ///
    /// Optional rather than required: a host that ships only the V1 document
    /// keeps working, and says so in the report rather than failing to launch.
    public static let additionalResourceNames = ["pilot_library_v1"]

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

        guard let url = Self.locate(Self.resourceName, searched: &searched) else {
            throw CatalogLoadError.resourceNotFound(searched: searched)
        }

        let isPackageBundle = url.path.contains("StoryEngine_StoryEngine.bundle")
        let source: CatalogLoadReport.Source = isPackageBundle
            ? .packageBundle(url.lastPathComponent)
            : .otherBundle(url.path)

        var documents: [(name: String, catalog: ContentCatalog)] = [
            (url.lastPathComponent, try Self.read(url))
        ]

        // Optional layers. A missing one is recorded by its absence from
        // `mergedSources`, never by a silent fallback to a catalog that cannot
        // build anything.
        for name in Self.additionalResourceNames {
            var ignored: [String] = []
            guard let extra = Self.locate(name, searched: &ignored) else { continue }
            documents.append((extra.lastPathComponent, try Self.read(extra)))
        }

        // The per-beat prose corpus, authored one file per beat. Layered last so
        // its lines join the pool for the beats it covers; beats it has not
        // reached yet keep the library's own templates.
        // Judged by the integrity checker, not printed. A warning in a log is
        // not being told; a fatal issue is.
        let corpus = BeatCorpusLoader().load()

        var catalog = ContentCatalog.merging(documents.map(\.catalog))
        if !corpus.templates.isEmpty {
            // The corpus **replaces** rather than joins, for the beats it
            // covers. The library's own templates were scaffolding written to
            // get a beat working at all — three variants each, and some of them
            // phrased for the one blueprint they were written beside. Left in
            // the pool they leak: a line about crossing to the other side,
            // written for a Threshold story, turned up as the resolution of a
            // Misreading one.
            let covered = Set(corpus.templates.compactMap(\.realizesBeat))
            let kept = catalog.templates.filter { template in
                template.realizesBeat.map { !covered.contains($0) } ?? true
            }
            catalog = ContentCatalog.merging([
                ContentCatalog(version: catalog.version, templates: corpus.templates),
                ContentCatalog(
                    version: catalog.version,
                    settings: catalog.settings,
                    companions: catalog.companions,
                    objects: catalog.objects,
                    events: catalog.events,
                    challenges: catalog.challenges,
                    endings: catalog.endings,
                    templates: kept,
                    blueprints: catalog.blueprints,
                    storyIdeas: catalog.storyIdeas,
                    storyModes: catalog.storyModes,
                    familyMoments: catalog.familyMoments,
                    familyAnimalKinds: catalog.familyAnimalKinds,
                    interests: catalog.interests
                )
            ])
        }
        let integrity = checker.check(catalog, corpus: corpus)
        let report = CatalogLoadReport(
            source: source,
            mergedSources: documents.map(\.name) + corpus.files,
            decoded: true,
            integrity: integrity,
            loadedAt: clock.now()
        )
        guard integrity.isUsable else {
            throw CatalogLoadError.unusable(report: integrity)
        }
        return Result(catalog: catalog, report: report)
    }

    private static func read(_ url: URL) throws -> ContentCatalog {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CatalogLoadError.unreadable(path: url.path, underlying: String(describing: error))
        }
        do {
            return try JSONDecoder().decode(ContentCatalog.self, from: data)
        } catch {
            throw CatalogLoadError.undecodable(path: url.path, underlying: String(describing: error))
        }
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
            source: source, mergedSources: [path], decoded: true,
            integrity: integrity, loadedAt: clock.now()
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
    static func locate(_ name: String, searched: inout [String]) -> URL? {
        searched.append("Bundle.module")
        if let url = Bundle.module.url(forResource: name, withExtension: resourceExtension) {
            return url
        }

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            let label = bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent
            searched.append(label)
            if let url = bundle.url(forResource: name, withExtension: resourceExtension) {
                return url
            }
        }
        return nil
    }

    /// Kept for callers that only ask about the required document.
    static func locate(searched: inout [String]) -> URL? {
        locate(resourceName, searched: &searched)
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
