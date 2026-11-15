import Foundation
import StoryEngine

/// Masal dünyasının yerleri, haritanın ve yer adlarının diliyle (Faz 10).
///
/// Hatırlama cümlesi E3'ten (15 Kasım 2026) beri burada değil, motorda:
/// `StoryContextBuilder.recallHistory` çocuğun geçmişini kimlik ve sayı
/// olarak verir, motor içerik bağlandıktan sonra kademeyi seçer ve satırı
/// katalogdan (`recall_lines_v1.json`) yazar. Burada yalnızca haritanın
/// kullandığı yer kaydı kaldı.
enum StoryMemory {

    struct Place: Equatable {
        let name: String
        let isProperNoun: Bool
        let hasPossessiveEnding: Bool
        let blocksSoftening: Bool

        var noun: TurkishNoun {
            TurkishNoun(name, isProperNoun: isProperNoun, hasPossessiveEnding: hasPossessiveEnding,
                        blocksSoftening: blocksSoftening)
        }
    }
}
