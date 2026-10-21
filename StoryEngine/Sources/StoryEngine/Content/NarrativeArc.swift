import Foundation

/// Bir masalın konturu: duygu nereye kadar yükselir, nerede iner, nerede biter.
///
/// Aile (`NarrativeFamily`) masalın **mekanizmasını** söyler — merak neden
/// doğar, ne direnir, son nasıl kazanılır. Ark ise aynı mekanizmanın hangi
/// biçimde anlatıldığını söyler. Uyku öncesi yeni bir mekanizma değil: çatışması
/// yine süre, çözümü yine sabır (charge). Farkı yerde, duygu eğrisinde ve son
/// sayfanın başladığı yere dönmesinde (karar: 21 Ekim 2026, kitap araştırması
/// `c_bedtime_closes_circle`, privacy-safety'nin beş koşulu).
///
/// Yedinci bir aile yerine ayrı bir eksen olmasının nedeni: aile değerleri
/// mekanizma enum'larında benzersiz olmak zorunda ve uzak bir paketteki
/// bilinmeyen bir aile değeri eski uygulamada bütün paketi düşürür. Bilinmeyen
/// bir anahtar ise yok sayılır.
public enum NarrativeArc: String, Codable, Sendable, Hashable, CaseIterable {
    /// Arkını söylemeyen her blueprint ve şablon: bugünkü bütün içerik.
    case standard
    /// Uyku öncesi: yatakta başlar, doruğu erken ve yumuşaktır, aynı yerde
    /// en sakin hâliyle biter.
    case bedtime

    /// Bu arkta bir sayfanın taşıyabileceği en yüksek duygu yoğunluğu.
    ///
    /// Genel tavan 2 ve değişmez; uyku öncesi 3-4 bandında 1'e iner
    /// (privacy-safety koşul 2).
    public func intensityCeiling(for band: AgeBand?) -> Int {
        switch self {
        case .standard: return 2
        case .bedtime: return (band?.upperBound ?? Int.max) <= 4 ? 1 : 2
        }
    }

    /// Uyku arkında doruk olamayacak duygular: tedirginlik, kaygı, kuşku,
    /// hayal kırıklığı. Uyku masalının doruğu merak ya da hafif şaşkınlıktır
    /// (privacy-safety koşul 1). Yoğunluk 2'nin çaba ve sabır hâlleri serbest.
    public static let bedtimeForbiddenPeaks: Set<EmotionalState> = [
        .unease, .concern, .doubt, .frustration, .hesitation
    ]

    /// Uyku arkının hiçbir satırının ve yerinin taşıyamayacağı konular.
    /// Ebeveynin ayarından bağımsız (privacy-safety koşul 1).
    public static let bedtimeExcludedTopics: Set<SafetyTopic> = ["darkness", "alone", "fear"]
}
