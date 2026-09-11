import SwiftUI

// MARK: - Masal dünyası ↔ üretim teması köprüsü
//
// Tasarım 12 masal dünyası tanımlar (04-STATE-INTERACTIONS.md), uygulamanın
// üretim hattı ise 6 `StoryTheme` üzerinden çalışır. Arayüz 12 dünyayı gösterir,
// üretim çağrısı karşılık gelen temaya düşer. Böylece görsel dil tasarıma
// uyarken mevcut Gemini/Fal.ai hattı olduğu gibi çalışmaya devam eder.

extension MP.World {

    /// Üretim hattına gidecek tema.
    var storyTheme: StoryTheme {
        switch self {
        case .krallik, .peri:    return .fantasy
        case .uzay, .robot:      return .space
        case .orman, .ciftlik:   return .jungle
        case .kahraman:          return .hero
        case .deniz:             return .underwater
        case .dinozor, .korsan, .kar, .sirk: return .custom
        }
    }

    /// Kayıtlı bir masalın temasından temsili dünya — kütüphane ve kapaklar için.
    static func from(theme: StoryTheme) -> MP.World {
        switch theme {
        case .fantasy:    return .krallik
        case .space:      return .uzay
        case .jungle:     return .orman
        case .hero:       return .kahraman
        case .underwater: return .deniz
        case .custom:     return .dinozor
        }
    }

    /// Tasarımdaki tile sırası: ilk 6 ücretsiz, son 6 premium.
    static let ordered: [MP.World] = [
        .krallik, .uzay, .orman, .kahraman, .deniz, .dinozor,
        .peri, .korsan, .kar, .ciftlik, .robot, .sirk
    ]
}

// MARK: - Masal uzunluğu

/// Sihirbazın 3. adımındaki uzunluk seçenekleri (03-SCREENS.md §4).
enum MPStoryLength: String, CaseIterable, Identifiable {
    case kisa, orta, uzun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kisa: return "Kısa"
        case .orta: return "Orta"
        case .uzun: return "Uzun"
        }
    }

    var detail: String {
        switch self {
        case .kisa: return "5 sayfa · 3 dakika"
        case .orta: return "8 sayfa · 6 dakika"
        case .uzun: return "12 sayfa · 9 dakika"
        }
    }

    var symbol: String {
        switch self {
        case .kisa: return "clock"
        case .orta: return "book"
        case .uzun: return "bookmark"
        }
    }

    var pageCount: Int {
        switch self {
        case .kisa: return 5
        case .orta: return 8
        case .uzun: return 12
        }
    }

    /// "Uzun" premium kilitlidir.
    var isPremium: Bool { self == .uzun }
}

// MARK: - Masal tonu

enum MPStoryTone: String, CaseIterable, Identifiable {
    case neseli, sakin, maceral, ogretici

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neseli:   return "Neşeli"
        case .sakin:    return "Sakin"
        case .maceral:  return "Maceralı"
        case .ogretici: return "Öğretici"
        }
    }
}

// MARK: - Yaş aralığı

/// Profil oluşturmadaki 4 chip (03-SCREENS.md §2). Uygulama yaşı `Int` sakladığı
/// için aralık ↔ tek yaş dönüşümü burada yapılır.
enum MPAgeRange: String, CaseIterable, Identifiable {
    case r34 = "3-4 yaş"
    case r57 = "5-7 yaş"
    case r810 = "8-10 yaş"
    case r1112 = "11-12 yaş"

    var id: String { rawValue }

    /// Chip etiketi.
    var title: String { rawValue }

    /// Üretim hattına gidecek temsili yaş (aralığın ortası).
    var representativeAge: Int {
        switch self {
        case .r34: return 4
        case .r57: return 6
        case .r810: return 9
        case .r1112: return 11
        }
    }

    /// "{yaş} yaş · {n} masal" satırında kullanılan kısa etiket.
    var shortLabel: String {
        switch self {
        case .r34: return "3-4"
        case .r57: return "5-7"
        case .r810: return "8-10"
        case .r1112: return "11-12"
        }
    }

    static func from(age: Int) -> MPAgeRange {
        switch age {
        case ..<5: return .r34
        case 5...7: return .r57
        case 8...10: return .r810
        default: return .r1112
        }
    }
}

// MARK: - Türkçe metin yardımcıları

enum MPText {

    /// Kütüphane araması Türkçe locale ile yapılır — i/ı ayrımı için zorunlu.
    static func foldedForSearch(_ s: String) -> String {
        s.lowercased(with: Locale(identifier: "tr_TR"))
    }

    /// Masal kartlarındaki "Dün", "Bugün", "3 gün önce" etiketi.
    static func relativeDayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Bugün" }
        if cal.isDateInYesterday(date) { return "Dün" }

        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date),
                                      to: cal.startOfDay(for: Date())).day ?? 0
        if days < 7 { return "\(days) gün önce" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }

    /// "8 sayfa · Dün" — sayılar her zaman birim sözcüğüyle eşlenir.
    static func storyMeta(pageCount: Int, date: Date, childName: String? = nil) -> String {
        var parts = ["\(pageCount) sayfa", relativeDayLabel(date)]
        if let childName, !childName.isEmpty { parts.append(childName) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Ekran iskeleti

extension View {
    /// Tüm ekranların zemini düz sıcak kağıt rengidir — gradyan yok, sistem rengi yok.
    func mpScreenBackground() -> some View {
        self.background(MP.C.surfaceApp.ignoresSafeArea())
    }

    /// Sabit 20px ekran yan boşluğu.
    func mpGutter() -> some View {
        self.padding(.horizontal, MP.S.screenGutter)
    }
}

// MARK: - Reduce Motion

extension MP.M {
    /// Sistem "Hareketi Azalt" ayarı.
    static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    /// 01-TOKENS.md: Reduce Motion açıkken tüm süreler 0'a iner.
    /// `nil` animasyon SwiftUI'de geçişi tamamen kapatır.
    static func gated(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}
