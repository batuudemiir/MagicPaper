import Foundation

/// Ebeveyn panelindeki "Kelime dağarcığı" bölümünün veri kaynağı.
/// Prototipteki sabit sayılar yerine okunan masalların gerçek metinlerinden
/// hesaplanır — ek bir backend gerekmez.
///
/// Ölçtüğü şeyin adı önemli: bunlar çocuğun okuduğu sayfalarda geçen **farklı**
/// kelimelerdir, "yeni öğrenilen kelimeler" değil. Bir kelimenin çocuk için
/// yeni olup olmadığını bilmenin yolu yok; ekran da artık bunu iddia etmiyor.
///
/// Dönem, masalın **oluşturulma** tarihine göre ayrılıyor, okunma tarihine
/// göre değil: okuma zamanı hiçbir yerde saklanmıyor. Mart'ta oluşturulup
/// Nisan'da okunan bir masal Mart'a yazılır. Bunu düzeltmek `Story`'ye bir
/// okuma damgası eklemeyi gerektirir.
enum MPVocabulary {

    struct Summary {
        /// Bu ayın masallarında, okunmuş sayfalarda geçen farklı kelime sayısı.
        let uniqueThisMonth: Int
        /// Geçen aya göre fark (+/-). Yalnızca `hasPreviousMonth` ise anlamlı.
        let deltaVsLastMonth: Int
        /// Geçen ay hiç masal üretilmemişse kıyas cümlesi gösterilmez —
        /// aksi hâlde "geçen aya göre +420" gibi anlamsız bir değer çıkıyordu.
        let hasPreviousMonth: Bool
        /// Son 7 günün günlük benzersiz kelime sayısı (Pzt→Paz sırasıyla değil,
        /// 6 gün önce → bugün sırasıyla). Grafik bu diziyi çizer.
        let lastSevenDays: [Int]

        var hasData: Bool { uniqueThisMonth > 0 }

        /// Tek günlük veride 7 çubuklu grafik tek dikme gibi görünüyor;
        /// en az iki gün veri yoksa grafik hiç çizilmez.
        var hasChart: Bool { lastSevenDays.filter { $0 > 0 }.count >= 2 }
    }

    /// Bir masalın **okunmuş** sayfalarındaki benzersiz kelimeler.
    ///
    /// Eskiden masalın bütün sayfaları sayılıyordu — açılmamış bir masal da
    /// dâhil. Oysa bölümün adı "kelime dağarcığı": hiç okunmamış bir masalın
    /// hiçbir kelimesiyle karşılaşılmamıştır. Üretilen ama okunmayan masallar
    /// sayıyı şişirip ebeveyne çocuğun öğrendiğinden fazlasını gösteriyordu.
    ///
    /// Okunan sayfa = `lastReadPage`'e kadar olanlar; bu değer okuyucunun
    /// ulaştığı **en ileri** sayfadır (`StoryReaderModel.persistProgress`).
    private static func words(in story: Story) -> Set<String> {
        guard let furthest = story.lastReadPage else { return [] }
        var set = Set<String>()
        for page in story.pages.prefix(furthest + 1) {
            let folded = MPText.foldedForSearch(page.text)
            for raw in folded.split(whereSeparator: { !$0.isLetter }) {
                // 2 harften kısa parçalar (bağlaçlar, ekler) sayılmaz.
                if raw.count > 2 { set.insert(String(raw)) }
            }
        }
        return set
    }

    static func summary(for stories: [Story], now: Date = Date()) -> Summary {
        let cal = Calendar.current

        func union(_ list: [Story]) -> Set<String> {
            list.reduce(into: Set<String>()) { $0.formUnion(words(in: $1)) }
        }

        let thisMonth = stories.filter {
            cal.isDate($0.createdAt, equalTo: now, toGranularity: .month)
        }
        let lastMonthDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let lastMonth = stories.filter {
            cal.isDate($0.createdAt, equalTo: lastMonthDate, toGranularity: .month)
        }

        let thisCount = union(thisMonth).count
        let lastCount = union(lastMonth).count

        let days: [Int] = (0..<7).reversed().map { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { return 0 }
            let ofDay = stories.filter { cal.isDate($0.createdAt, inSameDayAs: day) }
            return union(ofDay).count
        }

        return Summary(
            uniqueThisMonth: thisCount,
            deltaVsLastMonth: thisCount - lastCount,
            hasPreviousMonth: !lastMonth.isEmpty,
            lastSevenDays: days
        )
    }
}
