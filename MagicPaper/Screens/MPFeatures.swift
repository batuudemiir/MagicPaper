import Foundation

/// Lansmanda kapalı tutulan, kodu duran özellikler.
///
/// Uyku modu (26 · kararan ekran, süre, sesli oturum, Live Activity, Siri
/// "Uyku modu") v2'de çıkar (karar 15 Ekim 2026,
/// `docs/UYKU_MODU_V2_PLANI.md`). Kapalıyken giriş noktaları gizlenir:
/// Ana sayfanın akşam kartı uyku masalı penceresini açar, masal sonu
/// "İyi geceler" okuyucuyu kapatır, `magicpaper://sleep` bu akşamın
/// masalına düşer.
enum MPFeatures {
    /// Faz 11 (11 Kasım 2026, `docs/VIZYON_PLANI.md`): uyku kapısı açıldı,
    /// varsayılan açık. İmzalı içerik akışı yine kapatabilir (`MPRemoteFlags`).
    static var sleepMode: Bool { MPRemoteFlags.value(.sleepMode, default: true) }
}

/// Uzaktan bayraklar (Faz 6): imzalı içerik akışından (`ContentFeed.flags`) gelir,
/// imza doğrulanmadan hiçbiri okunmaz. Yalnızca burada adı olan bayrak geçerli;
/// akış yeni bir ad getirse bile uygulama onu yok sayar. Akış yoksa varsayılan.
enum MPRemoteFlags {
    enum Flag: String, CaseIterable {
        case sleepMode
        /// Huni olaylarının gönderimi (Faz 6). Gizlilik politikası ve onay metni huniyi
        /// anlatana kadar kapalı; olaylar o zamana kadar yalnızca cihazda bekler.
        case funnelUpload
        /// "Önce masal" (Faz 8): ilk masal girişten önce. Hukuk onayına kadar kapalı.
        case storyBeforeAccount
    }

    private static let key = "mp_remoteFlags"

    static func value(_ flag: Flag, default fallback: Bool, defaults: UserDefaults = .standard) -> Bool {
        (defaults.dictionary(forKey: key) as? [String: Bool])?[flag.rawValue] ?? fallback
    }

    static func save(_ flags: [String: Bool]?, defaults: UserDefaults = .standard) {
        let known = Set(Flag.allCases.map(\.rawValue))
        defaults.set((flags ?? [:]).filter { known.contains($0.key) }, forKey: key)
    }
}
