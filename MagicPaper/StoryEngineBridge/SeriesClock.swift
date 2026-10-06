import Foundation

/// The series' sense of "today" (FAZ 13, karar: 6 Ekim 2026).
///
/// One episode a day: the next episode opens on a calendar day after the one
/// on which the previous episode was read, in the time zone it was read in.
///
/// - **Now** is the later of the device clock and the latest time this clock
///   has ever seen (`highWater`). Turning the clock back therefore moves
///   nothing back: a reading is never dated earlier than a moment already
///   seen, and an opened episode is never locked again.
/// - **Turning the clock forward** opens the next episode early. Accepted: a
///   trustworthy clock needs the network, and the parent has no reason to.
/// - **The latest time seen may lead the device clock by at most two days**
///   (karar: 6 Ekim 2026). A clock set a year ahead by mistake and then
///   corrected would otherwise hold every series back for that year. Only a
///   reading made *while* the clock was wrong keeps its wrong day: dating it
///   again would let a clock set back more than two days open an episode
///   early, which the series never allows.
/// - **The day of a reading** is computed in the time zone of that moment and
///   compared in that same zone, so travelling does not move the boundary.
struct SeriesClock {
    static let highWaterKey = "mp_seriesClockHighWater"

    var wallClock: () -> Date
    var timeZone: () -> TimeZone
    var defaults: UserDefaults

    init(
        wallClock: @escaping () -> Date = SeriesClock.deviceClock,
        timeZone: @escaping () -> TimeZone = { TimeZone.current },
        defaults: UserDefaults = .standard
    ) {
        self.wallClock = wallClock
        self.timeZone = timeZone
        self.defaults = defaults
    }

    /// The device clock. In a DEBUG build, Ayarlar > Geliştirici can move it
    /// forward a day at a time to look at an opened episode in the simulator;
    /// a released app has no such switch (no "şimdi aç" for parents).
    static func deviceClock() -> Date {
        #if DEBUG
        let days = UserDefaults.standard.integer(forKey: debugDayOffsetKey)
        return Date().addingTimeInterval(TimeInterval(days) * 86_400)
        #else
        return Date()
        #endif
    }

    #if DEBUG
    static let debugDayOffsetKey = "mp_seriesClockDebugDays"
    #endif

    /// How far the latest time seen may lead the device clock.
    static let maximumLead: TimeInterval = 2 * 86_400

    /// The later of the device clock and the latest time seen, the latter
    /// never more than `maximumLead` ahead; recorded.
    func now() -> Date {
        let wall = wallClock()
        let seen = defaults.object(forKey: Self.highWaterKey) as? Date
        guard let seen, seen > wall else {
            defaults.set(wall, forKey: Self.highWaterKey)
            return wall
        }
        let capped = min(seen, wall.addingTimeInterval(Self.maximumLead))
        if capped < seen { defaults.set(capped, forKey: Self.highWaterKey) }
        return capped
    }

    /// A reading, dated now.
    func mark() -> SeriesReadMark {
        let at = now()
        let zone = timeZone()
        return SeriesReadMark(at: at, day: Self.day(of: at, in: zone), timeZone: zone.identifier)
    }

    /// Whether a calendar day has turned since the reading, in its time zone.
    func dayHasPassed(since mark: SeriesReadMark) -> Bool {
        let zone = TimeZone(identifier: mark.timeZone) ?? timeZone()
        return Self.day(of: now(), in: zone) > mark.day
    }

    /// `yyyy-MM-dd` in the Gregorian calendar, whatever the device calendar
    /// is: the string compares in date order.
    static func day(of date: Date, in zone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
