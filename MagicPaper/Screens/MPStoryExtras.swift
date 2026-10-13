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
        // Takılı kalmış eski masal metin masalı olarak açılır: sayfalarında
        // kalmış çizim izleri onu "Görselli" yapmaz.
        guard !opensAsTextOnly else { return false }
        return pages.contains { $0.imageUrl != nil || $0.imageFileName != nil }
    }

    /// Kapak olarak gösterilecek varlık adı.
    ///
    /// Metin masallarının kendi kapağı yok — motor sayfa yazıyor, resim
    /// üretmiyor. Kapak yerine dünya ikonunu göstermek kütüphaneyi bir uygulama
    /// listesine çeviriyordu; ortak bir illüstrasyon en azından kitap rafı gibi
    /// duruyor.
    ///
    /// Görselli masallar kendi kapaklarını kullanır, bu yüzden `nil` döner.
    var mpDefaultCoverAsset: String? {
        // Günlük masalı (FAZ 20): kendi boyalı kapağı.
        if let classic = ClassicsCatalog.coverAsset(for: id) { return classic }
        guard !isIllustrated, opensAsTextOnly || (coverImageFileName == nil && coverImageUrl == nil) else { return nil }
        return "StoryCoverDefault"
    }

    // MARK: - Cover System

    /// Explicit cover presentation decision.
    ///
    /// Asset existence does not implicitly define story type — this property
    /// makes the decision explicit. Text-only stories use the generative
    /// mosaic; illustrated stories use their own cover images.
    var mpCoverStyle: StoryCoverStyle {
        if isIllustrated || (!opensAsTextOnly && (coverImageFileName != nil || coverImageUrl != nil)) {
            return .illustrated
        }
        return .magicPaperMosaic
    }

    /// The generative mosaic cover configuration for this story.
    ///
    /// Computed via a stateless generator — no coupling from the model layer
    /// into the UI layer. Only meaningful when `mpCoverStyle == .magicPaperMosaic`.
    var mpMosaicCover: MagicPaperCoverConfiguration {
        MagicPaperCoverGenerator.configuration(
            for: id.uuidString,
            theme: CoverTheme.from(world: mpWorld)
        )
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
        let palette = MP.C.avatarAccents
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
        case .bedtime:     return MP.World.uzay.accent
        case .morning:     return MP.C.reward
        case .educational: return MP.World.deniz.accent
        case .values:      return MP.World.krallik.accent
        case .adventure:   return MP.World.korsan.accent
        case .nature:      return MP.World.orman.accent
        }
    }
}

extension DailyStory {
    /// "5 dk · 4-6 yaş" — sayılar her zaman birim sözcüğüyle.
    var mpMeta: String { "\(readingTime) dk · \(ageRange) yaş" }
}
