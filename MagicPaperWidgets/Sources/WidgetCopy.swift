import Foundation

/// Widget ve Live Activity metinlerinin tek yeri (FAZ 19).
///
/// Ton CLAUDE.md §7: sakin; hedef, "kaldı", geri sayım baskısı yok. Teslimdeki
/// "3/4 akşam" halkası ve "1 kaldı" bu yüzden haftalık bir hedef olmadan,
/// yalnızca okunan akşamlarla çizilir.
enum WidgetCopy {

    // MARK: Bu akşamın masalı

    static func eyebrow(_ tonight: MPTonight) -> String {
        switch tonight {
        case .bedtime(let bedtime): "Saat \(bedtime.clockLabel)"
        case .resume: "Kaldığın yerden"
        case .unread: "Bu akşamın masalı"
        case .readToday: "Bugün okudun"
        }
    }

    static func title(_ tonight: MPTonight) -> String {
        switch tonight {
        case .bedtime: "Uyku masalı zamanı"
        case .resume(let resume): resume.title
        case .unread(let daily): daily.title
        case .readToday: "Yarın yeni bir masal hazır olacak"
        }
    }

    static func detail(_ tonight: MPTonight) -> String? {
        switch tonight {
        case .bedtime: nil
        case .resume(let resume): "Sayfa \(resume.page) / \(resume.pageCount)"
        case .unread(let daily): "\(daily.minutes) dakika"
        case .readToday: nil
        }
    }

    static let noChildEyebrow = "MagicPaper"
    static let noChildTitle = "Masal kitaplığın burada"

    static let tonightName = "Bu akşamın masalı"
    static let tonightDescription = "Uygulamayı açmadan bu akşamın masalı."

    // MARK: Haftalık okuma

    static let weekEyebrow = "Bu hafta"
    static func weekCount(_ count: Int) -> String { "\(count)" }
    static let weekUnit = "akşam okundu"
    static let weekStart = "Okuma yolculuğun burada başlıyor"
    static func weekLine(_ count: Int) -> String {
        count == 0 ? weekStart : "\(count) akşam okundu"
    }
    static func weekAccessibility(_ count: Int) -> String {
        count == 0 ? weekStart : "Bu hafta \(count) akşam masal okundu"
    }
    static let dayLetters = ["P", "S", "Ç", "P", "C", "C", "P"]
    static let weekName = "Okuma haftası"
    static let weekDescription = "Bu hafta birlikte okunan akşamlar."

    // MARK: Seri

    static func seriesEyebrow(_ episode: Int, ready: Bool) -> String {
        ready ? "Seri · \(episode). bölüm hazır" : "Seri · \(episode). bölüm yarın"
    }
    static let noSeriesTitle = "Devam eden seri yok"
    static let noSeriesBody = "Sevdiğin bir masalın sonunda “Devam ettir”e dokun."
    static let seriesName = "Seri"
    static let seriesDescription = "Devam eden serinin sıradaki bölümü."

    // MARK: Kilit ekranı

    static let lockName = "Masal saati"
    static let lockDescription = "Yatma saati ve bu hafta okunan akşamlar."

    // MARK: Uyku modu (Live Activity)

    static let sleepTitle = "Uyku modu"
    static let sleepReading = "Masal sesli okunuyor"
    static let sleepPaused = "Duraklatıldı"
    static let sleepFinished = "İyi uykular"
    static let sleepStop = "Durdur"
    static let sleepStopAccessibility = "Uyku modunu kapat"
}
