import Foundation

/// "Masal anıları" (rozet planı 4.3): Duolingo'nun kişisel rekorlarının sakin
/// karşılığı. Rekor ve sayı değil, kapakla bir anı: ilk masal, en çok okunan
/// masal, en sık gidilen yer, en yakın yol arkadaşı. Rozet değildir, sayılmaz.
struct MPBadgeMemory: Identifiable, Equatable {
    enum Kind: String { case firstStory, mostRead, favoritePlace, closestFriend }
    let kind: Kind
    /// Gösterilen ad: masalın başlığı, yerin ya da dostun adı.
    let value: String
    var id: String { kind.rawValue }

    var title: String {
        switch kind {
        case .firstStory:    return "İlk masalın"
        case .mostRead:      return "En çok okuduğun masal"
        case .favoritePlace: return "En sık gittiğin yer"
        case .closestFriend: return "En yakın yol arkadaşın"
        }
    }

    var icon: String {
        switch kind {
        case .firstStory:    return "sparkles"
        case .mostRead:      return "heart"
        case .favoritePlace: return "map"
        case .closestFriend: return "pawprint"
        }
    }

    var tone: MPWorldTone {
        switch kind {
        case .firstStory:    return .lav
        case .mostRead:      return .pink
        case .favoritePlace: return .mint
        case .closestFriend: return .peach
        }
    }
}

enum MPBadgeMemories {

    /// Defterden ve çocuğun kitaplığından anılar. Bilgisi olmayan anı çıkmaz;
    /// masal silindiyse başlığı bilinmez, o anı da çıkmaz.
    static func build(ledger: MPBadgeLedger, stories: [Story],
                      placeName: (String) -> String?,
                      companionName: (String) -> String?) -> [MPBadgeMemory] {
        let byID = Dictionary(stories.map { ($0.id.uuidString, $0) }, uniquingKeysWith: { a, _ in a })
        let finished = ledger.finished.compactMap { byID[$0] }
        var out: [MPBadgeMemory] = []

        // İlk masal: okunduğu ilk gün en erken olan; gün bilinmiyorsa masalın kendi tarihi.
        let firstDay: (Story) -> String = { story in
            ledger.finishDays[story.id.uuidString]?.min()
                ?? MPBadgeDay.key(for: story.lastReadAt ?? story.createdAt)
        }
        if let first = finished.min(by: { (firstDay($0), $0.id.uuidString) < (firstDay($1), $1.id.uuidString) }) {
            out.append(MPBadgeMemory(kind: .firstStory, value: first.title))
        }

        // En çok okunan: en az iki ayrı günde okunmuş olmalı, yoksa anı değil.
        let reads = finished.map { ($0, ledger.finishDays[$0.id.uuidString]?.count ?? 1) }
        if let most = reads.filter({ $0.1 >= 2 })
            .max(by: { ($0.1, $1.0.id.uuidString) < ($1.1, $0.0.id.uuidString) }) {
            out.append(MPBadgeMemory(kind: .mostRead, value: most.0.title))
        }

        if let id = mostFrequent(finished.compactMap { $0.origin?.settingID }), let place = placeName(id) {
            out.append(MPBadgeMemory(kind: .favoritePlace, value: place))
        }
        if let id = mostFrequent(finished.compactMap { $0.origin?.companionID }), let friend = companionName(id) {
            out.append(MPBadgeMemory(kind: .closestFriend, value: friend))
        }
        return out
    }

    /// En sık geçen kimlik; eşitlikte sözlük sırasıyla ilki (her açılışta aynı).
    static func mostFrequent(_ ids: [String]) -> String? {
        let counts = Dictionary(ids.filter { !$0.isEmpty }.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }
}

/// Rozet ekranlarının tarih ve cümleleri.
enum MPBadgeCopy {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM"
        return f
    }()

    /// "12 Kasım tarihinde kazandın."
    static func earnedLine(_ date: Date) -> String {
        "\(formatter.string(from: date)) tarihinde kazandın."
    }

    static func reachedLine(_ date: Date) -> String {
        "\(formatter.string(from: date)) tarihinde ulaştın."
    }

    /// Sayfanın Ragi cümlesi: kazanılanı söyler, "az kaldı" demez (ilke 7).
    static func greeting(earned: Int) -> String {
        earned == 0
            ? "Masal okudukça rozetlerin burada toplanır."
            : "Her rozet bir masaldan geldi. Dokun, hangisi olduğunu anlatayım."
    }
}
