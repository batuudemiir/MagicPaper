import SwiftUI

// MARK: - Masalın tasarımda kullanılan türetilmiş alanları

extension Story {

    /// Kapak/tile rengini ve ikonunu veren temsili masal dünyası.
    ///
    /// Masal yazılırken KARARLAŞTIRILIR ve kaydedilir; burada yeniden
    /// hesaplanmaz. Sebebi tek satırda: kapak, masalın bir özelliğidir, o anki
    /// katalogun değil. Her çizimde katalogdan mekân aranıyor olsaydı, kapak
    /// katalog yüklenemediğinde sessizce değişir ve içerik büyüdükçe eski
    /// masalların kapakları altlarından kayardı.
    ///
    /// `worldID` yoksa eski tema haritasına düşer — motor öncesi masallar ve
    /// bu alan eklenmeden kaydedilmiş olanlar aynen çalışmaya devam eder.
    var mpWorld: MP.World {
        if let id = origin?.worldID, let world = MP.World(rawValue: id) { return world }
        return MP.World.from(theme: theme)
    }

    var mpAccent: Color { mpWorld.accent }
    var mpSymbol: String { mpWorld.symbol }

    /// En az bir sayfası çizilmişse masal "Görselli"dir.
    var isIllustrated: Bool {
        pages.contains { $0.imageUrl != nil || $0.imageFileName != nil }
    }

    /// Okuma ilerlemesi 0…1. Kayıtlı son sayfadan hesaplanır.
    ///
    /// Tek sayfalık masal özel olarak ele alınır. Önceki biçim
    /// `guard pages.count > 1` diyordu, yani tek sayfalık bir masal okunmuş
    /// olsa bile sonsuza kadar `0` dönüyordu: kütüphanede hep "Oku" kalıyor,
    /// asla bitmiş sayılmıyordu. Bir sayfa okunduysa o masal bitmiştir.
    var mpProgress: Double {
        guard !pages.isEmpty, let last = lastReadPage else { return 0 }
        guard pages.count > 1 else { return last >= 0 ? 1 : 0 }
        return min(1, max(0, Double(last) / Double(pages.count - 1)))
    }

    /// Masal sonuna kadar okundu mu?
    ///
    /// Tek yerde söylenir çünkü üç çağrı yeri (kütüphane, ana sayfa, masal
    /// eylemleri sayfası) "bitti"yi aynı şekilde anlamak zorunda.
    var isFinished: Bool { mpProgress >= 1 }

    /// "8 sayfa · Dün" — sayılar her zaman birim sözcüğüyle.
    var mpMeta: String {
        MPText.storyMeta(pageCount: pages.count, date: createdAt)
    }

    /// Kütüphane satırı: "8 sayfa · Dün · Elif"
    var mpMetaWithChild: String {
        MPText.storyMeta(pageCount: pages.count, date: createdAt, childName: childName)
    }
}

// MARK: - Favoriler
//
// `Story` modelinde favori alanı yok; kalıcılık ayrı bir anahtar üzerinden
// yürütülür ki mevcut kayıtlı masalların kod çözümü bozulmasın.

@MainActor
final class MPFavorites: ObservableObject {
    static let shared = MPFavorites()

    private let key = "mp_favoriteStoryIDs"
    @Published private(set) var ids: Set<String>

    private init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func contains(_ id: UUID) -> Bool { ids.contains(id.uuidString) }

    /// Döndürülen değer: yeni favori durumu.
    @discardableResult
    func toggle(_ id: UUID) -> Bool {
        let key = id.uuidString
        if ids.contains(key) {
            ids.remove(key)
        } else {
            ids.insert(key)
        }
        UserDefaults.standard.set(Array(ids), forKey: self.key)
        return ids.contains(key)
    }
}

// MARK: - Profil

extension UserProfile {
    var mpAgeRange: MPAgeRange { MPAgeRange.from(age: age) }

    /// Avatar rengi addan türetilir; profil ekranında elle de seçilebilir.
    var mpColor: Color {
        let palette: [Color] = [
            Color(hex: 0xD25C81), Color(hex: 0xE0A32E), Color(hex: 0x2E7D6B),
            Color(hex: 0xE4572E), Color(hex: 0x3A4E76), Color(hex: 0xB265A8)
        ]
        let stored = UserDefaults.standard.integer(forKey: "mp_avatarColor_\(id.uuidString)")
        if stored > 0, stored - 1 < palette.count { return palette[stored - 1] }
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }

    static func storeColorIndex(_ index: Int, for id: UUID) {
        UserDefaults.standard.set(index + 1, forKey: "mp_avatarColor_\(id.uuidString)")
    }
}

// MARK: - Günlük masal kategorisi
//
// Kategorinin kendi `emoji` ve sistem renkleri (indigo/teal…) tasarım sistemine
// aykırı olduğu için arayüzde bu eşleme kullanılır: Lucide→SF Symbol ikonu ve
// muted tema aksanı.

extension DailyStoryCategory {
    var mpSymbol: String {
        switch self {
        case .bedtime:     return "moon"
        case .morning:     return "sun.max"
        case .educational: return "book"
        case .values:      return "heart"
        case .adventure:   return "tent"
        case .nature:      return "tree"
        }
    }

    var mpAccent: Color {
        switch self {
        case .bedtime:     return Color(hex: 0x3A4E76) // tema-uzay
        case .morning:     return Color(hex: 0xE0A32E) // hardal
        case .educational: return Color(hex: 0x2A7A94) // tema-deniz
        case .values:      return Color(hex: 0xD25C81) // tema-krallik
        case .adventure:   return Color(hex: 0x8A5A32) // tema-korsan
        case .nature:      return Color(hex: 0x2E7D6B) // tema-orman
        }
    }
}

extension DailyStory {
    /// "5 dk · 4-6 yaş" — sayılar her zaman birim sözcüğüyle.
    var mpMeta: String { "\(readingTime) dk · \(ageRange) yaş" }
}
