import SwiftUI

/// Bir okuma oturumunun *anlamlı* sayılıp sayılmadığı.
///
/// Bu tip, `MPStreak`'in kabul kapısıdır. Eskiden kapı yoktu: okuyucu açılır
/// açılmaz gün işaretleniyordu (`StoryReaderView.open()`'ın ilk satırı), yani
/// kaydedilen olay `StoryOpened`'dı. Ürünün kastettiği olay
/// `StoryReadingSessionCompleted` — "bir gün sayılmalıdır çünkü aile gerçekten
/// birlikte bir hikâye okudu".
///
/// ### Ölçüt: **bir sayfa ilerleme VEYA 30 saniye okuma**
///
/// İki ölçüt, çünkü tek başına hiçbiri yetmiyor:
///
/// - **Sayfa ilerlemesi** kitabın kendi kanıtıdır. Bir sayfayı çevirmek, o
///   sayfanın okunduğunu söyleyen tek doğal hareket. Kitap biçimli içerik için
///   doğru ölçüt bu, ve anında gerçekleşir — çocuk okurken serinin işaretlenmesi
///   için okuyucunun kapanmasını beklemek gerekmez.
/// - **Süre**, sayfası olmayan içerik için. Günlük masal tek parça metindir;
///   orada çevrilecek bir sayfa yok, ölçülebilecek tek şey okumaya ayrılan
///   zaman.
///
/// ### 30 saniye neden?
///
/// Yanlışlıkla açılan bir masal ilk on saniye içinde kapanır — kapak görülür,
/// "bu değilmiş" denir, geri dönülür. Sesli okunan tek bir MagicPaper sayfası
/// ise 30–60 saniye sürer. 30 saniye bu ikisinin arasındaki en geniş boşlukta
/// duruyor: her kazara açılışın üstünde, gerçekten okunan tek bir sayfanın
/// altında.
///
/// Süre *ön plandaki* süredir: uygulama arka plana geçtiğinde sayaç durur ve
/// geri dönüldüğünde kaldığı yerden devam eder (`StoryReaderView.pauseReading`).
/// Yani ekran kilitlenip açılan bir oturumun parçaları toplanır, cebe konmuş
/// bir telefon ise saymaz.
///
/// Eşik yükseltilmemeli: bu bir hedef değil, gürültü filtresidir. Bir aileye
/// "yeterince okumadınız" diyen bir sayı değil, "bu bir açılış kazasıydı"
/// diyen bir sayı.
struct MPReadingSession: Equatable {

    /// Sayfası olmayan içerik için süre eşiği.
    static let minimumSeconds: Double = 30

    /// Ön planda, okuyucu açıkken geçen süre.
    var secondsRead: Double
    /// Bu oturumda tamamlanan yaprak geçişi sayısı.
    var pagesTurned: Int

    init(secondsRead: Double, pagesTurned: Int) {
        self.secondsRead = secondsRead
        self.pagesTurned = pagesTurned
    }

    var isMeaningful: Bool {
        pagesTurned >= 1 || secondsRead >= Self.minimumSeconds
    }
}

/// Okuma serisi. Tasarımdaki "seri kartı" ve Günlük ekranındaki 7 günlük şerit
/// bu kayıttan beslenir.
///
/// Oyunlaştırma değil: okuma sürekliliği ve ailece hikâye ritüeli. Bir gün,
/// uygulama açıldığı için değil, **anlamlı bir okuma oturumu tamamlandığı için**
/// işaretlenir — kural `MPReadingSession`'da.
///
/// ### Çocuk başına (ürün kararı 2026-09-23)
///
/// Defter çocuğa aittir, aileye değil: anne Ali için hikâye okuduğunda Ece'nin
/// serisi devam etmemeli. Aile sahipliktir, çocuk deneyim. `activate(profileID:)`
/// hangi çocuğun defterinin açık olduğunu söyler; `ContentView` aktif profil
/// değiştikçe çağırır. Kurallar ve ekranların okuduğu değerler aynı kaldı —
/// yalnızca hangi defterden okundukları değişti.
///
/// Profilsiz örnek (`profileID == nil`) eski, cihaz geneli anahtarları kullanır;
/// testler ve geçiş bunun üzerine kurulu.
@MainActor
final class MPStreak: ObservableObject {
    static let shared = MPStreak()

    /// Cihaz geneli eski anahtarlar. Artık yalnızca geçişin kaynağı.
    nonisolated static let legacyDaysKey = "mp_readDays"
    nonisolated static let legacySecondsKey = "mp_readSeconds"
    /// Eski cihaz geneli defterin hangi çocuğa devredildiği. Bir kez yazılır.
    nonisolated static let legacyAssignedKey = "mp_streakLegacyAssignedTo"

    nonisolated static func daysKey(for profileID: UUID?) -> String {
        profileID.map { "\(legacyDaysKey).\($0.uuidString)" } ?? legacyDaysKey
    }

    nonisolated static func secondsKey(for profileID: UUID?) -> String {
        profileID.map { "\(legacySecondsKey).\($0.uuidString)" } ?? legacySecondsKey
    }

    /// Hangi çocuğun defteri açık. Nil: eski, cihaz geneli defter.
    private(set) var profileID: UUID?
    private var daysKey: String { Self.daysKey(for: profileID) }
    private var secondsKey: String { Self.secondsKey(for: profileID) }

    /// Defterin tuttuğu en uzun geçmiş.
    ///
    /// `mp_readDays` ve `mp_readSeconds` bugüne kadar hiç budanmıyordu: her
    /// okuma günü bir satır ekliyor, hiçbiri çıkmıyordu. Beş yıl okuyan bir
    /// aile `UserDefaults`'ta ~1800 girişlik iki koleksiyon taşıyacaktı ve
    /// `addReadingTime` her çağrıda sözlüğün tamamını okuyup geri yazdığı için
    /// bu maliyet her oturum kapanışında ödenecekti.
    ///
    /// 400 gün, çünkü ekranların hiçbiri bundan uzağa bakmıyor (en uzun
    /// pencere `currentStreak`, o da kesintiye kadar geriye yürüyor) ve 13 ay,
    /// "geçen yıl bugün" türü bir geri dönüşe yer bırakacak kadar geniş.
    /// Budama bir *kota* değil: kimse 400 günlük seriyi kaybetmesin diye
    /// pencere kesintisiz bir seriyi taşıyabilecek uzunlukta seçildi.
    static let retentionDays = 400

    /// Tek oturumda 2 saatten fazlası kayıt hatası sayılır (ekran açık unutulmuş).
    private static let sessionCeilingSeconds: Double = 2 * 60 * 60

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let fmt: DateFormatter

    @Published private(set) var readDays: Set<String>

    /// Testler saat dilimini, "şimdi"yi ve depoyu verebilsin diye enjekte
    /// edilebilir. Uygulamada tek örnek `shared` üzerinden kullanılır.
    init(defaults: UserDefaults = .standard,
         calendar: Calendar = .current,
         now: @escaping () -> Date = Date.init,
         profileID: UUID? = nil) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.profileID = profileID

        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        self.fmt = f

        if let profileID { Self.adoptLegacyLedgerIfNeeded(for: profileID, in: defaults) }
        self.readDays = Set(defaults.stringArray(forKey: Self.daysKey(for: profileID)) ?? [])
        prune()
    }

    // MARK: - Hangi çocuk

    /// Aktif çocuğun defterini açar. Aynı çocuk için ikinci çağrı bir şey yapmaz.
    func activate(profileID: UUID?) {
        guard profileID != self.profileID else { return }
        // `readSeconds` @Published değil; ekranlar yeni çocuğun süresini de görsün.
        objectWillChange.send()
        if let profileID { Self.adoptLegacyLedgerIfNeeded(for: profileID, in: defaults) }
        self.profileID = profileID
        readDays = Set(defaults.stringArray(forKey: daysKey) ?? [])
        prune()
    }

    /// Çocuk başına deftere geçiş: eski cihaz geneli defter, **ilk** etkinleşen
    /// çocuğa kopyalanır — geçiş anında seçili olan, yani o ana kadar okuyan çocuk.
    ///
    /// Kopyalanır, taşınmaz: eski anahtarlar yerinde kalır, hiçbir veri silinmez.
    /// Bir kez olur (`legacyAssignedKey`); ikinci bir çocuk eski geçmişi almaz,
    /// çünkü o geçmiş onun değildi. Çocuğun kendi defteri zaten varsa dokunulmaz.
    nonisolated static func adoptLegacyLedgerIfNeeded(for profileID: UUID, in defaults: UserDefaults) {
        guard defaults.string(forKey: legacyAssignedKey) == nil else { return }
        defaults.set(profileID.uuidString, forKey: legacyAssignedKey)

        let days = daysKey(for: profileID)
        let seconds = secondsKey(for: profileID)
        if defaults.object(forKey: days) == nil,
           let legacy = defaults.stringArray(forKey: legacyDaysKey) {
            defaults.set(legacy, forKey: days)
        }
        if defaults.object(forKey: seconds) == nil,
           let legacy = defaults.dictionary(forKey: legacySecondsKey) {
            defaults.set(legacy, forKey: seconds)
        }
    }

    /// Bir çocuğun defterini siler — profil silindiğinde.
    nonisolated static func eraseLedger(for profileID: UUID, in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: daysKey(for: profileID))
        defaults.removeObject(forKey: secondsKey(for: profileID))
    }

    /// Bütün defterler, eskisi ve çocuklarınki — "tüm verileri sil".
    nonisolated static func eraseAllLedgers(in defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix(legacyDaysKey) || key.hasPrefix(legacySecondsKey) || key == legacyAssignedKey {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Gün anahtarı

    private func dayKey(_ date: Date) -> String { fmt.string(from: date) }

    /// Hafta hesapları Pazartesi başlangıçlı, ama gün sınırı gövdedeki
    /// takvimle aynı saat diliminde olmalı.
    private var weekCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Pazartesi
        cal.timeZone = calendar.timeZone
        return cal
    }

    // MARK: - Günün işaretlenmesi

    /// Serinin tek giriş kapısı.
    ///
    /// `true` dönerse bugün bu çağrıyla işaretlendi (veya zaten işaretliydi);
    /// `false` dönerse oturum anlamlı bulunmadı ve hiçbir şey yazılmadı.
    @discardableResult
    func markReadingSession(_ session: MPReadingSession) -> Bool {
        guard session.isMeaningful else { return false }
        markReadToday()
        return true
    }

    /// Günü yazan ilkel işlem. Kasten `private`: bir günün işaretlenmesi
    /// yalnızca `markReadingSession` kapısından geçebilir, yoksa "açmak =
    /// okumak" hatası ilk uygun çağrı yerinde geri gelir.
    private func markReadToday() {
        let today = dayKey(now())
        guard !readDays.contains(today) else { return }
        var days = readDays
        days.insert(today)
        readDays = pruned(days)
        defaults.set(Array(readDays), forKey: daysKey)
    }

    var readToday: Bool {
        readDays.contains(dayKey(now()))
    }

    /// Kesintisiz gün sayısı. Bugün okunmadıysa dünden geriye sayar.
    var currentStreak: Int {
        var day = calendar.startOfDay(for: now())
        if !readDays.contains(dayKey(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
            guard readDays.contains(dayKey(day)) else { return 0 }
        }
        var count = 0
        while readDays.contains(dayKey(day)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Pazartesi→Pazar, bu haftanın okunmuş günleri.
    /// Haftanın bir gününün durumu.
    ///
    /// `[Bool]` yetmiyordu: kaçırılan bir Pazartesi ile henüz gelmemiş bir Cuma
    /// ikisi de `false` dönüyor, ekranda ikisi de boş daire olarak çiziliyordu.
    /// Çocuğa gelecek dört günü "kaçırdın" diye göstermek, alışkanlık kurmaya
    /// çalışan bir ekranın yapabileceği en ters şey.
    enum DayState { case done, missed, today, upcoming }

    var weekStates: [DayState] {
        let cal = weekCalendar
        let today = cal.startOfDay(for: now())
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else {
            return Array(repeating: .upcoming, count: 7)
        }
        return (0..<7).map { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else {
                return .upcoming
            }
            let read = readDays.contains(dayKey(day))
            if read { return .done }
            if day == today { return .today }
            return day < today ? .missed : .upcoming
        }
    }

    var thisWeek: [Bool] {
        let cal = weekCalendar
        let today = cal.startOfDay(for: now())
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return readDays.contains(dayKey(d))
        }
    }

    // MARK: - Okuma süresi
    //
    // Ebeveyn panelindeki "Bu hafta okuma" değeri eskiden okunan gün sayısından
    // uydurulmuştu. Artık okuyucu açık kaldığı süre gün gün biriktirilir.

    /// Gün ("yyyy-MM-dd") → o gün okunan saniye.
    private var readSeconds: [String: Double] {
        get { defaults.dictionary(forKey: secondsKey) as? [String: Double] ?? [:] }
        set { defaults.set(newValue, forKey: secondsKey) }
    }

    /// Okuyucu kapanırken ya da arka plana giderken çağrılır.
    ///
    /// Süre kapanış gününe toptan yazılmaz: gece yarısını aşan bir oturum
    /// gerçekte iki güne aittir ve günlük okuma bütçesi tam da bu ayrımın
    /// üstüne kuruludur. 23:50'de başlayıp 00:20'de biten bir masal, yarının
    /// bütçesinden yarım saat çalmamalı — ve dünün defterine yazılmalı.
    func addReadingTime(_ seconds: Double) {
        let clamped = min(max(seconds, 0), Self.sessionCeilingSeconds)
        guard clamped >= 1 else { return }
        let slices = daySlices(endingAt: now(), seconds: clamped)
        guard !slices.isEmpty else { return }

        // Bildirim değişimden ÖNCE. `readSeconds` `@Published` değil (değeri
        // `UserDefaults`'ta yaşıyor), bu yüzden bildirimi elle göndermek
        // gerekiyor — ama `ObservableObject` sözleşmesi "will", "did" değil:
        // sonradan gönderilen bir bildirim SwiftUI'ın o karede okuduğu değeri
        // bayat bırakabilir.
        objectWillChange.send()

        var map = readSeconds
        for slice in slices { map[slice.day, default: 0] += slice.seconds }
        readSeconds = pruned(map)
    }

    /// Bir oturumu takvim günlerine böler. Oturumun bittiği an bilinir, süresi
    /// bilinir; başlangıcı ikisinden çıkar.
    ///
    /// Testler için `internal`: gece yarısı bölünmesi saat dilimine bağlı bir
    /// kural ve enjekte edilmiş bir takvimle doğrulanabilmeli.
    func daySlices(endingAt end: Date, seconds: Double) -> [(day: String, seconds: Double)] {
        guard seconds > 0 else { return [] }
        let start = end.addingTimeInterval(-seconds)
        var out: [(day: String, seconds: Double)] = []
        var cursor = start
        // Tavan 2 saat olduğu için gerçekte en fazla iki dilim çıkar; sayaç
        // yalnızca bozuk bir takvimde sonsuz döngü olmasın diye.
        var steps = 0
        while cursor < end, steps < 8 {
            steps += 1
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: dayStart),
                  nextMidnight > cursor else { break }
            let sliceEnd = min(nextMidnight, end)
            let amount = sliceEnd.timeIntervalSince(cursor)
            if amount > 0 { out.append((dayKey(cursor), amount)) }
            cursor = sliceEnd
        }
        // Takvim hesabı tutmazsa süre kaybolmaz, kapanış gününe yazılır.
        if out.isEmpty { out.append((dayKey(end), seconds)) }
        return out
    }

    /// Bugün okunan süre, saniye. Günlük okuma bütçesi bunun üzerine kurulu.
    var secondsToday: Double {
        readSeconds[dayKey(now())] ?? 0
    }

    var minutesToday: Int { Int((secondsToday / 60).rounded()) }

    /// Bu hafta (Pzt→Paz) okunan toplam dakika.
    var minutesThisWeek: Int {
        let cal = weekCalendar
        let today = cal.startOfDay(for: now())
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return 0 }
        let map = readSeconds
        let total = (0..<7).reduce(0.0) { sum, offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { return sum }
            return sum + (map[dayKey(d)] ?? 0)
        }
        return Int((total / 60).rounded())
    }

    // MARK: - Budama

    /// Pencerenin dışında kalan en son gün. "yyyy-MM-dd" sözlük sırasında
    /// tarih sırasıyla aynı olduğu için karşılaştırma dizgi üzerinde yapılır —
    /// binlerce girişi `Date`'e çevirmeye gerek yok.
    private var cutoffKey: String {
        guard let cutoff = calendar.date(byAdding: .day, value: -Self.retentionDays, to: now()) else {
            return ""
        }
        return dayKey(cutoff)
    }

    private func pruned(_ days: Set<String>) -> Set<String> {
        let cutoff = cutoffKey
        guard !cutoff.isEmpty else { return days }
        return days.filter { $0 >= cutoff }
    }

    private func pruned(_ map: [String: Double]) -> [String: Double] {
        let cutoff = cutoffKey
        guard !cutoff.isEmpty else { return map }
        return map.filter { $0.key >= cutoff }
    }

    /// Açılışta bir kez. Budama yazma yollarında da yapılıyor, ama hiç okumayan
    /// bir kullanıcının eski defteri yalnızca burada küçülür.
    private func prune() {
        let days = pruned(readDays)
        if days.count != readDays.count {
            readDays = days
            defaults.set(Array(days), forKey: daysKey)
        }
        let map = readSeconds
        let kept = pruned(map)
        if kept.count != map.count {
            readSeconds = kept
        }
    }

    static let weekdayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
}
