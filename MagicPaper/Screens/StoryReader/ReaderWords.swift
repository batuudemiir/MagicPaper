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
    /// Sesli okumada paragrafın işareti: okunan cümle (UTF-16 aralığı) ve
    /// ondan önceki okunmuş kısmın sönük rengi.
    struct ReadAlong {
        let start: Int
        let end: Int
        let fill: Color
        let readInk: Color
    }

    /// Paragrafın işaretlenmiş hâli (21 Ekim 2026'dan beri):
    /// - yeni kelimeler: her birinin paragraftaki ilk geçişi, bağlantılı;
    /// - çocuğun adı: vurgu renginde ve kalın (renk tek başına bilgi taşımaz);
    /// - ses kelimeleri ("pıt pıt"): bir tık büyük, en kalın kesim;
    /// - sesli okumada okunan cümle fosforlu kalemle, öncesi sönük.
    static func attributed(_ text: String, words: [StoryWord], size: CGFloat, ink: Color,
                           highlight: Color, childName: String? = nil,
                           readAlong: ReadAlong? = nil) -> AttributedString {
        var out = AttributedString(text)
        out.font = MP.F.read(size)
        out.foregroundColor = ink
        let locale = Locale(identifier: "tr_TR")
        if let childName {
            for r in ReaderText.nameRanges(of: childName, in: text) {
                guard let ar = Range<AttributedString.Index>(r, in: out) else { continue }
                out[ar].foregroundColor = highlight
                out[ar].inlinePresentationIntent = .stronglyEmphasized
            }
        }
        for r in ReaderText.soundRanges(in: text) {
            guard let ar = Range<AttributedString.Index>(r, in: out) else { continue }
            out[ar].font = MP.F.sound(size)
        }
        for word in words {
            guard let range = out.range(of: word.surface, options: [.caseInsensitive], locale: locale) else { continue }
            out[range].link = URL(string: "\(ReaderWordSelection.scheme)://\(word.id)")
            out[range].foregroundColor = highlight
            out[range].underlineStyle = Text.LineStyle(pattern: .dot, color: highlight)
            out[range].inlinePresentationIntent = .stronglyEmphasized
        }
        if let readAlong {
            let length = (text as NSString).length
            let s = String.Index(utf16Offset: min(max(readAlong.start, 0), length), in: text)
            let e = String.Index(utf16Offset: min(max(readAlong.end, 0), length), in: text)
            if let read = Range<AttributedString.Index>(text.startIndex..<s, in: out) {
                out[read].foregroundColor = readAlong.readInk
            }
            if s < e, let sentence = Range<AttributedString.Index>(s..<e, in: out) {
                out[sentence].backgroundColor = readAlong.fill
            }
        }
        return out
    }

    /// Paragrafta geçen kelimeler, VoiceOver eylemleri için.
    static func words(in paragraphs: [String], from words: [StoryWord]) -> [StoryWord] {
        let joined = paragraphs.joined(separator: " ").lowercased(with: Locale(identifier: "tr_TR"))
        return words.filter { joined.contains($0.surface.lowercased(with: Locale(identifier: "tr_TR"))) }
    }
}
