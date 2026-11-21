import Foundation

/// Bir satırın görselleştirilebilir anlamı (20 Kasım 2026, görsel bağlayıcı
/// sözleşmesi). İçerik, satırın *neyi* anlattığının kaynağıdır; hangi çizimin
/// bunu karşılayacağını uygulamanın sanat kataloğu bilir. Burada dosya adı,
/// çizim kimliği ya da görünüş tarifi yoktur.
///
/// Örnek: "{{child.name}} {{discovery.name}}'i eline aldı" →
/// `{subject: discovery, presence: present, states: [held]}`;
/// "{{discovery.name}}'i hatırladı" → `{subject: discovery, presence: remembered}`.
/// İkisi aynı çizime otomatik bağlanmaz.
public struct VisualMention: Codable, Sendable, Hashable {

    /// Satırın andığı öğe, bağlanan içerikteki rolüyle. Motor bunu kayıt
    /// kimliğine çevirir (`ResolvedVisual.subjectID`).
    public enum Subject: String, Codable, Sendable, Hashable, CaseIterable {
        case discovery, companion, setting
    }

    /// Öğenin bu satırdaki varlığı.
    public enum Presence: String, Codable, Sendable, Hashable, CaseIterable {
        /// Sahnede, görülüyor ya da dokunuluyor.
        case present
        /// Hatırlanıyor, düşünülüyor, anlatılıyor; sahnede değil.
        case remembered
        /// Aranıyor, isteniyor, gidilecek yer; henüz sahnede değil.
        case intended
    }

    public let subject: Subject
    public let presence: Presence
    /// Anlatı durumu, kapalı sözlükten (`allowedStates`); görünüş değil.
    public let states: [String]

    public init(subject: Subject, presence: Presence, states: [String] = []) {
        self.subject = subject
        self.presence = presence
        self.states = states
    }

    private enum CodingKeys: String, CodingKey { case subject, presence, states }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        subject = try c.decode(Subject.self, forKey: .subject)
        presence = try c.decode(Presence.self, forKey: .presence)
        states = try c.decodeIfPresent([String].self, forKey: .states) ?? []
    }

    /// Konu başına izinli anlatı durumları. Yeni durum önce buraya eklenir;
    /// bütünlük denetimi sözlük dışını reddeder.
    public static let allowedStates: [Subject: Set<String>] = [
        // found: bulunduğu yerde fark ediliyor · held: elde · examined: yakından
        // inceleniyor · whole / piece: parçalı nesnenin bütünü ya da bir parçası
        // · emitting: ışık ya da ses veriyor · opened · given: birine veriliyor
        // · returned: yerine ya da sahibine dönüyor · missing: yerinde yok
        .discovery: ["found", "held", "examined", "whole", "piece", "emitting",
                     "opened", "given", "returned", "missing"],
        // arriving · greeting · helping · together: birlikte yürüyor/çalışıyor
        // · worried · glad · resting · asleep
        .companion: ["arriving", "greeting", "helping", "together", "worried",
                     "glad", "resting", "asleep"],
        // day · evening · night · wide: geniş sahne
        .setting: ["day", "evening", "night", "wide"]
    ]
}

/// Etiketin kaynağı: önerici betik mi, insan incelemesi mi.
public enum VisualReview: String, Codable, Sendable, Hashable {
    /// Betikle önerildi, incelenmedi. Bağlayıcı temkinli kullanmalı.
    case auto
    /// Elle incelendi.
    case reviewed
}

/// Sayfada çözülmüş görsel anlam: rol kayıt kimliğine çevrilmiş.
public struct ResolvedVisual: Codable, Sendable, Hashable {
    public let subject: VisualMention.Subject
    /// Kanonik konu: bağlanan kaydın kimliği (`object_torn_map_001`).
    public let subjectID: String
    public let presence: VisualMention.Presence
    public let states: [String]

    public init(subject: VisualMention.Subject, subjectID: String,
                presence: VisualMention.Presence, states: [String]) {
        self.subject = subject
        self.subjectID = subjectID
        self.presence = presence
        self.states = states
    }

    static func resolve(_ mentions: [VisualMention], content: BoundContent) -> [ResolvedVisual] {
        mentions.map { mention in
            let id: String
            switch mention.subject {
            case .discovery: id = content.discovery.id.rawValue
            case .companion: id = content.companion.id.rawValue
            case .setting: id = content.setting.id.rawValue
            }
            return ResolvedVisual(subject: mention.subject, subjectID: id,
                                  presence: mention.presence, states: mention.states)
        }
    }
}
