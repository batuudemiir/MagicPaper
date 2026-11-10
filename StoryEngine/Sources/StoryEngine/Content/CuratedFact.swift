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
    /// Olgunun **neye dayandığı** (karar: 30 Ekim 2026, Batuhan).
    ///
    /// "Her olgu kaynaklı" kuralı bilim için doğru, gündelik yaşam için
    /// saçma: "ekmek fırında pişer" için resmî kaynak aramak, kuralı
    /// kuralcılığa çevirir. Ama ayrımın bir yerde yazılı olması şart, yoksa
    /// kaynaksızlık sessizce yayılır.
    ///
    /// Ayrımın kendisi editoryal ve makineyle tespit edilemez — tıpkı
    /// 23 Ekim'in "insan kendi yerinde tanışır" kuralı gibi. Bu yüzden
    /// denetlenen şey ayrımın doğruluğu değil, **sonucu**: `sourced` olgu
    /// kaynaksız decode edilemez, `editorial` olgu ise sayı taşıyamaz
    /// (`CatalogIntegrity.editorial_fact_carries_a_number`) — sayı, bir
    /// gözlemin iddiaya dönüştüğü en net yapısal işaret.
    ///
    /// İkisi de `approved` olmadan masala girmiyor. Editoryal olmak onaydan
    /// kaçmak değil, kaynaktan muaf olmaktır.
    public let basis: Basis
    /// Kaynağın adı ve adresi. `sourced` olguda ikisi birden şart: ad olmadan
    /// adres bir gün ölü bağlantıya döner, adres olmadan ad doğrulanamaz.
    /// `editorial` olguda ikisi de yok.
    public let sourceName: String?
    public let sourceURL: String?
    /// Kaynakta doğrulandığı gün (ISO-8601 tarih). "Ne zaman doğruydu"
    /// sorusunun cevabı.
    public let verifiedOn: String
    public let review: Review

    /// Dayanak.
    public enum Basis: String, Codable, Sendable, CaseIterable {
        /// Dışarıdan doğrulanmış bir iddia: kaynak adı, adresi ve tarihi var.
        case sourced
        /// Kendi gözlemimiz: gündelik, tartışmasız, sayısız. Kaynağı yok,
        /// onayı var.
        case editorial
    }

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
        case id, statement, bands, basis, sourceName, sourceURL, verifiedOn, review
    }

    public init(
        id: ContentID, statement: String, bands: [AgeBand] = [],
        basis: Basis = .sourced, sourceName: String? = nil, sourceURL: String? = nil,
        verifiedOn: String, review: Review
    ) {
        self.id = id
        self.statement = statement
        self.bands = bands
        self.basis = basis
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
        // Dayanak yazılmamışsa `sourced`: eski kayıtların tamamı kaynaklı ve
        // varsayılanın SIKI olanı olması gerekiyor. Gevşek varsayılan, alanı
        // yazmayı unutan paketi kaynaksızlığa terfi ettirirdi.
        basis = try c.decodeIfPresent(Basis.self, forKey: .basis) ?? .sourced
        verifiedOn = try c.decode(String.self, forKey: .verifiedOn)
        review = try c.decode(Review.self, forKey: .review)
        switch basis {
        case .sourced:
            sourceName = try c.decode(String.self, forKey: .sourceName)
            sourceURL = try c.decode(String.self, forKey: .sourceURL)
        case .editorial:
            // Editoryal olguda kaynak alanı BULUNMAMALI. Varsa bu bir
            // çelişkidir ve sessizce yok saymak, yanlış etiketlenmiş bir
            // kaydı kaynaksız göstermek olur.
            guard !c.contains(.sourceName), !c.contains(.sourceURL) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .basis, in: c,
                    debugDescription: "editoryal olgu kaynak taşıyamaz (\(id.rawValue))")
            }
            sourceName = nil
            sourceURL = nil
        }
    }

    public func suits(band: AgeBand?) -> Bool {
        guard let band, !bands.isEmpty else { return true }
        return bands.contains(band)
    }
}
