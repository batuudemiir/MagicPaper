import Foundation
import StoryEngine

/// Okul öncesi "önce arkadaş" akışında sesle okunan her cümle, tek yerde.
///
/// Akış (26 Kasım 2026, Batuhan: "kısa ve net"): Kim gelsin? → {Arkadaş} ile
/// ne yapalım? → Kitap oluştur. Konu adımı ve "Hazır mısın?" sorusu bu yoldan
/// kalktı. Her cümle bir `MPVoiceLine`: stüdyo kaydının adı + kayıt yokken
/// cihaz sesinin okuyacağı metin. Liste ve dosya adları `docs/SESLENDIRME.md`;
/// `allLines` ile aynı kalır (testte karşılaştırılır).
///
/// Her cümle en çok 12 kelime; ekran sessizken de resimle anlaşılır.
enum LittleCreationCopy {

    /// Dosya adlarının ortak öneki.
    static let keyPrefix = "ses_olustur_"

    /// Arkadaşın dosya adındaki kısa adı; beşlinin dışındaki arkadaşın kaydı yok.
    static func friendKey(_ companionID: String?) -> String? {
        switch companionID {
        case "companion_hedgehog_pilot_001": return "kestane"
        case "companion_bear_001":           return "bogurtlen"
        case "companion_fox_pilot_001":      return "tarcin"
        case "companion_owl_pilot_001":      return "yildiz"
        case "companion_city_cat_001":       return "simit"
        default:                             return nil
        }
    }

    static func modeKey(_ mode: StoryMode) -> String {
        switch mode {
        case .bedtime:   return "uyku"
        case .adventure: return "macera"
        case .learning:  return "ogrenme"
        }
    }

    // MARK: - 1 · Kim gelsin?

    /// "Kim gelsin?" adımının sorusu (Ragi).
    static let friendQuestion = MPVoiceLine(key: keyPrefix + "kim_gelsin", text: "Kim gelsin?")

    /// Arkadaşın kendini tanıttığı tek cümle; dokununca okunur, arkadaşın sesiyle.
    /// Cümleler Batuhan ve İrem'in onayını bekliyor (26 Kasım 2026).
    static func intro(for companionID: String, name: String) -> MPVoiceLine {
        let text: String
        switch companionID {
        case "companion_hedgehog_pilot_001": text = "Ben Kestane! Küçük adımlarla cesaret ederim."
        case "companion_bear_001":           text = "Ben Böğürtlen! Büyüğüm ama seni hep dinlerim."
        case "companion_fox_pilot_001":      text = "Ben Tarçın! Acele etmem, seni beklerim."
        case "companion_owl_pilot_001":      text = "Ben Yıldız! Az konuşur, dikkatle bakarım."
        case "companion_city_cat_001":       text = "Ben Simit! Şehirden geldim, her şeyi merak ederim."
        default:                             text = "Ben \(name)! Seninle gelmek isterim."
        }
        let key = friendKey(companionID).map { keyPrefix + "tanitim_" + $0 } ?? keyPrefix + "tanitim_diger"
        return MPVoiceLine(key: key, text: text, pitch: pitch(for: companionID))
    }

    static let surpriseIntro = MPVoiceLine(key: keyPrefix + "tanitim_surpriz",
                                           text: "Sürpriz! Kim gelecek, birlikte göreceğiz.")

    /// Kayıt yokken tek cihaz sesi var; arkadaşlar yalnızca perde farkıyla
    /// ayrılır. Kayıtta her arkadaşın kendi sesi olur.
    static func pitch(for companionID: String?) -> Float {
        switch companionID {
        case "companion_hedgehog_pilot_001": return 1.25
        case "companion_bear_001":           return 0.85
        case "companion_owl_pilot_001":      return 1.1
        case "companion_city_cat_001":       return 1.15
        default:                             return 1.05
        }
    }

    // MARK: - 2 · Ne yapalım?

    /// "{Arkadaş} ile ne yapalım?"; Sürpriz'de yalnızca "Ne yapalım?" (Ragi).
    static func modeQuestion(friendName: String?, companionID: String? = nil) -> MPVoiceLine {
        guard let friendName else {
            return MPVoiceLine(key: keyPrefix + "ne_yapalim", text: "Ne yapalım?")
        }
        let key = friendKey(companionID).map { keyPrefix + "ne_yapalim_" + $0 } ?? keyPrefix + "ne_yapalim_diger"
        return MPVoiceLine(key: key, text: "\(friendName) ile ne yapalım?")
    }

    // MARK: - 3 · Kitap oluştur

    /// Son ekranın başlığı ve sesi: kim geliyor ve ne yapıyoruz (Ragi). Soru değil.
    static func startLine(friendName: String?, companionID: String? = nil, mode: StoryMode) -> MPVoiceLine {
        guard let friendName else {
            return MPVoiceLine(key: keyPrefix + "basla_surpriz", text: "Sürpriz bir arkadaş gelecek!")
        }
        let text: String
        switch mode {
        case .bedtime:   text = "\(friendName) ile uyku masalı geliyor!"
        case .adventure: text = "\(friendName) ile maceraya çıkıyoruz!"
        case .learning:  text = "\(friendName) ile yeni şeyler öğreniyoruz!"
        }
        let friend = friendKey(companionID) ?? "diger"
        return MPVoiceLine(key: keyPrefix + "basla_\(friend)_\(modeKey(mode))", text: text)
    }

    /// Son ekranın tek düğmesi (Batuhan'ın sözü, 26 Kasım 2026; dil kuralının
    /// istisnası: AGENTS.md "Dil").
    static let startButton = "Kitap oluştur"

    /// Henüz tanışılmamış arkadaşın karosunda (27 Kasım 2026). Seslendirilmez:
    /// ebeveynin göreceği kısa etiket.
    static let newFriendBadge = "Yeni"

    /// Bu arkadaşla bu moddaki her masal okunduysa mod kartında. Motor en
    /// uzun süre önce okunanı yeniden verir; ebeveyn bunu bilsin.
    static let readAllNote = "Hepsini okudunuz, en eskisi yeniden gelir"

    // MARK: - Liste

    /// Seslendirilecek her satır, kayıt sırasıyla: beşlinin adları sabit
    /// sırada (`StoryCreationSteps.littleFriendOrder`). `docs/SESLENDIRME.md`
    /// bu listeyle aynı kalır.
    static func allLines(friendNames: [String: String] = defaultFriendNames) -> [MPVoiceLine] {
        let friends = StoryCreationSteps.littleFriendOrder
        let name = { (id: String) in friendNames[id] ?? id }
        var lines = [friendQuestion, modeQuestion(friendName: nil)]
        lines += friends.map { modeQuestion(friendName: name($0), companionID: $0) }
        lines += friends.map { intro(for: $0, name: name($0)) }
        lines.append(surpriseIntro)
        for id in friends {
            for mode in [StoryMode.bedtime, .adventure, .learning] {
                lines.append(startLine(friendName: name(id), companionID: id, mode: mode))
            }
        }
        lines.append(startLine(friendName: nil, mode: .bedtime))
        return lines
    }

    /// Beşlinin katalog adları (kayıt listesi için; ekran adları kaynaktan gelir).
    static let defaultFriendNames: [String: String] = [
        "companion_hedgehog_pilot_001": "Kestane",
        "companion_bear_001": "Böğürtlen",
        "companion_fox_pilot_001": "Tarçın",
        "companion_owl_pilot_001": "Yıldız",
        "companion_city_cat_001": "Simit",
    ]

    /// Bu dosyadaki her cümle 12 kelimeyi geçmez (testte sayılır).
    static let maxWords = 12
}
