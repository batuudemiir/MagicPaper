import Foundation
import StoryEngine

/// Okul öncesi "önce arkadaş" akışında sesle okunan her cümle, tek yerde
/// (26 Kasım 2026, Batuhan K3: cihazın sesi, `MPSpeech`). Her cümle en çok 12
/// kelime; ekran sessizken de resimle anlaşılır.
enum LittleCreationCopy {

    /// "Kim gelsin?" adımının sorusu.
    static let friendQuestion = "Kim gelsin?"

    /// Arkadaşın kendini tanıttığı tek cümle; dokununca okunur.
    static func intro(for companionID: String, name: String) -> String {
        switch companionID {
        case "companion_hedgehog_pilot_001": return "Ben Kestane! Küçük adımlarla cesaret ederim."
        case "companion_bear_001":           return "Ben Böğürtlen! Büyüğüm ama seni hep dinlerim."
        case "companion_fox_pilot_001":      return "Ben Tarçın! Acele etmem, seni beklerim."
        case "companion_owl_pilot_001":      return "Ben Yıldız! Az konuşur, dikkatle bakarım."
        case "companion_city_cat_001":       return "Ben Simit! Şehirden geldim, her şeyi merak ederim."
        default:                             return "Ben \(name)! Seninle gelmek isterim."
        }
    }

    static let surpriseIntro = "Sürpriz! Kim gelecek, birlikte göreceğiz."

    /// Tek cihaz sesi var; arkadaşlar yalnızca perde farkıyla ayrılır. Ayrı
    /// ses kişiliği vaat edilmez.
    static func pitch(for companionID: String?) -> Float {
        switch companionID {
        case "companion_hedgehog_pilot_001": return 1.25
        case "companion_bear_001":           return 0.85
        case "companion_owl_pilot_001":      return 1.1
        case "companion_city_cat_001":       return 1.15
        default:                             return 1.05
        }
    }

    /// "{Arkadaş} ile ne yapalım?"; Sürpriz'de yalnızca "Ne yapalım?".
    static func modeQuestion(friendName: String?) -> String {
        friendName.map { "\($0) ile ne yapalım?" } ?? "Ne yapalım?"
    }

    /// Konu adımında sorudan sonra; "Fark etmez" beşliyi korur.
    static func anyTopicLine(friendName: String?) -> String? {
        friendName.map { "Fark etmez dersen \($0) seninle gelir." }
    }

    /// Onay ekranı: kim geliyor ve ne yapıyoruz.
    static func confirmLine(friendName: String?, keepsFriend: Bool, mode: StoryMode) -> String {
        guard let friendName, keepsFriend else {
            return friendName == nil ? "Sürpriz bir arkadaş gelecek!" : "Bu konuda yeni bir arkadaş gelecek."
        }
        switch mode {
        case .bedtime:   return "\(friendName) ile uyku masalı geliyor!"
        case .adventure: return "\(friendName) ile maceraya çıkıyoruz!"
        case .learning:  return "\(friendName) ile yeni şeyler öğreniyoruz!"
        }
    }

    /// Düğmenin rengi söylenmez: renk bilgisi tek başına anlam taşımaz.
    static let startLine = "Hazırsan Başla'ya dokun."

    /// Onay ekranının başlığı.
    static let confirmTitle = "Hazır mısın?"

    /// Bu dosyadaki her cümle 12 kelimeyi geçmez (testte sayılır).
    static let maxWords = 12
}
