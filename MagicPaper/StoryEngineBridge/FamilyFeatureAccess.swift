import Foundation

/// Ekranı tasarlanmış ama altyapısı henüz olmayan aile özellikleri (FAZ 18).
///
/// Karar (7 Ekim 2026): ekranlar İrem'in teslimine göre kurulur, girişleri
/// bayrak kapalıyken gizli kalır. Release'te hep kapalı; DEBUG'da Ayarlar'ın
/// geliştirici bölümünden açılır, ekranlara bakmak için.
enum FamilyFeature: String, CaseIterable {
    /// 33 · Kendi sesin: sayfa sayfa kayıt, okuyucuda "Kim okusun?".
    case voiceRecording
    /// 34 · Aile üyeleri: davet ve roller.
    case familyMembers
    /// 36 · Aileyle paylaş: süreli, salt okuma bağlantısı.
    case shareLink
    /// Haftalık özet e-postası.
    case weeklyEmail

    var title: String {
        switch self {
        case .voiceRecording: return "Kendi sesin"
        case .familyMembers:  return "Aile üyeleri"
        case .shareLink:      return "Aileyle paylaş"
        case .weeklyEmail:    return "Haftalık özet e-postası"
        }
    }
}

enum FamilyFeatureAccess {
    static func key(_ feature: FamilyFeature) -> String { "mp_dev_family_\(feature.rawValue)" }

    /// DEBUG'da geliştirici ayarı (varsayılan kapalı), Release'te hep kapalı.
    static func isEnabled(_ feature: FamilyFeature, defaults: UserDefaults = .standard) -> Bool {
        #if DEBUG
        // `bool(forKey:)`: başlatma argümanı (`-mp_dev_family_x YES`) metin olarak gelir.
        return defaults.bool(forKey: key(feature))
        #else
        return false
        #endif
    }

    static func setDeveloperFlag(_ feature: FamilyFeature, _ isOn: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isOn, forKey: key(feature))
    }
}
