import Foundation

/// Simulator demo. One Stock tin with two days left, today's ticket empty, plus three more tins.
/// Assign stays the first live verb. Built through the fold so the phases are real.
enum LarderSeed {
    static let primaryID = UUID(uuidString: "C05A0001-0000-4000-8000-000000000001") ?? UUID()
    static let tomatoID = UUID(uuidString: "C05A0001-0000-4000-8000-000000000002") ?? UUID()
    static let chickpeaID = UUID(uuidString: "C05A0001-0000-4000-8000-000000000003") ?? UUID()
    static let riceID = UUID(uuidString: "C05A0001-0000-4000-8000-000000000004") ?? UUID()

    static func demo(today: Int, calendar: Calendar, now: Date) -> LarderRecord {
        let shelf = LocalShelfCatalog.products
        guard shelf.count >= 4,
              let plus2 = CookDay.adding(days: 2, to: today, calendar: calendar),
              let plus4 = CookDay.adding(days: 4, to: today, calendar: calendar),
              let plus5 = CookDay.adding(days: 5, to: today, calendar: calendar),
              let plus9 = CookDay.adding(days: 9, to: today, calendar: calendar),
              let tomorrow = CookDay.adding(days: 1, to: today, calendar: calendar) else {
            return .empty
        }
        var record = LarderRecord.empty
        record.onboardingComplete = true
        let rows: [(ShelfIdentity, UUID, Int)] = [
            (shelf[0], primaryID, plus2),
            (shelf[1], tomatoID, plus5),
            (shelf[2], chickpeaID, plus9),
            (shelf[3], riceID, plus4),
        ]
        for row in rows {
            let effect = LarderFold.reduce(
                record,
                .scan(title: row.0.title, barcode: row.0.barcode, packageDaykey: row.2, id: row.1, at: now),
                today: today,
                calendar: calendar
            )
            record = effect.record
        }
        let seated = LarderFold.reduce(
            record,
            .assign(tinID: riceID, cookDaykey: tomorrow, at: now),
            today: today,
            calendar: calendar
        )
        record = seated.record
        return record
    }
}
