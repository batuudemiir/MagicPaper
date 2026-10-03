import Foundation

/// The one place a secret is read from.
///
/// Keys used to be literals in three separate files, which meant three places
/// to rotate, three chances to miss one, and a working copy that could not be
/// shared without shipping the credential. The project already had the right
/// mechanism for this — `Secrets.xcconfig` feeds a build setting into
/// `Info.plist`, which is how `REVENUECAT_API_KEY` already works. fal.ai simply
/// never used it.
///
/// Resolution order is environment first, then `Info.plist`, so CI and local
/// tooling can override without editing a file that must never be committed.
enum APIKeys {

    /// Yalnızca Debug. Görsel bulut yolu (`CloudIllustrationAccess`) Release'te
    /// kapalı; anahtar Release paketine hiç girmez (target'ın Release ayarı
    /// `FAL_API_KEY`'i boşaltır), bu satır da ikinci kilit.
    static var fal: String? {
        #if DEBUG
        resolve("FAL_API_KEY")
        #else
        nil
        #endif
    }

    /// An unresolved key is returned as `nil`, never as the literal
    /// `"$(FAL_API_KEY)"`. Xcode leaves the placeholder in place when the
    /// build setting is missing, and passing that to a provider produces a
    /// 401 that reads like an expired credential rather than a missing one.
    private static func resolve(_ name: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[name],
           !value.isEmpty { return value }
        guard let value = Bundle.main.object(forInfoDictionaryKey: name) as? String,
              !value.isEmpty,
              value != "$(\(name))" else { return nil }
        return value
    }
}
