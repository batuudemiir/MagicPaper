import Foundation

/// The consent text the parent agrees to (KVKK açık rıza), versioned.
///
/// Changing a word here means a new `version`: every parent is asked again on
/// their next launch, and the account keeps both records. Ses kaydı (FAZ 18)
/// is not in this text; when it arrives, the text and its version change.
///
/// Hukuki gözden geçirme bekliyor: metin ajan taslağıdır.
enum ParentConsentText {
    static let version = "2026-10-06"

    struct Section: Identifiable, Equatable {
        let title: String
        let body: String
        var id: String { title }
    }

    static let title = "Ebeveyn onayı"

    static let lead = "MagicPaper'ı çocuğunuz için kullanmadan önce, hangi bilgilerin nerede saklandığını okuyup onaylamanızı istiyoruz."

    static let sections: [Section] = [
        Section(
            title: "Hesabınızda saklananlar",
            body: "Çocuğunuzun adı ve yaşı, sevdiği şeyler, kitap karakteri, Masal ailem'e eklediğiniz adlar, yazılan masallar, seriler ve okuma ilerlemesi. Bunlar telefonunuz değişse de kaybolmasın diye hesabınızda tutulur."),
        Section(
            title: "Saklanmayanlar",
            body: "Çocuk fotoğrafı hiçbir yere gönderilmez. Ses kaydı yapılmaz. Çocuğunuz giriş yapmaz; hesap sizindir. E-posta adresiniz ve adınız MagicPaper tarafından saklanmaz."),
        Section(
            title: "Nerede",
            body: "Bilgiler Google Firebase sunucularında, yalnızca sizin hesabınızın erişebileceği biçimde saklanır. Sunucular yurt dışında olabilir; bu onay, bilgilerin bu amaçla yurt dışına aktarılmasını da kapsar."),
        Section(
            title: "Okuma bilgisi",
            body: "Açık bırakırsanız hangi masalların bitirildiği, ad, yaş, hesap ve cihaz bilgisi olmadan, masalları iyileştirmek için paylaşılır. Bu bilgi hesabınıza bağlanmaz. Ayarlar > Gizlilik ve veri'den istediğiniz zaman kapatabilirsiniz."),
        Section(
            title: "Haklarınız",
            body: "Onayınızı istediğiniz zaman geri alabilirsiniz: Ayarlar > Gizlilik ve veri > Hesabı sil, hesabınızı ve sunucudaki bütün bilgileri kalıcı olarak siler. Sorularınız için: support@magicpaperkids.com"),
    ]

    static let agreement = "Okudum; bu bilgilerin çocuğum için açıklanan amaçla saklanmasına onay veriyorum."
}

/// This device's copy of the parent's consent, tied to the account it was
/// given for. The account's copy (`FamilyRemote.recordConsent`) is the
/// record; this one lets the app open offline.
struct ParentConsentStore {
    private let defaults: UserDefaults
    static let key = "mp_parentConsent"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private struct Stored: Codable {
        let uid: String
        let record: ConsentRecord
        /// The account has it. False until the write is confirmed.
        var recordedRemotely: Bool
    }

    private func stored() -> Stored? {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(Stored.self, from: $0) }
    }

    /// The consent given for `uid`, if it is for the current text.
    func current(for uid: String, version: String = ParentConsentText.version) -> ConsentRecord? {
        guard let stored = stored(), stored.uid == uid, stored.record.version == version else { return nil }
        return stored.record
    }

    /// Whether this device has ever recorded a consent, for anyone.
    var hasAny: Bool { stored() != nil }

    func pendingRemote(for uid: String) -> ConsentRecord? {
        guard let stored = stored(), stored.uid == uid, !stored.recordedRemotely else { return nil }
        return stored.record
    }

    func save(_ record: ConsentRecord, for uid: String, recordedRemotely: Bool) {
        let value = Stored(uid: uid, record: record, recordedRemotely: recordedRemotely)
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: Self.key)
        }
    }

    func markRecorded(for uid: String) {
        guard var value = stored(), value.uid == uid else { return }
        value.recordedRemotely = true
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: Self.key)
        }
    }

    func erase() {
        defaults.removeObject(forKey: Self.key)
    }
}
