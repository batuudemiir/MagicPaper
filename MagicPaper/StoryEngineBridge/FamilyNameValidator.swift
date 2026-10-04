import Foundation

/// Masal ailem adının kuralları (FAZ 11). Ekran metni yok; gerekçeyi döndürür,
/// metni ekran (`FamilyCharacterCopy`) seçer.
///
/// Kurallar ek çekiminden geliyor. Ad masalda "Ela'ya", "Bulut'un" diye
/// çekilir: rakam, emoji ve simgenin ünlü uyumu yok, kesme işareti ekin
/// kendi işaretiyle çakışır, ünlüsüz bir sözcük çekilemez. Plan "rakam/emoji
/// ağırlıklı" diyordu; burada tek bir rakam ya da emoji bile reddettirir,
/// çünkü tek bir tanesi de çekimi bozar.
enum FamilyNameValidator {

    enum Rejection: Error, Equatable, Sendable {
        case empty
        case tooShort
        case tooLong
        case tooManyWords
        case invalidCharacters
        case noVowel
        case sameAsChild
        case duplicate
    }

    static let minLength = 2
    static let maxLength = 20
    static let maxWords = 3

    private static let locale = Locale(identifier: "tr_TR")
    private static let vowels = Set("aeıioöuüâîû")

    /// Normalleştirilmiş ad ya da ret gerekçesi.
    ///
    /// - Parameters:
    ///   - childName: Çocuğun kendi adı; aynı ad iki karakter yapar.
    ///   - existing: Çocuğun öteki Masal ailem adları. Düzenlenen karakterin
    ///     kendi adı bu listede olmamalı.
    static func validate(_ raw: String, childName: String, existing: [String]) -> Result<String, Rejection> {
        let words = raw.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return .failure(.empty) }
        guard words.count <= maxWords else { return .failure(.tooManyWords) }

        for word in words {
            // Tire yalnızca iki harf arasında: "Ayşe-Nur" evet, "-Ela" hayır.
            let parts = word.split(separator: "-", omittingEmptySubsequences: false)
            guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isLetter) }) else {
                return .failure(.invalidCharacters)
            }
        }

        let name = words.map(capitalised).joined(separator: " ")
        guard name.count >= minLength else { return .failure(.tooShort) }
        guard name.count <= maxLength else { return .failure(.tooLong) }
        guard name.lowercased(with: locale).contains(where: vowels.contains) else {
            return .failure(.noVowel)
        }

        let folded = fold(name)
        if folded == fold(childName) { return .failure(.sameAsChild) }
        if existing.contains(where: { fold($0) == folded }) { return .failure(.duplicate) }
        return .success(name)
    }

    /// "irem" → "İrem", "ELA" → "Ela", "ayşe-nur" → "Ayşe-Nur".
    static func capitalised(_ word: String) -> String {
        word.split(separator: "-", omittingEmptySubsequences: false).map { part in
            let lower = part.lowercased(with: locale)
            guard let first = lower.first else { return lower }
            return String(first).uppercased(with: locale) + lower.dropFirst()
        }
        .joined(separator: "-")
    }

    private static func fold(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased(with: locale)
    }
}
