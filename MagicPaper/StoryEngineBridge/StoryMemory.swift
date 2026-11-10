import Foundation
import StoryEngine

/// Masal dünyası hatırlar (Faz 10, 12 Kasım 2026; `docs/VIZYON_PLANI.md`).
///
/// Yeni masalın yol arkadaşıyla çocuk daha önce bir masalda tanıştıysa ya da
/// çocuk daha önce gittiği bir yere döndüyse, ilk sayfaya tek bir hatırlama
/// cümlesi eklenir. Deterministik: aynı geçmiş, aynı cümle. Yapay metin yok;
/// cümle kalıbı burada, ekler motorun Türkçe dilbilgisinden (`TurkishGrammar`).
///
/// Seri bölümlerinde eklenmez: seri kendi devamlılığını taşır.
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

    /// Yeni masalın yeri ve yol arkadaşı, önceki biten masallar (en yeni başta
    /// olması gerekmez) ve kimliğe göre yer bulucu.
    static func recallLine(childName: String,
                           settingID: String, place: Place,
                           companionID: String, companionName: String,
                           previous: [Story],
                           placeNamed: (String) -> Place?) -> String? {
        let child = childName.trimmingCharacters(in: .whitespaces)
        guard !child.isEmpty else { return nil }
        let earlier = previous
            .filter { $0.isFinished && $0.origin != nil && $0.origin?.seriesEpisode == nil }
            .sorted { ($0.lastReadAt ?? $0.createdAt) < ($1.lastReadAt ?? $1.createdAt) }

        // Önce yol arkadaşı: bir dostluk, bir yerden daha güçlü bir bağ.
        if let first = earlier.first(where: { $0.origin?.companionID == companionID }),
           let firstSettingID = first.origin?.settingID {
            if firstSettingID == settingID {
                return "\(companionName) ile \(child) eski dostlardı. İlk kez burada, \(TurkishGrammar.inflect(place.noun, into: .locative)) tanışmışlardı."
            }
            if let old = placeNamed(firstSettingID) {
                return "\(companionName) ile \(child) eski dostlardı. İlk kez \(TurkishGrammar.inflect(old.noun, into: .locative)) tanışmışlardı."
            }
        }
        if earlier.contains(where: { $0.origin?.settingID == settingID }) {
            return "\(child) \(TurkishGrammar.inflect(place.noun, into: .dative)) daha önce de gelmişti. Burayı hemen hatırladı."
        }
        return nil
    }

    /// Cümleyi ilk sayfanın sonuna ayrı bir paragraf olarak ekler.
    static func remember(_ line: String?, in story: Story) -> Story {
        guard let line, !story.pages.isEmpty else { return story }
        var story = story
        story.pages[0].text += "\n\n" + line
        story.origin?.recalled = true
        return story
    }
}
