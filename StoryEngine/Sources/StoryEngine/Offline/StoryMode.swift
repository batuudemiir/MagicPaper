import Foundation
import EngineFoundation

// MARK: - Story Mode

/// Ebeveynin bu akşamki niyeti.
///
/// Sabit bir şablon değil: bir mod hangi anlatı ailelerinin uygun olduğunu
/// söyler, hangi blueprint'in seçileceğini değil. Ailelerle eşleşme kodda değil
/// katalogda durur (`StoryModeProfile`), çünkü o bir içerik kararıdır.
///
/// **Burada `surprise` yok ve olmamalı.** "Bana sürpriz yap" bir niyet değil,
/// niyeti seçme biçimidir: MagicPaper ebeveyn adına bu üç moddan birini seçer.
/// Onu bir mod olarak modellemek, sistemin her yerinde "sürpriz özel bir mod
/// mu?" sorusunu doğururdu. Seçim biçimi `StorySelectionStrategy`'dir.
///
/// **Vaka sırası sabittir.** Sürprizin eşitlik bozması bu sıraya bakar; ekranda
/// görünen sıra uygulamanın sunum katmanında ayrıca tanımlanır.
public enum StoryMode: String, Sendable, Hashable, CaseIterable {
    /// Yeni şeyler öğrenelim — bir şey keşfetmek, öğrenmek, bir beceride ilerlemek.
    /// 3 Ekim 2026'ya kadar `growth` ("Gelişelim") adıyla kaydedildi.
    case learning
    /// Maceraya çıkalım — hedef, yolculuk, engel, çözüm, dönüş.
    case adventure
    /// Uyku öncesi — yavaş tempo, güven, tekrar, huzurlu son.
    case bedtime

    /// Artık yazılmayan ama kaydedilmiş masallarda ve eski kataloglarda duran
    /// adlar. Veri yeniden yazılmaz; okurken çözülür.
    public static let legacyAliases: [String: StoryMode] = ["growth": .learning]

    /// Saklanmış bir mod kimliğini çözer: önce bugünkü ad, sonra eski ad.
    ///
    /// Kayıttan mod okuyan her yer `init(rawValue:)` yerine bunu kullanmalı;
    /// yoksa eski bir masal modunu sessizce kaybeder.
    public init?(storedID: String) {
        guard let mode = StoryMode(rawValue: storedID) ?? Self.legacyAliases[storedID] else { return nil }
        self = mode
    }
}

extension StoryMode: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let mode = StoryMode(storedID: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "'\(raw)' is not a story mode"))
        }
        self = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Modun nasıl belirlendiği.
public enum StorySelectionStrategy: String, Codable, Sendable, Hashable {
    /// Ebeveyn modu kendisi seçti.
    case direct
    /// Ebeveyn "Bana sürpriz yap" dedi; mod `StoryModeResolver` ile seçildi.
    case surprise
}

/// Bir modun katalogdaki tanımı: hangi anlatı aileleri bu niyete hizmet eder.
///
/// Yeni bir davranış kuralı gerekmedikçe bir modun içeriği değiştirmek Swift
/// değişikliği gerektirmez — yalnızca katalog.
///
/// **Ton ayrı bir alan değil** (karar: 3 Ekim 2026). Bir masalın tonu modun
/// ailelerinden gelir: Uyku öncesi yalnızca sakin, bakım üzerine kurulu
/// aileleri kabul ettiği için sakin olur. Tonu değiştirmek aile listesini
/// değiştirmektir. Uzunluk da moddan değil yaş bandından gelir (`AgeBand.pageCount`).
public struct StoryModeProfile: Decodable, Sendable, Hashable {
    public let mode: StoryMode
    public let families: [NarrativeFamily]
    /// Neden bu aileler — içerik yazarları için. Uygulama göstermez.
    public let editorialNote: String
    /// Bu modda bir masalın "işe yaradığı" ne demek (FAZ 14). Kullanımdan
    /// öğrenme bunu okur.
    public let success: ModeSuccessRule

    public init(
        mode: StoryMode,
        families: [NarrativeFamily],
        editorialNote: String = "",
        success: ModeSuccessRule = .default
    ) {
        self.mode = mode
        self.families = families
        self.editorialNote = editorialNote
        self.success = success
    }

    private enum CodingKeys: String, CodingKey { case mode, families, editorialNote, success }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(StoryMode.self, forKey: .mode)
        families = try container.decodeIfPresent([NarrativeFamily].self, forKey: .families) ?? []
        editorialNote = try container.decodeIfPresent(String.self, forKey: .editorialNote) ?? ""
        success = try container.decodeIfPresent(ModeSuccessRule.self, forKey: .success) ?? .default
    }

    public func admits(_ blueprint: CatalogBlueprint) -> Bool {
        blueprint.family.map(families.contains) ?? false
    }
}

/// Bir modda başarının tanımı, katalogda (FAZ 14).
///
/// Uyku öncesinde masalı yarıda bırakmak başarıdır: çocuk uyumuştur. Bu
/// yüzden kural kodda değil katalogda; yeni bir mod kendi tanımını getirir.
public struct ModeSuccessRule: Decodable, Sendable, Hashable {
    /// Bitmeden kapanan ve hiç bitirilmemiş masal, ailesinin ve yol
    /// arkadaşının ağırlığını düşürür mü.
    public let abandonIsPenalty: Bool

    public init(abandonIsPenalty: Bool = true) {
        self.abandonIsPenalty = abandonIsPenalty
    }

    public static let `default` = ModeSuccessRule()

    private enum CodingKeys: String, CodingKey { case abandonIsPenalty }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        abandonIsPenalty = try container.decodeIfPresent(Bool.self, forKey: .abandonIsPenalty) ?? true
    }
}

// MARK: - Surprise

/// "Bana sürpriz yap"ın arkasındaki karar: üç moddan hangisi.
///
/// Rastgele değil. Son hikâyeler Macera, Macera, Öğrenelim ise yine Macera
/// seçmek sürpriz değil tekrardır. Bu yüzden her aday, yakın geçmişte ne kadar
/// göründüğüne göre puanlanır — en yeni hikâye en ağır basar — ve en az
/// görünen seçilir. Eşitlik tohumla bozulur: aynı istek aynı modu verir.
public struct StoryModeResolver: Sendable {

    /// Geriye kaç hikâyeye bakıldığı.
    public static let historyWindow = 3

    public init() {}

    public enum Failure: Error, Sendable, Equatable {
        /// Doğrudan seçimde mod verilmedi.
        case noModeRequested
        /// Bu çocuk için hiçbir mod kurulabilir değil.
        case noModeAvailable
    }

    /// - Parameters:
    ///   - available: Bu çocuk için hikâye kurulabilen modlar.
    ///   - recent: Çocuğun son hikâyelerinin modları, **en yeni önce**.
    public func resolve(
        strategy: StorySelectionStrategy,
        requested: StoryMode?,
        available: [StoryMode],
        recent: [StoryMode],
        seed: String
    ) throws -> StoryMode {
        switch strategy {
        case .direct:
            guard let requested else { throw Failure.noModeRequested }
            return requested
        case .surprise:
            // Sabit sıra: sonuç, çağıranın listeyi hangi sırayla verdiğine bağlı olmasın.
            let candidates = StoryMode.allCases.filter(available.contains)
            guard !candidates.isEmpty else { throw Failure.noModeAvailable }

            let window = Array(recent.prefix(Self.historyWindow))
            func weight(_ mode: StoryMode) -> Int {
                window.enumerated().reduce(0) { sum, entry in
                    entry.element == mode ? sum + (Self.historyWindow - entry.offset) : sum
                }
            }
            let lowest = candidates.map(weight).min() ?? 0
            let freshest = candidates.filter { weight($0) == lowest }
            return DeterministicPicker.pick(from: freshest, seed: seed, salt: "mode")
        }
    }
}
