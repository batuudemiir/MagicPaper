import Foundation

/// Kendi sesin (33, FAZ 18): ebeveynin sayfa sayfa okuduğu kayıtlar.
///
/// Bugün yalnızca bu cihazda, uygulamanın kendi klasöründe durur; hiçbir
/// yere gönderilmez, yedeğe girmez. Hesaba (Firebase Storage) taşınması
/// onay metni ve hukuk kararından sonra. Dosya yolu yalnızca masal kimliği
/// ve sayfa numarasından oluşur: içinde ad ya da metin yok.
struct VoiceRecordingStore {
    static let shared = VoiceRecordingStore()

    let root: URL

    init(root: URL? = nil) {
        if let root {
            self.root = root
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.root = support.appendingPathComponent("VoiceRecordings", isDirectory: true)
        }
    }

    private func folder(_ storyID: UUID) -> URL {
        root.appendingPathComponent(storyID.uuidString, isDirectory: true)
    }

    /// Kaydın yazılacağı yer (klasör hazırlanır, dosya henüz yok olabilir).
    func destination(story storyID: UUID, page: Int) throws -> URL {
        let dir = folder(storyID)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var excluded = root
        try? excluded.setResourceValues(values)
        return dir.appendingPathComponent("\(page).m4a")
    }

    /// Sayfanın kaydı, varsa.
    func recording(story storyID: UUID, page: Int) -> URL? {
        let url = folder(storyID).appendingPathComponent("\(page).m4a")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Kaydı olan sayfalar, artan sırada.
    func recordedPages(story storyID: UUID) -> [Int] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder(storyID).path)) ?? []
        return names.compactMap { name in
            name.hasSuffix(".m4a") ? Int(name.dropLast(4)) : nil
        }.sorted()
    }

    /// Kaydı olan masallar.
    func recordedStories() -> Set<UUID> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
        return Set(names.compactMap(UUID.init(uuidString:)).filter { !recordedPages(story: $0).isEmpty })
    }

    func delete(story storyID: UUID, page: Int) {
        try? FileManager.default.removeItem(at: folder(storyID).appendingPathComponent("\(page).m4a"))
    }

    func delete(story storyID: UUID) {
        try? FileManager.default.removeItem(at: folder(storyID))
    }

    /// Bütün kayıtlar (Gizlilik ve veri, hesap silme, çıkış).
    func deleteAll() {
        try? FileManager.default.removeItem(at: root)
    }
}
