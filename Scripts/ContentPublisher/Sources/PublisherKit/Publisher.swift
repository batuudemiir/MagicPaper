import Foundation
import CryptoKit
import StoryEngine

/// The places the publisher reads and writes, from the repository root.
public struct Repo {
    public let root: URL

    public init(root: URL) { self.root = root }

    /// Walks up from `start` to the folder holding `StoryEngine/Package.swift`.
    public static func find(from start: URL) throws -> Repo {
        var url = start.standardizedFileURL
        while url.path != "/" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("StoryEngine/Package.swift").path) {
                return Repo(root: url)
            }
            url.deleteLastPathComponent()
        }
        throw PublishError.message("Depo kökü bulunamadı (StoryEngine/Package.swift). --repo ile verin.")
    }

    public var stories: URL { root.appendingPathComponent("Content/DailyFeed/stories") }
    public var validatorBaseline: URL { root.appendingPathComponent("Content/validator_baseline.txt") }
    public var validator: URL { root.appendingPathComponent("StoryEngine/Tools/validate_beat_corpus.py") }
    public var hosting: URL { root.appendingPathComponent("hosting") }
    public var content: URL { hosting.appendingPathComponent("public/content") }
    public var catalogFolder: URL { content.appendingPathComponent("catalog") }
    public var feed: URL { content.appendingPathComponent("feed.json") }
    public var signature: URL { content.appendingPathComponent("feed.json.sig") }
    public var appFallback: URL {
        root.appendingPathComponent("MagicPaper/StoryEngineBridge/RemoteContent/daily_feed_fallback.json")
    }
}

/// The Ed25519 key the feed is signed with. The private half lives only on the
/// publisher's machine, never in the repository.
public struct Signer {
    public static let defaultKeyPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".magicpaper/content-signing.key")

    let key: Curve25519.Signing.PrivateKey

    public init(key: Curve25519.Signing.PrivateKey) { self.key = key }

    public init(contentsOf url: URL) throws {
        guard let text = try? String(contentsOf: url, encoding: .utf8),
              let raw = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: raw) else {
            throw PublishError.message("İmza anahtarı okunamadı: \(url.path). Önce `keygen`.")
        }
        self.key = key
    }

    /// Writes a new key, readable only by its owner. Never overwrites one.
    public static func generate(at url: URL) throws -> Signer {
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw PublishError.message("Anahtar zaten var: \(url.path). Silmek tüm yüklü uygulamaların akışı reddetmesi demek.")
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let key = Curve25519.Signing.PrivateKey()
        try Data(key.rawRepresentation.base64EncodedString().utf8).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        return Signer(key: key)
    }

    /// What goes into the app's Info.plist as `MPContentSigningKey`.
    public var publicKeyBase64: String { key.publicKey.rawRepresentation.base64EncodedString() }

    public func signature(for data: Data) throws -> Data {
        Data((try key.signature(for: data).base64EncodedString() + "\n").utf8)
    }

    public static func verify(_ signature: Data, for data: Data, publicKey: String) -> Bool {
        guard let rawKey = Data(base64Encoded: publicKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: rawKey),
              let text = String(data: signature, encoding: .utf8),
              let raw = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return key.isValidSignature(raw, for: data)
    }
}

public enum Digest {
    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

/// Builds and checks catalog packages.
public struct PackageBuilder {
    public init() {}

    /// A package from the engine's bundled sources — exactly what this
    /// checkout's app would ship. The version is the library's own `version`.
    public func build() throws -> (version: String, data: Data) {
        let sources = ContentPackage.bundledSources()
        guard let first = sources.libraries.first,
              let object = try JSONSerialization.jsonObject(with: first.data) as? [String: Any],
              let version = object["version"] as? String else {
            throw PublishError.message("Kütüphane belgesinde sürüm yok.")
        }
        return (version, try ContentPackage.build(version: version, libraries: sources.libraries, beats: sources.beats))
    }

    /// The device's checks, run here first: it loads, it is newer than the
    /// last published package, and it brings no error that one did not have.
    /// With nothing published yet, the bundle is the baseline for errors.
    public func check(_ package: Data, against previous: Data?) throws -> ContentCatalogLoader.Result {
        let loaded: ContentCatalogLoader.Result
        do {
            loaded = try ContentCatalogLoader().load(package: package)
        } catch {
            throw PublishError.message("Paket motorda yüklenmedi: \(error)")
        }
        if let previous {
            let baseline = try ContentCatalogLoader().load(package: previous)
            switch RemoteCatalogPolicy.evaluate(package: loaded, bundled: baseline) {
            case .accept: break
            case .notNewer(let new, let old):
                throw PublishError.message(
                    "Paket \(new), yayımlanmış \(old)'dan yeni değil. shared_content_library_v2.json'daki version'ı artırın.")
            case .newIssues(let issues):
                throw PublishError.invalid(issues.map { "yeni hata: \($0)" })
            }
        } else {
            let bundled = try ContentCatalogLoader().load()
            let known = Set(Self.blocking(bundled))
            let fresh = Self.blocking(loaded).filter { !known.contains($0) }
            guard fresh.isEmpty else { throw PublishError.invalid(fresh.map { "yeni hata: \($0)" }) }
        }
        return loaded
    }

    static func blocking(_ result: ContentCatalogLoader.Result) -> [String] {
        (result.report.integrity?.issues ?? [])
            .filter { $0.severity == .error || $0.severity == .fatal }
            .map { "\($0.code) \($0.recordID?.rawValue ?? "-")" }
    }
}

/// The publishing steps. Each writes files under `hosting/public/content`;
/// nothing leaves the machine unless `deploy` is called.
public struct Publisher {
    public let repo: Repo
    public var log: (String) -> Void = { print($0) }

    public init(repo: Repo) { self.repo = repo }

    // MARK: Validator

    /// `validate_beat_corpus.py` must not report more issues than its recorded
    /// baseline (`Content/validator_baseline.txt`).
    public func runValidator() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", repo.validator.path]
        process.currentDirectoryURL = repo.root.appendingPathComponent("StoryEngine")
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()

        let issues = Self.validatorIssues(output)
        let baseline = (try? String(contentsOf: repo.validatorBaseline, encoding: .utf8))?
            .split(separator: "\n").map(String.init) ?? []
        for line in issues where !baseline.contains(line) { log("  doğrulayıcı (tabanda yok):\(line.dropFirst(3))") }
        guard issues.count <= baseline.count else {
            throw PublishError.message("Doğrulayıcı \(issues.count) bulgu verdi, taban \(baseline.count).")
        }
        log("Doğrulayıcı: \(issues.count) bulgu (taban \(baseline.count)).")
    }

    static func validatorIssues(_ output: String) -> [String] {
        guard let start = output.range(of: "\nFAILED") else { return [] }
        return output[start.upperBound...].split(separator: "\n").map(String.init).filter { $0.hasPrefix("  - ") }
    }

    // MARK: Package

    /// Builds, checks and writes `catalog/<version>.json`. Returns its reference.
    @discardableResult
    public func buildPackage() throws -> PackageReference {
        try runValidator()
        let builder = PackageBuilder()
        let (version, data) = try builder.build()
        let path = "catalog/\(version).json"
        let target = repo.content.appendingPathComponent(path)
        if let existing = try? Data(contentsOf: target) {
            guard existing == data else {
                throw PublishError.message("\(path) zaten yayımlanmış ve içerik farklı. Sürümü artırın.")
            }
            log("\(path) zaten var, aynı içerik.")
            return reference(version: version, path: path, data: data)
        }
        let loaded = try builder.check(data, against: latestPackage()?.data)
        try FileManager.default.createDirectory(at: repo.catalogFolder, withIntermediateDirectories: true)
        try data.write(to: target, options: .atomic)
        log("Paket \(version) yazıldı (\(data.count / 1024) KB): \(loaded.report.integrity?.summary ?? "")")
        return reference(version: version, path: path, data: data)
    }

    func reference(version: String, path: String, data: Data) -> PackageReference {
        PackageReference(version: version, schemaVersion: ContentPackage.currentSchemaVersion, path: path,
                         sha256: Digest.sha256(data))
    }

    /// The highest-versioned package in `catalog/`.
    func latestPackage() -> (version: String, path: String, data: Data)? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: repo.catalogFolder.path)) ?? []
        let versions = names.filter { $0.hasSuffix(".json") }.map { String($0.dropLast(5)) }
            .compactMap { name in SemanticVersionKey(name).map { (name, $0) } }
        guard let latest = versions.max(by: { $0.1 < $1.1 })?.0,
              let data = try? Data(contentsOf: repo.catalogFolder.appendingPathComponent("\(latest).json")) else { return nil }
        return (latest, "catalog/\(latest).json", data)
    }

    // MARK: Feed

    public enum PackageChoice: Equatable {
        /// Whatever the last feed named.
        case keep
        /// The highest version in `catalog/`.
        case latest
        /// None: installed apps go back to their bundle.
        case none
        case version(String)
    }

    /// Writes `feed.json` and its signature. `feedVersion` is one above the
    /// last written feed's.
    @discardableResult
    public func publishFeed(signer: Signer, package choice: PackageChoice, today: String,
                            first: Bool = false) throws -> FeedFile {
        let stories = try StoryLibrary.load(from: repo.stories)
        let previous = try? JSONDecoder().decode(FeedFile.self, from: Data(contentsOf: repo.feed))
        // Installed apps refuse a feed that is not newer than theirs. Starting
        // again from 1 in a checkout without the last feed would be refused
        // everywhere, silently — so the first feed is said out loud.
        guard previous != nil || first else {
            throw PublishError.message(
                "Önceki feed.json yok (\(repo.feed.path)). Gerçekten ilk yayınsa --first ekleyin; "
                + "değilse yayımlanan son feed.json'u (repoda commit'li olmalı) geri getirin.")
        }

        let package: PackageReference?
        switch choice {
        case .none: package = nil
        case .keep:
            package = try previous?.catalogPackage.map { try packageReference(path: $0.path) }
        case .latest:
            guard let latest = latestPackage() else { throw PublishError.message("catalog/ boş. Önce build-package.") }
            package = reference(version: latest.version, path: latest.path, data: latest.data)
        case .version(let version):
            package = try packageReference(path: "catalog/\(version).json")
        }

        let feed = FeedFile(feedVersion: (previous?.feedVersion ?? 0) + 1, publishedAt: today,
                            stories: stories, catalogPackage: package)
        let data = try feed.encoded()
        try FileManager.default.createDirectory(at: repo.content, withIntermediateDirectories: true)
        try data.write(to: repo.feed, options: .atomic)
        try signer.signature(for: data).write(to: repo.signature, options: .atomic)

        let future = stories.filter { $0.publishDate > today }.count
        log("Akış \(feed.feedVersion) yazıldı: \(stories.count) masal (\(future) ileri tarihli), "
            + "paket \(package?.version ?? "yok").")
        return feed
    }

    func packageReference(path: String) throws -> PackageReference {
        guard let data = try? Data(contentsOf: repo.content.appendingPathComponent(path)) else {
            throw PublishError.message("\(path) bulunamadı.")
        }
        let version = String(path.dropFirst("catalog/".count).dropLast(".json".count))
        return reference(version: version, path: path, data: data)
    }

    /// The app's own copy of the stories, read before any feed arrives.
    /// Same stories, same bytes: dated by its newest story, not by the run.
    public func writeFallback() throws {
        let stories = try StoryLibrary.load(from: repo.stories)
        let newest = stories.map(\.publishDate).max() ?? ""
        let feed = FeedFile(feedVersion: 0, publishedAt: newest, stories: stories, catalogPackage: nil)
        try feed.encoded().write(to: repo.appFallback, options: .atomic)
        log("Uygulama yedeği yazıldı: \(stories.count) masal.")
    }

    /// `firebase deploy --only hosting`, from `hosting/`.
    public func deploy() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["firebase", "deploy", "--only", "hosting"]
        process.currentDirectoryURL = repo.hosting
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw PublishError.message("firebase deploy başarısız.") }
    }
}

/// Orders `x.y.z` file names.
struct SemanticVersionKey: Comparable {
    let parts: [Int]
    init?(_ text: String) {
        let parts = text.split(separator: ".").map { Int($0) }
        guard parts.count == 3, parts.allSatisfy({ $0 != nil }) else { return nil }
        self.parts = parts.map { $0! }
    }
    static func < (a: Self, b: Self) -> Bool { a.parts.lexicographicallyPrecedes(b.parts) }
}
