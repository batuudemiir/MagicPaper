import Foundation
import StoryEngine

/// 35 · Masal kitabı: hangi masalların kitaba gireceği (FAZ 18).
///
/// Liste bir çocuğun okunabilir masallarıdır, en eskisi önce: kitap çocuğun
/// masallarını yazıldıkları sırayla anlatır. Açılışta hepsi seçilidir;
/// ebeveyn çıkarmak istediğini kaldırır.
struct BookExportSelection: Equatable {
    let childName: String
    /// Kitaba girebilecek masallar, en eskisi önce.
    let candidates: [Story]
    private(set) var selectedIDs: Set<UUID>

    init(childName: String, stories: [Story]) {
        self.childName = childName
        self.candidates = stories.filter(\.isReadable).sorted { $0.createdAt < $1.createdAt }
        self.selectedIDs = Set(candidates.map(\.id))
    }

    /// Profilin masallarından kurar.
    init(profile: UserProfile, stories: [Story]) {
        self.init(childName: profile.name, stories: stories.filter { $0.belongs(to: profile) })
    }

    func isSelected(_ story: Story) -> Bool { selectedIDs.contains(story.id) }

    mutating func toggle(_ story: Story) {
        if selectedIDs.contains(story.id) { selectedIDs.remove(story.id) } else { selectedIDs.insert(story.id) }
    }

    /// Kitaba girecekler, listedeki sırayla.
    var selected: [Story] { candidates.filter { selectedIDs.contains($0.id) } }

    /// Masal sayfaları; her masalın kapağı ve kitabın kapağı sayılmaz.
    var pageCount: Int { selected.reduce(0) { $0 + $1.pages.count } }

    var canExport: Bool { !selected.isEmpty }

    /// "İrem'in Masal Kitabı"
    var bookTitle: String {
        let name = childName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "Masal Kitabı" }
        return TurkishGrammar.inflect(TurkishNoun(name, isProperNoun: true), into: .genitive) + " Masal Kitabı"
    }

    /// "3 masal, 26 sayfa. Yazdırmaya hazır PDF."
    var summary: String {
        guard canExport else { return "Kitaba girecek masalları seç." }
        return "\(selected.count) masal, \(pageCount) sayfa. Yazdırmaya hazır PDF."
    }

    /// Dosya adı Türkçe harf taşımaz; paylaşılan uygulamalar bunu bozabiliyor.
    var fileName: String {
        let folded = childName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
        let slug = folded.unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) && $0.isASCII ? String($0) : "-" }
            .joined()
            .split(separator: "-").joined(separator: "-")
        return slug.isEmpty ? "masal-kitabi.pdf" : "\(slug)-masal-kitabi.pdf"
    }
}
