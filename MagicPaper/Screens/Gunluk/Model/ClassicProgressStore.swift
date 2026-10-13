import Foundation

/// Günlük masallarında çocuğun kaldığı yer (FAZ 20).
///
/// Motor masalları `StoryGenerationManager`'da duruyor; Günlük masalları
/// orada durmaz, çünkü çocuğun Kitaplık'ına ait değiller. Bu defter yalnızca
/// "nerede kaldı, ne zaman açtı, bitirdi mi, hangi anlatımı seçti" sorularını
/// tutar. Çocuk başına ayrı, cihazda kalır.
@MainActor
final class ClassicProgressStore: ObservableObject {

    static let shared = ClassicProgressStore()

    struct Entry: Codable, Equatable {
        /// Ulaşılan en ileri sayfa (0'dan).
        var page: Int
        var pageCount: Int
        var openedAt: Date
        var finishedAt: Date?
        var narration: ClassicNarration

        var isFinished: Bool { finishedAt != nil }
        /// 0…1, "Kaldığın yerden" çubuğu için.
        var fraction: Double { pageCount > 0 ? min(Double(page + 1) / Double(pageCount), 1) : 0 }
    }

    @Published private(set) var entries: [UUID: Entry] = [:]

    private let defaults: UserDefaults
    private let childID: () -> UUID?
    private let now: () -> Date
    private var loadedFor: UUID??

    init(
        defaults: UserDefaults = .standard,
        childID: (() -> UUID?)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.childID = childID ?? { ProfileManager.shared.currentProfile?.id }
        self.now = now
        reload()
    }

    private var key: String { "mp_classicProgress." + (childID()?.uuidString ?? "none") }

    /// Çocuk değiştiyse onun defterini oku.
    func reload() {
        let current = childID()
        guard loadedFor != .some(current) else { return }
        loadedFor = .some(current)
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([UUID: Entry].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    func entry(_ id: UUID) -> Entry? {
        reload()
        return entries[id]
    }

    /// Okuyucu açılırken. Sayfa sayısı anlatıma göre değişir, burada yazılır.
    func markOpened(_ id: UUID, pageCount: Int, narration: ClassicNarration) {
        reload()
        var entry = entries[id] ?? Entry(page: 0, pageCount: pageCount, openedAt: now(),
                                         finishedAt: nil, narration: narration)
        if entry.narration != narration || entry.pageCount != pageCount {
            // Başka anlatım başka sayfalar demek: yer baştan.
            entry.page = 0
            entry.pageCount = pageCount
            entry.narration = narration
        }
        entry.openedAt = now()
        entries[id] = entry
        save()
    }

    /// Okuyucunun her kalıcı sayfa değişiminde.
    func saveProgress(_ id: UUID, page: Int) {
        reload()
        guard var entry = entries[id] else { return }
        entry.page = max(0, min(page, max(entry.pageCount - 1, 0)))
        entry.openedAt = now()
        if entry.pageCount > 0, entry.page >= entry.pageCount - 1, entry.finishedAt == nil {
            entry.finishedAt = now()
        }
        entries[id] = entry
        save()
    }

    /// Detaydaki "ANLATIM" seçimi; okuyucu bu anlatımla açılır.
    func narration(for id: UUID) -> ClassicNarration {
        entry(id)?.narration ?? .soft
    }

    func setNarration(_ narration: ClassicNarration, for id: UUID) {
        reload()
        guard var entry = entries[id] else {
            entries[id] = Entry(page: 0, pageCount: 0, openedAt: .distantPast, finishedAt: nil, narration: narration)
            save()
            return
        }
        guard entry.narration != narration else { return }
        entry.narration = narration
        entry.page = 0
        entries[id] = entry
        save()
    }

    /// Bitirilmiş masallar (günün masalı seçimi okunmamışı öne alır).
    var finishedIDs: Set<UUID> {
        reload()
        return Set(entries.filter { $0.value.isFinished }.map(\.key))
    }

    /// "Kaldığın yerden": açılmış, en az bir sayfa ilerlemiş, bitmemiş;
    /// en son açılan önce.
    func inProgress(limit: Int = 6) -> [(id: UUID, entry: Entry)] {
        reload()
        return entries
            .filter { !$0.value.isFinished && $0.value.page > 0 && $0.value.pageCount > 0 }
            .sorted { $0.value.openedAt > $1.value.openedAt }
            .prefix(limit)
            .map { (id: $0.key, entry: $0.value) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
