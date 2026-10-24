import Foundation

/// A cook day as an integer day key (YYYYMMDD). The ticket board groups assigned tins by this key.
/// Days left always uses Calendar day boundaries, never raw subtraction of the integers.
enum CookDay: Sendable {
    static func daykey(for date: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: date))
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func date(for daykey: Int, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = daykey / 10_000
        parts.month = (daykey / 100) % 100
        parts.day = daykey % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func adding(days: Int, to daykey: Int, calendar: Calendar) -> Int? {
        guard let date = date(for: daykey, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date) else {
            return nil
        }
        return Self.daykey(for: shifted, calendar: calendar)
    }

    /// Best-before minus today, in calendar days. Negative means the package day has passed.
    static func daysRemaining(until packageDaykey: Int, from today: Int, calendar: Calendar) -> Int? {
        guard let start = date(for: today, calendar: calendar),
              let end = date(for: packageDaykey, calendar: calendar) else {
            return nil
        }
        return calendar.dateComponents([.day], from: start, to: end).day
    }
}
