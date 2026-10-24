import Foundation

/// Deterministic ADT fold. Scan adds a Stock tin. Assign writes AssignMark and seats it on cookDaykey.
/// Finish writes FinishMark and clears an Assigned tin. Finish on Stock writes EarlyMark and is refused.
/// Assign on Assigned writes DuplicateMark and is refused. Midnight is derived: Stock or Assigned
/// with packageDaykey before today becomes Lapsed. An empty live board is Blank.
enum LarderFold {
    static func reduce(
        _ record: LarderRecord,
        _ command: LarderCommand,
        today: Int,
        calendar: Calendar
    ) -> FoldEffect {
        var next = record
        switch command {
        case let .scan(title, barcode, packageDaykey, id, at):
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || packageDaykey <= 0 {
                return FoldEffect(record: record, refusal: .invalidScan, committed: nil)
            }
            if next.tins.contains(where: { $0.id == id }) {
                return FoldEffect(record: record, refusal: .missingTin, committed: nil)
            }
            next.tins.append(
                Tin(id: id, title: trimmed, barcode: barcode, packageDaykey: packageDaykey, recordedAt: at)
            )
            return FoldEffect(record: next, refusal: nil, committed: .scan)
        case let .assign(tinID, cookDaykey, at):
            guard next.tins.contains(where: { $0.id == tinID }) else {
                return FoldEffect(record: record, refusal: next.tins.isEmpty ? .blankBoard : .missingTin, committed: nil)
            }
            let phase = phase(of: tinID, in: next, today: today, calendar: calendar)
            if phase == .assigned {
                next.duplicateMarks.append(
                    DuplicateMark(
                        id: UUID(),
                        sequence: next.takeSequence(),
                        tinID: tinID,
                        cookDaykey: cookDaykey,
                        recordedAt: at
                    )
                )
                return FoldEffect(record: next, refusal: .duplicateAssign, committed: .duplicate)
            }
            guard phase == .stock else {
                return FoldEffect(record: record, refusal: .notLive, committed: nil)
            }
            next.assignMarks.append(
                AssignMark(
                    id: UUID(),
                    sequence: next.takeSequence(),
                    tinID: tinID,
                    cookDaykey: cookDaykey,
                    recordedAt: at
                )
            )
            return FoldEffect(record: next, refusal: nil, committed: .assign)
        case let .finish(tinID, at):
            guard next.tins.contains(where: { $0.id == tinID }) else {
                return FoldEffect(record: record, refusal: .missingTin, committed: nil)
            }
            let phase = phase(of: tinID, in: next, today: today, calendar: calendar)
            if phase == .stock {
                next.earlyMarks.append(
                    EarlyMark(id: UUID(), sequence: next.takeSequence(), tinID: tinID, recordedAt: at)
                )
                return FoldEffect(record: next, refusal: .earlyFinish, committed: .early)
            }
            guard phase == .assigned else {
                return FoldEffect(record: record, refusal: .notLive, committed: nil)
            }
            next.finishMarks.append(
                FinishMark(id: UUID(), sequence: next.takeSequence(), tinID: tinID, recordedAt: at)
            )
            return FoldEffect(record: next, refusal: nil, committed: .finish)
        case let .waste(tinID, at):
            guard next.tins.contains(where: { $0.id == tinID }) else {
                return FoldEffect(record: record, refusal: .missingTin, committed: nil)
            }
            let phase = phase(of: tinID, in: next, today: today, calendar: calendar)
            guard phase == .stock || phase == .assigned || phase == .lapsed else {
                return FoldEffect(record: record, refusal: .notLive, committed: nil)
            }
            next.wasteMarks.append(
                WasteMark(id: UUID(), sequence: next.takeSequence(), tinID: tinID, recordedAt: at)
            )
            return FoldEffect(record: next, refusal: nil, committed: .waste)
        case .undo:
            guard peel(&next) else {
                return FoldEffect(record: record, refusal: .nothingToUndo, committed: nil)
            }
            return FoldEffect(record: next, refusal: nil, committed: .undo)
        case .cullLapsed:
            let doomed = next.tins.filter {
                phase(of: $0.id, in: next, today: today, calendar: calendar) == .lapsed
            }
            if doomed.isEmpty {
                return FoldEffect(record: record, refusal: .nothingToCull, committed: nil)
            }
            let ids = Set(doomed.map(\.id))
            next.tins.removeAll { ids.contains($0.id) }
            next.archivedTins.append(contentsOf: doomed)
            return FoldEffect(record: next, refusal: nil, committed: .cull)
        case let .adjustPackage(tinID, packageDaykey):
            guard packageDaykey > 0, let index = next.tins.firstIndex(where: { $0.id == tinID }) else {
                return FoldEffect(record: record, refusal: .missingTin, committed: nil)
            }
            next.tins[index].packageDaykey = packageDaykey
            return FoldEffect(record: next, refusal: nil, committed: .adjust)
        }
    }

    static func phase(of tinID: UUID, in record: LarderRecord, today: Int, calendar: Calendar) -> TinPhase {
        guard let tin = record.tins.first(where: { $0.id == tinID }) else {
            return .cleared
        }
        return phase(of: tin, in: record, today: today, calendar: calendar).phase
    }

    static func folded(_ record: LarderRecord, today: Int, calendar: Calendar) -> [FoldedTin] {
        record.tins.map { phase(of: $0, in: record, today: today, calendar: calendar) }
    }

    static func board(_ record: LarderRecord, today: Int, calendar: Calendar) -> CookDayBoard {
        let foldedTins = folded(record, today: today, calendar: calendar)
        let live = foldedTins.filter { $0.phase == .stock || $0.phase == .assigned }
        if live.isEmpty {
            return CookDayBoard(
                mark: .blank,
                featuredDaykey: today,
                tickets: [],
                ladder: [],
                assignedTally: 0,
                featuredDaysLeft: nil,
                pantry: pantry(from: foldedTins)
            )
        }
        let ladder = foldedTins
            .filter { $0.phase == .stock }
            .sorted { lhs, rhs in
                if lhs.daysLeft != rhs.daysLeft { return lhs.daysLeft < rhs.daysLeft }
                if lhs.tin.packageDaykey != rhs.tin.packageDaykey {
                    return lhs.tin.packageDaykey < rhs.tin.packageDaykey
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .map {
                LadderRung(
                    id: $0.id,
                    title: $0.tin.title,
                    daysLeft: $0.daysLeft,
                    packageDaykey: $0.tin.packageDaykey,
                    barcode: $0.tin.barcode
                )
            }
        var grouped: [Int: [FoldedTin]] = [:]
        for tin in foldedTins where tin.phase == .assigned {
            let key = tin.cookDaykey ?? today
            grouped[key, default: []].append(tin)
        }
        if grouped[today] == nil {
            grouped[today] = []
        }
        let tickets = grouped.keys.sorted().map { key in
            CookDayTicket(
                daykey: key,
                tins: (grouped[key] ?? []).sorted { $0.daysLeft < $1.daysLeft }
            )
        }
        let tally = tickets.first { $0.daykey == today }?.tins.count ?? 0
        let soonest = live.map(\.daysLeft).min()
        return CookDayBoard(
            mark: .live,
            featuredDaykey: today,
            tickets: tickets,
            ladder: ladder,
            assignedTally: tally,
            featuredDaysLeft: soonest,
            pantry: pantry(from: foldedTins)
        )
    }

    static func lapsedHolds(_ record: LarderRecord, today: Int, calendar: Calendar) -> [LapsedHold] {
        folded(record, today: today, calendar: calendar).compactMap { item in
            guard item.phase == .lapsed else { return nil }
            return LapsedHold(
                id: item.id,
                tin: item.tin,
                daysPast: max(0, -item.daysLeft),
                cookDaykey: item.cookDaykey
            )
        }
    }

    private static func pantry(from foldedTins: [FoldedTin]) -> PantryLedger {
        PantryLedger(
            assigned: foldedTins.filter { $0.phase == .assigned },
            stock: foldedTins.filter { $0.phase == .stock },
            lapsed: foldedTins.filter { $0.phase == .lapsed },
            cleared: foldedTins.filter { $0.phase == .cleared }
        )
    }

    private static func phase(
        of tin: Tin,
        in record: LarderRecord,
        today: Int,
        calendar: Calendar
    ) -> FoldedTin {
        let days = CookDay.daysRemaining(until: tin.packageDaykey, from: today, calendar: calendar) ?? 0
        let winner = latestLiveMark(for: tin.id, in: record)
        var phase: TinPhase
        var cookDaykey: Int?
        switch winner {
        case .none:
            phase = .stock
        case let .assign(mark):
            phase = .assigned
            cookDaykey = mark.cookDaykey
        case .finish, .waste:
            phase = .cleared
        }
        if (phase == .stock || phase == .assigned) && tin.packageDaykey < today {
            phase = .lapsed
        }
        return FoldedTin(tin: tin, phase: phase, cookDaykey: cookDaykey, daysLeft: days)
    }

    private enum LiveWinner {
        case none
        case assign(AssignMark)
        case finish(FinishMark)
        case waste(WasteMark)
    }

    private static func latestLiveMark(for tinID: UUID, in record: LarderRecord) -> LiveWinner {
        var best = Int.min
        var winner = LiveWinner.none
        for mark in record.assignMarks where mark.tinID == tinID && mark.sequence >= best {
            best = mark.sequence
            winner = .assign(mark)
        }
        for mark in record.finishMarks where mark.tinID == tinID && mark.sequence >= best {
            best = mark.sequence
            winner = .finish(mark)
        }
        for mark in record.wasteMarks where mark.tinID == tinID && mark.sequence >= best {
            best = mark.sequence
            winner = .waste(mark)
        }
        return winner
    }

    private static func peel(_ record: inout LarderRecord) -> Bool {
        struct Candidate {
            enum Kind { case assign, finish, waste }
            var sequence: Int
            var id: UUID
            var kind: Kind
        }
        var best: Candidate?
        for mark in record.assignMarks {
            if best == nil || mark.sequence > (best?.sequence ?? .min) {
                best = Candidate(sequence: mark.sequence, id: mark.id, kind: .assign)
            }
        }
        for mark in record.finishMarks {
            if best == nil || mark.sequence > (best?.sequence ?? .min) {
                best = Candidate(sequence: mark.sequence, id: mark.id, kind: .finish)
            }
        }
        for mark in record.wasteMarks {
            if best == nil || mark.sequence > (best?.sequence ?? .min) {
                best = Candidate(sequence: mark.sequence, id: mark.id, kind: .waste)
            }
        }
        guard let best else { return false }
        switch best.kind {
        case .assign:
            record.assignMarks.removeAll { $0.id == best.id }
        case .finish:
            record.finishMarks.removeAll { $0.id == best.id }
        case .waste:
            record.wasteMarks.removeAll { $0.id == best.id }
        }
        return true
    }
}

enum LarderCommand: Sendable {
    case scan(title: String, barcode: String, packageDaykey: Int, id: UUID, at: Date)
    case assign(tinID: UUID, cookDaykey: Int, at: Date)
    case finish(tinID: UUID, at: Date)
    case waste(tinID: UUID, at: Date)
    case undo
    case cullLapsed
    case adjustPackage(tinID: UUID, packageDaykey: Int)
}

enum FoldRefusal: String, Sendable, Equatable {
    case blankBoard
    case missingTin
    case invalidScan
    case earlyFinish
    case duplicateAssign
    case notLive
    case nothingToUndo
    case nothingToCull
}

enum CommittedMark: String, Sendable, Equatable {
    case scan
    case assign
    case finish
    case waste
    case early
    case duplicate
    case undo
    case cull
    case adjust
}

struct FoldEffect: Sendable, Equatable {
    var record: LarderRecord
    var refusal: FoldRefusal?
    var committed: CommittedMark?
}

struct FoldedTin: Sendable, Equatable, Identifiable {
    var tin: Tin
    var phase: TinPhase
    var cookDaykey: Int?
    var daysLeft: Int

    var id: UUID { tin.id }
}
