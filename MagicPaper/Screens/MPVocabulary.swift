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

    // MARK: - Yeni kelimelerim (FAZ 17)

    /// Çocuğun masallarda karşılaştığı, sözlükten gelen bir kelime.
    struct CollectedWord: Identifiable, Equatable {
        let word: StoryWord
        /// İlk karşılaştığı masalın adı.
        let storyTitle: String
        let storyID: UUID
        /// İlk karşılaşma: masalın son okunduğu an, yoksa yazıldığı gün.
        let date: Date
        /// Kelimenin o masalda geçtiği cümle (`sentence(containing:in:)`).
        /// Yazılış sayfada bulunamazsa `nil`; kart cümlesiz çizilir.
        var sentence: String? = nil
        var id: String { word.id }
    }

    /// Okunmuş sayfalardaki (`lastReadPage`'e kadar) öğretilen kelimeler,
    /// tekrarsız (sözlük kimliğine göre), en yeniden eskiye.
    ///
    /// Bunlar bir yazarın bu bant için "yeni" diye işaretlediği kelimelerdir;
    /// çocuğun gerçekten bilmediğini iddia etmez. Okunmamış sayfanın kelimesi
    /// sayılmaz: hiç karşılaşılmamış bir kelime toplanmış olamaz.
    static func collectedWords(in stories: [Story]) -> [CollectedWord] {
        var earliest: [String: CollectedWord] = [:]
        for story in stories {
            guard let furthest = story.lastReadPage else { continue }
            let date = story.lastReadAt ?? story.createdAt
            for page in story.pages.prefix(furthest + 1) {
                for word in page.words ?? [] {
                    if let known = earliest[word.id], known.date <= date { continue }
                    earliest[word.id] = CollectedWord(word: word, storyTitle: story.title,
                                                      storyID: story.id, date: date,
                                                      sentence: sentence(containing: word.surface, in: page.text))
                }
            }
        }
        return earliest.values.sorted {
            $0.date == $1.date ? $0.word.term < $1.word.term : $0.date > $1.date
        }
    }

    // MARK: - Masaldaki cümle (21 Ekim 2026)

    /// Kartta en fazla üç satır: bundan uzun cümle kelime sınırında kesilir.
    static let sentenceLimit = 140

    private static let turkish = Locale(identifier: "tr_TR")
    private static let terminators: Set<Character> = [".", "!", "?", "…"]
    private static let closers: Set<Character> = ["\"", "”", "’", "»", ")"]
    private static let openers: Set<Character> = ["\"", "“", "‘", "«", "(", "—", "–", "-"]

    /// `surface`'in geçtiği cümle, kartta gösterilecek uzunlukta.
    ///
    /// Birden çok cümlede geçerse sığan ilk cümle, hiçbiri sığmıyorsa en kısası
    /// alınır. Arama `ReaderWords` gibi Türkçe büyük/küçük harf katlamasıyla
    /// yapılır ("Işık" ışık'tır, "İşık" değildir).
    static func sentence(containing surface: String, in text: String) -> String? {
        let needle = surface.lowercased(with: turkish)
        guard !needle.isEmpty else { return nil }
        let matches = sentences(in: text).filter { $0.lowercased(with: turkish).contains(needle) }
        guard let chosen = matches.first(where: { $0.count <= sentenceLimit })
                ?? matches.min(by: { $0.count < $1.count }) else { return nil }
        return trimmed(chosen, around: needle)
    }

    /// Paragraf sonu her zaman böler. Paragraf içinde `. ! ? …` (ardından
    /// kapanan tırnak olabilir) yalnız sonraki karakter büyük harf, rakam,
    /// açılan tırnak ya da tire ise böler: "fener! dedi Ragi" tek cümledir.
    private static func sentences(in text: String) -> [String] {
        var out: [String] = []
        for paragraph in text.split(whereSeparator: \.isNewline) {
            let chars = Array(paragraph.split(whereSeparator: \.isWhitespace).joined(separator: " "))
            var start = 0
            var i = 0
            while i < chars.count {
                if terminators.contains(chars[i]) {
                    var end = i + 1
                    while end < chars.count, terminators.contains(chars[end]) || closers.contains(chars[end]) { end += 1 }
                    if end + 1 < chars.count, chars[end] == " " {
                        let next = chars[end + 1]
                        if next.isUppercase || next.isNumber || openers.contains(next) {
                            out.append(String(chars[start..<end]))
                            start = end + 1
                            i = start
                            continue
                        }
                    }
                    i = end
                } else {
                    i += 1
                }
            }
            if start < chars.count { out.append(String(chars[start...])) }
        }
        return out.filter { !$0.isEmpty }
    }

    /// Uzun cümleden kelimeyi içeren, `sentenceLimit`'e sığan bir parça.
    /// Kelime cümlenin başına yakınsa baş korunur; değilse kelimenin
    /// çevresinden alınır. Kesilen uç "…" ile gösterilir.
    private static func trimmed(_ sentence: String, around needle: String) -> String {
        guard sentence.count > sentenceLimit else { return sentence }
        let tokens = sentence.split(separator: " ").map(String.init)
        guard let target = tokens.firstIndex(where: { $0.lowercased(with: turkish).contains(needle) }) else {
            return sentence
        }
        func length(_ range: ClosedRange<Int>) -> Int {
            tokens[range].reduce(range.count - 1) { $0 + $1.count }
        }
        var range = target...target
        // Önce sağa: cümlenin başı korunabiliyorsa okunuşu bozulmaz.
        var head = 0...0
        while head.upperBound + 1 < tokens.count, length(0...(head.upperBound + 1)) <= sentenceLimit {
            head = 0...(head.upperBound + 1)
        }
        if head.contains(target) {
            range = head
        } else {
            var grew = true
            while grew {
                grew = false
                if range.upperBound + 1 < tokens.count,
                   length(range.lowerBound...(range.upperBound + 1)) <= sentenceLimit {
                    range = range.lowerBound...(range.upperBound + 1); grew = true
                }
                if range.lowerBound > 0,
                   length((range.lowerBound - 1)...range.upperBound) <= sentenceLimit {
                    range = (range.lowerBound - 1)...range.upperBound; grew = true
                }
            }
        }
        var piece = tokens[range].joined(separator: " ")
        if range.lowerBound > 0 { piece = "… " + piece }
        if range.upperBound < tokens.count - 1 { piece += " …" }
        return piece
    }

    /// Son yedi günde toplananlar ("Bu hafta").
    static func collectedThisWeek(_ words: [CollectedWord], now: Date = Date()) -> [CollectedWord] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? .distantPast
        return words.filter { $0.date >= start }
    }
}
