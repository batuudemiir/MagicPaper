import SwiftUI

// MARK: - Masal dünyası ↔ üretim teması köprüsü
//
// Tasarım 12 masal dünyası tanımlar (04-STATE-INTERACTIONS.md), uygulamanın
// üretim hattı ise 6 `StoryTheme` üzerinden çalışır. Arayüz 12 dünyayı gösterir,
// üretim çağrısı karşılık gelen temaya düşer. Metin masalı cihazdaki offline
// motorla yazılır (`OfflineStoryService`); dünya seçimi akıştan kalktı (FAZ 10),
// dünya artık yalnızca kapak sanatı ve tema eşlemesi için okunur.

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

// MARK: - Yaş aralığı

/// Profil oluşturmadaki 4 chip (03-SCREENS.md §2) — `AgeBandResolver`'ın
/// bantlarının ekrandaki karşılığı.
///
/// Eskiden 3-4 / 5-7 / 8-10 / 11-12 sunuyordu, motor ise 3-4 / 5-6 yazıyordu:
/// ekranın "5-7" dediği bir çocuk motorun hiçbir bandına tam oturmuyordu. Artık
/// bantların tek sahibi motordaki çözümleyici; burası yalnızca onları gösterir
/// ve `MPAgeRangeTests` ikisinin ayrışmadığını denetler.
///
/// Uygulama yaşı `Int` sakladığı için seçilen chip bandın üst yaşı olarak
/// kaydedilir; okurken `from(age:)` aynı çözümleyiciden geçer.
enum MPAgeRange: String, CaseIterable, Identifiable {
    case r34 = "3-4 yaş"
    case r56 = "5-6 yaş"
    case r78 = "7-8 yaş"
    case r910 = "9-10 yaş"

    var id: String { rawValue }

    /// Chip etiketi.
    var title: String { rawValue }

    /// Motorun bandı.
    var band: AgeBand {
        switch self {
        case .r34:  return AgeBand(lowerBound: 3, upperBound: 4)
        case .r56:  return AgeBand(lowerBound: 5, upperBound: 6)
        case .r78:  return AgeBand(lowerBound: 7, upperBound: 8)
        case .r910: return AgeBand(lowerBound: 9, upperBound: 10)
        }
    }

    /// Profile yazılan yaş: bandın üst ucu.
    var representativeAge: Int { band.upperBound }

    /// "{yaş} yaş · {n} masal" satırında kullanılan kısa etiket.
    var shortLabel: String { band.description }

    static func from(age: Int) -> MPAgeRange {
        let band = AgeBandResolver.band(forAge: age)
        return allCases.first { $0.band == band } ?? .r56
    }

    /// Masal yazılmış bantların chip'leri (C turu, 21 Ekim 2026).
    ///
    /// Yeni profil oluştururken sunulan liste budur: tutamayacağın bir yaş
    /// sözü vermemek için. **Kayıtlı profiller bundan etkilenmez** — 9
    /// yaşındaki bir çocuğun yaşı `from(age:)` ile hâlâ 9-10 okunur, hiçbir
    /// yere yazılmaz, hiçbir yerden silinmez.
    ///
    /// Liste boşsa (katalog okunamadı) dört chip'in hepsi döner: bilinmeyen
    /// bir durumda ebeveyne seçenek göstermemek, yanlış bilgi vermekten daha
    /// kötü.
    static func authored(_ bands: [AgeBand]) -> [MPAgeRange] {
        let authored = allCases.filter { bands.contains($0.band) }
        return authored.isEmpty ? allCases : authored
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
