import XCTest
@testable import Commissary

final class CommissaryTests: XCTestCase {
    private var calendar: Calendar!
    private var today: Int!
    private var now: Date!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar = gregorian
        now = Date(timeIntervalSince1970: 1_761_307_200) // 2025-10-24 12:00 UTC
        today = CookDay.daykey(for: now, calendar: calendar)
    }

    func testBestBeforeDaysLeftOrdersUseSoonAndMarkUsed() {
        let soon = day(2)
        let later = day(12)
        var record = LarderRecord.empty
        let soonID = UUID()
        let laterID = UUID()
        record = LarderFold.reduce(
            record,
            .scan(title: "Oat tin", barcode: "11111111", packageDaykey: later, id: laterID, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .scan(title: "Tomato tin", barcode: "22222222", packageDaykey: soon, id: soonID, at: now),
            today: today,
            calendar: calendar
        ).record
        let board = LarderFold.board(record, today: today, calendar: calendar)
        XCTAssertEqual(board.ladder.map(\.id), [soonID, laterID], "Use-soon ordered by best-before date, soonest days left first")
        XCTAssertEqual(board.ladder[0].daysLeft, 2)
        let monthToday = 20261030
        let monthPackage = 20261102
        let span = CookDay.daysRemaining(until: monthPackage, from: monthToday, calendar: calendar)
        XCTAssertEqual(span, 3, "Best-before days left crosses a month as calendar days")
        let finished = LarderFold.reduce(
            record,
            .assign(tinID: soonID, cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        ).record
        let cleared = LarderFold.reduce(
            finished,
            .finish(tinID: soonID, at: now),
            today: today,
            calendar: calendar
        ).record
        let phase = LarderFold.phase(of: soonID, in: cleared, today: today, calendar: calendar)
        XCTAssertEqual(phase, .cleared, "Mark used folds the tin off the ladder")
        XCTAssertFalse(CSVExporter.history(cleared).lowercased().contains("kcal"))
    }

    func testAssignEmptyPopulatedAndInvalid() {
        let missing = LarderFold.reduce(
            .empty,
            .assign(tinID: UUID(), cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        )
        XCTAssertEqual(missing.refusal, .blankBoard)
        XCTAssertEqual(LarderFold.board(.empty, today: today, calendar: calendar).mark, .blank)

        let tinID = UUID()
        let stock = LarderFold.reduce(
            .empty,
            .scan(title: "Oat tin", barcode: "5000159461122", packageDaykey: day(2), id: tinID, at: now),
            today: today,
            calendar: calendar
        ).record
        let seated = LarderFold.reduce(
            stock,
            .assign(tinID: tinID, cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        )
        XCTAssertNil(seated.refusal)
        XCTAssertEqual(seated.committed, .assign)
        XCTAssertEqual(LarderFold.phase(of: tinID, in: seated.record, today: today, calendar: calendar), .assigned)
        XCTAssertEqual(seated.record.assignMarks.first?.cookDaykey, today)

        let again = LarderFold.reduce(
            seated.record,
            .assign(tinID: tinID, cookDaykey: day(1), at: now),
            today: today,
            calendar: calendar
        )
        XCTAssertEqual(again.refusal, .duplicateAssign)
        XCTAssertEqual(again.record.duplicateMarks.count, 1)
        XCTAssertEqual(LarderFold.phase(of: tinID, in: again.record, today: today, calendar: calendar), .assigned)
        XCTAssertEqual(again.record.assignMarks.count, 1)
    }

    func testFinishOnStockIsRefusedAndMidnightLapses() {
        let tinID = UUID()
        let stock = LarderFold.reduce(
            .empty,
            .scan(title: "Oat tin", barcode: "5000159461122", packageDaykey: day(2), id: tinID, at: now),
            today: today,
            calendar: calendar
        ).record
        let early = LarderFold.reduce(
            stock,
            .finish(tinID: tinID, at: now),
            today: today,
            calendar: calendar
        )
        XCTAssertEqual(early.refusal, .earlyFinish)
        XCTAssertEqual(early.committed, .early)
        XCTAssertEqual(early.record.earlyMarks.count, 1)
        XCTAssertEqual(LarderFold.phase(of: tinID, in: early.record, today: today, calendar: calendar), .stock)
        XCTAssertTrue(early.record.finishMarks.isEmpty)

        let pastID = UUID()
        let past = LarderFold.reduce(
            .empty,
            .scan(title: "Tomato tin", barcode: "3017620422003", packageDaykey: day(-1), id: pastID, at: now),
            today: today,
            calendar: calendar
        ).record
        XCTAssertEqual(LarderFold.phase(of: pastID, in: past, today: today, calendar: calendar), .lapsed)

        let seatedID = UUID()
        var assigned = LarderFold.reduce(
            .empty,
            .scan(title: "Rice tin", barcode: "737628064502", packageDaykey: day(1), id: seatedID, at: now),
            today: today,
            calendar: calendar
        ).record
        assigned = LarderFold.reduce(
            assigned,
            .assign(tinID: seatedID, cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        ).record
        let rolled = LarderFold.reduce(
            assigned,
            .adjustPackage(tinID: seatedID, packageDaykey: day(-1)),
            today: today,
            calendar: calendar
        ).record
        XCTAssertEqual(LarderFold.phase(of: seatedID, in: rolled, today: today, calendar: calendar), .lapsed)
        let holds = LarderFold.lapsedHolds(rolled, today: today, calendar: calendar)
        XCTAssertEqual(holds.map(\.id), [seatedID])

        let clearedID = UUID()
        var cleared = LarderFold.reduce(
            .empty,
            .scan(title: "Chickpea tin", barcode: "8000500310427", packageDaykey: day(3), id: clearedID, at: now),
            today: today,
            calendar: calendar
        ).record
        cleared = LarderFold.reduce(
            cleared,
            .waste(tinID: clearedID, at: now),
            today: today,
            calendar: calendar
        ).record
        cleared = LarderFold.reduce(
            cleared,
            .adjustPackage(tinID: clearedID, packageDaykey: day(-3)),
            today: today,
            calendar: calendar
        ).record
        XCTAssertEqual(LarderFold.phase(of: clearedID, in: cleared, today: today, calendar: calendar), .cleared)
    }

    func testUndoPeelsFinishBackToAssigned() {
        let tinID = UUID()
        var record = LarderFold.reduce(
            .empty,
            .scan(title: "Oat tin", barcode: "5000159461122", packageDaykey: day(2), id: tinID, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .assign(tinID: tinID, cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .finish(tinID: tinID, at: now),
            today: today,
            calendar: calendar
        ).record
        XCTAssertEqual(LarderFold.phase(of: tinID, in: record, today: today, calendar: calendar), .cleared)
        let peeled = LarderFold.reduce(record, .undo, today: today, calendar: calendar)
        XCTAssertEqual(peeled.committed, .undo)
        XCTAssertEqual(LarderFold.phase(of: tinID, in: peeled.record, today: today, calendar: calendar), .assigned)
        XCTAssertTrue(peeled.record.finishMarks.isEmpty)
        XCTAssertEqual(peeled.record.assignMarks.count, 1)
    }

    func testBoardFoldsTicketsByCookDaykeyAndWritesBlank() {
        XCTAssertEqual(LarderFold.board(.empty, today: today, calendar: calendar).mark, .blank, "Blank")
        let first = UUID()
        let second = UUID()
        var record = LarderRecord.empty
        record = LarderFold.reduce(
            record,
            .scan(title: "Oat tin", barcode: "11111111", packageDaykey: day(3), id: first, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .scan(title: "Tomato tin", barcode: "22222222", packageDaykey: day(4), id: second, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .assign(tinID: first, cookDaykey: today, at: now),
            today: today,
            calendar: calendar
        ).record
        record = LarderFold.reduce(
            record,
            .assign(tinID: second, cookDaykey: day(1), at: now),
            today: today,
            calendar: calendar
        ).record
        let board = LarderFold.board(record, today: today, calendar: calendar)
        XCTAssertEqual(board.mark, .live)
        XCTAssertEqual(board.tickets.map(\.daykey), [today, day(1)])
        XCTAssertEqual(board.tickets[0].tins.map(\.id), [first])
        XCTAssertEqual(board.tickets[1].tins.map(\.id), [second])
        XCTAssertEqual(board.assignedTally, 1)
        XCTAssertTrue(board.ladder.isEmpty)
        let finished = LarderFold.reduce(
            record,
            .finish(tinID: first, at: now),
            today: today,
            calendar: calendar
        ).record
        let after = LarderFold.board(finished, today: today, calendar: calendar)
        XCTAssertFalse(after.tickets.contains { $0.tins.contains { $0.id == first } })
        XCTAssertEqual(after.pantry.cleared.map(\.id), [first])
    }

    func testSimulatorSeedLeavesTodayOpenForAssign() {
        let seeded = LarderSeed.demo(today: today, calendar: calendar, now: now)
        let board = LarderFold.board(seeded, today: today, calendar: calendar)
        XCTAssertEqual(board.mark, .live)
        XCTAssertEqual(board.assignedTally, 0)
        XCTAssertEqual(LarderFold.phase(of: LarderSeed.primaryID, in: seeded, today: today, calendar: calendar), .stock)
        let primary = board.ladder.first { $0.id == LarderSeed.primaryID }
        XCTAssertEqual(primary?.daysLeft, 2)
        XCTAssertEqual(seeded.tins.count, 4)
        XCTAssertTrue(seeded.onboardingComplete)
    }

    @MainActor
    func testPersistenceRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = "cms.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let tinID = UUID()
        let clock = now!
        let store = LarderStore(
            seedsDemo: false,
            defaults: defaults,
            directory: directory,
            now: { clock },
            calendar: calendar,
            debounce: .zero
        )
        await store.load()
        store.scan(title: "Oat tin", barcode: "5000159461122", packageDaykey: day(2), id: tinID)
        store.assign(tinID: tinID, cookDaykey: today)
        await store.flush()
        XCTAssertEqual(store.board.assignedTally, 1)
        XCTAssertGreaterThan(store.commitTick, 0)

        let reloaded = LarderStore(
            seedsDemo: false,
            defaults: defaults,
            directory: directory,
            now: { clock },
            calendar: calendar,
            debounce: .zero
        )
        await reloaded.load()
        XCTAssertEqual(LarderFold.phase(of: tinID, in: reloaded.record, today: today, calendar: calendar), .assigned)
        XCTAssertEqual(reloaded.record.assignMarks.first?.cookDaykey, today)
        XCTAssertEqual(reloaded.board.tickets.first?.tins.map(\.id), [tinID])
        let blob = try XCTUnwrap(defaults.data(forKey: LarderKeys.record))
        let decoded = try LarderRecord.decode(blob).get()
        XCTAssertEqual(decoded.schemaVersion, 1)
        defaults.removePersistentDomain(forName: suite)
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertNil(ReviewLaunch.screen(in: ["Commissary"]))
        XCTAssertEqual(ReviewLaunch.screen(in: ["Commissary", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Commissary", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Commissary", "-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Commissary", "-ReviewScreen", "pantry"]), "pantry")
        XCTAssertNil(ReviewLaunch.screen(in: ["Commissary", "-ReviewScreen"]))
    }

    func testBarcodeCandidatesAndProductStatus() throws {
        let fromURL = BarcodePayload.candidates(in: "https://world.openfoodfacts.org/product/123456789012")
        XCTAssertEqual(fromURL.first, "123456789012")
        XCTAssertTrue(fromURL.contains("0123456789012"))
        let json = Data(#"{"status":0,"product":null}"#.utf8)
        XCTAssertThrowsError(try ShelfDecoder.identity(fromProduct: json, fallbackCode: "12345678")) { error in
            XCTAssertEqual(error as? ShelfLookupError, .notFound)
        }
        let found = Data(#"{"status":1,"product":{"product_name":"Oat tin","code":"12345678","brands":"Millhouse","nutriments":{"energy-kcal_100g":"247"}}}"#.utf8)
        let identity = try ShelfDecoder.identity(fromProduct: found, fallbackCode: "12345678")
        XCTAssertEqual(identity.title, "Oat tin")
        XCTAssertEqual(ShelfDecoder.nutrimentKcal(from: found), 247)
        let broken = Data("not-json".utf8)
        XCTAssertThrowsError(try ShelfDecoder.identity(fromProduct: broken, fallbackCode: "1")) { error in
            XCTAssertEqual(error as? ShelfLookupError, .malformed)
        }
    }

    private func day(_ offset: Int) -> Int {
        CookDay.adding(days: offset, to: today, calendar: calendar) ?? today
    }
}
