import Foundation
import StoryEngine

/// Sayfanın kalıcı kaynak izi (20 Kasım 2026, görsel bağlayıcı sözleşmesi).
///
/// Motorun `PageSourcePart` listesinin kitapla saklanan kopyası: parçalar
/// sayfanın kuruluş sırasıyla, her biri kaynak türü, kaynak kimliği ve yazar
/// metninin özetiyle. Görsel bağlayıcı kaynağı buradan okur; metinden geri
/// tahmin etmez. Eski kitaplarda yoktur ve hiçbir zaman sonradan üretilmez:
/// iz yoksa sayfa otomatik görsel almaz.
///
/// Çözümleme hoşgörülü (`StoryPageReading` deseni): tanınmayan tür ya da eksik
/// alan bütün kitaplığı düşürmez, yalnızca o parçayı.
struct StoryPageProvenance: Codable, Equatable {
    let schemaVersion: Int
    let parts: [Part]
    /// Kayıt anında yazılan parça sayısı. Okumada bozuk parça atlanırsa
    /// `parts` bundan kısa kalır ve sayfa eksik sayılır (`isComplete`);
    /// yeniden kaydedilince beyan korunur, eksiklik kaybolmaz.
    let partCount: Int

    /// Bütün parçalar okundu mu. Eksik sayfaya otomatik görsel bağlanmamalı:
    /// kalan parçalar sayfanın bütün kaynağı değildir.
    var isComplete: Bool { parts.count == partCount }

    struct Part: Codable, Equatable {
        /// `beat_line`, `refrain`, `recall`. Ham metin: gelecekte eklenen bir
        /// tür eski uygulamada kitabı bozmaz.
        let sourceKind: String
        let sourceID: String
        let sourceTextDigest: String
        let templateID: String?
        let beat: String?
        /// `family`, `occasion`, `series`, `world`; sıralı.
        let contexts: [String]
        /// Satırın görsel anlamı, kanonik konu kimliğiyle; `nil`: satır
        /// etiketlenmemiş. Boş liste: görünen öğe yok.
        let visual: [Visual]?
        /// `auto` (önerildi) ya da `reviewed` (incelendi).
        let visualReview: String?

        struct Visual: Codable, Equatable {
            /// `discovery`, `companion`, `setting`
            let subject: String
            /// Kanonik konu: kayıt kimliği (`object_torn_map_001`).
            let subjectID: String
            /// `present`, `remembered`, `intended`
            let presence: String
            /// Anlatı durumu (`held`, `found`…); görünüş değil.
            let states: [String]
        }

        init(sourceKind: String, sourceID: String, sourceTextDigest: String,
             templateID: String? = nil, beat: String? = nil, contexts: [String] = [],
             visual: [Visual]? = nil, visualReview: String? = nil) {
            self.sourceKind = sourceKind
            self.sourceID = sourceID
            self.sourceTextDigest = sourceTextDigest
            self.templateID = templateID
            self.beat = beat
            self.contexts = contexts
            self.visual = visual
            self.visualReview = visualReview
        }

        private enum CodingKeys: String, CodingKey {
            case sourceKind, sourceID, sourceTextDigest, templateID, beat, contexts, visual, visualReview
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            sourceKind = try values.decode(String.self, forKey: .sourceKind)
            sourceID = try values.decode(String.self, forKey: .sourceID)
            sourceTextDigest = try values.decode(String.self, forKey: .sourceTextDigest)
            templateID = try? values.decode(String.self, forKey: .templateID)
            beat = try? values.decode(String.self, forKey: .beat)
            contexts = (try? values.decode([String].self, forKey: .contexts)) ?? []
            visual = try? values.decode([Visual].self, forKey: .visual)
            visualReview = try? values.decode(String.self, forKey: .visualReview)
        }
    }

    init(parts: [Part], schemaVersion: Int = PageSourcePart.schemaVersion) {
        self.schemaVersion = schemaVersion
        self.parts = parts
        self.partCount = parts.count
    }

    /// Motorun parçalarından; boşsa nil (bu alandan önce kurulmuş sayfa).
    init?(engine: [PageSourcePart]) {
        guard !engine.isEmpty else { return nil }
        self.init(parts: engine.map {
            Part(sourceKind: $0.kind.rawValue, sourceID: $0.sourceID,
                 sourceTextDigest: $0.sourceTextDigest, templateID: $0.templateID,
                 beat: $0.beat?.rawValue, contexts: $0.contexts,
                 visual: $0.visual?.map {
                     Part.Visual(subject: $0.subject.rawValue, subjectID: $0.subjectID,
                                 presence: $0.presence.rawValue, states: $0.states)
                 },
                 visualReview: $0.visualReview?.rawValue)
        })
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, parts, partCount }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = (try? values.decode(Int.self, forKey: .schemaVersion)) ?? 0
        // Bozuk parça atlanır; sıra korunur. Beyan yoksa ham dizi sayısı.
        let raw = (try? values.decode([FailableDecodable<Part>].self, forKey: .parts)) ?? []
        parts = raw.compactMap(\.value)
        partCount = max((try? values.decode(Int.self, forKey: .partCount)) ?? raw.count, raw.count)
    }

    /// Satır kimlikleri, beat satırlarıyla sınırlı, sırayla.
    var beatLineIDs: [String] { parts.filter { $0.sourceKind == "beat_line" }.map(\.sourceID) }
}

private struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}
