import Foundation
import EngineFoundation

/// The catalog as it travels after the app has shipped (FAZ 15).
///
/// A package is the **complete source set** — every library document and every
/// beat file the bundle carries — not a patch. The device runs it through the
/// same `assemble` road the bundle takes, so a package cannot mean anything the
/// bundle could not; there are no overlay rules to get wrong.
///
/// ```json
/// { "schemaVersion": 2, "version": "2.0.1",
///   "libraries": [ { "name": "shared_content_library_v2.json", "content": { … } } ],
///   "beats":     [ { "name": "beat_warm_close.json",           "content": { … } } ] }
/// ```
///
/// Data only. Nothing in it is executed; everything in it is decoded by the
/// types that decode the bundle.
public enum ContentPackage {
    /// The package format this engine reads. Raised when content needs engine
    /// code an older app does not have — an older app then keeps its bundle.
    ///
    /// The number is a **capability claim, not a date**: it says "the records in
    /// here may use everything the engine at this version understands". The app
    /// compares it before downloading (`RemoteContentService`) and the loader
    /// compares it again after, and both want it exactly equal — so raising it
    /// is also what keeps a *new* app from reading an *old* package whose
    /// records it would silently reinterpret.
    ///
    /// - 1: FAZ 15, the first package format.
    /// - 2: `refrain` (`RefrainSpec` on a blueprint, 15 Ekim 2026). An app
    ///   without that field decodes the blueprint and drops the repeated line,
    ///   which is the whole of the `p_repeated_line` experiment: it would show
    ///   the variant arm as if it were the control and quietly ruin the
    ///   measurement. A refused package is a child reading the shipped
    ///   catalog — a wrong answer in the data is worse than no answer.
    public static let currentSchemaVersion = 2

    /// One named document inside a package.
    public struct File: Sendable {
        public let name: String
        public let data: Data

        public init(name: String, data: Data) {
            self.name = name
            self.data = data
        }
    }

    /// Writes a package. Keys are sorted, so the same sources always give the
    /// same bytes — and the same digest in the signed feed.
    public static func build(version: String, libraries: [File], beats: [File]) throws -> Data {
        func entries(_ files: [File]) throws -> [[String: Any]] {
            try files.map { file in
                ["name": file.name, "content": try JSONSerialization.jsonObject(with: file.data)]
            }
        }
        let document: [String: Any] = [
            "schemaVersion": currentSchemaVersion,
            "version": version,
            "libraries": try entries(libraries),
            "beats": try entries(beats),
        ]
        return try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    }

    /// The documents the bundle loads, in the order it loads them. What a
    /// package built from this app's own content would carry.
    public static func bundledSources() -> (libraries: [File], beats: [File]) {
        var libraries: [File] = []
        for name in [ContentCatalogLoader.resourceName] + ContentCatalogLoader.additionalResourceNames {
            var ignored: [String] = []
            guard let url = ContentCatalogLoader.locate(name, searched: &ignored),
                  let data = try? Data(contentsOf: url) else { continue }
            libraries.append(File(name: url.lastPathComponent, data: data))
        }
        let beatURLs = (Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("beat_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let beats = beatURLs.compactMap { url in
            (try? Data(contentsOf: url)).map { File(name: url.lastPathComponent, data: $0) }
        }
        return (libraries, beats)
    }
}

extension ContentCatalogLoader {
    /// Loads a content package through the bundle's own merge and check.
    ///
    /// Throws for a format this engine does not read, for a package whose
    /// declared version is not the version its documents carry, and for
    /// everything `load()` throws for. Whether a package that *loads* should
    /// also be *used* is `RemoteCatalogPolicy`'s question, not this one's.
    public func load(package data: Data) throws -> Result {
        let path = "<package>"
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw CatalogLoadError.undecodable(path: path, underlying: "not a JSON object")
        }
        let schema = root["schemaVersion"] as? Int ?? -1
        guard schema == ContentPackage.currentSchemaVersion else {
            throw CatalogLoadError.unsupportedSchema(found: schema, supported: ContentPackage.currentSchemaVersion)
        }
        guard let version = root["version"] as? String, SemanticVersion(version) != nil else {
            throw CatalogLoadError.undecodable(path: path, underlying: "no semantic version")
        }

        func files(_ key: String) throws -> [(name: String, data: Data)] {
            guard let entries = root[key] as? [[String: Any]] else {
                throw CatalogLoadError.undecodable(path: path, underlying: "no \(key)")
            }
            return try entries.map { entry in
                guard let name = entry["name"] as? String, let content = entry["content"],
                      JSONSerialization.isValidJSONObject(content) else {
                    throw CatalogLoadError.undecodable(path: path, underlying: "a \(key) entry is malformed")
                }
                return (name, try JSONSerialization.data(withJSONObject: content))
            }
        }

        let libraries = try files("libraries")
        guard !libraries.isEmpty else {
            throw CatalogLoadError.undecodable(path: path, underlying: "no libraries")
        }
        let documents: [(name: String, catalog: ContentCatalog)] = try libraries.map { file in
            do {
                return (file.name, try JSONDecoder().decode(ContentCatalog.self, from: file.data))
            } catch {
                throw CatalogLoadError.undecodable(path: file.name, underlying: String(describing: error))
            }
        }
        let corpus = BeatCorpusLoader().load(files: try files("beats").map { ($0.name, Optional($0.data)) })

        let result = try assemble(documents: documents, corpus: corpus, source: .remotePackage(version))
        // The version the feed names and the version a saved story records
        // must be one and the same, or a story could not say what wrote it.
        guard result.catalog.version == version else {
            throw CatalogLoadError.undecodable(
                path: path, underlying: "declares \(version), its documents say \(result.catalog.version)")
        }
        return result
    }
}

/// Whether a package that loaded should replace the bundled catalog.
///
/// `CatalogIntegrity` lets errors through on purpose: bundled content with a
/// known flaw should still build stories. A package is held to more — it may
/// not bring a single error the bundle does not already have — because a
/// package nobody has seen on a phone yet is exactly where a new flaw would be.
public enum RemoteCatalogPolicy {
    public enum Verdict: Sendable, Equatable {
        case accept
        /// Not newer than what the app carries. An app update that ships the
        /// same or newer content retires an older download this way.
        case notNewer(package: String, bundled: String)
        /// Errors the bundle does not have, as `code recordID`.
        case newIssues([String])
    }

    public static func evaluate(
        package: ContentCatalogLoader.Result,
        bundled: ContentCatalogLoader.Result
    ) -> Verdict {
        let packageVersion = package.catalog.version
        let bundledVersion = bundled.catalog.version
        guard let new = SemanticVersion(packageVersion), let old = SemanticVersion(bundledVersion), new > old else {
            return .notNewer(package: packageVersion, bundled: bundledVersion)
        }

        func blocking(_ result: ContentCatalogLoader.Result) -> [String] {
            (result.report.integrity?.issues ?? [])
                .filter { $0.severity == .error || $0.severity == .fatal }
                .map { "\($0.code) \($0.recordID?.rawValue ?? "-")" }
        }
        let known = Set(blocking(bundled))
        let fresh = Array(Set(blocking(package)).subtracting(known)).sorted()
        return fresh.isEmpty ? .accept : .newIssues(fresh)
    }
}
