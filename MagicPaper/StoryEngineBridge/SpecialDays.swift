import Foundation
import StoryEngine

/// Özel günler (E6, 17 Kasım 2026): doğum günü, okulun ilk günü, yeni kardeş,
/// ilk düşen diş.
///
/// Kayıt yapılandırılmıştır: tür, isteğe bağlı gün, yeni kardeş için isteğe
/// bağlı olarak çocuğun Masal ailem'indeki bir kardeşin kimliği. Serbest metin
/// yok, ad yazdırılmaz. Yalnızca cihazda, profil başına; hesapla eşitlenmez.
/// Log'a tür dışında hiçbir şey düşmez.
enum SpecialDayKind: String, Codable, CaseIterable, Identifiable {
    case birthday, firstSchoolDay, newSibling, firstLostTooth

    var id: String { rawValue }

    /// The engine's occasion id (`occasion_library_v1.json`).
    var occasionID: String {
        switch self {
        case .birthday: return "occasion_birthday"
        case .firstSchoolDay: return "occasion_first_school_day"
        case .newSibling: return "occasion_new_sibling"
        case .firstLostTooth: return "occasion_first_lost_tooth"
        }
    }

    init?(occasionID: String) {
        guard let kind = Self.allCases.first(where: { $0.occasionID == occasionID }) else { return nil }
        self = kind
    }

    var title: String {
        switch self {
        case .birthday: return "Doğum günü"
        case .firstSchoolDay: return "Okulun ilk günü"
        case .newSibling: return "Yeni kardeş"
        case .firstLostTooth: return "İlk düşen diş"
        }
    }

    /// The chip in "Masalda kimler olsun?".
    var chipTitle: String {
        switch self {
        case .birthday: return "Doğum günü masalı"
        case .firstSchoolDay: return "Okulun ilk günü masalı"
        case .newSibling: return "Yeni kardeş masalı"
        case .firstLostTooth: return "İlk diş masalı"
        }
    }

    var symbol: String {
        switch self {
        case .birthday: return "gift"
        case .firstSchoolDay: return "backpack"
        case .newSibling: return "figure.and.child.holdinghands"
        case .firstLostTooth: return "mouth"
        }
    }

    /// The engine request. A sibling is passed by name only, and only for
    /// "Yeni kardeş"; without one the story says "küçük kardeşi".
    func request(sibling: FamilyCharacter?) -> OccasionRequest {
        let cast = self == .newSibling
            ? sibling.flatMap { $0.relation.kind == .sibling ? FamilyCast(name: $0.name, relation: .sibling) : nil }
            : nil
        return OccasionRequest(kind: ContentID(occasionID), sibling: cast)
    }
}

/// One special day of one child.
struct SpecialDay: Codable, Equatable, Identifiable {
    var kind: SpecialDayKind
    /// `yyyy-MM-dd` (Gregorian, `SeriesClock.day` format); nil when the parent
    /// gave no date.
    var day: String?
    /// For `newSibling`: a sibling from the child's Masal ailem.
    var siblingID: UUID?

    var id: SpecialDayKind { kind }

    init(kind: SpecialDayKind, day: String? = nil, siblingID: UUID? = nil) {
        self.kind = kind
        self.day = day
        self.siblingID = siblingID
    }
}

/// When a special day is offered while writing a story: undated, or dated
/// within 14 days before and 7 days after today, counted in whole days in the
/// device's time zone (`SeriesClock` pattern).
enum SpecialDayWindow {
    static let pastLimit = 14
    static let aheadLimit = 7

    static func isActive(_ day: SpecialDay, today: Date, timeZone: TimeZone = .current) -> Bool {
        guard let stored = day.day else { return true }
        guard let offset = daysFromToday(to: stored, today: today, timeZone: timeZone) else { return false }
        return offset >= -pastLimit && offset <= aheadLimit
    }

    /// Whole days from today to the stored day; negative when it has passed.
    static func daysFromToday(to stored: String, today: Date, timeZone: TimeZone) -> Int? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = stored.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: date).day
    }

    /// A picked date as stored.
    static func dayString(_ date: Date, timeZone: TimeZone = .current) -> String {
        SeriesClock.day(of: date, in: timeZone)
    }
}

/// The special days on this device, per child: `UserDefaults`, one key each.
struct SpecialDayStore {
    var defaults: UserDefaults = .standard
    static let keyPrefix = "mp_specialdays_"

    private func key(_ profileID: UUID) -> String { Self.keyPrefix + profileID.uuidString }

    /// In the order of `SpecialDayKind.allCases`. An unreadable list reads as
    /// empty: a lost special day only means one chip fewer.
    func days(for profileID: UUID) -> [SpecialDay] {
        guard let data = defaults.data(forKey: key(profileID)),
              let days = try? JSONDecoder().decode([SpecialDay].self, from: data) else { return [] }
        return SpecialDayKind.allCases.compactMap { kind in days.first { $0.kind == kind } }
    }

    /// One per kind: saving a kind replaces its earlier record.
    func save(_ day: SpecialDay, for profileID: UUID) {
        var days = days(for: profileID).filter { $0.kind != day.kind }
        days.append(day)
        write(days, for: profileID)
    }

    func delete(_ kind: SpecialDayKind, for profileID: UUID) {
        write(days(for: profileID).filter { $0.kind != kind }, for: profileID)
    }

    /// Profile deletion.
    func deleteAll(for profileID: UUID) {
        defaults.removeObject(forKey: key(profileID))
    }

    /// The days to offer as chips today.
    func activeKinds(for profileID: UUID, today: Date = Date(), timeZone: TimeZone = .current) -> [SpecialDayKind] {
        days(for: profileID).filter { SpecialDayWindow.isActive($0, today: today, timeZone: timeZone) }.map(\.kind)
    }

    private func write(_ days: [SpecialDay], for profileID: UUID) {
        guard !days.isEmpty else { return defaults.removeObject(forKey: key(profileID)) }
        guard let data = try? JSONEncoder().encode(days) else { return }
        defaults.set(data, forKey: key(profileID))
    }
}
