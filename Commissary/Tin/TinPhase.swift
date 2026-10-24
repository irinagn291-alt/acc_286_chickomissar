import Foundation

/// Live and terminal phases of a tin. The fold computes this. It is not stored.
enum TinPhase: String, Codable, Sendable, Equatable {
    /// On the use-soon ladder. Assign is the legal home verb.
    case stock
    /// Seated on a cook-day ticket after an AssignMark.
    case assigned
    /// Used or wasted. Off the live board.
    case cleared
    /// Stock or Assigned whose package day is already past. Pantry can cull it.
    case lapsed
}
