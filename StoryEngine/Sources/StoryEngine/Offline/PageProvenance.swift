import Foundation
import EngineFoundation

/// Sayfa metnini oluşturan tek bir parçanın kaynağı (20 Kasım 2026).
///
/// Görsel bağlayıcı sözleşmesi: sayfa, metnini hangi kaynaklardan hangi
/// sırayla kurduğunu taşır; bağlayıcı kimliği metinden geri tahmin etmez.
/// Tür ile bağlam ayrıdır: Masal ailem, özel gün, seri ve dünya satırı bir
/// beat satırının *bağlamı*dır, ayrı bir tür değil.
public struct PageSourcePart: Sendable, Hashable, Codable {
    public static let schemaVersion = 1

    public enum Kind: String, Sendable, Hashable, Codable {
        /// Bir beat'in kataloğundan seçilen satır.
        case beatLine = "beat_line"
        /// Olay örgüsünün kendi nakaratı (`RefrainSpec`); satır kimliği yok.
        case refrain
        /// E3 hatırlama satırı (`recall_lines`), sayfa kurulduktan sonra eklenir.
        case recall
    }

    public let kind: Kind
    /// Satır kimliği; nakaratta `<blueprintID>#refrain.line` ya da `#refrain.finalLine`.
    public let sourceID: String
    /// Yazarın metninin özeti (doldurulmamış hâli): çocuğun adı değişince
    /// değişmez, metin düzeltilince değişir.
    public let sourceTextDigest: String
    /// Beat satırının şablonu ve beat'i; öbür türlerde nil.
    public let templateID: String?
    public let beat: StoryBeat?
    /// Bağlam etiketleri, sıralı: `family`, `occasion`, `series`, `world`.
    public let contexts: [String]
    /// Satırın çözülmüş görsel anlamı; `nil`: satır henüz etiketlenmedi.
    public let visual: [ResolvedVisual]?
    public let visualReview: VisualReview?

    public init(kind: Kind, sourceID: String, sourceTextDigest: String,
                templateID: String? = nil, beat: StoryBeat? = nil, contexts: [String] = [],
                visual: [ResolvedVisual]? = nil, visualReview: VisualReview? = nil) {
        self.kind = kind
        self.sourceID = sourceID
        self.sourceTextDigest = sourceTextDigest
        self.templateID = templateID
        self.beat = beat
        self.contexts = contexts.sorted()
        self.visual = visual
        self.visualReview = visualReview
    }

    /// Kararlı özet; `AuthoredSourceFingerprint` ile aynı karma.
    public static func digest(_ authoredText: String) -> String {
        StableHash.fingerprint(["page-source-v1", "\(authoredText.utf8.count):\(authoredText)"])
    }
}
