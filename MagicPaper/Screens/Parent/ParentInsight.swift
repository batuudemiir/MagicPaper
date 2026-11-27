import Foundation
import StoryEngine

/// Özet'in tek cümlesi (Faz 7): sayıları okumadan önce haftanın özeti.
/// Sakin ve yalın: ne oldu, baskı yok (CLAUDE.md ilke 7).
///
/// 26 Kasım 2026 (değer önerisi 2): ebeveynin sorusu "işe yarıyor mu?".
/// Cümle artık dakika ve "üst üste" yerine haftanın gerçek kazançlarını
/// söyler: kaç akşam okundu, çocuk hangi kelimelerle ilk kez karşılaştı,
/// hangi masal arkadaşlarıyla okudu. Sayı sıfırlanmaz; kaçırılan akşam
/// "seriyi bozmaz". Her parça gerçek bir okuma kaydından gelir.
enum ParentInsight {

    /// Hafta Pazartesi başlar; başlık ve sayaç aynı haftaya bakar.
    static func weekInterval(containing date: Date = Date()) -> DateInterval? {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)
    }

    /// Bir haftanın kazançları.
    struct WeekGains: Equatable {
        /// Anlamlı bir okuma oturumu olan akşam sayısı (`MPStreak.thisWeek`).
        var evenings: Int
        /// Bu hafta sonuna kadar okunan masallar.
        var finished: Int
        /// Çocuğun bu hafta **ilk kez** karşılaştığı sözlük kelimeleri, en yeniden.
        var words: [String]
        /// Bu hafta biten masallardaki masal arkadaşları, ilk görülme sırasıyla.
        var friends: [String]
    }

    static func gains(stories: [Story], evenings: Int, week: DateInterval,
                      companionName: (String) -> String?) -> WeekGains {
        let finished = stories.filter { $0.isFinished && week.contains($0.lastReadAt ?? .distantPast) }
            .sorted { ($0.lastReadAt ?? .distantPast) < ($1.lastReadAt ?? .distantPast) }
        // İlk karşılaşma bütün masallara göre: önceki haftalarda görülmüş kelime yeni değildir.
        let words = MPVocabulary.collectedWords(in: stories)
            .filter { week.contains($0.date) }
            .map(\.word.term)
        var friends: [String] = []
        for story in finished {
            if let id = story.origin?.companionID, let name = companionName(id), !friends.contains(name) {
                friends.append(name)
            }
        }
        return WeekGains(evenings: evenings, finished: finished.count, words: words, friends: friends)
    }

    /// "Bu hafta 4 akşam masal okudunuz. İrem pusula, fener ve dalga
    /// kelimeleriyle ilk kez karşılaştı. Masal arkadaşları: Kestane, Tarçın."
    static func sentence(_ gains: WeekGains, childName: String) -> String {
        guard gains.evenings > 0 || gains.finished > 0 else { return "Bu hafta henüz masal okunmadı." }
        var parts: [String] = []
        if gains.evenings > 0 {
            parts.append("Bu hafta \(gains.evenings) akşam masal okudunuz.")
        } else {
            parts.append("Bu hafta \(gains.finished) masal okundu.")
        }
        let name = childName.trimmingCharacters(in: .whitespaces)
        let who = name.isEmpty ? "Çocuk" : name
        if !gains.words.isEmpty {
            let shown = Array(gains.words.prefix(3))
            let list = listed(shown)
            if gains.words.count > shown.count {
                parts.append("\(who) \(list) gibi \(gains.words.count) kelimeyle ilk kez karşılaştı.")
            } else {
                parts.append("\(who) \(list) \(shown.count == 1 ? "kelimesiyle" : "kelimeleriyle") ilk kez karşılaştı.")
            }
        }
        if !gains.friends.isEmpty {
            parts.append("Masal arkadaşları: \(gains.friends.joined(separator: ", ")).")
        }
        return parts.joined(separator: " ")
    }

    /// "a", "a ve b", "a, b ve c".
    static func listed(_ items: [String]) -> String {
        guard items.count > 1, let last = items.last else { return items.first ?? "" }
        return items.dropLast().joined(separator: ", ") + " ve " + last
    }
}

/// "Bu akşamın sorusu" (değer önerisi 3, 26 Kasım 2026): masal bittikten sonra
/// ebeveyne tek bir açık uçlu soru. Etkileşimli (diyalojik) okuma, ekran
/// karşısında yetişkin desteğinin fark yarattığı yer. Sınav değil: doğru
/// cevabı yok, puanı yok, çocuğa gösterilmez. Soru masalın gerçek bilgisinden
/// (mod ve masal arkadaşı) kurulur; masalda olmayan bir olay uydurmaz.
enum ParentQuestion {

    /// Dün ya da bugün biten en son masal.
    static func story(in stories: [Story], now: Date = Date(), calendar: Calendar = .current) -> Story? {
        stories
            .filter { story in
                guard story.isFinished, let read = story.lastReadAt else { return false }
                return calendar.isDate(read, inSameDayAs: now)
                    || calendar.isDate(read, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            }
            .max { ($0.lastReadAt ?? .distantPast) < ($1.lastReadAt ?? .distantPast) }
    }

    static func question(mode: StoryMode?, companion: String?) -> String {
        let friend = companion?.trimmingCharacters(in: .whitespaces) ?? ""
        switch mode {
        case .adventure:
            return friend.isEmpty
                ? "Sen o yolda olsaydın ne yapardın?"
                : "Sen de \(friend) ile o yolda olsaydın ne yapardın?"
        case .learning:
            return "Bu masalda yeni ne öğrendin? Bana da anlatır mısın?"
        case .bedtime:
            return friend.isEmpty
                ? "Masalın en sevdiğin anı hangisiydi?"
                : "\(friend) ile geçen masalın en sevdiğin anı hangisiydi?"
        case nil:
            return "Masalda en çok neyi sevdin, neden?"
        }
    }
}
