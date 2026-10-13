import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "VoiceRecordings")

/// Kendi sesin (FAZ 18): bir masalın sayfa sayfa ses kayıtları.
///
/// Cihaz önce: kayıt `Application Support/Voice/{storyID}/{page}.m4a`'ya
/// yazılır, sonra ailenin Storage klasörüne (`families/{fid}/voice/...`)
/// gider. Hangi sayfaların kaydı olduğu ailenin `recordings` kaydıyla
/// eşitlenir; ses dosyası başka cihazda okunacağı an indirilir.
/// Masal metni yazıldıktan sonra değişmediği için sayfa dizini anahtar yeter.
struct VoiceRecordingSet: Codable, Equatable, Sendable {
    /// Sayfa dizini (metin olarak, JSON kararlı kalsın diye) → saniye.
    var pages: [String: Double]
    /// Sayfayı kimin kaydettiği (aile üyesinin uid'i): rızasını geri çeken
    /// yetişkinin kayıtları silinir, diğerlerininki kalır.
    var by: [String: String]? = nil

    var pageIndexes: [Int] { pages.keys.compactMap(Int.init).sorted() }
    var isEmpty: Bool { pages.isEmpty }
    var totalSeconds: Double { pages.values.reduce(0, +) }
}

/// Ses dosyalarının sunucu tarafı.
protocol VoiceRemote: Sendable {
    func upload(file: URL, to path: String) async throws
    func download(path: String, to file: URL) async throws
    func delete(path: String) async throws
}

@MainActor
final class VoiceRecordingStore: ObservableObject {
    static let shared = VoiceRecordingStore()

    /// Bir sayfa en çok 3 dakika (Storage kuralıyla aynı boyut sınırına sığar).
    static let maxPageSeconds: TimeInterval = 180

    @Published private(set) var sets: [UUID: VoiceRecordingSet] = [:]

    private struct Index: Codable {
        var sets: [String: VoiceRecordingSet] = [:]
        /// Gönderilmeyi bekleyen dosyalar, "storyID/page".
        var pendingUploads: Set<String> = []
        /// Sunucudan silinmeyi bekleyenler, "storyID/page".
        var pendingDeletes: Set<String> = []
    }

    private let root: URL
    private var index = Index()
    private let remote: VoiceRemote?
    /// Ailenin ses klasörü, `families/{fid}/voice`. Giriş yoksa nil: kayıtlar cihazda bekler.
    private let folder: @MainActor () -> String?
    private var flushing = false

    init(root: URL? = nil, remote: VoiceRemote? = nil, folder: @escaping @MainActor () -> String? = { nil }) {
        self.root = root ?? Self.defaultRoot
        self.remote = remote
        self.folder = folder
        load()
    }

    private convenience init() {
        self.init(remote: FirebaseVoiceRemote(), folder: {
            AccountService.shared.familyID.map { "families/\($0)/voice" }
        })
    }

    static var defaultRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Voice", isDirectory: true)
    }

    // MARK: - Okuma

    func recordings(for storyID: UUID) -> VoiceRecordingSet? { sets[storyID] }

    func hasRecording(_ storyID: UUID) -> Bool { !(sets[storyID]?.isEmpty ?? true) }

    func isRecorded(_ storyID: UUID, page: Int) -> Bool { sets[storyID]?.pages[String(page)] != nil }

    var recordedStoryCount: Int { sets.values.filter { !$0.isEmpty }.count }

    func fileURL(_ storyID: UUID, page: Int) -> URL {
        root.appendingPathComponent(storyID.uuidString, isDirectory: true).appendingPathComponent("\(page).m4a")
    }

    /// Cihazda duran kayıt; yoksa nil (henüz indirilmemiş olabilir).
    func localFile(_ storyID: UUID, page: Int) -> URL? {
        guard isRecorded(storyID, page: page) else { return nil }
        let url = fileURL(storyID, page: page)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Yazma

    /// Kaydedilen sayfayı yerine taşır ve gönderilecekler arasına koyar.
    func save(recordingAt temporary: URL, storyID: UUID, page: Int, seconds: Double, by recorder: String? = nil) throws {
        let target = fileURL(storyID, page: page)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
        try FileManager.default.moveItem(at: temporary, to: target)
        var set = sets[storyID] ?? VoiceRecordingSet(pages: [:])
        set.pages[String(page)] = min(seconds, Self.maxPageSeconds)
        if let recorder {
            var owners = set.by ?? [:]
            owners[String(page)] = recorder
            set.by = owners
        }
        sets[storyID] = set
        let key = Self.key(storyID, page)
        index.pendingUploads.insert(key)
        index.pendingDeletes.remove(key)
        persist(changed: true)
        Task { await flush() }
    }

    /// Bir masalın bütün kayıtlarını siler (cihaz + aile).
    func deleteRecordings(for storyID: UUID) {
        guard let set = sets[storyID] else { return }
        for page in set.pageIndexes {
            let key = Self.key(storyID, page: page)
            index.pendingUploads.remove(key)
            index.pendingDeletes.insert(key)
        }
        try? FileManager.default.removeItem(at: root.appendingPathComponent(storyID.uuidString, isDirectory: true))
        sets[storyID] = nil
        persist(changed: true)
        Task { await flush() }
    }

    /// Ses rızası geri çekildiğinde: o yetişkinin kaydettiği (ya da kimin
    /// kaydettiği bilinmeyen) bütün sayfalar.
    func deleteAll(recordedBy recorder: String?) {
        for (storyID, set) in sets {
            let pages = set.pageIndexes.filter { page in
                guard let recorder, let owner = set.by?[String(page)] else { return true }
                return owner == recorder
            }
            deletePages(pages, of: storyID)
        }
    }

    /// Bir masalın bazı sayfalarını siler.
    func deletePages(_ pages: [Int], of storyID: UUID) {
        guard var set = sets[storyID], !pages.isEmpty else { return }
        for page in pages {
            let key = Self.key(storyID, page: page)
            index.pendingUploads.remove(key)
            index.pendingDeletes.insert(key)
            try? FileManager.default.removeItem(at: fileURL(storyID, page: page))
            set.pages[String(page)] = nil
            set.by?[String(page)] = nil
        }
        sets[storyID] = set.isEmpty ? nil : set
        persist(changed: true)
        Task { await flush() }
    }

    // MARK: - Eşitleme

    /// `recordings` kayıtları, masal kimliğine göre.
    var syncPayloads: [(storyID: UUID, set: VoiceRecordingSet)] {
        sets.filter { !$0.value.isEmpty }.map { ($0.key, $0.value) }
    }

    /// Aileden gelen kayıt bilgisi. Silinen sayfaların dosyası cihazdan da gider;
    /// yeni sayfalar okunacağı an indirilir.
    func applySynced(_ set: VoiceRecordingSet?, for storyID: UUID) {
        let old = sets[storyID]
        for page in old?.pageIndexes ?? [] where set?.pages[String(page)] == nil {
            try? FileManager.default.removeItem(at: fileURL(storyID, page: page))
        }
        // Başka cihazdan yeniden kaydedilen sayfa: eski dosya artık yanlış.
        for (page, seconds) in set?.pages ?? [:] where old?.pages[page] != seconds {
            if let index = Int(page) { try? FileManager.default.removeItem(at: fileURL(storyID, page: index)) }
        }
        sets[storyID] = (set?.isEmpty ?? true) ? nil : set
        persist(changed: false)
    }

    /// Bekleyen yüklemeleri ve silmeleri dener. Bağlantı yoksa bir sonraki sefere kalır.
    func flush() async {
        guard !flushing, let remote, let folder = folder() else { return }
        flushing = true
        defer { flushing = false }
        for key in index.pendingDeletes.sorted() {
            do {
                try await remote.delete(path: "\(folder)/\(key).m4a")
                index.pendingDeletes.remove(key)
            } catch {
                // Zaten yoksa da hata gelir; bir sonraki seferde yeniden denenir.
                if (error as NSError).code == 404 || "\(error)".contains("objectNotFound") { index.pendingDeletes.remove(key) }
            }
        }
        for key in index.pendingUploads.sorted() {
            guard let (storyID, page) = Self.parse(key) else { index.pendingUploads.remove(key); continue }
            let file = fileURL(storyID, page: page)
            guard FileManager.default.fileExists(atPath: file.path) else { index.pendingUploads.remove(key); continue }
            do {
                try await remote.upload(file: file, to: "\(folder)/\(key).m4a")
                index.pendingUploads.remove(key)
            } catch {
                logger.notice("Ses kaydı gönderilemedi; cihazda bekliyor")
                break
            }
        }
        persist(changed: false)
    }

    /// Okuyucu açılırken: eksik sayfaları indirir.
    func prefetch(_ storyID: UUID) async {
        guard let set = sets[storyID], let remote, let folder = folder() else { return }
        for page in set.pageIndexes where localFile(storyID, page: page) == nil {
            let target = fileURL(storyID, page: page)
            try? FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? await remote.download(path: "\(folder)/\(storyID.uuidString)/\(page).m4a", to: target)
        }
    }

    var hasPendingWork: Bool { !index.pendingUploads.isEmpty || !index.pendingDeletes.isEmpty }

    // MARK: - Disk

    private static func key(_ storyID: UUID, _ page: Int) -> String { "\(storyID.uuidString)/\(page)" }
    private static func key(_ storyID: UUID, page: Int) -> String { key(storyID, page) }

    private static func parse(_ key: String) -> (UUID, Int)? {
        let parts = key.split(separator: "/")
        guard parts.count == 2, let id = UUID(uuidString: String(parts[0])), let page = Int(parts[1]) else { return nil }
        return (id, page)
    }

    private var indexURL: URL { root.appendingPathComponent("index.json") }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let stored = try? JSONDecoder().decode(Index.self, from: data) else { return }
        index = stored
        sets = Dictionary(uniqueKeysWithValues: stored.sets.compactMap { key, value in
            UUID(uuidString: key).map { ($0, value) }
        })
    }

    private func persist(changed: Bool) {
        index.sets = Dictionary(uniqueKeysWithValues: sets.map { ($0.key.uuidString, $0.value) })
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            var url = root
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
            try JSONEncoder().encode(index).write(to: indexURL, options: .atomic)
        } catch {
            logger.error("🛑 Ses kaydı dizini yazılamadı")
        }
        if changed { NotificationCenter.default.post(name: .mpFamilyDataChanged, object: nil) }
    }

    /// Cihazdan siler; sunucuya dokunmaz (çıkış, hesap silme, aileden ayrılma).
    func eraseLocal() {
        try? FileManager.default.removeItem(at: root)
        index = Index()
        sets = [:]
    }
}
