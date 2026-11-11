import Foundation
import StoryEngine

/// Yıllık (Faz 12): "Bu yıl İrem'in dünyasında".
///
/// Faz 10'un hafızasından kurulur: o yıl bitirilen masallar, gidilen yerler,
/// tanışılan dostlar, ilk ve son masal. Sayılar tek satırda kalır; yıllık bir
/// karne değil, bir anı defteri. Seri bölümleri de masaldır, sayılır.
struct MPYearbook: Equatable {
    struct Section: Equatable {
        let title: String
        let lines: [String]
    }

    let year: Int
    let childName: String
    /// Yılın biten masalları, okunduğu sırayla.
    let stories: [Story]
    let places: [(name: String, count: Int)]
    let friends: [String]

    static func == (a: MPYearbook, b: MPYearbook) -> Bool {
        a.year == b.year && a.childName == b.childName && a.stories.map(\.id) == b.stories.map(\.id)
            && a.places.map(\.name) == b.places.map(\.name) && a.friends == b.friends
    }

    init(year: Int, childName: String, stories: [Story], calendar: Calendar = .current,
         placeName: (String) -> String?, companionName: (String) -> String?) {
        self.year = year
        self.childName = childName
        let finished = stories
            .filter { $0.isFinished && calendar.component(.year, from: Self.date(of: $0)) == year }
            .sorted { Self.date(of: $0) < Self.date(of: $1) }
        self.stories = finished

        var counts: [String: Int] = [:]
        var order: [String] = []
        var friends: [String] = []
        for story in finished {
            if let id = story.origin?.settingID, let name = placeName(id) {
                if counts[name] == nil { order.append(name) }
                counts[name, default: 0] += 1
            }
            if let id = story.origin?.companionID, let name = companionName(id), !friends.contains(name) {
                friends.append(name)
            }
        }
        self.places = order.map { ($0, counts[$0] ?? 0) }.sorted { $0.1 > $1.1 }
        self.friends = friends
    }

    var isEmpty: Bool { stories.isEmpty }

    var title: String {
        let name = childName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "Bu yılın masalları" }
        return "Bu yıl " + TurkishGrammar.inflect(TurkishNoun(name, isProperNoun: true), into: .genitive) + " dünyasında"
    }

    /// "2026 yılında 12 masal, 4 yer, 5 dost."
    var summaryLine: String {
        var parts = ["\(stories.count) masal"]
        if !places.isEmpty { parts.append("\(places.count) yer") }
        if !friends.isEmpty { parts.append("\(friends.count) dost") }
        return "\(year) yılında " + parts.joined(separator: ", ") + "."
    }

    var sections: [Section] {
        var result: [Section] = []
        if !places.isEmpty {
            result.append(.init(title: "Gittiğin yerler",
                                lines: places.map { $0.count == 1 ? $0.name : "\($0.name), \($0.count) kez" }))
        }
        if !friends.isEmpty {
            result.append(.init(title: "Tanıştığın dostlar", lines: [friends.joined(separator: ", ")]))
        }
        if let first = stories.first {
            var lines = ["İlk masal: \(first.title), \(Self.dayLabel(Self.date(of: first)))"]
            if let last = stories.last, last.id != first.id {
                lines.append("Son masal: \(last.title), \(Self.dayLabel(Self.date(of: last)))")
            }
            result.append(.init(title: "Yılın masalları", lines: lines))
        }
        return result
    }

    /// Bitirildiği gün; yoksa yazıldığı gün.
    private static func date(of story: Story) -> Date { story.lastReadAt ?? story.createdAt }

    private static func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: date)
    }
}
