import SwiftUI
import StoryEngine

/// Yaratma akışı: bu çocuğun yaşı için henüz masal yazılmamış (C turu).
///
/// Buraya kadar olan davranış sessiz bir yanlıştı: 9 yaşındaki bir çocuk için
/// masal istendiğinde `servedBand` en yakın bandı seçiyor, log'a bir uyarı
/// yazıyor ve 5-6 yaş masalını 9 yaşındakinin adıyla yazıyordu. Ebeveyn bunu
/// göremez; yalnızca masalın beklediğinden basit olduğunu hisseder ve sebebini
/// bilemez. Yanlış bandı sessizce sunmak, açıkça söylemekten kötüdür.
///
/// Ekran üç şey yapar: durumu söyler, sebebi içeriğe bağlar (çocuğa değil), ve
/// yapılabilen bir şey varsa onu teklif eder. Kayıtlı profile **dokunmaz**:
/// yaş düzeltilmez, profil silinmez, başka banda yönlendirilmez.
struct StoryUnsupportedAgeStep: View {

    /// Masalı istenen çocuk.
    let childName: String
    let childAge: Int
    /// Masal yazılmış bantlar, küçükten büyüğe. Metindeki aralık bundan gelir.
    let authoredBands: [AgeBand]
    /// Masal yazılabilecek diğer çocuklar. Boşsa teklif edilecek bir şey yok.
    let alternatives: [UserProfile]
    let onPickAnother: () -> Void
    let onClose: () -> Void

    /// "3-6": sunulan bantların uçları. Elle yazılmıyor, çünkü 7-8 yazıldığı
    /// gün bu cümlenin de büyümesi gerekiyor.
    private var supportedRange: String {
        guard let first = authoredBands.first, let last = authoredBands.last else { return "" }
        return "\(first.lowerBound)-\(last.upperBound)"
    }

    private var message: String {
        var lines = ["\(childName) \(childAge) yaşında."]
        if !supportedRange.isEmpty {
            lines.append("Şimdilik \(supportedRange) yaş için masal yazıyoruz, "
                         + "daha büyük yaşların masalları hazırlanıyor.")
        } else {
            lines.append("Bu yaşın masalları hazırlanıyor.")
        }
        lines.append(alternatives.isEmpty
                     ? "Günlük'teki klasik masalları şimdi de birlikte okuyabilirsiniz."
                     : "İstersen bu masalı başka bir çocuk için yazalım.")
        return lines.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", action: onClose)
                Spacer(minLength: 0)
            }
            .padding(.top, MPSpacing.sm)

            MPStateView(mascot: .pencil, tone: .lav,
                        title: "Bu yaş için masallar hazırlanıyor",
                        message: message) {
                if alternatives.isEmpty {
                    MPButton(title: "Ana sayfaya dön", kind: .ghost, action: onClose)
                } else {
                    MPButton(title: "Başka bir çocuk seç", fullWidth: true, action: onPickAnother)
                        .padding(.horizontal, MPSpacing.xl)
                    MPButton(title: "Ana sayfaya dön", kind: .ghost, action: onClose)
                }
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
    }
}

#Preview("Desteklenmeyen yaş · başka çocuk var") {
    StoryUnsupportedAgeStep(
        childName: "Ada", childAge: 9,
        authoredBands: [AgeBand(lowerBound: 3, upperBound: 4), AgeBand(lowerBound: 5, upperBound: 6)],
        alternatives: [UserProfile(name: "Deniz", age: 5)],
        onPickAnother: {}, onClose: {})
        .background(MPColor.backgroundKid)
}

#Preview("Desteklenmeyen yaş · tek çocuk") {
    StoryUnsupportedAgeStep(
        childName: "Ada", childAge: 9,
        authoredBands: [AgeBand(lowerBound: 3, upperBound: 4), AgeBand(lowerBound: 5, upperBound: 6)],
        alternatives: [],
        onPickAnother: {}, onClose: {})
        .background(MPColor.backgroundKid)
}
