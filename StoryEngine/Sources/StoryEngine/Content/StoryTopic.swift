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

    /// Bir konunun bir bantta teklif edilebilmesi için gereken en az
    /// **yapısal olarak farklı olay örgüsü mekanizması** sayısı (22 Ekim 2026).
    ///
    /// Kurulabilmek yetmez, çünkü kurulabilirlik tek bir şekli de kabul eder:
    /// tek mekanizmalı bir konu, aynı masalı farklı hayvanla ve farklı mekânla
    /// tekrar anlatır. A turu bunu ölçümle gösterdi — havuz iki katına çıktı,
    /// mekanizma sayısı hiç değişmedi, ve çocuğun aldığı masal sayısı da
    /// değişmedi. Bu yüzden eşik mekanizmada, blueprint sayısında değil.
    ///
    /// Üç, "bir şekil" ile "bir repertuar" arasındaki en küçük sayı: iki
    /// mekanizma çocuğun iki masalda farkı görmesine yeter, üçüncüsü farkın
    /// tesadüf olmadığını gösterir.
    public static let minimumMechanisms = 3

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
        /// **Olay örgüsünün kendisi** (karar: 30 Ekim 2026, Batuhan).
        ///
        /// Üç yuva "masalda kim var, nerede, ne bulundu" diyor; hiçbiri "masal
        /// NE HAKKINDA" demiyor. Ölçüm bu boşluğu gösterdi: "Meslekler"
        /// seçilen bir masalda öğretmen vardı, ama masal titrek bir ışık
        /// hakkındaydı ve öğretmenin mesleği hiçbir şey yapmıyordu. Kayıt
        /// süzüldüğü hâlde söz tutulmuyordu.
        ///
        /// Bu yuva `CatalogBlueprint.interests`'e bakıyor — o alan zaten tam
        /// bunu söylüyor: *"bağlanan içerikten bağımsız olarak masalın
        /// kendisinin neyle ilgili olduğu"*. Yani yeni bir eksen icat
        /// edilmedi, var olanı konu kapısına bağladı.
        ///
        /// Bedeli bilinçli: bir blueprint bu sözcüğü ancak PROZASI o işi
        /// gerçekten anlatıyorsa bildirir. Bildiren üçten az blueprint
        /// kalırsa konu `minimumMechanisms` kapısından geçmez ve ekrandan
        /// kalkar (karar: söz önce gelir).
        public let plot: [InterestTag]

        public init(setting: [InterestTag] = [], companion: [InterestTag] = [],
                    discovery: [InterestTag] = [], plot: [InterestTag] = []) {
            self.setting = setting
            self.companion = companion
            self.discovery = discovery
            self.plot = plot
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            setting = try c.decodeIfPresent([InterestTag].self, forKey: .setting) ?? []
            companion = try c.decodeIfPresent([InterestTag].self, forKey: .companion) ?? []
            discovery = try c.decodeIfPresent([InterestTag].self, forKey: .discovery) ?? []
            plot = try c.decodeIfPresent([InterestTag].self, forKey: .plot) ?? []
        }

        /// Hiçbir yuva şart koşmuyorsa bu konu hiçbir şey vaat etmiyor demektir.
        /// Böyle bir konu her masalı kabul eder, yani ekranda bir seçim gibi
        /// görünüp hiçbir şey seçmez. `CatalogIntegrity` bunu hata sayar.
        public var isEmpty: Bool {
            setting.isEmpty && companion.isEmpty && discovery.isEmpty && plot.isEmpty
        }

        public var allTags: [InterestTag] { setting + companion + discovery + plot }
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

    /// Olay örgüsü bu konu hakkında mı?
    ///
    /// Diğer üçünden farkı şu: bu reddi **kayıt bağlanmadan önce**, blueprint
    /// seçilirken veriliyor (`BlueprintSelector.admissible`). Bir şekil konu
    /// hakkında değilse o şekille kurulacak hiçbir bağlama onu konu hakkında
    /// yapamaz — meseleyi başka hayvanla çözmeye çalışmanın ta kendisi bu.
    public func rejection(blueprint record: CatalogBlueprint) -> String? {
        reason(requires.plot, record.interests, slot: "olay örgüsü")
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
