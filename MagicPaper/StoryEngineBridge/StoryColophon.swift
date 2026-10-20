import Foundation

/// Bir masalı ürün çıktısı değil kitap yapan küçük metinler: ithaf ve künye.
///
/// "Bu masal İrem için yazıldı. 16 Ekim 2026, Cuma akşamı." ve
/// "MagicPaper Kitaplığı · İrem'in 12. masalı". Hepsi masalın zaten taşıdığı
/// bilgiden gelir (`createdAt`, sahibi, kitaplık); yeni bir şey saklanmaz.
enum StoryColophon {

    // MARK: - Sıra numarası

    /// Masalın, sahibinin masalları arasında yazıldığı sıraya göre kaçıncı
    /// olduğu. Kitaplıkta henüz olmayan masal (yeni yazılan) sona eklenir.
    ///
    /// Sayı `createdAt`'ten çıkarılır, saklanmaz: senkron eski bir masalı
    /// getirirse yerine oturur. Silinen masal sonrakileri bir öne alır;
    /// raftaki kitap sayısıyla tutarlı kalsın diye bu bilinçli.
    static func ordinal(of story: Story, among stories: [Story]) -> Int {
        let siblings = stories.filter { sameOwner($0, story) && $0.id != story.id }
        let earlier = siblings.filter { precedes($0, story) }
        return earlier.count + 1
    }

    /// Aynı çocuğun masalı mı: kimlik varsa kimlikle, eski masallarda adla.
    private static func sameOwner(_ a: Story, _ b: Story) -> Bool {
        if let ida = a.childProfileID, let idb = b.childProfileID { return ida == idb }
        return !a.childName.isEmpty && a.childName == b.childName
    }

    /// Aynı anda yazılmış iki masal da her seferinde aynı sırada dursun.
    private static func precedes(_ a: Story, _ b: Story) -> Bool {
        a.createdAt != b.createdAt ? a.createdAt < b.createdAt : a.id.uuidString < b.id.uuidString
    }

    // MARK: - İthaf

    struct Dedication: Equatable {
        /// "Bu masal İrem için yazıldı."
        let line: String
        /// "16 Ekim 2026, Cuma akşamı"
        let date: String
    }

    /// Yalnızca bir çocuk için yazılmış masallarda: başlangıç kitapları ve
    /// sahipsiz masallar ithafsız kalır.
    static func hasDedication(_ story: Story) -> Bool {
        !story.childName.isEmpty && !SampleStoryRecognizer.isSample(story)
    }

    static func dedication(childName: String, date: Date,
                           calendar: Calendar = .current) -> Dedication {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        let hour = calendar.component(.hour, from: date)
        return Dedication(
            line: "Bu masal \(childName) için yazıldı.",
            date: "\(formatter.string(from: date)) \(partOfDay(hour))"
        )
    }

    /// "akşamı": günün hangi bölümünde yazıldığı, tamlama ekiyle.
    private static func partOfDay(_ hour: Int) -> String {
        switch hour {
        case 5..<12: "sabahı"
        case 12..<18: "öğleden sonrası"
        case 18..<22: "akşamı"
        default: "gecesi"
        }
    }

    // MARK: - Künye

    /// "MagicPaper Kitaplığı · İrem'in 12. masalı"
    static func colophon(childName: String, ordinal: Int) -> String {
        let nth = ordinal <= 1 ? "ilk" : "\(ordinal)."
        return "MagicPaper Kitaplığı · \(SeriesCopy.genitive(childName)) \(nth) masalı"
    }
}
