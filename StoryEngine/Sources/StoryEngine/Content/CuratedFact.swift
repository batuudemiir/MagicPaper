import Foundation

/// Masalda geçen, dünya hakkında gerçek bir iddia (B-ön 2, 23 Ekim 2026).
///
/// Sözlüğün (`CatalogGlossaryEntry`, FAZ 17) desenini kopyalıyor ve bu bilinçli:
/// orada da kayıt yazarın kararıdır, satır hangi kaydı öğrettiğini bildirir,
/// ve hiçbir şey tahmin etmez. Olgunun istediği tek fazladan şey **nereden
/// geldiği**: bir kelimenin anlamı eskiyemez, bir olgu eskir.
///
/// `CatalogObject.explainedBy` kullanılmadı, çünkü o başka bir soruyu
/// cevaplıyor: hangi *mekân özelliği* bu keşfi açıklar — yapısal açıklama.
/// Olgu ise dünya hakkında bir iddia. İkisini aynı alana koymak, A turunda
/// ayrılan eksenleri geri karıştırmak olurdu.
public struct CatalogFact: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// Olgu, **bizim** cümlemizle ve bu bant için. Kaynak metni asla.
    public let statement: String
    /// Hangi bantlar için yazıldı. Boş = her bant.
    ///
    /// Bugün hepsi 5-6: bir olgunun masala girdiği yer çocuğun bir şeyi
    /// anladığı beat ve o beat'ler `unexplained` ailesinin; 3-4'te öğrenelimin
    /// tek ailesi `charge` ve o bandın tüzüğü çıkarımı yasaklıyor.
    public let bands: [AgeBand]
    /// Kaynağın adı ve adresi. İkisi birden şart: ad olmadan adres bir gün ölü
    /// bağlantıya döner, adres olmadan ad doğrulanamaz.
    public let sourceName: String
    public let sourceURL: String
    /// Kaynakta doğrulandığı gün (ISO-8601 tarih). "Ne zaman doğruydu"
    /// sorusunun cevabı.
    public let verifiedOn: String
    public let review: Review

    /// İnceleme durumu. `approved` olmayan olgu seçime **girmez**, ve bu kodla
    /// zorlanır: onaysız bir olgu tutulamayan bir sözden kötüdür, yanlış
    /// bilgidir.
    public enum Review: String, Codable, Sendable, CaseIterable {
        /// Yazıldı, kaynağında okunmadı.
        case draft
        /// Yazıldı ama kaynağında doğrulanamadı (örn. kaynak otomatik
        /// erişime kapalı). Bir insanın açıp okuması gerekiyor.
        case sourceUnverified
        /// Kaynağında okundu ve onaylandı. Yalnızca bu durum masala girer.
        case approved
    }

    public var isApproved: Bool { review == .approved }

    private enum CodingKeys: String, CodingKey {
        case id, statement, bands, sourceName, sourceURL, verifiedOn, review
    }

    public init(
        id: ContentID, statement: String, bands: [AgeBand] = [],
        sourceName: String, sourceURL: String, verifiedOn: String, review: Review
    ) {
        self.id = id
        self.statement = statement
        self.bands = bands
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.verifiedOn = verifiedOn
        self.review = review
    }

    /// Eksik alanlar varsayılana düşmüyor, **hata** veriyor.
    ///
    /// Sözlükten ayrıldığı yer burası. Bir kelimenin `forms`'u eksikse
    /// terimin kendisi makul bir varsayılandır; bir olgunun kaynağı eksikse
    /// makul varsayılan yoktur — kaynaksız olgu, olgu değildir. Uzak bir
    /// paketin (FAZ 15) alanı atlayıp olguyu yine de göndermesi bu yüzden
    /// sessizce kabul edilmiyor.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(ContentID.self, forKey: .id)
        statement = try c.decode(String.self, forKey: .statement)
        bands = try c.decodeIfPresent([AgeBand].self, forKey: .bands) ?? []
        sourceName = try c.decode(String.self, forKey: .sourceName)
        sourceURL = try c.decode(String.self, forKey: .sourceURL)
        verifiedOn = try c.decode(String.self, forKey: .verifiedOn)
        review = try c.decode(Review.self, forKey: .review)
    }

    public func suits(band: AgeBand?) -> Bool {
        guard let band, !bands.isEmpty else { return true }
        return bands.contains(band)
    }
}
