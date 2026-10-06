import Foundation

/// İlgi alanları ekran metinlerinin tek kaynağı (FAZ 12).
///
/// Metinler geçici: İrem gözden geçirecek. Görünümler metni burada okur,
/// satır içine yazmaz; değişiklik yalnızca bu dosyada olur. Çip adları
/// ("Hayvanlar", "Doğa"…) burada değil, katalogdaki sözlükte durur: sözlük
/// açık bir küme, yeni bir kelime uygulama güncellenmeden gelebilir.
enum InterestCopy {

    // MARK: - Profil oluşturma

    static let question = "Neleri sever?"
    static let questionHint = "İstersen sonra da seçebilirsin. En fazla \(ChildInterests.maxSelection) tane."

    // MARK: - Ebeveyn > Çocuklar

    static let sectionTitle = "İlgi alanları"
    static let sectionSubtitle = "Masallar sevdiği şeylere biraz daha sık uğrar."
    static let rowSymbol = "heart"
    static let noneSelected = "Henüz seçilmedi"

    static func summary(_ names: [String]) -> String {
        names.isEmpty ? noneSelected : names.joined(separator: ", ")
    }

    static func rowAccessibility(child: String, names: [String]) -> String {
        "\(child), ilgi alanları: \(summary(names))"
    }

    static let rowHint = "İlgi alanlarını düzenler"

    // MARK: - Düzenleme sayfası

    static func editorTitle(child: String) -> String { "\(child) neleri sever?" }
    static let editorNote = "Masallar yine her şeyden olabilir; seçtiklerin biraz daha sık gelir."
    static let save = "Kaydet"
    static let saved = "İlgi alanları kaydedildi"

    // MARK: - Çipler

    static let limitHint = "En fazla \(ChildInterests.maxSelection) seçebilirsin. Önce birini kaldır."
}
