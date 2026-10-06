import SwiftUI

/// Tasarımdaki Ayarlar ekranının (03-SCREENS.md §13) tuttuğu tercihler.
/// Mevcut uygulamada karşılığı olmayan anahtarlar burada yeni oluşturulur;
/// okuma tercihleri okuyucuyla paylaşılır.
@MainActor
final class MPSettingsStore: ObservableObject {
    static let shared = MPSettingsStore()

    private let d = UserDefaults.standard

    @Published var readAloud: Bool { didSet { d.set(readAloud, forKey: K.readAloud) } }
    @Published var readSizeRaw: String { didSet { d.set(readSizeRaw, forKey: K.readSize) } }
    @Published var reminder: Bool { didSet { d.set(reminder, forKey: K.reminder) } }
    @Published var approve: Bool { didSet { d.set(approve, forKey: K.approve) } }
    @Published var screenLimit: Bool { didSet { d.set(screenLimit, forKey: K.screenLimit) } }
    /// Günlük okuma bütçesi, dakika. Ekrandaki "Günde 30 dakika" sabit bir
    /// metindi; artık seçilen değerin kendisi.
    @Published var screenLimitMinutes: Int { didSet { d.set(screenLimitMinutes, forKey: K.screenLimitMinutes) } }
    /// Hatırlatma saati. "Her akşam 20.30" da sabit bir metindi — çocuğu
    /// 19.30'da yatan bir evde işe yaramaz bir saat.
    @Published var reminderHour: Int { didSet { d.set(reminderHour, forKey: K.reminderHour) } }
    @Published var reminderMinute: Int { didSet { d.set(reminderMinute, forKey: K.reminderMinute) } }
    /// Dokunsal geri bildirim — okuyucudaki sayfa çevirme dokunuşu buna bakar.
    @Published var haptics: Bool { didSet { d.set(haptics, forKey: K.haptics) } }

    /// Anonim okuma olaylarının paylaşılması (FAZ 14). Gönderim FAZ 16'da;
    /// kapatmak bekleyen olayları da siler. Yerel öğrenme bundan bağımsız:
    /// çocuğun kendi okuma kaydı cihazdan hiç çıkmaz.
    @Published var shareUsageData: Bool {
        didSet {
            d.set(shareUsageData, forKey: K.shareUsageData)
            if !shareUsageData { ReadingEventQueue().eraseAll() }
        }
    }

    /// Okunmuş masal id'leri — "seri" ve onay kuyruğu için.
    @Published var approvedStoryIDs: Set<String> {
        didSet { d.set(Array(approvedStoryIDs), forKey: K.approved) }
    }

    private enum K {
        static let readAloud = "mp_readAloud"
        static let readSize = "mp_readSize"
        static let reminder = "mp_reminder"
        static let approve = "mp_approveBeforeShow"
        static let screenLimit = "mp_screenLimit"
        static let screenLimitMinutes = "mp_screenLimitMinutes"
        static let reminderHour = "mp_reminderHour"
        static let reminderMinute = "mp_reminderMinute"
        static let approved = "mp_approvedStoryIDs"
        static let haptics = "mp_haptics"
        static let shareUsageData = "mp_shareUsageData"
        static let seeded = "mp_settingsSeeded"
    }

    private init() {
        // Tasarımdaki varsayılanlar: hatırlatma açık, onay kapalı, ekran süresi açık.
        if !d.bool(forKey: K.seeded) {
            d.set(true, forKey: K.reminder)
            d.set(false, forKey: K.approve)
            d.set(true, forKey: K.screenLimit)
            d.set(false, forKey: K.readAloud)
            d.set(MP.ReadSize.normal.rawValue, forKey: K.readSize)
            d.set(true, forKey: K.seeded)
        }
        readAloud = d.bool(forKey: K.readAloud)
        readSizeRaw = d.string(forKey: K.readSize) ?? MP.ReadSize.normal.rawValue
        reminder = d.bool(forKey: K.reminder)
        approve = d.bool(forKey: K.approve)
        screenLimit = d.bool(forKey: K.screenLimit)
        approvedStoryIDs = Set(d.stringArray(forKey: K.approved) ?? [])
        // `seeded` bloğuna eklenemez: o blok yalnızca ilk kurulumda çalışır ve
        // mevcut kullanıcılarda bir daha çalışmaz, dolayısıyla oraya konan yeni
        // bir varsayılan onlara hiç ulaşmaz. Anahtarın yokluğu "açık" demektir.
        haptics = d.object(forKey: K.haptics) == nil ? true : d.bool(forKey: K.haptics)
        // Varsayılan açık (karar: 6 Ekim 2026). FAZ 16'daki ebeveyn onayı
        // metni bunu açıkça söyler.
        shareUsageData = d.object(forKey: K.shareUsageData) == nil ? true : d.bool(forKey: K.shareUsageData)
        // Aynı sebeple `seeded` bloğunun dışında: bu üç değer ekranda zaten
        // yazılı olan sabitlerin (30 dakika, 20.30) yerini alıyor, yani
        // anahtarı olmayan bir kullanıcıda ekranın bugüne kadar söylediği şey
        // ne ise o.
        let storedLimit = d.integer(forKey: K.screenLimitMinutes)
        screenLimitMinutes = storedLimit > 0 ? storedLimit : 30
        reminderHour = d.object(forKey: K.reminderHour) == nil ? 20 : d.integer(forKey: K.reminderHour)
        reminderMinute = d.object(forKey: K.reminderMinute) == nil ? 30 : d.integer(forKey: K.reminderMinute)
    }

    /// Var olan masalları toplu onaylar.
    ///
    /// Onay kapısı açıldığı anda kütüphanedeki her şey birden görünmez olsaydı,
    /// ebeveyn bir anahtara dokunup çocuğun rafını boşaltmış olurdu — üstelik
    /// o masalların hepsi zaten okunmuştu. Kapı ileriye doğru çalışır: bundan
    /// sonra üretilen masallar onay bekler.
    func approveStories(_ ids: [UUID]) {
        approvedStoryIDs.formUnion(ids.map(\.uuidString))
    }

    var readSize: MP.ReadSize {
        get { MP.ReadSize(rawValue: readSizeRaw) ?? .normal }
        set { readSizeRaw = newValue.rawValue }
    }

    func approveStory(_ id: UUID) {
        approvedStoryIDs.insert(id.uuidString)
    }

    func isApproved(_ id: UUID) -> Bool {
        approvedStoryIDs.contains(id.uuidString)
    }
}
