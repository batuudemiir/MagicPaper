import Foundation

/// Bir çocuğun yaşının bir yaş bandına dönüştüğü **tek** yer.
///
/// Eskiden üç ayrı şema vardı: profil ekranı 3-4 / 5-7 / 8-10 / 11-12 sunuyor,
/// motor 3-4 / 5-6 yazıyor, eski prototip 3-4 / 5-6 / 7-8 / 9-10 / 11-12
/// kullanıyordu. Her biri "bu çocuk hangi bantta" sorusunu kendi başına
/// cevaplıyordu. Artık soru burada sorulur, cevap `AgeBand` olarak döner ve
/// motorun geri kalanı ham yaşla karar vermez.
///
/// Bantlar ürün kararıdır: 3-4, 5-6, 7-8, 9-10. MVP'nin içerik yazılmış bandı
/// 5-6'dır.
public enum AgeBandResolver {

    /// Ürünün tanıdığı bantlar, küçükten büyüğe.
    public static let bands: [AgeBand] = [
        AgeBand(lowerBound: 3, upperBound: 4),
        AgeBand(lowerBound: 5, upperBound: 6),
        AgeBand(lowerBound: 7, upperBound: 8),
        AgeBand(lowerBound: 9, upperBound: 10)
    ]

    /// İçeriğin öncelikle yazıldığı bant.
    public static let mvp = AgeBand(lowerBound: 5, upperBound: 6)

    /// Yaşın bandı. Aralığın dışındaki bir yaş en yakın uca oturur: 2 yaşındaki
    /// bir çocuk 3-4'e, 11 yaşındaki 9-10'a.
    public static func band(forAge age: Int) -> AgeBand {
        if let exact = bands.first(where: { $0.contains(age) }) { return exact }
        return age < bands[0].lowerBound ? bands[0] : bands[bands.count - 1]
    }

    /// İstenen bant için içerik yoksa hangi banttan sunulacağı.
    ///
    /// Bir GEÇİCİ ÇÖZÜM ve adıyla duruyor: 7-8 ve 9-10 için yazılmış içerik
    /// yok. Boş bir ekran bozuk bir uygulamadır; bu yüzden en yakın bant
    /// seçilir. Eşit uzaklıkta **küçük** bant tercih edilir — biraz basit bir
    /// masal, çocuğun takip edemeyeceği bir masaldan iyidir.
    ///
    /// `available` boşsa `nil`: sunulacak hiçbir şey yok.
    public static func servedBand(for requested: AgeBand, available: Set<AgeBand>) -> AgeBand? {
        if available.contains(requested) { return requested }
        return available.min { a, b in
            let da = abs(a.lowerBound - requested.lowerBound)
            let db = abs(b.lowerBound - requested.lowerBound)
            return da == db ? a.lowerBound < b.lowerBound : da < db
        }
    }
}
