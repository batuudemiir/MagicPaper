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
    @Published var childMode: Bool { didSet { d.set(childMode, forKey: K.childMode) } }
    @Published var reminder: Bool { didSet { d.set(reminder, forKey: K.reminder) } }
    @Published var approve: Bool { didSet { d.set(approve, forKey: K.approve) } }
    @Published var screenLimit: Bool { didSet { d.set(screenLimit, forKey: K.screenLimit) } }

    /// Okunmuş masal id'leri — "seri" ve onay kuyruğu için.
    @Published var approvedStoryIDs: Set<String> {
        didSet { d.set(Array(approvedStoryIDs), forKey: K.approved) }
    }

    private enum K {
        static let readAloud = "mp_readAloud"
        static let readSize = "mp_readSize"
        static let childMode = "mp_childMode"
        static let reminder = "mp_reminder"
        static let approve = "mp_approveBeforeShow"
        static let screenLimit = "mp_screenLimit"
        static let approved = "mp_approvedStoryIDs"
        static let seeded = "mp_settingsSeeded"
    }

    private init() {
        // Tasarımdaki varsayılanlar: hatırlatma açık, onay kapalı, ekran süresi açık.
        if !d.bool(forKey: K.seeded) {
            d.set(true, forKey: K.reminder)
            d.set(false, forKey: K.approve)
            d.set(true, forKey: K.screenLimit)
            d.set(false, forKey: K.readAloud)
            d.set(false, forKey: K.childMode)
            d.set(MP.ReadSize.normal.rawValue, forKey: K.readSize)
            d.set(true, forKey: K.seeded)
        }
        readAloud = d.bool(forKey: K.readAloud)
        readSizeRaw = d.string(forKey: K.readSize) ?? MP.ReadSize.normal.rawValue
        childMode = d.bool(forKey: K.childMode)
        reminder = d.bool(forKey: K.reminder)
        approve = d.bool(forKey: K.approve)
        screenLimit = d.bool(forKey: K.screenLimit)
        approvedStoryIDs = Set(d.stringArray(forKey: K.approved) ?? [])
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
