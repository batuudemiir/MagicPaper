import SwiftUI

/// Okuyucuda yeni kelimeler (FAZ 17, 23 · Okuyucu).
///
/// Kelime paragrafta kalın ve noktalı alt çizgiyle durur (renk tek başına
/// bilgi taşımaz). Dokununca `mpword://` bağlantısı seçimi bildirir; okuyucu
/// alta kelime kartını açar. Sayfalar ayrı `UIHostingController`'larda
/// çizildiği için seçim ortam değeriyle değil, bu paylaşılan nesneyle taşınır.
@MainActor
final class ReaderWordSelection: ObservableObject {
    static let shared = ReaderWordSelection()
    @Published var selected: StoryWord?
    private init() {}

    static let scheme = "mpword"

    func handle(_ url: URL, in words: [StoryWord]) -> OpenURLAction.Result {
        guard url.scheme == Self.scheme, let id = url.host,
              let word = words.first(where: { $0.id == id }) else { return .systemAction }
        MPHaptics.selection()
        selected = word
        return .handled
    }
}

enum ReaderWords {
    /// Paragrafın kelimeleri işaretlenmiş hâli. Her kelimenin paragraftaki ilk
    /// geçişi işaretlenir; paragrafta geçmeyen kelime atlanır.
    static func attributed(_ text: String, words: [StoryWord], size: CGFloat, ink: Color,
                           highlight: Color) -> AttributedString {
        var out = AttributedString(text)
        out.font = MP.F.read(size)
        out.foregroundColor = ink
        let locale = Locale(identifier: "tr_TR")
        for word in words {
            guard let range = out.range(of: word.surface, options: [.caseInsensitive], locale: locale) else { continue }
            out[range].link = URL(string: "\(ReaderWordSelection.scheme)://\(word.id)")
            out[range].foregroundColor = highlight
            out[range].underlineStyle = Text.LineStyle(pattern: .dot, color: highlight)
            out[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return out
    }

    /// Paragrafta geçen kelimeler, VoiceOver eylemleri için.
    static func words(in paragraphs: [String], from words: [StoryWord]) -> [StoryWord] {
        let joined = paragraphs.joined(separator: " ").lowercased(with: Locale(identifier: "tr_TR"))
        return words.filter { joined.contains($0.surface.lowercased(with: Locale(identifier: "tr_TR"))) }
    }
}
