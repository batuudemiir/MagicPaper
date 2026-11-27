import Foundation

/// Bir çocuğun okuduğu P56 kitapları, en yenisi önce (tekrar çözümü, 26 Kasım 2026).
///
/// Motor bu listeyi seçimde kullanır: hücrede okunmamış kitap varken okunanları
/// atlar, hepsi okunduysa en uzun süre önce okunanı verir. Liste kitap
/// kimliğidir; çocuğun adı ya da metin gitmez.
///
/// 27 Kasım 2026: okuma kaydı da katılır. İlk üçte birinde kapatılıp hiç
/// bitirilmeyen kitap "göz atıldı" sayılır (`glanced`), okunanlardan önce geri
/// gelebilir. Arkadaş ağırlıkları (`companionWeights`) Sürpriz'de çocuğun
/// sonuna kadar okuduğu arkadaşları öne alır.
enum P56RecentBooks {
    /// Aynı kitabın birden çok kaydı varsa yalnız en yenisi sayılır.
    static func ids(forChild childID: UUID, in stories: [Story]) -> [String] {
        var seen = Set<String>()
        return ordered(forChild: childID, in: stories)
            .compactMap { bookID(of: $0) }
            .filter { seen.insert($0).inserted }
    }

    /// Verilen ama okunmayan kitaplar: her kaydı açılmış, ilk üçte birinde
    /// kapatılmış, hiç bitirilmemiş ve okuma süresi bitimiyle kesilmemiş.
    /// Okuma kaydı olmayan kitap okunmuş sayılır: kayıt yoksa tekrar etmemek
    /// daha güvenli.
    static func glancedIDs(forChild childID: UUID, in stories: [Story],
                           usage: [UUID: StoryUsageStore.Stats]) -> [String] {
        var verdict: [String: Bool] = [:]
        for story in ordered(forChild: childID, in: stories) {
            guard let id = bookID(of: story) else { continue }
            let glanced = usage[story.id].map { stats in
                stats.sessions > 0 && stats.completions == 0 && !stats.lastSessionInterrupted
                    && stats.furthestPage + 1 < StoryUsageStore.leavingThreshold(pageCount: story.pages.count)
            } ?? false
            verdict[id] = (verdict[id] ?? true) && glanced
        }
        let all = ids(forChild: childID, in: stories)
        return all.filter { verdict[$0] == true }
    }

    /// Arkadaş başına ağırlık: bitirilen masal sayısı yarıda bırakılandan
    /// fazlaysa 3, azsa 1; okunmamış ya da dengeli arkadaş yazılmaz (motor 2
    /// sayar). Son `StoryUsageStore.learningWindow` P56 masalına bakılır.
    static func companionWeights(forChild childID: UUID, in stories: [Story],
                                 usage: [UUID: StoryUsageStore.Stats]) -> [String: Int] {
        var score: [String: Int] = [:]
        for story in ordered(forChild: childID, in: stories)
            .filter({ $0.origin?.contentSource?.p56Reference != nil })
            .prefix(StoryUsageStore.learningWindow) {
            guard let companion = story.origin?.companionID, let stats = usage[story.id] else { continue }
            if stats.completions > 0 {
                score[companion, default: 0] += stats.completions > 1 ? 2 : 1
            } else if stats.abandoned(pageCount: story.pages.count) {
                score[companion, default: 0] -= 1
            }
        }
        return score.compactMapValues { $0 > 0 ? 3 : ($0 < 0 ? 1 : nil) }
    }

    /// Bu çocuğun beşliden en az bir masalını aldığı arkadaşlar. Seçim
    /// ekranı tanışılmamış arkadaşa "Yeni" der (27 Kasım 2026).
    static func metCompanionIDs(forChild childID: UUID, in stories: [Story]) -> Set<String> {
        Set(stories.filter { $0.childProfileID == childID && $0.origin?.contentSource?.p56Reference != nil }
            .compactMap { $0.origin?.companionID })
    }

    /// Hücredeki her kitap bu çocuğa verilmiş mi? Boş hücre "bilinmiyor"dur,
    /// okunmuş sayılmaz. Göz atılanlar da verilmiş sayılır: motor onları
    /// yeniden verir ama çocuk o kitabı görmüştür.
    static func hasReadAll(_ bookIDs: [String], recent: [String]) -> Bool {
        !bookIDs.isEmpty && Set(bookIDs).isSubset(of: Set(recent))
    }

    /// Bu çocuğun masalları, en yenisi önce; aynı ana düşenlerde kitaplığın
    /// sırası (en yeni önce) korunur.
    private static func ordered(forChild childID: UUID, in stories: [Story]) -> [Story] {
        stories
            .enumerated()
            .filter { $0.element.childProfileID == childID }
            .sorted { ($0.element.createdAt, -$0.offset) > ($1.element.createdAt, -$1.offset) }
            .map(\.element)
    }

    /// Kayıtlı kimlik; yoksa (alandan önce yazılmış v3+ masalı) ilk sayfanın
    /// şablon kimliğinden okunur: `p56_runtime_p56_v4_<kitap>_p01`. v1/v2
    /// şablonları kitap kimliğini taşımaz; o masallar sayılmaz.
    static func bookID(of story: Story) -> String? {
        guard story.origin?.contentSource?.p56Reference != nil else { return nil }
        if let id = story.origin?.p56BookID { return id }
        guard let template = story.pages.first?.provenance?.p56?.templateID,
              let start = template.range(of: "pilot56_book_"),
              let end = template.range(of: "_p", options: .backwards),
              start.lowerBound < end.lowerBound else { return nil }
        return String(template[start.lowerBound..<end.lowerBound])
    }
}
