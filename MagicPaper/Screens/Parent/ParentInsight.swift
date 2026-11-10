import Foundation

/// Özet'in tek cümlesi (Faz 7): sayıları okumadan önce haftanın özeti.
/// Sakin ve yalın: ne oldu, baskı yok (CLAUDE.md ilke 7).
enum ParentInsight {

    /// Hafta Pazartesi başlar; başlık ve sayaç aynı haftaya bakar.
    static func weekInterval(containing date: Date = Date()) -> DateInterval? {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)
    }

    static func sentence(stories: Int, minutes: Int, streak: Int) -> String {
        guard stories > 0 || minutes > 0 else { return "Bu hafta henüz masal okunmadı." }
        var parts = ["Bu hafta \(stories) masal"]
        if minutes > 0 { parts.append("\(minutes) dakika") }
        var text = parts.joined(separator: ", ")
        if streak > 1 { text += ", \(streak) akşam üst üste" }
        return text + "."
    }
}
