import UIKit

// MARK: - MagicPaper Original (spec 2026-11-12)
//
// Uzaktan akışın kendi masalları Masallar'da klasiklerin okuyucusuyla okunur.
// Kişiselleştirilmez; her çocuk aynı metni okur.

extension FeedOriginal {
    /// Masalın klasik biçimi. Kapak adı `original:<slug>:<özetin başı>`:
    /// kapak değişince ad da değişir, eski görsel önbellekte kalmaz.
    var classicTale: ClassicTale {
        ClassicTale(
            id: id, slug: slug, title: title, origin: .orijinal, byline: "Original",
            ageMin: ageMin, ageMax: ageMax, minutes: minutes, summary: summary,
            shelves: mode == "bedtime" ? [.orijinal, .uyku] : [.orijinal],
            cover: OriginalCovers.name(slug: slug, sha256: cover.sha256), coverFocus: .center,
            attribution: "MagicPaper Original.", coverCredit: "Kapak: MagicPaper.",
            soft: ClassicText(pages: pages), classic: nil, seriesID: nil, episode: nil)
    }
}

/// Original kapakları asset kataloğunda değil, cihazda
/// (`RemoteContentStore.originalCoverURL`).
enum OriginalCovers {
    static let prefix = "original:"
    private static let cache = NSCache<NSString, UIImage>()

    static func name(slug: String, sha256: String) -> String { "\(prefix)\(slug):\(sha256.prefix(12))" }

    static func slug(in name: String) -> String? {
        guard name.hasPrefix(prefix) else { return nil }
        return name.dropFirst(prefix.count).split(separator: ":").first.map(String.init)
    }

    static func image(named name: String, store: RemoteContentStore = RemoteContentStore()) -> UIImage? {
        guard let slug = slug(in: name) else { return nil }
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let image = UIImage(contentsOfFile: store.originalCoverURL(slug: slug).path) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

/// Okuyucunun main-actor dışı sorguları için Original masalların kapak adları.
/// `RemoteContentService.originals` her değiştiğinde güncellenir.
enum OriginalIndex {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var covers: [UUID: String] = [:]

    static func update(_ originals: [FeedOriginal]) {
        let map = Dictionary(originals.map { ($0.id, OriginalCovers.name(slug: $0.slug, sha256: $0.cover.sha256)) },
                             uniquingKeysWith: { first, _ in first })
        lock.lock(); covers = map; lock.unlock()
    }

    static func cover(for id: UUID) -> String? {
        lock.lock(); defer { lock.unlock() }
        return covers[id]
    }
}
