import Foundation
import FirebaseFirestore

/// Onaylı anonim huni (Faz 6, `docs/STARTUP_PLANI.md` başarı ölçütleri).
///
/// Bir ailenin ilk haftasında birkaç dönüm noktası, her biri kurulum başına **bir kez**:
/// ilk açılış, ilk masal, ilk biten masal, hesap, "Büyükler için"i bulma, ilk haftada
/// okunan gün sayısı. Giden şey yalnızca adım, kurulumdan beri geçen gün ve süre kovası.
/// Ad, yaş, kimlik, cihaz, tarih, saat ve masal **gitmez**: iki olay aynı aileye
/// bağlanamaz. Üçüncü taraf analitik yok (App Store 5.1.4).
///
/// Okuma olaylarıyla aynı kapı: ebeveynin "Kullanım verisini paylaş" anahtarı açık,
/// onay metni görülmüş ve hesap var (`AccountService.afterSync`). O zamana kadar olaylar
/// cihazda bekler; anahtar kapalıysa hiç gitmez.
struct MPFunnel {

    enum Step: String, CaseIterable, Codable, Sendable {
        case firstOpen, firstStory, firstFinish, account, parentRoom, firstWeek
    }

    /// Sunucuya giden biçim; anahtarları `firebase/firestore.rules` `validFunnel` ile sözleşme.
    struct Wire: Codable, Equatable, Sendable {
        static let schemaVersion = 1
        var schemaVersion = Wire.schemaVersion
        let step: String
        /// Kurulumdan beri geçen gün, 0-400.
        let days: Int
        /// İlk masal ve ilk bitiş: ilk açılıştan beri saniye, kovaya yuvarlanmış.
        /// İlk hafta: okunan gün sayısı (0-7).
        let value: Int?

        var fields: [String: Any] {
            var out: [String: Any] = ["schemaVersion": schemaVersion, "step": step, "days": days]
            if let value { out["value"] = value }
            return out
        }
    }

    /// Süre kesin değil, kova: kaba sayı bir aileyi işaret etmez.
    static let secondBuckets = [15, 30, 60, 120, 300, 600, 1_800, 3_600, 21_600, 86_400, 604_800]

    static func bucket(seconds: TimeInterval) -> Int {
        secondBuckets.first { Double($0) >= seconds } ?? secondBuckets.last! * 2
    }

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
    }

    private enum K {
        static let installedAt = "mp_funnel_installedAt"
        static let done = "mp_funnel_done"
        static let pending = "mp_funnel_pending"
        static let readDays = "mp_funnel_readDays"
    }

    var installedAt: Date {
        if let date = defaults.object(forKey: K.installedAt) as? Date { return date }
        let date = now()
        defaults.set(date, forKey: K.installedAt)
        return date
    }

    private var done: Set<String> { Set(defaults.stringArray(forKey: K.done) ?? []) }

    var pending: [Wire] {
        (defaults.data(forKey: K.pending)).flatMap { try? JSONDecoder().decode([Wire].self, from: $0) } ?? []
    }

    private func setPending(_ wires: [Wire]) {
        defaults.set(try? JSONEncoder().encode(wires), forKey: K.pending)
    }

    private var daysSinceInstall: Int {
        let start = calendar.startOfDay(for: installedAt)
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now())).day ?? 0
        return min(max(days, 0), 400)
    }

    /// Adımı bir kez kaydeder; ikinci çağrı hiçbir şey yapmaz.
    func record(_ step: Step) {
        guard !done.contains(step.rawValue) else { return }
        let value: Int?
        switch step {
        case .firstStory, .firstFinish: value = Self.bucket(seconds: now().timeIntervalSince(installedAt))
        default: value = nil
        }
        defaults.set(Array(done.union([step.rawValue])), forKey: K.done)
        setPending(pending + [Wire(step: step.rawValue, days: daysSinceInstall, value: value)])
    }

    /// Açılışta: kurulum tarihini sabitler, ilk açılışı ve yedinci günden sonra ilk haftayı yazar.
    func appOpened() {
        _ = installedAt
        record(.firstOpen)
        guard daysSinceInstall >= 7, !done.contains(Step.firstWeek.rawValue) else { return }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: installedAt)) ?? installedAt
        let days = readDays.filter { $0 < weekEnd }.count
        defaults.set(Array(done.union([Step.firstWeek.rawValue])), forKey: K.done)
        setPending(pending + [Wire(step: Step.firstWeek.rawValue, days: daysSinceInstall, value: min(days, 7))])
    }

    /// Bir masal bitti: ilk bitişi ve ilk haftanın okuma gününü yazar. Günler yalnızca
    /// cihazda, ilk hafta sayısı için; kendileri gitmez.
    func storyFinished() {
        record(.firstFinish)
        let today = calendar.startOfDay(for: now())
        guard today < calendar.date(byAdding: .day, value: 8, to: calendar.startOfDay(for: installedAt)) ?? today else { return }
        var days = readDays
        guard !days.contains(today) else { return }
        days.append(today)
        defaults.set(days, forKey: K.readDays)
    }

    private var readDays: [Date] { defaults.array(forKey: K.readDays) as? [Date] ?? [] }

    /// Gönderilenler kuyruktan düşer; gönderim başarısızsa olaylar bekler.
    func flush(sharingOn: Bool, consentGiven: Bool, signedIn: Bool,
               send: ([Wire]) async throws -> Void) async {
        let batch = pending
        guard sharingOn, consentGiven, signedIn, !batch.isEmpty else { return }
        do {
            try await send(batch)
            setPending(Array(pending.dropFirst(batch.count)))
        } catch {
            return
        }
    }

    /// Ebeveyn paylaşımı kapattığında bekleyenler silinir: sonra açılırsa eskiler gitmez.
    func discardPending() { setPending([]) }

    /// `funnelEvents/{auto}`: yalnızca ekleme, okuma yok, hesap kimliği yok.
    static func firestoreSend(_ wires: [Wire]) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        for wire in wires { batch.setData(wire.fields, forDocument: db.collection("funnelEvents").document()) }
        try await batch.commit()
    }
}
