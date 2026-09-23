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
public enum StoryMode: String, Codable, Sendable, Hashable, CaseIterable {
    /// Gelişelim — bir şey keşfetmek, öğrenmek, bir beceride ilerlemek.
    case growth
    /// Maceraya Çıkalım — hedef, yolculuk, engel, çözüm, dönüş.
    case adventure
    /// Uyku Zamanı — yavaş tempo, güven, tekrar, huzurlu son.
    case bedtime
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
public struct StoryModeProfile: Decodable, Sendable, Hashable {
    public let mode: StoryMode
    public let families: [NarrativeFamily]
    /// Neden bu aileler — içerik yazarları için. Uygulama göstermez.
    public let editorialNote: String

    public init(mode: StoryMode, families: [NarrativeFamily], editorialNote: String = "") {
        self.mode = mode
        self.families = families
        self.editorialNote = editorialNote
    }

    private enum CodingKeys: String, CodingKey { case mode, families, editorialNote }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(StoryMode.self, forKey: .mode)
        families = try container.decodeIfPresent([NarrativeFamily].self, forKey: .families) ?? []
        editorialNote = try container.decodeIfPresent(String.self, forKey: .editorialNote) ?? ""
    }

    public func admits(_ blueprint: CatalogBlueprint) -> Bool {
        blueprint.family.map(families.contains) ?? false
    }
}

// MARK: - Surprise

/// "Bana sürpriz yap"ın arkasındaki karar: üç moddan hangisi.
///
/// Rastgele değil. Son hikâyeler Macera, Macera, Gelişelim ise yine Macera
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
