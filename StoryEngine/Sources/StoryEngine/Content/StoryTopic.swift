import Foundation

/// Modun içindeki alt seçenek: "Meslekler", "Yeni bir ülke" (karar: 16 Ekim 2026).
///
/// FAZ 10 niyet modelinde `subOption` alanını açıp boş bıraktı — "her mod için
/// gelecek, bugün hep nil". Bu tip o alanın ne anlama geldiğidir.
///
/// **Alt seçenek bir sözdür, bir tat değil.** İlgi alanları (FAZ 12) ağırlık
/// verir ve asla süzmez: katalog "Dinozorlar"ı karşılayamıyorsa masal yine de
/// yazılır ve kimse bir şey kaybetmiş olmaz, çünkü kimseye bir şey söz
/// verilmemişti. Alt seçenek bunun tersi: ebeveyn "Meslekler" dediğinde
/// kaybolmuş bir kedi masalı gelirse uygulama yalan söylemiş olur. Bu yüzden
/// alt seçenek **süzgeçtir**, ve süzgeç olduğu için de ancak gerçekten
/// kurulabildiği yerde **teklif edilir** (`StoryTopicAvailability`).
///
/// Konu sözcükleri ayrı bir sözlük değil, ilgi alanı sözlüğünün ta kendisi
/// (`InterestTag`). İçerik üstünde "bu masal hayvanlarla ilgili" demenin iki
/// ayrı yazılışı olsaydı, biri güncellenip öbürü unutulurdu. Fark sözcükte
/// değil, sözcüğün nasıl uygulandığında: ilgi alanı ağırlık, konu şart.
public struct CatalogStoryTopic: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// Hangi modun altında görünür. Bir konu tek bir moda aittir: "Meslekler"
    /// hem öğrenme hem macera altında dursaydı, ikisi aynı şeyi vaat edip
    /// farklı aileler kurardı.
    public let mode: StoryMode
    /// Ebeveynin gördüğü ad. Kimlikle yan yana duruyor çünkü sözlük açık:
    /// uygulamanın hiç görmediği bir konu da adıyla gösterilebilmeli (FAZ 15).
    public let name: String
    /// SF Symbol. Yoksa ekran düz çip çizer.
    public let symbol: String?
    /// Hangi yuva hangi konu sözcüğünü taşımalı.
    public let requires: Slots

    /// Yuva başına "bunlardan en az biri".
    ///
    /// Yuva ayrımı şart: "Hayvanlar" yol arkadaşının hayvan olmasını ister,
    /// mekânın hayvan olmasını değil; "Yeni bir ülke" mekânın ülke olmasını
    /// ister, arkadaşın değil. Tek bir düz liste olsaydı ikisi de "masalın bir
    /// yerinde geçsin" demek olurdu — ki bu bir söz değil, bir temenni.
    public struct Slots: Codable, Sendable, Hashable {
        public let setting: [InterestTag]
        public let companion: [InterestTag]
        public let discovery: [InterestTag]

        public init(setting: [InterestTag] = [], companion: [InterestTag] = [],
                    discovery: [InterestTag] = []) {
            self.setting = setting
            self.companion = companion
            self.discovery = discovery
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            setting = try c.decodeIfPresent([InterestTag].self, forKey: .setting) ?? []
            companion = try c.decodeIfPresent([InterestTag].self, forKey: .companion) ?? []
            discovery = try c.decodeIfPresent([InterestTag].self, forKey: .discovery) ?? []
        }

        /// Hiçbir yuva şart koşmuyorsa bu konu hiçbir şey vaat etmiyor demektir.
        /// Böyle bir konu her masalı kabul eder, yani ekranda bir seçim gibi
        /// görünüp hiçbir şey seçmez. `CatalogIntegrity` bunu hata sayar.
        public var isEmpty: Bool {
            setting.isEmpty && companion.isEmpty && discovery.isEmpty
        }

        public var allTags: [InterestTag] { setting + companion + discovery }
    }

    public init(id: ContentID, mode: StoryMode, name: String, symbol: String? = nil,
                requires: Slots) {
        self.id = id
        self.mode = mode
        self.name = name
        self.symbol = symbol
        self.requires = requires
    }

    // MARK: - Süzme

    /// Konu sözcüğünü taşımayan kaydın **gerekçesi**; taşıyorsa `nil`.
    ///
    /// Gerekçe döndürmek, sessizce elemekten farklı: bağlayıcı reddedilen her
    /// kaydın sebebini topluyor ve "istenen şey verilemedi" diye açıklıyor
    /// (`testARejectedRequestIsExplainedNotSubstituted`). Konu, o listeye kendi
    /// cümlesiyle giriyor — "başka bir masal verdik" demeden.
    public func rejection(setting record: CatalogSetting) -> String? {
        reason(requires.setting, record.interests, slot: "mekân")
    }

    public func rejection(companion record: CatalogCompanion) -> String? {
        reason(requires.companion, record.interests, slot: "yol arkadaşı")
    }

    public func rejection(discovery record: CatalogObject) -> String? {
        reason(requires.discovery, record.interests, slot: "bulunan şey")
    }

    private func reason(_ wanted: [InterestTag], _ offered: [InterestTag], slot: String) -> String? {
        guard !wanted.isEmpty else { return nil }
        guard !offered.contains(where: Set(wanted).contains) else { return nil }
        return "\(name) konusu \(slot) için "
            + wanted.map(\.rawValue).sorted().joined(separator: ", ")
            + " istiyor"
    }
}

// MARK: - Katalogdaki konular

extension ContentCatalog {
    /// Bu modun tanımlı konuları, katalogdaki sırayla.
    ///
    /// Tanımlı olmak **sunulabilir olmak değildir**: hangi konunun çocuğa
    /// gösterileceğini `StoryTopicAvailability` söyler, çünkü o soru içeriğin
    /// o yaş bandında gerçekten kurulup kurulmadığına bakar.
    public func storyTopics(for mode: StoryMode) -> [CatalogStoryTopic] {
        // `self.` şart: metot adı özelliği gölgeliyor.
        self.storyTopics.filter { $0.mode == mode }
    }

    public func storyTopic(_ id: ContentID) -> CatalogStoryTopic? {
        storyTopics.first { $0.id == id }
    }
}
