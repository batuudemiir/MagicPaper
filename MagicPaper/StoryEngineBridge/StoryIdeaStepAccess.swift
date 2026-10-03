import Foundation

/// Fikir kartları adımının (`StoryIdeaStep`) tek açılış sorusu.
///
/// Ürün kararı (3 Ekim 2026): yaratma akışı mod → "Masalda kimler olsun?".
/// Fikir kartları her build'de kapalı; yeri, mod başına gelecek alt seçenekler
/// için korunuyor. Açmanın tek yolu Ayarlar'daki geliştirici bölümü, o da
/// yalnızca DEBUG derlemesinde var. Release'te bu adım hiç görünmez.
enum StoryIdeaStepAccess {
    static let developerFlagKey = "mp_dev_storyIdeaStep"

    /// DEBUG'da geliştirici ayarı (varsayılan kapalı), Release'te hep kapalı.
    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        #if DEBUG
        return defaults.object(forKey: developerFlagKey) as? Bool ?? false
        #else
        return false
        #endif
    }

    static func setDeveloperFlag(_ isOn: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isOn, forKey: developerFlagKey)
    }
}
