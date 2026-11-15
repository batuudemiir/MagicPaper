import Foundation

/// Çocuk arayüzünün kademesi (karar: 14 Kasım 2026, Batuhan).
///
/// Dört yaş bandı masalın metnini belirler; arayüzü belirleyen tek ayrım
/// çocuğun okuyup okuyamadığıdır. Bu yüzden dört değil iki kademe:
///
/// - `little`: okul öncesi (3-4, 5-6). Seçim resimle, yazı en az, sayaç yok.
/// - `big`: okuyan çocuk (7-8, 9-10). Yazılı satırlar, konu ve sayaçlar.
///
/// Kademe yaştan türer; ebeveyn çocuğun profilinde "Kendi okuyor" anahtarıyla
/// değiştirebilir. Çocuğa kademenin adı hiçbir yerde gösterilmez.
enum KidLevel: String, Equatable {
    case little
    case big

    /// Bu yaştan itibaren çocuk okur sayılır: 7-8 bandının alt sınırı.
    static let readingAge = 7

    /// - Parameter readsAlone: ebeveynin seçimi; `nil` ise yaş karar verir.
    static func resolve(age: Int, readsAlone: Bool?) -> KidLevel {
        if let readsAlone { return readsAlone ? .big : .little }
        return age < readingAge ? .little : .big
    }
}

extension UserProfile {
    /// Bu çocuğun ekranlarının kademesi.
    var kidLevel: KidLevel { .resolve(age: age, readsAlone: readsAlone) }

    /// "Kendi okuyor" anahtarının gösterdiği değer: seçilmediyse yaşın dediği.
    var effectiveReadsAlone: Bool { kidLevel == .big }
}
