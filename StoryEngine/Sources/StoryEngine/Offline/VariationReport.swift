import Foundation
import EngineFoundation

/// Bir çocuğun arka arkaya kaç FARKLI masal alabildiğinin ölçüsü (21 Ekim 2026).
///
/// Motor bugüne kadar çeşitliliği hiç ölçmedi. Ölçülmeyen şey yönetilemiyor:
/// havuza içerik eklendiğinde gerçekten daha çeşitli mi olduğu, yoksa aynı
/// masalın dekorunun mu değiştiği kimsenin elinde bir rakamla yoktu.
///
/// Bu tip bir test yardımcısı değil, kütüphane: ölçümü testler de, ileride bir
/// içerik aracı da aynı yerden alsın diye. Testler yalnızca eşik koyar.
///
/// **Asıl ölçüt mekanizma sayısıdır.** Aynı blueprint'i farklı hayvan ve farklı
/// mekânla koşturmak yeni bir masal değil, aynı masalın başka dekorudur; o
/// yüzden mekân/arkadaş/nesne çeşitliliği ayrı ve ikincil eksenler olarak
/// sayılıyor. Bir konunun canlıya açılma koşulu mekanizma sayısıdır.
public struct VariationReport: Sendable, Hashable, Codable {

    /// Ölçümün yapıldığı kesit.
    public let mode: StoryMode
    public let band: AgeBand
    /// Kaç masal kuruldu (istenen seed sayısı).
    public let requested: Int
    /// Kaçı gerçekten kuruldu. Aradaki fark içerik boşluğudur, hata değil:
    /// o bantta o modun kurulamadığı anlamına gelir.
    public let composed: Int

    /// Farklı olay örgüsü mekanizması — `editorialName`'in mekanizma yarısı
    /// ("III-2 - advocacy" → "advocacy"). Asıl çeşitlilik ölçüsü.
    public let mechanisms: Int
    public let blueprints: Int
    public let settings: Int
    public let companions: Int
    public let discoveries: Int
    /// Farklı (blueprint, mekân, arkadaş, nesne) dörtlüsü: kaç ayrı kadro.
    public let casts: Int
    /// Farklı açılış ve kapanış cümlesi.
    public let openings: Int
    public let closings: Int

    /// Daha önce başka bir masalda geçmiş cümlelerin oranı (0…1).
    ///
    /// Tekrarın kendisi kusur değil — bir nakarat kasıtlı olabilir — ama
    /// ÖLÇÜLMEMESİ kusur: havuz büyürken bu oran artıyorsa, eklenen içerik
    /// çeşitlilik değil hacim getirmiş demektir.
    public let repeatedSentenceRate: Double

    /// Aynı oran, **ilan edilmiş nakarat satırları sayılmadan** (23 Ekim 2026).
    ///
    /// Kitap araştırma ajanının itirazı üzerine ölçüldü ve haklı çıktı: nakaratlı
    /// bir blueprint'te masallar arası tekrarın **8'de 6'sı** nakaratın kendisiydi
    /// (`blueprint_charge_tending_age3_001_refrain`, satır üç sayfada geçiyor,
    /// altı masal ölçüldü). Nakarat blueprint'in bir özelliği: o blueprint'in her
    /// masalı onu tasarım gereği tekrarlar, yani sayılması motorun prozayı ne
    /// kadar çeşitlendirdiği hakkında hiçbir şey söylemez.
    ///
    /// Masal **içi** tekrar zaten sayılmıyordu (`seenSentences` masal bittikten
    /// sonra güncelleniyor), yani itirazın o yarısında düzeltilecek bir şey yoktu.
    ///
    /// `repeatedSentenceRate` neden duruyor: beş taban kaydı (`variation_baseline.json`)
    /// onunla alındı ve tanımı değiştirmek geçmişi kıyaslanamaz yapardı. İki ölçü
    /// yan yana duruyor; nakaratsız katalogda ikisi birebir aynı.
    ///
    /// Araştırma dayanağı: 3-4 kitaplarının 11'inin 8'inde nakarat ya da tekrar
    /// eden yapı var, yani bu bantta tekrar şeklin kendisi. Kanıt düzeyi LOW
    /// (hepsi tek yayınevinden); ölçüyü değiştirme gerekçesi araştırma değil,
    /// yukarıdaki 8'de 6 ölçümü.
    public let repeatedSentenceRateExcludingRefrains: Double

    /// Kurulamayan seed'lerin gerekçeleri, tekilleştirilmiş. Boş liste sağlıklı.
    public let failures: [String]

    /// Alanı olmayan eski kayıtlar çözülmeye devam ediyor.
    ///
    /// Elle yazılmış decoder'ın tek sebebi bu: `variation_baseline.json`'da bu
    /// alandan önce alınmış beş kayıt var ve sentezlenmiş decoder onları
    /// reddederdi. Reddetmesi sessiz bir felaket olurdu — `testRecordBaseline`
    /// çözülemeyen dosyayı boş liste sayıp üstüne yazıyor, yani turların
    /// karşılaştırma geçmişi kaybolurdu.
    ///
    /// Eski kayıtta nakaratsız oran, nakaratlı oranın aynısı sayılıyor: o
    /// kayıtlar alındığında yayında nakaratlı blueprint yoktu, yani ikisi
    /// gerçekten eşitti.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decode(StoryMode.self, forKey: .mode)
        band = try c.decode(AgeBand.self, forKey: .band)
        requested = try c.decode(Int.self, forKey: .requested)
        composed = try c.decode(Int.self, forKey: .composed)
        mechanisms = try c.decode(Int.self, forKey: .mechanisms)
        blueprints = try c.decode(Int.self, forKey: .blueprints)
        settings = try c.decode(Int.self, forKey: .settings)
        companions = try c.decode(Int.self, forKey: .companions)
        discoveries = try c.decode(Int.self, forKey: .discoveries)
        casts = try c.decode(Int.self, forKey: .casts)
        openings = try c.decode(Int.self, forKey: .openings)
        closings = try c.decode(Int.self, forKey: .closings)
        repeatedSentenceRate = try c.decode(Double.self, forKey: .repeatedSentenceRate)
        repeatedSentenceRateExcludingRefrains = try c.decodeIfPresent(
            Double.self, forKey: .repeatedSentenceRateExcludingRefrains) ?? repeatedSentenceRate
        failures = try c.decodeIfPresent([String].self, forKey: .failures) ?? []
    }

    init(
        mode: StoryMode, band: AgeBand, requested: Int, composed: Int, mechanisms: Int,
        blueprints: Int, settings: Int, companions: Int, discoveries: Int, casts: Int,
        openings: Int, closings: Int, repeatedSentenceRate: Double,
        repeatedSentenceRateExcludingRefrains: Double, failures: [String]
    ) {
        self.mode = mode; self.band = band; self.requested = requested; self.composed = composed
        self.mechanisms = mechanisms; self.blueprints = blueprints; self.settings = settings
        self.companions = companions; self.discoveries = discoveries; self.casts = casts
        self.openings = openings; self.closings = closings
        self.repeatedSentenceRate = repeatedSentenceRate
        self.repeatedSentenceRateExcludingRefrains = repeatedSentenceRateExcludingRefrains
        self.failures = failures
    }
}

extension VariationReport {

    /// Sabit seed kümesiyle ölçer. Rastgelelik yok: aynı girdi, aynı rapor.
    ///
    /// - Parameter seeds: ölçümün kimliği. Değişirse rakamlar kıyaslanamaz,
    ///   bu yüzden baseline kaydında seed kümesi de saklanıyor.
    public static func measure(
        catalog: ContentCatalog,
        mode: StoryMode,
        band: AgeBand,
        seeds: [String],
        childName: String = "Yeliz",
        composer: OfflineStoryComposer = OfflineStoryComposer()
    ) -> VariationReport {
        var mechanisms = Set<String>()
        var blueprints = Set<ContentID>()
        var settings = Set<ContentID>()
        var companions = Set<ContentID>()
        var discoveries = Set<ContentID>()
        var casts = Set<[String]>()
        var openings = Set<String>()
        var closings = Set<String>()
        var failures = Set<String>()

        // Cümle sayımı sıraya duyarlı: bir cümlenin "tekrar" sayılması için
        // DAHA ÖNCE görülmüş olması gerekiyor, aynı masalın içinde değil.
        var seenSentences = Set<String>()
        var totalSentences = 0
        var repeatedSentences = 0
        // Nakaratsız ikizi: aynı sayım, ilan edilmiş nakarat satırları hiç
        // girmeden. Ayrı küme şart — nakarat satırını `seenSentences`'a koymak,
        // onu başka bir blueprint'in aynı cümlesiyle karıştırırdı.
        var seenWithoutRefrain = Set<String>()
        var totalWithoutRefrain = 0
        var repeatedWithoutRefrain = 0
        var composed = 0

        for seed in seeds {
            let intent = OfflineStoryIntent(
                childName: childName, seed: seed, mode: mode, ageBand: band)
            guard let story = try? composer.compose(catalog: catalog, intent: intent) else {
                // Gerekçe değil kategori toplanıyor: 50 seed'in 50'si aynı
                // sebepten düşerse bu tek satır olmalı.
                failures.insert("seed \(seed) kurulamadı")
                continue
            }
            composed += 1

            blueprints.insert(story.blueprintID)
            if let mechanism = mechanism(of: story.blueprintID, in: catalog) {
                mechanisms.insert(mechanism)
            }
            settings.insert(story.content.setting.id)
            companions.insert(story.content.companion.id)
            discoveries.insert(story.content.discovery.id)
            casts.insert([
                story.blueprintID.rawValue,
                story.content.setting.id.rawValue,
                story.content.companion.id.rawValue,
                story.content.discovery.id.rawValue
            ])

            let sentences = story.pages.flatMap(Self.sentences(of:))
            if let first = sentences.first { openings.insert(first) }
            if let last = sentences.last { closings.insert(last) }
            for sentence in sentences {
                totalSentences += 1
                if seenSentences.contains(sentence) { repeatedSentences += 1 }
            }

            let refrains = Self.refrainSentences(of: story, in: catalog)
            let withoutRefrain = sentences.filter { !refrains.contains($0) }
            for sentence in withoutRefrain {
                totalWithoutRefrain += 1
                if seenWithoutRefrain.contains(sentence) { repeatedWithoutRefrain += 1 }
            }
            seenWithoutRefrain.formUnion(withoutRefrain)
            // Masal bittikten sonra eklenir: aynı masalın içindeki tekrar başka
            // bir denetimin işi (`CatalogIntegrity`), burada ölçülen masallar
            // ARASINDAKİ tekrar.
            seenSentences.formUnion(sentences)
        }

        return VariationReport(
            mode: mode, band: band, requested: seeds.count, composed: composed,
            mechanisms: mechanisms.count, blueprints: blueprints.count,
            settings: settings.count, companions: companions.count,
            discoveries: discoveries.count, casts: casts.count,
            openings: openings.count, closings: closings.count,
            repeatedSentenceRate: totalSentences == 0
                ? 0 : Double(repeatedSentences) / Double(totalSentences),
            repeatedSentenceRateExcludingRefrains: totalWithoutRefrain == 0
                ? 0 : Double(repeatedWithoutRefrain) / Double(totalWithoutRefrain),
            failures: failures.sorted())
    }

    /// Bir blueprint kimliğinin mekanizması. Tanım `CatalogBlueprint.mechanism`
    /// içinde; burası yalnızca kimlikten kayda ulaşıyor.
    static func mechanism(of id: ContentID, in catalog: ContentCatalog) -> String? {
        catalog.blueprints.first { $0.id == id }?.mechanism
    }

    /// Bu masalın ilan edilmiş nakarat cümleleri, `sentences(of:)`'in ürettiği
    /// biçimde (noktalama ayracı atılmış, kırpılmış) — yoksa karşılaştırma
    /// hiçbir zaman tutmaz.
    static func refrainSentences(of story: ComposedStory, in catalog: ContentCatalog) -> Set<String> {
        guard let refrain = catalog.blueprints.first(where: { $0.id == story.blueprintID })?.refrain
        else { return [] }
        return Set([refrain.line, refrain.finalLine].flatMap(Self.split))
    }

    /// Sayfanın cümleleri. Nakarat da bir cümledir ve sayılır: kasıtlı tekrar
    /// da tekrardır, ölçüde görünmeli — nakaratı ayıklayan ölçü
    /// `repeatedSentenceRateExcludingRefrains`, ve ayıklamayı o yapıyor.
    static func sentences(of page: ComposedPage) -> [String] {
        split(page.text)
    }

    /// Metni cümlelere ayırmanın tek yeri: sayfa da nakarat da buradan geçiyor.
    static func split(_ text: String) -> [String] {
        text
            .split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Kayıt

/// Bir ölçüm turu: ne zaman, hangi sürümde, hangi seed'lerle, hangi rakamlar.
///
/// Baseline dosyası bu kayıtların listesi. Üzerine yazılmaz, eklenir —
/// "havuz büyüdü mü" sorusunun cevabı iki kayıt arasındaki fark.
public struct VariationBaseline: Sendable, Hashable, Codable {
    public let takenAt: String
    /// Hangi commit'te ölçüldü. Elle yazılır; ölçüm aracı git'i bilmez.
    public let revision: String
    /// Ne için alındı: "A öncesi taban", "A sonrası" gibi.
    public let note: String
    public let seeds: [String]
    public let reports: [VariationReport]

    public init(takenAt: String, revision: String, note: String,
                seeds: [String], reports: [VariationReport]) {
        self.takenAt = takenAt
        self.revision = revision
        self.note = note
        self.seeds = seeds
        self.reports = reports
    }
}

extension VariationBaseline {
    /// Ölçümün sabit seed kümesi.
    ///
    /// Elli seed: bir çocuğun aylar içinde yazdırabileceği masal sayısı
    /// mertebesinde. Küme sabit, çünkü değişirse rakamlar kıyaslanamaz.
    public static let standardSeeds: [String] = (1...50).map { "var-\($0)" }

    public func report(mode: StoryMode, band: AgeBand) -> VariationReport? {
        reports.first { $0.mode == mode && $0.band == band }
    }
}
