import Foundation

/// A pantry tin. Scan writes one Stock tin stamped with packageDaykey.
/// Phase is never stored here. LarderFold derives Stock, Assigned, Cleared, or Lapsed.
struct Tin: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var barcode: String
    /// Best-before as YYYYMMDD. Days left is computed from this and today.
    var packageDaykey: Int
    var recordedAt: Date
}
