import Foundation

/// Where the remote content (FAZ 15) lives, and what the app reads it with.
struct RemoteContentConfig {
    /// The folder the feed sits in, e.g. `https://<proje>.web.app/content/`.
    let contentRoot: URL
    let key: ContentSigningKey

    static let baseURLKey = "MPContentBaseURL"
    static let signingKeyKey = "MPContentSigningKey"

    #if DEBUG
    /// Launch arguments for trying a local server in the simulator:
    /// `-mp.debug.contentBaseURL http://127.0.0.1:8765/content -mp.debug.contentSigningKey <base64>`.
    static let debugBaseURLKey = "mp.debug.contentBaseURL"
    static let debugSigningKeyKey = "mp.debug.contentSigningKey"
    #endif

    /// `nil` until the publisher's key and address are in Info.plist: no key,
    /// no remote content — the app never takes unsigned content.
    static func current(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> RemoteContentConfig? {
        var base = bundle.object(forInfoDictionaryKey: baseURLKey) as? String ?? ""
        var key = bundle.object(forInfoDictionaryKey: signingKeyKey) as? String ?? ""
        var allowsHTTP = false
        #if DEBUG
        if let override = defaults.string(forKey: debugBaseURLKey), !override.isEmpty {
            base = override
            allowsHTTP = true
        }
        if let override = defaults.string(forKey: debugSigningKeyKey), !override.isEmpty { key = override }
        #endif
        return make(base: base, key: key, allowsHTTP: allowsHTTP)
    }

    static func make(base: String, key: String, allowsHTTP: Bool = false) -> RemoteContentConfig? {
        guard var url = URL(string: base.trimmingCharacters(in: .whitespaces)),
              url.scheme == "https" || (allowsHTTP && url.scheme == "http"),
              url.host != nil, url.query == nil,
              let signingKey = ContentSigningKey(base64: key) else { return nil }
        if !url.path.hasSuffix("/") { url.appendPathComponent("", isDirectory: true) }
        return RemoteContentConfig(contentRoot: url, key: signingKey)
    }

    var feedURL: URL { contentRoot.appendingPathComponent("feed.json") }
    var signatureURL: URL { contentRoot.appendingPathComponent("feed.json.sig") }
    func url(for package: CatalogPackageRef) -> URL { contentRoot.appendingPathComponent(package.path) }
}

/// The last verified feed and the downloaded catalog packages.
///
/// `Library/Application Support/RemoteContent/`, kept out of backups: it is
/// published content, not the family's, and can always be fetched again. For
/// the same reason it is written readable after first unlock rather than with
/// the app's stricter class — a background refresh runs while the phone is
/// locked. Nothing here is about a child.
///
/// - `feed.json`, `feed.json.sig` — the signed bytes, exactly as downloaded.
/// - `catalog-staged.json` — a package that passed every check, waiting for
///   the next launch.
/// - `catalog-active.json` — the package the engine reads this launch.
struct RemoteContentStore: Sendable {
    static let defaultDirectoryName = "RemoteContent"

    let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.directory = support.appendingPathComponent(Self.defaultDirectoryName, isDirectory: true)
        }
    }

    private enum Name {
        static let feed = "feed.json"
        static let signature = "feed.json.sig"
        static let staged = "catalog-staged.json"
        static let active = "catalog-active.json"
    }

    // MARK: Feed

    /// The stored feed, checked against `key` again. A feed signed with a key
    /// this build no longer trusts is as good as none.
    func feed(key: ContentSigningKey) -> ContentFeed? {
        guard let data = read(Name.feed), let signature = read(Name.signature) else { return nil }
        return try? ContentFeed.verified(data, signature: signature, key: key)
    }

    func saveFeed(_ data: Data, signature: Data) throws {
        try write(data, Name.feed)
        try write(signature, Name.signature)
    }

    // MARK: Packages

    var stagedPackage: Data? { read(Name.staged) }
    var activePackage: Data? { read(Name.active) }

    func stage(_ package: Data) throws { try write(package, Name.staged) }

    /// At launch, before the engine reads anything: a staged package becomes
    /// the active one. Never mid-session — a book half-built from one catalog
    /// does not finish from another.
    func promoteStaged() {
        let staged = url(Name.staged)
        guard FileManager.default.fileExists(atPath: staged.path) else { return }
        _ = try? FileManager.default.replaceItemAt(url(Name.active), withItemAt: staged)
        if FileManager.default.fileExists(atPath: staged.path) {
            // `replaceItemAt` needs an existing item to replace.
            try? FileManager.default.moveItem(at: staged, to: url(Name.active))
        }
    }

    func removeStaged() { try? FileManager.default.removeItem(at: url(Name.staged)) }
    func removeActive() { try? FileManager.default.removeItem(at: url(Name.active)) }

    func eraseAll() { try? FileManager.default.removeItem(at: directory) }

    // MARK: Files

    private func url(_ name: String) -> URL { directory.appendingPathComponent(name) }

    private func read(_ name: String) -> Data? { try? Data(contentsOf: url(name)) }

    private func write(_ data: Data, _ name: String) throws {
        let manager = FileManager.default
        if !manager.fileExists(atPath: directory.path) {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            var folder = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? folder.setResourceValues(values)
        }
        try data.write(to: url(name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
