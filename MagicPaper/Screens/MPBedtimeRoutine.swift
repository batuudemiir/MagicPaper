import Foundation

/// Akşam sırası (Faz 11, `docs/VIZYON_PLANI.md`): diş, pijama, masal, ışık.
///
/// Çocuk başına ve gün başına tutulur; ertesi sabah kendiliğinden boşalır.
/// Seri değil, sayaç değil: kaçırılan akşam hiçbir yerde görünmez, "kaldı"
/// denmez (CLAUDE.md ilke 7). Masal bitince `story`, "İyi geceler" ya da uyku
/// modu açılınca `light` kendiliğinden işaretlenir; diş ve pijamayı çocuk
/// kendisi işaretler. Yalnızca cihazda durur, eşitlenmez.
@MainActor
final class MPBedtimeRoutine: ObservableObject {
    static let shared = MPBedtimeRoutine()

    enum Step: String, CaseIterable, Identifiable {
        case teeth, pajamas, story, light
        var id: String { rawValue }

        var title: String {
            switch self {
            case .teeth: "Diş"
            case .pajamas: "Pijama"
            case .story: "Masal"
            case .light: "Işık"
            }
        }

        var symbol: String {
            switch self {
            case .teeth: "mouth"
            case .pajamas: "tshirt"
            case .story: "book"
            case .light: "lightbulb"
            }
        }
    }

    /// Değişiklikte görünümler yeniden çizilsin diye.
    @Published private(set) var revision = 0

    private let defaults: UserDefaults
    private let calendar: Calendar
    private static let keyPrefix = "mp_bedtimeRoutine_"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    /// Bu akşam işaretlenenler. Akşam sabah `MPTonight.morningHour`'da biter:
    /// gece yarısından sonra işaretlenen ışık bir önceki akşama sayılır.
    func done(for childID: UUID?, now: Date = Date()) -> Set<Step> {
        guard let childID,
              let stored = defaults.dictionary(forKey: Self.keyPrefix + childID.uuidString),
              stored["day"] as? String == eveningKey(now),
              let raw = stored["done"] as? [String] else { return [] }
        return Set(raw.compactMap(Step.init(rawValue:)))
    }

    func toggle(_ step: Step, for childID: UUID?, now: Date = Date()) {
        var steps = done(for: childID, now: now)
        if steps.contains(step) { steps.remove(step) } else { steps.insert(step) }
        save(steps, for: childID, now: now)
    }

    func mark(_ step: Step, for childID: UUID?, now: Date = Date()) {
        var steps = done(for: childID, now: now)
        guard !steps.contains(step) else { return }
        steps.insert(step)
        save(steps, for: childID, now: now)
    }

    /// Kartın tek satırlık sözü. Sıradaki adımı söyler, kalan sayıyı değil.
    static func caption(for done: Set<Step>) -> String {
        if done.count == Step.allCases.count { return "Hepsi tamam. İyi uykular." }
        if let next = Step.allCases.first(where: { !done.contains($0) }) {
            switch next {
            case .teeth: return "Önce dişler fırçalanır."
            case .pajamas: return "Sırada pijamalar var."
            case .story: return "Sırada masal var."
            case .light: return "Masal tamam. Sırada ışık var."
            }
        }
        return ""
    }

    private func save(_ steps: Set<Step>, for childID: UUID?, now: Date) {
        guard let childID else { return }
        defaults.set(["day": eveningKey(now), "done": steps.map(\.rawValue).sorted()],
                     forKey: Self.keyPrefix + childID.uuidString)
        revision += 1
    }

    private func eveningKey(_ now: Date) -> String {
        let shifted = calendar.date(byAdding: .hour, value: -MPTonight.morningHour, to: now) ?? now
        let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
