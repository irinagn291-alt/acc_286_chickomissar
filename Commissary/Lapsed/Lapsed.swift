import Foundation

/// Terminal hold for a Stock or Assigned tin whose packageDaykey is before today.
/// Cull moves those tins off the live ledger into the archive. Cleared tins are not lapsed.
struct LapsedHold: Sendable, Equatable, Identifiable {
    var id: UUID
    var tin: Tin
    var daysPast: Int
    var cookDaykey: Int?
}
