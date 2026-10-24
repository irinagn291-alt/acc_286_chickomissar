import Foundation

/// Presentation state between the larder record and the home chrome.
/// Home reads this board. It does not recompute phases in a view.
struct CookDayBoard: Sendable, Equatable {
    /// Blank when no Stock or Assigned tin remains. Lapsed and Cleared do not keep the board live.
    var mark: BoardMark
    var featuredDaykey: Int
    var tickets: [CookDayTicket]
    var ladder: [LadderRung]
    var assignedTally: Int
    var featuredDaysLeft: Int?
    var pantry: PantryLedger

    var isBlank: Bool { mark == .blank }
}

enum BoardMark: String, Sendable, Equatable {
    case blank
    case live
}

struct CookDayTicket: Sendable, Equatable, Identifiable {
    var daykey: Int
    var tins: [FoldedTin]

    var id: Int { daykey }
}

struct LadderRung: Sendable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var daysLeft: Int
    var packageDaykey: Int
    var barcode: String
}

struct PantryLedger: Sendable, Equatable {
    var assigned: [FoldedTin]
    var stock: [FoldedTin]
    var lapsed: [FoldedTin]
    var cleared: [FoldedTin]

    static let empty = PantryLedger(assigned: [], stock: [], lapsed: [], cleared: [])
}
