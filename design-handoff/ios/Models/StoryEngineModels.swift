// StoryEngineModels.swift
// Codable mirrors of engine/schemas/*.schema.json. Field names match the JSON exactly,
// so the default JSONEncoder/JSONDecoder work without CodingKeys.
// Test: decode engine/fixtures/StoryRequest.example.json and StoryResponse.example.json in a unit test.

import Foundation

enum AgeBand: String, Codable, CaseIterable { case age3to4 = "3-4", age5to7 = "5-7", age8to10 = "8-10", age11to12 = "11-12" }
enum StoryLength: String, Codable, CaseIterable { case kisa, orta, uzun
    var pages: Int { switch self { case .kisa: 5; case .orta: 8; case .uzun: 12 } }
    var label: String { switch self { case .kisa: "Kısa"; case .orta: "Orta"; case .uzun: "Uzun" } }
    var requiresPremium: Bool { self == .uzun }
}
enum StoryTone: String, Codable, CaseIterable { case neseli, sakin, macerali, komik }
enum StoryMode: String, Codable { case normal, bedtime }
enum FreeTextMode: String, Codable { case off, on, approval }
enum FearLevel: String, Codable { case none, mild, medium }
enum AvoidTopic: String, Codable, CaseIterable { case olumKayip = "olum_kayip", karanlik, canavar, ayrilik, hastane, firtina }

struct StoryRequest: Codable, Hashable {
    struct Child: Codable, Hashable { var name: String; var ageBand: AgeBand }
    struct Character: Codable, Hashable { var id: String; var name: String; var kind: String; var traits: [String] }
    struct Series: Codable, Hashable { var seriesId: String; var episode: Int }
    struct ParentSettings: Codable, Hashable { var freeText: FreeTextMode; var fearLevel: FearLevel; var avoidTopics: [AvoidTopic] }

    var requestId: String
    var locale: String = "tr-TR"
    var profileId: String
    var child: Child
    var worldId: String
    var length: StoryLength
    var tone: StoryTone          // bedtime → always .sakin (the app sets this, see buildRequest in engine.js)
    var mode: StoryMode
    var characters: [Character]
    var wish: String             // max 140 chars; sent to the model only when freeText != .off
    var series: Series?
    var parentSettings: ParentSettings
    var includeImagePrompts: Bool = true

    /// Same rule as the backend (invalid_request / 400). Validate on the client before sending.
    static func isValidHeroName(_ s: String) -> Bool {
        s.range(of: #"^[A-Za-zÇĞİÖŞÜçğıöşü \-]{1,20}$"#, options: .regularExpression) != nil
    }
}

struct StoryResponse: Codable, Hashable {
    enum Mood: String, Codable { case merakli = "meraklı", mutlu, sakin, heyecanli = "heyecanlı", uykulu }
    enum Ending: String, Codable { case mutlu, huzurlu, uykulu }
    struct Page: Codable, Hashable, Identifiable { var index: Int; var text: String; var imagePrompt: String; var mood: Mood; var id: Int { index } }
    struct Word: Codable, Hashable { var word: String; var meaning: String; var page: Int }
    struct SeriesUpdate: Codable, Hashable { var newFacts: [String]?; var nextHook: String? }

    var title: String
    var summary: String
    var pages: [Page]
    var wordList: [Word]         // → Yeni kelimelerim + reader highlight (match by stem, see check() in engine.js)
    var characters: [String]
    var endingType: Ending
    var seriesUpdate: SeriesUpdate?
    var refusal: String?
}

/// Job lifecycle the app listens to (SSE or polling). Drives Uretim (Masal yazılıyor) stages.
enum StoryJobStatus: String, Codable { case queued, waitingApproval = "waiting_approval", writing, checking, rewriting, done, failed, rejected }

enum StoryEngineError: String, Codable, Error {
    case invalidRequest = "invalid_request"     // 400 → inline field error on Yarat 2
    case noStars = "no_stars"                   // 402 → YildizBitti
    case lockedOption = "locked_option"         // 403 → locked card, "Büyüğüne sor"
    case inputRejected = "input_rejected"       // 422 → "Bunu bir büyüğüne soralım.", star refunded
    case parentRejected = "parent_rejected"     // 422 → same child message, star refunded
    case generationFailed = "generation_failed" // 500 → UretimHata, star refunded

    /// Which prototype screen to show. Keep in sync with docs/ENGINE.md.
    var screen: String {
        switch self {
        case .invalidRequest: "SihirbazNasil (alan hatası)"
        case .noStars: "YildizBitti"
        case .lockedOption: "Kilitli kart + Büyüğüne sor"
        case .inputRejected, .parentRejected: "Nazik mesaj, Yarat 2'ye dön"
        case .generationFailed: "UretimHata"
        }
    }
}

struct StoryJob: Codable, Hashable {
    var jobId: String?
    var status: StoryJobStatus?
    var starsReserved: Int?
    var starsLeftAfter: Int?
    var storyId: String?
    var error: StoryEngineError?
    var http: Int?
    var refund: Bool?
    var childMessage: String?
}
