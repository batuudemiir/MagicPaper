import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "AvatarStore")

/// Kitap karakteri seçimi (B2), profil başına, yalnızca cihazda.
///
/// `Documents/…/Avatars/<profilUUID>.json`. `FileBackedStore` deseni: kayıt
/// başına bir dosya, atomik yazma, dosya koruması; okunamayan dosya "yok" ile
/// karıştırılmaz. Fotoğraf yok, ad yok — yalnızca kit parça kimlikleri.
///
/// D4 göçü `user_profiles` ve `stories` üzerinde çalışıyor; bu klasöre
/// dokunmaz.
///
/// Masala kopyalanan anlık görüntü burada değil, masalın içindedir
/// (`Story.illustration`): buradaki değer değişse de eski kitaplar değişmez.
struct AvatarStore: Sendable {
    static let shared = AvatarStore()
    static let defaultSubdirectory = "Avatars"

    private let store: FileBackedStore<AvatarSpec>
    private let subdirectory: String

    init(subdirectory: String = AvatarStore.defaultSubdirectory) {
        self.subdirectory = subdirectory
        self.store = FileBackedStore(subdirectory: subdirectory)
    }

    /// Profilin kayıtlı avatarı. Kayıt yoksa ya da okunamıyorsa `nil` — ikinci
    /// durum log'a yazılır (kimlik ya da içerik değil, yalnızca olay).
    func avatar(for profileID: UUID) async -> AvatarSpec? {
        do {
            return try await store.load(id: profileID)
        } catch {
            logger.error("🛑 Kayıtlı kitap karakteri okunamadı")
            return nil
        }
    }

    func save(_ spec: AvatarSpec, for profileID: UUID) async throws {
        try await store.save(spec, id: profileID)
    }

    func delete(for profileID: UUID) async {
        await store.delete(id: profileID)
    }

    /// "Tüm verileri sil" için: klasörün tamamı, eşzamanlı.
    static func eraseAll(subdirectory: String = AvatarStore.defaultSubdirectory) {
        guard let url = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

/// Görselli kitabın (B2) tek açılış sorusu.
///
/// Görselli masalın ücretsiz mi premium mu olacağı açık bir gelir modeli
/// kararı; bu yüzden paywall'a ve `Capability.illustratedStory`'ye bağlanmaz.
/// O yetenek ölçülü ve uzak maliyetli: her kullanımda yıldız düşürür. Sıfır
/// maliyetli B2'yi ona bağlamak her kitaptan yıldız keserdi. Karar verildiğinde
/// yalnızca burası değişir.
enum IllustratedBookAccess {
    static let developerFlagKey = "mp_dev_illustratedBooks"

    /// DEBUG'da geliştirici ayarı (varsayılan açık), Release'te kapalı.
    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        #if DEBUG
        return defaults.object(forKey: developerFlagKey) as? Bool ?? true
        #else
        return false
        #endif
    }

    static func setDeveloperFlag(_ isOn: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isOn, forKey: developerFlagKey)
    }
}
