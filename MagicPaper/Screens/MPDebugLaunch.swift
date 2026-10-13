import Foundation

#if DEBUG
/// Simülatörde ekran görüntüsü için başlatma kancaları (yalnızca DEBUG).
///
/// `xcrun simctl launch <cihaz> <paket> -mpDemo YES -mpStartParent YES`
/// - `mpDemo`: karşılama geçilmiş sayılır, giriş bu açılış için ertelenir,
///   profil yoksa örnek bir çocuk ("İrem", 6) kurulur.
/// - `mpStartParent`: uygulama ebeveyn alanında açılır.
/// - `mpStartTab`: `home`, `gunluk`, `library` ya da `corner`.
/// - `mpParentTab`: `overview`, `safety` ya da `settings`.
/// - `mpParentRoute`: ebeveyn alt sayfası, ör. `bookExport`, `familyMembers` (FAZ 18).
enum MPDebugLaunch {
    private static var defaults: UserDefaults { .standard }

    static var isDemo: Bool { defaults.bool(forKey: "mpDemo") }
    static var startsInParent: Bool { defaults.bool(forKey: "mpStartParent") }
    static var startTab: MPTab? { defaults.string(forKey: "mpStartTab").flatMap(MPTab.init(rawValue:)) }
    static var parentTab: MPParentTab? { defaults.string(forKey: "mpParentTab").flatMap(MPParentTab.init(rawValue:)) }
    static var parentRoute: MPParentRoute? { defaults.string(forKey: "mpParentRoute").flatMap(MPParentRoute.init(rawValue:)) }

    @MainActor
    static func applyBeforeGate() {
        guard isDemo else { return }
        let profiles = ProfileManager.shared
        if profiles.profiles.isEmpty {
            profiles.createProfile(name: "İrem", age: 6, profileType: .child)
        }
        profiles.hasCompletedOnboarding = true
        AccountService.shared.deferredSignIn = true
    }
}
#endif
