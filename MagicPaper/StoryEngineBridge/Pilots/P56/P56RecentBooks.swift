import Foundation

/// Bir çocuğun okuduğu P56 kitapları, en yenisi önce (tekrar çözümü, 26 Kasım 2026).
///
/// Motor bu listeyi seçimde kullanır: hücrede okunmamış kitap varken okunanları
/// atlar, hepsi okunduysa en uzun süre önce okunanı verir. Liste kitap
/// kimliğidir; çocuğun adı ya da metin gitmez.
enum P56RecentBooks {
    /// Aynı kitabın birden çok kaydı varsa yalnız en yenisi sayılır.
    static func ids(forChild childID: UUID, in stories: [Story]) -> [String] {
        var seen = Set<String>()
        return stories
            .enumerated()
            .filter { $0.element.childProfileID == childID }
            // Aynı ana düşenlerde kitaplığın sırası (en yeni önce) korunur.
            .sorted { ($0.element.createdAt, -$0.offset) > ($1.element.createdAt, -$1.offset) }
            .compactMap { bookID(of: $0.element) }
            .filter { seen.insert($0).inserted }
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
