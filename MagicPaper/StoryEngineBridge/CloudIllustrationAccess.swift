import Foundation

/// Görsel bulut yolunun (Firebase'e fotoğraf yükleme + fal.ai çizimi) tek
/// açılış sorusu.
///
/// Metin masalları tamamen cihazda üretilir; bu yol yalnızca görselli masal
/// ileride bilinçli olarak açıldığında devreye girer. Release'te sabit
/// `false`: çocuk fotoğrafı hiçbir koşulda buluta gitmez. DEBUG'da geliştirici
/// ayarı okunur (varsayılan kapalı). Arayüzde anahtar yoktur.
enum CloudIllustrationAccess {
    static let developerFlagKey = "mp_dev_cloudIllustration"

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
