import Foundation

/// Widget, Live Activity ve Siri'nin uygulamada açtığı yerler (FAZ 19).
///
/// Hepsi çocuk alanında açılır; hiçbiri ebeveyn kapısının arkasındaki bir
/// yüzeye götürmez. Aile daveti (`magicpaper://invite/…`) ayrı ve
/// `FamilyInviteCode`'da.
enum MPSurfaceLink: String, CaseIterable, Sendable {
    /// "Bu akşamın masalı": `MPTonight`'ın o an seçtiği masal.
    case tonight
    /// 18 · Seri masal.
    case series
    /// 26 · Uyku modu.
    case sleep

    static let scheme = "magicpaper"

    var url: URL { URL(string: "\(Self.scheme)://\(rawValue)")! }

    init?(url: URL) {
        guard url.scheme == Self.scheme, let host = url.host, url.path.isEmpty || url.path == "/",
              let link = MPSurfaceLink(rawValue: host) else { return nil }
        self = link
    }
}
