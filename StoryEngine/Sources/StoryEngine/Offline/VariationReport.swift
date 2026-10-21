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

    /// Kurulamayan seed'lerin gerekçeleri, tekilleştirilmiş. Boş liste sağlıklı.
    public let failures: [String]
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
            failures: failures.sorted())
    }

    /// `editorialName`'in mekanizma yarısı: "III-2 - advocacy" → "advocacy".
    ///
    /// Ad kuralı içerikte tutarlı ("<aile numarası> - <mekanizma>"); ayıraç
    /// yoksa adın tamamı mekanizma sayılır, çünkü yanlış ayrıştırmaktansa
    /// kaba saymak iyidir — eksik sayım çeşitliliği olduğundan AZ gösterir,
    /// ki bu ölçümün güvenli yönü.
    static func mechanism(of id: ContentID, in catalog: ContentCatalog) -> String? {
        guard let name = catalog.blueprints.first(where: { $0.id == id })?.editorialName,
              !name.isEmpty else { return nil }
        guard let dash = name.range(of: " - ") else { return name }
        return String(name[dash.upperBound...]).trimmingCharacters(in: .whitespaces)
    }

    /// Sayfanın cümleleri. Nakarat da bir cümledir ve sayılır: kasıtlı tekrar
    /// da tekrardır, ölçüde görünmeli.
    static func sentences(of page: ComposedPage) -> [String] {
        page.text
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
