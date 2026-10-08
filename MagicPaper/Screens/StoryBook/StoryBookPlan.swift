import Foundation

/// 35 · Masal kitabı'nın kuralları, ekrandan ayrı (test edilir).
///
/// Kitaba yalnızca okunabilir masallar girer; varsayılan seçim çocuğun
/// bitirdiği masallardır (bitirdiği yoksa hepsi). Sıra kitaplıktaki gibi:
/// en eski önce, kitap bir anı defteri gibi baştan sona okunur.
enum StoryBookPlan {
    /// Kitaba girebilecek masallar, en eskiden yeniye.
    static func candidates(_ stories: [Story], for profile: UserProfile) -> [Story] {
        stories
            .filter { $0.isReadable && $0.belongs(to: profile) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Ekran açıldığında işaretli olanlar.
    static func defaultSelection(_ candidates: [Story]) -> Set<UUID> {
        let finished = candidates.filter(\.isFinished)
        return Set((finished.isEmpty ? candidates : finished).map(\.id))
    }

    /// Seçilenler, kitap sırasıyla.
    static func ordered(_ candidates: [Story], selected: Set<UUID>) -> [Story] {
        candidates.filter { selected.contains($0.id) }
    }

    /// PDF'teki sayfa sayısı: her masal için bir kapak ve masalın sayfaları.
    static func pageCount(_ stories: [Story]) -> Int {
        stories.reduce(0) { $0 + 1 + $1.pages.count }
    }

    /// "Elif'in masal kitabı.pdf" yerine güvenli bir dosya adı; çocuğun adı
    /// paylaşılan dosyanın adında görünür, başka bilgi görünmez.
    static func fileName(childName: String) -> String {
        let ascii = childName.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i").replacingOccurrences(of: "İ", with: "I")
        let allowed = ascii.unicodeScalars.filter { $0.isASCII && CharacterSet.alphanumerics.contains($0) }
        let slug = String(String.UnicodeScalarView(allowed)).lowercased()
        return slug.isEmpty ? "masal-kitabi.pdf" : "\(slug)-masal-kitabi.pdf"
    }
}
