import Foundation
import StoryEngine

/// Seri (FAZ 13) ekran metinlerinin tek kaynağı.
///
/// Metinler geçici: İrem gözden geçirecek. Görünümler metni burada okur,
/// satır içine yazmaz. Ton CLAUDE.md §7'deki gibi: sakin, geri sayımsız,
/// "kaçırma" baskısı yok. Bildirim yok; bölüm kitaplıkta ve kartta bekler.
enum SeriesCopy {

    static let episodeCount = 5

    // MARK: - Masalın sonu

    static let continueButton = "Devam ettir"
    static let continueHint = "Bu masal dört bölüm daha sürsün. Her gün bir bölüm."
    static let continueAccessibilityHint = "Masalın devamını hazırlar; her gün bir bölüm açılır"

    /// Çocuğun başka bir serisi sürerken (karar 2): düğme yerine bu satır.
    static func blocked(child: String) -> String {
        "\(genitive(child)) bir serisi sürüyor. O bitince bu masala da devam edebilirsiniz."
    }

    static let started = "Devamı hazır. İlk bölüm yarın kitaplığında olacak."
    static let startedToast = "Masalın devamı hazırlandı"
    static let startFailed = "Bu masal şimdilik devam ettirilemiyor."

    static func episodeOf(_ number: Int) -> String {
        "\(number). bölüm · \(episodeCount) bölümlük seri"
    }
    static let nextEpisode = "Yarın yeni bölüm kitaplığında olacak."

    // MARK: - Seri tamamlandı

    static let completedTitle = "Seri tamamlandı"
    static let completedBody = "Beş bölümün hepsi okundu. Hepsi kitaplığında, istediğin zaman yeniden okuyabilirsin."

    // MARK: - Ana sayfa ve kitaplık kartı

    static let cardEyebrow = "SERİ"
    static func readyTitle(_ number: Int) -> String { "\(number). bölüm hazır" }
    static func waitingTitle(_ number: Int) -> String { "\(number). bölüm yarın" }
    static func cardSubtitle(_ title: String) -> String { title }
    static let readyAction = "Oku"
    static let waitingNote = "Bir önceki bölüm okununca, ertesi gün açılır."
    static func readyAccessibility(_ number: Int, _ title: String) -> String {
        "\(title), \(number). bölüm hazır. Okumak için dokun."
    }
    static func waitingAccessibility(_ number: Int, _ title: String) -> String {
        "\(title), \(number). bölüm bir önceki bölüm okununca, ertesi gün açılır."
    }

    // MARK: - Kitaplık satırı

    /// "2. bölüm" — kitaplıkta bir bölümün rozeti.
    static func episodeBadge(_ story: MagicPaper.Story) -> String? {
        story.origin?.seriesEpisode.map { "\($0). bölüm" }
    }

    // MARK: - Geliştirici (yalnız DEBUG)

    static let debugAdvance = "Seri saatini bir gün ileri al"
    static let debugReset = "Seri saatini sıfırla"

    // MARK: - Dil

    /// "Yeliz'in", "Can'ın", "Nuri'nin": adın ünlü uyumuyla.
    static func genitive(_ name: String) -> String {
        TurkishGrammar.inflect(TurkishNoun(name, isProperNoun: true), into: .genitive)
    }
}
