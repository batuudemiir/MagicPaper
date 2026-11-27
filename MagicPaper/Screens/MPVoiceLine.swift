import Foundation

/// Sesle okunan bir cümle ve stüdyo kaydının adı (26 Kasım 2026, Batuhan:
/// cihaz sesi robot gibi; cümleler ElevenLabs'ta seslendirilip pakete konur).
///
/// Kayıt `MagicPaper/DesignSystem/Sounds/Voice/` altında `<key>.m4a` (ya da
/// `.mp3`); `MPSound`'un sesleriyle aynı eşitlenmiş klasör, Xcode'da ayar yok.
/// Dosya pakette varsa o çalar; yoksa aynı cümleyi cihazın sesi `pitch` ile
/// okur. Böylece kayıtlar tek tek eklenebilir, eksik dosya akışı bozmaz.
/// Cümlelerin listesi ve dosya adları: `docs/SESLENDIRME.md`.
struct MPVoiceLine: Equatable {
    /// Dosya adı, uzantısız: `ses_olustur_kim_gelsin`. Yalnızca küçük ASCII
    /// harf, rakam ve alt çizgi (pakette düz bir ad; Türkçe harf yok).
    let key: String
    let text: String
    /// Kayıt yokken cihaz sesinin perdesi; anlatıcınınki 1.05.
    var pitch: Float = 1.05

    /// Pakette bu satırın kaydı, varsa.
    var recording: URL? { MPVoiceClips.url(for: key) }
}

/// Stüdyo kayıtlarını paketten bulur.
enum MPVoiceClips {
    /// Aranan uzantılar, sırayla.
    static let extensions = ["m4a", "mp3", "wav"]

    /// Xcode'un eşitlenmiş klasörü dosyaları paketin köküne düz koyar; klasör
    /// referansıyla eklenirse alt klasörde durur. İkisi de aranır.
    static let subdirectories: [String?] = [nil, "Voice"]

    static func url(for key: String, in bundle: Bundle = .main) -> URL? {
        for directory in subdirectories {
            for ext in extensions {
                if let url = bundle.url(forResource: key, withExtension: ext, subdirectory: directory) {
                    return url
                }
            }
        }
        return nil
    }

    /// Dosya adı kuralı: küçük ASCII harf, rakam, alt çizgi.
    static func isValidKey(_ key: String) -> Bool {
        !key.isEmpty && key.unicodeScalars.allSatisfy {
            ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_"
        }
    }
}
